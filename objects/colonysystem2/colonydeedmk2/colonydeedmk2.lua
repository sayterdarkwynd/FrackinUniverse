require "/scripts/quest/participant.lua"
require "/scripts/achievements.lua"
require "/scripts/util.lua"
require "/objects/spawner/colonydeed.lua"
local origChooseTenants = chooseTenants or function() end

function isRentDue()
	return false
end

function isOccupiedMk2()
	return storage.occupier ~= nil
end

function chooseTenants(seed, tags)
	for tag, needed in pairs (self.extraTagCriteria or {}) do
		if not tags[tag] or tags[tag] < needed then
			util.debugLog("Room does not have the necessary required extra tags")
			return
		end
	end
	origChooseTenants(seed, tags)
	if not isOccupiedMk2() then return end
	storage.occupier.colonyTagCriteria = getTagCriteria()
	for tag, needed in pairs (self.extraTagCriteria or {}) do
		storage.occupier.colonyTagCriteria[tag] = (storage.occupier.colonyTagCriteria[tag] or 0) + needed
	end
end