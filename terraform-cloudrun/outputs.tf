# Load Balancer IP
output "lb_ip_address" {
  description = "Global IP address for the HTTPS load balancer"
  value       = google_compute_global_address.ctfd_lb_ip.address
}

# Cloud Run URL
output "cloudrun_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.ctfd.uri
}

# GCS Bucket
output "uploads_bucket" {
  description = "GCS bucket name for uploads"
  value       = google_storage_bucket.ctfd_uploads.name
}

# Redis connection info
output "redis_host" {
  description = "Redis instance host"
  value       = google_redis_instance.ctfd_cache.host
}

output "redis_port" {
  description = "Redis instance port"
  value       = google_redis_instance.ctfd_cache.port
}

# Cloud SQL connection
output "sql_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.ctfd_db.connection_name
}

output "sql_private_ip" {
  description = "Cloud SQL instance private IP"
  value       = google_sql_database_instance.ctfd_db.private_ip_address
}

# Domain configuration reminder
output "domain_configuration" {
  description = "DNS configuration instructions"
  value       = "Point ${var.domain} A record to ${google_compute_global_address.ctfd_lb_ip.address}"
}
