#!/usr/bin/bash

# Exit script if you try to use an uninitialized variable.
set -o nounset
# Exit script if a statement returns a non-true return value.
set -o errexit
# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail
set -x # debug


# SLACK_TEMPLATE_BASE64=$(echo $SLACK_TEMPLATE | jq -r '. | @base64')

# msg_64=$(cat msg.json | base64)
# msg_json_url='https://gist.githubusercontent.com/bzumby/1f9a3c2fe32ea2a06f17c04b48571a9f/raw/e3423652ca0ac4a53c294d57ce43d966fa73f3d3/success_job_temp'
# msg_64=$(echo $(curl -sfL $msg_json_url) | base64)


setup_jq_bin() {
  jq='/tmp/jq'
  curl --location --fail --silent \
      'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64' --output $jq
  chmod +x $jq
}

set_slack_channel() {
  SLACK_TEMPLATE=$(echo $SLACK_TEMPLATE | $jq ". + {\"channel\": \"$SLACK_CHANNEL\"}")
}

notify() {
  curl -s -f -X POST \
    -H 'Content-type: application/json; charset=UTF-8' \
    -H "Authorization: Bearer $SLACK_ACCESS_TOKEN" \
    --data "$SLACK_TEMPLATE" https://slack.com/api/chat.postMessage
}

setup_jq_bin
echo 'setup_jq_bin'
set_slack_channel
echo 'set_slack_channel'
notify
echo 'notify'
