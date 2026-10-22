#!/usr/bin/env bash
set -euo pipefail

EXE_TOKEN="${EXE_TOKEN:-}"
VM_NAME="${1:-t3-sandbox-$(date +%s)}"
SETUP_URL="https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/setup.sh"

if [ -z "$EXE_TOKEN" ]; then
  echo "Error: EXE_TOKEN environment variable is required."
  exit 1
fi

echo "==> [1/3] Provisioning VM: ${VM_NAME}..."
curl -s -X POST https://exe.dev/exec \
  -H "Authorization: Bearer $EXE_TOKEN" \
  -H "Content-Type: text/plain" \
  -d "new --name=${VM_NAME} --setup-script=\"curl -fsSL ${SETUP_URL} | bash\" --json" > /dev/null

echo "==> [2/3] Attaching tailscale-wif integration..."
curl -s -X POST https://exe.dev/exec \
  -H "Authorization: Bearer $EXE_TOKEN" \
  -H "Content-Type: text/plain" \
  -d "integrations attach tailscale-wif vm:${VM_NAME} --json" > /dev/null

echo "==> [3/3] Ready!"
echo "Your T3 Code workspace is loading at: https://${VM_NAME}.exe.xyz"
