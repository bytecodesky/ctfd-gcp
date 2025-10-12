output "load_balancer_ip" {
  description = "Global Load Balancer IP address - point your DNS A record here"
  value       = google_compute_global_address.lb_ip.address
}

output "cloud_run_url" {
  description = "Cloud Run service URL (direct access, bypasses load balancer)"
  value       = google_cloud_run_v2_service.ctfd.uri
}

output "uploads_bucket_name" {
  description = "GCS bucket name for CTFd uploads"
  value       = google_storage_bucket.uploads.name
}

output "redis_host" {
  description = "Redis instance host"
  value       = google_redis_instance.cache.host
}

output "redis_port" {
  description = "Redis instance port"
  value       = google_redis_instance.cache.port
}

output "sql_connection_name" {
  description = "Cloud SQL connection name (for manual connections)"
  value       = google_sql_database_instance.postgres.connection_name
}

output "sql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "domain" {
  description = "Domain configured for the load balancer"
  value       = var.domain
}

output "ssl_cert_status" {
  description = "Managed SSL certificate provisioning status"
  value       = google_compute_managed_ssl_certificate.lb_cert.managed[0]
}
