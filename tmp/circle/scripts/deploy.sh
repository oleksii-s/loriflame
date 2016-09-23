#!/usr/bin/env bash

set -e

# If this is pull request, exit.
if [[ ! $CI_PULL_REQUEST == 'false' ]];
then
  echo "::Testing pull request complete."
  exit;
fi

echo "::Deploying"

# Note that you should have exported the Travis Repo SSH pub key, and
# added it into the deploy server keys list.

# Git config user/email
git config --global user.email "oleksii.semko@gmail.com"
git config --global user.name  "Circle CI - Loriflame"

# Checkout existing deployment repo.
cd $DEPLOY_DEST
git clone $DEPLOY_REPO $DEPLOY_DEST

# Deploy to deployment environment.
cd $DEPLOY_DEST
git checkout $DEPLOY_BRANCH
git rm -rf docroot -q
rm -rf docroot
mkdir docroot
cp -a $TEST_BUILD/. $DEPLOY_DEST/docroot
cd $DEPLOY_DEST


# If tmp/hooks exists, then copy all files to a folder outside docroot.
if [ -d $PROJECT_TMP/hooks ]; then
  echo "::Adding Acquia Cloud hooks."
  rm -rf $DEPLOY_DEST/hooks
  cp -a $PROJECT_TMP/hooks $DEPLOY_DEST
fi

if [ -d $PROJECT_TMP/config ]; then
  echo "::Moving config sync dir outside docroot"
  rm -rf $DEPLOY_DEST/config
  cp -a $PROJECT_TMP/config $DEPLOY_DEST
fi

if [[ -d $DEPLOY_DEST/profiles/$PROFILE_NAME/tmp ]]; then
  echo "::Removing non-production files"
  rm -rf $DEPLOY_DEST/profiles/$PROFILE_NAME/tmp
fi

if [[ -d $DEPLOY_DEST/profiles/$PROFILE_NAME/tmp ]]; then
  echo "::Removing non-production files"
  rm -rf $DEPLOY_DEST/profiles/$PROFILE_NAME/tmp
fi

echo "::Adding new files."
git add --all .

# Copy our pull request over.
cd $HOME/$PROFILE_NAME
PULL_REQUEST_MESSAGE=$(git log -n 1 --pretty=format:%s $TRAVIS_COMMIT)
cd $DEPLOY_DEST
git commit -m "${PULL_REQUEST_MESSAGE}

Commit $CIRCLE_TAG"
git push origin $DEPLOY_BRANCH
