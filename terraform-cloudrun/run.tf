# Service account for Cloud Run
resource "google_service_account" "cloudrun" {
  account_id   = "ctfd-cloudrun"
  display_name = "CTFd Cloud Run Service Account"
}

# Grant Cloud Run SA access to Secret Manager secrets
resource "google_secret_manager_secret_iam_member" "secret_key_access" {
  secret_id = google_secret_manager_secret.secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "database_url_access" {
  secret_id = google_secret_manager_secret.database_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "db_password_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "s3_access_key_access" {
  secret_id = google_secret_manager_secret.s3_access_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "s3_secret_key_access" {
  secret_id = google_secret_manager_secret.s3_secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Grant Cloud Run SA access to Cloud SQL
resource "google_project_iam_member" "cloudrun_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Cloud Run v2 service
resource "google_cloud_run_v2_service" "ctfd" {
  provider = google-beta
  name     = "ctfd"
  location = var.region

  template {
    service_account = google_service_account.cloudrun.email

    scaling {
      min_instance_count = var.ctfd.min_instances
      max_instance_count = var.ctfd.max_instances
    }

    # Cloud SQL connection annotation
    annotations = {
      "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.postgres.connection_name
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = var.ctfd.image

      resources {
        limits = {
          cpu    = var.ctfd.cpu
          memory = var.ctfd.memory
        }
        cpu_idle          = false
        startup_cpu_boost = true
      }

      # Environment variables
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "REDIS_URL"
        value = "redis://${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
      }

      env {
        name  = "UPLOAD_PROVIDER"
        value = "s3"
      }

      env {
        name  = "AWS_S3_BUCKET"
        value = google_storage_bucket.uploads.name
      }

      env {
        name  = "AWS_S3_ENDPOINT_URL"
        value = "https://storage.googleapis.com"
      }

      env {
        name  = "WORKERS"
        value = tostring(2 * tonumber(var.ctfd.cpu) + 1)
      }

      env {
        name  = "REVERSE_PROXY"
        value = "2,1,0,0,0"
      }

      # Secret environment variables from Secret Manager
      env {
        name = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secret_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "AWS_ACCESS_KEY_ID"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.s3_access_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "AWS_SECRET_ACCESS_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.s3_secret_key.secret_id
            version = "latest"
          }
        }
      }

      startup_probe {
        http_get {
          path = "/themes/core/static/css/main.dev.css"
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/themes/core/static/css/main.dev.css"
        }
        initial_delay_seconds = 30
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    max_instance_request_concurrency = var.ctfd.max_concurrency
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_secret_manager_secret_version.secret_key,
    google_secret_manager_secret_version.database_url,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.s3_access_key,
    google_secret_manager_secret_version.s3_secret_key,
    google_sql_database.ctfd,
    google_sql_user.ctfd
  ]
}

# Allow unauthenticated access to Cloud Run
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.ctfd.location
  name     = google_cloud_run_v2_service.ctfd.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
