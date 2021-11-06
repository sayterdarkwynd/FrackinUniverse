/**
 * Find all JSON files and check them for correctness.
 */

'use strict';

const fs = require( 'fs' ),
	process = require( 'process' ),
	glob = require( 'fast-glob' ),
	stripJsonComments = require( 'strip-json-comments' );

// Having these item codes in .recipe files, extractions, etc. won't be considered an error.
const listsOfAllowedUnknownItemCodes = [
	'data/vanilla_item_codes.txt',
	'data/expected_unknown_item_codes.txt'
];

// Having these items codes in unlocks of Research Tree won't be considered an error.
const listsOfAllowedNonCraftableItemsInNodes = [
	'data/expected_noncraftables_in_unlocks.txt'
];

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
		} else if ( isInsideQuotes ) {
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

/**
 * Returns array of all lines in several files.
 * @param {string[]} filenames
 * @return string[]
 */
function readAllLines( filenames ) {
	var lines = [];
	filenames.forEach( ( filename ) => {
		var moreLines = fs.readFileSync( __dirname + '/' + filename ).toString().split( /[\r\n]+/ ).filter( ( x ) => x !== '' );
		lines.push( ...moreLines );
	} );
	return lines;
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

var knownItemCodes = new Set(), // [ itemCode1, itemCode2, ... ]
	craftableItemCodes = new Set(),
	allAssets = new Map(); // { filename1: recipeData1, ... }

filenames.forEach( ( filename ) => {
	var jsonString = sanitizeRelaxedJson( fs.readFileSync( directory + '/' + filename ).toString() );
	var data;

	try {
		data = JSON.parse( jsonString );
	} catch ( error ) {
		console.log( '\n', filename, addContextToJsonError( error, jsonString ) );
		failedCount ++;
	}

	if ( data ) {
		var itemCode;
		if ( filename.endsWith( '.codex' ) && data.id ) {
			itemCode = data.id + '-codex';
		} else {
			itemCode = data.itemName || data.objectName;
		}

		if ( itemCode ) {
			knownItemCodes.add( itemCode );

			if ( filename.startsWith( 'items/generic/produce' ) ) {
				// Produce items (e.g. Aquapod) shouldn't cause a warning if used in unlocks of Agriculture nodes.
				craftableItemCodes.add( itemCode );
			}
		}

		allAssets.set( filename, data );
	}

	if ( ++ totalCount % 2500 == 0 ) {
		process.stdout.write( totalCount + ' ' );
	}
} );
console.log( '\n' );

// Load the list of unknown items that shouldn't be considered an error if we find them in recipes.
// These are mostly vanilla items. Also includes items from other mods that have extractions, etc.
readAllLines( listsOfAllowedUnknownItemCodes ).forEach( ( itemCode ) => {
	knownItemCodes.add( itemCode );

	// We don't know if these items are craftable, so we assume that they are.
	craftableItemCodes.add( itemCode );
} );
readAllLines( listsOfAllowedNonCraftableItemsInNodes ).forEach( ( itemCode ) => {
	craftableItemCodes.add( itemCode );
} );

// Remember which Tricorder techs are craftable.
for ( var tech of allAssets.get( 'interface/scripted/techshop/techshop.config' ).techs ) {
	craftableItemCodes.add( tech.item );
}

// Check if any crafting recipes have unknown item codes.
for ( var [ filename, data ] of allAssets ) {
	if ( !filename.endsWith( '.recipe' ) ) {
		continue;
	}

	var itemCodes = data.input.concat( [ data.output ] ).map( ( elem ) => elem.item || elem.name );
	itemCodes.forEach( ( itemCode ) => {
		if ( !knownItemCodes.has( itemCode ) ) {
			console.log( filename, 'Unknown item in recipe: ' + itemCode );
			failedCount ++;
		}
	} );

	// Remember that output item is craftable.
	// (used later to detect Research Tree unlocks of non-craftable items)
	craftableItemCodes.add( data.output.item || data.output.name );
}

// Check if outputs of extractions have unknown item codes.
for ( var extractionsFilename of [
	'objects/generic/extractionlab_recipes.config',
	'objects/generic/extractionlabmadness_recipes.config',
	'objects/generic/honeyjarrer_recipes.config',
	'objects/generic/xenostation_recipes.config',
	'objects/minibiome/elder/embalmingtable/embalmingtable_recipes.config',
	'objects/power/fu_liquidmixer/fu_liquidmixer_recipes.config'
] ) {
	allAssets.get( extractionsFilename ).forEach( ( extractorRecipe ) => {
		for ( var itemCode of Object.keys( extractorRecipe.outputs ) ) {
			if ( !knownItemCodes.has( itemCode ) ) {
				console.log( extractionsFilename, 'Unknown item in extraction: ' + itemCode );
				failedCount ++;
			}
		}
	} );
}

// Check if outputs of centrifuges/sifters/crushers have unknown item codes.
for ( var [ groupName, groupRecipes ] of Object.entries( allAssets.get( 'objects/generic/centrifuge_recipes.config' ) ) ) {
	if ( groupName == 'recipeTypes' ) {
		continue;
	}

	for ( var [ inputCode, outputs ] of Object.entries( groupRecipes ) ) {
		for ( var itemCode of Object.keys( outputs ) ) {
			if ( !knownItemCodes.has( itemCode ) ) {
				console.log( 'Unknown item in centrifuge recipe: ' + itemCode );
				failedCount ++;
			}
		}
	}
}

// Check if outputs of smelters have unknown item codes.
for ( var smelterFilename of [
	'objects/power/electricfurnace/electricfurnace.object',
	'objects/power/fu_blastfurnace/fu_blastfurnace.object',
	'objects/power/isn_arcsmelter/isn_arcsmelter.object'
] ) {
	var smelterConf = allAssets.get( smelterFilename );
	var possibleOutputs = new Set( Object.values( smelterConf.inputsToOutputs ) );

	for ( var bonusOutputs of Object.values( smelterConf.bonusOutputs ) ) {
		for ( var itemCode of Object.keys( bonusOutputs ) ) {
			possibleOutputs.add( itemCode );
		}
	}

	for ( var itemCode of possibleOutputs ) {
		if ( !knownItemCodes.has( itemCode ) ) {
			console.log( smelterFilename, 'Unknown item in smelter recipe: ' + itemCode );
			failedCount ++;
		}
	}
}

// Check if TreasurePools have unknown item codes.
for ( var [ filename, data ] of allAssets ) {
	if ( !filename.match( /\.treasurepools(|\.patch)$/ ) ) {
		continue;
	}

	var elementsToCheck = [];
	if ( filename.endsWith( 'treasurepools' ) ) {
		for ( var [ poolName, poolDataSets ] of Object.entries( data ) ) {
			poolDataSets.forEach( ( dataSet ) => {
				var poolData = dataSet[1];
				var poolElements = ( poolData.pool || [] ).concat( poolData.fill || [] );

				elementsToCheck.push( ...poolElements );
			} );
		}
	} else if ( filename.endsWith( 'patch' ) ) {
		for ( var instruction of data ) {
			if ( instruction.op === 'add' && instruction.path.endsWith( '/pool/-' ) ) {
				elementsToCheck.push( instruction.value );
			}
		}
	}

	for ( var elem of elementsToCheck ) {
		var itemCode = elem.item;
		if ( !itemCode ) {
			continue;
		}

		if ( Array.isArray( itemCode ) ) {
			itemCode = itemCode[0];
		} else if ( itemCode.name ) {
			itemCode = itemCode.name;
		}

		itemCode = itemCode.replace( /-recipe$/, '' );
		if ( !knownItemCodes.has( itemCode ) ) {
			console.log( filename, 'Unknown item in TreasurePool: ' + itemCode );
			failedCount ++;
		}
	}
}

// Check if research tree unlocks have unknown item codes.
for ( var treeFilename of [
	'zb/researchTree/fu_agriculture.config',
	'zb/researchTree/fu_chemistry.config',
	'zb/researchTree/fu_craftsmanship.config',
	'zb/researchTree/fu_engineering.config',
	'zb/researchTree/fu_geology.config',
	'zb/researchTree/fu_power.config',
	'zb/researchTree/fu_warcraft.config',
	'zb/researchTree/madness.config'
] ) {
	var treeConf = allAssets.get( treeFilename ).researchTree;
	Object.values( Object.values( treeConf )[0] ).forEach( ( node ) => {
		if ( !node.unlocks ) {
			return;
		}

		for ( itemCode of node.unlocks ) {
			if ( !knownItemCodes.has( itemCode ) ) {
				console.log( treeFilename, 'Unknown item in research unlocks: ' + itemCode );
				failedCount ++;
			}

			if ( !craftableItemCodes.has( itemCode ) ) {
				console.log( treeFilename, 'Non-craftable item in research unlocks: ' + itemCode );
				failedCount ++;
			}
		}
	} );
}

process.stdout.write( 'Checked ' + totalCount + ' JSON files. Errors: ' + failedCount + '.\n' );
process.exit( failedCount > 0 ? 1 : 0 );
