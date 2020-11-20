#!/bin/bash -e

#
# Configure and then build and install Trilinos for SPARC using:
#
#   cd Trilinos/
#   mkdir <build-dir>/
#   cd <build-dir>/
#   source ../cmake/std/atdm/load-env.sh <buld-name>
#   ../do-cmake_trilinos.sh -DCMAKE_INSTALL_PREFIX=<install-prefix>
#   ninja -j16 install
#

if [[ "${ATDM_CONFIG_COMPLETED_ENV_SETUP}" != "TRUE" ]] ; then
  echo "ERROR, ATDM_CONFIG_COMPLETED_ENV_SETUP is not set to TRUE." \
   " Must source <trilinos-dir>/cmake/std/atdm/load-env.sh <build-name> first!"
  exit 1
fi

if [[ "$ATDM_CONFIG_USE_NINJA" == "OFF" ]]; then
  GENERATOR=
else
  GENERATOR="-GNinja"
fi

cmake \
$GENERATOR \
-D Trilinos_CONFIGURE_OPTIONS_FILE:STRING=cmake/std/atdm/apps/sparc/SPARCTrilinosPackagesEnables.cmake,cmake/std/atdm/ATDMDevEnv.cmake \
"$@" \
..
