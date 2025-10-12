# Service account for Cloud Run
resource "google_service_account" "ctfd_cloudrun" {
  account_id   = "ctfd-cloudrun"
  display_name = "CTFd Cloud Run Service Account"
}

# Grant Cloud Run service account access to Secret Manager
resource "google_secret_manager_secret_iam_member" "ctfd_secret_key_access" {
  secret_id = google_secret_manager_secret.ctfd_secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.ctfd_cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "db_password_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.ctfd_cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "hmac_access_key_access" {
  secret_id = google_secret_manager_secret.hmac_access_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.ctfd_cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "hmac_secret_key_access" {
  secret_id = google_secret_manager_secret.hmac_secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.ctfd_cloudrun.email}"
}

# Grant Cloud Run service account access to Cloud SQL
resource "google_project_iam_member" "ctfd_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.ctfd_cloudrun.email}"
}

# Cloud Run v2 service
resource "google_cloud_run_v2_service" "ctfd" {
  name     = "ctfd"
  location = var.region

  template {
    service_account = google_service_account.ctfd_cloudrun.email

    scaling {
      min_instance_count = var.ctfd.min_instances
      max_instance_count = var.ctfd.max_instances
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    # Cloud SQL connection annotation
    annotations = {
      "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.ctfd_db.connection_name
    }

    containers {
      image = var.ctfd.image

      resources {
        limits = {
          cpu    = var.ctfd.cpu
          memory = var.ctfd.memory
        }
      }

      # Port configuration
      ports {
        container_port = 8080
      }

      # Startup probe for health check
      startup_probe {
        http_get {
          path = "/themes/core/static/css/main.dev.css"
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
      }

      # Environment variables
      env {
        name  = "REDIS_URL"
        value = "redis://${google_redis_instance.ctfd_cache.host}:${google_redis_instance.ctfd_cache.port}"
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql+psycopg2://ctfd:${random_password.db_password.result}@/${google_sql_database.ctfd.name}?host=/cloudsql/${google_sql_database_instance.ctfd_db.connection_name}"
      }

      env {
        name  = "UPLOAD_PROVIDER"
        value = "s3"
      }

      env {
        name = "AWS_ACCESS_KEY_ID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.hmac_access_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "AWS_SECRET_ACCESS_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.hmac_secret_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "AWS_S3_BUCKET"
        value = google_storage_bucket.ctfd_uploads.name
      }

      env {
        name  = "AWS_S3_ENDPOINT_URL"
        value = "https://storage.googleapis.com"
      }

      env {
        name = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.ctfd_secret_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "WORKERS"
        value = tostring(2 * tonumber(var.ctfd.cpu) + 1)
      }

      env {
        name  = "REVERSE_PROXY"
        value = "1,0,0,0,0"
      }

      env {
        name  = "CTFD_THEME"
        value = var.ctfd.theme
      }

      env {
        name  = "WORKER_PORT"
        value = "8080"
      }

      env {
        name  = "WORKER_TIMEOUT"
        value = "300"
      }
    }

    max_instance_request_concurrency = var.ctfd.concurrency
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_secret_manager_secret_version.ctfd_secret_key,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.hmac_access_key,
    google_secret_manager_secret_version.hmac_secret_key,
  ]
}

# Allow unauthenticated access to Cloud Run
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  name     = google_cloud_run_v2_service.ctfd.name
  location = google_cloud_run_v2_service.ctfd.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
