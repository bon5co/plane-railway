# plane-railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/plane-or-just-updated-jira-and-linear-al?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

**Deploy on Railway:** [Plane template](https://railway.com/deploy/plane-or-just-updated-jira-and-linear-al?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

Railway wrapper image for [Plane](https://plane.so), the open-source
Jira/Linear alternative, built on the official all-in-one community image
(`makeplane/plane-aio-community`) pinned by digest to v1.4.1.

## What this adds over deploying the stock image

- **Admin seeded before the public port opens.** Upstream exposes
  `POST /api/instances/admins/sign-up/` with `permission_classes=[AllowAny]`;
  while no `InstanceAdmin` exists, any anonymous caller becomes the instance
  administrator and `is_setup_done` flips — and upstream ships no env var or
  non-interactive CLI to seed one, so every stock deploy is claimable by the
  first stranger to reach the URL. This image boots Plane with Caddy bound to
  loopback, seeds the admin from `ADMIN_EMAIL`/`ADMIN_PASSWORD`, then hot-reloads
  Caddy onto `$PORT`. The public port never serves an unclaimed instance.
- **Password reset by redeploy.** The admin password is re-applied on every
  boot (upstream's reset is an interactive `getpass` prompt only).
- **Signup closed** (`ENABLE_SIGNUP=0`) and **telemetry off** by default.
- **Pinned** to a specific Plane release rather than a moving `:stable` tag,
  on an app that runs forward-only Django migrations every boot.

## Required variables

| Variable | Purpose |
|----------|---------|
| `ADMIN_EMAIL` | instance administrator login |
| `ADMIN_PASSWORD` | instance administrator password |

Plus the standard Plane wiring (`DATABASE_URL`, `REDIS_URL`, `AMQP_URL`, the
`AWS_*` S3 settings, `SECRET_KEY`, `LIVE_SERVER_SECRET_KEY`). See the Railway
template for the full service graph.
