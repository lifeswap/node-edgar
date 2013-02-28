#!/usr/bin/env zsh

#DEBUG='*' \
NODE_PATH=`pwd` NODE_ENV=testing \
	./node_modules/.bin/mocha \
    --timeout 2000 \
		--compilers coffee:coffee-script \
		--reporter progress \
		--require should \
    test/*.coffee \
