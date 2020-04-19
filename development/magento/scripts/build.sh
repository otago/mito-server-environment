#!/bin/bash

#set up motd graphic
cp -f $BUILD_PATH/$WEBSITE_ENV_TYPE/$WEBSITE_SERVER_TYPE/scripts/motd.txt /etc/update-motd.d/30-banner
update-motd

# symlink codedeploy agent config to environment config
rm -rf /etc/codedeploy-agent/conf/codedeployagent.yml
ln -s $BUILD_PATH/common/config/codedeploy/codedeployagent.yml /etc/codedeploy-agent/conf/codedeployagent.yml

# in .bashrc read in our custom file from within the project
printf "if [ -f $BUILD_PATH/$WEBSITE_ENV_TYPE/magento/scripts/.bashrc ]; then \n\
    . $BUILD_PATH/$WEBSITE_ENV_TYPE/magento/scripts/.bashrc  \n\
fi \n\n" >> /home/www/.bashrc
source /home/www/.bashrc
shopt -s expand_aliases

# symlink to logrotate config
ln -s $BUILD_PATH/$WEBSITE_ENV_TYPE/magento/config/logrotate/web /etc/logrotate.d/web
chmod 0444 /etc/logrotate.d/web

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

mkdir /mnt/web

# If an NFS / EFS server is defined in userdata, Install nfs and set up fstab to mount media volume
if [ -n "$EFS_ID" ]
then
    echo "$EFS_ID:/ /mnt/web efs nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
    # Set up cron to check nfs status
    echo "* * * * * /bin/sh ${BUILD_PATH}/${WEBSITE_ENV_TYPE}/${WEBSITE_SERVER_TYPE}/scripts/nfs-check.sh &>> ${LOG_PATH}/nfs-check.log" >> /var/spool/cron/root
fi

#mount all volumes and wait
mount -a
sleep 30 

# This is required to mount the EBS/nfs directory as a volume in docker
service docker restart

## Symlink Magento logs to log directory
mkdir -p ${LOG_PATH}/magento
mkdir -p ${LOG_PATH}/php
mkdir -p ${LOG_PATH}/nginx
chmod -R 777 ${LOG_PATH}


# Make entire project directory owned by www user incase anything important was created owned by root user
#chown -R www:www $WEBSITE_PATH
chown -R www:www $BUILD_PATH
#chown -R www:www /mnt/web #can we somehow not do this?


# pull and start docker containers
docker-compose pull
docker-compose up -d

sleep 120 

docker ps -a
echo "DONE"


# On successfull build create a new AMI image
aws ec2 create-image --instance-id $EC --name "${WEBSITE_ENV_TYPE}-${WEBSITE_SERVER_TYPE}-`date '+%Y-%m-%d_%H-%M-%S'`" --description "automated AMI build" --no-reboot

