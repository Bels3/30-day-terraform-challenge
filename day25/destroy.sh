#!/usr/bin/env bash
# Day 25 — Destroy all resources
# Run from: ~/terraform_30_day_challenge/

set -euo pipefail

DAY_DIR="$HOME/terraform_30_day_challenge/day25"
ENV_DIR="$DAY_DIR/envs/dev"
BACKEND_HCL="$DAY_DIR/backend.hcl"

echo ""
echo "══════════════════════════════════════════"
echo "  Day 25 · Destroy"
echo "══════════════════════════════════════════"
echo ""

if [[ ! -f "$BACKEND_HCL" ]]; then
  echo "ERROR: backend.hcl not found at ${BACKEND_HCL}" >&2
  exit 1
fi

cd "$ENV_DIR"

terraform init \
  -backend-config="${BACKEND_HCL}" \
  -reconfigure \
  -input=false \
  2>&1 | tail -5

echo ""
echo "Planning destroy..."
terraform plan -destroy -out="${DAY_DIR}/day25-destroy.tfplan"

echo ""
read -r -p "Proceed with destroy? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
terraform apply "${DAY_DIR}/day25-destroy.tfplan"

echo ""
echo "══════════════════════════════════════════"
echo "  Destroy complete."
echo "══════════════════════════════════════════"
echo ""

