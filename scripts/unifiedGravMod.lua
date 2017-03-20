unifiedGravMod={}
unifiedGravMod.gravHandler=nil

function init()
	unifiedGravMod.init()
	unifiedGravMod.initSoft()
end


function unifiedGravMod.update(dt)
	if self.gravityNormalize then
		unifiedGravMod.applyGravNormalization()
	end
	unifiedGravMod.refreshGrav(dt)
end

function update(dt)
	unifiedGravMod.update(dt)
end

function unifiedGravMod.initSoft()
	self.gravityMod = config.getParameter("gravityMod",0.0)
	self.gravityNormalize = config.getParameter("gravityNorm",false)
	self.gravityBaseMod = config.getParameter("gravityBaseMod",0.0)
	--sb.logInfo(sb.printJson({self.gravityMod,self.gravityNormalize,self.gravityBaseMod}))
	if not unifiedGravMod.gravHandler then
		unifiedGravMod.gravHandler=effect.addStatModifierGroup({{stat = "gravityMod", amount=self.gravityMod},{stat = "gravityBaseMod", amount=self.gravityBaseMod}})
	end
end


function unifiedGravMod.init()
	if self.gravityNormalize then
		unifiedGravMod.applyGravNormalization()
	end	
	local baseMotionParams=mcontroller.baseParameters()
	self.flying=not baseMotionParams.gravityEnabled--flying creatures are unaffected normally. I use an alternate method to apply it.
	self.ghosting=not baseMotionParams.collisionEnabled--'ghosts' are immune to gravity effects, period.
	self.gravMult2=((baseMotionParams.gravityMultiplier or 1.5)/1.5)--if the creature has a base gravity multiplier other than 1.5...we make adjustments.
end

function unifiedGravMod.refreshGrav(dt)
	if not self.ghosting then  --ignore effect if ghost
		local gravMod=status.stat("gravityMod")--most multipliers are gonna be this. this is where gravity increases and decreases go.
		local gravBaseMod=status.stat("gravityBaseMod")--stuff that directly affects how much gravity effects will affect a creature.
		local newGrav=(gravMod*(self.gravMult2-gravBaseMod))--new effective gravity
		local gravNorm=status.stat("gravityNorm")
		if not self.flying then
			newGrav=newGrav+gravNorm+1.5
			mcontroller.controlParameters({gravityMultiplier = newGrav})
		else
			mcontroller.addMomentum({0,-1*world.gravity(entity.position())*newGrav*0.2*dt})
		end
	end
end

function unifiedGravMod.applyGravNormalization()
	local magic=world.gravity(entity.position())
	magic=((magic>80 and -1.0) or (magic<80 and 1.0) or 0) * (80/magic)
	
	local gravNorm=1.5*magic
	if unifiedGravMod.normalizer==nil then
		if status.stat("gravityNorm") == 0.0 then
			unifiedGravMod.normalizer=effect.addStatModifierGroup({{stat="gravityNorm",amount=gravNorm}})
		end
	else
		effect.setStatModifierGroup(unifiedGravMod.normalizer,{{stat="gravityNorm",amount=gravNorm}})
		effect.setStatModifierGroup(unifiedGravMod.normalizer,{{stat="gravityNorm",amount=gravNorm}})
	end
end

function unifiedGravMod.removeNormalization()
	if unifiedGravMod.normalizer ~= nil then
		effect.removeStatModifierGroup(unifiedGravMod.normalizer)
		unifiedGravMod.normalizer=nil
	end
end

function unifiedGravMod.removeGravStat()
	if unifiedGravMod.gravHandler ~= nil then
		effect.removeStatModifierGroup(unifiedGravMod.gravHandler)
		unifiedGravMod.gravHandler=nil
	end
end

function unifiedGravMod.uninit()
	unifiedGravMod.removeNormalization()
	unifiedGravMod.removeGravStat()
end

function uninit()
	unifiedGravMod.uninit()
end