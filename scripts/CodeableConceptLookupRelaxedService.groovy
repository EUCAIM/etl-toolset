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
                } else if (value.startsWith("omop:")) {
                    // concept with omop ID
                    def omopId = value.toString().substring("omop:".length()).trim()
                    def code = lookupOmopConceptCode(conn, omopId, "${property}")
                    if (code != null) {
                        result["${property}"] = code
                    } else {
                        log.warn("CodeableConceptsLookupRelaxedService.lookup - NO OMOP MATCH for property '${property}': " +
                            "OMOP concept id '${omopId}' is not in concept_external_mapping. " +
                            "Stored as 'omop_id:${omopId}'. Add the mapping or correct the value.")
                        result["${property}"] = "omop_id:" + omopId
                    }
                } else if (value.startsWith("code:")) {
                    // concept with omop ID
                    result["${property}"] = "omop_id:" + value.toString().substring("code:".length())
                } else if (value.toString() ==~ /^[A-Za-z][A-Za-z0-9_-]*:[^\s]+$/) {
                    // pattern for a different coding system i.e. snomed:1234
                    result["${property}"] = value.toString().trim()
                    log.debug("CodeableConceptsLookupRelaxedService.lookup - property '${property}' value '${value}' is already a qualified code")
                } else if (isConceptCode(conn, value.toString())) {
                    result["${property}"] = value.toString().trim()
                    log.debug("CodeableConceptsLookupRelaxedService.lookup - property '${property}' value '${value}' is already a concept_code")
                } else {
                    def sql = """
                    SELECT c.concept_code, c.concept_name
                    FROM eucaim_hyperontology_codes.concept c
                    WHERE upper(c.concept_name) LIKE ?
                    ORDER BY (upper(c.concept_name) = upper(?)) DESC,
                             length(c.concept_name),
                             c.concept_id
                    """
                    // The exact name goes first; among the substring
                    // matches the shortest name is the closest to what was written.

                    def pstmt = conn.prepareStatement(sql)
                    pstmt.setString(1, "%" + value.toString().toUpperCase() + "%")
                    pstmt.setString(2, value.toString())
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
    
    // exact, case-insensitive match against concept_code: a code is never a substring guess
    private static boolean isConceptCode(Connection conn, String value) {
        def pstmt = conn.prepareStatement("SELECT 1 FROM eucaim_hyperontology_codes.concept c WHERE upper(c.concept_code) = upper(?) LIMIT 1")
        try {
            pstmt.setString(1, value.trim())
            def rs = pstmt.executeQuery()
            try { return rs.next() } finally { rs.close() }
        } finally {
            pstmt.close()
        }
    }

    private String lookupOmopConceptCode(Connection conn, String omopId, String property) {
        def sql = """
        SELECT c.concept_code
        FROM eucaim_hyperontology_codes.concept_external_mapping m
        JOIN eucaim_hyperontology_codes.concept c ON c.concept_id = m.concept_id
        WHERE m.external_vocabulary = 'OMOP_CONCEPT_ID'
          AND m.external_code = ?
        ORDER BY c.concept_id
        """
        def pstmt = conn.prepareStatement(sql)
        try {
            pstmt.setString(1, omopId)
            def rs = pstmt.executeQuery()
            try {
                if (!rs.next()) return null
                def code = rs.getString("concept_code")
                if (rs.next()) {
                    log.warn("CodeableConceptsLookupRelaxedService.lookup - AMBIGUOUS OMOP id '${omopId}' for property " +
                        "'${property}': it maps to more than one EUCAIM concept. Using " +
                        "'${code}', the first one loaded. Disambiguate it in " +
                        "eucaim_hyperontology_codes.concept_external_mapping.")
                }
                return code
            } finally { rs.close() }
        } finally { pstmt.close() }
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
