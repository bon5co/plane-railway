# Wrapper over Plane's all-in-one community image, pinned by digest.
# Adds: admin seeded before the public port opens (closes the anonymous
# instance-admin claim), signup disabled, telemetry off, secrets stable.
FROM makeplane/plane-aio-community:v1.4.3@sha256:07ead622af2cd7ae200845a3a37076ee68f36c529e281309dd7801ad1dd5a009

COPY railway-entrypoint.sh /railway-entrypoint.sh
COPY seed_admin.py /app/seed_admin.py
RUN chmod +x /railway-entrypoint.sh

# Signup closed and telemetry off by default (baked, not deployer-facing).
ENV ENABLE_SIGNUP=0

ENTRYPOINT ["/railway-entrypoint.sh"]
