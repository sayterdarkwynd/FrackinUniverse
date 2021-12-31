require "/scripts/util.lua"
require "/scripts/rect.lua"

function init()
	self.coroutines = {}
	message.setHandler("startSequence", function()
		table.insert(self.coroutines, coroutine.create(missionSequence))
	end)
	message.setHandler("bossWave", function()
		table.insert(self.coroutines, coroutine.create(bossWave))
	end)
	message.setHandler("noxBeamout", function()
		stopMusic()
		radioMessage("noxBeamout")
	end)

	self.wallAttacked = false
	message.setHandler("wallAttacked", function()
		if not self.wallAttacked then
			radioMessage("wallAttacked")
			self.wallAttacked = true
		end
	end)

	self.enemies = {}
	self.players = {}

	self.missionArea = rect.translate(config.getParameter("missionArea"), entity.position())

	playerScan()
end

function playerScan()
	local players = world.players()
	local newPlayers = util.filter(players, function(entityId)
		return contains(self.players, entityId)
	end)
	for _,playerId in pairs(newPlayers) do
		if self.music then
			world.sendEntityMessage(playerId, "playAltMusic", self.music, config.getParameter("musicFadeInTime"))
		end
	end
	self.players = players
end

function startMusic(musicKey)
	self.music = config.getParameter(musicKey)
	for _,playerId in pairs(self.players) do
		world.sendEntityMessage(playerId, "playAltMusic", self.music, config.getParameter("musicFadeInTime"))
	end
end

function stopMusic()
	if self.music then
		self.music = nil
		for _,playerId in pairs(self.players) do
			world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("musicFadeOutTime"))
		end
	end
end

function radioMessage(key)
	local messageConfig = config.getParameter("radioMessages." .. key)
	local message = {
		unique = false,
		portraitImage = messageConfig[2],
		portraitFrames = 1,
		messageId = "glitchmissionmanager",
		senderName = messageConfig[3],
		text = messageConfig[1]
	}
	for _,playerId in pairs(self.players) do
		world.sendEntityMessage(playerId, "queueRadioMessage", message)
	end
end

function update(dt)
	world.loadRegion(self.missionArea)
	--self.debug=true
	--util.debugRect(self.missionArea,{255,255,255})
	if #self.coroutines == 0 and self.music then
		stopMusic()
	end

	for i,cor in pairs(self.coroutines) do
		if coroutine.status(cor) ~= "dead" then
			local status, result = coroutine.resume(cor)
			if not status then error(result) end
		else
			table.remove(self.coroutines, i)
		end
	end

	playerScan()
end

function missionSequence()
	world.entityQuery({self.missionArea[1], self.missionArea[2]}, {self.missionArea[3], self.missionArea[4]}, {
		includedTypes = { "npc", "object" },
		callScript = "notify",
		callScriptArgs = { { type = "missionStarted", source = entity.id() } }
	})

	-- Start battle music later
	table.insert(self.coroutines, coroutine.create(function()
		util.wait(8.0)
		startMusic("battleMusic")
	end))

	local wave = spawnWave("campspawn", {
		{ entityType = "cultistknight", count = 3, parameters = { moveLeft = true } },
		{ entityType = "cultistarcher", count = 2, parameters = { moveLeft = true } }
	})
	while #wave > 0 do
		wave = util.filter(wave, world.entityExists)
		coroutine.yield()
	end
	util.wait(4.0)
	util.appendLists(wave, spawnWave("campspawn", {
		{ entityType = "cultistknight", count = 2, parameters = { moveLeft = true } },
		{ entityType = "cultistarcher", count = 1, parameters = { moveLeft = true } }
	}))
	util.appendLists(wave, spawnWave("midfieldspawn", {
		{ entityType = "cultistknight", count = 2 }, 
		{ entityType = "cultistarcher", count = 1 }
	}))
	while #wave > 0 do
		wave = util.filter(wave, world.entityExists)
		coroutine.yield()
	end
	util.wait(4.0)
	util.appendLists(wave, spawnWave("gatespawn", {
		{ entityType = "cultistknight", count = 2 },
		{ entityType = "cultistbasic", count = 1, parameters = { moveLeft = true, behavior="cultistinvader" } }
	}))
	util.appendLists(wave, spawnWave("gatespawn2", {
		{ entityType = "cultistscientistpet", count = 2 }
	}))
	util.appendLists(wave, spawnWave("midfieldspawn", {
		{ entityType = "cultistknight", count = 2 },
		{ entityType = "cultistarcher", count = 1 }
	}))
	while #wave > 0 do
		wave = util.filter(wave, world.entityExists)
		coroutine.yield()
	end

	util.wait(4.0)

	-- Keep spawning ballistas for the rest of the fight
	local ballistaCoroutine = coroutine.create(spawnBallistas)
	table.insert(self.coroutines, ballistaCoroutine)

	radioMessage("firstBallista")
	wave = spawnWave("ballistaspawn", {
		{ entityType = "cultistknight", count = 2 },
		{ entityType = "cultistarcher", count = 1 }
	})
	util.appendLists(wave, spawnWave("campspawn", {
		{ entityType = "cultistknight", count = 2, parameters = { moveLeft = true } },
		{ entityType = "cultistarcher", count = 1, parameters = { moveLeft = true } }
	}))
	while #wave > 0 do
		wave = util.filter(wave, world.entityExists)
		coroutine.yield()
	end
	util.wait(8.0)
	util.appendLists(wave, spawnWave("midfieldspawn", {
		{ entityType = "cultistknight", count = 2 },
		{ entityType = "cultistarcher", count = 1 }
	}))
	while #wave > 0 do
		wave = util.filter(wave, world.entityExists)
		coroutine.yield()
	end

	util.wait(4.0)

	-- Spawning helicultists should go on for the rest of the fight
	local heliCoroutine = coroutine.create(spawnHelis)
	table.insert(self.coroutines, heliCoroutine)
	util.appendLists(wave,spawnWave("gatespawn", {
		{ entityType = "cultistknight", count = 3},
		{ entityType = "cultistarcher", count = 2 }
	}))
	util.appendLists(wave,spawnWave("gatespawn2", {
		{ entityType = "cultistscientistpet", count = 2 }
	}))
	radioMessage("firstAirforce")
	while (#wave) > 0 do
		wave = util.filter(wave, world.entityExists)
		coroutine.yield()
	end

	util.wait(4.0)

	radioMessage("reinforcements")

	util.wait(6.0)

	local nuruId = world.spawnNpc(world.entityPosition(world.loadUniqueEntity("nuruspawn")), "floran", "nurufight", world.threatLevel())
	world.callScriptedEntity(nuruId, "status.addEphemeralEffect", "beamin")
	util.wait(3.0)
	local lanaId = world.spawnNpc(world.entityPosition(world.loadUniqueEntity("lanaspawn")), "apex", "lanafight", world.threatLevel())
	world.callScriptedEntity(lanaId, "status.addEphemeralEffect", "beamin")

	util.wait(6.0)

	local spawnFunctions = {
		function() return spawnWave("campspawn", {
			{ entityType = "cultistbasic", count = 2, parameters = { moveLeft = true, behavior="cultistinvader" } },
			{ entityType = "cultistassault", count = 1, parameters = { moveLeft = true, behavior="cultistinvader" } },
			{ entityType = "cultistsniper", count = 1, parameters = { moveLeft = true, behavior="cultistinvader" } },
			{ entityType = "cultistknight", count = 3, parameters = { moveLeft = true } }
		}) end,
		function() return spawnWave("midfieldspawn", {
			{ entityType = "cultistknight", count = 3},
			{ entityType = "cultistarcher", count = 2 },
			{ entityType = "cultistsniper", count = 1, parameters = { moveLeft = true, behavior="cultistinvader" } }
		}) end,
		function() return spawnWave("gatespawn", {
			{ entityType = "cultistbasic", count = 3, parameters = { moveLeft = true, behavior="cultistinvader" }},
			{ entityType = "cultistassault", count = 1, parameters = { moveLeft = true, behavior="cultistinvader" } }
		}) end,
		function() return spawnWave("gatespawn2", {
			{ entityType = "cultistsciencepet", count = 2 }
		}) end
	}
	for _ = 1, 5 do
		shuffle(spawnFunctions)
		for _,spawn in pairs(spawnFunctions) do
			util.appendLists(wave,spawn())
			util.wait(4.0)
		end
		while #wave > 0 do
			wave = util.filter(wave, world.entityExists)
			coroutine.yield()
		end
		util.wait(4.0)
	end
	-- Stop spawning helis and ballistas before the boss
	self.coroutines = util.filter(self.coroutines, function(cor)
		return cor ~= heliCoroutine and cor ~= ballistaCoroutine
	end)

	-- Wait for any straggling enemies to die
	while #self.enemies > 0 do
		self.enemies = util.filter(self.enemies, world.entityExists)
		coroutine.yield()
	end

	util.wait(2.0)

	radioMessage("finalWaveComplete")

	util.wait(2.0)

	world.entityQuery({self.missionArea[1], self.missionArea[2]}, {self.missionArea[3], self.missionArea[4]}, {
		includedTypes = { "npc", "object" },
		callScript = "notify",
		callScriptArgs = { { type = "reinforcementsLeave", source = entity.id() } }
	})

	local baron = world.loadUniqueEntity(config.getParameter("baronUuid"))
	world.sendEntityMessage(baron, "notify", {
		type = "lastWaveComplete",
		sourceId = entity.id()
	})
end

function bossWave()
	-- Keep cultists spawning in all spawn points to discourage player from leaving the boss area
	local spawnCultists = coroutine.create(function()
		util.wait(8.0)
		local wave={}
		while true do
			wave = util.filter(wave, world.entityExists)
			if #wave<=20 then -- implement spawn cap
				util.appendLists(wave,spawnWave("campspawn", {
					{ entityType = "cultistknight", count = 2, parameters = { moveLeft = true } },
					{ entityType = "cultistassault", count = 1, parameters = { moveLeft = true, behavior="cultistinvader" } },
					{ entityType = "fusorceror", count = 1, parameters = { moveLeft = true, behavior="cultistinvader" } }
				}))
			end
			if bossDefeated then
				for _,id in pairs(wave) do
					world.callScriptedEntity(id,"notify",{ { type = "missionEnded", source = entity.id() } })
				end
				return
			end
			util.wait(config.getParameter("bossAddSpawnInterval"))
		end
	end)
	table.insert(self.coroutines, spawnCultists)

	wave = spawnWave("bossposition", { { entityType = "dragonboss" } })

	util.wait(2.0)

	radioMessage("noxGreeting")

	util.wait(4.0)
	startMusic("bossMusic")

	for _,enemyId in pairs(wave) do
		-- FIXME: detected by Luacheck: something is wrong here (loop uses wave[1] several times).
		world.sendEntityMessage(wave[1], "notify", { type = "bossAggro", sourceId = entity.id() })
	end

	while #wave > 0 do
		wave = util.filter(wave, world.entityExists)
		if #wave>0 then
		local bossHealth=world.entityHealth(wave[1])--format: {current,max}
			if bossHealth[1]<=0 then
				bossDefeated=true
			end
		else
			bossDefeated=true
		end
		coroutine.yield()
	end

	-- Stop spawning cultists when the boss dies
	self.coroutines = util.filter(self.coroutines, function(cor) return cor ~= spawnCultists end)

	util.wait(2.0)

	world.entityQuery({self.missionArea[1], self.missionArea[2]}, {self.missionArea[3], self.missionArea[4]}, {
		includedTypes = { "npc" },
		callScript = "notify",
		callScriptArgs = { { type = "missionEnded", source = entity.id() } }
	})

	util.wait(6.0)

	radioMessage("bossDefeated")
	local baron = world.loadUniqueEntity(config.getParameter("baronUuid"))
	world.sendEntityMessage(baron, "notify", {
		type = "missionComplete",
		sourceId = entity.id()
	})

	self.coroutines = {}
end

function spawnBallistas()
	local ballistas = spawnWave("ballistaspawn", {
		{ entityType = "ballista" }
	})
	-- Keep spawning ballistas forever
	while true do
		while #ballistas > 0 do
			ballistas = util.filter(ballistas, world.entityExists)
			coroutine.yield()
		end

		util.wait(config.getParameter("ballistaSpawnDelay", 30))
		ballistas = spawnWave("ballistaspawn", {
			{ entityType = "ballista" },
			{ entityType = "cultistbasic", parameters = { moveLeft = true, behavior="cultistinvader" } }
		})
		spawnWave("ballistaspawn", {
			{ entityType = "cultistknight" },
			{entityType = "fuhugebiped"}
		})
	end
end

function spawnHelis()
	local helis = spawnWave("helispawn", {
		{ entityType = "helicultist", count = 2},
		{ entityType = "fuhelicultist", count = 1}
	})
	while true do
		for i,entityId in pairs(helis) do
			if not world.entityExists(entityId) then
				table.remove(helis, i)
				util.wait(config.getParameter("heliSpawnDelay", 20))
				local newHelis = spawnWave("helispawn", {
					{ entityType = "helicultist", count = 1},
					{ entityType = "fuhelicultist", count = 1}
				})
				for _,entityId in pairs(newHelis) do
					table.insert(helis, entityId)
				end
			end
		end

		coroutine.yield()
	end
end

function spawnWave(spawnPoint, wave)
	local spawnStagehand = world.loadUniqueEntity(spawnPoint)
	if not spawnStagehand then error(string.format("No entity with unique ID: %s", spawnPoint)) end
	local enemies = {}
	for _,spawn in pairs(wave) do
		for _ = 1, (spawn.count or 1) do
			local position = world.entityPosition(spawnStagehand)

			if contains({"cultistknight", "cultistarcher", "helicultist", "fuhelicultist","cultistbasic","cultistassault","cultistrocket","cultistscientistpet","cultistsniper","fusorceror"}, spawn.entityType) then
				local spawnPositionRange = config.getParameter("spawnPositionRange", 5)
				position = vec2.add(position, {math.random(spawnPositionRange[1], spawnPositionRange[2]), 0})
			end
			if contains({"fuhugebiped"}, spawn.entityType) then
				position = vec2.add(position, 30)
			end

			local entityId
			if spawn.entityType == "cultistknight" or spawn.entityType == "cultistarcher" or spawn.entityType == "cultistbasic" or spawn.entityType == "cultistassault" or spawn.entityType == "fusorceror" or spawn.entityType == "cultistrocket" or spawn.entityType == "cultistscientistpet" or spawn.entityType == "cultistsniper" then
				entityId = world.spawnNpc(position, "human", spawn.entityType, world.threatLevel(), nil, { scriptConfig = spawn.parameters or {}})
				world.callScriptedEntity(entityId, "status.addEphemeralEffect", "beamin")
			elseif spawn.entityType == "ballista" then
				entityId = world.spawnMonster("ballista", position, { aggressive = true, level = world.threatLevel() })
			elseif spawn.entityType == "helicultist" then
				entityId = world.spawnMonster("helicultist", position, { aggressive = true, level = world.threatLevel() })
			elseif spawn.entityType == "fuhelicultist" then
				entityId = world.spawnMonster("fuhelicultist", position, { aggressive = true, level = world.threatLevel() })
			elseif spawn.entityType == "fuhugebiped" then
				randVal = math.random(1,4)
				if randVal == 1 then
					entityId = world.spawnMonster("fuhugebiped", position, { aggressive = true, level = world.threatLevel() })
				else
					entityId = world.spawnMonster("cosmicintruder", position, { aggressive = true, level = 6 })
				end
			elseif spawn.entityType == "dragonboss" then
				entityId = world.spawnMonster("dragonboss", position, { aggressive = true, level = world.threatLevel() })
			end
			table.insert(enemies, entityId)
			table.insert(self.enemies, entityId)
		end
	end
	return enemies
end
