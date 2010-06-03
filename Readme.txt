Kyle's Adjacency -> Nested Sets Translator

Copyright 2007 Kyle Cordes

This class converts an "Adjacency" hierarchy representation in to a
"nested set" representation.  Search the web for Joe Celko's nested set
articles to learn what that means.

This assumes that nodes are identified by ints. You could change it to use
strings etc. as needed, of course.

To use this class:

  * create an instance. instances are single-shot, one use.

  * call "AddNode" 0..N times, once for each node.

  * call Convert.  The processing will occur, and your handler
    will be called once for each node, with the Left and Right values.


Enjoy. I'd love to hear if anyone finds this useful.

kyle@kylecordes.com
http://kylecordes.com/

