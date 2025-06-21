data "google_kms_secret" "AAACertificateServices" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/AAACertificateServices.crt.enc")
}

data "google_kms_secret" "STAR_kheops_site" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/STAR_kheops_site.crt.enc")
}

data "google_kms_secret" "SectigoRSADomainValidationSecureServerCA" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/SectigoRSADomainValidationSecureServerCA.crt.enc")
}

data "google_kms_secret" "USERTrustRSAAAACA" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/USERTrustRSAAAACA.crt.enc")
}

data "google_kms_secret" "wildcard_kheops_site_private_key" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/kheops.site.key.enc")
}

locals {
  public_key_certificate = join("", [
    data.google_kms_secret.STAR_kheops_site.plaintext,
    data.google_kms_secret.SectigoRSADomainValidationSecureServerCA.plaintext,
    data.google_kms_secret.USERTrustRSAAAACA.plaintext,
    data.google_kms_secret.AAACertificateServices.plaintext,
  ])

  private_key_certificate = data.google_kms_secret.wildcard_kheops_site_private_key.plaintext
}


resource "google_compute_ssl_certificate" "wildcard_kheops_ai" {
  name        = "wildcard-kheops-ai"
  private_key = local.private_key_certificate
  certificate = local.public_key_certificate
}

