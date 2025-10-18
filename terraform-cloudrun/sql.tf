# Allocate IP address range for Private Service Connect
resource "google_compute_global_address" "private_ip_range" {
  provider      = google-beta
  name          = "ctfd-sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Private Service Connect connection to Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

# Random suffix for DB instance name (allows destroy/recreate)
resource "random_id" "db_suffix" {
  byte_length = 4
}

# Random password for database user
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Cloud SQL PostgreSQL instance (regional HA)
resource "google_sql_database_instance" "postgres" {
  provider            = google-beta
  name                = "ctfd-db-${random_id.db_suffix.hex}"
  database_version    = var.db.postgres_version
  region              = var.region
  deletion_protection = false

  settings {
    tier              = var.db.tier
    disk_size         = var.db.disk_size_gb
    disk_type         = "PD_SSD"
    availability_type = var.db.availability_type

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database for CTFd
resource "google_sql_database" "ctfd" {
  name     = "ctfd"
  instance = google_sql_database_instance.postgres.name
}

# Database user
resource "google_sql_user" "ctfd" {
  name     = "ctfd"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}
