require "/scripts/set.lua"
require "/scripts/quest/location.lua"

QuestRelations = {}

local Item = QuestPredicands.Item
local ItemTag = QuestPredicands.ItemTag
local ItemList = QuestPredicands.ItemList
local Recipe = QuestPredicands.Recipe
local Player = QuestPredicands.Player
local NullEntity = QuestPredicands.NullEntity
local Entity = QuestPredicands.Entity
local UnbornNpc = QuestPredicands.UnbornNpc
local TemporaryNpc = QuestPredicands.TemporaryNpc
local TagSet = QuestPredicands.TagSet
local NpcType = QuestPredicands.NpcType

QuestRelations.entityExists = defineQueryRelation("entityExists", true) {
	[case(0, Entity)] = function (self, entity)
			if not self.negated then
				return {{entity}}
			end
			return Relation.empty
		end,

	[case(0, Nil)] = Relation.some,

	default = function (self, nonEntity)
			if self.negated then
				return {{nonEntity}}
			end
			return Relation.empty
		end
}

QuestRelations.owns = defineQueryRelation("owns") {
	[case(0, Player, NonNil, 0)] = function (self, owner, item)
			if self.negated then return Relation.empty end
			return {self.predicands}
		end,

	-- Always assume the player has nothing so that the necessary quests to
	-- fetch quest-related items are generated.
	[case(1, Player, Any, Any)] = Relation.empty,

	[case(2, Entity, Item, NonNil)] = function (self, deed, item, count)
			local objects = deed:callScript("getOwnedObjectNames") or {}
			if xor(self.negated, (objects[item.itemName] or 0) == count) then
				return {{deed, item, count}}
			end
			return Relation.empty
		end,

	[case(3, Entity, Item, Nil)] = function (self, deed, item)
			if self.negated then return Relation.some end
			local objects = deed:callScript("getOwnedObjectNames") or {}
			return {{deed, item, objects[item.itemName] or 0}}
		end,

	[case(4, Entity, Nil, Nil)] = function (self, deed)
			if self.negated then return Relation.some end
			local objects = deed:callScript("getOwnedObjectNames") or {}
			local results = {}
			for objectName, count in pairs(objects) do
				results[#results+1] = {deed, Item.new(objectName), count}
			end
			return results
		end,

	[case(5, Nil, Item, NonNil)] = function (self, _, object, count)
			if self.negated then return Relation.some end
			local results = {}
			local deeds = self.context:deedsOwningObject(object.itemName)
			for deed, objectCount in pairs(deeds) do
				if count == objectCount then
					results[#results+1] = {deed, Item.new(object.itemName), count}
				end
			end
			return results
		end,

	[case(6, Nil, Item, Nil)] = function (self, _, object, _)
			if self.negated then return Relation.some end
			local results = {}
			local deeds = self.context:deedsOwningObject(object.itemName)
			if not deeds then return results end
			for deed, objectCount in pairs(deeds) do
				results[#results+1] = {deed, Item.new(object.itemName), objectCount}
			end
			return results
		end,

	[case(7, Nil, ItemTag, Any)] = Relation.empty,

	default = Relation.some
}

QuestRelations.getStealableObjectEntity = defineQueryRelation("getStealableObjectEntity", true) {
	[case(1, Entity, Item, Entity)] = function (self, deed, item, object)
			local objectIds = deed:callScript("getStealableObjects") or {}
			local owned = false
			for _,objectId in ipairs(objectIds) do
				if object:entityId() == objectId then
					owned = true
					break
				end
			end
			if xor(self.negated, owned and object:entityName() == item.itemName) then
				return {{deed, item, object}}
			end
			return Relation.empty
		end,

	[case(2, Entity, Item, Nil)] = function (self, deed, item)
			local objectIds = deed:callScript("getStealableObjects") or {}
			local results = {}
			for _,objectId in ipairs(objectIds) do
				if xor(self.negated, world.entityName(objectId) == item.itemName) then
					results[#results+1] = {deed, item, self.context:entity(objectId)}
				end
			end
			return results
		end,

	default = Relation.some
}

QuestRelations.npcHasFurniture = defineQueryRelation("npcHasFurniture", true) {
	[case(1, Entity, Item)] = function (self, npc, item)
			local deed = nil
			if npc:uniqueId() then
				deed = self.context:parentDeeds()[npc:uniqueId()]
			end
			if not deed then
				if self.negated then
					return {{npc, item}}
				else
					return Relation.empty
				end
			end
			local objects = deed:callScript("getOwnedObjectNames") or {}
			if xor(self.negated, (objects[item.itemName] or 0) > 0) then
				return {{npc, item}}
			end
			return Relation.empty
		end,
	[case(2, Entity, Nil)] = Relation.some,
	[case(3, Nil, Item)] = Relation.some,
	[case(4, Nil, Nil)] = Relation.some,
	default = Relation.empty
}

local function predominantTags(context, npc)
	local deed = nil
	if npc:uniqueId() then
		deed = context:parentDeeds()[npc:uniqueId()]
	end
	local tags = {npc:entitySpecies()}
	if deed then
		util.appendLists(tags, deed:callScript("getPredominantTags", 3) or {})
	end
	return tags
end

QuestRelations.predominantTag = defineQueryRelation("predominantTag", true) {
	[case(1, Entity, NonNil)] = function (self, npc, tag)
			local tags = predominantTags(self.context, npc)
			if xor(self.negated, contains(tags, tag)) then
				return {{npc, tag}}
			end
			return Relation.empty
		end,

	[case(2, Entity, Nil)] = function (self, npc)
			if self.negated then return Relation.some end
			local tags = predominantTags(self.context, npc)
			return util.map(tags, function (tag)
					return {npc, tag}
				end)
		end,

	default = Relation.some
}

QuestRelations.hasTenant = defineQueryRelation("hasTenant", true) {
	[case(1, Entity, Entity)] = function (self, deed, tenant)
			local deedTenants = deed:callScript("getTenants") or {}
			for _,deedTenant in pairs(deedTenants) do
				if deedTenant.uniqueId == tenant:uniqueId() then
					return {{deed, tenant}}
				end
			end
			return Relation.empty
		end,

	[case(2, Entity, Nil)] = function (self, deed)
			local deedTenants = deed:callScript("getTenants") or {}
			local results = {}
			for _,deedTenant in pairs(deedTenants) do
				results[#results+1] = {deed, self.context:entity(deedTenant.uniqueId)}
			end
			return results
		end,

	[case(3, Nil, Entity)] = function (self, _, tenant)
			if not tenant:uniqueId() then return Relation.empty end
			local parentDeed = self.context:parentDeeds()[tenant:uniqueId()]
			if not parentDeed then return Relation.empty end
			return {{parentDeed, tenant}}
		end,

	[case(4, Nil, Nil)] = Relation.some,

	default = Relation.empty
}

QuestRelations.monsterTenants = defineQueryRelation("monsterTenants", true) {
	[case(1, Entity, NonNil)] = function (self, deed, count)
			if xor(self.negated, deed:callScript("countMonsterTenants") == count) then
				return {{deed, count}}
			end
			return Relation.empty
		end,

	[case(2, Entity, Nil)] = function (self, deed, count)
			if self.negated then return Relation.some end
			local count = deed:callScript("countMonsterTenants")
			if count then
				return {{deed, count}}
			end
			return Relation.empty
		end,

	[case(3, Nil, Any)] = Relation.some,

	default = Relation.empty
}

local function optionalDeed(context, tenant)
	if not tenant:uniqueId() then
		return nil
	end
	return context:parentDeeds()[tenant:uniqueId()]
end

QuestRelations.optionalDeed = defineQueryRelation("optionalDeed", true) {
	[case(1, Entity, NullEntity)] = function (self, tenant, deed)
			local actualDeed = optionalDeed(self.context, tenant)
			if xor(self.negated, not actualDeed) then
				return {{tenant, NullEntity.new()}}
			end
			return Relation.empty
		end,

	[case(2, Entity, Entity)] = function (self, tenant, deed)
			local actualDeed = optionalDeed(self.context, tenant)
			if xor(self.negated, deed == actualDeed) then
				return {{tenant, deed}}
			end
			return Relation.empty
		end,

	[case(3, Entity, Nil)] = function (self, tenant)
			if self.negated then return Relation.some end
			local actualDeed = optionalDeed(self.context, tenant)
			if actualDeed then
				return {{tenant, actualDeed}}
			else
				return {{tenant, NullEntity.new()}}
			end
		end,

	default = Relation.some
}

local function npcStateDeltaMethod(func)
	return function (self)
		assert(self:isGround())
		local arguments = util.map(self.predicands, Predicand.value)
		local cancel = false
		for _,argument in ipairs(arguments) do
			match (argument) {
				[Entity] = function()
						assert(argument:uniqueId())
					end,
				[UnbornNpc] = function()
						cancel = true
					end,
				default = function() end
			}
		end
		if cancel then return {} end
		return func(self, table.unpack(arguments))
	end
end

local NpcRelationship = defineSubclass(Relation, "NpcRelationship") {
	query = Relation.unpackedQuery {
			[case(1, UnbornNpc, Any)] = function (self, npc, otherNpc)
					if self.negated then
						if otherNpc and otherNpc ~= Nil then
							return {{npc, otherNpc}}
						else
							return util.map(self.context:entitiesByType()["npc"], function (otherNpc)
									return {npc, otherNpc}
								end)
						end
					end
					return Relation.empty
				end,

			[case(2, Any, UnbornNpc)] = function (self, npc, otherNpc)
					if self.negated then
						if npc and npc ~= Nil then
							return {{npc, otherNpc}}
						else
							return util.map(self.context:entitiesByType()["npc"], function (npc)
									return {npc, otherNpc}
								end)
						end
					end
					return Relation.empty
				end,

			[case(3, Entity, Entity)] = function (self, npc, otherNpc)
					if xor(self.negated, npc:hasRelationship(self.name, false, otherNpc)) then
						return {{npc, otherNpc}}
					end
					return Relation.empty
				end,

			[case(4, Entity, Nil)] = function (self, npc)
					local otherNpcs = self.context:queryNpcRelationships(self.name, false, self.negated, npc)
					return util.map(otherNpcs, function (otherNpc)
							return {npc, otherNpc}
						end)
				end,

			[case(5, Nil, Entity)] = function (self, _, otherNpc)
					local npcs = self.context:queryNpcRelationships(self.name, true, self.negated, otherNpc)
					return util.map(npcs, function (npc)
							return {npc, otherNpc}
						end)
				end,

			[case(6, Nil, Nil)] = function (self)
					if self.negated then return Relation.some end
					local npcs = util.take(5, self.context:entitiesByType()["npc"])
					local results = {}
					for _,npc in pairs(npcs) do
						for uniqueId,_ in pairs(npc:callScript("getRelationships", self.name, false)) do
							results[#results+1] = {npc, self.context:entity(uniqueId)}
						end
						for uniqueId,_ in pairs(npc:callScript("getRelationships", self.name, true)) do
							results[#results+1] = {self.context:entity(uniqueId), npc}
						end
					end
					return results
				end,

			default = Relation.empty
		},

	implications = function (self)
			if self.negated or not self.opposite then return Conjunction.new() end
			return Conjunction.new({self.opposite().new(true, self.predicands, self.context)})
		end,
	contradicts = function (self, condition)
			if self.negated or not self.opposite then return false end
			return condition:containsTerm(self.opposite().new(false, self.predicands, self.context))
		end,
	npcStateDeltas = npcStateDeltaMethod(function (self, npc1, npc2)
			local deltaType = "addRelationship"
			if self.negated then
				deltaType = "removeRelationship"
			end
			return {
					[npc1:uniqueId()] = {
							type = deltaType,
							arguments = {self.name, false, npc2:uniqueId()}
						},
					[npc2:uniqueId()] = {
							type = deltaType,
							arguments = {self.name, true, npc1:uniqueId()}
						}
				}
		end)
}

QuestRelations.criminal = defineRelation("criminal", true) {
	query = Relation.unpackedQuery {
			[case(1, Entity)] = function (self, entity)
					if xor(self.negated, entity:callScript("isCriminal")) then
						return {{entity}}
					else
						return Relation.empty
					end
				end,

			[case(2, Nil)] = function (self)
					local criminals = util.filter(self.context:entitiesByType()["npc"], function (npc)
							return xor(self.negated, npc:callScript("isCriminal"))
						end)
					return util.map(criminals, function (npc)
							return {npc}
						end)
				end,

			default = Relation.empty
		},
	npcStateDeltas = npcStateDeltaMethod(function (self, npc)
			return {
					[npc:uniqueId()] = {
							type = "setCriminal",
							arguments = {not self.negated}
						}
				}
		end)
}

QuestRelations.stolen = defineRelation("stolen", false) {
	query = Relation.unpackedQuery {
			[case(1, Entity, Entity, Item)] = function (self, victim, thief, item)
					if not thief:uniqueId() then
						if self.negated then
							return {victim, thief, item}
						else
							return Relation.empty
						end
					end
					if xor(self.negated, victim:callScript("isStolen", thief:uniqueId(), item.itemName)) then
						return {{victim, thief, item}}
					end
					return Relation.empty
				end,

			[case(2, Entity, Entity, Nil)] = function (self, victim, thief)
					if self.negated then return Relation.some end
					if not thief:uniqueId() then
						return Relation.empty
					end
					local items = victim:callScript("getStolenItemsForThief", thief:uniqueId())
					return util.map(items, function(itemName)
							return {victim, thief, Item.new(itemName)}
						end)
				end,

			[case(3, Entity, Nil, Item)] = function (self, victim, _, item)
					if self.negated then return Relation.some end
					local thieves = victim:callScript("getThievesForStolenItem", item.itemName)
					return util.map(thieves, function(thief)
							return {victim, self.context:entity(thief), item}
						end)
				end,

			[case(4, Entity, Nil, Nil)] = function (self, victim)
					if self.negated then return Relation.some end
					local stolenItems = victim:callScript("getStolenItems")
					local result = {}
					for _, itemName in pairs(stolenItems) do
						local item = Item.new(itemName)
						for _, thief in pairs(victim:callScript("getThievesForStolenItem", itemName)) do
							result[#result+1] = {victim, self.context:entity(thief), item}
						end
					end
					return result
				end,

			[case(5, Nil, Entity, Item)] = function (self, _, thief, item)
					if self.negated then return Relation.some end
					local result = {}
					for _,victim in ipairs(util.take(5, shuffled(self.context:entitiesByType()["npc"]))) do
						if contains(victim:callScript("getThievesForStolenItem", item.itemName), thief:uniqueId()) then
							result[#result+1] = {victim, thief, item}
						end
					end
					return result
				end,

			[case(6, Nil, Entity, Nil)] = function (self, _, thief)
					if self.negated then return Relation.some end
					if not thief:uniqueId() then return Relation.empty end
					local result = {}
					for _,victim in ipairs(util.take(5, shuffled(self.context:entitiesByType()["npc"]))) do
						for _, itemName in pairs(victim:callScript("getStolenItemsForThief", thief:uniqueId())) do
							result[#result+1] = {victim, thief, Item.new(itemName)}
						end
					end
					return result
				end,

			[case(7, Nil, Nil, Item)] = function (self, _, _, item)
					if self.negated then return Relation.some end
					local result = {}
					for _,victim in ipairs(util.take(5, shuffled(self.context:entitiesByType()["npc"]))) do
						for _, thiefUniqueId in pairs(victim:callScript("getThievesForStolenItem", item.itemName)) do
							result[#result+1] = {victim, self.context:entity(thiefUniqueId), item}
						end
					end
					return result
				end,

			[case(8, Nil, Nil, Nil)] = function (self)
					if self.negated then return Relation.some end
					local result = {}
					for _,victim in ipairs(util.take(5, shuffled(self.context:entitiesByType()["npc"]))) do
						for _, itemName in pairs(victim:callScript("getStolenItems")) do
							local item = Item.new(itemName)
							for _, thief in pairs(victim:callScript("getThievesForStolenItem", itemName)) do
								result[#result+1] = {victim, self.context:entity(thief), item}
							end
						end
					end
					return result
				end,

			default = Relation.empty
		},

	npcStateDeltas = npcStateDeltaMethod(function (self, npc, thief, item)
			local thiefUniqueId = thief:uniqueId()
			local deltaName = "setStolen"
			if self.negated then
				deltaName = "unsetStolen"
			end
			return {
					[npc:uniqueId()] = {
							type = deltaName,
							arguments = {thiefUniqueId, item.itemName}
						}
				}
		end)
}

QuestRelations.isStolen = createRelation("isStolen", false)

QuestRelations.likes = defineRelation("likes", false, NpcRelationship) {
	opposite = function() return QuestRelations.fears end
}

QuestRelations.fears = defineRelation("fears", false, NpcRelationship) {
	opposite = function () return QuestRelations.likes end,
	implications = function (self)
			if self.negated then return Conjunction.new() end
			return Conjunction.new({
					QuestRelations.likes.new(true, self.predicands, self.context)
				})
		end
}

QuestRelations.at = createRelation("at")

QuestRelations.isNpc = defineQueryRelation("isNpc", true) {
	[case(1, Entity)] = function (self, entity)
			if xor(self.negated, entity:entityType() == "npc") then
				return {{entity}}
			else
				return Relation.empty
			end
		end,

	[case(2, Nil)] = function (self)
			if self.negated then return Relation.some end
			return util.map(self.context:entitiesByType()["npc"], function (npc)
					return {npc}
				end)
		end,

	default = Relation.empty
}

QuestRelations.temporaryNpc = defineQueryRelation("temporaryNpc", true) {
	[case(1, TemporaryNpc, NonNil, NonNil, QuestPredicands.Location)] = function (self, npc, species, typeName, spawnLocation)
			if xor(self.negated, npc.species == species and npc.typeName == typeName) then
				return {{npc, species, typeName, spawnLocation}}
			end
			return Relation.empty
		end,

	[case(2, Nil, NonNil, NonNil, QuestPredicands.Location)] = function (self, _, species, typeName, spawnLocation)
			if self.negated then return Relation.some end
			return {{TemporaryNpc.new(species, typeName, spawnLocation.region), species, typeName, spawnLocation}}
		end,

	default = Relation.some
}

QuestRelations.species = defineQueryRelation("species", true) {
	[case(1, Entity, NonNil)] = function (self, entity, species)
			if xor(self.negated, entity:entitySpecies() == species) then
				return {{entity, species}}
			end
			return Relation.empty
		end,

	[case(2, Entity, Nil)] = function (self, entity)
			if self.negated then return Relation.some end
			return {{entity, entity:entitySpecies()}}
		end,

	default = Relation.some
}

QuestRelations.npcType = defineQueryRelation("npcType", true) {
	[case(1, Nil, NonNil, NonNil, NonNil, NonNil)] = function (self, _, name, species, typeName, parameters)
			if self.negated then return Relation.some end
			return {{NpcType.new({
					name = name,
					species = species,
					typeName = typeName,
					parameters = parameters
				}), name, species, typeName, parameters}}
		end,

	[case(2, NpcType, Any, Any, Any, Any)] = function (self, npcType)
			if self.negated then return Relation.some end
			return {{npcType, npcType.name, npcType.species, npcType.typeName, npcType.parameters}}
		end,

	[case(3, Nil, Any, Any, Any, Any)] = Relation.some,

	default = Relation.empty
}

QuestRelations.seededNpcType = defineQueryRelation("seededNpcType", true) {
	[case(1, Nil, NonNil, NonNil, NonNil)] = function (self, _, species, typeName, parameters)
			if self.negated then return Relation.some end
			return {{NpcType.new({
					species = species,
					typeName = typeName,
					parameters = parameters,
					seed = generateSeed()
				}), species, typeName, parameters}}
		end,

	[case(2, NpcType, Any, Any, Any)] = function (self, npcType)
			if self.negated then return Relation.some end
			return {{npcType, npcType.species, npcType.typeName, npcType.parameters}}
		end,

	[case(3, Nil, Any, Any, Any, Any)] = Relation.some,

	default = Relation.empty
}

QuestRelations.npcQuestGenFlag = defineQueryRelation("npcQuestGenFlag", true) {
	[case(1, Entity, NonNil)] = function (self, npc, flagName)
			local configPath = "questGenerator.flags."..flagName
			if xor(self.negated, npc:callScript("config.getParameter", configPath)) then
				return {{npc, flagName}}
			end
			return Relation.empty
		end,
	[case(2, Nil, NonNil)] = Relation.some,
	default = Relation.empty
}

local function countNpcsWithFlag(context, flag)
	return #util.filter(context:entitiesByType()["npc"], function (npc)
			return npc:callScript("config.getParameter", "questGenerator.flags.guard")
		end)
end

QuestRelations.countNpcsWithFlag = defineQueryRelation("countNpcsWithFlag", true) {
	[case(1, NonNil, NonNil)] = function (self, flag, count)
			if xor(self.negated, countNpcsWithFlag(self.context, flag) == count) then
				return {{flag, count}}
			end
			return Relation.empty
		end,

	[case(2, NonNil, Nil)] = function (self, flag)
			if self.negated then return Relation.some end
			return {{flag, countNpcsWithFlag(self.context, flag)}}
		end,

	default = Relation.empty
}

QuestRelations.itemName = defineQueryRelation("itemName", true) {
	[case(1, Item, Nil)] = function (self, item)
			if self.negated then return Relation.some end
			return {{item, item.itemName}}
		end,

	[case(2, Nil, NonNil)] = function (self, _, itemName)
			if type(itemName) ~= "string" then return Relation.empty end
			if self.negated then return Relation.some end
			return {{Item.new(itemName), itemName}}
		end,

	[case(3, Item, NonNil)] = function (self, item, itemName)
			if xor(self.negated, itemName == item.itemName) then
				return {item, itemName}
			end
			return Relation.empty
		end,

	[case(4, Nil, Nil)] = Relation.some,

	default = Relation.empty
}

QuestRelations.isObject = defineQueryRelation("isObject", true) {
	[case(1, Item)] = function (self, item)
			if xor(self.negated, item:type() == "object") then
				return {{item}}
			end
			return Relation.empty
		end,
	[case(2, Nil)] = Relation.some,
	default = Relation.empty
}

QuestRelations.isObjectTagged = defineQueryRelation("isObjectTagged", true) {
	[case(1, Item, NonNil)] = function (self, item, tag)
			if xor(self.negated, contains(item:objectTags(), tag)) then
				return {{item, tag}}
			end
			return Relation.empty
		end,
	default = Relation.some
}

local function objectExists(context, objectItem)
	if #(context:deedsOwningObject(objectItem.itemName)) > 0 then
		return true
	end
	for _,objectEntity in ipairs(context:entitiesByName()[objectItem.itemName] or {}) do
		if objectEntity:entityType() == "object" then
			return true
		end
	end
	return false
end

QuestRelations.objectExists = defineQueryRelation("objectExists", true) {
	[case(1, Item)] = function (self, objectItem)
			if xor(self.negated, objectExists(self.context, objectItem)) then
				return {{objectItem}}
			end
			return Relation.empty
		end,

	[case(2, Nil)] = function (self)
			return util.map(self.context:entitiesByType()["object"] or {}, function (object)
					return {object}
				end)
		end,

	default = Relation.empty
}

local function getRecipes(item)
	local recipes = util.map(root.recipesForItem(item.itemName), QuestPredicands.Recipe.new)
	recipes=util.filter(recipes, function (recipe) return #recipe.inputs > 0 end)
	local buffer={}
	for _,recipe in pairs(recipes) do
		local pass=true
		for group,_ in pairs(recipe.groups) do
			if group=="excludeFromQuests" then
				pass=false
				break
			end
		end
		if pass then
			table.insert(buffer,recipe)
		end
	end
	--recipes=buffer--util.filter(recipes, function (recipe) return not contains(recipe.groups,"excludeFromQuests") end)
	return buffer
end

local function recipeExists(recipe, item)
	local recipes = getRecipes(item)
	for _,r in ipairs(recipes) do
		if r:equals(recipe) then
			return true
		end
	end
	return false
end

QuestRelations.isRecipe = defineQueryRelation("isRecipe", true) {
	[case(1, Recipe, Item)] = function (self, recipe, item)
			if xor(self.negated, recipeExists(recipe, item)) then
				return {{recipe, item}}
			end
			return Relation.empty
		end,

	[case(2, Nil, Item)] = function (self, _, item)
			if self.negated then return Relation.some end
			local recipes = getRecipes(item)
			return util.map(recipes, function (recipe)
					return {recipe, item}
				end)
		end,

	[case(3, Recipe, Nil)] = Relation.some,
	[case(4, Nil, Nil)] = Relation.some,
	default = Relation.empty
}

QuestRelations.recipeHasGroup = defineQueryRelation("recipeHasGroup", true) {
	[case(1, Recipe, NonNil)] = function (self, recipe, groupName)
			if xor(self.negated, recipe:hasGroup(groupName)) then
				return {{recipe, groupName}}
			end
			return Relation.empty
		end,
	default = Relation.some
}

local function getRecipeIngredients(recipe, craftTimes)
	local itemList = ItemList.new()
	for _,itemDescriptor in ipairs(recipe.inputs) do
		itemList:add(itemDescriptor, craftTimes)
	end
	return itemList
end

QuestRelations.recipeIngredients = defineQueryRelation("recipeIngredients", true) {
	[case(1, Recipe, ItemList, NonNil)] = function (self, recipe, ingredients, craftTimes)
			if xor(self.negated, ingredients:equals(getRecipeIngredients(recipe, craftTimes))) then
				return {{recipe, ingredients, craftTimes}}
			end
			return Relation.empty
		end,

	[case(2, Recipe, Nil, NonNil)] = function (self, recipe, _, craftTimes)
			if self.negated then return Relation.some end
			local ingredients = getRecipeIngredients(recipe, craftTimes)
			return {{recipe, ingredients, craftTimes}}
		end,

	default = Relation.some
}

QuestRelations.ownsItemList = defineRelation("ownsItemList") {
	satisfiable = function (self)
			return true
		end,

	implications = function (self)
			return self:unpackPredicands {
				[case(0, Player, ItemList, Any)] = function (self, owner, itemList, vars)
						local terms = {}

						if vars == nil or vars == Nil then
							vars = PrintableTable.new({ old = PrintableTable.new(), new = PrintableTable.new() })
							self.predicands[3]:bindToValue(vars)
						end

						function variable(table, itemName)
							if not table[itemName] then
								table[itemName] = self.context.planner:newVariable(itemName)
							end
							return table[itemName]
						end

						function addTerm(term)
							if term.static then
								term:applyConstraints()
							end
							terms[#terms+1] = term
						end

						if not self.negated then
							-- We're in the preconditions.
							-- Create a variable for the counts of each item we
							-- currently have that is at least the amount needed by the
							-- itemList. The variable used is stashed in the magic 3rd predicand
							-- so that the variables can be referenced again in the postconds.
							--
							-- For each item, the implications are:
							--	owns(owner, item, oldCount)
							--	>=(oldCount, amountNeeded)
							--	+(newCount, amountNeeded, oldCount)
							for _,item in pairs(itemList:descriptors()) do
								local oldCount = variable(vars.old, item.name)
								local newCount = variable(vars.new, item.name)
								addTerm(QuestRelations.owns.new(false, {owner, Item.new(item), oldCount}, self.context))
								addTerm(BuiltinRelations[">="].new(false, {oldCount, item.count}, self.context))
								addTerm(BuiltinRelations["+"].new(false, {newCount, item.count, oldCount}, self.context))
							end
						else
							-- We're in the postconditions, and the items in the itemList are
							-- being removed:
							--	!owns(owner, item, oldCount)
							--	owns(owner, item, newCount)
							for _,item in pairs(itemList:descriptors()) do
								local oldCount = variable(vars.old, item.name)
								local newCount = variable(vars.new, item.name)
								addTerm(QuestRelations.owns.new(true, {owner, Item.new(item), oldCount}, self.context))
								addTerm(QuestRelations.owns.new(false, {owner, Item.new(item), newCount}, self.context))
							end

						end
						return Conjunction.new(terms)
					end,

				default = Conjunction.new()
			}
		end
}

QuestRelations.itemList = defineQueryRelation("itemList", true) {
	[case(1, ItemList, Item, NonNil)] = function (self, itemList, item, count)
			if xor(self.negated, itemList:contains(item:descriptor(count))) then
				return {{itemList, item, count}}
			end
			return Relation.empty
		end,

	[case(2, ItemList, Item, Nil)] = function (self, itemList, item)
			if self.negated then return Relation.some end
			return {{itemList, item, itemList:count(item:descriptor()) or 0}}
		end,

	[case(3, ItemList, Nil, Nil)] = function (self, itemList)
			if self.negated then return Relation.some end
			local results = {}
			for _,item in pairs(itemList:descriptors()) do
				results[#results+1] = {itemList, Item.new(item), item.count}
			end
			return results
		end,

	[case(4, Nil, Item, NonNil)] = function (self, _, item, count)
			if self.negated then return Relation.some end
			return {{ItemList.new({item:descriptor(count)}), item, count}}
		end,

	default = Relation.some
}

QuestRelations.unbornNpc = defineQueryRelation("unbornNpc", true) {
	[case(1, UnbornNpc)] = function (self, npc)
			if self.negated then return Relation.empty end
			return {{npc}}
		end,
	[case(2, Nil)] = function (self)
			if self.negated then return Relation.some end
			return {{UnbornNpc.new()}}
		end,
	default = Relation.empty
}

QuestRelations.price = defineQueryRelation("price", true) {
	[case(1, Item, NonNil)] = function (self, item, price)
			if xor(self.negated, price == item:price()) then
				return {{item, price}}
			end
			return Relation.empty
		end,

	[case(2, ItemList, NonNil)] = function (self, itemList, price)
			if xor(self.negated, price == itemList:price()) then
				return {{itemList, price}}
			end
			return Relation.empty
		end,

	[case(3, Item, Nil)] = function (self, item)
			if self.negated then return Relation.some end
			return {{item, item:price()}}
		end,

	[case(4, ItemList, Nil)] = function (self, itemList)
			if self.negated then return Relation.some end
			return {{itemList, itemList:price()}}
		end,

	[case(5, Nil, Any)] = Relation.some,

	default = Relation.empty
}

QuestRelations.countExtraMerchantItems = defineQueryRelation("countExtraMerchantItems", true) {
	[case(1, Entity, NonNil)] = function (self, merchant, count)
			if xor(self.negated, (merchant:callScript("countExtraMerchantItems") or 0) == count) then
				return {{merchant, count}}
			end
			return Relation.empty
		end,
	[case(2, Entity, Nil)] = function (self, merchant)
			if self.negated then return Relation.some end
			return {{merchant, merchant:callScript("countExtraMerchantItems") or 0}}
		end,
	[case(3, Nil, Any)] = Relation.some,
	default = Relation.empty
}

QuestRelations.sellsItem = defineQueryRelation("sellsItem", true) {
	[case(1, Entity, Item)] = function (self, merchant, item)
			if xor(self.negated, merchant:callScript("sellsItem", item.itemName)) then
				return {{merchant, item}}
			end
			return Relation.empty
		end,
	default = Relation.some
}

QuestRelations.tagSet = defineQueryRelation("tagSet", true) {
	[case(1, TagSet, NonNil)] = function (self, tagSet, tagsJson)
			if xor(self.negated, set.equals(tagSet.tags, set.new(tagsJson))) then
				return {{tagSet, tagsJson}}
			end
			return Relation.empty
		end,

	[case(2, Nil, NonNil)] = function (self, _, tagsJson)
			if self.negated then return Relation.some end
			return {{TagSet.new(tagsJson), tagsJson}}
		end,

	[case(3, TagSet, NonNil)] = function (self, tags)
			if self.negated then return Relation.some end
			return {{tags, tags:values()}}
		end,

	[case(4, Nil, Nil)] = Relation.some,

	default = Relation.empty
}

QuestRelations.findLocation = defineQueryRelation("findLocation", true) {
	[case(1, QuestPredicands.Location, TagSet, NonNil, NonNil)] = function (self, location, tags, minDistance, maxDistance)
			local locationPos = rect.center(location.region)
			local distance = world.magnitude(locationPos, entity.position())
			local inRange = maxDistance < 0 or distance <= maxDistance
			local tagsMatch = set.containsAll(set.new(location.tags), tags.tags)
			if xor(self.negated, tagsMatch and inRange) then
				return {{location, tags, minDistance, maxDistance}}
			end
			return Relation.empty
		end,

	[case(2, QuestPredicands.Location, Nil, NonNil, NonNil)] = function (self, location, tags, minDistance, maxDistance)
			if self.negated then return Relation.some end
			return {{location, TagSet.new(location.tags), minDistance, maxDistance}}
		end,

	[case(3, Nil, TagSet, NonNil, NonNil)] = function (self, _, tags, minDistance, maxDistance)
			if self.negated then return Relation.some end
			local range = maxDistance >= 0 and maxDistance or nil
			local results = util.map(Location.search(entity.position(), tags:values(), minDistance, range), function (location)
					return {
							QuestPredicands.Location.new(location.region, location.name, location.uniqueId, location.tags),
							tags,
							minDistance,
							maxDistance
						}
				end)
			return results
		end,

	[case(4, Nil, Nil, NonNil, NonNil)] = function (self, _, _, minDistance, maxDistance)
			if self.negated then return Relation.some end
			local range = maxDistance >= 0 and maxDistance or nil
			return util.map(Location.search(entity.position(), nil, minDistance, range), function (location)
					return {
							QuestPredicands.Location.new(location.region, location.name, location.uniqueId, location.tags),
							TagSet.new(location.tags),
							minDistance,
							maxDistance
						}
				end)
		end,

	default = Relation.empty
}

QuestRelations.tagSetContains = defineQueryRelation("tagSetContains", true) {
	[case(1, TagSet, NonNil)] = function (self, tags, tag)
			if xor(self.negated, set.contains(tags.tags, tag)) then
				return {{tags, tag}}
			end
			return Relation.empty
		end,
	default = Relation.some
}

QuestRelations.tagSubset = defineQueryRelation("tagSubset", true) {
	[case(1, TagSet, TagSet)] = function (self, tags1, tags2)
			if xor(self.negated, set.equals(set.intersection(tags1.tags, tags2.tags), tags2.tags)) then
				return {{tags1, tags2}}
			end
			return Relation.empty
		end,
	default = Relation.some
}

QuestRelations.itemSlotFilled = defineQueryRelation("itemSlotFilled", true) {
	[case(1, Entity, NonNil)] = function (self, npc, slotName)
			if xor(self.negated, npc:callScript("npc.getItemSlot", slotName) ~= nil) then
				return {{npc, slotName}}
			end
			return Relation.empty
		end,
	default = Relation.some
}

QuestRelations.chooseGift = defineRelation("chooseGift", true) {
	isGiftItem = function (self)
			local relation = self.context.planner.relations.isGiftItem
			return relation.new(self.negated, {self.predicands[2]}, self.context)
		end,
	isFurniture = function (self, tag)
			local furniturePredicands = {tag, self.predicands[2]}
			local relation = self.context.planner.relations.isFurniture
			return relation.new(self.negated, furniturePredicands, self.context)
		end,

	query = Relation.unpackedQuery {
		[case(1, Entity, Item)] = function (self, recipient, gift)
				if self:isGiftItem():satisfiable() then
					return {{recipient, gift}}
				end
				for _,tag in pairs(predominantTags(self.context, recipient)) do
					if self:isFurniture(tag):satisfiable() then
						return {{recipient, gift}}
					end
				end
				return Relation.empty
			end,

		[case(1, Entity, Nil)] = function (self, recipient)
				if math.random() < 0.5 then
					local results = {}
					for _,tag in pairs(predominantTags(self.context, recipient)) do
						local furnitureResults = self:isFurniture(tag):query()
						for _,furnitureRow in pairs(furnitureResults) do
							results[#results+1] = {recipient, furnitureRow[2]}
						end
					end
					if #results > 0 then
						return results
					end
				end

				local gifts = self:isGiftItem():query()
				return util.map(gifts, function (row)
						return {recipient, row[1]}
					end)
			end,

		default = Relation.some
	}
}

QuestRelations.commonItem = defineQueryRelation("commonItem", true) {
	[case(1, Item)] = function (self, item)
			local material = item:type() == "material" or item:type() == "liquid"
			local reagent = contains(item:itemTags(), "reagent")
			if xor(self.negated, material or reagent) then
				return {{item}}
			end
			return Relation.empty
		end,
	[case(2, Nil)] = Relation.some,
	default = Relation.empty
}
