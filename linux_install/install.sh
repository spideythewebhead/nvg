#!/bin/bash

RED='\033[0;31m'
NC='\033[0m'

DIR=$(dirname "$BASH_SOURCE")

if [[ "$DIR" != "." ]]; then
	echo "Changing directory $DIR ✓"
	cd "$DIR"
fi

echo "Setting correct paths ✓"
cp nvg_original.desktop nvg.desktop
sed -i'' "s|HOME|$HOME|g" nvg.desktop
sed -i'' "s|CWD|$PWD|g" nvg.desktop

echo "Installing desktop entry ✓"
mv nvg.desktop ~/.local/share/applications/

echo -e "\n\nNote: ${RED}if you change the folder location re-run this script${NC}"
