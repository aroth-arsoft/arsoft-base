
install(FILES root_ca.pem DESTINATION ${CERTSDIR} RENAME arsoft_root_ca_1.crt)
install(FILES root_ca_com.pem DESTINATION ${CERTSDIR} RENAME arsoft_root_ca_2.crt)
install(FILES root_ca_com_1.pem DESTINATION ${CERTSDIR} RENAME arsoft_root_ca_3.crt)
install(FILES ssl_ca_com.pem DESTINATION ${CERTSDIR} RENAME arsoft_ssl_ca_1.crt)
