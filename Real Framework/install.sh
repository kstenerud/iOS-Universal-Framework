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


echo "iOS Real Static Framework Installer"
echo "==================================="
echo
echo "This will install the iOS static framework templates and support files on your computer."
echo
echo "The templates will be installed in $TEMPLATES_DST_PATH"
echo
echo "The xcspec file will be installed in $SPECIFICATIONS_DIR"
echo


read -p "continue [y/N]: " answer
echo
if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
    echo
    echo "[ Cancelled ]"
    echo
    exit 1
fi


echo
echo "[ Installing xcspec file ]"
echo
echo mkdir -p "$SPECIFICATIONS_DIR"
mkdir -p "$SPECIFICATIONS_DIR"
echo cp "$SCRIPT_DIR/$SPECIFICATIONS_FILE" "$SPECIFICATIONS_DIR/"
cp "$SCRIPT_DIR/$SPECIFICATIONS_FILE" "$SPECIFICATIONS_DIR/"


# Install templates
echo
echo "[ Installing templates ]"
echo
echo mkdir -p "$TEMPLATES_DST_PATH"
mkdir -p "$TEMPLATES_DST_PATH"
cd "$TEMPLATES_SRC_PATH"
for template in *; do
	installpath="$TEMPLATES_DST_PATH/$template"
    echo rm -rf "$installpath"
    rm -rf "$installpath"
    echo cp -R "$template" "$installpath"
    cp -R "$template" "$installpath"
done

# Remove old version of unit test framework
rm -rf "$TEMPLATES_DST_PATH/Static iOS Framework Test.xctemplate"


echo
echo
echo "[ Installation complete. Please restart Xcode. ]"
echo
