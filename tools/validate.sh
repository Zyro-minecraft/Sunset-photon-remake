#!/usr/bin/env bash
# Inline Iris-style "/lib/..." includes and compile every program with glslangValidator.
set -u
cd "$(dirname "$0")/../shaders"
tmp=$(mktemp -d); fail=0
for f in *.vsh *.fsh; do
  stage=vert; [[ $f == *.fsh ]] && stage=frag
  python3 -I - "$f" > "$tmp/$f" <<'PY'
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
body = go(sys.argv[1])
print('#version 330 compatibility\n#define RGBA16F 1\n#define RGB16 2\n#line 1')
print(body)
PY
  if out=$(glslangValidator -S $stage "$tmp/$f" 2>&1); then echo "OK   $f"; else echo "FAIL $f"; echo "$out" | grep -E 'ERROR|WARN'; fail=1; fi
done
rm -rf "$tmp"; exit $fail
