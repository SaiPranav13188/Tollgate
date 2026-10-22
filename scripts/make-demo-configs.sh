#!/bin/bash
# Writes the EvalSet configs, with FAKE secrets filled in, to a demo folder you can add in Tollgate.
# Usage: scripts/make-demo-configs.sh [output-folder]   (default: build/demo-configs)
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/build/demo-configs}"
fixtures="$out/fixtures"
mkdir -p "$out" "$fixtures/world-writable" "$fixtures/owner-only" "$fixtures/scripts" "$fixtures/shared-dir"
printf '#!/bin/sh\n' > "$fixtures/world-writable/server"; chmod 777 "$fixtures/world-writable/server"
printf '#!/bin/sh\n' > "$fixtures/owner-only/server";     chmod 755 "$fixtures/owner-only/server"
printf '//\n' > "$fixtures/scripts/index.js";              chmod 666 "$fixtures/scripts/index.js"
printf '#\n'  > "$fixtures/shared-dir/server.py";          chmod 775 "$fixtures/shared-dir"

rep() { printf '%*s' "$2" '' | sed "s/ /$1/g"; }   # repeat a string N times
fake_github="ghp_$(rep FAKE0 8)"
fake_github_pat="github_pat_11FAKE0000_$(rep FAKEfake 7)"
fake_aws="AKIAFAKEFAKEFAKEFAKE"
fake_google="AIza$(rep Fake_ 7)"
fake_anthropic="sk-ant-api03-$(rep fakeFAKE 5)"
fake_openai="sk-proj-$(rep FakeFake 5)"
fake_slack="xoxb-000000000000-0000000000000-$(rep FAKEfake 3)"
fake_hex="f4ke$(rep 0123456789abcdef 2)f4ke"
fake_pem='-----BEGIN OPENSSH PRIVATE KEY-----\\nFAKEFAKEFAKEFAKE\\n-----END OPENSSH PRIVATE KEY-----'

for f in "$root"/EvalSet/configs/*.json; do
  name="$(basename "$f" .json)"
  mkdir -p "$out/$name"
  sed -e "s|{{HOME}}|$HOME|g" -e "s|{{FIXTURES}}|$fixtures|g" \
      -e "s|{{FAKE_GITHUB_PAT}}|$fake_github_pat|g" -e "s|{{FAKE_GITHUB}}|$fake_github|g" \
      -e "s|{{FAKE_AWS}}|$fake_aws|g" -e "s|{{FAKE_GOOGLE}}|$fake_google|g" \
      -e "s|{{FAKE_ANTHROPIC}}|$fake_anthropic|g" -e "s|{{FAKE_OPENAI}}|$fake_openai|g" \
      -e "s|{{FAKE_SLACK}}|$fake_slack|g" -e "s|{{FAKE_HEX}}|$fake_hex|g" \
      -e "s|{{FAKE_PRIVATE_KEY}}|$fake_pem|g" "$f" > "$out/$name/.mcp.json"
done
echo "Wrote $(ls -d "$out"/*/ | grep -vc fixtures) demo projects to $out"
echo "In Tollgate: Add Config... and pick any of those folders (or the .mcp.json inside)."
