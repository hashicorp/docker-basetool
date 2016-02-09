#!/bin/bash
set -e

# Get the version from the command line.
VERSION=$1
if [ -z $VERSION ]; then
    echo "Please specify a version."
    exit 1
fi

# Clear out any existing build.
rm -rf pkg
rm -f basetool*

# Generate the tag.
if [ -z $NOTAG ]; then
  git commit --allow-empty -a --gpg-sign=348FFC4C -m "Release v$VERSION"
  git tag -a -m "Version $VERSION" -s -u 348FFC4C "v${VERSION}" master
fi

# Build a release of the basetool in a hermetic Go build container.
docker run --rm -v "$PWD":/usr/src/basetool -w /usr/src/basetool \
       golang:latest sh -c "go get -d -v && CGO_ENABLED=0 go build"

# Snag the root certs out of a Debian container.
docker run --rm -v "$PWD":/usr/src/basetool -w /usr/src/basetool \
       debian:jessie sh -c "apt-get update && apt-get install -y ca-certificates zip && cd /etc/ssl/certs && zip /usr/src/basetool/basetool-certs.zip *"

# Sign the binary so it can be verified since it's going to be checked in.
shasum -a256 basetool >basetool.SHA256SUM
if [ -z $NOSIGN ]; then
    gpg --default-key 348FFC4C --detach-sig *.SHA256SUM
fi

# Prep the release.
mkdir -p pkg
zip -r pkg/docker-basetool_${VERSION}_linux_amd64.zip basetool*
pushd pkg
shasum -a256 * > ./docker-basetool_${VERSION}_SHA256SUMS
if [ -z $NOSIGN ]; then
  gpg --default-key 348FFC4C --detach-sig ./docker-basetool_${VERSION}_SHA256SUMS
fi
popd
