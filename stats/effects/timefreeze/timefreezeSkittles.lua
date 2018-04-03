
gregese={words={"@#$@$#@","greeeeg","greg","gregga","gregggggga","gregogreg","pft","rainbow","donkey","ahahaha"},punct={" ","...","?!","?!?","!!!","!","?","!!","!?"}}


function init()
  --effect.setParentDirectives("fade=6a2284=0.4")
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end

  --mcontroller.setVelocity({0, 0})
end

function update(dt)
	if not gregDate or gregDate > 1.0 then
		spaz(math.floor(math.random(1,81)/9))
		gregDate=0.0
	else
		gregDate=gregDate+dt*(math.random(1,10)/10.0)
	end

	--mcontroller.setVelocity({0, 0})
	mcontroller.controlModifiers({
		facingSuppressed = true,
		movementSuppressed = true
	})
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
	if world.entityType(entity.id()) =="npc" then
		world.callScriptedEntity(entity.id(),"npc.say",sentence)
	elseif  world.entityType(entity.id())=="monster" then
		world.callScriptedEntity(entity.id(),"monster.say",sentence)
	end
end


function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
