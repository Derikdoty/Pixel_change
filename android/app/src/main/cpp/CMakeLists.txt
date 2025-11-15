cmake_minimum_required(VERSION 3.10)

set(LIBIQ_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../native_libs/libimagequant")

message(STATUS "CMake current source dir: ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "Looking for libimagequant at: ${LIBIQ_DIR}")

if(NOT EXISTS "${LIBIQ_DIR}/libimagequant.c")
    message(FATAL_ERROR "libimagequant.c not found at: ${LIBIQ_DIR}/libimagequant.c")
endif()

add_library(
    image_quant_ffi
    SHARED
    image_quant_ffi.c
    ${LIBIQ_DIR}/libimagequant.c
    ${LIBIQ_DIR}/blur.c
    ${LIBIQ_DIR}/kmeans.c
    ${LIBIQ_DIR}/mediancut.c
    ${LIBIQ_DIR}/mempool.c
    ${LIBIQ_DIR}/nearest.c
    ${LIBIQ_DIR}/pam.c
    ${LIBIQ_DIR}/remap.c
)

target_include_directories(
    image_quant_ffi
    PUBLIC 
    ${LIBIQ_DIR}
)

target_link_libraries(
    image_quant_ffi
    android
    log
    m
)