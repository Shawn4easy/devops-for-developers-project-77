variable "yc_service_account_key" {
  description = "Авторизованный ключ сервисного аккаунта в формате JSON"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Идентификатор облака"
  type        = string
}

variable "yc_folder_id" {
  description = "Идентификатор каталога"
  type        = string
}

variable "yc_zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-a"
}

variable "project_name" {
  description = "Префикс имён ресурсов"
  type        = string
  default     = "app"
}

variable "domain" {
  description = "Домен приложения, делегированный на NS-серверы Yandex Cloud"
  type        = string
  default     = "shawn4easy.ru"
}

variable "subnets" {
  description = "Подсети по зонам доступности: в каждой поднимается один веб-сервер"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.10.1.0/24"
    "ru-central1-b" = "10.10.2.0/24"
  }
}

variable "admin_ssh_key" {
  description = "Публичный SSH-ключ пользователя ubuntu на веб-серверах"
  type        = string
}

variable "vm_image_family" {
  description = "Семейство образа для веб-серверов"
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "vm_cores" {
  description = "Число vCPU веб-сервера"
  type        = number
  default     = 2
}

variable "vm_core_fraction" {
  description = "Гарантированная доля vCPU, %"
  type        = number
  default     = 20
}

variable "vm_memory" {
  description = "Память веб-сервера, ГБ"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Размер загрузочного диска, ГБ"
  type        = number
  default     = 15
}

variable "app_port" {
  description = "Порт приложения на веб-серверах"
  type        = number
  default     = 3000
}

variable "db_name" {
  description = "Имя базы данных приложения"
  type        = string
  default     = "app"
}

variable "db_user" {
  description = "Пользователь базы данных приложения"
  type        = string
  default     = "app"
}

variable "db_password" {
  description = "Пароль пользователя базы данных"
  type        = string
  sensitive   = true
}

variable "db_resource_preset" {
  description = "Класс хоста PostgreSQL"
  type        = string
  default     = "b2.medium"
}

variable "db_disk_size" {
  description = "Размер диска PostgreSQL, ГБ"
  type        = number
  default     = 10
}
