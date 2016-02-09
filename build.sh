#!/bin/bash
set -e

# Get the version from the binary.
VERSION=$(awk -F\" '/^const Version/ { print $2; exit }' main.go)

# Clear out any existing build.
rm -rf pkg
rm -f docker-basetool*

# Generate the tag.
if [ -z $NOTAG ]; then
  git commit --allow-empty -a --gpg-sign=348FFC4C -m "Release v$VERSION"
  git tag -a -m "Version $VERSION" -s -u 348FFC4C "v${VERSION}" master
fi

# Build a release of the basetool in a hermetic Go build container.
docker run --rm -v "$PWD":/usr/src/docker-basetool -w /usr/src/docker-basetool \
       golang:latest sh -c "go get -d -v && CGO_ENABLED=0 go build"

# Snag the root certs out of a Debian container.
docker run --rm -v "$PWD":/usr/src/docker-basetool -w /usr/src/docker-basetool \
       debian:jessie sh -c "apt-get update && apt-get install -y ca-certificates zip && cd /etc/ssl/certs && zip /usr/src/docker-basetool/docker-basetool-certs.zip *"

# Prep the release.
mkdir -p pkg
zip -r pkg/docker-basetool_${VERSION}_linux_amd64.zip docker-basetool*
pushd pkg
shasum -a256 * > ./docker-basetool_${VERSION}_SHA256SUMS
if [ -z $NOSIGN ]; then
  gpg --default-key 348FFC4C --detach-sig ./docker-basetool_${VERSION}_SHA256SUMS
fi
popd
