v1.07:
NOTE: Version restarted from 1.0 due to extensive custom changes for Project Ebonhold.
Added manual name filter priority override - manual keep/delete name entries now take precedence over all quality/type/value filters.
Added matchKeepNames() and matchDeleteNames() helper functions for isolated name matching.
Restructured filter priority chain: Keep Names -> Delete Names -> Keep Properties -> Delete Properties -> No Match.
All existing name matching patterns (#, ##, exact) remain fully supported.
Maintains backward compatibility with existing filter configurations.


v3.13.1:
Added a setting for heirloom (Binds to account) items.
Added QUhTan to locale files. The new entries are under `qualities' and `radioButtonsText'. Please email locale updates to tweak(at)lootfilter(dot)com.
Fixed a problem where the delete settings button was showing up even when only one profile existed.
Fixed a problem where the delete settings button sometimes wouldn't work.
v3.13:
Fixed a problem with copying settings.
Added a more detailed error message when attempting to use PickupContainerItem on an invalid item location.
Added LFINT_TXT_DELETESETTINGS to locale files. Please email locale updates to tweak(at)lootfilter(dot)com.
Added a delete settings button to the copy tab.
v3.12:
Fixed problem in scheduler.
Fixed problem with loading settings.
v3.11:
Bumped TOC to 3.1
Fixed problem in lib/events.lua.
If anything crops up, let me know and please be specific.
Changed version check to only happen once per minute. Still only active while in a group.
v3.10:
Revamped the scheduler.
Added the option to confirm when an item is deleted. (Requires new localizations, see locale/en.lua for details)
Changed the sorting on the list of items under the "Clean" tab.
v3.9
Fixed some issues with the CN and DE locale.
v3.8:
Fixed an error with the scroll frame in the "Clean" tab.
v3.7:
Updated Loot Filter for compatibility with Wrath of the Lich King.