#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# scripts/verify.sh — smoke test the deployed stack against LocalStack
# Usage: bash scripts/verify.sh [environment]
# -----------------------------------------------------------------------------
set -euo pipefail

ENV=${1:-local}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="floci"
ENDPOINT="http://localhost:4566"

pass() { echo "  ✓ $*"; }
fail() { echo "  ✗ $*"; exit 1; }
section() { echo ""; echo "==> $*"; }

# ---------------------------------------------------------------------------
section "1. LocalStack connectivity"
# ---------------------------------------------------------------------------
HEALTH=$(curl -s "$ENDPOINT/_localstack/health" | python3 -m json.tool 2>/dev/null || echo "{}")
echo "$HEALTH" | grep -q '"running"' && pass "LocalStack is up" || fail "LocalStack not reachable at $ENDPOINT"

# ---------------------------------------------------------------------------
section "2. Network"
# ---------------------------------------------------------------------------
VPC_ID=$(aws ec2 describe-vpcs \
  --profile "$PROFILE" \
  --filters "Name=tag:ManagedBy,Values=terragrunt" \
  --query "Vpcs[0].VpcId" --output text 2>/dev/null)
[ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ] && pass "VPC: $VPC_ID" || fail "No VPC found"

SUBNET_COUNT=$(aws ec2 describe-subnets \
  --profile "$PROFILE" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "length(Subnets)" --output text 2>/dev/null)
[ "$SUBNET_COUNT" -ge 4 ] && pass "$SUBNET_COUNT subnets found" || fail "Expected 4 subnets, got $SUBNET_COUNT"

# ---------------------------------------------------------------------------
section "3. Security groups"
# ---------------------------------------------------------------------------
SG_COUNT=$(aws ec2 describe-security-groups \
  --profile "$PROFILE" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "length(SecurityGroups[?GroupName != 'default'])" --output text 2>/dev/null)
[ "$SG_COUNT" -ge 3 ] && pass "$SG_COUNT security groups found (alb, ec2, rds)" || fail "Expected 3+ security groups, got $SG_COUNT"

# ---------------------------------------------------------------------------
section "4. IAM"
# ---------------------------------------------------------------------------
ROLE=$(aws iam list-roles \
  --profile "$PROFILE" \
  --query "Roles[?contains(RoleName, \`$ENV\`)].RoleName | [0]" --output text 2>/dev/null)
[ "$ROLE" != "None" ] && [ -n "$ROLE" ] && pass "IAM role: $ROLE" || fail "No IAM role found"

# ---------------------------------------------------------------------------
section "5. RDS"
# ---------------------------------------------------------------------------
DB=$(aws rds describe-db-instances \
  --profile "$PROFILE" \
  --query "DBInstances[0].DBInstanceIdentifier" --output text 2>/dev/null)
[ "$DB" != "None" ] && [ -n "$DB" ] && pass "RDS instance: $DB" || fail "No RDS instance found"

# ---------------------------------------------------------------------------
section "6. Secrets Manager"
# ---------------------------------------------------------------------------
SECRET=$(aws secretsmanager list-secrets \
  --profile "$PROFILE" \
  --query "SecretList[0].Name" --output text 2>/dev/null)
[ "$SECRET" != "None" ] && [ -n "$SECRET" ] && pass "Secret: $SECRET" || fail "No secret found"

# ---------------------------------------------------------------------------
section "7. ALB"
# ---------------------------------------------------------------------------
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --profile "$PROFILE" \
  --query "LoadBalancers[0].DNSName" --output text 2>/dev/null)
[ "$ALB_DNS" != "None" ] && [ -n "$ALB_DNS" ] && pass "ALB DNS: $ALB_DNS" || fail "No ALB found"

TG_COUNT=$(aws elbv2 describe-target-groups \
  --profile "$PROFILE" \
  --query "length(TargetGroups)" --output text 2>/dev/null)
[ "$TG_COUNT" -ge 1 ] && pass "$TG_COUNT target group(s) found" || fail "No target groups found"

# ---------------------------------------------------------------------------
section "8. EC2"
# ---------------------------------------------------------------------------
INSTANCE_COUNT=$(aws ec2 describe-instances \
  --profile "$PROFILE" \
  --filters "Name=instance-state-name,Values=running" \
  --query "length(Reservations[].Instances[])" --output text 2>/dev/null)
[ "$INSTANCE_COUNT" -ge 1 ] && pass "$INSTANCE_COUNT running EC2 instance(s)" || fail "No running EC2 instances"

# ---------------------------------------------------------------------------
section "9. Flask app health check via ALB"
# ---------------------------------------------------------------------------
echo "  Waiting for Flask app (up to 60s)..."
for i in $(seq 1 6); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/health" 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ]; then
    pass "GET /health → HTTP 200"
    break
  fi
  echo "  Attempt $i/6: HTTP $STATUS — retrying in 10s..."
  sleep 10
  if [ "$i" = "6" ]; then
    fail "Health check failed after 60s (last status: $STATUS)"
  fi
done

# ---------------------------------------------------------------------------
section "10. CRUD smoke test"
# ---------------------------------------------------------------------------
CREATE=$(curl -s -X POST "http://$ALB_DNS/items" \
  -H "Content-Type: application/json" \
  -d '{"name":"smoke-test","description":"automated verify"}')
ITEM_ID=$(echo "$CREATE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
[ -n "$ITEM_ID" ] && pass "POST /items → id=$ITEM_ID" || fail "Failed to create item: $CREATE"

GET=$(curl -s "http://$ALB_DNS/items/$ITEM_ID")
echo "$GET" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['id']==$ITEM_ID" 2>/dev/null \
  && pass "GET /items/$ITEM_ID → OK" || fail "Failed to read item"

UPDATE=$(curl -s -X PUT "http://$ALB_DNS/items/$ITEM_ID" \
  -H "Content-Type: application/json" \
  -d '{"description":"updated"}')
echo "$UPDATE" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['description']=='updated'" 2>/dev/null \
  && pass "PUT /items/$ITEM_ID → OK" || fail "Failed to update item"

DELETE=$(curl -s -X DELETE "http://$ALB_DNS/items/$ITEM_ID")
echo "$DELETE" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['message']=='deleted'" 2>/dev/null \
  && pass "DELETE /items/$ITEM_ID → OK" || fail "Failed to delete item"

# ---------------------------------------------------------------------------
echo ""
echo "==> All checks passed ✓"
echo "    ALB endpoint: http://$ALB_DNS"
