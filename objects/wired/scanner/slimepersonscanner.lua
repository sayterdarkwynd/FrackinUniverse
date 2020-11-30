require "/scripts/util.lua"

function init()
	self.detectEntityTypes = config.getParameter("detectEntityTypes")
	self.detectBoundMode = config.getParameter("detectBoundMode", "CollisionArea")
	self.detectDamageTeam = config.getParameter("detectDamageTeam")
	local detectArea = config.getParameter("detectArea")
	local pos = object.position()
	if type(detectArea[2]) == "number" then
		--center and radius
		self.detectArea = {
			{pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
			detectArea[2]
		}
	elseif type(detectArea[2]) == "table" and #detectArea[2] == 2 then
		--rect corner1 and corner2
		self.detectArea = {
			{pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
			{pos[1] + detectArea[2][1], pos[2] + detectArea[2][2]}
		}
	end

	object.setInteractive(config.getParameter("interactive", true))
	object.setAllOutputNodes(false)
	animator.setAnimationState("switchState", "off")
	self.triggerTimer = 0
end

function trigger(logicState)
	object.setAllOutputNodes(logicState)
	animator.setAnimationState("switchState", logicState and "on" or "off")
	object.setSoundEffectEnabled(logicState)
	self.triggerTimer = config.getParameter("detectDuration")
end

function onInteraction(args)
	trigger()
end

function update(dt)
	if self.triggerTimer > 0 then
		self.triggerTimer = self.triggerTimer - dt
	elseif self.triggerTimer <= 0 then
		local entityIds = world.entityQuery(self.detectArea[1], self.detectArea[2], {
			withoutEntityId = entity.id(),
			includedTypes = self.detectEntityTypes,
			boundMode = self.detectBoundMode
		})
		if self.detectDamageTeam then
			entityIds = util.filter(entityIds, function (entityId)
				local entityDamageTeam = world.entityDamageTeam(entityId)
				if self.detectDamageTeam.type and self.detectDamageTeam.type ~= entityDamageTeam.type then
					return false
				end
				if self.detectDamageTeam.team and self.detectDamageTeam.team ~= entityDamageTeam.team then
					return false
				end
				return true
			end)
		end
		if #entityIds > 0 then
			local found
			for _,entity in pairs(entityIds) do
				local aggro=world.entityAggressive(entity)
				if not aggro then
					trigger(true)
					found=aggro
					break
				end
			end
			if not found then trigger(false) end
		else
			trigger(false)
		end
	end
end
