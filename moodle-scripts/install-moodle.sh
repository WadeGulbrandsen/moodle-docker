#!/usr/bin/env bash

version=$(echo "$MOODLE_VERSION" | tr -d .)
git_branch="MOODLE_${version}_STABLE"

echo "Installing Moodle $MOODLE_VERSION"
echo "Changing directory to /var/www"
cd /var/www || exit 1

echo "Cloning Moodle from git"
git clone git://git.moodle.org/moodle.git
cd moodle || exit 1

echo "Checking out $git_branch"

if [[ $(git branch -a) == *"$git_branch"* ]]; then
  git branch --track "$git_branch" "origin/$git_branch"
  git checkout "$git_branch"
else
  exit 1
fi
