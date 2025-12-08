#!/bin/bash
# Example script showing how to use pglaf-gitpull

# Basic usage - clone a new repository
python3 gitpull.py https://github.com/octocat/Hello-World.git /path/to/local/folder

# Update an existing repository
python3 gitpull.py https://github.com/octocat/Hello-World.git /path/to/local/folder

# Show help
python3 gitpull.py --help

# Example: Clone the Project Gutenberg repository (if this was the intended use case)
# python3 gitpull.py https://github.com/gutenbergtools/some-repo.git /var/www/gutenberg
