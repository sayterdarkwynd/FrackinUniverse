require'/scripts/fupower.lua'
require'/scripts/util.lua'
require "/scripts/poly.lua"
require "/scripts/vec2.lua"

local liquids

function init()
	--object.setInteractive(true)--useless, they dont do anything on interaction.
	storage.timer = storage.timer or 1
	power.init()
	power.update(0)
	storage.outputPos=entity.position()
	storage.outputPos[1]=storage.outputPos[1]+2+util.clamp(object.direction(),-1,0)
	wellRange=config.getParameter("airWellRange",20)
	liquids=config.getParameter("liquids")
	wellInit()
	setDesc()
end

function update(dt)
	if world.type() == 'playerstation' or world.type() == 'unknown' then
		if storage.timer <= 0 then
			storage.timer = 1
			animator.setAnimationState("machineState", "error")
		else
			storage.timer=storage.timer-dt
		end
		return
	end
	if not object.isInputNodeConnected(0) or object.getInputNodeLevel(0) then
		if not scanTimer or scanTimer > 1 then
			wellInit()
			setDesc()
			scanTimer=0
		else
			scanTimer=scanTimer+dt
		end
		if storage.timer > 0 then
			if power.consume(config.getParameter('isn_requiredPower')*dt) then
				animator.setAnimationState("machineState", "active")
				--storage.timer = storage.timer - (dt/wellsDrawing)
				storage.timer=storage.timer-(dt/math.sqrt(1+wellsDrawing))
			else
				animator.setAnimationState("machineState", "idle")
			end
		else
			local liquid = world.liquidAt(storage.outputPos)
			local value = worldInfo()
			if not liquid or (liquid[2] <= 0.5 and liquid[1] == value.liquid) then
				world.spawnLiquid(storage.outputPos,value.liquid,0.5)
				storage.timer = value.cooldown
			else
				animator.setAnimationState("machineState", "full")
			end
		end
	else
		animator.setAnimationState("machineState", storage.timer <=0 and "fullOff" or "idle")
	end
	power.update(dt)
end

function worldInfo()
	return liquids[world.type()] or liquids.other
end

function setDesc()
	local baseMessage="^blue;Input^reset;1^blue;:^reset; On/Off Switch\n^blue;Input^reset;2^blue;:^reset; Power"
	local color="^yellow;"
	local info
	if world.type() == 'playerstation' or world.type() == 'unknown' then
		color="^#7F7F7F;"
		info="Atmosphere: "..color.."Unusable.^reset;"
	else
		info = root.liquidConfig(worldInfo().liquid).config
		if info.color then
			color = "^#"..toHex(info.color[1])..toHex(info.color[2])..toHex(info.color[3])..";"
		end
		if info.itemDrop then
			info=root.itemConfig(info.itemDrop).config
			info="Atmosphere: "..color..info.shortdescription.."^reset;"
		else
			info="Atmosphere: "..color..info.name.."^reset;"
		end
	end
	--object.setConfigParameter('description',baseMessage.."\n"..info.."\n^red;Range:^gray; "..wellRange.."^reset;")
	object.setConfigParameter('description',baseMessage.."\n"..info.."\n^red;Range:^gray; "..wellRange.."\n^red;Wells in range:^gray; "..((wellsDrawing or 0)-1).."^reset;")
end

function toHex(num)
	local hex = string.format("%X", math.floor(num + 0.5))
	if num < 16 then hex = "0"..hex end
	return hex
end

function wellInit()
	if (not storage.wellPos) and object.spaces() then storage.wellPos=vec2.add(poly.center(object.spaces()),object.position()) end
	wellsDrawing=1+#(world.entityQuery(storage.wellPos or entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="fu_isAirWell"}) or {})
end

function fu_isAirWell() return (animator.animationState("machineState")=="active") end
