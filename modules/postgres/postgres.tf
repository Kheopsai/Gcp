resource "google_sql_database_instance" "postgres_instance" {
  name             = "pg-ha-instance"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier              = "db-custom-4-16384"
    availability_type = "REGIONAL"

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00" # Heure de début des sauvegardes automatiques
      location                       = var.region
      point_in_time_recovery_enabled = true # Récupération à un instant donné
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = data.google_compute_network.prod-network.self_link
    }

    database_flags {
      name  = "maintenance_work_mem"
      value = "524288"
    }

    database_flags {
      name  = "work_mem"
      value = "419430"
    }

    database_flags {
      name  = "shared_buffers"
      value = "419430"
    }

    database_flags {
      name  = "effective_cache_size"
      value = "12288"
    }

    database_flags {
      name  = "max_connections"
      value = "150"
    }
  }
  depends_on = [google_service_networking_connection.database_connection]
}
resource "random_password" "postgres_password" {
  length  = 64
  special = false
}
resource "google_sql_user" "postgres_user" {
  name     = "admin"
  instance = google_sql_database_instance.postgres_instance.name
  password = random_password.postgres_password.result
}

resource "google_sql_database" "default_db" {
  name     = "defaultdb"
  instance = google_sql_database_instance.postgres_instance.name
}

resource "google_compute_global_address" "database_ip_range" {
  name          = "database-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.prod-network.self_link
}

resource "google_service_networking_connection" "database_connection" {
  network = data.google_compute_network.prod-network.self_link
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.database_ip_range.name
  ]
}
