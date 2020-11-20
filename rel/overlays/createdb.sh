#!/bin/sh
# Creates the database if needed


BIN_DIR=`dirname "$0"`

${BIN_DIR}/bin/papercups eval ChatApi.Release.createdb