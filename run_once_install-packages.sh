#!/bin/sh

# Python

brew install python
export PATH=/usr/local/opt/python/libexec/bin:$PATH
curl -sSL https://install.python-poetry.org | python3 -
