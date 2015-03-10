#!/bin/bash

echo "Custom SCRIPTS_URI: " $SCRIPTS_URI
echo "Custom SCRIPTS_PROJECT: " $SCRIPTS_PROJECT
echo "Custom TRIGGER_WORKFLOW_JOB: "$TRIGGER_WORKFLOW_JOB
echo "Openshift SOURCE_URI: " $SOURCE_URI
echo "Openshift OPENSHIFT_CUSTOM_BUILD_BASE_IMAGE: " $OPENSHIFT_CUSTOM_BUILD_BASE_IMAGE

cd $JENKINS_HOME
function gclonecd(){
  # clone repo and cd to git repo but removing the '.git' from the directory name
  dirname=$(basename $1)
  len=${#dirname}-4
  git clone $1 && cd $(echo "${dirname:0:$len}")
}

gclonecd $SCRIPTS_URI

# Move scripts to jobs folder so they will be used to configure Jenkins when it starts
mv $SCRIPTS_PROJECT $JENKINS_HOME/jobs

# Launch Jenkins in the background
nohup /usr/local/bin/jenkins.sh &

JENKINS_URL=http://localhost:8080

echo "Waiting for Jenkins to start"

until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do
    printf '.'
    sleep 5
done

JOB_URL=$JENKINS_URL/job/$TRIGGER_WORKFLOW_JOB
JOB_STATUS_URL=${JOB_URL}/lastBuild/api/json

GREP_RETURN_CODE=0
cat
# Start the build
curl --output /dev/null --silent $JOB_URL/build?delay=0sec

# Poll every 5 seconds until the build is finished
while [ $GREP_RETURN_CODE -eq 0 ]
do
    sleep 5
    # Grep will return 0 while the build is running:
    curl --output /dev/null --silent $JOB_STATUS_URL | grep result\":null > /dev/null
    GREP_RETURN_CODE=$?
done

# Check if the build result was SUCCESS, exit script with error if not
IS_SUCCESS=$(curl $JOB_STATUS_URL | grep result\":\"SUCCESS)

if [[ $IS_SUCCESS -eq 0 ]]; then
	echo "Build failed"
	exit -1
else 
	echo "Build success"
	exit 0
fi
