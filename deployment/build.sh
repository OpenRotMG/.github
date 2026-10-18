set -euo pipefail
root=$PWD
bundle="$root/deploy.bundle"
cd app
revision=$(git rev-parse HEAD)
test "$revision" = "$GITHUB_SHA"
case "$GITHUB_REPOSITORY" in
  OpenRotMG/Open-RotMG-Server)
    rustup toolchain install 1.94.1 --profile minimal --component clippy,rustfmt
    cargo +1.94.1 fmt -- --check
    cargo +1.94.1 test --locked
    cargo +1.94.1 clippy --locked --all-targets -- -D warnings
    cargo +1.94.1 build --locked
    export OPENROTMG_BACKUP_BINARY="$PWD/target/debug/openrotmg"
    python3 -B -W error::ResourceWarning -m unittest discover -s scripts/backups -p 'test_*.py'
    python3 -B -m unittest discover -s scripts -p test_run.py
    python3 -B -m unittest discover -s scripts/deploy -p 'test_*.py'
    cargo +1.94.1 build --locked --release
    python3 scripts/deploy/package.py "$revision" target/release/openrotmg "$root/release"
    tar -C "$root/release" -cf "$bundle" release.json server.tar.gz
    user=openrotmg-server-deploy
    host=openrotmg-server
    command=$revision
    ;;
  OpenRotMG/Open-RotMG-Discord-Bot)
    npm ci --ignore-scripts
    npm test
    python3 -B -W error::ResourceWarning -m unittest discover -s scripts/deploy -p 'test_*.py'
    python3 -B scripts/deploy/package.py . "$revision" "$bundle"
    user=openrotmg-bot-deploy
    host=openrotmg-bot
    command=$revision
    ;;
  OpenRotMG/Open-RotMG-Website|OpenRotMG/Open-RotMG-Client)
    if [ "$GITHUB_REPOSITORY" = OpenRotMG/Open-RotMG-Website ]; then
      website=$PWD
      client="$root/client"
      git clone --quiet --depth=1 --branch main https://github.com/OpenRotMG/Open-RotMG-Client.git "$client"
    else
      client=$PWD
      website="$root/website"
      git clone --quiet --depth=1 --branch main https://github.com/OpenRotMG/Open-RotMG-Website.git "$website"
    fi
    export SITE_URL=https://openrotmg.org/ CLIENT_DIR="$client"
    python3 -B -m unittest discover -s "$client/tests" -v
    npm --prefix "$website" test
    python3 -B -W error::ResourceWarning -m unittest discover -s "$website/tools" -p 'test_*.py'
    web_revision=$(git -C "$website" rev-parse HEAD)
    client_revision=$(git -C "$client" rev-parse HEAD)
    python3 -B "$website/tools/package.py" "$website/dist" "$client" "$web_revision" "$bundle"
    user=openrotmg-website
    host=openrotmg-website
    command="$web_revision $client_revision"
    ;;
  *) echo "Unsupported deployment repository: $GITHUB_REPOSITORY" >&2; exit 1 ;;
esac
printf 'user=%s\nhost=%s\ncommand=%s\n' "$user" "$host" "$command" >> "$GITHUB_OUTPUT"
