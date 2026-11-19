# PostgreSQL в Docker на Windows: запуск и подключение через DBeaver

За несколько шагов вы запустите локальную базу `appdb`, подключитесь к ней из DBeaver и выполните первый SQL-запрос. Устанавливать сервер PostgreSQL в Windows отдельно не нужно.

## 1. Подготовьте программы

1. [Установите Docker Desktop](docker-desktop-windows.md), если его ещё нет. Запустите приложение и дождитесь запуска движка.
2. Скачайте и установите [DBeaver Community для Windows](https://dbeaver.io/download/). DBeaver — графический клиент для работы с базой, а не сама база данных.
3. Откройте **Windows PowerShell** через меню «Пуск» и выполните `docker info`. Если в выводе есть ошибка подключения к движку, сначала проверьте Docker Desktop. Команды ниже предназначены для PowerShell, не для SQL-редактора DBeaver.

## 2. Запустите PostgreSQL

Вставьте команду целиком в PowerShell и нажмите Enter. Перед запуском замените `LocalPg_ChangeMe_2026` на свой пароль для локальной базы и сохраните его. Для этого примера используйте длинный пароль из букв, цифр и `_`, чтобы не пришлось экранировать спецсимволы PowerShell.

```powershell
docker run -d --name pg-local -e POSTGRES_PASSWORD=LocalPg_ChangeMe_2026 -e POSTGRES_DB=appdb -p 127.0.0.1:15432:5432 -v pg-local-data:/var/lib/postgresql/data postgres:17
```

- `postgres:17` — официальный образ PostgreSQL 17. Docker скачает его при первом запуске. Путь к тому указан для версии 17; для 18 и новее официальный образ использует другую точку монтирования.
- `pg-local` — имя контейнера. Команда `docker run` создаёт его один раз.
- `127.0.0.1:15432:5432` — порт `15432` на вашем компьютере направляется на порт `5432` внутри контейнера. Привязка к `127.0.0.1` предназначена для локального подключения, а не доступа из сети.
- `pg-local-data` — именованный том Docker, отдельное хранилище данных. Он сохраняет данные при остановке и пересоздании контейнера, если тот же том подключён снова. Том не заменяет резервную копию.

Проверьте запуск:

```powershell
docker ps --filter name=pg-local
docker exec pg-local pg_isready -h 127.0.0.1 -U postgres -d appdb
```

В выводе второй команды должно быть `accepting connections`. Если сервер ещё запускается, подождите несколько секунд и повторите проверку. Если контейнера нет в списке запущенных, выполните `docker ps -a` и `docker logs --tail 50 pg-local`.

## 3. Подключитесь из DBeaver

1. Откройте **Database → New Database Connection**. Выберите **PostgreSQL** и нажмите **Next**.
2. Заполните поля:

   | Поле | Значение |
   | --- | --- |
   | Host | `127.0.0.1` |
   | Port | `15432` |
   | Database | `appdb` |
   | Username | `postgres` |
   | Password | Пароль, который вы указали в `POSTGRES_PASSWORD` |

3. Нажмите **Test Connection**. Если DBeaver предложит скачать драйвер PostgreSQL, согласитесь и дождитесь загрузки. После успешной проверки нажмите **Finish**.

## 4. Создайте таблицу и проверьте данные

В навигаторе DBeaver нажмите правой кнопкой по подключению и откройте **SQL Editor → New SQL Script**. Вставьте запросы ниже и выполните их по очереди: поставьте курсор в нужный запрос и нажмите `Ctrl + Enter`.

```sql
SELECT current_database(), current_user;

CREATE TABLE IF NOT EXISTS public.notes (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title text NOT NULL UNIQUE
);

INSERT INTO public.notes (title)
VALUES ('Моя первая запись')
ON CONFLICT (title) DO NOTHING;

SELECT id, title FROM public.notes;
```

Первый запрос должен показать `appdb` и `postgres`, последний — строку «Моя первая запись». Если таблица не появилась в дереве, обновите узел **Schemas → public → Tables**. Если в DBeaver включён ручной режим транзакций, нажмите **Commit**, чтобы сохранить изменения.

## 5. Остановка и повторный запуск

```powershell
docker stop pg-local
docker start pg-local
```

После `docker start` дождитесь готовности сервера и снова подключитесь. Повторять `docker run` не нужно. Не удаляйте том `pg-local-data`, если хотите сохранить базу.

## Если что-то не получилось

| Симптом | Что проверить |
| --- | --- |
| Порт `15432` занят при первом запуске | Если неудачная попытка создала контейнер, проверьте его через `docker ps -a`. Только если это ваш новый контейнер и он не запущен, удалите его командой `docker rm pg-local`. Повторите команду запуска с `127.0.0.1:15433:5432`, а в DBeaver укажите `15433`. |
| Имя `pg-local` уже используется | Посмотрите `docker ps -a`. Если это ваш ранее созданный контейнер, используйте `docker start pg-local` вместо `docker run`. |
| `Connection refused` | Проверьте запуск контейнера, результат `pg_isready` и порт в DBeaver. Внутренний `5432` здесь не равен порту Windows. |
| `password authentication failed` | Проверьте пароль. Значения `POSTGRES_PASSWORD` и `POSTGRES_DB` применяются при первой инициализации пустого тома. Повторный запуск с новым значением не меняет пароль существующей базы. |

Пароль из примера не используйте вне локальной учебной среды. Не публикуйте свой пароль в GitHub; переменная, переданная через `-e`, доступна в конфигурации контейнера, а сама команда может остаться в истории PowerShell.

Далее: [Как восстановить PostgreSQL из резервной копии](postgresql-restore-backup.md).

Документация: [образ PostgreSQL](https://hub.docker.com/_/postgres/) · [подключение PostgreSQL в DBeaver](https://dbeaver.com/docs/dbeaver/Database-driver-PostgreSQL/).
