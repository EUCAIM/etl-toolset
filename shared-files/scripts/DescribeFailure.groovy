import java.nio.charset.StandardCharsets

/**
 * Turns a FlowFile that a processor routed to a failure-like relationship into
 * a ProcessLog row that says what happened.
 *
 * Most processors drop such a FlowFile into an auto-terminated relationship, so
 * the only trace left is a bulletin in the NiFi canvas, which nobody sees on a
 * deployed node. Routing that relationship here instead keeps the evidence.
 *
 * The upstream StampFailure* UpdateAttribute supplies the context this script
 * cannot know by itself, because a script has no way of asking which connection
 * delivered the FlowFile:
 *
 *   failure.source   name of the processor that gave up on the FlowFile
 *   failure.rel      relationship it used (failure, unmatched, ...)
 *   failure.hint     what an operator should check, in plain words
 *
 * Only log_message is produced here. The bind parameters are assembled by the
 * PrepareLogArgs processor downstream, the same one every other log row uses.
 */

def flowFile = session.get()
if (!flowFile) return

// keep one oversized attribute from crowding out the rest of the message
final int MAX_ATTR = 160
final int MAX_MESSAGE = 3000

// noise that says nothing about the failure, plus our own plumbing
final Set<String> SKIP = ['path', 'absolute.path', 'uuid', 'entryDate', 'lineageStartDate',
                          'fileSize', 'file.owner', 'file.group', 'file.permissions',
                          'file.creationTime', 'file.lastModifiedTime', 'file.lastAccessTime',
                          'failure.source', 'failure.rel', 'failure.hint'] as Set

try {
    def attrs = flowFile.getAttributes()
    def hint = attrs['failure.hint'] ?: ''

    // A per-step stamp cannot name the processor, because a script has no way of
    // asking which connection delivered the FlowFile. Name the step instead:
    // that is what says where the run stopped.
    def where = "step ${attrs['log_stepnumber']} (${attrs['log_stepname']})" +
                (attrs['log_pipelinestage'] ? " of ${attrs['log_pipelinestage']}" : '')
    def source = attrs['failure.source'] ?: "A processor in ${where}"
    def rel = attrs['failure.rel'] ?: 'failure, unmatched or retry'

    // The content is the dataset itself, so it is never logged: these rows end
    // up in ProcessLog and are exported to output_data.
    def interesting = attrs.findAll { k, v ->
        !SKIP.contains(k) && !k.startsWith('sql.args.') && !k.startsWith('log_') && v
    }.collect { k, v ->
        def val = v.toString().replaceAll(/\s+/, ' ')
        "${k}=${val.length() > MAX_ATTR ? val.take(MAX_ATTR) + '...' : val}"
    }.sort().join('; ')

    def parts = ["${source} routed the file to '${rel}' and it was not processed."]
    if (hint) parts << hint
    if (interesting) parts << "FlowFile attributes: ${interesting}"
    parts << "FlowFile uuid: ${attrs['uuid']}"

    def message = parts.join(' ')
    if (message.length() > MAX_MESSAGE) message = message.take(MAX_MESSAGE) + '...'

    flowFile = session.putAttribute(flowFile, 'log_message', message)

    // a FlowFile that reaches here through a relationship nobody stamped would
    // otherwise be logged against an empty dataset
    if (!attrs['datasetId'] && attrs['filename']) {
        flowFile = session.putAttribute(flowFile, 'datasetId',
            attrs['filename'].toString().split('_')[0].toLowerCase())
    }

    log.error(message)
    session.transfer(flowFile, REL_SUCCESS)

} catch (Exception e) {
    // this processor is the last thing standing between a failure and silence,
    // so it must not become another silent drop
    def fallback = ("DescribeFailure could not describe the failure of " +
        "${flowFile.getAttribute('failure.source')}: ${e.class.simpleName}: ${e.message}").toString()
    log.error(fallback, e)
    flowFile = session.putAttribute(flowFile, 'log_message', fallback)
    session.transfer(flowFile, REL_SUCCESS)
}
