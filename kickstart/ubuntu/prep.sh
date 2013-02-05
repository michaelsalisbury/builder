#!/bin/bash
echo Setting up initial softlinks
ln -s ../*.template .
ln -s ../wget-* .
ln -s ../post* .
ln -s ../hd* .
ln -s ../ks* .
ln -s 
cp    local.cfg.template    local.cfg
cp defaults.cfg.template defaults.cfg
cp ../s.template/ks.cfg    local.ks.cfg
