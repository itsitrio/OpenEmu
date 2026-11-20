#!/bin/bash
# Local fixes for upstream submodules that can't be committed from this repo.
# Run from anywhere after `git submodule update --init --recursive`.
# Safe to run more than once.
set -euo pipefail
cd "$(dirname "$0")/.."

# OpenEmu-Shaders pins ZIPFoundation to its `development` branch, which no
# longer exists upstream (only `main` and tagged releases remain), so Swift
# package resolution fails for the whole workspace. Pin it to 0.9.x instead,
# matching the OpenEmu app target.
shaders=OpenEmu-Shaders/OpenEmuShaders.xcodeproj/project.pbxproj
if grep -q 'branch = development;' "$shaders"; then
    perl -0pi -e 's|(weichsel/ZIPFoundation";\n\t+requirement = \{\n)\t+branch = development;\n\t+kind = branch;\n|$1\t\t\t\tkind = upToNextMinorVersion;\n\t\t\t\tminimumVersion = 0.9.0;\n|' "$shaders"
    echo "Patched ZIPFoundation requirement in $shaders"
else
    echo "ZIPFoundation requirement in $shaders already patched"
fi
