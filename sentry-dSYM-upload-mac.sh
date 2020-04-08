#!/bin/sh

DWARF_DSYM_FOLDER_PATH=$WORKSPACE/dist/symbols

if which sentry-cli >/dev/null; then
    export SENTRY_ORG=flightgear
    export SENTRY_PROJECT=flightgear
  #  export SENTRY_AUTH_TOKEN=YOUR_AUTH_TOKEN
    ERROR=$(sentry-cli upload-dif "$DWARF_DSYM_FOLDER_PATH" 2>&1 >/dev/null)
    if [ ! $? -eq 0 ]; then
        echo "warning: sentry-cli - $ERROR"
    fi
else
    echo "warning: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
fi