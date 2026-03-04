variable "project_id" {
  description = "El ID de tu proyecto de Google Cloud (no el número, el ID)"
  type        = string
}

variable "region" {
  description = "Región principal para los recursos (Free Tier)"
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "El repositorio de GitHub que tendrá acceso"
  type        = string
  default     = "alvaromarlo/womens-euro-2025"
}