install_script_files(
    pbuildmgr
)


file(GLOB _files "hook/A*" "hook/B*" "hook/C*" "hook/D*" "hook/G*")
install(FILES ${_files} DESTINATION etc/arsoft/pbuilder/hook.d PERMISSIONS ${PERM_0755})
