# Random suffix for Cloud SQL instance name
resource "random_id" "db_suffix" {
  byte_length = 4
}

# Cloud SQL Postgres instance with Private IP
resource "google_sql_database_instance" "ctfd_db" {
  name             = "ctfd-db-${random_id.db_suffix.hex}"
  region           = var.region
  database_version = var.db.version

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.db.tier
    disk_size         = var.db.disk_gb
    disk_type         = "PD_SSD"
    availability_type = "REGIONAL" # Regional HA

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.ctfd_vpc.id
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 3
      update_track = "stable"
    }
  }

  deletion_protection = false
}

# Database for CTFd
resource "google_sql_database" "ctfd" {
  name     = "ctfd"
  instance = google_sql_database_instance.ctfd_db.name
  charset  = "UTF8"
}

# Database user
resource "google_sql_user" "ctfd" {
  name     = "ctfd"
  instance = google_sql_database_instance.ctfd_db.name
  password = random_password.db_password.result
}
