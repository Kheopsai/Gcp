resource "google_service_account" "mig-sa" {
  account_id   = "mig-sa"
  display_name = "MIG Service Account"
}