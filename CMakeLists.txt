cmake_minimum_required (VERSION 2.8)
project (arsoft-base C CXX)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

EXECUTE_PROCESS(COMMAND lsb_release -cs
                OUTPUT_VARIABLE _lsb_codename
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET)

if(NOT TARGET_DISTRIBUTION)
    set(TARGET_DISTRIBUTION ${_lsb_codename})
endif()

if(NOT TARGET_VERSION)
    # Get the current working branch
    execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Get the latest abbreviated commit hash of the working branch
    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(TARGET_VERSION "git-${GIT_BRANCH}-${GIT_COMMIT_HASH}")
endif()

add_definitions(-DTARGET_VERSION=\"${TARGET_VERSION}\" -DTARGET_DISTRIBUTION=\"${TARGET_DISTRIBUTION}\")
set(CMAKE_INSTALL_PREFIX "")

message(STATUS "Target distribution: ${TARGET_DISTRIBUTION}")
message(STATUS "Target version: ${TARGET_VERSION}")

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

macro(install_symlink src dest)
    install(CODE "execute_process(COMMAND \${CMAKE_COMMAND} -E create_symlink \"${src}\" \"\${CMAKE_INSTALL_PREFIX}/${dest}\")")
endmacro(install_symlink)


add_subdirectory(apt)
add_subdirectory(bind)
add_subdirectory(cert)
add_subdirectory(cron.daily)
add_subdirectory(cyrusimapd)
add_subdirectory(desktop)
add_subdirectory(dhcp)
add_subdirectory(devel)
add_subdirectory(docker)
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

