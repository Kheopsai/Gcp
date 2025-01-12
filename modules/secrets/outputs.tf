output "key_ring" {
  value = google_kms_key_ring.certs.id
}

output "crypto_key" {
  value = google_kms_crypto_key.certs.id
}

output "wildcard_kheops_ai" {
  value = google_compute_ssl_certificate.wildcard_kheops_ai.self_link
}