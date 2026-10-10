#!/usr/bin/env python3
"""Import the publicly accessible VSC atlas; never bypass membership access."""
import argparse
import concurrent.futures
import datetime
import json
from pathlib import Path
from urllib.request import urlopen

BASE = 'https://vibeshot.club'

def fetch(path):
    with urlopen(BASE + path, timeout=30) as response:
        return json.load(response)

def domain_styles(domain):
    data = fetch('/api/lexicon/atlas/domain/' + domain['id'])['props']
    result = []
    for lineage in data['lineages']:
        for concept in lineage['concepts']:
            if concept.get('locked'):
                continue
            detail = fetch('/api/lexicon/atlas/concept/' + concept['slug'])['props']['data']
            if detail.get('locked'):
                continue
            result.append(dict(id=detail['id'], name=detail['name'], summary=detail['summary'],
                               domain=domain['name'], lineage=lineage['name'],
                               features=detail.get('features') or {},
                               prompt=detail.get('prompt_template') or '',
                               source=BASE + '/lexicon/concept/' + concept['slug']))
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', default='Compositor/Resources/StyleAtlas.json')
    args = parser.parse_args()
    home = fetch('/api/lexicon/atlas/home')['props']
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        styles = [style for group in pool.map(domain_styles, home['data']['domains']) for style in group]
    assert len(styles) == home['data']['stats']['concepts'], 'Incomplete import; output not replaced'
    assert len({style['id'] for style in styles}) == len(styles)
    data = dict(source=BASE + '/lexicon', importedAt=datetime.date.today().isoformat(),
                total=home['access']['total'], styles=styles)
    Path(args.output).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print(f"Imported {len(styles)} accessible styles of {data['total']} into {args.output}")

if __name__ == '__main__':
    main()
