"""讀 agent-browser eval 的輸出（JSON 字串，可能再包一層 JSON），判斷攔截器狀態。

Exit：0 已武裝且沒有擋下的請求；9 未武裝或輸出不可解析；10 有請求被擋下。
"""
import json
import sys


def load(text):
    value = json.loads(text)
    return json.loads(value) if isinstance(value, str) else value


def main():
    raw = sys.stdin.read().strip()
    try:
        state = load(raw)
    except ValueError:
        print('GUARD NOT ARMED: unreadable output: %s' % raw[:200], file=sys.stderr)
        return 9
    if not isinstance(state, dict) or state.get('armed') is not True:
        print('GUARD NOT ARMED: %s' % raw[:300], file=sys.stderr)
        return 9
    print(json.dumps(state, ensure_ascii=False))
    if state.get('blocked'):
        print('GUARD BLOCKED: %s' % state['blocked'], file=sys.stderr)
        return 10
    return 0


if __name__ == '__main__':
    sys.exit(main())
