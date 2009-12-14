Basepath
========

Do you feel pain every time you have to dick around with relative paths?

    $: << File.dirname(__FILE__) + "/lib"
    require Pathname.new(__FILE__).dirname.join('../foo/bar').to_s

Oh, you don't. Ok then. You're done reading.


Usage
-----

Add an empty `.base` file to the root of your project.

When you `require 'basepath'`, it'll set `BASE_PATH` to a `Pathname` object
with the absolute path of the directory containing `.base`.


Bonus
-----

You can use the `.base` file to:

  * add paths to `$LOAD_PATH`,
  * add a default list of files to be required,
  * initialize other `Pathname` constants.

Paths are specified relative to `BASE_PATH`.


Example
-------

A fully specified `.base` file:

    [load_paths]
    vendor/*/lib
    lib

    [requires]
    yaml
    active_support

    [consts]
    EXAMPLES_PATH = etc/examples


Copyright
---------

Copyright © 2009 Caio Chassot. See LICENSE for details.
