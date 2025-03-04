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
  url    = "${var.kheops_url}/projects"
  method = "GET"
  request_headers = {
    Authorization = "Bearer ${var.kheops_token}"
  }
}

locals {
  existing_projects = jsondecode(data.http.projects.response_body)

  project_exists = length([
    for p in local.existing_projects : p
    if try(p.name, "") == var.project_name
  ]) > 0

  project_id_kheops = local.project_exists ? (
  [for p in local.existing_projects : p.project_id if p.name == var.project_name][0]
  ) : null
}

resource "null_resource" "create_project" {
  count = local.project_exists ? 0 : 1

  provisioner "local-exec" {
    command = <<-EOT
      # Send POST request and capture output
      response=$(curl -s -X POST "${var.kheops_url}/projects" \
        -H "Authorization: Bearer ${var.kheops_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "${var.project_name}",
          "description": "${var.project_description}",
          "is_public": ${var.is_public}
        }')

      # Validate response
      if ! echo "$response" | jq -e '.project_id' > /dev/null; then
        echo "Failed to create project"
        exit 1
      fi
    EOT

    interpreter = ["bash", "-c"]
  }
}

data "http" "project_creation_response" {
  count = local.project_exists ? 0 : 1
  url    = "${var.kheops_url}/projects"
  method = "GET"
  request_headers = {
    Authorization = "Bearer ${var.kheops_token}"
  }

  depends_on = [null_resource.create_project]
}

locals {
  project_id_kheops_final = coalesce(
    local.project_id_kheops,
    try([for p in jsondecode(data.http.project_creation_response[0].response_body) : p.project_id if p.name == var.project_name][0], null)
  )
}

###############################
# Duplicate Instances to Kheops
###############################

data "google_compute_region_instance_group" "mig_instances" {
  self_link = module.mig.instance_group
  region    = var.region
}

data "google_compute_instance" "instance_details" {
  for_each  = toset(data.google_compute_region_instance_group.mig_instances.instances[*].instance)
  self_link = each.value
}

resource "null_resource" "server_registration" {
  for_each = data.google_compute_instance.instance_details

  triggers = {
    instance_ip = each.value.network_interface[0].access_config[0].nat_ip
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "${var.kheops_url}/projects/${local.project_id_kheops_final}/servers" \
        -H "Authorization: Bearer ${var.kheops_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "${each.value.name}",
          "ip": "${each.value.network_interface[0].access_config[0].nat_ip}"
        }'
    EOT
  }

  depends_on = [null_resource.create_project]
}