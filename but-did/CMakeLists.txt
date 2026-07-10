cmake_minimum_required(VERSION 3.16)
project(but-did VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenSSL REQUIRED)

add_library(butdid STATIC
    src/did_main.cpp
)

target_include_directories(butdid PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${OPENSSL_INCLUDE_DIR}
)

target_link_libraries(butdid PUBLIC
    OpenSSL::Crypto
)

add_executable(but-did src/did_main.cpp)
target_link_libraries(but-did PRIVATE butdid)
