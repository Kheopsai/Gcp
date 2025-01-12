resource "google_compute_url_map" "mig-url-map" {
  name            = "mig-url-map"
  default_service = var.backend_service_id
  host_rule {
    hosts = ["*.kheops.ai", "kheops.ai"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = var.backend_service_id

    path_rule {
      paths = ["/*"]
      service = var.backend_service_id
    }
  }
}

resource "google_compute_target_https_proxy" "mig-https-lb-proxy" {
  name    = "mig-http-lb-proxy"
  url_map = google_compute_url_map.mig-url-map.id
  ssl_certificates = [
    var.ssl_certificate_self_link
  ]
}

resource "google_compute_global_forwarding_rule" "mig-http-lb-rule" {
  name                  = "mig-http-lb-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.mig-https-lb-proxy.id
  ip_address            = google_compute_global_address.mig-http-lb-address.address
}

resource "google_compute_global_address" "mig-http-lb-address" {
  name = "mig-http-lb-address"
}
