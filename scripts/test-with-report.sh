#!/usr/bin/env bash

set -u

cd "$(dirname "$0")/.."

REPORT="frontend/forge-results.json"
TEMP_REPORT="$(mktemp)"

echo "======================================"
echo " VaultGuard — Foundry Test Runner"
echo "======================================"
echo ""
echo "Running Foundry tests..."
echo ""

if forge test --json > "$TEMP_REPORT"; then
  TEST_EXIT_CODE=0
else
  TEST_EXIT_CODE=$?
fi

if [ -s "$TEMP_REPORT" ] && python3 -m json.tool "$TEMP_REPORT" >/dev/null 2>&1; then
  mv "$TEMP_REPORT" "$REPORT"
  echo "Report updated: $REPORT"
else
  rm -f "$TEMP_REPORT"
  echo "WARNING: Foundry did not produce valid JSON."
  echo "The previous report, if any, has been preserved."
fi

echo ""

if [ "$TEST_EXIT_CODE" -eq 0 ]; then
  echo "Foundry finished successfully."
  echo "Open VaultGuard's Security Tests page and import $REPORT."
else
  echo "Foundry exited with code $TEST_EXIT_CODE."
  echo "Check the test output and investigate any failures."
fi

exit "$TEST_EXIT_CODE"
