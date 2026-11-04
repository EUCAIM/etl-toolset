import groovy.transform.Field
import org.apache.nifi.processor.io.InputStreamCallback
import org.apache.nifi.processor.io.OutputStreamCallback
import java.nio.charset.StandardCharsets
import java.time.LocalDate
import java.time.temporal.ChronoUnit

// Clinical data delivered as one CSV per CDM entity (right now quite specific for APHP PAIMRI),
//  related by the ids of each entity.
// QueryRecord only sees one FlowFile at a time and cannot join them, so the files of a
// delivery are gathered here, joined, and written as a single CSV with one row per CDM record.
// Its "Entity" column tells which ingestion table the row is meant for, and the mapping filters
// on it.
//
// The files of a delivery reach this processor one by one, as TDC releases them. Until every
// expected entity is queued, or the oldest file has waited WaitSeconds, the session is rolled back
// and the processor yields, so the next run sees the whole queue again. Penalizing them instead
// would let each file come back at a different time, and they would never be seen together.
//
// Dynamic properties of the processor:
//   WaitSeconds         seconds to wait for missing entities before going on without them (120)
//   ExpectedEntities    comma separated entities a complete delivery carries (all known ones)
//   DatasetTitle        title of the dataset record
//   DatasetDescription  description of the dataset record

// entity of each file, told by its header: TDC and loop01 rename the files, so the name is no guide
static String entityOf(List<String> header) {
    if (!header) return null
    switch (header[0]) {
        case 'patient_id':           return 'Patient'
        case 'procedure_id':         return 'Procedure'
        case 'cancer_condition_id':  return 'Cancer_Condition'
        case 'histologic_grade_id':  return 'Histologic_Grade'
        case 'tumor_id':             return 'Tumor'
        case 'body_site_id':         return 'Body_Site'
        case 'tumor_marker_test_id': return 'Tumor_Marker_Test'
        case 'medical_history_id':   return 'Medical_History'
        case 'episode_id':           return header.contains('event_table_name') ? 'Episode_Event' : 'Episode'
        default:                     return null
    }
}

@Field static final List<String> ENTITIES = ['Patient', 'Procedure', 'Cancer_Condition', 'Histologic_Grade',
    'Tumor', 'Body_Site', 'Tumor_Marker_Test', 'Medical_History', 'Episode', 'Episode_Event']

// one column per field of every CDM record written; a row only fills those of its entity
@Field static final List<String> COLUMNS = ['Entity', 'Dataset_Identifier', 'Identifier', 'Patient_Identifier',
    'PrimaryCancerCondition_Identifier', 'Episode_Number', 'Episode_StartDate',
    'Dataset_Title', 'Dataset_Description',
    'Patient_BirthSex', 'Patient_BirthSexOriginal', 'Patient_DiagnosticCategory', 'Patient_DiagnosticCategoryOriginal',
    'Patient_ManagingOrganization', 'Patient_BirthDate', 'Patient_Deceased', 'Patient_LastContactDate',
    'Patient_CauseOfDeath', 'Patient_CauseOfDeathOriginal',
    'Episode_Type', 'Episode_TypeOriginal', 'Episode_EndDate',
    'PrimaryCancerCondition_AgeAtDiagnosis', 'PrimaryCancerCondition_AgeUnit', 'PrimaryCancerCondition_AgeUnitOriginal',
    'PrimaryCancerCondition_AssertedDate', 'PrimaryCancerCondition_Code', 'PrimaryCancerCondition_CodeOriginal',
    'PrimaryCancerCondition_HistologyMorphologyBehaviour', 'PrimaryCancerCondition_HistologyMorphologyBehaviourOriginal',
    'PrimaryCancerCondition_ConfirmedByProcedure',
    'Procedure_Code', 'Procedure_CodeOriginal', 'Procedure_Category', 'Procedure_CategoryOriginal',
    'Procedure_PerformedDate', 'Procedure_OffsetFromDiagnosis', 'Procedure_OffsetUnit', 'Procedure_OffsetUnitOriginal',
    'Procedure_ImagingTimepoint',
    'Tumor_IsIndex', 'Tumor_Morphology', 'Tumor_MorphologyOriginal', 'Tumor_Volume', 'Tumor_SizeMethod',
    'Tumor_SizeMethodOriginal', 'Tumor_SizeMaximumDimension', 'Tumor_SizeOtherDimension',
    'Tumor_BodySite', 'Tumor_BodySiteOriginal', 'Tumor_BodySiteLocation', 'Tumor_BodySiteLocationOriginal',
    'Tumor_BodySiteLaterality', 'Tumor_BodySiteLateralityOriginal', 'Tumor_HistologicGrade', 'Tumor_HistologicGradeOriginal',
    'HistologicGrade_ScoringSystem', 'HistologicGrade_ScoringSystemOriginal', 'HistologicGrade_CodeOriginal',
    'HistologicGrade_Grade', 'HistologicGrade_GradeOriginal',
    'TumorMarkerTest_Category', 'TumorMarkerTest_CategoryOriginal', 'TumorMarkerTest_Code', 'TumorMarkerTest_CodeOriginal',
    'TumorMarkerTest_ValueAsNumber', 'TumorMarkerTest_ValueAsConcept', 'TumorMarkerTest_ValueAsConceptOriginal',
    'TumorMarkerTest_ValueUnit', 'TumorMarkerTest_ValueUnitOriginal', 'TumorMarkerTest_Date']

// RFC 4180 records, also taking the \" escape the CSV writer of the pipeline uses
static List<List<String>> parseCsv(String text) {
    if (text.startsWith((char) 0xFEFF as String)) text = text.substring(1)
    def rows = []
    def row = []
    def field = new StringBuilder()
    boolean quoted = false
    int i = 0
    while (i < text.length()) {
        char c = text.charAt(i)
        char next = i + 1 < text.length() ? text.charAt(i + 1) : (char) 0
        if (quoted) {
            if ((c == (char) '"' || c == (char) '\\') && next == (char) '"') { field.append('"'); i += 2; continue }
            if (c == (char) '"') { quoted = false } else { field.append(c) }
        } else if (c == (char) '"') {
            quoted = true
        } else if (c == (char) ',') {
            row << field.toString(); field.setLength(0)
        } else if (c == (char) '\n') {
            row << field.toString(); field.setLength(0)
            rows << row; row = []
        } else if (c != (char) '\r') {
            field.append(c)
        }
        i++
    }
    if (field.length() > 0 || !row.isEmpty()) { row << field.toString(); rows << row }
    rows.findAll { r -> !(r.size() == 1 && r[0].trim().isEmpty()) }
}

static String csvValue(Object value) {
    def s = value == null ? '' : value.toString()
    (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) ? '"' + s.replace('"', '""') + '"' : s
}

static String text(Object value) { value == null ? '' : value.toString().trim() }

// TDC hands integers back as decimals ("90001.0"), which would break every id built from them
static String id(Object value) {
    def s = text(value)
    s ==~ /^-?\d+\.0+$/ ? s.substring(0, s.indexOf('.')) : s
}

static String date(Object value) {
    def s = text(value)
    if (s ==~ /^\d{4}-\d{2}-\d{2}.*/) return s.substring(0, 10)
    def m = s =~ /^(\d{2})\/(\d{2})\/(\d{4})/
    m.find() ? "${m.group(3)}-${m.group(2)}-${m.group(1)}".toString() : s
}

static Long daysBetween(String from, String to) {
    try {
        (from && to) ? ChronoUnit.DAYS.between(LocalDate.parse(from), LocalDate.parse(to)) : null
    } catch (Exception ignored) {
        null
    }
}

static String norm(Object value) { text(value).toLowerCase().replaceAll(/[^a-z]/, '') }

def flowFiles = session.get(100)
if (!flowFiles) return

def props = context.allProperties
int waitSeconds = (text(props['WaitSeconds']) ?: '120') as int
def expected = (text(props['ExpectedEntities']) ?: ENTITIES.join(',')).split(',')*.trim().findAll { it } as Set

def files = flowFiles.collect { ff ->
    def textRef = new StringBuilder()
    session.read(ff, { inputStream ->
        textRef.append(new String(inputStream.bytes, StandardCharsets.UTF_8))
    } as InputStreamCallback)
    def rows = parseCsv(textRef.toString())
    def header = rows ? rows[0].collect { it.trim().toLowerCase() } : []
    def records = rows.drop(1).collect { r ->
        def rec = [:]
        header.eachWithIndex { h, i -> rec[h] = i < r.size() ? r[i].trim() : '' }
        rec
    }
    [flowFile: ff, filename: ff.getAttribute('filename') ?: 'unknown file', entity: entityOf(header), records: records]
}

def present = files*.entity.findAll { it } as Set
def missing = (expected - present).sort()
long waited = (System.currentTimeMillis() - (flowFiles*.lineageStartDate.min() as long)).intdiv(1000)

if (missing && waited < waitSeconds) {
    log.debug("Waiting for ${missing} (${waited}s of ${waitSeconds}s), ${flowFiles.size()} file(s) queued")
    session.rollback()
    context.yield()
    return
}

def failAll = { List fs, String message ->
    log.error(message)
    fs.each { f -> session.transfer(session.putAttribute(f.flowFile, 'log_message', message), REL_FAILURE) }
}

def unknown = files.findAll { !it.entity }
if (unknown) {
    failAll(unknown, ("${unknown*.filename} not recognised as any CDM entity file: the first header column " +
        "must be the id of one of ${ENTITIES}.").toString())
}
def known = files.findAll { it.entity }
if (!known) return
if (!present.contains('Patient')) {
    failAll(known, ("No Patient file after waiting ${waited}s for this delivery (${known*.filename}). " +
        "The files are not processed without one.").toString())
    return
}
if (missing) {
    log.warn("Going on without ${missing} after waiting ${waited}s: they never reached this processor.")
}

def code = known[0].filename.split('_')[0].toLowerCase()
def bundle = null

try {
    def data = [:].withDefault { [] }
    known.each { data[it.entity].addAll(it.records) }

    def episodes = data.Episode.collectEntries { [(id(it.episode_id)): it] }
    def eventEpisode = data.Episode_Event.collectEntries { [(norm(it.event_table_name) + '|' + id(it.event_table_id)): id(it.episode_id)] }
    def conditions = data.Cancer_Condition.collectEntries { [(id(it.cancer_condition_id)): it] }
    def conditionsByPatient = data.Cancer_Condition.groupBy { id(it.patient_id) }
    def procedures = data.Procedure.collectEntries { [(id(it.procedure_id)): it] }
    def grades = data.Histologic_Grade.collectEntries { [(id(it.histologic_grade_id)): it] }
    def bodySites = data.Body_Site.collectEntries { [(id(it.body_site_id)): it] }

    def episodeOf = { String table, String eventId -> episodes[eventEpisode[table + '|' + eventId]] }
    def pccIdentifier = { String pid, String ccid -> "${code}${pid}_cancerCondition_${ccid}".toString() }
    def isImaging = { Map pr -> norm(pr.procedure_category).startsWith('imaging') }
    def procedureIdentifier = { Map pr ->
        "${code}${id(pr.patient_id)}_${isImaging(pr) ? 'imagingProcedure' : 'procedure'}_${id(pr.procedure_id)}".toString()
    }

    // the condition a record names, or else the only one of its patient
    def conditionOf = { String pid, String ccid ->
        if (ccid && id(conditions[ccid]?.patient_id) == pid) return ccid
        def own = conditionsByPatient[pid]
        own?.size() == 1 ? id(own[0].cancer_condition_id) : null
    }
    // procedures name no condition: the one in their episode, the one they confirm, or the patient's only one
    def conditionOfProcedure = { String pid, String prid ->
        def episodeId = eventEpisode['procedure|' + prid]
        def inEpisode = episodeId ? data.Cancer_Condition.find { eventEpisode['cancercondition|' + id(it.cancer_condition_id)] == episodeId } : null
        def confirmed = data.Cancer_Condition.find { id(it.procedure_id) == prid }
        def found = inEpisode ?: confirmed
        found && id(found.patient_id) == pid ? id(found.cancer_condition_id) : conditionOf(pid, null)
    }
    def episodeFields = { Map ep -> [Episode_Number: id(ep?.episode_number), Episode_StartDate: date(ep?.episode_start_date)] }
    def coded = { String column, Object value -> [(column): text(value), (column + 'Original'): text(value)] }

    def rows = []
    def emit = { String entity, Map values -> rows << ([Entity: entity, Dataset_Identifier: code] + values) }
    def skipped = [:].withDefault { 0 }

    emit('Dataset', [Identifier: code, Dataset_Title: text(props['DatasetTitle']) ?: code,
        Dataset_Description: text(props['DatasetDescription'])])

    data.Patient.each { p ->
        def pid = id(p.patient_id)
        emit('Patient', [Identifier: pid, Patient_Identifier: pid,
            Patient_ManagingOrganization: text(p.patient_managing_organization_id),
            Patient_BirthDate: date(p.patient_birth_date), Patient_Deceased: text(p.patient_deceased),
            Patient_LastContactDate: date(p.patient_date_of_last_contact)] +
            coded('Patient_BirthSex', p.patient_birth_sex) +
            coded('Patient_DiagnosticCategory', p.patient_diagnostic_category) +
            coded('Patient_CauseOfDeath', p.patient_cause_of_death))
    }

    data.Episode.each { e ->
        def pid = id(e.patient_id)
        emit('Episode', [Identifier: "${code}${pid}_episode_${id(e.episode_id)}".toString(), Patient_Identifier: pid,
            Episode_EndDate: date(e.episode_end_date)] + episodeFields(e) + coded('Episode_Type', e.episode_type_code))
    }

    data.Cancer_Condition.each { c ->
        def pid = id(c.patient_id)
        def ccid = id(c.cancer_condition_id)
        def confirming = procedures[id(c.procedure_id)]
        emit('PrimaryCancerCondition', [Identifier: pccIdentifier(pid, ccid), Patient_Identifier: pid,
            PrimaryCancerCondition_AgeAtDiagnosis: text(c.cancer_condition_age_at_diagnosis),
            PrimaryCancerCondition_AssertedDate: date(c.cancer_condition_asserted_date),
            PrimaryCancerCondition_ConfirmedByProcedure: confirming ? procedureIdentifier(confirming) : ''] +
            episodeFields(episodeOf('cancercondition', ccid)) +
            coded('PrimaryCancerCondition_AgeUnit', c.cancer_condition_age_unit) +
            coded('PrimaryCancerCondition_Code', c.cancer_condition_code) +
            coded('PrimaryCancerCondition_HistologyMorphologyBehaviour', c.cancer_condition_histology_morphology_behavior))
    }

    // imaging and diagnostic procedures both need a condition in ingestion: without one they are left out
    def imagingByPatient = [:].withDefault { [] }
    data.Procedure.each { pr ->
        def pid = id(pr.patient_id)
        def prid = id(pr.procedure_id)
        def ccid = conditionOfProcedure(pid, prid)
        if (!ccid) { skipped['procedures without a cancer condition']++; return }
        def performed = date(pr.procedure_date)
        def diagnosis = date(conditions[ccid].cancer_condition_asserted_date)
        def offset = daysBetween(diagnosis, performed)
        def values = [Identifier: procedureIdentifier(pr), Patient_Identifier: pid,
            PrimaryCancerCondition_Identifier: pccIdentifier(pid, ccid),
            Procedure_PerformedDate: performed, Procedure_OffsetFromDiagnosis: offset == null ? '' : offset.toString()] +
            episodeFields(episodeOf('procedure', prid) ?: episodeOf('cancercondition', ccid)) +
            coded('Procedure_Code', pr.procedure_code) +
            coded('Procedure_Category', pr.procedure_category) +
            coded('Procedure_OffsetUnit', offset == null ? '' : 'day')
        if (isImaging(pr)) {
            imagingByPatient[pid] << [order: prid.isLong() ? prid.toLong() : 0L, fields: values]
        } else {
            emit('CancerRelatedProcedure', values)
        }
    }
    // timepoints number the imaging procedures of each patient by date, as the DICOM timepoints expect
    imagingByPatient.each { pid, list ->
        list.sort { a, b ->
            ((a.fields.Procedure_PerformedDate ?: '9999') <=> (b.fields.Procedure_PerformedDate ?: '9999')) ?: (a.order <=> b.order)
        }.eachWithIndex { item, i -> emit('ImagingProcedure', item.fields + [Procedure_ImagingTimepoint: (i + 1).toString()]) }
    }

    data.Histologic_Grade.each { g ->
        def pid = id(g.patient_id)
        def ccid = conditionOf(pid, id(g.cancer_condition_id))
        if (!ccid) { skipped['histologic grades without a cancer condition']++; return }
        emit('HistologicGrade', [Identifier: "${code}${pid}_histologicGrade_${id(g.histologic_grade_id)}".toString(),
            Patient_Identifier: pid, PrimaryCancerCondition_Identifier: pccIdentifier(pid, ccid),
            HistologicGrade_CodeOriginal: text(g.histologic_grade_code)] +
            coded('HistologicGrade_ScoringSystem', g.histologic_grade_scoring_system) +
            coded('HistologicGrade_Grade', g.histologic_grade_value_as_concept))
    }

    // tumors reach their condition through their histologic grade, and their site through Body_Site
    def conditionsWithTumor = [] as Set
    data.Tumor.each { t ->
        def pid = id(t.patient_id)
        def tid = id(t.tumor_id)
        def grade = grades[id(t.histologic_grade_id)]
        def ccid = conditionOf(pid, grade ? id(grade.cancer_condition_id) : null)
        if (!ccid) { skipped['tumors without a cancer condition']++; return }
        def site = bodySites[id(t.tumor_body_site_id)] ?: [:]
        conditionsWithTumor << ccid
        emit('Tumor', [Identifier: "${code}${pid}_tumor_${tid}".toString(), Patient_Identifier: pid,
            PrimaryCancerCondition_Identifier: pccIdentifier(pid, ccid), Tumor_IsIndex: text(t.tumor_is_index),
            Tumor_Volume: text(t.tumor_volume), Tumor_SizeMaximumDimension: text(t.tumor_size_maximum_dimension),
            Tumor_SizeOtherDimension: text(t.tumor_size_other_dimension)] +
            episodeFields(episodeOf('tumor', tid) ?: episodeOf('cancercondition', ccid)) +
            coded('Tumor_Morphology', t.tumor_histology_morphology) +
            coded('Tumor_SizeMethod', t.tumor_size_method) +
            coded('Tumor_BodySite', site.body_site_code ?: conditions[ccid].cancer_condition_topography) +
            coded('Tumor_BodySiteLocation', site.body_site_location) +
            coded('Tumor_BodySiteLaterality', site.body_site_laterality) +
            coded('Tumor_HistologicGrade', grade?.histologic_grade_value_as_concept))
    }
    // without Tumor.csv (not applicable to PAIMRI) the topography of the condition is still kept, as IMALIVE does
    data.Cancer_Condition.findAll { !conditionsWithTumor.contains(id(it.cancer_condition_id)) && text(it.cancer_condition_topography) }.each { c ->
        def pid = id(c.patient_id)
        def ccid = id(c.cancer_condition_id)
        emit('Tumor', [Identifier: pccIdentifier(pid, ccid) + '_tumor_1', Patient_Identifier: pid,
            PrimaryCancerCondition_Identifier: pccIdentifier(pid, ccid)] +
            episodeFields(episodeOf('cancercondition', ccid)) +
            coded('Tumor_BodySite', c.cancer_condition_topography))
    }

    data.Tumor_Marker_Test.each { m ->
        def pid = id(m.patient_id)
        def mid = id(m.tumor_marker_test_id)
        def ccid = conditionOf(pid, id(m.cancer_condition_id))
        def ep = episodeOf('tumormarkertest', mid) ?: episodeOf('procedure', id(m.procedure_id)) ?:
            (ccid ? episodeOf('cancercondition', ccid) : null)
        emit('TumorMarkerTest', [Identifier: "${code}${pid}_tumorMarkerTest_${mid}".toString(), Patient_Identifier: pid,
            TumorMarkerTest_ValueAsNumber: text(m.tumor_marker_test_value_as_number),
            TumorMarkerTest_Date: date(m.tumor_marker_test_date)] +
            episodeFields(ep) +
            coded('TumorMarkerTest_Category', m.tumor_marker_test_category) +
            coded('TumorMarkerTest_Code', m.tumor_marker_test_code) +
            coded('TumorMarkerTest_ValueAsConcept', m.tumor_marker_test_value_as_concept) +
            coded('TumorMarkerTest_ValueUnit', m.tumor_marker_test_value_unit))
    }

    // no ingestion table holds them yet
    if (data.Medical_History) skipped['medical history records (no ingestion table)'] += data.Medical_History.size()

    def counts = rows.countBy { it.Entity }
    def summary = ("${known.size()} files joined into ${rows.size()} records ${counts}" +
        (skipped ? ", left out: ${skipped}" : '') + (missing ? ", missing files: ${missing}" : '')).toString()
    log.info("${code}: ${summary}")

    def output = ([COLUMNS.join(',')] + rows.collect { r -> COLUMNS.collect { csvValue(r[it]) }.join(',') }).join('\n') + '\n'

    bundle = session.create(known*.flowFile)
    bundle = session.write(bundle, { outputStream ->
        outputStream.write(output.getBytes(StandardCharsets.UTF_8))
    } as OutputStreamCallback)
    bundle = session.putAllAttributes(bundle, [
        filename      : "${code}_relational_bundle.csv".toString(),
        datasetId     : code,
        bundle_files  : known*.filename.join(','),
        bundle_summary: summary])
    session.transfer(bundle, REL_SUCCESS)
    session.remove(known*.flowFile)

} catch (Exception e) {
    if (bundle != null) session.remove(bundle)
    failAll(known, ("Could not join the relational CSV files ${known*.filename}: " +
        "${e.class.simpleName}: ${e.message}").toString())
}
