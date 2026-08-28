# Git Server managed service

This repository defines the Codesphere landscape-based **Git Server** managed
service provider. It is powered by [Forgejo](https://forgejo.org/); each service
instance runs Forgejo 16 with a dedicated PostgreSQL 17.9 managed service and
persistent workspace storage.

## Service behavior

- Forgejo serves its web UI and HTTP Git traffic on port 3000 through the
  landscape's `/` route.
- The built-in SSH server is disabled. Clone and push over HTTPS.
- Repository data, attachments, configuration, and other Forgejo files persist
  in the workspace `data/` directory.
- Application metadata and state persist in a dedicated PostgreSQL database.
- The service runs as a non-root user and uses one replica because its file
  storage is not shared between replicas.

## Configuration

Codesphere collects the fields declared in `provider.yml`. Configuration is
injected into the landscape as `workspace.env`; secrets are injected into the
landscape vault. `ci.yml` then maps them to Forgejo and PostgreSQL.

| Field | Required | Default | Purpose |
| --- | --- | --- | --- |
| `APP_NAME` | No | `Git Server` | Instance name shown in the UI |
| `DISABLE_REGISTRATION` | No | `true` | Prevent self-service user registration |
| `REQUIRE_SIGNIN_VIEW` | No | `true` | Require authentication to view the instance |
| `PG_APP_PASSWORD` | Yes | — | Forgejo database credential (vault secret) |
| `PG_ADMIN_PASSWORD` | Yes | — | Database provisioning credential (vault secret) |

Use different random values of at least 16 characters for the two database
passwords. Changing configuration restarts the landscape and can briefly
interrupt the service.

After the first deployment, open the service URL assigned by Codesphere and
complete Forgejo's initial setup. The database connection is already supplied by
the landscape. Create the first administrator during setup. If self-registration
remains disabled, subsequent users must be created or invited by an administrator.

## Publish the provider

Publishing requires Codesphere cluster-admin permission (or a team-scoped
provider request) and a Git connection that can read this repository.

1. Commit the provider and landscape files.
2. Create and push the immutable release tag referenced by `provider.yml`:

   ```shell
   git tag v0.1.0
   git push origin main v0.1.0
   ```

3. Upsert the provider through the Codesphere API:

   ```shell
   curl -X PUT "https://<codesphere-host>/api/managed-services/providers" \
     -H "Authorization: Bearer <api-key>" \
     -H "Content-Type: application/json" \
     -d '{
       "gitUrl": "https://github.com/codesphere-cloud/managed-services-git-server",
       "gitRef": "v0.1.0",
       "scope": { "type": "global" }
     }'
   ```

Use a team scope with `teamIds` instead of `global` when the service should only
be visible to selected teams. Provider versions are append-only: publish changes
under a new version and Git tag rather than moving an existing tag.

See [Architecture](docs/architecture.md) for component boundaries, data flow,
storage, networking, and operational considerations.

## Operations

- Back up both the workspace `data/` path and the PostgreSQL managed service. A
  database-only backup does not contain Git repositories or attachments.
- Restore the database and file storage from the same backup point to keep them
  consistent.
- Upgrade Forgejo by changing the image tag, testing the database migration, and
  publishing a new append-only provider version and Git tag.

The provider format and configuration hand-off follow the
[Codesphere service-provider guide](https://docs.codesphere.com/managed-services/creating-service-providers#passing-configuration-to-landscapes).
