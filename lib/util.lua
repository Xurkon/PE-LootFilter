function LootFilter.print(value)
	if (value == nil) then
		value= "";
	end;
	DEFAULT_CHAT_FRAME:AddMessage("Loot Filter - "..value, 1.0, 1.0, 1.0);	
end;

function LootFilter.debug(value)
	if LootFilter.REALMPLAYER == "" or not LootFilterVars[LootFilter.REALMPLAYER].debug then
		return;
	end
	if (value == nil) then
		value= "";
	end;
	DEFAULT_CHAT_FRAME:AddMessage("Loot Filter - DEBUG: "..value, 1.0, 1.0, 1.0);
end;

function LootFilter.report(value)
	if LootFilter.REALMPLAYER == "" or not LootFilterVars[LootFilter.REALMPLAYER] then
		return;
	end
	if (LootFilterVars[LootFilter.REALMPLAYER].report) then
		LootFilter.print(value);
	end;
end;

function LootFilter.tcount(table)
	local n=0;
	for _ in pairs(table) do
		n=n+1;
	end
	return n;
end;

function LootFilter.varCount()
	local n = 0;
	for k in pairs(LootFilterVars) do
		if k:find("%s -") ~= nil then
			n = n + 1;
		end
	end
	return n;
end

function LootFilter.trim(name)
	return string.gsub(name, "LootFilter", "");	
end;

function LootFilter.split(str, at)
	if (not (type(str) == "string")) then
		return
	end

	if (not str) then
		str = ""
	end

	if (not at) then
		return {str}
	else
		return {strsplit(at, str)};
	end
end

function LootFilter.stripComment(searchName)
	local comment = "";
	local commentPos = string.find(searchName, ";", 1, true);
	if (commentPos ~= nil) and (commentPos > 0) then -- comment found
		comment = string.sub(searchName, commentPos);
		searchName= string.sub(searchName, 0, commentPos-1);
		searchName= strtrim(searchName);
	end;
	return searchName, comment;
end;

function LootFilter.sendAddonMessage(value, channel)
	if (channel == 1) then
		local guild = GetGuildInfo("player");
		if (guild ~= nil) then
			SendAddonMessage("LootFilter", value, "GUILD", "");
		end;
	elseif (channel == 2) then
		if (LootFilter.versionUpdate == true) then
			SendAddonMessage("LootFilter", value, "RAID", "");
		end;
	end;
end;

function LootFilter.toggleWindow()
	if (not LootFilterOptions:IsShown()) then
		LootFilterOptions:Show();
	else
		LootFilterOptions:Hide();
	end;
end;

function LootFilter.command(cmd)
	local args= {};
	local i= 1;
	for w in string.gmatch(cmd, "%w+") do
		args[i]= w;
		i= i + 1;
	end;

	if (table.getn(args) == 0) then
		LootFilter.toggleWindow();
	elseif (args[1] == "lootbot" or args[1] == "bot") then
		LootFilterVars[LootFilter.REALMPLAYER].lootbotmode = not LootFilterVars[LootFilter.REALMPLAYER].lootbotmode;
		if LootFilterVars[LootFilter.REALMPLAYER].lootbotmode then
			LootFilter.takeBagSnapshot(); -- Take fresh snapshot when enabling
			LootFilter.print("|cff00ff00Loot Bot Mode ENABLED|r - Items added to bags will be filtered automatically.");
		else
			LootFilter.print("|cffff0000Loot Bot Mode DISABLED|r - Only items from loot windows will be filtered.");
		end
	elseif (args[1] == "debug") then
		LootFilterVars[LootFilter.REALMPLAYER].debug = not LootFilterVars[LootFilter.REALMPLAYER].debug;
		if LootFilterVars[LootFilter.REALMPLAYER].debug then
			LootFilter.print("|cff00ff00Debug Mode ENABLED|r - Diagnostic output will appear in chat.");
		else
			LootFilter.print("|cffff0000Debug Mode DISABLED|r");
		end
	elseif (args[1] == "status") then
		LootFilter.print("Loot Bot Mode: " .. (LootFilterVars[LootFilter.REALMPLAYER].lootbotmode and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"));
		LootFilter.print("Filtering: " .. (LootFilterVars[LootFilter.REALMPLAYER].enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"));
		LootFilter.print("Debug Mode: " .. (LootFilterVars[LootFilter.REALMPLAYER].debug and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"));
		LootFilter.print("GetSellValue API: " .. (GetSellValue and "|cff00ff00AVAILABLE|r" or "|cffff0000NOT AVAILABLE|r"));
	elseif (args[1] == "help") then
		LootFilter.print("Commands:");
		LootFilter.print("  /lf - Toggle options window");
		LootFilter.print("  /lf lootbot - Toggle loot bot mode (auto-filters items added to bags, e.g. from Scavenger companion)");
		LootFilter.print("  /lf debug - Toggle debug mode (diagnostic output in chat)");
		LootFilter.print("  /lf status - Show current status");
		LootFilter.print("  /lf help - Show this help");
	end;
end;

function LootFilter.constructCleanList()
	LootFilter.cleanList = {};
	local z = 1;
	local slots = 0;
	local totalValue = 0;
	for j=0 , 4 , 1 do
		if (LootFilterVars[LootFilter.REALMPLAYER].openbag[j]) then
			local x = GetContainerNumSlots(j);
			for i=1 , x , 1 do
				local item = LootFilter.getBasicItemInfo(GetContainerItemLink(j,i));
				if (item ~= nil) then
					item["bag"] = j;
					item["slot"] = i;
					item["amount"] = LootFilter.getStackSizeOfItem(item);
					LootFilter.ensureItemValue(item); -- re-resolve value in case GetItemInfo was not ready earlier

					local reason = LootFilter.matchKeepNames(item);
					if (reason ~= "") then
						-- keep name takes highest priority, skip item
					elseif (LootFilter.matchDeleteNames(item) ~= "") then
						item["value"] = item["value"] - 1000; -- delete name overrides keep properties
						LootFilter.cleanList[z] = item;
						z = z + 1;
					else
						reason = LootFilter.matchKeepProperties(item);
						if (reason == "") then
							reason = LootFilter.matchDeleteProperties(item);
							if (reason ~= "") then
								item["value"] = item["value"] - 1000; -- make sure we delete the item with the lowest value (cleanList will be sorted)
							end;
							LootFilter.cleanList[z] = item;
							z = z + 1;
						end;
					end;
				else
					slots = slots + 1;
				end;
			end;
		end;
	end;
	return slots;
end;


function LootFilter.calculateCleanListValue()
	local totalValue = 0;
	local x = table.getn(LootFilter.cleanList);
	for j = 1, x, 1 do
		if (LootFilter.cleanList[j]["value"] < 0) then
			totalValue = totalValue + tonumber((LootFilter.cleanList[j]["value"]+1000)*LootFilter.cleanList[j]["amount"]);
		else
			totalValue = totalValue + tonumber(LootFilter.cleanList[j]["value"]*LootFilter.cleanList[j]["amount"]);
		end;
	end;
	return totalValue;
end;

function LootFilter.deepCopy(orig)
	if type(orig) ~= "table" then
		return orig;
	end
	local copy = {};
	for k, v in pairs(orig) do
		copy[k] = LootFilter.deepCopy(v);
	end
	return copy;
end

function LootFilter.copySettings()
	local realmPlayer = UIDropDownMenu_GetText(LootFilterSelectDropDown);
	LootFilterVars[LootFilter.REALMPLAYER] = LootFilter.deepCopy(LootFilterVars[realmPlayer]);
	LootFilter.getNames();
	LootFilter.getNamesDelete();
	LootFilter.getItemValue();
	LootFilterEditBoxTitleCopy5:Hide();
	LootFilterEditBoxTitleCopy4:Show();
	return;
end;

function LootFilter.deleteSettings()
	local realmPlayer = UIDropDownMenu_GetText(LootFilterSelectDropDown);
	if (realmPlayer ~= LootFilter.REALMPLAYER) then
		LootFilter.deleteTable(LootFilterVars[realmPlayer]);
		LootFilterVars[realmPlayer] = nil;
		UIDropDownMenu_SetSelectedValue(LootFilterSelectDropDown, nil);
		LootFilter.SelectDropDown_Initialize();
		LootFilterEditBoxTitleCopy4:Hide();
		LootFilterEditBoxTitleCopy5:Show();
		LootFilter.initCopyTab();
	end;
end

function LootFilter.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult	
end;


function LootFilter.sessionReset()
	LootFilterVars[LootFilter.REALMPLAYER].session = {};
	LootFilterVars[LootFilter.REALMPLAYER].session["itemValue"] = 0;
	LootFilterVars[LootFilter.REALMPLAYER].session["itemCount"] = 0;
	LootFilterVars[LootFilter.REALMPLAYER].session["start"] = time();
	LootFilterVars[LootFilter.REALMPLAYER].session["end"] = time();
end;

function LootFilter.sessionAdd(item)
	LootFilter.ensureItemValue(item); -- re-resolve value in case GetItemInfo was not ready at loot time
	LootFilterVars[LootFilter.REALMPLAYER].session["itemValue"] = LootFilterVars[LootFilter.REALMPLAYER].session["itemValue"] + item["value"];
	LootFilterVars[LootFilter.REALMPLAYER].session["itemCount"] = LootFilterVars[LootFilter.REALMPLAYER].session["itemCount"] + 1;
end;

function LootFilter.sessionUpdateValues()
	if (not GetSellValue) then
		return;
	end;
	local value = LootFilterVars[LootFilter.REALMPLAYER].session["itemValue"] * 10000;
	LootFilterTextSessionValueInfo:SetText(LootFilter.Locale.LocText["LTSessionInfo"]);
	LootFilterTextSessionItemTotal:SetText(LootFilter.Locale.LocText["LTSessionItemTotal"]..": "..LootFilterVars[LootFilter.REALMPLAYER].session["itemCount"]);
	LootFilterTextSessionValueTotal:SetText(LootFilter.Locale.LocText["LTSessionTotal"]..": "..string.format("|c00FFFF66 %2dg" , value / 10000)..string.format("|c00C0C0C0 %2ds" , string.sub(value,-4)/100)..string.format("|c00CC9900 %2dc" , string.sub(value,-2)));
	local average;
	if (value ~= nil) and (value ~= 0) then
		average = LootFilter.round(value / LootFilterVars[LootFilter.REALMPLAYER].session["itemCount"]);
	else
		average = 0;
	end;
	LootFilterTextSessionValueAverage:SetText(LootFilter.Locale.LocText["LTSessionAverage"]..": "..string.format("|c00FFFF66 %2dg" , average / 10000)..string.format("|c00C0C0C0 %2ds" , string.sub(average,-4)/100)..string.format("|c00CC9900 %2dc" , string.sub(average,-2)));
	if (LootFilterVars[LootFilter.REALMPLAYER].session["end"] == nil) then
		LootFilterVars[LootFilter.REALMPLAYER].session["end"] = LootFilterVars[LootFilter.REALMPLAYER].session["start"];
	end;
	local time = LootFilterVars[LootFilter.REALMPLAYER].session["end"] - LootFilterVars[LootFilter.REALMPLAYER].session["start"];
	if (time ~= 0) then
		local hours = time / 3600;
		if (value ~= nil) and (value ~= 0) then
			if (hours ~= 0) then
				value = LootFilter.round(value / hours);
			end;
		else
			value = 0;
		end;
	else
		value = 0;
	end;
	LootFilterTextSessionValueHour:SetText(LootFilter.Locale.LocText["LTSessionValueHour"]..": "..string.format("|c00FFFF66 %2dg" , value / 10000)..string.format("|c00C0C0C0 %2ds" , string.sub(value,-4)/100)..string.format("|c00CC9900 %2dc" , string.sub(value,-2)));
end;

function LootFilter.deleteTable(t)
	for k, v in pairs(t) do
		if type(v) == "table" then
			LootFilter.deleteTable(t[k]);
		end
		t[k] = nil;
	end
end

