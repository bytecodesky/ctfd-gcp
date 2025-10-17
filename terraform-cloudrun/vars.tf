variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region for resources (e.g., us-central1)"
  default     = "us-central1"
}

variable "bucket_location" {
  type        = string
  description = "GCS bucket location (e.g., US, EU)"
  default     = "US"
}

variable "main_subnet_cidr" {
  type        = string
  description = "CIDR range for the main VPC subnet"
  default     = "10.0.0.0/24"
}

variable "access_connector_cidr" {
  type        = string
  description = "CIDR range for Serverless VPC Access connector"
  default     = "10.8.0.0/28"
}

variable "domain" {
  type        = string
  description = "Domain name for the CTFd deployment (e.g., ctf.qnqsec.team)"
  default     = "ctf.qnqsec.team"
}

variable "s3_bucket_prefix" {
  type        = string
  description = "Prefix for GCS bucket names"
  default     = "ctfd"
}

variable "ctfd" {
  type = object({
    image         = string
    min_instances = number
    max_instances = number
    cpu           = string
    memory        = string
    concurrency   = number
    theme         = string
  })
  description = "CTFd Cloud Run configuration"
  default = {
    image         = "us-central1-docker.pkg.dev/PROJECT_ID/ctfd/ctfd:latest"
    min_instances = 0
    max_instances = 100
    cpu           = "1"
    memory        = "1Gi"
    concurrency   = 70
    theme         = "qnqsec"
  }
}

variable "db" {
  type = object({
    tier    = string
    version = string
    disk_gb = number
  })
  description = "Cloud SQL Postgres configuration"
  default = {
    tier    = "db-custom-2-7680"
    version = "POSTGRES_15"
    disk_gb = 10
  }
}

variable "redis" {
  type = object({
    tier    = string
    size_gb = number
  })
  description = "Memorystore Redis configuration"
  default = {
    tier    = "STANDARD_HA"
    size_gb = 1
  }
}
