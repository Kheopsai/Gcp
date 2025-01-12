resource "google_dns_managed_zone" "default" {
  project       = var.project_id
  name          = "kheops-ai"
  dns_name      = "kheops.ai."
  description   = "Kheops Public DNS zone"
  force_destroy = "false"
}
