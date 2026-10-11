#!/usr/bin/env python3
"""Snapshot public OpenNana catalogue metadata, without requesting locked prompts."""
import argparse
import concurrent.futures
import datetime
import json
import subprocess
import tempfile
from pathlib import Path

BASE = 'https://api.opennana.com/api/prompts'

def fetch(page):
    url = f'{BASE}?page={page}&limit=100&access_type=1&sort=reviewed_at&order=DESC'
    result = subprocess.run(['curl', '--fail', '--retry', '4', '--retry-all-errors', '--max-time', '45', '-sL', url],
                            check=True, capture_output=True, text=True)
    response = json.loads(result.stdout)
    if response.get('status') != 200:
        raise ValueError('Catalogue request failed')
    return response['data']

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', default='Compositor/Resources/OpenNanaGallery.json')
    args = parser.parse_args()
    first = fetch(1)
    pagination = first['pagination']
    items = first['items']
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        for data in pool.map(fetch, range(2, pagination['total_pages'] + 1)):
            if data['pagination']['total'] != pagination['total']:
                raise ValueError('Catalogue changed during snapshot; retry')
            items.extend(data['items'])
    if len(items) != pagination['total'] or len({i['id'] for i in items}) != len(items):
        raise ValueError('Incomplete or duplicate catalogue; existing output preserved')
    entries = [dict(id=str(i['id']), title=i['title'], mediaType=i['media_type'],
                    source='https://opennana.com/awesome-prompt-gallery/' + i['slug'],
                    thumbnail=i.get('cover_image') or '') for i in items]
    output = Path(args.output)
    payload = dict(source='https://opennana.com/awesome-prompt-gallery?access_type=1',
                   importedAt=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).date().isoformat(), total=len(entries),
                   scope='paid-public-metadata', entries=entries)
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=output.parent,
                                     delete=False, suffix='.tmp') as file:
        json.dump(payload, file, ensure_ascii=False, indent=2)
        file.write('\n')
        temporary = Path(file.name)
    temporary.replace(output)
    print(f'Saved {len(entries)} public references; locked prompt text was not requested.')

if __name__ == '__main__':
    main()
