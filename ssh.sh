#!/usr/bin/env bash
#
# SSH into the Corvanta backend EC2 instance.
#
# The host address is read from the Terraform outputs (backend_elastic_ip,
# falling back to backend_public_ip) instead of a hardcoded IP, so it always
# matches whatever is currently deployed.
#
# This script never creates, changes, or destroys AWS resources.

set -euo pipefail

cd "$(dirname "$0")"

KEY="$HOME/.ssh/corvanta-ec2"
SSH_USER="ubuntu"

if [[ ! -f "$KEY" ]]; then
  echo "SSH private key not found: $KEY" >&2
  echo "Create it with: ssh-keygen -t ed25519 -f $KEY -C corvanta-ec2" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform CLI not found; unable to read the deployed instance address." >&2
  exit 1
fi

# Guard: refuse to use a state file that belongs to a different AWS account.
# Without this check a leftover state file would point at an instance that
# lives in another account.
state_account() {
  [[ -f terraform.tfstate ]] || return 1
  python3 - <<'PY' 2>/dev/null
import json
import sys

try:
    with open("terraform.tfstate", encoding="utf-8") as handle:
        state = json.load(handle)
except Exception:
    sys.exit(1)

for resource in state.get("resources", []):
    if resource.get("mode") != "data":
        continue
    for instance in resource.get("instances", []):
        account = (instance.get("attributes") or {}).get("account_id")
        if account:
            print(account)
            sys.exit(0)

sys.exit(1)
PY
}

STATE_ACCOUNT="$(state_account || true)"
CURRENT_ACCOUNT="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"

if [[ -n "$STATE_ACCOUNT" && -n "$CURRENT_ACCOUNT" && "$STATE_ACCOUNT" != "$CURRENT_ACCOUNT" ]]; then
  echo "Refusing to connect: the local Terraform state belongs to AWS account" >&2
  echo "$STATE_ACCOUNT but the active credentials are for account $CURRENT_ACCOUNT." >&2
  echo "Isolate the stale state before using this script." >&2
  exit 1
fi

HOST="$(terraform output -raw backend_elastic_ip 2>/dev/null || true)"

if [[ -z "$HOST" ]]; then
  HOST="$(terraform output -raw backend_public_ip 2>/dev/null || true)"
fi

if [[ -z "$HOST" ]]; then
  echo "No deployed Corvanta EC2 address found in the Terraform outputs." >&2
  echo "The backend has not been deployed yet (no backend_elastic_ip or backend_public_ip output)." >&2
  echo "Deploy the infrastructure first, then re-run this script." >&2
  exit 1
fi

# Host key verification stays at the ssh default: an unknown host key has to be
# confirmed interactively and a changed host key is always rejected.
if [[ ! -t 0 && ! -t 1 ]]; then
  echo "Refusing to connect without an interactive terminal: the first connection" >&2
  echo "requires confirmation of the host key fingerprint." >&2
  echo "Run this script from a terminal, or connect manually:" >&2
  echo "  ssh -i $KEY -o IdentitiesOnly=yes ${SSH_USER}@${HOST}" >&2
  exit 1
fi

echo "Connecting to ${SSH_USER}@${HOST} using ${KEY}"

exec ssh -i "$KEY" -o IdentitiesOnly=yes "${SSH_USER}@${HOST}" "$@"
