
-- Do NOT attempt to print strings through Lua if the string holds a non-modifier % in it. (i.e 20%)
-- Add another % before it so Lua reads it like a normal % and not a modifier checker

frackinRaces = false
elements = {"physical", "fire", "poison", "cold", "shock", "radiation", "cosmic", "death", }
validRaces = {"apex", "avian", "floran", "glitch", "human", "hylotl", "novakid"}
statuses = {
	-- Structure:
	-- {statusName, visibleDescription, toSkip1, toSkip2, etc...}
	-- Adding variables after the 2nd will tell the system to skip those immunities to reduce clutter in situationes like Cold I + Cold II
	-- Ofcourse that means that the status that tells the system to skip an effect has to come before any effects it tells it to skip
	toSkip = {},
	
	-- Cold
	{ "liquidnitrogenImmunity", "^#4BF3FD;Liquid Nitrogen", "nitrogenfreezeImmunity", },
	{ "nitrogenfreezeImmunity", "^#4BF3FD;Nitrogen Freeze", },
	{ "ffextremecoldImmunity", "^#4BF3FD;Cold II", "biomecoldImmunity", },
	{ "biomecoldImmunity", "^#4BF3FD;Cold I", },
	
	-- Blocks
	{ "quicksandImmunity", "^yellow;Quick Sand", },
	{ "snowslowImmunity", "^#4BF3FD;Snow Slow", },
	{ "slushslowImmunity", "^#4BF3FD;Slush Slow", },
	{ "iceslipImmunity", "^#4BF3FD;Ice Slipping", },
	{ "fumudslowImmunity", "^brown;Mud Slow", },
	{ "fujungleslowImmunity", "^green;Jungle Slow", },
	
	{ "slimefrictionImmunity", "^#61D13F;Slime Bounce", },
	{ "slimestickImmunity", "^#61D13F;Lingering Slime", },
	{ "slimeImmunity", "^#61D13F;Slime", },
	
	-- Liquids
	{ "waterbreathProtection", "^blue;Drowning", },
	{ "biooozeImmunity", "^#78f04f;Bio-Ooze", },
	{ "pusImmunity", "^yellow;Puss", },
	{ "gravrainImmunity", "^gray;Gravity Rain", },
	{ "blacktarImmunity", "^#5B6177;Black Tar", "tarImmunity", },
	{ "tarImmunity", "^#5B6177;Tar", },
	
	-- Fire
	{ "ffextremeheatImmunity", "^#FDBE4B;Heat II", "biomeheatImmunity", },
	{ "biomeheatImmunity", "^#FDBE4B;Heat I", },
	{ "lavaImmunity", "^#C83E14;Lava", },
	
	-- Specific
	{ "sandstormImmunity", "^orange;Sandstorm", },
	{ "breathProtection", "Breath", },
	{ "gasImmunity", "^#D1E160'Gas", },
	{ "stunImmunity", "^gray;Stun", },
	{ "asteroidImmunity", "^gray;Asteroids", },
	{ "sulphuricImmunity", "^#ffd800;Sulphuric Acid", },
	{ "protoImmunity", "^#78f04f;Proto-Poison", },
	{ "extremepressureProtection", "^gray;Extreme Pressure", "pressureProtection", },
	{ "pressureProtection", "^gray;Pressure", },
	{ "shadowImmunity", "^#3F2E4D;Shadow", },
	{ "aetherImmunity", "^#E33FFF;Aether", },
	{ "insanityImmunity", "^#EA907E;Insanity", },
	
	-- Bees
	{ "beestingImmunity", "^#ffae00;Bee Stings", },
	{ "honeyslowImmunity", "^#FFEC84;Honey Slow", },
	
	-- Status
	{ "electricStatusImmunity", "^#FFE149;Electrification", },
	{ "poisonStatusImmunity", "^#D1E160;Poisoning", },
	{ "fireStatusImmunity", "^#FDBE4B;Burning", },
	{ "iceStatusImmunity", "^#4BF3FD;Freeze", },
	
	-- Radiation
	{ "ffextremeradiationImmunity", "^yellow;Radiation II", "biomeradiationImmunity", },
	{ "biomeradiationImmunity", "^yellow;Radiation I", },
	{ "radiationburnImmunity", "^yellow;Radiation Burn", },
}

function init()
	widget.setText("characterName", "^blue;"..world.entityName(player.id()))
	
	local playerRace = player.species()
	for _,race in ipairs(validRaces) do
		if race == playerRace then
			widget.setImage("characterSuit", "/interface/scripted/techupgrade/suits/"..playerRace.."-"..player.gender()..".png")
			break
		end
	end
	
	if frackinRaces then
		-- widget.setText("racialLabel", "Racial traits - "..playerRace)
		widget.setVisible("racialDesc", true)
	else
		widget.setText("racialLabel", "SoonTM")
	end
	
	populateRacialDescription()
	refresh()
end

function refresh()
	for _, element in ipairs(elements) do
		widget.setText(element.."Resist", tostring(avarage(status.stat(element.."Resistance")*100)).."%")
	end
	
	widget.clearListItems("immunitiesList.textList")
	for i = 1, #statuses do
		local tbl = statuses[i]
		local name = tbl[1]
		local skipping = false
		
		for _,skipped in ipairs(statuses.toSkip) do
			if skipped == name then
				skipping = true
				break
			end
		end
		
		if not skipping then 
			if status.stat(name) >= 1 then
				local listItem = "immunitiesList.textList."..widget.addListItem("immunitiesList.textList")
				widget.setText(listItem..".immunity", tbl[2])
				
				for j = 3, #tbl do
					table.insert(statuses.toSkip, tbl[j])
				end
			end
		end
	end
end

function avarage(num)
	local low = math.floor(num)
	local high = math.ceil(num)
	if math.abs(num - low) < math.abs(num - high) then
		return low
	else
		return high
	end
end

function populateRacialDescription()
	widget.clearListItems("racialDesc.textList")
	
	-- using 'for i' loop because 'i/pairs' tends to fuck up order
	
	--[[
	for i = 1, #racialDescription.positive do
		local listItem = "racialDesc.textList."..widget.addListItem("racialDesc.textList")
		local text = "^green;"..racialDescription.positive[i]
		widget.setText(listItem..".trait", text)
	end
	
	for i = 1, #racialDescription.negative do
		local listItem = "racialDesc.textList."..widget.addListItem("racialDesc.textList")
		local text = "^red;"..racialDescription.negative[i]
		widget.setText(listItem..".trait", text)
	end]]
end