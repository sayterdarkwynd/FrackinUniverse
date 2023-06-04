typerParticle={}
typerParticle.cfg = { }
typerParticle.instances = { }
typerParticle.spawnCooldown = 0
typerParticle.runningTime = 0
typerParticle.tid = 1

-- 		Usage:
-- Attach as a script to a status effect (in the 'scripts' field), and configure through a custom 'effectConfig' field in the effects root.
-- Full config example:
--  "effectConfig" : {
--		// Basically a text particle definition.
--    "typerParticleConfig" : {
--      "particle" : {
--        "color" : [0, 0, 0, 205],
--        "size" : 1,
--        "fade" : 0.7,
--        "destructionTime" : 0.8,
--        "initialVelocity" : [0, 4],
--        "finalVelocity" : [0, 0],
--        "timeToLive" : 0,
--        "destructionAction" : "shrink"
--      },
--
--      "spawnInterval" : 0.5,
--      "writeInterval" : 0.1,
--      "printTextInOrder" : false,
--      "loopOrderedText" : true,
--      "spacing" : [1, 1.5],
--      "boundingBox" : [ 0, 0 ],
--      "texts" : [
--        "*honk*",
--        "*HONK*",
--        "h o n k",
--        "H O N K",
--        "Kevin says hi",
--        "banana",
--        "clown",
--        "*wilhelm scream*"
--      ],
--
--		// All of these are optional
--      "controllers" : {
--        "color" : [125, 50, 25, 0],
--        "colorLoop" : true,
--        "size" : 1,
--        "sizeMax" : 10,
--        "timeToLive" : 1,
--        "timeToLiveMax" : 5,
--        "boundingBox" : [3, 3],
--        "boundingBoxMax" : [50, 50],
--        "spacing" : [1, 1.5]
--      }
--    }
--  },

-- Contains all controller methods.
-- Irrelevant ones are culled on init, based on config
typerParticle.controllerChain = {
	color = function(dt)
		if typerParticle.cfg.controllers.colorLoop then
			-- Giving a 255 headtsrat because the correct color calculation only works above 255
			realColor = realColor or {
				255 + typerParticle.cfg.particle.color[1],
				255 + typerParticle.cfg.particle.color[2],
				255 + typerParticle.cfg.particle.color[3],
				255 + typerParticle.cfg.particle.color[4]
			}

			realColor = {
				realColor[1] + typerParticle.cfg.controllers.color[1] * dt,
				realColor[2] + typerParticle.cfg.controllers.color[2] * dt,
				realColor[3] + typerParticle.cfg.controllers.color[3] * dt,
				realColor[4] + typerParticle.cfg.controllers.color[4] * dt
			}

			typerParticle.cfg.particle.color = {
				math.abs(255 - realColor[1] % 510),
				math.abs(255 - realColor[2] % 510),
				math.abs(255 - realColor[3] % 510),
				math.abs(255 - realColor[4] % 510)
			}
		else
			typerParticle.cfg.particle.color = {
				math.max(0, math.min(typerParticle.cfg.particle.color[1] + typerParticle.cfg.controllers.color[1] * dt, 255)),
				math.max(0, math.min(typerParticle.cfg.particle.color[2] + typerParticle.cfg.controllers.color[2] * dt, 255)),
				math.max(0, math.min(typerParticle.cfg.particle.color[3] + typerParticle.cfg.controllers.color[3] * dt, 255)),
				math.max(0, math.min(typerParticle.cfg.particle.color[4] + typerParticle.cfg.controllers.color[4] * dt, 255))
			}
		end
	end,

	size = function(dt)
		if not typerParticle.cfg.controllers.sizeMax or typerParticle.cfg.particle.size < typerParticle.cfg.controllers.sizeMax then
			typerParticle.cfg.particle.size = typerParticle.cfg.particle.size + typerParticle.cfg.controllers.size * dt
		end
	end,

	timeToLive = function(dt)
		if not typerParticle.cfg.controllers.lifeSpanMax or typerParticle.cfg.particle.timeToLive < typerParticle.cfg.controllers.lifeSpanMax then
			typerParticle.cfg.particle.timeToLive = typerParticle.cfg.particle.timeToLive + typerParticle.cfg.controllers.timeToLive * dt
		end
	end,

	boundingBox = function(dt)
		typerParticle.cfg.boundingBox = typerParticle.cfg.boundingBox or {0, 0}

		if typerParticle.cfg.controllers.boundingBoxMax then
			typerParticle.cfg.boundingBox = {
				math.min(typerParticle.cfg.boundingBox[1] + typerParticle.cfg.controllers.boundingBox[1] * dt, typerParticle.cfg.controllers.boundingBoxMax[1]),
				math.min(typerParticle.cfg.boundingBox[2] + typerParticle.cfg.controllers.boundingBox[2] * dt, typerParticle.cfg.controllers.boundingBoxMax[2])
			}
		else
			typerParticle.cfg.boundingBox = {
				typerParticle.cfg.boundingBox[1] + typerParticle.cfg.controllers.boundingBox[1] * dt,
				typerParticle.cfg.boundingBox[2] + typerParticle.cfg.controllers.boundingBox[2] * dt
			}
		end

		typerParticle.cfg.boundingBox = {
			math.max(0, typerParticle.cfg.boundingBox[1]),
			math.max(0, typerParticle.cfg.boundingBox[2])
		}
	end,

	spacing = function(dt)
		typerParticle.cfg.spacing = {
			typerParticle.cfg.spacing[1] + typerParticle.cfg.controllers.spacing[1] * dt,
			typerParticle.cfg.spacing[2] + typerParticle.cfg.controllers.spacing[2] * dt
		}
	end
}

local typer_previousInit = init
local typer_previousUpdate = update
typerParticle.isActive = true

function init()
	if typer_previousInit then typer_previousInit() end
	typerParticle.init()
end

function typerParticle.init()
	-- Do nothing if the entity is not a player. (Don't expire the status effect as it might have other functionality)
	if world.entityType(entity.id()) ~= "player" then
		typerParticle.isActive = false
		return
	end

	-- Get config and set constant particle info
	typerParticle.cfg = config.getParameter("typerParticleConfig")
	typerParticle.cfg.particle.type = "text"
	typerParticle.cfg.particle.layer = "front"

	-- Remove unused controllers
	if typerParticle.cfg.controllers then
		for controller, _ in pairs(typerParticle.controllerChain) do
			if not typerParticle.cfg.controllers[controller] then
				typerParticle.controllerChain[controller] = nil
			end
		end

		-- If the color is looping, it doesn't matter visually in which direction its going (beyond the past loop anyways)
		-- But it does for the code so....
		if typerParticle.cfg.controllers.color and typerParticle.cfg.controllers.colorLoop then
			for i, color in ipairs(typerParticle.cfg.controllers.color) do
				typerParticle.cfg.controllers.color[i] = math.abs(color)
			end
		end
	else
		typerParticle.controllerChain = nil
	end

	-- Set the correct picking method to the generic placeholder
	-- Clear the other one--no.
	if (typerParticle.cfg.printTextInOrder) then
		typerParticle.SelectText = typerParticle.SelectOrdered
		--typerParticle.SelectRandom = nil
	else
		typerParticle.SelectText = typerParticle.SelectRandom
		--typerParticle.SelectOrdered = nil
	end
end

function update(dt)
	if typer_previousUpdate then typer_previousUpdate(dt) end
	typerParticle.update(dt)
end

function typerParticle.reset()
	typerParticle.runningTime=0.0
	typerParticle.init()
end

function typerParticle.update(dt)
	if not typerParticle.isActive then return end

	-- Keeps track of how long the effect is running
	typerParticle.runningTime = typerParticle.runningTime + dt

	local toRemove = {}
	for i, data in ipairs(typerParticle.instances) do
		if (typerParticle.runningTime - data.lastTime >= typerParticle.cfg.writeInterval) then
			typerParticle.cfg.particle.position = data.position
			typerParticle.cfg.particle.text = string.sub(data.text, data.index, data.index)
			world.sendEntityMessage(entity.id(), "fu_specialAnimator.spawnParticle", typerParticle.cfg.particle)

			data.position[1] = data.position[1] + typerParticle.cfg.spacing[1]
			data.lastTime = typerParticle.runningTime
			data.index = data.index + 1

			-- New line
			if (string.sub(data.text, data.index, data.index) == "\n") then
				data.position[1] = data.origin[1]
				data.position[2] = data.position[2] + typerParticle.cfg.spacing[2]
				data.index = data.index + 1
			end

			-- Mark for removal if the entire string was printed out
			if (data.index > #data.text) then
				table.insert(toRemove, i)
			end
		end
	end

	-- Remove marked typerParticle.instances
	for i = #toRemove, 1, -1 do
		table.remove(typerParticle.instances, toRemove[i])
	end

	if (typerParticle.spawnCooldown <= 0) then
		typerParticle.spawnCooldown = typerParticle.cfg.spawnInterval

		-- Get player position, and randomize particles position based on bounding box
		local pos = entity.position()
		if typerParticle.cfg.boundingBox then
			pos = {
				pos[1] + typerParticle.cfg.boundingBox[1] * (0.5 - math.random()),
				pos[2] + typerParticle.cfg.boundingBox[2] * (0.5 - math.random())
			}
		end

		table.insert(typerParticle.instances, {
			text = typerParticle.SelectText(),
			index = 1,
			lastTime = 0,
			origin = pos,
			position = {pos[1], pos[2]}
		})
	else
		typerParticle.spawnCooldown = typerParticle.spawnCooldown - dt
	end

	-- Run controller chain of command
	for _, command in pairs(typerParticle.controllerChain) do command(dt) end
end

-- Gets overriden by another selection method on init. Treat it like a state.
function typerParticle.SelectText() end

function typerParticle.SelectOrdered()
	local str = typerParticle.cfg.texts[typerParticle.tid]

	if (typerParticle.cfg.loopOrderedText) then
		typerParticle.tid = typerParticle.tid % #typerParticle.cfg.texts
	elseif (typerParticle.tid >= #typerParticle.cfg.texts) then
		typerParticle.cfg.spawnInterval = 999999999
	end

	typerParticle.tid = typerParticle.tid + 1
	return str
end

function typerParticle.SelectRandom()
	return typerParticle.cfg.texts[math.random(1, #typerParticle.cfg.texts)]
end
