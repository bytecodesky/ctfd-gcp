# Service account for HMAC key generation
resource "google_service_account" "ctfd_storage" {
  account_id   = "ctfd-storage"
  display_name = "CTFd Storage Service Account"
}

# GCS bucket for CTFd uploads
resource "google_storage_bucket" "ctfd_uploads" {
  name          = "${var.s3_bucket_prefix}-${var.project_id}-uploads"
  location      = var.bucket_location
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }
}

# Grant service account access to bucket
resource "google_storage_bucket_iam_member" "ctfd_storage_admin" {
  bucket = google_storage_bucket.ctfd_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ctfd_storage.email}"
}

# Generate HMAC key for S3-compatible access
resource "google_storage_hmac_key" "ctfd_hmac_key" {
  service_account_email = google_service_account.ctfd_storage.email
}
