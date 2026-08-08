#!/bin/bash
# Export Jenkins plugins and JCasC config from running instance

JENKINS_URL="http://gitops-jenkins-jenkins-dev-1941183696.us-east-1.elb.amazonaws.com"
USER="Immrdg"
PASS="Immrdg@21"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

COOKIE_JAR=$(mktemp)
CRUMB=$(curl -s -c "$COOKIE_JAR" -u "$USER:$PASS" "$JENKINS_URL/crumbIssuer/api/json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['crumb'])")

echo "=== Exporting plugins ==="
curl -s -b "$COOKIE_JAR" -u "$USER:$PASS" \
  -H "Jenkins-Crumb:$CRUMB" \
  --data-urlencode 'script=
def plugins = Jenkins.instance.pluginManager.plugins.collect { "${it.shortName}:${it.version}" }
plugins.sort().each { println it }
' "$JENKINS_URL/scriptText" > "$SCRIPT_DIR/plugins.txt"

echo "Saved $(wc -l < "$SCRIPT_DIR/plugins.txt") plugins to jenkins/plugins.txt"

echo ""
echo "=== Exporting JCasC config ==="
curl -s -b "$COOKIE_JAR" -u "$USER:$PASS" \
  -H "Jenkins-Crumb:$CRUMB" \
  "$JENKINS_URL/manage/configuration-as-code/export" > "$SCRIPT_DIR/jenkins.yaml"

echo "Saved JCasC to jenkins/jenkins.yaml"

rm -f "$COOKIE_JAR"
echo ""
echo "Done!"
