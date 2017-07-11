
require "/zz/scripts/textTyper.lua"
textData = {}
textData.currentRace = ""

textData.avian = {
	welcome = "^cyan;Avian:^reset; Hello [playername]!\n[(tp)10]Please let us know if you need anything!\noh...[(tp)1000] and how about [(instant)a lot of fucking instant text just for the keks.]",
	chat1 = "avian chat1",
	chat2 = "avian chat2",
	chat3 = "avian chat3",
}

textData.floran = {
	welcome = "^green;Floran:^reset; Hello [playername]!\n[(tp)10]Please let us know if you need anything!\noh...[(tp)1000] and how about [(instant)a lot of fucking instant text just for the keks.]",
	chat1 = "floran chat1",
	chat2 = "floran chat2",
	chat3 = "floran chat3",
}

function init()
	if math.random() < 0.5 then
		textData.currentRace = "avian"
	else
		textData.currentRace = "floran"
	end
	
	writerInit(textData, textData.currentRace, "welcome")
end

function update()
	writerUpdate(textData)
	widget.setText("visibleText", textData.written)
end

function chat()
	pane.setTitle(" "..textData.currentRace.." dialogue", " Text panel")
	writerInit(textData, textData.currentRace, "chat"..math.random(1,3))
end
