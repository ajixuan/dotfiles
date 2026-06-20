#!/bin/bash
# 1. Run formatter/linter
npx prettier --write "$1"
# 2. Run related tests with fresh context
npm test "$1"

