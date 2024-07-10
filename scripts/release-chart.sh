#!/bin/sh

die() {
    echo "ERROR: $1"
    git checkout -- VERSION
    exit 1
}

if [ -z "$1" ]
then
  die "Must provide chart name to release"
fi

staging_area=`git ls-files --deleted --modified --others --exclude-standard`
if [ ! -z "$staging_area" ]
then
  git status
  die "Add, commit or reset unstaged files before continuing"
fi

VERSION=`cat VERSION`
APP_VERSION=`sed -E "s/^(.*)-([0-9]+)$/\1/g" charts/$1/CHART_VERSION` || die "failed to get app version"
CHART_RELEASE=`sed -E "s/^(.*)-([0-9]+)$/\2/g" charts/$1/CHART_VERSION` || die "failed to get chart release"

if [ "$VERSION" = "$APP_VERSION" ]
then
  CHART_RELEASE=`expr $CHART_RELEASE + 1` || die "error bumping chart release"
else
  CHART_RELEASE="1"
  APP_VERSION=$VERSION
fi

CHART_VERSION="$APP_VERSION-$CHART_RELEASE"
echo $CHART_VERSION > charts/$1/CHART_VERSION

if [ "$(uname -s)" = "Darwin" ]
then
find charts/$1/ -name Chart.yaml -exec sed -i '' s/^appVersion:.*$/appVersion:\ \"$APP_VERSION\"/g {} + || die "failed to bump chart app versions"
find charts/$1/ -name Chart.yaml -exec sed -i '' s/^version:.*$/version:\ \"$CHART_VERSION\"/g {} + || die "failed to bump chart app versions"
else
find charts/$1/ -name Chart.yaml -exec sed -i s/^appVersion:.*$/appVersion:\ \"$APP_VERSION\"/g {} + || die "failed to bump chart app versions"
find charts/$1/ -name Chart.yaml -exec sed -i s/^version:.*$/version:\ \"$CHART_VERSION\"/g {} + || die "failed to bump chart app versions"
fi

git add charts || die "failed to add changed files"

git commit -m "chart $CHART_VERSION" || die "failed to commit changed files"
git tag -a "chart-v$CHART_VERSION" -m "chart-v$CHART_VERSION" || die "failed to tag git"

echo "Chart Release $CHART_VERSION complete, push latest to git to complete"
