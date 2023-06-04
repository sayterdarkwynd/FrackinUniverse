local penguinFixOldUpdate=update

function update(dt)
	if penguinFixOldUpdate then penguinFixOldUpdate(dt) end
	if self.targetId then
		monster.setAggressive(true)
	else
		monster.setAggressive(false)
	end
end