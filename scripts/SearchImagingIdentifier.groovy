import org.apache.nifi.controller.ControllerServiceInitializationContext
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
        log.info("SearchImagingIdentifier.lookup")
        log.info("SearchImagingIdentifier.lookup - coordinates values: ${coordinates}")

         if (dbcpService == null) {
            log.error("CodeableConceptsLookupService.lookup - DBCPService not initialized.")
            return Optional.empty()
        }

        def input = coordinates.get("lookup_batch").toMap()
        def result = [:]

        Connection conn = dbcpService.getConnection()
        if (conn == null) {
            log.error("SearchImagingIdentifier.lookup - Connection not initialized.")
            return Optional.empty()['lookup_batch']
        }

        try {
            
            def patientID = input.PatientID
            def datasetID = input.DatasetID

            log.info("patientID: " + patientID)
            log.info("datasetID: " + datasetID)

            def sql = """
                    SELECT  i.procedureidentifier 
                    FROM ImagingProcedure i
                    JOIN CancerPatient p ON (p.Identifier = i.patientidentifier  and p.datasetidentifier = i.datasetidentifier)
                    WHERE i.datasetIdentifier = ? and i.patientidentifier = ?; 
                """

            log.info(sql)

            def pstmt = conn.prepareStatement(sql)
            pstmt.setString(1, datasetID.toString())
            pstmt.setString(2, patientID.toString())
            def rs = pstmt.executeQuery()

            if (rs.next()) {
                log.info("SearchImagingIdentifier.lookup - Parsing result")
                def identifier = rs.getString("procedureidentifier")
                result["imagingIdentifier"] = identifier
            } else {
                result["imagingIdentifier"] = "NOT FOUND"
            }

            rs.close()
            pstmt.close()

        } catch (Exception e) {
            log.error("SearchImagingIdentifier.lookup - Lookup error: {}", [e.message])
            return Optional.empty()
        } finally {
            if (conn != null) conn.close()
        }

        log.info("SearchImagingIdentifier.lookup - result values: ${result}")

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

    def onEnabled(configurationContext) {
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