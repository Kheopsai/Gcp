module "mig" {
  source     = "./modules/mig"
  project_id = var.project_id
  region     = var.region
}