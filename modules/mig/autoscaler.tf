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