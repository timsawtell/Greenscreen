Greenscreen
===========

A project based off Erik M. Buck's code, available from http://www.informit.com/articles/article.aspx?p=1946398.

All credit goes to this guy, I just tweaked the code so that I can run it on a retina iPad.

Changes I have made:
Remove a lot of code that was unreachable.
Made the vertex shader more discerning re: green color. i.e. the pixel has to be more green than before to become transparent. Stops things like yellow being semi transparent.
Added support for retina devices.

![Example](http://i.imgur.com/3xwqJ.png "Example of the greenscreen in action")

