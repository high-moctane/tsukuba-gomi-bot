#!/bin/bash
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

my_path=`dirname $0`

cd ${my_path}/../lib

while :
do
    bundle exec ruby regular_tweet.rb

    # 0-10 min sleep
    sleep `expr $RANDOM % 600`

    # 1h30m sleep
    sleep 9000
done

