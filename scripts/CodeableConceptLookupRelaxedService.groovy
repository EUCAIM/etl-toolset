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
    ControllerServiceInitializationContext initContext = null

    // NiFi re-evaluates this script on every validation pass (BaseScriptedLookupService.customValidate
    // always calls setup()), which builds a brand new instance of this class and calls initialize() on
    // it, but never onEnabled() again. The DBCPService injected when the service was enabled was
    // therefore lost on the first validation that ran after the enabling, and from then on every lookup
    // failed with "DBCPService not initialized". The service resolved in onEnabled is published in a
    // JVM-wide registry keyed by the component id, so a reloaded instance recovers it in initialize().
    static final String DBCP_CACHE_PREFIX = "eucaim.nifi.dbcpService."

    private static void cacheDbcpService(String componentId, DBCPService service) {
        if (componentId && service != null) {
            System.getProperties().put(DBCP_CACHE_PREFIX + componentId, service)
        }
    }

    private static DBCPService cachedDbcpService(String componentId) {
        componentId ? (DBCPService) System.getProperties().get(DBCP_CACHE_PREFIX + componentId) : null
    }

    static final PropertyDescriptor DBCP_SERVICE = new PropertyDescriptor.Builder()
            .name(dbcpServiceName)
            .identifiesControllerService(DBCPService)
            .required(true)
            .build()

    @OnEnabled
    void onEnabled(final ConfigurationContext context) {
        dbcpService = context.getProperty(DBCP_SERVICE)
                             .asControllerService(DBCPService)
        cacheDbcpService(initContext?.identifier, dbcpService)

        log.info("DBCPService initialized: ${dbcpService != null}")
    }

    @Override
    Optional<Map<String, Object>> lookup(Map<String, Object> coordinates) {
        log.debug("CodeableConceptsLookupRelaxedService.lookup - coordinates values: ${coordinates}")

        if (dbcpService == null) {
            // onEnabled ran on an instance that a later script reload has replaced
            dbcpService = cachedDbcpService(initContext?.identifier)
        }

        if (dbcpService == null) {
            log.error("CodeableConceptsLookupRelaxedService.lookup - DBCPService not initialized.")
            return Optional.empty()
        }

        def input = coordinates.get("lookup_batch").toMap()
        def result = [:]

        Connection conn = dbcpService.getConnection()
        if (conn == null) {
            // used to be Optional.empty()['lookup_batch'], which throws instead
            // of returning, hiding the real cause behind a Groovy error
            log.error("CodeableConceptsLookupRelaxedService.lookup - Connection not initialized.")
            return Optional.empty()
        }

        try {
            input.each { property, value ->
                if (!value) {
                    result["${property}"] = null
                    log.debug("CodeableConceptsLookupRelaxedService.lookup - null value for property '${property}'")
                } else {
                    // concept_name is selected so the substring match that was
                    // actually applied can be reported, not just its code
                    def sql = """
                    SELECT c.concept_code, c.concept_name
                    FROM eucaim_hyperontology_codes.concept c
                    WHERE upper(c.concept_name) LIKE ?
                    """

                    def pstmt = conn.prepareStatement(sql)
                    pstmt.setString(1, "%" + value.toString().toUpperCase() + "%")
                    def rs = pstmt.executeQuery()

                    log.debug("CodeableConceptsLookupRelaxedService.lookup - property '${property}', value '${value}'")

                    if (rs.next()) {
                        def code = rs.getString("concept_code")
                        def matched = rs.getString("concept_name")
                        result["${property}"] = code
                        // a relaxed match is a guess: say what it resolved to so a
                        // wrong code can be spotted without re-running the pipeline
                        if (!matched.equalsIgnoreCase(value.toString())) {
                            log.warn("CodeableConceptsLookupRelaxedService.lookup - RELAXED MATCH for " +
                                "property '${property}': value '${value}' resolved to concept " +
                                "'${matched}' (${code}) by substring match. Confirm this is correct.")
                        }
                    } else {
                        // this is the silent mapping failure: the literal string
                        // below travels downstream as if it were a valid code
                        log.warn("CodeableConceptsLookupRelaxedService.lookup - NO MATCH for property " +
                            "'${property}' with value '${value}'. It is stored as NOT FOUND. " +
                            "Add the term to eucaim_hyperontology_codes.concept or correct the mapping.")
                        result["${property}"] = "NOT FOUND"
                    }
                rs.close()
                pstmt.close()
                }

                
            }
        } catch (Exception e) {
            log.error("CodeableConceptsLookupRelaxedService.lookup - ${e.class.simpleName}: ${e.message}. " +
                "Coordinates were: ${coordinates}", e)
            return Optional.empty()
        } finally {
            if (conn != null) conn.close()
        }

        log.debug("CodeableConceptsLookupRelaxedService.lookup - result values: ${result}")

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
        initContext = ctx
        // this instance is brand new, so take back the service the component already resolved
        dbcpService = cachedDbcpService(ctx?.identifier)
        log.info("CodeableConceptsLookupService.initialize - dbcpService recovered from a previous enable: ${dbcpService != null}")
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
