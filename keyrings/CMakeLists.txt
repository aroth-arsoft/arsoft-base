file(GLOB _files "*.gpg")
install(FILES ${_files} DESTINATION etc/apt/trusted.gpg.d)
install(FILES ${_files} DESTINATION usr/share/keyrings)
