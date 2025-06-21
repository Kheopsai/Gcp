variable "project_id" {
  description = "The project ID to deploy resources"
  type        = string
}
variable "region" {
  description = "The region to deploy resources"
  type        = string
}

variable "network" {
  description = "The network to deploy the MIG"
  type        = string
}

variable "subnet" {
  description = "The subnet to deploy the MIG"
  type        = string
}

variable "cloud_armor_security_policy_self_link" {
  description = "The self link of the Cloud Armor security policy"
  type        = string
}

variable "kheops_auth_token" {
  description = "The auth token for the Kheops API"
  type        = string
}

variable "kheops_project_name" {
  description = "The name project for the Kheops API"
  type        = string
}