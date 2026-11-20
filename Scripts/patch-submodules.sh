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

# Xcode 27 only supports macOS deployment targets of 12.0 and later, but the
# core and framework submodules target 10.11-11.x. Raise anything older than
# 12.0 to 12.0 in every Xcode project and xcconfig in the workspace,
# including optional cores (UME, PPSSPP) cloned outside of git submodules.
count=0
while IFS= read -r -d '' f; do
    if grep -Eq 'MACOSX_DEPLOYMENT_TARGET[[:space:]]*=[[:space:]]*"?(10|11)\.' "$f"; then
        perl -pi -e 's/(MACOSX_DEPLOYMENT_TARGET\s*=\s*)"?(?:10|11)\.\d+(?:\.\d+)?"?/${1}12.0/g' "$f"
        count=$((count + 1))
    fi
done < <(find . \( -path ./build -o -path '*/DerivedData' -o -path ./.git \) -prune -o \
              \( -name project.pbxproj -o -name '*.xcconfig' \) -print0)
echo "Raised deployment target to macOS 12.0 in $count file(s)"
