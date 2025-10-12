# Reserve global IP address for load balancer
resource "google_compute_global_address" "ctfd_lb_ip" {
  name = "ctfd-lb-ip"
}

# Serverless NEG for Cloud Run
resource "google_compute_region_network_endpoint_group" "ctfd_neg" {
  name                  = "ctfd-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.ctfd.name
  }
}

# Backend service
resource "google_compute_backend_service" "ctfd_backend" {
  name                  = "ctfd-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 300
  enable_cdn            = false
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.ctfd_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL map
resource "google_compute_url_map" "ctfd_urlmap" {
  name            = "ctfd-urlmap"
  default_service = google_compute_backend_service.ctfd_backend.id
}

# Managed SSL certificate
resource "google_compute_managed_ssl_certificate" "ctfd_cert" {
  name = "ctfd-cert"

  managed {
    domains = [var.domain]
  }
}

# HTTPS proxy
resource "google_compute_target_https_proxy" "ctfd_https_proxy" {
  name             = "ctfd-https-proxy"
  url_map          = google_compute_url_map.ctfd_urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ctfd_cert.id]
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "ctfd_https" {
  name                  = "ctfd-https"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.ctfd_https_proxy.id
  ip_address            = google_compute_global_address.ctfd_lb_ip.id
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "ctfd_http_redirect" {
  name = "ctfd-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# HTTP proxy for redirect
resource "google_compute_target_http_proxy" "ctfd_http_proxy" {
  name    = "ctfd-http-proxy"
  url_map = google_compute_url_map.ctfd_http_redirect.id
}

# Global forwarding rule for HTTP
resource "google_compute_global_forwarding_rule" "ctfd_http" {
  name                  = "ctfd-http"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.ctfd_http_proxy.id
  ip_address            = google_compute_global_address.ctfd_lb_ip.id
}
