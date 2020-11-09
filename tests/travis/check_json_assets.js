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

glob.sync( '**', globOptions ).forEach( ( filename ) => {
	try {
		JSON.parse( sanitizeRelaxedJson( fs.readFileSync( directory + '/' + filename ).toString() ) );
	} catch ( error ) {
		console.log( filename, error );
		failedCount ++;
	}

	if ( ++ totalCount % 200 == 0 ) {
		process.stdout.write( totalCount + ' ' );
	}
} );

process.stdout.write( '\n' );
process.exit( failedCount > 0 ? 1 : 0 );
