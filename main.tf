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
  write_returns_object = true
  headers = {
    Authorization = "Bearer ${var.kheops_token}"
    Content-Type  = "application/json"
    Accept        = "application/json"
  }
  create_method  = "POST"
  read_method    = "GET"
  update_method  = "PUT"
  destroy_method = "DELETE"
  base_url       = var.kheops_url
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

variable "ssh_public_key" {
  description = "SSH public key to configure in Kheops instances"
  type        = string
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
  project_exists = length([for p in local.existing_projects : p if try(p.name, "") == var.project_name]) > 0
  project_id_kheops = local.project_exists ? (
  [for p in local.existing_projects : p if try(p.name, "") == var.project_name][0].project_id
  ) : restful_object.project[0].id
}

resource "restful_object" "project" {
  count = local.project_exists ? 0 : 1
  path  = "/projects"
  data = jsonencode({
    name        = var.project_name
    description = var.project_description
    is_public   = var.is_public
  })
  id_attribute = "project_id"
}

###############################
# Duplicate Instances to Kheops
###############################

resource "restful_object" "server_registration" {
  for_each = { for instance in module.mig.instances : instance.name => instance }
  path = "/projects/${local.project_id_kheops}/servers"
  data = jsonencode({
    name = each.value.name
    ip   = each.value.ip
  })
  id_attribute = "server_id"
}

###############################
# Configure SSH Keys in Kheops
###############################

resource "restful_object" "ssh_key" {
  for_each = restapi_object.server_registration
  path = "/servers/${each.value.id}/ssh-keys"
  data = jsonencode({
    ssh_key = var.ssh_public_key
  })
  id_attribute = "key_id"
}