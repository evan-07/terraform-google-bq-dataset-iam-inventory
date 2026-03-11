locals {
  # One IAM binding resource per unique project_id + dataset_id + role.
  bindings_by_key = {
    for binding in var.dataset_iam_bindings_filtered :
    "${binding.project_id}/${binding.dataset_id}/${binding.role}" => binding
  }
}

resource "google_bigquery_dataset_iam_binding" "this" {
  for_each = local.bindings_by_key

  project    = each.value.project_id
  dataset_id = each.value.dataset_id
  role       = each.value.role
  members    = each.value.members
}
