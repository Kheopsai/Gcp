module "memory_store" {
  source  = "terraform-google-modules/memorystore/google"
  version = "~> 12.0"

  name = "redis-memory-store"

  project_id              = var.project_id
  region                  = var.region
  enable_apis             = true
  auth_enabled            = true
  authorized_network      = data.google_compute_network.prod-network.id
  memory_size_gb          = 5
  persistence_config = {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "ONE_HOUR"
  }
  tier = "STANDARD_HA"
  replica_count = 1
  read_replicas_mode = "READ_REPLICAS_ENABLED"
}