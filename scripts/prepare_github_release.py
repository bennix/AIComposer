#!/usr/bin/env python3
"""Split an unchanged large notarized DMG into GitHub-compatible assets and a verified downloader."""
import argparse
import hashlib
import json
from pathlib import Path

PART_SIZE = 1_900_000_000  # GitHub requires each Release asset to be under 2 GiB.


def digest(path):
    result = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(8 * 1024 * 1024), b''):
            result.update(chunk)
    return result.hexdigest()


def prepare(source, output, version, repository):
    output.mkdir(parents=True, exist_ok=True)
    parts = []
    full = hashlib.sha256()
    with source.open('rb') as stream:
        index = 1
        while True:
            first = stream.read(min(8 * 1024 * 1024, PART_SIZE))
            if not first:
                break
            path = output / f'{source.name}.part{index:02d}'
            part_hash = hashlib.sha256()
            size = 0
            with path.open('wb') as target:
                block = first
                while block:
                    target.write(block); part_hash.update(block); full.update(block)
                    size += len(block)
                    if size == PART_SIZE:
                        break
                    block = stream.read(min(8 * 1024 * 1024, PART_SIZE - size))
            parts.append(dict(name=path.name, bytes=size, sha256=part_hash.hexdigest()))
            print(f'Prepared {path.name}: {size:,} bytes', flush=True)
            index += 1
    manifest = dict(version=version, file=source.name, bytes=source.stat().st_size, sha256=full.hexdigest(), parts=parts)
    (output / 'download-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (output / 'SHA256SUMS').write_text(''.join(f'{part["sha256"]}  {part["name"]}\n' for part in parts) + f'{full.hexdigest()}  {source.name}\n')
    base = f'https://github.com/{repository}/releases/download/v{version}'
    lines = '\n'.join(f'fetch_part "{part["name"]}" "{part["sha256"]}"' for part in parts)
    part_names = ' '.join('"' + part['name'] + '"' for part in parts)
    script = '''#!/bin/bash
# Downloads and reconstructs the original signed, notarized DMG. Does not install or launch it.
set -euo pipefail
BASE=__BASE__
DEST="${1:-$HOME/Downloads/AIComposer-__VERSION__}"
DMG=__DMG__
EXPECTED=__HASH__
mkdir -p "$DEST"
cd "$DEST"
check() { printf '%s  %s\\n' "$2" "$1" | /usr/bin/shasum -a 256 -c - >/dev/null 2>&1; }
if [[ -f "$DMG" ]] && check "$DMG" "$EXPECTED"; then
  printf 'Verified DMG already exists: %s/%s\\n' "$DEST" "$DMG"
  exit 0
fi
fetch_part() {
  local name="$1" hash="$2"
  if [[ -f "$name" ]] && check "$name" "$hash"; then
    printf 'Verified: %s\\n' "$name"
    return
  fi
  printf 'Downloading: %s\\n' "$name"
  /usr/bin/curl --fail --location --retry 3 --continue-at - "$BASE/$name" -o "$name.download"
  if ! check "$name.download" "$hash"; then
    printf 'Checksum failed: %s. Remove its .download file and retry.\\n' "$name" >&2
    return 1
  fi
  mv "$name.download" "$name"
}
__FETCH__
printf 'All parts verified. Reconstructing the original notarized DMG…\\n'
cat __PARTS__ > "$DMG.assembling"
if ! check "$DMG.assembling" "$EXPECTED"; then
  printf 'Final DMG checksum failed; no installation was performed.\\n' >&2
  exit 1
fi
mv "$DMG.assembling" "$DMG"
printf 'Ready: %s/%s\\nOpen the DMG and drag Compositor to Applications.\\n' "$DEST" "$DMG"
'''
    replacements = {'__BASE__': '"' + base + '"', '__VERSION__': version,
                    '__DMG__': '"' + source.name + '"', '__HASH__': '"' + full.hexdigest() + '"',
                    '__FETCH__': lines, '__PARTS__': part_names}
    for key, value in replacements.items():
        script = script.replace(key, value)
    helper = output / 'download-aicomposer.command'
    helper.write_text(script)
    helper.chmod(0o755)
    return manifest


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('dmg', type=Path)
    p.add_argument('--version', required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--repository', default='bennix/AIComposer')
    args = p.parse_args()
    result = prepare(args.dmg, args.output, args.version, args.repository)
    print(f'{len(result["parts"])} parts; original SHA-256: {result["sha256"]}', flush=True)

if __name__ == '__main__':
    main()
