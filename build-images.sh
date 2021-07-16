#!/usr/bin/env bash

declare -A builds
builds[MOODLE_38_STABLE]="3.8"
builds[MOODLE_39_STABLE]="3.9 lts"
builds[MOODLE_310_STABLE]="3.10"
builds[MOODLE_311_STABLE]="3.11 latest"

# Need this to preserver order
branches=(MOODLE_38_STABLE MOODLE_39_STABLE MOODLE_310_STABLE MOODLE_311_STABLE)

repos=(moodle-docker wadegulbrandsen/moodle-docker)
remotes=(wadegulbrandsen/moodle-docker)

echo "Building images..."

for branch in "${branches[@]}"
do
  echo "Building $branch..."
  command="docker build --build-arg MOODLE_BRANCH=$branch"
  for tag in ${builds[$branch]}
  do
    for repo in "${repos[@]}"
    do
      command="$command -t $repo:$tag"
    done
  done
  command="$command ."
  eval "$command"
  for tag in ${builds[$branch]}
  do
    for remote in "${remotes[@]}"
    do
      docker push "$remote:$tag"
    done
  done
done
