#!/bin/bash
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# my_path=`readlink -f $0`
my_path=`dirname $0`

bundle exec ruby ${my_path}/../lib/regular_tweet.rb
