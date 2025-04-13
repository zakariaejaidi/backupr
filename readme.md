# macOS S3 Backup

A simple but powerful Bash script to synchronize your essential macOS folders with an AWS S3 bucket.

## Overview

This tool automatically backs up your important macOS directories to an AWS S3 bucket, providing a reliable cloud backup solution. The script intelligently synchronizes only the changed files to minimize bandwidth usage and storage costs.

## Features

- Backs up the following directories:
  - Desktop
  - Documents
  - Downloads
  - Movies
  - Music
  - Pictures
- Configurable deletion behavior (keep or remove files in S3 that were deleted locally)
- Skips macOS system files (.DS_Store, etc.)
- Detailed logging for troubleshooting
- Error handling and status checks
- Easy to configure and customize

## Requirements

- macOS
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- AWS S3 bucket
- AWS IAM user with appropriate S3 permissions

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/macos-s3-backup.git
   cd macos-s3-backup
   ```

2. Make the script executable:
   ```bash
   chmod +x s3_sync.sh
   ```

3. Edit the script to configure your S3 bucket name and deletion behavior:
   ```bash
   nano s3_sync.sh
   ```
   - Change the `S3_BUCKET` variable to your bucket name
   - By default, `ENABLE_DELETE` is set to `false`, meaning files deleted locally will remain in S3
   - Change to `true` if you want files deleted locally to also be deleted from S3

## Usage

### Manual Backup

Run the script manually:

```bash
./s3_sync.sh         # Uses the ENABLE_DELETE setting from the script
./s3_sync.sh --delete     # Force enable deletion of files in S3 that don't exist locally
./s3_sync.sh --no-delete  # Force disable deletion of files in S3 that don't exist locally
./s3_sync.sh --help       # Display help information
```

### Automated Backups

Set up a cron job to run the script automatically:

1. Open the crontab editor:
   ```bash
   crontab -e
   ```

2. Add a line to run the script at your preferred schedule:
   ```
   # Run backup daily at 2:00 AM
   0 2 * * * /path/to/s3_sync.sh
   ```

### Logs

Logs are stored in `~/Library/Logs/s3_sync.log`.

## AWS Setup

### Creating an S3 Bucket

1. Log in to your AWS Management Console
2. Navigate to S3 service
3. Click "Create bucket"
4. Name your bucket and configure as needed
5. Consider enabling versioning for added protection

### IAM Policy

Create an IAM user with the following policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        }
    ]
}
```

## Customization

- **Adding/Removing Directories**: Edit the `DIRECTORIES` array in the script.
- **Exclude Patterns**: Modify the `--exclude` parameters in the `sync_directory` function.
- **Sync Options**: Adjust the AWS CLI sync options as needed.
- **Deletion Behavior**:
  - In the script: Set `ENABLE_DELETE=true` or `ENABLE_DELETE=false`
  - When running: Use `--delete` or `--no-delete` command line options

## Security Considerations

- This script requires AWS credentials with write access to your S3 bucket
- Consider encrypting your S3 bucket for sensitive data
- Be mindful of what directories you are syncing
- Ensure AWS credentials are secured properly

## License

MIT

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.