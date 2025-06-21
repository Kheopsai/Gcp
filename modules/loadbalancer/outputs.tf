output "lb_ip" {
  value = google_compute_global_address.mig-http-lb-address.address
}
