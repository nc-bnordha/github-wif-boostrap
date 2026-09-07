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
