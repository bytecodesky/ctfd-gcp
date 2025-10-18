# Random SECRET_KEY for CTFd
resource "random_password" "secret_key" {
  length  = 64
  special = true
}

# Secret Manager secret for CTFd SECRET_KEY
resource "google_secret_manager_secret" "secret_key" {
  secret_id = "ctfd-secret-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_key" {
  secret      = google_secret_manager_secret.secret_key.id
  secret_data = random_password.secret_key.result
}

# Secret Manager secret for database URL (includes password)
resource "google_secret_manager_secret" "database_url" {
  secret_id = "ctfd-database-url"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = "postgresql+psycopg2://ctfd:${random_password.db_password.result}@/ctfd?host=/cloudsql/${google_sql_database_instance.postgres.connection_name}"

  depends_on = [google_sql_database_instance.postgres]
}

# Secret Manager secret for database password
resource "google_secret_manager_secret" "db_password" {
  secret_id = "ctfd-db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Secret Manager secret for AWS S3 Access Key ID (HMAC)
resource "google_secret_manager_secret" "s3_access_key" {
  secret_id = "ctfd-s3-access-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "s3_access_key" {
  secret      = google_secret_manager_secret.s3_access_key.id
  secret_data = google_storage_hmac_key.s3_key.access_id
}

# Secret Manager secret for AWS S3 Secret Access Key (HMAC)
resource "google_secret_manager_secret" "s3_secret_key" {
  secret_id = "ctfd-s3-secret-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "s3_secret_key" {
  secret      = google_secret_manager_secret.s3_secret_key.id
  secret_data = google_storage_hmac_key.s3_key.secret
}
