#!/usr/bin/env bash
SCRIPTFILE=$(realpath ${WORKSPACE:?}/Trilinos/packages/framework/pr_tools/PullRequestLinuxDriver.sh)
SCRIPTPATH=$(dirname $SCRIPTFILE)
source ${SCRIPTPATH:?}/common.bash


print_banner "PullRequestLinuxDriver.sh"

# Argument defaults
on_kokkos_develop=0

original_args=$@

# Do POSIXLY_CORRECT option handling.
ARGS=$(getopt -n PullRequestLinuxDriver.sh \
 --options '+x' \
 --longoptions kokkos-develop \
 --longoptions extra-configure-args: \
 -- "${@}") || exit $?

eval set -- "${ARGS}"

while [ "$#" -gt 0 ]
do
    case "${1}" in
    (--kokkos-develop)
        on_kokkos_develop=1
        shift
        ;;
    (--extra-configure-args)
        extra_configure_args=$2
        shift 2
        ;;
    (-h|--help)
        # When help is requested echo it to stdout.
        echo -e "$USAGE"
        exit 0
        ;;
    (-x)
        set -x
        shift
        ;;
    (--) # This is an explicit directive to stop processing options.
        shift
        break
        ;;
    (-*) # Catch options which are defined but not implemented.
        echo >&2 "${toolName}: ${1}: Unimplemented option passed."
        exit 1
        ;;
    (*) # The first parameter terminates option processing.
        break
        ;;
    esac
done

# Set up Sandia PROXY environment vars
envvar_set_or_create https_proxy 'http://proxy.sandia.gov:80'
envvar_set_or_create http_proxy  'http://proxy.sandia.gov:80'
envvar_set_or_create no_proxy    'localhost,.sandia.gov,localnets,127.0.0.1,169.254.0.0/16,forge.sandia.gov'

envvar_set_or_create PYTHON_EXE $(which python3)
message_std "PRDriver> " "Python EXE : ${PYTHON_EXE:?}"

# Identify the path to the trilinos repository root
REPO_ROOT=`readlink -f ${SCRIPTPATH:?}/../..`
test -d ${REPO_ROOT:?}/.git || REPO_ROOT=`readlink -f ${WORKSPACE:?}/Trilinos`
message_std "PRDriver> " "REPO_ROOT : ${REPO_ROOT}"

# Get the md5 checksum of this script:
sig_script_old=$(get_md5sum ${REPO_ROOT:?}/packages/framework/pr_tools/PullRequestLinuxDriver.sh)

# Get the md5 checksum of the Merge script
sig_merge_old=$(get_md5sum ${REPO_ROOT:?}/packages/framework/pr_tools/PullRequestLinuxDriverMerge.py)

if [[ ${on_kokkos_develop} == "1" ]]; then
    message_std "PRDriver> --kokkos-develop is set - setting kokkos and kokkos-kernels packages to current develop and pointing at them"
    "${SCRIPTPATH}"/SetKokkosDevelop.sh
    extra_configure_args="-DKokkos_SOURCE_DIR_OVERRIDE:string=kokkos;-DKokkosKernels_SOURCE_DIR_OVERRIDE:string=kokkos-kernels${extra_configure_args:+;${extra_configure_args}}"
fi

# determine what MODE we are using
mode="standard"
if [[ "${JOB_BASE_NAME:?}" == "Trilinos_pullrequest_gcc_8.3.0_installation_testing" ]]; then
    mode="installation"
fi

envvar_set_or_create TRILINOS_BUILD_DIR ${WORKSPACE}/pull_request_test

print_banner "Launch the Test Driver"

# Prepare the command for the TEST operation
test_cmd_options=(
    --target-branch-name=${TRILINOS_TARGET_BRANCH:?}
    --genconfig-build-name=${GENCONFIG_BUILD_NAME:?}
    --pullrequest-env-config-file=${LOADENV_CONFIG_FILE:?}
    --pullrequest-gen-config-file=${GENCONFIG_CONFIG_FILE:?}
    --pullrequest-number=${PULLREQUESTNUM:?}
    --jenkins-job-number=${BUILD_NUMBER:?}
    --req-mem-per-core=4.0
    --max-cores-allowed=${TRILINOS_MAX_CORES:=29}
    --num-concurrent-tests=16
    --test-mode=${mode}
    --workspace-dir=${WORKSPACE:?}
    --filename-packageenables=${WORKSPACE:?}/packageEnables.cmake
    --filename-subprojects=${WORKSPACE:?}/package_subproject_list.cmake
    --source-dir=${WORKSPACE}/Trilinos
    --build-dir=${TRILINOS_BUILD_DIR:?}
    --ctest-driver=${WORKSPACE:?}/Trilinos/cmake/SimpleTesting/cmake/ctest-driver.cmake
    --ctest-drop-site=${TRILINOS_CTEST_DROP_SITE:?}
    --dashboard-build-name=${DASHBOARD_BUILD_NAME}
)

if [[ ${extra_configure_args} ]]
then
    test_cmd_options+=( "--extra-configure-args=\"${extra_configure_args}\"")
fi

if [[ ${GENCONFIG_BUILD_NAME} == *"gnu"* ]]
then
    test_cmd_options+=( "--use-explicit-cachefile ")
fi

test_cmd="${PYTHON_EXE:?} ${REPO_ROOT:?}/packages/framework/pr_tools/PullRequestLinuxDriverTest.py ${test_cmd_options[@]}"

# Call the script to launch the tests
print_banner "Execute Test Command"
message_std "PRDriver> " "cd $(pwd)"
message_std "PRDriver> " "${test_cmd:?} --pullrequest-cdash-track='${PULLREQUEST_CDASH_TRACK:?}'"
execute_command_checked "${test_cmd:?} --pullrequest-cdash-track='${PULLREQUEST_CDASH_TRACK:?}'"
