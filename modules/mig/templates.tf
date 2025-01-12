module "v1" {
  source                = "./modules/v1"
  project_id            = var.project_id
  network               = var.network
  region                = var.region
  subnet                = var.subnet
  service_account_email = google_service_account.mig-sa.email
}

module "v2" {
  source                = "./modules/v2"
  project_id            = var.project_id
  network               = var.network
  region                = var.region
  subnet                = var.subnet
  service_account_email = google_service_account.mig-sa.email
}
module "v3" {
  source                = "./modules/v3"
  project_id            = var.project_id
  network               = var.network
  region                = var.region
  subnet                = var.subnet
  service_account_email = google_service_account.mig-sa.email
}
