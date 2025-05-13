terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
}

# Repository create
resource "github_repository" "example_repo" {
  name        = var.repo
  description = "Repository mit geschütztem Workflow"
  visibility  = "public"
  auto_init   = true
}

# Branch Protection Rule for main
resource "github_branch_protection" "main" {
  repository_id = github_repository.example_repo.node_id
  pattern       = "main"

  required_pull_request_reviews {
    dismiss_stale_reviews      = true
    require_code_owner_reviews = true
  }

  required_status_checks {
    strict = true
  }

  allows_deletions = false
  allows_force_pushes = false

}

# Action Variable JF_URL 
resource "github_actions_variable" "jf_url" {
  repository    = github_repository.example_repo.name
  variable_name = "JF_URL"
  value         = var.jf_url
}

# Secret JF_ACCESS_TOKEN 
resource "github_actions_secret" "jf_access_token" {
  repository      = github_repository.example_repo.name
  secret_name     = "JF_ACCESS_TOKEN"
  plaintext_value = var.jf_access_token
}

# Path Restriction for Workflows
resource "github_repository_file" "workflow" {
  repository = github_repository.example_repo.name
  branch     = "main"
  file       = ".github/workflows/workflow.yml"
  content    = <<-EOT
name: Docker Build Pipeline with Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]


jobs:
  build-and-tag:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup JFrog CLI
        uses: jfrog/setup-jfrog-cli@v4
        env:
          JF_URL: $${{ vars.JF_URL }}
          JF_ACCESS_TOKEN: $${{ secrets.JF_ACCESS_TOKEN }}

      - name: Build & Test
        run: |
          # Gradle Build and Tests executions
          ./gradlew clean build test
      - name: Build Tag and push Docker Image
        env:
          IMAGE_NAME: trial3i8n2w.jfrog.io/testpet-docker/jfrog-docker-petclinic-image:$${{ github.run_number }}
        run: |
          jf docker build -t $IMAGE_NAME .
      - name: Run Xray Security Scan
        env:
          IMAGE_NAME: trial3i8n2w.jfrog.io/testpet-docker/jfrog-docker-petclinic-image:$${{ github.run_number }}
        run: |
          # Xray Scan 
          jf docker scan $IMAGE_NAME \
            --format json  > xray-results.json
      - name: Upload scan results
        uses: actions/upload-artifact@v4
        with:
          name: xray-scan-results
          path: xray-results.json
      - name: Push Docker Image
        env:
          IMAGE_NAME: trial3i8n2w.jfrog.io/testpet-docker/jfrog-docker-petclinic-image:$${{ github.run_number }}
        run: |
          jf docker push $IMAGE_NAME
      - name: Publish Build Info
        if: success()
        env:
          JFROG_CLI_BUILD_NAME: secure-docker-build
          JFROG_CLI_BUILD_NUMBER: $${{ github.run_number }}
        run: |
          jf rt build-collect-env
          jf rt build-add-git
          jf rt build-publish
EOT
}
