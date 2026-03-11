#!/usr/bin/env bash
set -euo pipefail

# build_bq_dataset_inventory.sh
#
# Generates env-specific Terraform input:
#   <env_dir>/generated/dataset_iam_filtered.auto.tfvars.json
#
# Flow:
# 1) Read desired IAM bindings from YAML.
# 2) List existing datasets in BigQuery for the same project.
# 3) Keep only bindings whose dataset_id currently exists.
# 4) Write filtered Terraform .auto.tfvars.json.

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: ${cmd}" >&2
    exit 1
  fi
}

require_cmd bq
require_cmd jq
require_cmd yq

ENV_DIR_INPUT="${1:-envs/dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${ENV_DIR_INPUT}" = /* ]]; then
  ENV_DIR="${ENV_DIR_INPUT}"
else
  ENV_DIR="${REPO_ROOT}/${ENV_DIR_INPUT}"
fi

DESIRED_FILE="${ENV_DIR}/dataset_iam_desired.yaml"
OUTPUT_DIR="${ENV_DIR}/generated"
OUTPUT_FILE="${OUTPUT_DIR}/dataset_iam_filtered.auto.tfvars.json"

if [[ ! -f "${DESIRED_FILE}" ]]; then
  echo "Error: desired YAML file not found: ${DESIRED_FILE}" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

PROJECT_ID="$(yq -r '.project_id // empty' "${DESIRED_FILE}")"
if [[ -z "${PROJECT_ID}" ]]; then
  echo "Error: project_id is missing or empty in ${DESIRED_FILE}" >&2
  exit 1
fi

# Convert desired YAML bindings into compact JSON array.
DESIRED_BINDINGS_JSON="$(
  yq -o=json '.bindings // []' "${DESIRED_FILE}" \
  | jq -c '
      if type != "array" then
        error("bindings must be an array")
      else
        map({
          dataset_id: .dataset_id,
          role: .role,
          members: (.members // [])
        })
      end
    '
)"

TOTAL_DESIRED="$(jq 'length' <<<"${DESIRED_BINDINGS_JSON}")"

# bq returns objects where dataset_id can be found in different places depending on output shape.
EXISTING_DATASET_IDS_JSON="$(
  bq ls --format=json --project_id="${PROJECT_ID}" \
  | jq -c '
      map(
        .datasetReference.datasetId
        // (if (.id | type) == "string" then (.id | split(":") | last) else null end)
      )
      | map(select(type == "string" and length > 0))
      | unique
    '
)"

FILTERED_BINDINGS_JSON="$(
  jq -c \
    --arg project_id "${PROJECT_ID}" \
    --argjson desired "${DESIRED_BINDINGS_JSON}" \
    --argjson existing_ids "${EXISTING_DATASET_IDS_JSON}" '
      $desired
      | map(select(.dataset_id as $id | $existing_ids | index($id)))
      | map({
          project_id: $project_id,
          dataset_id: .dataset_id,
          role: .role,
          members: .members
        })
    '
)"

MATCHED_BINDINGS="$(jq 'length' <<<"${FILTERED_BINDINGS_JSON}")"
SKIPPED_BINDINGS="$((TOTAL_DESIRED - MATCHED_BINDINGS))"

jq -n \
  --argjson filtered "${FILTERED_BINDINGS_JSON}" \
  '{dataset_iam_bindings_filtered: $filtered}' > "${OUTPUT_FILE}"

echo "Done."
echo "- total desired bindings: ${TOTAL_DESIRED}"
echo "- matched bindings: ${MATCHED_BINDINGS}"
echo "- skipped bindings: ${SKIPPED_BINDINGS}"
echo "- output file: ${OUTPUT_FILE}"
