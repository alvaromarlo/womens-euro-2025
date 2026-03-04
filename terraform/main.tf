# ==========================================================
# 1. DATA LAKE (CLOUD STORAGE EN FREE TIER)
# ==========================================================
resource "google_storage_bucket" "datalake" {
  name          = "datalake-euro2025-tf" # Cámbialo si este nombre ya está en uso
  location      = "US-CENTRAL1"              # Obligatorio para Free Tier
  storage_class = "STANDARD"

  uniform_bucket_level_access = true         # Buena práctica de seguridad
  force_destroy               = true         # Permite a Terraform borrar el bucket aunque tenga archivos
}

# ==========================================================
# 2. CUENTA DE SERVICIO & PERMISOS
# ==========================================================
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa-tf"
  display_name = "GitHub Actions SA Data"
}

# Asignar los 3 roles exactos a la Cuenta de Servicio
locals {
  sa_roles = [
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/storage.objectAdmin"
  ]
}

resource "google_project_iam_member" "sa_roles_binding" {
  for_each = toset(local.sa_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# ==========================================================
# 3. WORKLOAD IDENTITY FEDERATION (KEYLESS AUTH)
# ==========================================================
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool-tf"
  display_name              = "GitHub Actions Pool Data"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider-tf"
  display_name                       = "GitHub Provider"

  # Mapeo de atributos (El Paso 2 de la consola)
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Condición de atributo (La caja de texto donde tuvimos el error)
  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ==========================================================
# 4. UNIR GITHUB CON LA CUENTA DE SERVICIO (EL PASO FINAL)
# ==========================================================
resource "google_service_account_iam_member" "github_sa_binding" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  
  # Le damos permiso específicamente a la identidad que coincida con tu repositorio
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}