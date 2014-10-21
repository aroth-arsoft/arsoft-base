.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/usr/share/pam-configs
ifneq ($(TARGET_DISTRIBUTION),utopic)
	install -m 0644 -o root -g root mkhomedir $(DESTDIR)/usr/share/pam-configs/mkhomedir
endif
