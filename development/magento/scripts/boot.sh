#!/bin/bash

# If EFS wasn't mounted when image was created this directory can exist which causes issues with mounting
rm -rf $WEBSITE_PATH/app/etc/env.php

#safety measure to ensure we have magento available for the cli
docker restart cron

#ensure codedeploy agent is running - it should be already
service codedeploy-agent start

## If a desired Elastic IP is set attempt to assign it if it isn't already in use
if [ -n "$WEBSITE_DESIREDIP" ]
then
    IP_OWNER=`aws ec2 describe-addresses --public-ips $WEBSITE_DESIREDIP | grep "InstanceId" | cut -d":" -f2 | cut -d'"' -f2 | uniq`

    if [ "$IP_OWNER" != "" ]
    then
        echo 'desired IP already used so ignoring'
    else
        echo 'desired IP not visible so attaching'
        aws ec2 associate-address --instance-id $EC --public-ip $WEBSITE_DESIREDIP --allow-reassociation
    fi
fi

# Configure cloud watch logging
if [ -n "$CLOUDWATCH_LOGS_CONFIG" ]
then
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:$CLOUDWATCH_LOGS_CONFIG -s
fi

# Saftey check to ensure www can talk to docker, this should have already happened
usermod -a -G docker www

#ensure containers are started
echo 'Starting docker containers'
/bin/sh $BUILD_PATH/common/scripts/startall.sh
