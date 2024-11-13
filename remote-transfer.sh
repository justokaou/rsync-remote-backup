#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Exit the script in case of any error
set -e

# Help function
usage() {
    echo -e "${CYAN}Usage: $0 [OPTIONS]${NC}"
    echo "Available options:"
    echo "  -h, --help                  Display this help message"
    echo "  -hs, --host-source          Source host (required for --copy-to-temp)"
    echo "  -ps, --port-source          SSH port for the source (default: 22)"
    echo "  -s, --source                Path to the source directory (required for --copy-to-temp)"
    echo "  -hd, --host-destination     Destination host (required for --copy-from-temp)"
    echo "  -pd, --port-destination     SSH port for the destination (default: 22)"
    echo "  -d, --destination           Path to the destination directory (required for --copy-from-temp)"
    echo "  -e, --exclude               Exclude files or directories during the copy"
    echo "  -k, --keep-temp             Do not delete the temporary directory after the copy"
    echo "  -n, --dry-run               Show what would be copied without actually transferring files"
    echo "  --copy-to-temp              Copy from the source to the temporary directory only"
    echo "  --copy-from-temp            Copy from the temporary directory to the destination only"
    echo ""
    echo "Note: If neither --copy-to-temp nor --copy-from-temp are specified, a full copy from source to destination is performed."
    exit 1
}

# Initialize default variables
user=$(whoami)
source=""
destination=""
temp_dir="/tmp/transfer_dir"
port_source=22
port_destination=22
keep_temp=false
dry_run=false
exclude=""
copy_to_temp=true
copy_from_temp=true
rsync_options="-az --no-perms --no-owner --no-group"

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -hs|--host-source) host_source="$2"; shift 2 ;;
        -ps|--port-source) port_source="$2"; shift 2 ;;
        -s|--source) source="$2"; shift 2 ;;
        -hd|--host-destination) host_destination="$2"; shift 2 ;;
        -pd|--port-destination) port_destination="$2"; shift 2 ;;
        -d|--destination) destination="$2"; shift 2 ;;
        -e|--exclude) exclude="$2"; shift 2 ;;
        -k|--keep-temp) keep_temp=true ;;
        -n|--dry-run) dry_run=true ;;
        --copy-to-temp) copy_to_temp=true; copy_from_temp=false ;;
        --copy-from-temp) copy_to_temp=false; copy_from_temp=true ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
    shift
done

[[ "$dry_run" == "true" ]] && rsync_options="$rsync_options --dry-run"
[[ "$dry_run" == "false" ]] && rsync_options="$rsync_options --progress"
[[ -n "$exclude" ]] && rsync_options="$rsync_options --exclude=$exclude"

# Check for required arguments
if [[ -z "$host_source" || -z "$source" ]] && [[ "$copy_to_temp" == "true" ]]; then
    echo -e "${RED}Error: host-source and source arguments are required for copying to temporary.${NC}"
    usage
fi

if [[ -z "$host_destination" || -z "$destination" ]] && [[ "$copy_from_temp" == "true" ]]; then
    echo -e "${RED}Error: host-destination and destination arguments are required for copying from temporary.${NC}"
    usage
fi

# Check if rsync is installed
echo -e "${CYAN}Checking if rsync is installed...${NC}"
command -v rsync >/dev/null 2>&1 || { echo -e "${RED}Error: rsync is not installed. Please install it.${NC}"; exit 1; }

# Create the temporary directory if it does not exist
if [[ ! -d "$temp_dir" ]]; then
    echo -e "${CYAN}Creating temporary directory: ${YELLOW}${temp_dir}${NC}"
    mkdir -p "$temp_dir"
fi

# Section 1: Copy from source to temporary directory
if [[ "$copy_to_temp" == "true" ]]; then
    echo -e "${CYAN}Checking SSH connection to the source host...${NC}"
    ssh -p "$port_source" -o BatchMode=yes -o ConnectTimeout=5 "${user}@${host_source}" exit || { echo -e "${RED}Error: Unable to connect to the source host.${NC}"; exit 1; }

    echo -e "${CYAN}Calculating the size of the source directory...${NC}"
    source_size=$(ssh -p "$port_source" "${user}@${host_source}" "du -sk \"$source\" | cut -f1")

    if [[ -z "$source_size" ]]; then
        echo -e "${RED}Error: Unable to calculate the size of the source directory.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Source directory size: ${source_size} KB${NC}"

    temp_available=$(df "$temp_dir" | awk 'NR==2 {print $4}')
    if [[ "$temp_available" -lt "$source_size" ]]; then
        echo -e "${RED}Error: Insufficient disk space in ${temp_dir}. Available: ${temp_available} KB, Required: ${source_size} KB.${NC}"
        exit 1
    fi

    echo -e "${CYAN}Copying from source ${YELLOW}${source}${CYAN} to ${YELLOW}${temp_dir}${NC}"
    rsync $rsync_options -e "ssh -p ${port_source}" "${user}@${host_source}:${source}" "$temp_dir"
    echo -e "${GREEN}Successfully copied from source to temporary directory${NC}"
fi

# Section 2: Copy from temporary directory to destination
if [[ "$copy_from_temp" == "true" ]]; then
    echo -e "${CYAN}Calculating the size of the temporary directory...${NC}"
    temp_size=$(du -sk "$temp_dir" | cut -f1)

    dest_available=$(ssh -p "$port_destination" "${user}@${host_destination}" "df \"$destination\" | awk 'NR==2 {print \$4}'")
    if [[ "$dest_available" -lt "$temp_size" ]]; then
        echo -e "${RED}Error: Insufficient disk space on the destination. Available: ${dest_available} KB, Required: ${temp_size} KB.${NC}"
        exit 1
    fi

    echo -e "${CYAN}Copying from ${YELLOW}${temp_dir}${CYAN} to ${YELLOW}${destination}${NC}"
    rsync $rsync_options -e "ssh -p ${port_destination}" "$temp_dir/" "${user}@${host_destination}:${destination}"
    echo -e "${GREEN}Successfully copied from temporary directory to destination${NC}"
fi

# Cleanup of the temporary directory
if [[ "$keep_temp" == "false" && "$copy_from_temp" == "true" ]]; then
    echo -e "${CYAN}Cleaning up the temporary directory...${NC}"
    rm -rf "$temp_dir"
    echo -e "${GREEN}Cleanup completed${NC}"
else
    echo -e "${YELLOW}The temporary directory is kept for inspection: ${temp_dir}${NC}"
fi
