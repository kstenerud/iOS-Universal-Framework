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

OLD_DEVELOPER_PATH="/Developer"
NEW_DEVELOPER_PATH="/Applications/Xcode.app/Contents/Developer"
LOCAL_DEVELOPER_PATH="$HOME/Library/Developer"

TEMPLATES_DIR="Templates/Framework & Library"
SPECIFICATIONS_DIR="Developer/Library/Xcode/Specifications"
SPECIFICATIONS_FILE="UFW-iOSStaticFramework.xcspec"
IOS_SPECIFICATIONS_PATH="Platforms/iPhoneOS.platform/$SPECIFICATIONS_DIR"
SIM_SPECIFICATIONS_PATH="Platforms/iPhoneSimulator.platform/$SPECIFICATIONS_DIR"

TEMPLATES_SRC_PATH="$SCRIPT_DIR/$TEMPLATES_DIR"
TEMPLATES_DST_PATH="$LOCAL_DEVELOPER_PATH/Xcode/$TEMPLATES_DIR"


echo "iOS Real Static Framework Installer"
echo "==================================="
echo
echo "This will install the iOS static framework templates and support files on your computer."
echo "Note: Real static frameworks require two xcspec files to be added to Xcode."
echo
echo "*** THIS SCRIPT WILL ADD THE FOLLOWING FILES TO XCODE ***"
echo
echo " * $IOS_SPECIFICATIONS_PATH/$SPECIFICATIONS_FILE"
echo " * $SIM_SPECIFICATIONS_PATH/$SPECIFICATIONS_FILE"
echo


# Get the install path
if [ -d "$NEW_DEVELOPER_PATH" ]
then
    DEFAULT_GLOBAL_DEVELOPER_PATH="$NEW_DEVELOPER_PATH"
else
    DEFAULT_GLOBAL_DEVELOPER_PATH="$OLD_DEVELOPER_PATH"
fi

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
        echo "Could not find Xcode files in \"$GLOBAL_DEVELOPER_PATH\". Please make sure you typed it correctly."
        echo "You should see the path \"$IOS_SPECIFICATIONS_PATH\" inside of it."
        echo
        GLOBAL_DEVELOPER_PATH=
    fi
done

IOS_SPECIFICATIONS_DST_PATH="$GLOBAL_DEVELOPER_PATH/$IOS_SPECIFICATIONS_PATH"
SIM_SPECIFICATIONS_DST_PATH="$GLOBAL_DEVELOPER_PATH/$SIM_SPECIFICATIONS_PATH"

# Last chance to back out
echo
echo "I am about add the following files to support real static iOS frameworks:"
echo
echo " * $IOS_SPECIFICATIONS_DST_PATH/$SPECIFICATIONS_FILE"
echo " * $SIM_SPECIFICATIONS_DST_PATH/$SPECIFICATIONS_FILE"
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


echo
echo "[ Installing xcspec file ]"
echo
echo sudo cp "$SCRIPT_DIR/$SPECIFICATIONS_FILE" "$IOS_SPECIFICATIONS_DST_PATH/"
sudo cp "$SCRIPT_DIR/$SPECIFICATIONS_FILE" "$IOS_SPECIFICATIONS_DST_PATH/"
echo sudo cp "$SCRIPT_DIR/$SPECIFICATIONS_FILE" "$SIM_SPECIFICATIONS_DST_PATH/"
sudo cp "$SCRIPT_DIR/$SPECIFICATIONS_FILE" "$SIM_SPECIFICATIONS_DST_PATH/"


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
