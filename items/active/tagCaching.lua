tagCaching={}
tagCaching.primaryTagCache={}
tagCaching.altTagCache={}
tagCaching.mergedCache={}

function tagCaching.update(dt)
	local primaryItem = world.entityHandItem(entity.id(), "primary") --check what they have in hand
	local altItem = world.entityHandItem(entity.id(), "alt")
	local doMerge=false
	if tagCaching.primaryTagCacheItem~=primaryItem then
		tagCaching.primaryTagCache=primaryItem and tagCaching.tagsToKeys(tagCaching.fetchTags(root.itemConfig(primaryItem))) or {}
		tagCaching.primaryTagCacheItem=primaryItem
		doMerge=true
	elseif not primaryItem then
		tagCaching.primaryTagCache={}
		doMerge=true
	end
	if tagCaching.altTagCacheItem~=altItem then
		tagCaching.altTagCache=altItem and tagCaching.tagsToKeys(tagCaching.fetchTags(root.itemConfig(altItem))) or {}
		tagCaching.altTagCacheItem=altItem
		doMerge=true
	elseif not altItem then
		tagCaching.altTagCache={}
		doMerge=true
	end
	if doMerge then
		tagCaching.mergedCache={}
		for k,v in pairs(tagCaching.primaryTagCache or {}) do
			tagCaching.mergedCache[k]=v
		end
		for k,v in pairs(tagCaching.altTagCache or {}) do
			tagCaching.mergedCache[k]=v
		end
	end
end

function tagCaching.fetchTags(iConf)
    if not iConf or not iConf.config then return {} end
    local tags={}
    for k,v in pairs(iConf.config or {}) do
        if string.lower(k)=="itemtags" then
            tags=util.mergeTable(tags,copy(v))
        end
    end
    for k,v in pairs(iConf.parameters or {}) do
        if string.lower(k)=="itemtags" then
            tags=util.mergeTable(tags,copy(v))
        end
    end
    return tags
end

function tagCaching.tagsToKeys(tags)
    local buffer={}
    for _,v in pairs(tags) do
        --buffer[v]=true
        buffer[v:lower()]=true
    end
    return buffer
end