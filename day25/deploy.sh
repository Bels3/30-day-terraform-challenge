#!/usr/bin/env bash
# Day 25 — Static Website on AWS S3 + CloudFront
# 30-Day Terraform Challenge · Beldine Oluoch
#
# Run from: ~/terraform_30_day_challenge/
# Requirements: Terraform >= 1.9.0, AWS credentials configured
#
# ─────────────────────────────────────────────────────────────

set -euo pipefail

CHALLENGE_ROOT="$HOME/terraform_30_day_challenge"
DAY_DIR="$CHALLENGE_ROOT/day25"
ENV_DIR="$DAY_DIR/envs/dev"

echo ""
echo "══════════════════════════════════════════"
echo "  Day 25 · Static Website S3 + CloudFront"
echo "══════════════════════════════════════════"
echo ""

# ── STEP 0: verify prerequisites ──────────────────────────────
echo "[0/6] Checking prerequisites..."

if ! command -v terraform &>/dev/null; then
  echo "ERROR: terraform not found in PATH" >&2
  exit 1
fi

TF_VERSION=$(terraform version -json | python3 -c "import sys,json; print(json.load(sys.stdin)['terraform_version'])")
echo "      Terraform: v${TF_VERSION}"

if ! aws sts get-caller-identity &>/dev/null; then
  echo "ERROR: AWS credentials not configured or not valid" >&2
  exit 1
fi

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "      AWS Account: ${ACCOUNT}"
echo "      Region: eu-west-1"
echo ""

# ── STEP 1: enable TF_LOG ─────────────────────────────────────
echo "[1/6] Enabling TF_LOG=DEBUG..."

export TF_LOG=DEBUG
export TF_LOG_PATH="${DAY_DIR}/terraform-debug.log"

echo "      TF_LOG=DEBUG"
echo "      TF_LOG_PATH=${TF_LOG_PATH}"
echo "      Log will be written to: ${TF_LOG_PATH}"
echo ""

# ── STEP 2: verify backend.hcl exists ────────────────────────
echo "[2/6] Verifying backend.hcl..."

BACKEND_HCL="${DAY_DIR}/backend.hcl"

if [[ ! -f "$BACKEND_HCL" ]]; then
  echo ""
  echo "  backend.hcl not found. Creating from example..."
  cat > "$BACKEND_HCL" <<-EOF
bucket       = "terraform-state-beldine-2026"
key          = "day25/static-website/dev/terraform.tfstate"
region       = "eu-west-1"
encrypt      = true
use_lockfile = true
EOF
  echo "  Created: ${BACKEND_HCL}"
fi

echo "      backend.hcl present"
echo ""

# ── STEP 3: terraform init ────────────────────────────────────
echo "[3/6] Initializing..."
echo ""

cd "$ENV_DIR"

terraform init \
  -backend-config="${BACKEND_HCL}" \
  -reconfigure

echo ""
echo "      Init complete."
echo ""

# ── STEP 4: validate + plan ───────────────────────────────────
echo "[4/6] Validating and planning..."
echo ""

terraform validate

terraform plan \
  -out="${DAY_DIR}/day25.tfplan" \
  -detailed-exitcode || PLAN_EXIT=$?

# exit code 2 = changes to apply, that's expected
if [[ "${PLAN_EXIT:-0}" -eq 1 ]]; then
  echo "ERROR: terraform plan failed" >&2
  exit 1
fi

echo ""
echo "      Plan written to: ${DAY_DIR}/day25.tfplan"
echo ""

# ── STEP 5: apply ────────────────────────────────────────────
echo "[5/6] Applying..."
echo ""

terraform apply "${DAY_DIR}/day25.tfplan"

echo ""

# ── STEP 6: show outputs ─────────────────────────────────────
echo "[6/6] Outputs:"
echo ""

terraform output

echo ""
WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || echo "")
CF_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")

if [[ -n "$WEBSITE_URL" ]]; then
  echo "══════════════════════════════════════════"
  echo "  Live URL: ${WEBSITE_URL}"
  echo ""
  echo "  NOTE: CloudFront distributions take 5-15"
  echo "  minutes to propagate globally. If the URL"
  echo "  returns an error immediately, wait and retry."
  echo ""
  echo "  Test with:"
  echo "  curl -sI ${WEBSITE_URL} | head -5"
  echo "══════════════════════════════════════════"
fi

echo ""
echo "  TF_LOG captured to: ${TF_LOG_PATH}"
LOG_LINES=$(wc -l < "${TF_LOG_PATH}" 2>/dev/null || echo "?")
echo "  Log lines: ${LOG_LINES}"
echo ""

# ── OPTIONAL: cache invalidation helper ──────────────────────
if [[ -n "$CF_ID" ]]; then
  echo "  To invalidate CloudFront cache after content changes:"
  echo "  aws cloudfront create-invalidation \\"
  echo "    --distribution-id ${CF_ID} \\"
  echo "    --paths '/*'"
  echo ""
fi

echo "  Day 25 complete."
echo ""

