output "generated_workflows" {
  value = {
    verification = abspath(local_file.verify_workflow.filename)
    cloud_run    = abspath(local_file.cloud_run_workflow.filename)
  }
}