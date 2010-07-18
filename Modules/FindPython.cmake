# - Find python
# This module searches for both the python interpreter and the python libraries
# and determines where they are located
#
#  Python_FOUND - The requested Python components were found
#  Python_EXECUTABLE  - path to the Python interpreter
#

#=============================================================================
# Copyright 2010 Branan Purvine-Riley
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distributed this file outside of CMake, substitute the full
#  License text for the above reference.)

IF("3" STREQUAL "${Python_FIND_VERSION_MAJOR}")
  SET(Python_3_OK "TRUE")
  SET(Python_2_OK "FALSE") # redundant in version selection code, but skips a FOREACH
ELSE("3" STREQUAL "${Python_FIND_VERSION_MAJOR}")
  SET(Python_2_OK "TRUE")
  # don't set Python_3_OK to false here - if the user specified it we want to search for Python 2 & 3
ENDIF("3" STREQUAL "${Python_FIND_VERSION_MAJOR}")

# This is  heavily inspired by FindBoost.cmake, with the addition of a second version list to keep
# python 2 and python 3 separate
IF(Python_FIND_VERSION_EXACT)
  SET(_Python_TEST_VERSIONS "${Python_FIND_VERSION_MAJOR}"."${Python_FIND_VERSION_MINOR}")
ELSE(Python_FIND_VERSION_EXACT)
  SET(_Python_3_KNOWN_VERSIONS ${Python_3_ADDITIONAL_VERSIONS}
    "3.1" "3.0")
  SET(_Python_2_KNOWN_VERSIONS ${Python_2_ADDITIONAL_VERSIONS}
    "2.7" "2.6" "2.5" "2.4" "2.3" "2.2" "2.1" "2.0" "1.6" "1.5")
  SET(_Python_TEST_VERSIONS)
  IF(Python_FIND_VERSION)
    IF(Python_3_OK)
      FOREACH(version ${_Python_3_KNOWN_VERSIONS})
        IF(NOT ${version} VERSION_LESS ${Python_FIND_VERSION})
          LIST(APPEND _Python_TEST_VERSIONS ${version})
        ENDIF(NOT ${version} VERSION_LESS ${Python_FIND_VERSION})
      ENDFOREACH(version)
    ENDIF(Python_3_OK)
    IF(Python_2_OK)
      FOREACH(version ${_Python_2_KNOWN_VERSIONS})
        IF(NOT ${version} VERSION_LESS ${Python_FIND_VERSION})
          LIST(APPEND _Python_TEST_VERSIONS ${version})
        ENDIF(NOT ${version} VERSION_LESS ${Python_FIND_VERSION})
      ENDFOREACH(version)
    ENDIF(Python_2_OK)
  ELSE(Python_FIND_VERSION)
    IF(Python_3_OK)
      LIST(APPEND _Python_TEST_VERSIONS ${_Python_3_KNOWN_VERSIONS})
    ENDIF(Python_3_OK)
    IF(Python_2_OK)
      LIST(APPEND _Python_TEST_VERSIONS ${_Python_2_KNOWN_VERSIONS})
    ENDIF(Python_2_OK)
  ENDIF(Python_FIND_VERSION)
ENDIF(Python_FIND_VERSION_EXACT)

SET(_Python_EXE_VERSIONS)
FOREACH(version ${_Python_TEST_VERSIONS})
  LIST(APPEND _Python_EXE_VERSIONS python${version})
ENDFOREACH(version ${_Python_TEST_VERSIONS})

IF(WIN32)
  SET(_Python_REGISTRY_KEYS)
  FOREACH(version ${_Python_TEST_VERSIONS})
    LIST(APPEND _Python_REGISTRY_KEYS [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${version}\\InstallPath])
  ENDFOREACH(version ${_Python_TEST_VERSIONS})
  # this will find any standard windows Python install before it finds anything from Cygwin
  FIND_PROGRAM(Python_EXECUTABLE NAMES python ${_Python_EXE_VERSIONS} PATHS ${_Python_REGISTRY_KEYS})
ELSE(WIN32)
  FIND_PROGRAM(Python_EXECUTABLE NAMES ${_Python_EXE_VERSIONS} python)
ENDIF(WIN32)


# Make sure our python version matches the requested version when we get a non-versioned executable name
GET_FILENAME_COMPONENT(_Python_EXENAME ${Python_EXECUTABLE} NAME_WE)
IF(Python_FIND_VERSION AND Python_EXECUTABLE AND ${_Python_EXENAME} STREQUAL "python")
  EXEC_PROGRAM("${Python_EXECUTABLE}" ARGS "--version" OUTPUT_VARIABLE _Python_VERSION)
  STRING(SUBSTRING "${_Python_VERSION}" 7 3 _Python_VERSION)
  IF(Python_FIND_VERSION_EXACT)
    IF(NOT ${_Python_VERSION} VERSION_EQUAL "${Python_FIND_VERSION_MAJOR}"."${Python_FIND_VERSION_MINOR}")
      SET(Python_EXECUTABLE)
    ENDIF(NOT ${_Python_VERSION} VERSION_EQUAL "${Python_FIND_VERSION_MAJOR}"."${Python_FIND_VERSION_MINOR}")
  ELSE(Python_FIND_VERSION_EXACT)
    IF(NOT ${_Python_VERSION} VERSION_LESS ${Python_FIND_VERSION})
      SET(Python_EXECUTABLE)
    ENDIF(NOT ${_Python_VERSION} VERSION_LESS ${Python_FIND_VERSION})
  ENDIF(Python_FIND_VERSION_EXACT)
ENDIF(Python_FIND_VERSION AND Python_EXECUTABLE AND ${_Python_EXENAME} STREQUAL "python")

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Python DEFAULT_MSG Python_EXECUTABLE)

MARK_AS_ADVANCED(Python_EXECUTABLE)
