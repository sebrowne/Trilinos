#!/bin/bash
EXTRA_ARGS=$@

COMPILER_DIR=
MPI_DIR=${MPI_DIR}
BLAS_DIR=${ARMPL_DIR}
LAPACK_DIR=${ARMPL_DIR}
HDF5_DIR=${HDF5_DIR}
NETCDF_DIR=${NETCDF_DIR}
PNETCDF_DIR=${PNETCDF_DIR}
ZLIB_DIR=${ZLIB_DIR}
CGNS_DIR=${CGNS_DIR}
BOOST_DIR=${BOOST_DIR}
METIS_DIR=${METIS_DIR}
PARMETIS_DIR=${PARMETIS_DIR}
SUPERLUDIST_DIR=${SUPERLU_DIST_DIR}

BUILD_TYPE=RELEASE
BUILD_SUFFIX=opt
BUILD_C_FLAGS=""
BUILD_CXX_FLAGS=""
BUILD_F_FLAGS=""
BUILD_LINK_FLAGS=""
BOUNDS_CHECKING=OFF

if   [[ ${1} == 'opt' || ${2} == 'opt' ]]
then
  :
elif [[ ${1} == 'dbg' || ${2} == 'dbg' ]]
then
  BUILD_TYPE=DEBUG
  BUILD_SUFFIX=dbg
  BOUNDS_CHECKING=ON
else
  echo " *** You may specify 'opt' or 'dbg' to this configuration script. Defaulting to 'opt'! ***"
fi

LINK_SHARED=OFF
LINK_SUFFIX=static

if   [[ ${1} == 'static' || ${2} == 'static' ]]
then
  :
elif [[ ${1} == 'shared' || ${2} == 'shared' ]]
then
  LINK_SHARED=ON
  LINK_SUFFIX=shared
else
  echo " *** You may specify 'static' or 'shared' to this configuration script. Defaulting to 'static'!"
fi

TRILINOS_HOME=${TRILINOS_REPO_DIR:-$(cd ..; pwd)}
TRIL_INSTALL_PATH=${TRIL_INSTALL_PATH:-$(cd ..; pwd)}
TRIL_INSTALL_DIR=${SPARC_ARCH}_${SPARC_COMPILER}_openmp_${SPARC_MPI}_${LINK_SUFFIX}_${BUILD_SUFFIX}

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
   \
   -D Trilinos_VERBOSE_CONFIGURE=FALSE \
   -D Trilinos_ENABLE_ALL_PACKAGES=OFF \
   -D Trilinos_ENABLE_SECONDARY_TESTED_CODE=OFF \
   \
   -D Trilinos_ENABLE_TESTS=OFF \
   -D DART_TESTING_TIMEOUT:STRING="600" \
   \
   -D Trilinos_ENABLE_EXPLICIT_INSTANTIATION=ON \
   -D Zoltan_ENABLE_ULLONG_IDS=ON \
   \
   -D Trilinos_ENABLE_OpenMP=ON \
   -D TPL_ENABLE_Pthread=OFF \
   \
   -D Trilinos_ENABLE_SEACAS=ON \
   -D Trilinos_ENABLE_Pamgen=OFF \
   -D Trilinos_ENABLE_Kokkos=OFF \
   -D TPL_ENABLE_X11=OFF \
   -D TPL_ENABLE_Matio=OFF \
   \
   -D TPL_ENABLE_MPI=ON \
   -D MPI_USE_COMPILER_WRAPPERS=ON \
   -D MPI_BASE_DIR:PATH=${MPI_DIR} \
   -D MPI_EXEC:PATH="mpirun" \
   -D MPI_EXEC_MAX_NUMPROCS:STRING="8" \
   -D MPI_EXEC_NUMPROCS_FLAG:STRING="-np" \
   \
   -D TPL_ENABLE_BinUtils=ON \
   \
   -D TPL_ENABLE_BLAS=ON \
   -D BLAS_LIBRARY_DIRS:PATH="${BLAS_DIR}/lib" \
   -D BLAS_LIBRARY_NAMES:STRING="armpl_lp64_mp;armflang;omp" \
   \
   -D TPL_ENABLE_LAPACK=ON \
   -D LAPACK_LIBRARY_DIRS:PATH="${LAPACK_DIR}/lib" \
   -D LAPACK_LIBRARY_NAMES:STRING="armpl_lp64_mp;armflang;omp" \
   \
   -D TPL_ENABLE_Boost=ON \
   -D Boost_INCLUDE_DIRS:PATH=${BOOST_DIR}/include \
   \
   -D TPL_ENABLE_BoostLib=ON \
   -D BoostLib_INCLUDE_DIRS:PATH=${BOOST_DIR}/include \
   -D BoostLib_LIBRARY_DIRS:PATH=${BOOST_DIR}/lib \
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
   -D TPL_ENABLE_METIS=ON \
   -D METIS_INCLUDE_DIRS:PATH=${METIS_DIR}/include \
   -D METIS_LIBRARY_DIRS:PATH=${METIS_DIR}/lib \
   \
   -D TPL_ENABLE_ParMETIS=ON \
   -D ParMETIS_INCLUDE_DIRS:PATH=${PARMETIS_DIR}/include \
   -D ParMETIS_LIBRARY_DIRS:PATH=${PARMETIS_DIR}/lib \
   \
   -D TPL_ENABLE_SuperLUDist=ON \
   -D SuperLUDist_INCLUDE_DIRS:PATH=${SUPERLUDIST_DIR}/include \
   -D SuperLUDist_LIBRARY_DIRS:PATH=${SUPERLUDIST_DIR}/lib \
   -D SuperLUDist_LIBRARY_NAMES:STRING="superlu_dist" \
   \
   -D Trilinos_EXTRA_LINK_FLAGS:STRING="-lmpi" \
   \
   ${EXTRA_ARGS} \
   ${TRILINOS_HOME}
