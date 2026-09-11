# Contributing

Two ways to contribute, both welcome.

## Request a script

Open an issue with the **Script request** template. Say what breaks without the script
(a disk fills, a service dies, a cron job overlaps) — that sentence becomes the script's
`# Purpose:` line and decides whether it belongs here. Requests that describe a real
failure get written first.

## Send a fix or a script

1. Fork, branch, edit.
2. Every script follows the house format — copy any file in `scripts/` as a template:
   ```bash
   #!/bin/bash
   # Script: descriptive-name.sh
   # Purpose: One sentence on WHAT BREAKS without this script
   # Usage: ./descriptive-name.sh [args]
   set -euo pipefail

   CHECK="✓"
   CROSS="✗"
   ```
3. `set -euo pipefail` on line 4 or 5. Named variables for every path and threshold —
   no magic numbers. Comments say *why* a line exists, not what it does.
4. It must pass `shellcheck -S style scripts/your-script.sh` with **zero** findings.
   No `# shellcheck disable=` without a comment saying why.
5. Run it. Paste the real output in the PR description.
6. Add a row to the table in `README.md`. If the script is explained on
   [bashsnippets.xyz](https://bashsnippets.xyz), link that page in the **Explained** column;
   if not, leave the column as `—` and we will write the page.

Bug fixes to an existing script: same rules, plus one line in the PR saying what the bug
did on a real box (or would do) — that goes into the site page's "common mistakes" section.

MIT, like everything here. No CLA.
