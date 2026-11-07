#!/usr/bin/env bash
# Inline Iris-style "/..." includes and compile every program of every dimension with glslangValidator.
set -u
cd "$(dirname "$0")/../shaders"
tmp=$(mktemp -d); fail=0; n=0
for f in *.vsh *.fsh world-1/*.vsh world-1/*.fsh world1/*.vsh world1/*.fsh; do
  stage=vert; [[ $f == *.fsh ]] && stage=frag
  out_f="$tmp/$(echo "$f" | tr / _)"
  python3 -I - "$f" > "$out_f" <<'PY'
import re, sys
seen = set()
def go(p):
    out = []
    for l in open(p):
        m = re.match(r'\s*#include\s+"(.+)"', l)
        if m:
            f = '.' + m.group(1)
            if f not in seen:
                seen.add(f); out.append(go(f))
        elif not l.startswith('#version'):
            out.append(l)
    return ''.join(out)
print('#version 330 compatibility\n' + go(sys.argv[1]))
PY
  n=$((n+1))
  if ! out=$(glslangValidator -S $stage "$out_f" 2>&1); then echo "FAIL $f"; echo "$out" | grep -E 'ERROR' | head -5; fail=1; fi
done
[ $fail = 0 ] && echo "all $n programs OK"
rm -rf "$tmp"; exit $fail
