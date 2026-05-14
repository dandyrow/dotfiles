#!/usr/bin/env sh
#
# Simple script to copy stdin to the clipboard.
# Uses wl-copy, xclip, or xsel depending on what's available.

if command -v wl-copy > /dev/null 2>&1; then
  wl-copy
elif command -v xclip > /dev/null 2>&1; then
  xclip -selection clipboard
elif command -v xsel > /dev/null 2>&1; then
  xsel --clipboard --input
fi
