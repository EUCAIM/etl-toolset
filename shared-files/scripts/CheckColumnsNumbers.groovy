import org.apache.nifi.processor.io.InputStreamCallback
import org.apache.nifi.processor.io.OutputStreamCallback
import org.apache.nifi.processor.io.StreamCallback
import java.nio.charset.StandardCharsets
import java.util.regex.Pattern

def flowFile = session.get()
if(!flowFile) return

def mismatches = []
def filename = flowFile.getAttribute('filename') ?: 'unknown file'

try {

	def textRef = new StringBuilder()
    session.read(flowFile, new InputStreamCallback() {
        @Override
        void process(InputStream inputStream) throws IOException {
            textRef.append(new String(inputStream.bytes, StandardCharsets.UTF_8))
        }
    })
    def content = textRef.toString()
	def lines = content.readLines()
	
    // an empty input used to fall through without transferring the FlowFile,
    // which NiFi rolls back and retries forever instead of reporting
    if (lines.isEmpty()) {
        def empty = "${filename} is empty: no header row was found.".toString()
        log.error(empty)
        flowFile = session.putAttribute(flowFile, "log_message", empty)
        session.transfer(flowFile, REL_FAILURE)
        return
    }

    String header = lines[0]
    def expectedCols = header.split(/,(?=(?:[^"]*"[^"]*")*[^"]*$)/, -1).length
    log.debug("${filename}: header declares ${expectedCols} columns -> ${header}")

    for (int lineNumber = 1; lineNumber < lines.size(); lineNumber++) {
        def line = lines[lineNumber]
        def cols = line.split(/,(?=(?:[^"]*"[^"]*")*[^"]*$)/, -1).length  // -1 para incluir vacíos

        if (cols != expectedCols) {
            // the row itself is patient data, so it is deliberately not logged
            def mismatch = ("${filename}: line ${lineNumber} has ${cols} columns, " +
                "the header declares ${expectedCols}. Check that row for stray or " +
                "missing commas, or for a value containing a comma that is not quoted.").toString()
            log.warn(mismatch)
            flowFile = session.putAttribute(flowFile, "log_message", mismatch)
            session.transfer(flowFile, REL_FAILURE)
            return
        }
    }

    log.debug("${filename}: ${lines.size() - 1} data rows checked, all with ${expectedCols} columns")

    flowFile = session.write(flowFile, new OutputStreamCallback() {
        @Override
        void process(OutputStream outputStream) throws IOException {
            outputStream.write(content.getBytes(StandardCharsets.UTF_8))
        }
    })

    session.transfer(flowFile, REL_SUCCESS)

} catch (Exception e) {
    // without this the failure reached ProcessLog with an empty message
    def detail = "Column check failed on ${filename} - ${e.class.simpleName}: ${e.message}".toString()
    log.error(detail, e)
    flowFile = session.putAttribute(flowFile, "log_message", detail)
    session.transfer(flowFile, REL_FAILURE)
}