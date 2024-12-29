resource "google_compute_backend_service" "mig" {
  name                  = "mig-backend-service"
  load_balancing_scheme = "EXTERNAL"
  health_checks = [google_compute_health_check.mig-health-check.id]
  protocol              = "HTTP"
  session_affinity      = "NONE"
  timeout_sec           = 30
  backend {
    group           = google_compute_region_instance_group_manager.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0

  }

}
resource "google_compute_url_map" "mig-url-map" {
  name            = "mig-url-map"
  default_service = google_compute_backend_service.mig.id
}
resource "google_compute_target_http_proxy" "mig-http-lb-proxy" {
  name    = "mig-http-lb-proxy"
  url_map = google_compute_url_map.mig-url-map.id
}

resource "google_compute_global_forwarding_rule" "mig-http-lb-rule" {
  name                  = "mig-http-lb-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80-80"
  target                = google_compute_target_http_proxy.mig-http-lb-proxy.id
  ip_address            = google_compute_global_address.mig-http-lb-address.address
}

resource "google_compute_global_address" "mig-http-lb-address" {
  name = "mig-http-lb-address"
}