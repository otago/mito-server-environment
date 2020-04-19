shopt -s expand_aliases
source /home/www/.bashrc
set -e

NEW_CODE=/home/www/build
CURRENT_CODE=/home/www/${WEBSITE_DOMAIN}/magento
PREVIOUS_CODE=/home/www/${WEBSITE_DOMAIN}/previous
DISCARDED_CODE=/home/www/${WEBSITE_DOMAIN}/discard


echo "--------------------------"
echo "Begin After Install Script"
echo "--------------------------"

#ensure volumes are mounted in case of first boot
# mount -a

echo 'moving code'
if [ -d ${PREVIOUS_CODE} ]; then
  mv ${PREVIOUS_CODE} ${DISCARDED_CODE}
fi

if [ -d ${CURRENT_CODE} ]; then
  mv ${CURRENT_CODE} ${PREVIOUS_CODE}
fi

if [ -d ${NEW_CODE} ]; then
  mv ${NEW_CODE} ${CURRENT_CODE}
fi

echo "checking docker availability"
maxattempts=30
attempt=0
while [ $attempt -le 59 ]; do
    attempt=$(( $attempt + 1 ))
    result=$(systemctl show --property ActiveState docker)
    if grep -q 'inactive' <<< $result ; then
      echo "Waiting for docker to be up (attempt: $attempt)..."
      sleep 5
      if (( $attempt > $maxattempts )); then
          echo "Cannot connect to docker, failing script"
          exit 1;
      fi
    else
        echo "docker is up"
        break;
    fi
done

# run as a saftey measure to ensure all required containers are available
#docker-compose up -d

echo 'enabling maintenance'
mkdir -p ${PREVIOUS_CODE}/var && touch ${PREVIOUS_CODE}/var/.maintenance.flag
mkdir -p ${CURRENT_CODE}/var/tmp && touch ${CURRENT_CODE}/var/.maintenance.flag

echo 'fixing permissions'
chown -R www:www ${CURRENT_CODE}

# If EFS wasn't mounted when image was created this directory can exist which causes issues with mounting
rm -rf $WEBSITE_PATH/app/etc/env.php

# restarting cron container so it contains latest code
echo 'restarting containers'
docker-compose restart cron

if [ -e ${CURRENT_CODE}/composer.json ]
then

  # test if setups need to run NOTE: Always returning true currently due to https://github.com/magento/magento2/issues/19597
  # @todo this also fails setup script as set to fail on error, need to do this without stopping further execution function maybe
  #message=$(mage setup:db:status --no-ansi 2>&1 >/dev/null)
  #if [[ ${message:0:3} == "All" ]];
  #then
    # nothing to do, no setups required
   # echo 'skipping setup scripts'
  #else
      echo 'running setup scripts'
      mage setup:upgrade --keep-generated
  #fi

   echo 'restarting containers'
   docker-compose restart php
   docker-compose restart nginx

   echo 'clearing caches'
   mage absolute:cache-bust:static
   mage cache:clean full_page

    echo 'disabling maintenance'
    rm ${CURRENT_CODE}/var/.maintenance.flag

    echo 'fixing permissions'
    chown -R www:www /home/www/${WEBSITE_DOMAIN}/log

    echo 'tidying'
    if [ -d ${DISCARDED_CODE} ]; then
      rm -rf ${DISCARDED_CODE}
    fi
#    docker-compose restart cron
else
    echo "magento code doesn't exist"
fi
echo "-------------------"
echo "Deployment Complete"
echo "-------------------"
