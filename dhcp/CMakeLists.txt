
install(FILES arsoft-dhcp-client-exit DESTINATION etc/dhcp/dhclient-exit-hooks.d)
install(FILES arsoft-dhcp-client-enter DESTINATION etc/dhcp/dhclient-enter-hooks.d)
install(FILES default DESTINATION etc/default/arsoft-dhcp-client)

install(FILES nm-dispatch DESTINATION etc/NetworkManager/dispatcher.d RENAME 20arsoft-nm-dispatch PERMISSIONS ${PERM_0755})

#install(CODE "file(MAKE_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}/usr/lib/arsoft-dhcp/dhclient-enter\")")
#install(CODE "file(MAKE_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}/usr/lib/arsoft-dhcp/dhclient-exit\")")

install_mkdir(usr/lib/arsoft-dhcp/dhclient-exit)
install_mkdir(usr/lib/arsoft-dhcp/dhclient-enter)


file(GLOB _files "exit.d/*")
install(FILES ${_files} DESTINATION usr/lib/arsoft-dhcp/dhclient-exit PERMISSIONS ${PERM_0755})

#file(GLOB _files "enter.d/*")
#install(FILES ${_files} DESTINATION usr/lib/arsoft-dhcp/dhclient-enter PERMISSIONS ${PERM_0755})

install(FILES master-script DESTINATION usr/lib/arsoft-dhcp RENAME dhclient-master-script PERMISSIONS ${PERM_0755})
if(EXISTS dhclient-script.${TARGET_DISTRIBUTION})
    set(_files dhclient-script.${TARGET_DISTRIBUTION})
else()
    set(_files dhclient-script.saucy)
endif()
install(FILES master-script DESTINATION usr/lib/arsoft-dhcp RENAME dhclient-script PERMISSIONS ${PERM_0755})
