cmake_minimum_required (VERSION 2.8)
project (CMakeHelloWorld)

#find_package(krb5)

#indicate the entry point for the executable
add_executable (akt akt.cpp)

# Indicate which libraries to include during the link process.
target_link_libraries (akt krb5)

install (TARGETS akt DESTINATION bin)
