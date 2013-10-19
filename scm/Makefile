SCM_BIN_SCRIPTS := mimediff \
		oodiff \
		zipdiff \
		imagediff \
		svn2git \
		git-deep-clone \
		git-info \
		git-shrink \
		git-subdir2submodule

.PHONY: all

all:

clean:

install:
	install -m 0755 -o root -g root ${SCM_BIN_SCRIPTS} $(DESTDIR)/usr/bin
