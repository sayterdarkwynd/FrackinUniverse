require "/scripts/golemancer/gol_resourceManager.lua"
require "/scripts/golemancer/gol_spawnManager.lua"

local preGolemInit = init
local preGolemUpdate = update
local preGolemRequire = require

function init()
	preGolemInit()
	self.evolutions = config.getParameter("evolutions")
	self.tickEvoTime = config.getParameter("tickEvoTime") or 5.0
	self.tickEvoTimer = self.tickEvoTime
	self.baseEvoTime=config.getParameter("agingEvoTime") or 5000
	self.tickEvoTimerAging = self.baseEvoTime
	self.consumedTable = {}
end

function update(dt)
	preGolemUpdate(dt)
	self.tickEvoTimer = self.tickEvoTimer - dt
	self.tickEvoTimerAging = self.tickEvoTimerAging - dt
	if self.tickEvoTimer <= 0 then
		self.tickEvoTimer = self.tickEvoTime
		if not world.getProperty("ephemeral") then
			self.position = mcontroller.position()
			for _, v in ipairs(self.evolutions) do
				local evolution = root.assetJson(v)
				if consumeResources(evolution) == "allConsumed" then evolve(evolution) end
			end
		end
	end
	if self.tickEvoTimerAging <= 0 then
		self.tickEvoTimerAging = self.baseEvoTime
		if not world.getProperty("ephemeral") then
			self.position = mcontroller.position()
			for _, v in ipairs(self.evolutions) do
				local evolution = root.assetJson(v)
				evolve(evolution)
			end
		end
	end
end

-- luacheck: ignore 121
function require(s)
	if s ~= "/monsters/monster.lua" then preGolemRequire(s) end
end
