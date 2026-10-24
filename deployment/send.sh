set -euo pipefail
umask 077
key="$RUNNER_TEMP/deploy-key"
hosts="$RUNNER_TEMP/deploy-hosts"
trap 'rm -f "$key" "$hosts"' EXIT
printf '%s\n' "$DEPLOY_KEY" > "$key"
cp "$(dirname -- "$0")/known_hosts" "$hosts"
ssh -T -i "$key" -o IdentitiesOnly=yes -o BatchMode=yes \
  -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$hosts" \
  -o HostKeyAlias="$DEPLOY_HOST" -o ConnectTimeout=60 \
  -o ServerAliveInterval=15 -o ServerAliveCountMax=4 \
  "$DEPLOY_USER@159.195.232.164" "$DEPLOY_COMMAND" < deploy.bundle
