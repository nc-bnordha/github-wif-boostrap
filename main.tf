locals {
  repository = "${var.github_owner}/${var.github_repository}"

  required_services = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "run.googleapis.com"
  ])
}

data "google_project" "target" {
  project_id = var.target_project_id
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.target_project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.target_project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "Workload Identity Pool for GitHub Actions"

  depends_on = [
    google_project_service.required
  ]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.target_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub Actions"
  description                        = "OIDC provider for ${local.repository}"

  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.repository_id"       = "assertion.repository_id"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
    "attribute.repository"          = "assertion.repository"
    "attribute.ref"                 = "assertion.ref"
  }

  attribute_condition = join(" && ", [
    "assertion.repository_owner_id == '${var.github_owner_id}'",
    "assertion.repository_id == '${var.github_repository_id}'",
    "assertion.ref == '${var.allowed_ref}'"
  ])

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com/"
  }
}

resource "google_service_account" "github_deployer" {
  project      = var.target_project_id
  account_id   = var.deployment_service_account_id
  display_name = "GitHub Actions deployer"
  description  = "Service account impersonated by ${local.repository}"

  depends_on = [
    google_project_service.required
  ]
}

resource "google_service_account" "cloud_run_runtime" {
  project      = var.target_project_id
  account_id   = "cloud-run-runtime"
  display_name = "Cloud Run runtime"
  description  = "Runtime identity for the Cloud Run sample service"

  depends_on = [
    google_project_service.required
  ]
}

resource "google_service_account_iam_member" "github_impersonation" {
  service_account_id = google_service_account.github_deployer.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository_id/${var.github_repository_id}"
}

resource "google_project_iam_member" "deployment_roles" {
  for_each = var.deployment_roles

  project = var.target_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_service_account_iam_member" "deployer_can_use_runtime" {
  service_account_id = google_service_account.cloud_run_runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "local_file" "verify_workflow" {
  filename = "${path.module}/generated/verify-authentication.yaml"

  content = templatefile(
    "${path.module}/templates/verify-authentication.yaml.tftpl",
    {
      project_id                  = var.target_project_id
      repository                  = local.repository
      allowed_branch              = trimprefix(var.allowed_ref, "refs/heads/")
      workload_identity_provider = google_iam_workload_identity_pool_provider.github.name
      service_account             = google_service_account.github_deployer.email
    }
  )
}

resource "local_file" "cloud_run_workflow" {
  filename = "${path.module}/generated/deploy-cloudrun.yaml"

  content = templatefile(
    "${path.module}/templates/deploy-cloudrun.yaml.tftpl",
    {
      project_id                  = var.target_project_id
      repository                  = local.repository
      allowed_branch              = trimprefix(var.allowed_ref, "refs/heads/")
      workload_identity_provider = google_iam_workload_identity_pool_provider.github.name
      service_account             = google_service_account.github_deployer.email
      runtime_service_account     = google_service_account.cloud_run_runtime.email
      cloud_run_service           = var.cloud_run_service
      cloud_run_region            = var.cloud_run_region
      cloud_run_image             = var.cloud_run_image
    }
  )
}