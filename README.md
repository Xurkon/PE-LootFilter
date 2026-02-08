LOOT FILTER - PROJECT EBONHOLD - WoW WotLK 3.3.5a
=====================================
> **IMPORTANT:** If you get errors after updating this addon, it may be because
> old saved variables are in an outdated format. To fix this, delete (or move as
> a backup) `LootFilter.lua` and `LootFilter.lua.bak` from:
> `<WoW directory>\WTF\Account\<account ID>\<realm>\<character>\SavedVariables\`

A rewrite of the classic LootFilter addon, now compatible with the Scavenger companion (works fine without it too).


INSTALLATION
------------
Place the addon folder in your WoW AddOns directory. The folder **must** be
named `LootFilter` (matching the .toc file):

  `<WoW directory>\Interface\AddOns\LootFilter\`
Biggest difference to the default addon is that we added a function for GetSellValue API instead of relying on a separate addon, this allows the addon to filter items based on vendor price.

What the addon does:
Automatically filter, delete, or sell looted items based on quality, type, value, or name patterns.


COMMANDS
--------
  /lf            Open options window
  /lf lootbot    Toggle loot bot mode (see Loot Bot Mode below)
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


FILTER PRIORITY
---------------
Filters are evaluated in the following order. The first match wins:

  1. Keep Names       - Items on your keep name list are always kept
  2. Delete Names     - Items on your delete name list are always deleted
  3. Keep Properties  - Quality, type, or value rules that keep items
  4. Delete Properties - Quality, type, or value rules that delete items
  5. No Match         - Items that match nothing are kept by default

Name filters always take priority over property filters. This means you
can set broad rules like "keep all Rare items" and still force-delete a
specific item by adding its name to the delete list (or vice versa).

This priority applies everywhere: loot processing, the Clean tab, vendor
selling, and loot bot mode.


LOOT BOT MODE
--------------
Toggle with: /lf lootbot (or /lf bot)

By default, Loot Filter only processes items you loot yourself through
a loot window (right-clicking a corpse, opening a chest, etc.). This
is the normal mode and it works whether loot bot is on or off.

Loot bot mode adds an extra layer: it monitors your bags for items that
appear without a loot window. This is designed for the Scavenger
companion that loots on your behalf, but it works with any source that
puts items directly into your bags.

When you enable loot bot mode, a snapshot of your current bags is taken.
Any items that appear after that point are detected and run through the
same filters as normally looted items. When a loot window is open, bag
monitoring is paused so items are not processed twice.

Both paths — normal looting and loot bot — use the exact same filter
priority chain (Keep Names > Delete Names > Keep Properties > Delete
Properties), so you will always get consistent results.

Loot bot mode is a separate toggle because always-on bag monitoring
could cause false positives — accidentally filtering items received
from trade windows, mailbox, vendors, or quest rewards. Toggle it on
when using a companion and off when you are done.


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
