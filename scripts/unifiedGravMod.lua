unifiedGravMod={}
unifiedGravMod.gravHandler=nil

function init()
	--dbg("uGM","init")
	unifiedGravMod.init()
	unifiedGravMod.initSoft()
	script.setUpdateDelta(5)
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
	self.gravFlightOverride = config.getParameter("gravFlightOverride",false)
	--dbg("uGM.iS",{self.gravityMod,self.gravityNormalize,self.gravityBaseMod,self.gravFlightOverride})
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
	--dbg("uGM.i",{self.flying,self,ghosting,self.gravMult2})
end

function unifiedGravMod.refreshGrav(dt)
	if not self.ghosting then --ignore effect if ghost
		local gravMod=(self.gravFlightOverride and -1.0) or (status.statPositive("gravFlightOverride") and 0.0) or status.stat("gravityMod")--most multipliers are gonna be this. this is where gravity increases and decreases go.
		local gravBaseMod=status.stat("gravityBaseMod")--stuff that directly affects how much gravity effects will affect a creature.
		local newGrav=(gravMod*self.gravMult2*(1+gravBaseMod))--new effective gravity
		local gravNorm=((status.statPositive("fuswimming") and 0.0) or 1.0) * status.stat("gravityNorm")
		local newGravNorm=(gravNorm~=0.0) and (((status.statPositive("fuswimming") and 0.0) or 1.0)) or 0.0
		local createGravity=status.statPositive("createGravity")
		--dbg("uGM.rG@first: ",{flying=self.flying,ghosting=self.ghosting,gravMod=gravMod,gravMult2=self.gravMult2,gravBaseMod=gravBaseMod,gravAt=world.gravity(entity.position()),newGrav=newGrav,gravNorm=gravNorm,newGravNorm=newGravNorm,createGravity=createGravity,zeroG=mcontroller.zeroG()})

		if self.gravFlightOverride or status.statPositive("gravFlightOverride") or ((not createGravity) and (0==world.gravity(entity.position()))) then
			--nothing
		elseif self.createGravity or self.flying or (0==world.gravity(entity.position())) then
			local fishbowl=((0==world.gravity(entity.position())) and 80) or (world.gravity(entity.position()))
			--dbg("uGM.rG","Flying entity!")
			mcontroller.addMomentum({0,-0.2*fishbowl*newGrav*dt})
		else
			--reduce effect of gravity modifiers if gravity normalization is in effect
			newGravNorm=newGravNorm*(((newGravNorm~=0.0) and ((newGrav*(1.0-(0.5*math.abs(gravNorm))))*-1)) or 0)
			newGrav=newGrav+newGravNorm+gravNorm+1.5
			mcontroller.controlParameters({gravityMultiplier = newGrav})
		end
		--dbg("uGM.rG@end",{flying=self.flying,ghosting=self.ghosting,gravMod=gravMod,newGrav=newGrav,gravNorm=gravNorm,gravMult2=self.gravMult2,gravBaseMod=gravBaseMod,newGravNorm=newGravNorm})
	end
end

-- F(x)=IF(x>80,-1,IF(x<80,1,0))*120/x, F(22)=80
function unifiedGravMod.applyGravNormalization()
	local gravity=world.gravity(entity.position())
	local gravNorm=0
	if gravity ~= 0 then
		gravNorm=(80/gravity)-1.5
	end
	--dbg("uGM.aGN",{gravity,gravNorm})
	if unifiedGravMod.normalizer==nil then
		if status.stat("gravityNorm") == 0.0 then
			unifiedGravMod.normalizer=effect.addStatModifierGroup({{stat="gravityNorm",amount=gravNorm}})
		end
	else
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

function dbg(s,t)
	sb.logInfo(s..": %s",t)
end