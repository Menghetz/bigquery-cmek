# Enable the BigQuery service account to encrypt/decrypt Cloud KMS keys
data "google_project" "project" {
}

resource "google_project_iam_member" "service_account_access" {
  project = data.google_project.project.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:bq-${data.google_project.project.number}@bigquery-encryption.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "gs_service_account_access" {
  project = data.google_project.project.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_kms_key_ring" "my_key_ring" {
  name     = "my-key-ring"
  location = var.region
}

resource "google_kms_crypto_key" "my_crypto_key" {
  name            = "my-crypto-key"
  key_ring        = google_kms_key_ring.my_key_ring.id
  rotation_period = "100000s" # Adjust rotation period as needed
}

resource "google_bigquery_dataset" "my_dataset" {
  dataset_id                  = "kms_dataset"
  location                    = var.region
  description                 = "Encrypted with CMKE"
  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.my_crypto_key.id
  }

  depends_on = [google_project_iam_member.service_account_access]

}

resource "google_storage_bucket" "my-kms-bucket" {
  name          = "${data.google_project.project.number}-kms"
  location      = var.region

  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name =  google_kms_crypto_key.my_crypto_key.id
  }
  depends_on = [ google_project_iam_member.gs_service_account_access ]
}

# resource "google_bigquery_table" "my_table" {
#   dataset_id = google_bigquery_dataset.my_dataset.dataset_id
#   table_id   = "my_table"
#   schema {
#     fields {
#       name = "id"
#       type = "STRING"
#       mode = "REQUIRED"
#     }
#     fields {
#       name = "name"
#       type = "STRING"
#     }
#     # Add more fields as needed
#   }
#   encryption_configuration {
#     kms_key_name = google_kms_crypto_key.my_crypto_key.self_link
#   }
# }
