# ARCON REST API Design Spec

## Overview

ARCON is a multi-tenant REST API for executing RCON commands on game servers. It provides two modes of operation:

1. **Quick connect** -- Authenticated users provide connection details directly and send RCON commands. No server registration, no permission checks, rate-limited.
2. **Managed mode** -- Servers are registered within a tenant. Users are assigned roles with fine-grained per-command permissions. Full audit logging, command history, favourites, and real-time WebSocket support.

The API is defined as an OpenAPI 3.0 contract. A separate repository (`arcon-commands`) will define game-specific command catalogs using a structured schema (full contracts with typed parameters, command variants/overloads, and RCON-invocability flags).

## Authentication & Security

### Security Scheme

Bearer JWT issued by an external Identity Provider (Keycloak, Auth0, or similar). ARCON validates tokens but does not handle login, registration, or password management.

### Headers

- `Authorization: Bearer <jwt>` -- required on all endpoints except health/info
- `X-Tenant-Id: <uuid>` -- required on tenant-scoped endpoints, omitted for `/tenants`, `/rcon/exec`, `/invites/{code}`, `/me`

### Expected JWT Claims

- `sub` (user ID)
- `email`
- `roles` (platform roles: `admin`, `user`)

### Authorization Layers

1. **Platform level**: Is this a valid JWT? (all endpoints)
2. **Tenant level**: Is this user a member of the tenant in `X-Tenant-Id`? What's their tenant role? (tenant-scoped endpoints)
3. **Server level**: Does this user have permission to execute this command on this server? (execution endpoints)

### User Profile Endpoint

- `GET /me` -- Returns the current user's profile, tenant memberships, and permissions. No `X-Tenant-Id` required.

## Tenant Management

### Endpoints

- `POST /tenants` -- Create a tenant (any authenticated user). Creator becomes owner.
- `GET /tenants` -- List tenants the current user is a member of
- `GET /tenants/{id}` -- Get tenant details
- `PUT /tenants/{id}` -- Update tenant (name, description, settings). Owner/admin only.
- `DELETE /tenants/{id}` -- Delete tenant. Owner only.

### Tenant Model

| Field         | Type     | Notes                        |
|---------------|----------|------------------------------|
| `id`          | uuid     |                              |
| `name`        | string   | e.g., "Leberkas Gaming"      |
| `description` | string   |                              |
| `ownerId`     | uuid     | References the user          |
| `createdAt`   | datetime |                              |
| `updatedAt`   | datetime |                              |

Ownership transfer via `PUT /tenants/{id}` by setting a new `ownerId` (current owner only).

### Built-in Tenant Roles

- `owner` -- Full control, can delete tenant, manage admins
- `admin` -- Manage servers, roles, members, view audit logs
- `member` -- Use servers according to assigned RCON permissions

Users can be members of multiple tenants with different roles in each.

## Member Management

All endpoints require `X-Tenant-Id`.

### Endpoints

- `GET /members` -- List members of the tenant
- `PUT /members/{userId}` -- Update a member's tenant role
- `DELETE /members/{userId}` -- Remove member from tenant

### Invite Flow

1. Admin calls `POST /members/invite` with an email and tenant role
2. ARCON generates a unique invite code and returns an invite URL
3. Admin shares the link (Discord, email, etc.)
4. Invitee opens the link, authenticates via IdP, accepts
5. ARCON links their IdP identity to the tenant with the assigned role

### Invite Endpoints

- `POST /members/invite` -- Create invite (admin+). Returns invite code/URL. Requires `X-Tenant-Id`.
- `GET /members/invites` -- List pending invites (admin+). Requires `X-Tenant-Id`.
- `DELETE /members/invites/{code}` -- Revoke a pending invite. Requires `X-Tenant-Id`.
- `GET /invites/{code}` -- Get invite details (tenant name, who invited). No auth required. Returns 404 if code is invalid or expired.
- `POST /invites/{code}/accept` -- Accept invite. Requires auth, no `X-Tenant-Id`.

### Invite Model

| Field       | Type              | Notes                                             |
|-------------|-------------------|----------------------------------------------------|
| `code`      | string            | Unique invite code                                 |
| `tenantId`  | uuid              |                                                    |
| `email`     | string (nullable) | If set, only this email can accept                 |
| `role`      | enum              | Tenant role the invitee will receive               |
| `invitedBy` | uuid              | userId of the inviter                              |
| `createdAt` | datetime          |                                                    |
| `expiresAt` | datetime          |                                                    |

If `email` is omitted, the invite link works for anyone (useful for open communities).

## Server Management

All endpoints require `X-Tenant-Id`.

### Endpoints

- `POST /servers` -- Register a server. Admin only.
- `GET /servers` -- List servers (members see only servers they have permissions for)
- `GET /servers/{id}` -- Get server details
- `PUT /servers/{id}` -- Update server. Admin only.
- `PUT /servers/{id}/password` -- Update RCON password (separate endpoint, write-only). Admin only.
- `DELETE /servers/{id}` -- Remove server. Admin only.
- `GET /servers/{id}/status` -- Connection test

### Server Model

| Field                    | Type              | Notes                                      |
|--------------------------|-------------------|--------------------------------------------|
| `id`                     | uuid              |                                            |
| `name`                   | string            | e.g., "PZ EU #1"                           |
| `description`            | string            |                                            |
| `hostname`               | string            |                                            |
| `port`                   | number            |                                            |
| `password`               | string            | Write-only, never returned in responses    |
| `gameType`               | string            | e.g., `project-zomboid`, `minecraft`       |
| `commandCatalogVersion`  | string (nullable) | Pin a specific catalog version or use latest |
| `tags`                   | string[]          | e.g., `["eu", "modded", "pve"]`            |
| `icon`                   | string (nullable) | URL or identifier for UI                   |
| `color`                  | string (nullable) | Hex color for UI                           |
| `connectionTimeout`      | number (nullable) | Milliseconds, service provides default     |
| `createdAt`              | datetime          |                                            |
| `updatedAt`              | datetime          |                                            |

### Server Status Response

| Field       | Type     | Notes           |
|-------------|----------|-----------------|
| `reachable` | boolean  |                 |
| `latencyMs` | number   |                 |
| `checkedAt` | datetime |                 |

## Roles & Permissions

### Role Endpoints (require `X-Tenant-Id`)

- `POST /roles` -- Create a role. Admin only.
- `GET /roles` -- List roles in the tenant
- `GET /roles/{id}` -- Get role details including command permissions
- `PUT /roles/{id}` -- Update role. Admin only.
- `DELETE /roles/{id}` -- Delete role. Admin only.

### Role Model

| Field         | Type              | Notes                        |
|---------------|-------------------|------------------------------|
| `id`          | uuid              |                              |
| `name`        | string            | e.g., "Moderator"           |
| `description` | string            |                              |
| `permissions` | PermissionRule[]  | Array of command permissions |
| `createdAt`   | datetime          |                              |
| `updatedAt`   | datetime          |                              |

### Permission Rule Model

| Field            | Type              | Notes                                      |
|------------------|-------------------|--------------------------------------------|
| `commandPattern` | string            | Supports wildcards: `*`, `players.*`, `kick` |
| `allow`          | boolean           |                                            |
| `gameType`       | string (nullable) | Scope to a specific game, or omit for all  |

Rules are evaluated in order, first match wins. Examples:
- Allow everything: `[{commandPattern: "*", allow: true}]`
- Moderator: `[{commandPattern: "players.*", allow: true}, {commandPattern: "server.status", allow: true}]`
- All except destructive: `[{commandPattern: "server.shutdown", allow: false}, {commandPattern: "*", allow: true}]`

### Per-Server Permission Overrides (require `X-Tenant-Id`)

- `GET /servers/{id}/permissions` -- List role assignments and user overrides
- `PUT /servers/{id}/permissions` -- Set role assignments and user overrides

### Server Permission Model

- `roleAssignments` -- array of `{userId, roleId}`
- `userOverrides` -- array of `{userId, permissions: PermissionRule[]}` (take precedence over role)

**Resolution order**: user override on this server > role on this server > deny by default.

## Command Execution

### Managed Execution (requires `X-Tenant-Id`)

`POST /servers/{id}/exec`

**Request body** (JSON):

| Field     | Type     | Notes                           |
|-----------|----------|---------------------------------|
| `command` | string   | Command name, e.g., `kick`      |
| `args`    | string[] | e.g., `["PlayerName", "reason"]` |

**Response** (JSON):

| Field             | Type              | Notes                                |
|-------------------|-------------------|--------------------------------------|
| `success`         | boolean           |                                      |
| `raw`             | string            | Raw RCON response                    |
| `command`         | string            | Command that was executed            |
| `variant`         | string (nullable) | Which signature matched (from catalog) |
| `server`          | object            | `{id, name}`                         |
| `executedAt`      | datetime          |                                      |
| `executionTimeMs` | number            |                                      |

### Quick Connect (no `X-Tenant-Id`)

`POST /rcon/exec`

Requires JWT auth. Hostname, port, password provided as query/header params. Plain text body for the command.

Simplified response: `success`, `raw`, `executedAt`, `executionTimeMs`.

Rate-limited per user. Returns `429 Too Many Requests` with `Retry-After` header when exceeded.

## Command History

All endpoints require `X-Tenant-Id`.

### Endpoints

- `GET /servers/{id}/history` -- List previously executed commands (paginated, filterable by user, command, date range)
- `POST /servers/{id}/history/{entryId}/replay` -- Re-execute a command from history. Same permission checks apply.

### History Entry Model

| Field             | Type     | Notes                |
|-------------------|----------|----------------------|
| `id`              | uuid     |                      |
| `command`         | string   |                      |
| `args`            | string[] |                      |
| `executedBy`      | uuid     | userId               |
| `executedAt`      | datetime |                      |
| `executionTimeMs` | number   |                      |
| `success`         | boolean  |                      |
| `raw`             | string   | The RCON response    |

## Favourites

Favourites are saved command templates, always scoped to a server and tenant. Sharing is controlled via explicit share entries.

All endpoints require `X-Tenant-Id`.

### Endpoints

- `GET /servers/{id}/favourites` -- List favourites visible to the current user on this server
- `POST /servers/{id}/favourites` -- Create a favourite
- `PUT /servers/{id}/favourites/{favId}` -- Update (own or admin)
- `DELETE /servers/{id}/favourites/{favId}` -- Delete (own or admin)

### Favourite Model

| Field       | Type         | Notes                              |
|-------------|--------------|------------------------------------|
| `id`        | uuid         |                                    |
| `name`      | string       | Optional custom label              |
| `command`   | string       |                                    |
| `args`      | string[]     | Pre-filled arguments               |
| `serverId`  | uuid         |                                    |
| `tenantId`  | uuid         |                                    |
| `createdBy` | uuid         | userId                             |
| `createdAt` | datetime     |                                    |
| `shares`    | ShareEntry[] | Defines who else can see/use this  |

### Share Entry Model

| Field      | Type              | Notes                                          |
|------------|-------------------|-------------------------------------------------|
| `type`     | enum              | `user`, `role`, `server`, `tenant`             |
| `targetId` | uuid (nullable)   | userId for `user`, roleId for `role`, null for `server`/`tenant` |

Examples:
- No shares: private, only the creator sees it
- `[{type: "tenant"}]`: everyone in the tenant sees it
- `[{type: "server"}]`: everyone with access to this server sees it
- `[{type: "user", targetId: "..."}]`: shared with a specific user
- `[{type: "role", targetId: "..."}]`: shared with everyone who has a specific role

Permission checks still apply at execution time -- if a user loses command access, the favourite stays but can't be executed.

## Audit Logging

### Endpoints (admin only, require `X-Tenant-Id`)

- `GET /audit` -- Tenant-wide audit log
- `GET /servers/{id}/audit` -- Per-server audit log

Both paginated, filterable by `userId`, `action`, `from`/`to` date range, and `serverId` (tenant-wide only).

### Audit Entry Model

| Field       | Type              | Notes                                      |
|-------------|-------------------|--------------------------------------------|
| `id`        | uuid              |                                            |
| `tenantId`  | uuid              |                                            |
| `serverId`  | uuid (nullable)   | Null for non-server actions                |
| `userId`    | uuid              |                                            |
| `action`    | enum              | See action types below                     |
| `detail`    | object            | Action-specific payload                    |
| `timestamp` | datetime          |                                            |

### Action Types

- `command.executed`
- `command.replayed`
- `server.created` / `server.updated` / `server.deleted`
- `role.created` / `role.updated` / `role.deleted`
- `member.invited` / `member.removed` / `member.updated`
- `permission.updated`
- `favourite.shared`

Audit logs are read-only. The service writes them automatically.

## WebSocket / Real-time

### Endpoint

`GET /ws/servers/{id}` -- Upgrade to WebSocket connection

Query params (because WebSocket handshake doesn't support custom headers in browsers):
- `token` -- JWT
- `tenant` -- tenant ID

### Client-to-Server Messages (JSON)

- `{type: "exec", command: "...", args: [...]}` -- Execute a command
- `{type: "ping"}` -- Keep-alive

### Server-to-Client Messages (JSON)

- `{type: "result", success: true, raw: "...", command: "...", executionTimeMs: ...}` -- Command result
- `{type: "error", code: "...", message: "..."}` -- Error (permission denied, server unreachable, etc.)
- `{type: "pong"}` -- Keep-alive response

Permission checks apply to every `exec` message. Commands executed via WebSocket are written to history and audit log.

## File Structure

```
src/
  api.yml                    - Root spec (info, servers, security, references)
  paths/
    index.yml.tpl            - Auto-generated path index
    me.yml                   - GET /me
    tenants.yml              - /tenants/*
    members.yml              - /members/*
    invites.yml              - /invites/*
    roles.yml                - /roles/*
    servers.yml              - /servers/*
    permissions.yml          - /servers/{id}/permissions/*
    exec.yml                 - /servers/{id}/exec
    history.yml              - /servers/{id}/history/*
    favourites.yml           - /servers/{id}/favourites/*
    audit.yml                - /audit/* and /servers/{id}/audit/*
    rcon.yml                 - /rcon/exec (quick connect)
    ws.yml                   - /ws/servers/{id}
  schemas/
    index.yml.tpl            - Auto-generated schema index
    Tenant.yml
    Member.yml
    Invite.yml
    Role.yml
    PermissionRule.yml
    Server.yml
    ServerStatus.yml
    CommandRequest.yml
    CommandResponse.yml
    HistoryEntry.yml
    Favourite.yml
    ShareEntry.yml
    AuditEntry.yml
    UserProfile.yml
    Error.yml
    PaginatedResponse.yml
build/
  openapi.yml               - Bundled output
  api_doc.html               - Static docs
```

The build script scans both `src/paths/` and `src/schemas/`, generates index files from templates, and bundles via `redocly bundle`.

## Command Catalog (Separate Repository)

The `arcon-commands` repository defines game-specific command catalogs. This repo (`arcon-api`) defines the meta-schema for how commands are structured. The catalog supports:

- **Full contracts**: Command name, description, category, typed parameters, expected response format, required privilege level, risk/side-effect classification
- **Command variants/overloads**: e.g., `teleport` with signatures for user-to-user, user-to-coordinates
- **RCON-invocability flag**: Distinguishes commands that can be called via RCON from in-game-only commands
- **Parameter constraints and validation rules**

The `gameType` field on registered servers links to the appropriate command catalog.
