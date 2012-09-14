all:
	valac --pkg gtk+-3.0 --pkg json-glib-1.0 --pkg libsoup-2.4 main.vala --thread --pkg gio-2.0 --pkg cairo -o colourl
