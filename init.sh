#!/bin/bash
echo "****Starting eucaim startup script ****"

#install jq to parse json
pip install jq --break-system-packages

#Wait for NiFi to start
registryIp=$(getent hosts nifi_registry | awk '{ print $1 }')

sleep 60

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

#Force enable of  StagingDBCPConnectionPool service
processGroupID="896a4a36-7cc4-3592-b1a9-8a5d5589d4a3"
enableProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID)
enableServices=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID/controller-services)
startProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"RUNNING\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID)
transmittingProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"disconnectedNodeAcknowledged\":false,\"state\":\"TRANSMITTING\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID/run-status)
echo "**** Force flow outcome ->  $transmittingProcessGroup"


processGroupID=$(echo "$processGroup" | jq -r '.id')

enableProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID)
enableServices=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID/controller-services)
startProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"RUNNING\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID)
transmittingProcessGroup=$(curl -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $token" -k -d "{\"disconnectedNodeAcknowledged\":false,\"state\":\"TRANSMITTING\"}" https://nifi:8443/nifi-api/flow/process-groups/$processGroupID/run-status)
echo "**** Flow insertion outcome ->  $transmittingProcessGroup"




((index+=450))
done


#Force enable of StagingDBCPConnectionPool service for each "loop03" processGroup
echo "Querying..."
response=$(curl -s -k -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  "https://nifi:8443/nifi-api/process-groups/root/process-groups")
echo
echo "Existing process groups:"
echo "$response" | jq -r '.processGroups[] | "\(.component.id)\t\(.component.name)"'

processGroupIDs=$(echo "$response" | jq -r '.processGroups[] | "\(.component.id)\t\(.component.name)"'   | grep "Clinical_data_loop03_" | awk '{print $1}')

for processGroupID in $processGroupIDs; do
  echo "Procesando Process Group ID: $processGroupID"

  # Habilitar el grupo
  curl -s -X PUT -H 'Content-Type: application/json' \
       -H "Authorization: Bearer $token" -k \
       -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\"}" \
       "https://nifi:8443/nifi-api/flow/process-groups/$processGroupID"

  # Habilitar sus controller services
  curl -s -X PUT -H 'Content-Type: application/json' \
       -H "Authorization: Bearer $token" -k \
       -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"ENABLED\"}" \
       "https://nifi:8443/nifi-api/flow/process-groups/$processGroupID/controller-services"

  # Arrancar el grupo
  curl -s -X PUT -H 'Content-Type: application/json' \
       -H "Authorization: Bearer $token" -k \
       -d "{\"id\":\"$processGroupID\",\"disconnectedNodeAcknowledged\":false,\"state\":\"RUNNING\"}" \
       "https://nifi:8443/nifi-api/flow/process-groups/$processGroupID"

  echo "✅ Process Group $processGroupID activado correctamente"
done