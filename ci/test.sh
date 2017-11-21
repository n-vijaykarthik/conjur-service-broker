#!/bin/bash -x

rspec --format RspecJunitFormatter --out spec/reports/test.xml --format progress
cucumber --format junit --out features/reports  --format pretty

# exit 0 so failing tests will mark the build unstable
exit 0
