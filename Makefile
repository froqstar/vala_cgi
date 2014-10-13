all: compile deploy
    
compile: index.vala
	valac --pkg gio-2.0 --pkg gee-0.8 index.vala -o index.cgi
    
deploy:
	cp index.cgi /var/www/lighttpd/cgi-bin/
	cp -r posts /var/www/lighttpd/cgi-bin/
	cp -r static /var/www/lighttpd/cgi-bin/
	
clean:
	rm -f index.cgi
