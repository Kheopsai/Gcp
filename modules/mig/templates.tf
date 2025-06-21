module "v1" {
  source                = "./modules/v1"
  project_id            = var.project_id
  network               = var.network
  region                = var.region
  subnet                = var.subnet
  service_account_email = google_service_account.mig-sa.email
  kheops_auth_token     = var.kheops_auth_token
  kheops_project_name   = var.kheops_project_name
}
module "v2" {
  source                = "./modules/v2"
  project_id            = var.project_id
  network               = var.network
  region                = var.region
  subnet                = var.subnet
  service_account_email = google_service_account.mig-sa.email
  kheops_auth_token     = var.kheops_auth_token
  kheops_project_name     = var.kheops_project_name
}
