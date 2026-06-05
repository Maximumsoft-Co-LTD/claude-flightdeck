# Database Migration Patterns — Idempotent, Reversible, Zero-Downtime

> Loaded by `/ship` Phase 1.5 (and `/ship --check`) when the
> deployment introduces schema changes. Covers idempotent runners,
> expand-contract for online changes, `pt-online-schema-change` /
> `gh-ost` for MySQL, and the rollback drill.

## The two-axis question every migration must answer

| | Reversible (can run `down`) | Not reversible |
|---|---|---|
| Online-safe (no table lock) | Default — most migrations | Document the irreversibility in the migration file's header |
| Locking / downtime needed | Run during a maintenance window | Run during a maintenance window AND document irreversibility |

Default = reversible + online-safe. Anything else needs explicit
justification in the design doc.

## Idempotent up / down

A migration is **idempotent** when re-running it produces no error and
no state drift. This matters because:

- CI runs migrations on a fresh DB AND on a re-baselined snapshot.
- Failed deployments may re-run `up` after partial application.
- Developers re-run locally after `git pull` without resetting.

**Idempotent ADDs:**

```sql
-- Postgres
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- MySQL 8 (some versions don't support IF NOT EXISTS for columns)
-- Use a procedure / pre-check:
SET @col := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
               AND COLUMN_NAME = 'email_verified');
SET @sql := IF(@col = 0, 'ALTER TABLE users ADD COLUMN email_verified TINYINT(1) DEFAULT 0', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
```

**Idempotent DROPs:**

```sql
ALTER TABLE users DROP COLUMN IF EXISTS old_field;
DROP INDEX IF EXISTS idx_users_old;
```

**Idempotent backfills** use `WHERE` to skip already-updated rows:

```sql
UPDATE users SET tenant_id = '...' WHERE tenant_id IS NULL;
```

## Expand-contract (a.k.a. the parallel-change pattern)

The canonical safe-by-default migration for stateful systems. Used
when changing a column type, renaming, splitting, or removing.

**Single big-bang rename:**
```
v1: CREATE -> code uses old_col
v2: ALTER COLUMN RENAME old_col -> new_col + code uses new_col
       ⚠ Any pod still running v1 errors out during the rollout.
```

**Expand-contract:**

```
v1:     code reads old_col, writes old_col

v2:     ALTER TABLE ADD new_col
        code DUAL WRITES (old + new), DUAL READS (prefer new, fall back to old)
        backfill job copies old_col -> new_col for existing rows

v3:     code writes new_col only, reads new_col only
        (no schema change in this version)

v4:     ALTER TABLE DROP old_col
        (only safe once no running pod reads it)
```

Each step is independently deployable + reversible. The deploy is
boring; no migration ever races a pod rollout.

**Naming convention** for the migration files:
```
20260520_120000_expand_users_add_new_email.sql
20260521_080000_backfill_users_new_email.sql
20260522_120000_contract_users_drop_old_email.sql
```

Lock-free for the entire deploy.

## Online schema change (MySQL — pt-online-schema-change)

When you must run a long ALTER on a hot table without locking:

```bash
pt-online-schema-change \
  --execute \
  --alter "ADD COLUMN email_verified TINYINT(1) DEFAULT 0" \
  --max-load Threads_running=50 \
  --critical-load Threads_running=200 \
  --chunk-size=1000 \
  --recursion-method=hosts \
  D=mydb,t=users,h=writer.example.com,u=migrator,p=$DB_PASS
```

What it does:
1. Creates a shadow table (`_users_new`) with the new schema.
2. Copies rows in chunks while triggers replicate writes.
3. Swaps the two tables in a single atomic RENAME.
4. Drops the old table (or keeps `_users_old` for safety).

Caveats:
- Requires triggers; doesn't work on tables that already have a
  trigger for the operation you're applying.
- Increases write load 2-3x during the copy. Run off-peak.
- Foreign keys are tricky — read the docs before applying to a
  parent / child of an FK.

## Online schema change (MySQL — gh-ost)

Modern alternative; uses the binlog instead of triggers (lower app
overhead):

```bash
gh-ost \
  --execute \
  --user=migrator --password=$DB_PASS \
  --host=writer.example.com \
  --database=mydb \
  --table=users \
  --alter="ADD COLUMN email_verified TINYINT(1) DEFAULT 0" \
  --max-load=Threads_running=50 \
  --critical-load=Threads_running=200 \
  --chunk-size=1000 \
  --allow-on-master \
  --cut-over=default
```

Prefer `gh-ost` over `pt-osc` when:
- You can't add triggers (e.g. multi-master replication, GTID
  constraints).
- You want to pause / resume the migration mid-flight.

## Online schema change (Postgres)

Postgres handles many ALTERs online natively. The pitfalls:

- `ALTER TABLE ADD COLUMN` is fast IF no default OR (Postgres 11+) a
  constant default. A non-constant default triggers a table rewrite.
- `ALTER TABLE ALTER COLUMN TYPE` rewrites the table — lock.
- `CREATE INDEX` locks writes; use `CREATE INDEX CONCURRENTLY` for
  zero downtime.

**Safe Postgres patterns:**
```sql
-- Adding a column with no default: instant
ALTER TABLE users ADD COLUMN email_verified BOOLEAN;

-- Adding default later, in a second migration, in chunks
UPDATE users SET email_verified = FALSE WHERE email_verified IS NULL
  AND id BETWEEN ? AND ?;  -- run in batches

-- Then enforce
ALTER TABLE users ALTER COLUMN email_verified SET DEFAULT FALSE;
ALTER TABLE users ALTER COLUMN email_verified SET NOT NULL;

-- Indexes — always CONCURRENTLY in prod
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

## Rollback drill

Every migration that ships gets practiced in advance:

```bash
# Local rehearsal — verify up + down work
<your migrate up>
<your migrate down 1>
<your migrate up>

# Verify the schema is bit-for-bit identical after up→down→up
<your schema-dump command> > /tmp/before.sql
<your migrate up>
<your migrate down 1>
<your migrate up>
<your schema-dump command> > /tmp/after.sql
diff /tmp/before.sql /tmp/after.sql      # should be empty
```

For prod rollback, the playbook is:
1. **STOP THE BLEEDING** — roll back the app (revert image tag /
   ArgoCD rollback). Schema is forward-compatible if you used
   expand-contract.
2. **Decide if schema needs reverting** — most expand-contract
   migrations DON'T need a down. The old column is still there.
3. **If schema MUST revert** — run `<your migrate down N>` ONLY after
   confirming no live app version expects the new shape.
4. **Postmortem** — capture what went wrong; was it the migration
   itself, or app code consuming the new shape?

## When migrations cannot be reversed

Document the irreversibility in the migration file header. Common
cases:

- **Data loss in `down`** — `DROP COLUMN` on `up` means `down` would
  have to backfill from somewhere. If the source data is gone, the
  `down` is impossible.
- **Type narrowing** — `VARCHAR(255) -> VARCHAR(50)` truncates rows.
  Down can restore the type but not the truncated bytes.
- **Schema split** — splitting `name` into `first` + `last` is
  reversible in shape but lossy if rejoining doesn't know the original
  separator.

For irreversible migrations:

```sql
-- 20260601_120000_drop_legacy_user_audit.sql
-- IRREVERSIBLE: this drops the user_audit table. After this runs in
-- prod, the only way to recover the audit history is from the
-- nightly backups. See docs/runbooks/restore-user-audit.md.

DROP TABLE IF EXISTS user_audit;

-- DOWN migration intentionally errors so it can't run silently:
-- raise NotImplementedError
SELECT 1/0;
```

The `down` deliberately fails. If you need to "revert" it, you must
plan a separate forward migration that recreates the structure +
restores from backup.

## Pre-deploy checklist

- [ ] Migration has both `up` and `down` (or `down` documented as
      impossible)
- [ ] `up` is idempotent (re-runs are no-ops)
- [ ] Tested locally: `up`, `down`, `up` produces identical schema
- [ ] If hot-table on MySQL → planned via `gh-ost` / `pt-osc`
- [ ] If hot-table on Postgres → uses `CONCURRENTLY` for indexes,
      no implicit table rewrite
- [ ] Expand-contract used for any rename / type-narrow / drop where
      pods + DB live across the rollout
- [ ] Backfill jobs chunk-sized + resumable
- [ ] Document the runtime estimate in the migration header
- [ ] Migration job's PreSync wave is correct (ArgoCD) or `dependsOn`
      is set (Flux)

## Related

- `references/gitops-argocd.md` §Sync hooks — PreSync Job for ArgoCD
- `references/gitops-flux.md` — Kustomization `dependsOn` for Flux
- `references/health-probes.md` — `readyz` must wait for migrations
  before reporting Ready
