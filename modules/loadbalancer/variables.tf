variable "backend_service_id" {
  description = "The backend service for the MIG"
  type        = string
}

variable "ssl_certificate_self_link" {
  description = "The SSL certificate for the load balancer"
  type        = string
}