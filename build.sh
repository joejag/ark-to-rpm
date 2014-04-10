#!/bin/bash

NAME='ark_to_rpm'

MAJOR_VERSION=0
MINOR_VERSION=0
BUILD_REVISION=${GO_PIPELINE_COUNTER:="LocalBuild"}

VERSION_STRING="$MAJOR_VERSION.$MINOR_VERSION.$BUILD_REVISION"

test -d lib/ark_to_rpm || mkdir -p lib/ark_to_rpm

cat <<EOF > lib/ark_to_rpm/version.rb
module ArkToRpm
  VERSION = "${VERSION_STRING}"
end
EOF

rake build

fpm -s gem -t rpm --force --iteration ${BUILD_REVISION} pkg/${NAME}-${VERSION_STRING}.gem | tee rpms/fpm.log

rm -rf ./rpms
mkdir rpms
touch rpms/nolog.log

mv rubygem-${NAME}*.rpm rpms

rm -rf ./srpms
mkdir srpms
touch srpms/nolog.log
