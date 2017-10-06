#!/bin/bash

rm config/init.sh
touch config/init.sh
vagrant destroy -f
rm -rf .vagrant