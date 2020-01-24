require'/scripts/power.lua'
require'/scripts/util.lua'

liquids = {
	aethersea = {liquid=100,cooldown=2},
	moon = {liquid=49,cooldown=2},
	moon_desert = {liquid=49,cooldown=2},
	moon_shadow = {liquid=49,cooldown=2},
	moon_stone = {liquid=49,cooldown=2},
	moon_volcanic = {liquid=49,cooldown=2},
	moon_toxic = {liquid=49,cooldown=2},
	atropus = {liquid=53,cooldown=2},
	atropusdark = {liquid=53,cooldown=2},
	fugasgiant = {liquid=62,cooldown=2},
	bog = {liquid=12,cooldown=2},
	chromatic = {liquid=69,cooldown=2},
	crystalmoon = {liquid=43,cooldown=2},
	nitrogensea = {liquid=56,cooldown=2},
	infernus = {liquid=2,cooldown=2},
	infernusdark = {liquid=2,cooldown=2},
	slimeworld = {liquid=13,cooldown=2},
	strangesea = {liquid=41,cooldown=2},
	sulphuric = {liquid=46,cooldown=2},
	tarball = {liquid=42,cooldown=2},
	toxic = {liquid=3,cooldown=2},
	metallicmoon = {liquid=52,cooldown=3},
	lightless = {liquid=100,cooldown=3},
	penumbra = {liquid=60,cooldown=4},
	protoworld = {liquid=44,cooldown=5},
	irradiated = {liquid=47,cooldown=2},
	other = {liquid=1,cooldown=2}
}

function init()
	--object.setInteractive(true)--useless, they dont do anything on interaction.
	storage.timer = storage.timer or 1
	power.init()
	power.update()
	storage.outputPos=entity.position()
	storage.outputPos[1]=storage.outputPos[1]+2+util.clamp(object.direction(),-1,0)
	wellRange=config.getParameter("airWellRange",20)
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
		if not deltaTime or deltaTime > 1 then
			wellInit()
			deltaTime=0
		else
			deltaTime=deltaTime+dt
		end
		if storage.timer > 0 then
			if power.consume(config.getParameter('isn_requiredPower')*dt) then
				animator.setAnimationState("machineState", "active")
				storage.timer = storage.timer - (dt/wellsDrawing)
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
	local baseMessage="^blue;Input^reset;1^blue;:^reset; Logic\n^blue;Input^reset;2^blue;:^reset; Power"
	local color="^yellow;"
	local info="Standby."
	if world.type() == 'playerstation' or world.type() == 'unknown' then
		info="Atmosphere: "..color.."Unusable.^reset;"
		color="^#7F7F7F;"
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
	object.setConfigParameter('description',baseMessage.."\n"..info.."\n^red;Range:^gray; "..wellRange.."^reset;")
end

function toHex(num)
	local hex = string.format("%X", math.floor(num + 0.5))
	if num < 16 then hex = "0"..hex end
	return hex
end

function wellInit()
	wellsDrawing=1+#(world.entityQuery(entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="fu_isAirWell"}) or {})
end

function fu_isAirWell() return (animator.animationState("machineState")=="active") end