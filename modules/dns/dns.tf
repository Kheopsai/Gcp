resource "google_dns_managed_zone" "default" {
  project       = var.project_id
  name          = "kheops-site"
  dns_name      = "kheops.site."
  description   = "Kheops Public DNS zone"
  force_destroy = "false"
}
