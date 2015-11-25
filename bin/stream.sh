#!/bin/bash
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

my_path=`dirname $0`

cd ${my_path}/../lib
bundle exec ruby stream.rb
