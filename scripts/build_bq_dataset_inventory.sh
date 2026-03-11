#!/usr/bin/env bash
set -euo pipefail

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

for required_tool in bq jq yq; do
  if ! command -v "${required_tool}" >/dev/null 2>&1; then
    echo "Error: required tool '${required_tool}' is not installed or not in PATH." >&2
    exit 1
  fi
done

if [[ ! -f "${DESIRED_FILE}" ]]; then
  echo "Error: desired YAML file not found: ${DESIRED_FILE}" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

project_id="$(yq -er '.project_id' "${DESIRED_FILE}")"
bindings_json="$(yq -o=json -I=0 '.bindings // []' "${DESIRED_FILE}")"

if ! jq -e 'type == "array"' >/dev/null <<<"${bindings_json}"; then
  echo "Error: 'bindings' must be an array in ${DESIRED_FILE}" >&2
  exit 1
fi

existing_datasets_json="$(bq ls --format=json --project_id="${project_id}")"

existing_dataset_ids_json="$(
  jq -c '
    [
      .[]
      | (
          .datasetReference.datasetId
          // (
            .id
            | if type == "string" then
                (split(":")[-1] | split(".")[-1])
              else
                empty
              end
          )
        )
      | select(type == "string" and length > 0)
    ]
    | unique
  ' <<<"${existing_datasets_json}"
)"

filtered_output_json="$(
  jq -cn \
    --arg project_id "${project_id}" \
    --argjson desired_bindings "${bindings_json}" \
    --argjson existing_dataset_ids "${existing_dataset_ids_json}" '
      ($existing_dataset_ids | map({(.): true}) | add // {}) as $existing_set
      | {
          dataset_iam_bindings_filtered: [
            $desired_bindings[]
            | select(.dataset_id and ($existing_set[.dataset_id] // false))
            | {
                project_id: $project_id,
                dataset_id: .dataset_id,
                role: .role,
                members: (.members // [])
              }
          ]
        }
    '
)"

printf '%s\n' "${filtered_output_json}" | jq '.' >"${OUTPUT_FILE}"

total_desired_bindings="$(jq 'length' <<<"${bindings_json}")"
matched_bindings="$(jq '.dataset_iam_bindings_filtered | length' <<<"${filtered_output_json}")"
skipped_bindings="$((total_desired_bindings - matched_bindings))"

echo "Total desired bindings: ${total_desired_bindings}"
echo "Matched bindings: ${matched_bindings}"
echo "Skipped bindings: ${skipped_bindings}"
echo "Output file: ${OUTPUT_FILE}"
