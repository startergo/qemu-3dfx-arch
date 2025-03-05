#!/bin/sh

export WATCOM=/opt/watcom
export PATH=$WATCOM/binnt64:$WATCOM/binnt:$PATH
export EDPATH=$WATCOM/eddat

#these variables change based on compilation target
#defaults are set for native compilation
export INCLUDE=$WATCOM/h/nt
# export LIB =

# Windows HTML Help Workshop
# export WHTMLHELP=$WATCOM/binnt/help





