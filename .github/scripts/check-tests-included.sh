#!/usr/bin/env bash
# Fails a pull request that changes Swift code without changing any tests.
#
# "Code" = .swift files outside any *Tests/ folder (Package.swift excluded).
# "Tests" = .swift files inside a folder whose name ends in "Tests/",
#           e.g. PittChessCore/Tests/... or PittChessTests/...
#
# Escape hatch: add the "no-tests-needed" label to the PR (renames, UI-only tweaks).
set -euo pipefail

if [ "${EVENT_NAME:-}" != "pull_request" ]; then
  echo "Not a pull request; nothing to check."
  exit 0
fi

if [ "${SKIP_LABEL:-false}" = "true" ]; then
  echo "PR has the 'no-tests-needed' label; skipping the check."
  exit 0
fi

changed=$(git diff --name-only "$BASE_SHA...$HEAD_SHA")

code_changes=$(printf '%s\n' "$changed" \
  | grep -E '\.swift$' \
  | grep -vE '(^|/)[^/]*Tests/' \
  | grep -vE '(^|/)Package\.swift$' || true)

test_changes=$(printf '%s\n' "$changed" \
  | grep -E '(^|/)[^/]*Tests/.*\.swift$' || true)

if [ -z "$code_changes" ]; then
  echo "No Swift code changes; no tests required."
  exit 0
fi

if [ -n "$test_changes" ]; then
  echo "Code changes come with test changes:"
  printf '  %s\n' $test_changes
  exit 0
fi

echo "::error::This PR changes Swift code but no tests."
echo "Changed code files:"
printf '  %s\n' $code_changes
echo
echo "Add or update tests in PittChessCore/Tests/ or PittChessTests/."
echo "If this change really needs no tests (a rename, a UI-only tweak), add the"
echo "'no-tests-needed' label to the PR."
exit 1
