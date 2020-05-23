file(GLOB _files "*.gpg")
install(FILES ${_files} DESTINATION etc/apt/trusted.gpg.d)
