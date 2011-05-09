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

GLOBAL_DEVELOPER_PATH="/Developer"
LOCAL_DEVELOPER_PATH="$HOME/Library/Developer"

TEMPLATES_DIR="Templates/Framework & Library"
SPECIFICATIONS_DIR="Developer/Library/Xcode/Specifications"

TEMPLATES_SRC_PATH="$SCRIPT_DIR/$TEMPLATES_DIR"
TEMPLATES_DST_PATH="$LOCAL_DEVELOPER_PATH/Xcode/$TEMPLATES_DIR"
IOS_SPECIFICATIONS_DST_PATH="$GLOBAL_DEVELOPER_PATH/Platforms/iPhoneOS.platform/$SPECIFICATIONS_DIR"
SIM_SPECIFICATIONS_DST_PATH="$GLOBAL_DEVELOPER_PATH/Platforms/iPhoneSimulator.platform/$SPECIFICATIONS_DIR"
REJECTS_FILE="$SCRIPT_DIR/.rejects.deleteme"


echo "iOS Static Framework Installer"
echo "=============================="
echo
echo "This will install the iOS static framework templates and support files on your computer."
echo "continue [y/N]"

read answer
if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
    echo Cancelled.
    exit 0
fi


echo
echo "[ Backing up and replacing iOS specification files in Xcode ]"
echo cd "$IOS_SPECIFICATIONS_DST_PATH"
cd "$IOS_SPECIFICATIONS_DST_PATH"
if [ "$?" != "0" ]; then echo >&2 "Error: Could not change directory to $IOS_SPECIFICATIONS_DST_PATH"; exit 1; fi
echo "patch -p1 -b -N <$SCRIPT_DIR/iphone_specifications.diff"
patch -p1 -b -N -r "$REJECTS_FILE" <"$SCRIPT_DIR/iphone_specifications.diff"
if [ "$?" != "0" ]; then echo >&2 "Error: Patch failed. Please uninstall first before reinstalling templates"; exit 1; fi

echo
echo "[ Backing up and replacing Simulator specification files in Xcode ]"
echo cd "$SIM_SPECIFICATIONS_DST_PATH"
cd "$SIM_SPECIFICATIONS_DST_PATH"
if [ "$?" != "0" ]; then echo >&2 "Error: Could not change directory to $SIM_SPECIFICATIONS_DST_PATH"; exit 1; fi
echo "patch -p1 -b -N <$SCRIPT_DIR/simulator_specifications.diff"
patch -p1 -b -N -r "$REJECTS_FILE" <"$SCRIPT_DIR/simulator_specifications.diff"
if [ "$?" != "0" ]; then echo >&2 "Error: Patch failed. Please uninstall first before reinstalling templates"; exit 1; fi


echo
echo "[ Installing templates into $TEMPLATES_DST_PATH ]"
echo mkdir -p "$TEMPLATES_DST_PATH"
mkdir -p "$TEMPLATES_DST_PATH"
if [ "$?" != "0" ]; then echo >&2 "Error: mkdir failed"; exit 1; fi
cd "$TEMPLATES_SRC_PATH"
if [ "$?" != "0" ]; then echo >&2 "Error: Could not change directory to $TEMPLATES_SRC_PATH"; exit 1; fi
for template in *; do
	installpath=$TEMPLATES_DST_PATH/$template
    echo rm -rf "$installpath"
    rm -rf "$installpath"
    echo cp -R "$template" "$installpath"
    cp -R "$template" "$installpath"
    if [ "$?" != "0" ]; then echo >&2 "Error: copy failed"; exit 1; fi
done

# Remove old version of unit test framework
rm -rf "$TEMPLATES_DST_PATH/Static iOS Framework Test.xctemplate"

rm -f "$REJECTS_FILE"


echo
echo "Install complete"
