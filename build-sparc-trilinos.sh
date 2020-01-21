#!/bin/bash

# Arg checking
if [[ ${1} != 'setup' && ${1} != 'build' ]]; then
  echo " *** Error: Argument #1 to this script must be either 'setup' or 'build'! ***"
  exit
fi
if [[ ${2} != 'cee-default' && ${2} != 'cee-advanced' && ${2} != 'ats1' && ${2} != 'ats2' && ${2} != 'van1' && ${2} != 'cts1' && ${2} != 'tlcc2' && ${2} != 'waterman' ]]; then
  echo " *** Error: Argument #2 to this script must be one of the following: 'cee-default', 'cee-advanced', 'ats1', 'ats2', 'van1', 'cts1', 'tlcc2', 'waterman'! ***"
  exit
fi
if [[ ${3} != 'deploy' && ${3} != '' ]]; then
  echo " *** Error: Optional argument #3 to this script must be 'deploy'! ***"
  exit
fi

# CEE
CEE_CLANG=cee-cpu_clang-5.0.1_serial_openmpi-4.0.1
CEE_GCC=cee-cpu_gcc-7.2.0_serial_openmpi-4.0.1          # sierra development default
CEE_INTEL=cee-cpu_intel-19.0.3_serial_intelmpi-2018.4   # sierra production default
CEE_ATS1=cee-cpu_intel-18.0.2_openmp_mpich2-3.2         # ats-1 surrogate
CEE_ATS2=cee-p100_cuda-9.2.88_gcc-7.2.0_openmpi-4.0.1   # ats-2 surrogate

# HPCs
ATS1_HSW=ats1-hsw_intel-18.0.2_openmp_mpich-7.7.4	            # ats-1/hsw
ATS1_KNL=ats1-knl_intel-18.0.2_openmp_mpich-7.7.4	            # ats-1/knl
ATS2_PWR9_XLC=ats2-pwr9_xl-2019.02.07_serial_spmpi-2019.01.30       # ats-2/pwr9/xl
ATS2_PWR9_GCC=ats2-pwr9_gcc-7.3.1_serial_spmpi-2019.01.30           # ats-2/pwr9/gcc
ATS2_V100_XLC=ats2-v100_cuda-9.2.148_xl-2019.02.07_spmpi-2019.01.30 # ats-2/v100/xl
ATS2_V100_GCC=ats2-v100_cuda-9.2.148_gcc-7.3.1_spmpi-2019.01.30	    # ats-2/v100/gcc
CTS1_BDW=cts1-bdw_intel-19.0.5_openmp_openmpi-4.0.1  	            # cts-1/bdw
CTS1_P100=cts1-p100_gcc-6.3.1_cuda-9.2.88_openmpi-2.1.1             # cts-1/p100
TLCC2_SNB=tlcc2-snb_intel-19.0.5_openmp_openmpi-4.0.1               # tlcc2/snb
VAN1_TX2=van1-tx2_arm-19.2_openmp_openmpi-3.1.4                     # van-1/tx2

# Testbeds
WTRM_V100=waterman-v100_gcc-7.2.0_cuda-9.2.88_openmpi-2.1.2         # ats-2 surrogate

# Build stuff
MAKE_CMD='make -j16 install'
DATE_STR=`date +%Y-%m-%d`/00000000
#DATE_STR=2019-12-06/00000000
echo " ... Using "${DATE_STR}" for /projects/sparc/ installations ..."

function setup
{
  linktype=${4:-static}
  builddir=${1:?}_${linktype:?}_${2:?}_build
  echo "Setting up build directory '${builddir:?}' with configure script '${3:?}'"
  if [ ! -d ${builddir:?} ]
  then
    mkdir ${builddir:?}
  fi
  ln -sf ../${3:?} ${builddir:?}/do-cmake.sh
}

function build
{
  linktype=${4:?}
  builddir=${1:?}_${linktype:?}_${2:?}_build
  echo "Building configuration '${2:?}' with link type '${linktype:?}' in directory '${builddir:?}'"
  cd ${builddir:?}
  if [[ ${5} ]]
  then
      export TRIL_INSTALL_PATH=${5}
  fi
  ./do-cmake.sh ${linktype:?} ${2:?}
  if [ $? != 0 ]
  then
    echo "**** CONFIGURE IN DIR '${builddir:?}' FAILED ****"
    cd ../
    return
  fi
  ${3:?}
  if [ $? != 0 ]
  then
    echo "**** BUILD IN DIR '${builddir:?}' FAILED ****"
    cd ../
    return
  fi
  cd ../
}

function set_permissions
{
    if [[ $(hostname) == *"waterman"* ]]
    then
        group=wg-aero-dev
    else
        group=wg-aero-usr
    fi
    chgrp -R ${group} ${1:?}
    chmod -R g+rX ${1:?}
}


if     [[ ${1} == 'setup' ]]; then
  if   [[ ${2} == 'cee-default' ]]; then
    setup ${CEE_CLANG} dbg do-cmake_trilinos_cee-cpu_clang_serial_openmpi.sh static
    setup ${CEE_CLANG} opt do-cmake_trilinos_cee-cpu_clang_serial_openmpi.sh static
    setup ${CEE_CLANG} dbg do-cmake_trilinos_cee-cpu_clang_serial_openmpi.sh shared
    setup ${CEE_CLANG} opt do-cmake_trilinos_cee-cpu_clang_serial_openmpi.sh shared

    setup mini_${CEE_CLANG} dbg do-cmake_minitrilinos_cee-cpu_clang_serial_openmpi.sh static
    setup mini_${CEE_CLANG} opt do-cmake_minitrilinos_cee-cpu_clang_serial_openmpi.sh static
    setup mini_${CEE_CLANG} dbg do-cmake_minitrilinos_cee-cpu_clang_serial_openmpi.sh shared
    setup mini_${CEE_CLANG} opt do-cmake_minitrilinos_cee-cpu_clang_serial_openmpi.sh shared

    setup ${CEE_GCC} dbg do-cmake_trilinos_cee-cpu_gcc_serial_openmpi.sh static
    setup ${CEE_GCC} opt do-cmake_trilinos_cee-cpu_gcc_serial_openmpi.sh static
    setup ${CEE_GCC} dbg do-cmake_trilinos_cee-cpu_gcc_serial_openmpi.sh shared
    setup ${CEE_GCC} opt do-cmake_trilinos_cee-cpu_gcc_serial_openmpi.sh shared

    setup mini_${CEE_GCC} dbg do-cmake_minitrilinos_cee-cpu_gcc_serial_openmpi.sh static
    setup mini_${CEE_GCC} opt do-cmake_minitrilinos_cee-cpu_gcc_serial_openmpi.sh static
    setup mini_${CEE_GCC} dbg do-cmake_minitrilinos_cee-cpu_gcc_serial_openmpi.sh shared
    setup mini_${CEE_GCC} opt do-cmake_minitrilinos_cee-cpu_gcc_serial_openmpi.sh shared

  elif [[ ${2} == 'cee-advanced' ]]; then
    setup ${CEE_INTEL} dbg do-cmake_trilinos_cee-cpu_intel_serial_intelmpi.sh static
    setup ${CEE_INTEL} opt do-cmake_trilinos_cee-cpu_intel_serial_intelmpi.sh static

    setup mini_${CEE_INTEL} dbg do-cmake_minitrilinos_cee-cpu_intel_serial_intelmpi.sh static
    setup mini_${CEE_INTEL} opt do-cmake_minitrilinos_cee-cpu_intel_serial_intelmpi.sh static

    setup ${CEE_ATS1} dbg do-cmake_trilinos_cee-cpu_intel_openmp_mpich.sh static
    setup ${CEE_ATS1} opt do-cmake_trilinos_cee-cpu_intel_openmp_mpich.sh static

    setup mini_${CEE_ATS1} dbg do-cmake_minitrilinos_cee-cpu_intel_openmp_mpich.sh static
    setup mini_${CEE_ATS1} opt do-cmake_minitrilinos_cee-cpu_intel_openmp_mpich.sh static

    setup ${CEE_ATS2} dbg do-cmake_trilinos_cee-p100_gcc_cuda_openmpi.sh static
    setup ${CEE_ATS2} opt do-cmake_trilinos_cee-p100_gcc_cuda_openmpi.sh static

    setup mini_${CEE_ATS2} dbg do-cmake_minitrilinos_cee-p100_gcc_cuda_openmpi.sh static
    setup mini_${CEE_ATS2} opt do-cmake_minitrilinos_cee-p100_gcc_cuda_openmpi.sh static

  elif [[ ${2} == 'ats1' ]]; then
    setup ${ATS1_HSW} dbg do-cmake_trilinos_ats1-hsw_intel_openmp_mpich.sh static
    setup ${ATS1_HSW} opt do-cmake_trilinos_ats1-hsw_intel_openmp_mpich.sh static

    setup ${ATS1_KNL} dbg do-cmake_trilinos_ats1-knl_intel_openmp_mpich.sh static
    setup ${ATS1_KNL} opt do-cmake_trilinos_ats1-knl_intel_openmp_mpich.sh static

  elif [[ ${2} == 'ats2' ]]; then
    setup ${ATS2_PWR9_XLC} dbg do-cmake_trilinos_ats2-pwr9_xl_serial_spmpi.sh static
    setup ${ATS2_PWR9_XLC} opt do-cmake_trilinos_ats2-pwr9_xl_serial_spmpi.sh static

    setup ${ATS2_PWR9_GCC} dbg do-cmake_trilinos_ats2-pwr9_gcc_serial_spmpi.sh static
    setup ${ATS2_PWR9_GCC} opt do-cmake_trilinos_ats2-pwr9_gcc_serial_spmpi.sh static

    setup ${ATS2_V100_XLC} dbg do-cmake_trilinos_ats2-v100_xl_cuda_spmpi.sh static
    setup ${ATS2_V100_XLC} opt do-cmake_trilinos_ats2-v100_xl_cuda_spmpi.sh static

    setup ${ATS2_V100_GCC} dbg do-cmake_trilinos_ats2-v100_gcc_cuda_spmpi.sh static
    setup ${ATS2_V100_GCC} opt do-cmake_trilinos_ats2-v100_gcc_cuda_spmpi.sh static

  elif [[ ${2} == 'cts1' ]]; then
    setup ${CTS1_BDW} dbg do-cmake_trilinos_cts1-bdw_intel_openmp_openmpi.sh static
    setup ${CTS1_BDW} opt do-cmake_trilinos_cts1-bdw_intel_openmp_openmpi.sh static

    setup ${CTS1_P100} dbg do-cmake_trilinos_cts1-p100_gcc_cuda_openmpi.sh static
    setup ${CTS1_P100} opt do-cmake_trilinos_cts1-p100_gcc_cuda_openmpi.sh static

  elif [[ ${2} == 'tlcc2' ]]; then
    setup ${TLCC2_SNB} dbg do-cmake_trilinos_tlcc2-snb_intel_openmp_openmpi.sh static
    setup ${TLCC2_SNB} opt do-cmake_trilinos_tlcc2-snb_intel_openmp_openmpi.sh static

  elif [[ ${2} == 'van1' ]]; then
    setup ${VAN1_TX2} dbg do-cmake_trilinos_van1-tx2_arm_openmp_openmpi.sh static
    setup ${VAN1_TX2} opt do-cmake_trilinos_van1-tx2_arm_openmp_openmpi.sh static

  elif [[ ${2} == 'waterman' ]]; then
    setup ${WTRM_V100} dbg do-cmake_trilinos_waterman-v100_gcc_cuda_openmpi.sh static
    setup ${WTRM_V100} opt do-cmake_trilinos_waterman-v100_gcc_cuda_openmpi.sh static
  fi
elif   [[ ${1} == 'build' ]]; then
  if   [[ ${2} == 'cee-default' ]]; then
    if [[ ${3} == 'deploy' ]]
    then
        TRIL_INSTALL_PATH=/projects/sparc/tpls/cee-rhel6/Trilinos/${DATE_STR}
        MINITRIL_INSTALL_PATH=/projects/sparc/tpls/cee-rhel6/minitrilinos/${DATE_STR}
    fi

    module purge && module load sparc-dev/clang
    build ${CEE_CLANG} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CEE_CLANG} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CEE_CLANG} opt "${MAKE_CMD}" shared ${TRIL_INSTALL_PATH}
    build ${CEE_CLANG} dbg "${MAKE_CMD}" shared ${TRIL_INSTALL_PATH}

    build mini_${CEE_CLANG} opt "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_CLANG} dbg "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_CLANG} opt "${MAKE_CMD}" shared ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_CLANG} dbg "${MAKE_CMD}" shared ${MINITRIL_INSTALL_PATH}

    module purge && module load sparc-dev/gcc
    build ${CEE_GCC} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CEE_GCC} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CEE_GCC} opt "${MAKE_CMD}" shared ${TRIL_INSTALL_PATH}
    build ${CEE_GCC} dbg "${MAKE_CMD}" shared ${TRIL_INSTALL_PATH}

    build mini_${CEE_GCC} opt "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_GCC} dbg "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_GCC} opt "${MAKE_CMD}" shared ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_GCC} dbg "${MAKE_CMD}" shared ${MINITRIL_INSTALL_PATH}

    if [[ ${3} == 'deploy' ]]
    then
        set_permissions ${TRIL_INSTALL_PATH}
        set_permissions ${MINITRIL_INSTALL_PATH}
    fi

  elif [[ ${2} == 'cee-advanced' ]]; then
    if [[ ${3} == 'deploy' ]]
    then
        TRIL_INSTALL_PATH=/projects/sparc/tpls/cee-rhel6/Trilinos/${DATE_STR}
        MINITRIL_INSTALL_PATH=/projects/sparc/tpls/cee-rhel6/minitrilinos/${DATE_STR}
    fi
  
    module purge && module load sparc-dev/intel
    build ${CEE_INTEL} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CEE_INTEL} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}

    build mini_${CEE_INTEL} opt "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_INTEL} dbg "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}

    module purge && module load sparc-dev/intel-18.0.2_mpich2-3.2
    build ${CEE_ATS1} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CEE_ATS1} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}

    build mini_${CEE_ATS1} opt "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_ATS1} dbg "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}

    module purge && module load sparc-dev/cuda-9.2.88_gcc-7.2.0_openmpi-4.0.1
    build ${CEE_ATS2} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CEE_ATS2} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}

    build mini_${CEE_ATS2} opt "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}
    build mini_${CEE_ATS2} dbg "${MAKE_CMD}" static ${MINITRIL_INSTALL_PATH}

    if [[ ${3} == 'deploy' ]]
    then
        set_permissions ${TRIL_INSTALL_PATH}
        set_permissions ${MINITRIL_INSTALL_PATH}
    fi

  elif [[ ${2} == 'ats1' ]]; then
    if [[ ${3} == 'deploy' ]]
    then
        HSW_TRIL_INSTALL_PATH=/projects/sparc/tpls/ats1-hsw/Trilinos/$DATE_STR
        KNL_TRIL_INSTALL_PATH=/projects/sparc/tpls/ats1-knl/Trilinos/$DATE_STR
    fi

    module unload sparc-dev/intel-knl && module load sparc-dev/intel-hsw
    build ${ATS1_HSW} opt "${MAKE_CMD}" static ${HSW_TRIL_INSTALL_PATH}
    build ${ATS1_HSW} dbg "${MAKE_CMD}" static ${HSW_TRIL_INSTALL_PATH}

    module unload sparc-dev/intel-hsw && module load sparc-dev/intel-knl
    build ${ATS1_KNL} opt "${MAKE_CMD}" static ${KNL_TRIL_INSTALL_PATH}
    build ${ATS1_KNL} dbg "${MAKE_CMD}" static ${KNL_TRIL_INSTALL_PATH}

    if [[ ${3} == 'deploy' ]]
    then
        set_permissions ${HSW_TRIL_INSTALL_PATH}
        set_permissions ${KNL_TRIL_INSTALL_PATH}
    fi

  elif [[ ${2} == 'ats2' ]]; then
    if [[ ${3} == 'deploy' ]]
    then
        PWR9_TRIL_INSTALL_PATH=/projects/sparc/tpls/ats2-pwr9/Trilinos/$DATE_STR
        V100_TRIL_INSTALL_PATH=/projects/sparc/tpls/ats2-v100/Trilinos/$DATE_STR
    fi

    module unload sparc-dev/cuda-xl && module load sparc-dev/xl
    build ${ATS2_PWR9_XLC} opt "${MAKE_CMD}" static ${PWR9_TRIL_INSTALL_PATH}
    build ${ATS2_PWR9_XLC} dbg "${MAKE_CMD}" static ${PWR9_TRIL_INSTALL_PATH}

    module unload sparc-dev/xl && module load sparc-dev/gcc-7.3.1_spmpi-2019.01.30
    build ${ATS2_PWR9_GCC} opt "${MAKE_CMD}" static ${PWR9_TRIL_INSTALL_PATH}
    build ${ATS2_PWR9_GCC} dbg "${MAKE_CMD}" static ${PWR9_TRIL_INSTALL_PATH}

    module unload sparc-dev/gcc-7.3.1_spmpi-2019.01.30 && module load sparc-dev/cuda-xl
    build ${ATS2_V100_XLC} opt "${MAKE_CMD}" static ${V100_TRIL_INSTALL_PATH}
    build ${ATS2_V100_XLC} dbg "${MAKE_CMD}" static ${V100_TRIL_INSTALL_PATH}

    module unload sparc-dev/cuda-xl && module load sparc-dev/cuda-9.2.148_gcc-7.3.1_spmpi-2019.01.30
    build ${ATS2_V100_GCC} opt "${MAKE_CMD}" static ${V100_TRIL_INSTALL_PATH}
    build ${ATS2_V100_GCC} dbg "${MAKE_CMD}" static ${V100_TRIL_INSTALL_PATH}

    if [[ ${3} == 'deploy' ]]
    then
        set_permissions ${PWR9_TRIL_INSTALL_PATH}
        set_permissions ${V100_TRIL_INSTALL_PATH}
    fi

  elif [[ ${2} == 'van1' ]]; then
    if [[ ${3} == 'deploy' ]]; then TRIL_INSTALL_PATH=/projects/sparc/tpls/van1-tx2/Trilinos/${DATE_STR}; fi

    module unload sparc-dev && module load sparc-dev/arm-19.2_openmpi-3.1.4
    build ${VAN1_TX2} opt "${MAKE_CMD}" static
    build ${VAN1_TX2} dbg "${MAKE_CMD}" static

    if [[ ${3} == 'deploy' ]]; then set_permissions ${TRIL_INSTALL_PATH}; fi

  elif [[ ${2} == 'cts1' ]]; then
    if [[ ${3} == 'deploy' ]]; then TRIL_INSTALL_PATH=/projects/sparc/tpls/cts1-bdw/Trilinos/${DATE_STR}; fi

    module purge && module load sparc-dev/intel
    build ${CTS1_BDW} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CTS1_BDW} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}

    if [[ ${3} == 'deploy' ]]; then set_permissions ${TRIL_INSTALL_PATH}; fi
  
    if [[ ${3} == 'deploy' ]]; then TRIL_INSTALL_PATH=/projects/sparc/tpls/cts1-p100/Trilinos/${DATE_STR}; fi

    module purge && module load sparc-dev/cuda-gcc
    build ${CTS1_P100} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${CTS1_P100} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}

    if [[ ${3} == 'deploy' ]]; then set_permissions ${TRIL_INSTALL_PATH}; fi

  elif [[ ${2} == 'tlcc2' ]]; then
    if [[ ${3} == 'deploy' ]]; then TRIL_INSTALL_PATH=/projects/sparc/tpls/tlcc2-snb/Trilinos/${DATE_STR}; fi

    module purge && module load sparc-dev/intel
    build ${TLCC2_SNB} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${TLCC2_SNB} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    
    if [[ ${3} == 'deploy' ]]; then set_permissions ${TRIL_INSTALL_PATH}; fi

  elif [[ ${2} == 'waterman' ]]; then
    if [[ ${3} == 'deploy' ]]; then TRIL_INSTALL_PATH=/projects/sparc/tpls/waterman-gpu/Trilinos/${DATE_STR}; fi

    module purge && module load sparc-dev/cuda-gcc
    build ${WTRM_V100} opt "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    build ${WTRM_V100} dbg "${MAKE_CMD}" static ${TRIL_INSTALL_PATH}
    
    if [[ ${3} == 'deploy' ]]; then set_permissions ${TRIL_INSTALL_PATH}; fi
  fi
fi
