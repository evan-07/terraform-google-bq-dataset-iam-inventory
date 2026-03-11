variable "dataset_iam_bindings_filtered" {
  description = "Generated and pre-filtered bindings for the dev environment."
  type = list(object({
    project_id = string
    dataset_id = string
    role       = string
    members    = list(string)
  }))
}
