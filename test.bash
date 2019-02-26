#!/bin/bash

PATH=/usr/bin:/bin:./../../function:./function

if ! check_root;then
    exit 1
fi

export autoYes=$1

if ifon;then
    echo 1
fi