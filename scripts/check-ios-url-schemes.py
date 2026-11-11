#!/usr/bin/env python3
"""Check iOS URL-type structure without printing configuration values."""

import plistlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BUNDLE = "ge.mili.delivery"
REQUIRES_PHONE_AUTH_CALLBACK = True
KEEPZ_CALLBACK = None


def check_configuration(firebase, info):
    errors = []
    if firebase.get("BUNDLE_ID") != EXPECTED_BUNDLE:
        errors.append("Firebase app identifier differs from the expected app.")
    url_types = info.get("CFBundleURLTypes", [])
    if not isinstance(url_types, list):
        return errors + ["CFBundleURLTypes must be an array."]

    schemes = []
    for entry in url_types:
        if not isinstance(entry, dict):
            errors.append("Each CFBundleURLTypes entry must be a dictionary.")
            continue
        values = entry.get("CFBundleURLSchemes")
        if not isinstance(values, list) or not values:
            errors.append("Each URL type must contain a non-empty scheme array.")
            continue
        for value in values:
            if not isinstance(value, str):
                errors.append("URL scheme arrays may contain strings only.")
            elif not re.fullmatch(r"[A-Za-z][A-Za-z0-9+.-]*", value):
                errors.append("A URL scheme has an invalid format.")
            else:
                schemes.append(value)
    if len(schemes) != len(set(schemes)):
        errors.append("A URL scheme is registered more than once.")

    app_id = firebase.get("GOOGLE_APP_ID")
    if not isinstance(app_id, str) or not app_id:
        errors.append("The official Firebase application registration is missing.")
        encoded_callback = None
    else:
        encoded_callback = "app-" + app_id.replace(":", "-")
    if REQUIRES_PHONE_AUTH_CALLBACK:
        if not encoded_callback or schemes.count(encoded_callback) != 1:
            errors.append("The current Firebase phone-auth callback is missing.")
    if any(value.startswith("app-1-") and value != encoded_callback for value in schemes):
        errors.append("A stale Firebase phone-auth callback remains.")

    reversed_client = firebase.get("REVERSED_CLIENT_ID")
    if any(
        value.startswith("com.googleusercontent.apps.") and value != reversed_client
        for value in schemes
    ):
        errors.append("An unregistered Google OAuth callback remains.")

    if KEEPZ_CALLBACK and schemes.count(KEEPZ_CALLBACK) != 1:
        errors.append("The existing Keepz callback must remain a top-level URL type.")

    facebook_app = info.get("FacebookAppID")
    if facebook_app and "fb" + str(facebook_app) not in schemes:
        errors.append("The existing Facebook callback was not preserved.")
    return errors


def main():
    with (ROOT / "ios/GoogleService-Info.plist").open("rb") as handle:
        firebase = plistlib.load(handle)
    with (ROOT / "ios/Runner/Info.plist").open("rb") as handle:
        info = plistlib.load(handle)
    errors = check_configuration(firebase, info)
    duplicate = ROOT / "ios/Runner/GoogleService-Info.plist"
    if duplicate.exists():
        if duplicate.read_bytes() != (ROOT / "ios/GoogleService-Info.plist").read_bytes():
            errors.append("The additional Firebase plist must exactly match the official copy.")
    if errors:
        for error in errors:
            print("iOS URL configuration BLOCKED: " + error, file=sys.stderr)
        return 1
    print("iOS URL scheme preflight PASS (static configuration only).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
