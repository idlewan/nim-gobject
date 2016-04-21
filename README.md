nim-gobject
===========

Nim glib/gobject wrapper

Automatically generated from latest stable header files of glib 2.48.0

Generally glib/gobject is not used from Nim directly, but it is,
together with GIO, Cairo and Pango the foundation for GDK3 and GTK3.

To generate the wrapper files: cd into gen directory, make sure path
to glib source directory containing C header files is correct in
file prep-gobj.sh. Then execute command "bash prep-gobj.sh".
This script executes a few tiny Ruby scripts, so you should ensure
that Ruby is installed on your computer. (Perl also.)

Script does work with c2nim 0.9.8

