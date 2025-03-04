output "backend_service_id" {
  description = "The backend service for the MIG"
  value       = google_compute_backend_service.mig.id
}
output "instance_group" {
  description = "The self-link of the managed instance group"
  value       = google_compute_region_instance_group_manager.mig.instance_group
}