This is a lightly modified version of the VIM plugin 'minpac' 
located at: https://github.com/k-takata/minpac


This version lets plugins be installed into different package names.


The changes in the actual code are few. However, so that I could
understand the workflow, I significantly restructured the code.
The existing structure was absolutly fine; but the fastest way I
coud understand it was to retype it.


Some of the cosmetic or minor changes included:

* Reordered the functions
* Moved some functions from the plugin file to the autoload file.
* Renamed private functions so that they are private, and not autoloaded.
* Added some comments and folding
* Split up the tests into separate files. Added new ones.
  


I changed the names of all functions from 'minpac' to autopac because:

* it kept me from accidently modifying the original "minpac" code when 
  I thought I was modifying my version of it.
* it prevents me from deleting the repo and expecting to be able to duplicate from 
  the original version at github.



This is for my personal use only.
