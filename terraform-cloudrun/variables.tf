variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "bucket_location" {
  description = "Location for GCS bucket (e.g., US, EU, ASIA)"
  type        = string
  default     = "US"
}

variable "main_subnet_cidr" {
  description = "CIDR range for the main VPC subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "access_connector_cidr" {
  description = "CIDR range for the Serverless VPC Access connector (must be /28)"
  type        = string
  default     = "10.8.0.0/28"
}

variable "domain" {
  description = "Domain name for the HTTPS Load Balancer (e.g., ctf.example.com)"
  type        = string
}

variable "ctfd" {
  description = "CTFd Cloud Run configuration"
  type = object({
    image           = string
    min_instances   = number
    max_instances   = number
    cpu             = string
    memory          = string
    max_concurrency = number
  })
  default = {
    image           = "ctfd/ctfd:3.7.0"
    min_instances   = 1
    max_instances   = 10
    cpu             = "2"
    memory          = "2Gi"
    max_concurrency = 80
  }
}

variable "db" {
  description = "Cloud SQL Postgres configuration"
  type = object({
    tier              = string
    disk_size_gb      = number
    availability_type = string
    postgres_version  = string
  })
  default = {
    tier              = "db-custom-2-7680"
    disk_size_gb      = 20
    availability_type = "REGIONAL"
    postgres_version  = "POSTGRES_15"
  }
}

variable "redis" {
  description = "Memorystore Redis configuration"
  type = object({
    memory_size_gb = number
    tier           = string
  })
  default = {
    memory_size_gb = 2
    tier           = "STANDARD_HA"
  }
}

variable "s3_bucket_prefix" {
  description = "Prefix for the S3-compatible GCS bucket name (will append project_id)"
  type        = string
  default     = "ctfd-uploads"
}
