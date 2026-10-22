# PostgreSQL 18 OCI image

Nix-built PostgreSQL 18 image for x86_64 Linux using Nixpkgs' `postgresql_18` and `dockerTools`. It does not wrap an upstream OCI image.

## Build

```sh
nix flake check
nix build .#image
podman load -i result
```

The lockfile pins Nixpkgs; current selected server version is 18.6.

## Runtime contract

- Numeric non-root identity: `10001:10001`.
- Direct entrypoint: Nixpkgs PostgreSQL `postgres`; no shell entrypoint or automatic init script. Bash is included at `/bin/sh` because Nixpkgs `initdb` invokes a shell to locate the server binary.
- TCP port metadata: 5432.
- Writable path: `/var/lib/postgresql/data` (PGDATA); image creates it with UID/GID 10001 and mode 0700. Mount `/tmp` as tmpfs for the local socket directory when using a read-only root.
- The server does not initialize a new database automatically. Initialize a new, disposable or explicitly provisioned directory with the included `initdb` before starting the server.
- For network access, configure `listen_addresses` and initialize host authentication with SCRAM/passwords. Never expose a trust-authenticated cluster to a shared network.
- Keep PostgreSQL 18 data separate from other major versions. No compatibility with an existing database has been established.

## Disposable smoke-test pattern

Create a new temporary Podman volume, initialize only that volume, start the server, and verify `pg_isready`. Remove only that test volume afterward. Never use existing PostgreSQL storage.
