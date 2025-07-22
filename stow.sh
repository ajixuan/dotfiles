#!/bin/bash

# write the local ignore file
cat <<EOF > .stow-local-ignore
.git
alis
README.md
build_env
ajichangelog.md
todo.md
windows.sh
EOF

# stow all
stow ./nix
stow ./vim
stow .tmux.conf
stow ./config


