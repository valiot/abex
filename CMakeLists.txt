cmake_minimum_required (VERSION 2.8...3.19)

# prevent expansion of quoted things that could be variables in if()
if(${CMAKE_VERSION} VERSION_GREATER 3.1)
    cmake_policy(SET CMP0054 NEW)
endif()

# this is the root libplctag project for abex
project (libplctag_project)

# make sure our outputs are going somewhere sane
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY $ENV{MIX_COMPILE_PATH}/../priv)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY $ENV{MIX_COMPILE_PATH}/../priv)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY $ENV{MIX_COMPILE_PATH}/../priv)

# the project is version 2.6
set (libplctag_VERSION_MAJOR 2)
set (libplctag_VERSION_MINOR 6)
set (libplctag_VERSION_PATCH 12)
set (VERSION "${libplctag_VERSION_MAJOR}.${libplctag_VERSION_MINOR}.${libplctag_VERSION_PATCH}")

# we need threads
find_package(Threads REQUIRED)

# set the main paths for abex custom programs
set ( base_PATH "${PROJECT_SOURCE_DIR}/src/libplctag" )
set ( abex_SRC_PATH "${PROJECT_SOURCE_DIR}/src" )

# C compiler specific settings
if (CMAKE_C_COMPILER_ID STREQUAL "Clang")
    # using Clang
    set(BASE_RELEASE_FLAGS "${CMAKE_C_FLAGS} -Wall -pedantic -Wextra -Wc99-c11-compat -Wconversion -fms-extensions -fno-strict-aliasing -D__USE_POSIX=1 -D_POSIX_C_SOURCE=200809L")
    set(BASE_DEBUG_FLAGS "${CMAKE_C_FLAGS}  -g -Wall -pedantic -Wextra -Wc99-c11-compat -Wconversion -fms-extensions -fno-strict-aliasing -D__USE_POSIX=1 -D_POSIX_C_SOURCE=200809L")
elseif (CMAKE_C_COMPILER_ID STREQUAL "GNU")
    # using GCC
    set(BASE_RELEASE_FLAGS "${CMAKE_C_FLAGS} -Wall -pedantic -Wextra -Wc99-c11-compat -Wconversion -fms-extensions -fno-strict-aliasing -D__USE_POSIX=1 -D_POSIX_C_SOURCE=200809L")
    set(BASE_DEBUG_FLAGS "${CMAKE_C_FLAGS}  -g -Wall -pedantic -Wextra -Wc99-c11-compat -Wconversion -fms-extensions -fno-strict-aliasing -D__USE_POSIX=1 -D_POSIX_C_SOURCE=200809L")
elseif (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    # using Visual Studio C/C++
    set(BASE_RELEASE_FLAGS "${CMAKE_C_FLAGS} /DLIBPLCTAGDLL_EXPORTS=1 /W3")
    set(BASE_DEBUG_FLAGS "${CMAKE_C_FLAGS} /DLIBPLCTAGDLL_EXPORTS=1 /W3")
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(BASE_FLAGS "${BASE_DEBUG_FLAGS}")
else()
    set(BASE_FLAGS "${BASE_RELEASE_FLAGS}")
endif()

if (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    # check MSVC version
    if((${MSVC_VERSION} EQUAL 1800) OR (${MSVC_VERSION} LESS 1800))
        message("MSVC cannot handle C99, compiling code as C++")
        set(BASE_C_FLAGS "${BASE_FLAGS}")
    else()
        message("MSVC can handle C99, compiling code as C")
        set(BASE_C_FLAGS "${BASE_FLAGS} /c")
    endif()
else()
    set(BASE_C_FLAGS "${BASE_FLAGS} -std=c99")
endif()

# clear incompatible flags
string(REPLACE "-fPIE" "-fPIC" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
string(REPLACE "-fPIE" "-fPIC" BASE_C_FLAGS "${BASE_C_FLAGS}")

# Include directories
include_directories("${base_PATH}/src")
include_directories("${base_PATH}/src/examples")

# Build libplctag library using its own CMakeLists.txt
# We need to set some variables that the submodule expects
set(BUILD_EXAMPLES 0 CACHE BOOL "Don't build libplctag examples" FORCE)
set(BUILD_TESTS 0 CACHE BOOL "Don't build libplctag tests" FORCE)

# Add libplctag as subdirectory
add_subdirectory("${base_PATH}" libplctag_build)

# Now build our abex-specific programs
set(abex_PROGRAMS tag_list rw_tag)
set(libplctag_EXAMPLES tag_rw2)

# abex programs need compat_utils from libplctag examples
set(abex_UTIL_SOURCES 
    "${base_PATH}/src/examples/compat_utils.c" 
    "${base_PATH}/src/examples/compat_utils.h")

# Build abex custom programs
foreach(program ${abex_PROGRAMS})
    set_source_files_properties("${abex_SRC_PATH}/${program}.c" PROPERTIES COMPILE_FLAGS ${BASE_C_FLAGS})
    set_source_files_properties("${base_PATH}/src/examples/compat_utils.c" PROPERTIES COMPILE_FLAGS ${BASE_C_FLAGS})
    
    add_executable(${program} "${abex_SRC_PATH}/${program}.c" "${abex_UTIL_SOURCES}")
    
    # Link with the plctag library and threads
    target_link_libraries(${program} plctag_dyn)
    
    if(UNIX)
        if(CMAKE_THREAD_LIBS_INIT)
            target_link_libraries(${program} "${CMAKE_THREAD_LIBS_INIT}")
        endif()
    elseif(WIN32)
        target_link_libraries(${program} ws2_32)
    endif()
endforeach(program)

# Build libplctag example programs
foreach(program ${libplctag_EXAMPLES})
    set_source_files_properties("${base_PATH}/src/examples/${program}.c" PROPERTIES COMPILE_FLAGS ${BASE_C_FLAGS})
    set_source_files_properties("${base_PATH}/src/examples/compat_utils.c" PROPERTIES COMPILE_FLAGS ${BASE_C_FLAGS})
    
    add_executable(${program} "${base_PATH}/src/examples/${program}.c" "${abex_UTIL_SOURCES}")
    
    # Link with the plctag library and threads
    target_link_libraries(${program} plctag_dyn)
    
    if(UNIX)
        if(CMAKE_THREAD_LIBS_INIT)
            target_link_libraries(${program} "${CMAKE_THREAD_LIBS_INIT}")
        endif()
    elseif(WIN32)
        target_link_libraries(${program} ws2_32)
    endif()
endforeach(program)

message(STATUS "ABex programs configured: ${abex_PROGRAMS}")
message(STATUS "libplctag examples configured: ${libplctag_EXAMPLES}")
