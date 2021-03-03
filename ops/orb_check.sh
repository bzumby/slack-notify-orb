#!/usr/bin/bash

# Exit script if you try to use an uninitialized variable.
set -o nounset
# Exit script if a statement returns a non-true return value.
set -o errexit
# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

circleci orb pack --skip-update-check src > orb.yml
yamllint orb.yml
circleci orb --skip-update-check validate orb.yml
