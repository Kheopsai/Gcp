resource "google_compute_backend_service" "mig" {
  name                  = "mig-backend-service"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.mig-health-check.id]
  protocol              = "HTTP"
  session_affinity      = "NONE"
  timeout_sec           = 30

  # Cloud Armor Security Policy
  security_policy = module.armor_security_policy.policy.self_link

  backend {
    group           = google_compute_region_instance_group_manager.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}
