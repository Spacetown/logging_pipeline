#!/usr/bin/env bash
set -e

THIS_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

echo """
Running ruff format..."""
ruff format --check $THIS_DIRECTORY/..

echo """
Running ruff check..."""
ruff check $THIS_DIRECTORY/..

echo """
Running bandit..."""
bandit -c pyproject.toml -r $THIS_DIRECTORY/..


echo """
Creating virtual environment and install wheel..."""
python3 -m venv --clear /tmp/.venv
. /tmp/.venv/bin/activate
pip install $THIS_DIRECTORY/../dist/*.whl

stderr=$(mktemp --suffix .stderr)

function runOneLinerNotExpected {
    local oneLiner="$1"
    local notExpected="$2"

    echo
    echo "   Execute: $oneLiner"
    echo "   Not expected pattern: $notExpected"
    python3 -c "$oneLiner" > /dev/null 2> $stderr
    echo "   Output stderr:"
    cat $stderr | sed -e 's/^/      /'
    grep -F "$notExpected" $stderr > /dev/null
    if [ $? == 0 ] ; then
        exit 1
    fi
}

function runOneLinerExpected {
    local oneLiner="$1"
    local expected="$2"

    echo
    echo "   Execute: $oneLiner"
    echo "   Expected pattern: $expected"
    python3 -c "$oneLiner" > /dev/null 2> $stderr
    echo "   Output stderr:"
    if [ "${GITHUB_ACTIONS}" != "" ] ; then echo "stopMarker=stop$$" ; fi
    cat $stderr | sed -e 's/^/      /'
    if [ "${GITHUB_ACTIONS}" != "" ] ; then echo "stop$$" ; fi
    grep -F "$expected" $stderr > /dev/null
    if [ $? != 0 ] ; then
        exit 1
    fi
}

echo """
Running tests..."""
echo """
Clear pipeline variables and ensure that output is not found..."""
unset TF_BUILD
unset GITHUB_ACTIONS
(
    set +e
    runOneLinerNotExpected "import logging; logging.warning('Test warning')"   '##vso[task.logissue type=warning]Test warning'
    runOneLinerNotExpected "import logging; logging.error('Test error')"       '##vso[task.logissue type=error]Test error'
    runOneLinerNotExpected "import logging; logging.critical('Test critical')" '##vso[task.logissue type=error]Test critical'
)

(
    set +e
    runOneLinerNotExpected "import logging; logging.warning('Test warning')"   '::warning::Test warning'
    runOneLinerNotExpected "import logging; logging.error('Test error')"       '::error::Test error' 
    runOneLinerNotExpected "import logging; logging.critical('Test critical')" '::error::Test critical' 
)

echo """
Check if Azure pipeline output is found..."""
(
    set +e
    export TF_BUILD=1
    runOneLinerExpected "import logging; logging.warning('Test warning')"   '##vso[task.logissue type=warning]Test warning'
    runOneLinerExpected "import logging; logging.error('Test error')"       '##vso[task.logissue type=error]Test error' 
    runOneLinerExpected "import logging; logging.critical('Test critical')" '##vso[task.logissue type=error]Test critical'
)

echo """
Check if GitHub pipeline output is found..."""
(
    export GITHUB_ACTIONS=1
    runOneLinerExpected "import logging; logging.warning('Test warning')"   '::warning::Test warning'
    runOneLinerExpected "import logging; logging.error('Test error')"       '::error::Test error' 
    runOneLinerExpected "import logging; logging.critical('Test critical')" '::error::Test critical'
)

echo """
User defined warning"""
(
    export LOGGING_PIPELINE_WARNING_MESSAGE_FORMAT="::%(filename)s:%(lineno)d::%(levelname)s::%(message)s::"
    runOneLinerExpected "import logging; logging.warning('Test warning')" '::<string>:1::WARNING::Test warning'
)

echo """
User defined error"""
(
    export LOGGING_PIPELINE_ERROR_MESSAGE_FORMAT="::%(filename)s:%(lineno)d::%(levelname)s::%(message)s::"
    runOneLinerExpected "import logging; logging.error('Test error')"       '::<string>:1::ERROR::Test error'
    runOneLinerExpected "import logging; logging.critical('Test critical')" '::<string>:1::CRITICAL::Test critical'
)
