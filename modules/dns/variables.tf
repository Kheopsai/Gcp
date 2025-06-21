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

variable "lb_ip" {
  description = "IP address for the Load Balancer A record"
  type        = string
}