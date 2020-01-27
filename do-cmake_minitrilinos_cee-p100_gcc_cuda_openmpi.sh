#!/bin/bash

if [[ ${TMPDIR} ]] && [[ ! -d ${TMPDIR} ]]
then
    mkdir -p ${TMPDIR}
fi

EXTRA_ARGS=$@

COMPILER_DIR=${COMPILER_ROOT}
MPI_DIR=${MPI_ROOT}
BLAS_DIR=${BLAS_ROOT}
LAPACK_DIR=${LAPACK_ROOT}
HDF5_DIR=${HDF5_ROOT}
NETCDF_DIR=${NETCDF_ROOT}
PNETCDF_DIR=${PNETCDF_ROOT}
ZLIB_DIR=${ZLIB_ROOT}
CGNS_DIR=${CGNS_ROOT}
BOOST_DIR=${BOOST_ROOT}
METIS_DIR=${METIS_ROOT}
PARMETIS_DIR=${PARMETIS_ROOT}
SUPERLUDIST_DIR=${SUPERLUDIST_ROOT}

BUILD_TYPE=RELEASE
BUILD_SUFFIX=opt
BUILD_C_FLAGS=""
BUILD_CXX_FLAGS=""
BUILD_F_FLAGS=""
BUILD_LINK_FLAGS=""
if   [[ ${1} == 'opt' || ${2} == 'opt' || ${3} == 'opt' ]]
then
  :
elif [[ ${1} == 'dbg' || ${2} == 'dbg' || ${3} == 'dbg' ]]
then
  BUILD_TYPE=DEBUG
  BUILD_SUFFIX=dbg
else
  echo " *** You may specify 'opt' or 'dbg' to this configuration script. Defaulting to 'opt'! ***"
fi

LINK_SHARED=OFF
LINK_SUFFIX=static
if   [[ ${1} == 'static' || ${2} == 'static' || ${3} == 'static' ]]
then
  :
  BUILD_C_FLAGS="-fPIC ${BUILD_C_FLAGS}"
  BUILD_CXX_FLAGS="-fPIC ${BUILD_CXX_FLAGS}"
  BUILD_F_FLAGS="-fPIC ${BUILD_F_FLAGS}"
elif [[ ${1} == 'shared' || ${2} == 'shared' || ${3} == 'shared' ]]
then
  LINK_SHARED=ON
  LINK_SUFFIX=shared
else
  echo " *** You may specify 'static' or 'shared' to this configuration script. Defaulting to 'static'!"
fi

USING_SERIAL=ON
USING_OPENMP=OFF
if   [[ ${1} == 'serial' || ${2} == 'serial' || ${3} == 'serial' ]]
then
  USING_SERIAL=ON
  USING_OPENMP=OFF
elif [[ ${1} == 'openmp' || ${2} == 'openmp' || ${3} == 'openmp' ]]
then
  USING_OPENMP=OFF
  USING_SERIAL=ON
else
  echo " *** You may specify 'serial' or 'openmp' to this configuration script. Defaulting to 'serial'!"
fi

TRILINOS_HOME=${TRILINOS_REPO_DIR:-$(cd ..; pwd)}
TRIL_INSTALL_PATH=${TRIL_INSTALL_PATH:-$(cd ..; pwd)}
TRIL_INSTALL_DIR=${SPARC_ARCH}_${SPARC_COMPILER}_${SPARC_MPI}_${LINK_SUFFIX}_${BUILD_SUFFIX}

echo " *** Installing in: ${TRIL_INSTALL_PATH}/${TRIL_INSTALL_DIR}"
sleep 3

rm -f CMakeCache.txt; rm -rf CMakeFiles

cmake \
   -D CMAKE_VERBOSE_MAKEFILE=FALSE \
   -D CMAKE_INSTALL_PREFIX:PATH=${TRIL_INSTALL_PATH}/${TRIL_INSTALL_DIR} \
   -D CMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
   -D BUILD_SHARED_LIBS=${LINK_SHARED} \
   \
   -D CMAKE_C_COMPILER="mpicc" \
   -D CMAKE_CXX_COMPILER="mpicxx" \
   -D CMAKE_Fortran_COMPILER="mpif90" \
   \
   -D CMAKE_C_FLAGS="$BUILD_C_FLAGS" \
   -D CMAKE_CXX_FLAGS="$BUILD_CXX_FLAGS" \
   -D CMAKE_Fortran_FLAGS="$BUILD_F_FLAGS" \
   -D CMAKE_EXE_LINKER_FLAGS="$BUILD_LINK_FLAGS" \
   -D Trilinos_CXX11_FLAGS="-std=c++11 --expt-extended-lambda" \
   \
   -D Trilinos_VERBOSE_CONFIGURE=FALSE \
   -D Trilinos_ENABLE_ALL_PACKAGES=OFF \
   -D Trilinos_ENABLE_SECONDARY_TESTED_CODE=OFF \
   \
   -D Trilinos_ENABLE_TESTS=OFF \
   -D DART_TESTING_TIMEOUT:STRING="600" \
   \
   -D Trilinos_ENABLE_EXPLICIT_INSTANTIATION=ON \
   \
   -D Trilinos_ENABLE_OpenMP=${USING_OPENMP:?} \
   -D TPL_ENABLE_Pthread=OFF \
   \
   -D Trilinos_ENABLE_Kokkos=ON \
   -D Trilinos_ENABLE_KokkosCore=ON \
   -D Kokkos_ENABLE_Serial=${USING_SERIAL:?} \
   -D Kokkos_ENABLE_OpenMP=${USING_OPENMP:?} \
   -D Kokkos_ENABLE_Pthread=OFF \
   -D TPL_ENABLE_CUDA=ON \
   -D Kokkos_ENABLE_Cuda=ON \
   -D Kokkos_ENABLE_Cuda_UVM=ON \
   -D KOKKOS_ARCH="Pascal60" \
   -D Kokkos_ENABLE_Cuda_Lambda=ON \
   -D Kokkos_ENABLE_Cuda_Relocatable_Device_Code=OFF \
   \
   -D KOKKOS_ENABLE_DEPRECATED_CODE=OFF \
   \
   -D Trilinos_ENABLE_SEACAS=ON \
   -D SEACAS_ENABLE_Kokkos=OFF \
   \
   -D TPL_ENABLE_MPI=ON \
   \
   -D HDF5_ROOT:PATH=${HDF5_DIR} \
   -D HDF5_NO_SYSTEM_PATHS=ON \
   \
   -D PNetCDF_ROOT:PATH=${PNETCDF_DIR} \
   \
   -D TPL_ENABLE_Netcdf=ON \
   -D NetCDF_ROOT:PATH=${NETCDF_DIR} \
   \
   -D TPL_ENABLE_CGNS=ON \
   -D CGNS_INCLUDE_DIRS:PATH="${CGNS_DIR}/include" \
   -D CGNS_LIBRARY_DIRS:PATH="${CGNS_DIR}/lib" \
   -D CGNS_LIBRARY_NAMES:STRING="cgns" \
   \
   -D Trilinos_ENABLE_Pamgen=OFF \
   -D TPL_ENABLE_X11=OFF \
   -D TPL_ENABLE_Matio=OFF \
   \
   -D Zoltan_ENABLE_ULLONG_IDS=ON \
   -D Trilinos_EXTRA_LINK_FLAGS:STRING="-lmpi -ldl -lgomp" \
   \
   ${EXTRA_ARGS} \
   ${TRILINOS_HOME}
