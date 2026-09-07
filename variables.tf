variable "target_project_id" {
  description = "Google Cloud project to configure"
  type        = string
}

variable "github_owner" {
  description = "GitHub user or organization name"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name without the owner"
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub user or organization ID"
  type        = string
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID"
  type        = string
}

variable "allowed_ref" {
  description = "Git ref allowed to authenticate"
  type        = string
  default     = "refs/heads/main"
}

variable "pool_id" {
  type    = string
  default = "github"
}

variable "provider_id" {
  type    = string
  default = "github"
}

variable "deployment_service_account_id" {
  type    = string
  default = "github-deployer"
}

variable "deployment_roles" {
  description = "Project roles granted to the deployment service account"
  type        = set(string)
  default     = ["roles/browser"]
}

variable "workflow_output_path" {
  type    = string
  default = "generated/workload.yaml"
}


variable "workflow_type" {
  description = "Workflow template to generate"
  type        = string
  default     = "verify"

  validation {
    condition     = contains(["verify", "cloudrun"], var.workflow_type)
    error_message = "workflow_type must be either verify or cloudrun."
  }
}

variable "cloud_run_service" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "wif-sample"
}

variable "cloud_run_region" {
  description = "Region for the Cloud Run service"
  type        = string
  default     = "asia-southeast1"
}

variable "cloud_run_image" {
  description = "Container image deployed by the Cloud Run example"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello:latest"
}