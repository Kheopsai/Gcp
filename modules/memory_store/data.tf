data "google_compute_network" "prod-network" {
  name = var.network
}

data "google_compute_subnetwork" "prod-subnet" {
  name    = var.subnet
  region  = var.region
}