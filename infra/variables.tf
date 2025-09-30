variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "shippit-473611" # TODO: remove this
}

variable "region" {
  description = "GCP region (e.g. asia-southeast2)"
  type        = string
  default     = "asia-southeast2"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "webapp"
}

variable "repository_id" {
  description = "Artifact Registry repository ID to store the container"
  type        = string
  default     = "app"
}

variable "image" {
  description = "Fully-qualified image URI to deploy (e.g. asia-southeast2-docker.pkg.dev/PROJECT/REPO/NAME:TAG)"
  type        = string
  # Default to a public sample; CI overrides this with the built image
  #default = "us-docker.pkg.dev/cloudrun/container/hello"
  #default = "asia-southeast2-docker.pkg.dev/shippit/shippit/webapp:latest"
  default = "asia-southeast2-docker.pkg.dev/shippit-473611/app/webapp:latest"
}

variable "allow_unauthenticated" {
  description = "Whether to allow public (unauthenticated) access to the service"
  type        = bool
  default     = true
}

# GitHub OIDC configuration for Workload Identity Federation
variable "github_repository" {
  description = "GitHub repository in the form OWNER/REPO for OIDC trust"
  type        = string
  default     = "andycpu/shippit" # TODO: remove this
}

variable "github_branch" {
  description = "Git branch to allow (e.g. main)"
  type        = string
  default     = "main"
}

variable "gh_sa_account_id" {
  description = "Service account ID (prefix) for GitHub deployer (letters, digits, and hyphens)"
  type        = string
  default     = "gh-actions-deployer"
}

variable "deployer_sa_email" {
  description = "Email of an existing deployer service account (overrides computed email)"
  type        = string
  default     = null
}
