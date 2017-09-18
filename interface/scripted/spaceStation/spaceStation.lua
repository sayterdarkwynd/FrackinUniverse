
require "/scripts/textTyper.lua"

--	NOTES:

--	IDEAS:
-- Make the pixel count turn red if the player cant afford it
-- Disable the buy button if the player is short on pixels

--	TO DO:
-- Have the 'Hire Crew' command give the player a contract for the NPC they hired


textData = {}
textData.defaultButtonStates = {"Chat", "Quest", "Shop", "Trade Goods", "Special", "Goodbye"}
textData.specialListPopulated = false
textData.currentRace = ""
textData.stationType = ""

textData.example = function()
	sb.logError("This message will appear when called through the textTyper via [(function)example] in the sent string","")
end

-- Creates tables for every listed race
races = {"avian", "apex", "human", "hylotl", "glitch", "novakid", "floran"}
for _,race in ipairs(races) do
	textData[race] = {}
end

---------------------- DIALOGUE TEXTS ----------------------
------------------------------------------------------------
-- This has to be defined separetly because otherwise it won't be detected in the definition where its used
textData.floran.questBriefing = "Go to planet ^orange;[(data)questData.current.planet]^reset; and kill ^orange;[(data)questData.current.target]^reset;.\n\nYou have ^orange;[(data)questData.current.time]^reset; to complete the task, and will be rewarded with ^orange;[(data)questData.current.reward]^reset;."
textData.novakid.questBriefing = "quest"

textData.floran = {
	-- welcome = "Hello [playername], and welcome to the ^orange;Alpha Centauri^reset; medical research center!\nNormally we have tasks that require outside help, so if you're looking to make a profit, I'm sure we have something for you.\nIn addition, we buy and sell all sorts of items and goods. Since this is a medical lab, we mainly sell and export medical supplies and equipment.\nAnd finally, we provide specialized body enhancements services that last for quite a while, and stay with you even after death.",
	welcome = "",
	
	chat1	= "Blablablablablablabla, ^red;blablabla!? BLABLABLA!!!^reset;\n[(pause)10]Bla?\n[(pause)20].[(pause)20].[(pause)20].\n^red;R^orange;A^yellow;I^green;N^cyan;B^blue;O^#9932CC;W^reset;\n^red;[(instant)explosions and screams heard in the distance]^reset;\n[(pause)20]Bla! Blablablablablabla!\nBLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA!!!\n^red;END OF TRANSMISSION^reset;",
	chat2	= "Wonderful day outside, isn't it?",
	chat3	= "Have you heard of the high elves?",
	chat4	= "I AM A BEACON OF KNOWLEDGE BLAZING OUT ACROSS A BLACK SEA OF IGNORANCE!",
	chat5	= "mama mia[(pause)10]\npapa pia[(pause)10]\nbaby got the diarrrrrrrrrrrrrrrrrrRRRRRRRRRRHEEEEEEEEEEEEEEEEEEEEEAAAAAAAAAAAA",
	chat6	= "From the Ghastly Eyrie I can see to the ends of the world, and from this vantage point I declare with utter certainty that this one is in the bag!",
	chat7	= "According to all known laws of aviation, there is no way a bee should be able to fly.\nIts wings are too small to get its fat little body off the ground.\nThe bee, of course, flies anyway because bees don't care what humans think is impossible.\nYellow, black. Yellow, black.\nYellow, black. Yellow, black.\nOoh, black and yellow!\nLet's shake it up a little.\nBarry! Breakfast is ready!\nOoming!\nHang on a second.\nHello?\n- Barry?\n- Adam?\n- Oan you believe this is happening?\n- I can't. I'll pick you up.\nLooking sharp.\nUse the stairs. Your father\npaid good money for those.\nSorry. I'm excited.\nHere's the graduate.\nWe're very proud of you, son.",
	chat8	= "Now this is a story all about how\nMy life got flipped-turned upside down\nAnd I'd like to take a minute\nJust sit right there\nI'll tell you how I became the prince of a town called Bel-Air\nIn west Philadelphia born and raised\nOn the playground was where I spent most of my days\nChillin' out maxin' relaxin' all cool\nAnd all shooting some b-ball outside of the school\nWhen a couple of guys who were up to no good\nStarted making trouble in my neighborhood\nI got in one little fight and my mom got scared\nShe said, 'You're movin' with your auntie and uncle in Bel-Air.'",
	chat9	= "Nice meme!",
	chat10	= "^red;ARE YOU NOT ENTERTAINED!?",
	
	questStage0 = "Why yes, we do have a task that needs completing.\n\n"..textData.floran.questBriefing,
	questStage1 = "Finish your previous assigment before asking for another.",
	questStage2 = "Unfortunetly, you've failed to uphold your part of the deal.\nTherefore, we shall not pay you the promised ^orange;[(data)questData.current.reward]^reset;.",
	questStage3 = "Well done!\nWe shall now tranfer you the promised ^orange;[(data)questData.current.reward]^reset;.",
	
	questNone		= "Sorry, we do not have anything that needs taking care of at the moment.",
	questDecline	= "Oh well, another time perhaps.\nDon't forget you can ask for an easier task, unless it was the easier task you've declined, in which case I pity you.",
	questAccept		= "I'm sending the details and a more specific location to your quest log right now.\nGood luck, and remember - we won't be paying you should you not meet one of the conditions.",
	questEasier		= "Easier?\nYour impression was of someone who could complete the task, guess I was wrong.\nBut its good to know the limit of your abilities, and for that I respect you.\n\n"..textData.floran.questBriefing,
	questHarder		= "Harder? Thats the spirit!\nJust let me remind you - Should you fail to meet any of the conditions, you will not be payed at all.\n\n"..textData.floran.questBriefing,
	
	militarySpecial		= "As a military station, our special service is allowing you to hire new crew members. The price goes up with the quality, so does the return when they save your ass from some otherwordly monstrocity. Sadly, we can only spare one crew member per captain. We don't want to end up being the ones in need of crew members...",
	medicalSpecial		= "As a medical research lab, our special service is providing you with all sort of long lasting enhancers, for the right price of course.\ndue to health hazard, only one enhancer can be applied once per 48 hours.\nOn the bright side, they stay with you even after death!",
	scientificSpecial	= "As a scientific research lab, we specialize in synthesysing all sorts of materials, and are willing to trade them for others.\nBe sure to check in often though, we don't always have or need the same materials!",
	tradingSpecial		= "As a trading center, we care primarly about pixels and their value.\nShould you be able to raise a high enough amount and invest in us, we'll make sure it'll be worth your while.\nNot only will we recieve new goods to sell and buy your items at a higher rate, but we'll also return a small percentage of our earnings onces in a while.",
	returnSpecial		= "Was there anything else you wanted?",
	
	cantAfford1 = "Seems like you're a bit short on pixels...",
	cantAfford2 = "You're low on pixels.",
	cantAfford3 = "You can not afford that.",
	cantAfford4 = "You'll need more pixels",
	
	acquireEnhancer		= "Come back in 48 hours if you want another one!\nOh, and side effects may include: dry mouth, nausea, vomiting, water retention, painful rectal itch, hallucination, dementia, psychosis, coma, death, and halitosis.",
	cooldownEnhancer	= "I'm sorry, but for your own safety we cannot provide you with another enhancer for the next ^orange;[(data)medicalSpecialCooldownRemaining.hours] hours^reset;, ^orange;[(data)medicalSpecialCooldownRemaining.minutes] minutes^reset;, and ^orange;[(data)medicalSpecialCooldownRemaining.seconds] seconds^reset;.",
	
	hireMerc	= "Heres the contract, use it to call and recruit them.",
	noMoreMerc	= "Sorry, we only allow one crewmate per captain.\nTry checking other military stations if you're in need for more crewmates.",
}

textData.novakid = {
	welcome = "Hello [playername], and welcome to the ^orange;Alpha Centauri^reset; medical research center!\nNormally we have tasks that require outside help, so if you're looking to make a profit, I'm sure we have something for you.\nIn addition, we buy and sell all sorts of items and goods. Since this is a medical lab, we mainly sell and export medical supplies and equipment.\nAnd finally, we provide specialized body enhancements services that last for quite a while, and stay with you even after death.",
	
	chat1	= "Blablablablablablabla, ^red;blablabla!? BLABLABLA!!!^reset;\n[(pause)10]Bla?\n[(pause)20].[(pause)20].[(pause)20].\n^red;R^orange;A^yellow;I^green;N^cyan;B^blue;O^#9932CC;W^reset;\n^red;[(instant)explosions and screams heard in the distance]^reset;\n[(pause)20]Bla! Blablablablablabla!\nBLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA!!!\n^red;END OF TRANSMISSION^reset;",
	chat2	= "Wonderful day outside, isn't it?",
	chat3	= "Have you heard of the high elves?",
	chat4	= "I AM A BEACON OF KNOWLEDGE BLAZING OUT ACROSS A BLACK SEA OF IGNORANCE!",
	chat5	= "mama mia[(pause)10]\npapa pia[(pause)10]\nbaby got the diarrrrrrrrrrrrrrrrrrRRRRRRRRRRHEEEEEEEEEEEEEEEEEEEEEAAAAAAAAAAAA",
	chat6	= "From the Ghastly Eyrie I can see to the ends of the world, and from this vantage point I declare with utter certainty that this one is in the bag!",
	chat7	= "According to all known laws of aviation, there is no way a bee should be able to fly.\nIts wings are too small to get its fat little body off the ground.\nThe bee, of course, flies anyway because bees don't care what humans think is impossible.\nYellow, black. Yellow, black.\nYellow, black. Yellow, black.\nOoh, black and yellow!\nLet's shake it up a little.\nBarry! Breakfast is ready!\nOoming!\nHang on a second.\nHello?\n- Barry?\n- Adam?\n- Oan you believe this is happening?\n- I can't. I'll pick you up.\nLooking sharp.\nUse the stairs. Your father\npaid good money for those.\nSorry. I'm excited.\nHere's the graduate.\nWe're very proud of you, son.",
	chat8	= "Now this is a story all about how\nMy life got flipped-turned upside down\nAnd I'd like to take a minute\nJust sit right there\nI'll tell you how I became the prince of a town called Bel-Air\nIn west Philadelphia born and raised\nOn the playground was where I spent most of my days\nChillin' out maxin' relaxin' all cool\nAnd all shooting some b-ball outside of the school\nWhen a couple of guys who were up to no good\nStarted making trouble in my neighborhood\nI got in one little fight and my mom got scared\nShe said, 'You're movin' with your auntie and uncle in Bel-Air.'",
	chat9	= "Nice meme!",
	chat10	= "^red;ARE YOU NOT ENTERTAINED!?",
	
	questStage0 = "Why yes, we do have a task that needs completing.\n\n"..textData.novakid.questBriefing,
	questStage1 = "Finish your previous assigment before asking for another.",
	questStage2 = "Unfortunetly, you've failed to uphold your part of the deal.\nTherefore, we shall not pay you the promised ^orange;[(data)questData.current.reward]^reset;.",
	questStage3 = "Well done!\nWe shall now tranfer you the promised ^orange;[(data)questData.current.reward]^reset;.",
	
	questNone		= "Sorry, we do not have anything that needs taking care of at the moment.",
	questDecline	= "Oh well, another time perhaps.\nDon't forget you can ask for an easier task, unless it was the easier task you've declined, in which case I pity you.",
	questAccept		= "I'm sending the details and a more specific location to your quest log right now.\nGood luck, and remember - we won't be paying you should you not meet one of the conditions.",
	questEasier		= "Easier?\nYour impression was of someone who could complete the task, guess I was wrong.\nBut its good to know the limit of your abilities, and for that I respect you.\n\n"..textData.novakid.questBriefing,
	questHarder		= "Harder? Thats the spirit!\nJust let me remind you - Should you fail to meet any of the conditions, you will not be payed at all.\n\n"..textData.novakid.questBriefing,
	
	militarySpecial		= "As a military station, our special service is allowing you to hire new crew members. The price goes up with the quality, so does the return when they save your ass from some otherwordly monstrocity. Sadly, we can only spare one crew member per captain. We don't want to end up being the ones in need of crew members...",
	medicalSpecial		= "As a medical research lab, our special service is providing you with all sort of long lasting enhancers, for the right price of course.\ndue to health hazard, only one enhancer can be applied once per 48 hours.\nOn the bright side, they stay with you even after death!",
	scientificSpecial	= "As a scientific research lab, we specialize in synthesysing all sorts of materials, and are willing to trade them for others.\nBe sure to check in often though, we don't always have or need the same materials!",
	tradingSpecial		= "As a trading center, we care primarly about pixels and their value.\nShould you be able to raise a high enough amount and invest in us, we'll make sure it'll be worth your while.\nNot only will we recieve new goods to sell and buy your items at a higher rate, but we'll also return a small percentage of our earnings onces in a while.",
	returnSpecial		= "Maybe another time then...\nAnything else?",
	
	cantAfford1 = "Seems like you're a bit short on pixels...",
	cantAfford2 = "You're low on pixels.",
	cantAfford3 = "You can not afford that.",
	cantAfford4 = "You'll need more pixels",
	
	acquireEnhancer		= "Come back in 48 hours if you want another one!\nOh, and side effects may include: dry mouth, nausea, vomiting, water retention, painful rectal itch, hallucination, dementia, psychosis, coma, death, and halitosis.",
	cooldownEnhancer	= "I'm sorry, but for your own safety we cannot provide you with another enhancer for the next ^orange;[(data)medicalSpecialCooldownRemaining.hours] hours^reset;, ^orange;[(data)medicalSpecialCooldownRemaining.minutes] minutes^reset;, and ^orange;[(data)medicalSpecialCooldownRemaining.seconds] seconds^reset;.",
	
	hireMerc	= "Heres the contract, use it to call and recruit them.",
	noMoreMerc	= "Sorry, we only allow one crewmate per captain.\nTry checking other military stations if you're in need for more crewmates.",
}

textData.questData = {
	dif0 = {
		planet = "Earth",
		target = "a bunch of hippies",
		time = "90 minutes",
		reward = "300 pixels",
	},
	dif1 = {
		planet = "Altair II",
		target = "a pack of mutant spiders",
		time = "60 minutes",
		reward = "1000 pixels",
	},
	dif2 = {
		planet = "Anteras III",
		target = "an elite squadron",
		time = "30 minutes",
		reward = "5000 pixels & 200 ancient essence",
	},
	current = {
		planet = "",
		target = "",
		time = "",
		reward = "",
		difficulty = 1,	-- 0 = easy | 1 = normal | 2 = hard
		stage = 0,		-- 0 = not started | 1 = in progress | 2 = failed | 3 = complete (reward ready to be claimed)
	},
}

---------------------- STATION TRADING/SPECIAL VALUES ----------------------
----------------------------------------------------------------------------

stationGoods = {
	{name = "foodgoods",		basePrice = 100,	baseAmount = 80,	stock = 200,},
	{name = "mineralgoods",		basePrice = 150,	baseAmount = 80,	stock = 100,},
	{name = "medicalgoods",		basePrice = 250,	baseAmount = 130,	stock = 120,},
	{name = "electronicgoods",	basePrice = 350,	baseAmount = 220,	stock = 80,	},
	{name = "chemicalgoods",	basePrice = 500,	baseAmount = 100,	stock = 60,	},
	{name = "luxurygoods",		basePrice = 650,	baseAmount = 100,	stock = 90,	},
	{name = "militarygoods",	basePrice = 800,	baseAmount = 50,	stock = 35,	},
	{name = "contrabandgoods",	basePrice = 1000,	baseAmount = 5,		stock = 2,	},
}

stationSpecials = {}

-- 	{ displayed name, price, icon, effect name, duration, description }
stationSpecials.medical = {
	cooldown = 30,			-- In seconds, since purchase
	purchaseTime = 0,		-- Player time when purhased
	{ "^yellow;Miners Sense",			5000,	"/items/generic/other/yellowstim.png",		"runboost",	10,	"Increases mining equipment efficiency, and allows you to detect ores in a small radius around you.\nIn return, reduces damage output, and movement speed."},
	{ "^red;Berserks Rage",				6000,	"/items/generic/other/redstim.png", 		"runboost",	10,	"Increases damage output, energy regeneration, and speed.\nIn return, drastically reduces defence and makes you more suspectible to knockbacks."},
	{ "^blue;Oceanids Embrace",			7000,	"/items/generic/other/bluestim.png",		"runboost",	10,	"Renders you immune to breathing effects and gasses, while also greatly boosting your swiming speed.\nIn return, your movement, energy and health regenerations are slowed down."},
	{ "^green;Survivalists Instincts",	4500,	"/items/generic/other/greenstim.png",		"runboost",	10,	"Hunger rate is drastically reduced, while drop rates and health are increased.\nIn return, Once you beam down on a planet, your only way back up is death."},
	{ "^orange;Warriors Vendetta",		5700,	"/items/generic/other/orangestim.png",		"runboost",	10,	"Damage output, health, armor, and resistances are increased.\nIn return, if you do not kill something for more than 30 seconds, you will start losing health."},
	{ "^#9932CC;Test Vial #83",			8338,	"/items/generic/other/synthesisstim.png",	"runboost",	10,	"A strange enhancer with seemingly random effect.\nConstantly applies random buffs and debuffs."},
}

--	{ displayed name, price, icon, description }
stationSpecials.military = {
	mercHired = false,
	{ "^gray;Spec Ops",					5000,	"/items/armors/human/human-tier4/icons.png:head",			"A soldier specialized in fucking up franchises.\n^green;+25% damage, +10 protection"},
	{ "Ghost Unit",						6000,	"/items/armors/apex/apex-tier6manipulator/icons.png:head", 	"A soldier specialized in not getting a promised game.\n^green;+10% crit chance, +33% crit damage"},
	{ "^orange;Combat Engineer",		7000,	"/items/armors/human/human-tier6separator/icons.png:head",	"A soldier specialized in capturing structures by recoloring them, and then disappearing into thin air.\n^green;+20% fuel efficiency, +20% ship speed"},
	{ "^red;Pyrotechnics Specialist",	4500,	"/items/armors/human/human-tier4/icons.png:head",			"A soldier specialized in burning stuff. Unsure if male or female. Maybe its not even human.\n^green;+33% fire resistance, +33% fire damage"},
	{ "^pink;Psychic Manipulator",		5700,	"/items/armors/human/human-tier4/icons.png:head",			"A soldier specialized in screaming 'Yuri!' at things and setting them on fire.\n^green;Insanity immunity, lesser monsters are docile."},
	{ "^#9932CC;Project Nemesis",		8338,	"/items/armors/human/human-tier4/icons.png:head",			"A badass beast, carring all sorts of heavy weaponry with it, which is also able to sniff out zombie virus infected chicks.\n^green;+40% Badass"},
}

--	{ item in, amount in, item out, amount out, skip}
-- !!! - 'skip' shouldn't be added here, unless you feel like fucking shit up
stationSpecials.scientific = {
	{ "feroziumore",		1,	"coalore",		20	},
	{ "aegisaltore",		5,	"diamond",		1	},
	{ "alienweirdwood",		3,	"ancientbones",	1	},
	{ "artificialbrain",	1,	"basic",		50	},
	{ "battery",			1,	"biosample",	20	},
}

---------------------- PORTRAIT ANIMATION VALUES ----------------------
-----------------------------------------------------------------------
textData.floran.talkTotalFrames = 2
textData.floran.talkTicksPerFrame = 5
textData.floran.blinkTotalFrames = 1
textData.floran.blinkTicksPerFrame = 3
textData.floran.blinkCooldownAvg = 90

textData.avian = textData.floran

textData.novakid.talkTotalFrames = 4
textData.novakid.talkTicksPerFrame = 2
textData.novakid.blinkTotalFrames = 4
textData.novakid.blinkTicksPerFrame = 3
textData.novakid.blinkCooldownAvg = 90

textData.currentTalkFrame = 0
textData.currentBlinkFrame = 0
textData.talkFrameCooldown = 0
textData.blinkFrameCooldown = 0
textData.blinkCurrentCooldown = 0


---------------------- BASIC STUFF ----------------------
---------------------------------------------------------

-- Sets some base values, starts the welcoming text, and updates some things
function init()
	textData.currentRace = "floran"
	textData.stationType = "trading"
	
	textData.talkFrameCooldown = textData[textData.currentRace].talkTicksPerFrame
	textData.blinkFrameCooldown = textData[textData.currentRace].blinkTicksPerFrame
	textData.blinkCooldown = textData[textData.currentRace].blinkCooldownAvg * (0.5 + math.random())
	
	widget.setImage("talkerImage", "/interface/scripted/spaceStation/t"..textData.currentRace..".png:talk.0")
	widget.registerMemberCallback("goodsTradeList.itemList", "buyGoods", buyGoods)
	widget.registerMemberCallback("goodsTradeList.itemList", "sellGoods", sellGoods)
	widget.registerMemberCallback("scientificSpecialList.itemList", "tradeA", tradeA)
	widget.registerMemberCallback("scientificSpecialList.itemList", "tradeB", tradeB)
	
	resetGUI()
	writerInit(textData, textData[textData.currentRace].welcome)
end

-- Prints texts, animates portraits, and plays sound
function update()
	local sound = "/interface/scripted/spaceStation/chatterGeneric.ogg"
	
	if textData[textData.currentRace].sound then
		sound = textData[textData.currentRace].sound
	end
	
	writerUpdate(textData, sound, 0.5)
	writerScrambling(textData)
	widget.setText("text", textData.written)
	
	-- Portrait animation
	if textData.textPause <= 0 and not textData.isFinished then
		if textData.talkFrameCooldown <= 0 then
			textData.currentTalkFrame = (textData.currentTalkFrame + 1) % textData[textData.currentRace].talkTotalFrames
			widget.setImage("talkerImage", "/interface/scripted/spaceStation/t"..textData.currentRace..".png:talk."..tostring(textData.currentTalkFrame))
			textData.talkFrameCooldown = textData[textData.currentRace].talkTicksPerFrame
		else
			textData.talkFrameCooldown = textData.talkFrameCooldown - 1
		end
		
	elseif textData.isFinished then
		if textData.blinkCooldown <= 0 then
			if textData.blinkFrameCooldown <= 0 then
				widget.setImage("talkerImage", "/interface/scripted/spaceStation/t"..textData.currentRace..".png:blink."..tostring(textData.currentBlinkFrame))
				
				textData.currentBlinkFrame = textData.currentBlinkFrame + 1
				if textData.currentBlinkFrame >= textData[textData.currentRace].blinkTotalFrames then
					textData.currentBlinkFrame = textData.currentBlinkFrame % textData[textData.currentRace].blinkTotalFrames
					textData.blinkCooldown = textData[textData.currentRace].blinkCooldownAvg * (0.5 + math.random())
				end
				
				textData.blinkFrameCooldown = textData[textData.currentRace].blinkTicksPerFrame
			else
				textData.blinkFrameCooldown = textData.blinkFrameCooldown - 1
			end
		else
			if textData.blinkFrameCooldown <= 0 then
				widget.setImage("talkerImage", "/interface/scripted/spaceStation/t"..textData.currentRace..".png:talk.0")
				textData.blinkCooldown = textData.blinkCooldown - 1
			else
				textData.blinkFrameCooldown = textData.blinkFrameCooldown - 1
			end
		end
	
	else	-- during text pauses
		textData.currentTalkFrame = 0
		widget.setImage("talkerImage", "/interface/scripted/spaceStation/t"..textData.currentRace..".png:talk.0")
		textData.talkFrameCooldown = textData[textData.currentRace].talkTotalFrames
	end
end

-- Instantly prints the entire text
function skip()
	writerSkip(textData)
end

-- Does stuff based on the clicked button.
-- pass it whatever `widget.getData(clickedButtonsName)` returns
function commandProcessor(command)
	
	if command == "Chat" then
		writerInit(textData, textData[textData.currentRace]["chat"..math.random(1,10)])
		
	elseif command == "Quest" then
		local stage = textData.questData.current.stage
		if stage == 0 then	-- Requesting a quest
			updateQuestDetails(textData.questData.current.difficulty)
			writerInit(textData, textData[textData.currentRace]["questStage"..stage])
			modifyButtons("Accept", "Easier", "Harder", false, false, "Decline")
			
		elseif stage == 1 then	-- Requesting a quest when there's one in progress
			writerInit(textData, textData[textData.currentRace]["questStage"..stage])
			resetGUI()
			
		elseif stage == 2 then	-- Returning a failed quest
			textData.questData.stage = 0
			textData.questData.current.difficulty = 1
			writerInit(textData, textData[textData.currentRace]["questStage"..stage])
			resetGUI()
			
		elseif stage == 3 then	-- Returning a complete quest
			textData.questData.stage = 0
			-- reward the player
			textData.questData.current.difficulty = 1
			writerInit(textData, textData[textData.currentRace]["questStage"..stage])
			resetGUI()
		end
	
	elseif command == "Accept" then
		textData.questData.current.stage = 1
		writerInit(textData, textData[textData.currentRace].questAccept)
		resetGUI()
		
	elseif command == "Decline" then
		textData.questData.current.difficulty = 1
		writerInit(textData, textData[textData.currentRace].questDecline)
		resetGUI()
	
	elseif command == "Easier" then
		-- modify values
		textData.questData.current.difficulty = textData.questData.current.difficulty - 1
		updateQuestDetails(textData.questData.current.difficulty)
		writerInit(textData, textData[textData.currentRace].questEasier)
		
		if textData.questData.current.difficulty < 1 then
			modifyButtons("Accept", false, "Harder", false, false, "Decline")
		else
			modifyButtons("Accept", "Easier", "Harder", false, false, "Decline")
		end
	
	elseif command == "Harder" then
		-- modify values
		textData.questData.current.difficulty = textData.questData.current.difficulty + 1
		updateQuestDetails(textData.questData.current.difficulty)
		writerInit(textData, textData[textData.currentRace].questHarder)
		
		if textData.questData.current.difficulty > 1 then
			modifyButtons("Accept", "Easier", false, false, false, "Decline")
		else
			modifyButtons("Accept", "Easier", "Harder", false, false, "Decline")
		end
	
	elseif command == "Shop" then
		
		-- Open shop pannel
		
	elseif command == "Trade Goods" then
		populateGoodsList()
		writerInit(textData, "")
		modifyButtons(false, false, false, false, false, "Return")
		
	elseif command == "Special" then
		local type = textData.stationType
		writerInit(textData, textData[textData.currentRace][type.."Special"])
		
		if type == "military" then
			if stationSpecials.military.mercHired then
				writerInit(textData, textData[textData.currentRace].noMoreMerc)
			else
				modifyButtons("Hire Crew", false, false, false, false, "Return")
				widget.setButtonEnabled("button1", false)
				widget.setVisible("specialsScrollArea", true)
				populateSpecialList()
			end
			
		elseif type == "medical" then
			
			local difference = player.playTime() - stationSpecials.medical.purchaseTime
			if difference > stationSpecials.medical.cooldown then
				modifyButtons("Acquire", false, false, false, false, "Return")
				widget.setButtonEnabled("button1", false)
				widget.setVisible("specialsScrollArea", true)
				populateSpecialList()
			else
				textData.medicalSpecialCooldownRemaining = toTime(stationSpecials.medical.cooldown - difference)
				writerInit(textData, textData[textData.currentRace].cooldownEnhancer)
			end
			
		elseif type == "scientific" then
			widget.setVisible("scientificSpecialList", true)
			writerInit(textData, textData[textData.currentRace].scientificSpecial)
			populateScientificList()
			modifyButtons(false, false, false, false, false, "Return")
			
		elseif type == "trading" then
			modifyButtons("Invest", false, false, false, false, "Return")
			
		else
			writerInit(textData, "^red;ERROR -^reset;\nWrong 'type' recieved in 'commandProcessor' > 'elseif command == \"Special\" then'")
			resetGUI()
		end
		
	elseif command == "Hire Crew" then
		local merc = stationSpecials.selected
		if merc then
			local price = stationSpecials.military[stationSpecials.selected.index][2]
			if player.currency("money") < price then 
				writerInit(textData, textData[textData.currentRace]["cantAfford"..math.random(1,4)])
			else
				writerInit(textData, textData[textData.currentRace].hireMerc)
				stationSpecials.military.mercHired = true
				player.consumeCurrency("money", price)
				resetGUI()
			end
		end
		
	elseif command == "Trade Resources" then
	
	elseif command == "Invest" then
	
	elseif command == "Return" then
		writerInit(textData, textData[textData.currentRace].returnSpecial)
		resetGUI()
		
	elseif command == "Acquire" then
		local special = stationSpecials.selected
		if special then
			local price = stationSpecials.medical[stationSpecials.selected.index][2]
			if player.currency("money") < price then 
				writerInit(textData, textData[textData.currentRace]["cantAfford"..math.random(1,4)])
			else
				local effect = stationSpecials.medical[stationSpecials.selected.index][4]
				local duration = stationSpecials.medical[stationSpecials.selected.index][5]
				status.addEphemeralEffect(effect, duration, nil)
				stationSpecials.medical.purchaseTime = player.playTime()
				
				writerInit(textData, textData[textData.currentRace].acquireEnhancer)
				player.consumeCurrency("money", price)
				resetGUI()
			end
		end
		
	elseif command == "Goodbye" then
		pane.dismiss()
	end
end

-- Modify button based on context
-- Recieves b# , where the # stands for the number of the button (top 1 to bottom 6)
-- 'string' - Changes the text and data on the button to the recieved one
-- 'false' - Hides the button
-- 'nil' - applies no changes
function modifyButtons(b1, b2, b3, b4, b5, b6)
	if b1 then
		widget.setButtonEnabled("button1", true)
		widget.setVisible("button1", true)
		widget.setText("button1", b1)
		widget.setData("button1", b1)
	elseif b1 == false then
		widget.setVisible("button1", false)
	end
	
	if b2 then
		widget.setButtonEnabled("button2", true)
		widget.setVisible("button2", true)
		widget.setText("button2", b2)
		widget.setData("button2", b2)
	elseif b2 == false then
		widget.setVisible("button2", false)
	end
	
	if b3 then
		widget.setButtonEnabled("button3", true)
		widget.setVisible("button3", true)
		widget.setText("button3", b3)
		widget.setData("button3", b3)
	elseif b3 == false then
		widget.setVisible("button3", false)
	end
	
	if b4 then
		widget.setButtonEnabled("button4", true)
		widget.setVisible("button4", true)
		widget.setText("button4", b4)
		widget.setData("button4", b4)
	elseif b4 == false then
		widget.setVisible("button4", false)
	end
	
	if b5 then
		widget.setButtonEnabled("button5", true)
		widget.setVisible("button5", true)
		widget.setText("button5", b5)
		widget.setData("button5", b5)
	elseif b5 == false then
		widget.setVisible("button5", false)
	end
	
	if b6 then
		widget.setButtonEnabled("button6", true)
		widget.setVisible("button6", true)
		widget.setText("button6", b6)
		widget.setData("button6", b6)
	elseif b6 == false then
		widget.setVisible("button6", false)
	end
end

-- Restores buttons to their default states (set in textData.defaultButtonStates)
function resetGUI()
	for button, text in ipairs(textData.defaultButtonStates) do
		if text then
			widget.setButtonEnabled("button"..button, true)
			widget.setVisible("button"..button, true)
			widget.setText("button"..button, text)
			widget.setData("button"..button, text)
		elseif text == false then
			widget.setVisible("button"..button, false)
		end
	end
	
	widget.setVisible("specialsScrollArea", false)
	widget.setVisible("goodsTradeList", false)
	widget.setVisible("scientificSpecialList", false)
	stationSpecials.selected = nil
end

-- Update quest text values
function updateQuestDetails(difficulty)
	for loc, data in pairs(textData.questData["dif"..difficulty]) do
		textData.questData.current[loc] = data
	end
end


---------------------- TRADING GOODS ----------------------
-----------------------------------------------------------
function populateGoodsList(forced)
	if not widget.active("goodsTradeList") then
		widget.setVisible("goodsTradeList", true)
	end
	
	if forced or not textData.goodsListPopulated then
		textData.goodsListPopulated = true
		widget.clearListItems("goodsTradeList.itemList")
		
		-- Using a regular for loop so the list is organized
		for i = 1, #stationGoods do
			local data = stationGoods[i]
			local config = root.itemConfig(data.name)
			local listItem = "goodsTradeList.itemList."..widget.addListItem("goodsTradeList.itemList")
			local name = config.config.shortdescription
			
			widget.setData(listItem,{
				itemName = config.config.itemName,
				basePrice = data.basePrice,
				baseAmount = data.baseAmount,
				stock = data.stock,
			})
			
			local buyPrice, buyRate = updatePrice(data.basePrice, data.baseAmount, data.stock, true)
			local sellPrice, sellRate = updatePrice(data.basePrice, data.baseAmount, data.stock)
			
			if buyRate >= 1.5 then
				widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:-2")
			elseif buyRate >= 1.2 then
				widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:-1")
			elseif buyRate >= 0.9 then
				widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:0")
			elseif buyRate >= 0.6 then
				widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:1")
			else
				widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:2")
			end
			
			if sellRate >= 1.5 then
				widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:2")
			elseif sellRate >= 1.2 then
				widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:1")
			elseif sellRate >= 0.9 then
				widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:0")
			elseif sellRate >= 0.6 then
				widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:-1")
			else
				widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:-2")
			end
			
			widget.setText(listItem..".buyPrice", buyPrice)
			widget.setText(listItem..".sellPrice", sellPrice)
			
			widget.setText(listItem..".stationStockLabel", "Station stock: "..data.stock)
			widget.setText(listItem..".sellStockLabel", "Your stock:     "..data.stock)
			
			widget.setText(listItem..".itemName", name)
			widget.setItemSlotItem(listItem..".itemIcon", data.name)
		end
		
		stationSpecials.selected = nil
	end
end

function goodsSelected()
	local listItem = widget.getListSelected("goodsTradeList.itemList")
	stationGoods.selected = listItem
	
	if listItem then
		local itemData = widget.getData("goodsTradeList.itemList."..listItem)
		stationGoods.selected = itemData
	end
end

function sellGoods()
	if stationGoods.selected then
		player.giveItem(stationGoods.selected.itemName)
	else
		writerInit(textData, "No item selected.\nHow the fuck did you achieve this?\nSeriously, I'm impressed.\n\nReport this I guess?")
	end
end

function buyGoods()
	if stationGoods.selected then
		player.giveItem(stationGoods.selected.itemName)
	else
		writerInit(textData, "No item selected.\nHow the fuck did you achieve this?\nSeriously, I'm impressed.\n\nReport this I guess?")
	end
end

-- Updates prices
function updatePrice(basePrice, baseAmount, stock, isBuying)
	local rate = 1 - (stock * 100 / baseAmount * 0.01) + 1
	local rateMin = 0.35
	local rateMax = 1.65
	
	if rate < rateMin then
		rate = rateMin
	elseif rate > rateMax then
		rate = rateMax
	end
	
	if isBuying then
		rate = rate * 1.05
	else
		rate = rate * 0.95
	end
	
	local price = basePrice * rate
	
	if price - math.abs(math.floor(price)) < price - math.abs(math.ceil(price)) then
		price = math.floor(price)
	else
		price = math.ceil(price)
	end
	
	return price, rate
end


---------------------- STATION SPECIALS ----------------------
--------------------------------------------------------------

-- Used for medical and military stations
function populateSpecialList(forced)
	if forced or not textData.specialListPopulated then
		textData.specialListPopulated = true
		widget.clearListItems("specialsScrollArea.itemList")
		
		for i = 1, #stationSpecials[textData.stationType] do
			if stationSpecials[textData.stationType][i] then
				local listItem = "specialsScrollArea.itemList."..widget.addListItem("specialsScrollArea.itemList")
				local data = stationSpecials[textData.stationType][i]
				
				
				widget.setText(listItem..".name",  data[1])
				widget.setImage(listItem..".icon", data[3])
				widget.setText(listItem..".price", "x "..data[2])
				
				widget.setData(listItem, { index = i, })
			end
		end
		
		stationSpecials.selected = nil
	end
end

function specialSelected()
	local listItem = widget.getListSelected("specialsScrollArea.itemList")
	stationSpecials.selected = listItem
	
	if listItem then
		stationSpecials.selected = widget.getData(string.format("%s.%s", "specialsScrollArea.itemList", listItem))
		widget.setButtonEnabled("button1", true)
		
		if textData.stationType == "medical" then
			writerInit(textData, stationSpecials.medical[stationSpecials.selected.index][6])
		elseif textData.stationType == "military" then
			writerInit(textData, stationSpecials.military[stationSpecials.selected.index][4])
		else
			writerInit(textData, "ERROR - No or wrong station type")
		end
	else
		widget.setButtonEnabled("button1", false)
		writerInit(textData, "No item selected.\nHow the fuck did you achieve this?\nSeriously, I'm impressed.\n\nReport this I guess?")
	end
end

-- Used for scientific stations
function populateScientificList(forced)
	if forced or not textData.specialListPopulated then
		textData.specialListPopulated = true
		widget.clearListItems("scientificSpecialList.itemList")
		
		for i, data in ipairs(stationSpecials[textData.stationType]) do
			if not data[5] then -- check if this option was already added
				local listItem = "scientificSpecialList.itemList."..widget.addListItem("scientificSpecialList.itemList")
				widget.setItemSlotItem(listItem..".itemIn1", data[1])
				widget.setItemSlotItem(listItem..".itemOut1", data[3])
				widget.setText(listItem..".amountIn1", data[2])
				widget.setText(listItem..".amountOut1", data[4])
				
				widget.setData(listItem, { indexA = i, })
				secondData = stationSpecials[textData.stationType][i+1]
				
				if secondData then
					widget.setItemSlotItem(listItem..".itemIn2", secondData[1])
					widget.setItemSlotItem(listItem..".itemOut2", secondData[3])
					widget.setText(listItem..".amountIn2", secondData[2])
					widget.setText(listItem..".amountOut2", secondData[4])
				
					widget.setData(listItem, { indexA = i, indexB = i+1})
					secondData[5] = true
				else
					widget.setVisible(listItem..".amountInBG2", false)
					widget.setVisible(listItem..".amountIn2", false)
					widget.setVisible(listItem..".amountOutBG2", false)
					widget.setVisible(listItem..".amountOut2", false)
					widget.setVisible(listItem..".trade2", false)
				end
			end
		end
		
		stationSpecials.selected = nil
	end
end

function scientificSelected()
	local listItem = widget.getListSelected("scientificSpecialList.itemList")
	stationSpecials.selected = listItem
	
	if listItem then
		stationSpecials.selected = widget.getData(string.format("%s.%s", "scientificSpecialList.itemList", listItem))
	else
		writerInit(textData, "No item selected.\nHow the fuck did you achieve this?\nSeriously, I'm impressed.\n\nReport this I guess?")
	end
end

function tradeA()
	if stationSpecials.selected then
		local inputDescriptor = {
			name = stationSpecials.scientific[stationSpecials.selected.indexA][1],
			count = stationSpecials.scientific[stationSpecials.selected.indexA][2],
		}
		
		if player.hasItem(inputDescriptor, true) then
			player.consumeItem(inputDescriptor, true, true)
			
			local outputDescriptor = {
				name = stationSpecials.scientific[stationSpecials.selected.indexA][3],
				count = stationSpecials.scientific[stationSpecials.selected.indexA][4],
			}
			player.giveItem(outputDescriptor)
		end
	else
		writerInit(textData, "ERROR - Attempted to trade while no item was selected in function 'tradeA'")
	end
end

function tradeB()
	if stationSpecials.selected then
		local inputDescriptor = {
			name = stationSpecials.scientific[stationSpecials.selected.indexB][1],
			count = stationSpecials.scientific[stationSpecials.selected.indexB][2],
		}
		
		if player.hasItem(inputDescriptor, true) then
			player.consumeItem(inputDescriptor, true, true)
			
			local outputDescriptor = {
				name = stationSpecials.scientific[stationSpecials.selected.indexB][3],
				count = stationSpecials.scientific[stationSpecials.selected.indexB][4],
			}
			player.giveItem(outputDescriptor)
		end
	else
		writerInit(textData, "ERROR - Attempted to trade while no item was selected in function 'tradeA'")
	end
end

-- Used for trading stations

---------------------- MISC. ----------------------
---------------------------------------------------

-- Recieves a single number, and returns a table holding seconds, minutes, and hours as if the value recieved was seconds
function toTime(time)
	local table = {
		seconds = math.floor(time % 60),
		minutes = math.floor((time / 60) % 60),
		hours = math.floor((time / 60 / 60)),
	}
	return table
end

-- Functions called by buttons - nothing exciting, they just send data to the commandProcessor
function button1() commandProcessor(widget.getData("button1")) end
function button2() commandProcessor(widget.getData("button2")) end
function button3() commandProcessor(widget.getData("button3")) end
function button4() commandProcessor(widget.getData("button4")) end
function button5() commandProcessor(widget.getData("button5")) end
function button6() commandProcessor(widget.getData("button6")) end
function skiptext() skip() end