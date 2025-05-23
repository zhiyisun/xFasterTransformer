# Copyright (c) 2023 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

cmake_minimum_required(VERSION 3.18)

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.24.0")
    cmake_policy(SET CMP0135 NEW)
endif()

project(dependency NONE)

include(ExternalProject)

set(ONEDNN_BUILD_OPTIONS -DONEDNN_LIBRARY_TYPE=STATIC -DONEDNN_BUILD_TESTS=OFF -DONEDNN_BUILD_EXAMPLES=OFF)
if(WITH_GPU)
    set(ONEDNN_BUILD_OPTIONS "${ONEDNN_BUILD_OPTIONS};-DONEDNN_GPU_RUNTIME=SYCL")
endif()

set(ONEDNN_3rdparty_DIR "${CMAKE_SOURCE_DIR}/3rdparty/onednn")

set(ONEDNN_TAG "v3.5")

set(SKIP_FLAG FALSE)

if(EXISTS ${ONEDNN_3rdparty_DIR})
    file(GLOB FILES "${ONEDNN_3rdparty_DIR}/*")

    if(FILES)
        find_program(GIT_EXECUTABLE git)
        if(NOT GIT_EXECUTABLE)
            message(FATAL_ERROR "Git not found. Aborting.")
        endif()

        execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags
        WORKING_DIRECTORY ${ONEDNN_3rdparty_DIR}
        OUTPUT_VARIABLE CURRENT_TAG
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        message(STATUS "Current TAG of OneDNN : ${CURRENT_TAG}")

        if(CURRENT_TAG STREQUAL ${ONEDNN_TAG})
            set(SKIP_FLAG TRUE)
        endif()
    else()
        file(REMOVE_RECURSE ${ONEDNN_3rdparty_DIR})
    endif()
endif()

if(NOT SKIP_FLAG)
    # cmake-format: off
    ExternalProject_Add(onednn
      GIT_REPOSITORY    https://github.com/oneapi-src/oneDNN.git
      GIT_TAG           ${ONEDNN_TAG}
      SOURCE_DIR        ${ONEDNN_3rdparty_DIR}
      BINARY_DIR        ${ONEDNN_3rdparty_DIR}
      CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory "build" && ${CMAKE_COMMAND} -E chdir "build" ${CMAKE_COMMAND} ${ONEDNN_BUILD_OPTIONS} ..
      BUILD_COMMAND     ${CMAKE_COMMAND} -E chdir "build" make -j all
      INSTALL_COMMAND   ""
      TEST_COMMAND      ""
    )
    # cmake-format: on
else()
    if(NOT TARGET onednn)
        add_library(onednn INTERFACE)
    endif()
    message(STATUS "oneDNN directory already exists. Skipping installation.")
endif()
