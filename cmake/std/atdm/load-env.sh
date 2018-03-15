################################################################################
#
# Source to set up the env to do ATDM configuration of Trilinos.
#
################################################################################

# Assert this script is sourced, not run!
called=$_
if [ "$called" == "$0" ] ; then
  echo "This script '$0' is being called.  Instead, it must be sourced!"
  exit 1
fi

# Return the absoute directory of some relative directory path.
#
# This uses a temp shell to cd into the directory and then uses pwd to get the
# path.
function get_abs_dir_path() {
  [ -z "$1" ] && { pwd; return; }
  (cd -P -- "$1" && pwd)
}

# Get the base dir for the sourced script
_SCRIPT_DIR=`echo $BASH_SOURCE | sed "s/\(.*\)\/.*\.sh/\1/g"`
#echo "_SCRIPT_DIR = '$_SCRIPT_DIR'"

#
# A) Parse the command-line arguments
#

# Make sure job-name is passed in as first (and only ) arguemnt
if [ "$1" == "" ] ; then
  echo "Error, the first argument must be the job name with keyword names!"
  return
fi

# Make sure there are no other command-line arguments set
if [ "$2" != "" ] ; then
  echo "Error, this source script only accepts a single comamnd-line argument!"
  return
fi

#
# B) Get the system name from the hostname
#

source $_SCRIPT_DIR/utils/get_known_system_name.sh

if [[ $ATDM_CONFIG_KNOWN_SYSTEM_NAME == "" ]] ; then
  echo "Error, could not determine known system, aborting env loading"
  return
fi

#
# C) Set JOB_NAME and Trilinos base directory
#

export JOB_NAME=$1

# Get the Trilins base dir
export ATDM_CONFIG_TRILNOS_DIR=`get_abs_dir_path $_SCRIPT_DIR/../../..`
echo "ATDM_CONFIG_TRILNOS_DIR = $ATDM_CONFIG_TRILNOS_DIR"

#
# D) Parse $JOB_NAME for consumption by the system-specific environoment.sh
# script
#

source $_SCRIPT_DIR/utils/set_build_options.sh

#
# E) Load the matching env
#

# Set other vaues to empty by default
export OMP_NUM_THREADS=
export OMPI_CC=
export OMPI_CXX=
export OMPI_FC=
export ATDM_CONFIG_USE_NINJA=
export ATDM_CONFIG_BUILD_COUNT=
export ATDM_CONFIG_KOKKOS_ARCH=
export ATDM_CONFIG_CTEST_PARALLEL_LEVEL=
export ATDM_CONFIG_BLAS_LIB=
export ATDM_CONFIG_LAPACK_LIB=
export ATDM_CONFIG_USE_HWLOC=
export ATDM_CONFIG_HWLOC_LIBS=
export ATDM_CONFIG_USE_CUDA=
export ATDM_CONFIG_HDF5_LIBS=
export ATDM_CONFIG_NETCDF_LIBS=
export ATDM_CONFIG_MPI_POST_FLAG=

source $_SCRIPT_DIR/$ATDM_CONFIG_KNOWN_SYSTEM_NAME/environment.sh

# NOTE: The ATDMDevEnv.cmake module when processed will assert that all of
# these are set!
