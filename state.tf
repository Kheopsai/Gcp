resource "google_storage_bucket" "default" {
  name     = "terraform-remote-backend-prod"
  location = "EUROPE-WEST9"

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "local_file" "default" {
  file_permission = "0644"
  filename        = "${path.module}/backend.tf"

  # You can store the template in a file and use the templatefile function for
  # more modularity, if you prefer, instead of storing the template inline as
  # we do here.
  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "${google_storage_bucket.default.name}"
    }
  }
  EOT
}

resource "google_service_account" "github-actions-ci-cd" {
  account_id   = "github-actions-ci-cd"
  display_name = "GitHub Actions CI/CD"
}

resource "google_project_iam_binding" "github-actions-ci-cd" {
  project = var.project_id
  role    = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.github-actions-ci-cd.email}",
  ]
}

resource "google_service_account_key" "github-actions-ci-cd" {
  service_account_id = google_service_account.github-actions-ci-cd.name
}