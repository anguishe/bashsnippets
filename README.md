# bash/snippets

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg) ![ShellCheck: clean](https://img.shields.io/badge/ShellCheck-clean-brightgreen.svg) ![Explained at bashsnippets.xyz](https://img.shields.io/badge/explained%20at-bashsnippets.xyz-blue)

I got tired of digging the same scripts out of my own notes every time a disk filled up, a service died, or a cron job overlapped itself into an outage. This repo is those scripts: tested, copy-paste bash for real Linux boxes and cron jobs, each one explained line-by-line at [bashsnippets.xyz](https://bashsnippets.xyz). No login, no paywall, no newsletter wall — clone it, read it, run it.

**Every script in this repo:**

- runs `set -euo pipefail` — stops on the first error instead of marching past it
- uses named variables for thresholds and paths — no magic numbers to guess at
- comments explain *why* a line exists, not *what* it does
- is **ShellCheck-clean** (`shellcheck -S style`, zero findings) and mirrors the tested version explained line-by-line on the site

## Scripts

| Script | What breaks without it | Explained |
|--------|------------------------|-----------|
| [`argument-list-too-long.sh`](scripts/argument-list-too-long.sh) | `rm ./*.log` on 200,000 files dies with "Argument list too long" and deletes nothing. | [Read](https://bashsnippets.xyz/snippets/argument-list-too-long) |
| [`automated-file-backup.sh`](scripts/automated-file-backup.sh) | Deleted or disk-failed data is gone with no undo. | [Read](https://bashsnippets.xyz/snippets/automated-file-backup) |
| [`bash-argument-parsing.sh`](scripts/bash-argument-parsing.sh) | A flag read as a value deploys to nowhere, silently. | [Read](https://bashsnippets.xyz/snippets/bash-argument-parsing) |
| [`bash-arrays.sh`](scripts/bash-arrays.sh) | One space in a list item silently splits it in two. | [Read](https://bashsnippets.xyz/snippets/bash-arrays) |
| [`bash-case-statement.sh`](scripts/bash-case-statement.sh) | A `*.gz` rule above `*.tar.gz` gunzips a tarball into one opaque `.tar`. | [Read](https://bashsnippets.xyz/snippets/bash-case-statement) |
| [`bash-command-not-found.sh`](scripts/bash-command-not-found.sh) | "command not found" has six causes and one message; reinstalling fixes one of them. | [Read](https://bashsnippets.xyz/snippets/bash-command-not-found) |
| [`bash-curl-api-requests.sh`](scripts/bash-curl-api-requests.sh) | curl exits 0 on HTTP 500, so a failed call poisons everything downstream. | [Read](https://bashsnippets.xyz/snippets/bash-curl-api-requests) |
| [`bash-environment-variables.sh`](scripts/bash-environment-variables.sh) | A variable set but never exported is invisible to every child process — cron runs with an empty token. | [Read](https://bashsnippets.xyz/snippets/bash-environment-variables) |
| [`bash-flock-single-instance.sh`](scripts/bash-flock-single-instance.sh) | Overlapping cron runs stack copies until the box falls over. | [Read](https://bashsnippets.xyz/snippets/bash-flock-single-instance) |
| [`bash-for-loop-examples.sh`](scripts/bash-for-loop-examples.sh) | Looping over `ls` silently skips filenames with spaces. | [Read](https://bashsnippets.xyz/snippets/bash-for-loop-examples) |
| [`bash-functions-arguments.sh`](scripts/bash-functions-arguments.sh) | A reused variable clobbers the caller and deletes the wrong dir. | [Read](https://bashsnippets.xyz/snippets/bash-functions-arguments) |
| [`bash-functions.sh`](scripts/bash-functions.sh) | `return` sets an exit code, not a string — data lost. | [Read](https://bashsnippets.xyz/snippets/bash-functions) |
| [`bash-heredoc.sh`](scripts/bash-heredoc.sh) | An unset variable in an unquoted heredoc ships `server_name ;` to production. | [Read](https://bashsnippets.xyz/snippets/bash-heredoc) |
| [`bash-if-else-examples.sh`](scripts/bash-if-else-examples.sh) | The wrong test operator fails logic silently on odd input. | [Read](https://bashsnippets.xyz/snippets/bash-if-else-examples) |
| [`bash-parse-json-jq.sh`](scripts/bash-parse-json-jq.sh) | grep on JSON breaks the moment the API reformats — and fails silently. | [Read](https://bashsnippets.xyz/snippets/bash-parse-json-jq) |
| [`bash-permission-denied.sh`](scripts/bash-permission-denied.sh) | chmod +x fixes one Permission denied; noexec mounts and directory bits block the rest. | [Read](https://bashsnippets.xyz/snippets/bash-permission-denied) |
| [`bash-read-file-line-by-line.sh`](scripts/bash-read-file-line-by-line.sh) | A missing final newline silently drops the last line. | [Read](https://bashsnippets.xyz/snippets/bash-read-file-line-by-line) |
| [`bash-retry-with-backoff.sh`](scripts/bash-retry-with-backoff.sh) | One transient error kills a deploy you then re-run by hand. | [Read](https://bashsnippets.xyz/snippets/bash-retry-with-backoff) |
| [`bash-sed-find-replace.sh`](scripts/bash-sed-find-replace.sh) | An unanchored `sed -i` across a tree rewrites substrings you never looked at. | [Read](https://bashsnippets.xyz/snippets/bash-sed-find-replace) |
| [`bash-send-email-alert.sh`](scripts/bash-send-email-alert.sh) | Failures go unnoticed until users report them. | [Read](https://bashsnippets.xyz/snippets/bash-send-email-alert) |
| [`bash-slack-webhook-alerts.sh`](scripts/bash-slack-webhook-alerts.sh) | A broken cron job fails silently for a week before anyone notices. | [Read](https://bashsnippets.xyz/snippets/bash-slack-webhook-alerts) |
| [`bash-string-manipulation.sh`](scripts/bash-string-manipulation.sh) | `cut` returns the wrong field the moment the format shifts. | [Read](https://bashsnippets.xyz/snippets/bash-string-manipulation) |
| [`bash-timeout-command.sh`](scripts/bash-timeout-command.sh) | A hung job never exits and never frees its lock. | [Read](https://bashsnippets.xyz/snippets/bash-timeout-command) |
| [`bash-trap-cleanup.sh`](scripts/bash-trap-cleanup.sh) | A crash leaves temp files behind and publishes a half-written file. | [Read](https://bashsnippets.xyz/snippets/bash-trap-cleanup) |
| [`bash-while-loop-examples.sh`](scripts/bash-while-loop-examples.sh) | `while ! check; do sleep 1; done` hangs forever when the service never comes up. | [Read](https://bashsnippets.xyz/snippets/bash-while-loop-examples) |
| [`check-if-website-is-up.sh`](scripts/check-if-website-is-up.sh) | You learn the site is down from angry users. | [Read](https://bashsnippets.xyz/snippets/check-if-website-is-up) |
| [`check-ssl-certificate-expiry.sh`](scripts/check-ssl-certificate-expiry.sh) | An expired certificate takes the site dark without warning. | [Read](https://bashsnippets.xyz/snippets/check-ssl-certificate-expiry) |
| [`create-dated-folder.sh`](scripts/create-dated-folder.sh) | Untimestamped backup folders overwrite the previous run. | [Read](https://bashsnippets.xyz/snippets/create-dated-folder) |
| [`cron-job-not-running.sh`](scripts/cron-job-not-running.sh) | A cron job that never runs, or fails, leaves no error you would see; output is discarded without an MTA. | [Read](https://bashsnippets.xyz/snippets/cron-job-not-running) |
| [`delete-old-log-files.sh`](scripts/delete-old-log-files.sh) | Unmanaged logs fill `/var/log` until writes fail and services crash. | [Read](https://bashsnippets.xyz/snippets/delete-old-log-files) |
| [`disk-space-warning.sh`](scripts/disk-space-warning.sh) | A silently full disk crashes writes with no heads-up. | [Read](https://bashsnippets.xyz/snippets/disk-space-warning) |
| [`docker-remove-all-containers.sh`](scripts/docker-remove-all-containers.sh) | `docker rm $(docker ps -aq)` fails on an empty list, refuses running containers and keeps volumes without saying so. | [Read](https://bashsnippets.xyz/snippets/docker-remove-all-containers) |
| [`docker-prune-cleanup.sh`](scripts/docker-prune-cleanup.sh) | Dead containers, images, and volumes eat disk unnoticed. | [Read](https://bashsnippets.xyz/snippets/docker-prune-cleanup) |
| [`file-permissions-security.sh`](scripts/file-permissions-security.sh) | World-writable files let a compromised script overwrite your app. | [Read](https://bashsnippets.xyz/snippets/file-permissions-security) |
| [`find-duplicate-files.sh`](scripts/find-duplicate-files.sh) | Duplicate copies waste gigabytes silently across archives. | [Read](https://bashsnippets.xyz/snippets/find-duplicate-files) |
| [`find-ip-address-linux.sh`](scripts/find-ip-address-linux.sh) | A firewall rule or backup target built on the wrong IP locks you out or ships data elsewhere. | [Read](https://bashsnippets.xyz/snippets/find-ip-address-linux) |
| [`find-large-files-linux.sh`](scripts/find-large-files-linux.sh) | Disk hits 100% and you can't find the culprit fast. | [Read](https://bashsnippets.xyz/snippets/find-large-files-linux) |
| [`fix-bad-interpreter-crlf.sh`](scripts/fix-bad-interpreter-crlf.sh) | A script saved with CRLF endings dies with `/bin/bash^M: bad interpreter`, or runs with strict mode silently off. | [Read](https://bashsnippets.xyz/snippets/fix-bad-interpreter-crlf) |
| [`journalctl-disk-usage-vacuum.sh`](scripts/journalctl-disk-usage-vacuum.sh) | An unconfigured systemd journal quietly holds up to 4G of disk. | [Read](https://bashsnippets.xyz/snippets/journalctl-disk-usage-vacuum) |
| [`kill-process-on-port.sh`](scripts/kill-process-on-port.sh) | `EADDRINUSE` — something squats your port and blocks startup. | [Read](https://bashsnippets.xyz/snippets/kill-process-on-port) |
| [`list-open-ports-linux.sh`](scripts/list-open-ports-linux.sh) | Unknown listening ports are the blind spot in a security audit. | [Read](https://bashsnippets.xyz/snippets/list-open-ports-linux) |
| [`lsof-command-examples.sh`](scripts/lsof-command-examples.sh) | du says the disk has space, df says it is full: deleted files still held open keep every byte. | [Read](https://bashsnippets.xyz/snippets/lsof-command-examples) |
| [`log-retention-cleanup.sh`](scripts/log-retention-cleanup.sh) | Dated backup folders nobody rotates fill the disk in the directories logrotate does not own. | [Read](https://bashsnippets.xyz/snippets/log-retention-cleanup) |
| [`monitor-cpu-ram-usage.sh`](scripts/monitor-cpu-ram-usage.sh) | A runaway process pins CPU until the server stops responding. | [Read](https://bashsnippets.xyz/snippets/monitor-cpu-ram-usage) |
| [`mysql-database-backup.sh`](scripts/mysql-database-backup.sh) | A mistaken `DROP TABLE` destroys data with no undo. | [Read](https://bashsnippets.xyz/snippets/mysql-database-backup) |
| [`no-space-left-on-device-inodes.sh`](scripts/no-space-left-on-device-inodes.sh) | Writes fail with "No space left on device" while `df -h` shows free space: the filesystem is out of inodes. | [Read](https://bashsnippets.xyz/snippets/no-space-left-on-device-inodes) |
| [`port-listening-but-connection-refused.sh`](scripts/port-listening-but-connection-refused.sh) | A service bound to 127.0.0.1 answers on the box and refuses every other machine with "Connection refused". | [Read](https://bashsnippets.xyz/snippets/port-listening-but-connection-refused) |
| [`ports-audit.sh`](scripts/ports-audit.sh) | A new listener appears on a server and nobody notices until it is in an incident report. | [Read](https://bashsnippets.xyz/snippets/ports-audit) |
| [`quick-system-info-report.sh`](scripts/quick-system-info-report.sh) | Guessing server state during an outage costs response time. | [Read](https://bashsnippets.xyz/snippets/quick-system-info-report) |
| [`restart-service-if-stopped.sh`](scripts/restart-service-if-stopped.sh) | A crashed service stays down for hours without a watchdog. | [Read](https://bashsnippets.xyz/snippets/restart-service-if-stopped) |
| [`rsync-remote-backup.sh`](scripts/rsync-remote-backup.sh) | A local-only backup dies with the machine. | [Read](https://bashsnippets.xyz/snippets/rsync-remote-backup) |
| [`rust-coreutils-ubuntu.sh`](scripts/rust-coreutils-ubuntu.sh) | On Ubuntu 26.04 `ls` and `timeout` are Rust while `cp` may still be GNU, and nothing says which one a script ran. | [Read](https://bashsnippets.xyz/snippets/rust-coreutils-ubuntu) |
| [`scp-command-examples.sh`](scripts/scp-command-examples.sh) | scp exits 0 without checking what arrived; a cut-off copy leaves a half file. | [Read](https://bashsnippets.xyz/snippets/scp-command-examples) |
| [`search-files-for-text-grep.sh`](scripts/search-files-for-text-grep.sh) | Hunting a pattern by opening files by hand wastes time. | [Read](https://bashsnippets.xyz/snippets/search-files-for-text-grep) |
| [`service-watchdog.sh`](scripts/service-watchdog.sh) | A hung service passes `is-active` and stays broken; a naive restart loop fires 60 alerts an hour. | [Read](https://bashsnippets.xyz/snippets/service-watchdog) |
| [`ssh-key-setup-script.sh`](scripts/ssh-key-setup-script.sh) | Password SSH invites brute-force attacks on any exposed server. | [Read](https://bashsnippets.xyz/snippets/ssh-key-setup-script) |
| [`ssh-run-remote-commands.sh`](scripts/ssh-run-remote-commands.sh) | A loop that ignores ssh exit codes reports done while three hosts never changed. | [Read](https://bashsnippets.xyz/snippets/ssh-run-remote-commands) |
| [`start-request-repeated-too-quickly.sh`](scripts/start-request-repeated-too-quickly.sh) | "Start request repeated too quickly" hides the real crash behind the rate limit; raising the limit hides it longer. | [Read](https://bashsnippets.xyz/snippets/start-request-repeated-too-quickly) |
| [`sudo-rs-afraid-cant-do-that.sh`](scripts/sudo-rs-afraid-cant-do-that.sh) | sudo-rs says "I'm afraid I can't do that" for a missing rule, a dropped rule and a one-character argument mismatch alike. | [Read](https://bashsnippets.xyz/snippets/sudo-rs-afraid-cant-do-that) |
| [`sudo-rs-wildcards-not-allowed.sh`](scripts/sudo-rs-wildcards-not-allowed.sh) | sudo-rs drops sudoers rules it can't parse, so a nightly job that ran under sudo for years fails after the 26.04 upgrade. | [Read](https://bashsnippets.xyz/snippets/sudo-rs-wildcards-not-allowed) |
| [`systemd-status-203-exec.sh`](scripts/systemd-status-203-exec.sh) | `status=203/EXEC` has five causes and `systemctl status` shows the same code for all of them. | [Read](https://bashsnippets.xyz/snippets/systemd-status-203-exec) |
| [`uutils-vs-gnu-coreutils.sh`](scripts/uutils-vs-gnu-coreutils.sh) | A script that passed on GNU coreutils changes exit codes, stderr or output under Rust coreutils without failing loudly. | [Read](https://bashsnippets.xyz/snippets/uutils-vs-gnu-coreutils) |

## The bashlib starter

Ten functions to `source` into every script, so each one starts with the safety the scripts above repeat by hand. Explained function by function at [bashsnippets.xyz/snippets/bashlib-starter](https://bashsnippets.xyz/snippets/bashlib-starter).

- `enable_strict_traps` — `set -Eeuo pipefail` plus an ERR trap that names the failing command and line (the `-E` makes it fire inside functions)
- `register_temp`, `make_temp_file`, `make_temp_dir` — cleanup that runs on every exit path: success, `exit N`, a `set -e` abort, Ctrl-C, SIGTERM
- `acquire_lock` — one running copy at a time, stale locks from dead PIDs reclaimed
- `run_with_timeout` — a hung command is killed (exit 124) instead of hanging the script and its lock
- `retry` — exponential backoff that returns the last exit code
- `log`, `die`, `require_cmd`

```bash
curl -fsSLO https://raw.githubusercontent.com/anguishe/bashsnippets/main/lib/bashlib-starter.sh
```

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/bashlib-starter.sh"
enable_strict_traps
require_cmd curl timeout
acquire_lock
tmp="$(make_temp_file)"
run_with_timeout 30 curl -fsS https://example.com -o "$tmp"
log INFO "fetched $(wc -c < "$tmp") bytes"
```

Every function is exercised on its failure path by [`lib/bashlib-starter.test.sh`](lib/bashlib-starter.test.sh): `bash lib/bashlib-starter.test.sh` ends in `✓ all checks passed`. The function names match the [Production Bash Toolkit](https://bashsnippets.xyz/starter-kit)'s `bashlib.sh`; the reasoning behind strict mode and the ERR trap is in the [safe bash script template](https://bashsnippets.xyz/guides/safe-bash-script-template) guide.

## Explained on the site

Five pages earn their place as full explainers rather than a single copy-paste script — a strict-mode pattern you add to *every* script, three command references you run interactively, and an error whose fix is quoting rather than a script. They live on the site, not in `scripts/`:

- [Bash error handling with `set -euo pipefail`](https://bashsnippets.xyz/snippets/bash-error-handling)
- [Kill a process by name with `pgrep` / `pkill`](https://bashsnippets.xyz/snippets/kill-a-process)
- [Fix "unary operator expected": empty variables inside `[ ]`](https://bashsnippets.xyz/snippets/unary-operator-expected)
- [ss command examples: `-tulpn`, filters and every column decoded](https://bashsnippets.xyz/snippets/ss-command-examples)
- [AWK cheat sheet: columns, filters, sums, every line run for real](https://bashsnippets.xyz/snippets/awk-cheat-sheet)

## Browser tools

Some of these jobs are faster to build in a form than to hand-write — a cron schedule, a hardened wrapper, a chmod calculator. The interactive versions live at [bashsnippets.xyz/tools](https://bashsnippets.xyz/tools).

---

The production layer these scripts don't cover — logging, locking, alerting wired together — is the [Production Bash Toolkit](https://bashsnippets.xyz/starter-kit).

Licensed under the [MIT License](LICENSE).
