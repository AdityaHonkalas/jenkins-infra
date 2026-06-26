#!/bin/sh
# Note: Cypress seems to need more memory to run, as it executes more and more tests. If running Docker, `--shm-size 4g` (at least) recommended.

# input parameters in input.json file
# {
#   "apiurl": "https://api.rdr-zstream-p9-3f42.redhat.com:6443",
#   "password": "LKLCT-6zsgM-SqCFC-2r6nZ",
#   "idp": "kube:admin",
#   "idp_user": "user1",
#   "idp_password": "keypass123",
#   "driver": "Cypress",
#   "suite": "Network_Observability",
#   "browser": "Chrome",
#   "jtimeout": 180000,
#   "retries": ""
# }

# $1=message, $2=type (2=block, 1=standout, 0=subtle=default)
function printInfo() {
  msg=$1
  type=$2
  test -z "$type" && type=0
  test $type -gt 0 && echo ""
  len=`expr 100 - ${#msg}`
  echo -n "INFO: $msg "
  cnt=0
  rch="."
  test $type -gt 0 && rch="~"
  test $type -gt 1 && rch="="
  while [ $cnt -lt $len ]; do
    echo -n $rch
    cnt=`expr $cnt + 1`
  done
  echo ""
  test $type -gt 0 && echo ""
}

# $1=(optional) test suite name to run
function run_cypress_tests() {
  test "$DRIVER" == "protractor" && return #NEEDSATTN
  local RC=0

  if [[ ! $PWD = '/root/console/frontend' ]]; then
    cd $ROOTDIR"/frontend"
  fi

  if [ "$1" == 'e2e' -o "$1" == 'dvt' -o -z "$1" ]; then
    printInfo "Starting all Cypress tests" 1
    ./integration-tests/test-cypress.sh -p console -h true | tee $HOSTDIR"/${SUITE2RUN}-${NOW}.txt"
  else # specific suite
    #TEST_SUITE=$(echo $SUITE2RUN | cut -d '/' -f 3 | cut -d '.' -f 1)
    printInfo "Starting Cypress for '$SUITE2RUN'" 1
    ./integration-tests/test-cypress.sh -p console -s "${SUITE2RUN}" -h true | tee $HOSTDIR"/${SUITE2RUN}-${NOW}.txt"
  fi
  test $? -eq 0 || RC=1
  local RUN=1
  if [ $RC -ne 0 -a $RETRYMAX -ne 0 ]; then
    while [ $RC -ne 0 -a $RUN -le $RETRYMAX ]; do
      rerun_cypress_tests $(date +%s) $RUN
      test $? -eq 0 && RC=0 || RUN=`expr $RUN + 1`
    done
  fi
  test $RC -eq 0 && echo "INFO: Cypress tests passed!!" || echo "WARNING: Cypress tests failed :-("
  report_cypress_rerun
  return $RC
}

# $1=epoch (just to be unique across runs inside the same container), $2=next run#
function rerun_cypress_tests() {
  mkdir $OUTDIR/cypress-$1; mv $OUTDIR/cypress $OUTDIR/cypress_report*.json $OUTDIR/cypress-$1
  FAILED_SPECS=`mktemp`
  jq -r '.results[] | {file: .file, test: {title: (.suites[0].tests[]          | .title), result: (.suites[0].tests[]          | .state)}} | select(.test.result|test("^fail")) | .file' $OUTDIR/cypress-$1/*.json >  $FAILED_SPECS
  jq -r '.results[] | {file: .file, test: {title: (.suites[0].suites[].tests[] | .title), result: (.suites[0].suites[].tests[] | .state)}} | select(.test.result|test("^fail")) | .file' $OUTDIR/cypress-$1/*.json >> $FAILED_SPECS
  local RC=0
  for SPEC in $(cat $FAILED_SPECS | sort | uniq); do
    printInfo "Starting Cypress rerun for $SPEC (#$2)" 1
    ./integration-tests/test-cypress.sh -p console -s $SPEC -h true | tee $HOSTDIR"/$(echo $SPEC | cut -d '/' -f 3 | cut -d '.' -f 1)-${RC}-${NOW}.txt"
    CYRC=$?
    test $CYRC -eq 0 && echo "INFO: Cypress rerun for $SPEC passed!! :-)" || echo "WARNING: Cypress rerun for $SPEC failed :-("
    test $CYRC -ne 0 && RC=1
  done
  rm -f $FAILED_SPECS
  return $RC
}

function report_cypress_rerun() {
  printInfo "Failed Cypress Suite(s)" 2
  VERDICT_C=0
  SUITES=`mktemp`
  jq -r '.results[0].suites[0].title' $OUTDIR/cypress_report*.json | egrep -v 'null|Skipping' | sort | uniq > $SUITES
  while read SUITE; do
    grep -h testsuite $OUTDIR/junit_cypress-*.xml | egrep -v 'Root Suite|/testsuite|Mocha Tests' | sort | grep "$SUITE" | tail -1 | grep -v 'failures="0"'
    VERDICT_C=`expr $VERDICT_C + $?`
  done < $SUITES
  rm -f $SUITES
  printInfo " " 2
}

# ------------------- Not required ---------------
function adjust_for_dvt() {
  printInfo "Trimming for DVT..."
  SUITE2RUN=dashboards #NEEDSATTN
  CYDIR=frontend/packages/integration-tests-cypress
  mv $CYDIR/cypress.json $CYDIR/cypress.json~ ; jq '.video=false' $CYDIR/cypress.json~ > $CYDIR/cypress.json
  mv $CYDIR/tests/crud/annotations.spec.ts \
     $CYDIR/tests/i18n/* \
     /tmp/
}

HOSTDIR=/host #NEEDSATTN
[ -f /input.json ] && PARAMSJ=/input.json || PARAMSJ=$HOSTDIR/input.json
jq '. | del(.password)' $PARAMSJ

OAPIURL=$(jq -r .apiurl $PARAMSJ)
if [ -z "$OAPIURL" ]; then
  printInfo "ERROR: no OpenShift cluster URL provided -- aborting..."
  exit 1
fi

OCADMPW=$(jq -r .password $PARAMSJ)
if [ -z "$OCADMPW" ]; then
  printInfo "ERROR: no kubeadmin password  provided -- aborting..."
  exit 2
else
  export BRIDGE_KUBEADMIN_PASSWORD=$OCADMPW
fi

# Check for IDP user other than kubeadmin
if [ -z $(jq -r .idp $PARAMSJ) ]; then
  printInfo "WARNING: IDP not found in the input parameters, using default kubeadmin."
  export CYPRESS_LOGIN_IDP="kube:admin"
  export CYPRESS_LOGIN_USERS="kubeadmin:${OCADMPW}"
elif [ -n "$(jq -r .idp_user $PARAMSJ)" ] && [ -n "$(jq -r .idp_password $PARAMSJ)" ]; then
  export CYPRESS_LOGIN_IDP=$(jq -r .idp $PARAMSJ)
  export CYPRESS_LOGIN_USERS=$(jq -r .idp_user $PARAMSJ)":"$(jq -r .idp_password $PARAMSJ)
  printInfo "Configured $(jq -r .idp $PARAMSJ) IDP for multi-user auth test"
fi

# Check if kubeconfig is on the path $HOSTDIR/kubeconfig
if [ -e $HOSTDIR/kubeconfig ]; then
  export KUBECONFIG=$HOSTDIR/kubeconfig
  export CYPRESS_KUBECONFIG_PATH=$HOSTDIR/kubeconfig
else
  printInfo "ERROR: No kubeconfig provided -- aborting...."
  exit 1
fi

NOW=$(date +%Y%m%d-%H%M)
#echo "NOW=$NOW"
ROOTDIR=/root/console
REFRESH=$(jq -r .refresh $PARAMSJ)

[ -z $REFRESH ] && REFRESH=false && printInfo "No refresh param found in input.json, defaulting to false"

# Switch to the /root dir if not already there
[ $pwd != '/root' ] && cd /root

printInfo "Checking for existing 'console' directory at $ROOTDIR"
echo ""
if [ ! -d $ROOTDIR -o "$REFRESH" == "true" ]; then
  if [ -e $HOSTDIR/console-built.tgz ]; then
    printInfo "Unzipping pre-built console code"
    tar xzf $HOSTDIR/console-built.tgz
    cd $ROOTDIR
  else
    printInfo "Building latest console code from Git"
    git clone https://github.com/openshift/console.git
    [ -n $(jq -r .ocp_version $PARAMSJ) ] && git checkout $(jq -r .ocp_version $PARAMSJ) || printInfo "OCP version is not found in the input.json, builing code with main branch." && git checkout main
    cd $ROOTDIR
    ./build.sh
    [ $? -ne 0 ] && git checkout -- frontend/yarn.lock ; ./build.sh
  fi
  printInfo "Done!"
else
  printInfo "Using existing 'console' directory"
  cd $ROOTDIR
fi

echo ""
df -h .

echo ""
printInfo "Priming runtime env"

oc login -u kubeadmin -p $OCADMPW $OAPIURL --insecure-skip-tls-verify

export BRIDGE_BASE_ADDRESS="$(oc get consoles.config.openshift.io cluster -o jsonpath='{.status.consoleURL}')"
export BRIDGE_KUBEADMIN_PASSWORD=$OCADMPW

export CHROME_VERSION=$(google-chrome --version | sed 's/Google Chrome //')

# FAILFAST=$(jq -r .failfast $PARAMSJ)
# [ "$FAILFAST" != "yes" -a "$FAILFAST" != "true" ] && export NO_FAILFAST=false

if [ -z "$BRIDGE_E2E_BROWSER_NAME" ]; then
  BROWSER=$(jq -r .browser $PARAMSJ)
  [ -n "$BROWSER" ] && export BRIDGE_E2E_BROWSER_NAME=$BROWSER
fi

JASMINETO=$(jq -r .jtimeout $PARAMSJ)
[ -n "$JASMINETO" ] && export BRIDGE_JASMINE_TIMEOUT=$JASMINETO

DRIVER=$(jq -r .driver $PARAMSJ)

SUITE2RUN=$(jq -r .suite $PARAMSJ)
[ -z "$SUITE2RUN" ] && SUITE2RUN=e2e #NEEDSATTN

RETRYMAX=$(jq -r .retries $PARAMSJ)
[ -z "$RETRYMAX" -o "$RETRYMAX" == "null" ] && RETRYMAX=2 #NEEDSATTN

# export CYPRESS_PLUGIN_PULL_SPEC=quay.io/miyamoto_h/console-demo-plugin:latest
export CYPRESS_PLUGIN_PULL_SPEC=quay.io/rh_ee_ahonkala/console-demo-plugin:ppc64le

OUTDIR=${ROOTDIR}"/frontend/gui_test_screenshots"
VERDICT_P=1 # did Protractor tests pass(=0) after all?
VERDICT_C=1 # did Cypress    tests pass(=0) after all?

echo ""
if [ "$SUITE2RUN" == 'e2e' -o "$SUITE2RUN" == 'dvt' ]; then
  test "$SUITE2RUN" == 'dvt' && adjust_for_dvt
  printInfo "Kicking off available test suites"
  run_cypress_tests $SUITE2RUN
else
  printInfo "Kicking off test suite: $SUITE2RUN"
  run_netobserv_cypress_tests $SUITE2RUN
fi

#echo "DEBUG: VERDICT_P=$VERDICT_P, VERDICT_C=$VERDICT_C"

echo ""
if [ -w $HOSTDIR ]; then
  cp -r $OUTDIR $HOSTDIR/out-$NOW
  printInfo "Copied output to directory: out-$NOW"
else
  echo "WARN: $HOSTDIR not writeable, unable to copy output..."
fi

exit `expr $VERDICT_P + $VERDICT_C`
