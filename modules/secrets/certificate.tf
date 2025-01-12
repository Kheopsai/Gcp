resource "google_kms_secret_ciphertext" "AAACertificateServices" {
  crypto_key = google_kms_crypto_key.certs.id
  plaintext = file("${path.module}/http-certificates/AAACertificateServices.crt")
}

resource "google_kms_secret_ciphertext" "STAR_kheops_ai" {
  crypto_key = google_kms_crypto_key.certs.id
  plaintext = file("${path.module}/http-certificates/STAR_kheops_ai.crt")
}

resource "google_kms_secret_ciphertext" "SectigoRSADomainValidationSecureServerCA" {
  crypto_key = google_kms_crypto_key.certs.id
  plaintext = file("${path.module}/http-certificates/SectigoRSADomainValidationSecureServerCA.crt")
}

resource "google_kms_secret_ciphertext" "USERTrustRSAAAACA" {
  crypto_key = google_kms_crypto_key.certs.id
  plaintext = file("${path.module}/http-certificates/USERTrustRSAAAACA.crt")
}

resource "google_kms_secret_ciphertext" "wildcard_kheops_ai_private_key" {
  crypto_key = google_kms_crypto_key.certs.id
  plaintext = file("${path.module}/http-certificates/wildcard.kheops.ai.key")
}

locals {
  public_key_certificate = join("", [
    google_kms_secret_ciphertext.STAR_kheops_ai.plaintext,
    google_kms_secret_ciphertext.SectigoRSADomainValidationSecureServerCA.plaintext,
    google_kms_secret_ciphertext.USERTrustRSAAAACA.plaintext,
    google_kms_secret_ciphertext.AAACertificateServices.plaintext,
  ])

  private_key_certificate = google_kms_secret_ciphertext.wildcard_kheops_ai_private_key.plaintext
}


resource "google_compute_ssl_certificate" "wildcard_kheops_ai" {
  name        = "wildcard-kheops-ai"
  private_key = local.private_key_certificate
  certificate = local.public_key_certificate
}

