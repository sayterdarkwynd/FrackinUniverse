local crewOverflowOldInit = init
local crewOverflowOldUpdate = update
local crewOverflowOldUninit = uninit
local Pet = Pet or {}

function init()
	crewOverflowOldInit()
	message.setHandler("returnStoredCompanions", function() return fuStoredCrew end)
	message.setHandler("dismissStoredCompanion", function(_, _, podUuid)
		for num, data in pairs (fuStoredCrew) do
			if data.podUuid == podUuid then
				table.remove(fuStoredCrew, num)
				status.setStatusProperty("fuStoredCrew", fuStoredCrew)
			end
		end
	end)
	message.setHandler("openCrewDeedInterface", function(_, _, args)
		if world.entityExists(args.objectId) and player.worldId() == player.ownShipWorldId() then
			player.interact("ShowPopup", {message = "Room is valid. Increasing max crew"}, args.objectId)
		else
			player.interact("ShowPopup", {message = args.notOwnShipMessage}, args.objectId)
		end
	end)

	recruitSpawner.crewLimit = function()
		if player.shipUpgrades().shipLevel == 0 then
			crewLimit = status.statusProperty("byosCrewSize", 0)
		else
			crewLimit = (player.shipUpgrades().crewSize or 0) + status.statusProperty("byosCrewSize", 0)
		end
		return crewLimit
	end

	fuStoredCrew = {}
	for _,value in pairs(status.statusProperty("fuStoredCrew", {})) do
		if value then
			fuStoredCrew[#fuStoredCrew+1] = value
		end
	end
	fuFirstCrewCheckTimer = 1
end

function update(dt)
	crewOverflowOldUpdate(dt)

	if player.worldId() == player.ownShipWorldId() then
		if fuFirstCrewCheckTimer <= 0 then	--To hopefully fix the issue where crew members are stored when you first join the world
			fuCrewMembers = playerCompanions.getCompanions("crew")
			fuCrewLimit = recruitSpawner.crewLimit()
			if #fuCrewMembers > fuCrewLimit then
				for fuCrewMemberNumber, fuCrewMemberData in pairs (fuCrewMembers) do
					if fuCrewMemberNumber > fuCrewLimit then
						table.insert(fuStoredCrew, fuCrewMemberData)
						status.setStatusProperty("fuStoredCrew", fuStoredCrew)
						recruitSpawner:dismiss(fuCrewMemberData.podUuid)
					end
				end
			elseif #fuStoredCrew > 0 then
				fuFreeCrewSpace = math.min(fuCrewLimit - #fuCrewMembers, #fuStoredCrew)
				if fuFreeCrewSpace > 0 then
					for _ = 1, fuFreeCrewSpace do
						recruitSpawner:addCrew(fuStoredCrew[1].podUuid, fuStoredCrew[1])
						table.remove(fuStoredCrew, 1)
						status.setStatusProperty("fuStoredCrew", fuStoredCrew)
					end
				end
			end
		else
			fuFirstCrewCheckTimer = fuFirstCrewCheckTimer - dt
		end
	end
end

function uninit()
	crewOverflowOldUninit()
	status.setStatusProperty("fuStoredCrew", fuStoredCrew)
end

function Pet:store()
  if self.uniqueId then
    promises:add(world.sendEntityMessage(self.uniqueId, "pandorasboxGetHarvestTimeLeft"), function(harvestTimeLeft)
      if harvestTimeLeft then
        self.spawnConfig.parameters.pandorasboxHarvestTimeLeft = harvestTimeLeft
      end
    end)
	promises:add(world.sendEntityMessage(self.uniqueId, "fuGetShipPetData"), function(shipPetData)
      if shipPetData then
        self.spawnConfig.parameters = util.mergeTable(self.spawnConfig.parameters, shipPetData)
      end
    end)
  end
  local result = self:toJson()
  if not self.persistent then
    result.uniqueId = nil
  end
  return result
end
