#! /bin/bash
# Pushes image to logged in docker registry (tagged with github ref)

set -xe

IMAGE_ID=$1

# Change all uppercase to lowercase
IMAGE_ID=$(echo $IMAGE_ID | tr '[A-Z]' '[a-z]')

# Strip git ref prefix from version
VERSION=$(echo "${{ github.ref }}" | sed -e 's,.*/\(.*\),\1,')

# Strip "v" prefix from tag name
[[ "${{ github.ref }}" == "refs/tags/"* ]] && VERSION=$(echo $VERSION | sed -e 's/^v//')

# Use docker `latest` tag convention
[ "$VERSION" == "master" ] && VERSION=latest

echo IMAGE_ID=$IMAGE_ID
echo VERSION=$VERSION

docker tag $IMAGE_ID $IMAGE_ID:$VERSION
docker push $IMAGE_ID:$VERSION
