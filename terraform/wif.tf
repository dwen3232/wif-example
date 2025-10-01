locals {
  project_id = "development-448601"
  region     = "us-central1"
}
provider "google" {
  project = local.project_id
  region  = local.region
}

# Create a Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions workflows"
}

# Create a Workload Identity Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "attribute.repository == 'dwen3232/infra-example'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create a service account to be impersonated by the GitHub Actions
resource "google_service_account" "github_sa" {
  project      = local.project_id
  account_id   = "github-actions-sa"
  display_name = "Service Account for GitHub Actions"
}

# Allow the GitHub Actions to impersonate the service account
resource "google_service_account_iam_binding" "github_sa_binding" {
  service_account_id = google_service_account.github_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/dwen3232/infra-example"
  ]
}


