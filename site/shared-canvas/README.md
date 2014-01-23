SGA Shared Canvas
=================

**SGA Shared Canvas** is a shared canvas reader written in CoffeeScript.

How to build SGA Shared Canvas
---------------------------------------

First, clone a copy of the SGA git repo by running `git clone git://github.com/umd_mith/sga.git`.

You will need to have installed Node.js and npm (a node package manager).

First get all node.js dependencies by running:

```
$ npm install
```

Then get other dependencies (including those from Bower) by running:

```
$ grunt install
```

Finally, to compile run:

```
$ grunt
```

Style Guide
-----------

The source files are written in CoffeeScript and compiled to JavaScript. CoffeeScript treats white space similar
to Python. It is significant, and indentation indicates a block of statements.

Except for the intro.coffee and outro.coffee source files, all files should start with no indentation.
The make process will add two tabs at the beginning of each line when building the angles.coffee master file.

Grunt can watch your source and compile the CoffeScript code. Run `$ grunt run` to watch your code and run a simple server for testing through the demo page.

Before committing changes, please make sure you can build the shared-cavas.js file and pass JSLint tests.

Components should go into the source files named for the type of component being added. For example, controllers should
go in the controller.coffee source file.