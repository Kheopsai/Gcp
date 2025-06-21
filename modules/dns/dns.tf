resource "google_dns_managed_zone" "default" {
  project       = var.project_id
  name          = "kheops-site"
  dns_name      = "kheops.site."
  force_destroy = "false"
}
resource "google_dns_record_set" "kheops_site_a" {
  name         = "kheops.site."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.default.name
  rrdatas      = [var.lb_ip]
}

resource "google_dns_record_set" "kheops_wildcard_a" {
  name         = "*.kheops.site."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.default.name
  rrdatas      = [var.lb_ip]
}