install(FILES fastprotect_root_ca.pem DESTINATION ${CERTSDIR} RENAME fastprotect_root_ca.crt)
install(FILES fastprotect_ssl_ca.pem DESTINATION ${CERTSDIR} RENAME fastprotect_ssl_ca.crt)
install(FILES fastprotect_root_ca_sha256.pem DESTINATION ${CERTSDIR} RENAME fastprotect_root_ca_sha256.crt)
install(FILES fastprotect_ssl_ca_sha256.pem DESTINATION ${CERTSDIR} RENAME fastprotect_ssl_ca_sha256.crt)

