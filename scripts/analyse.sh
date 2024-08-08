#!/bin/sh

set -e

curl -O https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua
rojo sourcemap default.project.json -o sourcemap.json

luau-lsp analyze --definitions=globalTypes.d.lua --base-luaurc=.luaurc \
    --sourcemap=sourcemap.json --settings=.vscode/settings.json \
    --no-strict-dm-types --ignore src/base.luau \
    src/
