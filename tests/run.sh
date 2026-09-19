#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
luac5.1 -p Core.lua
lua5.1 tests/runtime.lua
bash -n tools/deploy.sh
pwsh -NoProfile -Command '$null = [scriptblock]::Create((Get-Content -LiteralPath "tools/windows/Deploy-SimpleBagMover.ps1" -Raw))'
python3 - <<'PY'
from pathlib import Path
p = Path('SimpleBagMover_Camelot.toc')
s = p.read_text()
assert '## Interface: 16001' in s
assert '## Version: 0.1.3' in s
assert '## SavedVariablesPerCharacter: SimpleBagMoverDB, MoveBagsDB' in s
assert '## X-Curse-Project-ID: 1702845' in s
assert '## X-Flavor: Forever' in s
assert '## AllowLoadGameType: camelot' in s
assert '## IconTexture: Interface\\AddOns\\SimpleBagMover\\assets\\addon-icon.tga' in s
for line in s.splitlines():
    if line and not line.startswith('#'):
        assert Path(line).is_file(), line
print('PASS: TOC and runtime files')
PY

file assets/addon-icon.tga | grep -Fq '256 x 256 x 32'
