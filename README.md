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

## Inventory script

### Prerequisites

- `bq` CLI installed and authenticated.
- `jq` installed.
- `yq` installed.
- Access configured for the target GCP project (`gcloud auth` / `bq` auth context).

### Usage

```bash
./scripts/build_bq_dataset_inventory.sh envs/dev
```

Default environment directory is `envs/dev` when no argument is provided.

### What the script does

1. Reads `project_id` and `bindings` from `<env_dir>/dataset_iam_desired.yaml`.
2. Lists existing datasets using `bq ls --format=json --project_id=<project_id>`.
3. Filters desired bindings to keep only entries where `dataset_id` exists in BigQuery.
4. Writes `<env_dir>/generated/dataset_iam_filtered.auto.tfvars.json` with:
   - `dataset_iam_bindings_filtered`
5. Prints a concise summary with total desired, matched, and skipped bindings.

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
