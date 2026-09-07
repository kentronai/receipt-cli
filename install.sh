#!/usr/bin/env sh
set -eu

RECEIPT_CLI_VERSION="${RECEIPT_CLI_VERSION:-v0.1.0-preview.7}"
RECEIPT_CLI_REPO="${RECEIPT_CLI_REPO:-kentronai/receipt-cli}"
RECEIPT_CLI_BIN_DIR="${RECEIPT_CLI_BIN_DIR:-${HOME}/.local/bin}"
RECEIPT_CLI_BIN="${RECEIPT_CLI_BIN:-${RECEIPT_CLI_BIN_DIR}/receipt}"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

platform() {
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    *)
      echo "Unsupported OS: $os" >&2
      exit 1
      ;;
  esac

  case "$arch" in
    arm64|aarch64) arch="arm64" ;;
    x86_64|amd64) arch="x64" ;;
    *)
      echo "Unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac

  printf "%s-%s" "$os" "$arch"
}

verify_checksum() {
  file="$1"

  # Select the checksum line by exact filename match. A grep pattern would treat
  # the dots in the asset name as wildcards, and an empty match must be a hard
  # error: BSD sha256sum exits 0 when it is handed no checksum lines at all.
  line="$(awk -v f="$file" '$2 == f { print; found = 1 } END { exit !found }' checksums.txt)" || {
    echo "checksums.txt has no entry for ${file}" >&2
    exit 1
  }

  if command -v shasum >/dev/null 2>&1; then
    printf '%s\n' "$line" | shasum -a 256 -c -
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s\n' "$line" | sha256sum -c -
  else
    echo "Missing required command: shasum or sha256sum" >&2
    exit 1
  fi
}

fetch() {
  curl -fsSLO "$1" || {
    echo "Download failed: $1" >&2
    echo "  repo=${RECEIPT_CLI_REPO} version=${RECEIPT_CLI_VERSION}" >&2
    echo "  Check that this release and asset exist." >&2
    exit 1
  }
}

need curl
need tar
need awk

# platform() exits from a subshell here, so check the result at the call site
# rather than relying on set -e alone.
target="$(platform)" || exit 1
[ -n "$target" ] || exit 1
asset="receipt-${target}.tar.gz"
base_url="https://github.com/${RECEIPT_CLI_REPO}/releases/download/${RECEIPT_CLI_VERSION}"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

# Derive the directory from the final binary path so that overriding
# RECEIPT_CLI_BIN alone still creates the right directory.
bin_dir="$(dirname "$RECEIPT_CLI_BIN")"
mkdir -p "$bin_dir"

cd "$tmp_dir"
fetch "${base_url}/${asset}"
fetch "${base_url}/checksums.txt"
verify_checksum "$asset"
tar -xzf "$asset"
install -m 0755 "receipt-${target}" "$RECEIPT_CLI_BIN"

echo "Installed receipt CLI at ${RECEIPT_CLI_BIN}"

case ":${PATH}:" in
  *":${bin_dir}:"*)
    echo "Run 'receipt --help' to get started."
    ;;
  *)
    echo ""
    echo "${bin_dir} is not on your PATH. Add it, then run 'receipt --help':"
    echo ""
    case "${SHELL:-}" in
      */fish)
        echo "  fish_add_path ${bin_dir}"
        ;;
      *)
        case "${SHELL:-}" in
          */zsh) profile="${ZDOTDIR:-$HOME}/.zshrc" ;;
          */bash) profile="${HOME}/.bashrc" ;;
          *) profile="${HOME}/.profile" ;;
        esac
        echo "  echo 'export PATH=\"${bin_dir}:\$PATH\"' >> ${profile}"
        echo "  export PATH=\"${bin_dir}:\$PATH\""
        ;;
    esac
    echo ""
    ;;
esac
