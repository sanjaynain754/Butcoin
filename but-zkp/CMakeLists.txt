cmake_minimum_required(VERSION 3.16)
project(but-zkp VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenSSL REQUIRED)

add_library(butzkp STATIC
    src/zkf_main.cpp
)

target_include_directories(butzkp PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${OPENSSL_INCLUDE_DIR}
)

target_link_libraries(butzkp PUBLIC
    OpenSSL::Crypto
)

add_executable(but-zkp src/zkf_main.cpp)
target_link_libraries(but-zkp PRIVATE butzkp)
