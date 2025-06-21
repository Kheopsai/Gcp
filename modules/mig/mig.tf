resource "google_compute_region_instance_group_manager" "mig" {
  name = "mig"

  base_instance_name = "mig"
  region             = var.region

  version {
    instance_template = module.v2.instance_template
    name              = "v2"
  }

  update_policy {
    type           = "PROACTIVE"
    minimal_action = "REPLACE"
  }
  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.mig-health-check.id
    initial_delay_sec = 500
  }

  timeouts {
    create = "30m"
    update = "30m"
  }

  wait_for_instances = false
}


