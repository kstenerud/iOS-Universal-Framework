#!/bin/sh

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


echo "iOS Static Framework Uninstaller"
echo "================================"
echo
echo "This will UNINSTALL the iOS static framework templates and support files on your computer."
echo "continue [y/N]"

read answer
if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
    echo Cancelled.
    exit 0
fi


echo "[ Removing templates in $TEMPLATES_DST_PATH ]"
cd "$ORIG_DIR"
if [ "$?" != "0" ]; then echo >&2 "Error: Could not change directory to $ORIG_DIR"; exit 1; fi
cd "$TEMPLATES_SRC_PATH"
if [ "$?" != "0" ]; then echo >&2 "Error: Could not change directory to $TEMPLATES_SRC_PATH"; exit 1; fi
for template in *; do
	installpath=$TEMPLATES_DST_PATH/$template
    echo rm -rf "$installpath"
    rm -rf "$installpath"
done


echo
echo "Uninstall complete"
