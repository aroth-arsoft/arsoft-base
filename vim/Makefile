.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/usr/share/arsoft-base/vim
	install -m 0644 -o root -g root vimrc $(DESTDIR)/usr/share/arsoft-base/vim/vimrc
	mkdir -p $(DESTDIR)/etc/vim
	ln -s /usr/share/arsoft-base/vim/vimrc $(DESTDIR)/etc/vim/vimrc
