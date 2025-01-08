
resource "google_kms_key_ring" "certs" {
  name     = "certs-key-ring"
  location = var.location
}

# Create a KMS crypto key that's being prevented from being destroyed.
resource "google_kms_crypto_key" "certs" {
  name     = "certs-crypto-key"
  key_ring = google_kms_key_ring.certs.id

  lifecycle {
    prevent_destroy = true
  }
}


