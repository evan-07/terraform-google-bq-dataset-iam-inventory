output "applied_binding_keys" {
  description = "Unique keys for IAM bindings managed by this module."
  value       = keys(local.bindings_by_key)
}

output "applied_bindings" {
  description = "Final pre-filtered bindings consumed by this module."
  value       = values(local.bindings_by_key)
}
