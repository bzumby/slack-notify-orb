#!/usr/bin/bash

# Exit script if you try to use an uninitialized variable.
set -o nounset
# Exit script if a statement returns a non-true return value.
set -o errexit
# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail
set -x # debug


setup_jq_bin() {
  jq='/tmp/jq'
  curl --location --fail --silent \
      'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64' --output $jq
  chmod +x $jq
}

setup_template() {
  if [ -n "$SLACK_TEMPLATE_URL" ]; then
    SLACK_TEMPLATE=$(curl -sfL $SLACK_TEMPLATE_URL)
  else
    SLACK_TEMPLATE=$(eval $SLACK_TEMPLATE)
  fi
  SLACK_TEMPLATE=$(echo $SLACK_TEMPLATE | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/`/\\`/g')
}

setup_slack_channel() {
  SLACK_TEMPLATE=$(echo $SLACK_TEMPLATE | $jq ". + {\"channel\": \"$SLACK_CHANNEL\"}")
}

notify() {
  curl -s -f -X POST \
    -H 'Content-type: application/json; charset=UTF-8' \
    -H "Authorization: Bearer $SLACK_ACCESS_TOKEN" \
    --data "$SLACK_TEMPLATE" 'https://slack.com/api/chat.postMessage'
}

setup_jq_bin
setup_template
setup_slack_channel
notify
