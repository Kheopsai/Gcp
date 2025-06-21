output "key_ring" {
  value = google_kms_key_ring.certs.id
}

output "crypto_key" {
  value = google_kms_crypto_key.certs.id
}

output "wildcard_kheops_site" {
  value = google_compute_ssl_certificate.kheops-site.self_link
}