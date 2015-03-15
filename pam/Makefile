.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/usr/share/pam-configs
ifeq ($(TARGET_DISTRIBUTION),trusty)
	install -m 0644 -o root -g root mkhomedir $(DESTDIR)/usr/share/pam-configs/mkhomedir
endif
ifeq ($(TARGET_DISTRIBUTION),precise)
	install -m 0644 -o root -g root mkhomedir $(DESTDIR)/usr/share/pam-configs/mkhomedir
endif
