# ARCON – REST API for RCON Servers 🏴‍☠️
<img style="background:white; padding: 30px;max-height:250px" src="logo.svg">

**ARCON** _(pronounced ARRR-con, like a pirate growling "RCON")_ is a multi-tenant REST API for managing and executing **RCON commands** on dedicated game servers. It provides fine-grained access control, command catalogs, audit logging, and real-time WebSocket support — all defined as an OpenAPI 3.0 contract.

> **This repository contains the API specification only, not the service implementation.**

## ⚙️ Features

- 📡 RCON command execution via REST and WebSocket
- 🏢 Multi-tenant support — organize servers and users into tenants
- 🔐 Bearer JWT authentication via external Identity Provider (Keycloak, Auth0, etc.)
- 🛡️ Per-command permissions with role-based access control and per-user overrides
- 📚 Command catalogs — structured definitions of RCON commands per game, hosted globally or per-tenant
- 📜 Audit logging — track who ran what command on which server
- 🔄 Command history with replay
- ⭐ Favourites — save and share command templates across users, roles, or tenants
- ⚡ Quick Connect mode — execute RCON commands without server registration
- 🔌 WebSocket support for real-time command execution

## 🛠️ Use Cases

- **Quick Connect**: Point at any RCON server, authenticate, and send commands — no setup needed
- **Managed Mode**: Register servers in a tenant, assign roles with per-command permissions, and let your team manage game servers through a controlled interface
- Game server management (Minecraft, Project Zomboid, ARK, CS, Rust, and more)
- Admin panels and dashboards
- Automated server orchestration and monitoring

## 📁 Repository Structure

```
src/
  api.yml              Root OpenAPI spec with all path references
  paths/               One file per endpoint (Path Item Objects)
  schemas/             One file per data model
scripts/
  build.sh             Linux/macOS build script
  build_windows.ps1    Windows build script (runs via Docker)
build/
  openapi.yml          Bundled single-file spec (generated)
  api_doc.html         Static HTML documentation (generated)
```

The spec is split into multiple files for maintainability. The build system uses [redocly](https://redocly.com/docs/cli/) to bundle everything into a single `openapi.yml` and generate static HTML docs.

## 🚀 Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)

### Build

**Windows:**
```powershell
.\scripts\build_windows.ps1
```

**Linux/macOS (via Docker):**
```bash
docker build -t arcon-api-build .
docker run --rm -v ./src:/api/src -v ./build:/api/build arcon-api-build
```

This generates `build/openapi.yml` (bundled spec) and `build/api_doc.html` (browsable API documentation).

To force a Docker image rebuild (e.g. after changing build scripts):
```powershell
.\scripts\build_windows.ps1 --build
```

### View Documentation

Open `build/api_doc.html` in your browser after building.
