# Common Ambient Variables:
#   CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#   CURRENT_PORT DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
#   PORT                      = current port name (zlib, etc)
#   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
#   VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
#   VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
#   VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
#   VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
#

include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/cppunit-1.13.2)
vcpkg_download_distfile(ARCHIVE
    URLS "http://dev-www.libreoffice.org/src/cppunit-1.13.2.tar.gz"
    FILENAME "cppunit-1.13.2.tar.gz"
    SHA512 8f4be569f321d577cec31931f49f4df143bc94e283605509b6ea50c60690aa91a2aed940e7eebd4b2413a4218f9a6c3978d312d8e587eab040283c6563846ecd
)
vcpkg_extract_source_archive(${ARCHIVE})

if (VCPKG_CRT_LINKAGE STREQUAL static)
    vcpkg_apply_patches(
        SOURCE_PATH ${SOURCE_PATH}
        PATCHES
            # Make sure cppunit static lib uses static CRT linkage
            ${CMAKE_CURRENT_LIST_DIR}/0001-static-crt-linkage.patch
    )
endif()

if (VCPKG_TARGET_ARCHITECTURE MATCHES "x86")
    set(BUILD_ARCH "Win32")
    set(OUTPUT_DIR "Win32")
elseif (VCPKG_TARGET_ARCHITECTURE MATCHES "x64")
    set(BUILD_ARCH "x64")
else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    vcpkg_build_msbuild(
        PROJECT_PATH ${SOURCE_PATH}/src/cppunit/cppunit_dll.vcxproj
        PLATFORM ${BUILD_ARCH})
elseif (VCPKG_LIBRARY_LINKAGE STREQUAL static)
    vcpkg_build_msbuild(
        PROJECT_PATH ${SOURCE_PATH}/src/cppunit/cppunit.vcxproj
        PLATFORM ${BUILD_ARCH})
endif()

file(COPY ${SOURCE_PATH}/include/cppunit DESTINATION ${CURRENT_PACKAGES_DIR}/include FILES_MATCHING PATTERN *.h)

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    file(COPY ${SOURCE_PATH}/lib/cppunitd_dll.dll DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
    file(COPY ${SOURCE_PATH}/lib/cppunitd_dll.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(COPY ${SOURCE_PATH}/lib/cppunit_dll.dll DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
    file(COPY ${SOURCE_PATH}/lib/cppunit_dll.lib DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
elseif (VCPKG_LIBRARY_LINKAGE STREQUAL static)
    file(COPY ${SOURCE_PATH}/lib/cppunitd.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(COPY ${SOURCE_PATH}/lib/cppunit.lib DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
endif()

# Handle copyright
file(COPY ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/cppunit)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/cppunit/COPYING ${CURRENT_PACKAGES_DIR}/share/cppunit/copyright)

vcpkg_copy_pdbs()