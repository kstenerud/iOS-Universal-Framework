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

DEFAULT_GLOBAL_DEVELOPER_PATH="/Developer"
GLOBAL_DEVELOPER_PATH="$DEFAULT_GLOBAL_DEVELOPER_PATH"
LOCAL_DEVELOPER_PATH="$HOME/Library/Developer"

TEMPLATES_DIR="Templates/Framework & Library"
SPECIFICATIONS_DIR="Developer/Library/Xcode/Specifications"

TEMPLATES_SRC_PATH="$SCRIPT_DIR/$TEMPLATES_DIR"
TEMPLATES_DST_PATH="$LOCAL_DEVELOPER_PATH/Xcode/$TEMPLATES_DIR"
IOS_SPECIFICATIONS_PATH="Platforms/iPhoneOS.platform/$SPECIFICATIONS_DIR"
SIM_SPECIFICATIONS_PATH="Platforms/iPhoneSimulator.platform/$SPECIFICATIONS_DIR"
IOS_PATCH_FILE="$SCRIPT_DIR/iphone_specifications.diff"
SIM_PATCH_FILE="$SCRIPT_DIR/simulator_specifications.diff"


echo "iOS Real Static Framework Installer"
echo "==================================="
echo
echo "This will install the iOS static framework templates and support files on your computer."
echo "Note: Real static frameworks require modifications to Xcode."
echo
echo "*** THIS SCRIPT WILL MODIFY THE FOLLOWING FILES INSIDE XCODE ***"
echo
echo " * $IOS_SPECIFICATIONS_PATH/iPhoneOSPackageTypes.xcspec"
echo " * $IOS_SPECIFICATIONS_PATH/iPhoneOSProductTypes.xcspec"
echo " * $SIM_SPECIFICATIONS_PATH/iPhoneOSPackageTypes.xcspec"
echo " * $SIM_SPECIFICATIONS_PATH/iPhoneOSProductTypes.xcspec"
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
echo "I am about to modify the following files to support real static iOS frameworks (originals will be backed up as <filename>.orig):"
echo
echo " * $IOS_SPECIFICATIONS_DST_PATH/iPhoneOSPackageTypes.xcspec"
echo " * $IOS_SPECIFICATIONS_DST_PATH/iPhoneOSProductTypes.xcspec"
echo " * $SIM_SPECIFICATIONS_DST_PATH/iPhoneOSPackageTypes.xcspec"
echo " * $SIM_SPECIFICATIONS_DST_PATH/iPhoneOSProductTypes.xcspec"
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


# Sanity check
echo
echo "[ Testing patches (dry run) to make sure they will succeed ]"
echo
cd "$IOS_SPECIFICATIONS_DST_PATH"
set +e
patch --dry-run -p1 -b -N -s <"$IOS_PATCH_FILE"
if [ "$?" != "0" ]
then
	echo
	echo >&2 "NOT MODIFIED: Could not apply patches in $IOS_PATCH_FILE to $IOS_SPECIFICATIONS_DST_PATH. Have they already been applied?"
	echo
	echo
	echo >&2 "[ ABORTING INSTALL ]"
	echo
	exit 1
fi
set -e

cd "$SIM_SPECIFICATIONS_DST_PATH"
set +e
patch --dry-run -p1 -b -N -s <"$SIM_PATCH_FILE"
if [ "$?" != "0" ]
then
	echo
	echo >&2 "NOT MODIFIED: Could not apply patches in $SIM_PATCH_FILE to $SIM_SPECIFICATIONS_DST_PATH. Have they already been applied?"
	echo
	echo
	echo >&2 "[ ABORTING INSTALL ]"
	echo
	exit 1
fi
set -e

echo "Patches verified."
echo


# Modify Xcode
echo
echo "[ Backing up and replacing iOS specification files in Xcode ]"
echo
echo cd "$IOS_SPECIFICATIONS_DST_PATH"
cd "$IOS_SPECIFICATIONS_DST_PATH"
echo "patch -p1 -b -N <$IOS_PATCH_FILE"
patch -p1 -b -N <"$IOS_PATCH_FILE"
echo

echo
echo "[ Backing up and replacing Simulator specification files in Xcode ]"
echo
echo cd "$SIM_SPECIFICATIONS_DST_PATH"
cd "$SIM_SPECIFICATIONS_DST_PATH"
echo "patch -p1 -b -N <$SIM_PATCH_FILE"
patch -p1 -b -N <"$SIM_PATCH_FILE"
echo


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

# Remove old version of unit test framework
rm -rf "$TEMPLATES_DST_PATH/Static iOS Framework Test.xctemplate"


echo
echo
echo "[ Installation complete ]"
echo
