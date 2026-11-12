#!/usr/bin/env python3
"""Prepare and verify the complete offline image bundles; never substitute missing images."""
import argparse
import concurrent.futures
import hashlib
import json
import shutil
import sqlite3
import time
import urllib.request
from pathlib import Path


def download(item):
    url, target, *fallbacks = item
    if target.is_file() and target.stat().st_size:
        return None
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix('.part')
    last_error = ''
    for address in [url, *fallbacks]:
        for attempt in range(3):
            try:
                request = urllib.request.Request(address, headers={'User-Agent': 'AIComposer-offline-resources/1.0'})
                with urllib.request.urlopen(request, timeout=45) as response, temporary.open('wb') as out:
                    shutil.copyfileobj(response, out)
                with temporary.open('rb') as image:
                    prefix = image.read(16)
                if not (prefix.startswith(b'\xff\xd8\xff') or prefix.startswith(b'\x89PNG') or prefix.startswith(b'RIFF') or prefix.startswith(b'GIF8') or b'ftyp' in prefix):
                    raise ValueError('Response is not an image')
                temporary.replace(target)
                return None
            except Exception as error:
                last_error = str(error)
                temporary.unlink(missing_ok=True)
                if attempt < 2:
                    time.sleep(attempt + 1)
    return {'urls': [url, *fallbacks], 'path': str(target), 'error': last_error}


def fetch_all(items, title):
    failures = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=32) as pool:
        for number, failure in enumerate(pool.map(download, items), 1):
            if failure:
                failures.append(failure)
            if number % 100 == 0 or number == len(items):
                print(f'{title}: {number}/{len(items)}, failures: {len(failures)}', flush=True)
    return failures


def inventory(bundle, paths, source):
    missing = [name for name in paths if not (bundle / name).is_file() or not (bundle / name).stat().st_size]
    if missing:
        raise RuntimeError(f'{bundle.name}: {len(missing)} images missing; no complete inventory was written')
    entries = []
    for name in paths:
        path = bundle / name
        digest = hashlib.sha256()
        with path.open('rb') as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b''):
                digest.update(chunk)
        entries.append({'path': name, 'bytes': path.stat().st_size, 'sha256': digest.hexdigest()})
    value = {'source': source, 'count': len(entries), 'bytes': sum(e['bytes'] for e in entries), 'images': entries}
    (bundle / 'Inventory.json').write_text(json.dumps(value, ensure_ascii=False, separators=(',', ':')) + '\n')
    print(f'{bundle.name}: verified {value["count"]} images, {value["bytes"]:,} bytes', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checkout', type=Path)
    parser.add_argument('--opennana-only', action='store_true')
    args = parser.parse_args()
    resources = Path('Compositor/Resources')
    failures = []
    if not args.opennana_only:
        if not args.checkout:
            parser.error('--checkout is required')
        root = args.checkout.resolve()
        database = root / '.oip/runtime/prompts.db'
        conn = sqlite3.connect(f'file:{database}?mode=ro', uri=True)
        rows = conn.execute('SELECT url,local_path FROM images ORDER BY id').fetchall()
        assert len(rows) == 38519
        bundle = resources / 'OpenImagePromptsImages.bundle'
        missing = []
        paths = []
        for url, name in rows:
            path = Path(name)
            assert name.startswith('images/') and '..' not in path.parts and not path.is_absolute()
            paths.append(name)
            target = bundle / name
            if not target.is_file():
                source = root / name
                if source.is_file():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source, target)
                else:
                    # The upstream API explicitly documents this public self-hosted media base.
                    mirror = 'https://media.openimages.relakkesyang.org/' + name
                    missing.append((mirror, target, url))
        print(f'OIP: {len(rows)-len(missing)} local files ready; fetching {len(missing)} missing source files', flush=True)
        failures += fetch_all(missing, 'OIP source files')
        if not failures:
            inventory(bundle, paths, 'https://github.com/NanmiCoder/open-image-prompts')
    data = json.loads((resources / 'OpenNanaGallery.json').read_text())
    bundle = resources / 'OpenNanaImages.bundle'
    entries = data['entries']
    assert all(str(e['id']).isdigit() for e in entries)
    items = [(e['thumbnail'], bundle / 'images' / (e['id'] + '.image')) for e in entries]
    nana_failures = fetch_all(items, 'OpenNana previews')
    failures += nana_failures
    if not nana_failures:
        inventory(bundle, ['images/' + e['id'] + '.image' for e in entries], data['source'])
    if failures:
        Path('/tmp/aicomposer-image-failures.json').write_text(json.dumps(failures, ensure_ascii=False, indent=2))
        raise SystemExit(f'{len(failures)} downloads failed; details: /tmp/aicomposer-image-failures.json')

if __name__ == '__main__':
    main()
