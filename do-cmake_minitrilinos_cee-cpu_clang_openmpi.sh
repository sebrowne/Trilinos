#!/bin/bash
EXTRA_ARGS=$@

COMPILER_DIR=${COMPILER_ROOT}
MPI_DIR=${MPI_ROOT}
BLAS_DIR=${CBLAS_ROOT}
LAPACK_DIR=${CBLAS_ROOT}
HDF5_DIR=${HDF5_ROOT}
NETCDF_DIR=${NETCDF_ROOT}
PNETCDF_DIR=${PNETCDF_ROOT}
ZLIB_DIR=/usr/lib64
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
BUILD_LINK_FLAGS="-ldl"
if   [[ ${1} == 'opt' || ${2} == 'opt' || ${3} == 'opt' || ${4} == 'opt' ]]
then
  :
elif [[ ${1} == 'dbg' || ${2} == 'dbg' || ${3} == 'dbg' || ${4} == 'dbg' ]]
then
  BUILD_TYPE=DEBUG
  BUILD_SUFFIX=dbg
else
  echo " *** You may specify 'opt' or 'dbg' to this configuration script. Defaulting to 'opt'! ***"
fi

LINK_SHARED=OFF
LINK_SUFFIX=static
if   [[ ${1} == 'static' || ${2} == 'static' || ${3} == 'static' || ${4} == 'static' ]]
then
  :
  BUILD_C_FLAGS="-fPIC ${BUILD_C_FLAGS}"
  BUILD_CXX_FLAGS="-fPIC ${BUILD_CXX_FLAGS}"
  BUILD_F_FLAGS="-fPIC ${BUILD_F_FLAGS}"
elif [[ ${1} == 'shared' || ${2} == 'shared' || ${3} == 'shared' || ${4} == 'shared' ]]
then
  LINK_SHARED=ON
  LINK_SUFFIX=shared
else
  echo " *** You may specify 'static' or 'shared' to this configuration script. Defaulting to 'static'!"
fi

USING_SERIAL=ON
USING_OPENMP=OFF
if   [[ ${1} == 'serial' || ${2} == 'serial' || ${3} == 'serial' || ${4} == 'serial' ]]
then
  USING_SERIAL=ON
  USING_OPENMP=OFF
elif [[ ${1} == 'openmp' || ${2} == 'openmp' || ${3} == 'openmp' || ${4} == 'openmp' ]]
then
  USING_OPENMP=OFF
  USING_SERIAL=ON
else
  echo " *** You may specify 'serial' or 'openmp' to this configuration script. Defaulting to 'serial'!"
fi

USING_MPI=ON
if   [[ ${1} == 'mpi' || ${2} == 'mpi' || ${3} == 'mpi' || ${4} == 'mpi' ]]
then
  USING_MPI=ON
elif [[ ${1} == 'nompi' || ${2} == 'nompi' || ${3} == 'nompi' || ${4} == 'nompi' ]]
then
  USING_MPI=OFF
else
  echo " *** You may specify 'mpi' or 'nompi' to this configuration script. Defaulting to 'mpi'!"
fi

TRILINOS_HOME=${TRILINOS_REPO_DIR:-$(cd ..; pwd)}
TRIL_INSTALL_PATH=${TRIL_INSTALL_PATH:-$(cd ..; pwd)}

if [[ "${USING_MPI:-}" == "OFF" ]]
then
    C_COMPILER=${SERIAL_CC}
    CXX_COMPILER=${SERIAL_CXX}
    Fortran_COMPILER=${SERIAL_FC}
    HDF5_DIR=${SPARC_SERIAL_HDF5_ROOT}
    NETCDF_DIR=${SPARC_SERIAL_NETCDF_ROOT}
    CGNS_DIR=${SPARC_SERIAL_CGNS_ROOT}
    EXTRA_LINK_FLAGS=""
    TRIL_INSTALL_DIR=${SPARC_ARCH}_${SPARC_COMPILER}_serial_nompi_${LINK_SUFFIX}_${BUILD_SUFFIX}
elif [[ "${USING_MPI:-}" == "ON" ]]
then
    C_COMPILER="mpicc"
    CXX_COMPILER="mpicxx"
    Fortran_COMPILER="mpif90"
    EXTRA_LINK_FLAGS="-lmpi"
    TRIL_INSTALL_DIR=${SPARC_ARCH}_${SPARC_COMPILER}_serial_${SPARC_MPI}_${LINK_SUFFIX}_${BUILD_SUFFIX}
fi

echo " *** Installing in: ${TRIL_INSTALL_PATH}/${TRIL_INSTALL_DIR}"
sleep 3

rm -f CMakeCache.txt; rm -rf CMakeFiles

cmake \
   -D CMAKE_VERBOSE_MAKEFILE=FALSE \
   -D CMAKE_INSTALL_PREFIX:PATH=${TRIL_INSTALL_PATH}/${TRIL_INSTALL_DIR} \
   -D CMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
   -D BUILD_SHARED_LIBS=${LINK_SHARED} \
   \
   -D CMAKE_C_COMPILER=${C_COMPILER} \
   -D CMAKE_CXX_COMPILER=${CXX_COMPILER} \
   -D CMAKE_Fortran_COMPILER=${Fortran_COMPILER} \
   \
   -D CMAKE_C_FLAGS="$BUILD_C_FLAGS" \
   -D CMAKE_CXX_FLAGS="$BUILD_CXX_FLAGS" \
   -D CMAKE_Fortran_FLAGS="$BUILD_F_FLAGS" \
   -D CMAKE_EXE_LINKER_FLAGS="$BUILD_LINK_FLAGS" \
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
   -D TPL_ENABLE_CUDA=OFF \
   -D Kokkos_ENABLE_Cuda=OFF \
   -D Kokkos_ENABLE_Cuda_UVM=OFF \
   \
   -D KOKKOS_ENABLE_DEPRECATED_CODE=OFF \
   \
   -D Trilinos_ENABLE_SEACAS=ON \
   -D SEACAS_ENABLE_Kokkos=OFF \
   \
   -D TPL_ENABLE_MPI=${USING_MPI:?} \
   \
   -D HDF5_ROOT:PATH="${HDF5_DIR}" \
   -D HDF5_NO_SYSTEM_PATHS=ON \
   \
   -D TPL_ENABLE_Pnetcdf=${USING_MPI:?} \
   -D PNetCDF_ROOT:PATH="${PNETCDF_DIR}" \
   \
   -D TPL_ENABLE_Netcdf=ON \
   -D NetCDF_ROOT:PATH="${NETCDF_DIR}" \
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
   -D Trilinos_EXTRA_LINK_FLAGS:STRING="${EXTRA_LINK_FLAGS}" \
   \
   ${EXTRA_ARGS} \
   ${TRILINOS_HOME}
