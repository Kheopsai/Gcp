output "instance_template" {
  value = google_compute_instance_template.mig-template.self_link
}