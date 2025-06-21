data "google_kms_secret" "SectigoPublicServerAuthenticationCADVR36" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/SectigoPublicServerAuthenticationCADVR36.crt.enc")
}

data "google_kms_secret" "SectigoPublicServerAuthenticationRootR46_USERTrust" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/SectigoPublicServerAuthenticationRootR46_USERTrust.crt.enc")
}

data "google_kms_secret" "STAR_kheops_site" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/STAR_kheops_site.crt.enc")
}

data "google_kms_secret" "USERTrustRSACertificationAuthority" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/USERTrustRSACertificationAuthority.crt.enc")
}

data "google_kms_secret" "wildcard_kheops_site_private_key" {
  crypto_key = google_kms_crypto_key.certs.id
  ciphertext = filebase64("${path.module}/http-certificates/wildcard_kheops_site_private_key.key.enc")
}

locals {
  public_key_certificate = join("", [
    data.google_kms_secret.STAR_kheops_site.plaintext,
    data.google_kms_secret.SectigoPublicServerAuthenticationCADVR36.plaintext,
    data.google_kms_secret.SectigoPublicServerAuthenticationRootR46_USERTrust.plaintext,
    data.google_kms_secret.USERTrustRSACertificationAuthority.plaintext,
  ])

  private_key_certificate = data.google_kms_secret.wildcard_kheops_site_private_key.plaintext
}

resource "google_compute_ssl_certificate" "kheops-site" {
  name        = "kheops-site"
  private_key = local.private_key_certificate
  certificate = local.public_key_certificate
}
