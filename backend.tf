terraform {
  backend "gcs" {
    bucket = "terraform-remote-backend-prod"
  }
}
