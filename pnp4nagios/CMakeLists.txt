
file(GLOB _files "check_commands/*.cfg")
install(FILES ${_files} DESTINATION etc/pnp4nagios/check_commands)


file(GLOB _files "templates/*.php")
install(FILES ${_files} DESTINATION etc/pnp4nagios/templates)
