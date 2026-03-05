terraform {
  # --- AQUÍ CONFIGURAS EL BUCKET QUE ACABAS DE CREAR ---
  backend "gcs" {
    bucket = "tf-state-euro2025" # El nombre exacto de tu nuevo bucket
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}