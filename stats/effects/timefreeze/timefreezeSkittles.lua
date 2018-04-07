
gregese={words={"@#$@$#@","greeeeg","greg","gregga","gregggggga","gregogreg","pft","rainbow","donkey","ahahaha"},punct={" ","...","?!","?!?","!!!","!","?","!!","!?"}}


function init()
	if effect.sourceEntity then
		source=effect.sourceEntity()
	end
	--"specialStatusImmunity"
	hardTarget=(status.stat("specialStatusImmunity")>0)
	--sb.logInfo("%s",{status=status,effect=effect})
	--effect.setParentDirectives("fade=6a2284=0.4")
	stun(1)

	--mcontroller.setVelocity({0, 0})
end

function update(dt)
	if status.resource("health") <= 0.0 then
		stun()
		effect.expire()
		return
	else
		if not gregDate or gregDate > 1.0 then
			stun((gregDate or 1.0)*1.3)
			local donkey=math.floor(math.random(1,81))
			--sb.logInfo("Donkey %s",donkey)
			gregDate=0.0
			if donkey == 1 or donkey == 81 then
				if donkey == 1 then
					effectSelf("l6doomed",effect.duration()/(hardTarget and 2 or 1))
				else
					effectOnSource("l6doomed",effect.duration()*(hardTarget and 2 or 1))
				end
				say("Sayter.")
				special=true
			elseif donkey == 6 or donkey == 66 then
				stun()
				effectSelf("heal_1",effect.duration())
				effectSelf("cultistshield",effect.duration())
				say("Kevin.")
				special=true
			elseif donkey <= 3 or donkey == 33 then
				effectSelf("partytime2",effect.duration()*donkey)
				say("Gregga greg. Donkey...RAINBOW RAINBOW RAINBOW!!!")
				special=true
			elseif donkey <= 9 then
				if source then
					effectOnSource("nude",donkey*effect.duration()/10.0)
					if hardTarget then
						effectOnSource("vulnerability",donkey*effect.duration()/10.0)
					end
					say("Matt Damon.")
					special=true
				end
			end
			if special then
				effect.expire()
				return
			else
				spaz(math.floor(donkey/9.0))
			end
		else
			gregDate=gregDate+dt*(math.random(1,10)/10.0)
		end

		--mcontroller.setVelocity({0, 0})
		mcontroller.controlModifiers({
			facingSuppressed = true,
			movementSuppressed = true
		})
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
	say(sentence)
end


function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function say(sentence)
	if world.entityType(entity.id()) =="npc" then
		world.callScriptedEntity(entity.id(),"npc.say",sentence)
	elseif  world.entityType(entity.id())=="monster" then
		world.callScriptedEntity(entity.id(),"monster.say",sentence)
	end
end

function effectInRange(range,effect,duration)
	local buffer=util.mergeLists(world.npcQuery(activeItem.ownerAimPosition(),range),world.monsterQuery(activeItem.ownerAimPosition(),range))
	for _,id in pairs(buffer) do
		--world.sendEntityMessage(id,"applyStatusEffect",effect,duration,activeItem.ownerEntityId())
		effectTarget(id,effect,duration)
	end
end

function stun(duration)
	duration=duration or 0
	if status.isResource("stunned") and not (status.stat("stunImmunity") > 0) then
		status.setResource("stunned", duration)
	elseif duration > 0 then
		status.modifyResourcePercentage("health",duration*0.1)
	end
end

function effectSelf(effect,duration)
	status.addEphemeralEffect(effect,duration,source)
end

function effectOnSource(effect,duration)
	effectTarget(source,effect,duration)
end

function effectTarget(id,effect,duration)
	world.sendEntityMessage(id,"applyStatusEffect",effect,duration,source)
end