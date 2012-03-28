SGA Shared Canvas
=================

**SGA Shared Canvas** is a shared canvas reader written in CoffeeScript.

What you need to use SGA Shared Canvas
--------------------------------------

SGA Shared Canvas depends on jQuery, Raphaël, and MITHGrid.

The following libraries and versions are included in the lib/ directory.
These are the version with which SGA Shared Canvas is developed. This may
change as new capabilities are added to the library.

* jQuery 1.6.1
* Raphaël 1.5.2
* MITHGrid current pre-release

What you need to build your own SGA Shared Canvas
-------------------------------------------------

In order to build SGA Shared Canvas, you need to have GNU made 3.81 or later, CoffeeScript 1.1.1
or later, Node.js 0.5 or later, and git 1.7 or later. Earlier versions might work, but
they have not been tested.

Mac OS users should install Xcode, either from the Mac OS install DVD or from the
Apple Mac OS App Store. Node.js can be installed by one of the UNIX package managers
available for the Mac OS or by using the DMG available on the Node.js website.

Linux/BSD users should use their appropriate package managers to install make, git,
and node.

How to build your own SGA Shared Canvas
---------------------------------------

First, clone a copy of the SGA git repo by running `git clone git://github.com/umd_mith/sga.git`.

Then, to get a complete, minified, jslinted version of SGA Shared Canvas, simply `cd` to the `sga/shared-canvas` directory and
type `make`. If you don't have Node installed and/or want to make a basic, uncompressed, unlinted version
of SGA Shared Canvas, use `make shared-canvas` instead of `make`.

**N.B.:** Node.js and CoffeeScript are required to compile the CoffeeScript to JavaScript.

The built version of SGA Shared Canvas will be in the `dist/` subdirectory.

To remove all built files, run `make clean`.

How to test SGA Shared Canvas
-----------------------------

Once you have built SGA Shared Canvas, you can browse to the `test/` subdirectory and view the
`index.html` file. This file loads the minified version of SGA Shared Canvas by default.

Style Guide
-----------

The source files are written in CoffeeScript and compiled to JavaScript. CoffeeScript treats white space similar
to Python. It is significant, and indentation indicates a block of statements.

Except for the intro.coffee and outro.coffee source files, all files should start with no indentation.
The make process will add two tabs at the beginning of each line when building the angles.coffee master file.

Before committing changes, please make sure you can build the shared-cavas.js file and pass the JSLint tests.

Components should go into the source files named for the type of component being added. For example, controllers should
go in the controller.coffee source file.