# GCS bucket for CTFd uploads
resource "google_storage_bucket" "uploads" {
  name          = "${var.s3_bucket_prefix}-${var.project_id}"
  location      = var.bucket_location
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }
}

# Service account for S3-compatible access
resource "google_service_account" "s3_hmac" {
  account_id   = "ctfd-s3-hmac"
  display_name = "CTFd S3 HMAC Service Account"
}

# Grant objectAdmin role to service account on bucket
resource "google_storage_bucket_iam_member" "s3_hmac_admin" {
  bucket = google_storage_bucket.uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.s3_hmac.email}"
}

# HMAC keys for S3-compatible access
resource "google_storage_hmac_key" "s3_key" {
  service_account_email = google_service_account.s3_hmac.email
}
