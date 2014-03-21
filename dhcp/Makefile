DHCP_EXIT_HOOKS := apt \
		cups \
		heimdal \
		ldap \
		postfix \
		puppet \
		network \
		ntp \
		timezone

DHCP_ENTER_HOOKS := 

.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/usr/lib/arsoft-dhcp/dhclient-exit
	mkdir -p $(DESTDIR)/usr/lib/arsoft-dhcp/dhclient-enter
	install -m 0755 -o root -g root ${DHCP_EXIT_HOOKS} $(DESTDIR)/usr/lib/arsoft-dhcp/dhclient-exit
	#install -m 0755 -o root -g root ${DHCP_ENTER_HOOKS} $(DESTDIR)/usr/lib/arsoft-dhcp/dhclient-enter
	install -m 0755 -o root -g root master-script $(DESTDIR)/usr/lib/arsoft-dhcp/dhclient-master-script
	[ -f dhclient-script.$(TARGET_DISTRIBUTION) ] && install -m 0755 -o root -g root dhclient-script.$(TARGET_DISTRIBUTION) $(DESTDIR)/usr/lib/arsoft-dhcp/dhclient-script || true
	[ ! -f dhclient-script.$(TARGET_DISTRIBUTION) ] && install -m 0755 -o root -g root dhclient-script.quantal $(DESTDIR)/usr/lib/arsoft-dhcp/dhclient-script || true

	install -m 0644 default $(DESTDIR)/etc/default/arsoft-dhcp-client

	mkdir -p $(DESTDIR)/etc/dhcp/dhclient-exit-hooks.d
	mkdir -p $(DESTDIR)/etc/dhcp/dhclient-enter-hooks.d
	install -m 0644 arsoft-dhcp-client-exit $(DESTDIR)/etc/dhcp/dhclient-exit-hooks.d/arsoft-dhcp-client-exit
	install -m 0644 arsoft-dhcp-client-enter $(DESTDIR)/etc/dhcp/dhclient-enter-hooks.d/arsoft-dhcp-client-enter
	
	mkdir -p $(DESTDIR)/etc/NetworkManager/dispatcher.d
	install -m 0755 -o root -g root nm-dispatch $(DESTDIR)/etc/NetworkManager/dispatcher.d/20arsoft-nm-dispatch
