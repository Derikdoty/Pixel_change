cmake_minimum_required(VERSION 3.10)

# Define the path to libimagequant relative to this CMakeLists.txt
set(LIBIQ_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../native_libs/libimagequant")

# Debug output
message(STATUS "CMake current source dir: ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "Looking for libimagequant at: ${LIBIQ_DIR}")

# Verify the main file exists
if(NOT EXISTS "${LIBIQ_DIR}/libimagequant.c")
    message(FATAL_ERROR "libimagequant.c not found at: ${LIBIQ_DIR}/libimagequant.c")
endif()

# Add the libimagequant library
add_library(
    image_quant_ffi
    SHARED
    # FFI bridge file (in the same directory as this CMakeLists.txt)
    image_quant_ffi.c
    
    # All libimagequant source files based on your directory listing
    ${LIBIQ_DIR}/libimagequant.c
    ${LIBIQ_DIR}/blur.c
    ${LIBIQ_DIR}/kmeans.c
    ${LIBIQ_DIR}/mediancut.c
    ${LIBIQ_DIR}/mempool.c
    ${LIBIQ_DIR}/nearest.c
    ${LIBIQ_DIR}/pam.c
    ${LIBIQ_DIR}/remap.c
)

# Specify include directories
target_include_directories(
    image_quant_ffi
    PUBLIC 
    ${LIBIQ_DIR}
)

# Link to Android libraries
target_link_libraries(
    image_quant_ffi
    android
    log
    m  # Math library
)