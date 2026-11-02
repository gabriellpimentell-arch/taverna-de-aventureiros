cmake_minimum_required(VERSION 3.20)
project(TavernaDeAventureiros C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# No Windows, embute o runtime do Visual C++ no .exe (não precisa instalar nada)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

include(FetchContent)

# --- raylib: janela, desenho, entrada e som ----------------------------------
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_GAMES OFF CACHE BOOL "" FORCE)
FetchContent_Declare(raylib
  GIT_REPOSITORY https://github.com/raysan5/raylib.git
  GIT_TAG 5.5
  GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(raylib)

# --- Lua: linguagem dos scripts do jogo --------------------------------------
FetchContent_Declare(lua
  GIT_REPOSITORY https://github.com/lua/lua.git
  GIT_TAG v5.4.7
  GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(lua)

file(GLOB LUA_FONTES ${lua_SOURCE_DIR}/*.c)
list(FILTER LUA_FONTES EXCLUDE REGEX ".*/(lua|luac|onelua|ltests)\\.c$")
add_library(lua_estatica STATIC ${LUA_FONTES})
target_include_directories(lua_estatica PUBLIC ${lua_SOURCE_DIR})
if(UNIX)
  target_compile_definitions(lua_estatica PRIVATE LUA_USE_POSIX)
endif()

# --- O jogo ------------------------------------------------------------------
add_executable(TavernaDeAventureiros src/main.cpp)
target_link_libraries(TavernaDeAventureiros PRIVATE raylib lua_estatica)

if(MSVC)
  # abre só a janela do jogo, sem a janela preta do console
  set_target_properties(TavernaDeAventureiros PROPERTIES
    LINK_FLAGS "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup")
  target_compile_options(TavernaDeAventureiros PRIVATE /utf-8)
endif()

# copia scripts e fontes para perto do executável
add_custom_command(TARGET TavernaDeAventureiros POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/scripts $<TARGET_FILE_DIR:TavernaDeAventureiros>/scripts
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/assets $<TARGET_FILE_DIR:TavernaDeAventureiros>/assets)
