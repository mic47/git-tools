WORKING_DIR=_deb

deb_dir: git-* debian.control
	mkdir -p "$(WORKING_DIR)"/DEBIAN
	cp debian.control "$(WORKING_DIR)"/DEBIAN/control
	mkdir -p "$(WORKING_DIR)"/usr/bin/
	cp git-* "$(WORKING_DIR)"/usr/bin/
	curl https://raw.githubusercontent.com/git/git/master/contrib/workdir/git-new-workdir > "$(WORKING_DIR)"/usr/bin/git-new-workdir

deb: deb_dir
	dpkg-deb --build "$(WORKING_DIR)" package.deb

clean:
	rm -r "$(WORKING_DIR)" package.deb

install: deb
	sudo dpkg -i package.deb

install-local: git-*
	ls git* | parallel ln -s $(shell pwd)/{} ~/.local/bin/{}
