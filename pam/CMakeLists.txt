
if(TARGET_DISTRIBUTION MATCHES "trusty" OR TARGET_DISTRIBUTION MATCHES "precise")
    install(FILES mkhomedir DESTINATION usr/share/pam-configs/mkhomedir)
endif()
