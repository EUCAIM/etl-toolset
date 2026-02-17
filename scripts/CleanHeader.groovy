import org.apache.nifi.processor.io.InputStreamCallback
import org.apache.nifi.processor.io.OutputStreamCallback
import org.apache.nifi.processor.io.StreamCallback
import java.nio.charset.StandardCharsets
import java.util.regex.Pattern

def flowFile = session.get()
if(!flowFile) return

try {
    def rowsNumber = flowFile.getAttribute('rowsNumber')
    if (!rowsNumber) {
        log.warn("Atributo 'rowsNumber' no encontrado, se omite el FlowFile.")
        session.transfer(flowFile, REL_FAILURE)
        return
    }
    if (rowsNumber == 'null'){
        log.warn("Atributo 'rowsNumber' es null, NO se modifica el FlowFile.")
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

    flowFile = session.write(flowFile, new OutputStreamCallback() {
        @Override
        void process(OutputStream outputStream) throws IOException {
            outputStream.write(result.getBytes(StandardCharsets.UTF_8))
        }
    })

    session.transfer(flowFile, REL_SUCCESS)

} catch (Exception e) {
    log.error("Error procesando el FlowFile: ${e.message}", e)
    session.transfer(flowFile, REL_FAILURE)
}