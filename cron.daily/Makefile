
.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/etc/cron.daily
	install -m 0755 -o root -g root arsoft-base-repos $(DESTDIR)/etc/cron.daily/arsoft-base-repos
	install -m 0755 -o root -g root clean-old-bootcharts $(DESTDIR)/etc/cron.daily/clean-old-bootcharts
