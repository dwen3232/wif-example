provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_iam_workload_identity_pool" "example-wif-pool" {
  workload_identity_pool_id = "example-wif-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions workflows"
}

resource "google_iam_workload_identity_pool_provider" "example-provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.example-wif-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "example-provider"
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.workflow"   = "assertion.workflow"
  }

  attribute_condition = <<-EOT
    assertion.repository == 'dwen3232/wif-example' && 
    assertion.ref == 'refs/heads/main' && 
    assertion.workflow == 'Example WIF'
  EOT

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create a service account to be impersonated by the GitHub Actions
resource "google_service_account" "github_sa" {
  project      = var.project_id
  account_id   = "sa-wif-example"
  display_name = "Service Account for GitHub Actions"
}

# Allow the GitHub Actions to impersonate the service account
resource "google_service_account_iam_binding" "github_sa_binding" {
  service_account_id = google_service_account.github_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.example-wif-pool.name}/attribute.repository/dwen3232/wif-example"
  ]
}
