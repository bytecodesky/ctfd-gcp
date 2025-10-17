# Memorystore Redis instance
resource "google_redis_instance" "ctfd_cache" {
  name           = "ctfd-cache"
  tier           = var.redis.tier
  memory_size_gb = var.redis.size_gb
  region         = var.region

  # Redis version
  redis_version = "REDIS_7_0"

  # Connect to VPC
  authorized_network = google_compute_network.ctfd_vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  # HA configuration for STANDARD_HA tier
  replica_count      = var.redis.tier == "STANDARD_HA" ? 1 : 0
  read_replicas_mode = var.redis.tier == "STANDARD_HA" ? "READ_REPLICAS_ENABLED" : null

  # Disable TLS for now as requested
  transit_encryption_mode = "DISABLED"

  depends_on = [google_service_networking_connection.private_vpc_connection]
}
