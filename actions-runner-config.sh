#!/bin/bash

set -eou pipefail



if [[ ! -f "$RUNNER_HOME/.runner" && -x "$RUNNER_HOME/config.sh" ]]; then
  "$RUNNER_HOME/config.sh" \
    --token "$RUNNER_TOKEN" \
    --work "$RUNNER_WORK_DIRECTORY" \
    --name "$RUNNER_NAME" \
    $RUNNER_REPLACE \
    $RUNNER_LABELS \
    --unattended \
    --ephemeral
else
  exit 0
fi
