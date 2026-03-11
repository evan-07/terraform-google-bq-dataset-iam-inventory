# bq-dataset-iam-from-inventory

Terraform module that applies BigQuery dataset IAM bindings from a **pre-filtered** inventory input.

## Responsibility

This module only:
- takes a list of validated dataset IAM bindings, and
- applies those bindings using `google_bigquery_dataset_iam_binding`.

This module does **not**:
- discover datasets,
- check whether datasets exist,
- manage project-level IAM, bucket IAM, or service account IAM.

## Input contract

### `dataset_iam_bindings_filtered`

A list of objects where each object has:
- `project_id` (string)
- `dataset_id` (string)
- `role` (string)
- `members` (list(string))

Expected behavior:
- Input is generated outside Terraform.
- Input contains only datasets that currently exist.
- Module creates one IAM binding resource per unique `project_id + dataset_id + role`.

## Example

```hcl
module "bq_dataset_iam" {
  source = "../../modules/bq-dataset-iam-from-inventory"

  dataset_iam_bindings_filtered = [
    {
      project_id = "my-gcp-project"
      dataset_id = "raw"
      role       = "roles/bigquery.dataViewer"
      members = [
        "group:analytics-readers@example.com",
      ]
    }
  ]
}
```
