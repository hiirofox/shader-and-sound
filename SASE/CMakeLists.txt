cmake_minimum_required(VERSION 3.20)

project(SASE LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(SASE
    main.cpp
)

target_link_libraries(SASE PRIVATE
    d2d1
    dwrite
)
