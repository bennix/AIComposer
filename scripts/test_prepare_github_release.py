import contextlib
import hashlib
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import prepare_github_release as publisher


class ReleasePartsTests(unittest.TestCase):
    def test_partial_final_piece_and_download_helper_reconstruct_original(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            content = bytes(range(256)) * 3 + b'original notarization ticket bytes'
            source = root / 'Compositor-2.2.0.dmg'
            source.write_bytes(content)
            output = root / 'assets'
            with patch.object(publisher, 'PART_SIZE', 127), contextlib.redirect_stdout(io.StringIO()):
                manifest = publisher.prepare(source, output, '2.2.0', 'bennix/AIComposer')
            self.assertGreater(len(manifest['parts']), 1)
            joined = b''.join((output / part['name']).read_bytes() for part in manifest['parts'])
            self.assertEqual(content, joined)
            self.assertEqual(hashlib.sha256(content).hexdigest(), manifest['sha256'])
            self.assertTrue(all(part['bytes'] <= 127 for part in manifest['parts']))
            result = subprocess.run(['bash', str(output / 'download-aicomposer.command'), str(output)], check=True, capture_output=True, text=True)
            self.assertNotIn('Downloading:', result.stdout)
            self.assertEqual(content, (output / source.name).read_bytes())
            self.assertEqual(source.read_bytes(), content)

    def test_exact_boundary_does_not_emit_empty_asset(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / 'fixture.dmg'
            source.write_bytes(b'abcdef' * 4)
            with patch.object(publisher, 'PART_SIZE', 12), contextlib.redirect_stdout(io.StringIO()):
                result = publisher.prepare(source, root / 'assets', '2.2.0', 'bennix/AIComposer')
            self.assertEqual([p['bytes'] for p in result['parts']], [12, 12])


if __name__ == '__main__':
    unittest.main()
