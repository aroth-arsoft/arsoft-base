#find_package(krb5)

find_package( Boost 1.40 COMPONENTS program_options filesystem system regex REQUIRED )
include_directories( ${Boost_INCLUDE_DIR} )

#indicate the entry point for the executable
add_executable (akt akt.cpp opts_helper.cpp opts_helper.h)

# Indicate which libraries to include during the link process.
target_link_libraries (akt krb5)
target_link_libraries( akt ${Boost_LIBRARIES} )

install (TARGETS akt DESTINATION usr/bin)
