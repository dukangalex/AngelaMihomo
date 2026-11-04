"""Static policy checks for GitHub Actions workflows.

Guards the 2026-11 CI hardening decisions:
- Every third-party action is pinned to a full commit SHA (no mutable tags).
- No job may hold `write-all`; the workflow default is contents: read and
  the release job carries only the scopes it actually uses.
- Checkouts never persist credentials into the workspace.
"""
import re
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
WORKFLOWS = ROOT / '.github' / 'workflows'
SHA_PIN = re.compile(r'@[0-9a-f]{40}(\s|$)')


def load(name):
    return yaml.safe_load((WORKFLOWS / name).read_text(encoding='utf-8'))


def all_steps(doc):
    for job in (doc.get('jobs') or {}).values():
        yield from job.get('steps') or []


class WorkflowPolicyTest(unittest.TestCase):
    def test_all_actions_pinned_to_full_sha(self):
        for path in sorted(WORKFLOWS.glob('*.y*ml')):
            for line in path.read_text(encoding='utf-8').splitlines():
                stripped = line.strip()
                if stripped.startswith('uses:'):
                    self.assertRegex(
                        stripped,
                        SHA_PIN,
                        f'{path.name}: unpinned action: {stripped}',
                    )

    def test_no_write_all_anywhere(self):
        for path in sorted(WORKFLOWS.glob('*.y*ml')):
            self.assertNotIn('write-all', path.read_text(encoding='utf-8'))

    def test_checkouts_do_not_persist_credentials(self):
        for path in sorted(WORKFLOWS.glob('*.y*ml')):
            doc = yaml.safe_load(path.read_text(encoding='utf-8'))
            for step in all_steps(doc):
                uses = step.get('uses', '')
                if uses.startswith('actions/checkout@'):
                    with_block = step.get('with') or {}
                    self.assertIs(
                        with_block.get('persist-credentials'),
                        False,
                        f'{path.name}: checkout persists credentials',
                    )

    def test_build_workflow_permission_shape(self):
        doc = load('build.yaml')
        self.assertEqual(doc.get('permissions'), {'contents': 'read'})
        build = doc['jobs']['build']
        self.assertEqual(build['permissions'].get('contents'), 'read')
        upload = doc['jobs']['upload']
        self.assertEqual(
            upload['permissions'],
            {'contents': 'write', 'actions': 'read'},
        )

    def test_android_apk_workflow_is_read_only(self):
        doc = load('android-apk.yml')
        self.assertEqual(doc.get('permissions'), {'contents': 'read'})


if __name__ == '__main__':
    unittest.main()
