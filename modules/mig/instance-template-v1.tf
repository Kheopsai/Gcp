resource "google_service_account" "mig-sa" {
  account_id   = "mig-sa"
  display_name = "MIG Service Account"

}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"

}

resource "google_compute_instance_template" "mig-v1-template" {
  # machine_type = "e2-highmem-4"
  machine_type = "e2-micro"
  name         = "mig-v1-template"
  description  = "Instance template for MIG"
  project      = var.project_id

  disk {
    source_image = data.google_compute_image.ubuntu.self_link
    boot         = true
    auto_delete  = true
  }

  network_interface {
    network    = "prod-vpc"
    subnetwork = "prod-subnet"

  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  service_account {
    scopes = ["cloud-platform"]
    email = google_service_account.mig-sa.email
  }

  metadata_startup_script = file("${path.module}/scripts/startup.sh")
  tags = ["http-server"]

}