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

variable "service_account_email" {
  description = "The service account of the template"
  type        = string
}