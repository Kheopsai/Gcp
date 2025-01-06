output "backend_service_id" {
  description = "The backend service for the MIG"
  value       = google_compute_backend_service.mig.id
}