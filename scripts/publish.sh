#!/bin/zsh
# Publishes the DMG that release.sh built: a GitHub Release (v<version>) on bennix/AIComposer,
# then the Sparkle update feed (appcast.xml on main + GitHub Pages) pointing at it.
#
# Run release.sh first. Needs the Sparkle signing key in the login keychain and `gh` signed in.
# Release notes: RELEASE_NOTES="…" ./scripts/publish.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP=Compositor
REPO=bennix/AIComposer
REMOTE="https://github.com/$REPO.git"
WORK="$HOME/Library/Caches/CompositorRelease"
SIGN_UPDATE="$WORK/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"

settings=$(xcodebuild -project "$PROJECT_DIR/$APP.xcodeproj" -scheme "$APP" -configuration Release -showBuildSettings 2>/dev/null)
VERSION=$(print -r -- "$settings" | awk -F' = ' '/ MARKETING_VERSION = /{print $2; exit}')
BUILD=$(print -r -- "$settings" | awk -F' = ' '/ CURRENT_PROJECT_VERSION = /{print $2; exit}')
MINIMUM=$(print -r -- "$settings" | awk -F' = ' '/ MACOSX_DEPLOYMENT_TARGET = /{print $2; exit}')
TAG="v$VERSION"
SOURCE="$PROJECT_DIR/dist/$APP-$VERSION.dmg"
ASSET="$APP-$VERSION.dmg"
[[ -f "$SOURCE" ]] || { echo "No $SOURCE — run scripts/release.sh first."; exit 1; }
[[ -x "$SIGN_UPDATE" ]] || { echo "Sparkle's sign_update isn't built — run scripts/release.sh first."; exit 1; }
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Release $TAG already exists. Raise the version (and build number) first."
  exit 1
fi

echo "==> $APP $VERSION ($BUILD)"

echo "==> Signing the update for Sparkle"
signature=$("$SIGN_UPDATE" "$SOURCE")

echo "==> Creating GitHub Release $TAG"
gh release create "$TAG" "$SOURCE" --repo "$REPO" --title "AIComposer $VERSION" --notes "${RELEASE_NOTES:-AIComposer $VERSION}"

echo "==> Publishing the update feed"
feed=$(cat <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>AIComposer</title>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MINIMUM</sparkle:minimumSystemVersion>
      <link>https://github.com/$REPO/releases/tag/$TAG</link>
      <enclosure url="https://github.com/$REPO/releases/download/$TAG/$ASSET" $signature type="application/octet-stream"/>
    </item>
  </channel>
</rss>
XML
)
print -r -- "$feed" > "$PROJECT_DIR/appcast.xml"
print -r -- "$feed" > "$PROJECT_DIR/docs/appcast.xml"
git -C "$PROJECT_DIR" add appcast.xml docs/appcast.xml
git -C "$PROJECT_DIR" commit -q -m "Publish update feed for AIComposer $VERSION"
git -C "$PROJECT_DIR" -c credential.helper='!gh auth git-credential' push -q "$REMOTE" HEAD:main
echo "==> Done: https://github.com/$REPO/releases/tag/$TAG"
echo "==> Feed: https://bennix.github.io/AIComposer/appcast.xml"
