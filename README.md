# 🔄 File Transfer Script

`remote-transfer.sh` is a Bash script designed to securely transfer files between hosts using `rsync` with SSH. It offers flexible options for copying from a source to a temporary directory, and then from the temporary directory to a destination. The script handles connectivity checks, disk space verification, and supports options for excluding files, dry runs, and keeping temporary files.

## 📋 Prerequisites

Ensure that you have the following tools installed on your system:
- **rsync**
- **SSH access** to both the source and destination hosts

## ⚙️ Installation

Clone the repository or download the script directly:

```bash
git clone [https://github.com/justokaou/rsync-remote-backup.git](https://github.com/justokaou/rsync-remote-backup.git)
cd rsync-remote-backup
chmod +x remote-transfer.sh
```

## 💻 Usage

```bash
./remote-transfer.sh [OPTIONS]
```

### 🔍 Options

| Option                  | Description                                               |
|-------------------------|-----------------------------------------------------------|
| `-h`, `--help`          | Displays this help message                               |
| `-hs`, `--host-source`  | Source host (required for `--copy-to-temp`)            |
| `-ps`, `--port-source`  | SSH port for the source host (default: 22)              |
| `-s`, `--source`        | Path to the source directory (required for `--copy-to-temp`) |
| `-hd`, `--host-destination` | Destination host (required for `--copy-from-temp`)    |
| `-pd`, `--port-destination` | SSH port for the destination host (default: 22)        |
| `-d`, `--destination`   | Path to the destination directory (required for `--copy-from-temp`) |
| `-e`, `--exclude`       | Exclude files or directories during the copy             |
| `-k`, `--keep-temp`     | Do not delete the temporary directory after the copy     |
| `-n`, `--dry-run`       | Show what would be copied without actually transferring files |
| `--copy-to-temp`         | Copy from the source to the temporary directory only     |
| `--copy-from-temp`       | Copy from the temporary directory to the destination only |

## 🛠️ Examples

### Example 1: Full copy from source to destination

```bash
./remote-transfer.sh -hs source-host -s /path/to/source -hd dest-host -d /path/to/destination
```

- Copies the source directory to a temporary directory and then transfers it to the destination.

### Example 2: Copy only to the temporary directory

```bash
./remote-transfer.sh -hs source-host -s /path/to/source --copy-to-temp -k
```

- Copies the source directory to a temporary location and keeps it for inspection.

### Example 3: Copy from the temporary directory to the destination

```bash
./remote-transfer.sh -hd dest-host -d /path/to/destination --copy-from-temp
```

- Transfers the contents of the temporary directory to the destination.

## 📂 Temporary Directory

By default, the script uses `/tmp/transfer_dir` as the temporary directory. You can inspect the contents if you use the `-k` option to keep it after the transfer.

## 📝 .gitignore

The script may create temporary files during execution. You can add the following entries to your `.gitignore`:

```
/tmp/transfer_dir
```

## 🛡️ License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributions

Contributions are welcome! Feel free to open an issue or a pull request if you have suggestions or improvements.

## ✨ Author

- JustOkaou - [Github Profile](https://github.com/justokaou)

---

🚀 Thank you for using `remote-transfer.sh`! Happy file transferring! 🔄
