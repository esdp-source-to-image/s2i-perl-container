#!/bin/bash -e
# $1 - Specifies distribution - RHEL7/CentOS7
# $2 - Specifies Perl version - 5.16
# TEST_MODE - If set, build a candidate image and test it

# Array of all versions of Perl
declare -a VERSIONS=(5.16)

OS=$1
VERSION=$2

function squash {
  # install the docker layer squashing tool
  easy_install --user docker-scripts==0.4.1
  base=$(awk '/^FROM/{print $2}' Dockerfile)
  $HOME/.local/bin/docker-scripts squash -f $base ${IMAGE_NAME}
}

if [ -z ${VERSION} ]; then
  # Build all versions
  dirs=${VERSIONS}
else
  # Build only specified version of Perl image
  dirs=${VERSION}
fi

for dir in ${dirs}; do
  IMAGE_NAME=openshift/perl-${dir//./}-${OS}
  if [ -v TEST_MODE ]; then
    IMAGE_NAME="${IMAGE_NAME}-candidate"
  fi
  echo ">>>> Building ${IMAGE_NAME}"

  pushd ${dir} > /dev/null

  if [ "$OS" == "rhel7" ]; then
    docker build -t ${IMAGE_NAME} -f Dockerfile.rhel7 .
  else
    docker build -t ${IMAGE_NAME} .
  fi
  [ -z "${SKIP_SQUASH}" ] && squash


  if [ -v TEST_MODE ]; then
    IMAGE_NAME=${IMAGE_NAME} test/run
  fi

  popd > /dev/null
done
