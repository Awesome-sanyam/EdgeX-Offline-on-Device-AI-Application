cmake_minimum_required(VERSION 3.22.1)
project(core_ai_engine)

# Add our source files
add_library(
    core_ai_engine
    SHARED
    core_ai_engine.cpp
)

# Link Android standard libraries (log for debugging, android for native APIs)
target_link_libraries(
    core_ai_engine
    log
    android
)