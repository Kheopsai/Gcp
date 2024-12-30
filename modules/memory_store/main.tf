# resource "google_redis_cluster" "redis-cluster" {
#   name        = "redis-cluster"
#   shard_count = 3
#   psc_configs {
#     network = data.google_compute_network.prod-network.id
#   }
#   region                  = var.region
#   replica_count           = 1
#   node_type               = "REDIS_SHARED_CORE_NANO"
#   transit_encryption_mode = "TRANSIT_ENCRYPTION_MODE_DISABLED"
#   authorization_mode      = "AUTH_MODE_DISABLED"
#   redis_configs = {
#     maxmemory-policy = "volatile-ttl"
#   }
#   deletion_protection_enabled = false
#
#   zone_distribution_config {
#     mode = "MULTI_ZONE"
#   }
#   maintenance_policy {
#     weekly_maintenance_window {
#       day = "MONDAY"
#       start_time {
#         hours   = 1
#         minutes = 0
#         seconds = 0
#         nanos   = 0
#       }
#     }
#   }
#   depends_on = [
#     google_network_connectivity_service_connection_policy.redis-connectivity-policy
#   ]
#
# }

# resource "google_network_connectivity_service_connection_policy" "redis-connectivity-policy" {
#   name          = "redis-connectivity-policy"
#   location      = var.region
#   service_class = "gcp-memorystore-redis"
#   description   = "Connection policy for Redis"
#   network       = data.google_compute_network.prod-network.id
#   psc_config {
#     subnetworks = [data.google_compute_subnetwork.prod-subnet.id]
#   }
# }
