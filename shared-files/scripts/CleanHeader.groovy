import org.apache.nifi.processor.io.InputStreamCallback
import org.apache.nifi.processor.io.OutputStreamCallback
import org.apache.nifi.processor.io.StreamCallback
import java.nio.charset.StandardCharsets
import java.util.regex.Pattern

def flowFile = session.get()
if(!flowFile) return

def filename = flowFile.getAttribute('filename') ?: 'unknown file'
def datasetId = flowFile.getAttribute('datasetId') ?: 'unknown dataset'

try {
    def rowsNumber = flowFile.getAttribute('rowsNumber')
    if (!rowsNumber) {
        def missing = ("${filename}: attribute 'rowsNumber' is missing, so the header " +
            "cannot be cleaned. Dataset ${datasetId} is most likely not registered in " +
            "eucaim_etl_aux.LookupHeaderRowsToRemove.").toString()
        log.error(missing)
        flowFile = session.putAttribute(flowFile, "log_message", missing)
        session.transfer(flowFile, REL_FAILURE)
        return
    }
    if (rowsNumber == 'null'){
        log.debug("${filename}: 'rowsNumber' is null, the FlowFile is passed through unchanged.")
        session.transfer(flowFile, REL_SUCCESS)
        return
    }

    def rows = rowsNumber as int

	def textRef = new StringBuilder()
    session.read(flowFile, new InputStreamCallback() {
        @Override
        void process(InputStream inputStream) throws IOException {
            textRef.append(new String(inputStream.bytes, StandardCharsets.UTF_8))
        }
    })
    def content = textRef.toString()
	def lines = content.readLines()
	
	// calcular desde donde conservar
	def start = 1 + rows  // conservar desde esta posición en adelante (índice)
	def tail = []

	if (start < lines.size()) {
   		// subList desde start hasta el final
    	tail = lines.subList(start, lines.size())
	} else {
    	// no hay líneas tras la cabecera + rowsNumber
    	tail = []
	}

	// reconstruir: primera línea + tail
	def result = ([lines[0]] + tail).join('\n')

	log.debug("${filename}: dropped ${rows} row(s) after the header, ${tail.size()} data rows kept")

    flowFile = session.write(flowFile, new OutputStreamCallback() {
        @Override
        void process(OutputStream outputStream) throws IOException {
            outputStream.write(result.getBytes(StandardCharsets.UTF_8))
        }
    })

    session.transfer(flowFile, REL_SUCCESS)

} catch (Exception e) {
    def detail = ("Header cleaning failed on ${filename} - " +
        "${e.class.simpleName}: ${e.message}").toString()
    log.error(detail, e)
    flowFile = session.putAttribute(flowFile, "log_message", detail)
    session.transfer(flowFile, REL_FAILURE)
}