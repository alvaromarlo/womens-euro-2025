# ==========================================================
# SERVICE ACCOUNTS
# ==========================================================

# SA para GitHub Actions (CI/CD)
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa-tf"
  display_name = "GitHub Actions SA Data"
}

# SA para Cloud Function (Least Privilege)
resource "google_service_account" "cloud_function_sa" {
  account_id   = "statsbomb-function-sa"
  display_name = "Cloud Function Service Account"
  description  = "SA dedicada solo a ejecutar la función de ingesta"
}

# ==========================================================
# PROJECT IAM BINDINGS
# ==========================================================

resource "google_project_iam_member" "sa_roles_binding" {
  for_each = toset(local.sa_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.github_actions_sa.email}"
}
