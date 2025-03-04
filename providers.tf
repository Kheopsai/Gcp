terraform {
  required_version = ">= 0.14.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.1"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.0"
    }
    restful = {
      source = "magodo/restful"
      version = "0.18.1"
    }
  }
}


provider "google" {
  project = var.project_id
  region  = var.region
}
