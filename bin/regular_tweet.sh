#!/bin/bash
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

my_path=`dirname $0`

cd ${my_path}/../src

while :
do
    bundle exec ruby regular_tweet.rb

    # 0-20 min sleep
    sleep `expr $RANDOM % 1200`

    # 1h20m sleep
    sleep 4800
done

