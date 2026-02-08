function LootFilter.sortByValue(a, b)
	if ( not a ) then return true;	elseif ( not b ) then return false; end

	local aVal = a["value"] or math.huge;
	local bVal = b["value"] or math.huge;

	if (LootFilterVars[LootFilter.REALMPLAYER].calculate == 2) then
		aVal = aVal * (a["amount"] or 1);
		bVal = bVal * (b["amount"] or 1);
	elseif (LootFilterVars[LootFilter.REALMPLAYER].calculate ~= 1) then
		aVal = aVal * (a["stack"] or 1);
		bVal = bVal * (b["stack"] or 1);
	end;

	return aVal < bVal;
end;


function LootFilter.processCaching()
	if LootFilter.inDialog then
		LootFilter.schedule(LootFilter.LOOT_PARSE_DELAY, LootFilter.processCaching);
		return;
	end
	if (GetTime() > LootFilter.LOOT_MAXTIME) then
		return;
	end;
			
	local slots = LootFilter.constructCleanList();
	
	if (slots < LootFilterVars[LootFilter.REALMPLAYER].freebagslots) and (table.getn(LootFilter.cleanList) > 0)  then
		local needSlots = LootFilterVars[LootFilter.REALMPLAYER].freebagslots-slots;
		
		table.sort(LootFilter.cleanList, LootFilter.sortByValue);
		if (LootFilter.deleteItemFromBag(LootFilter.cleanList[1])) then
			local calculatedValue;
			if (LootFilter.cleanList[1]["value"] < 0) then -- item matched a delete property
				LootFilter.cleanList[1]["value"]  = LootFilter.cleanList[1]["value"] + 10000000; -- restore its original value
			end;
			if (LootFilterVars[LootFilter.REALMPLAYER].calculate == 1) then
				calculatedValue = tonumber(LootFilter.cleanList[1]["value"]);
			elseif (LootFilterVars[LootFilter.REALMPLAYER].calculate == 2) then
				calculatedValue = tonumber(LootFilter.cleanList[1]["value"]*LootFilter.cleanList[1]["amount"]);
			else
				calculatedValue = tonumber(LootFilter.cleanList[1]["value"]*LootFilter.cleanList[1]["stack"]);
			end;
			LootFilter.print(LootFilter.cleanList[1]["link"].." "..LootFilter.Locale.LocText["LTWasDeleted"]..": "..LootFilter.Locale.LocText["LTItemLowestValue"].." ("..calculatedValue / 10000 ..")");
			table.remove(LootFilter.cleanList, 1);
		end;
		LootFilter.schedule(LootFilter.LOOT_PARSE_DELAY, LootFilter.processCaching);				
	end;	
end;


function LootFilter.deleteItems(timeout, delete)
	if (delete) then
		LootFilter.constructCleanList();
	end;
	if (LootFilter.lastCleanListCount ~= table.getn(LootFilter.cleanList)) then
		LootFilter.lastCleanListCount = table.getn(LootFilter.cleanList);
	end;
	
	LootFilterButtonDeleteItems:Enable();
	LootFilterButtonIWantTo:Disable();
	if (not delete) and (LootFilterButtonDeleteItems:GetText() ~= LootFilter.Locale.LocText["LTSellItems"]) then  -- cancel if vendor window is closed while selling
		LootFilter.initClean();
		local cleanLine = getglobal("cleanLine1");
		cleanLine:SetText(LootFilter.Locale.LocText["LTVendorWinClosedWhileSelling"]);
		cleanLine:Show();
		LootFilter.schedule(2, LootFilter.processCleaning);
		return;
	end;

	if (timeout < GetTime()) then -- item could not be found and resulted in a timeout

		LootFilter.initClean();
		local cleanLine = getglobal("cleanLine1");
		cleanLine:SetText(LootFilter.Locale.LocText["LTTimeOutItemNotFound"]);
		cleanLine:Show();
		LootFilter.schedule(2, LootFilter.processCleaning);
		return;
	end;
	
	if (table.getn(LootFilter.cleanList) >= 1) then -- if we have one or more items on the list start selling/deleting
		local interval = 0;
		local item = table.remove(LootFilter.cleanList, 1);
		if (LootFilterButtonDeleteItems:GetText() == LootFilter.Locale.LocText["LTSellItems"]) then -- sell items
			while LootFilter.sellQueue < LootFilter.SELL_QUEUE do
				LootFilter.sellQueue = LootFilter.sellQueue + 1;
				LootFilter.schedule(LootFilter.SELL_INTERVAL, LootFilter.deleteItems, GetTime()+LootFilter.SELL_TIMEOUT, false);
			end;
						
			
			local currentLink = GetContainerItemLink(item["bag"], item["slot"]);
			if (currentLink ~= item["link"]) then
				LootFilter.debug("Skipped stale slot: expected " .. tostring(item["link"]) .. " at bag=" .. item["bag"] .. " slot=" .. item["slot"]);
				LootFilter.schedule(LootFilter.SELL_INTERVAL, LootFilter.deleteItems, GetTime()+LootFilter.SELL_TIMEOUT, false);
				return;
			end;

			UseContainerItem(item["bag"], item["slot"]);
			if (LootFilter.questUpdateToggle == 1) then
				LootFilter.lastDeleted = item["name"];
			end;

			-- give the client time to actually sell the item
			LootFilter.schedule(LootFilter.SELL_INTERVAL, LootFilter.checkIfItemSold, GetTime()+LootFilter.SELL_ITEM_TIMEOUT, item);
			
			return;
		else -- delete items
			if (LootFilter.deleteItemFromBag(item)) then
				if (LootFilter.questUpdateToggle == 1) then
					LootFilter.lastDeleted = item["name"];
				end;
			end;
			interval = LootFilter.LOOT_PARSE_DELAY;
			LootFilter.CleanScrollBar_Update(true);
			LootFilter.schedule(interval, LootFilter.deleteItems, timeout, delete);
		end;		
		
	else
		LootFilter.sellQueue = 0;
		LootFilter.initClean();
		local cleanLine = getglobal("cleanLine1");
		cleanLine:SetText(LootFilter.Locale.LocText["LTFinishedSC"]);
		cleanLine:Show();		
		LootFilter.schedule(2, LootFilter.processCleaning);
	end;
end;

function LootFilter.checkIfItemSold(timeout, item)
	
	if (timeout < GetTime()) or (GetContainerItemLink(item["bag"], item["slot"]) == nil) then -- item sold or could not be sold (timeout)
		LootFilter.schedule(LootFilter.SELL_INTERVAL, LootFilter.deleteItems, GetTime()+LootFilter.SELL_TIMEOUT, false);
		LootFilter.CleanScrollBar_Update(true);
	else
		UseContainerItem(item["bag"], item["slot"]);
		LootFilter.schedule(LootFilter.SELL_INTERVAL, LootFilter.checkIfItemSold, timeout, item);
	end;
	
end;

