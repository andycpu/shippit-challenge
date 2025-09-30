output "service_url" {
  description = "Deployed Cloud Run service URL"
  value       = try(google_cloud_run_service.service.status[0].url, null)
}

output "repository_path" {
  description = "Artifact Registry repository path"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}"
}

output "deployer_service_account_email" {
  description = "Email of the GitHub Actions deployer service account"
  value       = local.deployer_sa_email
}

output "workload_identity_pool_name" {
  description = "Full name of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.github.name
}

output "workload_identity_provider_name" {
  description = "Full name of the Workload Identity Provider for GitHub"
  value       = google_iam_workload_identity_pool_provider.github.name
}
