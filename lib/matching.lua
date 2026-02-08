function LootFilter.matchProperties(key, value, item, keep)
	local reason = "";
	_, _, item["rarity"], _, _, item["type"], item["subType"], _ = GetItemInfo(item["id"]);

	if (string.match(key, "^QU")) then
		LootFilter.debug("|cff00ffff[MATCH]|r Quality check: key=" ..
		tostring(key) .. " ruleValue=" .. tostring(value) .. " itemRarity=" .. tostring(item["rarity"]));
		if (item["rarity"] == value) then
			reason = LootFilter.Locale.LocText["LTQualMatched"] .. " (" .. value .. ")";
		elseif (value == -1) then
			if (string.lower(item["type"]) == LootFilter.Locale.LocText["LTQuest"]) then
				reason = LootFilter.Locale.LocText["LTQuestItem"];
			end;
		end;
	elseif (string.match(key, "^TY")) then
		if (string.match(key, "^TY" .. item["type"])) and (item["subType"] == value) then
			reason = LootFilter.Locale.LocText["LTTypeMatched"] .. " (" .. value .. ")";
		end;
	elseif (string.match(key, "^VA")) then
		if (GetSellValue) and (LootFilterVars[LootFilter.REALMPLAYER].novalue) and ((item["value"] == nil) or (item["value"] <= 0)) then
			reason = LootFilter.Locale.LocText["LTNoKnownValue"];
		elseif (GetSellValue) then
			local calculatedValue;
			if (LootFilterVars[LootFilter.REALMPLAYER].calculate == 1) then
				calculatedValue = tonumber(item["value"]);
			elseif (LootFilterVars[LootFilter.REALMPLAYER].calculate == 2) then
				calculatedValue = tonumber(item["value"] * item["amount"]);
			else
				calculatedValue = tonumber(item["value"] * item["stack"]);
			end;
			if (keep) and (LootFilterVars[LootFilter.REALMPLAYER].keepList["VAOn"]) then
				if (calculatedValue > tonumber(LootFilterVars[LootFilter.REALMPLAYER].keepList["VAValue"]) * 10000) then
					reason = LootFilter.Locale.LocText["LTValueHighEnough"] .. " (" .. calculatedValue / 10000 .. ")";
				end;
			elseif (not keep) and ((LootFilterVars[LootFilter.REALMPLAYER].deleteList["VAOn"])) then
				if (calculatedValue < tonumber(LootFilterVars[LootFilter.REALMPLAYER].deleteList["VAValue"]) * 10000) then
					reason = LootFilter.Locale.LocText["LTValueNotHighEnough"] .. " (" .. calculatedValue / 10000 .. ")";
				end;
			end;
		end;
	elseif (key == "names") then
		for _, name in pairs(value) do
			local nameMatched = LootFilter.matchItemNames(item, name);
			LootFilter.debug("|cff00ffff[NAMES]|r \"" ..
			tostring(name) ..
			"\" vs \"" .. tostring(item["name"]) .. "\" => " .. (nameMatched and "|cff00ff00MATCHED|r" or "no match"));
			if (nameMatched) then
				reason = LootFilter.Locale.LocText["LTNameMatched"] .. " (" .. name .. ")";
				break;
			end;
		end;
	end;
	return reason;
end;

function LootFilter.matchKeepProperties(item)
	local reason = "";

	for key, value in pairs(LootFilterVars[LootFilter.REALMPLAYER].keepList) do
		reason = LootFilter.matchProperties(key, value, item, true);
		if (reason ~= "") then
			return reason;
		end;
	end;
	return reason;
end;

function LootFilter.matchDeleteProperties(item)
	local reason = "";
	for key, value in pairs(LootFilterVars[LootFilter.REALMPLAYER].deleteList) do
		reason = LootFilter.matchProperties(key, value, item, false);
		if (reason ~= "") then
			return reason;
		end;
	end;
	return reason;
end;

function LootFilter.matchKeepNames(item)
	local reason = "";
	if (LootFilterVars[LootFilter.REALMPLAYER].keepList["names"] ~= nil) then
		for _, name in pairs(LootFilterVars[LootFilter.REALMPLAYER].keepList["names"]) do
			local nameMatched = LootFilter.matchItemNames(item, name);
			LootFilter.debug("|cff00ffff[KEEP-NAMES]|r \"" ..
			tostring(name) ..
			"\" vs \"" .. tostring(item["name"]) .. "\" => " .. (nameMatched and "|cff00ff00MATCHED|r" or "no match"));
			if (nameMatched) then
				reason = LootFilter.Locale.LocText["LTNameMatched"] .. " (" .. name .. ")";
				break;
			end;
		end;
	end;
	return reason;
end;

function LootFilter.matchDeleteNames(item)
	local reason = "";
	if (LootFilterVars[LootFilter.REALMPLAYER].deleteList["names"] ~= nil) then
		for _, name in pairs(LootFilterVars[LootFilter.REALMPLAYER].deleteList["names"]) do
			local nameMatched = LootFilter.matchItemNames(item, name);
			LootFilter.debug("|cff00ffff[DELETE-NAMES]|r \"" ..
			tostring(name) ..
			"\" vs \"" .. tostring(item["name"]) .. "\" => " .. (nameMatched and "|cff00ff00MATCHED|r" or "no match"));
			if (nameMatched) then
				reason = LootFilter.Locale.LocText["LTNameMatched"] .. " (" .. name .. ")";
				break;
			end;
		end;
	end;
	return reason;
end;

function LootFilter.findItemInBags(item)
	local x, y;
	local containerItem = {};
	item["bag"] = -1;
	item["slot"] = -1;
	item["count"] = 0;

	for j = 0, 4, 1 do
		if (LootFilterVars[LootFilter.REALMPLAYER].openbag[j]) then
			x = GetContainerNumSlots(j);
			for i = 1, x, 1 do
				containerItem["link"] = GetContainerItemLink(j, i);
				if (containerItem["link"] ~= nil) then
					containerItem["name"] = LootFilter.getNameOfItem(containerItem["link"]);
					containerItem["id"] = LootFilter.getIdOfItem(containerItem["link"]);
					if (containerItem["id"] >= 1) then
						if (LootFilter.matchItemNames(item, containerItem["name"])) then
							item["bag"] = j;
							item["slot"] = i;
							LootFilter.debug("|cff00ffff[FIND]|r Found \"" ..
							tostring(item["name"]) .. "\" in bag=" .. j .. " slot=" .. i);
							return item;
						end;
					end;
				end;
			end;
		end;
	end;
	LootFilter.debug("|cff00ffff[FIND]|r \"" .. tostring(item["name"]) .. "\" NOT found in any bag");
	return item;
end;

function LootFilter.matchItemNames(item, searchName)
	if (item["name"] == nil) or (searchName == nil) then
		return false;
	end;

	local comment;
	searchName, comment = LootFilter.stripComment(searchName);

	if (string.find(searchName, "##", 1, true) == 1) then
		if (item["info"] ~= nil) then
			local pattern = string.lower(string.sub(searchName, 3));
			local ok, result = pcall(string.find, string.lower(item["info"]), pattern);
			if (not ok) then
				LootFilter.debug("Bad pattern in ##: " .. tostring(pattern));
				return false;
			end;
			if (result) then
				return true;
			end;
		end;
	elseif (string.find(searchName, "#", 1, true) == 1) then
		local pattern = string.lower(string.sub(searchName, 2));
		local ok, result = pcall(string.find, string.lower(item["name"]), pattern);
		if (not ok) then
			LootFilter.debug("Bad pattern in #: " .. tostring(pattern));
			return false;
		end;
		if (result) then
			return true;
		end;
	elseif (string.lower(item["name"]) == string.lower(searchName)) then
		return true;
	end;
	return false;
end;
