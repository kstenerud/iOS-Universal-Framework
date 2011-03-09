#!/bin/sh

##############################################################################
#
# Universal Framework Builder for iOS
#
# By Karl Stenerud
#
#
# This script combines frameworks from multiple platforms into a single,
# "static library" universal framework.
#
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


show_help()
{
    echo >&2 "Usage: $0 [OPTIONS] <Framework Target>"
    echo >&2 "Options:"
    echo >&2 "    -h or -?: This help text"
    echo >&2 "    -p <platforms>: Platforms to build"
    echo >&2 "    -c <configurations>: Configurations to build"
    echo >&2 "    -a <action>: One of: build, clean, rebuild (or \"clean build\")"
    echo >&2
    echo >&2 "The default is equivalent to: -p \"iphoneos iphonesimulator\" -c \"Debug Release\" -a build"
}


# Defaults

# Default platforms to build for (all will be combined into a universal framework)
UFW_PLATFORMS="iphoneos iphonesimulator"

# Default configurations build (builds one universal framework per configuration)
UFW_CONFIGURATIONS="Debug Release"

# Default build action
UFW_ACTION="build"

# Default build dir
UFW_BUILD_DIR="./build"


# Get arguments
OPTIND=1
while getopts "h?a:c:p:" opt; do
  case "$opt" in
    h|\?) show_help; exit 0;;
    a) UFW_ACTION="$OPTARG";;
    c) UFW_CONFIGURATIONS="$OPTARG";;
    p) UFW_PLATFORMS="$OPTARG";;
  esac
done
shift $((OPTIND-1))
if [ "$1" = -- ]; then shift; fi

case "${UFW_ACTION}" in
    build) ;;
    clean) ;;
    "clean build") ;;
    rebuild) UFW_ACTION="clean build";;
    *)
        echo >&2 "${UFW_ACTION}: Unknown action"
        show_help
        exit 1;;
esac

if [ $# != 1 ]; then
    show_help
    exit 1
fi

UFW_TARGET=$1


# Global vars

if [ ! -z ${BUILD_DIR} ]; then
    # Use the build dir specified by XCode
    UFW_BUILD_DIR="${BUILD_DIR}"
fi

if [ -z ${SDK_NAME} ]; then
    # Use the latest iphoneos SDK available
    UFW_GREP_RESULT=$(xcodebuild -showsdks | grep -o "iphoneos.*$")
    while read -r line; do
        UFW_SDK_VERSION="${line}"
    done <<< "${UFW_GREP_RESULT}"
else
    # Use the SDK specified by XCode
    UFW_SDK_VERSION="${SDK_NAME}"
fi

UFW_SDK_VERSION=$(echo "${UFW_SDK_VERSION}" | grep -o "[0-9].*$")
UFW_EXE_FOLDER_PATH="${UFW_TARGET}.framework"
UFW_EXE_PATH="${UFW_EXE_FOLDER_PATH}/${UFW_TARGET}"


# Setup is complete. Time to start doing something useful
echo "${UFW_ACTION} Universal ${UFW_EXE_FOLDER_PATH}"


# Always delete the universal framework dirs to start out clean
for configuration in ${UFW_CONFIGURATIONS}; do
	rm -rf "${UFW_BUILD_DIR}/${configuration}-universal"
done

# Run for all selected configurations
for configuration in ${UFW_CONFIGURATIONS}; do
	for platform in ${UFW_PLATFORMS}; do
		xcodebuild -sdk "${platform}${UFW_SDK_VERSION}" -configuration "${configuration}" -target "${UFW_TARGET}" ${UFW_ACTION}
		if [ "$?" != "0" ]; then echo >&2 "Error: xcodebuild failed"; exit 1; fi
	done

    # Unless we are only cleaning, build out the universal framework
	if [ "${UFW_ACTION}" != "clean" ]; then
		# Copy the iphone framework as a basis for the universal framework
		UFW_BUILT_FW_DIR="${UFW_BUILD_DIR}/${configuration}-${UFW_PLATFORMS%% *}"
		UFW_UNIVERSAL_DIR="${UFW_BUILD_DIR}/${configuration}-universal"

		mkdir -p "${UFW_UNIVERSAL_DIR}"
		if [ "$?" != "0" ]; then echo >&2 "Error: mkdir failed"; exit 1; fi
		cp -a "${UFW_BUILT_FW_DIR}/${UFW_EXE_FOLDER_PATH}" "${UFW_UNIVERSAL_DIR}/${UFW_EXE_FOLDER_PATH}"
		if [ "$?" != "0" ]; then echo >&2 "Error: cp failed"; exit 1; fi

		# Replace the copied iphone library with a combined universal library
		unset UFW_EXE_PATHS
		declare -a UFW_EXE_PATHS
		for platform in ${UFW_PLATFORMS}; do
			UFW_EXE_PATHS+=("${UFW_BUILD_DIR}/${configuration}-${platform}/${UFW_EXE_PATH}")
		done

		echo "Combining ${UFW_EXE_PATHS[@]} into ${UFW_UNIVERSAL_DIR}/${UFW_EXE_PATH}"
		lipo -create -output "${UFW_UNIVERSAL_DIR}/${UFW_EXE_PATH}" "${UFW_EXE_PATHS[@]}"
		if [ "$?" != "0" ]; then echo >&2 "Error: lipo failed"; exit 1; fi
	fi
done

if [ "${UFW_ACTION}" = "clean" ]; then
    echo "Frameworks for \"${UFW_TARGET}\" cleaned for configuration(s): ${UFW_CONFIGURATIONS}"
else
    echo "Universal framework \"${UFW_TARGET}\" (${UFW_PLATFORMS}) successfully built for configuration(s): ${UFW_CONFIGURATIONS}"
fi

exit 0

