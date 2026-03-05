# ==========================================================
# DATA LAKE (CLOUD STORAGE)
# ==========================================================
resource "google_storage_bucket" "datalake" {
  name          = "datalake-euro2025-tf"
  location      = "US-CENTRAL1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  force_destroy               = true
}

# IAM: Cloud Function SA → Data Lake bucket
resource "google_storage_bucket_iam_member" "function_storage_admin" {
  bucket = google_storage_bucket.datalake.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}
