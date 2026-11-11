#!/usr/bin/env bash
# Build an unsigned, arm64 release IPA for subsequent signing with Sideloadly.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This workflow requires macOS and Xcode." >&2
  exit 1
fi

source_branch="${CM_BRANCH:-$(git branch --show-current)}"
if [[ "$source_branch" != "main" ]]; then
  echo "Unsigned MILI device builds are restricted to the main branch." >&2
  exit 1
fi

app_slug="${MILI_IOS_APP_SLUG:?MILI_IOS_APP_SLUG must be set}"
expected_bundle="${MILI_IOS_BUNDLE_ID:?MILI_IOS_BUNDLE_ID must be set}"
case "$app_slug:$expected_bundle" in
  vendor:ge.mili.vendor|delivery:ge.mili.delivery) ;;
  *) echo "Unexpected application identity; refusing to build." >&2; exit 1 ;;
esac

artifact_dir="$repo_root/build/ios/sideloadly"
mkdir -p "$artifact_dir"
if [[ ! -f ios/Podfile.lock ]]; then
  echo "A committed iOS Podfile.lock is required." >&2
  exit 1
fi
cp ios/Podfile.lock "$artifact_dir/Podfile.before.lock"

# Actual Firebase app registrations must match before an IPA is built.
# This gate deliberately does not rewrite identifiers or bypass mismatches.
python3 scripts/check-ios-firebase-release.py \
  2>&1 | tee "$artifact_dir/firebase-preflight.log"
python3 scripts/check-ios-url-schemes.py \
  2>&1 | tee -a "$artifact_dir/firebase-preflight.log"

flutter config --enable-ios
flutter pub get --enforce-lockfile

# CocoaPods creates the plugin symlinks on the first installation attempt.
# Preserve the existing lock and only repair the explicitly audited Firebase
# snapshot mismatch; any other resolution failure remains a hard failure.
pod_status=0
(cd ios && pod install --repo-update) || pod_status=$?
if [[ "$pod_status" -ne 0 ]]; then
  firebase_version_file="ios/.symlinks/plugins/firebase_core/ios/firebase_sdk_version.rb"
  if [[ ! -f "$firebase_version_file" ]]; then
    echo "CocoaPods failed before the expected Firebase plugin was available." >&2
    exit "$pod_status"
  fi
  firebase_versions="$(ruby -ryaml -e '
    lock = YAML.safe_load(File.read(ARGV[0]))
    pods = lock.fetch("PODS")
    names = pods.flat_map { |pod| pod.is_a?(Hash) ? pod.keys : [pod] }
    snapshot = names.find { |name| name.start_with?("Firebase/CoreOnly (") }
    locked = snapshot && snapshot[/\(([^)]+)\)/, 1]
    source = File.read(ARGV[1])
    expected = source[/^\s*["\x27](\d+\.\d+\.\d+)["\x27]\s*$/, 1]
    abort "Cannot establish the audited Firebase versions." unless locked && expected
    puts "#{locked}:#{expected}"
  ' ios/Podfile.lock "$firebase_version_file")"

  case "$app_slug:$firebase_versions" in
    vendor:12.8.0:12.15.0)
      (cd ios && pod update Firebase/CoreOnly Firebase/Messaging)
      ;;
    delivery:12.2.0:12.6.0)
      (cd ios && pod update Firebase/CoreOnly Firebase/Messaging Firebase/Auth)
      ;;
    *)
      echo "CocoaPods failed outside the known Firebase snapshot mismatch." >&2
      echo "Review the native dependency lock; no blanket pod update is allowed." >&2
      exit "$pod_status"
      ;;
  esac
fi
cp ios/Podfile.lock "$artifact_dir/Podfile.lock"
(cd ios && pod install --deployment)

flutter build ios --release --no-codesign --no-pub
cp ios/Podfile.lock "$artifact_dir/Podfile.lock"

app_path="$repo_root/build/ios/iphoneos/Runner.app"
if [[ ! -d "$app_path" ]]; then
  echo "The expected iPhone device application was not produced." >&2
  exit 1
fi
lipo -verify_arch arm64 "$app_path/Runner"

staging_path="$artifact_dir/staging"
if [[ -e "$staging_path" ]]; then
  echo "IPA staging already exists; use a fresh CI checkout/build directory." >&2
  exit 1
fi
mkdir -p "$staging_path/Payload"
ditto "$app_path" "$staging_path/Payload/Runner.app"
ipa_path="$artifact_dir/mili-$app_slug-unsigned-sideloadly.ipa"
(
  cd "$staging_path"
  ditto -c -k --keepParent Payload "$ipa_path"
)
python3 scripts/write-ios-sideloadly-provenance.py \
  --app "$app_path" \
  --ipa "$ipa_path" \
  --bundle-id "$expected_bundle" \
  --app-slug "$app_slug" \
  --artifact-dir "$artifact_dir"
