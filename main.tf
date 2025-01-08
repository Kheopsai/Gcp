module "secrets" {
  source   = "./modules/secrets"
  location = var.region
}

module "mig" {
  source     = "./modules/mig"
  project_id = var.project_id
  region     = var.region
  network    = var.network
  subnet     = var.subnet
}

module "loadbalancer" {
  source                    = "./modules/loadbalancer"
  backend_service_id        = module.mig.backend_service_id
  ssl_certificate_self_link = module.secrets.wildcard_kheops_ai
}

module "memory_store" {
  source     = "./modules/memory_store"
  project_id = var.project_id
  region     = var.region
  network    = var.network
  subnet     = var.subnet
}

