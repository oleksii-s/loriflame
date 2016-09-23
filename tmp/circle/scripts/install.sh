#!/usr/bin/env bash

set -e
# Increase max_allowed_packet so it's easier to revert features.
mysql -e "SET GLOBAL max_allowed_packet=128*1024*1024;"

# Install Compass
gem update --system
gem install sass --version "=3.4.12"
gem install compass --version "=1.0.3"

# Run the make script.
echo ">> Running build"

# Pass a commit if we're building a pull-request
if [[ $TRAVIS_PULL_REQUEST == 'false' ]]; then
  BUILD_COMMIT=${TRAVIS_PULL_REQUEST}
else
  BUILD_COMMIT=$(git rev-list HEAD --max-count=1 --skip=1)
  echo ">> Using commit ${BUILD_COMMIT}"
fi

bash tmp/scripts/build.sh $PROFILE_NAME $TEST_BUILD $BUILD_COMMIT

echo ">> Installing Drush integration ..."
cp $CI_ASSETS/$PROJECT_NAME.aliases.drushrc.php $HOME/.drush/$PROJECT_NAME.aliases.drushrc.php
cp $CI_ASSETS/drushrc.php $HOME/.drush/drushrc.php

echo ">> Copy the built site over to the deploy folder ..."
cp -R $TEST_BUILD $DEPLOY_REPO

echo ">> Copy local settings file for Travis env to the test folder ..."
cp $CI_ASSETS/settings.local.php $TEST_BUILD/sites/default/settings.local.php

cd $TEST_BUILD/profiles/$PROFILE_NAME
composer update

cd $TEST_BUILD
# Sync or install the database depending on your needs.
echo  "::Installing development database ..."
drush si $PROFILE_NAME -y

#echo  "::Importing development database"
#drush sql-sync @${PROJECT_NAME}.dev default -y
#drush -y updatedb
#drush -y config-import
#drush cache-rebuild
