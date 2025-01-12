resource "google_sql_database" "postgres-pgvector-main" {
  name     = "postgres-pgvector-main"
  instance = google_sql_database_instance.postgres-pgvector-main-instance.name
}

resource "google_sql_database_instance" "postgres-pgvector-main-instance" {
  name             = "postgres-pgvector-main-instance"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier              = "db-standard-4"
    edition           = "ENTERPRISE"
    availability_type = "REGIONAL"

    backup_configuration {
      enabled                        = true
      binary_log_enabled             = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 3
      }
    }
  }
}
