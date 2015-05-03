=====================================================================================
===================================ASSMod Readme=====================================
=====================================================================================

= ASSmod 2.2 =
A Simple Server modification.

This is basically a server admin modification for Garry's Mod. It has a fairly
nice GUI and makes administrating a bit easier then some of the other admin mods
available.

== Access Levels ==
(in order of priority)
0. Owner
1. Super Admin
2. Admin
3. Temp Admin
4. Respected
5. Guest
255. Banned

== Usage ==
Simple bind a key to "+ASS_Menu". I generally use t since it's easy access and
isn't really used for anything else.

Example:
bind "t" "+ASS_Menu"

=== Console Commands ===
The only time you should ever need to use an ASSmod console command is to assign
ownership of the server a player (or players) - This is only really needed on a 
dedicated server, or a server where more then one 'owner' is necessary. This
command is ASS_GiveOwnership <userid>.

Example:
] status
hostname:  The Hole
version : 1.0.0.0/7 3203 secure 
udp/ip  :  192.168.1.6:27015
map     :  gm_construct at: 882 x, -49 y, -79 z
players :  1 (8 max)

# userid name uniqueid connected ping loss state adr
#  9 "AndyVincent" STEAM_0:1:5014589 06:51 91 0 active 127.0.0.1:27005
] ASS_GiveOwnership 9
Ownership Given!

The <userid> option is taken from the first column of the status report.

== Data Files ==
ASSmod keeps 3 files of data, and a few that are used for logging.
The log files are kept at around 20k so they shouldn't grow too big.
The 3 data files are kept in:

garrysmod\data\ass_rankings.txt
garrysmod\data\ass_config_client.txt
garrysmod\data\ass_config_server.txt

The log files are all kept in:

garrysmod\data\asslog\ass_acl_ban_kick.txt
garrysmod\data\asslog\ass_acl_god.txt
garrysmod\data\asslog\ass_acl_health.txt
garrysmod\data\asslog\ass_acl_join_quit.txt
garrysmod\data\asslog\ass_acl_kill.txt
garrysmod\data\asslog\ass_acl_map.txt
garrysmod\data\asslog\ass_acl_notice.txt
garrysmod\data\asslog\ass_acl_promote.txt
garrysmod\data\asslog\ass_acl_rcon.txt
garrysmod\data\asslog\ass_acl_slap.txt
garrysmod\data\asslog\ass_acl_speech.txt
garrysmod\data\asslog\ass_acl_team.txt

This is all assuming that you're using the "Default Writer" plugin
(the chances are that you are, it's the default setup).

== Plugins == 
It's possible to make plugins for this modifiation. Explore the "plugins"
directory. If you don't know Lua the chances are you won't be able to make 
any. Contact me if you need any information that you can't workout.

== Thanks ==
Thanks to:
* Garry for Garry's Mod and Derma (without Derma this mod would've never been made)
* Anmizu for the name
* GiGabyte for helping test
* Ortzinator for helping test
* Mark James for the Silk icon set
* Anyone who commented on the WIP thread
* Anyone who joined my server and let me experiment on them ;)
* Anyone who said "cool" when I showed them a screenshot
* Thanks to Dark_Moo for helping to test the lag problems in 2.0-2.01

== Changes ==
=== 2.2 - 28 Feb 2008 ===
* Fixed possible problems if a client has ASSmod but the server does not.
* Added "admin_speak_prefix" config option
* Guests are now not written to the ASS_Rankings file.
* Spam protection only affects Guests.
* Weapon plugin now checks if the user is allowed to spawn the weapon.

=== 2.11 - 8 Feb 2008 ===
* Fixed "attempt to call method 'Nick' (a nil value)" error when spawning a SWEP
  through the spawn menu.

=== 2.1 - 7 Feb 2008 ===
* No-clip privailages default settings customizable per-level
* Swep/Sent restrictions (like the Tool restrictions)
* Prop protection "Disallow admins mode"
* Progress information when recieving lots of data
* ASS_SetWriterPlugin command (to change the plugin used to write the ranking/log files)

=== 2.05 - 3 Feb 2008 ===
* Fixed "attempt to index global 'INFO' (a nil value)" error when promoting players.

=== 2.04 - 3 Feb 2008 ===
* Fixed potential bug "attempt to call method 'AddOption' (a nil value)" on some
  menus.
* Added tool restrict plugin
* Menus can now stay open after you click an item.

=== 2.03 - 31 Jan 2008 ===
* Removed SetOwner STOOL from minimal and compact distributions.
* Very minor changes to prop protection
* Fixed "Tried to use a NULL entity!" error when looking at some props
* Removed sbox_allownpcs option (since it doesn't exist anymore).
* Added anti-spam plugin (configurable delay between allowed item spawning)
* Removing notices and bans doesn't close the dialog automatically.
* Strip/Kill/Unfreeze/Freeze/Slap/Noclip/God/Team/Give/Strip items all have options
  to perform the action on all players, all non-admins, or all-admins.
* Map favourites list (10 most recently selected maps)

=== 2.02 - 28 Jan 2008 ===
* Rewrote all plugins to use a slightly more efficient system.
* Added in the bitmaps!

=== 2.01 - 28 Jan 2008 ===
* Hopefully hacked around the lag problem.

=== 2.0 - 27 Jan 2008 ===
* Updated to use the new Derma menus
* Now using standard Derma dialogs (and custom ones have the blurred
  background)
* Removed the black and white background
* All plugins will need to be re-written
* Fixed a few bugs (1 day ban bug, kicking random players...)
* removed speed plugin

=== 1.52 - 17 Jan 2008 ===
* Removed: gmsv_asscmd.dll - It's causing crashes and is impossible
           to fix until VALVe release the ability to make mods
           based upon orangebox games. This means that commands
           such as sv_cheats WILL fail using ASSmod's RCON.

=== 1.51 - 14 Jan 2008 ===
* Bug fix: Fixed a bug causing the menus to break in the beta
* Bug fix: "Unknown Player" result from using ASS_GiveOwnership
* Bug fix: Minor change to the way noclip is handled
* Issue: gmsv_asscmd.dll causes crashes when used with the
         beta and a dedicated server. Remove the DLL to fix
         the problem.
* Issue: The menu looks REALLY shitty in the beta. Re-write will
         be needed to make it use the sexy Derma menus...

=== 1.5 - 08 Jan 2008 ===
* Change: Beta compatability
* Change: Console commands can now accept UniqueID, UserID, Steam ID or player
          name
* Bug fixes: Long rcon commands wouldn't work
* Addition: Added Clear Decals plugin by "Camper"
* Addition: Added Sandbox Cleanup plugin
* Addition: "Super" on Slap plugin (fast but little damage)
* Addition: "No Limits" mode for Sandbox (admin only)
* Change: Prop protection "use" is only under Strict
* Addition: Prop protection plugin draws the prop owners name in the bottom-right
            of the screen.

=== 1.4 - 22 Oct 2007 ===
* Bug fixes: Prop protection wouldn't work in some cases
* Change: Non-admins can use the +ASS_Menu command and will get a different menu.
* Change: Black and white post-processing when the menu is active (has an option
          to disable it).
* Addition: Buddy list for prop protection
* Addition: Added "Custom..." to the map change option.
* Addition: Added a "Set Owner" STOOL for the prop protection.
* Addition: Strip weapons / ammo (requested by foxdie)
* Addition: Option to hide the actions of admins (requested by jobbe)
* Addition: Spawn / Give Weapons & items
* Addition: Sandbox options (PvP damage, etc)

=== 1.3 - 18 Sept 2007 ===
* Addition: Prop protection plugin now stops players from using your
            props/entities.
* Addition: Notices can be removed easily.
* Addition: Gamemodes can hide the notice bar (include GM.ASS_HideNoticeBar
            = true in your gamemode code).
* Change: Moved notice stuff to a sub-menu.
* Bug: Fixed a minor problem with custom gamemode icons (it'd always use
       the default icon instead of one specified by the gamemode).
* Bug: Empty tables not loaded correctly by util.KeyValuesToTable (or saved
       by util.TableToKeyValues).

=== 1.22 - 18 Sept 2007 ===
* Addition: Prop protection plugin now stops players from using your
            props/entities.
* Bug: Fixed a minor problem with custom gamemode icons (it'd always use
       the default icon instead of one specified by the gamemode).

=== 1.21 - 16 Sept 2007 ===
* Bug: Fixed a typo in the sandbox limit plugin, which would cause Lua errors.

=== 1.2 - 16 Sept 2007 ===
* Addition: Added a gamemode menu item (this menu items takes the gamemodes name).
            Plugins can add to this item by hooking the AddGamemodeMenu function.
            (see the sandbox plugins for examples).
* Addition: Menu items now can have icons (the AddOption function returns a MENUITEM
            on which you can call SetImage(filename)). Icons are 16x16 in size.
            Thanks to Mark James for the Silk iconset.
* Addition: Sandbox plugins for changing limits, and prop protection.
* Change: Split in to 3 seperate packages: Full (includes all plugins), Compact
          (includes a few plugins), and Minimal (contains no plugins).

=== 1.1 - 08 Sept 2007 ===
* Bug: Default config includes an escape character (which causes
       the string to be cut off - actually a bug in Gmod util.KeyValueToTable)
* Bug: Map change to current doesn't work sometimes
* Addition: Notice bar (top bar) is hideable using the console command
           "ASS_ToggleNoticeBar"
* Addition: Plugin callback "FormatText" this is used to plugins can
            add custom keys for notices (see plugins/ass_exformat.lua)
* Addition: Debug module.
* Documentation: Documented the Kill plugin (it's fairly simple to understand
                 what's happening).

=== 1.0 - 03 Sept 2007 ===
* Initial Release

== Contact ==
PM'ing me on FacePunchStudios is the best option generally but here's my other
contact details should you need them.

Steam: AndyVincent
FPS: AndyVincent
MSN: andyvinc@hotmail.com
GTalk: andy.i.vincent@gmail.com













