This is a lightly modified version of the VIM plugin ['minpac'](https://github.com/k-takata/minpac).


### Reason for modifications

This version lets plugins be installed into different package names.
Also provides a way to handle dependencies between plugins when 
using 'packadd'

### Types of Changes

The changes in the actual code are few. However, so that I could
understand the workflow, I significantly restructured the code.

Some of the cosmetic or minor changes:

* Reordered the functions
* Moved some functions from the plugin file to the autoload file.
* Renamed private functions so that they are private, and not autoloaded.
* Added some comments and folding
* Split up the tests into separate files. Added new ones.

A major structural change is that I changed the names of all functions from 'minpac' to autopac because:

* It kept me from accidentally modifying the original "minpac" code when I thought I was modifying my version of it.
* It prevents me from deleting my repo and still expecting to be able to duplicate it from the original version at github.

### Example
See [example](example/myplugins.vim) for an annotated example.

### Credit
Thanks to [k-takata](https://github.com/k-takata) for an excellent plugin.
