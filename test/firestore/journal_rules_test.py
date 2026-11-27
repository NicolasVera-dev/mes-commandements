"""Run against a local Firestore emulator; never connects to production.

FIRESTORE_EMULATOR_HOST=127.0.0.1:8088 python3 test/firestore/journal_rules_test.py
Use project demo-rituel-journal and load this repository's firestore.rules.
"""
import base64
import json
import os
import time
import unittest
import urllib.error
import urllib.request

PROJECT = 'demo-rituel-journal'
HOST = os.environ.get('FIRESTORE_EMULATOR_HOST', '')
if not HOST.startswith(('127.0.0.1:', 'localhost:')):
    raise RuntimeError('A localhost Firestore emulator is required')
BASE = f'http://{HOST}/v1/projects/{PROJECT}/databases/(default)/documents'


def token(uid):
    def encode(value):
        return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
    now = int(time.time())
    return '.'.join([encode({'alg': 'none', 'typ': 'JWT'}), encode({
        'iss': f'https://securetoken.google.com/{PROJECT}', 'aud': PROJECT,
        'sub': uid, 'user_id': uid, 'iat': now, 'exp': now + 3600,
        'firebase': {'sign_in_provider': 'custom'},
    }), ''])


def field(value):
    if value is None:
        return {'nullValue': None}
    if isinstance(value, bool):
        return {'booleanValue': value}
    if isinstance(value, str):
        return {'stringValue': value}
    if isinstance(value, int):
        return {'integerValue': str(value)}
    if isinstance(value, list):
        return {'arrayValue': {'values': [field(v) for v in value]}}
    return {'mapValue': {'fields': {k: field(v) for k, v in value.items()}}}


def request(method, path, uid=None, data=None):
    headers = {'Content-Type': 'application/json'}
    if uid:
        headers['Authorization'] = 'Bearer ' + token(uid)
    body = None if data is None else json.dumps({'fields': {k: field(v) for k, v in data.items()}}).encode()
    req = urllib.request.Request(BASE + '/' + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code


class JournalRulesTest(unittest.TestCase):
    def setUp(self):
        self.task = {'title': 'Devis', 'priority': False, 'order': 0,
                     'plans': [{'start': '2026-11-25', 'end': None}],
                     'originalDay': '2026-11-25', 'completedDay': None, 'removedDay': None}
        self.path = 'users/owner/journal_tasks/' + self._testMethodName
        self.assertEqual(request('PATCH', self.path, 'owner', self.task), 200)

    def test_owner_can_read_and_update(self):
        self.assertEqual(request('GET', self.path, 'owner'), 200)
        self.task['completedDay'] = '2026-11-25'
        self.assertEqual(request('PATCH', self.path, 'owner', self.task), 200)

    def test_other_accounts_and_anonymous_are_denied(self):
        for uid in ['stranger', None]:
            self.assertEqual(request('GET', self.path, uid), 403)
            self.assertEqual(request('PATCH', self.path, uid, self.task), 403)
            self.assertEqual(request('DELETE', self.path, uid), 403)

    def test_invalid_tasks_are_denied(self):
        for change in [{'title': ''}, {'title': 'a' * 201}, {'priority': 'yes'},
                       {'plans': []}, {'extra': True}]:
            self.assertEqual(request('PATCH', self.path, 'owner', {**self.task, **change}), 403)

    def test_reflections_are_private_and_validated(self):
        path = 'users/owner/journal_reflections/2026-11-25'
        review = {'note': 'Une belle journée', 'mood': 'satisfied'}
        self.assertEqual(request('PATCH', path, 'owner', review), 200)
        self.assertEqual(request('GET', path, 'owner'), 200)
        self.assertEqual(request('GET', path, 'stranger'), 403)
        self.assertEqual(request('GET', path, None), 403)
        self.assertEqual(request('PATCH', path, 'owner', {**review, 'mood': 'invalid'}), 403)
        self.assertEqual(request('PATCH', path, 'owner', {**review, 'note': 'a' * 4001}), 403)
        self.assertEqual(request('PATCH', path, 'owner', {'note': '', 'mood': None}), 200)


if __name__ == '__main__':
    unittest.main()
