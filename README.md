# Terraform GCP Infrastructure

This repository contains Terraform configurations for provisioning and managing infrastructure on Google Cloud
Platform (GCP). Follow the steps below to set up Terraform, authenticate with GCP, and apply the infrastructure.

---

## Prerequisites

Before you start, ensure you have the following installed on your local machine:

1. [Terraform](https://www.terraform.io/downloads) (v1.0.0 or later).
2. [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (gcloud).
3. An active GCP project with billing enabled.
4. IAM permissions to create resources in the GCP project.

---

## Setup Instructions

### Step 1: Clone the Repository

```bash
$ git clone https://github.com/yourusername/terraform-gcp-infra.git
$ cd terraform-gcp-infra
```

### Step 2: Install Terraform

Download and install Terraform if it is not already installed. Verify the installation:

```bash
$ terraform -v
Terraform v1.x.x
```

### Step 3: Authenticate with GCP

1. Log in to your Google account:

   ```bash
   $ gcloud auth application-default login
   ```

2. Set the active project:

   ```bash
   $ gcloud config set project [PROJECT_ID]
   ```

### Step 4: Initialize Terraform

Run the following command to initialize the Terraform workspace:

```bash
$ terraform init
```

### Step 5: Review and Apply the Configuration

1. Review the planned changes:

   ```bash
   $ terraform plan
   ```

2. Apply the configuration to create the resources:

   ```bash
   $ terraform apply
   ```

   Type `yes` when prompted to confirm the creation of resources.

---

## Repository Structure

```
terraform-gcp-infra/
|-- modules/           # Reusable Terraform modules
|-- main.tf            # Entry point for Terraform configuration
|-- variables.tf       # Input variable definitions
|-- outputs.tf         # Outputs for the infrastructure
|-- provider.tf        # GCP provider configuration
```
