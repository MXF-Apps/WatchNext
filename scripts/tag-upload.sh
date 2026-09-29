#!/bin/sh
# Tags the current commit with the version and build number that were just
# uploaded to App Store Connect, as semver build metadata: 1.0.0+2 means
# version 1.0.0, build 2. Reads both numbers from the project so the tag can
# never disagree with the archive. Pushes the tag unless --no-push is given.
set -eu
cd "$(dirname "$0")/.."
pbxproj=WatchNext.xcodeproj/project.pbxproj

value() {
    values=$(grep -o "$1 = [^;]*" "$pbxproj" | cut -d' ' -f3 | sort -u)
    if [ "$(printf '%s\n' "$values" | wc -l)" -ne 1 ]; then
        echo "$1 differs between configurations: $(printf '%s ' $values)" >&2
        exit 1
    fi
    printf '%s' "$values"
}

if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree is not clean; commit or stash first." >&2
    exit 1
fi

tag="$(value MARKETING_VERSION)+$(value CURRENT_PROJECT_VERSION)"
git tag "$tag"
echo "Tagged $(git rev-parse --short HEAD) as $tag"
if [ "${1:-}" != "--no-push" ]; then
    git push origin "$tag"
fi
