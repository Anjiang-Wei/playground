#!/bin/bash

TARGET=$1
BINARY=$(echo $TARGET | sed 's?.rg??')
TARGET_DIR=build

CWD=$PWD
SRC_FILE=$CWD/$TARGET


if [ ! -f $SRC_FILE ]; then
    echo "[ERROR] Cannot find \"$SRC_FILE\"."
    exit
else
    echo "Compile source code \"$SRC_FILE\" to \"$TARGET_DIR\"."
fi

if [ ! -d $TARGET_DIR ]; then
    echo "$TARGET_DIR does not exist."
    mkdir -p $TARGET_DIR && cd $TARGET_DIR
else
    echo "$TARGET_DIR already exists."
    cd $TARGET_DIR
fi


OBJNAME=$BINARY regent.py $SRC_FILE \
    && echo "Compile completed."

cd $CWD
