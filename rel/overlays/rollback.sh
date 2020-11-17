#!/bin/sh

BIN_DIR=`dirname "$0"`

${BIN_DIR}/bin/papercups eval ChatApi.Release.rollback
