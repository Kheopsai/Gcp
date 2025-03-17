resource "google_compute_instance_template" "mig-template" {
  # machine_type = "e2-highmem-4"
  machine_type = "e2-micro"
  name         = "mig-v4-template"
  description  = "Instance template for MIG"
  project      = var.project_id

  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20250112"
    boot         = true
    auto_delete  = true
    # disk_size_gb = 100
    # disk_type = "pd-ssd"
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnet
    access_config {
      // Ephemeral IP
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  service_account {
    scopes = ["cloud-platform"]
    email = var.service_account_email
  }

  metadata_startup_script = file("${path.module}/scripts/startup.sh")
  tags = ["http-server"]
}
