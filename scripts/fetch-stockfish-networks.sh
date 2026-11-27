#!/bin/bash
# Downloads the two neural-network files Stockfish 17 needs to evaluate positions.
#
# They're too big for git (the main one is 75 MB), so they're kept out of the repo
# (see .gitignore) and fetched once per clone. CI runs this script too.
#
# Each file is checked against its full SHA-256 fingerprint, so a broken or swapped
# download is rejected instead of quietly changing the engine's scores.
#
# Usage: scripts/fetch-stockfish-networks.sh   (safe to run again; skips good files)

set -euo pipefail

# Variables are written as ${name}, with braces: the Mac's built-in bash (3.2) can
# otherwise read a following "…" as part of the name and stop with "unbound variable".

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
destination="${repo_root}/PittChessCore/Sources/PittChessCore/Engine/Networks"
source_url="https://tests.stockfishchess.org/api/nn"

# name and SHA-256. A network's name is the first 12 characters of its fingerprint.
networks=(
    "nn-1111cefa1111.nnue 1111cefa11116b77161bd4b14dab4c50f26e5920c756f4861592be3dcd6de174"
    "nn-37f18f62d772.nnue 37f18f62d772f3107e1d6aaca3898c130c3c86f2ab63e6555fbbca20635a899d"
)

fingerprint() {
    shasum -a 256 "$1" | cut -d ' ' -f 1
}

mkdir -p "${destination}"

for entry in "${networks[@]}"; do
    read -r name expected <<<"${entry}"
    file="${destination}/${name}"

    if [ -f "${file}" ] && [ "$(fingerprint "${file}")" = "${expected}" ]; then
        echo "✓ ${name} is already here."
        continue
    fi

    echo "↓ Downloading ${name}…"
    partial="${file}.partial"
    curl --fail --location --silent --show-error --retry 3 --output "${partial}" "${source_url}/${name}"

    actual="$(fingerprint "${partial}")"
    if [ "${actual}" != "${expected}" ]; then
        rm -f "${partial}"
        echo "✗ ${name} has the wrong fingerprint." >&2
        echo "  expected ${expected}" >&2
        echo "  got      ${actual}" >&2
        exit 1
    fi

    mv "${partial}" "${file}"
    echo "✓ ${name} downloaded and checked."
done
