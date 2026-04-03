#!/bin/sh

zip -r -o -X -ll QTUN-Magisk-$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'CHANGELOG.md' -x 'update.json' -x 'build.sh' -x '.github/*' -x 'QTUN/run/*'