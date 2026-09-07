output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "deployment_service_account" {
  value = google_service_account.github_deployer.email
}

output "generated_workflow" {
  value = abspath(local_file.workflow.filename)
}

output "next_step" {
  value = "Copy ${var.workflow_output_path} to .github/workflows/workload.yaml in ${local.repository}"
}
