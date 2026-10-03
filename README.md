# Инфраструктура как код

[![hexlet-check](https://github.com/Shawn4easy/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Shawn4easy/devops-for-developers-project-77/actions)

Автоматизация создания инфраструктуры проекта через Terraform и Ansible

Учебный проект Хекслета: https://ru.hexlet.io/programs/devops-for-developers
Как это должно работать: https://asciinema.org/a/aeg7afREm5TJHn9PT0S465lEa

## Стек

- Terraform — описание инфраструктуры в Yandex Cloud
- Ansible — генерация переменных Terraform из зашифрованного хранилища секретов
- Yandex Cloud — облачный провайдер, Object Storage для хранения state

## Структура

```
terraform/   конфигурация Terraform: provider.tf, backend.tf, variables.tf
ansible/     плейбуки, шаблоны и зашифрованные секреты (Ansible Vault)
```

## Требования

- Terraform 1.10 или новее
- Ansible 2.15 или новее
- `make`

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
лежит в `~/.config/hexlet-devops-77/vault_pass`, путь к нему прописан в `ansible/ansible.cfg`.

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
make tf-init    # сгенерировать переменные и подключить удалённый state
make tf-plan    # показать изменения
make tf-apply   # применить изменения
make tf-destroy # удалить инфраструктуру
```

Каждая команда сначала выполняет `make tf-vars`: генерирует файлы переменных из vault.

---

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
