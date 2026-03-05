# Este fichero se mantiene vacío intencionalmente.
# Los recursos están organizados por concern en ficheros separados:
#
#   providers.tf          → Terraform backend y provider de Google
#   variables.tf          → Variables de entrada
#   locals.tf             → Valores locales compartidos
#   storage.tf            → Data Lake (Cloud Storage) e IAM del bucket
#   iam.tf                → Service Accounts y Project IAM bindings
#   workload_identity.tf  → Workload Identity Federation (keyless auth)
#   outputs.tf            → Outputs útiles tras terraform apply