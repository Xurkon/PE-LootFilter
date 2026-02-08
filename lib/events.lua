function LootFilter.takeBagSnapshot()
	LootFilter.bagSnapshot = {};
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag);
		for slot = 1, numSlots do
			local link = GetContainerItemLink(bag, slot);
			if link then
				local key = bag .. ":" .. slot;
				local count = select(2, GetContainerItemInfo(bag, slot)) or 0;
				LootFilter.bagSnapshot[key] = link .. ":" .. count;
			end
		end
	end
end

function LootFilter.findNewItemsInBags()
	local newItems = {};
	for bag = 0, 4 do
		if LootFilterVars[LootFilter.REALMPLAYER].openbag[bag] then
			local numSlots = GetContainerNumSlots(bag);
			for slot = 1, numSlots do
				local link = GetContainerItemLink(bag, slot);
				if link then
					local key = bag .. ":" .. slot;
					local count = select(2, GetContainerItemInfo(bag, slot)) or 0;
					local current = link .. ":" .. count;
					local old = LootFilter.bagSnapshot[key];
						if not old or old ~= current then
						local item = LootFilter.getBasicItemInfo(link);
						if item then
							item["bag"] = bag;
							item["slot"] = slot;
							item["amount"] = count > 0 and count or 1;
							table.insert(newItems, item);
						end
					end
				end
			end
		end
	end
	return newItems;
end

function LootFilter.processBagUpdate()
	if not LootFilterVars[LootFilter.REALMPLAYER].lootbotmode then
		return;
	end
	if not LootFilterVars[LootFilter.REALMPLAYER].enabled then
		return;
	end

	local newItems = LootFilter.findNewItemsInBags();
	LootFilter.debug("|cff44ff44[LOOTBOT]|r BAG_UPDATE detected " .. tostring(table.getn(newItems)) .. " new item(s)");

	for _, item in ipairs(newItems) do
		LootFilter.debug("|cff44ff44[LOOTBOT]|r New item: " .. tostring(item["name"]) .. " (id=" .. tostring(item["id"]) .. ") bag=" .. tostring(item["bag"]) .. " slot=" .. tostring(item["slot"]));
		table.insert(LootFilterVars[LootFilter.REALMPLAYER].itemStack, item);

		if GetSellValue then
			LootFilter.sessionAdd(item);
			LootFilterVars[LootFilter.REALMPLAYER].session["end"] = time();
			LootFilter.sessionUpdateValues();
		end
	end

	LootFilter.takeBagSnapshot();

	if table.getn(LootFilterVars[LootFilter.REALMPLAYER].itemStack) > 0 then
		LootFilter.LOOT_MAXTIME = GetTime() + LootFilter.LOOT_TIMEOUT;
		if table.getn(LootFilter.timerArr) == 0 then
			if LootFilterVars[LootFilter.REALMPLAYER].caching then
				LootFilterVars[LootFilter.REALMPLAYER].itemStack = {};
				LootFilter.schedule(LootFilter.LOOT_PARSE_DELAY, LootFilter.processCaching);
			else
				LootFilter.schedule(LootFilter.LOOT_PARSE_DELAY, LootFilter.processItemStack);
			end
		end
	end

	LootFilter.bagUpdatePending = false;
end

function LootFilter.OnEvent()
	if (event == "BAG_UPDATE") then
		if LootFilterVars[LootFilter.REALMPLAYER] and LootFilterVars[LootFilter.REALMPLAYER].lootbotmode and LootFilterVars[LootFilter.REALMPLAYER].enabled then
			-- Skip BAG_UPDATE while a loot window is open; LOOT_OPENED handles those items
			if LootFilter.lootWindowOpen then
				return;
			end
			-- Debounce: only schedule one update even if multiple bags change
			if not LootFilter.bagUpdatePending then
				LootFilter.bagUpdatePending = true;
				LootFilter.schedule(LootFilter.BAG_UPDATE_DELAY, LootFilter.processBagUpdate);
			end
		end
		return;
	end

	if (event == "RAID_ROSTER_UPDATE") then
		if (LootFilter.versionUpdate == false) then
			LootFilter.versionUpdate = true;
			LootFilter.schedule(60, LootFilter.sendAddonMessage, "VERSION:"..LootFilter.newVersion, 2);
		end;
		return;
	end;

	if LootFilter.REALMPLAYER == "" or not LootFilterVars[LootFilter.REALMPLAYER] then
		if event == "ADDON_LOADED" and arg1 == "LootFilter" then
			-- Allow ADDON_LOADED to proceed (it does the initialization)
		else
			return;
		end
	end

	if (event == "CHAT_MSG_ADDON") then
		if (arg1 == "LootFilter") then
			local name = string.match(arg2, "(%a+):");
			local version = string.match(arg2, ":(.*)");
			if (name == "VERSION") then
				if (((arg3 == "RAID") or (arg3 == "PARTY")) and (LootFilter.versionUpdate == true)) then
					LootFilter.versionUpdate = false;
				end;
				if (tonumber(version) ~= nil) and (tonumber(LootFilter.newVersion) ~= nil) then
					if (tonumber(version) > tonumber(LootFilter.newVersion)) then
						LootFilter.newVersion = version;
						if (LootFilterVars[LootFilter.REALMPLAYER].notifynew) then
							LootFilter.print(LootFilter.Locale.LocText["LTNewVersion1"].." ("..version..") "..LootFilter.Locale.LocText["LTNewVersion2"]);
						end;
					end;
				end;
			end;
		end;
		return;
	end;

	if (event == "UNIT_SPELLCAST_START") then
		LootFilter.spellCast = true;
	end;
	if (event == "UNIT_SPELLCAST_STOP") then
		LootFilter.spellCast = false;
	end;

	if (event == "UI_INFO_MESSAGE") then
		if (LootFilterVars[LootFilter.REALMPLAYER].deleteList["QUQuest"] == nil) then
			if (string.find(arg1, "slain: ") ~= nil) and (string.find(arg1, "slain: ") > 0) then
				return;
			end;
			local itemName = gsub(arg1,"(.*): %s*([-%d]+)%s*/%s*([-%d]+)%s*$","%1",1);
			if (itemName ~= arg1) then
				local item = {};
				item["name"] = itemName;
				for index, name in pairs(LootFilterVars[LootFilter.REALMPLAYER].keepList["names"]) do
					if (LootFilter.matchItemNames(item, name)) then
						return;
					end;
				end;

				for index, item in pairs(LootFilterVars[LootFilter.REALMPLAYER].itemStack) do
					local name = item["name"];
					if (string.lower(name) == string.lower(itemName)) then
						table.remove(LootFilterVars[LootFilter.REALMPLAYER].itemStack, index);
						if (LootFilterVars[LootFilter.REALMPLAYER].notifykeep) then
							LootFilter.print(item["link"].." "..LootFilter.Locale.LocText["LTKept"]..": "..LootFilter.Locale.LocText["LTQuestItem"]);
						end;
						if (item["itemType"] ~= LootFilter.Locale.LocText["LTQuest"]) and (item["itemSubType"] ~= LootFilter.Locale.LocText["LTQuest"]) then
							table.insert(LootFilterVars[LootFilter.REALMPLAYER].keepList["names"], itemName.."  ; "..LootFilter.Locale.LocText["LTAddedCosQuest"]);
						end;
						return;
					end;
				end;
			end;
		end;
	end;
	
	if (event == "LOOT_OPENED") and (LootFilterVars[LootFilter.REALMPLAYER].enabled) then
		LootFilter.lootWindowOpen = true;
		-- Take a snapshot before looting so BAG_UPDATE can detect what's new after the window closes
		if LootFilterVars[LootFilter.REALMPLAYER].lootbotmode then
			LootFilter.takeBagSnapshot();
		end
		local numitems= GetNumLootItems();
		for i = 1, numitems, 1 do
			if (not LootSlotIsCoin(i)) then
				local icon, name, quantity, quality= GetLootSlotInfo(i);
				if (icon ~= nil) then
						local item = LootFilter.getBasicItemInfo(GetLootSlotLink(i));
					if (item ~= nil) then
						LootFilter.debug("|cff44ff44[LOOT]|r Loot window item: " .. tostring(item["name"]) .. " (id=" .. tostring(item["id"]) .. ") " .. tostring(item["link"]));
						if (not LootFilterVars[LootFilter.REALMPLAYER].caching) then
							table.insert(LootFilterVars[LootFilter.REALMPLAYER].itemStack, item);
						end;
						if (GetSellValue) then -- record the value of this item
							LootFilter.sessionAdd(item);
							LootFilterVars[LootFilter.REALMPLAYER].session["end"] = time();
							LootFilter.sessionUpdateValues();
						end;
					end;
				end;
			end;
		end;
	end;

	if (event == "LOOT_CLOSED") and (LootFilterVars[LootFilter.REALMPLAYER].enabled) then
		LootFilter.lootWindowOpen = false;
		if LootFilterVars[LootFilter.REALMPLAYER].lootbotmode then
			LootFilter.takeBagSnapshot();
		end
		LootFilter.LOOT_MAXTIME = GetTime() + LootFilter.LOOT_TIMEOUT;
		LootFilter.itemOpen = false;
		if (table.getn(LootFilter.timerArr) == 0) then
			if (LootFilterVars[LootFilter.REALMPLAYER].caching) then
				LootFilterVars[LootFilter.REALMPLAYER].itemStack = {};
				LootFilter.schedule(LootFilter.LOOT_PARSE_DELAY, LootFilter.processCaching);
			else
				LootFilter.schedule(LootFilter.LOOT_PARSE_DELAY, LootFilter.processItemStack);
			end;
		end;
	end;

	if (event == "ITEM_LOCK_CHANGED") then
		if (LootFilter.hasFocus > 0) then
			itemName= LootFilter.findItemWithLock();
			if (itemName ~= nil) and (itemName ~= "") then
				if (LootFilter.hasFocus == 1) then
					LootFilterEditBox1:SetText(LootFilterEditBox1:GetText()..itemName.."\n");
				elseif (LootFilter.hasFocus == 2) then
					LootFilterEditBox2:SetText(LootFilterEditBox2:GetText()..itemName.."\n");
				end;
			end;
		end;
	end;

	if (event == "MERCHANT_CLOSED") then
		LootFilterButtonDeleteItems:SetText(LootFilter.Locale.LocText["LTDeleteItems"]);
	end;

	if (event == "MERCHANT_SHOW") then
		LootFilterButtonDeleteItems:SetText(LootFilter.Locale.LocText["LTSellItems"]);
		LootFilter.processCleaning();
		if (table.getn(LootFilter.cleanList) > 0) then
			if (LootFilterVars[LootFilter.REALMPLAYER].openvendor) then
				LootFilterOptions:Show();
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].autosell) then
				LootFilter.iWantTo();
				LootFilter.sellQueue = 1;
				LootFilter.deleteItems(GetTime() + LootFilter.LOOT_TIMEOUT, false);
			end;			
			LootFilter.selectButton(LootFilterButtonClean, LootFilterFrameClean); 
		end;
	end;

	if (event == "ADDON_LOADED") then

		if (arg1 == "LootFilter") then
			
			LootFilter.REALMPLAYER= GetCVar("realmName") .. " - " ..UnitName("player");
			if (LootFilterVars[LootFilter.REALMPLAYER] == nil) then
				LootFilterVars[LootFilter.REALMPLAYER]= {};
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].openList == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].openList= {};
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].keepList == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].keepList= {};
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].keepList["names"] == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].keepList["names"] = {
					"Hearthstone",
				};
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].deleteList == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].deleteList= {};
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].deleteList["names"] == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].deleteList["names"] = {};
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].itemStack == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].itemStack= {};
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].enabled == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].enabled= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].debug == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].debug = false;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].tooltips == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].tooltips= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].notifydelete == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].notifydelete= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].notifykeep == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].notifykeep= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].notifynomatch == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].notifynomatch= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].notifyopen == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].notifyopen= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].notifynew == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].notifynew= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].caching == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].caching= false;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].novalue == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].novalue= false;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].marketvalue == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].marketvalue= false;
			end;			
			if (LootFilterVars[LootFilter.REALMPLAYER].calculate == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].calculate= 3;
			end;							
			if (LootFilterVars[LootFilter.REALMPLAYER].freebagslots == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].freebagslots= 5;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].openvendor == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].openvendor= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].autosell == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].autosell= false;
			end;			
			if (LootFilterVars[LootFilter.REALMPLAYER].openbag == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].openbag= {};
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].openbag[0] == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].openbag[0]= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].openbag[1] == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].openbag[1]= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].openbag[2] == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].openbag[2]= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].openbag[3] == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].openbag[3]= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].openbag[4] == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].openbag[4]= true;
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].confirmdel == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].confirmdel= false;
			end
			if (LootFilterVars[LootFilter.REALMPLAYER].session == nil) then
				LootFilter.sessionReset();
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].lootbotmode == nil) then
				LootFilterVars[LootFilter.REALMPLAYER].lootbotmode = false;
			end;

			LootFilter.takeBagSnapshot();

			LootFilterButtonGeneral:LockHighlight();
			LootFilter.setTitle();
			LootFilter.getNames();
			LootFilter.getNamesDelete();
			LootFilter.getItemValue();
			LootFilter.versionUpdate = false;

			LootFilter.initCopyTab();
			
			LootFilter.initTypeTab();
			LootFilter.initQualityTab();			
			UIDropDownMenu_Initialize(LootFilterSelectDropDownType, LootFilter.SelectDropDownType_Initialize);
			UIDropDownMenu_Initialize(LootFilterSelectDropDownCalculate, LootFilter.SelectDropDownCalculate_Initialize);
			LootFilter.SelectDropDown_Initialize();
			
			
			-- The following was added because GetSellValue is not always available when addons load
			-- GetItemPriceTooltip (uses Ace2) for example loads its GetSellValue when it is enable (after it has been loaded...) 
			LootFilter.schedule(2, LootFilter.checkDependencies);
		end;
	
		LootFilter.checkDependencies();
	
	end;
end;



function LootFilter.OnLoad()
	SLASH_LOOTFILTER1= "/lootfilter";
	SLASH_LOOTFILTER2= "/lf";
	SLASH_LOOTFILTER3= "/lfr";
	SlashCmdList["LOOTFILTER"] = LootFilter.command;

	this:RegisterEvent("LOOT_OPENED");
	this:RegisterEvent("LOOT_CLOSED");
	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("ITEM_LOCK_CHANGED");
	this:RegisterEvent("UI_INFO_MESSAGE");
	this:RegisterEvent("UNIT_SPELLCAST_START");
	this:RegisterEvent("UNIT_SPELLCAST_STOP");
	this:RegisterEvent("MERCHANT_CLOSED");
	this:RegisterEvent("MERCHANT_SHOW");
	this:RegisterEvent("CHAT_MSG_ADDON");
	this:RegisterEvent("RAID_ROSTER_UPDATE");
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("BAG_UPDATE");
	LootFilter.newVersion = LootFilter.VERSION;
	LootFilter.schedule(5, LootFilter.sendAddonMessage, "VERSION:"..LootFilter.newVersion, 1);
end;

