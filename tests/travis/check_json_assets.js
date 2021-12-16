/**
 * Find all JSON files and check them for correctness.
 */

'use strict';

const fs = require( 'fs' ),
	process = require( 'process' ),
	glob = require( 'fast-glob' ),
	stripJsonComments = require( 'strip-json-comments' );

class JsonAssetsTest {
	constructor() {
		this.failedCount = 0; // Incremented by fail().

		// These tables are populated by various load*() methods below
		this.knownItemCodes = new Set(); // [ itemCode1, itemCode2, ... ]
		this.craftableItemCodes = new Set();
		this.knownAssets = new Map(); // { filename1: recipeData1, ... }
	}

	/**
	 * Run all checks.
	 *
	 * @return {boolean} True if all checks were successful, false otherwise.
	 */
	runTest() {
		var totalAssetCount = this.loadAssets();

		this.loadExceptionLists();
		this.loadTricorderTechs();
		this.loadCraftingRecipes();

		this.checkExtractions();
		this.checkCentrifuges();
		this.checkSmelters();
		this.checkSpaceStations();
		this.checkTreasurePools();
		this.checkTreeUnlocks();

		process.stdout.write( 'Checked ' + totalAssetCount + ' JSON files. Errors: ' + this.failedCount + '.\n' );
		return this.failedCount === 0;
	}

	/**
	 * Print error message and increment the number of failed tests.
	 *
	 * @param {...Mixed} errorMessage
	 */
	fail( ...errorMessage ) {
		console.log( ...errorMessage );
		this.failedCount++;
	}

	/**
	 * Load all JSON assets, populating this.knownAssets array.
	 *
	 * @return {number} Total number of assets (including assets that failed to load).
	 */
	loadAssets() {
		// This script is under tests/travis/
		var directory = __dirname + '/../..',
			totalAssetCount = 0;

		this.findAssetFilenames( directory ).forEach( ( filename ) => {
			if ( ++totalAssetCount % 2500 === 0 ) {
				// Progress bar.
				process.stdout.write( totalAssetCount + ' ' );
			}

			var jsonString = this.sanitizeRelaxedJson( fs.readFileSync( directory + '/' + filename ).toString() );
			var data;

			try {
				data = JSON.parse( jsonString );
			} catch ( error ) {
				this.fail( '\n', filename, this.addContextToJsonError( error, jsonString ) );
				return;
			}

			// Ensure that description/shortdescription don't have non-closed color codes (e.g. ^yellow;).
			for ( var fieldName of [ 'description', 'shortdescription' ] ) {
				var fieldValue = data[fieldName];
				if ( fieldValue ) {
					var hasColor = false;
					for ( var match of fieldValue.matchAll( /\^([^;^]+);/g ) ) {
						var color = match[1].toLowerCase();
						hasColor = ( color !== 'reset' );
					}

					if ( hasColor ) {
						this.fail( '\n', filename, 'Missing ^reset; in ' + fieldName + ': ' + fieldValue );
					}
				}
			}

			// Remember if this is an item.
			var itemCode;
			if ( filename.endsWith( '.codex' ) && data.id ) {
				itemCode = data.id + '-codex';
			} else {
				itemCode = data.itemName || data.objectName;
			}

			if ( itemCode ) {
				if ( this.knownItemCodes.has( itemCode ) && itemCode !== 'weaponupgradeanvil2' ) {
					this.fail( '\n', filename, 'Duplicate item ID: ' + itemCode );
				}

				this.knownItemCodes.add( itemCode );

				if ( filename.startsWith( 'items/generic/produce' ) ) {
					// Produce items (e.g. Aquapod) shouldn't cause a warning if used in unlocks of Agriculture nodes.
					this.craftableItemCodes.add( itemCode );
				}
			}

			this.knownAssets.set( filename, data );
		} );

		// Completed progress bar.
		console.log( '\n' );
		return totalAssetCount;
	}

	/**
	 * Get array of filenames of all JSON assets.
	 *
	 * @param {string} directory
	 * @return {string[]}
	 */
	findAssetFilenames( directory ) {
		var globOptions = {
			cwd: directory,
			ignore: [
				// Exclude everything that is not a JSON asset: images, documentation, examples, etc.
				'tests',
				'a_modders',
				'_previewimage',
				'**/*.gun', // legacy files (JSON, but are not loaded by the game)
				'**/*.{lua,png,xcf,wav,ogg,txt,md,ase,aseprite,tsx,aup,ico,tmx,pdn,zip,au,old,unused}'
			],
			caseSensitiveMatch: false
		};

		return glob.sync( '**', globOptions ).concat( [ '.metadata' ] );
	}

	/**
	 * Prepare the list of expected (ignored) errors, e.g. "unknown item" for vanilla items.
	 */
	loadExceptionLists() {
		// Having these item codes in extraction inputs won't be considered an error.
		// (e.g. items not from FU+vanilla that have extractions)
		this.externalExtractionInputs = new Set( this.readAllLines( [
			'data/expected_unknown_extraction_inputs.txt'
		] ) );

		// Having these item codes in .recipe files, extractions outputs, etc. won't be considered an error
		this.readAllLines( [
			'data/vanilla_item_codes.txt',
			'data/expected_unknown_item_codes.txt'
		] ).forEach( ( itemCode ) => {
			this.knownItemCodes.add( itemCode );

			// We don't know if these items are craftable, so we assume that they are.
			this.craftableItemCodes.add( itemCode );
		} );

		// Having these items codes in unlocks of Research Tree won't be considered an error.
		this.readAllLines( [ 'data/expected_noncraftables_in_unlocks.txt' ] ).forEach( ( itemCode ) => {
			this.craftableItemCodes.add( itemCode );
		} );
	}

	/**
	 * Remember which Tricorder techs are craftable.
	 */
	loadTricorderTechs() {
		for ( var tech of this.knownAssets.get( 'interface/scripted/techshop/techshop.config' ).techs ) {
			this.craftableItemCodes.add( tech.item );
		}
	}

	/**
	 * Check all .recipe files for unknown inputs/outputs. Remember which items are craftable.
	 */
	loadCraftingRecipes() {
		// To keep track of duplicate "inputs+outputs", see below.
		var seenCraftingInputOutputs = new Set();

		// Check if any crafting recipes have unknown item codes.
		for ( var [ filename, data ] of this.knownAssets ) {
			if ( !filename.endsWith( '.recipe' ) ) {
				continue;
			}

			var itemCodes = data.input.concat( [ data.output ] ).map( ( elem ) => elem.item || elem.name );
			itemCodes.forEach( ( itemCode ) => {
				if ( !this.knownItemCodes.has( itemCode ) ) {
					this.fail( filename, 'Unknown item in recipe: ' + itemCode );
				}
			} );

			// Remember that output item is craftable.
			// (used later to detect Research Tree unlocks of non-craftable items)
			this.craftableItemCodes.add( data.output.item || data.output.name );

			// Keep track of "inputs+outputs" in .recipe files (including quantities),
			// because it is an error for 2+ recipe files to have the same "inputs+outputs"
			// (the game will ignore duplicate recipes, only one of them will be used).
			var inputsOutputsId = data.input.concat( [
				Object.assign( { isOutput: 1 }, data.output )
			] ).map( ( elem ) => {
				let id = ( elem.item || elem.name ) + ':' + ( elem.count || 1 );

				if ( elem.parameters ) {
					id += ':' + JSON.stringify( Object.entries( elem.parameters ).sort() );
				}

				if ( elem.isOutput ) {
					id = '_Output<<<' + id + '>>>';
				}

				return id;
			} ).sort().join( ',' );

			if ( seenCraftingInputOutputs.has( inputsOutputsId ) ) {
				this.fail( filename, 'Two (or more) crafting recipes with the same inputs+outputs: ' + inputsOutputsId );
			}
			seenCraftingInputOutputs.add( inputsOutputsId );
		}
	}

	/**
	 * Check if inputs/outputs of extractions have unknown item codes.
	 */
	checkExtractions() {
		for ( var extractionsFilename of [
			'objects/generic/extractionlab_recipes.config',
			'objects/generic/extractionlabmadness_recipes.config',
			'objects/generic/honeyjarrer_recipes.config',
			'objects/generic/xenostation_recipes.config',
			'objects/minibiome/elder/embalmingtable/embalmingtable_recipes.config',
			'objects/power/fu_liquidmixer/fu_liquidmixer_recipes.config'
		] ) {
			var seenInputs = new Set();

			this.knownAssets.get( extractionsFilename ).forEach( ( extractorRecipe ) => {
				for ( let itemCode of Object.keys( extractorRecipe.outputs ) ) {
					if ( !this.knownItemCodes.has( itemCode ) ) {
						this.fail( extractionsFilename, 'Unknown item in extraction: ' + itemCode );
					}
				}

				var inputCodes = Object.keys( extractorRecipe.inputs );
				for ( let itemCode of inputCodes ) {
					if ( !this.knownItemCodes.has( itemCode ) && !this.externalExtractionInputs.has( itemCode ) ) {
						this.fail( extractionsFilename, 'Unknown item as extraction input: ' + itemCode );
					}
				}

				var inputsId = inputCodes.sort().join( ',' );
				if ( seenInputs.has( inputsId ) ) {
					this.fail( extractionsFilename, 'Two (or more) extractions with the same inputs: ' + inputsId );
				}
				seenInputs.add( inputsId );
			} );
		}
	}

	/**
	 * Check if inputs/outputs of centrifuges/sifters/crushers have unknown item codes.
	 */
	checkCentrifuges() {
		for ( var [ groupName, groupRecipes ] of Object.entries( this.knownAssets.get( 'objects/generic/centrifuge_recipes.config' ) ) ) {
			if ( groupName === 'recipeTypes' ) {
				continue;
			}

			for ( var [ inputCode, outputs ] of Object.entries( groupRecipes ) ) {
				for ( var itemCode of Object.keys( outputs ) ) {
					if ( !this.knownItemCodes.has( itemCode ) ) {
						this.fail( 'Unknown item in centrifuge recipe: ' + itemCode );
					}
				}

				if ( !this.knownItemCodes.has( inputCode ) && !this.externalExtractionInputs.has( inputCode ) ) {
					this.fail( 'Unknown item as centrifuge input: ' + inputCode );
				}
			}
		}
	}

	/**
	 * Check if inputs/outputs of smelters have unknown item codes.
	 */
	checkSmelters() {
		for ( var smelterFilename of [
			'objects/power/electricfurnace/electricfurnace.object',
			'objects/power/fu_blastfurnace/fu_blastfurnace.object',
			'objects/power/isn_arcsmelter/isn_arcsmelter.object'
		] ) {
			var smelterConf = this.knownAssets.get( smelterFilename );
			var possibleOutputs = new Set( Object.values( smelterConf.inputsToOutputs ) );

			for ( var bonusOutputs of Object.values( smelterConf.bonusOutputs ) ) {
				for ( let itemCode of Object.keys( bonusOutputs ) ) {
					possibleOutputs.add( itemCode );
				}
			}

			for ( let itemCode of possibleOutputs ) {
				if ( !this.knownItemCodes.has( itemCode ) ) {
					this.fail( smelterFilename, 'Unknown item in smelter recipe: ' + itemCode );
				}
			}

			var possibleInputs = new Set(
				Object.keys( smelterConf.inputsToOutputs ).concat( Object.keys( smelterConf.bonusOutputs ) ) );
			for ( let itemCode of possibleInputs ) {
				if ( !this.knownItemCodes.has( itemCode ) && !this.externalExtractionInputs.has( itemCode ) ) {
					this.fail( smelterFilename, 'Unknown item as smelter input: ' + itemCode );
				}
			}
		}
	}

	/**
	 * Check if shops of spacestations have unknown item codes.
	 */
	checkSpaceStations() {
		var itemsSoldAtStations = new Set(
			Object.values( this.knownAssets.get( 'interface/scripted/spaceStation/spaceStationData.config' ).shop.potentialStock ).flat()
		);
		for ( var itemCode of itemsSoldAtStations ) {
			if ( !this.knownItemCodes.has( itemCode ) ) {
				this.fail( 'Unknown item sold at spacestations: ' + itemCode );
			}
		}
	}

	/**
	 * Check if TreasurePools have unknown item codes.
	 */
	checkTreasurePools() {
		for ( var [ filename, data ] of this.knownAssets ) {
			if ( !filename.match( /\.treasurepools(|\.patch)$/ ) ) {
				continue;
			}

			if ( filename.endsWith( 'treasurepools' ) ) {
				for ( var poolDataSets of Object.values( data ) ) {
					poolDataSets.forEach( ( dataSet ) => {
						var poolData = dataSet[1];
						var poolElements = ( poolData.pool || [] ).concat( poolData.fill || [] );

						poolElements.forEach( ( elem ) => this.checkTreasurePoolElement( elem, filename ) );
					} );
				}
			} else if ( filename.endsWith( 'patch' ) ) {
				for ( var instruction of data ) {
					if ( instruction.op === 'add' && instruction.path.endsWith( '/pool/-' ) ) {
						this.checkTreasurePoolElement( instruction.value, filename );
					}
				}
			}
		}
	}

	/**
	 * Check if 1 element of TreasurePool refers to unknown item.
	 *
	 * @param {Object} elem
	 * @param {string} sourceFilename
	 */
	checkTreasurePoolElement( elem, sourceFilename ) {
		var itemCode = elem.item;
		if ( !itemCode ) {
			return;
		}

		if ( Array.isArray( itemCode ) ) {
			itemCode = itemCode[0];
		} else if ( itemCode.name ) {
			itemCode = itemCode.name;
		}

		itemCode = itemCode.replace( /-recipe$/, '' );
		if ( !this.knownItemCodes.has( itemCode ) ) {
			this.fail( sourceFilename, 'Unknown item in TreasurePool: ' + itemCode );
		}
	}

	/**
	 * Check if research tree unlocks have unknown/non-craftable item codes.
	 */
	checkTreeUnlocks() {
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
			var treeConf = this.knownAssets.get( treeFilename ).researchTree;
			Object.values( Object.values( treeConf )[0] ).forEach( ( node ) => {
				if ( !node.unlocks ) {
					return;
				}

				for ( var itemCode of node.unlocks ) {
					if ( !this.knownItemCodes.has( itemCode ) ) {
						this.fail( treeFilename, 'Unknown item in research unlocks: ' + itemCode );
					} else if ( !this.craftableItemCodes.has( itemCode ) ) {
						this.fail( treeFilename, 'Non-craftable item in research unlocks: ' + itemCode );
					}
				}
			} );
		}
	}

	/* ------------------------------------------------------------------------------------- */
	/* --------------- Utility methods ----------------------------------------------------- */
	/* ------------------------------------------------------------------------------------- */

	/**
	 * Turn non-strict JSON (with comments, newlines, etc.) into a string suitable for JSON.parse().
	 * From https://github.com/edwardspec/fudocgenerator/
	 *
	 * @param {string} relaxedJson
	 * @return {string}
	 */
	sanitizeRelaxedJson( relaxedJson ) {
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
		[...relaxedJson].forEach( ( char ) => {
			// Non-escaped " means that this is start/end of a string.
			if ( char === '"' && prevChar !== '\\' ) {
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
	 *
	 * @param {Error} exception Exception thrown by JSON.parse().
	 * @param {string} sourceCode String that was passed to JSON.parse() as parameter.
	 * @return {string} Improved error message.
	 * Example of improved message:
	 * ... "path": "/a", "value": 123 } <<<SYNTAX ERROR HERE>>>{ "op": "add", "path": "/b" ...
	 */
	addContextToJsonError( exception, sourceCode ) {
		var errorMessage = exception.message;

		var match = errorMessage.match( 'at position ([0-9]+)' );
		if ( match ) {
			// We are quoting symbolsToQuote before AND symbolsToQuote after the error position.
			// As such, up to 2*symbolsToQuote symbols can be quoted.
			var symbolsToQuote = 100,
				position = parseInt( match[1] ),
				quoteBefore = sourceCode.slice( 0, position ).replace( /\s+/g, ' ' ),
				quoteAfter = sourceCode.slice( position ).replace( /\s+/g, ' ' );

			quoteBefore = quoteBefore.slice( -1 * symbolsToQuote );
			quoteAfter = quoteAfter.slice( 0, symbolsToQuote );

			errorMessage += '\n\t... ' + quoteBefore + '<<<SYNTAX ERROR HERE>>>' + quoteAfter + ' ...';
		}

		return errorMessage;
	}

	/**
	 * Returns array of all lines in several files.
	 *
	 * @param {string[]} filenames
	 * @return {string[]}
	 */
	readAllLines( filenames ) {
		var lines = [];
		filenames.forEach( ( filename ) => {
			var moreLines = fs.readFileSync( __dirname + '/' + filename ).toString().split( /[\r\n]+/ )
				.filter( function ( x ) {
					return x !== '' && !x.startsWith( '#' ) && !x.startsWith( '//' );
				} );
			lines.push( ...moreLines );
		} );
		return lines;
	}
}

// Actually run the test.
var test = new JsonAssetsTest();
process.exit( test.runTest() ? 0 : 1 );
