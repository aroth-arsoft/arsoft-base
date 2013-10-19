.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/etc/pnp4nagios/check_commands
	mkdir -p $(DESTDIR)/etc/pnp4nagios/templates
	install -m 0644 -o root -g root check_commands/*.cfg $(DESTDIR)/etc/pnp4nagios/check_commands
	install -m 0644 -o root -g root templates/*.php $(DESTDIR)/etc/pnp4nagios/templates
