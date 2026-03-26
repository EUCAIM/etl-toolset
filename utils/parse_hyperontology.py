import rdflib
from rdflib.namespace import RDF, RDFS, OWL, SKOS
from rdflib import URIRef, Namespace


OWL_FILE = "eucaim_hyperontology.owl"
OUTPUT_SQL = "5_init_eucaim_hyperontology_codes_update.sql"

g = rdflib.Graph()
g.parse(OWL_FILE, format="xml")

# Namespace base
EUCAIM = Namespace("https://cancerimage.eu/ontology/EUCAIM#")

def get_class_properties(class_url):
    """
    Dada la URL de una clase, devuelve un diccionario con propiedades a extraer
    """
    class_uri = URIRef(class_url)
    
    # Lista de propiedades a extraer
    custom_props = [
        "OMOP_Concept_ID",
        "OMOP_Concept_code",
        "OMOP_Domain_ID",
        "OMOP_Vocabulary_ID",
        "LOINC",
        "source",
        "rdfs:label",
        "skos:prefLabel"
    ]
    
    result = {}
    
    for prop in custom_props:
        # Construir URI de la propiedad
        if prop.startswith("rdfs:"):
            prop_uri = URIRef(f"http://www.w3.org/2000/01/rdf-schema#{prop.split(':')[1]}")
        elif prop.startswith("skos:"):
            prop_uri = URIRef(f"http://www.w3.org/2004/02/skos/core#{prop.split(':')[1]}")
        else:
            prop_uri = EUCAIM[prop]
        
        # Obtener todos los valores de esa propiedad
        values = list(g.objects(subject=class_uri, predicate=prop_uri))
        # Convertir de URIRef o Literal a string
        result[prop] = [str(v) for v in values] if values else None
    
    return result

def get_first_literal(s, predicates):
    for p in predicates:
        for _, _, o in g.triples((s, p, None)):
            return str(o)
    return None

def extract_code(uri):
    return uri.split("#")[-1]

def infer_domain(s):
    props = get_class_properties(s)
    #print("--" + str(props["OMOP_Domain_ID"]))
    if props["OMOP_Domain_ID"]:
        return props["OMOP_Domain_ID"][0]

    # 3. fallback
    return "---"


concepts = []
id_counter = 1

for s in g.subjects(RDF.type, OWL.Class):
    uri = str(s)
    code = extract_code(uri)

    label = get_first_literal(s, [RDFS.label, SKOS.prefLabel])
    if not label:
        label = code

    label = label.replace("'", "''")

    domain = infer_domain(s)

    concepts.append({
        "id": id_counter,
        "code": code,
        "uri": uri,
        "name": label,
        "domain": domain
    })

    id_counter += 1


with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
    for c in concepts:
        f.write(f"""INSERT INTO eucaim_hyperontology_codes.concept VALUES (
{c['id']},
'{c['code']}',
'{c['uri']}',
'{c['name']}',
'{c['domain']}',
'None',
'EUCAIM',
'Class',
'S'
);\n""")

print("✅ SQL generado en \'" + OUTPUT_SQL + "\' a partir de la ontología en \'" + OWL_FILE + "\'")