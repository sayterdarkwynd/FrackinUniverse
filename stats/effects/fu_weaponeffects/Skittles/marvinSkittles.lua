require "/scripts/effectUtil.lua"

gregese={words={"@#$@$#@","greeeeg","greg","gregga","gregggggga","gregogreg","pft","rainbow","donkey","ahahaha"},punct={" ","...","?!","?!?","!!!","!","?","!!","!?"}}


function init()
	if world.getProperty("ship.fuel") then
		effect.expire()
		return
	end
	self.tickDamagePercentage = 0.025
	self.tickTime = 1.0
	self.tickTimer = self.tickTime
	spaz(1)
	stun()
	if status.isResource("energy") then
		status.setResourcePercentage("energy",0)
	end
end

function update(dt)
	if world.getProperty("ship.fuel") then
		effect.expire()
		return
	else
		effect.modifyDuration(dt)
		if status.resourcePercentage("health") < self.tickDamagePercentage then
			status.setResourcePercentage("health",0.0)
			stun()
		else
			self.tickTimer = self.tickTimer - dt
			if self.tickTimer <= 0 then
				self.tickTimer = self.tickTime
				spaz(math.floor(math.random(1,81)/9))
				--status.overConsumeResource("energy",math.huge)
				status.applySelfDamageRequest({
					damageType = "IgnoresDef",
					damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
					damageSourceKind = "default",
					sourceEntityId = entity.id()
				})
				stun()
			end
		end
	end
end

function spaz(wordCount)
	local sentence=""
	local caps=1
	
	for x=0,wordCount do
		if caps==1 then
			if math.random(0,1) > 0.67 then
				caps=2
			else
				caps=1
			end
		else
			if math.random(0,1) > 0.67 then
				caps=2
			else
				caps=0
			end
		end
		
		local rWord=gregese.words[math.floor(math.random(1,#gregese.words))]
		
		if caps==2 then
			rWord=string.upper(rWord)
		elseif caps==1 then
			rWord=firstToUpper(rWord)
		end
		
		local punctIndex=math.floor(math.max(math.random(1,#gregese.punct+6)-6,1))
		caps=(punctIndex>1 and 1) or 0

		local rPunct=gregese.punct[punctIndex] or " "
		if x<wordCount and rPunct~=" " then
			rPunct=rPunct.." "
		elseif x==wordCount and rPunct==" " then
			while rPunct==" " do
				punctIndex=math.floor(math.max(math.random(1,#gregese.punct+6)-6,1))
				rPunct=gregese.punct[punctIndex] or "."
			end
		end
		
		sentence=sentence..rWord..rPunct
	end
	effectUtil.say(sentence)
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function stun()
	if status.isResource("stunned") then
		if status.resourcePositive("health") then
			status.setResource("stunned",status.resourceMax("stunned") or math.huge)
		else
			status.setResource("stunned",0)
		end
	end
	if status.resourcePositive("health") then
		if status.isResource("energyRegenBlock") then
			status.setResource("energyRegenBlock",status.resourceMax("energyRegenBlock") or 60)
		end
	end
end