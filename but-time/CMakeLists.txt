cmake_minimum_required(VERSION 3.16)
project(but-time VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenSSL REQUIRED)

add_library(buttime STATIC
    src/tlk_main.cpp
)

target_include_directories(buttime PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${OPENSSL_INCLUDE_DIR}
)

target_link_libraries(buttime PUBLIC
    OpenSSL::Crypto
)

add_executable(but-time src/tlk_main.cpp)
target_link_libraries(but-time PRIVATE buttime)
