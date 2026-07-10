cmake_minimum_required(VERSION 3.16)
project(but-ai VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenSSL REQUIRED)

add_library(butai STATIC
    src/ais_main.cpp
)

target_include_directories(butai PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${OPENSSL_INCLUDE_DIR}
)

target_link_libraries(butai PUBLIC
    OpenSSL::Crypto
)

add_executable(but-ai src/ais_main.cpp)
target_link_libraries(but-ai PRIVATE butai)
