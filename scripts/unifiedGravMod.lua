unifiedGravMod={}
unifiedGravMod.gravHandler=nil

function init()
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
		if 0==world.gravity(entity.position()) then
			mcontroller.addMomentum({0,-1*80*newGrav*0.2*dt})
		elseif self.flying then
			mcontroller.addMomentum({0,-1*world.gravity(entity.position())*newGrav*0.2*dt})
		else
			newGrav=newGrav+gravNorm+1.5
			mcontroller.controlParameters({gravityMultiplier = newGrav})
		end
		--sb.logInfo("%s",{flying=self.flying,ghosting=self.ghosting,gravMod=gravMod,newGrav=newGrav,gravNorm=gravNorm})
	end
end

-- F(x)=IF(x>80,-1,IF(x<80,1,0))*120/x, F(22)=80
function unifiedGravMod.applyGravNormalization()
	local gravity=world.gravity(entity.position())
	local gravNorm=0
	if gravity ~= 0 then
		gravNorm=(80/gravity)-1.5
	end
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