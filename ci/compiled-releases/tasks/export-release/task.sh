#!/usr/bin/env bash

set -eu

#
# stemcell metadata/upload
#

tar -xzf stemcell/*.tgz $(tar -tzf stemcell/*.tgz | grep 'stemcell.MF')
STEMCELL_OS=$(grep -E '^operating_system: ' stemcell.MF | awk '{print $2}' | tr -d "\"'")
STEMCELL_VERSION=$(grep -E '^version: ' stemcell.MF | awk '{print $2}' | tr -d "\"'")

#
# release metadata/upload
#

pushd release >/dev/null
tar -xzf *.tgz $(tar -tzf *.tgz | grep 'release.MF')
RELEASE_NAME=$(grep -E '^name: ' release.MF | awk '{print $2}' | tr -d "\"'")
RELEASE_VERSION=$(grep -E '^version: ' release.MF | awk '{print $2}' | tr -d "\"'")

popd >/dev/null

releases_in_bucket=$(curl -s "https://storage.googleapis.com/bosh-compiled-release-tarballs/?prefix=${RELEASE_NAME}")
if [[ ${releases_in_bucket} == *"${RELEASE_VERSION}-${STEMCELL_OS}-${STEMCELL_VERSION}"-* ]]; then
	exit 0
fi

start-bosh
source /tmp/local-bosh/director/env
bosh -n upload-stemcell stemcell/*.tgz
pushd release >/dev/null
bosh -n upload-release *.tgz
popd >/dev/null
#
# compilation deployment
#

cat >manifest.yml <<EOF
---
name: compilation
releases:
- name: "$RELEASE_NAME"
  version: "$RELEASE_VERSION"
stemcells:
- alias: default
  os: "$STEMCELL_OS"
  version: "$STEMCELL_VERSION"
update:
  canaries: 1
  max_in_flight: 1
  canary_watch_time: 1000 - 90000
  update_watch_time: 1000 - 90000
instance_groups: []
EOF

bosh -n -d compilation deploy manifest.yml
bosh -d compilation export-release $RELEASE_NAME/$RELEASE_VERSION $STEMCELL_OS/$STEMCELL_VERSION

mv *.tgz compiled-release/$(echo *.tgz | sed "s/\.tgz$/-$(date -u +%Y%m%d%H%M%S).tgz/")
sha1sum compiled-release/*.tgz
