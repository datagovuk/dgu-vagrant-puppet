#/usr/bin/env bash

directories=`find . -mindepth 1 -maxdepth 1 -type d`

echo 'Checking local branches...'
for repo in $directories ; do
  cd $repo
  if ! git diff-index --quiet HEAD --; then
      echo $repo has outstanding changes. Refusing to rebase.
      exit 1
  fi
  cd ..
done
echo "No outstanding changes found. Rebasing all..."

set -x

for repo in $directories ; do
  cd $repo
  git pull --rebase origin
  cd ..
done
