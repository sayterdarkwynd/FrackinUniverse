require "/objects/generic/extractor_xeno_common.lua"

-- unit times for the xeno lab tech levels
function getTimer(techLevel)
	return ({ 5.5, 1.2 , 1.2 })[techLevel]
end

-- Format:
--   inputs = list of item=quantity pairs
--   outputs = list of item=quantity pairs
--   timeScale = extraction time scaling value (default 1); may be a list as for quantity
--               e.g. { 1, 2 } gives { 5.5 * 1, 1.2 * 2 } = { 5.5, 2.4 }, but generally a single value should be used
--   reversible = true if the conversion can be reversed
--
--   Each quantity is either a single number or a table containing a value for each extractor tech level
--   Order is basic (1), advanced (2), super-advanced (3)
--
--   Listing order is no guarantee of checking order
--   No checks are made for multi-input recipes being overridden by single-input recipes
function getRecipes()
	return root.assetJson('/objects/generic/xenostation_recipes.config')
end
