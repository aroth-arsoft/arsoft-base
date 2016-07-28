set(CERTSDIR usr/share/ca-certificates)
add_subdirectory(arsoft)
add_subdirectory(fastprotect)

install_script_files(nss-import-cert)
