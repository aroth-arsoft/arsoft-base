cmake_minimum_required (VERSION 2.8)
project (arsoft-base C CXX)

EXECUTE_PROCESS(COMMAND lsb_release -cs
                OUTPUT_VARIABLE _lsb_codename
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET)

if(NOT TARGET_DISTRIBUTION)
    set(TARGET_DISTRIBUTION ${_lsb_codename})
endif()

set(CMAKE_INSTALL_PREFIX "")

message(STATUS "Target distribution: ${TARGET_DISTRIBUTION}")

set(PERM_0755 OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

macro(install_script_files)

    install(
        FILES
            ${ARGN}
        DESTINATION
            usr/bin
        PERMISSIONS
            ${PERM_0755}
           )
endmacro(install_script_files)

macro(install_mkdir)
    foreach(arg ${ARGN})
        install(CODE "file(INSTALL DESTINATION \"\${CMAKE_INSTALL_PREFIX}/${arg}\" TYPE FILE)")
    endforeach()
endmacro(install_mkdir)


add_subdirectory(apt)
add_subdirectory(bind)
add_subdirectory(cert)
add_subdirectory(cron.daily)
add_subdirectory(cyrusimapd)
add_subdirectory(desktop)
add_subdirectory(dhcp)
add_subdirectory(devel)
add_subdirectory(keyrings)
add_subdirectory(krb5)
add_subdirectory(ldap)
add_subdirectory(nagios)
add_subdirectory(network)
add_subdirectory(nfs)
add_subdirectory(openvpn)
add_subdirectory(pam)
add_subdirectory(pbuilder)
add_subdirectory(pnp4nagios)
add_subdirectory(postfix)
add_subdirectory(puppet)
add_subdirectory(shell)
add_subdirectory(spamassassin)
add_subdirectory(ssh)
add_subdirectory(scm)
add_subdirectory(sysinfo)
add_subdirectory(tftp)
add_subdirectory(wine)

