terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = "my-gcp-project"
}

module "bq_dataset_iam_from_inventory" {
  source = "../../modules/bq-dataset-iam-from-inventory"

  dataset_iam_bindings_filtered = var.dataset_iam_bindings_filtered
}
