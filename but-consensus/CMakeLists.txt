cmake_minimum_required(VERSION 3.16)
project(but-consensus VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenSSL REQUIRED)

add_library(butconsensus STATIC
    src/poc.hpp
    src/validator.hpp
)

target_include_directories(butconsensus PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${OPENSSL_INCLUDE_DIR}
)

target_link_libraries(butconsensus PUBLIC
    OpenSSL::Crypto
)

add_executable(but-consensus src/main.cpp)
target_link_libraries(but-consensus PRIVATE butconsensus)
