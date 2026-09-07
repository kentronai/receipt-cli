# Receipt CLI

Public binary releases for `receipt`, the Kentron AI CLI that connects Receipt
workspace resources and runs the Receipt MCP bridge.

`receipt connect` lets a signed-in user connect workspace resources such as
AWS, Google Cloud, GitHub, GitLab, Slack, Notion, Jira, Linear, HubSpot,
Stripe, Datadog, Sentry, Cloudflare, Vercel, Terraform Cloud, Incident.io,
Azure DevOps, and Confluence through Receipt's hosted Nango-backed Connect
flow. Receipt stores only encrypted org-scoped connection references.

Run `receipt --help` for the full list of supported providers.

> **Upgrading from `v0.1.0-preview.6`?** That build could not sign in on a
> fresh machine (`receipt setup` failed with "production URL is not configured
> yet"). Re-run the install command below to get `v0.1.0-preview.7`, which
> works out of the box. Your saved sessions in `~/.receipt` are kept.

## 1. Install the CLI

```bash
curl -fsSL https://raw.githubusercontent.com/kentronai/receipt-cli/main/install.sh | bash
```

The binary is installed to `~/.local/bin/receipt`. If that directory is not
already on your `PATH`, the installer prints the exact line to add. To use it
in the current shell right away:

```bash
export PATH="$HOME/.local/bin:$PATH"
receipt --version
receipt doctor
```

`receipt doctor` is read-only: it shows which Receipt host the CLI will talk
to, probes that it is reachable, and reports whether you are signed in. It
never opens a browser and never prints your token. On a fresh install it ends
with `Run 'receipt setup' to sign in.`

The hosted Receipt origin (`https://app.kentron.ai`) is built into the binary,
so there is nothing to configure for the hosted app.

## 2. Sign in

```bash
receipt setup
receipt workspace current
```

`receipt setup` opens your browser, where you approve the CLI with your
Receipt account and organization. It saves a session for this machine, prints
the connector catalog, and installs the Claude observer when a release bundles
it. The session is bound to your organization's **Default** workspace; use
`receipt workspace use <workspace>` to switch.

Related commands:

```bash
receipt login           # sign in only, without the connector summary
receipt logout          # remove the saved session
receipt setup --fresh-login   # force a new browser sign-in
```

The saved token lasts 12 hours. When it expires, `receipt setup` notices and
signs you in again; you never have to clear anything by hand.

## 3. Connect integrations

In Receipt:

1. Open *Organization Settings → MCP Gateway*.
2. Select or create a workspace.
3. Open the workspace's *Integrations* page.
4. Connect the providers you want MCP to access.
5. Return to the workspace *Overview* page.

Or connect directly from the CLI:

```bash
receipt connect aws
receipt connect gcp
receipt connect gitlab
receipt connect datadog
receipt connect status
receipt connect disconnect --provider aws
```

`receipt connect` commands reuse the session saved by `receipt setup`; they do
not open a second browser sign-in. Connections created from the CLI are named
`default` and live in the Default workspace.

## 4. Install for Codex

```bash
receipt tools list
receipt mcp config codex
receipt mcp install codex
receipt mcp status codex
```

Restart Codex or reload its MCP servers afterward. The generated configuration
never contains your session token; Codex launches `receipt mcp serve`, which
reads the saved session when it starts.

## Other MCP clients

Generate a generic configuration:

```bash
receipt mcp config generic --output receipt-mcp.json
```

Import `receipt-mcp.json` into any client supporting local STDIO MCP
servers, then refresh its tool list.

## Dev or self-hosted deployments

Skip this on the hosted app. To point the CLI at another Receipt deployment:

```bash
export RECEIPT_CONNECT_PUBLIC_GATEWAY_URL=https://receipt.example.com
receipt doctor
receipt setup
```

or pass `--server-url https://receipt.example.com` on the command. Add
`--auth-url` when the web sign-in origin differs from the gateway.

For a local Receipt stack use the `local` target. It defaults to gateway
`http://127.0.0.1:8787` and sign-in `http://127.0.0.1:3000`; override them with
`RECEIPT_CONNECT_LOCAL_SERVER_URL` and `RECEIPT_CONNECT_LOCAL_AUTH_URL`, then
run `receipt doctor --target local` and `receipt setup --target local`. The
target you set up most recently is the one `mcp`, `workspace`, and `tools`
talk to.

The binary ignores any `.env` file in your working directory, so a project's
environment file cannot redirect the CLI.

## Installer options

The installer reads these environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `RECEIPT_CLI_VERSION` | `v0.1.0-preview.7` | Release tag to install |
| `RECEIPT_CLI_REPO` | `kentronai/receipt-cli` | Repository to fetch release assets from |
| `RECEIPT_CLI_BIN_DIR` | `$HOME/.local/bin` | Install directory |
| `RECEIPT_CLI_BIN` | `$RECEIPT_CLI_BIN_DIR/receipt` | Full path of the installed binary |

For example, to install a specific version somewhere else:

```bash
curl -fsSL https://raw.githubusercontent.com/kentronai/receipt-cli/main/install.sh \
  | RECEIPT_CLI_VERSION=v0.1.0-preview.7 RECEIPT_CLI_BIN_DIR=/usr/local/bin bash
```

The variables are read by the shell that runs the script, so in a piped
install they go on `bash`, not on `curl`.

## Upgrading

Re-run the install command. It overwrites the existing binary in place and
leaves `~/.receipt` untouched, so you stay signed in.

If you installed an earlier build that was named `kentronai`, remove the stale
binary after upgrading, and re-run `receipt mcp install codex` so the MCP entry
points at the new path:

```bash
rm -f ~/.local/bin/kentronai
receipt mcp install codex
```

## Uninstalling

```bash
receipt mcp remove codex
receipt logout
rm -f ~/.local/bin/receipt
```

## Troubleshooting

Start with `receipt doctor`; it names the fix for the common cases:

```bash
receipt --version
receipt doctor --json
receipt workspace current --json
receipt tools list
receipt mcp status codex
```

- `receipt: command not found` — `~/.local/bin` is not on your `PATH`; see
  step 1. If more than one `receipt` is installed, `command -v receipt` shows
  which one wins.
- `not signed in; run 'receipt setup' first` — run `receipt setup`.
- `unauthorized` from every command — the 12-hour token expired or was
  rejected. `receipt doctor` shows it as expired; run `receipt setup`.
- `receipt doctor` reports the gateway or sign-in origin as unreachable —
  check the URL, or the `RECEIPT_CONNECT_*` variables if you overrode it.
- `receipt tools list` is empty — no provider is connected in the workspace
  your session is bound to. Connect one (step 3) and re-list.

## Supported Platforms

- macOS Apple Silicon: `darwin-arm64`
- macOS Intel: `darwin-x64`
- Linux x64: `linux-x64`
- Linux arm64: `linux-arm64`

## Verifying a download

Every release publishes a `checksums.txt` alongside the tarballs, and the
installer verifies the SHA-256 of the asset before installing it. To check a
download by hand:

```bash
curl -fsSLO https://github.com/kentronai/receipt-cli/releases/download/v0.1.0-preview.7/receipt-darwin-arm64.tar.gz
curl -fsSLO https://github.com/kentronai/receipt-cli/releases/download/v0.1.0-preview.7/checksums.txt
shasum -a 256 -c --ignore-missing checksums.txt
```

## What Is In This Repo

This repository contains only the public installer and release artifacts for
the connect-only CLI. The private Kentron AI application source is not
published here.
