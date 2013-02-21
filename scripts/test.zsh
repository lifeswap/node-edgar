#!/usr/bin/env zsh

#DEBUG='*' \
NODE_PATH=`pwd` ENV=TEST \
	./node_modules/.bin/mocha \
    --timeout 2000 \
		--compilers coffee:coffee-script \
		--reporter progress \
		--require should \
    test/*.coffee \
