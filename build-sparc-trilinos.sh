#!/bin/bash

# Arg checking
if [[ ${1} != 'setup' && ${1} != 'build' ]]; then
  echo " *** Error: Argument #1 to this script must be either 'setup' or 'build'! ***"
  exit
fi
if [[ ${2} != 'cee-default' && ${2} != 'cee-advanced' && ${2} != 'ats1' && ${2} != 'cts1' && ${2} != 'tlcc2' && ${2} != 'waterman' && ${2} != 'morgan' ]]; then
  echo " *** Error: Argument #2 to this script must be one of the following: 'cee-default', 'cee-advanced', 'ats1', 'cts1', 'tlcc2', 'waterman', 'morgan'! ***"
  exit
fi
if [[ ${3} != 'deploy' && ${3} != '' ]]; then
  echo " *** Error: Optional argument #3 to this script must be 'deploy'! ***"
  exit
fi

# CEE
CEE_CLANG=cee-cpu_clang-5.0.1_serial_openmpi-1.10.2    # sparc development default
CEE_GCC=cee-cpu_gcc-7.2.0_serial_openmpi-1.10.2        # sierra development default
CEE_INTEL=cee-cpu_intel-17.0.1_serial_intelmpi-2018.4_static   # sierra production default
CEE_INTEL_OLD=cee-cpu_intel-17.0.1_serial_intelmpi-5.1.2_static   # sierra old production default
CEE_ATS1=cee-cpu_intel-18.0.2_openmp_mpich2-3.2_static        # ats-1 surrogate
CEE_ATS2=cee-gpu_cuda-9.2.88_gcc-7.2.0_openmpi-1.10.2_static  # ats-2 surrogate

# HPCs
ATS1_HSW=ats1-hsw_intel-18.0.2_openmp_mpich-7.7.1_static	# ats-1/hsw
ATS1_KNL=ats1-knl_intel-18.0.2_openmp_mpich-7.7.1_static	# ats-1/knl
CTS1_BDW=cts1-bdw_intel-17.0.1_openmp_openmpi-1.10.5_static	# cts-1/bdw
CTS1_P100=cts1-p100_gcc-6.3.1_cuda-9.2.88_openmpi-2.1.1_static  # cts-1/p100
TLCC2_SNB=tlcc2-snb_intel-17.0.1_openmp_openmpi-1.10.5_static   # tlcc2/snb

# Testbeds
WTRM_V100=waterman-v100_gcc-7.2.0_cuda-9.2.88_openmpi-2.1.2_static  # ats-2 surrogate
MORG_TX2=morgan-tx2_gcc-7.2.0_openmp_openmpi-2.1.2_static           # astra surrogate

# Build stuff
MAKE_CMD='make -j16 install'
DATE_STR=`date +%Y-%m-%d`
echo " ... Using "${DATE_STR}" for /projects/sparc/ installations ..."

if     [[ ${1} == 'setup' ]]; then
  if   [[ ${2} == 'cee-default' ]]; then
    mkdir ${CEE_CLANG}_static_dbg_build && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_clang_openmpi.sh  do-cmake.sh; cd .. 
    mkdir ${CEE_CLANG}_static_opt_build && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_clang_openmpi.sh  do-cmake.sh; cd ..

    mkdir ${CEE_CLANG}_shared_dbg_build && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_clang_openmpi.sh  do-cmake.sh; cd .. 
    mkdir ${CEE_CLANG}_shared_opt_build && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_clang_openmpi.sh  do-cmake.sh; cd ..
    
    mkdir ${CEE_GCC}_static_dbg_build   && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_gcc_openmpi.sh    do-cmake.sh; cd ..
    mkdir ${CEE_GCC}_static_opt_build   && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_gcc_openmpi.sh    do-cmake.sh; cd ..

    mkdir ${CEE_GCC}_shared_dbg_build   && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_gcc_openmpi.sh    do-cmake.sh; cd ..
    mkdir ${CEE_GCC}_shared_opt_build   && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_gcc_openmpi.sh    do-cmake.sh; cd ..
  elif [[ ${2} == 'cee-advanced' ]]; then
    
    mkdir ${CEE_INTEL}_dbg_build && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_intel_intelmpi.sh do-cmake.sh; cd ..
    mkdir ${CEE_INTEL}_opt_build && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_intel_intelmpi.sh do-cmake.sh; cd ..

    mkdir ${CEE_INTEL_OLD}_dbg_build && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_intel_intelmpi.sh do-cmake.sh; cd ..
    mkdir ${CEE_INTEL_OLD}_opt_build && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_intel_intelmpi.sh do-cmake.sh; cd ..
    
    mkdir ${CEE_ATS1}_dbg_build  && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_intel_openmp_mpich.sh do-cmake.sh; cd ..
    mkdir ${CEE_ATS1}_opt_build  && cd $_; ln -s ../do-cmake_trilinos_cee-cpu_intel_openmp_mpich.sh do-cmake.sh; cd ..
    
    mkdir ${CEE_ATS2}_dbg_build  && cd $_; ln -s ../do-cmake_trilinos_cee-gpu_gcc_cuda_openmpi.sh   do-cmake.sh; cd ..
    mkdir ${CEE_ATS2}_opt_build  && cd $_; ln -s ../do-cmake_trilinos_cee-gpu_gcc_cuda_openmpi.sh   do-cmake.sh; cd ..
  elif [[ ${2} == 'ats1' ]]; then
    mkdir ${ATS1_HSW}_dbg_build  && cd $_; ln -s ../do-cmake_trilinos_ats1-hsw_intel_mpich.sh do-cmake.sh; cd ..
    mkdir ${ATS1_HSW}_opt_build  && cd $_; ln -s ../do-cmake_trilinos_ats1-hsw_intel_mpich.sh do-cmake.sh; cd ..
    
    mkdir ${ATS1_KNL}_dbg_build  && cd $_; ln -s ../do-cmake_trilinos_ats1-knl_intel_mpich.sh do-cmake.sh; cd ..
    mkdir ${ATS1_KNL}_opt_build  && cd $_; ln -s ../do-cmake_trilinos_ats1-knl_intel_mpich.sh do-cmake.sh; cd ..
  elif [[ ${2} == 'cts1' ]]; then
    mkdir ${CTS1_BDW}_dbg_build  && cd $_; ln -s ../do-cmake_trilinos_cts1-bdw_intel_openmpi.sh do-cmake.sh; cd ..
    mkdir ${CTS1_BDW}_opt_build  && cd $_; ln -s ../do-cmake_trilinos_cts1-bdw_intel_openmpi.sh do-cmake.sh; cd ..
    
    mkdir ${CTS1_P100}_dbg_build && cd $_; ln -s ../do-cmake_trilinos_cts1-gpu_cuda_gcc_openmpi.sh do-cmake.sh; cd ..
    mkdir ${CTS1_P100}_opt_build && cd $_; ln -s ../do-cmake_trilinos_cts1-gpu_cuda_gcc_openmpi.sh do-cmake.sh; cd ..
  elif [[ ${2} == 'tlcc2' ]]; then
    mkdir ${TLCC2_SNB}_dbg_build && cd $_; ln -s ../do-cmake_trilinos_tlcc2-snb_intel_openmpi.sh do-cmake.sh; cd ..
    mkdir ${TLCC2_SNB}_opt_build && cd $_; ln -s ../do-cmake_trilinos_tlcc2-snb_intel_openmpi.sh do-cmake.sh; cd ..
  elif [[ ${2} == 'waterman' ]]; then
    mkdir ${WTRM_V100}_dbg_build && cd $_; ln -s ../do-cmake_trilinos_waterman-gpu_gcc_cuda_openmpi.sh do-cmake.sh; cd ..
    mkdir ${WTRM_V100}_opt_build && cd $_; ln -s ../do-cmake_trilinos_waterman-gpu_gcc_cuda_openmpi.sh do-cmake.sh; cd ..
  elif [[ ${2} == 'morgan' ]]; then
    mkdir ${MORG_TX2}_dbg_build && cd $_; ln -s ../do-cmake_trilinos_morgan-armtx2_gcc_openmpi.sh do-cmake.sh; cd ..
    mkdir ${MORG_TX2}_opt_build && cd $_; ln -s ../do-cmake_trilinos_morgan-armtx2_gcc_openmpi.sh do-cmake.sh; cd ..
  fi
elif   [[ ${1} == 'build' ]]; then
  if   [[ ${2} == 'cee-default' ]]; then
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/cee-rhel6-new/Trilinos/$DATE_STR; fi
    
    module purge && module load sparc-dev/clang
    cd ${CEE_CLANG}_static_opt_build; ./do-cmake.sh static opt; ${MAKE_CMD}; cd ..
    cd ${CEE_CLANG}_static_dbg_build; ./do-cmake.sh static dbg; ${MAKE_CMD}; cd ..
    cd ${CEE_CLANG}_shared_opt_build; ./do-cmake.sh shared opt; ${MAKE_CMD}; cd ..
    cd ${CEE_CLANG}_shared_dbg_build; ./do-cmake.sh shared dbg; ${MAKE_CMD}; cd ..
  
    module purge && module load sparc-dev/gcc
    cd ${CEE_GCC}_static_opt_build; ./do-cmake.sh static opt; ${MAKE_CMD}; cd ..
    cd ${CEE_GCC}_static_dbg_build; ./do-cmake.sh static dbg; ${MAKE_CMD}; cd ..
    cd ${CEE_GCC}_shared_opt_build; ./do-cmake.sh shared opt; ${MAKE_CMD}; cd ..
    cd ${CEE_GCC}_shared_dbg_build; ./do-cmake.sh shared dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then chmod -R g+rX $TRIL_INSTALL_PATH; fi

  elif [[ ${2} == 'cee-advanced' ]]; then
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/cee-rhel6-new/Trilinos/$DATE_STR; fi
  
    module purge && module load sparc-dev/intel-17.0.1_intelmpi-2018.4
    cd ${CEE_INTEL}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${CEE_INTEL}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
  
    module purge && module load sparc-dev/intel
    cd ${CEE_INTEL_OLD}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${CEE_INTEL_OLD}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    module purge && module load sparc-dev/intel-18.0.2_mpich2-3.2
    cd ${CEE_ATS1}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${CEE_ATS1}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
  
    module purge && module load sparc-dev/cuda-9.2.88_gcc-7.2.0_openmpi-1.10.2
    cd ${CEE_ATS2}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${CEE_ATS2}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then chmod -R g+rX $TRIL_INSTALL_PATH; fi
    
  elif [[ ${2} == 'ats1' ]]; then
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/ats1-hsw/Trilinos/$DATE_STR; fi
    module unload sparc-dev/intel-knl && module load sparc-dev/intel-hsw
    cd ${ATS1_HSW}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${ATS1_HSW}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/ats1-knl/Trilinos/$DATE_STR; fi
    module unload sparc-dev/intel-hsw && module load sparc-dev/intel-knl
    cd ${ATS1_KNL}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${ATS1_KNL}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then chmod -R g+rX $TRIL_INSTALL_PATH; fi

  elif [[ ${2} == 'cts1' ]]; then
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/cts1-bdw/Trilinos/$DATE_STR; fi
    module purge && module load sparc-dev/intel
    cd ${CTS1_BDW}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${CTS1_BDW}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/cts1-p100/Trilinos/$DATE_STR; fi
    module purge && module load sparc-dev/cuda-gcc
    cd ${CTS1_P100}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${CTS1_P100}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then chmod -R g+rX $TRIL_INSTALL_PATH; fi

  elif [[ ${2} == 'tlcc2' ]]; then
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/tlcc2-snb/Trilinos/$DATE_STR; fi
    module purge && module load sparc-dev/intel
    cd ${TLCC2_SNB}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${TLCC2_SNB}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then chmod -R g+rX $TRIL_INSTALL_PATH; fi

  elif [[ ${2} == 'waterman' ]]; then
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/waterman/Trilinos/$DATE_STR; fi
    module purge && module load sparc-dev/cuda-gcc
    cd ${WTRM_V100}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${WTRM_V100}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then chmod -R g+rX $TRIL_INSTALL_PATH; fi

  elif [[ ${2} == 'morgan' ]]; then
    if [[ ${3} == 'deploy' ]]; then export TRIL_INSTALL_PATH=/projects/sparc/tpls/morgan/Trilinos/$DATE_STR; fi
    module purge && module load sparc-dev/gcc-7.2.0_openmpi-2.1.2
    cd ${MORG_TX2}_opt_build; ./do-cmake.sh opt; ${MAKE_CMD}; cd ..
    cd ${MORG_TX2}_dbg_build; ./do-cmake.sh dbg; ${MAKE_CMD}; cd ..
    
    if [[ ${3} == 'deploy' ]]; then chmod -R g+rX $TRIL_INSTALL_PATH; fi
  fi
fi
