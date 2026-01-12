-- THIS IS THE FRACKIN RACES ONE
require "/scripts/util.lua"

function init()
	self.data = root.assetJson("/interface/scripted/statWindow/statWindow.config")
	self.elements = self.data.elements
	self.statuses = self.data.statuses
	self.extraOpen = false

	widget.setText("characterName", "^blue;"..world.entityName(player.id()))

	local playerRace = status.statusProperty("fr_race")
	local recognized = false
	for _,race in ipairs(self.data.races) do
		if race == playerRace then
			recognized = true
			break
		end
	end

	if not status.statusProperty("fr_enabled") then recognized = false end

	if recognized then
		widget.setImage("characterSuit", "/interface/scripted/techupgrade/suits/"..playerRace.."-"..player.gender()..".png")
		--widget.setText("racialLabel", "Racial traits - "..playerRace) --Moved into populateRacialDescription to get the friendly-text name.
		widget.setVisible("racialDesc", true)
		widget.setVisible("offline", false)

		populateRacialDescription(playerRace)
	else
		widget.setVisible("racialDesc", true)
		populateRacialDescription(playerRace,not recognized)
		widget.setText("racialLabel", "UNRECOGNIZED SPECIES")
	end
end

function update()
	for _, element in ipairs(self.elements) do
		widget.setText(element.."Resist", math.floor(status.stat(element.."Resistance")*100+0.5).."%")
	end

	widget.clearListItems("immunitiesList.textList")
	bufferList={}
	bufferPrioritiesFound={}
	for thing,stuff in pairs(self.statuses) do
		local skipping = false

		for _,skipped in ipairs(stuff.skip or {}) do
			if status.stat(skipped) >= 1 then
				skipping = true
				break
			end
		end

		if not skipping then
			if status.stat(thing) >= 1 then
				bufferList[thing]={name=stuff.name,priority=stuff.priority or -1}
				bufferPrioritiesFound[stuff.priority]=true
			end
		end
	end

	bufferPrioritiesRemapped={}
	for prio in pairs(bufferPrioritiesFound) do
		bufferPrioritiesRemapped[#bufferPrioritiesRemapped+1]=prio
	end

	table.sort(bufferPrioritiesRemapped)
	bufferPrioritiesRemapped[#bufferPrioritiesRemapped+1]=-1

	for _,priority in ipairs(bufferPrioritiesRemapped) do
		for thing,stuff in pairs(bufferList) do
			if(priority==stuff.priority) then
				local listItem = "immunitiesList.textList."..widget.addListItem("immunitiesList.textList")
				widget.setText(listItem..".immunity", stuff.name)
				bufferList[thing]=null
			end
		end
	end
end

function expand()
	player.interact("ScriptPane", "/interface/scripted/statWindow/extraStatsWindow.config", player.id())
end

function loreBook()
	player.interact("ScriptPane", "/interface/scripted/xcustomcodex/xcodexui.config", player.id())
end
function research()
	player.interact("ScriptPane", "/zb/researchTree/researchTree.config", player.id())
end

function mechEquip()
	player.interact("ScriptPane", "/interface/scripted/mechassembly/mechassemblygui.config", player.id())
end
function mechFuel()
	player.interact("ScriptPane", "/interface/mechfuel/mechfuel.config", player.id())
end

function techBuild()
	player.interact("ScriptPane", "/interface/scripted/techshop/techshop.config", player.id())
end
function techEquip()
	player.interact("ScriptPane", "/interface/scripted/techupgrade/techupgradegui.config", player.id())
end
function loadGPS()
	player.interact("ScriptPane", "/interface/kukagps/kukagps.config", player.id())
end

function populateRacialDescription(race,notRecognized)
	widget.clearListItems("racialDesc.textList")
	local JSON = (notRecognized and {charCreationTooltip={description="Please check SAIL's '^cyan;Misc.^reset;' tab if you believe this is in error."}}) or root.assetJson("/species/"..race..".species")
	--local charGenLabels = JSON.charGenTextLabels
	--local racialName = charGenLabels[#charGenLabels-1] --NOTE: In the species file there is the character generation label list. The second to last is the user-friendly display name of the race.
	--Edit: Go with the character creation tooltip title.
	local racialName = (notRecognized and "") or JSON.charCreationTooltip.title
	widget.setText("racialLabel", "Racial Traits - " .. racialName)

	local str = JSON.charCreationTooltip.description
--work smart, not hard, bucko.
--[[	local strTbl = {}
	local splitters = {}
	local lists = {}
	local startFound = false
	local skipped = 0
	local skip = false
	local firstskip = false
	local char = ""

	str=string.gsub(str,"\r\n","\n")
	local str2=str
	while str~=string.gsub(str," \n","\n") do
		str=string.gsub(str," \n","\n")
	end]]
	str=string.gsub(str,"\n      ","\n^gray;>>>^reset;")
	str=string.gsub(str,"\n    ","\n^gray;>>^reset;")
	str=string.gsub(str,"\n  ","\n^gray;>^reset;")
	--all of this was unnecessary. all it took was a single, properly formatted, text element.
	--[[local wordWall={}
	local line={}
	local sentence=""

	for i = 1, string.len(str) do
		local c = string.sub(str, i, i)
		if c == "\n" or i==string.len(str) then
			if (i==(string.len(str))) then table.insert(line,c) end
			if util.tableSize(line) > 0 then
				local sentenceSize=0
				local word={}
				local wordTest=""
				local colorTest=""
				for i = 1, #line do
					local c2=line[i]
					if i==#line or c2==" " then
						if i==#line and not (c2==" ") then
							table.insert(word,c2)
						end
						local heightened=false
						for k = 1, #word do
							local c3 = word[k]
							if c3=="^" then
								heightened=true
								colorTest=c3
							elseif heightened and c3==";" then
								colorTest=colorTest..c3
								heightened=false
							elseif not heightened then
								wordTest=wordTest..c3
							else
								colorTest=colorTest..c3
							end
						end
						--sb.logInfo("%s <adding to> %s",wordTest,sentence)
						if (string.len(stripTagging(sentence)) + string.len(wordTest)) > 28 then
							table.insert(wordWall,sentence)
							sentence=colorTest
						end
						if string.len(sentence) > 0 then sentence = sentence.." " end
						sentence=sentence..table.concat(word)
						word={}
						wordTest=""
					else
						table.insert(word,c2)
					end
				end
				table.insert(wordWall,sentence)
				sentence=""
			end
			line={}
		else
			table.insert(line,c)
		end
	end
	for i = 1, #wordWall do
		local listItem = "racialDesc.textList."..widget.addListItem("racialDesc.textList")
		--widget.setSize(listItem,{})
		widget.setText(listItem..".trait", wordWall[i])
	end]]
	widget.setText("racialDesc.textElement", str)
end

function upgradeEquipmentMenu()
	player.interact("ScriptPane", "/interface/scripted/fu_upgradetable/fu_upgradetable.config", player.id())
end
