# SQL Server en Docker Compose 🚀

Este proyecto contiene una configuración robusta y lista para producción de **Microsoft SQL Server 2022** utilizando Docker Compose.

## 📋 Requisitos Previos

Asegúrate de tener instalados:
* [Docker](https://docs.docker.com/get-docker/)
* [Docker Compose](https://docs.docker.com/compose/install/)

---

## ⚙️ Configuración (`.env`)

Los parámetros sensibles y de red se gestionan en el archivo [`.env`](./.env).

> [!IMPORTANT]
> **Requisito de Contraseña Fuerte de SQL Server:**
> SQL Server requiere por defecto una contraseña que cumpla con las políticas de complejidad de Windows/SQL Server. Debe tener:
> 1. Al menos 8 caracteres de longitud.
> 2. Contener caracteres de al menos 3 de los siguientes grupos:
>    * Letras mayúsculas (`A-Z`)
>    * Letras minúsculas (`a-z`)
>    * Números base 10 (`0-9`)
>    * Símbolos no alfanuméricos (ej. `!`, `@`, `#`, `$`, `%`)
>
> Si la contraseña no es lo suficientemente fuerte, el contenedor **se detendrá inmediatamente** al iniciar. Puedes cambiar la contraseña en el archivo [`.env`](./.env).

---

## 🚀 Cómo Iniciar el Servicio

Para levantar el servidor en segundo plano (modo daemon):

```bash
docker compose up -d
```

### 🔍 Verificar el Estado

Para ver si el contenedor está corriendo correctamente:

```bash
docker compose ps
```

Para inspeccionar los logs en tiempo real y asegurarte de que SQL Server inició con éxito:

```bash
docker compose logs -f
```

Deberías ver un mensaje similar a:
`SQL Server is now ready for client connections.`

---

## 🛑 Detener el Servicio

Para detener el contenedor manteniendo intactos todos los datos:

```bash
docker compose down
```

Para detener el contenedor **y eliminar** todos los datos almacenados en el volumen (reinicio completo de fábrica):

```bash
docker compose down -v
```

---

## 🔌 Cómo Conectarse

Puedes conectarte a este SQL Server usando tus herramientas favoritas con las siguientes credenciales:

* **Servidor (Host):** `localhost` (o `127.0.0.1`)
* **Puerto:** El configurado en `.env` (por defecto `1433`)
* **Usuario (Authentication Type):** SQL Server Authentication
* **Usuario (Username):** `sa`
* **Contraseña:** La configurada en `MSSQL_SA_PASSWORD` dentro del archivo `.env` (por defecto `yourStrong(!)Password2026`)

### Herramientas Recomendadas:
1. **DBeaver** (Multiplataforma, muy potente y gratuito).
2. **Azure Data Studio** (De Microsoft, excelente soporte y multiplataforma).
3. **SQL Server Management Studio (SSMS)** (Solo Windows).
4. **VS Code** con la extensión `SQL Server (mssql)`.

---

## 📂 Estructura de Archivos

* [`docker-compose.yml`](./docker-compose.yml) - Configuración del servicio de SQL Server y definición del volumen persistente.
* [`.env`](./.env) - Configuración de variables de entorno (puerto y contraseña).
* [`README.md`](./README.md) - Esta guía de uso y documentación rápida.
