WORKING_DIR=_deb

deb_dir: git-* debian.control
	mkdir -p "$(WORKING_DIR)"/DEBIAN
	cp debian.control "$(WORKING_DIR)"/DEBIAN/control
	mkdir -p "$(WORKING_DIR)"/usr/bin/
	cp git-* "$(WORKING_DIR)"/usr/bin/

deb: deb_dir
	dpkg-deb --build "$(WORKING_DIR)" package.deb

clean:
	rm -r "$(WORKING_DIR)" package.deb

install: 
	sudo dpkg -i package.deb
