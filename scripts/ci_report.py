"""Turns analyzer and test output into GitHub annotations."""
import json
import sys


def esc(text):
    return text.replace('%', '%25').replace('\r', '').replace('\n', '%0A')


def analyze(path, root):
    count = 0
    for line in open(path, encoding='utf-8', errors='replace'):
        parts = line.rstrip('\n').split('|')
        if len(parts) < 8:
            if line.strip():
                print(line.rstrip())
            continue
        sev, _, code, file, ln, col = parts[:6]
        msg = '|'.join(parts[7:])
        level = {'ERROR': 'error', 'WARNING': 'warning'}.get(sev, 'notice')
        file = file.replace(root, '')
        print(f'::{level} file={file},line={ln},col={col}::{code}: {esc(msg)}')
        count += 1
    print(f'Analyzer issues: {count}')


def test(path):
    names = {}
    prints = {}
    failed = 0
    for line in open(path, encoding='utf-8', errors='replace'):
        line = line.strip()
        if not line.startswith('{'):
            continue
        try:
            event = json.loads(line)
        except ValueError:
            continue
        kind = event.get('type')
        if kind == 'testStart':
            t = event['test']
            names[t['id']] = (t.get('name', ''), t.get('url') or t.get('root_url') or '')
        elif kind == 'print':
            prints.setdefault(event.get('testID'), []).append(event.get('message', ''))
        elif kind == 'error':
            name, url = names.get(event.get('testID'), ('?', ''))
            logged = '\n'.join(prints.get(event.get('testID'), []))[:3000]
            body = f"{name}\n{logged}\n{event.get('error', '')}\n{event.get('stackTrace', '')[:800]}"
            print(f'::error title={esc(name)[:120]}::{esc(body)[:4000]}')
            failed += 1
    print(f'Test errors: {failed}')


if __name__ == '__main__':
    if sys.argv[1] == 'analyze':
        analyze(sys.argv[2], sys.argv[3])
    else:
        test(sys.argv[2])
