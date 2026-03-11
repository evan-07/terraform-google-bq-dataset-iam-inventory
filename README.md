# terraform-google-bq-dataset-iam-inventory

This repository manages **BigQuery dataset IAM only** using Terraform, based on a pre-filtered dataset inventory generated outside Terraform.

## Purpose

BigQuery datasets are created and sometimes deleted manually by developers. If Terraform tries to apply IAM on deleted datasets, pipelines fail.

To prevent this, desired IAM bindings are filtered against currently existing datasets **before** Terraform runs.

## Architecture

- **Desired config (YAML)**: Source of truth per environment.
  - `envs/dev/dataset_iam_desired.yaml`
  - `envs/prod/dataset_iam_desired.yaml`
- **Inventory/filter script (Bash)**: External workflow that reads desired YAML, discovers existing datasets, and writes filtered tfvars JSON.
  - `scripts/build_bq_dataset_inventory.sh`
- **Generated filtered tfvars (JSON)**: Terraform input that should contain only valid datasets.
  - `envs/<env>/generated/dataset_iam_filtered.auto.tfvars.json`
- **Terraform module**: Applies dataset IAM bindings exactly as provided.
  - `modules/bq-dataset-iam-from-inventory`

## Prerequisites

Before running the inventory script, ensure all of the following are available:

- `bq` (BigQuery CLI)
- `jq`
- `yq` (v4 syntax)
- Authenticated Google Cloud access for the target project (for example via `gcloud auth application-default login` and/or `gcloud auth login`, with permissions to list BigQuery datasets)

## Build the filtered tfvars file

Run the script with an environment directory argument (default is `envs/dev`):

```bash
./scripts/build_bq_dataset_inventory.sh envs/dev
```

What the script does:

1. Reads `project_id` and `bindings` from `envs/<env>/dataset_iam_desired.yaml`.
2. Calls `bq ls --format=json --project_id=<project_id>` to fetch currently existing datasets.
3. Keeps only desired IAM bindings where `dataset_id` exists in BigQuery now.
4. Writes `envs/<env>/generated/dataset_iam_filtered.auto.tfvars.json` with variable name `dataset_iam_bindings_filtered`.
5. Prints a concise summary (total desired, matched, skipped, output path).

## End-to-end flow

1. Update desired IAM in `envs/<env>/dataset_iam_desired.yaml`.
2. Run `scripts/build_bq_dataset_inventory.sh envs/<env>` to generate filtered tfvars JSON.
3. Run Terraform in `envs/<env>`.
4. Module consumes `dataset_iam_bindings_filtered` and applies IAM bindings with `google_bigquery_dataset_iam_binding`.

## Scope boundaries

This repo intentionally does **not** manage:
- project-level IAM,
- bucket IAM,
- service account IAM,
- dataset creation/deletion.

It only applies IAM to datasets already validated by the external inventory process.
