#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open app with dev tools
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Developer Utils

# Documentation:
# @raycast.description Open local app with dev tools open in Chrome
# @raycast.author jackdewinter
# @raycast.authorURL https://raycast.com/jackdewinter

open -a "Google Chrome" http://localhost:3000/ --args --auto-open-devtools-for-tabs
