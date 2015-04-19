/*
Cops vs Terrorists [BASE GM FOR BEGINNERS] [MySQL] - Brought to you by Kapersky.
This script is created by Kapersky & LivingLikeYouDo (Most support - I'm here because of him.)
Thanks for the support guys! I'm thankful to you guys! 
 
SCRIPTING NOTES: 
 - Script uses MySQL latest libraries.
 - Team '1' is Cops - Team '2' is Terrorists - Team '0' is none.
 - Variables declared with a 'char' at the end saves more memory, and should be accessed with curly brackets ' { } ', as defined in Slice tutorial. EX: gIsNewHere { playerid } = false;
 - Do not add air-killing vehicles such as Hunter or Sparrows. They provide extra power over killing.
 - Anticheat Settings:
        ALWAYS use SetPlayerHealthEx / SetPlayerArmourEx to set the players health/armour, or else the script will detect the player as hacking!*/
#include	<a_samp>
#include	<a_mysql>
#include	<ZCMD>
#include	<colors>
#include	<foreach>
#include	<mSelection>
#include	<streamer>
#include	<ZCMD>
#include	<sscanf2>

#undef          MAX_PLAYERS
#define         MAX_PLAYERS 50

#define         HOST                            "localhost"
#define         DB                              "tdm"
#define         USER                            "root"
#define         PASS                            ""

#define         D_REG                           (1)
#define         D_LOG                           (2)
#define         D_TEAM                  (3)
#define         D_ACMDLIST              (4)

#define         TEAM_COPS                       1
#define         TEAM_TERRORISTS         2

#define         CUSTOM_SKIN_ARMY_MENU   3
#define         CUSTOM_SKIN_TERROR_MENU 4

#define         SERVER_NAME             "[BASE] Cops vs Terrorists"
#define         SERVER_VERSION          "CVT 0.1a"
a
#define         AdminOnly               "You are not authourized to use this command!");
#define         SCM                     SendClientMessage
#define         SCMTA                   SendClientMessageToAll

new
mysql,
Name[MAX_PLAYERS][24],
IP[MAX_PLAYERS][16]
;

native WP_Hash(buffer[], len, const str[]);

enum E_PLAYER_DATA
{
	ID,
	Password[129],
	Money,
	Admin,
	VIP,
	Team
}

new
pInfo[MAX_PLAYERS][E_PLAYER_DATA],
gLoginAttempts[MAX_PLAYERS],
bool:gIsNewHere[MAX_PLAYERS char],
bool:gAntiSpawnProtected[MAX_PLAYERS char],
gHealth[MAX_PLAYERS],
gArmour[MAX_PLAYERS],
gIsLogged[MAX_PLAYERS char],
IsPMEnabled[MAX_PLAYERS char],
Float:SpecX[MAX_PLAYERS],
Float:SpecY[MAX_PLAYERS],
Float:SpecZ[MAX_PLAYERS],
vWorld[MAX_PLAYERS],
Inter[MAX_PLAYERS],
IsSpecing[MAX_PLAYERS],
IsBeingSpeced[MAX_PLAYERS],spectatorid[MAX_PLAYERS];

//TDs
new
PlayerText:CVTIntro_TD[MAX_PLAYERS][10],
Text:randommsg;

//Arrays:
new Float:RandomArmySpawn[][] =
{
	{191.0500, 1931.2633, 17.6406, 87.7332},
	{225.1407, 1867.3564, 13.1406, 87.4198},
	{211.0664, 1810.9338, 21.8672, 99.3032},
	{349.1653, 2029.8040, 22.6406, 85.2495}
};

new Float:RandomTerroristSpawn[][] =
{
	{-1503.8159, 2618.3647, 55.8359, 267.9561},
	{-1451.6556, 2589.7002, 59.7459, 2.2938},
	{-1389.8231, 2638.2393, 55.9844, 174.4604},
	{-1466.4821, 2686.5588, 55.8359, 170.2186}
};

new RandomMessages[][] =
{
	"~y~[CVT] RM: ~w~Ever spotted a ~r~hacker?~w~ ~g~/report~w~ him to the administrators!",
	"~y~[CVT] RM: ~w~Want to suggest something or report a bug? ~g~Visit our forums!",
	"~y~[CVT] RM: ~w~Make sure you register at our ~g~forums~w~ and register to our newsletter!",
	"~y~[CVT] RM: ~w~Just ~g~chill~w~, and ~r~kill!"
};


//Functions forwards
forward OnPlayerAccountCheck(playerid);
forward OnPlayerAccountRegister(playerid);
forward OnPlayerAccountLoad(playerid);
forward RandomMessage();

//Timers
forward KickPlayer(playerid);
forward SaveAccountsPerMinute(playerid);
forward AntiSpawnTimer(playerid);
forward Anticheat(playerid);

main()
{
	print("\n [CVT] Cops vs Terrorists.");
	print(" Created by Kapersky");
	print(" Now loading.\n");
}

public OnGameModeInit()
{
	SetGameModeText(SERVER_VERSION);
	
	//Server settings:
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
	ShowNameTags(1);
	SetNameTagDrawDistance(10.0);
	EnableStuntBonusForAll(0);
	DisableInteriorEnterExits();
	
	//MySQL Connection:
	mysql_log( LOG_ERROR | LOG_WARNING | LOG_DEBUG );
	mysql = mysql_connect( HOST , USER , DB , PASS );
	
	if(mysql_errno(mysql) != 0)
	{
		printf("ERROR: MySQL could not connect to mysql. Console quiting.");
		SendRconCommand("exit");
	}
	/////////
	
	//We will not use player classes.
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	
	foreach(Player,i)
	{
		SetTimerEx("SaveAccountsPerMinute", 60000, true, "u", i);
	}
	
	SetTimer("RandomMessage",8000,1); //We define the random messages per 8 seconds.
	
	//Global Textdraws Creation:
	randommsg = TextDrawCreate(7.000000, 427.000000, "You don't need to add any text here");
	TextDrawBackgroundColor(randommsg, 255);
	TextDrawFont(randommsg, 1);
	TextDrawLetterSize(randommsg, 0.379999, 1.499999);
	TextDrawColor(randommsg, -1);
	TextDrawSetOutline(randommsg, 1);
	TextDrawSetProportional(randommsg, 1);
	
	//Objects and vehicles
	AddStaticVehicle(476,308.6000100,2055.2000000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,320.0996100,2055.2998000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,296.7000100,2055.3000000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,297.2000100,2065.8000000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,319.8999900,2065.5000000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,308.5000000,2065.7002000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,287.3999900,2059.3999000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,329.8999900,2059.7000000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,314.8999900,2043.6000000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,291.5996100,2043.7002000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,303.2998000,2043.5996000,18.8000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(476,327.1000100,2043.9000000,19.1000000,180.0000000,105,88); //Rustler
	AddStaticVehicle(432,272.0000000,2014.5000000,17.7000000,270.0000000,95,10); //Rhino
	AddStaticVehicle(432,271.8999900,2021.0000000,17.7000000,270.0000000,95,10); //Rhino
	AddStaticVehicle(432,271.9003900,2026.7998000,17.7000000,270.0000000,95,10); //Rhino
	AddStaticVehicle(432,271.7000100,2032.3000000,17.7000000,270.0000000,95,10); //Rhino
	AddStaticVehicle(432,282.8999900,2025.1000000,17.7000000,270.0000000,95,10); //Rhino
	AddStaticVehicle(433,280.7000100,1983.4000000,18.2000000,270.0000000,95,10); //Barracks
	AddStaticVehicle(433,280.7000100,1989.0000000,18.2000000,270.0000000,95,10); //Barracks
	AddStaticVehicle(433,280.5000000,1994.6000000,18.2000000,270.0000000,95,10); //Barracks
	AddStaticVehicle(470,282.2000100,1953.0000000,17.8000000,270.0000000,95,10); //Patriot
	AddStaticVehicle(470,282.4003900,1948.7998000,17.8000000,270.0000000,95,10); //Patriot
	AddStaticVehicle(470,282.0000000,1959.5000000,17.8000000,270.0000000,95,10); //Patriot
	AddStaticVehicle(470,282.1000100,1956.3000000,17.8000000,270.0000000,95,10); //Patriot
	AddStaticVehicle(470,281.8999900,1962.8000000,17.8000000,270.0000000,95,10); //Patriot
	AddStaticVehicle(470,235.3000000,1917.3000000,17.8000000,145.0000000,95,10); //Patriot
	AddStaticVehicle(470,235.1000100,1911.3000000,17.8000000,144.9980000,95,10); //Patriot
	AddStaticVehicle(470,235.1000100,1905.3000000,17.8000000,144.9980000,95,10); //Patriot
	AddStaticVehicle(470,234.7000000,1899.5000000,17.8000000,144.9980000,95,10); //Patriot
	AddStaticVehicle(470,234.5000000,1888.0000000,17.8000000,144.9980000,95,10); //Patriot
	AddStaticVehicle(470,235.0000000,1893.9004000,17.8000000,144.9980000,95,10); //Patriot
	AddStaticVehicle(470,234.3000000,1876.7000000,17.8000000,144.9980000,95,10); //Patriot
	AddStaticVehicle(470,234.2002000,1882.2002000,17.8000000,144.9980000,95,10); //Patriot
	AddStaticVehicle(497,208.3999900,1931.4000000,23.5000000,0.0000000,-1,-1); //Police Maverick
	AddStaticVehicle(497,223.5996100,1886.7998000,17.9000000,0.0000000,-1,-1); //Police Maverick
	AddStaticVehicle(497,205.2002000,1886.5996000,17.9000000,0.0000000,-1,-1); //Police Maverick
	AddStaticVehicle(497,196.0000000,1931.2002000,23.5000000,0.0000000,-1,-1); //Police Maverick
	AddStaticVehicle(497,220.8999900,1931.5000000,23.5000000,0.0000000,-1,-1); //Police Maverick
	AddStaticVehicle(482,222.8000000,1866.3000000,13.3000000,90.0000000,102,28); //Burrito
	AddStaticVehicle(482,222.5000000,1863.5000000,13.4000000,90.0000000,102,28); //Burrito
	AddStaticVehicle(482,222.6000100,1860.6000000,13.4000000,90.0000000,102,28); //Burrito
	AddStaticVehicle(599,213.8999900,1860.4000000,13.5000000,0.0000000,-1,-1); //Police Ranger
	AddStaticVehicle(599,210.8000000,1860.4000000,13.5000000,0.0000000,-1,-1); //Police Ranger
	AddStaticVehicle(599,207.0000000,1860.7000000,13.5000000,0.0000000,-1,-1); //Police Ranger
	AddStaticVehicle(599,203.2000000,1861.1000000,13.5000000,0.0000000,-1,-1); //Police Ranger
	AddStaticVehicle(522,153.3000000,1914.2000000,18.5000000,0.0000000,76,117); //NRG-500
	AddStaticVehicle(522,152.2000000,1914.2000000,18.5000000,0.0000000,76,117); //NRG-500
	AddStaticVehicle(522,154.2000000,1914.1000000,18.5000000,0.0000000,76,117); //NRG-500
	AddStaticVehicle(522,153.2998000,1914.2002000,18.5000000,0.0000000,76,117); //NRG-500
	AddStaticVehicle(522,151.2000000,1914.2000000,18.5000000,0.0000000,76,117); //NRG-500
	AddStaticVehicle(522,150.2000000,1914.2000000,18.5000000,0.0000000,76,117); //NRG-500
	AddStaticVehicle(522,149.2000000,1914.2000000,18.5000000,0.0000000,76,117); //NRG-500
	AddStaticVehicle(522,148.2000000,1914.3000000,18.5000000,0.0000000,76,117); //NRG-500
	AddStaticVehicle(598,158.5000000,1908.2000000,18.6000000,0.0000000,-1,-1); //Police Car (LVPD)
	AddStaticVehicle(598,161.2000000,1908.2000000,18.5000000,0.0000000,-1,-1); //Police Car (LVPD)
	AddStaticVehicle(598,164.0000000,1908.2000000,18.4000000,0.0000000,-1,-1); //Police Car (LVPD)
	AddStaticVehicle(598,169.2000000,1908.2000000,18.3000000,0.0000000,-1,-1); //Police Car (LVPD)
	AddStaticVehicle(598,166.5996100,1908.2002000,18.3000000,0.0000000,-1,-1); //Police Car (LVPD)
	AddStaticVehicle(598,174.8999900,1908.3000000,18.1000000,0.0000000,-1,-1); //Police Car (LVPD)
	AddStaticVehicle(598,172.0000000,1908.2002000,18.2000000,0.0000000,-1,-1); //Police Car (LVPD)
	AddStaticVehicle(598,177.8999900,1908.4000000,17.9000000,0.0000000,-1,-1); //Police Car (LVPD)
	AddStaticVehicle(490,130.1000100,1915.2000000,19.2000000,0.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(490,137.7002000,1915.2002000,19.2000000,0.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(490,133.9003900,1915.0996000,19.2000000,0.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(490,125.3000000,1914.3000000,19.2000000,45.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(490,124.3000000,1911.0000000,19.1000000,45.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(490,123.7000000,1902.3000000,18.9000000,45.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(490,123.7998000,1906.5996000,19.0000000,45.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(490,124.0000000,1893.9000000,18.7000000,45.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(490,123.7998000,1898.2002000,18.8000000,45.0000000,-1,-1); //FBI Rancher
	AddStaticVehicle(427,149.3999900,1869.5000000,18.1000000,270.0000000,-1,-1); //Enforcer
	AddStaticVehicle(427,149.2000000,1878.8000000,18.2000000,270.0000000,-1,-1); //Enforcer
	AddStaticVehicle(427,149.3999900,1872.7000000,18.1000000,270.0000000,-1,-1); //Enforcer
	AddStaticVehicle(427,149.2998000,1875.5996000,18.1000000,270.0000000,-1,-1); //Enforcer
	AddStaticVehicle(427,149.2000000,1881.9000000,18.3000000,270.0000000,-1,-1); //Enforcer
	AddStaticVehicle(417,349.3999900,1941.1000000,18.0000000,0.0000000,-1,-1); //Leviathan
	AddStaticVehicle(561,113.9000000,1864.2000000,17.7000000,0.0000000,63,62); //Stratum
	AddStaticVehicle(561,123.7000000,1864.1000000,17.7000000,0.0000000,63,62); //Stratum
	AddStaticVehicle(561,117.5996100,1864.2002000,17.7000000,0.0000000,63,62); //Stratum
	AddStaticVehicle(561,120.7998000,1864.0996000,17.7000000,0.0000000,63,62); //Stratum
	AddStaticVehicle(469,116.9000000,1840.5000000,17.7000000,0.0000000,245,245); //Sparrow
	AddStaticVehicle(469,117.5000000,1827.4004000,17.7000000,0.0000000,245,245); //Sparrow
	AddStaticVehicle(469,129.7998000,1827.9004000,17.7000000,0.0000000,245,245); //Sparrow
	AddStaticVehicle(469,129.7998000,1840.4004000,17.7000000,0.0000000,245,245); //Sparrow
	AddStaticVehicle(565,-1561.9000000,2661.1001000,55.5000000,0.0000000,76,117); //Flash
	AddStaticVehicle(565,-1564.5000000,2661.0000000,55.5000000,0.0000000,76,117); //Flash
	AddStaticVehicle(565,-1567.1000000,2661.0000000,55.5000000,0.0000000,76,117); //Flash
	AddStaticVehicle(565,-1572.2000000,2661.0000000,55.5000000,0.0000000,76,117); //Flash
	AddStaticVehicle(565,-1569.5996000,2661.0000000,55.5000000,0.0000000,76,117); //Flash
	AddStaticVehicle(559,-1520.3000000,2630.3000000,55.6000000,0.0000000,109,24); //Jester
	AddStaticVehicle(559,-1517.0996000,2630.2002000,55.6000000,0.0000000,109,24); //Jester
	AddStaticVehicle(559,-1523.4000000,2630.2000000,55.6000000,0.0000000,109,24); //Jester
	AddStaticVehicle(559,-1532.7000000,2627.0000000,55.6000000,0.0000000,109,24); //Jester
	AddStaticVehicle(559,-1526.5000000,2630.3000000,55.6000000,0.0000000,109,24); //Jester
	AddStaticVehicle(559,-1529.2002000,2627.0000000,55.6000000,0.0000000,109,24); //Jester
	AddStaticVehicle(555,-1540.9000000,2586.3000000,55.6000000,0.0000000,48,79); //Windsor
	AddStaticVehicle(555,-1541.0000000,2579.3999000,55.5000000,0.0000000,48,79); //Windsor
	AddStaticVehicle(555,-1551.0000000,2569.5000000,55.6000000,0.0000000,48,79); //Windsor
	AddStaticVehicle(555,-1541.0996000,2571.7002000,55.5000000,0.0000000,48,79); //Windsor
	AddStaticVehicle(555,-1541.0996000,2563.2002000,55.5000000,0.0000000,48,79); //Windsor
	AddStaticVehicle(555,-1551.0000000,2577.0000000,55.6000000,0.0000000,48,79); //Windsor
	AddStaticVehicle(555,-1551.0000000,2584.2000000,55.6000000,0.0000000,48,79); //Windsor
	AddStaticVehicle(555,-1551.0000000,2590.8999000,55.6000000,0.0000000,48,79); //Windsor
	AddStaticVehicle(480,-1431.1000000,2614.0000000,55.7000000,0.0000000,42,119); //Comet
	AddStaticVehicle(480,-1431.0000000,2620.3999000,55.7000000,0.0000000,42,119); //Comet
	AddStaticVehicle(480,-1420.9000000,2619.5000000,55.7000000,0.0000000,42,119); //Comet
	AddStaticVehicle(480,-1431.0000000,2626.6006000,55.7000000,0.0000000,42,119); //Comet
	AddStaticVehicle(480,-1430.9004000,2633.7002000,55.5000000,0.0000000,42,119); //Comet
	AddStaticVehicle(480,-1421.0000000,2613.6006000,55.5000000,0.0000000,42,119); //Comet
	AddStaticVehicle(480,-1420.8000000,2633.3999000,55.7000000,0.0000000,42,119); //Comet
	AddStaticVehicle(480,-1420.7002000,2626.1006000,55.7000000,0.0000000,42,119); //Comet
	AddStaticVehicle(417,-1447.3000000,2616.7000000,60.8000000,0.0000000,-1,-1); //Leviathan
	AddStaticVehicle(417,-1465.4000000,2620.7000000,61.1000000,0.0000000,-1,-1); //Leviathan
	AddStaticVehicle(447,-1509.9000000,2532.2000000,55.8000000,0.0000000,32,32); //Seasparrow
	AddStaticVehicle(447,-1498.5000000,2532.2998000,55.8000000,0.0000000,32,32); //Seasparrow
	AddStaticVehicle(447,-1520.6000000,2532.3999000,55.8000000,0.0000000,32,32); //Seasparrow
	AddStaticVehicle(447,-1531.6000000,2532.3000000,55.8000000,0.0000000,32,32); //Seasparrow
	AddStaticVehicle(563,-1530.7000000,2583.8000000,61.5000000,0.0000000,245,245); //Raindance
	AddStaticVehicle(563,-1481.0996000,2582.7002000,61.5000000,0.0000000,245,245); //Raindance
	AddStaticVehicle(563,-1512.5000000,2584.4004000,61.9000000,0.0000000,245,245); //Raindance
	AddStaticVehicle(476,-1542.1000000,2483.2000000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(476,-1529.4000000,2483.1001000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(476,-1517.0000000,2483.2000000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(476,-1517.0000000,2472.6001000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(476,-1529.2000000,2472.8000000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(476,-1541.3000000,2473.0000000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(476,-1541.0000000,2462.5000000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(476,-1528.9000000,2462.6001000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(476,-1517.1000000,2462.7000000,57.6000000,180.0000000,111,130); //Rustler
	AddStaticVehicle(553,-1490.7000000,2473.6001000,58.6000000,180.0000000,125,98); //Nevada
	AddStaticVehicle(553,-1490.9000000,2447.6001000,58.6000000,180.0000000,125,98); //Nevada
	AddStaticVehicle(447,-1529.8000000,2617.3000000,59.7000000,0.0000000,32,32); //Seasparrow
	AddStaticVehicle(447,-1509.2000000,2616.5000000,59.6000000,0.0000000,32,32); //Seasparrow
	AddStaticVehicle(447,-1519.7002000,2617.1006000,59.8000000,0.0000000,32,32); //Seasparrow
	AddStaticVehicle(422,-1406.9000000,2658.2000000,55.8000000,0.0000000,30,46); //Bobcat
	AddStaticVehicle(422,-1412.3000000,2658.3000000,55.8000000,0.0000000,30,46); //Bobcat
	AddStaticVehicle(422,-1409.7998000,2658.2002000,55.8000000,0.0000000,30,46); //Bobcat
	AddStaticVehicle(428,-1400.4000000,2659.7000000,55.9000000,90.0000000,38,55); //Securicar
	AddStaticVehicle(428,-1400.5000000,2650.2000000,55.9000000,90.0000000,38,55); //Securicar
	AddStaticVehicle(428,-1400.5996000,2656.5000000,55.9000000,90.0000000,38,55); //Securicar
	AddStaticVehicle(428,-1400.5996000,2653.4004000,55.9000000,90.0000000,38,55); //Securicar
	AddStaticVehicle(600,-1400.7000000,2643.8000000,55.5000000,90.0000000,189,190); //Picador
	AddStaticVehicle(600,-1400.7000000,2637.7000000,55.5000000,90.0000000,189,190); //Picador
	AddStaticVehicle(600,-1400.7998000,2640.7998000,55.5000000,90.0000000,189,190); //Picador
	AddStaticVehicle(600,-1400.8000000,2631.7000000,55.6000000,90.0000000,189,190); //Picador
	AddStaticVehicle(600,-1400.7998000,2634.6006000,55.6000000,90.0000000,189,190); //Picador
	AddStaticVehicle(522,-1452.3000000,2658.7000000,55.5000000,0.0000000,109,122); //NRG-500
	AddStaticVehicle(522,-1457.4004000,2658.7002000,55.5000000,0.0000000,109,122); //NRG-500
	AddStaticVehicle(522,-1456.2002000,2658.7998000,55.5000000,0.0000000,109,122); //NRG-500
	AddStaticVehicle(522,-1455.2002000,2658.7998000,55.5000000,0.0000000,109,122); //NRG-500
	AddStaticVehicle(522,-1454.2002000,2658.7998000,55.5000000,0.0000000,109,122); //NRG-500
	AddStaticVehicle(522,-1450.3000000,2658.7000000,55.5000000,0.0000000,109,122); //NRG-500
	AddStaticVehicle(522,-1451.3000000,2658.6001000,55.5000000,0.0000000,109,122); //NRG-500
	AddStaticVehicle(522,-1453.3000000,2658.8000000,55.5000000,0.0000000,109,122); //NRG-500
	AddStaticVehicle(580,-1478.0000000,2663.1001000,55.7000000,0.0000000,109,108); //Stafford
	AddStaticVehicle(580,-1474.3000000,2663.1001000,55.7000000,0.0000000,109,108); //Stafford
	AddStaticVehicle(580,-1462.6000000,2663.0000000,55.7000000,0.0000000,109,108); //Stafford
	AddStaticVehicle(580,-1470.7002000,2663.1006000,55.7000000,0.0000000,109,108); //Stafford
	AddStaticVehicle(580,-1467.9004000,2663.0000000,55.7000000,0.0000000,109,108); //Stafford
	AddStaticVehicle(580,-1465.2002000,2663.0000000,55.7000000,0.0000000,109,108); //Stafford
	AddStaticVehicle(584,-1303.4000000,2702.3999000,51.2000000,6.0000000,245,245); //Trailer 3
	AddStaticVehicle(584,-1311.2000000,2699.7000000,51.2000000,4.0000000,245,245); //Trailer 3
	AddStaticVehicle(584,-1307.0996000,2701.2998000,51.2000000,6.0000000,245,245); //Trailer 3
	CreateDynamicObject(3399,284.3999900,1832.3000000,18.0000000,0.0000000,0.0000000,90.0000000); //object(cxrf_a51_stairs) (1)
	CreateDynamicObject(3399,284.3999900,1844.0000000,22.5000000,0.0000000,0.0000000,90.0000000); //object(cxrf_a51_stairs) (2)
	CreateDynamicObject(3399,286.7002000,1855.5996000,22.5000000,0.0000000,0.0000000,270.0000000); //object(cxrf_a51_stairs) (3)
	CreateDynamicObject(3399,286.6000100,1867.2000000,17.8000000,0.0000000,0.0000000,270.0000000); //object(cxrf_a51_stairs) (4)
	CreateDynamicObject(13647,164.0000000,1964.8000000,17.7000000,0.0000000,0.0000000,0.0000000); //object(wall1) (1)
	CreateDynamicObject(13647,107.5000000,1964.4000000,17.8000000,0.0000000,0.0000000,0.0000000); //object(wall1) (2)
	CreateDynamicObject(4724,148.3999900,1929.5000000,20.1000000,0.0000000,0.0000000,0.0000000); //object(librarywall_lan2) (1)
	CreateDynamicObject(4724,176.8999900,1921.4000000,19.1000000,0.0000000,0.0000000,180.0000000); //object(librarywall_lan2) (2)
	CreateDynamicObject(4603,87.6000000,2011.9000000,22.7000000,0.0000000,0.0000000,90.0000000); //object(sky4plaz2_lan) (1)
	CreateDynamicObject(4726,348.2000100,1937.0000000,15.4000000,0.0000000,0.0000000,0.0000000); //object(libtwrhelipd_lan2) (1)
	CreateDynamicObject(3095,268.2000100,1883.6000000,15.9000000,0.0000000,0.0000000,0.0000000); //object(a51_jetdoor) (1)
	CreateDynamicObject(3271,217.5000000,1985.8000000,16.6000000,0.0000000,0.0000000,0.0000000); //object(bonyrd_block3_) (1)
	CreateDynamicObject(3271,246.5000000,2010.9000000,16.8000000,0.0000000,0.0000000,0.0000000); //object(bonyrd_block3_) (2)
	CreateDynamicObject(3271,244.9003900,1964.5996000,16.6000000,0.0000000,0.0000000,0.0000000); //object(bonyrd_block3_) (3)
	CreateDynamicObject(12911,165.7000000,1993.6000000,17.6000000,0.0000000,0.0000000,0.0000000); //object(sw_silo02) (1)
	CreateDynamicObject(12911,178.7998000,1989.5996000,17.1000000,0.0000000,0.0000000,0.0000000); //object(sw_silo02) (2)
	CreateDynamicObject(3934,129.8999900,1841.1000000,16.7000000,0.0000000,0.0000000,0.0000000); //object(helipad01) (1)
	CreateDynamicObject(3934,116.9000000,1841.1000000,16.7000000,0.0000000,0.0000000,0.0000000); //object(helipad01) (2)
	CreateDynamicObject(3934,117.4000000,1828.4000000,16.7000000,0.0000000,0.0000000,0.0000000); //object(helipad01) (3)
	CreateDynamicObject(3934,129.8999900,1828.7000000,16.7000000,0.0000000,0.0000000,0.0000000); //object(helipad01) (4)
	CreateDynamicObject(8171,-1490.1000000,2419.1001000,55.4000000,0.0000000,0.0000000,0.0000000); //object(vgssairportland06) (1)
	CreateDynamicObject(8171,-1529.9004000,2419.1006000,55.4000000,0.0000000,0.0000000,0.0000000); //object(vgssairportland06) (2)
	CreateDynamicObject(1337,-1474.9258000,2388.9805000,50.5988000,0.0000000,0.0000000,0.0000000); //object(binnt07_la) (4)
	CreateDynamicObject(7191,-1470.3000000,2376.7000000,53.3000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (1)
	CreateDynamicObject(7191,-1470.4000000,2421.3000000,53.3000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (3)
	CreateDynamicObject(7191,-1470.3000000,2466.1001000,53.3000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (4)
	CreateDynamicObject(7191,-1492.8000000,2488.0000000,53.3000000,0.0000000,0.0000000,90.0000000); //object(vegasnnewfence2b) (5)
	CreateDynamicObject(7191,-1527.5996000,2488.0000000,53.3000000,0.0000000,0.0000000,90.0000000); //object(vegasnnewfence2b) (6)
	CreateDynamicObject(7191,-1549.9004000,2466.0000000,53.3000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (8)
	CreateDynamicObject(7191,-1549.8000000,2421.5000000,53.3000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (2)
	CreateDynamicObject(7191,-1549.9000000,2376.6001000,53.3000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (7)
	CreateDynamicObject(7191,-1549.9000000,2376.6001000,49.8000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (9)
	CreateDynamicObject(7191,-1549.9000000,2376.6001000,46.0000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (10)
	CreateDynamicObject(7191,-1549.9000000,2376.6001000,42.0000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (11)
	CreateDynamicObject(7191,-1549.8000000,2421.5000000,49.5000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (12)
	CreateDynamicObject(7191,-1549.8000000,2421.5000000,45.8000000,0.0000000,0.0000000,0.0000000); //object(vegasnnewfence2b) (13)
	CreateDynamicObject(7191,-1527.8000000,2350.1001000,53.3000000,0.0000000,0.0000000,90.0000000); //object(vegasnnewfence2b) (14)
	CreateDynamicObject(7191,-1527.8000000,2350.1001000,49.4000000,0.0000000,0.0000000,90.0000000); //object(vegasnnewfence2b) (15)
	CreateDynamicObject(7191,-1527.8000000,2350.1001000,46.2000000,0.0000000,0.0000000,90.0000000); //object(vegasnnewfence2b) (16)
	CreateDynamicObject(7191,-1492.9000000,2350.3000000,53.3000000,0.0000000,0.0000000,90.0000000); //object(vegasnnewfence2b) (17)
	CreateDynamicObject(7191,-1492.9000000,2350.3000000,49.8000000,0.0000000,0.0000000,90.0000000); //object(vegasnnewfence2b) (18)
	CreateDynamicObject(3279,-1545.2000000,2354.5000000,55.4000000,0.0000000,0.0000000,0.0000000); //object(a51_spottower) (1)
	CreateDynamicObject(3279,-1473.9000000,2354.8000000,55.4000000,0.0000000,0.0000000,180.0000000); //object(a51_spottower) (2)
	
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SpawnPlayer(playerid);
	return 1;
}

public OnPlayerConnect(playerid)
{
	//Reseting Vars
	gIsNewHere { playerid } = false;
	gLoginAttempts[ playerid ] = 0;
	gAntiSpawnProtected{ playerid } = false;
	gHealth[playerid] = 0;
	gHealth[playerid] = 0;
	IsPMEnabled{ playerid } = 1;
	gIsLogged{ playerid } = 0;
	for(new E_PLAYER_DATA:e; e < E_PLAYER_DATA; ++e)
		pInfo[playerid][e] = 0;
	///////////////////
	new query[128];
	GetPlayerName(playerid, Name[playerid], sizeof(Name));
	GetPlayerIp(playerid, IP[playerid], sizeof(IP));
	mysql_format(mysql, query, sizeof(query), "SELECT `Password`, `IP` FROM `players` WHERE `Username`='%e' LIMIT 1", Name[playerid]);
	mysql_tquery(mysql, query, "OnPlayerAccountCheck", "i", playerid);
	SetTimerEx("Anticheat", 1000, true, "u", playerid);
	CreateUsefulTextdraws(playerid);
	ShowServerIntroTextdraws(playerid);
	SetSpawnInfo( playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 26, 36, 28, 150, 0, 0 );
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	SaveAccounts(playerid);
	if(IsBeingSpeced[playerid] == 1)
	{
		foreach(Player,i)
		{
			if(spectatorid[i] == playerid)
			{
				TogglePlayerSpectating(i,false);
			}
		}
	}
	return 1;
}


public OnPlayerSpawn(playerid)
{
	if(IsSpecing[playerid] == 1)
	{
		SetPlayerPos(playerid,SpecX[playerid],SpecY[playerid],SpecZ[playerid]);// Remember earlier we stored the positions in these variables, now we're gonna get them from the variables.
		SetPlayerInterior(playerid,Inter[playerid]);//Setting the player's interior to when they typed '/spec'
		SetPlayerVirtualWorld(playerid,vWorld[playerid]);//Setting the player's virtual world to when they typed '/spec'
		IsSpecing[playerid] = 0;//Just saying you're free to use '/spec' again YAY :D
		IsBeingSpeced[spectatorid[playerid]] = 0;//Just saying that the player who was being spectated, is not free from your stalking >:D
	}
	gIsLogged{ playerid } = 1;
	HideServerIntroTextdraws(playerid);
	TextDrawShowForPlayer(playerid, randommsg);
	if( pInfo[playerid][Team] >= 1 )
	{
		switch( pInfo[playerid][Team] )
		{
			case 1:
			{
				SendClientMessage( playerid, COLOR_BLUE, "You have spawned as a cop. You have an anti-spawn protection for ten seconds!");
				GameTextForPlayer( playerid, "~b~Cops", 3000, 3 );
				new Random = random(sizeof(RandomArmySpawn));
				SetPlayerPos( playerid, RandomArmySpawn[Random][0], RandomArmySpawn[Random][1], RandomArmySpawn[Random][2]);
				SetPlayerFacingAngle( playerid, RandomArmySpawn[Random][3]);
				SkinSelectionPerTeam(playerid);
				SetPlayerColor(playerid, COLOR_BLUE);
			}
			case 2:
			{
				SendClientMessage( playerid, COLOR_RED, "You have spawned as a terrorist. You have an anti-spawn protection for ten seconds!");
				GameTextForPlayer( playerid, "~b~Terrorists", 3000, 3 );
				new Random = random(sizeof(RandomTerroristSpawn));
				SetPlayerPos( playerid, RandomTerroristSpawn[Random][0], RandomTerroristSpawn[Random][1], RandomTerroristSpawn[Random][2]);
				SetPlayerFacingAngle( playerid, RandomTerroristSpawn[Random][3]);
				SkinSelectionPerTeam(playerid);
				SetPlayerColor(playerid, COLOR_RED);
			}
		}
	}
	else if( pInfo[playerid][Team] <= 0)
	{
		ShowPlayerDialog(playerid, D_TEAM, DIALOG_STYLE_MSGBOX, "Team Selection", "Please choose your respective team.\nYou can always change your respective team with $10.", "Cops", "Terrorists");
	}
	SetTimerEx("AntiSpawnTimer", 10000, false, "u", playerid);
	SetPlayerHealthEx(playerid, 999999999);
	gAntiSpawnProtected{ playerid } = true;
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	gHealth[playerid] = 0;
	if(IsBeingSpeced[playerid] == 1)
	{
		foreach(Player,i)
		{
			if(spectatorid[i] == playerid)
			{
				TogglePlayerSpectating(i,false);
			}
		}
	}
	return 1;
}

//Commands
//Level 7:
CMD:setadmin(playerid, params[])
{
	if(pInfo[playerid][Admin] >= 7)
	{
		new msg[180], target, level;
		if(!sscanf(params,"ui", target, level))
		{
			if(IsPlayerConnected(target))
			{
				if(level > 0)
				{
					format(msg, sizeof(msg), "Administrator %s promoted %s to admin level %d! Congratulations!", Name[playerid], Name[target], level);
					SendClientMessageToAll(COLOR_GREEN, msg);
					pInfo[playerid][Admin] = level;
					SendClientMessage(target, COLOR_GREEN, "* Use /ah for your new commands' list!");
				}
				else SendClientMessage(playerid, COLOR_RED, "Invalid Administrator Level Specified.");
			}
			else SendClientMessage(playerid, COLOR_RED, "Target unavailible.");
		}
		else SendClientMessage(playerid, COLOR_ORANGE, "SYNTAX: /setadmin [playerid] [level]"); SendClientMessage(playerid, COLOR_ORANGE, "Admin levels: 1 - Helper | 2 - Moderator | \
		3 - Trial Admin | 4 - Basic Admin | 5 - General Admin | 6 - Lead Admin | 7 - Executive");
	}
	else SendClientMessage(playerid, COLOR_RED, "You are not authourized to use this command!");
	return 1;
}

//Level 2:
CMD:a(playerid, params[])
{
	if(pInfo[playerid][Admin] >= 2)
	{
		new msg[128];
		if(!sscanf(params, "s[128]", msg))
		{
			format(msg, sizeof(msg), "[A] %s: %s", Name[playerid], msg);
			SendClientMessageToAdmins(COLOR_PINK, msg);
		}
		else SCM(playerid, COLOR_RED, "SYNTAX: /a [text]");
	}
	else SCM(playerid, COLOR_RED, "You are not authourized to use this command!");
	return 1;
}

CMD:spec(playerid, params[])
{
	new id;
	if(pInfo[playerid][Admin] <= 1)return SCM(playerid, COLOR_RED, "Invalid permissions!");
	if(sscanf(params,"u", id))return SendClientMessage(playerid, COLOR_RED, "Usage: /spec [id]");
	if(id == playerid)return SendClientMessage(playerid,COLOR_RED,"You cannot spec yourself.");
	if(id == INVALID_PLAYER_ID)return SendClientMessage(playerid, COLOR_RED, "Player not found!");
	if(IsSpecing[playerid] == 1)return SendClientMessage(playerid,COLOR_RED,"You are already specing someone.");
	GetPlayerPos(playerid,SpecX[playerid],SpecY[playerid],SpecZ[playerid]);
	Inter[playerid] = GetPlayerInterior(playerid);
	vWorld[playerid] = GetPlayerVirtualWorld(playerid);
	TogglePlayerSpectating(playerid, true);
	if(IsPlayerInAnyVehicle(id))
	{
		if(GetPlayerInterior(id) > 0)
		{
			SetPlayerInterior(playerid,GetPlayerInterior(id));
		}
		if(GetPlayerVirtualWorld(id) > 0)
		{
			SetPlayerVirtualWorld(playerid,GetPlayerVirtualWorld(id));
		}
		PlayerSpectateVehicle(playerid,GetPlayerVehicleID(id));
	}
	else
	{
		if(GetPlayerInterior(id) > 0)
		{
			SetPlayerInterior(playerid,GetPlayerInterior(id));
		}
		if(GetPlayerVirtualWorld(id) > 0)
		{
			SetPlayerVirtualWorld(playerid,GetPlayerVirtualWorld(id));
		}
		PlayerSpectatePlayer(playerid,id);
	}
	new String[128];
	format(String, sizeof(String),"[SPEC]:You have started to spectate %s.",Name[id]);
	SendClientMessage(playerid,0x0080C0FF,String);
	IsSpecing[playerid] = 1;
	IsBeingSpeced[id] = 1;
	spectatorid[playerid] = id;
	return 1;
}

CMD:specoff(playerid, params[])
{
	if(pInfo[playerid][Admin] <= 1)return SCM(playerid, COLOR_RED, "Insufficient permissions!");
	if(IsSpecing[playerid] == 0)return SendClientMessage(playerid,COLOR_ORANGE,"You are not spectating anyone.");
	TogglePlayerSpectating(playerid, 0);
	return 1;
}

//Level 1:
CMD:respond(playerid, params[])
{
	if(pInfo[playerid][Admin] == 1)
	{
		new id, text[64];
		if(!sscanf(params, "us[128]", id, text))
		{
			if(IsPlayerConnected(id))
			{
				new msg[128];
				format(msg, sizeof(msg), "[Admin %s]: %s", Name[playerid], text);
				SendClientMessage(id, COLOR_YELLOW, msg);
				SendClientMessage(playerid, COLOR_YELLOW, "Your reply has been sent.");
			}
			else SCM(playerid, COLOR_RED, "Invalid target specified.");
		}
		else SCM(playerid, COLOR_RED, "SYNTAX: /respond [id] [text]");
	}
	else SCM(playerid, COLOR_RED, "Insufficient permissions!");
	return 1;
}

CMD:ah(playerid, params[])
{
	new str[1024];
	if(pInfo[playerid][Admin] >= 1)
	{
		strcat(str, "/a                 - Admin Chat\n", sizeof(str));
		strcat(str, "/respond   - Responds a player's question.\n", sizeof(str));
	}
	if(pInfo[playerid][Admin] >= 2)
	{
		strcat(str, "/spec(off)      - Spectates a player.\n", sizeof(str));
	}
	if(pInfo[playerid][Admin] >= 3)
	{
	}
	if(pInfo[playerid][Admin] >= 4)
	{
	}
	if(pInfo[playerid][Admin] >= 5)
	{
	}
	if(pInfo[playerid][Admin] >= 6)
	{
	}
	if(pInfo[playerid][Admin] >= 7)
	{
		strcat(str, "/setadmin - \n", sizeof(str));
	}
	ShowPlayerDialog(playerid, D_ACMDLIST, DIALOG_STYLE_MSGBOX, "Admin commands:", str, "Done", "");
	return 1;
}

//Players"

CMD:cmds(playerid, params[])
{
	return cmd_help(playerid, params);
}

CMD:help(playerid, params[])
{
	SCM(playerid, -1, "[COMMANDS]: /help - /ask - /report - /pm - /togpm");
	return 1;
}

CMD:ask(playerid, params[])
{
	new text[64];
	if(!sscanf(params, "s[64]", text))
	{
		foreach(Player,i)
		{
			if(pInfo[playerid][Admin] >= 1)
			{
				new str[128];
				format(str, sizeof(str), "[ASK]: %s (%d): %s", Name[playerid], playerid, text);
				SendClientMessage(i, COLOR_LIGHTBLUE, str);
				SendClientMessage(i, COLOR_LIGHTBLUE, "[ASK]: Use /respond to respond to the player.");
				SendClientMessage(playerid, COLOR_LIGHTBLUE, "You request has been send to online administrators.");
			}
		}
	}
	else SCM(playerid, COLOR_RED, "SYNTAX: /ask [text]");
	return 1;
}

CMD:pm(playerid, params[])
{
	new id, text[64];
	if(!sscanf(params, "us[64]", id, text))
	{
		if(IsPlayerConnected(id))
		{
			if(IsPMEnabled{ id } == 1)
			{
				new msg[128];
				format(msg, sizeof(msg), "[PM from %s (%d)]: %s", Name[playerid], playerid, text);
				SCM(id, COLOR_YELLOW, msg);
				format(msg, sizeof(msg), "[PM to %s (%d)]: %s", Name[id], id, text);
				SCM(playerid, COLOR_YELLOW, msg);
			}
			else SCM(playerid, COLOR_RED, "!- That player has his PM's disabled.");
		}
		else SCM(playerid, COLOR_RED, "!- Specified target is not connected.");
	}
	else SCM(playerid, COLOR_RED, "SYNTAX: /pm [id] [text]");
	return 1;
}

CMD:togpm(playerid, params[])
{
	if(IsPMEnabled{ playerid } == 0)
	{
		IsPMEnabled{playerid} = 1;
		SCM(playerid, COLOR_YELLOW, "!- PMs enabled. Use /togpm again to disable PMs.");
	}
	else if(IsPMEnabled{ playerid } == 1)
	{
		IsPMEnabled{playerid} = 0;
		SCM(playerid, COLOR_YELLOW, "!- PMs disabled. Use /togpm again to enable PMs.");
	}
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	foreach(Player,i)
	{
		if(GetPlayerVehicleID(i) == vehicleid && GetPlayerVehicleSeat(i) == 1 && GetPlayerTeamEx(i) == GetPlayerTeamEx(playerid))
		{
			SendClientMessage(playerid, COLOR_RED, "!- Stop car jacking your team-mate!");
			ClearAnimations(playerid);
			return 0;
		}
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)// If the player's state changes to a vehicle state we'll have to spec the vehicle.
	{
		if(IsBeingSpeced[playerid] == 1)//If the player being spectated, enters a vehicle, then let the spectator spectate the vehicle.
		{
			foreach(Player,i)
			{
				if(spectatorid[i] == playerid)
				{
					PlayerSpectateVehicle(i, GetPlayerVehicleID(playerid));// Letting the spectator, spectate the vehicle of the player being spectated (I hope you understand this xD)
				}
			}
		}
	}
	if(newstate == PLAYER_STATE_ONFOOT)
	{
		if(IsBeingSpeced[playerid] == 1)//If the player being spectated, exists a vehicle, then let the spectator spectate the player.
		{
			foreach(Player,i)
			{
				if(spectatorid[i] == playerid)
				{
					PlayerSpectatePlayer(i, playerid);// Letting the spectator, spectate the player who exited the vehicle.
				}
			}
		}
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	if(IsBeingSpeced[playerid] == 1)//If the player being spectated, changes an interior, then update the interior and virtualword for the spectator.
	{
		foreach(Player,i)
		{
			if(spectatorid[i] == playerid)
			{
				SetPlayerInterior(i,GetPlayerInterior(playerid));
				SetPlayerVirtualWorld(i,GetPlayerVirtualWorld(playerid));
			}
		}
	}
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch( dialogid )
	{
		case D_LOG:
		{
			if(!response) return Kick(playerid);
			new hpass[129], query[300];
			WP_Hash( hpass, 129, inputtext );
			if(!strcmp(hpass, pInfo[playerid][Password]))
			{
				mysql_format(mysql, query, sizeof(query), "SELECT * FROM `players` WHERE `Username` = '%e' LIMIT 1", Name[playerid]);
				mysql_tquery(mysql, query, "OnPlayerAccountLoad", "i", playerid);
			}
			else
			{
				gLoginAttempts[playerid] ++;
				ShowPlayerDialog(playerid, D_LOG, DIALOG_STYLE_PASSWORD, "Welcome back to CVT!", "ERROR: Incorrect password! \nPlease enter your password to login!", "Login", "Quit");
			}
			if(gLoginAttempts[playerid] >= 3)
			{
				SendClientMessage(playerid, COLOR_RED, "[ERROR]: You have reached the max login limit. You have been kicked.");
				KickEx(playerid);
			}
		}
		case D_REG:
		{
			if(!response) return Kick(playerid);
			if(strlen(inputtext) < 6) return ShowPlayerDialog(playerid, D_REG, DIALOG_STYLE_PASSWORD, "Welcome to CVT!", "{FF0000}Error: You have entered an invalid password.\n{FFFFFF}Your password must be at least 6 characters long!", "Register", "Quit");
			new query[300];
			WP_Hash(pInfo[playerid][Password], 129, inputtext);
			mysql_format(mysql, query, sizeof(query), "INSERT INTO `players` (`Username`, `Password`, `IP`, `Admin`, `VIP`, `Money`, `Team`) VALUES ('%e', '%s', '%s', 0, 0, 0, 0)", Name[playerid], pInfo[playerid][Password], IP[playerid]);
			mysql_tquery(mysql, query, "OnPlayerAccountRegister", "i", playerid);
			ShowPlayerDialog(playerid, D_TEAM, DIALOG_STYLE_MSGBOX,  "Team Selection", "Please choose your respective team, after this you will spawn. \nNOTE: You will not be able to change your team again, unless \nyou buy a 'Team Change' pass for $10.", \
			"Cops", "Terrorists");
		}
		case D_TEAM:
		{
			if(!response) //If choosen 'Terrorists'
			{
				pInfo[playerid][Team] = 2;
				SendClientMessage( playerid, COLOR_RED, "You have spawned as a terrorist. You have an anti-spawn protection for ten seconds!");
				GameTextForPlayer( playerid, "~b~Terrorists", 3000, 3 );
				new Random = random(sizeof(RandomTerroristSpawn));
				SetPlayerPos( playerid, RandomTerroristSpawn[Random][0], RandomTerroristSpawn[Random][1], RandomTerroristSpawn[Random][2]);
				SetPlayerFacingAngle( playerid, RandomTerroristSpawn[Random][3]);
				SetPlayerColor(playerid, COLOR_RED);
			}
			if(response) //If choosen 'Cops'
			{
				pInfo[playerid][Team] = 1;
				SendClientMessage( playerid, COLOR_BLUE, "You have spawned as a cop. You have an anti-spawn protection for ten seconds!");
				GameTextForPlayer( playerid, "~b~Cops", 3000, 3 );
				new Random = random(sizeof(RandomArmySpawn));
				SetPlayerPos( playerid, RandomArmySpawn[Random][0], RandomArmySpawn[Random][1], RandomArmySpawn[Random][2]);
				SetPlayerFacingAngle( playerid, RandomArmySpawn[Random][3]);
				SetPlayerColor(playerid, COLOR_BLUE);
			}
			SkinSelectionPerTeam(playerid);
		}
	}
	
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	if(issuerid != INVALID_PLAYER_ID)
	{
		if(GetPlayerTeamEx(playerid) == GetPlayerTeamEx(issuerid))
		{
			gHealth[playerid] -= amount;
			SendClientMessage(issuerid, COLOR_RED, "!- Stop teamkilling! You have been given the same damage recieved by the player!");
			return 0;
		}
	}
	gHealth[playerid] -= amount;
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
	if(playerid != INVALID_PLAYER_ID)
	{
		if(gAntiSpawnProtected { damagedid } == true)
		{
			SendClientMessage(playerid, COLOR_RED, "[MSG]: The player you are trying to kill is on anti-spawn kill protection.");
			return 0;
		}
	}
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(hittype == BULLET_HIT_TYPE_VEHICLE)
	{
		foreach(Player,i)
		{
			if(GetPlayerVehicleID(i) == hitid && GetPlayerVehicleSeat(i) == 1 && GetPlayerTeamEx(i) == GetPlayerTeamEx(playerid))
			{
				SendClientMessage(playerid, COLOR_RED, "!- Stop shooting your team-mate's vehicle!");
				return 0;
			}
		}
	}
	return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(gIsLogged{ playerid } == 0)
	{
		SendClientMessage(playerid, COLOR_RED, "You are not logged in!");
		return 0;
	}
	if(!success)
	{
		new msg[200];
		format(msg, sizeof(msg), "!- The command [%s] was not found on our database. Try using /cmds.", cmdtext);
		SendClientMessage(playerid, COLOR_RED, msg);
	}
	return 1;
}

/* Custom Functions */
public OnPlayerAccountCheck(playerid)
{
	new rows, fields;
	new dialogstring[300];
	cache_get_data( rows, fields, mysql );
	if( rows )
	{
		cache_get_field_content(0, "Password", pInfo[playerid][Password], mysql, 129);
		pInfo[playerid][ID] = cache_get_field_content_int(0, "ID");
		format( dialogstring, sizeof( dialogstring ), "Welcome back to "SERVER_NAME", {00FF00}%s!\nPlease enter your password below to login.", Name[playerid]);
		ShowPlayerDialog(playerid, D_LOG, DIALOG_STYLE_PASSWORD, "Welcome back to CVT!", dialogstring, "Login", "Quit");
	}
	else
	{
		format( dialogstring, sizeof( dialogstring ), "Welcome to "SERVER_NAME", {00FF00}%s!\nPlease enter a password below to register.", Name[playerid]);
		ShowPlayerDialog(playerid, D_REG, DIALOG_STYLE_PASSWORD, "Welcome to CVT!", dialogstring, "Register", "Quit");
	}
	return 1;
}

public OnPlayerAccountRegister(playerid)
{
	pInfo[playerid][ID] = cache_insert_id();
	gIsNewHere { playerid } = true;
	SpawnPlayer(playerid);
	return 1;
}

public OnPlayerAccountLoad(playerid)
{
	pInfo[playerid][Admin] = cache_get_field_content_int(0, "Admin");
	pInfo[playerid][VIP] = cache_get_field_content_int(0, "VIP");
	pInfo[playerid][Money] = cache_get_field_content_int(0, "Money");
	pInfo[playerid][Team] = cache_get_field_content_int(0, "Team");
	
	GivePlayerMoney(playerid, pInfo[playerid][Money]);
	SendClientMessage(playerid, -1, "Successfully logged in!");
	return 1;
}

stock KickEx(playerid)
{
	SetTimerEx("KickPlayer", 1000, false, "i", playerid);
	return 1;
}

public KickPlayer(playerid)
{
	Kick(playerid);
	return 1;
}

public SaveAccountsPerMinute(playerid)
{
	SaveAccounts(playerid);
	return 1;
}

SaveAccounts(playerid)
{
	new query[300];
	mysql_format(mysql, query, sizeof(query), "UPDATE `players` SET `Admin`='%d', `Money`='%d', `VIP`='%d', `Team`='%d' WHERE `ID`='%d'", \
	pInfo[playerid][Admin],
	pInfo[playerid][Money],
	pInfo[playerid][VIP],
	pInfo[playerid][Team],
	pInfo[playerid][ID]);
	mysql_tquery(mysql, query, "", "");
	return 1;
}

stock SkinSelectionPerTeam(playerid)
{
	if(pInfo[playerid][Team] == 1) //Is a cop
	{
		new SkinArray[9];
		SkinArray[0] = 287;
		SkinArray[1] = 280;
		SkinArray[2] = 282;
		SkinArray[3] = 285;
		SkinArray[4] = 284;
		SkinArray[5] = 267;
		SkinArray[6] = 266;
		SkinArray[7] = 265;
		ShowModelSelectionMenuEx(playerid, SkinArray, 8, "Select Skin", CUSTOM_SKIN_ARMY_MENU, 16.0, 0.0, -55.0, 1, 0x464646FF,  0x88888899 , 0xFFFF00AA);
		return 1;
	}
	else if(pInfo[playerid][Team] == 2) //Is a terrorist
	{
		new SkinArray[9];
		SkinArray[0] = 254;
		SkinArray[1] = 248;
		SkinArray[2] = 241;
		SkinArray[3] = 217;
		SkinArray[4] = 179;
		SkinArray[5] = 176;
		ShowModelSelectionMenuEx(playerid, SkinArray, 6, "Select Skin", CUSTOM_SKIN_TERROR_MENU, 16.0, 0.0, -55.0, 1, 0x464646FF, 0x88888899 , 0xFFFF00AA);
		return 1;
	}
	return 1;
}

public AntiSpawnTimer(playerid)
{
	SetPlayerHealthEx(playerid, 80);
	gAntiSpawnProtected{ playerid } = false;
	SendClientMessage(playerid, COLOR_RED, "* Your anti spawn-kill protection has been ended.");
	return 1;
}

public Anticheat(playerid)
{
	if(GetPlayerHealthEx(playerid) != gHealth[playerid])
	{
		SetPlayerHealthEx(playerid, gHealth[playerid]);
	}
	if(GetPlayerArmourEx(playerid) != gArmour[playerid])
	{
		SetPlayerHealthEx(playerid, gArmour[playerid]);
	}
	return 1;
}

public OnPlayerModelSelectionEx(playerid, response, extraid, modelid)
{
	if(extraid == CUSTOM_SKIN_ARMY_MENU || CUSTOM_SKIN_TERROR_MENU)
	{
		if(response)
		{
			SendClientMessage(playerid, COLOR_RED, "Skin selected. You are ready for the war!");
			SetPlayerSkin(playerid, modelid);
			GivePlayerWeapon(playerid, WEAPON_DEAGLE, 150);
			GivePlayerWeapon(playerid, WEAPON_SHOTGUN, random(150));
			GivePlayerWeapon(playerid, WEAPON_AK47, random(500));
			GivePlayerWeapon(playerid, WEAPON_MP5, random(500));
			GivePlayerWeapon(playerid, WEAPON_RIFLE, random(200));
			SendClientMessage(playerid, COLOR_ORANGE, "-> You have recieved random amount of ammo for each of your weapons.");
		}
		else SkinSelectionPerTeam(playerid);
	}
	return 1;
}

CreateUsefulTextdraws(playerid)
{
	//CVTIntro_TD
	CVTIntro_TD[playerid][0] = CreatePlayerTextDraw(playerid, 675.000000, 460.666625, "box");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][0], 0.000000, -31.437500);
	PlayerTextDrawTextSize(playerid, CVTIntro_TD[playerid][0], -43.750000, 0.000000);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][0], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][0], -1);
	PlayerTextDrawUseBox(playerid, CVTIntro_TD[playerid][0], 1);
	PlayerTextDrawBoxColor(playerid, CVTIntro_TD[playerid][0], 153);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][0], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][0], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][0], 0);
	
	CVTIntro_TD[playerid][1] = CreatePlayerTextDraw(playerid, 95.625000, 54.666683, "Cops_vs~n~________Terrorists");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][1], 0.658125, 3.291667);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][1], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][1], 255);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][1], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][1], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][1], 3);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][1], 0);
	
	CVTIntro_TD[playerid][2] = CreatePlayerTextDraw(playerid, 281.250000, 155.000030, "A_TDM_project_brought_to_you_by~n~______________________________________");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][2], 0.336249, 1.162499);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][2], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][2], 1499027967);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][2], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][2], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][2], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][2], 2);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][2], 0);
	
	CVTIntro_TD[playerid][3] = CreatePlayerTextDraw(playerid, 438.125000, 165.500000, "Kapersky");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][3], 0.392499, 1.244166);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][3], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][3], -2139094785);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][3], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][3], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][3], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][3], 2);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][3], 0);
	
	CVTIntro_TD[playerid][4] = CreatePlayerTextDraw(playerid, 2.500000, 179.500076, "box");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][4], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, CVTIntro_TD[playerid][4], 648.750000, 0.000000);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][4], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][4], -1);
	PlayerTextDrawUseBox(playerid, CVTIntro_TD[playerid][4], 1);
	PlayerTextDrawBoxColor(playerid, CVTIntro_TD[playerid][4], -2139062017);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][4], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][4], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][4], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][4], 1);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][4], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][4], 0);
	
	CVTIntro_TD[playerid][5] = CreatePlayerTextDraw(playerid, 27.500000, 194.083419, "");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][5], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, CVTIntro_TD[playerid][5], 90.000000, 90.000000);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][5], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][5], -1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][5], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][5], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][5], 1);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][5], 5);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][5], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][5], 0);
	PlayerTextDrawSetPreviewModel(playerid, CVTIntro_TD[playerid][5], 348);
	PlayerTextDrawSetPreviewRot(playerid, CVTIntro_TD[playerid][5], 0.000000, -45.000000, 1.100000, 1.500000);
	
	CVTIntro_TD[playerid][6] = CreatePlayerTextDraw(playerid, 40.000000, 205.166702, "box");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][6], 0.000000, 22.312500);
	PlayerTextDrawTextSize(playerid, CVTIntro_TD[playerid][6], 296.250000, 0.000000);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][6], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][6], -1);
	PlayerTextDrawUseBox(playerid, CVTIntro_TD[playerid][6], 1);
	PlayerTextDrawBoxColor(playerid, CVTIntro_TD[playerid][6], 96);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][6], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][6], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][6], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][6], 1);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][6], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][6], 0);
	
	CVTIntro_TD[playerid][7] = CreatePlayerTextDraw(playerid, 99.375000, 112.999992, "'Where_the_battle_begins'");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][7], 0.499374, 1.279167);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][7], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][7], -2139062017);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][7], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][7], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][7], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][7], 0);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][7], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][7], 0);
	
	CVTIntro_TD[playerid][8] = CreatePlayerTextDraw(playerid, 92.500000, 205.166717, "Cops vs Terrorist (also known as CvT) is a server based ~n~ over war. ~n~This server is based on the wars and battles between~n~to factions; \
	Cops and Terrorist. Your duty is to serve ~n~your team the best and prevent~n~it to be exploited by your rivals. You \
	must prove your~n~ abilities before you are handed over~n~the rank of Supreme. You may also find roleplay...");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][8], 0.214999, 1.296666);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][8], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][8], -1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][8], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][8], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][8], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][8], 1);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][8], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][8], 0);
	
	CVTIntro_TD[playerid][9] = CreatePlayerTextDraw(playerid, 92.500000, 368.499969, "________________________or_even_RP_events_going_on_here_'n~n~there._So_what_are_you_waiting_for?_Get_your_gear_up_and_~n~get_ready_for_the_ultimate_war!");
	PlayerTextDrawLetterSize(playerid, CVTIntro_TD[playerid][9], 0.214999, 1.296666);
	PlayerTextDrawAlignment(playerid, CVTIntro_TD[playerid][9], 1);
	PlayerTextDrawColor(playerid, CVTIntro_TD[playerid][9], -1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][9], 0);
	PlayerTextDrawSetOutline(playerid, CVTIntro_TD[playerid][9], 0);
	PlayerTextDrawBackgroundColor(playerid, CVTIntro_TD[playerid][9], 255);
	PlayerTextDrawFont(playerid, CVTIntro_TD[playerid][9], 1);
	PlayerTextDrawSetProportional(playerid, CVTIntro_TD[playerid][9], 1);
	PlayerTextDrawSetShadow(playerid, CVTIntro_TD[playerid][9], 0);
	return 1;
}

ShowServerIntroTextdraws(playerid)
{
	for(new i = 0; i < 10; i++)
	{
		PlayerTextDrawShow(playerid, CVTIntro_TD[playerid][i]);
	}
	return 1;
}

HideServerIntroTextdraws(playerid)
{
	for(new i = 0; i < 10; i++)
	{
		PlayerTextDrawHide(playerid, CVTIntro_TD[playerid][i]);
	}
	return 1;
}

public RandomMessage()
{
	TextDrawSetString(randommsg, RandomMessages[random(sizeof(RandomMessages))]); // We need this to make the timer working
	return 1;
}

stock GetPlayerTeamEx(playerid)
{
	return pInfo[playerid][Team];
}

stock SendClientMessageForTeam(team, color, message[])
{
	foreach(Player,i)
	{
		if(GetPlayerTeamEx(i) == team)
		{
			SendClientMessage(i, COLOR_YELLOW, message);
		}
	}
	return 1;
}

stock SetPlayerHealthEx(playerid, amount)
{
	gHealth[playerid] = amount;
	return 1;
}

stock GetPlayerHealthEx(playerid)
{
	new Float:hp;
	return GetPlayerHealth(playerid, hp);
}

stock SetPlayerArmourEx(playerid, amount)
{
	gArmour[playerid] = amount;
	return 1;
}

stock GetPlayerArmourEx(playerid)
{
	new Float:armour;
	return GetPlayerArmour(playerid, armour);
}

stock SendClientMessageToAdmins(color, message[])
{
	foreach(Player,i)
	{
		if(pInfo[i][Admin] >= 2)
		{
			SendClientMessage(i, color, message);
		}
	}
	return 1;
}

stock AdminRank(playerid)
{
	new admin[40];
	switch(pInfo[playerid][Admin])
	{
		case 1: format(admin,sizeof(admin),"Helper");
		case 2: format(admin,sizeof(admin),"Moderator");
		case 3: format(admin,sizeof(admin),"Trial Admin");
		case 4: format(admin,sizeof(admin),"Basic Admin");
		case 5: format(admin,sizeof(admin),"General Admin");
		case 6: format(admin,sizeof(admin),"Lead Admin");
		case 7: format(admin,sizeof(admin),"Executive Director");
	}
	return admin;
	
}
