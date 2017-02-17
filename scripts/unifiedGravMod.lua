unifiedGravMod={}

function init()
	unifiedGravMod.init()
	self.gravityMod = config.getParameter("gravityModifier",0.0)
	self.gravityNormalize = config.getParameter("gravityNormalize",false)
	self.gravityBaseMod = config.getParameter("gravityBaseModifier",0.0)
	effect.addStatModifierGroup({{stat = "gravityMod", amount=self.gravityMod}})
	effect.addStatModifierGroup({{stat = "gravityBaseMod", amount=self.gravityBaseMod}})
	if self.gravityNormalize then
		unifiedGravMod.applyNormalization()
	end	
end


function update(dt)
	if self.gravityNormalize then
		unifiedGravMod.applyNormalization()
	end
	unifiedGravMod.refreshGrav()
end

function unifiedGravMod.init()
	local baseMotionParams=mcontroller.baseParameters()
	self.flying=not baseMotionParams.gravityEnabled--flying creatures are unaffected normally. I use an alternate method to apply it.
	self.ghosting=not baseMotionParams.collisionEnabled--'ghosts' are immune to gravity effects, period.
	self.gravMult2=((self.movementParams.gravityMultiplier or 1.5)/1.5)--if the creature has a base gravity multiplier other than 1.5...we make adjustments.
end

function unifiedGravMod.refreshGrav()
	if not self.ghosting then  --ignore effect if ghost
		local gravMod=status.stat("gravityMod")--most multipliers are gonna be this. this is where gravity increases and decreases go.
		local gravBaseMod=status.stat("gravityBaseMod")--stuff that directly affects how much gravity effects will affect a creature.
		local newGrav=(gravMod*(self.gravMult2-gravBaseMod))--new effective gravity
		local gravNorm=status.stat("gravityNorm")
		if not self.flying then
			newGrav=newGrav+1.5-gravNorm
			mcontroller.controlParameters({gravityMultiplier = newGrav})
		else
			
		end
	end
end

function unifiedGravMod.getGravPct()
	--default planetary gravity is technically 80 (actually 100, but all planets use 80)
	return world.gravity(entity.position())/80.0
end

function unifiedGravMod.getGravOffset()
	--default planetary gravity is technically 80 (actually 100, but almost all planets use 80)
	return world.gravity(entity.position())-80.0
end

function unifiedGravMod.applyNormalization()
	local gravNorm=-1.5*unifiedGravMod.getGravOffset()
	if unifiedGravMod.normalizer==nil then
		if status.stat("gravityNorm") == 0.0 then
			unifiedGravMod.normalizer=effect.addStatModifierGroup({{stat="gravityNorm",amount=gravNorm}})
		end
	else
		effect.replaceStatModifierGroup(unifiedGravMod.normalizer,{{stat="gravityNorm",amount=gravNorm}})
	end
end

function unifiedGravMod.removeNormalization()
	if unifiedGravMod.normalizer ~= nil then
		effect.removeStatModifierGroup(unifiedGravMod.normalizer)
		unifiedGravMod.normalizer=nil
	end
end