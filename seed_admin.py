"""Seed the Plane instance administrator before the public port opens.

Upstream exposes POST /api/instances/admins/sign-up/ with permission_classes
[AllowAny]: while no InstanceAdmin exists, any anonymous caller becomes the
instance admin and is_setup_done flips. There is no env var and no
non-interactive CLI to seed the admin, so every stock deploy is claimable by
the first stranger to reach the URL. This script closes that window: it creates
the admin (idempotently) and re-applies the password on every boot, so a
redeploy is a working password reset. Run before Caddy binds $PORT.
"""
import os
import uuid

from django.contrib.auth.hashers import make_password
from django.utils import timezone

from plane.db.models import User, Profile
from plane.license.models import Instance, InstanceAdmin

email = (os.environ.get("ADMIN_EMAIL") or "").strip().lower()
password = os.environ.get("ADMIN_PASSWORD") or ""
first_name = os.environ.get("ADMIN_FIRST_NAME") or "Admin"

if not email or not password:
    raise SystemExit("SEED: ADMIN_EMAIL and ADMIN_PASSWORD are required")

instance = Instance.objects.first()
if instance is None:
    raise SystemExit("SEED: instance not configured yet")

user = User.objects.filter(email=email).first()
if user is None:
    user = User.objects.create(
        first_name=first_name,
        email=email,
        username=uuid.uuid4().hex,
        password=make_password(password),
        is_password_autoset=False,
        is_active=True,
    )
    Profile.objects.get_or_create(user=user)
    print(f"SEED: created admin user {email}")
else:
    # Rotate the password on every boot -> redeploy is a working reset.
    user.password = make_password(password)
    user.is_password_autoset = False
    user.is_active = True
    user.save(update_fields=["password", "is_password_autoset", "is_active"])
    Profile.objects.get_or_create(user=user)
    print(f"SEED: re-applied password for {email}")

if not InstanceAdmin.objects.filter(user=user).exists():
    InstanceAdmin.objects.create(user=user, instance=instance, role=20)
    print("SEED: registered instance admin")

# Close setup and turn telemetry off.
instance.is_setup_done = True
instance.is_telemetry_enabled = False
instance.save(update_fields=["is_setup_done", "is_telemetry_enabled"])
print("SEED: setup_done=True telemetry=off")
