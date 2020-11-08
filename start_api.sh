#!/bin/sh
nginx
echo Nginx running
echo Starting Bot API
/app/telegram-bot-api --local --http-port=8080 --temp-dir=/tmp/tgbot --dir=/file --username=botapi
echo Exiting...
nginx -s stop