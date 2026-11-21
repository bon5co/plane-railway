# Wrapper over Plane's all-in-one community image, pinned by digest.
# Adds: admin seeded before the public port opens (closes the anonymous
# instance-admin claim), signup disabled, telemetry off, secrets stable.
FROM makeplane/plane-aio-community:v1.5.0@sha256:16a2680cc7ab0c1ef86396905563816246692e32302154cb2a4f335276ac03b0

COPY railway-entrypoint.sh /railway-entrypoint.sh
COPY seed_admin.py /app/seed_admin.py
RUN chmod +x /railway-entrypoint.sh

# Signup closed and telemetry off by default (baked, not deployer-facing).
ENV ENABLE_SIGNUP=0

ENTRYPOINT ["/railway-entrypoint.sh"]
