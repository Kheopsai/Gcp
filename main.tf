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

###############################
# Kheops cloud
###############################

provider "restful" {
  base_url = var.kheops_url
  security = {
    http = {
      token = {
        token = "Bearer ${var.kheops_token}"
      }
    }
  }
  alias = "http_token"
}

variable "kheops_url" {
  description = "URL of the Kheops API"
  type        = string
  default     = "https://kheops.cloud/api"
}

variable "kheops_token" {
  description = "Authentication token for Kheops API"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Kheops project name"
  type        = string
  default     = "Kheops prod"
}

variable "project_description" {
  description = "Description of the project in Kheops"
  type        = string
  default     = ""
}

variable "is_public" {
  description = "Whether the Kheops project is public"
  type        = bool
  default     = false
}

###############################
# Kheops Project Setup
###############################

data "http" "projects" {
  url = "${var.kheops_url}/projects"
  request_headers = {
    Authorization = "Bearer ${var.kheops_token}"
  }
}

locals {
  existing_projects = jsondecode(data.http.projects.response_body)
  project_exists    = length([for p in local.existing_projects : p if try(p.name, "") == var.project_name]) > 0
  project_id_kheops = local.project_exists ? (
  [for p in local.existing_projects : p if try(p.name, "") == var.project_name][0].project_id
  ) : restful_resource.project[0].id
}


resource "restful_resource" "project" {
  count = local.project_exists ? 0 : 1
  path  = "/projects"
  body         = {
    name        = var.project_name
    description = var.project_description
    is_public   = var.is_public
  }
}

###############################
# Duplicate Instances to Kheops
###############################

resource "restful_resource" "server_registration" {
  for_each = { for instance in module.mig.instances : instance.name => instance }
  path = "/projects/${local.project_id_kheops}/servers"
  body = {
    name = each.value.name
    ip   = each.value.ip
  }
}
