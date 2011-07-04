#!/bin/bash

set -u
set -e

# Assume this script was called normally and hasn't been added to the path or symlinked
SCRIPT_DIR=$(dirname $0)
if [[ $SCRIPT_DIR != /* ]]; then
    if [[ $SCRIPT_DIR == "." ]]; then
        SCRIPT_DIR=$PWD
    else
        SCRIPT_DIR=$PWD/$SCRIPT_DIR
    fi
fi

LOCAL_DEVELOPER_PATH="$HOME/Library/Developer"

TEMPLATES_DIR="Templates/Framework & Library"
SPECIFICATIONS_DIR="Developer/Library/Xcode/Specifications"

TEMPLATES_SRC_PATH="$SCRIPT_DIR/$TEMPLATES_DIR"
TEMPLATES_DST_PATH="$LOCAL_DEVELOPER_PATH/Xcode/$TEMPLATES_DIR"


# Last chance to back out
echo "iOS Fake Static Framework Installer"
echo "==================================="
echo
echo "This will install the fake iOS static framework templates on your computer."
echo
echo "The templates will be installed in $TEMPLATES_DST_PATH"
echo

read -p "continue [y/N]: " answer
echo
if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
    echo
    echo "[ Cancelled ]"
    echo
    exit 1
fi


# Install templates
echo
echo "[ Installing templates into $TEMPLATES_DST_PATH ]"
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
echo

# Remove old version of unit test framework
rm -rf "$TEMPLATES_DST_PATH/Static iOS Framework Test.xctemplate"


echo
echo "[ Installation complete ]"
echo
