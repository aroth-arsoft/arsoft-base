#indicate the entry point for the executable
add_executable (trac-admin-suid trac-admin-suid.c)

install (TARGETS trac-admin-suid DESTINATION usr/lib/arsoft-python)
