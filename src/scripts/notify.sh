#!/usr/bin/bash

# Exit script if you try to use an uninitialized variable.
set -o nounset
# Exit script if a statement returns a non-true return value.
set -o errexit
# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail
set -x # debug

set_jq_bin() {
  jq='/tmp/jq'
  curl --location --fail --silent \
      'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64' --output $jq
  chmod +x $jq
}

process_template() {
  url_regex='^(https|http|file):\/\/.*'
  if [[ $SLACK_TEMPLATE =~ $url_regex ]]; then
    # re-assign
    SLACK_TEMPLATE=$(curl -sfL "$SLACK_TEMPLATE")
    # shellcheck disable=SC2016
    SLACK_TEMPLATE=$(echo "$SLACK_TEMPLATE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/`/\\`/g')
  else
    # string to var
    SLACK_TEMPLATE="\$$SLACK_TEMPLATE"
    SLACK_TEMPLATE=$(eval echo "$SLACK_TEMPLATE" | sed 's/"/\\"/g')
  fi
  # substitute vars & add channel ID
  SLACK_TEMPLATE=$(eval echo \""$SLACK_TEMPLATE"\")
  SLACK_TEMPLATE=$(echo "$SLACK_TEMPLATE" | $jq ". + {\"channel\": \"$SLACK_CHANNEL\"}")
}

choose_template() {
  declare -A state=( ["pass"]=$PASS_TEMPLATE ["fail"]=$FAIL_TEMPLATE )
  if [ -n "$SLACK_CONDITION" ]; then
    echo "Sate: event($SLACK_CONDITION) vs status($CCI_STATUS)"
    if [[ "$SLACK_CONDITION" == "$CCI_STATUS" ]]; then
      echo 'Sending notification!'
      if [ -z "$SLACK_TEMPLATE" ]; then
        SLACK_TEMPLATE="${state[$SLACK_CONDITION]}"
      fi
    else
      echo 'Skipping notification!'
      exit 0
    fi
  else
    echo "Default: sending '$CCI_STATUS' notification!"
    if [ -z "$SLACK_TEMPLATE" ]; then
      SLACK_TEMPLATE="${state[$CCI_STATUS]}"
    fi
  fi
}

notify() {
for i in ${SLACK_CHANNEL/,/ }
do
  # shellcheck disable=SC2016
  SLACK_TEMPLATE=$(echo "$SLACK_TEMPLATE" | $jq --arg channel "$i" '.channel = $channel')
  curl -s -f -X POST \
    -H 'Content-type: application/json; charset=UTF-8' \
    -H "Authorization: Bearer $SLACK_ACCESS_TOKEN" \
    --data "$SLACK_TEMPLATE" 'https://slack.com/api/chat.postMessage'
done
}

set_jq_bin
choose_template
process_template
notify
