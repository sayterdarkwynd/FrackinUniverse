require "/scripts/effectUtil.lua"

gregese={words={"@#$@$#@","greeeeg","greg","gregga","gregggggga","gregogreg","pft","rainbow","donkey","ahahaha"},punct={" ","...","?!","?!?","!!!","!","?","!!","!?"}}


function init()
	if effect.sourceEntity then
		effectUtil.source=effect.sourceEntity()
	end
	local typeName=effectUtil.entityTypeName()
	isGreg=typeName=="greg" or typeName=="crewmembergreg"
	hardTarget=(status.stat("specialStatusImmunity")>0)
	stun(1)
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
			gregDate=0.0
			if donkey == 1 or donkey == 81 then
				if donkey == 1 then
					effectUtil.effectSelf("l6doomed",effect.duration()/(hardTarget and 2 or 1))
				else
					effectUtil.effectOnSource("l6doomed",effect.duration()*(hardTarget and 2 or 1))
				end
				skittleSay("Sayter.")
				special=true
			elseif donkey == 6 or donkey == 66 then
				stun()
				effectUtil.effectSelf("heal_1",effect.duration())
				effectUtil.effectSelf("cultistshield",effect.duration())
				skittleSay("Kevin.")
				special=true
			elseif donkey <= 3 or donkey == 33 then
				if hardTarget and not true then

				end
				effectUtil.effectSelf("partytime2",effect.duration()*donkey)
				skittleSay("Gregga greg. Donkey...RAINBOW RAINBOW RAINBOW!!!")
				special=true
			elseif donkey <= 9 then
				effectUtil.effectOnSource("nude",donkey*effect.duration()/10.0,true)
				if hardTarget and not effectUtil.effectOnSource("vulnerability",donkey*effect.duration()/10.0) then
					if effectUtil.effectPlayersInRange("vulnerability",100,donkey*effect.duration()/10.0) == 0 then
						kevinDamon=true
						effectUtil.effectSelf("heal_1",effect.duration())
						effectUtil.effectSelf("cultistshield",effect.duration())
					end
				end
				if kevinDamon then
					skittleSay("Kevin Damon.")
				else
					skittleSay("Matt Damon.")
				end
				special=true
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
	skittleSay(sentence)
end


function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function stun(duration)
	duration=not isGreg and duration or 0
	if status.isResource("stunned") and not (status.stat("stunImmunity") > 0) then
		status.setResource("stunned", duration)
	elseif duration > 0 then
		status.modifyResourcePercentage("health",duration*0.001*math.random(1,10))
	end
end

function skittleSay(sentence)
	effectUtil.say(isGreg and string.reverse(sentence) or sentence)
end