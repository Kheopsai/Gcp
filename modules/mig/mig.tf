resource "google_compute_region_instance_group_manager" "mig" {
  name               = "mig"
  base_instance_name = "mig"
  region             = var.region

  version {
    instance_template = module.v1.instance_template
    name              = "v1"
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
    instance_redistribution_type = "PROACTIVE"
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.mig-health-check.id
    initial_delay_sec = 500
  }
}