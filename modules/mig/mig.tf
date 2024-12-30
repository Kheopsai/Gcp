resource "google_compute_health_check" "mig-health-check" {
  name               = "mig-health-check"
  check_interval_sec = 5
  healthy_threshold  = 2
  http_health_check {
    port               = 80
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
    request_path       = "/"
  }
  timeout_sec         = 5
  unhealthy_threshold = 2
}

resource "google_compute_region_instance_group_manager" "mig" {
  name = "mig"

  base_instance_name = "mig"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.mig-v1-template.self_link_unique
    name              = "v1"
  }


  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.mig-health-check.id
    initial_delay_sec = 300
  }
  wait_for_instances = true

}


resource "google_compute_region_autoscaler" "mig-autoscaler" {
  name   = "mig-autoscaler"
  target = google_compute_region_instance_group_manager.mig.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}