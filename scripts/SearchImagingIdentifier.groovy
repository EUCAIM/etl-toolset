import org.apache.nifi.controller.ControllerServiceInitializationContext
import org.apache.nifi.annotation.lifecycle.OnEnabled
import org.apache.nifi.controller.ConfigurationContext
import org.apache.nifi.reporting.InitializationException
import org.apache.nifi.dbcp.DBCPService
import java.sql.*

class ImagingIdentifierLookupService implements LookupService<String> {

    final String ID = UUID.randomUUID().toString()
    final static String dbcpServiceName = "dbcpService"

    public static final PropertyDescriptor DBCP_SERVICE = new PropertyDescriptor.Builder()
            .name(dbcpServiceName)
            .description("The Controller Service that is used to obtain connection to database")
            .required(true)
            .identifiesControllerService(DBCPService)
            .build()

    DBCPService dbcpService
    ComponentLog log = null

    @Override
    Optional<Map<String, String>> lookup(Map<String, String> coordinates) {
        log.debug("SearchImagingIdentifier.lookup - coordinates values: ${coordinates}")

         if (dbcpService == null) {
            log.error("SearchImagingIdentifier.lookup - DBCPService not initialized.")
            return Optional.empty()
        }

        def input = coordinates.get("lookup_batch").toMap()
        def result = [:]

        Connection conn = dbcpService.getConnection()
        if (conn == null) {
            log.error("SearchImagingIdentifier.lookup - Connection not initialized.")
            return Optional.empty()
        }

        try {
            
            def studyUID = input.StudyUID
            def patientID = input.PatientID
            def datasetID = input.DatasetID
            def imagingTimepoint = Integer.parseInt(input.ImagingTimepoint)

            log.debug("SearchImagingIdentifier.lookup - studyUID=${studyUID}, patientID=${patientID}, " +
                "datasetID=${datasetID}, imagingTimepoint=${imagingTimepoint}")

            def sql = """
                    SELECT  i.procedureidentifier 
                    FROM eucaim_cdm_ingestion.ImagingProcedure i               
                    JOIN eucaim_cdm_ingestion.PrimaryCancerCondition pcc ON i.PrimaryCancerConditionIdentifier = pcc.Identifier 
                    JOIN eucaim_cdm_ingestion.CancerPatient cp ON pcc.PatientIdentifier = cp.Identifier
                    WHERE lower(cp.DatasetIdentifier) = ? and pcc.Patientidentifier = ? and i.ImagingTimepoint = ?; 
                """

            def pstmt = conn.prepareStatement(sql)
            pstmt.setString(1, datasetID.toString())
            pstmt.setString(2, patientID.toString())
            pstmt.setInt(3, imagingTimepoint)
            def rs = pstmt.executeQuery()

            if (rs.next()) {
                def identifier = rs.getString("procedureidentifier")
                result["imagingIdentifier"] = identifier
            } else {
                log.warn("SearchImagingIdentifier.lookup - NO MATCH for datasetID='${datasetID}', " +
                    "patientID='${patientID}', imagingTimepoint=${imagingTimepoint} " +
                    "(studyUID='${studyUID}'). The timepoint is stored as NOT FOUND. Check that the " +
                    "clinical data and the DICOM metadata for this patient were ingested first.")
                result["imagingIdentifier"] = "NOT FOUND"
            }

            rs.close()
            pstmt.close()

        } catch (Exception e) {
            // a lookup error and a genuinely absent record both used to end up as
            // "NOT FOUND" at WARN, which made them impossible to tell apart
            log.error("SearchImagingIdentifier.lookup - ${e.class.simpleName}: ${e.message}. " +
                "This is a lookup FAILURE, not an absent record. Coordinates were: ${coordinates}", e)
            result["imagingIdentifier"] = "NOT FOUND"
        } finally {
            if (conn != null) conn.close()
        }

        log.debug("SearchImagingIdentifier.lookup - result values: ${result}")

        return result.isEmpty() ? Optional.empty() : Optional.of(result)
    }
    
    Set<String> getRequiredKeys() {
        return java.util.Collections.emptySet();
    }
    
    @Override
    Class<?> getValueType() {
        return String
    }

    @Override
    void initialize(ControllerServiceInitializationContext ctx) {
        log.info("SearchImagingIdentifier.initialize")
    }

    @Override
    Collection<ValidationResult> validate(ValidationContext context) {
       null
    }

    @Override
    PropertyDescriptor getPropertyDescriptor(String name) {
       name.equals(DBCP_SERVICE.name) ? DBCP_SERVICE : null
    }

    @Override
    void onPropertyModified(PropertyDescriptor descriptor, String oldValue, String newValue) {
    }

    @Override
    List<PropertyDescriptor> getPropertyDescriptors() {
        return [DBCP_SERVICE];
    }

    @Override
    String getIdentifier() {
       ID
    }

    @OnEnabled
    void onEnabled(final ConfigurationContext configurationContext) {
        log.info("SearchImagingIdentifier.onEnabled")

        dbcpService = configurationContext.getProperty(DBCP_SERVICE)?.asControllerService(DBCPService)

        if (dbcpService == null) {
         log.error("SearchImagingIdentifier.onEnabled - Could not obtain dbcpService in onEnabled.")
        } else {
         log.info("SearchImagingIdentifier.onEnabled - dbcpService has been set correctly.")
        }
    }

    def onDisabled() {
      log.info("SearchImagingIdentifier.onDisabled")
      //conn?.close()
    }

    def setLogger(logger) {
        log = logger
    }
}

lookupService = new ImagingIdentifierLookupService()