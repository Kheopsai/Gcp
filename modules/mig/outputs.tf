output "instance_group" {
  description = "The self-link of the managed instance group"
  value       = google_compute_region_instance_group_manager.mig.instance_group
}