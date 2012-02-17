#!/bin/bash

set -u
set -e

# Assume this script was called normally and hasn't been added to the path or symlinked
SCRIPT_DIR=$(dirname "$0")
if [[ $SCRIPT_DIR != /* ]]; then
    if [[ $SCRIPT_DIR == "." ]]; then
        SCRIPT_DIR=$PWD
    else
        SCRIPT_DIR=$PWD/$SCRIPT_DIR
    fi
fi

LOCAL_DEVELOPER_PATH="$HOME/Library/Developer"

TEMPLATES_DIR="Templates/Framework & Library"
SPECIFICATIONS_DIR="$HOME/Library/Application Support/Developer/Shared/Xcode/Specifications"
SPECIFICATIONS_FILE="UFW-iOSStaticFramework.xcspec"

TEMPLATES_SRC_PATH="$SCRIPT_DIR/$TEMPLATES_DIR"
TEMPLATES_DST_PATH="$LOCAL_DEVELOPER_PATH/Xcode/$TEMPLATES_DIR"


echo "iOS Real Static Framework Uninstaller"
echo "====================================="
echo
echo "This will UNINSTALL the iOS static framework templates and support files on your computer."
echo


read -p "continue [y/N]: " answer
echo
if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
    echo
    echo "[ Cancelled ]"
    echo
    exit 1
fi


# Remove spec files
echo
echo "[ Removing custom specification files ]"
echo
echo rm -f "$SPECIFICATIONS_DIR/$SPECIFICATIONS_FILE"
rm -f "$SPECIFICATIONS_DIR/$SPECIFICATIONS_FILE"


# Remove templates
echo
echo "[ Removing templates in $TEMPLATES_DST_PATH ]"
echo
cd "$TEMPLATES_SRC_PATH"
for template in *; do
	installpath="$TEMPLATES_DST_PATH/$template"
    echo rm -rf "$installpath"
    rm -rf "$installpath"
done
echo


echo
echo "[ Uninstall complete. Please restart Xcode. ]"
echo
