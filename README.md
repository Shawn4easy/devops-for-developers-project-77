# Инфраструктура как код

[![hexlet-check](https://github.com/Shawn4easy/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Shawn4easy/devops-for-developers-project-77/actions)

Автоматизация создания инфраструктуры проекта через Terraform и Ansible

Учебный проект Хекслета: https://ru.hexlet.io/programs/devops-for-developers
Как это должно работать: https://asciinema.org/a/aeg7afREm5TJHn9PT0S465lEa

## Стек

- Terraform — описание инфраструктуры в Yandex Cloud
- Ansible — генерация переменных Terraform из зашифрованного хранилища секретов
- Yandex Cloud — облачный провайдер, Object Storage для хранения state
- DataDog — мониторинг доступности приложения на каждом сервере
- UptimeRobot — внешняя проверка доступности сайта из разных регионов

## Инфраструктура

Приложение доступно по адресу **https://shawn4easy.ru**.
Статус доступности: https://stats.uptimerobot.com/6fE93VV7wJ

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
| `monitoring.tf` | монитор DataDog, который следит за приложением на каждом сервере |
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

- `terraform/secrets.auto.tfvars` — ключ сервисного аккаунта, параметры облака и
  ключи DataDog, Terraform подхватывает его сам
- `terraform/secrets.backend.tfvars` — ключи доступа к бакету со state, передаются
  через `terraform init -backend-config`: блок `backend` не принимает переменные

## Использование

### Инфраструктура

```bash
make setup      # установить коллекции Ansible и подключить удалённый state
make tf-plan    # показать изменения
make tf-apply   # создать или обновить инфраструктуру
make tf-destroy # удалить инфраструктуру
make tf-output  # адреса серверов, балансировщика и базы
```

Команды `tf-*` сначала выполняют `make tf-vars`: генерируют файлы переменных из vault.

Создание занимает 15–20 минут: дольше всего поднимается кластер PostgreSQL и
проверяется сертификат. Балансировщик подключает сертификат, только когда Let's Encrypt
его выпустил, поэтому Terraform ждёт проверки домена.

### Деплой

```bash
make deploy          # подготовить серверы и задеплоить блог
make ansible-setup   # только подготовка: Docker, зеркало Docker Hub и агент DataDog
make ansible-monitoring # только агент DataDog
make ansible-deploy  # только деплой приложения
make ansible-inventory # перегенерировать инвентарь
```

Плейбук `ansible/playbook.yml` разбит на play с тегами:

| Тег | Что делает |
|---|---|
| `terraform` | рендерит файлы переменных Terraform из vault |
| `inventory` | читает `terraform output` и генерирует `ansible/inventory/webservers.ini` |
| `setup` | ставит Docker из репозитория Ubuntu, настраивает зеркало Docker Hub и ставит агент DataDog |
| `monitoring` | ставит агент DataDog и проверку `http_check` |
| `deploy` | раскладывает файл окружения и запускает контейнер блога |

Инвентарь веб-серверов в репозиторий не попадает: адреса машин и хост базы берутся
из вывода Terraform при каждом запуске `setup` и `deploy`.

Деплой идёт по одному серверу (`serial: 1`): блог применяет миграции при старте, и
два одновременных запуска на пустой базе мешают друг другу. Плейбук ждёт, пока
приложение ответит `200`, и только потом переходит ко второму серверу.

Пока на веб-серверах не запущено приложение, балансировщик не принимает соединения:
узлы ALB не открывают слушатели без хотя бы одного здорового бэкенда.

### Мониторинг

Агент DataDog 7 ставится на веб-серверы коллекцией `datadog.dd`. Организация заведена
в регионе `datadoghq.eu`, он задан переменной `datadog_site` в
`ansible/group_vars/all/main.yml`. Ключ API нужен агенту, ключ приложения — Terraform
для управления монитором, оба лежат в vault.

Агент каждые 15 секунд запрашивает `http://localhost:8080/` на своём сервере
(`http_check`, экземпляр `blog`). Монитор `datadog_monitor.blog_http` из
`terraform/monitoring.tf` следит за `http.can_connect` отдельно по каждому серверу и
поднимает тревогу, если две из трёх последних проверок неудачны. Если агент перестал
присылать данные дольше 5 минут, монитор тоже поднимает тревогу.

Проверить агент на серверах:

```bash
cd ansible && ansible webservers -b -m command -a 'datadog-agent status'
```

Роль скачивает APT-ключи DataDog с `s3.amazonaws.com` без повторов, а связь с AWS
из облака бывает нестабильной. Плейбук скачивает ключи заранее с повторами, роль
берёт их из локальных файлов.

### Внешняя проверка доступности

DataDog проверяет приложение изнутри, с каждого сервера. Он не заметит, что сайт
недоступен снаружи: например, когда сломался DNS, истёк сертификат или
балансировщик перестал принимать соединения.

Эту проверку делает UptimeRobot. Каждые 5 минут он запрашивает
`https://shawn4easy.ru` из разных регионов и шлёт письмо, если сайт не ответил.
Монитор заведён в веб-интерфейсе UptimeRobot, публичная страница статуса:
https://stats.uptimerobot.com/6fE93VV7wJ

В задании Хекслета предлагается Upmon, но сейчас он умеет только принимать сигналы
от cron-задач и сам сайты не проверяет. Поэтому взят UptimeRobot, аналог Pingdom из
того же задания.

### Если сервер не может скачать пакеты

Часть публичных адресов Yandex Cloud попадает под фильтрацию: с них не открываются
`download.docker.com`, `github.com`, Docker Hub и репозитории DataDog на AWS. Блокировка идёт по адресу источника,
и лечится перезапуском машины — она получает новый адрес:

```bash
yc compute instance stop app-a && yc compute instance start app-a
terraform -chdir=terraform apply -refresh-only  # записать новый адрес в state
make deploy
```

---

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
