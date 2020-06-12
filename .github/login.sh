# Logs into docker if credentials are provided

USER=$1
PASSWD=$2

if [[ -z "$USER" ]]; then
    echo "no username provided -- not logging in"
    exit 0
fi

if [[ -z "$PASSWD" ]]; then
    echo "no password provided -- not logging in"
    exit 0
fi

echo "$PASSWD" | docker login -u "$USER" --password-stdin
