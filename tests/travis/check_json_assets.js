/**
 * Find all JSON files and check them for correctness.
 */

'use strict';

const fs = require( 'fs' ),
	process = require( 'process' ),
	glob = require( 'fast-glob' ),
	stripJsonComments = require( 'strip-json-comments' );

/**
 * Turn non-strict JSON (with comments, newlines, etc.) into a string suitable for JSON.parse().
 * From https://github.com/edwardspec/fudocgenerator/
 * @param {string} relaxedJson
 * @return {string}
 */
function sanitizeRelaxedJson( relaxedJson ) {
	// Some input files have "new line" character within the JSON strings (between " and ").
	// This is invalid JSON (would cause syntax error), but we must be tolerant to such input.
	// This is especially important for weapons/tools, as most of them have multiline descriptions.
	var sanitizedJson = '',
		isInsideQuotes = false,
		prevChar = '';

	// Remove comments (JSON standard doesn't allow them).
	relaxedJson = stripJsonComments( relaxedJson );

	// Remove both \r and BOM (byte order mark) symbols, because they confuse JSON.parse().
	relaxedJson = relaxedJson.replace( /(\uFEFF|\r)/g, '' );

	// Iterate over each character, and if we find "new line" or "tab" characters inside the quotes,
	// replace them with "\n" and "\t" respectively, making this a valid JSON.
	[...relaxedJson].forEach( char => {
		// Non-escaped " means that this is start/end of a string.
		if ( char == '"' && prevChar != '\\' ) {
			isInsideQuotes = !isInsideQuotes;
		}

		if ( isInsideQuotes ) {
			switch ( char ) {
				case '\n':
					char = '\\n';
					break;
				case '\t':
					char = '\\t';
			}
		}

		sanitizedJson += char;
		prevChar = char;
	} );

	return sanitizedJson;
}

/**
 * Make error from JSON.parse() more readable by adding "text before/after the position of error".
 * Normal error like "Unexpected token { in JSON at position 1005" is inconvenient to troubleshoot.
 * @param {Error} exception Exception thrown by JSON.parse().
 * @param {string} sourceCode String that was passed to JSON.parse() as parameter.
 * @return {string} Improved error message.
 * Example of improved message:
 * ... "path": "/a", "value": 123 } <<<SYNTAX ERROR HERE>>>{ "op": "add", "path": "/b" ...
 */
function addContextToJsonError( exception, sourceCode ) {
	var errorMessage = exception.message;

	var match = errorMessage.match( 'at position ([0-9]+)' );
	if ( match ) {
		// We are quoting symbolsToQuote before AND symbolsToQuote after the error position.
		// As such, up to 2*symbolsToQuote symbols can be quoted.
		var symbolsToQuote = 100,
			position = parseInt( match[1] ),
			quoteBefore = sourceCode.substring( 0, position ).replace( /\s+/g, ' ' ),
			quoteAfter = sourceCode.substring( position ).replace( /\s+/g, ' ' );

		quoteBefore = quoteBefore.substring( quoteBefore.length - symbolsToQuote );
		quoteAfter = quoteAfter.substring( 0, symbolsToQuote );

		errorMessage += '\n\t... ' + quoteBefore + '<<<SYNTAX ERROR HERE>>>' + quoteAfter + ' ...';
	}

	return errorMessage;
}

// This script is under tests/travis/
var directory = __dirname + '/../..';

var globOptions = {
	cwd: directory,
	ignore: [
		// Exclude everything that is not a JSON asset: images, documentation, examples, etc.
		'tests',
		'a_modders',
		'_previewimage',
		'**/*.{lua,png,xcf,wav,ogg,txt,md,ase,aseprite,tsx,aup,ico,tmx,pdn,zip,au,old,unused}'
	],
	caseSensitiveMatch: false
};

var totalCount = 0,
	failedCount = 0;

var filenames = glob.sync( '**', globOptions ).concat( [ '.metadata' ] );

filenames.forEach( ( filename ) => {
	var jsonString = sanitizeRelaxedJson( fs.readFileSync( directory + '/' + filename ).toString() );
	try {
		JSON.parse( jsonString );
	} catch ( error ) {
		console.log( '\n', filename, addContextToJsonError( error, jsonString ) );
		failedCount ++;
	}

	if ( ++ totalCount % 2500 == 0 ) {
		process.stdout.write( totalCount + ' ' );
	}
} );

process.stdout.write( '\nChecked ' + totalCount + ' JSON files. Errors: ' + failedCount + '.\n' );
process.exit( failedCount > 0 ? 1 : 0 );
