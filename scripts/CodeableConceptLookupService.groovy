import org.apache.nifi.controller.ControllerServiceInitializationContext
import org.apache.nifi.annotation.lifecycle.OnEnabled
import org.apache.nifi.controller.ConfigurationContext
import org.apache.nifi.reporting.InitializationException
import org.apache.nifi.dbcp.DBCPService
import java.sql.*

class CodeableConceptsLookupService implements LookupService<Map<String, Object>> {

    final String ID = UUID.randomUUID().toString()
    final static String dbcpServiceName = "dbcpService"

   DBCPService dbcpService
    ComponentLog log

    static final PropertyDescriptor DBCP_SERVICE = new PropertyDescriptor.Builder()
            .name(dbcpServiceName)
            .identifiesControllerService(DBCPService)
            .required(true)
            .build()

    @OnEnabled
    void onEnabled(final ConfigurationContext context) {
        dbcpService = context.getProperty(DBCP_SERVICE)
                             .asControllerService(DBCPService)

        log.info("DBCPService initialized: ${dbcpService != null}")
    }

    @Override
    Optional<Map<String, Object>> lookup(Map<String, Object> coordinates) {
        log.debug("CodeableConceptsLookupService.lookup - coordinates values: ${coordinates}")

         if (dbcpService == null) {
            log.error("CodeableConceptsLookupService.lookup - DBCPService not initialized.")
            return Optional.empty()
        }

        def input = coordinates.get("lookup_batch").toMap()
        def result = [:]

        Connection conn = dbcpService.getConnection()
        if (conn == null) {
            // used to be Optional.empty()['lookup_batch'], which throws instead
            // of returning, hiding the real cause behind a Groovy error
            log.error("CodeableConceptsLookupService.lookup - Connection not initialized.")
            return Optional.empty()
        }

        try {
            input.each { property, value ->
                if (!value) {
                    result["${property}"] = null
                    log.debug("CodeableConceptsLookupService.lookup - null value for property '${property}'")
                } else if (value.startsWith("code:")){
                    result["${property}"] = value
                } else {
                    def sql = """
                    SELECT c.concept_code
                    FROM eucaim_hyperontology_codes.concept c
                    WHERE c.concept_name = ?
                    """

                    def pstmt = conn.prepareStatement(sql)
                    pstmt.setString(1, value.toString())
                    def rs = pstmt.executeQuery()

                    log.debug("CodeableConceptsLookupService.lookup - property '${property}', value '${value}'")

                    if (rs.next()) {
                        def code = rs.getString("concept_code")
                        result["${property}"] = code
                    } else {
                        // this is the silent mapping failure: the literal string
                        // below travels downstream as if it were a valid code
                        log.warn("CodeableConceptsLookupService.lookup - NO MATCH for property " +
                            "'${property}' with value '${value}'. It is stored as NOT FOUND. " +
                            "Add the term to eucaim_hyperontology_codes.concept or correct the mapping.")
                        result["${property}"] = "NOT FOUND"
                    }
                rs.close()
                pstmt.close()
                }

                
            }
        } catch (Exception e) {
            log.error("CodeableConceptsLookupService.lookup - ${e.class.simpleName}: ${e.message}. " +
                "Coordinates were: ${coordinates}", e)
            return Optional.empty()
        } finally {
            if (conn != null) conn.close()
        }

        log.debug("CodeableConceptsLookupService.lookup - result values: ${result}")

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
    def onDisabled() {
      log.info("CodeableConceptsLookupService.onDisabled")
      //conn?.close()
    }

    def setLogger(logger) {
        log = logger
    }
}

lookupService = new CodeableConceptsLookupService()
