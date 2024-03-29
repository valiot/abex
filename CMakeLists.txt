cmake_minimum_required (VERSION 2.8...3.19)

# prevent expansion of quoted things that could be variables in if()
if(${CMAKE_VERSION} VERSION_GREATER 3.1)
    cmake_policy(SET CMP0054 NEW)
endif()

# this is the root libplctag project
project (libplctag_project)

# make sure our outputs are going somewhere sane
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY $ENV{MIX_COMPILE_PATH}/../priv)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY $ENV{MIX_COMPILE_PATH}/../priv)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY $ENV{MIX_COMPILE_PATH}/../priv)

# the project is version 2.0
set (libplctag_VERSION_MAJOR 2)
set (libplctag_VERSION_MINOR 0)
set (libplctag_VERSION_PATCH 26)
set (VERSION "${libplctag_VERSION_MAJOR}.${libplctag_VERSION_MINOR}.${libplctag_VERSION_PATCH}")

# we need threads
find_package(Threads REQUIRED)


# set the main paths.
set ( base_PATH "${PROJECT_SOURCE_DIR}/src/libplctag" )
set ( base_SRC_PATH "${base_PATH}/src" )
set ( lib_SRC_PATH "${base_SRC_PATH}/lib" )
set ( protocol_SRC_PATH "${base_SRC_PATH}/protocols" )
set ( ab_SRC_PATH "${protocol_SRC_PATH}/ab" )
set ( util_SRC_PATH "${base_SRC_PATH}/util" )
set ( example_SRC_PATH "${base_SRC_PATH}/examples" )
set ( test_SRC_PATH "${base_SRC_PATH}/tests" )

# OS-specific files for the platform code.
# FIXME - does this work for macOS?
if (UNIX)
    set ( platform_SRC_PATH "${base_SRC_PATH}/platform/linux" )
elseif (WIN32)
    set ( platform_SRC_PATH "${base_SRC_PATH}/platform/windows" )
endif()


# where to find include files.
include_directories("${base_SRC_PATH}")
include_directories("${platform_SRC_PATH}")
include_directories("${protocol_SRC_PATH}")

# C compiler specific settings
if (CMAKE_C_COMPILER_ID STREQUAL "Clang")
    # using Clang
    set(BASE_RELEASE_FLAGS "${CMAKE_C_FLAGS} -Wall -pedantic -Wextra -Wc99-c11-compat -Wconversion -fms-extensions -fno-strict-aliasing -D__USE_POSIX=1 -D_POSIX_C_SOURCE=200809L")
    set(BASE_DEBUG_FLAGS "${CMAKE_C_FLAGS}  -g -Wall -pedantic -Wextra -Wc99-c11-compat -Wconversion -fms-extensions -fno-strict-aliasing -D__USE_POSIX=1 -D_POSIX_C_SOURCE=200809L")
elseif (CMAKE_C_COMPILER_ID STREQUAL "GNU")
    # using GCC
    set(BASE_RELEASE_FLAGS "${CMAKE_C_FLAGS} -Wall -pedantic -Wextra -Wc99-c11-compat -Wconversion -fms-extensions -fno-strict-aliasing -D__USE_POSIX=1 -D_POSIX_C_SOURCE=200809L")
    set(BASE_DEBUG_FLAGS "${CMAKE_C_FLAGS}  -g -Wall -pedantic -Wextra -Wc99-c11-compat -Wconversion -fms-extensions -fno-strict-aliasing -D__USE_POSIX=1 -D_POSIX_C_SOURCE=200809L")
elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
    # using Intel C/C++
    MESSAGE("Intel C compiler not supported!")
elseif (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    # using Visual Studio C/C++
    set(BASE_RELEASE_FLAGS "${CMAKE_C_FLAGS} /DLIBPLCTAGDLL_EXPORTS=1 /W3")
    set(BASE_DEBUG_FLAGS "${CMAKE_C_FLAGS} /DLIBPLCTAGDLL_EXPORTS=1 /W3")
    # /MD$<$<STREQUAL:$<CONFIGURATION>,Debug>:d>
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(BASE_FLAGS "${BASE_DEBUG_FLAGS}")
else()
    set(BASE_FLAGS "${BASE_RELEASE_FLAGS}")
endif()

#MESSAGE("BASE_FLAGS=${BASE_FLAGS}")

if (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    # check MSVC version, only newer versions than 2012 support C99 things we need
    if((${MSVC_VERSION} EQUAL 1800) OR (${MSVC_VERSION} LESS 1800))
        message("MSVC cannot handle C99, compiling code as C++")
        set(BASE_C_FLAGS "${BASE_FLAGS}")
    else()
        message("MSVC can handle C99, compiling code as C")
        set(BASE_C_FLAGS "${BASE_FLAGS} /c")
    endif()
else()
    #set(BASE_C_FLAGS "${BASE_FLAGS} -std=c99 -Wc++-compat ")
    set(BASE_C_FLAGS "${BASE_FLAGS} -std=c99")
endif()

set(BASE_CXX_FLAGS "${BASE_FLAGS}")

# clear incompatible flags
string(REPLACE "-fPIE" "-fPIC" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
string(REPLACE "-fPIE" "-fPIC" BASE_C_FLAGS "${BASE_C_FLAGS}")

# generate version file from CMake info.
CONFIGURE_FILE("${lib_SRC_PATH}/version.c.in" "${lib_SRC_PATH}/version.c" @ONLY)

# set up the library sources
set ( libplctag_SRCS "${lib_SRC_PATH}/init.c"
                     "${lib_SRC_PATH}/init.h"
                     "${lib_SRC_PATH}/libplctag.h"
                     "${lib_SRC_PATH}/lib.c"
                     "${lib_SRC_PATH}/tag.h"
                     "${lib_SRC_PATH}/version.h"
                     "${lib_SRC_PATH}/version.c"
                     "${ab_SRC_PATH}/ab.h"
                     "${ab_SRC_PATH}/ab_common.c"
                     "${ab_SRC_PATH}/ab_common.h"
                     "${ab_SRC_PATH}/cip.c"
                     "${ab_SRC_PATH}/cip.h"
                     "${ab_SRC_PATH}/defs.h"
                     "${ab_SRC_PATH}/eip_cip.c"
                     "${ab_SRC_PATH}/eip_cip.h"
                     "${ab_SRC_PATH}/eip_dhp_pccc.c"
                     "${ab_SRC_PATH}/eip_dhp_pccc.h"
                     "${ab_SRC_PATH}/eip_lgx_pccc.c"
                     "${ab_SRC_PATH}/eip_lgx_pccc.h"
                     "${ab_SRC_PATH}/eip_plc5_pccc.c"
                     "${ab_SRC_PATH}/eip_plc5_pccc.h"
                     "${ab_SRC_PATH}/eip_slc_pccc.c"
                     "${ab_SRC_PATH}/eip_slc_pccc.h"
                     "${ab_SRC_PATH}/error_codes.c"
                     "${ab_SRC_PATH}/error_codes.h"
                     "${ab_SRC_PATH}/pccc.c"
                     "${ab_SRC_PATH}/pccc.h"
                     "${ab_SRC_PATH}/session.c"
                     "${ab_SRC_PATH}/session.h"
                     "${ab_SRC_PATH}/tag.h"
                     "${protocol_SRC_PATH}/system/system.c"
                     "${protocol_SRC_PATH}/system/system.h"
                     "${protocol_SRC_PATH}/system/tag.h"
                     "${util_SRC_PATH}/atomic_int.c"
                     "${util_SRC_PATH}/atomic_int.h"
                     "${util_SRC_PATH}/attr.c"
                     "${util_SRC_PATH}/attr.h"
                     "${util_SRC_PATH}/byteorder.h"
                     "${util_SRC_PATH}/debug.c"
                     "${util_SRC_PATH}/debug.h"
                     "${util_SRC_PATH}/hash.c"
                     "${util_SRC_PATH}/hash.h"
                     "${util_SRC_PATH}/hashtable.c"
                     "${util_SRC_PATH}/hashtable.h"
                     "${util_SRC_PATH}/macros.h"
                     "${util_SRC_PATH}/rc.c"
                     "${util_SRC_PATH}/rc.h"
                     "${util_SRC_PATH}/vector.c"
                     "${util_SRC_PATH}/vector.h"
                     "${platform_SRC_PATH}/platform.c"
                     "${platform_SRC_PATH}/platform.h" )

# set the compiler flags
FOREACH( lib_src ${libplctag_SRCS} )
    set_source_files_properties(${lib_src} PROPERTIES COMPILE_FLAGS ${BASE_C_FLAGS})
ENDFOREACH()

# shared library
add_library(plctag SHARED ${libplctag_SRCS} )
add_library(plctag_static STATIC ${libplctag_SRCS} )


#if(THREADS_HAVE_PTHREAD_ARG)
#  set_property(TARGET plctag PROPERTY COMPILE_OPTIONS "-pthread")
#  set_property(TARGET plctag PROPERTY INTERFACE_COMPILE_OPTIONS "-pthread")
#endif()

# make sure we link with the threading library.
if (UNIX)
    if(CMAKE_THREAD_LIBS_INIT)
      target_link_libraries(plctag "${CMAKE_THREAD_LIBS_INIT}")
    endif()
endif()

# Windows needs to link the library to the WINSOCK library
if (WIN32)
    target_link_libraries(plctag ws2_32)
endif()

# add the examples and tests
if (UNIX)
    # Logix simulator
    set ( lgx_sim_FILES "${test_SRC_PATH}/lgx_sim/log.h"
                        "${test_SRC_PATH}/lgx_sim/main.c"
                        "${test_SRC_PATH}/lgx_sim/packet.h"
                        "${test_SRC_PATH}/lgx_sim/main.c"
                        "${test_SRC_PATH}/lgx_sim/session.c"
                        "${test_SRC_PATH}/lgx_sim/session.h"
                        "${test_SRC_PATH}/lgx_sim/tags.c"
                        "${test_SRC_PATH}/lgx_sim/tags.h" )

    foreach ( file ${lgx_sim_FILES} )
        set_source_files_properties("${file}" PROPERTIES COMPILE_FLAGS "${BASE_FLAGS} -std=c11")
    endforeach ( file )

    add_executable ( lgx_sim ${lgx_sim_FILES} )
    target_link_libraries ( lgx_sim pthread )

    add_executable(test_hashtable "${test_SRC_PATH}/hashtable/test_hashtable.c" "${util_SRC_PATH}/hashtable.h" "${util_SRC_PATH}/debug.h")
    target_link_libraries(test_hashtable plctag pthread)


    set ( example_PROGRAMS async
                           data_dumper
                           list_tags
                           multithread
                           multithread_cached_read
                           multithread_plc5
                           multithread_plc5_dhp
                           plc5
                           simple
                           simple_dual
                           slc500
                           stress_api_lock
                           stress_test
                           string
                           test_reconnect
                           test_special
                           toggle_bool
                           write_string
                           tag_rw )

    set ( example_PROG_UTIL utils_posix.c )
    set ( example_LIBRARIES plctag pthread )


elseif(WIN32)
    set ( example_PROGRAMS async
                           list_tags
                           plc5
                           simple
                           simple_dual
                           slc500
                           string
                           test_special
                           toggle_bool
                           write_string
                           tag_rw )

    set ( example_PROG_UTIL utils_windows.c)
    set ( example_LIBRARIES plctag ws2_32 )
endif()

set (abex_PROGRAMS tag_list rw_tag)

# simple.cpp is different because it is C++
set_source_files_properties("${example_SRC_PATH}/simple_cpp.cpp" PROPERTIES COMPILE_FLAGS ${BASE_CXX_FLAGS})
add_executable (simple_cpp "${example_SRC_PATH}/simple_cpp.cpp" "${example_SRC_PATH}/${example_PROG_UTIL}" "${example_SRC_PATH}/utils.h" )
target_link_libraries (simple_cpp ${example_LIBRARIES} )


foreach ( example ${example_PROGRAMS} )
    set_source_files_properties("${example_SRC_PATH}/${example}.c" PROPERTIES COMPILE_FLAGS ${BASE_C_FLAGS})
    add_executable( ${example} "${example_SRC_PATH}/${example}.c" "${example_SRC_PATH}/${example_PROG_UTIL}" "${example_SRC_PATH}/utils.h" )
    target_link_libraries(${example} ${example_LIBRARIES} )
endforeach(example)

# abex source code
foreach ( example ${abex_PROGRAMS} )
    set_source_files_properties("${base_PATH}/../${example}.c" PROPERTIES COMPILE_FLAGS ${BASE_C_FLAGS})
    add_executable( ${example} "${base_PATH}/../${example}.c" "${example_SRC_PATH}/${example_PROG_UTIL}" "${example_SRC_PATH}/utils.h" )
    target_link_libraries(${example} ${example_LIBRARIES} )
endforeach(example)


# Generate files from templates
CONFIGURE_FILE("${base_PATH}/libplctag.pc.in" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/libplctag.pc" @ONLY)

# for installation
install(TARGETS plctag DESTINATION lib${LIB_SUFFIX})
install(TARGETS plctag_static DESTINATION lib${LIB_SUFFIX})
install(FILES "${lib_SRC_PATH}/libplctag.h" DESTINATION include)
install(FILES "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/libplctag.pc" DESTINATION "lib${LIB_SUFFIX}/pkgconfig")

message(STATUS "Debug CMAKE_C_FLAGS=${CMAKE_C_FLAGS}; BASE_C_FLAGS=${BASE_C_FLAGS}")

macro(print_all_variables)
    message(STATUS "print_all_variables------------------------------------------{")
    get_cmake_property(_variableNames VARIABLES)
    foreach (_variableName ${_variableNames})
        message(STATUS "${_variableName}=${${_variableName}}")
    endforeach()
    message(STATUS "print_all_variables------------------------------------------}")
endmacro()

# Debugging
#print_all_variables()
