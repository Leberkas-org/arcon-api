# ARCON API OpenAPI Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the ARCON OpenAPI 3.0 contract from a single-file spec into a multi-file, multi-tenant REST API covering authentication, tenants, members, invites, servers, roles, permissions, command execution, history, favourites, audit logging, and WebSocket endpoints.

**Architecture:** The contract is split into per-path-key files under `src/paths/` and per-model schema files under `src/schemas/`. Each path file contains a Path Item Object (the HTTP methods), and `api.yml` lists every path key with a `$ref` to its file. Schemas use the existing auto-generated index pattern via Jinja2 templates. `redocly bundle` merges everything into a single `build/openapi.yml`.

**Tech Stack:** OpenAPI 3.0.3, redocly CLI, envtpl (Jinja2), bash

**Note on `$ref` placement:** OpenAPI 3.0 allows `$ref` at the Path Item level (`/path: $ref: file.yml`) but NOT at the `paths` or `components.schemas` top level. The existing `components.schemas.$ref` works because redocly resolves it during bundling (non-standard but functional). Paths use the spec-compliant approach: individual `$ref` per path key.

---

## File Map

### Files to delete (old spec, replaced entirely)
- `src/schemas/SessionResponse.yml` -- replaced by new schema set
- `src/schemas/SimpleResponse.yml` -- replaced by new schema set

### Files to create

**Schemas (each is a standalone OpenAPI schema object):**
- `src/schemas/Error.yml`
- `src/schemas/PaginatedResponse.yml`
- `src/schemas/UserProfile.yml`
- `src/schemas/TenantSummary.yml`
- `src/schemas/Tenant.yml`
- `src/schemas/TenantCreate.yml`
- `src/schemas/TenantUpdate.yml`
- `src/schemas/Member.yml`
- `src/schemas/MemberUpdate.yml`
- `src/schemas/InviteCreate.yml`
- `src/schemas/Invite.yml`
- `src/schemas/InviteDetails.yml`
- `src/schemas/Server.yml`
- `src/schemas/ServerCreate.yml`
- `src/schemas/ServerUpdate.yml`
- `src/schemas/ServerPasswordUpdate.yml`
- `src/schemas/ServerStatus.yml`
- `src/schemas/Role.yml`
- `src/schemas/RoleCreate.yml`
- `src/schemas/RoleUpdate.yml`
- `src/schemas/PermissionRule.yml`
- `src/schemas/ServerPermissions.yml`
- `src/schemas/RoleAssignment.yml`
- `src/schemas/UserOverride.yml`
- `src/schemas/CommandRequest.yml`
- `src/schemas/CommandResponse.yml`
- `src/schemas/QuickConnectResponse.yml`
- `src/schemas/HistoryEntry.yml`
- `src/schemas/Favourite.yml`
- `src/schemas/FavouriteCreate.yml`
- `src/schemas/FavouriteUpdate.yml`
- `src/schemas/ShareEntry.yml`
- `src/schemas/AuditEntry.yml`
- `src/schemas/ServerRef.yml`

**Path files (one file per path key, each contains a Path Item Object):**
- `src/paths/me.yml` -- GET
- `src/paths/tenants.yml` -- GET, POST
- `src/paths/tenants@{id}.yml` -- GET, PUT, DELETE
- `src/paths/members.yml` -- GET
- `src/paths/members@{userId}.yml` -- PUT, DELETE
- `src/paths/members@invite.yml` -- POST
- `src/paths/members@invites.yml` -- GET
- `src/paths/members@invites@{code}.yml` -- DELETE
- `src/paths/invites@{code}.yml` -- GET
- `src/paths/invites@{code}@accept.yml` -- POST
- `src/paths/servers.yml` -- GET, POST
- `src/paths/servers@{id}.yml` -- GET, PUT, DELETE
- `src/paths/servers@{id}@password.yml` -- PUT
- `src/paths/servers@{id}@status.yml` -- GET
- `src/paths/servers@{id}@permissions.yml` -- GET, PUT
- `src/paths/servers@{id}@exec.yml` -- POST
- `src/paths/servers@{id}@history.yml` -- GET
- `src/paths/servers@{id}@history@{entryId}@replay.yml` -- POST
- `src/paths/servers@{id}@favourites.yml` -- GET, POST
- `src/paths/servers@{id}@favourites@{favId}.yml` -- PUT, DELETE
- `src/paths/audit.yml` -- GET
- `src/paths/servers@{id}@audit.yml` -- GET
- `src/paths/rcon@exec.yml` -- POST
- `src/paths/ws@servers@{id}.yml` -- GET

File naming follows redocly convention: `@` replaces `/` in path segments.

### Files to modify
- `src/api.yml` -- Complete rewrite: new tags, security scheme (Bearer JWT), `X-Tenant-Id` parameter, path `$ref` entries

---

## Task 1: Root API File & Security Scheme

**Files:**
- Modify: `src/api.yml` -- complete rewrite

- [ ] **Step 1: Rewrite `src/api.yml`**

Replace the entire content of `src/api.yml`. This defines the API metadata, tags, security scheme (Bearer JWT), reusable `X-Tenant-Id` header parameter, and `$ref` for every path key pointing to its file:

```yaml
openapi: 3.0.3
info:
  title: ARCON
  description: |-
    ARCON is a multi-tenant REST API for executing RCON commands on game servers.

    ## Modes of Operation

    - **Quick Connect**: Authenticated users provide connection details directly and send RCON commands. No server registration, no permission checks, rate-limited.
    - **Managed Mode**: Servers are registered within a tenant. Users are assigned roles with fine-grained per-command permissions. Full audit logging, command history, favourites, and real-time WebSocket support.

    ## Authentication

    All endpoints require a Bearer JWT token issued by an external Identity Provider.
    Tenant-scoped endpoints additionally require the `X-Tenant-Id` header.
  contact:
    email: arcon@leberkas.org
  version: "2.0"
servers:
  - url: https://arcon.leberkas.org/api/v2
  - url: api/v2
tags:
  - name: profile
    description: Current user profile and memberships
  - name: tenants
    description: Tenant management
  - name: members
    description: Tenant member management
  - name: invites
    description: Tenant invite system
  - name: servers
    description: Game server registration and management
  - name: roles
    description: Role and permission management
  - name: permissions
    description: Per-server permission assignments
  - name: execution
    description: RCON command execution on managed servers
  - name: history
    description: Command execution history
  - name: favourites
    description: Saved command templates
  - name: audit
    description: Audit logging
  - name: rcon
    description: Quick connect RCON execution
  - name: websocket
    description: Real-time WebSocket command channel
paths:
  /me:
    $ref: "./paths/me.yml"
  /tenants:
    $ref: "./paths/tenants.yml"
  /tenants/{id}:
    $ref: "./paths/tenants@{id}.yml"
  /members:
    $ref: "./paths/members.yml"
  /members/{userId}:
    $ref: "./paths/members@{userId}.yml"
  /members/invite:
    $ref: "./paths/members@invite.yml"
  /members/invites:
    $ref: "./paths/members@invites.yml"
  /members/invites/{code}:
    $ref: "./paths/members@invites@{code}.yml"
  /invites/{code}:
    $ref: "./paths/invites@{code}.yml"
  /invites/{code}/accept:
    $ref: "./paths/invites@{code}@accept.yml"
  /servers:
    $ref: "./paths/servers.yml"
  /servers/{id}:
    $ref: "./paths/servers@{id}.yml"
  /servers/{id}/password:
    $ref: "./paths/servers@{id}@password.yml"
  /servers/{id}/status:
    $ref: "./paths/servers@{id}@status.yml"
  /servers/{id}/permissions:
    $ref: "./paths/servers@{id}@permissions.yml"
  /servers/{id}/exec:
    $ref: "./paths/servers@{id}@exec.yml"
  /servers/{id}/history:
    $ref: "./paths/servers@{id}@history.yml"
  /servers/{id}/history/{entryId}/replay:
    $ref: "./paths/servers@{id}@history@{entryId}@replay.yml"
  /servers/{id}/favourites:
    $ref: "./paths/servers@{id}@favourites.yml"
  /servers/{id}/favourites/{favId}:
    $ref: "./paths/servers@{id}@favourites@{favId}.yml"
  /audit:
    $ref: "./paths/audit.yml"
  /servers/{id}/audit:
    $ref: "./paths/servers@{id}@audit.yml"
  /rcon/exec:
    $ref: "./paths/rcon@exec.yml"
  /ws/servers/{id}:
    $ref: "./paths/ws@servers@{id}.yml"
components:
  schemas:
    $ref: "./schemas/index.yml"
  securitySchemes:
    bearer_auth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token issued by an external Identity Provider (Keycloak, Auth0, etc.)
  parameters:
    TenantId:
      name: X-Tenant-Id
      in: header
      description: ID of the tenant to operate within. Required for all tenant-scoped endpoints.
      required: true
      schema:
        type: string
        format: uuid
security:
  - bearer_auth: []
```

- [ ] **Step 2: Commit**

```bash
git add src/api.yml
git commit -m "feat: rewrite api.yml with multi-tenant structure and Bearer JWT auth"
```

---

## Task 2: Foundation Schemas -- Error, Pagination, Common Types

**Files:**
- Create: `src/schemas/Error.yml`
- Create: `src/schemas/PaginatedResponse.yml`
- Create: `src/schemas/ServerRef.yml`
- Create: `src/schemas/ShareEntry.yml`
- Create: `src/schemas/PermissionRule.yml`
- Delete: `src/schemas/SessionResponse.yml`
- Delete: `src/schemas/SimpleResponse.yml`

- [ ] **Step 1: Create `src/schemas/Error.yml`**

```yaml
type: object
required:
  - code
  - message
properties:
  code:
    type: string
    description: Machine-readable error code
    example: "PERMISSION_DENIED"
  message:
    type: string
    description: Human-readable error message
    example: "You do not have permission to execute this command"
```

- [ ] **Step 2: Create `src/schemas/PaginatedResponse.yml`**

```yaml
type: object
required:
  - total
  - page
  - pageSize
properties:
  total:
    type: integer
    description: Total number of items across all pages
    example: 42
  page:
    type: integer
    description: Current page number (1-based)
    example: 1
  pageSize:
    type: integer
    description: Number of items per page
    example: 20
```

- [ ] **Step 3: Create `src/schemas/ServerRef.yml`**

```yaml
type: object
required:
  - id
  - name
properties:
  id:
    type: string
    format: uuid
  name:
    type: string
    example: "PZ EU #1"
```

- [ ] **Step 4: Create `src/schemas/ShareEntry.yml`**

```yaml
type: object
required:
  - type
properties:
  type:
    type: string
    enum:
      - user
      - role
      - server
      - tenant
    description: |
      Scope of the share:
      - `user`: shared with a specific user (targetId = userId)
      - `role`: shared with users who have a specific role (targetId = roleId)
      - `server`: shared with all users who have access to this server
      - `tenant`: shared with all tenant members
  targetId:
    type: string
    format: uuid
    nullable: true
    description: userId for type=user, roleId for type=role, null for server/tenant
```

- [ ] **Step 5: Create `src/schemas/PermissionRule.yml`**

```yaml
type: object
required:
  - commandPattern
  - allow
properties:
  commandPattern:
    type: string
    description: |
      Command name or wildcard pattern. Supports:
      - Exact match: `kick`
      - Category wildcard: `players.*`
      - Full wildcard: `*`
    example: "players.*"
  allow:
    type: boolean
    description: Whether commands matching this pattern are allowed or denied
    example: true
  gameType:
    type: string
    nullable: true
    description: Scope this rule to a specific game type. Omit to apply to all games.
    example: "project-zomboid"
```

- [ ] **Step 6: Delete old schemas**

```bash
git rm src/schemas/SessionResponse.yml src/schemas/SimpleResponse.yml
```

- [ ] **Step 7: Commit**

```bash
git add src/schemas/Error.yml src/schemas/PaginatedResponse.yml src/schemas/ServerRef.yml src/schemas/ShareEntry.yml src/schemas/PermissionRule.yml
git commit -m "feat: add foundation schemas, remove old session/simple response"
```

---

## Task 3: User Profile & Tenant Schemas

**Files:**
- Create: `src/schemas/UserProfile.yml`
- Create: `src/schemas/TenantSummary.yml`
- Create: `src/schemas/Tenant.yml`
- Create: `src/schemas/TenantCreate.yml`
- Create: `src/schemas/TenantUpdate.yml`

- [ ] **Step 1: Create `src/schemas/TenantSummary.yml`**

```yaml
type: object
required:
  - id
  - name
  - role
properties:
  id:
    type: string
    format: uuid
  name:
    type: string
    example: "Leberkas Gaming"
  role:
    type: string
    enum:
      - owner
      - admin
      - member
    description: The current user's role in this tenant
```

- [ ] **Step 2: Create `src/schemas/UserProfile.yml`**

```yaml
type: object
required:
  - id
  - email
  - tenants
properties:
  id:
    type: string
    format: uuid
    description: User ID (from JWT sub claim)
  email:
    type: string
    format: email
  tenants:
    type: array
    items:
      $ref: "index.yml#/TenantSummary"
    description: Tenants the user is a member of, with their role in each
```

- [ ] **Step 3: Create `src/schemas/Tenant.yml`**

```yaml
type: object
required:
  - id
  - name
  - ownerId
  - createdAt
  - updatedAt
properties:
  id:
    type: string
    format: uuid
  name:
    type: string
    example: "Leberkas Gaming"
  description:
    type: string
    example: "Our gaming community servers"
  ownerId:
    type: string
    format: uuid
    description: User ID of the tenant owner
  createdAt:
    type: string
    format: date-time
  updatedAt:
    type: string
    format: date-time
```

- [ ] **Step 4: Create `src/schemas/TenantCreate.yml`**

```yaml
type: object
required:
  - name
properties:
  name:
    type: string
    example: "Leberkas Gaming"
  description:
    type: string
    example: "Our gaming community servers"
```

- [ ] **Step 5: Create `src/schemas/TenantUpdate.yml`**

```yaml
type: object
properties:
  name:
    type: string
    example: "Leberkas Gaming"
  description:
    type: string
    example: "Our gaming community servers"
  ownerId:
    type: string
    format: uuid
    description: Transfer ownership to another user (current owner only)
```

- [ ] **Step 6: Commit**

```bash
git add src/schemas/UserProfile.yml src/schemas/TenantSummary.yml src/schemas/Tenant.yml src/schemas/TenantCreate.yml src/schemas/TenantUpdate.yml
git commit -m "feat: add user profile and tenant schemas"
```

---

## Task 4: Member & Invite Schemas

**Files:**
- Create: `src/schemas/Member.yml`
- Create: `src/schemas/MemberUpdate.yml`
- Create: `src/schemas/Invite.yml`
- Create: `src/schemas/InviteCreate.yml`
- Create: `src/schemas/InviteDetails.yml`

- [ ] **Step 1: Create `src/schemas/Member.yml`**

```yaml
type: object
required:
  - userId
  - email
  - role
  - joinedAt
properties:
  userId:
    type: string
    format: uuid
  email:
    type: string
    format: email
  role:
    type: string
    enum:
      - owner
      - admin
      - member
  joinedAt:
    type: string
    format: date-time
```

- [ ] **Step 2: Create `src/schemas/MemberUpdate.yml`**

```yaml
type: object
required:
  - role
properties:
  role:
    type: string
    enum:
      - admin
      - member
    description: New tenant role for the member. Cannot set to owner (use tenant ownership transfer instead).
```

- [ ] **Step 3: Create `src/schemas/InviteCreate.yml`**

```yaml
type: object
required:
  - role
properties:
  email:
    type: string
    format: email
    description: If set, only this email can accept the invite. Omit for an open invite link.
  role:
    type: string
    enum:
      - admin
      - member
    description: Tenant role the invitee will receive upon accepting
```

- [ ] **Step 4: Create `src/schemas/Invite.yml`**

```yaml
type: object
required:
  - code
  - tenantId
  - role
  - invitedBy
  - createdAt
  - expiresAt
properties:
  code:
    type: string
    description: Unique invite code
    example: "abc123def456"
  tenantId:
    type: string
    format: uuid
  email:
    type: string
    format: email
    nullable: true
    description: If set, only this email can accept
  role:
    type: string
    enum:
      - admin
      - member
  invitedBy:
    type: string
    format: uuid
    description: User ID of the person who created the invite
  createdAt:
    type: string
    format: date-time
  expiresAt:
    type: string
    format: date-time
```

- [ ] **Step 5: Create `src/schemas/InviteDetails.yml`**

```yaml
type: object
required:
  - tenantName
  - invitedByEmail
  - role
  - expiresAt
properties:
  tenantName:
    type: string
    example: "Leberkas Gaming"
    description: Name of the tenant the invite is for
  invitedByEmail:
    type: string
    format: email
    description: Email of the person who created the invite
  role:
    type: string
    enum:
      - admin
      - member
  expiresAt:
    type: string
    format: date-time
```

- [ ] **Step 6: Commit**

```bash
git add src/schemas/Member.yml src/schemas/MemberUpdate.yml src/schemas/Invite.yml src/schemas/InviteCreate.yml src/schemas/InviteDetails.yml
git commit -m "feat: add member and invite schemas"
```

---

## Task 5: Server Schemas

**Files:**
- Create: `src/schemas/Server.yml`
- Create: `src/schemas/ServerCreate.yml`
- Create: `src/schemas/ServerUpdate.yml`
- Create: `src/schemas/ServerPasswordUpdate.yml`
- Create: `src/schemas/ServerStatus.yml`

- [ ] **Step 1: Create `src/schemas/Server.yml`**

Password is excluded (write-only, never returned):

```yaml
type: object
required:
  - id
  - name
  - hostname
  - port
  - gameType
  - createdAt
  - updatedAt
properties:
  id:
    type: string
    format: uuid
  name:
    type: string
    example: "PZ EU #1"
  description:
    type: string
  hostname:
    type: string
    example: "rcon.example.org"
  port:
    type: integer
    example: 27020
  gameType:
    type: string
    description: Game identifier, links to command catalog
    example: "project-zomboid"
  commandCatalogVersion:
    type: string
    nullable: true
    description: Pin a specific command catalog version, or null for latest
  tags:
    type: array
    items:
      type: string
    example: ["eu", "modded", "pve"]
  icon:
    type: string
    nullable: true
    description: URL or identifier for UI display
  color:
    type: string
    nullable: true
    description: Hex color code for UI display
    example: "#4CAF50"
  connectionTimeout:
    type: integer
    nullable: true
    description: Connection timeout in milliseconds. Service provides default if omitted.
  createdAt:
    type: string
    format: date-time
  updatedAt:
    type: string
    format: date-time
```

- [ ] **Step 2: Create `src/schemas/ServerCreate.yml`**

```yaml
type: object
required:
  - name
  - hostname
  - port
  - password
  - gameType
properties:
  name:
    type: string
    example: "PZ EU #1"
  description:
    type: string
  hostname:
    type: string
    example: "rcon.example.org"
  port:
    type: integer
    example: 27020
  password:
    type: string
    format: password
    description: RCON password. Write-only, will never be returned in responses.
  gameType:
    type: string
    example: "project-zomboid"
  commandCatalogVersion:
    type: string
    description: Pin a specific command catalog version
  tags:
    type: array
    items:
      type: string
    example: ["eu", "modded", "pve"]
  icon:
    type: string
  color:
    type: string
    example: "#4CAF50"
  connectionTimeout:
    type: integer
    description: Connection timeout in milliseconds
```

- [ ] **Step 3: Create `src/schemas/ServerUpdate.yml`**

```yaml
type: object
properties:
  name:
    type: string
    example: "PZ EU #1"
  description:
    type: string
  hostname:
    type: string
    example: "rcon.example.org"
  port:
    type: integer
    example: 27020
  gameType:
    type: string
    example: "project-zomboid"
  commandCatalogVersion:
    type: string
    nullable: true
  tags:
    type: array
    items:
      type: string
  icon:
    type: string
    nullable: true
  color:
    type: string
    nullable: true
  connectionTimeout:
    type: integer
    nullable: true
```

- [ ] **Step 4: Create `src/schemas/ServerPasswordUpdate.yml`**

```yaml
type: object
required:
  - password
properties:
  password:
    type: string
    format: password
    description: New RCON password for the server
```

- [ ] **Step 5: Create `src/schemas/ServerStatus.yml`**

```yaml
type: object
required:
  - reachable
  - checkedAt
properties:
  reachable:
    type: boolean
  latencyMs:
    type: number
    description: Round-trip latency in milliseconds. Only present when reachable is true.
    example: 23.5
  checkedAt:
    type: string
    format: date-time
```

- [ ] **Step 6: Commit**

```bash
git add src/schemas/Server.yml src/schemas/ServerCreate.yml src/schemas/ServerUpdate.yml src/schemas/ServerPasswordUpdate.yml src/schemas/ServerStatus.yml
git commit -m "feat: add server schemas"
```

---

## Task 6: Role & Permission Schemas

**Files:**
- Create: `src/schemas/Role.yml`
- Create: `src/schemas/RoleCreate.yml`
- Create: `src/schemas/RoleUpdate.yml`
- Create: `src/schemas/ServerPermissions.yml`
- Create: `src/schemas/RoleAssignment.yml`
- Create: `src/schemas/UserOverride.yml`

- [ ] **Step 1: Create `src/schemas/Role.yml`**

```yaml
type: object
required:
  - id
  - name
  - permissions
  - createdAt
  - updatedAt
properties:
  id:
    type: string
    format: uuid
  name:
    type: string
    example: "Moderator"
  description:
    type: string
    example: "Can manage players but not server settings"
  permissions:
    type: array
    items:
      $ref: "index.yml#/PermissionRule"
    description: Ordered list of permission rules. First match wins.
  createdAt:
    type: string
    format: date-time
  updatedAt:
    type: string
    format: date-time
```

- [ ] **Step 2: Create `src/schemas/RoleCreate.yml`**

```yaml
type: object
required:
  - name
  - permissions
properties:
  name:
    type: string
    example: "Moderator"
  description:
    type: string
  permissions:
    type: array
    items:
      $ref: "index.yml#/PermissionRule"
    description: Ordered list of permission rules. First match wins.
```

- [ ] **Step 3: Create `src/schemas/RoleUpdate.yml`**

```yaml
type: object
properties:
  name:
    type: string
    example: "Moderator"
  description:
    type: string
  permissions:
    type: array
    items:
      $ref: "index.yml#/PermissionRule"
    description: Ordered list of permission rules. First match wins.
```

- [ ] **Step 4: Create `src/schemas/RoleAssignment.yml`**

```yaml
type: object
required:
  - userId
  - roleId
properties:
  userId:
    type: string
    format: uuid
  roleId:
    type: string
    format: uuid
```

- [ ] **Step 5: Create `src/schemas/UserOverride.yml`**

```yaml
type: object
required:
  - userId
  - permissions
properties:
  userId:
    type: string
    format: uuid
  permissions:
    type: array
    items:
      $ref: "index.yml#/PermissionRule"
    description: Override permission rules for this user. Takes precedence over role permissions.
```

- [ ] **Step 6: Create `src/schemas/ServerPermissions.yml`**

```yaml
type: object
required:
  - roleAssignments
  - userOverrides
properties:
  roleAssignments:
    type: array
    items:
      $ref: "index.yml#/RoleAssignment"
    description: Which users are assigned which roles on this server
  userOverrides:
    type: array
    items:
      $ref: "index.yml#/UserOverride"
    description: Per-user permission overrides that take precedence over role permissions
```

- [ ] **Step 7: Commit**

```bash
git add src/schemas/Role.yml src/schemas/RoleCreate.yml src/schemas/RoleUpdate.yml src/schemas/ServerPermissions.yml src/schemas/RoleAssignment.yml src/schemas/UserOverride.yml
git commit -m "feat: add role and permission schemas"
```

---

## Task 7: Command Execution, History, Favourite & Audit Schemas

**Files:**
- Create: `src/schemas/CommandRequest.yml`
- Create: `src/schemas/CommandResponse.yml`
- Create: `src/schemas/QuickConnectResponse.yml`
- Create: `src/schemas/HistoryEntry.yml`
- Create: `src/schemas/Favourite.yml`
- Create: `src/schemas/FavouriteCreate.yml`
- Create: `src/schemas/FavouriteUpdate.yml`
- Create: `src/schemas/AuditEntry.yml`

- [ ] **Step 1: Create `src/schemas/CommandRequest.yml`**

```yaml
type: object
required:
  - command
properties:
  command:
    type: string
    description: Command name
    example: "kick"
  args:
    type: array
    items:
      type: string
    description: Command arguments
    example: ["PlayerName", "AFK too long"]
```

- [ ] **Step 2: Create `src/schemas/CommandResponse.yml`**

```yaml
type: object
required:
  - success
  - raw
  - command
  - server
  - executedAt
  - executionTimeMs
properties:
  success:
    type: boolean
  raw:
    type: string
    description: Raw RCON response string
  command:
    type: string
    description: The command that was executed
    example: "kick"
  variant:
    type: string
    nullable: true
    description: Which command signature matched, if the command catalog defines overloads
  server:
    $ref: "index.yml#/ServerRef"
  executedAt:
    type: string
    format: date-time
  executionTimeMs:
    type: number
    description: Execution time in milliseconds
    example: 45.2
```

- [ ] **Step 3: Create `src/schemas/QuickConnectResponse.yml`**

```yaml
type: object
required:
  - success
  - raw
  - executedAt
  - executionTimeMs
properties:
  success:
    type: boolean
  raw:
    type: string
    description: Raw RCON response string
  executedAt:
    type: string
    format: date-time
  executionTimeMs:
    type: number
    description: Execution time in milliseconds
    example: 45.2
```

- [ ] **Step 4: Create `src/schemas/HistoryEntry.yml`**

```yaml
type: object
required:
  - id
  - command
  - executedBy
  - executedAt
  - executionTimeMs
  - success
  - raw
properties:
  id:
    type: string
    format: uuid
  command:
    type: string
    example: "kick"
  args:
    type: array
    items:
      type: string
    example: ["PlayerName", "AFK too long"]
  executedBy:
    type: string
    format: uuid
    description: User ID of the person who executed the command
  executedAt:
    type: string
    format: date-time
  executionTimeMs:
    type: number
    example: 45.2
  success:
    type: boolean
  raw:
    type: string
    description: The RCON response
```

- [ ] **Step 5: Create `src/schemas/Favourite.yml`**

```yaml
type: object
required:
  - id
  - command
  - serverId
  - tenantId
  - createdBy
  - createdAt
  - shares
properties:
  id:
    type: string
    format: uuid
  name:
    type: string
    description: Optional custom label
    example: "Restart warning sequence"
  command:
    type: string
    example: "servermsg"
  args:
    type: array
    items:
      type: string
    example: ["Server restarting in 5 minutes"]
  serverId:
    type: string
    format: uuid
  tenantId:
    type: string
    format: uuid
  createdBy:
    type: string
    format: uuid
  createdAt:
    type: string
    format: date-time
  shares:
    type: array
    items:
      $ref: "index.yml#/ShareEntry"
    description: Defines who can see and use this favourite. Empty array means private.
```

- [ ] **Step 6: Create `src/schemas/FavouriteCreate.yml`**

```yaml
type: object
required:
  - command
properties:
  name:
    type: string
    example: "Restart warning sequence"
  command:
    type: string
    example: "servermsg"
  args:
    type: array
    items:
      type: string
    example: ["Server restarting in 5 minutes"]
  shares:
    type: array
    items:
      $ref: "index.yml#/ShareEntry"
    description: Share entries. Omit for a private favourite.
```

- [ ] **Step 7: Create `src/schemas/FavouriteUpdate.yml`**

```yaml
type: object
properties:
  name:
    type: string
  command:
    type: string
  args:
    type: array
    items:
      type: string
  shares:
    type: array
    items:
      $ref: "index.yml#/ShareEntry"
```

- [ ] **Step 8: Create `src/schemas/AuditEntry.yml`**

```yaml
type: object
required:
  - id
  - tenantId
  - userId
  - action
  - detail
  - timestamp
properties:
  id:
    type: string
    format: uuid
  tenantId:
    type: string
    format: uuid
  serverId:
    type: string
    format: uuid
    nullable: true
    description: Null for non-server actions (e.g., role changes, member management)
  userId:
    type: string
    format: uuid
    description: User who performed the action
  action:
    type: string
    enum:
      - command.executed
      - command.replayed
      - server.created
      - server.updated
      - server.deleted
      - role.created
      - role.updated
      - role.deleted
      - member.invited
      - member.removed
      - member.updated
      - permission.updated
      - favourite.shared
    description: Type of audited action
  detail:
    type: object
    description: Action-specific payload (e.g., which command was run, what permission changed)
  timestamp:
    type: string
    format: date-time
```

- [ ] **Step 9: Commit**

```bash
git add src/schemas/CommandRequest.yml src/schemas/CommandResponse.yml src/schemas/QuickConnectResponse.yml src/schemas/HistoryEntry.yml src/schemas/Favourite.yml src/schemas/FavouriteCreate.yml src/schemas/FavouriteUpdate.yml src/schemas/AuditEntry.yml
git commit -m "feat: add execution, history, favourite, and audit schemas"
```

---

## Task 8: Path Files -- Profile, Tenants, Members, Invites

Each path file is a Path Item Object (HTTP methods only, no path key wrapper).

**Files:**
- Create: `src/paths/me.yml`
- Create: `src/paths/tenants.yml`
- Create: `src/paths/tenants@{id}.yml`
- Create: `src/paths/members.yml`
- Create: `src/paths/members@{userId}.yml`
- Create: `src/paths/members@invite.yml`
- Create: `src/paths/members@invites.yml`
- Create: `src/paths/members@invites@{code}.yml`
- Create: `src/paths/invites@{code}.yml`
- Create: `src/paths/invites@{code}@accept.yml`

- [ ] **Step 1: Create `src/paths/me.yml`**

```yaml
get:
  tags:
    - profile
  summary: Get current user profile
  description: Returns the authenticated user's profile, including all tenant memberships and roles.
  operationId: getProfile
  security:
    - bearer_auth: []
  responses:
    '200':
      description: User profile
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/UserProfile"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 2: Create `src/paths/tenants.yml`**

```yaml
get:
  tags:
    - tenants
  summary: List tenants
  description: List all tenants the current user is a member of.
  operationId: listTenants
  security:
    - bearer_auth: []
  responses:
    '200':
      description: List of tenants
      content:
        application/json:
          schema:
            type: array
            items:
              $ref: "../schemas/index.yml#/Tenant"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
post:
  tags:
    - tenants
  summary: Create a tenant
  description: Create a new tenant. The authenticated user becomes the owner.
  operationId: createTenant
  security:
    - bearer_auth: []
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/TenantCreate"
  responses:
    '201':
      description: Tenant created
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Tenant"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 3: Create `src/paths/tenants@{id}.yml`**

```yaml
get:
  tags:
    - tenants
  summary: Get tenant details
  operationId: getTenant
  security:
    - bearer_auth: []
  parameters:
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '200':
      description: Tenant details
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Tenant"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Not a member of this tenant
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Tenant not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
put:
  tags:
    - tenants
  summary: Update tenant
  description: Update tenant details. Owner or admin only. Only the owner can transfer ownership via ownerId.
  operationId: updateTenant
  security:
    - bearer_auth: []
  parameters:
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/TenantUpdate"
  responses:
    '200':
      description: Tenant updated
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Tenant"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Tenant not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
delete:
  tags:
    - tenants
  summary: Delete tenant
  description: Delete a tenant and all associated data. Owner only.
  operationId: deleteTenant
  security:
    - bearer_auth: []
  parameters:
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '204':
      description: Tenant deleted
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Only the owner can delete a tenant
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Tenant not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 4: Create `src/paths/members.yml`**

```yaml
get:
  tags:
    - members
  summary: List tenant members
  operationId: listMembers
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
  responses:
    '200':
      description: List of members
      content:
        application/json:
          schema:
            type: array
            items:
              $ref: "../schemas/index.yml#/Member"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Not a member of this tenant
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 5: Create `src/paths/members@{userId}.yml`**

```yaml
put:
  tags:
    - members
  summary: Update member role
  description: Update a member's tenant role. Admin or owner only.
  operationId: updateMember
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: userId
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/MemberUpdate"
  responses:
    '200':
      description: Member updated
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Member"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Member not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
delete:
  tags:
    - members
  summary: Remove member
  description: Remove a member from the tenant. Admin or owner only.
  operationId: removeMember
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: userId
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '204':
      description: Member removed
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Member not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 6: Create `src/paths/members@invite.yml`**

```yaml
post:
  tags:
    - members
  summary: Create invite
  description: Create an invite link for the tenant. Admin or owner only.
  operationId: createInvite
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/InviteCreate"
  responses:
    '201':
      description: Invite created
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Invite"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 7: Create `src/paths/members@invites.yml`**

```yaml
get:
  tags:
    - members
  summary: List pending invites
  description: List all pending invites for the tenant. Admin or owner only.
  operationId: listInvites
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
  responses:
    '200':
      description: List of pending invites
      content:
        application/json:
          schema:
            type: array
            items:
              $ref: "../schemas/index.yml#/Invite"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 8: Create `src/paths/members@invites@{code}.yml`**

```yaml
delete:
  tags:
    - members
  summary: Revoke invite
  description: Revoke a pending invite. Admin or owner only.
  operationId: revokeInvite
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: code
      in: path
      required: true
      schema:
        type: string
  responses:
    '204':
      description: Invite revoked
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Invite not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 9: Create `src/paths/invites@{code}.yml`**

```yaml
get:
  tags:
    - invites
  summary: Get invite details
  description: View invite details before accepting. No authentication required. Returns 404 if the code is invalid or expired.
  operationId: getInviteDetails
  security: []
  parameters:
    - name: code
      in: path
      required: true
      schema:
        type: string
  responses:
    '200':
      description: Invite details
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/InviteDetails"
    '404':
      description: Invite not found or expired
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 10: Create `src/paths/invites@{code}@accept.yml`**

```yaml
post:
  tags:
    - invites
  summary: Accept invite
  description: Accept an invite and join the tenant. Requires authentication but no X-Tenant-Id header.
  operationId: acceptInvite
  security:
    - bearer_auth: []
  parameters:
    - name: code
      in: path
      required: true
      schema:
        type: string
  responses:
    '200':
      description: Invite accepted, user is now a member
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Member"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Invite not found or expired
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '409':
      description: User is already a member of this tenant
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 11: Commit**

```bash
git add src/paths/me.yml src/paths/tenants.yml "src/paths/tenants@{id}.yml" src/paths/members.yml "src/paths/members@{userId}.yml" "src/paths/members@invite.yml" "src/paths/members@invites.yml" "src/paths/members@invites@{code}.yml" "src/paths/invites@{code}.yml" "src/paths/invites@{code}@accept.yml"
git commit -m "feat: add profile, tenant, member, and invite path files"
```

---

## Task 9: Path Files -- Servers, Roles, Permissions

**Files:**
- Create: `src/paths/servers.yml`
- Create: `src/paths/servers@{id}.yml`
- Create: `src/paths/servers@{id}@password.yml`
- Create: `src/paths/servers@{id}@status.yml`
- Create: `src/paths/roles.yml`
- Create: `src/paths/roles@{id}.yml`
- Create: `src/paths/servers@{id}@permissions.yml`

- [ ] **Step 1: Create `src/paths/servers.yml`**

```yaml
get:
  tags:
    - servers
  summary: List servers
  description: List servers in the tenant. Members see only servers they have permissions for.
  operationId: listServers
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
  responses:
    '200':
      description: List of servers
      content:
        application/json:
          schema:
            type: array
            items:
              $ref: "../schemas/index.yml#/Server"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Not a member of this tenant
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
post:
  tags:
    - servers
  summary: Register a server
  description: Register a new game server in the tenant. Admin or owner only.
  operationId: createServer
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/ServerCreate"
  responses:
    '201':
      description: Server registered
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Server"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 2: Create `src/paths/servers@{id}.yml`**

```yaml
get:
  tags:
    - servers
  summary: Get server details
  operationId: getServer
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '200':
      description: Server details
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Server"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
put:
  tags:
    - servers
  summary: Update server
  description: Update server details. Admin or owner only. Does not update the RCON password (use PUT /servers/{id}/password).
  operationId: updateServer
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/ServerUpdate"
  responses:
    '200':
      description: Server updated
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Server"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
delete:
  tags:
    - servers
  summary: Delete server
  description: Remove a server from the tenant. Admin or owner only.
  operationId: deleteServer
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '204':
      description: Server deleted
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 3: Create `src/paths/servers@{id}@password.yml`**

```yaml
put:
  tags:
    - servers
  summary: Update server RCON password
  description: Update the RCON password for a server. Admin or owner only. The password is write-only and will never be returned in responses.
  operationId: updateServerPassword
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/ServerPasswordUpdate"
  responses:
    '204':
      description: Password updated
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 4: Create `src/paths/servers@{id}@status.yml`**

```yaml
get:
  tags:
    - servers
  summary: Check server status
  description: Test if ARCON can reach the RCON server.
  operationId: getServerStatus
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '200':
      description: Server status
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/ServerStatus"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 5: Create `src/paths/roles.yml`**

```yaml
get:
  tags:
    - roles
  summary: List roles
  description: List all roles in the tenant.
  operationId: listRoles
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
  responses:
    '200':
      description: List of roles
      content:
        application/json:
          schema:
            type: array
            items:
              $ref: "../schemas/index.yml#/Role"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Not a member of this tenant
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
post:
  tags:
    - roles
  summary: Create a role
  description: Create a new role with command permissions. Admin or owner only.
  operationId: createRole
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/RoleCreate"
  responses:
    '201':
      description: Role created
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Role"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 6: Create `src/paths/roles@{id}.yml`**

```yaml
get:
  tags:
    - roles
  summary: Get role details
  description: Get a role including its command permission rules.
  operationId: getRole
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '200':
      description: Role details
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Role"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Role not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
put:
  tags:
    - roles
  summary: Update role
  description: Update role name, description, or permissions. Admin or owner only.
  operationId: updateRole
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/RoleUpdate"
  responses:
    '200':
      description: Role updated
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Role"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Role not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
delete:
  tags:
    - roles
  summary: Delete role
  description: Delete a role. Admin or owner only. Users assigned this role on servers will lose those permissions.
  operationId: deleteRole
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '204':
      description: Role deleted
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Role not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 7: Create `src/paths/servers@{id}@permissions.yml`**

```yaml
get:
  tags:
    - permissions
  summary: Get server permissions
  description: Get role assignments and user overrides for a server. Admin or owner only.
  operationId: getServerPermissions
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '200':
      description: Server permissions
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/ServerPermissions"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
put:
  tags:
    - permissions
  summary: Set server permissions
  description: |
    Set role assignments and user overrides for a server. Admin or owner only.
    This replaces the entire permission configuration for the server.

    **Resolution order**: user override > role permissions > deny by default.
  operationId: setServerPermissions
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/ServerPermissions"
  responses:
    '200':
      description: Permissions updated
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/ServerPermissions"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 8: Commit**

```bash
git add src/paths/servers.yml "src/paths/servers@{id}.yml" "src/paths/servers@{id}@password.yml" "src/paths/servers@{id}@status.yml" src/paths/roles.yml "src/paths/roles@{id}.yml" "src/paths/servers@{id}@permissions.yml"
git commit -m "feat: add server, role, and permission path files"
```

---

## Task 10: Path Files -- Execution, History, Favourites, Audit, RCON, WebSocket

**Files:**
- Create: `src/paths/servers@{id}@exec.yml`
- Create: `src/paths/servers@{id}@history.yml`
- Create: `src/paths/servers@{id}@history@{entryId}@replay.yml`
- Create: `src/paths/servers@{id}@favourites.yml`
- Create: `src/paths/servers@{id}@favourites@{favId}.yml`
- Create: `src/paths/audit.yml`
- Create: `src/paths/servers@{id}@audit.yml`
- Create: `src/paths/rcon@exec.yml`
- Create: `src/paths/ws@servers@{id}.yml`

- [ ] **Step 1: Create `src/paths/servers@{id}@exec.yml`**

```yaml
post:
  tags:
    - execution
  summary: Execute a command
  description: |
    Execute an RCON command on a managed server. Requires command permission.
    The command and args are validated against the server's command catalog if available.
  operationId: executeCommand
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/CommandRequest"
  responses:
    '200':
      description: Command executed
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/CommandResponse"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: No permission to execute this command on this server
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '502':
      description: Failed to connect to the RCON server
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 2: Create `src/paths/servers@{id}@history.yml`**

```yaml
get:
  tags:
    - history
  summary: Get command history
  description: List previously executed commands on this server. Paginated and filterable.
  operationId: getCommandHistory
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
    - name: page
      in: query
      schema:
        type: integer
        default: 1
    - name: pageSize
      in: query
      schema:
        type: integer
        default: 20
    - name: userId
      in: query
      description: Filter by user who executed the command
      schema:
        type: string
        format: uuid
    - name: command
      in: query
      description: Filter by command name
      schema:
        type: string
    - name: from
      in: query
      description: Filter from this date (inclusive)
      schema:
        type: string
        format: date-time
    - name: to
      in: query
      description: Filter to this date (inclusive)
      schema:
        type: string
        format: date-time
  responses:
    '200':
      description: Command history
      content:
        application/json:
          schema:
            allOf:
              - $ref: "../schemas/index.yml#/PaginatedResponse"
              - type: object
                required:
                  - items
                properties:
                  items:
                    type: array
                    items:
                      $ref: "../schemas/index.yml#/HistoryEntry"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 3: Create `src/paths/servers@{id}@history@{entryId}@replay.yml`**

```yaml
post:
  tags:
    - history
  summary: Replay a command
  description: Re-execute a command from history. The same permission checks apply as for a fresh execution.
  operationId: replayCommand
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
    - name: entryId
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '200':
      description: Command replayed
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/CommandResponse"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: No permission to execute this command
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server or history entry not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '502':
      description: Failed to connect to the RCON server
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 4: Create `src/paths/servers@{id}@favourites.yml`**

```yaml
get:
  tags:
    - favourites
  summary: List favourites
  description: List favourites visible to the current user on this server (personal + shared via roles/server/tenant).
  operationId: listFavourites
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '200':
      description: List of favourites
      content:
        application/json:
          schema:
            type: array
            items:
              $ref: "../schemas/index.yml#/Favourite"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
post:
  tags:
    - favourites
  summary: Create a favourite
  description: Save a command as a favourite on this server. Private by default, add share entries to share.
  operationId: createFavourite
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/FavouriteCreate"
  responses:
    '201':
      description: Favourite created
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Favourite"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 5: Create `src/paths/servers@{id}@favourites@{favId}.yml`**

```yaml
put:
  tags:
    - favourites
  summary: Update a favourite
  description: Update a favourite. Users can update their own, admins can update any.
  operationId: updateFavourite
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
    - name: favId
      in: path
      required: true
      schema:
        type: string
        format: uuid
  requestBody:
    required: true
    content:
      application/json:
        schema:
          $ref: "../schemas/index.yml#/FavouriteUpdate"
  responses:
    '200':
      description: Favourite updated
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Favourite"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Favourite not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
delete:
  tags:
    - favourites
  summary: Delete a favourite
  description: Delete a favourite. Users can delete their own, admins can delete any.
  operationId: deleteFavourite
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
    - name: favId
      in: path
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '204':
      description: Favourite deleted
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Favourite not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 6: Create `src/paths/audit.yml`**

```yaml
get:
  tags:
    - audit
  summary: Get tenant-wide audit log
  description: Query audit log entries across the entire tenant. Admin or owner only. Paginated and filterable.
  operationId: getTenantAuditLog
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: page
      in: query
      schema:
        type: integer
        default: 1
    - name: pageSize
      in: query
      schema:
        type: integer
        default: 20
    - name: userId
      in: query
      description: Filter by user who performed the action
      schema:
        type: string
        format: uuid
    - name: serverId
      in: query
      description: Filter by server
      schema:
        type: string
        format: uuid
    - name: action
      in: query
      description: Filter by action type
      schema:
        type: string
        enum:
          - command.executed
          - command.replayed
          - server.created
          - server.updated
          - server.deleted
          - role.created
          - role.updated
          - role.deleted
          - member.invited
          - member.removed
          - member.updated
          - permission.updated
          - favourite.shared
    - name: from
      in: query
      description: Filter from this date (inclusive)
      schema:
        type: string
        format: date-time
    - name: to
      in: query
      description: Filter to this date (inclusive)
      schema:
        type: string
        format: date-time
  responses:
    '200':
      description: Audit log
      content:
        application/json:
          schema:
            allOf:
              - $ref: "../schemas/index.yml#/PaginatedResponse"
              - type: object
                required:
                  - items
                properties:
                  items:
                    type: array
                    items:
                      $ref: "../schemas/index.yml#/AuditEntry"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden - admin or owner required
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 7: Create `src/paths/servers@{id}@audit.yml`**

```yaml
get:
  tags:
    - audit
  summary: Get server audit log
  description: Query audit log entries for a specific server. Admin or owner only. Paginated and filterable.
  operationId: getServerAuditLog
  security:
    - bearer_auth: []
  parameters:
    - $ref: "../api.yml#/components/parameters/TenantId"
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
    - name: page
      in: query
      schema:
        type: integer
        default: 1
    - name: pageSize
      in: query
      schema:
        type: integer
        default: 20
    - name: userId
      in: query
      description: Filter by user who performed the action
      schema:
        type: string
        format: uuid
    - name: action
      in: query
      description: Filter by action type
      schema:
        type: string
        enum:
          - command.executed
          - command.replayed
          - server.created
          - server.updated
          - server.deleted
          - role.created
          - role.updated
          - role.deleted
          - member.invited
          - member.removed
          - member.updated
          - permission.updated
          - favourite.shared
    - name: from
      in: query
      description: Filter from this date (inclusive)
      schema:
        type: string
        format: date-time
    - name: to
      in: query
      description: Filter to this date (inclusive)
      schema:
        type: string
        format: date-time
  responses:
    '200':
      description: Server audit log
      content:
        application/json:
          schema:
            allOf:
              - $ref: "../schemas/index.yml#/PaginatedResponse"
              - type: object
                required:
                  - items
                properties:
                  items:
                    type: array
                    items:
                      $ref: "../schemas/index.yml#/AuditEntry"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: Forbidden - admin or owner required
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 8: Create `src/paths/rcon@exec.yml`**

```yaml
post:
  tags:
    - rcon
  summary: Quick connect - execute command
  description: |
    Execute an RCON command directly by providing connection details.
    No server registration or command permissions required.
    Requires authentication. Rate-limited per user.
  operationId: quickConnectExec
  security:
    - bearer_auth: []
  parameters:
    - name: hostname
      in: query
      description: Hostname of the RCON server
      required: true
      schema:
        type: string
        example: "rcon.example.org"
    - name: port
      in: query
      description: Port for the RCON server
      required: true
      schema:
        type: integer
        example: 27020
    - name: password
      in: query
      description: Password for the RCON server
      required: true
      schema:
        type: string
        format: password
  requestBody:
    description: Plain text RCON command
    required: true
    content:
      text/plain:
        schema:
          type: string
        example: ListPlayers
  responses:
    '200':
      description: Command executed
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/QuickConnectResponse"
    '401':
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '429':
      description: Rate limit exceeded
      headers:
        Retry-After:
          description: Seconds until the rate limit resets
          schema:
            type: integer
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '502':
      description: Failed to connect to the RCON server
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 9: Create `src/paths/ws@servers@{id}.yml`**

```yaml
get:
  tags:
    - websocket
  summary: WebSocket command channel
  description: |
    Upgrade to a WebSocket connection for real-time command execution.

    Authentication and tenant are provided via query parameters because the
    WebSocket handshake does not support custom headers in browsers.

    ## Client-to-Server Messages (JSON)

    - `{"type": "exec", "command": "...", "args": [...]}` - Execute a command
    - `{"type": "ping"}` - Keep-alive

    ## Server-to-Client Messages (JSON)

    - `{"type": "result", "success": true, "raw": "...", "command": "...", "executionTimeMs": ...}` - Command result
    - `{"type": "error", "code": "...", "message": "..."}` - Error
    - `{"type": "pong"}` - Keep-alive response

    Permission checks apply to every exec message. Commands are written to history and audit log.
  operationId: websocketConnect
  parameters:
    - name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid
    - name: token
      in: query
      description: JWT token for authentication
      required: true
      schema:
        type: string
    - name: tenant
      in: query
      description: Tenant ID
      required: true
      schema:
        type: string
        format: uuid
  responses:
    '101':
      description: Switching Protocols - WebSocket connection established
    '401':
      description: Invalid or expired token
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '403':
      description: No access to this server
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
    '404':
      description: Server not found
      content:
        application/json:
          schema:
            $ref: "../schemas/index.yml#/Error"
```

- [ ] **Step 10: Commit**

```bash
git add "src/paths/servers@{id}@exec.yml" "src/paths/servers@{id}@history.yml" "src/paths/servers@{id}@history@{entryId}@replay.yml" "src/paths/servers@{id}@favourites.yml" "src/paths/servers@{id}@favourites@{favId}.yml" src/paths/audit.yml "src/paths/servers@{id}@audit.yml" "src/paths/rcon@exec.yml" "src/paths/ws@servers@{id}.yml"
git commit -m "feat: add execution, history, favourite, audit, rcon, and websocket path files"
```

---

## Task 11: Build & Validate

- [ ] **Step 1: Run the build script**

```bash
bash scripts/build.sh
```

Expected: no errors, `build/openapi.yml` is generated, `redocly stats` shows the full endpoint count.

- [ ] **Step 2: Fix any `$ref` resolution errors**

If redocly reports broken references, check the `$ref` paths in the failing file. Common issues:
- Schema refs should use `../schemas/index.yml#/SchemaName`
- Parameter refs should use `../api.yml#/components/parameters/TenantId`
- Path file `$ref` in api.yml should use `./paths/filename.yml`

Fix any issues and re-run the build until it succeeds.

- [ ] **Step 3: Verify endpoint count**

The bundled spec should contain ~38 operations across 24 path files. Check with:

```bash
grep -c "operationId:" build/openapi.yml
```

- [ ] **Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve build issues in OpenAPI spec"
```

---

## Task 12: Final Review & Cleanup

- [ ] **Step 1: Generate HTML docs**

```bash
STATIC_HTML_DOCS=1 bash scripts/build.sh
```

Open `build/api_doc.html` in a browser and visually verify:
- All tags/sections are present
- Schemas render correctly with examples
- `X-Tenant-Id` header appears on tenant-scoped endpoints
- Security scheme shows as Bearer JWT

- [ ] **Step 2: Commit final state**

```bash
git add -A
git commit -m "feat: complete ARCON v2 OpenAPI contract"
```
