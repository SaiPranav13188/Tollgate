# Tollgate

A native macOS app that finds the MCP servers set up on your Mac, checks their configs for risky settings, and gives each one a 0–100 score with a fix for every problem.

![Tollgate showing a server with a leaked key and a shell launch](docs/screenshot.png)

Tollgate **reads config files only**. It never starts a server, never changes a file and never uploads anything.

## What it checks

| Rule | Severity | Detects | Fix |
|---|---|---|---|
| CFG-001 | High | A secret-looking value written directly in a server's `env` | Load it from the Keychain or a secrets manager, and rotate it |
| CFG-002 | Medium | A package launched without a pinned version (`npx -y pkg`, `pkg@latest`, `uvx pkg`, `^1.2` ranges) | Pin an exact version |
| CFG-003 | High | A remote `url` over plain `http://` (not localhost) | Use HTTPS |
| CFG-004 | Medium | A server launched through a shell (`sh -c`, `bash -c`) | Run the executable directly |
| CFG-005 | High | A filesystem server given `/`, `~` or your whole home folder | Give it one project folder |
| CFG-006 | Low | A server executable or script that other users can modify | Use a path only you can change |
| SEC-001 | Critical | A known key format (GitHub, AWS, Google, Anthropic, OpenAI, private key blocks) anywhere in the config | Remove it and revoke the key |

Secrets are always redacted (`sk-pro...ke`) in the app and in the JSON export. A test checks that a full secret never appears in either.

## Where it looks

- Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Cursor: `~/.cursor/mcp.json`
- Claude Code: `~/.claude.json` (global and per-project servers), plus each known project's `.mcp.json`
- Anything you add with **Add Config…**: a config file, or a folder containing `.mcp.json`, `mcp.json`, `.cursor/mcp.json`, `.vscode/mcp.json` or `claude_desktop_config.json`

Missing or broken files are skipped and shown with a note in the sidebar.

## Scoring

Each category (config, secrets, tools, privacy) starts at 100 and loses points per finding: critical 25, high 12, medium 5, low 1. The total is a weighted average (secrets 35%, config 30%, tools 25%, privacy 10%). Any critical finding caps the total at 59. Grades: 85+ Good, 60–84 Needs work, below 60 At risk.

Tools and privacy are not checked in v1, so they show `--` in the app.

## Accuracy

Tollgate's rules are heuristics, so they are measured. [`EvalSet/`](EvalSet/) holds 36 labelled configs (69 servers): copies of public README examples, deliberately insecure configs with fake keys, and secure ones. The `EvalTests` test runs all of them and prints precision and recall per rule.

| Rule | TP | FP | FN | Precision | Recall |
|---|---|---|---|---|---|
| CFG-001 | 9 | 2 | 5 | 82% | 64% |
| CFG-002 | 14 | 0 | 0 | 100% | 100% |
| CFG-003 | 3 | 0 | 1 | 100% | 75% |
| CFG-004 | 4 | 0 | 0 | 100% | 100% |
| CFG-005 | 3 | 0 | 1 | 100% | 75% |
| CFG-006 | 3 | 0 | 0 | 100% | 100% |
| SEC-001 | 9 | 0 | 2 | 100% | 82% |
| **All** | **45** | **2** | **9** | **96%** | **83%** |

**Before and after.** In the first run, CFG-002 (unpinned packages) was the worst rule at 62% precision and 71% recall. It misread `uvx --from pkg==1.0`, `pipx run pkg==1.0` and `npx --package=pkg@1.0` as unpinned, and missed `bunx` and `^`/`~` version ranges. After teaching it each launcher's flags and pin syntax, it reached 100% / 100%, and the overall score went from 84% precision and 76% recall to 96% and 83%. Full lists of mistakes: [before](EvalSet/results-before.md), [after](EvalSet/results-after.md).

**Known gaps** (the remaining misses):
- CFG-001 does not look at secrets in `headers`, in `args`, or inside connection strings like `postgres://user:password@host`, and it raises false alarms on placeholders like `xoxb-your-bot-token` and on key names that only look secret (`PRIMARY_KEY_FIELD`, `SSH_KEY_PATH`).
- SEC-001 does not yet know fine-grained GitHub tokens (`github_pat_`) or Slack tokens (`xoxb-`).
- CFG-003 misses `http://` URLs passed to `mcp-remote` as an argument.
- CFG-005 misses a home folder mounted into a Docker container.

## Build and run

Requirements: macOS 15 or later and Xcode 16 or later.

```sh
open Tollgate.xcodeproj        # then Cmd+R
```

Run the tests (needs the full Xcode toolchain, not only the Command Line Tools):

```sh
cd Packages/MCPShieldCore
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

To try it without touching your real configs, generate the evaluation configs with fake secrets and add any of the folders in the app:

```sh
scripts/make-demo-configs.sh   # writes to build/demo-configs
```

The App Sandbox is off because Tollgate has to read config files that belong to other apps.

### Opening a downloaded build

Release builds are not signed with an Apple Developer ID, so macOS will warn you the first time. Right-click `Tollgate.app`, choose **Open**, then confirm **Open**.

## Project layout

```
MCPShieldApp/                 SwiftUI app (views and view model only)
Packages/MCPShieldCore/       All the logic, no UI: discovery, rules, secrets, scoring, report
  Tests/MCPShieldCoreTests/   Unit tests and the evaluation run
EvalSet/                      Labelled configs, labels.json, before/after results
scripts/                      Demo-config generator
```

## Responsible use

- Tollgate reads files. It never runs, changes or uploads them.
- Only scan configs and servers that you own or trust. Do not point it at other people's systems.
- Findings never show full secrets.
- If you find a problem in someone's public project, report it privately to the maintainer first.
- Everything stays on your Mac. No account, no upload.

Scores are heuristics measured on a small labelled set. They are not a guarantee that a server is safe.

## Roadmap

- **v1.5**: with your explicit approval, start one server, list its tools (`initialize` and `tools/list` only, never tool calls) and check tool names for risky actions and personal data.
- **v2**: remote HTTP servers, SARIF export, a command-line version, git history scan.
