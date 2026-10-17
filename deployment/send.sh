set -euo pipefail
umask 077
key="$RUNNER_TEMP/deploy-key"
hosts="$RUNNER_TEMP/deploy-hosts"
trap 'rm -f "$key" "$hosts"' EXIT
printf '%s\n' "$DEPLOY_KEY" > "$key"
printf '%s\n' "$DEPLOY_KNOWN_HOSTS" > "$hosts"
ssh -T -i "$key" -o IdentitiesOnly=yes -o BatchMode=yes \
  -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$hosts" \
  -o HostKeyAlias="$DEPLOY_HOST" -o ConnectTimeout=60 \
  -o ServerAliveInterval=15 -o ServerAliveCountMax=4 \
  -o 'ProxyCommand=gcloud compute start-iap-tunnel openrotmg 22 --listen-on-stdin --zone=us-central1-a --project=openrotmg-20261011 --quiet' \
  "$DEPLOY_USER@openrotmg" "$DEPLOY_COMMAND" < deploy.bundle
