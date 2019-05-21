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

EXTRA_C_FLAGS="-mkl -xCORE-AVX2"
EXTRA_CXX_FLAGS="-mkl -xCORE-AVX2"
EXTRA_F_FLAGS="-mkl -xCORE-AVX2"
LINK_FLAGS="-mkl -xCORE-AVX2"

TRILINOS_HOME=${TRILINOS_REPO_DIR:-$(cd ..; pwd)}

# Shouldn't need to change anything below this line
if [[ ${1} == 'static' || ${2} == 'static' ]]
then
  LINK_SHARED=OFF
  LINK_SUFFIX=static
elif [[ ${1} == 'shared' || ${2} == 'shared' ]]
then
  LINK_SHARED=ON
  LINK_SUFFIX=shared
else
  echo " *** Warning: 'static' or 'shared' LINK_TYPE is an optional argument to this script.  Defaulting to 'static'."
  LINK_SHARED=OFF
  LINK_SUFFIX=static
fi

if [[ ${1} == 'opt' || ${2} == 'opt' ]]
then
  BUILD_TYPE=RELEASE
  BUILD_SUFFIX=opt
elif [[ ${1} == 'dbg' || ${2} == 'dbg' ]]
then
  BUILD_TYPE=DEBUG
  BUILD_SUFFIX=dbg
else
  echo " *** Warning: 'opt' or 'dbg' BUILD_TYPE is an optional argument to this script.  Defaulting to 'opt'."
  BUILD_TYPE=RELEASE
  BUILD_SUFFIX=opt
fi

TRIL_INSTALL_PATH=${TRIL_INSTALL_PATH:-$(cd ..; pwd)}
TRIL_INSTALL_DIR=${SPARC_ARCH}_${SPARC_COMPILER}_openmp_${SPARC_MPI}_${LINK_SUFFIX}_${BUILD_SUFFIX}

echo " *** Installing in: ${TRIL_INSTALL_PATH}/${TRIL_INSTALL_DIR}"
sleep 5

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
   -D CMAKE_C_FLAGS="$EXTRA_C_FLAGS" \
   -D CMAKE_CXX_FLAGS="$EXTRA_CXX_FLAGS" \
   -D CMAKE_Fortran_FLAGS="$EXTRA_F_FLAGS" \
   -D CMAKE_EXE_LINKER_FLAGS="$LINK_FLAGS" \
   \
   -D Trilinos_VERBOSE_CONFIGURE=FALSE \
   -D Trilinos_ENABLE_ALL_PACKAGES=OFF \
   -D Trilinos_ENABLE_SECONDARY_TESTED_CODE=OFF \
   \
   -D Trilinos_ENABLE_TESTS=OFF \
   -D DART_TESTING_TIMEOUT:STRING="600" \
   \
   -D Trilinos_ENABLE_EXPLICIT_INSTANTIATION=ON \
   -D Tpetra_INST_FLOAT=OFF \
   -D Tpetra_INST_DOUBLE=ON \
   -D Tpetra_INST_COMPLEX_FLOAT=OFF \
   -D Tpetra_INST_COMPLEX_DOUBLE=OFF \
   -D Tpetra_INST_INT_INT=OFF \
   -D Tpetra_INST_INT_LONG=OFF \
   -D Tpetra_INST_INT_UNSIGNED=OFF \
   -D Tpetra_INST_INT_LONG_LONG=ON \
   -D Teuchos_ENABLE_LONG_LONG_INT=ON \
   -D Teuchos_ENABLE_COMPLEX=OFF \
   -D Zoltan_ENABLE_ULLONG_IDS=ON \
   \
   -D Trilinos_ENABLE_OpenMP=ON \
   -D TPL_ENABLE_Pthread=OFF \
   \
   -D Trilinos_ENABLE_Teuchos=ON \
   -D Trilinos_ENABLE_Epetra=ON \
   -D Trilinos_ENABLE_EpetraExt=ON \
   -D Trilinos_ENABLE_AztecOO=ON \
   -D Trilinos_ENABLE_Amesos=ON \
   -D Trilinos_ENABLE_Stratimikos=ON \
   -D Trilinos_ENABLE_Anasazi=ON \
   -D Anasazi_ENABLE_RBGen=ON \
   -D Trilinos_ENABLE_Ifpack=ON \
   -D Trilinos_ENABLE_ML=ON \
   -D Trilinos_ENABLE_Teko=ON \
   -D Trilinos_ENABLE_NOX=ON \
   -D Trilinos_ENABLE_Thyra=ON \
   -D Trilinos_ENABLE_Rythmos=OFF \
   -D Trilinos_ENABLE_Sacado=ON \
   -D Trilinos_ENABLE_Stokhos=OFF \
   -D Trilinos_ENABLE_Panzer=OFF \
   -D Trilinos_ENABLE_Tpetra=ON \
   -D Tpetra_INST_SERIAL=OFF \
   -D Tpetra_INST_OPENMP=ON \
   -D Trilinos_ENABLE_Belos=ON \
   -D Trilinos_ENABLE_Amesos2=ON \
   -D Amesos2_ENABLE_Epetra=OFF \
   -D Amesos2_ENABLE_KLU2=ON \
   -D Trilinos_ENABLE_Ifpack2=ON \
   -D Trilinos_ENABLE_MueLu=ON \
   -D MueLu_ENABLE_Epetra=OFF \
   -D Xpetra_ENABLE_Epetra=OFF \
   -D Trilinos_ENABLE_Zoltan2=ON \
   -D Trilinos_ENABLE_STKMesh=OFF \
   -D Trilinos_ENABLE_STKIO=OFF \
   -D Trilinos_ENABLE_STKTransfer=ON \
   -D Trilinos_ENABLE_STKSearch=ON \
   -D Trilinos_ENABLE_STKUtil=ON \
   -D Trilinos_ENABLE_STKTopology=OFF \
   \
   -D Trilinos_ENABLE_ShyLU=ON \
   -D Trilinos_ENABLE_ShyLU_DDCore=ON \
   -D Trilinos_ENABLE_ShyLU_NodeHTS=ON \
   -D ShyLU_NodeHTS_ENABLE_TESTS=OFF \
   \
   -D Trilinos_ENABLE_Kokkos=ON \
   -D Trilinos_ENABLE_KokkosCore=ON \
   -D Kokkos_ENABLE_Serial=OFF \
   -D Kokkos_ENABLE_OpenMP=ON \
   -D Kokkos_ENABLE_Pthread=OFF \
   -D Kokkos_ENABLE_Cuda=OFF \
   -D Kokkos_ENABLE_Cuda_UVM=OFF \
   \
   -D Trilinos_ENABLE_SEACAS=ON \
   -D TPL_ENABLE_X11=OFF \
   -D TPL_ENABLE_Matio=OFF \
   \
   -D Trilinos_ENABLE_Gtest=ON \
   \
   -D Trilinos_ENABLE_TriKota=ON \
   -D DAKOTA_ENABLE_TESTS=OFF \
   -D Trilinos_ENABLE_ROL=ON \
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
   -D BLAS_LIBRARY_DIRS:PATH="${BLAS_DIR}/mkl/lib/intel64;${BLAS_DIR}/compiler/lib/intel64" \
   -D BLAS_LIBRARY_NAMES:STRING="mkl_intel_lp64;mkl_intel_thread;mkl_core;iomp5" \
   \
   -D TPL_ENABLE_LAPACK=ON \
   -D LAPACK_LIBRARY_DIRS:PATH="${LAPACK_DIR}/mkl/lib/intel64;${LAPACK_DIR}/compiler/lib/intel64" \
   -D LAPACK_LIBRARY_NAMES:STRING="mkl_intel_lp64;mkl_intel_thread;mkl_core;iomp5" \
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
