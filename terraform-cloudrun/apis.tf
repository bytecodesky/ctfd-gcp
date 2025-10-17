# Required GCP APIs
variable "gcp_services" {
  type = list(string)
  default = [
    "run.googleapis.com",
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "redis.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ]
}

# Enable required APIs
resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_services)
  project  = var.project_id
  service  = each.key

  disable_dependent_services = false
  disable_on_destroy         = false
}
