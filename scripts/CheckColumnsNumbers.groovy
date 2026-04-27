import org.apache.nifi.processor.io.InputStreamCallback
import org.apache.nifi.processor.io.OutputStreamCallback
import org.apache.nifi.processor.io.StreamCallback
import java.nio.charset.StandardCharsets
import java.util.regex.Pattern

def flowFile = session.get()
if(!flowFile) return

def mismatches = []

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
	
    String header = lines[0]
    if (header == null) return
    def expectedCols = header.split(/,(?=(?:[^"]*"[^"]*")*[^"]*$)/).length
    log.info(header)

    for (int lineNumber = 1; lineNumber < lines.size(); lineNumber++) {
        def line = lines[lineNumber]
        def cols = line.split(/,(?=(?:[^"]*"[^"]*")*[^"]*$)/, -1).length  // -1 para incluir vacíos

        if (cols != expectedCols) {
            def mismatch = "Line ${lineNumber}: ${cols} columns (expected ${expectedCols})"
            log.warn(mismatch)
            flowFile = session.putAttribute(flowFile, "log_message", mismatch)
            session.transfer(flowFile, REL_FAILURE)
            return
        }

        log.info(line)
    }

    flowFile = session.write(flowFile, new OutputStreamCallback() {
        @Override
        void process(OutputStream outputStream) throws IOException {
            outputStream.write(content.getBytes(StandardCharsets.UTF_8))
        }
    })

    session.transfer(flowFile, REL_SUCCESS)

} catch (Exception e) {
    log.error("Error procesando el FlowFile: ${e.message}", e)
    session.transfer(flowFile, REL_FAILURE)
}