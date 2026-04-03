#!/bin/sh

zip -r -o -X QTUN-Magisk-$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'CHANGELOG.md' -x 'update.json' -x 'build.sh' -x '.github/*' -x 'QTUN/run/*' -x 'QTUN/bin/.bin' -x '.gitignore'
