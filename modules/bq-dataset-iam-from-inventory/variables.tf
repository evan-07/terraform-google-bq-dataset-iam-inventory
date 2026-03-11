variable "dataset_iam_bindings_filtered" {
  description = "Pre-filtered dataset IAM bindings. Input must contain only existing datasets."
  type = list(object({
    project_id = string
    dataset_id = string
    role       = string
    members    = list(string)
  }))
}
