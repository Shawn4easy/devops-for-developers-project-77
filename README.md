# Инфраструктура как код

[![hexlet-check](https://github.com/Shawn4easy/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Shawn4easy/devops-for-developers-project-77/actions)

Автоматизация создания инфраструктуры проекта через Terraform и Ansible

Учебный проект Хекслета: https://ru.hexlet.io/programs/devops-for-developers
Как это должно работать: https://asciinema.org/a/aeg7afREm5TJHn9PT0S465lEa

## Стек

- Terraform — описание инфраструктуры в Yandex Cloud
- Ansible — генерация переменных Terraform из зашифрованного хранилища секретов
- Yandex Cloud — облачный провайдер, Object Storage для хранения state

## Инфраструктура

Приложение доступно по адресу **https://shawn4easy.ru**.

Разворачивается блог на Fastify из проекта
[devops-for-programmers-project-lvl1](https://github.com/Shawn4easy/devops-for-programmers-project-lvl1),
образ [`shawn4easy/devops-for-programmers-project-lvl1`](https://hub.docker.com/r/shawn4easy/devops-for-programmers-project-lvl1).
Данные хранятся в Managed PostgreSQL.

```
     shawn4easy.ru :80 → :443
                │
       ┌────────▼────────┐
       │  app-alb (L7)   │  TLS, сертификат Let's Encrypt
       └────────┬────────┘
        ┌───────┴───────┐
   ┌────▼────┐     ┌────▼────┐
   │  app-a  │     │  app-b  │   веб-серверы в зонах a и b
   └────┬────┘     └────┬────┘
        └───────┬───────┘
       ┌────────▼────────┐
       │ app-db (PG 16)  │  Managed PostgreSQL
       └─────────────────┘
```

Конфигурация Terraform разбита по файлам:

| Файл | Что описывает |
|---|---|
| `network.tf` | сеть и подсети в зонах `ru-central1-a` и `ru-central1-b` |
| `security.tf` | группы безопасности балансировщика, веб-серверов и базы |
| `compute.tf` | две виртуальные машины Ubuntu 24.04 |
| `database.tf` | кластер Managed PostgreSQL, база и пользователь |
| `alb.tf` | L7-балансировщик: HTTPS-обработчик и редирект с HTTP |
| `certificate.tf` | managed-сертификат Let's Encrypt и записи для его проверки |
| `dns.tf` | DNS-зона домена и A-записи на балансировщик |
| `outputs.tf` | адреса серверов, балансировщика и базы |

Домен `shawn4easy.ru` зарегистрирован в reg.ru и делегирован на
`ns1.yandexcloud.net` и `ns2.yandexcloud.net`.

## Структура

```
terraform/   конфигурация Terraform: provider.tf, backend.tf, variables.tf
ansible/     плейбуки, шаблоны и зашифрованные секреты (Ansible Vault)
```

## Требования

- Terraform 1.10 или новее
- Ansible 2.15 или новее
- `make`
- SSH-ключ для доступа к серверам: `ssh-keygen -t ed25519 -f ~/.ssh/hexlet_devops_77`.
  Путь к публичной части задаётся переменной `admin_ssh_key_path` в
  `ansible/group_vars/all/main.yml`

Реестр HashiCorp из России недоступен, поэтому провайдеры ставятся с зеркала
Yandex Cloud. Для этого в `~/.terraformrc` прописывается:

```hcl
provider_installation {
  network_mirror {
    url     = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

## Установка

```bash
git clone https://github.com/Shawn4easy/devops-for-developers-project-77.git
cd devops-for-developers-project-77
```

### Секреты

Terraform работает от сервисного аккаунта `terraform-sa` с ролью `editor` на каталог.
State хранится в бакете Object Storage `shawn4easy-hexlet-77-tfstate`. Сервисный аккаунт
и бакет создаются один раз вручную через `yc`: они нужны самому Terraform для работы.

Ключи хранятся в зашифрованном файле `ansible/group_vars/all/vault.yml`. Состав
переменных — в образце `ansible/group_vars/all/vault.yml.example`. Пароль от vault
лежит в `~/.config/hexlet-devops-77/vault_pass`. `Makefile` передаёт его Ansible через
`ANSIBLE_VAULT_PASSWORD_FILE`, другой путь задаётся так: `make VAULT_PASSWORD_FILE=<путь> <цель>`.

```bash
make vault-view   # посмотреть секреты
make vault-edit   # изменить секреты
```

Terraform секреты не расшифровывает. Ansible рендерит из vault два файла, которые
не попадают в репозиторий:

- `terraform/secrets.auto.tfvars` — ключ сервисного аккаунта и параметры облака,
  Terraform подхватывает его сам
- `terraform/secrets.backend.tfvars` — ключи доступа к бакету со state, передаются
  через `terraform init -backend-config`: блок `backend` не принимает переменные

## Использование

```bash
make setup      # установить зависимости Ansible и подключить удалённый state
make tf-init    # сгенерировать переменные и подключить удалённый state
make tf-plan    # показать изменения
make tf-apply   # применить изменения
make tf-destroy # удалить инфраструктуру
make tf-output  # адреса серверов, балансировщика и базы
```

Команды `tf-*` сначала выполняют `make tf-vars`: генерируют файлы переменных из vault.

Создание занимает 15–20 минут: дольше всего поднимается кластер PostgreSQL и
проверяется сертификат. Балансировщик подключает сертификат, только когда Let's Encrypt
его выпустил, поэтому Terraform ждёт проверки домена.

Пока на веб-серверах не запущено приложение, балансировщик не принимает соединения:
узлы ALB не открывают слушатели без хотя бы одного здорового бэкенда.

---

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
