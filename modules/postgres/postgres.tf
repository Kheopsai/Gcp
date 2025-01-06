resource "google_sql_database" "postgres-pgvector-main" {
  name     = "postgres-pgvector-main"
  instance = google_sql_database_instance.postgres-pgvector-main-instance.name
}

resource "google_sql_database_instance" "postgres-pgvector-main-instance" {
  name             = "postgres-pgvector-main-instance"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    edition = "ENTERPRISE"
    availability_type = "REGIONAL"

    backup_configuration {
      enabled = true
      binary_log_enabled = true
    }
  }
}
