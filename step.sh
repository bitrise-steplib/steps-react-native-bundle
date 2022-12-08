#!/bin/bash

set -e

#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
	key=$1
	value=$2
	if [ -z "${value}" ] ; then
		echo_fail "[!] Missing required input: ${key}"
	fi
}

function validate_required_input_with_options {
	key=$1
	value=$2
	values=$3

	validate_required_input "${key}" "${value}"

	found="0"
	for v in "${values[@]}" ; do
		if [ "${v}" == "${value}" ] ; then
			found="1"
		fi
	done

	if [ "${found}" == "0" ] ; then
		echo_fail "Invalid input: (${key}) value: (${value}), valid values: ($( IFS=$", "; echo "${values[*]}" ))"
	fi
}

#=======================================
# Main
#=======================================

#
# Validate parameters
echo_info "Configs:"
echo_details "* binary_path: $binary_path"
echo_details "* platform: $platform"
echo_details "* entry_file: $entry_file"
echo_details "* bundle_output: $out"
echo_details "* dev: $dev"
echo_details "* assets_dest: $assetRoots"
echo_details "* options: $options"

echo_info "Deprecated Configs:"
echo_details "* root: $root"
echo_details "* url: $url"

echo_info "\`react-native\` info:"

# Find path to the react-native CLI
declare REACT_NATIVE_BIN
if [[ -n "${binary_path}" ]]; then
	# If binary_path is specified, use that
	REACT_NATIVE_BIN="${binary_path}/react-native"
	echo_details "* Using binary specified in binary_path"
elif output=$(npx --yes which react-native 2>/dev/null); then
	# If npx version is available, use that
	REACT_NATIVE_BIN=${output}
	echo_details "* Using binary via \`npx\`"
else
	# Otherwise, use the react-native CLI in the current PATH
	REACT_NATIVE_BIN="react-native"
	echo_details "* Using react-native CLI in PATH"
fi
echo_details "* Location: ${REACT_NATIVE_BIN}"

if output=$("${REACT_NATIVE_BIN}" --version 2>/dev/null); then
	echo_details "* Version: ${output}"
elif output=$("${REACT_NATIVE_BIN}" -v 2>/dev/null); then
	echo_details "* Version: ${output}"
else
	echo_warn "* Failed to get \`react-native\` version"
fi

echo

bundle_output="${out}"
assets_dest="${assetRoots}"

values=("ios"  "android")
validate_required_input_with_options "platform" $platform "${values[@]}"
validate_required_input "entry_file" $entry_file
validate_required_input "bundle_output" $bundle_output

if [ ! -z "${root}" ] ; then
	echo_warn "root input is deprecated and removed from react-native bundle flags"
fi

if [ ! -z "${url}" ] ; then
	echo_warn "url input is deprecated and removed from react-native bundle flags"
fi

echo

PLATFORM_OPTION=""
if [ ! -z "${platform}" ] ; then
    PLATFORM_OPTION="--platform ${platform}"
fi

ENTRY_FILE_OPTION=""
if [ ! -z "${entry_file}" ] ; then
    ENTRY_FILE_OPTION="--entry-file "${entry_file}""
fi

BUNDLE_OUTPUT_OPTION=""
if [ ! -z "${bundle_output}" ] ; then
    mkdir -p "$(dirname "${bundle_output}")"
    BUNDLE_OUTPUT_OPTION="--bundle-output ${bundle_output}"
fi

DEV_OPTION=""
if [ ! -z "${dev}" ] ; then
    DEV_OPTION="--dev ${dev}"
fi

ASSETS_DEST_OPTION=""
if [ ! -z "${assets_dest}" ] ; then
    ASSETS_DEST_OPTION="--assets-dest ${assets_dest}"
fi

# Bundle

set -x

$REACT_NATIVE_BIN bundle $ENTRY_FILE_OPTION \
    $PLATFORM_OPTION \
    $BUNDLE_OUTPUT_OPTION \
		$DEV_OPTION \
    $ASSETS_DEST_OPTION \
		$options
