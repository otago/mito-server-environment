#!/bin/bash

# Run docker containers
cd $BUILD_PATH/$WEBSITE_ENV_TYPE/$WEBSITE_SERVER_TYPE
docker-compose up -d

