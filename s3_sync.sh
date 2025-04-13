#!/bin/bash

# macOS S3 Sync Script
# This script syncs your Downloads, Documents, and Desktop folders to an AWS S3 bucket
# Requirements: AWS CLI installed and configured with proper credentials

# Configuration
S3_BUCKET="your-bucket-name" # Replace with your actual bucket name
USER_HOME="$HOME"           # User's home directory
LOG_FILE="$USER_HOME/Library/Logs/s3_sync.log"
ENABLE_DELETE=false         # Set to true to delete files in S3 that don't exist locally, false to keep them
DIRECTORIES=(
  "Desktop"
  "Documents"
  "Downloads"
  "Movies"
  "Music"
  "Pictures"
)

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to sync a directory
sync_directory() {
  local dir_name="$1"
  local source_dir="$USER_HOME/$dir_name"
  local s3_path="s3://$S3_BUCKET/$dir_name"
  
  if [ ! -d "$source_dir" ]; then
    log_message "ERROR: Source directory '$source_dir' does not exist"
    return 1
  fi
  
  log_message "Starting sync of '$dir_name' to S3 bucket '$S3_BUCKET'"
  
  # Using aws s3 sync to synchronize the directory
  # --delete (optional): Files that exist in the destination but not in the source are deleted
  # --exclude: Skip .DS_Store files and other temporary files
  
  # Build the sync command
  SYNC_CMD="aws s3 sync \"$source_dir\" \"$s3_path\" \
    --exclude \"*.DS_Store\" \
    --exclude \"*.tmp\" \
    --exclude \"*.temp\" \
    --exclude \".Trash*\" \
    --exclude \".Trashes*\" \
    --exclude \"*.crdownload\" \
    --exclude \"*.part\" \
    --exclude \".fseventsd*\" \
    --exclude \".Spotlight-V100*\" \
    --exclude \"*Icon?\""
  
  # Add --delete option if enabled
  if [ "$ENABLE_DELETE" = true ]; then
    log_message "Running with --delete option enabled (will remove files in S3 that don't exist locally)"
    SYNC_CMD="$SYNC_CMD --delete"
  else
    log_message "Running without --delete option (will keep files in S3 even if deleted locally)"
  fi
  
  # Execute the sync command
  eval "$SYNC_CMD" 2>&1 | tee -a "$LOG_FILE"
  
  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log_message "Successfully synced '$dir_name' to S3"
    return 0
  else
    log_message "ERROR: Failed to sync '$dir_name' to S3"
    return 1
  fi
}

# Main function
main() {
  log_message "=== S3 Sync Starting ==="
  
  # Parse command line arguments
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --no-delete) ENABLE_DELETE=false ;;
      --delete) ENABLE_DELETE=true ;;
      --help) 
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --delete     Enable deletion of files in S3 that don't exist locally (default if ENABLE_DELETE=true)"
        echo "  --no-delete  Disable deletion of files in S3 that don't exist locally"
        echo "  --help       Display this help message"
        exit 0
        ;;
      *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
  done
  
  # Check if AWS CLI is installed
  if ! command -v aws &> /dev/null; then
    log_message "ERROR: AWS CLI is not installed. Please install it first."
    log_message "You can install it using 'brew install awscli' or visit https://aws.amazon.com/cli/"
    exit 1
  fi
  
  # Check if AWS credentials are configured
  if ! aws sts get-caller-identity &> /dev/null; then
    log_message "ERROR: AWS credentials not configured properly."
    log_message "Please run 'aws configure' to set up your credentials."
    exit 1
  fi
  
  # Check if bucket exists
  if ! aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
    log_message "ERROR: S3 bucket '$S3_BUCKET' does not exist or you don't have access to it."
    log_message "Please create the bucket or check your permissions."
    exit 1
  fi
  
  # Sync each directory
  local error_count=0
  for dir in "${DIRECTORIES[@]}"; do
    sync_directory "$dir" || ((error_count++))
  done
  
  # Summary
  if [ $error_count -eq 0 ]; then
    log_message "=== S3 Sync completed successfully ==="
  else
    log_message "=== S3 Sync completed with $error_count errors ==="
  fi
}

# Run the main function
main

exit 0