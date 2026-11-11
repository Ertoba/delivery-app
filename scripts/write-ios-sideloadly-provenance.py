#!/usr/bin/env python3
"""Validate an unsigned device IPA and emit only non-secret build metadata."""

import argparse
import hashlib
import json
import os
import plistlib
import subprocess
import zipfile
from datetime import datetime, timezone
from pathlib import Path


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--ipa", required=True, type=Path)
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--app-slug", required=True)
    parser.add_argument("--artifact-dir", required=True, type=Path)
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    expected_identity = {
        "vendor": "ge.mili.vendor",
        "delivery": "ge.mili.delivery",
    }
    if expected_identity.get(args.app_slug) != args.bundle_id:
        raise SystemExit("Unexpected application identity.")

    with (args.app / "Info.plist").open("rb") as handle:
        info = plistlib.load(handle)
    if info.get("CFBundleIdentifier") != args.bundle_id:
        raise SystemExit("Built application has an unexpected bundle identifier.")
    if (args.app / "_CodeSignature").exists():
        raise SystemExit("Runner.app is unexpectedly signed.")
    if (args.app / "embedded.mobileprovision").exists():
        raise SystemExit("A provisioning profile was unexpectedly embedded.")
    if not (args.app / info.get("CFBundleExecutable", "Runner")).is_file():
        raise SystemExit("Built application executable is missing.")

    preflight_path = args.artifact_dir / "firebase-preflight.log"
    if "Firebase iOS release preflight PASS" not in preflight_path.read_text():
        raise SystemExit("The required Firebase preflight has not passed.")

    with zipfile.ZipFile(args.ipa) as archive:
        corrupt = archive.testzip()
        if corrupt:
            raise SystemExit("IPA archive integrity validation failed.")
        names = archive.namelist()
        if "Payload/Runner.app/Info.plist" not in names:
            raise SystemExit("IPA Payload layout is invalid.")
        if any(name.startswith("/") or ".." in Path(name).parts for name in names):
            raise SystemExit("IPA contains an unsafe archive path.")
        archived_info = plistlib.loads(archive.read("Payload/Runner.app/Info.plist"))
        if archived_info.get("CFBundleIdentifier") != args.bundle_id:
            raise SystemExit("Packaged application bundle identifier differs.")

    flutter = json.loads(subprocess.check_output(
        ["flutter", "--version", "--machine"], text=True, cwd=root
    ))
    commit = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], text=True, cwd=root
    ).strip()
    previous_lock = args.artifact_dir / "Podfile.before.lock"
    resolved_lock = args.artifact_dir / "Podfile.lock"
    previous_hash = sha256(previous_lock)
    resolved_hash = sha256(resolved_lock)
    report = {
        "schemaVersion": 1,
        "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "source": {
            "commit": commit,
            "branch": os.environ.get("CM_BRANCH", "main"),
        },
        "app": {
            "slug": args.app_slug,
            "bundleId": args.bundle_id,
            "versionName": info.get("CFBundleShortVersionString"),
            "buildNumber": info.get("CFBundleVersion"),
            "minimumOsVersion": info.get("MinimumOSVersion"),
        },
        "toolchain": {
            "flutter": flutter.get("frameworkVersion"),
            "engineRevision": flutter.get("engineRevision"),
            "dart": flutter.get("dartSdkVersion"),
            "xcode": subprocess.check_output(
                ["xcodebuild", "-version"], text=True
            ).strip(),
            "cocoapods": subprocess.check_output(
                ["pod", "--version"], text=True
            ).strip(),
        },
        "artifact": {
            "file": args.ipa.name,
            "bytes": args.ipa.stat().st_size,
            "sha256": sha256(args.ipa),
            "signing": "unsigned",
            "intendedInstaller": "Sideloadly",
            "deviceArchitecture": "arm64",
        },
        "nativeDependencyLock": {
            "previousSha256": previous_hash,
            "resolvedSha256": resolved_hash,
            "requiresLockfileReviewAndCommit": previous_hash != resolved_hash,
        },
        "verification": {
            "firebaseConfigurationPreflight": "passed",
            "ipaArchiveIntegrity": "passed",
            "physicalDeviceInstallation": "not performed",
            "pushAuthenticationAndPayments": "not verified",
            "appStoreOrTestFlightSubmission": "not performed",
        },
    }
    output_path = args.artifact_dir / "provenance.json"
    output_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Created unsigned Sideloadly IPA: {args.ipa.name}")
    print(f"Bundle: {args.bundle_id}; version: {info.get('CFBundleVersion')}")
    print(f"SHA-256: {report['artifact']['sha256']}")
    if previous_hash != resolved_hash:
        print("Review the generated Podfile.lock and commit it before subsequent builds.")


if __name__ == "__main__":
    main()
