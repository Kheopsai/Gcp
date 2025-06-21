module "secrets" {
  source   = "./modules/secrets"
  location = var.region
}

module "mig" {
  source                                = "./modules/mig"
  project_id                            = var.project_id
  region                                = var.region
  network                               = var.network
  subnet                                = var.subnet
  cloud_armor_security_policy_self_link = module.armor.security_policy
  kheops_auth_token                     = var.kheops_auth_token
  kheops_project_name                   = var.kheops_project_name
}

module "loadbalancer" {
  source                    = "./modules/loadbalancer"
  backend_service_id        = module.mig.backend_service_id
  ssl_certificate_self_link = module.secrets.wildcard_kheops_site
}

module "memory_store" {
  source     = "./modules/memory_store"
  project_id = var.project_id
  region     = var.region
  network    = var.network
  subnet     = var.subnet
}

module "postgres" {
  source     = "./modules/postgres"
  project_id = var.project_id
  region     = var.region
  network    = var.network
  subnet     = var.subnet
}


module "armor" {
  source     = "./modules/cloud_armor"
  project_id = var.project_id
  region     = var.region
  network    = var.network
  subnet     = var.subnet
}

module "dns" {
  source     = "./modules/dns"
  project_id = var.project_id
  region     = var.region
  network    = var.network
  subnet     = var.subnet
}
