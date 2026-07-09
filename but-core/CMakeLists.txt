cmake_minimum_required(VERSION 3.16)
project(but-core VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# OpenSSL for SHA-512
find_package(OpenSSL REQUIRED)

# Butcoin Core Library
add_library(butcore STATIC
    src/main.cpp
)

target_include_directories(butcore PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${OPENSSL_INCLUDE_DIR}
)

target_link_libraries(butcore PUBLIC
    OpenSSL::Crypto
    OpenSSL::SSL
)

# Butcoin Node Executable
add_executable(butd src/main.cpp)
target_link_libraries(butd PRIVATE butcore)
