#!/bin/bash

source function/all_function

function_list

if ! check_root 0;then
echo 1
fi

export autoYes=$1

if ifon;then
echo 1
fi