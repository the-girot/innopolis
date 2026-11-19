# Как запустить Apache Airflow в Docker на Windows 10 или 11

В этой инструкции вы поднимете Airflow 3.4.0, откроете его в браузере и запустите первую задачу. Используем официальный Docker Compose: он сам поднимет отдельный PostgreSQL для метаданных Airflow и Redis для очереди задач. Подключать `pg-local` из урока по PostgreSQL не нужно.

> Это локальная учебная установка, не для продакшена. Интерфейс будет доступен только с этого компьютера.

## Шаг 1. Проверьте Docker Desktop

Если Docker ещё не установлен, пройдите [инструкцию по установке Docker Desktop](docker-desktop-windows.md). Запустите Docker Desktop и откройте **Windows PowerShell**. Все команды ниже выполняйте в PowerShell, а не в Ubuntu или CMD.

```powershell
docker info --format 'OS={{.OSType}} RAM={{.MemTotal}}'
docker compose version
```

- В первой строке ожидается `OS=linux`. `RAM` — память, доступная Docker, в байтах. Airflow рекомендует выделить Docker не менее 4 ГБ, лучше 8 ГБ, если на компьютере достаточно памяти. Если Docker видит меньше примерно 4 миллиардов байт, сначала увеличьте лимит.
- Docker Compose должен быть версии 2.14.0 или новее. Если команды нет или версия ниже, обновите Docker Desktop.
- Если Docker не отвечает, дождитесь запуска движка. Если `OS=windows`, переключите Docker Desktop в режим Linux-контейнеров.

## Шаг 2. Создайте отдельную папку и скачайте Compose

Используйте новую папку, не ту, в которой уже лежит другой `docker-compose.yaml` или `.env`.

```powershell
New-Item -ItemType Directory -Path "$HOME\airflow-local" -ErrorAction Stop
Set-Location "$HOME\airflow-local"
Invoke-WebRequest -UseBasicParsing -ErrorAction Stop -Uri 'https://airflow.apache.org/docs/apache-airflow/3.4.0/docker-compose.yaml' -OutFile 'docker-compose.yaml'
```

Если папка уже существует от предыдущей попытки, не перезаписывайте её файлы вслепую. Для чистого запуска выберите другое имя папки; для продолжения вернитесь в существующую папку и перейдите к нужному шагу.

## Шаг 3. Подготовьте настройки

Выполните блок в папке `airflow-local`. Он создаёт рабочие каталоги и `.env`, а затем меняет публикацию интерфейса с `8080` на `127.0.0.1:8088`. Внутри контейнера порт остаётся `8080`.

```powershell
New-Item -ItemType Directory -Path dags,logs,plugins,config -Force | Out-Null
@'
AIRFLOW_UID=50000
FERNET_KEY=
_AIRFLOW_WWW_USER_USERNAME=airflow
_AIRFLOW_WWW_USER_PASSWORD=airflow
'@ | Set-Content -Path .env -Encoding ascii

$compose = Get-Content -Raw -Path docker-compose.yaml
if (-not $compose.Contains('"8080:8080"')) { throw 'Expected port mapping not found.' }
$compose.Replace('"8080:8080"', '"127.0.0.1:8088:8080"').Replace("AIRFLOW__CORE__LOAD_EXAMPLES: 'true'", "AIRFLOW__CORE__LOAD_EXAMPLES: 'false'") | Set-Content -Path docker-compose.yaml -Encoding ascii

docker compose config --quiet
```

Последняя команда проверяет конфигурацию; если она завершилась без ошибок, переходите дальше. `FERNET_KEY` намеренно оставлен пустым для учебной среды — не храните здесь реальные секреты. Блок изменения портов рассчитан на исходный скачанный файл и выполняется один раз.

## Шаг 4. Скачайте образы и инициализируйте Airflow

Команды выполняйте по одной. Нужен интернет; первая загрузка может занять несколько минут.

```powershell
docker compose pull
docker compose up airflow-init
docker compose ps -a airflow-init
```

`airflow-init` подготавливает базу метаданных и создаёт пользователя. В выводе последней команды ожидается **`Exited (0)`**: это одноразовый сервис, он не должен оставаться запущенным. При другом коде не переходите дальше; посмотрите `docker compose logs --tail 100 airflow-init`.

## Шаг 5. Запустите сервисы и откройте интерфейс

```powershell
docker compose up -d
docker compose ps
```

Подождите, пока `airflow-apiserver`, `airflow-scheduler`, `airflow-dag-processor` и `airflow-worker` пройдут проверки состояния. Сразу после запуска `health: starting` — нормально. Повторите `docker compose ps` через 30–60 секунд, если сервисы ещё стартуют.

Откройте в браузере **http://127.0.0.1:8088**. Для входа используйте логин `airflow` и пароль `airflow` — они заданы в `.env` для этого локального урока.

## Шаг 6. Запустите первый DAG

DAG — workflow: описание задач и порядка их выполнения. Создайте файл `dags/hello_airflow.py` прямо из PowerShell:

```powershell
@'
from airflow.sdk import dag, task


@dag(dag_id="hello_airflow", schedule=None, catchup=False)
def hello_airflow():
    @task
    def say_hello():
        print("Hello from Airflow!")

    say_hello()


hello_airflow()
'@ | Set-Content -Path dags/hello_airflow.py -Encoding ascii
```

1. Откройте список **DAGs** и найдите `hello_airflow`. Если его не видно сразу, подождите около минуты и обновите страницу: Airflow должен обнаружить и обработать файл.
2. Откройте `hello_airflow`. Если DAG на паузе, включите его переключателем. Нажмите **Trigger DAG** и подтвердите запуск, если интерфейс попросит. С расписанием `None` DAG запускается только вручную, если не настроен внешний триггер.
3. Откройте созданный запуск, выберите задачу `say_hello` и вкладку **Logs**. Успешная проверка: статус `success`, в логе есть `Hello from Airflow!`.

## Шаг 7. Остановите и запустите снова

Из той же папки:

```powershell
docker compose stop
```

Когда захотите продолжить:

```powershell
docker compose up -d
```

Повторно скачивать файл и вручную выполнять `airflow-init` не нужно. Не используйте `docker compose down -v`, если хотите сохранить историю запусков, пользователей и настройки: команда удаляет том с метаданными. Python-файлы DAG хранятся отдельно в папке `dags` на Windows.

## Если что-то не получилось

| Симптом | Что сделать |
| --- | --- |
| `no configuration file provided` | Выполните `Set-Location "$HOME\airflow-local"` и проверьте `Get-ChildItem -Force`: должны быть `docker-compose.yaml` и `.env`. |
| Порт `8088` занят | В `docker-compose.yaml` замените `127.0.0.1:8088:8080` на `127.0.0.1:8089:8080`. Повторите `docker compose up -d` и откройте `http://127.0.0.1:8089`. |
| Сервисы перезапускаются, выводят предупреждение о памяти или завершаются с `137` | Проверьте память командой из шага 1 и посмотрите `docker compose logs --tail 80`. При недостатке памяти проверьте лимиты WSL 2, в том числе параметры `memory` и `processors` в `%USERPROFILE%\.wslconfig`, если файл уже существует. После изменения сохраните работу в WSL, закройте Docker Desktop, выполните `wsl --shutdown`, затем снова запустите Docker Desktop. Эта команда останавливает все запущенные дистрибутивы WSL. |
| Интерфейс не открывается | Выполните `docker compose ps` и `docker compose logs --tail 80 airflow-apiserver`. Дождитесь `healthy` и проверьте адрес и порт из шага 5. |
| DAG не появился | Убедитесь, что файл называется `hello_airflow.py`, а не `hello_airflow.py.txt`. Проверьте ошибки командой `docker compose exec airflow-dag-processor airflow dags list-import-errors`. |
| Задача долго остаётся в очереди | Убедитесь, что DAG не на паузе, проверьте `docker compose ps` и выполните `docker compose logs --tail 80 airflow-scheduler airflow-worker`. |

Документация: [официальный запуск Airflow через Docker Compose](https://airflow.apache.org/docs/apache-airflow/3.4.0/howto/docker-compose/index.html) · [настройки WSL 2](https://learn.microsoft.com/windows/wsl/wsl-config).
