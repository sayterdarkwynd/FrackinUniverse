/**
 * Find all JSON files and check them for correctness.
 */

'use strict';

const fs = require( 'fs' ),
	process = require( 'process' ),
	glob = require( 'fast-glob' ),
	stripJsonComments = require( 'strip-json-comments' );

// Make output synchronous (workaround for Node.js sometimes exiting before printing everything).
process.stdout._handle.setBlocking( true ); // eslint-disable-line no-underscore-dangle

class JsonAssetsTest {
	constructor() {
		this.failedCount = 0; // Incremented by fail().

		// These tables are populated by various load*() methods below
		this.knownItemCodes = new Set(); // [ itemCode1, itemCode2, ... ]
		this.craftableItemCodes = new Set();
		this.knownAssets = new Map(); // { filename1: assetData1, ... }

		this.knownLiquids = new Map(); // { liquidId: liquidData1, ... }
		this.knownMaterials = new Map(); // { materialId: materialData1, ... }
		this.knownMaterialsByName = new Map(); // { materialName: materialData1, ... }

		this.placeableMaterials = new Set(); // { materialId1, materialId2, ... }
	}

	/**
	 * Run all checks.
	 *
	 * @return {boolean} True if all checks were successful, false otherwise.
	 */
	runTest() {
		var totalAssetCount;

		this.loadMockedVanillaAssets();

		totalAssetCount = this.loadAssets();
		this.analyzeAssets();

		this.loadExceptionLists();
		this.loadTricorderTechs();
		this.loadCraftingRecipes();

		this.checkExtractions();
		this.checkCentrifuges();
		this.checkSmelters();
		this.checkSpaceStations();
		this.checkTreasurePools();
		this.checkTreeUnlocks();
		this.checkLiquidInteractions();

		console.log( 'Checked ' + totalAssetCount + ' JSON files. Errors: ' + this.failedCount + '.\n' );
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
	 * Load shortened information about some vanilla assets (e.g. lists of liquids and materials).
	 */
	loadMockedVanillaAssets() {
		[
			'data/vanilla_liquids.json',
			'data/vanilla_materials.json'
		].forEach( ( pathToMock ) => {
			var mocks = JSON.parse( fs.readFileSync( __dirname + '/' + pathToMock ).toString() );
			for ( var [ filename, data ] of mocks ) {
				this.knownAssets.set( filename, data );
			}
		} );
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
			if ( ++totalAssetCount % 2500 === 0 && process.stdout.isTTY ) {
				// Progress bar.
				process.stdout.write( totalAssetCount + ' ' );
			}

			var relaxedJsonString = fs.readFileSync( directory + '/' + filename ).toString();

			// Detect trailing spaces in JSON files except 1) changelogs,
			// 2) files created by Tiled, such as tilesets or dungeons.
			if ( !filename.match( /^((dungeons|frackinship|tilesets)\/|_(FU|ZB).*\.config$)/ ) ) {
				relaxedJsonString.split( /\r?\n/ ).forEach( ( line, lineIndex ) => {
					if ( line.match( /\s+$/ ) ) {
						let errorMessage;
						if ( line.match( /[^\s]/ ) ) {
							errorMessage = 'trailing whitespace: "' + line + '"';
						} else {
							errorMessage = 'line contains only whitespace';
						}

						this.fail( filename + ':' + ( 1 + lineIndex ) + ': ' + errorMessage );
					}
				} );
			}

			// Parse the JSON asset.
			var jsonString = this.sanitizeRelaxedJson( relaxedJsonString );
			var data;

			try {
				data = JSON.parse( jsonString );
			} catch ( error ) {
				this.fail( '\n', filename, this.addContextToJsonError( error, jsonString ) );
				return;
			}

			this.knownAssets.set( filename, data );
		} );

		// Completed progress bar.
		console.log( '\n' );
		return totalAssetCount;
	}

	/**
	 * After all assets are loaded, perform most basic checks on their contents,
	 * populate this.knownItemCodes, etc.
	 */
	analyzeAssets() {
		for ( var [ filename, data ] of this.knownAssets ) {
			var filenamePaths = filename.split( '.' ),
				fileExtension = filenamePaths.pop(),
				patchedExtension = null;

			if ( fileExtension === 'patch' ) {
				// We don't have full vanilla assets here, so we can't apply patches completely,
				// but some parts of them may still be analyzed below.
				patchedExtension = filenamePaths.pop();
			}

			// Add "sourceFilename" to all assets (for use in error messages).
			Object.defineProperty( data, 'sourceFilename', { value: filename } );

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
			if ( fileExtension === 'codex' && data.id ) {
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

				if ( data.materialId ) {
					this.placeableMaterials.add( data.materialId );
				}

				// No more checks for items.
				continue;
			}

			// Remember if this is a liquid or material.
			if ( fileExtension === 'liquid' ) {
				this.knownLiquids.set( data.liquidId, data );
				continue;
			}

			if ( fileExtension === 'material' ) {
				this.knownMaterials.set( data.materialId, data );
				this.knownMaterialsByName.set( data.materialName, data );

				continue;
			}

			// Partially apply some patches.
			if ( !patchedExtension || ![ 'liquid', 'material' ].includes( patchedExtension ) ) {
				continue;
			}

			var dataToPatch = this.knownAssets.get( filename.replace( /\.patch$/, '' ) );
			if ( !dataToPatch ) {
				continue;
			}

			for ( let instruction of data ) {
				if ( instruction.op !== 'add' && instruction.op !== 'replace' ) {
					continue;
				}

				if ( instruction.path === '/interactions/-' ) {
					if ( !dataToPatch.interactions ) {
						dataToPatch.interactions = [];
					}
					dataToPatch.interactions.push( instruction.value );
				} else if ( instruction.path === '/liquidInteractions' ) {
					dataToPatch.liquidInteractions = instruction.value;
				} else if ( instruction.path === '/itemDrop' ) {
					dataToPatch.itemDrop = instruction.value;
				}
			}
		}
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

		// These vanilla materials can be placed by player (using a block item).
		this.readAllLines( [
			'data/vanilla_placeable_materials.txt'
		] ).forEach( ( materialIdAsString ) => {
			this.placeableMaterials.add( parseInt( materialIdAsString ) );
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

				// Catch typos like { inputs: { A: 1, B: 1 }, outputs: { A: 1 } } <-- should be: outputs: { A: 2 }
				var outputEntries = Object.entries( extractorRecipe.outputs ).map( ( arr ) => JSON.stringify( arr ) );
				for ( var inputEntry of Object.entries( extractorRecipe.inputs ) ) {
					if ( outputEntries.includes( JSON.stringify( inputEntry ) ) ) {
						this.fail( extractionsFilename, 'Extraction has the same item in inputs and outputs: ', extractorRecipe );
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

	/**
	 * Check that all in-world mixings are possible in Liquid Mixer.
	 */
	checkLiquidInteractions() {
		// These liquids don't need to be in sync with Liquid Mixer recipes.
		var nonPlaceableLiquids = new Set( [
			8, // corelava
			62, // hydrogen,
			63, // funitrogengas
			64, // poisongas
			65, // fuquicksand
			66, // metallichydrogen
			69 // sludge
		] );

		// Load recipes of Liquid Mixer.
		var mixerInteractions = new Map();
		this.knownAssets.get( 'objects/power/fu_liquidmixer/fu_liquidmixer_recipes.config' ).forEach( ( mixing ) => {
			let interactionId = Object.keys( mixing.inputs ).sort().join( '+' );
			mixerInteractions.set( interactionId, Object.keys( mixing.outputs )[0] );
		} );

		var interactionsToCheck = [];

		// Check liquids.
		for ( let liquid of this.knownLiquids.values() ) {
			( liquid.interactions || [] ).forEach( ( interaction ) => {
				interactionsToCheck.push( {
					firstLiquid: liquid.liquidId,
					secondLiquid: interaction.liquid,
					resultLiquid: interaction.liquidResult,
					resultMaterialName: interaction.materialResult,
					filename: liquid.sourceFilename
				} );
			} );
		}

		// Check materials.
		for ( let material of this.knownMaterials.values() ) {
			( material.liquidInteractions || [] ).forEach( ( interaction ) => {
				interactionsToCheck.push( {
					firstLiquid: interaction.liquidId,
					material: material.materialId,
					resultMaterial: interaction.transformMaterialId,
					filename: material.sourceFilename
				} );
			} );
		}

		// { "itemCode1+itemCode2": Set { possibleOutputItem1, possibleOutputItem2, ... }, ... }
		var seenInWorldInteractions = new Map();

		// [ 'string1_to_add_to_mixer_recipes', 'string2_to_add', ... ]
		var recommendedMixerRecipesToAdd = new Set();

		interactionsToCheck.forEach( ( interaction ) => {
			if ( interaction.resultLiquid === 0 ) {
				// Unnecessary recipes "<something> + Core Lava = 0 (nothing)", can be ignored.
				return;
			}

			let inputItems = [],
				filename = interaction.filename;

			let liquid = this.knownLiquids.get( interaction.firstLiquid );
			if ( !liquid ) {
				this.fail( filename, 'Unknown liquid in interaction: ' + interaction.firstLiquid );
				return;
			}
			inputItems.push( liquid.itemDrop );

			let secondIngredient =
				( interaction.secondLiquid && this.knownLiquids.get( interaction.secondLiquid ) ) ||
				( interaction.material && this.knownMaterials.get( interaction.material ) );
			if ( !secondIngredient ) {
				this.fail( filename, 'Unknown second ingredient in interaction: ', interaction );
				return;
			}
			inputItems.push( secondIngredient.itemDrop );

			let resultMaterial = ( interaction.resultMaterial && this.knownMaterials.get( interaction.resultMaterial ) ) ||
				( interaction.resultMaterialName && this.knownMaterialsByName.get( interaction.resultMaterialName ) );
			let result = resultMaterial || ( interaction.resultLiquid && this.knownLiquids.get( interaction.resultLiquid ) );
			if ( !result ) {
				this.fail( filename, 'Unknown result in interaction: ', interaction );
				return;
			}

			let outputItem = result.itemDrop;
			if ( !inputItems[0] || !inputItems[1] || !outputItem ) {
				// Some of the liquids/materials drop nothing when mined.
				return;
			}

			if ( resultMaterial && inputItems.includes( outputItem ) ) {
				// This is of the cosmetic interactions like "jellystone -> fublueslimestone",
				// where the resulting material yields the same item as the input material.
				// This is not usable in Liquid Mixer (which is for changing item and/or quantity of liquid).
				return;
			}

			if ( nonPlaceableLiquids.has( interaction.firstLiquid ) ||
				nonPlaceableLiquids.has( interaction.secondLiquid )
			) {
				// Liquids that can't be placed by player (Quicksand, Sludge, etc.) are rarely available and
				// are not usable in automation, so they don't need to be in sync with Liquid Mixer recipes.
				return;
			}

			if ( secondIngredient.materialId && !this.placeableMaterials.has( secondIngredient.materialId ) ) {
				// Mixing requires a non-placeable material as input, ignoring.
				return;
			}

			let interactionId = inputItems.sort().join( '+' );
			let mixerOutputItem = mixerInteractions.get( interactionId );
			if ( !mixerOutputItem ) {
				// In-world interaction exists, but we are missing Liquid Mixer recipe.
				// For convenience, form a JSON line ready for copy-pasting into [fu_liquidmixer_recipes.config].
				recommendedMixerRecipesToAdd.add( JSON.stringify( {
					inputs: {
						[inputItems[0]]: 1,
						[inputItems[1]]: 1
					},
					outputs: {
						[outputItem]: interaction.resultLiquid ? 2 : 1
					}
				} ) );

				this.fail( filename, 'Liquid interaction is only possible in-world, not in Mixer: ' +
					interactionId + '=' + outputItem );
			} else if ( mixerOutputItem !== outputItem ) {
				// We tolerate Lava+Oil inconsistency, because it's a vanilla mixing,
				// and we probably shouldn't patch array entries like "/interactions/1" without a better reason.
				if ( interactionId !== 'liquidlava+liquidoil' ) {
					this.fail( filename, 'Liquid interaction inconsistency: ' + interactionId +
						': in-world: ' + outputItem + ', in Mixer: ' + mixerOutputItem );
				}
			}

			// Remember this in-world interaction. Used later to detect "A+B=C, B+A=D, C!=D" inconsistencies.
			var alternateOutputs = seenInWorldInteractions.get( interactionId );
			if ( !alternateOutputs ) {
				alternateOutputs = {};
				seenInWorldInteractions.set( interactionId, alternateOutputs );
			}
			alternateOutputs[filename] = outputItem;
		} );

		for ( let [ interactionId, possibleOutputs ] of seenInWorldInteractions ) {
			let differentOutputs = new Set( Object.values( possibleOutputs ) );
			if ( differentOutputs.size > 1 ) {
				this.fail( 'Inconsistent in-world mixing: ' + interactionId +
					' may result in: ' + JSON.stringify( possibleOutputs ) );
			}
		}

		if ( recommendedMixerRecipesToAdd.size > 0 ) {
			console.log( 'Recommendation: you might want to add these recipes to Liquid Mixer:\n\t' +
				[...recommendedMixerRecipesToAdd].sort().join( ',\n\t' ) );
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
