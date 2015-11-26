#!/bin/bash
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

my_path=`dirname $0`

cd ${my_path}/../lib

while :
do
    bundle exec ruby friendship.rb

    # 0-20 min sleep
    sleep `expr $RANDOM % 1200`

    # 1h50m sleep
    sleep 6600
done

