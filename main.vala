// Colourl is a simple app to retrieve nice patterns from ColorLOVERS
// Copyright (C) 2012 Nick Glynn <exosyst@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//  
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Useful information - if it crashes, try and debug with:
// G_DEBUG=fatal_warnings gdb ./colourl


using GLib;
using Gtk;
using Gdk;
using Soup;
using Cairo;

// The ColourLOVER class is designed to take a given image URL
// and add it to a given box
// 
public class ColourLOVER : GLib.Object
{
        private DrawingArea m_area;
        private string m_title;
        private string m_imageURL;
        private string m_id;
        private string m_author;
        private Gtk.Grid m_grid  = new Grid();
        
        public ColourLOVER(Gtk.Box box, string id, string web_address, 
                           string title, string author) {
                m_title = title;
                m_id = id;
                m_imageURL = web_address;
                m_author = author;
                
                var temp_spinner = new Gtk.Spinner();
                var temp_label = new Gtk.Label("Fetching Colours...");
                box.pack_start(temp_label, true, false, 0);
                box.pack_start(temp_spinner, true, false, 0);
                temp_spinner.start();
                temp_label.show_now();
                temp_spinner.show_now();

                // Fetch the image and get the icon
                string result_string = get_image(m_imageURL);
                if (result_string.length > 0) {
                        stdout.printf("Got image %s\n", result_string);
                        // This is what our widget should consist of...
	                m_grid = new Grid();
	                var wallpaper_label = new Button.with_label("Set as wallpaper");
	                var add_fave_label = new Button.with_label("Add as favourite");
	                
	                wallpaper_label.clicked.connect(set_wallpaper);
	                
	                m_texture = new Cairo.ImageSurface.from_png(result_string);
	                m_area = new DrawingArea();
	                m_area.set_size_request(600, 200);
                        m_area.draw.connect(on_draw);
                        m_area.queue_draw();

                        /*
                                child : the widget to add
                                left : the column number to attach the left side of child to
                                top : the row number to attach the top side of child to
                                width : the number of columns that child will span
                                height : the number of rows that child will span
                        */
                        m_grid.attach(m_area, 0, 0, 3, 2);
                        m_grid.attach(wallpaper_label, 3, 0, 1, 1);
                        m_grid.attach(add_fave_label, 3, 1, 1, 1);
                        
                        box.pack_start(m_grid, true, false, 0);
                }
                box.remove(temp_spinner);
        }
        
        private void set_wallpaper() {
                // Gleaned from #$ gsettings list-recursively org.gnome.desktop.background
                var settings = new GLib.Settings("org.gnome.desktop.background");
                string wallpaper_location = "file://" + Environment.get_current_dir() + "/" + m_id + ".png";
                stdout.printf("Location %s\n", wallpaper_location);
                settings.set_string("picture-uri", wallpaper_location);
                settings.set_string("picture-options", "tile"); // Tile
        }
        
        
        private Cairo.ImageSurface m_texture = null;
        
        private string get_image(string image_address) {
                // Go do some webby stuff and print to console
                string cached_image = "";
                string image_name_to_try = m_id + ".png";
                var session = new Soup.SessionAsync();
                
                // We're going to use JSON as libxml2 sucks
                var message = new Soup.Message("GET", image_address);

                // send the HTTP request
                session.send_message(message);

                var file = File.new_for_path(image_name_to_try);
                if (file.query_exists()) {
                       try {
                                file.delete();
                        } catch (GLib.Error e) {
                                GLib.warning("%s\n", e.message);
                        }
                }
                try {
                        var data_stream = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));
                        // Set byte order? data_stream.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);
                        try {
                                data_stream.write(message.response_body.data);
                                cached_image = image_name_to_try;
                                
                        } catch (GLib.IOError e) {
                                GLib.warning("%s\n", e.message);
                        }
                } catch (GLib.Error e) {
                        GLib.warning("%s\n", e.message);
                }
                return cached_image;
        }
        
        private Cairo.Pattern pattern;
	
	public bool on_draw(Widget da, Context ctx) {
	        if (m_texture == null)
	                return true;
	                
	        stdout.printf("On_draw()\n");    
                var w = m_texture.get_width();
                var h = m_texture.get_height();
	        stdout.printf("Height: %d, Width :%d\n", h, w);
	        
	        // Get our bounds
                int width;
                int height;
                da.get_size_request(out width, out height);
	        stdout.printf("Height: %d, Width :%d\n", height, width);
                
                
                this.pattern = new Cairo.Pattern.for_surface(m_texture);
                this.pattern.set_extend(Cairo.Extend.REPEAT);
                ctx.set_source(this.pattern);
	        ctx.rectangle(0, 0, width, height);
	        ctx.fill();
	        ctx.stroke();
                
                // Draw a translucent window
	        ctx.set_source_rgba(0.80, 0.8, 0.82, 0.7);
	        ctx.rectangle(0, height * 0.6, width, height * 0.4);
	        ctx.fill();
	        ctx.stroke();
	        
	        // Draw title and author
	        ctx.set_source_rgba(0, 0, 0, 1.0);
	        ctx.select_font_face("Cantarell",
                                FontSlant.NORMAL,
                                FontWeight.NORMAL);

                ctx.set_font_size(22);

                ctx.move_to(20, height - 40);
                ctx.show_text(m_title);
                
                
	        ctx.set_source_rgba(0.10, 0.10, 0.10, 1.0);
	        ctx.select_font_face("Cantarell",
                                FontSlant.NORMAL,
                                FontWeight.BOLD);
                                
                ctx.set_font_size(14);
                ctx.move_to(20, height - 14);
                ctx.show_text(m_author);

	        
                return true;
	}
}

public class Main : GLib.Object
{
        private Gtk.Window m_window;
        private Image m_image;
        private Gtk.Notebook m_notebook;
        private Gtk.ScrolledWindow m_scroll_new;
        private Gtk.Box m_the_box = new Box(Orientation.VERTICAL, 5);
        private ColourLOVER[] m_loverlist = new ColourLOVER[30];
        
	public Main ()
	{
		m_window = new Gtk.Window();
		m_window.set_title ("Colourl");
		m_window.set_size_request(800, 600);
		
		// Try and get our app icon
		try {
                    // Either directly from a file ...
                    m_window.icon = new Pixbuf.from_file ("colourl.png");
                    // ... or from the theme
                    m_window.icon = IconTheme.get_default().load_icon ("colourl", 48, 0);
                } catch (GLib.Error e) {
                    stderr.printf("Could not load application icon: %s\n", e.message);
                }
		
		// Get some tabs in this mofo
		m_notebook = new Gtk.Notebook();
		var popular_label = new Gtk.Label("Popular");
		var new_label = new Gtk.Label("New");
		var fave_label = new Gtk.Label("Favourites");
		
		var blank_1 = new Gtk.Label("Nothing to see here :(");
		var blank_2 = new Gtk.Label("Nothing to see here :(");
		
		// Create the scrollable new page
		m_scroll_new = new Gtk.ScrolledWindow(null, null);
		
                /* 
                // Gleaned from #$ gsettings list-recursively org.gnome.desktop.background
                var settings = new GLib.Settings("org.gnome.desktop.background");
                var greeting = settings.get_string("picture-uri");
                var thi = settings.get_string("picture-options"); // Tile
                var foo = Environment.get_current_dir();
                stdout.printf("Wallpaper %s\n", greeting);
                stdout.printf("Setting %s\n", thi);
                stdout.printf("PWD %s\n", foo);
                */
                
		m_scroll_new.add_with_viewport(m_the_box);
		
		// Sort out the notebook
	        m_notebook.append_page(m_scroll_new, new_label);
	        m_notebook.append_page(blank_1, popular_label);
	        m_notebook.append_page(blank_2, fave_label);
	        m_notebook.set_tab_pos(PositionType.LEFT);
		m_window.add(m_notebook);
		
		// Show dialog on open file
		//button.clicked.connect(on_open_image);
				
		// Launch a web request setup
		/* var web_request = new Button.with_label("Do web request");
		m_the_box.pack_start(web_request, true, false, 0);
		web_request.clicked.connect(do_web_request);
		
		// Launch a color adder
		var add_colour = new Button.with_label("Add color");
		m_the_box.pack_start(add_colour, true, false, 0);
		add_colour.clicked.connect(add_lover);
		*/
		
						
		m_window.show_all();
		m_window.destroy.connect(on_destroy);
		do_web_request();
	}
		
	public void do_web_request_click(Button self) {
                do_web_request();
        }
	
	public void do_web_request() {
	        // Go do some webby stuff and print to console
                var session = new Soup.SessionAsync();
                
                // We're going to use JSON as libxml2 sucks
                var message = new Soup.Message("GET", "http://www.colourlovers.com/api/patterns/top?format=json");

                // send the HTTP request
                session.send_message(message);

                // output the JSON result to stdout 
                //stdout.write(message.response_body.data);
                
                try {
                        var parser = new Json.Parser();
                        parser.load_from_data((string)message.response_body.flatten().data, -1);

                        Json.Array elements = parser.get_root().get_array();
                        int counter = 0;
                        elements.foreach_element ((array, index, node) => {
                                Json.Object obj = node.get_object ();
                                string id = "%d".printf((int)obj.get_int_member("id"));
                                string title = obj.get_string_member ("title");
                                string imageURL = obj.get_string_member ("imageUrl");
                                string author = obj.get_string_member ("userName");
                                
                                stdout.printf("ID %s\n Title %s\n imageURL %s\n author%s\n----------------\n", id, title, imageURL, author);
                                
                                // Try it!
                                m_loverlist[counter++] = new ColourLOVER(m_the_box, id,
		                                                         imageURL, 
		                                                         title, author);
                        });
                        // Show the widgets - urk!
                    
	                m_window.show_all();
                } catch (GLib.Error e) {
                        stderr.printf("Nope. No idea what happened to that request\n");
                }
	}
	
	public void on_open_image(Button self) {
	        var filter = new FileFilter();
	        var dialog = new FileChooserDialog("Open Image",
	                                           m_window,
	                                           FileChooserAction.OPEN,
	                                           Stock.OK,    ResponseType.ACCEPT,
	                                           Stock.CANCEL, ResponseType.CANCEL);
                filter.add_pixbuf_formats();
                dialog.add_filter(filter);
               
                // Get image from file
                
                switch(dialog.run()) {
                        case ResponseType.ACCEPT:
                                var filename = dialog.get_filename();
                                try {
                                        // Scale the image
                                        var pb = new Pixbuf.from_file(filename);
                                        m_image.set_from_pixbuf(pb);
                                } catch (GLib.Error e) {
                                        GLib.warning("%s: %s\n", e.message, filename);
                                }
                                break;
                        default:
                                break;
                }
                dialog.destroy();
        }


	public void on_destroy (Widget window) {
		Gtk.main_quit();
	}
	
	public void nowarn() {
	        return;
        }

	static int main (string[] args)
	{
		Gtk.init (ref args);
		var app = new Main();
		
		app.nowarn();

		Gtk.main ();

		return 0;
	}
}
