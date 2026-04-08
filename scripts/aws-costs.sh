#!/usr/bin/env bash
# Pulls AWS cost data for specific services across all SSO profiles.
# Requires: aws-sso, aws CLI, jq
#
# Usage:
#   ./scripts/aws-costs.sh                          # last 30 days, all services, all accounts
#   ./scripts/aws-costs.sh --days 7                 # last 7 days
#   ./scripts/aws-costs.sh --service "Amazon S3"    # filter to S3 only
#   ./scripts/aws-costs.sh --service "Amazon S3" --service "Amazon EC2" --days 14
#   ./scripts/aws-costs.sh --profile analytical-platform-compute-production:platform-engineer-admin
#   ./scripts/aws-costs.sh --account 381491960855   # specific AWS account ID
#   ./scripts/aws-costs.sh --account 381491960855 --account 992382429243
#   ./scripts/aws-costs.sh --match compute          # all accounts matching "compute"
#   ./scripts/aws-costs.sh --match "data-engineering|ingestion"  # regex match

set -euo pipefail

log() { echo "[INFO] $*" >&2; }
warn() { echo "[WARN] $*" >&2; }

DAYS=30
SERVICES=()
PROFILES=()
ACCOUNTS=()
MATCH_PATTERN=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)
      DAYS="$2"
      shift 2
      ;;
    --service)
      SERVICES+=("$2")
      shift 2
      ;;
    --profile)
      PROFILES+=("$2")
      shift 2
      ;;
    --account)
      ACCOUNTS+=("$2")
      shift 2
      ;;
    --match)
      MATCH_PATTERN="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --list-services)
      # Need credentials from at least one account to query Cost Explorer
      # Use the first available preferred-role profile
      PREFERRED_ROLES=("platform-engineer-admin" "AdministratorAccess")
      mapfile -t _ALL < <(aws-sso list --csv 2>/dev/null | tail -n +2)
      _PROF=""
      for _LINE in "${_ALL[@]}"; do
        _ROLE=$(echo "$_LINE" | cut -d',' -f3)
        for _R in "${PREFERRED_ROLES[@]}"; do
          if [[ "$_ROLE" == "$_R" ]]; then
            _PROF=$(echo "$_LINE" | cut -d',' -f4)
            break 2
          fi
        done
      done
      if [[ -z "$_PROF" ]]; then
        echo "No suitable SSO profile found. Run 'aws-sso login' first." >&2
        exit 1
      fi
      echo "Fetching service list from Cost Explorer..." >&2
      eval "$(aws-sso eval --profile "$_PROF" 2>/dev/null)"
      aws ce get-dimension-values \
        --region us-east-1 \
        --time-period "Start=$(date -u -d '30 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d)" \
        --dimension SERVICE \
        --output json 2>&1 \
      | jq -r '.DimensionValues[].Value' | sort
      exit 0
      ;;
    --help|-h)
      head -11 "$0" | tail -9
      echo ""
      echo "Options:"
      echo "  --days N          Number of days to look back (default: 30)"
      echo "  --service NAME    Filter to specific service (repeatable)"
      echo "  --profile NAME    Specific SSO profile to query (repeatable; default: all)"
      echo "  --account ID      Filter to specific AWS account ID (repeatable)"
      echo "  --match PATTERN   Filter accounts by regex match on account alias (e.g. 'compute')"
      echo "  --output FILE     Write CSV output to file"
      echo "  --list-services   List available service names for --service filter"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

END_DATE=$(date -u +%Y-%m-%d)
START_DATE=$(date -u -d "${DAYS} days ago" +%Y-%m-%d)

# Use DAILY granularity for ranges up to 31 days, MONTHLY otherwise
if [[ $DAYS -le 31 ]]; then
  GRANULARITY=DAILY
else
  GRANULARITY=MONTHLY
fi

log "Date range: ${START_DATE} to ${END_DATE} (${DAYS} days, ${GRANULARITY})"
[[ ${#SERVICES[@]} -gt 0 ]] && log "Service filter: ${SERVICES[*]}"
[[ ${#ACCOUNTS[@]} -gt 0 ]] && log "Account filter: ${ACCOUNTS[*]}"
[[ -n "$MATCH_PATTERN" ]] && log "Match pattern: ${MATCH_PATTERN}"

# Build the Cost Explorer filter for specific services
build_filter() {
  if [[ ${#SERVICES[@]} -eq 0 ]]; then
    echo "{}"
  elif [[ ${#SERVICES[@]} -eq 1 ]]; then
    jq -n --arg svc "${SERVICES[0]}" \
      '{"Dimensions": {"Key": "SERVICE", "Values": [$svc]}}'
  else
    jq -n --jsonargs \
      '{"Dimensions": {"Key": "SERVICE", "Values": $ARGS.positional}}' \
      -- "${SERVICES[@]}"
  fi
}

FILTER=$(build_filter)

# Validate --service names against Cost Explorer if any were specified
if [[ ${#SERVICES[@]} -gt 0 ]]; then
  log "Validating service name(s)..."

  # Get credentials from the first available preferred-role profile
  _PREFERRED_ROLES=("platform-engineer-admin" "AdministratorAccess")
  mapfile -t _VAL_PROFILES < <(aws-sso list --csv 2>/dev/null | tail -n +2)
  _VAL_PROF=""
  for _LINE in "${_VAL_PROFILES[@]}"; do
    _ROLE=$(echo "$_LINE" | cut -d',' -f3)
    for _R in "${_PREFERRED_ROLES[@]}"; do
      if [[ "$_ROLE" == "$_R" ]]; then
        _VAL_PROF=$(echo "$_LINE" | cut -d',' -f4)
        break 2
      fi
    done
  done

  if [[ -n "$_VAL_PROF" ]]; then
    eval "$(aws-sso eval --profile "$_VAL_PROF" 2>/dev/null)"
    VALID_SERVICES=$(aws ce get-dimension-values \
      --region us-east-1 \
      --time-period "Start=${START_DATE},End=${END_DATE}" \
      --dimension SERVICE \
      --output json 2>/dev/null \
    | jq -r '.DimensionValues[].Value') || VALID_SERVICES=""

    if [[ -n "$VALID_SERVICES" ]]; then
      INVALID=()
      for SVC in "${SERVICES[@]}"; do
        if ! echo "$VALID_SERVICES" | grep -qxF "$SVC"; then
          INVALID+=("$SVC")
        fi
      done
      if [[ ${#INVALID[@]} -gt 0 ]]; then
        echo "Error: invalid service name(s):" >&2
        for I in "${INVALID[@]}"; do
          echo "  - \"$I\"" >&2
        done
        echo "" >&2
        echo "Run --list-services to see valid names. Common mistakes:" >&2
        echo "  \"Amazon S3\" should be \"Amazon Simple Storage Service\"" >&2
        echo "  \"Amazon EC2\" should be \"Amazon Elastic Compute Cloud - Compute\"" >&2
        exit 1
      fi
      log "Service name(s) validated"
    else
      warn "Could not fetch service list for validation, proceeding anyway"
    fi
  else
    warn "No profile available for service validation, proceeding anyway"
  fi
fi

# Get list of profiles
if [[ ${#PROFILES[@]} -eq 0 ]]; then
  PREFERRED_ROLES=("platform-engineer-admin" "AdministratorAccess")
  mapfile -t ALL_PROFILES < <(aws-sso list --csv 2>/dev/null | tail -n +2 | sort -t',' -k4 -u)

  # Track which accounts we've already added a profile for
  declare -A SEEN_ACCOUNTS

  for LINE in "${ALL_PROFILES[@]}"; do
    ACCT_ID=$(echo "$LINE" | cut -d',' -f1)
    ACCT_ALIAS=$(echo "$LINE" | cut -d',' -f2)
    ROLE_NAME=$(echo "$LINE" | cut -d',' -f3)
    PROF=$(echo "$LINE" | cut -d',' -f4)

    # Only use preferred roles
    ROLE_OK=false
    for R in "${PREFERRED_ROLES[@]}"; do
      if [[ "$ROLE_NAME" == "$R" ]]; then
        ROLE_OK=true
        break
      fi
    done
    if [[ "$ROLE_OK" != "true" ]]; then
      continue
    fi

    # If --account specified, only include matching account IDs
    if [[ ${#ACCOUNTS[@]} -gt 0 ]]; then
      MATCHED=false
      for A in "${ACCOUNTS[@]}"; do
        if [[ "$ACCT_ID" == "$A" ]]; then
          MATCHED=true
          break
        fi
      done
      if [[ "$MATCHED" != "true" ]]; then
        continue
      fi
    fi

    # If --match specified, only include accounts whose alias matches the pattern
    if [[ -n "$MATCH_PATTERN" ]]; then
      if ! echo "$ACCT_ALIAS" | grep -qiE "$MATCH_PATTERN"; then
        continue
      fi
    fi

    # Only add one profile per account (first preferred role wins)
    if [[ -z "${SEEN_ACCOUNTS[$ACCT_ID]:-}" ]]; then
      PROFILES+=("$PROF")
      SEEN_ACCOUNTS[$ACCT_ID]=1
    fi
  done
fi

if [[ ${#PROFILES[@]} -eq 0 ]]; then
  echo "No SSO profiles found. Run 'aws-sso login' first." >&2
  exit 1
fi

log "Found ${#PROFILES[@]} profile(s) to query"

# Print header
HEADER="Account,Service,Cost (USD),Currency,Period"
echo "$HEADER"
[[ -n "$OUTPUT_FILE" ]] && echo "$HEADER" > "$OUTPUT_FILE"

for PROFILE in "${PROFILES[@]}"; do
  ACCOUNT_ALIAS="${PROFILE%%:*}"

  log "[${ACCOUNT_ALIAS}] Fetching credentials via aws-sso eval..."
  CREDS=$(aws-sso eval --profile "$PROFILE" 2>&1) || {
    warn "[${ACCOUNT_ALIAS}] Failed to get credentials: ${CREDS}"
    continue
  }
  eval "$CREDS"
  log "[${ACCOUNT_ALIAS}] Credentials obtained, querying Cost Explorer..."

  CE_ARGS=(
    ce get-cost-and-usage
    --region us-east-1
    --time-period "Start=${START_DATE},End=${END_DATE}"
    --granularity "${GRANULARITY}"
    --metrics BlendedCost
    --group-by "Type=DIMENSION,Key=SERVICE"
  )

  if [[ "$FILTER" != "{}" ]]; then
    CE_ARGS+=(--filter "$FILTER")
  fi

  RESULT=$(aws "${CE_ARGS[@]}" 2>&1) || {
    warn "[${ACCOUNT_ALIAS}] Cost Explorer query failed: ${RESULT}"
    continue
  }

  # Parse and output
  LINES=$(echo "$RESULT" | jq -r --arg acct "$ACCOUNT_ALIAS" '
    .ResultsByTime[] |
    .TimePeriod.Start as $period |
    .Groups[] |
    [$acct, .Keys[0], .Metrics.BlendedCost.Amount, .Metrics.BlendedCost.Unit, $period] |
    @csv
  ')

  if [[ -n "$LINES" ]]; then
    NUM_LINES=$(echo "$LINES" | wc -l)
    log "[${ACCOUNT_ALIAS}] Got ${NUM_LINES} result(s)"
    echo "$LINES"
    [[ -n "$OUTPUT_FILE" ]] && echo "$LINES" >> "$OUTPUT_FILE"
  else
    log "[${ACCOUNT_ALIAS}] No cost data returned for this period"
  fi
done

log "Done."
