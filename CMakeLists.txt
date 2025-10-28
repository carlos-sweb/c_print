cmake_minimum_required(VERSION 3.15)
project(c_print VERSION 1.0.0 LANGUAGES C CXX)

# Opciones de compilación
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)


# Archivos fuente
set(SOURCES c_print.c)

set(HEADERS c_print.h )

# Librería compartida (.so en Linux, .dll en Windows)
add_library(c_print_shared SHARED ${SOURCES} ${HEADERS})
set_target_properties(c_print_shared PROPERTIES
    OUTPUT_NAME c_print
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    PUBLIC_HEADER c_print.h
)

# Librería estática (.a en Linux, .lib en Windows)
add_library(c_print_static STATIC ${SOURCES} ${HEADERS})
set_target_properties(c_print_static PROPERTIES
    OUTPUT_NAME c_print
    PUBLIC_HEADER c_print.h
)

# Opciones de compilación para warnings
if(MSVC)
    target_compile_options(c_print_shared PRIVATE /W4)
    target_compile_options(c_print_static PRIVATE /W4)
else()
    target_compile_options(c_print_shared PRIVATE -Wall -Wextra -pedantic)
    target_compile_options(c_print_static PRIVATE -Wall -Wextra -pedantic)
endif()

# Instalación
include(GNUInstallDirs)

install(TARGETS c_print_shared c_print_static
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Configurar e instalar el archivo pkg-config
configure_file(c_print.pc.in c_print.pc @ONLY)

install(
    FILES ${CMAKE_BINARY_DIR}/c_print.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

# Ejemplo de uso (opcional)
option(BUILD_EXAMPLES "Build example programs" ON)

if(BUILD_EXAMPLES)
    add_executable(example_shared test/example.c)
    target_link_libraries(example_shared c_print_shared)
    
    add_executable(example_static test/example.c)
    target_link_libraries(example_static c_print_static)
endif()

# Información de compilación
message(STATUS "C Print Library Configuration:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  Install prefix: ${CMAKE_INSTALL_PREFIX}")