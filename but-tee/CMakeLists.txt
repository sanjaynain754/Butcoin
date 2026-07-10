cmake_minimum_required(VERSION 3.16)
project(but-tee VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenSSL REQUIRED)

add_library(buttee STATIC
    src/tex_main.cpp
)

target_include_directories(buttee PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${OPENSSL_INCLUDE_DIR}
)

target_link_libraries(buttee PUBLIC
    OpenSSL::Crypto
)

add_executable(but-tee src/tex_main.cpp)
target_link_libraries(but-tee PRIVATE buttee)
