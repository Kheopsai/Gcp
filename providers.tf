terraform {
  required_version = ">= 0.14.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
}


provider "google" {
  project = var.project_id
  region  = var.region
}