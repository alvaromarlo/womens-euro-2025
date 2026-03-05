output "datalake_bucket_name" {
  description = "Nombre del bucket del Data Lake"
  value       = google_storage_bucket.datalake.name
}

output "github_actions_sa_email" {
  description = "Email de la Service Account de GitHub Actions"
  value       = google_service_account.github_actions_sa.email
}

output "cloud_function_sa_email" {
  description = "Email de la Service Account de la Cloud Function"
  value       = google_service_account.cloud_function_sa.email
}

output "workload_identity_provider" {
  description = "Nombre completo del provider de Workload Identity (para usar en GitHub Actions)"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}
