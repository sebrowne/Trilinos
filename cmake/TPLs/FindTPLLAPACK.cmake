
tribits_tpl_allow_pre_find_package(LAPACK LAPACK_ALLOW_PREFIND)

if (LAPACK_ALLOW_PREFIND)
  message("-- Using find_package(LAPACK ...) ...")
  find_package(LAPACK)
  if (LAPACK_FOUND)
    message("-- Found LAPACK_DIR='${LAPACK_DIR}'")
    message("-- Generating LAPACK::all_libs and LAPACKConfig.cmake")
    tribits_extpkg_create_imported_all_libs_target_and_config_file(LAPACK
      INNER_FIND_PACKAGE_NAME  LAPACK
      IMPORTED_TARGETS_FOR_ALL_LIBS LAPACK::LAPACK)
  endif()
endif()

if (NOT TARGET LAPACK::all_libs)
  if (MSVC AND NOT
      (LAPACK_LIBRARY_DIRS  OR
      (NOT "${LAPACK_LIBRARY_NAMES}" STREQUAL "lapack lapack_win32" AND
        NOT "${LAPACK_LIBRARY_NAMES}" STREQUAL "") OR
      LAPACK_INCLUDE_DIRS  OR
      LAPACK_INCLUDE_NAMES OR
      (NOT "${TPL_LAPACK_LIBRARIES}" STREQUAL "lapack" AND
        NOT "${TPL_LAPACK_LIBRARIES}" STREQUAL "") OR
      TPL_LAPACK_INCLUDE_DIRS)
    )
    if(CLAPACK_FOUND)
      advanced_set(TPL_LAPACK_LIBRARIES lapack
          CACHE FILEPATH "Set from MSVC CLAPACK specialization")
    endif()
  endif()

  tribits_tpl_find_include_dirs_and_libraries(LAPACK
    REQUIRED_LIBS_NAMES "lapack lapack_win32")
endif()