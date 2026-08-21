# Wrapper over Plane's all-in-one community image, pinned by digest.
# Adds: admin seeded before the public port opens (closes the anonymous
# instance-admin claim), signup disabled, telemetry off, secrets stable.
FROM makeplane/plane-aio-community:stable@sha256:48d104c606b017f0b3bcbeef004921d97dd32e806a4b1d8e99a1748ee71ee291

COPY railway-entrypoint.sh /railway-entrypoint.sh
COPY seed_admin.py /app/seed_admin.py
RUN chmod +x /railway-entrypoint.sh

# Signup closed and telemetry off by default (baked, not deployer-facing).
ENV ENABLE_SIGNUP=0

ENTRYPOINT ["/railway-entrypoint.sh"]
