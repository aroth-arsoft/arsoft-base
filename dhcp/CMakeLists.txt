
install(FILES arsoft-dhcp-client-exit DESTINATION etc/dhcp/dhclient-exit-hooks.d)
install(FILES arsoft-dhcp-client-enter DESTINATION etc/dhcp/dhclient-enter-hooks.d)

install(FILES nm-dispatch DESTINATION etc/NetworkManager/dispatcher.d PERMISSIONS ${PERM_0755})



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
