require "/objects/generic/extractor_xeno_common.lua"

-- unit times for the extractor tech levels
function getTimer(techLevel)
	return ({ 0.75, 0.45, 0.1 })[techLevel]
end

-- Format:
--   inputs = list of item=quantity pairs
--   outputs = list of item=quantity pairs
--   timeScale = extraction time scaling value (default 1); may be a list as for quantity
--               e.g. { 1, 2, 4 } gives { 0.75 * 1, 0.45 * 2, 0.1 * 4 } = { 0.75, 0.9, 0.4 }, but generally a single value should be used
--   reversible = true if the conversion can be reversed
--
--   Each quantity is either a single number or a table containing a value for each extractor tech level
--   Order is basic (1), advanced (2), quantum (3)
--
--   Listing order is no guarantee of checking order
--   No checks are made for multi-input recipes being overridden by single-input recipes
function getRecipes()
	return root.assetJson('/objects/generic/extractionlab_recipes.config')
end
