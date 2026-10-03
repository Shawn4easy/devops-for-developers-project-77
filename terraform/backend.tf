# Ключи доступа к бакету передаются при инициализации:
# terraform init -backend-config=secrets.backend.tfvars
terraform {
  backend "s3" {
    bucket = "shawn4easy-hexlet-77-tfstate"
    key    = "terraform.tfstate"
    region = "ru-central1"

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
  }
}
