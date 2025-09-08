JENKINS_URL="https://build-oci.dhsie.hawaii.gov"
JENKINS_USER="chwang"
JENKINS_PASSWORD_OR_TOKEN='h%4"[r\LXK|?GO|t'
JENKINS_CLI=./jenkins-cli.jar

if [ "$#" -ne 1 ]; then
 echo "Usage: $0 <arg1>"
 exit 1
fi
echo "You provided $# arguments."

# CRUMB
CRUMB=$(curl -s --cookie-jar /tmp/cookies -u "$JENKINS_USER:$JENKINS_PASSWORD_OR_TOKEN" \
    "$JENKINS_URL/crumbIssuer/api/json" | 
    grep -Eo '"crumb"[^,]*' | grep -Eo '[^:]*$')
### jq -r '.crumb')

### echo "Generated CRUMB: $CRUMB"
CRUMB2=$(echo $CRUMB | sed 's/"//g')
echo "Generated CRUMB2: $CRUMB2"

# New Token
NEW_TOKEN_NAME="NewToken"

ACCESS_TOKEN=$(curl  -X POST -H "Jenkins-Crumb:$CRUMB2" \
    --cookie /tmp/cookies -u "$JENKINS_USER:$JENKINS_PASSWORD_OR_TOKEN" \
    "$JENKINS_URL/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" \
    --data-urlencode "newTokenName=$NEW_TOKEN_NAME" )
echo "Generated token: $ACCESS_TOKEN"

TKN=$(echo $ACCESS_TOKEN | grep -oP '"tokenValue":\s*"\K[^"]+')
UUID=$(echo $ACCESS_TOKEN | grep -oP '"tokenUuid":\s*"\K[^"]+')

echo "Generated token: $TKN"
echo "Generated token UUID: $UUID"

AUTH="$JENKINS_USER:$TKN"

#UPDATE_LIST=$( java -jar $JENKINS_CLI -s $JENKINS_URL -auth $AUTH list-plugins script-security | grep -e ')$' | awk '{ print $1 }' )

UPDATE_LIST=$1
echo "${UPDATE_LIST//__/ }"
PLUGINS=${UPDATE_LIST//__/ }

if [ ! -z "${PLUGINS}" ]; then
echo "Updating Jenkins Plugins: ${PLUGINS}"
java -jar $JENKINS_CLI -s $JENKINS_URL -auth $AUTH install-plugin ${PLUGINS}
# Jenkins Safe restart
##java -jar $JENKINS_CLI -s $JENKINS_URL -auth $AUTH safe-restart
else
echo "No upgradable pluggin."
fi

