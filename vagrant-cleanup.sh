#!/bin/bash

rm config/init.bash
touch config/init.bash
vagrant destroy -f
rm -rf .vagrant