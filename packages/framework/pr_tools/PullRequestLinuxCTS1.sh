#!/bin/bash -l

if [ "${SLURM_CTEST_TIME_LIMIT}" == "" ] ; then
  # 12 hrs * 60 min = 720 minutes
  # export SLURM_CTEST_TIME_LIMIT=720
  # but the short queue has a limit of 2 hours
  export SLURM_CTEST_TIME_LIMIT=240
fi

if [ "${Trilinos_CTEST_DO_ALL_AT_ONCE}" == "" ] ; then
  export Trilinos_CTEST_DO_ALL_AT_ONCE=TRUE
fi

# comment out sh and add what we need individually.
#source $WORKSPACE/Trilinos/packages/framework/pr_tools/atdm/load-env.sh $JOB_NAME

set -x

sbatch --wait --account=fy200165 --exclusive --partition=short --ntasks=16 --job-name="${JOB_NAME}" --time="${SLURM_CTEST_TIME_LIMIT}" "${WORKSPACE}"/Trilinos/packages/framework/pr_tools/PullRequestLinuxDriver.sh
