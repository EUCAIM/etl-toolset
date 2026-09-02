#!/bin/bash
echo "****Starting eucaim startup script ****"

#remove flag file
if [ -f /tmp/init_done ]; then
    rm /tmp/init_done
fi

#install jq to parse json
pip install jq --break-system-packages

#Wait for NiFi to start
registryIp=$(getent hosts nifi_registry | awk '{ print $1 }')

#sleep 60
while ! curl -sfk https://nifi:8443/nifi > /dev/null; do
    echo "still waiting for nifi to start"
    sleep 5
done
echo "** Applying changes ** "
bucketDelete=$(curl -X GET http://nifi_registry:18080/nifi-registry-api/buckets)

bucketToDelete=$(echo "$bucketDelete" | jq -r '.[0].identifier')
echo "Old bucket found! Need to delete $bucketToDelete"
deleting=$(curl -X DELETE http://nifi_registry:18080/nifi-registry-api/buckets/$bucketToDelete?version=0)



bucketCreate=$(curl -X POST -d '{"name":"ETL3","description":"","allowPublicRead":false,"revision":{"version":0}}' -H 'Content-Type: application/json'  http://nifi_registry:18080/nifi-registry-api/buckets)
bucketHref=$(echo "$bucketCreate" | jq -r '.link.href')

# Get the token
token=$(curl -X POST -k -H 'Content-Type: application/x-www-form-urlencoded' -d "username=$SINGLE_USER_CREDENTIALS_USERNAME&password=$SINGLE_USER_CREDENTIALS_PASSWORD" https://nifi:8443/nifi-api/access/token)
# Add NiFi Registry client
registry=$(curl -X POST -k \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "{
    \"revision\": {
      \"clientId\": \"a8a925f9-696c-4a57-8e4c-8a222fc2c86f\",
      \"version\": 0
    },
    \"disconnectedNodeAcknowledged\": false,
    \"component\": {
      \"name\": \"RegistryConnection\",
      \"type\": \"org.apache.nifi.registry.flow.NifiRegistryFlowRegistryClient\",
      \"bundle\": {
        \"group\": \"org.apache.nifi\",
        \"artifact\": \"nifi-flow-registry-client-nar\",
        \"version\": \"2.3.0\"
      },
      \"properties\": {
        \"url\": \"http://$registryIp:18080/nifi-registry/\",
        \"ssl-context-service\": null
      }
    }
    }" \
https://nifi:8443/nifi-api/controller/registry-clients)


# Download flows
# Repository URL
REPO_URL="https://github.com/EUCAIM/etl-mappings"

# Extract owner and repo from URL
OWNER=$(echo "$REPO_URL" | awk -F'github.com/' '{print $2}' | cut -d'/' -f1)
REPO=$(echo "$REPO_URL" | awk -F'github.com/' '{print $2}' | cut -d'/' -f2)

### Whether to pull the mappings from the repository at all. Defaults to true,
### which is the behaviour every existing deployment already has.
###
### The download overwrites /flows, which is bind-mounted to ./flows, so a
### mapping edited locally goes back to the published version on the next
### start. Turning this off keeps whatever is already in ./flows, which is what
### you want while adjusting a mapping, and on a node with no access to GitHub.
case "$(printf '%s' "${DOWNLOAD_FLOWS:-true}" | tr '[:upper:]' '[:lower:]')" in
    false|no|0|off) DOWNLOAD_FLOWS=false ;;
    *)              DOWNLOAD_FLOWS=true  ;;
esac

# Convert datasetsList to array
IFS=',' read -r -a DATASETS <<< "$DATASETSLIST"

if [ "$DOWNLOAD_FLOWS" != true ]; then
    echo "Flow download disabled (DOWNLOAD_FLOWS=false): using the mappings already in /flows"
else

    # Authenticate when a token is available: unauthenticated calls to the GitHub
    # API are capped at 60 per hour and per IP, and CI runners share their IP, so
    # the cap is often already spent by someone else
    AUTH_HEADER=()
    if [ -n "$GITHUB_TOKEN" ]; then
        AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
        echo "Using an authenticated GitHub API"
    fi

    # Get default branch
    DEFAULT_BRANCH=$(curl -s "${AUTH_HEADER[@]}" "https://api.github.com/repos/${OWNER}/${REPO}" \
        | jq -r '.default_branch')

    echo "Repository: ${OWNER}/${REPO}"
    echo "Branch: ${DEFAULT_BRANCH}"

    # A failed API call yields "null" here, the tree request below then 404s and the
    # whole download loop ends up doing nothing while returning success
    if [ -z "$DEFAULT_BRANCH" ] || [ "$DEFAULT_BRANCH" = "null" ]; then
        echo "ERROR: could not resolve the default branch of ${OWNER}/${REPO}."
        echo "       The GitHub API answered:"
        curl -s "${AUTH_HEADER[@]}" "https://api.github.com/repos/${OWNER}/${REPO}" | head -5
        echo "       Set DOWNLOAD_FLOWS=false to start from the mappings already in ./flows."
        ### this script runs in the background while NiFi keeps going, so aborting
        ### is invisible from outside: leave a marker for whoever is waiting
        touch /tmp/init_failed
        exit 1
    fi

    if [ -z "$DATASETSLIST" ]; then
        echo "DATASETSLIST está vacía. No se descargará ningún fichero."
    else

	# Get file list
	curl -s "${AUTH_HEADER[@]}" \
	  "https://api.github.com/repos/${OWNER}/${REPO}/git/trees/${DEFAULT_BRANCH}?recursive=1" \
	  | jq -r '.tree[] | select(.type=="blob") | .path' |
	while read -r FILE; do

		BASENAME=$(basename "$FILE")

		for DATASET in "${DATASETS[@]}"; do

			if [[ "$BASENAME" == "${DATASET}"* ]]; then
				echo "Downloading: $FILE"

				if ! curl -sSL --fail -o "/flows/${BASENAME}" \
				  "https://raw.githubusercontent.com/${OWNER}/${REPO}/${DEFAULT_BRANCH}/${FILE}"; then
					echo "ERROR: could not download ${BASENAME} into /flows"
				fi

				break
			fi
		done
	done
    fi
fi

echo "Download flows ended"

### Runs whether or not the mappings were downloaded: with the download off it
### is the check that the operator did put every selected mapping in ./flows.
if [ -n "$DATASETSLIST" ]; then
    MISSING=""
    for DATASET in "${DATASETS[@]}"; do
        if ! ls /flows/"${DATASET}"* >/dev/null 2>&1; then
            MISSING="${MISSING} ${DATASET}"
        fi
    done
    if [ -n "$MISSING" ]; then
        if [ "$DOWNLOAD_FLOWS" = true ]; then
            echo "ERROR: no mapping was downloaded for:${MISSING}"
            echo "       Repository ${OWNER}/${REPO}, branch ${DEFAULT_BRANCH}."
        else
            echo "ERROR: no mapping is present in ./flows for:${MISSING}"
            echo "       The download is disabled (DOWNLOAD_FLOWS=false), so every dataset"
            echo "       in datasetsList must already have its mapping file in ./flows."
        fi
        echo "       Files currently in /flows:"
        ls -1 /flows | sed 's/^/         /'
        touch /tmp/init_failed
        exit 1
    fi
    echo "Mappings verified: every dataset in DATASETSLIST has its flow"
fi


#Add flows to registry
FOLDER="/flows"
index=0
for file in "$FOLDER"/*.json; do
    filename=$(basename "$file")
    flow=$(curl -X POST -d "{\"name\":\"$filename\",\"description\":\"\"}"  -H 'Content-Type: application/json'  http://nifi_registry:18080/nifi-registry-api/$bucketHref/flows )
    hrefFlow=$(echo "$flow" | jq -r '.link.href')
    ret=$(curl -X POST -d @$file  -H 'Content-Type: application/json' http://nifi_registry:18080/nifi-registry-api/$hrefFlow/versions/import)
    #Import flow to nifi
    registryID=$(echo "$registry" | jq -r '.id')
    bucketID=$(echo "$ret" | jq -r '.bucket.identifier')
    flowID=$(echo "$ret" | jq -r '.flow.identifier')
    processGroup=$(curl -X POST -k -d "{
    \"revision\": {
        \"clientId\": \"1\",
        \"version\": 0
    },
    \"disconnectedNodeAcknowledged\": false,
    \"component\": {
        \"position\": {
            \"y\": 0,
            \"x\": $index
        },
        \"versionControlInformation\": {
            \"registryId\": \"$registryID\",
            \"bucketId\": \"$bucketID\",
            \"flowId\": \"$flowID\",
            \"version\": \"1\"
        }
    }
    }" -H 'Content-Type: application/json' -H "Authorization: Bearer $token" https://nifi:8443/nifi-api/process-groups/root/process-groups?parameterContextHandlingStrategy=KEEP_EXISTING)
    
    
    processGroupID=$(echo "$processGroup" | jq -r '.id')

    # Get all controller services in this process group
    SERVICES=$(curl -s -k -H "Authorization: Bearer $token" \
    "https://nifi:8443/nifi-api/flow/process-groups/$processGroupID/controller-services")
    
       

    # Find DBConnectionPool instances
    LOOKUP_SERVICES=$(echo "$SERVICES" | jq -r '.controllerServices[] | select(.component.name=="DBConnectionPool") | .component.id')
    for serviceId in $LOOKUP_SERVICES; do
        echo "----- Found DBConnectionPool: $serviceId"
        SERVICE_INFO=$(curl -s -k -H "Authorization: Bearer $token" \
        "https://nifi:8443/nifi-api/controller-services/$serviceId")
        
        REVISION=$(echo "$SERVICE_INFO" | jq '.revision.version')
        ENABLE_RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" -k \
            -d "{\"revision\":{\"version\":$REVISION},\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\",\"uiOnly\":false}" \
        "https://nifi:8443/nifi-api/controller-services/$serviceId/run-status")
        echo "Service $serviceId enabling..."
        
        while true; do
            STATUS=$(curl -s -k -H "Authorization: Bearer $token" \
                "https://nifi:8443/nifi-api/controller-services/$serviceId" \
            | jq -r '.status.runStatus')
            
            VALIDATION=$(curl -s -k -H "Authorization: Bearer $token" \
                "https://nifi:8443/nifi-api/controller-services/$serviceId" \
            | jq -r '.status.validationStatus')
            
            echo "Checking Status: $STATUS / Validation: $VALIDATION"
            
            if [[ "$STATUS" == "ENABLED" && "$VALIDATION" == "VALID" ]]; then
                echo "Controller service fully enabled"
                break
            fi
            
            sleep 2
        done
    done  


    # Find ScriptedLookupService instances
    LOOKUP_SERVICES=$(echo "$SERVICES" | jq -r '.controllerServices[] | select(.component.name=="ScriptedLookupService") | .component.id')
    for serviceId in $LOOKUP_SERVICES; do
        echo "----- Found ScriptedLookupService: $serviceId"
        SERVICE_INFO=$(curl -s -k -H "Authorization: Bearer $token" \
        "https://nifi:8443/nifi-api/controller-services/$serviceId")
        
        REVISION=$(echo "$SERVICE_INFO" | jq '.revision.version')
        ENABLE_RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" -k \
            -d "{\"revision\":{\"version\":$REVISION},\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\",\"uiOnly\":false}" \
        "https://nifi:8443/nifi-api/controller-services/$serviceId/run-status")
        echo "Service $serviceId enabling..."
        
        while true; do
            STATUS=$(curl -s -k -H "Authorization: Bearer $token" \
                "https://nifi:8443/nifi-api/controller-services/$serviceId" \
            | jq -r '.status.runStatus')
            
            VALIDATION=$(curl -s -k -H "Authorization: Bearer $token" \
                "https://nifi:8443/nifi-api/controller-services/$serviceId" \
            | jq -r '.status.validationStatus')
            
            echo "Checking Status: $STATUS / Validation: $VALIDATION"
            
            if [[ "$STATUS" == "ENABLED" && "$VALIDATION" == "VALID" ]]; then
                echo "Controller service fully enabled"
                break
            fi
            
            sleep 2
        done
    done 


    enableProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID)
    enableServices=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID/controller-services)
    startProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"RUNNING\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID)
    transmittingProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"disconnectedNodeAcknowledged\":false,\"state\":\"TRANSMITTING\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID/run-status)


    echo "**** Flow insertion outcome ->  $transmittingProcessGroup"
    

    ((index+=450))
done

### Reporting task that records in ProcessLog every file the ETL discarded.
###
### It lives at the controller level, not inside any process group, so it adds
### nothing to the mappings. NiFi keeps reporting tasks in conf/flow.json.gz,
### which is not a mounted volume, so it has to be recreated on every start just
### like the bucket and the registry client above.
REPORTING_TASK_NAME="ProvenanceToProcessLog"
### literal, not ${ETL_RESOURCES}: whether that property resolves Expression
### Language in a reporting task has not been confirmed, and the path is fixed
### by the volume in docker-compose anyway
ETL_FILES="/mnt/persistent-home/ETL-files"

existing=$(curl -s -k -H "Authorization: Bearer $token" \
    https://nifi:8443/nifi-api/flow/controller/reporting-tasks \
    | jq -r --arg n "$REPORTING_TASK_NAME" \
      '.reportingTasks[]? | select(.component.name==$n) | .id')

if [ -n "$existing" ]; then
    echo "Reporting task ${REPORTING_TASK_NAME} already present"
else
    created=$(curl -s -X POST -k -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $token" -d "{
        \"revision\": {\"clientId\": \"1\", \"version\": 0},
        \"disconnectedNodeAcknowledged\": false,
        \"component\": {
            \"type\": \"org.apache.nifi.reporting.script.ScriptedReportingTask\",
            \"bundle\": {\"group\": \"org.apache.nifi\", \"artifact\": \"nifi-scripting-nar\", \"version\": \"2.3.0\"},
            \"name\": \"${REPORTING_TASK_NAME}\"
        }}" https://nifi:8443/nifi-api/controller/reporting-tasks)

    taskID=$(echo "$created" | jq -r '.id')
    taskVersion=$(echo "$created" | jq -r '.revision.version')

    if [ -z "$taskID" ] || [ "$taskID" = "null" ]; then
        echo "ERROR: could not create the ${REPORTING_TASK_NAME} reporting task."
        echo "       NiFi answered: $(echo "$created" | head -c 300)"
        echo "       The pipelines still run: what is lost is the record of the files they discard."
    else
        configured=$(curl -s -X PUT -k -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $token" -d "{
            \"revision\": {\"clientId\": \"1\", \"version\": ${taskVersion}},
            \"disconnectedNodeAcknowledged\": false,
            \"component\": {
                \"id\": \"${taskID}\",
                \"name\": \"${REPORTING_TASK_NAME}\",
                \"schedulingStrategy\": \"TIMER_DRIVEN\",
                \"schedulingPeriod\": \"30 sec\",
                \"properties\": {
                    \"Script Engine\": \"Groovy\",
                    \"Script File\": \"${ETL_FILES}/scripts/ProvenanceToProcessLog.groovy\",
                    \"Module Directory\": \"${ETL_FILES}/postgresql-42.7.4.jar\"
                }
            }}" https://nifi:8443/nifi-api/reporting-tasks/${taskID})

        newVersion=$(echo "$configured" | jq -r '.revision.version')
        started=$(curl -s -X PUT -k -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $token" -d "{
            \"revision\": {\"clientId\": \"1\", \"version\": ${newVersion}},
            \"disconnectedNodeAcknowledged\": false,
            \"state\": \"RUNNING\"
            }" https://nifi:8443/nifi-api/reporting-tasks/${taskID}/run-status)

        state=$(echo "$started" | jq -r '.component.state // .status.runStatus // "UNKNOWN"')
        echo "Reporting task ${REPORTING_TASK_NAME} created and set to ${state}"
        if [ "$state" != "RUNNING" ]; then
            echo "       It did not start. NiFi answered: $(echo "$started" | head -c 300)"
        fi
    fi
fi

#create flag file to mark as completed
touch /tmp/init_done

echo "****eucaim startup script completed ****"
