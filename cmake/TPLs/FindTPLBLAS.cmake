
tribits_tpl_allow_pre_find_package(BLAS BLAS_ALLOW_PREFIND)

if (BLAS_ALLOW_PREFIND)
  message("-- Using find_package(BLAS ...) ...")
  find_package(BLAS)
  if (BLAS_FOUND)
    message("-- Found BLAS_DIR='${BLAS_DIR}'")
    message("-- Generating BLAS::all_libs and BLASConfig.cmake")
    tribits_extpkg_create_imported_all_libs_target_and_config_file(BLAS
      INNER_FIND_PACKAGE_NAME  BLAS
      IMPORTED_TARGETS_FOR_ALL_LIBS BLAS::BLAS)
  endif()
endif()

if (NOT TARGET BLAS::all_libs)
  if (MSVC AND NOT
      (BLAS_LIBRARY_DIRS  OR
      (NOT "${BLAS_LIBRARY_NAMES}" STREQUAL "blas blas_win32" AND
        NOT "${BLAS_LIBRARY_NAMES}" STREQUAL "") OR
      BLAS_INCLUDE_DIRS  OR
      BLAS_INCLUDE_NAMES OR
      (NOT "${TPL_BLAS_LIBRARIES}" STREQUAL "blas" AND
        NOT "${TPL_BLAS_LIBRARIES}" STREQUAL "") OR
      TPL_BLAS_INCLUDE_DIRS)
    )
    # Find the CLAPACK built by CMake on the machine for MSVC if found it will
    # set the BLAS and LAPACK libraries.  NOTE: This the FindCLAPACK module must
    # be called every configure or this does not work!
    # If the user has specified alternate name or location of their blas that
    # will be used instead.
    find_package(CLAPACK 3.2.1 NO_MODULE)
    if (CLAPACK_FOUND)
      advanced_set(TPL_BLAS_LIBRARIES blas
        CACHE FILEPATH "Set from MSVC CLAPACK specialization")
    endif()
  endif()

  tribits_tpl_find_include_dirs_and_libraries(BLAS
    REQUIRED_LIBS_NAMES "blas blas_win32")
endif()