#!/usr/bin/env zsh

ZMOD_DIR=$(pwd)
ZMOD_WORKSPACE=$(pwd)

. ${ZMOD_DIR}/src/utils/test.zsh;
. ${ZMOD_DIR}/src/utils/error.zsh;
. ${ZMOD_DIR}/src/utils/debug.zsh; 
. ${ZMOD_DIR}/src/utils/extract-functions.zsh;

TRUE=0
FALSE=1

TOTAL_TESTS=0
TOTAL_FAILED_TESTS=0
TOTAL_PASSED_TESTS=0

START_TIME=$(date +%s )
TOTAL_FILES=0

IS_CURRENT_TEST_OK=${FALSE}
CURRENT_TEST_FILE=''
CURRENT_TEST_NAME=''


# set the global variable
# @param {string} $1 - global variable name
# @param {string} $2 - the value of the global variable
#
function setGlobalVariables() {
  local globalVariableName=$1
  local value=$2

  eval "${globalVariableName}=${value}"
}

function print_current_test_result() {
  local testFunc=$1
  local isCurrentTestOk=$2
  if [[ ${isCurrentTestOk} -eq ${TRUE} ]]; then
    echo "  ${lightGreen}✓${noColor} ${testFunc}"
  fi
}

local testConfFile=$1
local configFiles=($(source ${testConfFile}))
local testFile='';
for testFile in ${configFiles[@]}; do
  local relativeTestFile=${testFile#${ZMOD_DIR}/}
  echo "Test  ${relativeTestFile}"
  # load the test file
  . ${testFile}

  setGlobalVariables "TOTAL_FILES" "$(( TOTAL_FILES + 1 ))"
  # loop the test functions
  setGlobalVariables "CURRENT_TEST_FILE" "${relativeTestFile}"
  local testFunctions=($(extract_test_functions ${testFile}))
  local testFunc=''
  for testFunc in ${testFunctions[@]}; do
    # execute the test function
    setGlobalVariables "CURRENT_TEST_NAME" "${testFunc}"
    setGlobalVariables IS_CURRENT_TEST_OK "${TRUE}"
    ${testFunc}
    print_current_test_result ${testFunc} ${IS_CURRENT_TEST_OK}
    # Collecting test data
    setGlobalVariables "TOTAL_TESTS" "$(( TOTAL_TESTS + 1 ))"
    if [[ ${IS_CURRENT_TEST_OK} -eq ${TRUE} ]]; then
      setGlobalVariables "TOTAL_PASSED_TESTS" "$(( TOTAL_PASSED_TESTS + 1 ))"
    else
      setGlobalVariables "TOTAL_FAILED_TESTS" "$(( TOTAL_FAILED_TESTS + 1 ))"
    fi
  done
done

echo "
Tests:        ${TOTAL_FAILED_TESTS} failed, ${TOTAL_PASSED_TESTS} passed, ${TOTAL_TESTS} total
Time:         $(( $(date +%s) - ${START_TIME} )) s
Test files:   ${TOTAL_FILES} f
Ran all test files."

if [[ ${TOTAL_FAILED_TESTS} -gt 0 ]]; then
  exit 1;
fi
