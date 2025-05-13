# Variables
variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "jf_url" {
  description = "JFrog URL"
  type        = string
}

variable "jf_access_token" {
  description = "JFrog Access Token"
  type        = string
  sensitive   = true
}

variable "repo" {
  description = "Name of the Repo to be created"
  type = string
  default = "jf-petclinic-demo"
}