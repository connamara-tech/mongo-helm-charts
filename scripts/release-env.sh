#!/bin/bash

die() {
    echo "ERROR: $1"
    git checkout -- VERSION
    exit 1
}

staging_area=`git ls-files --deleted --modified --others --exclude-standard`

if [ ! -z "$staging_area" ]
then
  git status
  die "Add, commit or reset unstaged files before continuing"
fi

bumppatch() {
    v=`cat VERSION`
    echo "${v%.*}.$((${v##*.}+1))" > VERSION
}

bumpminor() {
    v=`cat VERSION`
    maj="${v%.[0-9]*.[0-9]*}"
    min="${v%.[0-9]*}"
    min="$((${min##*.}+1))"

    echo "${maj}.${min}.0" > VERSION
}

release() {
    PACKAGE_VERSION=`cat VERSION`
    git add VERSION || "failed to add changed files"
    git commit -m "$PACKAGE_VERSION" || "failed to commit changed files"
    git tag -a "v$PACKAGE_VERSION" -m "v$PACKAGE_VERSION" || "failed to tag git"

    echo "Release $PACKAGE_VERSION complete, push latest to git to complete"

    $(dirname $0)/release-charts.sh || die "failed to release charts"
}
