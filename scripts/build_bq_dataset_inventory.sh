#!/usr/bin/env bash
set -euo pipefail

# build_bq_dataset_inventory.sh
#
# Skeleton script to generate:
# envs/<env>/generated/dataset_iam_filtered.auto.tfvars.json
#
# Responsibilities for this script (outside Terraform):
# - Read desired dataset IAM bindings from YAML.
# - List currently existing BigQuery datasets via bq CLI.
# - Intersect desired bindings with existing datasets.
# - Write filtered output in Terraform .auto.tfvars.json format.

ENVIRONMENT="${1:-dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESIRED_FILE="${REPO_ROOT}/envs/${ENVIRONMENT}/dataset_iam_desired.yaml"
OUTPUT_FILE="${REPO_ROOT}/envs/${ENVIRONMENT}/generated/dataset_iam_filtered.auto.tfvars.json"

if [[ ! -f "${DESIRED_FILE}" ]]; then
  echo "Desired file not found: ${DESIRED_FILE}" >&2
  exit 1
fi

mkdir -p "$(dirname "${OUTPUT_FILE}")"

echo "Building filtered dataset IAM inventory for environment: ${ENVIRONMENT}"
echo "Desired file: ${DESIRED_FILE}"
echo "Output file: ${OUTPUT_FILE}"

# TODO: Parse ${DESIRED_FILE} YAML to extract:
#   - project_id
#   - bindings[].dataset_id
#   - bindings[].role
#   - bindings[].members

# TODO: Use bq CLI to list existing datasets for the desired project_id.
# Example direction (not implemented):
#   bq ls --project_id="${PROJECT_ID}" --format=json

# TODO: Intersect desired bindings with existing dataset IDs.
# Keep only bindings whose dataset_id exists at runtime.

# TODO: Write filtered bindings to ${OUTPUT_FILE} as:
# {
#   "dataset_iam_bindings_filtered": [ ... ]
# }

cat > "${OUTPUT_FILE}" <<'JSON'
{
  "dataset_iam_bindings_filtered": []
}
JSON

echo "Wrote placeholder output to ${OUTPUT_FILE}"
echo "TODO: implement YAML parsing + dataset discovery + intersection logic."
