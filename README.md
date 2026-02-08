LOOT FILTER - PROJECT EBONHOLD - WoW WotLK 3.3.5a
=====================================
(The code is modified using AI so I don't take credit for it)

A rewrite of the classic LootFilter addon, now compatible with the Scavenger companion (works fine without it too).
Biggest difference to the default addon is that we added a function for GetSellValue API instead of relying on a separate addon, this allows the addon to filter items based on vendor price.

What the addon does:
Automatically filter, delete, or sell looted items based on quality, type, value, or name patterns.


COMMANDS
--------
  /lf            Open options window
  /lf lootbot    Toggle Scavenger/companion mode
  /lf debug      Toggle debug diagnostic logging
  /lf status     Show addon status
  /lf help       Show commands


QUICK START
-----------
1. Type /lf to open options
2. Enable "Loot Filter" on General tab
3. Use tabs to configure filters:
   - QUALITY: Filter by rarity (Grey, Green, Blue, etc.)
   - TYPE: Filter by type (Armor, Trade Goods, etc.)
   - NAME: Keep/delete specific items by name
   - VALUE: Filter by vendor price
   - CLEAN: Sell/delete items at vendor

4. For each filter choose: Default / Keep / Delete


SCAVENGER MODE
--------------
If using Scavenger companion, enable with: /lf lootbot

This monitors bags for new items and filters them automatically.
This is a separate toggle because always-on bag monitoring could cause
false positives — accidentally filtering items received from trade
windows, mailbox, vendors, or quest rewards. By toggling it on only
when using a companion, normal looting and other interactions remain
unaffected.


NAME PATTERNS
-------------
  Silk Cloth       Exact match
  #cloth           Contains "cloth"
  ##Soulbound      Tooltip contains "Soulbound"

Add comments: Rugged Leather ; for crafting


VALUE FILTERING
---------------
Set gold thresholds (0.1 = 10 silver):
  - Delete items worth less than X gold
  - Keep items worth more than X gold


CREDITS
-------
Original addon by Meter: https://warperia.com/addon-wotlk/loot-filter/
