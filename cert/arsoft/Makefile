#
# Makefile
#

all:

clean:
	-rm -f *.crt

install:
	cat *.pem > tmp_combined.crt
	install -m 644 tmp_combined.crt $(CERTSDIR)/arsoft_root.crt
