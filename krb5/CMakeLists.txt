find_package(Krb5)
include_directories( ${KRB5_INCLUDE_DIRS} )

find_package( Boost 1.40 COMPONENTS program_options filesystem system regex REQUIRED )
include_directories( ${Boost_INCLUDE_DIR} )

#indicate the entry point for the executable
add_executable (akt akt.cpp opts_helper.cpp opts_helper.h krb5_wrapper.h krb5_wrapper.cpp)

# Indicate which libraries to include during the link process.
target_link_libraries (akt krb5)
target_link_libraries( akt ${Boost_LIBRARIES} ${KRB5_LIBRARIES} )

install (TARGETS akt DESTINATION usr/bin)
