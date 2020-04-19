#!/bin/sh

cd $BUILD_PATH/$WEBSITE_ENV_TYPE/$WEBSITE_SERVER_TYPE
docker-compose stop
docker-compose rm -f
