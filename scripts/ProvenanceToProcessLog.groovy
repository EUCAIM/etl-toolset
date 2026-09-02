import org.apache.nifi.components.state.Scope
import org.apache.nifi.provenance.ProvenanceEventType

/**
 * Records in ProcessLog every file the ETL threw away.
 *
 * When a processor sends a FlowFile to a relationship that is auto-terminated,
 * the file is destroyed and the trail in ProcessLog simply stops: nothing says
 * the run ended early, let alone where. NiFi does record it, as a DROP
 * provenance event, and this reporting task turns those events into rows.
 *
 * It runs outside the dataflow, so no processor and no connection is added to
 * any mapping. One instance covers every pipeline and every dataset.
 *
 * Only failure, retry and unmatched are reported. A file that completes is
 * auto-terminated too, through success or original, and those are not failures.
 */

final int MAX_EVENTS = 5000
final Set<String> REPORTED = ['failure', 'retry', 'unmatched'] as Set
final String AUTO_TERMINATED = 'Auto-Terminated by '

/**
 * One (stepNumber, stepName) per pipeline stage, keyed by dataset type. These
 * are pairs the flows already declare; the task introduces none of its own. The
 * exact processor is named in the message, so the step is only a grouping.
 */
final Map<String, List<String>> STEPS = [
    'clinical_data|loop01'    : ['1', 'read_raw_input'],
    'clinical_data|loop02'    : ['3', 'invoke_TDC'],
    'clinical_data|loop03'    : ['7', 'write_to_ingestion_db'],
    'clinical_data|loop04'    : ['8', 'write_csv_output'],
    'image_metadata|loop01'   : ['1', 'read_and_convert_input'],
    'image_metadata|loop02'   : ['3', 'write_to_ingestion_db'],
    // that flow declares no step of its own, so it borrows the closest one
    'image_metadata|loop03'   : ['3', 'write_to_ingestion_db'],
    'image_timepoints|loop01' : ['1', 'read_and_convert_input'],
    'image_timepoints|loop02' : ['3', 'write_data_linking'],
    'image_timepoints|loop03' : ['4', 'write_output_db'],
]

final Map<String, String> DATASET_TYPES = [
    'Clinical_data'    : 'clinical_data',
    'Dicom_metadata'   : 'image_metadata',
    'Dicom_timepoints' : 'image_timepoints',
]

// ---------------------------------------------------------------- position

def stateManager = context.stateManager
def state = stateManager.getState(Scope.LOCAL)
def repository = context.eventAccess.provenanceRepository
long maxEventId = repository.maxEventId == null ? -1L : repository.maxEventId
long lastSeen = state.get('lastEventId') ? state.get('lastEventId') as long : -1L

if (lastSeen < 0) {
    // First run. The repository holds weeks of history and replaying it would
    // bury ProcessLog under events nobody is waiting for, so start from now.
    stateManager.setState(['lastEventId': String.valueOf(maxEventId)], Scope.LOCAL)
    log.info("ProvenanceToProcessLog starting at event ${maxEventId}; earlier history is not replayed")
    return
}
if (maxEventId <= lastSeen) return

// --------------------------------------------- which group each processor is in

def processors = [:]   // processor id -> [name, name of the group that identifies the stage]
def walk
walk = { status, inherited ->
    // a processor nested in a sub group keeps the name of the enclosing flow,
    // which is the one carrying the loopNN that identifies the stage
    def effective = (status.name ==~ /(?i).*loop0\d.*/) ? status.name : inherited
    status.processorStatus.each { p -> processors[p.id] = [p.name, effective ?: ''] }
    status.processGroupStatus.each { child -> walk(child, effective) }
}
walk(context.eventAccess.controllerStatus, null)

// ------------------------------------------------------------------ events

def events = context.eventAccess.getProvenanceEvents(lastSeen + 1, MAX_EVENTS)
if (!events) return

def rows = []
int unmapped = 0

events.each { event ->
    if (event.eventType != ProvenanceEventType.DROP) return

    def details = event.details ?: ''
    // getRelationship is the reliable source; details is the fallback for the
    // case where the event carries the name only in its text
    def relationship = event.relationship
    if (!relationship && details.startsWith(AUTO_TERMINATED)) {
        relationship = details.substring(AUTO_TERMINATED.length())
                              .replaceFirst(/(?i)\s*Relationship\s*$/, '').trim()
    }
    if (!relationship || !REPORTED.contains(relationship.toLowerCase())) return

    def (processorName, groupName) = processors[event.componentId] ?: [event.componentType, '']
    // matched anywhere in the name, not just at the start: the flow file is
    // prefixed with the dataset id and nothing guarantees the group keeps the
    // exact shape of the name the mapping declares
    def stageMatch = (groupName =~ /(?i)(loop0\d)/)
    def stage = stageMatch ? stageMatch[0][1].toLowerCase() : null
    def datasetType = DATASET_TYPES.find { marker, _ ->
        groupName.toLowerCase().contains(marker.toLowerCase())
    }?.value

    def step = (stage && datasetType) ? STEPS["${datasetType}|${stage}"] : null
    if (!step) {
        // never drop it silently: that is the very habit this task exists to end
        unmapped++
        log.warn("ProvenanceToProcessLog: no step is mapped for group '${groupName}' " +
                 "(processor '${processorName}', relationship '${relationship}'), row not written")
        return
    }

    def attributes = event.attributes ?: [:]
    def filename = attributes['filename'] ?: ''
    def datasetId = attributes['datasetId'] ?:
        (filename.contains('_') ? filename.substring(0, filename.indexOf('_')).toLowerCase() : '')

    def message = "${processorName} (${event.componentType}) discarded the file through the " +
                  "'${relationship}' relationship, so it did not complete ${stage}." +
                  (details ? " NiFi reported: ${details}." : '') +
                  " FlowFile uuid: ${event.flowFileUuid}"

    rows << [filename, datasetId, datasetType, stage, step[0], step[1], 'ERROR', 'ERROR', message.toString()]
}

// ------------------------------------------------------------------ writing

if (rows) {
    def url = "jdbc:postgresql://${System.getenv('SHARED_DB_HOST')}:" +
              "${System.getenv('SHARED_DB_PORT')}/${System.getenv('SHARED_DB_NAME')}"

    // The driver comes from Module Directory, so it lives in a class loader of
    // its own. DriverManager only accepts drivers visible to its caller and
    // answers "No suitable driver found" for this one, however well it loaded.
    // Asking the driver to connect directly sidesteps that registry.
    def driver = Class.forName('org.postgresql.Driver').getDeclaredConstructor().newInstance()
    def credentials = new Properties()
    credentials.setProperty('user', System.getenv('SHARED_DB_USERNAME') ?: '')
    credentials.setProperty('password', System.getenv('SHARED_DB_PASSWORD') ?: '')
    def connection = driver.connect(url, credentials)
    if (connection == null) {
        throw new IllegalStateException("the PostgreSQL driver did not accept ${url}")
    }
    try {
        connection.autoCommit = false
        def call = connection.prepareStatement(
            'CALL eucaim_etl_aux.insert_log_v001(?,?,?,?,?,?,?,?,?)')
        rows.each { row ->
            row.eachWithIndex { value, i -> call.setString(i + 1, value as String) }
            call.addBatch()
        }
        call.executeBatch()
        connection.commit()
        call.close()
        log.info("ProvenanceToProcessLog wrote ${rows.size()} discarded files to ProcessLog")
    } catch (Exception e) {
        // leave lastEventId untouched so the next run retries these events
        connection.rollback()
        log.error("ProvenanceToProcessLog could not write to ProcessLog: " +
                  "${e.class.simpleName}: ${e.message}", e)
        throw e
    } finally {
        connection.close()
    }
}

long processed = events.last().eventId
stateManager.setState(['lastEventId': String.valueOf(processed)], Scope.LOCAL)
if (unmapped) {
    log.warn("ProvenanceToProcessLog skipped ${unmapped} discarded files whose group is not mapped to a step")
}
