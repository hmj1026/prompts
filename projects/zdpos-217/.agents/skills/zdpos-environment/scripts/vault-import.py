"""從 accounts.md 取出指定 env／account 的密碼，直接以 stdin 存進 agent-browser auth vault。
不印出任何密碼或其他列內容，只回報是否成功。"""
import io
import subprocess
import sys

path, env, account, profile, url = sys.argv[1:6]
matches = []
with io.open(path, encoding='utf-8') as fh:
    for line in fh:
        if not line.lstrip().startswith('|'):
            continue
        cells = [c.strip().strip('`') for c in line.strip().strip('|').split('|')]
        if len(cells) >= 3 and cells[0].lower() == env and cells[1] == account:
            matches.append(cells[2])
if len(matches) != 1:
    print('rows matched: %d (need exactly 1); nothing saved' % len(matches))
    sys.exit(1)
proc = subprocess.run(
    ['agent-browser', 'auth', 'save', profile, '--url', url, '--username', account, '--password-stdin'],
    input=matches[0].encode('utf-8'), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
print('exit=%d' % proc.returncode)
print(proc.stdout.decode('utf-8', 'replace').replace(matches[0], '***')[:300])
print(proc.stderr.decode('utf-8', 'replace').replace(matches[0], '***')[:300])
