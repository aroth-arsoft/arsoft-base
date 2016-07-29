set(_subdirs arsoft fastprotect)
foreach(d ${_subdirs})
    set(CERTSDIR usr/share/ca-certificates/${d})
    add_subdirectory(${d})
endforeach()

install_script_files(nss-import-cert)
