install_script_files(
    cp_p
)

install(FILES bash.bashrc DESTINATION usr/share/arsoft-base/bash)
install(FILES profile DESTINATION usr/share/arsoft-base)

install_mkdir(etc/arsoft-base/system-startup.d)
install_mkdir(etc/arsoft-base/system-shutdown.d)

# The symlink need to be created by using dpkg-divert and this is done
# in the arsoft-base.postinst
#install_symlink(usr/share/arsoft-base/bash/bash.bashrc etc/bash.bashrc)
#install_symlink(usr/share/arsoft-base/profile etc/profile)
