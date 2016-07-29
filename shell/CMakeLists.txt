install_script_files(
    cp_p
)

install(FILES bash.bashrc DESTINATION usr/share/arsoft-base/bash/bash.bashrc)
install(FILES profile DESTINATION usr/share/arsoft-base/profile)

install_mkdir(etc/arsoft-base/system-startup.d)
install_mkdir(etc/arsoft-base/system-shutdown.d)
