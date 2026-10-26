#!/usr/bin/env python3
"""Read-only iOS Firebase release preflight. Never emits credentials or tokens."""
import json
import plistlib
import re
import sys
from pathlib import Path

EXPECTED_BUNDLE = "ge.mili.delivery"
ROOT = Path(__file__).resolve().parents[1]

plist_path = ROOT / "ios/GoogleService-Info.plist"
pbx_path = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
android_path = ROOT / "android/app/google-services.json"

errors = []
for path in (plist_path, pbx_path, android_path):
    if not path.exists():
        errors.append(f"Missing required Firebase/release file: {path.relative_to(ROOT)}")

if not errors:
    with plist_path.open("rb") as handle:
        ios = plistlib.load(handle)
    android = json.loads(android_path.read_text())
    ios_bundle = ios.get("BUNDLE_ID")
    ios_project = ios.get("PROJECT_ID")
    android_project = android.get("project_info", {}).get("project_id")
    pbx_text = pbx_path.read_text()
    target_ids = set(re.findall(
        r"PRODUCT_BUNDLE_IDENTIFIER\\s*=\\s*([^;]+);", pbx_text
    ))
    app_target_ids = {s.strip().strip('"') for s in target_ids if ".RunnerTests" not in s}

    print(f"Expected app identifier: {EXPECTED_BUNDLE}")
    print(f"iOS plist app identifier: {ios_bundle or '[missing]'}")
    print(f"Xcode app target identifiers: {', '.join(sorted(app_target_ids)) or '[missing]'}")
    print(f"Android Firebase project: {android_project or '[missing]'}")
    print(f"iOS Firebase project: {ios_project or '[missing]'}")

    if ios_bundle != EXPECTED_BUNDLE:
        errors.append("iOS plist BUNDLE_ID does not match the MILI app identifier.")
    if EXPECTED_BUNDLE not in app_target_ids or len(app_target_ids) != 1:
        errors.append("Xcode main app bundle identifier differs from the MILI release ID.")
    if not ios.get("GOOGLE_APP_ID") or not ios.get("GCM_SENDER_ID"):
        errors.append("iOS Firebase application registration fields are missing.")
    if not ios_project or not android_project:
        errors.append("Firebase PROJECT_ID is missing.")
    elif ios_project != android_project:
        errors.append(
            "Android/iOS Firebase projects are split. MILI currently has only "
            "one configured backend FCM project; unify Firebase registrations "
            "or explicitly implement and verify cross-project sending/IAM first."
        )

    extra_plist = ROOT / "ios/Runner/GoogleService-Info.plist"
    if extra_plist.exists():
        print(
            "NOTE: A second ios/Runner/GoogleService-Info.plist exists. "
            "The release review must confirm which plist Xcode packages."
        )

if errors:
    for error in errors:
        print(f"RELEASE BLOCKED: {error}", file=sys.stderr)
    sys.exit(1)
print("Firebase iOS release preflight PASS (static configuration only).")
