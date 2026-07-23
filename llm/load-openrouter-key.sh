#!/bin/bash
export OPENROUTER_API_KEY="$(gpg --decrypt ~/ki/openrouter_api_key.gpg 2>/dev/null)"
