# Generate random password for CTFd SECRET_KEY
resource "random_password" "ctfd_secret_key" {
  length  = 32
  special = true
}

# Generate random password for database
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secret Manager secret for CTFd SECRET_KEY
resource "google_secret_manager_secret" "ctfd_secret_key" {
  secret_id = "ctfd-secret-key"

  replication {
    auto {}
  }
}

# Store SECRET_KEY in Secret Manager
resource "google_secret_manager_secret_version" "ctfd_secret_key" {
  secret      = google_secret_manager_secret.ctfd_secret_key.id
  secret_data = random_password.ctfd_secret_key.result
}

# Secret Manager secret for database password
resource "google_secret_manager_secret" "db_password" {
  secret_id = "ctfd-db-password"

  replication {
    auto {}
  }
}

# Store database password in Secret Manager
resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Secret Manager secret for HMAC access key
resource "google_secret_manager_secret" "hmac_access_key" {
  secret_id = "ctfd-hmac-access-key"

  replication {
    auto {}
  }
}

# Store HMAC access key in Secret Manager
resource "google_secret_manager_secret_version" "hmac_access_key" {
  secret      = google_secret_manager_secret.hmac_access_key.id
  secret_data = google_storage_hmac_key.ctfd_hmac_key.access_id
}

# Secret Manager secret for HMAC secret key
resource "google_secret_manager_secret" "hmac_secret_key" {
  secret_id = "ctfd-hmac-secret-key"

  replication {
    auto {}
  }
}

# Store HMAC secret key in Secret Manager
resource "google_secret_manager_secret_version" "hmac_secret_key" {
  secret      = google_secret_manager_secret.hmac_secret_key.id
  secret_data = google_storage_hmac_key.ctfd_hmac_key.secret
}
