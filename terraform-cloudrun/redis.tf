# Memorystore Redis instance (STANDARD_HA for high availability)
resource "google_redis_instance" "cache" {
  name           = "ctfd-redis"
  tier           = var.redis.tier
  memory_size_gb = var.redis.memory_size_gb
  region         = var.region
  redis_version  = "REDIS_7_0"

  # Non-TLS for simplicity inside VPC (can enable TLS later if needed)
  transit_encryption_mode = "DISABLED"
  auth_enabled            = false

  authorized_network = google_compute_network.vpc.id
  connect_mode       = "DIRECT_PEERING"

  depends_on = [google_compute_network.vpc]
}
