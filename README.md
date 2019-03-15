# Assmod 2.4 (A simple server modification)

- Quick administration menu, just bind a key to ``+ass_menu``.
- Lua ban system, uses CheckPassword to drop clients with custom reasons.
- Lots of neat plugins.
- Silkicons everywhere!
- Lightweight design unlike ULX.
- MySQL ranks and global bans out of the box. Wow!

### Images
| Access Menu | Gamemode Plugin Menu |
|--|--|
|![1](https://www.exiledservers.net/sadistic/ranks.PNG) |![2](https://www.exiledservers.net/sadistic/sandbox.PNG) |
### Access Levels
In order of priority, you can edit these in ``ass_shared.lua``. Action is allowed if the actor's level is less than the target's level. (ex: 0 < 2, Owners can act on Admins)
| Level | Rank |
| -- | -- |
| 0 | Owner |
| 1 | Super Admin |
| 2 | Admin |
| 3 | Temp Admin |
| 4 | Respected |
| 5 | Guest (Default) |
| 255 | Banned |

### Usage
Simple, bind a key to ``"+ass_menu"``. For example, ``bind "t" "+ass_menu"``.

### Console Commands
The only time you should ever need to use an Assmod console command is to assign ownership of the server a player (or players). This is only really needed on a dedicated server, or a server where more then one 'owner' is necessary. The command is ``ass_giveownership <userid>``.

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

The ``<userid>`` option is taken from the first column of the status report.

### Data Files
Assmod's default data writing plugins write text files to the ``data`` folder. It will also write log files of admin actions and other basic events to the ``assmod/logs`` data folder. These logs are automatically cleared periodically when they get larger.

You can find the data files in ``garrysmod\data\assmod``

This is all assuming that you're using the "Default Writer" plugins, you can also switch over to TMySQL3, TMySQL4 or MySQLOO if you wish so with the following commands. Just place the name of the plugin you'd like to use in place of my examples.

```
ass_setwriterplugin "TMySQL4 Writer"
ass_setbanlistplugin "TMySQL4 Banlist"
ass_setloggerplugin "TMySQL4 Logger"
```

### Contact
- Steam: http://steamcommunity.com/id/SadisticSlayer
- Facepunch: https://forum.facepunch.com/u/lbtn/Slayer3032/
