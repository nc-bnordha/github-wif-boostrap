# GitHub Actions Workload Identity Federation Bootstrap

This Terraform configuration bootstraps keyless authentication from a specific
GitHub repository to a Google Cloud project.

It creates the Workload Identity Pool, GitHub OIDC provider, deployment service
account and required IAM bindings. It also generates two GitHub Actions
workflows:

* A workflow that verifies Google Cloud authentication
* An optional workflow that deploys Google's sample container to Cloud Run

No service account keys or GitHub secrets are required.

## What Terraform creates

The following resources are created in the target Google Cloud project:

* Required Google Cloud APIs
* Workload Identity Pool
* GitHub OIDC provider
* GitHub deployment service account
* Cloud Run runtime service account
* Workload Identity User binding
* Configurable project IAM roles
* Service Account User binding for the Cloud Run runtime account

The provider accepts tokens only when the immutable GitHub owner ID, repository
ID and selected Git reference match the configured values.

## Generated workflows

Terraform generates:

    generated/verify-authentication.yaml
    generated/deploy-cloudrun.yaml

Both workflows use manual execution through workflow_dispatch. They do not run
automatically when code is pushed.

## Prerequisites

You need:

* An existing Google Cloud project with billing enabled
* Permission to enable APIs and manage IAM in the target project
* An existing GitHub repository
* Terraform 1.5 or later
* Google Cloud CLI

Cloud Shell provides Terraform and Google Cloud CLI.

## Find the GitHub numeric IDs

For a personal GitHub account, open:

    https://api.github.com/users/GITHUB_OWNER

For a GitHub organization, open:

    https://api.github.com/orgs/GITHUB_OWNER

For the target repository, open:

    https://api.github.com/repos/GITHUB_OWNER/GITHUB_REPOSITORY

Use the numeric id value from each response. Do not use node_id.

## Configure the target

Copy the sample variables file:

    cp terraform.tfvars.example terraform.tfvars

Edit terraform.tfvars:

    # Google Cloud project where the resources will be created.
    target_project_id = "my-target-project"

    # GitHub user or organization that owns the target repository.
    github_owner = "my-github-organization"

    # Repository where the generated workflows will run.
    github_repository = "my-repository"

    # Immutable numeric GitHub IDs. Replace both sample values.
    github_owner_id      = "12345678"
    github_repository_id = "987654321"

    # Only workflows running from this Git reference may authenticate.
    allowed_ref = "refs/heads/main"

    # Names assigned to the Google Cloud WIF resources.
    pool_id     = "github"
    provider_id = "github"

    # Service account that GitHub Actions will impersonate.
    deployment_service_account_id = "github-deployer"

    # Browser supports verification. Cloud Run Admin supports the optional demo.
    deployment_roles = [
      "roles/browser",
      "roles/run.admin"
    ]

## Run the bootstrap

Verify the active Google account:

    gcloud auth list

Then run:

    terraform init
    terraform fmt -check
    terraform validate
    terraform plan
    terraform apply

Review the plan before approving it. All managed Google Cloud resources should
refer to target_project_id.

## Add a generated workflow to GitHub

Copy one or both generated files into the target repository:

    mkdir -p /path/to/repository/.github/workflows

    cp generated/verify-authentication.yaml \
      /path/to/repository/.github/workflows/

    cp generated/deploy-cloudrun.yaml \
      /path/to/repository/.github/workflows/

Commit and push:

    cd /path/to/repository
    git add .github/workflows
    git commit -m "Add keyless Google Cloud workflows"
    git push origin main

## Run a workflow manually

In GitHub:

1. Open the repository.
2. Select **Actions**.
3. Select the required workflow.
4. Select **Run workflow**.
5. Choose the main branch.
6. Select **Run workflow** again.

## Verification workflow

Run the verification workflow first. It confirms that GitHub can issue an OIDC
token, Google Cloud accepts it, service account impersonation succeeds, and the
resulting identity can inspect the target project.

## Cloud Run example

The optional workflow deploys:

    us-docker.pkg.dev/cloudrun/container/hello:latest

The defaults are:

    Service: wif-sample
    Region: asia-southeast1

The service uses the dedicated cloud-run-runtime service account. The example
makes the service publicly accessible so its URL can be tested with curl. An
organization policy may prevent public access.

## Reusing the bootstrap

Terraform tracks resources through its state. Keep the state if you intend to
run the configuration again. Use a separate workspace for each target:

    terraform workspace new TARGET_PROJECT_ID

If the workspace already exists:

    terraform workspace select TARGET_PROJECT_ID

If resources exist but are missing from the current state, Terraform cannot
adopt them automatically. Import them before applying. For example:

    terraform import \
      google_iam_workload_identity_pool.github \
      projects/TARGET_PROJECT_ID/locations/global/workloadIdentityPools/github

For long term or team use, store Terraform state in a protected remote backend.

## Security notes

* No service account keys are created.
* GitHub receives short lived credentials.
* Trust uses immutable GitHub numeric IDs.
* Authentication is restricted to the configured Git reference.
* The generated workflows run manually.
* Do not grant roles/editor or roles/owner to the deployment account.
* Review and reduce deployment_roles for real workloads.

## Cleanup

Review the destroy plan:

    terraform plan -destroy

Then remove resources managed by the current state:

    terraform destroy
