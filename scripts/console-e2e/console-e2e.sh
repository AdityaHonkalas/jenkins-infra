#!/bin/bash
# Note: Playwright console UI e2e tests execution script. If running Docker/Podman, `--shm-size 4g` (at least) recommended.

# input parameters in input.json file
# {
#   "apiurl": "https://api.rdr-zstream-p9-3f42.redhat.com:6443",
#   "password": "LKLCT-6zsgM-SqCFC-2r6nZ",
#   "idp": "kube:admin",
#   "idp_user": "user1",
#   "idp_password": "keypass123",
#   "driver": "Playwright",
#   "suite": "console",
#   "browser": "chromium",
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
function run_playwright_tests() {
  local RC=0

  if [[ ! $PWD = '/root/console/frontend' ]]; then
    cd $ROOTDIR"/frontend"
  fi

  # Install chromium before running the tests
  yarn playwright install chromium 

  if [ "$1" == 'e2e' -o "$1" == 'console' -o -z "$1" ]; then
    printInfo "Starting Playwright tests for console suite" 1
    ./integration-tests/test-playwright.sh -p console -h true | tee $HOSTDIR"/${SUITE2RUN}-${NOW}.txt"
    RC=${PIPESTATUS[0]}
  else # specific spec or suite
    printInfo "Starting Playwright for '$SUITE2RUN'" 1
    ./integration-tests/test-playwright.sh -p console -s "${SUITE2RUN}" -h true | tee $HOSTDIR"/${SUITE2RUN}-${NOW}.txt"
    RC=${PIPESTATUS[0]}
  fi

  local RUN=1
  if [ $RC -ne 0 -a $RETRYMAX -ne 0 ]; then
    while [ $RC -ne 0 -a $RUN -le $RETRYMAX ]; do
      rerun_playwright_tests $(date +%s) $RUN
      RC=$?
      RUN=`expr $RUN + 1`
    done
  fi

  test $RC -eq 0 && echo "INFO: Playwright tests passed!!" || echo "WARNING: Playwright tests failed :-("
  report_playwright_rerun
  return $RC
}

# $1=epoch (unique across runs), $2=next run#
function rerun_playwright_tests() {
  local EPOCH=$1
  local RUN_NUM=$2
  local BACKUP_DIR="$OUTDIR/playwright-run-$EPOCH"
  mkdir -p "$BACKUP_DIR"

  # Backup previous reports/results
  [ -d "$PW_DIR/test-results" ] && cp -r "$PW_DIR/test-results" "$BACKUP_DIR/"
  [ -d "$PW_DIR/playwright-report" ] && cp -r "$PW_DIR/playwright-report" "$BACKUP_DIR/"
  [ -d "$PW_DIR/gui_test_screenshots" ] && cp -r "$PW_DIR/gui_test_screenshots" "$BACKUP_DIR/"
  ls $PW_DIR/junit*.xml >/dev/null 2>&1 && cp $PW_DIR/junit*.xml "$BACKUP_DIR/"

  FAILED_SPECS=`mktemp`

  # 1. Extract failed specs from Playwright JUnit XML reports if available
  if ls $PW_DIR/junit*.xml >/dev/null 2>&1; then
    grep -l '<failure' $PW_DIR/junit*.xml | while read JUNIT_FILE; do
      grep -o 'file="[^"]*"' "$JUNIT_FILE" | sed 's/file="//;s/"//' >> $FAILED_SPECS
    done
  fi

  # 2. Extract failed specs from Playwright JSON report if available
  if ls $PW_DIR/playwright-report/*.json >/dev/null 2>&1; then
    jq -r '.. | objects | select(.status? == "unexpected" or .status? == "failed") | .file? // empty' $PW_DIR/playwright-report/*.json >> $FAILED_SPECS
  fi

  # 3. Fallback: Parse failed spec paths from execution log file if reports were not generated
  if [ ! -s $FAILED_SPECS ] && [ -f "$HOSTDIR/${SUITE2RUN}-${NOW}.txt" ]; then
    grep -E '✘|FAIL|failed' "$HOSTDIR/${SUITE2RUN}-${NOW}.txt" | grep -oE '[a-zA-Z0-9_\/\.\-]+\.spec\.ts' >> $FAILED_SPECS
  fi

  local RC=0
  local FOUND_FAILURES=false

  for SPEC in $(cat $FAILED_SPECS | sort | uniq); do
    [ -z "$SPEC" ] && continue
    FOUND_FAILURES=true
    SPEC_NAME=$(basename $SPEC .spec.ts)
    printInfo "Starting Playwright rerun for $SPEC (#$RUN_NUM)" 1
    ./integration-tests/test-playwright.sh -p console -s "$SPEC" -h true | tee $HOSTDIR"/${SPEC_NAME}-rerun${RUN_NUM}-${NOW}.txt"
    PRC=${PIPESTATUS[0]}
    if [ $PRC -eq 0 ]; then
      echo "INFO: Playwright rerun for $SPEC passed!! :-)"
    else
      echo "WARNING: Playwright rerun for $SPEC failed :-("
      RC=1
    fi
  done

  rm -f $FAILED_SPECS

  # If failures occurred but no specs could be isolated, rerun the suite
  if [ "$FOUND_FAILURES" = false ]; then
    printInfo "No isolated spec files identified, re-running full suite '$SUITE2RUN' (#$RUN_NUM)" 1
    if [ "$SUITE2RUN" == 'e2e' -o "$SUITE2RUN" == 'console' -o -z "$SUITE2RUN" ]; then
      ./integration-tests/test-playwright.sh -p console -h true | tee $HOSTDIR"/${SUITE2RUN}-rerun${RUN_NUM}-${NOW}.txt"
      RC=${PIPESTATUS[0]}
    else
      ./integration-tests/test-playwright.sh -p console -s "${SUITE2RUN}" -h true | tee $HOSTDIR"/${SUITE2RUN}-rerun${RUN_NUM}-${NOW}.txt"
      RC=${PIPESTATUS[0]}
    fi
  fi

  return $RC
}

function report_playwright_rerun() {
  printInfo "Playwright Test Execution Summary" 2
  if ls $PW_DIR/junit*.xml >/dev/null 2>&1; then
    grep -h '<testsuite' $PW_DIR/junit*.xml | egrep -v 'failures="0" errors="0"' || echo "All testsuites passed in the latest run."
  elif ls $PW_DIR/playwright-report/*.json >/dev/null 2>&1; then
    jq -r '.stats // empty' $PW_DIR/playwright-report/*.json
  fi
  printInfo " " 2
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
  export PLAYWRIGHT_LOGIN_IDP="kube:admin"
  export PLAYWRIGHT_LOGIN_USERS="kubeadmin:${OCADMPW}"
  export CYPRESS_LOGIN_IDP="kube:admin"
  export CYPRESS_LOGIN_USERS="kubeadmin:${OCADMPW}"
elif [ -n "$(jq -r .idp_user $PARAMSJ)" ] && [ -n "$(jq -r .idp_password $PARAMSJ)" ]; then
  IDP_VAL=$(jq -r .idp $PARAMSJ)
  USERS_VAL=$(jq -r .idp_user $PARAMSJ)":"$(jq -r .idp_password $PARAMSJ)
  export PLAYWRIGHT_LOGIN_IDP="$IDP_VAL"
  export PLAYWRIGHT_LOGIN_USERS="$USERS_VAL"
  export CYPRESS_LOGIN_IDP="$IDP_VAL"
  export CYPRESS_LOGIN_USERS="$USERS_VAL"
  printInfo "Configured $IDP_VAL IDP for multi-user auth test"
fi

# Check if kubeconfig is on the path $HOSTDIR/kubeconfig
if [ -e $HOSTDIR/kubeconfig ]; then
  export KUBECONFIG=$HOSTDIR/kubeconfig
  export PLAYWRIGHT_KUBECONFIG_PATH=$HOSTDIR/kubeconfig
  export CYPRESS_KUBECONFIG_PATH=$HOSTDIR/kubeconfig
else
  printInfo "ERROR: No kubeconfig provided -- aborting...."
  exit 1
fi

NOW=$(date +%Y%m%d-%H%M)
ROOTDIR=/root/console
REFRESH=$(jq -r .refresh $PARAMSJ)

[ -z $REFRESH ] && REFRESH=false && printInfo "No refresh param found in input.json, defaulting to false"

# Switch to the /root dir if not already there
[ "$PWD" != '/root' ] && cd /root

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
    [ -n "$(jq -r .ocp_version $PARAMSJ)" ] && git checkout $(jq -r .ocp_version $PARAMSJ) || printInfo "OCP version is not found in the input.json, building code with main branch." && git checkout main
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

CONSOLE_URL="$(oc get consoles.config.openshift.io cluster -o jsonpath='{.status.consoleURL}')"
export BRIDGE_BASE_ADDRESS="$CONSOLE_URL"
export WEB_CONSOLE_URL="$CONSOLE_URL"
export BRIDGE_KUBEADMIN_PASSWORD=$OCADMPW

if [ -z "$BRIDGE_E2E_BROWSER_NAME" ]; then
  BROWSER=$(jq -r .browser $PARAMSJ)
  [ -n "$BROWSER" -a "$BROWSER" != "null" ] && export BRIDGE_E2E_BROWSER_NAME=$BROWSER || export BRIDGE_E2E_BROWSER_NAME="chromium"
fi

JASMINETO=$(jq -r .jtimeout $PARAMSJ)
[ -n "$JASMINETO" -a "$JASMINETO" != "null" ] && export BRIDGE_JASMINE_TIMEOUT=$JASMINETO

DRIVER=$(jq -r .driver $PARAMSJ)

SUITE2RUN=$(jq -r .suite $PARAMSJ)
[ -z "$SUITE2RUN" -o "$SUITE2RUN" == "null" ] && SUITE2RUN=console

RETRYMAX=$(jq -r .retries $PARAMSJ)
[ -z "$RETRYMAX" -o "$RETRYMAX" == "null" ] && RETRYMAX=2

export PLAYWRIGHT_PLUGIN_PULL_SPEC=quay.io/rh_ee_ahonkala/console-demo-plugin:ppc64le
export CYPRESS_PLUGIN_PULL_SPEC=quay.io/rh_ee_ahonkala/console-demo-plugin:ppc64le

PW_DIR="${ROOTDIR}/frontend/packages/integration-tests-playwright"
OUTDIR="${ROOTDIR}/frontend/gui_test_screenshots"
mkdir -p "$OUTDIR"

# Install Playwright browser binaries if not present
if [ -d "$ROOTDIR/frontend" ]; then
  cd "$ROOTDIR/frontend"
  if command -v yarn >/dev/null 2>&1; then
    printInfo "Ensuring Playwright browser binaries are installed"
    yarn playwright install || npx playwright install || true
  fi
fi

VERDICT=1

echo ""
printInfo "Kicking off Playwright test suite: $SUITE2RUN"
run_playwright_tests "$SUITE2RUN"
VERDICT=$?

echo ""
if [ -w $HOSTDIR ]; then
  mkdir -p $HOSTDIR/out-$NOW
  # Copy screenshots, reports, traces, and test-results
  [ -d "$OUTDIR" ] && cp -r $OUTDIR $HOSTDIR/out-$NOW/
  [ -d "$PW_DIR/test-results" ] && cp -r $PW_DIR/test-results $HOSTDIR/out-$NOW/
  [ -d "$PW_DIR/playwright-report" ] && cp -r $PW_DIR/playwright-report $HOSTDIR/out-$NOW/
  [ -d "$PW_DIR/gui_test_screenshots" ] && cp -r $PW_DIR/gui_test_screenshots $HOSTDIR/out-$NOW/
  ls $PW_DIR/junit*.xml >/dev/null 2>&1 && cp $PW_DIR/junit*.xml $HOSTDIR/out-$NOW/
  printInfo "Copied test outputs and artifacts to directory: $HOSTDIR/out-$NOW"
else
  echo "WARN: $HOSTDIR not writeable, unable to copy output..."
fi

exit $VERDICT
