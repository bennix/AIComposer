#!/bin/zsh
# Publish the notarized release and update feed. Large DMGs use verified multipart downloads.
# Run release.sh first; requires gh login and the aicomposer Sparkle key in Keychain.
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
[[ -f "$SOURCE" && -x "$SIGN_UPDATE" ]] || { echo "Run scripts/release.sh first."; exit 1; }
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Release $TAG already exists; refusing to overwrite it."
  exit 1
fi
xcrun stapler validate "$SOURCE"
signature=$("$SIGN_UPDATE" --account aicomposer "$SOURCE")
assets=("$SOURCE")
large=false
if (( $(stat -f%z "$SOURCE") >= 2147483648 )); then
  large=true
  PACKAGE="$PROJECT_DIR/dist/github-$TAG"
  python3 "$PROJECT_DIR/scripts/prepare_github_release.py" "$SOURCE" --version "$VERSION" --output "$PACKAGE"
  print -r -- "$signature" > "$PACKAGE/$ASSET.edSignature.txt"
  cp "$PROJECT_DIR/LICENSE" "$PACKAGE/GPL-LICENSE.txt"
  cp "$PROJECT_DIR/LICENSING.md" "$PACKAGE/LICENSING.txt"
  cp "$PROJECT_DIR/Compositor/Resources/OpenImagePrompts/DATA_LICENSE.md" "$PACKAGE/OIP-DATA-LICENSE.txt"
  assets=("$PACKAGE/$ASSET".part?? "$PACKAGE/SHA256SUMS" "$PACKAGE/download-manifest.json"
          "$PACKAGE/download-aicomposer.command" "$PACKAGE/$ASSET.edSignature.txt"
          "$PACKAGE/GPL-LICENSE.txt" "$PACKAGE/LICENSING.txt" "$PACKAGE/OIP-DATA-LICENSE.txt")
fi
NOTES_FILE="$WORK/release-notes.md"
print -r -- "${RELEASE_NOTES:-AIComposer $VERSION}" > "$NOTES_FILE"
echo "==> Creating draft $TAG"
gh release create "$TAG" --draft --repo "$REPO" --target "$(git -C "$PROJECT_DIR" rev-parse HEAD)" --title "AIComposer $VERSION — Complete Offline Edition" --notes-file "$NOTES_FILE"
echo "==> Uploading verified assets"
gh release upload "$TAG" "${assets[@]}" --repo "$REPO"
gh release edit "$TAG" --draft=false --latest --repo "$REPO"

# Sparkle cannot reconstruct split archives. Official informational updates open the download page.
if $large; then
  enclosure='<sparkle:informationalUpdate/>'
  link="https://bennix.github.io/AIComposer/#download"
else
  enclosure="<enclosure url=\"https://github.com/$REPO/releases/download/$TAG/$ASSET\" $signature type=\"application/octet-stream\"/>"
  link="https://github.com/$REPO/releases/tag/$TAG"
fi
feed=$(cat <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>AIComposer</title>
    <item>
      <title>AIComposer $VERSION — Complete Offline Edition</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MINIMUM</sparkle:minimumSystemVersion>
      <description><![CDATA[<p>39 style cards, 23,196 originals and 43,943 bundled images. The complete offline edition is a 7.36GB manual download; visit the download page for the verified multipart helper.</p><p>完整离线版包含全部图片，需要手动下载与合并，不会自动下载数 GB 资源。</p>]]></description>
      <link>$link</link>
      $enclosure
    </item>
  </channel>
</rss>
XML
)
print -r -- "$feed" > "$PROJECT_DIR/appcast-v2.xml"
print -r -- "$feed" > "$PROJECT_DIR/docs/appcast-v2.xml"
git -C "$PROJECT_DIR" add appcast-v2.xml docs/appcast-v2.xml
git -C "$PROJECT_DIR" commit -q -m "Publish update feed for AIComposer $VERSION"
git -C "$PROJECT_DIR" -c credential.helper='!gh auth git-credential' push -q "$REMOTE" HEAD:main
echo "==> Published: https://github.com/$REPO/releases/tag/$TAG"
