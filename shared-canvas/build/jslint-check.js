var JSLINT = require("./lib/jslint").check, //.JSLINT,
	print = require("util").print,
	src = require("fs").readFileSync("dist/angles.js", "utf8");

JSLINT(src, { 
	forin: true, 
	maxerr: 100, 
	vars: true,
	maxlen: 255,
	white: true, 
	sloppy: true, 
	browser: true, 
	plusplus: false,
	"continue": true,
	confusion: true,
	nomen: true
});

// All of the following are known issues that we think are 'ok'
// (in contradiction with JSLint). These are either because we
// reference globals defined by dependencies or are caused by
// standard CoffeeScript practices.
var ok = {
	"'jQuery' was used before it was defined.": true,
	"'MITHGrid' was used before it was defined.": true,
	"Move the invocation into the parens that contain the function.": true,
	"Do not wrap function literals in parens unless they are to be immediately invoked.": true
};

var e = JSLINT.errors, found = 0, w;

for ( var i = 0; i < e.length; i++ ) {
	w = e[i];
	if(w === null) { continue; }

	if ( !ok[ w.reason ] ) {
		found++;
		print( "\n" + w.evidence + "\n" );
		print( "    Problem at line " + w.line + " character " + w.character + ": " + w.reason );
	}
}

if ( found > 0 ) {
	print( "\n" + found + " Error(s) found.\n" );

} else {
	print( "JSLint check passed.\n" );
}
