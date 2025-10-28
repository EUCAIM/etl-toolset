import org.apache.nifi.controller.ControllerServiceInitializationContext
import org.apache.nifi.reporting.InitializationException
import org.apache.nifi.dbcp.DBCPService
import java.sql.*

class SequenceLookupService implements LookupService<Map<String, Object>> {

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
    Optional<Map<String, Object>> lookup(Map<String, Object> coordinates) {
        log.info("CodeableConceptsLookupService.lookup")
        log.info("CodeableConceptsLookupService.lookup - coordinates values: ${coordinates}")

         if (dbcpService == null) {
            log.error("CodeableConceptsLookupService.lookup - DBCPService not initialized.")
            return Optional.empty()
        }

        def input = coordinates.get("lookup_batch").toMap()
        def result = [:]

        Connection conn = dbcpService.getConnection()
        if (conn == null) {
            log.error("CodeableConceptsLookupService.lookup - Connection not initialized.")
            return Optional.empty()['lookup_batch']
        }

        try {
            input.each { property, value ->
                if (!value) return

                def sql = """
                    SELECT c.concept_code
                    FROM eucaim_hyperontology_codes.concept c
                    WHERE c.concept_name = ?
                """

                log.info(sql)

                def pstmt = conn.prepareStatement(sql)
                pstmt.setString(1, value.toString())
                def rs = pstmt.executeQuery()

                log.info("CodeableConceptsLookupService.lookup - Executed query with value: " + value.toString())

                if (rs.next()) {
                    log.info("CodeableConceptsLookupService.lookup - Parsing one result")
                    def code = rs.getString("concept_code")
                    result["${property}"] = code
                } else {
                    result["${property}"] = "NOT FOUND"
                }

                rs.close()
                pstmt.close()
            }
        } catch (Exception e) {
            log.error("CodeableConceptsLookupService.lookup - Lookup error: {}", [e.message])
            return Optional.empty()
        } finally {
            if (conn != null) conn.close()
        }

        log.info("CodeableConceptsLookupService.lookup - result values: ${result}")

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
        log.info("CodeableConceptsLookupService.initialize")
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
        log.info("CodeableConceptsLookupService.onEnabled")

        dbcpService = configurationContext.getProperty(DBCP_SERVICE)?.asControllerService(DBCPService)

        if (dbcpService == null) {
         log.error("CodeableConceptsLookupService.onEnabled - Could not obtain dbcpService in onEnabled.")
        } else {
         log.info("CodeableConceptsLookupService.onEnabled - dbcpService has been set correctly.")
        }
    }

    def onDisabled() {
      log.info("CodeableConceptsLookupService.onDisabled")
      //conn?.close()
    }

    def setLogger(logger) {
        log = logger
    }
}

lookupService = new SequenceLookupService()
