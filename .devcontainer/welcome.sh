#!/bin/bash
echo "------------------------------------------------"
# Run figlet via npx (from package.json)
npx figlet "READY!"
# Run cowsay via python
python3 -m cowsay "Environment is healthy"
echo "------------------------------------------------"
# Confirm tree utility is installed
tree --version
