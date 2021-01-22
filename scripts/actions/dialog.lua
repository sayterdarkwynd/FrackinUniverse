function context()
	return _ENV[entity.entityType()]
end

function entityVariant()
	if entity.entityType() == "monster" then
		return monster.type()
	elseif entity.entityType() == "npc" then
		return npc.npcType(),npc.species()
	elseif entity.entityType() == "object" then
		return world.entityName(entity.id())
	end
end

function loadDialog(dialogKey)
	local configEntry = config.getParameter(dialogKey)
	if type(configEntry) == "string" then
		self.dialog[dialogKey] = root.assetJson(configEntry)
	elseif type(configEntry) == "table" then
		self.dialog[dialogKey] = configEntry
	else
		self.dialog[dialogKey] = false
	end
end

function queryDialog(dialogKey, targetId)
	if self.dialog == nil then self.dialog = {} end
	if self.dialog[dialogKey] == nil then loadDialog(dialogKey) end

	local dialog = self.dialog[dialogKey]
	if dialog then
		return speciesDialog(dialog, targetId)
	end
end

function speciesDialog(dialog, targetId, overrideToDefault)
	local species = (not overrideToDefault and (context().species and context().species())) or "default"
	dialog = dialog[species] or dialog.default

	local targetDialog
	if not dialog then return end

	if targetId then
		targetDialog = dialog[world.entitySpecies(targetId)] or dialog.default
	else
		targetDialog = dialog.default
	end

	if dialog.generic and targetDialog then
		targetDialog = util.mergeLists(dialog.generic, targetDialog)
	end

	return targetDialog
end

function staticRandomizeDialog(list)
	if #list < 1 then
		sb.logWarn("/scripts/actions/dialog.lua:staticRandomizeDialog: Entity supplied empty dialog list. %s",{entityType=world.entityType(entity.id()),npctype=npc and npc.npcType(),npcspecies=npc and npc.species(),monstertype=monster and monster.type(),objectname=object and object.name()})
	return
	end
	return list[sb.staticRandomI32Range(1, #list, context().seed())]
end

function sequenceDialog(list, sequenceKey)
	self.dialogSequence = self.dialogSequence or {}
	self.dialogSequence[sequenceKey] = (self.dialogSequence[sequenceKey] or -1) + 1
	return list[(self.dialogSequence[sequenceKey] % #list) + 1]
end

function randomizeDialog(list)
	return list[math.random(1, #list)]
end

function randomChatSound()
	local chatSounds = config.getParameter("chatSounds") or {}

	local speciesSounds = chatSounds[npc.species()] or chatSounds.default
	if not speciesSounds then return nil end

	local genderSounds = speciesSounds[npc.gender()] or speciesSounds.default
	if not genderSounds then return nil end
	if type(genderSounds) ~= "table" then return genderSounds end
	if #genderSounds == 0 then return nil end

	return genderSounds[math.random(#genderSounds)]
end

-- output dialog
-- output source
function receiveClueDialog(args, board)
	local notification = util.find(self.notifications, function(n) return n.type == "giveClue" end)
	if notification then
		local dialog = root.assetJson(notification.dialog)
		local dialogLine = staticRandomizeDialog(speciesDialog(dialog, notification.sourceId))
		world.sendEntityMessage(notification.sourceId, "dialogClueReceived", dialogLine)
		return true, {dialog = dialog, source = notification.sourceId}
	else
		return false
	end
end

-- param tag
-- param text
function setDialogTag(args, board)
	self.dialogTags = self.dialogTags or {}
	self.dialogTags[args.tag] = args.text
	return true
end

-- param dialogType
-- param dialog
-- param entity
-- param tags
function sayToEntity(args, board)
	local dialog = (args.dialog and (speciesDialog(args.dialog, args.entity) or speciesDialog(args.dialog) or speciesDialog(args.dialog, args.entity,true) or speciesDialog(args.dialog,nil,true))) or queryDialog(args.dialogType, args.entity)
	local dialogMode = config.getParameter("dialogMode") or "static"
	--sb.logInfo("eE: %s",{z=args,a=args.dialog or "FUCK! It's a nil.", b=args.dialog and speciesDialog(args.dialog, args.entity),c=args.dialog and speciesDialog(args.dialog),d=args.dialog and speciesDialog(args.dialog, args.entity,true),e=args.dialog and speciesDialog(args.dialog,nil,true),f=args.dialog and queryDialog(args.dialogType, args.entity)})
	if dialog == nil then
		--[[local eType,species=entityVariant()
		if eType=="npc" then
			sb.logError("/scripts/actions/dialog.lua: Dialog type %s not specified in %s, of species %s", args.dialogType, eType,species)
		else
			sb.logError("/scripts/actions/dialog.lua: Dialog type %s not specified in %s", args.dialogType, eType)
		end]]
		--dialog={"<^red;MISSING^reset;>"}
		--dialogMode="static"
		return false
	end

	if dialogMode == "static" then
		dialog = staticRandomizeDialog(dialog)
	elseif dialogMode == "sequence" then
		dialog = sequenceDialog(dialog, args.dialogType)
	else
		dialog = randomizeDialog(dialog)
	end
	if dialog == nil then return false end

	local tags = sb.jsonMerge(self.dialogTags or {}, args.tags)
	tags.selfname = world.entityName(entity.id())
	if args.entity then
		tags.entityname = world.entityName(args.entity)

		local entityType = world.entityType(args.entity)
		if entityType and entityType == "npc" then
			tags.entitySpecies = world.entitySpecies(args.entity)
		end
	end

	local options = {}

	-- Only NPCs have sound support
	if entity.entityType() == "npc" then
		options.sound = randomChatSound()
	end

	context().say(dialog, tags, options)
	return true
end

-- param entity
function inspectEntity(args, board)
	if not args.entity or not world.entityExists(args.entity) then return false end

	local options = {}
	local species = nil
	if entity.entityType() == "npc" then
		species = npc.species()
		options.sound = randomChatSound()
	end

	local dialog = world.entityDescription(args.entity, species)
	if not dialog then return false end

	context().say(dialog, {}, options)
	return true
end

-- param dialogType
-- param entity
function getDialog(args, board)
	self.currentDialog = copy(queryDialog(args.dialogType, args.entity))
	self.currentDialogTarget = args.entity
	if self.currentDialog == nil then
		return false
	end

	return true
end

-- param content
function say(args, board)
	local portrait = config.getParameter("chatPortrait")

	args.tags.selfname = world.entityName(entity.id())

	local options = {}
	if entity.entityType() == "npc" then
		options.sound = randomChatSound()
	end

	if portrait == nil then
		context().say(args.content, args.tags, options)
	else
		context().sayPortrait(args.content, portrait, args.tags, options)
	end

	return true
end

function sayNext(args, board)
	if self.currentDialog == nil or #self.currentDialog == 0 then return false end

	local portrait = config.getParameter("chatPortrait")

	args.tags.selfname = world.entityName(entity.id())
	if self.currentDialogTarget then args.tags.entityname = world.entityName(self.currentDialogTarget) end

	local options = {}
	if entity.entityType() == "npc" then
		options.sound = randomChatSound()
	end

	if portrait == nil then
		context().say(self.currentDialog[1], args.tags, options)
	else
		if #self.currentDialog > 1 then
			options.drawMoreIndicator = args.drawMoreIndicator
		end
		context().sayPortrait(self.currentDialog[1], portrait, args.tags, options)
	end

	table.remove(self.currentDialog, 1)
	return true
end

function hasMoreDialog(args, output)
	if self.currentDialog == nil or #self.currentDialog == 0 then return false end
	return true
end
