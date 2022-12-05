#!/usr/bin/env bash


# print usage
echo '
 Usage: define the following variables in your environment:
 - APPS_TYPE: "git" or "docker"
 - APPS_COUNT: number of apps to create
 - OAUTH2_PROXY: cookie secret for oauth2_proxy
'

if [ -z "$OAUTH2_PROXY" ]; then
    echo "OAUTH2_PROXY is not set"
    exit 1
fi

if [ -z "$APPS_COUNT" ]; then
    echo "APPS_COUNT is not set"
    exit 1
fi


HEADERS="-H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Cookie: _oauth2_proxy="$OAUTH2_PROXY"'"
request_graphql() {
  eval curl --silent -X POST "$HEADERS" https://cp.wpcp-demo.io/graphql -d \'$1\'
}


WORKSPACE_REQUEST='{"operationName":"Workspaces","variables":{},"query":"query Workspaces {\n  workspaces {\n    results {\n      ...Workspace\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment Workspace on WorkspaceType {\n  name\n  defaultDomain\n  links {\n    ...WorkspaceLink\n    __typename\n  }\n  __typename\n}\n\nfragment WorkspaceLink on WorkspaceLinkType {\n  type\n  title\n  url\n  __typename\n}\n"}'
WORKSPACE_NAME=$(request_graphql "$WORKSPACE_REQUEST" | jq -r '.data.workspaces.results[].name')


# if there are more than one workspace, alert the user
if [ $(echo "$WORKSPACE_NAME" | wc -l) -gt 1 ]; then
    echo "$WORKSPACE_NAME"
    echo "There are more than one workspace, looks like you use admin cookie. Please use user cookie."
    exit 1
elif [ -z "$WORKSPACE_NAME" ]; then
    echo "There is no workspace, please create one"
    exit 1
fi

echo "Workspace name: $WORKSPACE_NAME"

create_git_example_apps()
{
  for i in $(seq 1 "$APPS_COUNT"); do
  # Generate a random name less then 8 characters long
    NAME=git-$RANDOM
    CREATE_APPLICATION='{"operationName":"CreateApplication","variables":{"input":{"workspaceName":"'${WORKSPACE_NAME}'","name":"'${NAME}'","description":"'${i}'","gitConfiguration":{"repository":"https://github.com/wsp-for-aws/woocommerce.git","branch":"master","credentials":"","dockerfile":"Dockerfile","context":"/"}}},"query":"mutation CreateApplication($input: ApplicationCreateInput!) {\n  createApplication(input: $input) {\n    application {\n      ...Application\n      __typename\n    }\n    ok\n    errors {\n      field\n      messages\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment Application on ApplicationType {\n  id\n  name\n  description\n  status\n  gitConfiguration {\n    ...GitConfiguration\n    __typename\n  }\n  dockerConfiguration {\n    ...DockerConfiguration\n    __typename\n  }\n  stands {\n    ...Stand\n    __typename\n  }\n  __typename\n}\n\nfragment GitConfiguration on GitConfigurationType {\n  id\n  repository\n  branch\n  dockerfile\n  context\n  credentials {\n    ...Credentials\n    __typename\n  }\n  lastCommit\n  lastCommitDetails\n  lastCommitUpdated\n  __typename\n}\n\nfragment Credentials on CredentialsType {\n  ...BasicAuthCredentials\n  ...SshKeyAuthCredentials\n  __typename\n}\n\nfragment BasicAuthCredentials on BasicAuthCredentialsType {\n  id\n  type\n  usage\n  displayName\n  __typename\n}\n\nfragment SshKeyAuthCredentials on SshKeyAuthCredentialsType {\n  id\n  type\n  usage\n  displayName\n  __typename\n}\n\nfragment DockerConfiguration on DockerConfigurationType {\n  id\n  repository\n  tag\n  credentials {\n    ...Credentials\n    __typename\n  }\n  __typename\n}\n\nfragment Stand on StandType {\n  id\n  name\n  displayName\n  endpoint\n  previewUrl\n  screenshotUrl\n  monitoringUrl\n  logsUrl\n  actionOnCommit\n  scheduledTasks\n  environment {\n    id\n    region\n    isProduction\n    isTrial\n    connector {\n      id\n      awsAccountId\n      awsConsoleUrl\n      __typename\n    }\n    __typename\n  }\n  configuration {\n    ...StandConfiguration\n    __typename\n  }\n  environmentVariables {\n    ...EnvironmentVariable\n    __typename\n  }\n  secrets {\n    ...Secret\n    __typename\n  }\n  initTask {\n    ...StandTask\n    __typename\n  }\n  lastBuild {\n    ...Build\n    __typename\n  }\n  lastBuilds {\n    ...Build\n    __typename\n  }\n  lastDeployment {\n    ...Deployment\n    __typename\n  }\n  lastDeployments {\n    ...Deployment\n    __typename\n  }\n  destroyTask {\n    ...StandTask\n    __typename\n  }\n  lastLoadTests {\n    ...LoadTest\n    __typename\n  }\n  __typename\n}\n\nfragment StandConfiguration on StandConfigurationType {\n  accessRule {\n    id\n    displayName\n    __typename\n  }\n  params {\n    sharedDomain\n    domain\n    port\n    dbType\n    cpu\n    memory\n    actionOnCommit\n    dbVersion\n    dbInstanceClass\n    dbStorageType\n    dbStorageIops\n    dbAllocatedStorage\n    dbMaxAllocatedStorage\n    dbSkipFinalSnapshot\n    dbDeleteProtection\n    dbBackupRetentionPeriod\n    dbParameters\n    dbEnvHost\n    dbEnvPort\n    dbEnvUser\n    dbEnvPassword\n    dbEnvDbName\n    dbEnvType\n    efsEnabled\n    efsMountPath\n    metricsPath\n    metricsPort\n    hchPath\n    hchTimeout\n    hchMatcher\n    hchInterval\n    hchPort\n    hchProtocol\n    hchHealthyThreshold\n    hchUnhealthyThreshold\n    replicasCount\n    asEnabled\n    asMetric\n    asMetricValue\n    asMinCount\n    asMaxCount\n    asMetricHigh\n    asMetricLow\n    asAdjustmentUp\n    asAdjustmentDown\n    sesEnabled\n    sesVerificationEnabled\n    sesSnsHttpEndpointUrl\n    sesMailFrom\n    sesAuth0DnsName\n    __typename\n  }\n  hash\n  __typename\n}\n\nfragment EnvironmentVariable on StandEnvironmentVariableType {\n  name\n  value\n  __typename\n}\n\nfragment Secret on StandSecretType {\n  name\n  __typename\n}\n\nfragment StandTask on StandTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment Build on BuildType {\n  id\n  buildNumber\n  shortRevision\n  status\n  buildTask {\n    ...BuildTask\n    __typename\n  }\n  deployTask {\n    ...DeploymentTask\n    __typename\n  }\n  __typename\n}\n\nfragment BuildTask on BuildTaskType {\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment DeploymentTask on DeploymentTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment Deployment on DeploymentType {\n  ...DeploymentBasic\n  deployTask {\n    ...DeploymentTask\n    __typename\n  }\n  build {\n    ...Build\n    __typename\n  }\n  __typename\n}\n\nfragment DeploymentBasic on DeploymentType {\n  id\n  status\n  endpoint\n  previewUrl\n  screenshotUrl\n  configuration {\n    hash\n    __typename\n  }\n  __typename\n}\n\nfragment LoadTest on LoadTestType {\n  id\n  status\n  createdAt\n  updatedAt\n  params {\n    targetPath\n    duration\n    virtualUsers\n    __typename\n  }\n  task {\n    ...LoadTestTask\n    __typename\n  }\n  __typename\n}\n\nfragment LoadTestTask on LoadTestTaskType {\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n"}'
    echo -e "\n\n\n-------Creating GIT app $i with name $NAME--------"
    echo "Run CreateApplication:"

    APP_ID=$(request_graphql "$CREATE_APPLICATION"|jq -r '.data.createApplication.application.id')
    echo "App ID: $APP_ID"
    CREATE_STAND='{"operationName":"CreateStand","variables":{"input":{"application":"'${APP_ID}'","environment":"488","configuration":{"params":{"actionOnCommit":"no","port":80,"cpu":256,"domain":"'${NAME}'demp.'"$WORKSPACE_NAME"'.wpcp-demo.run","sharedDomain":true,"memory":512,"replicasCount":1,"dbAllocatedStorage":20,"dbMaxAllocatedStorage":25,"dbBackupRetentionPeriod":0,"dbEnvDbName":"DB_NAME","dbEnvHost":"DB_HOST","dbEnvPassword":"DB_PASSWORD","dbEnvPort":"DB_PORT","dbEnvUser":"DB_USER","dbInstanceClass":"db.t3.micro","dbStorageType":"gp2","dbType":"mariadb","dbVersion":"10.6","efsEnabled":true,"efsMountPath":"/mnt/data","hchHealthyThreshold":3,"hchInterval":30,"hchMatcher":"200,302","hchPath":"/","hchProtocol":"HTTP","hchTimeout":5,"hchUnhealthyThreshold":3,"hchPort":80}},"environmentVariables":[{"name":"WORDPRESS_URL","value":"{WSP_APP_DOMAIN}"},{"name":"WORDPRESS_TITLE","value":"AWS Woocommerce installation"},{"name":"WORDPRESS_ADMIN_USER","value":"admin"},{"name":"WORDPRESS_ADMIN_EMAIL","value":"shop@{WSP_APP_DOMAIN}"},{"name":"WORDPRESS_ADMIN_PASSWORD","value":"PleaseChangeThePasswordForProductionUse"}],"scheduledTasks":"# print \"Alive\" every 15 minutes\n# */15 * * * ? * echo \"Alive\"","secrets":[]}},"query":"mutation CreateStand($input: StandCreateInput!) {\n  createStand(input: $input) {\n    stand {\n      ...Stand\n      __typename\n    }\n    ok\n    errors {\n      field\n      messages\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment Stand on StandType {\n  id\n  name\n  displayName\n  endpoint\n  previewUrl\n  screenshotUrl\n  monitoringUrl\n  logsUrl\n  actionOnCommit\n  scheduledTasks\n  environment {\n    id\n    region\n    isProduction\n    isTrial\n    connector {\n      id\n      awsAccountId\n      awsConsoleUrl\n      __typename\n    }\n    __typename\n  }\n  configuration {\n    ...StandConfiguration\n    __typename\n  }\n  environmentVariables {\n    ...EnvironmentVariable\n    __typename\n  }\n  secrets {\n    ...Secret\n    __typename\n  }\n  initTask {\n    ...StandTask\n    __typename\n  }\n  lastBuild {\n    ...Build\n    __typename\n  }\n  lastBuilds {\n    ...Build\n    __typename\n  }\n  lastDeployment {\n    ...Deployment\n    __typename\n  }\n  lastDeployments {\n    ...Deployment\n    __typename\n  }\n  destroyTask {\n    ...StandTask\n    __typename\n  }\n  lastLoadTests {\n    ...LoadTest\n    __typename\n  }\n  __typename\n}\n\nfragment StandConfiguration on StandConfigurationType {\n  accessRule {\n    id\n    displayName\n    __typename\n  }\n  params {\n    sharedDomain\n    domain\n    port\n    dbType\n    cpu\n    memory\n    actionOnCommit\n    dbVersion\n    dbInstanceClass\n    dbStorageType\n    dbStorageIops\n    dbAllocatedStorage\n    dbMaxAllocatedStorage\n    dbSkipFinalSnapshot\n    dbDeleteProtection\n    dbBackupRetentionPeriod\n    dbParameters\n    dbEnvHost\n    dbEnvPort\n    dbEnvUser\n    dbEnvPassword\n    dbEnvDbName\n    dbEnvType\n    efsEnabled\n    efsMountPath\n    metricsPath\n    metricsPort\n    hchPath\n    hchTimeout\n    hchMatcher\n    hchInterval\n    hchPort\n    hchProtocol\n    hchHealthyThreshold\n    hchUnhealthyThreshold\n    replicasCount\n    asEnabled\n    asMetric\n    asMetricValue\n    asMinCount\n    asMaxCount\n    asMetricHigh\n    asMetricLow\n    asAdjustmentUp\n    asAdjustmentDown\n    sesEnabled\n    sesVerificationEnabled\n    sesSnsHttpEndpointUrl\n    sesMailFrom\n    sesAuth0DnsName\n    __typename\n  }\n  hash\n  __typename\n}\n\nfragment EnvironmentVariable on StandEnvironmentVariableType {\n  name\n  value\n  __typename\n}\n\nfragment Secret on StandSecretType {\n  name\n  __typename\n}\n\nfragment StandTask on StandTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment Build on BuildType {\n  id\n  buildNumber\n  shortRevision\n  status\n  buildTask {\n    ...BuildTask\n    __typename\n  }\n  deployTask {\n    ...DeploymentTask\n    __typename\n  }\n  __typename\n}\n\nfragment BuildTask on BuildTaskType {\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment DeploymentTask on DeploymentTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment Deployment on DeploymentType {\n  ...DeploymentBasic\n  deployTask {\n    ...DeploymentTask\n    __typename\n  }\n  build {\n    ...Build\n    __typename\n  }\n  __typename\n}\n\nfragment DeploymentBasic on DeploymentType {\n  id\n  status\n  endpoint\n  previewUrl\n  screenshotUrl\n  configuration {\n    hash\n    __typename\n  }\n  __typename\n}\n\nfragment LoadTest on LoadTestType {\n  id\n  status\n  createdAt\n  updatedAt\n  params {\n    targetPath\n    duration\n    virtualUsers\n    __typename\n  }\n  task {\n    ...LoadTestTask\n    __typename\n  }\n  __typename\n}\n\nfragment LoadTestTask on LoadTestTaskType {\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n"}'
    echo "Run CreateStand:"
    STAND_ID=$(request_graphql "$CREATE_STAND"| jq -r '.data.createStand.stand.id')
    echo "Stand ID: $STAND_ID"

    echo "Run ImmediateDeploy:"
    IMMEDIATE_DEPLOY='{"operationName":"ImmediateDeploy","variables":{"standId":"'${STAND_ID}'"},"query":"mutation ImmediateDeploy($standId: ID!) {\n  runImmediateDeploy(standId: $standId) {\n    ok\n    error\n    task {\n      ...StandTask\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment StandTask on StandTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n"}'
    request_graphql "$IMMEDIATE_DEPLOY"
  done
}

create_docker_example_apps()
{
  for i in $(seq 1 "$APPS_COUNT"); do
    # Generate a random name less then 8 characters long
    NAME=dkr-$RANDOM
    CREATE_APPLICATION='{"operationName":"CreateApplication","variables":{"input":{"workspaceName":"'${WORKSPACE_NAME}'","name":"'${NAME}'","description":"'${i}'","dockerConfiguration":{"repository":"plesk/woocommerce","tag":"latest","credentials":""}}},"query":"mutation CreateApplication($input: ApplicationCreateInput!) {\n  createApplication(input: $input) {\n    application {\n      ...Application\n      __typename\n    }\n    ok\n    errors {\n      field\n      messages\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment Application on ApplicationType {\n  id\n  name\n  description\n  status\n  gitConfiguration {\n    ...GitConfiguration\n    __typename\n  }\n  dockerConfiguration {\n    ...DockerConfiguration\n    __typename\n  }\n  stands {\n    ...Stand\n    __typename\n  }\n  __typename\n}\n\nfragment GitConfiguration on GitConfigurationType {\n  id\n  repository\n  branch\n  dockerfile\n  context\n  credentials {\n    ...Credentials\n    __typename\n  }\n  lastCommit\n  lastCommitDetails\n  lastCommitUpdated\n  __typename\n}\n\nfragment Credentials on CredentialsType {\n  ...BasicAuthCredentials\n  ...SshKeyAuthCredentials\n  __typename\n}\n\nfragment BasicAuthCredentials on BasicAuthCredentialsType {\n  id\n  type\n  usage\n  displayName\n  __typename\n}\n\nfragment SshKeyAuthCredentials on SshKeyAuthCredentialsType {\n  id\n  type\n  usage\n  displayName\n  __typename\n}\n\nfragment DockerConfiguration on DockerConfigurationType {\n  id\n  repository\n  tag\n  credentials {\n    ...Credentials\n    __typename\n  }\n  __typename\n}\n\nfragment Stand on StandType {\n  id\n  name\n  displayName\n  endpoint\n  previewUrl\n  screenshotUrl\n  monitoringUrl\n  logsUrl\n  actionOnCommit\n  scheduledTasks\n  environment {\n    id\n    region\n    isProduction\n    isTrial\n    connector {\n      id\n      awsAccountId\n      awsConsoleUrl\n      __typename\n    }\n    __typename\n  }\n  configuration {\n    ...StandConfiguration\n    __typename\n  }\n  environmentVariables {\n    ...EnvironmentVariable\n    __typename\n  }\n  secrets {\n    ...Secret\n    __typename\n  }\n  initTask {\n    ...StandTask\n    __typename\n  }\n  lastBuild {\n    ...Build\n    __typename\n  }\n  lastBuilds {\n    ...Build\n    __typename\n  }\n  lastDeployment {\n    ...Deployment\n    __typename\n  }\n  lastDeployments {\n    ...Deployment\n    __typename\n  }\n  destroyTask {\n    ...StandTask\n    __typename\n  }\n  lastLoadTests {\n    ...LoadTest\n    __typename\n  }\n  __typename\n}\n\nfragment StandConfiguration on StandConfigurationType {\n  accessRule {\n    id\n    displayName\n    __typename\n  }\n  params {\n    sharedDomain\n    domain\n    port\n    dbType\n    cpu\n    memory\n    actionOnCommit\n    dbVersion\n    dbInstanceClass\n    dbStorageType\n    dbStorageIops\n    dbAllocatedStorage\n    dbMaxAllocatedStorage\n    dbSkipFinalSnapshot\n    dbDeleteProtection\n    dbBackupRetentionPeriod\n    dbParameters\n    dbEnvHost\n    dbEnvPort\n    dbEnvUser\n    dbEnvPassword\n    dbEnvDbName\n    dbEnvType\n    efsEnabled\n    efsMountPath\n    metricsPath\n    metricsPort\n    hchPath\n    hchTimeout\n    hchMatcher\n    hchInterval\n    hchPort\n    hchProtocol\n    hchHealthyThreshold\n    hchUnhealthyThreshold\n    replicasCount\n    asEnabled\n    asMetric\n    asMetricValue\n    asMinCount\n    asMaxCount\n    asMetricHigh\n    asMetricLow\n    asAdjustmentUp\n    asAdjustmentDown\n    sesEnabled\n    sesVerificationEnabled\n    sesSnsHttpEndpointUrl\n    sesMailFrom\n    sesAuth0DnsName\n    __typename\n  }\n  hash\n  __typename\n}\n\nfragment EnvironmentVariable on StandEnvironmentVariableType {\n  name\n  value\n  __typename\n}\n\nfragment Secret on StandSecretType {\n  name\n  __typename\n}\n\nfragment StandTask on StandTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment Build on BuildType {\n  id\n  buildNumber\n  shortRevision\n  status\n  buildTask {\n    ...BuildTask\n    __typename\n  }\n  deployTask {\n    ...DeploymentTask\n    __typename\n  }\n  __typename\n}\n\nfragment BuildTask on BuildTaskType {\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment DeploymentTask on DeploymentTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment Deployment on DeploymentType {\n  ...DeploymentBasic\n  deployTask {\n    ...DeploymentTask\n    __typename\n  }\n  build {\n    ...Build\n    __typename\n  }\n  __typename\n}\n\nfragment DeploymentBasic on DeploymentType {\n  id\n  status\n  endpoint\n  previewUrl\n  screenshotUrl\n  configuration {\n    hash\n    __typename\n  }\n  __typename\n}\n\nfragment LoadTest on LoadTestType {\n  id\n  status\n  createdAt\n  updatedAt\n  params {\n    targetPath\n    duration\n    virtualUsers\n    __typename\n  }\n  task {\n    ...LoadTestTask\n    __typename\n  }\n  __typename\n}\n\nfragment LoadTestTask on LoadTestTaskType {\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n"}'
    echo -e "\n\n\n-------Creating DOCKER app $i with name $NAME--------"
    echo "Run CreateApplication:"
    APP_ID=$(request_graphql "$CREATE_APPLICATION"|jq -r '.data.createApplication.application.id')
    echo "App ID: $APP_ID"

    CREATE_STAND='{"operationName":"CreateStand","variables":{"input":{"application":"'${APP_ID}'","environment":"488","configuration":{"params":{"actionOnCommit":"no","port":80,"cpu":256,"domain":"'${NAME}'.demp.'"$WORKSPACE_NAME"'.wpcp-demo.run","sharedDomain":true,"memory":512,"replicasCount":1,"dbAllocatedStorage":20,"dbMaxAllocatedStorage":25,"dbBackupRetentionPeriod":0,"dbEnvDbName":"DB_NAME","dbEnvHost":"DB_HOST","dbEnvPassword":"DB_PASSWORD","dbEnvPort":"DB_PORT","dbEnvUser":"DB_USER","dbInstanceClass":"db.t3.micro","dbStorageType":"gp2","dbType":"mariadb","dbVersion":"10.6","efsEnabled":true,"efsMountPath":"/mnt/data","hchHealthyThreshold":3,"hchInterval":30,"hchMatcher":"200,302","hchPath":"/","hchProtocol":"HTTP","hchTimeout":5,"hchUnhealthyThreshold":3,"hchPort":80}},"environmentVariables":[{"name":"DOMAIN_NAME","value":"{WSP_APP_DOMAIN}"},{"name":"DSN","value":"{WSP_DB_USER}@{WSP_DB_HOST}:{WSP_DB_PORT}/{WSP_DB_NAME}"}],"scheduledTasks":"# print \"Alive\" every 15 minutes\n# */15 * * * ? * echo \"Alive\"","secrets":[]}},"query":"mutation CreateStand($input: StandCreateInput!) {\n  createStand(input: $input) {\n    stand {\n      ...Stand\n      __typename\n    }\n    ok\n    errors {\n      field\n      messages\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment Stand on StandType {\n  id\n  name\n  displayName\n  endpoint\n  previewUrl\n  screenshotUrl\n  monitoringUrl\n  logsUrl\n  actionOnCommit\n  scheduledTasks\n  environment {\n    id\n    region\n    isProduction\n    isTrial\n    connector {\n      id\n      awsAccountId\n      awsConsoleUrl\n      __typename\n    }\n    __typename\n  }\n  configuration {\n    ...StandConfiguration\n    __typename\n  }\n  environmentVariables {\n    ...EnvironmentVariable\n    __typename\n  }\n  secrets {\n    ...Secret\n    __typename\n  }\n  initTask {\n    ...StandTask\n    __typename\n  }\n  lastBuild {\n    ...Build\n    __typename\n  }\n  lastBuilds {\n    ...Build\n    __typename\n  }\n  lastDeployment {\n    ...Deployment\n    __typename\n  }\n  lastDeployments {\n    ...Deployment\n    __typename\n  }\n  destroyTask {\n    ...StandTask\n    __typename\n  }\n  lastLoadTests {\n    ...LoadTest\n    __typename\n  }\n  __typename\n}\n\nfragment StandConfiguration on StandConfigurationType {\n  accessRule {\n    id\n    displayName\n    __typename\n  }\n  params {\n    sharedDomain\n    domain\n    port\n    dbType\n    cpu\n    memory\n    actionOnCommit\n    dbVersion\n    dbInstanceClass\n    dbStorageType\n    dbStorageIops\n    dbAllocatedStorage\n    dbMaxAllocatedStorage\n    dbSkipFinalSnapshot\n    dbDeleteProtection\n    dbBackupRetentionPeriod\n    dbParameters\n    dbEnvHost\n    dbEnvPort\n    dbEnvUser\n    dbEnvPassword\n    dbEnvDbName\n    dbEnvType\n    efsEnabled\n    efsMountPath\n    metricsPath\n    metricsPort\n    hchPath\n    hchTimeout\n    hchMatcher\n    hchInterval\n    hchPort\n    hchProtocol\n    hchHealthyThreshold\n    hchUnhealthyThreshold\n    replicasCount\n    asEnabled\n    asMetric\n    asMetricValue\n    asMinCount\n    asMaxCount\n    asMetricHigh\n    asMetricLow\n    asAdjustmentUp\n    asAdjustmentDown\n    sesEnabled\n    sesVerificationEnabled\n    sesSnsHttpEndpointUrl\n    sesMailFrom\n    sesAuth0DnsName\n    __typename\n  }\n  hash\n  __typename\n}\n\nfragment EnvironmentVariable on StandEnvironmentVariableType {\n  name\n  value\n  __typename\n}\n\nfragment Secret on StandSecretType {\n  name\n  __typename\n}\n\nfragment StandTask on StandTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment Build on BuildType {\n  id\n  buildNumber\n  shortRevision\n  status\n  buildTask {\n    ...BuildTask\n    __typename\n  }\n  deployTask {\n    ...DeploymentTask\n    __typename\n  }\n  __typename\n}\n\nfragment BuildTask on BuildTaskType {\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment DeploymentTask on DeploymentTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n\nfragment Deployment on DeploymentType {\n  ...DeploymentBasic\n  deployTask {\n    ...DeploymentTask\n    __typename\n  }\n  build {\n    ...Build\n    __typename\n  }\n  __typename\n}\n\nfragment DeploymentBasic on DeploymentType {\n  id\n  status\n  endpoint\n  previewUrl\n  screenshotUrl\n  configuration {\n    hash\n    __typename\n  }\n  __typename\n}\n\nfragment LoadTest on LoadTestType {\n  id\n  status\n  createdAt\n  updatedAt\n  params {\n    targetPath\n    duration\n    virtualUsers\n    __typename\n  }\n  task {\n    ...LoadTestTask\n    __typename\n  }\n  __typename\n}\n\nfragment LoadTestTask on LoadTestTaskType {\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n"}'
    echo "Run CreateStand:"
    STAND_ID=$(request_graphql "$CREATE_STAND"| jq -r '.data.createStand.stand.id')
    echo "Stand ID: $STAND_ID"

    echo "Run ImmediateDeploy:"
    IMMEDIATE_DEPLOY='{"operationName":"ImmediateDeploy","variables":{"standId":"'${STAND_ID}'"},"query":"mutation ImmediateDeploy($standId: ID!) {\n  runImmediateDeploy(standId: $standId) {\n    ok\n    error\n    task {\n      ...StandTask\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment StandTask on StandTaskType {\n  actionType\n  id\n  type\n  uuid\n  status\n  startedAt\n  finishedAt\n  estimate\n  duration\n  message\n  __typename\n}\n"}'
    request_graphql "$IMMEDIATE_DEPLOY"
  done
}

if [ "$APPS_TYPE" == "git" ]
then
  echo "Creating $APPS_COUNT git example apps"
  create_git_example_apps
elif [ "$APPS_TYPE" == "docker" ]
then
  echo "Creating $APPS_COUNT docker example apps"
  create_docker_example_apps
else
  echo "Unknown APPS_TYPE env, please set it to git or docker"
fi
