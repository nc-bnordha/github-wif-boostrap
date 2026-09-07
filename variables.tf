variable "target_project_id" {
  description = "Google Cloud project to configure"
  type        = string

  validation {
    condition     = length(var.target_project_id) > 0
    error_message = "target_project_id must not be empty."
  }
}

variable "github_owner" {
  description = "GitHub user or organization that owns the target repository"
  type        = string

  validation {
    condition     = length(var.github_owner) > 0
    error_message = "github_owner must not be empty."
  }
}

variable "github_repository" {
  description = "GitHub repository name without the owner"
  type        = string

  validation {
    condition     = length(var.github_repository) > 0
    error_message = "github_repository must not be empty."
  }
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub user or organization ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "github_owner_id must be a numeric GitHub ID."
  }
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "github_repository_id must be a numeric GitHub repository ID."
  }
}

variable "allowed_ref" {
  description = "Git reference permitted to authenticate"
  type        = string
  default     = "refs/heads/main"

  validation {
    condition     = startswith(var.allowed_ref, "refs/")
    error_message = "allowed_ref must start with refs/."
  }
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github"

  validation {
    condition = (
      length(var.pool_id) >= 4 &&
      length(var.pool_id) <= 32 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.pool_id)) &&
      !startswith(var.pool_id, "gcp-")
    )

    error_message = "pool_id must contain 4 to 32 lowercase letters, digits or hyphens, start with a letter, and must not start with gcp-."
  }
}

variable "provider_id" {
  description = "GitHub OIDC provider ID"
  type        = string
  default     = "github"

  validation {
    condition = (
      length(var.provider_id) >= 4 &&
      length(var.provider_id) <= 32 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.provider_id)) &&
      !startswith(var.provider_id, "gcp-")
    )

    error_message = "provider_id must contain 4 to 32 lowercase letters, digits or hyphens, start with a letter, and must not start with gcp-."
  }
}

variable "deployment_service_account_id" {
  description = "Account ID for the GitHub deployment service account"
  type        = string
  default     = "github-deployer"

  validation {
    condition = (
      length(var.deployment_service_account_id) >= 6 &&
      length(var.deployment_service_account_id) <= 30 &&
      can(regex(
        "^[a-z][a-z0-9-]*[a-z0-9]$",
        var.deployment_service_account_id
      ))
    )

    error_message = "deployment_service_account_id must contain 6 to 30 lowercase letters, digits or hyphens and start with a letter."
  }
}

variable "deployment_roles" {
  description = "Project IAM roles granted to the GitHub deployment service account"
  type        = set(string)

  default = [
    "roles/browser",
    "roles/run.admin"
  ]

  validation {
    condition = alltrue([
      for role in var.deployment_roles :
      startswith(role, "roles/")
    ])

    error_message = "Every deployment role must start with roles/."
  }
}

variable "cloud_run_service" {
  description = "Name of the sample Cloud Run service"
  type        = string
  default     = "wif-sample"

  validation {
    condition = (
      length(var.cloud_run_service) >= 1 &&
      length(var.cloud_run_service) <= 49 &&
      can(regex(
        "^[a-z][a-z0-9-]*[a-z0-9]$",
        var.cloud_run_service
      ))
    )

    error_message = "cloud_run_service must use lowercase letters, digits or hyphens and start with a letter."
  }
}

variable "cloud_run_region" {
  description = "Google Cloud region for the sample Cloud Run service"
  type        = string
  default     = "asia-southeast1"

  validation {
    condition     = length(var.cloud_run_region) > 0
    error_message = "cloud_run_region must not be empty."
  }
}

variable "cloud_run_image" {
  description = "Existing container image deployed by the Cloud Run example"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello:latest"

  validation {
    condition     = length(var.cloud_run_image) > 0
    error_message = "cloud_run_image must not be empty."
  }
}