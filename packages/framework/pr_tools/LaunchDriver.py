#!/usr/bin/env python3

import argparse
from pathlib import Path
import sys
import subprocess
import os
import hashlib

# Packages are snapshotted via install_reqs.sh or these are in Python's site-packages
try:                                                                                # pragma: no cover
    from .determinesystem import DetermineSystem

except ImportError:                                                                 # pragma: no cover
    try:  # Perhaps this file is being imported from another directory
        p = Path(__file__).parents[0]
        sys.path.insert(0, str(p))

        from determinesystem import DetermineSystem

    except ImportError:  # Perhaps LoadEnv was snapshotted and these packages lie up one dir.
        p = Path(__file__).parents[1]  # One dir up from the path to this file
        sys.path.insert(0, str(p))

        from determinesystem import DetermineSystem


ENVIRONMENT_SETUP_COMMANDS = {
   "rhel8": [
      "source /projects/sems/modulefiles/utils/sems-modules-init.sh",
      "module unload sems-git",
      "module unload sems-python",
      "module load sems-git/2.37.0",
      "module load sems-python/3.9.0",
      "module load sems-ccache",
      "export CCACHE_NODISABLE=true",
      "export CCACHE_DIR=/fgs/trilinos/ccache/cache",
      "export CCACHE_BASEDIR=\"${WORKSPACE:?}\"",
      "export CCACHE_NOHARDLINK=true",
      "export CCACHE_UMASK=077",
      "export CCACHE_MAXSIZE=100G",
   ],
   "weaver": [
      "module unload git",
      "module unload python",
      "module load git/2.10.1",
      "module load python/3.7.3"
   ]
}


_script_path = os.path.dirname(os.path.realpath(__file__))
REPO_ROOT = os.path.realpath(os.path.join(_script_path, '../../..'))
if not os.path.exists(os.path.join(REPO_ROOT, '.git')):
    REPO_ROOT = os.path.realpath(os.path.join(os.environ['WORKSPACE'], 'Trilinos'))
print(f"REPO_ROOT : {REPO_ROOT}")


def print_banner(message):
    print(f"====== {message} ======")


def execute_command_checked(command):
    try:
        #subprocess.check_call(command, shell=True)
        print(command)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        sys.exit(1)


def get_md5sum(file_path):
    with open(file_path, 'rb') as file:
        md5 = hashlib.md5()
        while True:
            chunk = file.read(4096)
            if not chunk:
                break
            md5.update(chunk)
    return md5.hexdigest()


def merge():
    if os.environ['TRILINOS_SOURCE_REPO'] == os.environ['TRILINOS_TARGET_REPO'] and os.environ['TRILINOS_TARGET_BRANCH'] == os.environ['TRILINOS_SOURCE_SHA']:
        print("Bypassing merge, source and target repositories and refs are the same (meaning merge will have no effect)")
        return False
    else:
        # Checksum the scripts needed prior to the merge step
        driver_script = os.path.join(REPO_ROOT, 'packages/framework/pr_tools/LaunchDriver.py')
        merge_script = os.path.join(REPO_ROOT, 'packages/framework/pr_tools/PullRequestLinuxDriverMerge.py')
        sig_script_old = get_md5sum(driver_script)
        sig_merge_old = get_md5sum(merge_script)

        print_banner("Merge Source into Target")
        print(f"TRILINOS_SOURCE_SHA: {os.environ['TRILINOS_SOURCE_SHA']}")

        # Prepare the command for the MERGE operation
        merge_cmd_options = [
            os.environ['TRILINOS_SOURCE_REPO'],
            os.environ['TRILINOS_TARGET_REPO'],
            os.environ['TRILINOS_TARGET_BRANCH'],
            os.environ['TRILINOS_SOURCE_SHA'],
            os.environ['WORKSPACE'],
        ]
        merge_cmd = f"python3 {merge_script} {' '.join(merge_cmd_options)}"

        print("")
        print(f"Execute Merge Command: {merge_cmd}")
        print("")
        execute_command_checked(merge_cmd)

        print_banner("Merge completed")

        print_banner("Check for PR Driver Script Modifications")

        sig_script_new = get_md5sum(driver_script)
        print("")
        print(f"Script File: {driver_script}")
        print(f"Old md5sum : {sig_script_old}")
        print(f"New md5sum : {sig_script_new}")

        sig_merge_new = get_md5sum(merge_script)
        print("")
        print(f"Script File: {merge_script}")
        print(f"Old md5sum : {sig_merge_old}")
        print(f"New md5sum : {sig_merge_new}")

        if sig_script_old != sig_script_new or sig_merge_old != sig_merge_new:
            print("")
            print_banner("Driver or Merge script change detected.")
            return True

        print("")
        print("Driver and Merge scripts unchanged.")
        print("")
        return False


def main(argv):
  """
  This python script determines what system it is running on and then launches
  the trilinos driver script appropriately.

  The script returns 0 upon success and non-zero otherwise.
  """
  parser = argparse.ArgumentParser(description='Launch a trilinos driver script on this system.')
  parser.add_argument('--build-name', required=True,
                      help='The name of the build being launched')
  parser.add_argument('--supported-systems', required=False,
                      default='./LoadEnv/ini_files/supported-systems.ini',
                      help='The INI file containing supported systems')
  parser.add_argument('--in-container', default=False, action="store_true",
                      help="Build is happening in a container")
  parser.add_argument("--kokkos-develop", default=False, action="store_true",
                      help="Build is requiring to pull the current develop of kokkos and kokkos-kernels packages")
  parser.add_argument("--extra-configure-args",
                      help="Extra arguments that will be passed to CMake for configuring Trilinos.")
  args = parser.parse_args(argv)

  if os.getenv("TRILINOS_DIR") == None:
    print("LaunchDriver> ERROR: Please set TRILINOS_DIR.", flush=True)
    sys.exit(1)

  print("LaunchDriver> INFO: TRILINOS_DIR=\"" + os.environ["TRILINOS_DIR"] + "\"", flush=True)

  rerun_this_script = merge()
  if rerun_this_script:
    print("Re-launching PR Driver")
    print(sys.argv)
    subprocess.check_call(sys.argv)
    sys.exit(0)

  ds = DetermineSystem(args.build_name, args.supported_systems, force_build_name=True)

  if not args.in_container:
    cmd = " ; ".join(ENVIRONMENT_SETUP_COMMANDS.get(ds.system_name, []))
    if cmd:
        cmd += " ;"

  if ds.system_name == "ats2":
    cmd += f" {REPO_ROOT}/packages/framework/pr_tools/PullRequestLinuxCudaVortexDriver.sh"

  cmd += f" {REPO_ROOT}/packages/framework/pr_tools/PullRequestLinuxDriver.sh"

  cmd += " --no-bootstrap"

  if args.kokkos_develop:
    cmd += " --kokkos-develop"

  if args.extra_configure_args:
    cmd += f" --extra-configure-args=\"{args.extra_configure_args}\""

  print("LaunchDriver> EXEC: " + cmd, flush=True)

  #cmd_output = subprocess.run(cmd, shell=True)

  sys.exit(cmd_output.returncode)


if __name__ == "__main__":
    main(sys.argv[1 :])
