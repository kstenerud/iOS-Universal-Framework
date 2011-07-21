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

IOS_PATCH_FILE="$SCRIPT_DIR/iphone_specifications.diff"
SIM_PATCH_FILE="$SCRIPT_DIR/simulator_specifications.diff"
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
echo "I am about to restore the following files to their original state:"
echo
echo " * $IOS_SPECIFICATIONS_DST_PATH/iPhoneOSPackageTypes.xcspec"
echo " * $IOS_SPECIFICATIONS_DST_PATH/iPhoneOSProductTypes.xcspec"
echo " * $SIM_SPECIFICATIONS_DST_PATH/iPhoneOSPackageTypes.xcspec"
echo " * $SIM_SPECIFICATIONS_DST_PATH/iPhoneOSProductTypes.xcspec"
echo
echo "The templates will be removed from $TEMPLATES_DST_PATH"
echo

read -p "continue [y/N]: " answer
echo
if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
    echo
    echo "[ Cancelled ]"
    echo
    exit 1
fi


# Restore files in Xcode
echo
echo "[ Restoring original iOS specification files in Xcode ]"
echo
cd "$IOS_SPECIFICATIONS_DST_PATH"
set +e
patch --dry-run -p1 -b -R -N -s <"$IOS_PATCH_FILE"
if [ "$?" != "0" ]
then
	echo
	echo >&2 "NOT MODIFIED: Could not remove patches in $IOS_PATCH_FILE from $IOS_SPECIFICATIONS_DST_PATH. Have they already been removed?"
else
    set -e
    echo cd "$IOS_SPECIFICATIONS_DST_PATH"
    cd "$IOS_SPECIFICATIONS_DST_PATH"
    echo "patch -p1 -b -R -N <$IOS_PATCH_FILE"
    patch -p1 -b -R -N <"$IOS_PATCH_FILE"
fi
echo
set -e

echo
echo "[ Restoring original Simulator specification files in Xcode ]"
echo
cd "$SIM_SPECIFICATIONS_DST_PATH"
set +e
patch --dry-run -p1 -b -R -N -s <"$SIM_PATCH_FILE"
if [ "$?" != "0" ]
then
	echo
	echo >&2 "NOT MODIFIED: Could not remove patches in $SIM_PATCH_FILE from $SIM_SPECIFICATIONS_DST_PATH. Have they already been removed?"
else
    set -e
    echo cd "$SIM_SPECIFICATIONS_DST_PATH"
    cd "$SIM_SPECIFICATIONS_DST_PATH"
    echo "patch -p1 -b -R -N <$SIM_PATCH_FILE"
    patch -p1 -b -R -N <"$SIM_PATCH_FILE"
fi
echo
set -e


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
