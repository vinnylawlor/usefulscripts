# backup-to-network-gitbash.sh — README

A Git Bash–friendly backup helper for Windows that copies a configurable list of **files and folders** to a **local or network destination**.  
It uses Windows-native tools under the hood for speed and reliability:

- **Directories** → [`robocopy`](https://learn.microsoft.com/windows-server/administration/windows-commands/robocopy) (supports mirroring, retries, and dry-run via `/L`).
- **Files** → PowerShell [`Copy-Item`](https://learn.microsoft.com/powershell/module/microsoft.powershell.management/copy-item) (supports `-WhatIf` for dry-run).

> Works with both **POSIX-style paths** (`/c/Users/you/...`, `//server/share/...`) and **Windows paths** (`C:\Users\you\...`, `\\server\share\...`). The script normalizes them automatically for the underlying tools.

---

## Features

- Read sources from a config file (one path per line; `#` comments and blank lines ignored).
- **Dry-run** mode for safe preview.
- Optional **mirror** mode (`robocopy /MIR`).
- Verbose logging to a timestamped logfile.
- Automatic **path normalization** using `cygpath` if available.

---

## Usage

```bash
./backup-to-network-gitbash.sh -c CONFIG -d DESTINATION [options]
```

**Required:**
- `-c, --config FILE` — Text file with one source path per line.
- `-d, --dest PATH` — Destination directory (UNC like `//server/share/Backups` or `E:\Backups`).

**Options:**
- `-n, --dry-run` — Show what would be copied (no changes).
- `--mirror` — Mirror directories (equivalent to `robocopy /MIR`).
- `-l, --log FILE` — Write log (default: `./backup-YYYYmmdd-HHMMSS.log`).
- `-v, --verbose` — More output.
- `-h, --help` — Help text.

### Examples

Dry-run to a UNC share:
```bash
./backup-to-network-gitbash.sh -c ~/backup-gitbash.conf -d //nas/Backups -n -v
```

Mirror mode to a mapped drive:
```bash
./backup-to-network-gitbash.sh -c ~/backup-gitbash.conf -d 'E:\Backups' --mirror -v
```

---

## Config file format

Example (`backup-gitbash.conf`):

```text
# POSIX or Windows paths
/c/Users/you/Documents
/c/Users/you/Pictures
C:\Users\you\Projects
\\server\teamshare\handbook.pdf
```

- **Directories** are replicated into the destination as subfolders with the same basename.
- **Files** are copied into the destination directory root.

---

## Quoting & Path Tips

When running from **Git Bash**:

1. **Quote paths with spaces** — prefer single quotes:
   ```bash
   -d 'E:\Company Backups'
   -c 'C:\Users\you\My Files\backup.conf'
   ```
2. **UNC paths** — use `//server/share`:
   ```bash
   -d //server/share/Backups
   ```
3. **Avoid unquoted backslashes** — they can be misinterpreted by Bash.
4. **`~` and env vars** are expanded by the script — quote if you need literals.

---

## How it Works

1. Checks for `robocopy` and `powershell.exe`.
2. Normalizes POSIX/Windows paths using `cygpath` if available.
3. Reads config, ignores comments and blanks, expands `~` and variables.
4. **Directories** → `robocopy` with `/E` or `/MIR`, `/COPY:DAT`, `/DCOPY:DAT`, `/R:2`, `/W:5` (+`/L` for dry-run).
5. **Files** → PowerShell `Copy-Item -LiteralPath <SRC> -Destination <DEST> -Force` (+`-WhatIf` for dry-run).
6. Logs all output to a file.

**References:**
- [`robocopy` docs](https://learn.microsoft.com/windows-server/administration/windows-commands/robocopy)
- [`Copy-Item` docs](https://learn.microsoft.com/powershell/module/microsoft.powershell.management/copy-item)
- [`-WhatIf` common parameter](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_commonparameters)

---

## Safety Checklist

- Always test with `--dry-run` first.
- Double-check your destination path.
- Be careful with `--mirror` — it deletes files at the destination.

---

## Troubleshooting

- **Tool not found** — ensure `robocopy` and `powershell.exe` are in `PATH`.
- **Wrong path conversions** — prefer POSIX or quoted Windows paths.
- **Permissions issues** — may require elevated rights for attributes/ACLs.
