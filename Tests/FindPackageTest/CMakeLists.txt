cmake_minimum_required (VERSION 2.6)
PROJECT(FindPackageTest)

# Look for a package that has a find module and may be found.
FIND_PACKAGE(OpenGL QUIET)

# Look for a package that has no find module and will not be found.
FIND_PACKAGE(NotAPackage QUIET)

# Look for a package that has an advanced find module.
FIND_PACKAGE(VTK QUIET)

ADD_EXECUTABLE(FindPackageTest FindPackageTest.cxx)

# test behaviour of cmFindBase wrt. the CMAKE_PREFIX_PATH variable
# foo.h should be found in ${CMAKE_CURRENT_SOURCE_DIR}/include:

SET(CMAKE_PREFIX_PATH /blub /blah "${CMAKE_CURRENT_SOURCE_DIR}")
FIND_PATH(FOO_DIR foo.h)

IF(NOT FOO_DIR)
  MESSAGE(FATAL_ERROR "Did not find foo.h which is in ${CMAKE_CURRENT_SOURCE_DIR}/include
  CMAKE_PREFIX_PATH = ${CMAKE_PREFIX_PATH}")
ENDIF(NOT FOO_DIR)

LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
FIND_PACKAGE(VersionTestA 1)
FIND_PACKAGE(VersionTestB 1.2)
FIND_PACKAGE(VersionTestC 1.2.3)
FIND_PACKAGE(VersionTestD 1.2.3.4)

#-----------------------------------------------------------------------------

#SET(CMAKE_FIND_DEBUG_MODE 1)

# For purposes of the test wipe out previous find results.
SET(PACKAGES
  foo Foo Bar TFramework Tframework TApp Tapp Special
  VersionedA VersionedB VersionedC VersionedD VersionedE
  WrongA WrongB WrongC WrongD
  wibbleA wibbleB
  RecursiveA RecursiveB RecursiveC
  EnvA EnvB
  )
FOREACH(p ${PACKAGES})
  SET(${p}_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
ENDFOREACH(p)

# Enable framework and bundle searching.  Make sure bundles are found
# before unix-syle packages.
SET(CMAKE_FIND_FRAMEWORK LAST)
SET(CMAKE_FIND_APPBUNDLE FIRST)

# Set the wrong answer for a find to make sure it re-finds.
set(VersionedA_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lib/cmake/zot-4.0)

# Look for packages with new-style signatures.
FIND_PACKAGE(foo NO_MODULE)
FIND_PACKAGE(Foo CONFIGS FooConfig.cmake)
FIND_PACKAGE(Bar)
FIND_PACKAGE(TFramework CONFIGS TFrameworkConfig.cmake)
FIND_PACKAGE(Tframework)
FIND_PACKAGE(TApp)
FIND_PACKAGE(Tapp CONFIGS tapp-config.cmake)
FIND_PACKAGE(Special NAMES Suffix SuffixTest PATH_SUFFIXES test)
FIND_PACKAGE(VersionedA 2 NAMES zot)
FIND_PACKAGE(VersionedB 3.1 EXACT NAMES zot)
FIND_PACKAGE(VersionedC 4.0 EXACT NAMES zot)
FIND_PACKAGE(VersionedD 1.1 EXACT NAMES Baz)
FIND_PACKAGE(VersionedE 1.2 EXACT NAMES Baz)

# Test wrong initial path when result is present.
SET(WrongA_DIR "${VersionedD_DIR}")
FIND_PACKAGE(WrongA 1.2 EXACT NAMES Baz)

# Test wrong initial cache entry of UNINITIALIZED type when result is present.
SET(WrongB_DIR "${VersionedD_DIR}" CACHE UNINITIALIZED "Wrong Value" FORCE)
GET_PROPERTY(type CACHE WrongB_DIR PROPERTY TYPE)
FIND_PACKAGE(WrongB 1.2 EXACT NAMES Baz)

# Test wrong initial path when result is missing.
SET(WrongC_DIR "${VersionedD_DIR}")
FIND_PACKAGE(WrongC 1.3 EXACT QUIET NAMES Baz)

# Test wrong initial cache entry of UNINITIALIZED type when result is missing.
SET(WrongD_DIR "${VersionedD_DIR}" CACHE UNINITIALIZED "Wrong Value" FORCE)
GET_PROPERTY(type CACHE WrongD_DIR PROPERTY TYPE)
FIND_PACKAGE(WrongD 1.3 EXACT QUIET NAMES Baz)

# HINTS should override the system but PATHS should not
LIST(INSERT CMAKE_SYSTEM_PREFIX_PATH 0 "${CMAKE_CURRENT_SOURCE_DIR}/A")
FIND_PACKAGE(wibbleA NAMES wibble PATHS B)
FIND_PACKAGE(wibbleB NAMES wibble HINTS B)

# Look for package with recursive find-modules.
FIND_PACKAGE(RecursiveA)
FIND_PACKAGE(RecursiveB 2)
FIND_PACKAGE(RecursiveC 3.1 EXACT)

# Test <Package>_DIR environment variable.
# We erase the main prefix path to ensure the env var is used.
SET(CMAKE_PREFIX_PATH)
SET(ENV{EnvA_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/lib/zot-3.1")
FIND_PACKAGE(EnvA 3.1 EXACT QUIET NAMES zot) # Should Work
FIND_PACKAGE(EnvB 3.1 EXACT QUIET NAMES zot) # Should Fail

# Expected locations at which packages should be found.
SET(foo_EXPECTED "lib/foo-1.2/foo-config.cmake")
SET(Foo_EXPECTED "lib/foo-1.2/CMake/FooConfig.cmake")
SET(Bar_EXPECTED "lib/Bar/BarConfig.cmake")
SET(Special_EXPECTED "lib/suffix/test/SuffixTestConfig.cmake")
SET(TFramework_EXPECTED
  "TFramework.framework/Versions/A/Resources/CMake/TFrameworkConfig.cmake")
SET(Tframework_EXPECTED
  "TFramework.framework/Versions/A/Resources/tframework-config.cmake")
SET(TApp_EXPECTED
  "TApp.app/Contents/Resources/TAppConfig.cmake")
SET(Tapp_EXPECTED
  "TApp.app/Contents/Resources/cmake/tapp-config.cmake")
SET(VersionedA_EXPECTED "lib/zot-2.0/zot-config.cmake")
SET(VersionedB_EXPECTED "lib/zot-3.1/zot-config.cmake")
SET(VersionedC_EXPECTED "lib/cmake/zot-4.0/zot-config.cmake")
SET(VersionedD_EXPECTED "Baz 1.1/BazConfig.cmake")
SET(VersionedE_EXPECTED "Baz 1.2/CMake/BazConfig.cmake")
SET(WrongA_EXPECTED "${VersionedE_EXPECTED}")
SET(WrongB_EXPECTED "${VersionedE_EXPECTED}")
SET(WrongC_MISSING "WrongC_DIR-NOTFOUND")
SET(WrongD_MISSING "WrongD_DIR-NOTFOUND")
SET(wibbleA_EXPECTED "A/wibble-config.cmake")
SET(wibbleB_EXPECTED "B/wibble-config.cmake")
SET(RecursiveA_EXPECTED "lib/RecursiveA/recursivea-config.cmake")
SET(RecursiveB_EXPECTED "lib/zot-2.0/zot-config.cmake")
SET(RecursiveC_EXPECTED "lib/zot-3.1/zot-config.cmake")
SET(EnvA_EXPECTED "lib/zot-3.1/zot-config.cmake")
SET(EnvB_MISSING "EnvB_DIR-NOTFOUND")

# Check the results.
FOREACH(p ${PACKAGES})
  IF(DEFINED ${p}_MISSING)
    # Check and report failure.
    IF(NOT "${${p}_DIR}" STREQUAL "${${p}_MISSING}")
      MESSAGE(SEND_ERROR
        "Package ${p} should have been [${${p}_MISSING}] but "
        "was [${${p}_DIR}]")
    ENDIF()
  ELSEIF(${p}_FOUND)
    # Convert to relative path for comparison to expected location.
    FILE(RELATIVE_PATH REL_${p}_CONFIG "${CMAKE_CURRENT_SOURCE_DIR}"
      "${${p}_CONFIG}")

    # Debugging output.
    IF(CMAKE_FIND_DEBUG_MODE)
      MESSAGE("Package ${p} found [${REL_${p}_CONFIG}]")
    ENDIF(CMAKE_FIND_DEBUG_MODE)

    # Check and report failure.
    IF(NOT "${REL_${p}_CONFIG}" STREQUAL "${${p}_EXPECTED}")
      MESSAGE(SEND_ERROR
        "Package ${p} should have been [${${p}_EXPECTED}] but "
        "was [${REL_${p}_CONFIG}]")
    ENDIF(NOT "${REL_${p}_CONFIG}" STREQUAL "${${p}_EXPECTED}")
  ELSE()
    MESSAGE(SEND_ERROR "Package ${p} not found!")
  ENDIF()
ENDFOREACH(p)

# Check that version information was extracted.
IF(NOT "${VersionedA_VERSION}" STREQUAL "2.0")
  MESSAGE(SEND_ERROR
    "Package VersionedA is version [${VersionedA_VERSION}], not [2.0]")
ENDIF(NOT "${VersionedA_VERSION}" STREQUAL "2.0")
IF(NOT "${VersionedA_VERSION_MAJOR}" STREQUAL "2")
  MESSAGE(SEND_ERROR
    "Package VersionedA is major version [${VersionedA_VERSION_MAJOR}], not [2]")
ENDIF(NOT "${VersionedA_VERSION_MAJOR}" STREQUAL "2")
IF(NOT "${VersionedA_VERSION_MINOR}" STREQUAL "0")
  MESSAGE(SEND_ERROR
    "Package VersionedA is minor version [${VersionedA_VERSION_MINOR}], not [0]")
ENDIF(NOT "${VersionedA_VERSION_MINOR}" STREQUAL "0")

IF(NOT "${VersionedB_VERSION}" STREQUAL "3.1")
  MESSAGE(SEND_ERROR
    "Package VersionedB is version [${VersionedB_VERSION}], not [3.1]")
ENDIF(NOT "${VersionedB_VERSION}" STREQUAL "3.1")
IF(NOT "${VersionedB_VERSION_MAJOR}" STREQUAL "3")
  MESSAGE(SEND_ERROR
    "Package VersionedB is major version [${VersionedB_VERSION_MAJOR}], not [3]")
ENDIF(NOT "${VersionedB_VERSION_MAJOR}" STREQUAL "3")
IF(NOT "${VersionedB_VERSION_MINOR}" STREQUAL "1")
  MESSAGE(SEND_ERROR
    "Package VersionedB is minor version [${VersionedB_VERSION_MINOR}], not [1]")
ENDIF(NOT "${VersionedB_VERSION_MINOR}" STREQUAL "1")

IF(NOT "${Special_VERSION}" STREQUAL "1.2")
  MESSAGE(SEND_ERROR
    "Package Special is version [${Special_VERSION}], not [1.2]")
ENDIF(NOT "${Special_VERSION}" STREQUAL "1.2")
IF(NOT "${Special_VERSION_MAJOR}" STREQUAL "1")
  MESSAGE(SEND_ERROR
    "Package Special is major version [${Special_VERSION_MAJOR}], not [1]")
ENDIF(NOT "${Special_VERSION_MAJOR}" STREQUAL "1")
IF(NOT "${Special_VERSION_MINOR}" STREQUAL "2")
  MESSAGE(SEND_ERROR
    "Package Special is minor version [${Special_VERSION_MINOR}], not [2]")
ENDIF(NOT "${Special_VERSION_MINOR}" STREQUAL "2")

# Test version number comparison.
IF(NOT "1.2.3.4" VERSION_LESS "1.2.3.5")
  MESSAGE(SEND_ERROR "1.2.3.4 VERSION_LESS 1.2.3.5 is not true!")
ENDIF()
IF(NOT "1.2" VERSION_LESS "1.10")
  MESSAGE(SEND_ERROR "1.2 VERSION_LESS 1.10 is not true!")
ENDIF()
IF(NOT "1.02" VERSION_GREATER "1.1")
  MESSAGE(SEND_ERROR "1.02 VERSION_GREATER 1.1 is not true!")
ENDIF()
IF("1.2.3" VERSION_GREATER "1.2.3.4")
  MESSAGE(SEND_ERROR "1.2.3 VERSION_GREATER 1.2.3.4 is not false!")
ENDIF()
IF(NOT "1.2" VERSION_EQUAL "1.2.0.0")
  MESSAGE(SEND_ERROR "1.2 VERSION_EQUAL 1.2.0.0 is not true!")
ENDIF()

#-----------------------------------------------------------------------------
# Test export(PACKAGE) with find_package.
MESSAGE(STATUS "Preparing export(PACKAGE) test project")
TRY_COMPILE(EXPORTER_COMPILED
  ${FindPackageTest_BINARY_DIR}/Exporter
  ${FindPackageTest_SOURCE_DIR}/Exporter
  CMakeTestExportPackage dummy
  OUTPUT_VARIABLE output)
MESSAGE(STATUS "Searching for export(PACKAGE) test project")
SET(CMakeTestExportPackage_DIR "" CACHE FILEPATH
  "Wipe out find results for testing." FORCE)
STRING(REGEX REPLACE "-.*$" "" version ${CMAKE_VERSION})
FIND_PACKAGE(CMakeTestExportPackage 1.${version} EXACT REQUIRED)
