data "google_project" "this" {
  project_id = var.project_id
}

# Enable required APIs (done once per project)
resource "google_project_service" "run_api" {
  project = var.project_id
  service = "run.googleapis.com"
}

resource "google_project_service" "artifact_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

# Required for Workload Identity Federation and SA credential generation
resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"
}

resource "google_project_service" "iamcredentials_api" {
  project = var.project_id
  service = "iamcredentials.googleapis.com"
}

resource "google_project_service" "sts_api" {
  project = var.project_id
  service = "sts.googleapis.com"
}

# Create an Artifact Registry Docker repository
resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  description   = "Container images for ${var.service_name}"
  format        = "DOCKER"

  depends_on = [
    google_project_service.artifact_api
  ]
}

# Allow the default compute service account (used by Cloud Run runtime)
# to pull images from this repository
resource "google_artifact_registry_repository_iam_member" "repo_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.repo.location
  repository = google_artifact_registry_repository.repo.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_project.this.number}-compute@developer.gserviceaccount.com"
}

# Cloud Run service (fully managed)
resource "google_cloud_run_service" "service" {
  project  = var.project_id
  name     = var.service_name
  location = var.region

  template {
    spec {
      service_account_name = "${data.google_project.this.number}-compute@developer.gserviceaccount.com"
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/app/shippit:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_project_service.run_api,
    google_project_service.artifact_api,
    google_artifact_registry_repository_iam_member.repo_reader
  ]
}

# Optionally allow unauthenticated invocations
resource "google_cloud_run_service_iam_member" "invoker" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = google_cloud_run_service.service.location
  project  = var.project_id
  service  = google_cloud_run_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
