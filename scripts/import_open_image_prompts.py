#!/usr/bin/env python3
"""Build the native OIP index from a SHA-verified upstream checkout (no image copies)."""
import argparse
import gzip
import hashlib
import json
import re
import sqlite3
import subprocess
import tempfile
import unicodedata
from pathlib import Path


def cards(root):
    result = []
    mapping = {'中文名 / English name': 'names', '触发': 'trigger', '不适用': 'not_for',
               '视觉 DNA': 'visual_dna', '构图、光色与材质': 'composition_light_color_material',
               '边界': 'boundaries', '反模式': 'anti_patterns', '选择边界': 'selection_boundary'}
    for path in sorted((root / 'skills/img-gen-taste/references').glob('*.md')):
        for section in re.split(r'^## ', path.read_text(), flags=re.M)[1:]:
            match = re.search(r'^- `id`:\s*`([^`]+)`', section, re.M)
            if not match:
                continue
            fields = {}
            for line in section.splitlines():
                m = re.match(r'^- \*\*([^*]+)\*\*\s*(.*)', line) or re.match(r'^- `([^`]+)`:\s*(.*)', line)
                if m:
                    key = m[1].rstrip(':：')
                    fields[mapping.get(key, key)] = m[2].strip('`')
            if 'names' in fields:
                names = fields['names'].split(' / ', 1)
                fields['name_zh'] = names[0]
                fields['name_en'] = names[-1]
            template = re.search(r'```text\n(.*?)\n```', section, re.S)
            if template:
                fields['template'] = template[1]
            fields.update(id=match[1], category=path.stem,
                          references=list(dict.fromkeys(re.findall(r'tweet_id:\s*(\d+)', section))),
                          source='https://github.com/NanmiCoder/open-image-prompts/blob/main/skills/img-gen-taste/references/' + path.name)
            result.append(fields)
    assert len(result) == 39 and len({c['id'] for c in result}) == 39
    assert all(c.get('template') and c.get('visual_dna') for c in result)
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('checkout', type=Path)
    p.add_argument('--output', type=Path, default=Path('Compositor/Resources/OpenImagePrompts'))
    args = p.parse_args()
    root, out = args.checkout.resolve(), args.output
    manifest = json.loads((root / 'data/dataset-manifest.json').read_text())
    assert manifest['taxonomy_version'] == 'oip-visual-v2'
    archive = root / 'db/prompts.db.gz'
    with archive.open('rb') as f:
        digest = hashlib.sha256()
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            digest.update(chunk)
        assert digest.hexdigest() == manifest['db']['sha256'], 'Upstream checksum mismatch'
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='aicomposer-oip-') as temp:
        source = Path(temp) / 'source.sqlite'
        with gzip.open(archive, 'rb') as f, source.open('wb') as dest:
            import shutil
            shutil.copyfileobj(f, dest)
        src = sqlite3.connect(source)
        src.row_factory = sqlite3.Row
        db = Path(temp) / 'native.sqlite'
        dst = sqlite3.connect(db)
        dst.executescript('''
        PRAGMA user_version=2;
        CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
        CREATE TABLE records(id TEXT PRIMARY KEY, author TEXT, tool TEXT, source TEXT, original TEXT, zh TEXT, en TEXT, search_text TEXT);
        CREATE TABLE images(id INTEGER PRIMARY KEY, record_id TEXT, url TEXT, path TEXT);
        CREATE INDEX image_record ON images(record_id);
        CREATE TABLE tags(record_id TEXT, tag TEXT, image INTEGER, confidence REAL, PRIMARY KEY(record_id,tag,image));
        CREATE INDEX tag_lookup ON tags(tag,record_id);
        ''')
        dst.executemany('INSERT INTO metadata VALUES(?,?)', [('version', manifest['dataset_version']), ('taxonomy', manifest['taxonomy_version'])])
        translations = {}
        for r in src.execute('SELECT tweet_id,locale,translated_text FROM prompt_translations'):
            translations.setdefault(r['tweet_id'], {})[r['locale']] = r['translated_text']
        for r in src.execute('SELECT * FROM prompts ORDER BY tweet_id'):
            tr = translations.get(r['tweet_id'], {})
            zh = tr.get('zh-Hans', tr.get('zh', ''))
            en = tr.get('en', '')
            dst.execute('INSERT INTO records VALUES(?,?,?,?,?,?,?,?)', (r['tweet_id'], r['author'], r['tool'], r['tweet_url'], r['prompt_text'], zh, en, unicodedata.normalize('NFKC', '\n'.join([r['prompt_text'], zh, en])).casefold()))
        dst.executemany('INSERT INTO images VALUES(?,?,?,?)',
                        (tuple(r) for r in src.execute('SELECT id,tweet_id,url,local_path FROM images ORDER BY id')))
        for table, image in [('prompt_labels', 0), ('media_labels', 1)]:
            where = "AND p.media_type='image'" if image else ''
            rows = src.execute(f'''SELECT p.tweet_id,t.dimension_key||':'||t.key,MAX(p.confidence)
                FROM {table} p JOIN taxonomy_labels t ON p.label_id=t.label_id AND p.taxonomy_version=t.taxonomy_version
                WHERE p.taxonomy_version='oip-visual-v2' {where} GROUP BY p.tweet_id,t.dimension_key,t.key''')
            dst.executemany('INSERT INTO tags VALUES(?,?,?,?)', ((r[0],r[1],image,r[2]) for r in rows))
        counts = {t: dst.execute('SELECT count(*) FROM ' + t).fetchone()[0] for t in ['records','images','tags']}
        assert counts['records'] == manifest['db']['counts']['prompts']
        assert counts['images'] == manifest['db']['counts']['images']
        dst.commit()
        assert dst.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
        dst.close()
        subprocess.run(['/usr/bin/swift', '-e', '''import Foundation
let d = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let packed = try (d as NSData).compressed(using: .lzfse)
try packed.write(to: URL(fileURLWithPath: CommandLine.arguments[2]), options: .atomic)
''', str(db), str(out / 'Archive.oip')], check=True)
    (out / 'StyleCards.json').write_text(json.dumps(cards(root), ensure_ascii=False, indent=2) + '\n')
    for name, dest in [('data/dataset-manifest.json', 'DatasetManifest.json'),
                       ('retrieval/oip-visual-v2-intent.json','Intent.json'),
                       ('taxonomy/oip-visual-v2.json','Taxonomy.json'),
                       ('DATA_LICENSE.md','DATA_LICENSE.md'),('LICENSE','LICENSE'),
                       ('skills/img-gen-taste/SKILL.md','TasteSkill.md'),
                       ('skills/img-gen-prompts/SKILL.md','PromptsSkill.md')]:
        (out / dest).write_bytes((root / name).read_bytes())
    commit = subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
    (out / 'Provenance.json').write_text(json.dumps(dict(repository='https://github.com/NanmiCoder/open-image-prompts',commit=commit,counts=counts,
        datasetVersion=manifest['dataset_version'],archiveSHA256=hashlib.sha256((out/'Archive.oip').read_bytes()).hexdigest()), indent=2)+'\n')
    print(json.dumps(dict(counts=counts,bytes=(out/'Archive.oip').stat().st_size,commit=commit)))

if __name__ == '__main__':
    main()
