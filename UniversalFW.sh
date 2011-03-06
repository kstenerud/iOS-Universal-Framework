##############################################################################
#
# Make Universal Framework
#
# By Karl Stenerud
#
# This script generates a universal (iOS + simulator) static framework from
# existing iOS and simulator framework builds within a project, for both
# Debug and Release configurations.
#
# License:
#
# Use it any way you want.
# This work is provided on an "AS-IS" basis, without warranties or conditions
# of any kind.
# By using this work you agree that you and you alone are responsible for any
# and all damages resulting from the use of this work.
#
##############################################################################


# Get arguments
if [ $# -ne 2 ]; then
    echo >&2 "Usage: $0 <build | clean | rebuild> <Target>"
    exit 1
fi

UFW_DO_CLEAN=0
UFW_DO_BUILD=0
UFW_TASK="Unknown"
case "$1" in
    build)
        UFW_TASK="Build"
        UFW_DO_CLEAN=0
        UFW_DO_BUILD=1;;
    clean)
        UFW_TASK="Clean"
        UFW_DO_CLEAN=1
        UFW_DO_BUILD=0;;
    rebuild)
        UFW_TASK="Rebuild"
        UFW_DO_CLEAN=1
        UFW_DO_BUILD=1;;
    *)
        echo >&2 "Usage: $0 <build | clean | rebuild> <Target>"
        exit 1;;
esac

UFW_TARGET=$2


# Global vars
UFW_SDK_VERSION=$(echo "${SDK_NAME}" | grep -o "[0-9].*$")
UFW_EXE_FOLDER_PATH="${UFW_TARGET}.framework"
UFW_EXE_PATH="${UFW_EXE_FOLDER_PATH}/${UFW_TARGET}"


echo "${UFW_TASK} Universal ${UFW_EXE_FOLDER_PATH}"


# Always delete the universal framework dir
rm -rf "${BUILD_DIR}/Debug-universal"
rm -rf "${BUILD_DIR}/Release-universal"


# Clean all targets
if [ ${UFW_DO_CLEAN} -eq 1 ]; then
    for UFW_CONFIG in Debug Release; do
        for UFW_PLATFORM in iphoneos iphonesimulator; do
            xcodebuild -sdk "${UFW_PLATFORM}${UFW_SDK_VERSION}" -configuration "${UFW_CONFIG}" -target "${UFW_TARGET}" clean
            if [ "$?" != "0" ]; then echo >&2 "xcodebuild failed"; exit 1; fi
        done
    done
fi


# Build all targets
if [ ${UFW_DO_BUILD} -eq 1 ]; then
    for UFW_CONFIG in Debug Release; do
        # Build the framework for all platforms.
        for UFW_PLATFORM in iphoneos iphonesimulator; do
            xcodebuild -sdk "${UFW_PLATFORM}${UFW_SDK_VERSION}" -configuration "${UFW_CONFIG}" -target "${UFW_TARGET}" build
            if [ "$?" != "0" ]; then echo >&2 "xcodebuild failed"; exit 1; fi
        done

        UFW_DEVICE_DIR="${BUILD_DIR}/${UFW_CONFIG}-iphoneos"
        UFW_SIMULATOR_DIR="${BUILD_DIR}/${UFW_CONFIG}-iphonesimulator"
        UFW_UNIVERSAL_DIR="${BUILD_DIR}/${UFW_CONFIG}-universal"

        # Copy the framework dir from the iphone build.
        mkdir -p "${UFW_UNIVERSAL_DIR}"
        if [ "$?" != "0" ]; then echo >&2 "mkdir failed"; exit 1; fi
        cp -a "${UFW_DEVICE_DIR}/${UFW_EXE_FOLDER_PATH}" "${UFW_UNIVERSAL_DIR}/${UFW_EXE_FOLDER_PATH}"
        if [ "$?" != "0" ]; then echo >&2 "cp failed"; exit 1; fi

        # Create the universal library over top of the copied one.
        lipo -create -output "${UFW_UNIVERSAL_DIR}/${UFW_EXE_PATH}" "${UFW_DEVICE_DIR}/${UFW_EXE_PATH}" "${UFW_SIMULATOR_DIR}/${UFW_EXE_PATH}"
        if [ "$?" != "0" ]; then echo >&2 "lipo failed"; exit 1; fi
    done
fi

exit 0

