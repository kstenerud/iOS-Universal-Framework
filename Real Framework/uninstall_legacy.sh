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

SPECIFICATIONS_DIR="Developer/Library/Xcode/Specifications"

IOS_PATCH_FILE="$SCRIPT_DIR/legacy/iphone_specifications.diff"
SIM_PATCH_FILE="$SCRIPT_DIR/legacy/simulator_specifications.diff"
IOS_SPECIFICATIONS_PATH="Platforms/iPhoneOS.platform/$SPECIFICATIONS_DIR"
SIM_SPECIFICATIONS_PATH="Platforms/iPhoneSimulator.platform/$SPECIFICATIONS_DIR"

IOS_SPECIFICATIONS_DST_PATH="$GLOBAL_DEVELOPER_PATH/$IOS_SPECIFICATIONS_PATH"
SIM_SPECIFICATIONS_DST_PATH="$GLOBAL_DEVELOPER_PATH/$SIM_SPECIFICATIONS_PATH"


echo "iOS Real Static Framework Legacy Patch Uninstaller"
echo "=================================================="
echo
echo "This will remove any legacy Xcode patches on your computer."
echo
echo "Note: This script is only needed if you have installed the Real Static"
echo "      Framework templates using Mk 5 or earlier."
echo
echo "WARNING: Only run this script if you are upgrading from"
echo "         iOS-Universal-Framework Mk 5 or earlier!"
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


IOS_PATCHES_PRESENT=0
SIM_PATCHES_PRESENT=0
set +e

cd "$IOS_SPECIFICATIONS_DST_PATH"
patch --dry-run -p1 -b -R -N -s <"$IOS_PATCH_FILE" >/dev/null
if [ "$?" == "0" ]
then
echo present
    IOS_PATCHES_PRESENT=1
fi

cd "$SIM_SPECIFICATIONS_DST_PATH"
patch --dry-run -p1 -b -R -N -s <"$SIM_PATCH_FILE" >/dev/null
if [ "$?" == "0" ]
then
    SIM_PATCHES_PRESENT=1
fi

set -e

if [ "$IOS_PATCHES_PRESENT" == "0" ] && [ "$SIM_PATCHES_PRESENT" == "0" ]
then
    echo
    echo "Xcode install at $GLOBAL_DEVELOPER_PATH does not contain legacy specification data"
    exit 0
fi


# Last chance to back out
echo
echo "I am about to remove modifications from previous versions of iOS-Universal-Framework in:"
echo
if [ "$IOS_PATCHES_PRESENT" == "1" ]
then
    echo " * $IOS_SPECIFICATIONS_DST_PATH/iPhoneOSPackageTypes.xcspec"
    echo " * $IOS_SPECIFICATIONS_DST_PATH/iPhoneOSProductTypes.xcspec"
fi
if [ "$SIM_PATCHES_PRESENT" == "1" ]
then
    echo " * $SIM_SPECIFICATIONS_DST_PATH/iPhoneOSPackageTypes.xcspec"
    echo " * $SIM_SPECIFICATIONS_DST_PATH/iPhoneOSProductTypes.xcspec"
fi
echo

read -p "continue [y/N]: " answer
echo
if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
    echo
    echo "[ Cancelled ]"
    echo
    exit 1
fi


if [ ! -f "$IOS_SPECIFICATIONS_DST_PATH/iPhoneOSPackageTypes.xcspec.orig" ]
then
    echo "WARNING: Did not find .orig files in $IOS_SPECIFICATIONS_DST_PATH"
    echo "Are you SURE you installed an older version of iOS-Universal-Framework in $GLOBAL_DEVELOPER_PATH?"
    echo
    echo "If you've reinstalled Xcode, you don't need to run this script."
    echo
	read -p "Really continue [y/N]: " answer
	echo
	if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
		echo
		echo "[ Cancelled ]"
		echo
		exit 1
	fi
fi


# Restore files in Xcode
if [ "$IOS_PATCHES_PRESENT" == "1" ]
then
    echo
    echo "[ Removing legacy modifications from $IOS_SPECIFICATIONS_DST_PATH ]"
    echo
    echo cd "$IOS_SPECIFICATIONS_DST_PATH"
    cd "$IOS_SPECIFICATIONS_DST_PATH"
    echo "patch -p1 -b -R -N <$IOS_PATCH_FILE"
    patch -p1 -b -R -N <"$IOS_PATCH_FILE"
fi

if [ "$SIM_PATCHES_PRESENT" == "1" ]
then
    echo
    echo "[ Removing legacy modifications from $SIM_SPECIFICATIONS_DST_PATH ]"
    echo
    echo cd "$SIM_SPECIFICATIONS_DST_PATH"
    cd "$SIM_SPECIFICATIONS_DST_PATH"
    echo "patch -p1 -b -R -N <$SIM_PATCH_FILE"
    patch -p1 -b -R -N <"$SIM_PATCH_FILE"
fi


echo
echo
echo "Legacy Xcode modifications removed"
