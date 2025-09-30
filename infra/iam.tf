locals {
  # Principal used for GitHub OIDC subject scoping (OWNER/REPO)
  gh_repo = var.github_repository

  # Deployer SA email: explicit var overrides, else derive from ID + project
  deployer_sa_email = coalesce(
    var.deployer_sa_email,
    "${var.gh_sa_account_id}@${var.project_id}.iam.gserviceaccount.com",
  )

  deployer_sa_name = "projects/${var.project_id}/serviceAccounts/${local.deployer_sa_email}"
}

# Service Account for GitHub Actions to deploy with OIDC
resource "google_service_account" "gh_actions" {
  account_id   = var.gh_sa_account_id
  display_name = "GitHub Actions Deployer"
  project      = var.project_id

  depends_on = [
    google_project_service.iam_api
  ]
}

# Grant project-level roles to the deployer SA (simple, permissive set)
resource "google_project_iam_member" "gh_actions_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${local.deployer_sa_email}"
}

resource "google_project_iam_member" "gh_actions_artifact_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${local.deployer_sa_email}"
}

resource "google_project_iam_member" "gh_actions_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.deployer_sa_email}"
}

resource "google_project_iam_member" "gh_actions_serviceusage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${local.deployer_sa_email}"
}

# Workload Identity Federation pool + provider for GitHub OIDC
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  disabled                  = false

  depends_on = [
    google_project_service.iam_api
  ]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id           = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id  = "github"
  display_name                        = "GitHub OIDC"
  disabled                            = false

  attribute_mapping = {
    "google.subject"      = "assertion.sub"
    "attribute.actor"     = "assertion.actor"
    "attribute.aud"       = "assertion.aud"
    "attribute.repository"= "assertion.repository"
    "attribute.ref"       = "assertion.ref"
  }

  # Restrict to your repo and branch
  #attribute_condition = "attribute.repository == \"${local.gh_repo}\""
  attribute_condition = "attribute.repository == \"${local.gh_repo}\" && attribute.ref == \"refs/heads/${var.github_branch}\""
  #attribute_condition = "attribute.repository == \"${local.gh_repo}\" && (attribute.ref == \"refs/heads/${var.github_branch}\" || string(attribute.ref).startsWith(\"refs/pull/\"))"


  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  depends_on = [
    google_project_service.iam_api,
    google_project_service.sts_api
  ]
}

# Allow identities from the GitHub provider to impersonate the SA
resource "google_service_account_iam_member" "wif" {
  service_account_id = local.deployer_sa_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.gh_repo}"
}

# Allow the deployer SA to act as the Cloud Run runtime SA (default compute SA)
resource "google_service_account_iam_member" "deployer_actas_compute" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.this.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.deployer_sa_email}"
}

resource "google_project_iam_member" "deployer_sa_user_project" { 
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.deployer_sa_email}"
  depends_on = [
    google_service_account.gh_actions,
  ]
}
