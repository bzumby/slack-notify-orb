
#!/bin/bash

circleci orb pack --skip-update-check src > orb.yml
yamllint orb.yml
circleci orb --skip-update-check validate orb.yml
