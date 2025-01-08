# Encrypting Certificates with Google Cloud KMS

This module uses Google Cloud Key Management Service (KMS) to securely store and manage encryption keys, which are used to encrypt certificates. It includes Terraform resources to create a KMS key ring and a crypto key, and also provides instructions for encrypting the certificates.

## Prerequisites

1. Ensure you have a Google Cloud project with billing enabled.
2. Install the following tools:
    - [Terraform](https://www.terraform.io/downloads.html)
    - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
3. Authenticate with Google Cloud:
   ```bash
   gcloud auth application-default login
   ```

## Module Structure

```plaintext
├── http-certificates
│   ├── AAACertificateServices.crt
│   ├── STAR_kheops_ai.crt
│   ├── SectigoRSADomainValidationSecureServerCA.crt
│   ├── USERTrustRSAAAACA.crt
│   └── wildcard.kheops.ai.key
├── kms.tf         # Contains the KMS key ring and crypto key definitions.
├── outputs.tf     # Defines outputs for the module.
├── variables.tf   # Contains input variables for the module.
├── certificates.tf # Contains resources for managing encrypted certificates.
```

## Key Management Service (KMS) Resources

### Key Ring
The `google_kms_key_ring` resource creates a key ring for organizing your KMS keys.

```hcl
resource "google_kms_key_ring" "certs" {
  name     = "certs-key-ring"
  location = var.location
}
```

### Crypto Key
The `google_kms_crypto_key` resource defines a cryptographic key for encryption and decryption. The `prevent_destroy` lifecycle rule ensures the key cannot be accidentally destroyed.

```hcl
resource "google_kms_crypto_key" "certs" {
  name     = "certs-crypto-key"
  key_ring = google_kms_key_ring.certs.id

  lifecycle {
    prevent_destroy = true
  }
}
```

### Outputs
The module outputs the IDs of the key ring and crypto key for reference.

```hcl
output "key_ring" {
  value = google_kms_key_ring.certs.id
}

output "crypto_key" {
  value = google_kms_crypto_key.certs.id
}
```

## Encrypting Certificates

1. Navigate to the `http-certificates` directory containing the certificates.

2. Use the following command to encrypt each file using the crypto key:

   ```bash
   gcloud kms encrypt \
     --keyring="certs-key-ring" \
     --key="certs-crypto-key" \
     --location="<LOCATION>" \
     --plaintext-file="<FILE_TO_ENCRYPT>" \
     --ciphertext-file="<OUTPUT_FILE>"
   ```

   Replace:
    - `<LOCATION>` with the value of the `location` variable.
    - `<FILE_TO_ENCRYPT>` with the path to the certificate file.
    - `<OUTPUT_FILE>` with the desired output file path for the encrypted file.

   Example:

   ```bash
   gcloud kms encrypt --keyring="certs-key-ring" --key="certs-crypto-key" --location="europe-west9" --plaintext-file="AAACertificateServices.crt" --ciphertext-file="AAACertificateServices.crt.enc"
   
   gcloud kms encrypt --keyring="certs-key-ring" --key="certs-crypto-key" --location="europe-west9" --plaintext-file="STAR_kheops_ai.crt" --ciphertext-file="STAR_kheops_ai.crt.enc"

   gcloud kms encrypt --keyring="certs-key-ring" --key="certs-crypto-key" --location="europe-west9" --plaintext-file="SectigoRSADomainValidationSecureServerCA.crt" --ciphertext-file="SectigoRSADomainValidationSecureServerCA.crt.enc"

   gcloud kms encrypt --keyring="certs-key-ring" --key="certs-crypto-key" --location="europe-west9" --plaintext-file="USERTrustRSAAAACA.crt" --ciphertext-file="USERTrustRSAAAACA.crt.enc"

   gcloud kms encrypt --keyring="certs-key-ring" --key="certs-crypto-key" --location="europe-west9" --plaintext-file="wildcard.kheops.ai.key" --ciphertext-file="wildcard.kheops.ai.key.enc"
   ```

3. Store the encrypted files securely.

## Decrypting Certificates
To decrypt a file, use the following command:

```bash
gcloud kms decrypt \
  --keyring="certs-key-ring" \
  --key="certs-crypto-key" \
  --location="<LOCATION>" \
  --plaintext-file="<OUTPUT_FILE>" \
  --ciphertext-file="<FILE_TO_DECRYPT>"
```

Replace `<OUTPUT_FILE>` with the path to store the decrypted file and `<FILE_TO_DECRYPT>` with the path to the encrypted file.

### Certificate Management
The `google_kms_secret_ciphertext` resources are used to decrypt the certificate files. The decrypted data is then used to create a Google Compute SSL certificate resource.

#### Decrypting Certificates with Terraform
```hcl
resource "google_kms_secret_ciphertext" "AAACertificateServices" {
   crypto_key = google_kms_crypto_key.certs.id
   plaintext = filebase64("${path.module}/http-certificates/AAACertificateServices.crt")
}

resource "google_kms_secret_ciphertext" "STAR_kheops_ai" {
   crypto_key = google_kms_crypto_key.certs.id
   plaintext = filebase64("${path.module}/http-certificates/STAR_kheops_ai.crt")
}

resource "google_kms_secret_ciphertext" "SectigoRSADomainValidationSecureServerCA" {
   crypto_key = google_kms_crypto_key.certs.id
   plaintext = filebase64("${path.module}/http-certificates/SectigoRSADomainValidationSecureServerCA.crt")
}

resource "google_kms_secret_ciphertext" "USERTrustRSAAAACA" {
   crypto_key = google_kms_crypto_key.certs.id
   plaintext = filebase64("${path.module}/http-certificates/USERTrustRSAAAACA.crt")
}

resource "google_kms_secret_ciphertext" "wildcard_kheops_ai_private_key" {
   crypto_key = google_kms_crypto_key.certs.id
   plaintext = filebase64("${path.module}/http-certificates/wildcard.kheops.ai.key")
}

```

#### Combining Certificates
The certificates are combined using Terraform local variables to create a single public key certificate chain and private key for use in a Google Compute SSL certificate.

```hcl
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
```

## Usage
```hcl
module "certs" {
  source  = "github.com/kheops-tech/terraform-modules/modules/secrets"
  location = "europe-west9"
}
```
## Notes
- Ensure proper IAM roles are assigned to the service account to access KMS. (e.g., `roles/cloudkms.cryptoKeyEncrypterDecrypter`, `roles/cloudkms.admin`, etc.)
- Avoid sharing sensitive information, such as decrypted certificates, in untrusted locations.