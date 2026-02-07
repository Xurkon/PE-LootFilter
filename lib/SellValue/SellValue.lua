-- SellValue Library for WoW 3.3.5a (WotLK)
-- Provides GetSellValue API for addons that need item vendor prices
-- Bundled with LootFilter addon

-- Only define if not already defined by another addon
if GetSellValue then
	return;
end

-- Cache for item sell values to reduce API calls
local sellValueCache = {};

-- GetSellValue(itemID) - Returns the vendor sell price for an item in copper
-- @param itemID - The item ID (number) or item link (string)
-- @return number - The sell price in copper, or nil if item not found
function GetSellValue(itemID)
	-- Handle item links by extracting the ID
	if type(itemID) == "string" then
		local extractedID = tonumber(string.match(itemID, "item:(%d+)"));
		if extractedID then
			itemID = extractedID;
		else
			-- Try to extract from simple ID format
			itemID = tonumber(string.match(itemID, ":(%d+)")) or tonumber(itemID);
		end
	end

	if not itemID or itemID == 0 then
		return nil;
	end

	-- Check cache first
	if sellValueCache[itemID] ~= nil then
		return sellValueCache[itemID];
	end

	-- GetItemInfo returns: name, link, quality, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice
	-- Index 11 is the vendor sell price in WoW 3.3.5a
	local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemID);

	if vendorPrice then
		sellValueCache[itemID] = vendorPrice;
		return vendorPrice;
	end

	-- Item not in cache yet (may not be loaded), return nil
	-- The addon should retry later when item info becomes available
	return nil;
end

-- GetSellValueText(itemID) - Returns formatted price string (gold/silver/copper)
-- @param itemID - The item ID (number) or item link (string)
-- @return string - Formatted price string, or "Unknown" if not found
function GetSellValueText(itemID)
	local value = GetSellValue(itemID);
	if not value or value == 0 then
		return "No vendor value";
	end

	local gold = math.floor(value / 10000);
	local silver = math.floor((value % 10000) / 100);
	local copper = value % 100;

	local text = "";
	if gold > 0 then
		text = gold .. "g ";
	end
	if silver > 0 or gold > 0 then
		text = text .. silver .. "s ";
	end
	text = text .. copper .. "c";

	return text;
end

-- ClearSellValueCache() - Clears the cached sell values
-- Call this if you need to force a refresh
function ClearSellValueCache()
	sellValueCache = {};
end

-- Debug message
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00SellValue|r: GetSellValue API loaded (bundled with LootFilter)");
