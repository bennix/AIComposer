#!/usr/bin/env python3
"""Fail packaging if any built-in creative image is missing, truncated or mismatched."""
import argparse
import hashlib
import json
from pathlib import Path


def verify(resources, hashes=False):
    provenance_path = resources / 'OpenImagePrompts/Provenance.json'
    if not provenance_path.is_file():
        provenance_path = resources / 'Provenance.json'
    provenance = json.loads(provenance_path.read_text())
    gallery = json.loads((resources / 'OpenNanaGallery.json').read_text())
    expectations = [('OpenImagePromptsImages.bundle', provenance['counts']['images']),
                    ('OpenNanaImages.bundle', len(gallery['entries']))]
    for name, expected in expectations:
        bundle = resources / name
        data = json.loads((bundle / 'Inventory.json').read_text())
        entries = data['images']
        assert data['count'] == len(entries) == expected, f'{name}: incomplete inventory'
        assert len({e['path'] for e in entries}) == expected, f'{name}: duplicate paths'
        for entry in entries:
            relative = Path(entry['path'])
            assert entry['path'].startswith('images/') and '..' not in relative.parts
            path = bundle / relative
            assert path.is_file() and path.stat().st_size == entry['bytes'] > 0, f'Missing or truncated: {path}'
            if hashes:
                digest = hashlib.sha256()
                with path.open('rb') as source:
                    for chunk in iter(lambda: source.read(1024 * 1024), b''):
                        digest.update(chunk)
                assert digest.hexdigest() == entry['sha256'], f'Image digest mismatch: {path}'
        print(f'{name}: {expected:,} built-in images verified', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--resources', type=Path, default=Path('Compositor/Resources'))
    parser.add_argument('--hashes', action='store_true')
    args = parser.parse_args()
    verify(args.resources, args.hashes)

if __name__ == '__main__':
    main()
