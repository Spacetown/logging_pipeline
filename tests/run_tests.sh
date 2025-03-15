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

echo """
Running tests..."""
echo "   Clear pipeline variables and ensure that output is not found."
unset TF_BUILD
unset GITHUB_ACTIONS
(
    if (
        python3 -c "import logging; logging.warning('Test warning')" 2>&1 1>&2
    ) | grep -F '##vso[task.logissue type=warning]Test warning' ; then
        echo "Found unexpected Azure pipeline output."
        exit 1
    fi
    if (
        python3 -c "import logging; logging.error('Test error')"  2>&1 1>&2
    ) | grep -F '##vso[task.logissue type=error]Test error' ; then
        echo "Found unexpected Azure pipeline output."
        exit 1
    fi
    if (
        python3 -c "import logging; logging.critical('Test critical')" 2>&1 1>&2
    ) | grep -F '##vso[task.logissue type=error]Test critical' ; then
        echo "Found unexpected Azure pipeline output."
        exit 1
    fi
)

(
    if (
        python3 -c "import logging; logging.warning('Test warning')" 2>&1 1>&2
    ) | grep -F '::warning::Test warning' ; then
        echo "Found unexpected GitHub pipeline output."
        exit 1
    fi
    if (
        python3 -c "import logging; logging.error('Test error')"  2>&1 1>&2
    ) | grep -F '::error::Test error' ; then
        echo "Found unexpected GitHub pipeline output."
        exit 1
    fi
    if (
        python3 -c "import logging; logging.critical('Test critical')" 2>&1 1>&2
    ) | grep -F '::error::Test critical' ; then
        echo "Found unexpected GitHub pipeline output."
        exit 1
    fi
)

echo "   Check if Azure pipeline output is found"
(
    export TF_BUILD=1
    (
        python3 -c "import logging; logging.warning('Test warning')" 2>&1 1>&2
    ) | grep -F '##vso[task.logissue type=warning]Test warning' > /dev/null
    (
        python3 -c "import logging; logging.error('Test error')"  2>&1 1>&2
    ) | grep -F '##vso[task.logissue type=error]Test error' > /dev/null
    (
        python3 -c "import logging; logging.critical('Test critical')" 2>&1 1>&2
    ) | grep -F '##vso[task.logissue type=error]Test critical' > /dev/null
)

echo "   Check if GitHub pipeline output is found"
(
    export GITHUB_ACTIONS=1
    (
        python3 -c "import logging; logging.warning('Test warning')" 2>&1 1>&2
    ) | grep -F '::warning::Test warning' > nul
    (
        python3 -c "import logging; logging.error('Test error')" 2>&1 1>&2
    ) | grep -F '::error::Test error' > nul
    (
        python3 -c "import logging; logging.critical('Test critical')" 2>&1 1>&2
    ) | grep -F '::error::Test critical' > nul
)
