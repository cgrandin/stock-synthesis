#!/bin/bash

# script modified by C. Grandin Nov 24, 2022

# output settings
function display_settings()
{
  echo "-- $Type Settings --"
  echo "ADMB_HOME  = $ADMB_HOME"
  echo "Source Dir = $SRC_DIR"
  echo "Build Dir  = $BUILD_DIR"
  echo "Build exe  = $BUILD_TYPE"
  echo "Warnings   = $WARNINGS"
}

# want help?
function usage()
{
  echo ""
  echo "Call this script as follows:"
  echo "  ./Make_SS_330_new.sh [(-s | --source) source_dir] [(-b | --build) build_dir]" 
  echo "   [(-a | --admb) admb_dir] [[-o | --opt] | [-f | --safe] [-p] "
  echo "   [-w | --warn] [-d | --debug] [-h | --help]"
  echo "Notes:"
  echo "   -p is an ADMB flag to build statically and will be passed. "
  echo "   -w re-compiles with common warnings enabled. "
  echo "   -d will display the settings used to build SS. "
  echo ""
  echo "The default is the 'safe' build to directory SS330."
  echo ""
  display_settings
}

# create safe source tpl
function cat_safe_files()
{
# concatenate all tpl files to a single file
cat SS_biofxn.tpl SS_miscfxn.tpl SS_selex.tpl SS_popdyn.tpl SS_recruit.tpl SS_benchfore.tpl SS_expval.tpl SS_objfunc.tpl SS_write.tpl SS_write_ssnew.tpl SS_write_report.tpl SS_ALK.tpl SS_timevaryparm.tpl SS_tagrecap.tpl > SS_functions.temp
cat SS_versioninfo_330safe.tpl SS_readstarter.tpl SS_readdata_330.tpl SS_readcontrol_330.tpl SS_param.tpl SS_prelim.tpl SS_global.tpl SS_proced.tpl SS_functions.temp > $BUILD_DIR/ss3.tpl
}

# create opt source tpl
function cat_opt_files()
{
# concatenate all tpl files to a single file
cat SS_biofxn.tpl SS_miscfxn.tpl SS_selex.tpl SS_popdyn.tpl SS_recruit.tpl SS_benchfore.tpl SS_expval.tpl SS_objfunc.tpl SS_write.tpl SS_write_ssnew.tpl SS_write_report.tpl SS_ALK.tpl SS_timevaryparm.tpl SS_tagrecap.tpl > SS_functions.temp
cat SS_versioninfo_330opt.tpl SS_readstarter.tpl SS_readdata_330.tpl SS_readcontrol_330.tpl SS_param.tpl SS_prelim.tpl SS_global.tpl SS_proced.tpl SS_functions.temp > $BUILD_DIR/ss3_opt.tpl
}

# default directories
SRC_DIR=.
BUILD_DIR=build
# other defaults (safe build is the default)
BUILD_TYPE=ss3
WARNINGS=off
DEBUG=off
GREP=
Type=Current
STATICFLAG=
OPTFLAG=

if [ "$1" == "" ]  ; then
    Type=Default
    display_settings
    usage
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
         # debug
        -d | --debug )   DEBUG=on
                         ;;
         # show standard warnings
        -w | --warn )    WARNINGS=on
                         ;;
         # check for new source directory
        -s | --source )  shift
                         SRC_DIR=$1
                         ;;
         # check for new build directory
        -b | --build )   shift
                         BUILD_DIR=$1
                         ;;
         # check for ADMB directory and set
        -a | --admb )    shift
                         ADMB_HOME=$1
                         export ADMB_HOME
                         PATH=$ADMB_HOME:$PATH
                         ;;
         # output help - usage
        -h | --help )    Type=Default
                         usage
                         exit
                         ;;
         # build statically? (admb flag passed through - not documented) 
        -p )             STATICFLAG=-p
                         ;;
         # build safe version
        -f | --safe )    BUILD_TYPE=ss3
                         ;;
         # build fast version
        -o | --opt )     BUILD_TYPE=ss3_opt
                         OPTFLAG=-f
                         ;;
    esac
    shift
done

# change to the source dir
cd $SRC_DIR

# delete the temp file if it exists
if [ -f SS_functions.temp ]; then
    rm SS_functions.temp
fi

# create source files in build dir
mkdir -p $BUILD_DIR
case $BUILD_TYPE in
    ss3_opt )   grep "opt" SS_versioninfo_330opt.tpl
               cat_opt_files
               ;;
    ss3)       grep "safe" SS_versioninfo_330safe.tpl
               cat_safe_files
esac

# debug info
if [[ "$DEBUG" == "on" ]] ; then
  display_settings
else
  echo "-- Building $BUILD_TYPE in '$BUILD_DIR' --"
fi

# change to build dir and build 
cd $BUILD_DIR
admb $OPTFLAG $STATICFLAG $BUILD_TYPE
chmod a+x $BUILD_TYPE

# output warnings
if [[ "$WARNINGS" == "on" ]] ; then
    echo "... compiling a second time to get warnings ..."
    g++ -c -std=c++0x -O3 -I. -I"$ADMB_HOME/include" -I"/$ADMB_HOME/include/contrib" -o$BUILD_TYPE.obj $BUILD_TYPE.cpp -Wall -Wextra
fi


exit
