# .bashrc

# Docker aliases
alias dockerstartall='/bin/sh $BUILD_PATH/common/scripts/startall.sh'
alias dockerstopall='/bin/sh $BUILD_PATH/common/scripts/stopall.sh'

alias magento='docker exec --user www -ti cron php /var/www/src/bin/magento'
alias mage='docker exec --user www cron php /var/www/src/bin/magento'
alias magerun='docker exec --user www -ti cron magerun2 --skip-root-check --root-dir=/var/www/src'
alias mr='docker exec --user www cron magerun2 --skip-root-check --root-dir=/var/www/src'
alias docker-compose='docker-compose -f $BUILD_PATH/$WEBSITE_ENV_TYPE/$WEBSITE_SERVER_TYPE/docker-compose.yml -p mito'

# Utility aliases
alias healthcheck='curl -i http://localhost/healthcheck.php'