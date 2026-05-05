<!-- Google Search Console verification -->
<meta name="google-site-verification" content="MWzywB1C7S0c4dD5fXrGLuyqcDU_LY80S5ZitNRrmvc" />
# BashSnippets — Free Copy-Paste Bash Scripts

Free bash scripts for Linux users, developers, and sysadmins.
Every script is tested, explained in plain English, and copy-paste ready.
No login. No paywall. No bloat.

🌐 **Full library with explanations:** [bashsnippets.xyz](https://bashsnippets.xyz)
📺 **Shorts on YouTube:** [@BashSnippets](https://youtube.com/@BashSnippets)
🎵 **TikTok:** [@BashSnippets](https://tiktok.com/@BashSnippets)

---

## Scripts

| Script | What it does | Full reference |
|--------|-------------|----------------|
| [diskcheck.sh](./scripts/diskcheck.sh) | Warns when disk usage crosses a threshold | [bashsnippets.xyz →](https://bashsnippets.xyz/snippets/disk-space-warning.html) |
| [cleanlog.sh](./scripts/cleanlog.sh) | Deletes log files older than N days | [bashsnippets.xyz →](https://bashsnippets.xyz/snippets/delete-old-log-files.html) |
| [uptime.sh](./scripts/uptime.sh) | Checks if a website is up via HTTP status code | [bashsnippets.xyz →](https://bashsnippets.xyz/snippets/check-if-website-is-up.html) |
| [backup.sh](./scripts/backup.sh) | Automated file backup with timestamp | [bashsnippets.xyz →](https://bashsnippets.xyz/snippets/automated-file-backup.html) |
| [sysinfo.sh](./scripts/sysinfo.sh) | Quick system info report | [bashsnippets.xyz →](https://bashsnippets.xyz/snippets/quick-system-info-report.html) |
| [grep-search.sh](./scripts/grep-search.sh) | Search files for text recursively | [bashsnippets.xyz →](https://bashsnippets.xyz/snippets/search-files-for-text-grep.html) |

---

## Quick Start

Clone the repo and run any script directly:

```bash
git clone https://github.com/anguishe/bash-scripts.git
cd bash-scripts/scripts
chmod +x diskcheck.sh
./diskcheck.sh
```

Or copy-paste any script directly from [bashsnippets.xyz](https://bashsnippets.xyz) — full explanations, flag references, and cron setup included for every script.

---

## Scripts explained

### diskcheck.sh — Disk Space Warning
Checks disk usage with `df /` and compares against a threshold you set.
When usage crosses it, prints a warning. Schedule with cron to run hourly.

```bash
./diskcheck.sh
# ⚠ Disk usage at 82% — above 80% threshold. Clean up.
```

→ [Full explanation + cron setup](https://bashsnippets.xyz/snippets/disk-space-warning.html)

### uptime.sh — Check If Website Is Up
Uses `curl` to return the HTTP status code of any URL.
200 = up. Anything else = problem. Runs on cron every 5 minutes.

```bash
./uptime.sh
# ✓ https://bashsnippets.xyz is up (HTTP 200)
```

→ [Full explanation + cron setup](https://bashsnippets.xyz/snippets/check-if-website-is-up.html)

### cleanlog.sh — Delete Old Log Files
Finds and deletes log files older than a set number of days using `find`.
Safe, fast, and cron-compatible.

```bash
./cleanlog.sh
# ✓ Done. Cleaned 4 files older than 30 days.
```

→ [Full explanation](https://bashsnippets.xyz/snippets/delete-old-log-files.html)

---

## Why plain English?

Every script on bashsnippets.xyz includes:
- The command broken down flag by flag
- What each variable does
- Common mistakes and how to avoid them
- Cron scheduling examples
- Copy-paste ready — no modification required to run

---

## Adding a new script to cron

Every script in this repo is cron-compatible. General pattern:

```bash
# Edit your crontab
crontab -e

# Run diskcheck.sh every hour
0 * * * * ~/bash-scripts/scripts/diskcheck.sh

# Run uptime.sh every 5 minutes
*/5 * * * * ~/bash-scripts/scripts/uptime.sh >> ~/uptime.log 2>&1
```

---

## Contributing

Pull requests welcome. All scripts must:
- Be tested on Ubuntu/Debian
- Include a comment header explaining what it does
- Use `#!/bin/bash` shebang
- Follow the CHECK/CROSS variable convention for output

---

## License

MIT — use these scripts however you want.

---

Built by [@BashSnippets](https://bashsnippets.xyz)
