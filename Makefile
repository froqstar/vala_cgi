all: compile deploy
    
compile: index.vala
	valac --pkg gio-2.0 --pkg gee-0.8 index.vala -o index.cgi
    
deploy:
	scp -r * root@madzone.me:/data/web/blog
	
clean:
	rm -f index.cgi
