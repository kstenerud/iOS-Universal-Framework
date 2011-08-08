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

DEFAULT_GLOBAL_DEVELOPER_PATH="/Developer"
GLOBAL_DEVELOPER_PATH="$DEFAULT_GLOBAL_DEVELOPER_PATH"
LOCAL_DEVELOPER_PATH="$HOME/Library/Developer"

TEMPLATES_DIR="Templates/Framework & Library"
SPECIFICATIONS_DIR="Developer/Library/Xcode/Specifications"
SPECIFICATIONS_FILE="UFW-iOSStaticFramework.xcspec"

TEMPLATES_SRC_PATH="$SCRIPT_DIR/$TEMPLATES_DIR"
TEMPLATES_DST_PATH="$LOCAL_DEVELOPER_PATH/Xcode/$TEMPLATES_DIR"

IOS_SPECIFICATIONS_PATH="Platforms/iPhoneOS.platform/$SPECIFICATIONS_DIR"
SIM_SPECIFICATIONS_PATH="Platforms/iPhoneSimulator.platform/$SPECIFICATIONS_DIR"


echo "iOS Real Static Framework Uninstaller"
echo "====================================="
echo
echo "This will UNINSTALL the iOS static framework templates and support files on your computer."
echo


# Get the install path
GLOBAL_DEVELOPER_PATH=
while [ "$GLOBAL_DEVELOPER_PATH" == "" ]
do
    read -p "Where is Xcode installed? (CTRL-C to abort) [ $DEFAULT_GLOBAL_DEVELOPER_PATH ]: " GLOBAL_DEVELOPER_PATH
    if [ "$GLOBAL_DEVELOPER_PATH" == "" ]
    then
        GLOBAL_DEVELOPER_PATH="$DEFAULT_GLOBAL_DEVELOPER_PATH"
    fi

    # Just in case ;-)
    if [ "$GLOBAL_DEVELOPER_PATH" == "CTRL-C" ] || [ "$GLOBAL_DEVELOPER_PATH" == "ctrl-c" ]
    then
        echo
        echo "[ Cancelled ]"
        echo
        exit 1
    fi

    if [ ! -d "${GLOBAL_DEVELOPER_PATH}/${IOS_SPECIFICATIONS_PATH}" ] || [ ! -d "${GLOBAL_DEVELOPER_PATH}/${SIM_SPECIFICATIONS_PATH}" ]
    then
        echo "Could not find Xcode files in $GLOBAL_DEVELOPER_PATH. Please make sure you typed it correctly."
        echo "You should see the path \"$IOS_SPECIFICATIONS_PATH\" inside of it."
        echo
        GLOBAL_DEVELOPER_PATH=
    fi
done

IOS_SPECIFICATIONS_DST_PATH="$GLOBAL_DEVELOPER_PATH/$IOS_SPECIFICATIONS_PATH"
SIM_SPECIFICATIONS_DST_PATH="$GLOBAL_DEVELOPER_PATH/$SIM_SPECIFICATIONS_PATH"


# Last chance to back out
echo
echo "I am about to remove the following custom specifications (these are not part of the original Xcode install):"
echo
echo " * $IOS_SPECIFICATIONS_DST_PATH/$SPECIFICATIONS_FILE"
echo " * $SIM_SPECIFICATIONS_DST_PATH/$SPECIFICATIONS_FILE"
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
echo rm -f "$IOS_SPECIFICATIONS_DST_PATH/$SPECIFICATIONS_FILE"
rm -f "$IOS_SPECIFICATIONS_DST_PATH/$SPECIFICATIONS_FILE"
echo rm -f "$SIM_SPECIFICATIONS_DST_PATH/$SPECIFICATIONS_FILE"
rm -f "$SIM_SPECIFICATIONS_DST_PATH/$SPECIFICATIONS_FILE"


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
