#!/bin/bash
echo Setting up initial softlinks
ln -s ../../../builder/builder.sh .
ln -s ../DEB/* .
echo Copying templates
cp             local.cfg.template    local.cfg
cp          defaults.cfg.template defaults.cfg
cp                 ks.sh.template       ks.sh
cp ../preseed/preseed.sh.template  preseed.sh
