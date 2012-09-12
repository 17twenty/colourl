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


using GLib;
using Gtk;
using Gdk;
using Soup;
using Cairo;

// The ColourLOVER class is designed to take a given image URL
// 
public class ColourLOVER : Object
{
        public ColourLOVER()
        {
        }
}

public class Main : Object
{
        private Gtk.Window m_window;
        private Image m_image;
        private Gtk.Notebook m_notebook;
        private Gtk.ScrolledWindow m_scroll_new;
        private Gtk.Spinner m_spinner;
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
                } catch (Error e) {
                    stderr.printf("Could not load application icon: %s\n", e.message);
                }
		
		// Setup our spinner
		//m_spinner = new Gtk.Spinner();
		//m_spinner.start();
		
		// Get some tabs in this mofo
		m_notebook = new Gtk.Notebook();
		var popular_label = new Gtk.Label("Popular");
		var new_label = new Gtk.Label("New");
		var fave_label = new Gtk.Label("Favourites");
		
		var blank_1 = new Gtk.Label("Nothing to see here :(");
		var blank_2 = new Gtk.Label("Nothing to see here :(");
		
		// Create the scrollable new page
		m_scroll_new = new Gtk.ScrolledWindow(null, null);
		
		var box = new Box(Orientation.VERTICAL, 5);
		m_image = new Image();
		
		// This is what our widget should consist of...
		var grid = new Grid();
		var wallpaper_label = new Button.with_label("Set as wallpaper");
		var add_fave_label = new Button.with_label("Add as favourite");
		var drawing_area = new DrawingArea();
		drawing_area.set_size_request(600, 200);
                drawing_area.draw.connect(on_draw);
                /*
                        child : the widget to add
                        left : the column number to attach the left side of child to
                        top : the row number to attach the top side of child to
                        width : the number of columns that child will span
                        height : the number of rows that child will span
                */
                grid.attach(drawing_area, 0, 0, 3, 2);
                grid.attach(wallpaper_label, 3, 0, 1, 1);
                grid.attach(add_fave_label, 3, 1, 1, 1);
                
                box.pack_start(grid, true, false, 0);
                //box.pack_start(m_image, true, true, 0);
                
                
		//var button = new Button.with_label("Open Image");
		//box.pack_start(button, true, false, 0);
		//box.pack_start(m_spinner, true, false, 0);
		m_scroll_new.add_with_viewport(box);
		
		// Sort out the notebook
	        m_notebook.append_page(m_scroll_new, new_label);
	        m_notebook.append_page(blank_1, popular_label);
	        m_notebook.append_page(blank_2, fave_label);
	        m_notebook.set_tab_pos(PositionType.LEFT);
		m_window.add(m_notebook);
		
		// Show dialog on open file
		//button.clicked.connect(on_open_image);
				
		// Launch a web request setup
		//var web_request = new Button.with_label("Do web request");
		//box.pack_start(web_request, true, false, 0);
		//web_request.clicked.connect(do_web_request);
						
		m_window.show_all();
		m_window.destroy.connect(on_destroy);
	}
	
	private Cairo.Pattern pattern;
	
	public bool on_draw(Widget da, Context ctx) {
	        stdout.printf("On_draw()\n");	        
	        var image = new Cairo.ImageSurface.from_png("stripes.png");
                var w = image.get_width();
                var h = image.get_height();
	        stdout.printf("Height: %d, Width :%d\n", h, w);
	        
	        // Get our bounds
                int width;
                int height;
                da.get_size_request(out width, out height);
	        stdout.printf("Height: %d, Width :%d\n", height, width);
                
                
                this.pattern = new Cairo.Pattern.for_surface(image);
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
                ctx.show_text("Magic Patterns");
                
                
	        ctx.set_source_rgba(0.10, 0.10, 0.10, 1.0);
	        ctx.select_font_face("Cantarell",
                                FontSlant.NORMAL,
                                FontWeight.BOLD);
                                
                ctx.set_font_size(14);
                ctx.move_to(20, height - 14);
                ctx.show_text("By The Amazing Valdini");

	        
                return true;
	}
	
	public void do_web_request(Button self) {
	        // Go do some webby stuff and print to console
                var session = new Soup.SessionAsync();
                var message = new Soup.Message("GET", "http://i.imgur.com/uvrjk.png");

                // send the HTTP request
                session.send_message(message);

                // output the XML result to stdout 
                //stdout.write(message.response_body.data);
                
                var file = File.new_for_path("out.png");
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
                        } catch (GLib.IOError e) {
                                GLib.warning("%s\n", e.message);
                        }
                } catch (GLib.Error e) {
                        GLib.warning("%s\n", e.message);
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


	public void on_destroy (Widget window)
	{
		Gtk.main_quit();
	}

	static int main (string[] args)
	{
		Gtk.init (ref args);
		var app = new Main();

		Gtk.main ();

		return 0;
	}
}
