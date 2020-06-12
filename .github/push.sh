# Pushes image to logged in docker registry (tagged with github ref) if logged in

IMAGE_ID=$1
REF=$2

mkdir -p ~/.docker/
touch ~/.docker/config.json
(grep -q "index.docker.io" ~/.docker/config.json)
LOGGED_OUT=$?

if [[ $LOGGED_OUT = 1 ]]; then
    echo "Not logged into docker -- not pushing"
    exit 0
fi

# Change all uppercase to lowercase
IMAGE_ID=$(echo $IMAGE_ID | tr '[A-Z]' '[a-z]')

# Strip git ref prefix from version
VERSION=$(echo "$REF" | sed -e 's,.*/\(.*\),\1,')

# Strip "v" prefix from tag name
[[ "$REF" == "refs/tags/"* ]] && VERSION=$(echo $VERSION | sed -e 's/^v//')

# Use docker `latest` tag convention
[ "$VERSION" == "master" ] && VERSION=latest

echo IMAGE_ID=$IMAGE_ID
echo VERSION=$VERSION

docker tag $IMAGE_ID $IMAGE_ID:$VERSION
docker push $IMAGE_ID:$VERSION
