#!/usr/bin/env python3
"""
Points the DBCPConnectionPool of each given flow at the SHARED_DB_* parameters,
so the same flow file works against the nifi-postgres container of a local node
and against the database the reference node is given (shared-sql-db-auth).

    scripts/parametrize_db_connection.py [--check] flows/*.json ../etl-mappings/*.json

For every DBCPConnectionPool it sets:
    Database Connection URL  jdbc:postgresql://#{SHARED_DB_HOST}:#{SHARED_DB_PORT}/#{SHARED_DB_NAME}
    Database User            #{SHARED_DB_USERNAME}
    Password                 #{SHARED_DB_PASSWORD}
and adds to ETL_v03_parameters whichever SHARED_DB_* parameter the file lacks.
Their values are the environment variables of the same name, which
docker-compose.yaml and the helm chart set. SHARED_DB_PASSWORD is sensitive, so
NiFi never exports its value: init.sh fills it after loading the flows.

The file is edited as text, not dumped again, so the diff holds only these
properties. Re-exporting from NiFi would instead rewrite most identifiers and
hide the change. The result is then parsed and compared with the original: if
anything but the intended properties changed, the file is left untouched.

--check changes nothing and exits 1 if any flow still needs the change, which is
what the CI runs to stop a flow exported from an outdated NiFi from bringing a
hard coded connection back.
"""
import copy
import json
import re
import sys

PARAM_CONTEXT = "ETL_v03_parameters"
URL = "jdbc:postgresql://#{SHARED_DB_HOST}:#{SHARED_DB_PORT}/#{SHARED_DB_NAME}"
USER = "#{SHARED_DB_USERNAME}"
PASSWORD = "#{SHARED_DB_PASSWORD}"
PARAMETERS = [
    ("SHARED_DB_HOST", False),
    ("SHARED_DB_PORT", False),
    ("SHARED_DB_NAME", False),
    ("SHARED_DB_USERNAME", False),
    ("SHARED_DB_PASSWORD", True),
]


def connection_pools(node):
    if isinstance(node, dict):
        if node.get("type") == "org.apache.nifi.dbcp.DBCPConnectionPool":
            yield node
        for value in node.values():
            yield from connection_pools(value)
    elif isinstance(node, list):
        for value in node:
            yield from connection_pools(value)


def missing_parameters(flow):
    context = flow.get("parameterContexts", {}).get(PARAM_CONTEXT)
    if context is None:
        return []
    present = {p["name"] for p in context["parameters"]}
    return [(n, s) for n, s in PARAMETERS if n not in present]


def needs_change(flow):
    for pool in connection_pools(flow):
        props = pool["properties"]
        if (props.get("Database Connection URL"), props.get("Database User"), props.get("Password")) != (URL, USER, PASSWORD):
            return True
    return bool(missing_parameters(flow))


def expected(flow):
    """the flow as it must look after the change, to validate the text edit"""
    flow = copy.deepcopy(flow)
    for pool in connection_pools(flow):
        pool["properties"]["Database Connection URL"] = URL
        pool["properties"]["Database User"] = USER
        pool["properties"]["Password"] = PASSWORD
    for name, sensitive in missing_parameters(flow):
        param = {"name": name, "description": "", "sensitive": sensitive, "provided": False}
        if not sensitive:
            param["value"] = "${%s}" % name
        flow["parameterContexts"][PARAM_CONTEXT]["parameters"].append(param)
    return flow


def edit_text(text, flow):
    # string values only: the property descriptors share these keys but hold an object
    text = re.sub(r'("Database Connection URL"\s*:\s*)"jdbc:postgresql:[^"]*"',
                  lambda m: m.group(1) + json.dumps(URL), text)
    text = re.sub(r'("Password"\s*:\s*)"#\{[^"}]*\}"',
                  lambda m: m.group(1) + json.dumps(PASSWORD), text)

    # a pool with no Password gets it right after the user, on a line of its own
    add_password = not any("Password" in p["properties"] for p in connection_pools(flow))
    text = re.sub(r'("Database User"(\s*:\s*))"[^"]*"',
                  lambda m: m.group(1) + json.dumps(USER) + (
                      "," + _sep_before(text, m.start()) + '"Password"' + m.group(2) + json.dumps(PASSWORD)
                      if add_password else ""),
                  text)

    missing = missing_parameters(flow)
    if missing:
        text = _append_parameters(text, missing)
    return text


def _sep_before(text, pos):
    """newline and indent of the line holding pos, or nothing on a one line file"""
    line_start = text.rfind("\n", 0, pos)
    if line_start < 0:
        return ""
    indent = re.match(r"[ \t]*", text[line_start + 1:]).group(0)
    return "\n" + indent


def _append_parameters(text, missing):
    start = text.index('"%s"' % PARAM_CONTEXT)
    array = text.index('"parameters"', start)
    open_bracket = text.index("[", array)
    objects = _array_objects(text, open_bracket)
    close_bracket = objects.pop()

    # copy the layout of the last parameter already there: key order and indents
    last_start, last_end = objects[-1]
    last = text[last_start:last_end + 1]
    keys = re.findall(r'"(\w+)"\s*:', last)
    sep_obj = _sep_before(text, last_start)
    sep_key = _sep_before(last, re.search(r'"\w+"', last).start())
    sep_close = _sep_before(last, len(last) - 1)
    colon = re.search(r'"\w+"(\s*:\s*)', last).group(1)

    blocks = []
    for name, sensitive in missing:
        values = {"name": name, "description": "", "sensitive": sensitive, "provided": False}
        if not sensitive:
            values["value"] = "${%s}" % name
        order = [k for k in keys if k in values] + [k for k in values if k not in keys]
        pairs = [json.dumps(k) + colon + json.dumps(values[k]) for k in order]
        blocks.append("{" + sep_key + ("," + sep_key).join(pairs) + sep_close + "}")

    insertion = "".join("," + sep_obj + b for b in blocks)
    return text[:last_end + 1] + insertion + text[last_end + 1:]


def _array_objects(text, open_pos):
    """(start, end) of each object directly inside the array, then the closing bracket"""
    found, depth, in_string, escaped, obj_start = [], 0, False, False, None
    for i in range(open_pos, len(text)):
        c = text[i]
        if in_string:
            if escaped:
                escaped = False
            elif c == "\\":
                escaped = True
            elif c == '"':
                in_string = False
        elif c == '"':
            in_string = True
        elif c in "[{":
            depth += 1
            if c == "{" and depth == 2:
                obj_start = i
        elif c in "]}":
            depth -= 1
            if c == "}" and depth == 1:
                found.append((obj_start, i))
            elif depth == 0:
                found.append(i)
                return found
    raise ValueError("unbalanced parameters array")


def main(argv):
    check = "--check" in argv
    files = [a for a in argv if a != "--check"]
    pending, failed = [], []
    for path in files:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        flow = json.loads(text)
        if not needs_change(flow):
            continue
        pending.append(path)
        if check:
            continue
        new_text = edit_text(text, flow)
        if json.loads(new_text) != expected(flow):
            failed.append(path)
            continue
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(new_text)
        print("updated  " + path)

    if check and pending:
        print("These flows connect to the database without the SHARED_DB_* parameters:")
        for path in pending:
            print("  " + path)
        print("Run scripts/parametrize_db_connection.py on them.")
        return 1
    if failed:
        print("Left untouched, the text edit did not give the expected flow:")
        for path in failed:
            print("  " + path)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
