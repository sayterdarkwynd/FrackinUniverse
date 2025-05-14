require'/scripts/fupower.lua'

function init()
	power.init()

	-- This device starts sending "On" signal if all batteries combined
	-- are at less than "activatePercent" of their maximum capacity.
	-- Then it keeps sending "On" signal until they reach at least "deactivatePercent"
	-- of their maximum capacity.
	-- Note: we can add UI to allow the player to choose these numbers. 10%/100% is a sensible default.
	-- We use 10% instead of 0%, because there can be a small leftover charge in the battery (too little to spend).
	self.activatePercent = config.getParameter("activatePercent") or 10
	self.deactivatePercent = config.getParameter("deactivatePercent") or 100
	self.chatStrings = config.getParameter("chatStrings")

	-- True if currently sending "On" signal.
	storage.needRecharge = storage.needRecharge or false
end


function update(dt)
	if not power.entitylist or not power.entitylist.battery then
		return
	end

	local maxCapacity = 0
	local currentCharge = 0
	local numBatteries = 0

	for _, entityId in ipairs(power.entitylist.battery) do
		local capacity = callEntity(entityId, 'power.getMaxEnergy')
		if capacity then
			maxCapacity = maxCapacity + capacity
			currentCharge = currentCharge + ( callEntity(entityId, 'power.getStoredEnergy') or 0 )
			numBatteries = numBatteries + 1
		end
	end

	if maxCapacity == 0 then
		-- No batteries on this conduit.
		object.setConfigParameter('description', self.chatStrings.noBatteries)
		animator.setAnimationState('switchState', 'off')
		return
	end

	local percent = currentCharge / maxCapacity * 100
	if not storage.needRecharge and percent <= self.activatePercent then
		storage.needRecharge = true
	elseif storage.needRecharge and percent >= self.deactivatePercent then
		storage.needRecharge = false
	end

	object.setOutputNodeLevel(0, storage.needRecharge)

	-- Update scan text and appearance.
	local statusTooltip
	if storage.needRecharge then
		statusTooltip = string.format(self.chatStrings.statusOn, self.deactivatePercent)
		animator.setAnimationState('switchState', 'on')
	else
		statusTooltip = string.format(self.chatStrings.statusOff, self.activatePercent)
		animator.setAnimationState('switchState', 'off')
	end

	object.setConfigParameter('description', string.format(self.chatStrings.tooltip,
		numBatteries,
		math.floor(percent * 2) / 2, -- Rounded to the multiple of 0.5
		statusTooltip
	))
end
