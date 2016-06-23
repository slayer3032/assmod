#Assmod 2.4 (A simple server modification)

- Quick administration menu, just bind a key to +ass_menu.
- Lua ban system, uses CheckPassword to drop clients with custom reasons.
- Lots of neat plugins.
- Silkicons everywhere!
- Lightweight design unlike ULX.
- MySQL ranks and global bans out of the box. Wow!

###Images
![1](http://dl.dropbox.com/u/5601782/assmod/ranks.PNG)![2](http://dl.dropbox.com/u/5601782/assmod/sandbox.PNG)

###Access Levels
In order of priority, you can edit these in ass_shared.lua

0. Owner
1. Super Admin
2. Admin
3. Temp Admin
4. Respected
5. Guest
255. Banned

###Usage
Simple, bind a key to "+ass_menu". I generally use t since it's easy access and isn't really used for anything else.

```
bind "t" "+ass_menu"
```

###Console Commands
The only time you should ever need to use an Assmod console command is to assign ownership of the server a player (or players) - This is only really needed on a dedicated server, or a server where more then one 'owner' is necessary. This command is ass_giveownership (userid).

```
] status
hostname:  The Hole
version : 1.0.0.0/7 3203 secure 
udp/ip  :  192.168.1.6:27015
map     :  gm_construct at: 882 x, -49 y, -79 z
players :  1 (8 max)
 userid name uniqueid connected ping loss state adr
 9 "AndyVincent" STEAM_0:1:5014589 06:51 91 0 active 127.0.0.1:27005
] ASS_GiveOwnership 9
Ownership Given!
```

The userid option is taken from the first column of the status report.

###Data Files
Assmod's default data writing plugins write text files to the data folder. It will also write log files of admin actions and other basic events to the assmod/logs data folder. These logs are automatically cleared periodically when they get larger.

You can find the data files in garrysmod\data\assmod

This is all assuming that you're using the "Default Writer" plugins, you can also switch over to TMySQL3, TMySQL4 or MySQLOO if you wish so with the following commands. Just place the name of the plugin you'd like to use in place of my examples.

```
ass_setwriterplugin "TMySQL4 Writer"
ass_setbanlistplugin "TMySQL4 Banlist"
ass_setloggerplugin "TMySQL4 Logger"
```

###Thanks
* AndyVincent for being the original developer and creator of ASSmod
* Garry for Garry's Mod and Derma (without Derma this mod would've never been made)
* Anmizu for the name
* GiGabyte for helping test
* Ortzinator for helping test
* Mark James for the Silk icon set
* Anyone who commented on the WIP thread
* Anyone who joined my server and let me experiment on them ;)
* Anyone who said "cool" when I showed them a screenshot
* Thanks to Dark_Moo for helping to test the lag problems in 2.0-2.01

###Contact
- Steam: http://steamcommunity.com/id/SadisticSlayer
- Facepunch: https://facepunch.com/member.php?u=129746
