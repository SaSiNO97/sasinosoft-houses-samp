/*
									 ___                                                 ___  _   
									(  _`\               _                             /'___)( )_ 
									| (_(_)   _ _   ___ (_)  ___     _     ___    _   | (__  | ,_)
									`\__ \  /'_` )/',__)| |/' _ `\ /'_`\ /',__) /'_`\ | ,__) | |  
									( )_) |( (_| |\__, \| || ( ) |( (_) )\__, \( (_) )| |    | |_ 
									`\____)`\__,_)(____/(_)(_) (_)`\___/'(____/`\___/'(_)    `\__)
									
									( ) ( )                                     /'__`\    /' _`\ 
									| |_| |   _    _   _   ___    __    ___    (_)  ) )   | ( ) |
									|  _  | /'_`\ ( ) ( )/',__) /'__`\/',__)      /' /    | | | |
									| | | |( (_) )| (_) |\__, \(  ___/\__, \    /' /( ) _ | (_) |
									(_) (_)`\___/'`\___/'(____/`\____)(____/   (_____/'(_)`\___/'
																								  
*/
// Sasinosoft Houses 2.0 - By Sasino97 - December 2012 - January 2013
// Totally rewritten from scratch
// This filterscript only works for SA-MP Server 0.3e or higher

/*
															PLACE THIS IN YOUR GAMEMODE:
	
			
#define BOX_STYLE_CMD "{33AA33}COMMAND"
#define BOX_STYLE_ERROR "{FF0000}ERROR"
#define BOX_STYLE_WARNING "{FF8000}WARNING"

stock CreateHouse(Float:eX, Float:eY, Float:eZ, Float:iX, Float:iY, Float:iZ, price, interior, exterior = 0, virtualWorld = 1)
{
	return CallRemoteFunction("FS_CreateHouse", "ffffffiiii", eX, eY, eZ, iX, iY, iZ, price, interior, exterior, virtualWorld);
}
stock CreateBusiness(title[MAX_PLAYER_NAME], earning, Float:eX, Float:eY, Float:eZ, Float:iX, Float:iY, Float:iZ, price, interior, exterior = 0, virtualWorld = 1, iconmarker = 37, itemlist[1024] = "_")
{
	return CallRemoteFunction("FS_CreateBusiness", "siffffffiiiiis", title, earning, eX, eY, eZ, iX, iY, iZ, price, interior, exterior, virtualWorld, iconmarker, itemlist);
}
stock GiveBusinessMoney(shopid, money) { return CallRemoteFunction("FS_GiveBusinessMoney", "ii", shopid, money); }
stock GetBusinessMoney(shopid) { return CallRemoteFunction("FS_GetBusinessMoney", "i", shopid); }
stock GiveBusinessGoods(shopid, goods) { return CallRemoteFunction("FS_GiveBusinessGoods", "ii", shopid, goods); }
stock GetBusinessGoods(shopid) { return CallRemoteFunction("FS_GetBusinessGoods", "i", shopid); }
stock MsgBox(playerid, style[], text[]) { return CallRemoteFunction("FS_MsgBox", "iss", playerid, style, text); }

forward OnPlayerBuyItem(playerid, shopid, itemid);
public OnPlayerBuyItem(playerid, shopid, itemid)
{
	// Put here code
	return 1;
}

*/

#define FILTERSCRIPT

#include <a_samp>
#include <SII> // NOTICE: Make sure that INI_MAX_LINES in SII.inc is at least 512 (By default it's 256) otherwise not all of the furniture will be saved. If you don't want to, then decrease the furniture limit to 30.
#include <streamer>

#if !defined EditObject
#error "This filterscript only works for SA-MP Server 0.3e or higher. Please download the lastest SA-MP Server package."
#endif

// Main Settings
// Warning: changing any of these and then recompling the code could result in bugs if there are already created houses or businesses. Change them before using it in your game.
#define MAX_HOUSES 50 // Set to whatever you want (default = 50). A big value could cause long looping times.
#define MAX_SHOPS 50 // Set to whatever you want (default = 50). A big value could cause long looping times.
#define MAX_TITLE 20 // The max length of the title of a shop
#define MAX_TITLE_STR "20" // The same as above, but make it as string.
#define MAX_FURNITURE 50 // The max number of furniture a house can have. If you make this bigger remember to edit MAX_INI_LINES into SII
#define VISIT_TIME 60000 // The time a player has to visit a house.
#define HOUSE_FILE "Sasinosoft/Houses/House%d.ini" //Set to whatever you want (default = "Sasinosoft/Houses/House%d.ini")
#define SHOP_FILE "Sasinosoft/Shops/Shop%d.ini" //Set to whatever you want (default = "Sasinosoft/Houses/House%d.ini")
#define SAVED_HOUSES_FILE "Sasinosoft/Houses/SavedHouses.txt" // The file where the houses saved with /savehouse are written
#define SAVED_SHOPS_FILE "Sasinosoft/Shops/SavedShops.txt" // The file where the stores/shops saved with /savestore are written
#define GOOD_PRICE 100 // 1 good = 1 player can buy 1 item (default = 100$ per good)
#define SELL_MULTIPLIER 0.8 // When a player sells a house, a furniture or a shop he will receive the initial price of the shop multiplied by this value
#define INVALID_OWNER "LOK18F75J" // Never change this. If you set this to a common nickname and that player connects I don't know what will happen. If you change this while there are unbought houses they will result as bought.
#define INVALID_HOUSE_ID -255 // Use only a negative value
#define KEY KEY_LOOK_BEHIND // The key to press to open dialogs
#define KEY_STRING "\"MMB\"" // The same, but in a string
#define NO_ITEMS_STRING "{FF0000}Nothing to buy" // String displayed in a shop without nothing to buy
#define MAP_ICONS 1 // If defined to 1, on the map will be created icons.
#define CONSOLE 1 // if defined to 1, the important things are printed to the console (and then to server_log.txt)
#define ShowNoMoneyMessage(%0) FS_MsgBox(%0, BOX_STYLE_ERROR, "You don't have enough money.") // A useful macro


// Furniture
#define FURNITURE_NUMBER 55
#define INVALID_FURNITURE_ID 0
stock FurnitureInfo[][] =
{// {[0]object, [1]price, [2]name}
	{0, 0, "INVALID_FURNITURE_ID"}, // 0
	{2165, 1500, "Desk and PC"}, // 1
	{2356, 100, "Desk chair"}, // 2
	{2028, 350, "CJD500 console"}, // 3
	{2779, 600, "Arcade machine"}, // 4
	{2030, 750, "Marble table"}, // 5
	{2086, 1000, "Glass table"}, // 6
	{2112, 300, "Wood table"}, // 7
	{2115, 600, "Big wood table"}, // 8
	{2079, 80, "Chair A"}, // 9
	{2120, 150, "Chair B"}, // 10
	{2121, 50, "Red folding chair"}, // 11
	{2096, 100, "Rocking chair"}, // 12
	{2069, 100, "Lamp"}, // 13
	{2103, 800, "Radio"}, // 14
	{2132, 200, "White Sink"}, // 15
	{2141, 900, "White Fridge"}, // 16
	{2149, 600, "Microwave oven"}, // 17
	{2161, 500, "Book shelf"}, // 18
	{2167, 750, "Wardrobe"}, // 19
	{2202, 1500, "Photocopier"}, // 20
	{2313, 900, "TV Shelf + DVD Player"}, // 21
	{2312, 1200, "Television A"}, // 22
	{2316, 1200, "Television B"}, // 23
	{2322, 1200, "Television C"}, // 24
	{2298, 1000, "Blue Bed"}, // 25
	{2299, 1000, "Brown Bed"}, // 26
	{2300, 1000, "Yellow Bed"}, // 27
	{2301, 1000, "Green and Blue Bed"}, // 28
	{2526, 1250, "Bath"}, // 29
	{2527, 1200, "Shower"}, // 30
	{2524, 200, "Washbasin"}, // 31
	{2525, 200, "Toilet"}, // 32
	{1208, 1200, "Washing Machine"}, // 33
	{1762, 1200, "Armchair A"}, // 34
	{1765, 1200, "Armchair B"}, // 35
	{1761, 700, "Sofa A"}, // 36
	{1764, 700, "Sofa B"}, // 37
	{1409, 20, "Trash can"}, // 38
	{2627, 1000, "Tapis Roulant"}, // 39
	{2630, 800, "Cyclette"}, // 40
	{2964, 1000, "Pool Table"}, // 41
	{1502, 200, "Door"}, // 42
	{19317, 600, "Bass Guitar"}, // 43
	{2134, 300, "White Kitchen Part 1"}, // 44
	{2133, 300, "White Kitchen Part 2"}, // 45
	{2131, 300, "White Kitchen Part 3"}, // 46
	{2130, 200, "Red Sink"}, // 47
	{2128, 900, "Red Fridge"}, // 48
	{2127, 300, "Red Kitchen Part 1"}, // 49
	{2129, 300, "Red Kitchen Part 2"}, // 50
	{2294, 300, "Red Kitchen Part 3"}, // 51
	{19166, 100, "San Andreas Picture"}, // 52
	{19172, 100, "Santa Maria Beach Picture"}, // 53
	{19173, 100, "San Fierro Picture"} // 54
	// Add more if you wish, but remember to redefine FURNITURE_NUMBER
};

// Box styles
#define BOX_STYLE_CMD "{33AA33}COMMAND"
#define BOX_STYLE_ERROR "{FF0000}ERROR"
#define BOX_STYLE_WARNING "{FF8000}WARNING"

// Dialogs
#define DIALOG_FORSALE_HOUSE 470 //
#define DIALOG_MY_HOUSE 471 //
#define DIALOG_OTHERS_HOUSE 472 //
#define DIALOG_FORSALE_BIZ 473 //
#define DIALOG_MY_BIZ 474 //
#define DIALOG_OTHERS_BIZ 475 //
#define DIALOG_HOUSE_MENU 476 //
#define DIALOG_SELL_HOUSE 477 //
#define DIALOG_RENAME_SHOP 478 //
#define DIALOG_SELL_SHOP 479 //
#define DIALOG_SUPPLY 480 //
#define DIALOG_STORE_MONEY 481 //
#define DIALOG_WITHDRAW_MONEY 482 //
#define DIALOG_EDIT_FURNITURE 483 //
#define DIALOG_SELL_FURNITURE 484 //
#define DIALOG_BUY_FURNITURE 485 //
#define DIALOG_MOVE_FURNITURE 486 //
#define DIALOG_FURNITURE_BOUGHT 487 //
#define DIALOG_SHOP 488 //
#define DIALOG_SHOP_MENU 489 //

stock SetLastHouse(playerid, houseid) 		{ return SetPVarInt(playerid, "LastHouse", houseid); }
stock SetLastShop(playerid, shopid) 		{ return SetPVarInt(playerid, "LastShop", shopid); }
stock GetLastHouse(playerid) 				{ return GetPVarInt(playerid, "LastHouse"); }
stock GetLastShop(playerid) 				{ return GetPVarInt(playerid, "LastShop"); }

new pVisitTimer[MAX_PLAYERS];

enum hInfo
{
	Owner[MAX_PLAYER_NAME],
	Price,
	Interior,
	Exterior,
	VirtualWorld, // Useful for making 2 houses with the same interior
	Locked,
	Float:InteriorX,
	Float:InteriorY,
	Float:InteriorZ,
	Float:ExteriorX,
	Float:ExteriorY,
	Float:ExteriorZ,
	// Storage
	Money, 
	Weapon[13],
	Ammo[13],
	// Furniture
	FCount,
	FModel[MAX_FURNITURE],
	FurnitureObj[MAX_FURNITURE],
	Float:FPosX[MAX_FURNITURE],
	Float:FPosY[MAX_FURNITURE],
	Float:FPosZ[MAX_FURNITURE],
	Float:FRotX[MAX_FURNITURE],
	Float:FRotY[MAX_FURNITURE],
	Float:FRotZ[MAX_FURNITURE]
};

new HouseInfo[MAX_HOUSES][hInfo];
new HousePickup[MAX_HOUSES];
new HousePickup2[MAX_HOUSES];
new HouseIcon[MAX_HOUSES];

enum bInfo 
{ 
	bTitle[MAX_TITLE], 
	bOwner[MAX_PLAYER_NAME], 
	bPrice, 
	bInterior, 
	bExterior, 
	bVirtualWorld, 
	bLocked, 
	Float:bInteriorX, 
	Float:bInteriorY, 
	Float:bInteriorZ, 
	Float:bExteriorX, 
	Float:bExteriorY,
	Float:bExteriorZ,
	// Stats
	bEarning, 
	bGoods, 
	bMoney,
	bItemList[1024]
};

new BusinessInfo[MAX_SHOPS][bInfo];
new BusinessPickup[MAX_SHOPS];
new BusinessPickup2[MAX_SHOPS];
new BusinessIcon[MAX_HOUSES];

public OnFilterScriptInit()
{
	print("\n---------------------------------------");
	print("          Sasinosoft Houses 2.0        \n");
	print("---------------------------------------\n");
	print("Sasinosoft Houses by Sasino97 2.0 has been loaded.");
	return 1;
}

public OnFilterScriptExit()
{
	for(new i=0;i<MAX_HOUSES;i++)
	{
		DestroyDynamicPickup(HousePickup[i]);
		DestroyDynamicPickup(HousePickup2[i]);
		DestroyDynamicMapIcon(HouseIcon[i]);
	}
	for(new i=0;i<MAX_SHOPS;i++)
	{
		DestroyDynamicPickup(BusinessPickup[i]);
		DestroyDynamicPickup(BusinessPickup2[i]);
		DestroyDynamicMapIcon(BusinessIcon[i]);
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
	SetLastHouse(playerid, INVALID_HOUSE_ID);
	SetLastShop(playerid, INVALID_HOUSE_ID);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetPlayerVirtualWorld(playerid, 0);
	SetLastHouse(playerid, INVALID_HOUSE_ID);
	SetLastShop(playerid, INVALID_HOUSE_ID);
	return 1;
}

public OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	if(response == EDIT_RESPONSE_UPDATE) return 1;
	new ini[64];
	new key[24];
	for(new hID = 0; hID < MAX_HOUSES; hID ++)
	{
		for(new i = 0; i < MAX_FURNITURE; i ++)
		{
			if(objectid == HouseInfo[hID][FurnitureObj][i])
			{
				if(response) // Clicked on the save icon
				{
					format(ini, 64, HOUSE_FILE, hID);
					INI_Open(ini);

					HouseInfo[hID][FPosX][i] = x; HouseInfo[hID][FPosY][i] = y; HouseInfo[hID][FPosZ][i] = z;
					HouseInfo[hID][FRotX][i] = rx; HouseInfo[hID][FRotY][i] = ry; HouseInfo[hID][FRotZ][i] = rz;
					format(key, 24, "FPosX%d", i); INI_WriteFloat(key, HouseInfo[hID][FPosX][i]);
					format(key, 24, "FPosY%d", i); INI_WriteFloat(key, HouseInfo[hID][FPosY][i]);
					format(key, 24, "FPosZ%d", i); INI_WriteFloat(key, HouseInfo[hID][FPosZ][i]);
					format(key, 24, "FRotX%d", i); INI_WriteFloat(key, HouseInfo[hID][FRotX][i]);
					format(key, 24, "FRotY%d", i); INI_WriteFloat(key, HouseInfo[hID][FRotY][i]);
					format(key, 24, "FRotZ%d", i); INI_WriteFloat(key, HouseInfo[hID][FRotZ][i]);
					
					SetDynamicObjectPos(objectid, HouseInfo[hID][FPosX][i], HouseInfo[hID][FPosY][i], HouseInfo[hID][FPosZ][i]);
					SetDynamicObjectRot(objectid, HouseInfo[hID][FRotX][i], HouseInfo[hID][FRotY][i], HouseInfo[hID][FRotZ][i]);
				
					INI_Save();
					INI_Close();
				}
				else // Pressed ESC
				{
					SetDynamicObjectPos(objectid, HouseInfo[hID][FPosX][i], HouseInfo[hID][FPosY][i], HouseInfo[hID][FPosZ][i]);
					SetDynamicObjectRot(objectid, HouseInfo[hID][FRotX][i], HouseInfo[hID][FRotY][i], HouseInfo[hID][FRotZ][i]);
				}
				break;
			}
		}
	}
	return 1;
}

#define Command(%0) !strcmp(cmd, %0, true)
public OnPlayerCommandText(playerid, cmdtext[])
{
	// Commands that help scripters to create new houses and stores for the game
	new cmd[256];
	new idx;
	cmd = strtok(cmdtext, idx);
	
	if(Command("/savehouse"))
	{
		if(IsPlayerAdmin(playerid))
		{
			new Float:X, Float:Y, Float:Z;
			new I;
			GetPlayerPos(playerid, X, Y, Z);
			I = GetPlayerInterior(playerid);
			
			new comment[128];
			comment = strrest(cmdtext, idx);
			new File: fileid = fopen(SAVED_HOUSES_FILE, io_append);
			if(fileid)
			{
				new string[256];
				format(string, 256, "CreateHouse(%.2f, %.2f, %.2f, interiorX, interiorY, interiorZ, price, interior, %d, virtualworld); // %s\r\n", X, Y, Z, I, comment);
				fwrite(fileid, string);
				fclose(fileid);
				FS_MsgBox(playerid, "{33AA33}SUCCESS", "The house has been saved to \""SAVED_HOUSES_FILE"\"");
			}
			else FS_MsgBox(playerid, BOX_STYLE_ERROR, "An error has occurred! Maybe the directory doesn't exist.");
			return 1;
		}
	}
	if(Command("/savestore") || Command("/savebiz") || Command("/saveshop"))
	{
		if(IsPlayerAdmin(playerid))
		{
			new Float:X, Float:Y, Float:Z;
			new I;
			GetPlayerPos(playerid, X, Y, Z);
			I = GetPlayerInterior(playerid);
			new comment[128];
			comment = strrest(cmdtext, idx);
			new File: fileid = fopen(SAVED_SHOPS_FILE, io_append);
			if(fileid)
			{
				new string[256];
				format(string, 256, "CreateBusiness(title, earning, %.2f, %.2f, %.2f, interiorX, interiorY, interiorZ, price, interior, %d, virtualworld, iconmarker, item_list[]); // %s\r\n", X, Y, Z, I, comment);
				fwrite(fileid, string);
				fclose(fileid);
				FS_MsgBox(playerid, "{33AA33}SUCCESS", "The store has been saved to \""SAVED_SHOPS_FILE"\"");
			}
			else FS_MsgBox(playerid, BOX_STYLE_ERROR, "An error has occurred! Maybe the directory doesn't exist.");
			return 1;
		}
	}
	return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(newkeys & KEY)
	{
		new name[24];
		GetPlayerName(playerid, name, 24);
		for(new i=0; i<MAX_HOUSES; i++)
		{
			if(IsPlayerInRangeOfPoint(playerid, 1, HouseInfo[i][InteriorX], HouseInfo[i][InteriorY], HouseInfo[i][InteriorZ]) && GetPlayerVirtualWorld(playerid) == HouseInfo[i][VirtualWorld])
			{
				return ExitHouse(playerid, i);
			}
		}
		for(new i=0; i<MAX_SHOPS; i++)
		{
			if(IsPlayerInRangeOfPoint(playerid, 1, BusinessInfo[i][bInteriorX], BusinessInfo[i][bInteriorY], BusinessInfo[i][bInteriorZ]) && GetPlayerVirtualWorld(playerid) == BusinessInfo[i][bVirtualWorld])
			{
				return ExitShop(playerid, i);
			}
		}
		if(GetHouseID(playerid) != INVALID_HOUSE_ID) return OpenHouseDialog(playerid, GetHouseID(playerid));
		if(GetShopID(playerid) != INVALID_HOUSE_ID) return OpenBusinessDialog(playerid, GetShopID(playerid));
		
		new LH = GetLastHouse(playerid);
		if(LH != INVALID_HOUSE_ID && !strcmp(name, HouseInfo[LH][Owner], true))
		{
			ShowHouseMenu(playerid);
			return 1;
		}
		new LS = GetLastShop(playerid);
		if(LS != INVALID_HOUSE_ID)
		{
			if(!strcmp(name, BusinessInfo[LS][bOwner], true)) // he is the owner
			{
				ShowBusinessMenu(playerid);
			}
			else
			{
				ShowPlayerDialog(playerid, DIALOG_SHOP, DIALOG_STYLE_LIST, BusinessInfo[LS][bTitle], BusinessInfo[LS][bItemList], "Buy", "Cancel");
			}
			return 1;
		}
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	new hID = GetHouseID(playerid);
	new sID = GetShopID(playerid);
	switch(dialogid)
	{
		case DIALOG_HOUSE_MENU:
		{
			hID = GetLastHouse(playerid);
			if(!response) return 1;
			switch(listitem)
			{
				case 0: // Store money
				{
					new string[128];
					format(string, 128, "Current money: %d - Insert the money to deposit", HouseInfo[hID][Money]);
					ShowPlayerDialog(playerid, DIALOG_STORE_MONEY, DIALOG_STYLE_INPUT, "{33AA33}STORE MONEY", string, "OK", "Cancel");
				}
				case 1: // Withdraw money
				{
					new string[128];
					format(string, 128, "Current money: %d - Insert the money to withdraw", HouseInfo[hID][Money]);
					ShowPlayerDialog(playerid, DIALOG_WITHDRAW_MONEY, DIALOG_STYLE_INPUT, "{33AA33}WITHDRAW MONEY", string, "OK", "Cancel");
				}
				case 2: // Store weapons
				{	
					new ini[64];
					format(ini, 64, HOUSE_FILE, hID);
					INI_Open(ini);
					new key[24];
					for(new x = 0; x < 13; x ++)
					{
						format(key, 24, "Weapon%d", x);
						HouseInfo[hID][Weapon][x] = INI_ReadInt(key);
						format(key, 24, "Ammo%d", x);
						HouseInfo[hID][Ammo][x] = INI_ReadInt(key);
						GivePlayerWeapon(playerid, HouseInfo[hID][Weapon][x], HouseInfo[hID][Ammo][x]);
					}
					INI_Close();
					INI_Open(ini);
					for(new x = 0; x < 13; x ++)
					{
						GetPlayerWeaponData(playerid, x, HouseInfo[hID][Weapon][x], HouseInfo[hID][Ammo][x]);
						if(HouseInfo[hID][Weapon][x] == 0) continue;
						format(key, 24, "Weapon%d", x);
						INI_WriteInt(key, HouseInfo[hID][Weapon][x]);
						format(key, 24, "Ammo%d", x);
						INI_WriteInt(key, HouseInfo[hID][Ammo][x]);
					}
					INI_Save();
					INI_Close();
					ResetPlayerWeapons(playerid);
					FS_MsgBox(playerid, BOX_STYLE_CMD, "All weapons stored.");
				}
				case 3: // Collect weapons
				{
					new ini[64];
					new key[24];
					format(ini, 64, HOUSE_FILE, hID);
					
					// Read weapons and give them to player
					INI_Open(ini);
					new count = 0;
					for(new x = 0; x < 13; x ++) 
					{
						format(key, 24, "Weapon%d", x);
						HouseInfo[hID][Weapon][x] = INI_ReadInt(key);
						format(key, 24, "Ammo%d", x);
						HouseInfo[hID][Ammo][x] = INI_ReadInt(key);
						if(HouseInfo[hID][Weapon][x] != 0)
						{
							count += 1;
							GivePlayerWeapon(playerid, HouseInfo[hID][Weapon][x], HouseInfo[hID][Ammo][x]);
						}
					}
					INI_Close();
					// Delete weapons from storage
					INI_Open(ini); 
					for(new x = 0; x < 13; x ++) 
					{
						HouseInfo[hID][Weapon][x] = 0;
						HouseInfo[hID][Ammo][x] = 0;
						format(key, 24, "Weapon%d", x);
						INI_WriteInt(key, HouseInfo[hID][Weapon][x]);
						format(key, 24, "Ammo%d", x);
						INI_WriteInt(key, HouseInfo[hID][Ammo][x]);
					}
					INI_Save();
					INI_Close();
					format(key, 24, "%d weapons collected.", count);
					if(count != 0) FS_MsgBox(playerid, BOX_STYLE_CMD, key);
					else FS_MsgBox(playerid, BOX_STYLE_ERROR, "You have no weapons in your storage!");
				}
				case 4: // Edit furniture
				{
					new bigstring[2048];
					new string[64];
					hID = GetLastHouse(playerid);
					for(new i = 0; i < MAX_FURNITURE; i++)
					{
						if(HouseInfo[hID][FModel][i] == INVALID_FURNITURE_ID) 
						{ 
							format(string, 64, "%d - {FF0000}Empty", i+1); 
						}
						else
						{
							if(HouseInfo[hID][FPosX][i] != 0.0) format(string, 64, "%d - %s - {33AA33}in house", i+1, FurnitureInfo[HouseInfo[hID][FModel][i]][2]); // Edit
							else format(string, 64, "%d - %s - {0000FF}in storage", i+1, FurnitureInfo[HouseInfo[hID][FModel][i]][2]); // Place
						}
						format(bigstring, sizeof(bigstring), "%s%s\n", bigstring, string);
					}
					ShowPlayerDialog(playerid, DIALOG_EDIT_FURNITURE, DIALOG_STYLE_LIST, "{33AA33}Select a furniture to place/edit.", bigstring, "Edit", "Cancel");
				}
				case 5: // Buy furniture
				{
					ShowFurnitureMenu(playerid);
				}
				case 6: // Sell furniture
				{
					new bigstring[2048];
					new string[64];
					hID = GetLastHouse(playerid);
					for(new i = 0; i < MAX_FURNITURE; i++)
					{
						if(HouseInfo[hID][FModel][i] == INVALID_FURNITURE_ID) 
						{ 
							format(string, 64, "%d - {FF0000}Empty", i+1); 
						}
						else
						{
							format(string, 64, "%d - %s {33AA33}(%d$)", i+1, FurnitureInfo[HouseInfo[hID][FModel][i]][2], floatround(FurnitureInfo[HouseInfo[hID][FModel][i]][1]*SELL_MULTIPLIER));
						}
						format(bigstring, sizeof(bigstring), "%s%s\n", bigstring, string);
					}
					ShowPlayerDialog(playerid, DIALOG_SELL_FURNITURE, DIALOG_STYLE_LIST, "{33AA33}Select a furniture to sell.", bigstring, "Sell", "Cancel");
				}
			}
			return 1;
		}
		case DIALOG_EDIT_FURNITURE:
		{
			if(!response) return 1;
			new i = listitem;
			hID = GetLastHouse(playerid);
			if(HouseInfo[hID][FModel][i] == INVALID_FURNITURE_ID) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "Invalid furniture selected.");
			if(HouseInfo[hID][FPosX][i] != 0.0)
			{
				if(!IsValidDynamicObject(HouseInfo[hID][FurnitureObj][i])) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "Invalid dynamic object.");
				EditDynamicObject(playerid, HouseInfo[hID][FurnitureObj][i]);
			}
			else
			{
				new Float:X, Float:Y, Float:Z;
				GetPlayerPos(playerid, X, Y, Z);
				GetXYInFrontOfPlayer(playerid, X, Y, 2.0);
				HouseInfo[hID][FPosX][i] = X; HouseInfo[hID][FPosY][i] = Y; HouseInfo[hID][FPosZ][i] = Z;
				HouseInfo[hID][FRotX][i] = 0; HouseInfo[hID][FRotY][i] = 0; HouseInfo[hID][FRotZ][i] = 0;
				HouseInfo[hID][FurnitureObj][i] = CreateDynamicObject(FurnitureInfo[HouseInfo[hID][FModel][i]][0], HouseInfo[hID][FPosX][i], HouseInfo[hID][FPosY][i], HouseInfo[hID][FPosZ][i], HouseInfo[hID][FRotX][i], HouseInfo[hID][FRotY][i], HouseInfo[hID][FRotZ][i], HouseInfo[hID][VirtualWorld], HouseInfo[hID][Interior], -1, 50.0);
				SaveFurniturePosition(hID, i);
			}
			return 1;
		}
		case DIALOG_BUY_FURNITURE:
		{
			if(!response) return 1;
			if(GetPlayerMoney(playerid) < FurnitureInfo[listitem][1]) return ShowNoMoneyMessage(playerid);
			hID = GetLastHouse(playerid);
			BuyFurniture(playerid, hID, listitem+1);
			return 1;
		}
		case DIALOG_SELL_FURNITURE:
		{
			if(!response) return 1;
			new i = listitem;
			new fname[128];
			hID = GetLastHouse(playerid);
			if(HouseInfo[hID][FModel][i] == INVALID_FURNITURE_ID) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "Invalid furniture selected.");
			new money = floatround(FurnitureInfo[HouseInfo[hID][FModel][i]][1]*SELL_MULTIPLIER);
			GivePlayerMoney(playerid, money);
			format(fname, 128, "{FFFFFF}You sold a {0000FF}\"%s\"{FFFFFF} for {33AA33}%d$.", FurnitureInfo[HouseInfo[hID][FModel][i]][2], money);
			FS_MsgBox(playerid, BOX_STYLE_CMD, fname);
			HouseInfo[hID][FModel][i] = INVALID_FURNITURE_ID;
			HouseInfo[hID][FPosX][i] = 0; HouseInfo[hID][FPosY][i] = 0; HouseInfo[hID][FPosZ][i] = 0;
			HouseInfo[hID][FRotX][i] = 0; HouseInfo[hID][FRotY][i] = 0; HouseInfo[hID][FRotZ][i] = 0;
			if(IsValidDynamicObject(HouseInfo[hID][FurnitureObj][i])) DestroyDynamicObject(HouseInfo[hID][FurnitureObj][i]);
			HouseInfo[hID][FurnitureObj][i] = 0;
			HouseInfo[hID][FCount] -= 1;
			format(fname, 128, HOUSE_FILE, hID);
			new key[24];
			INI_Open(fname);
			INI_WriteInt("FCount", HouseInfo[hID][FCount]);
			format(key, 24, "FModel%d", i); INI_WriteInt(key, INVALID_FURNITURE_ID);
			INI_Save();
			INI_Close();
			
			return 1;
		}
		case DIALOG_FURNITURE_BOUGHT:
		{
			if(response) ShowFurnitureMenu(playerid);
			return 1;
		}
		case DIALOG_STORE_MONEY:
		{
			if(!response) return 1;
			
			new string[128];
			hID = GetLastHouse(playerid);
			sID = GetLastShop(playerid);
			new val = strval(inputtext);
			if(val < 0 || val > GetPlayerMoney(playerid)) return ShowNoMoneyMessage(playerid);
			GivePlayerMoney(playerid, -val);
			HouseInfo[hID][Money] += val;
			format(string, 128, "%d$ stored in your house.", val);
			FS_MsgBox(playerid, BOX_STYLE_CMD, string);
			format(string, 128, HOUSE_FILE, hID);
			INI_Open(string);
			INI_WriteInt("Money", HouseInfo[hID][Money]);
			INI_Save();
			INI_Close();
			return 1;
		}
		case DIALOG_WITHDRAW_MONEY:
		{
			if(!response) return 1;
			
			new string[128];
			hID = GetLastHouse(playerid);
			sID = GetLastShop(playerid);
			new val = strval(inputtext);
			if(val < 0 || val > HouseInfo[hID][Money]) return ShowNoMoneyMessage(playerid);
			GivePlayerMoney(playerid, val);
			HouseInfo[hID][Money] -= val;
			format(string, 128, "%d$ withdrew from your house.", val);
			FS_MsgBox(playerid, BOX_STYLE_CMD, string);
			format(string, 128, HOUSE_FILE, hID);
			INI_Open(string);
			INI_WriteInt("Money", HouseInfo[hID][Money]);
			INI_Save();
			INI_Close();
			return 1;
		}
		case DIALOG_FORSALE_HOUSE:
		{
			if(!response) return 1;
			if(listitem == 0)
			{
				if(GetPlayerMoney(playerid) < HouseInfo[hID][Price]) return ShowNoMoneyMessage(playerid);
				BuyHouse(playerid, hID);
			}
			else if(listitem == 1)
			{
				EnterHouse(playerid, hID);
				FS_MsgBox(playerid, BOX_STYLE_CMD, "You are visiting this house.");
				pVisitTimer[playerid] = SetTimerEx("ExitHouse", VISIT_TIME, false, "ii", playerid, hID);
			}
			return 1;
		}
		case DIALOG_MY_HOUSE:
		{
			if(!response) return 1;
			switch(listitem)
			{
				case 0: // entra
				{
					EnterHouse(playerid, hID);
				}
				case 1: // apri/chiudi
				{
					LockUnlockHouse(playerid, hID);
				}
				case 2: // vendi
				{
					new string[64];
					format(string, 64, "{33AA33}Do you want to sell your house for %d$?\n{FF0000}All the money, the weapons and the furniture in your storage will remain there, and the next owner can use them.", floatround(HouseInfo[hID][Price]*SELL_MULTIPLIER));
					ShowPlayerDialog(playerid, DIALOG_SELL_HOUSE, DIALOG_STYLE_MSGBOX, "{FF8000}CONFIRMATION", string, "Sell", "Don't sell");
				}
			}
			return 1;
		}
		case DIALOG_OTHERS_HOUSE:
		{
			if(!response) return 1;
			if(HouseInfo[hID][Locked] == 1)
			{
				FS_MsgBox(playerid, BOX_STYLE_ERROR, "This house is {FF0000}locked.");
			}
			else
			{
				EnterHouse(playerid, hID);
			}
			return 1;
		}
		case DIALOG_SELL_HOUSE:
		{
			if(response)
			{
				SellHouse(playerid, hID);
			}
			else
			{
				FS_MsgBox(playerid, BOX_STYLE_WARNING, "House not sold.");
			}
			return 1;
		}
		case DIALOG_SHOP:
		{
			if(!response) return 1;
			sID = GetLastShop(playerid);
			CallRemoteFunction("OnPlayerBuyItem", "iii", playerid, sID, listitem);
			return 1;
		}
		case DIALOG_SHOP_MENU:
		{
			sID = GetLastShop(playerid);
			if(!response) return 1;
			switch(listitem)
			{
				case 0: //Rename your shop
				{
					new string[68];
					format(string, 68, "Current Name: %s", BusinessInfo[sID][bTitle]);
					ShowPlayerDialog(playerid, DIALOG_RENAME_SHOP, DIALOG_STYLE_INPUT, "{33AA33}RENAME", string, "OK", "Cancel");
				}
				case 1: //Collect your earnings
				{
					if(BusinessInfo[sID][bMoney] == 0) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "The cash register is empty.");
					new string[128];
					GivePlayerMoney(playerid, BusinessInfo[sID][bMoney]);
					format(string, 128, "You earned %d$.", BusinessInfo[sID][bMoney]);
					FS_MsgBox(playerid, BOX_STYLE_CMD, string);
					
					BusinessInfo[sID][bMoney] = 0;
					format(string, 128, SHOP_FILE, sID);
					INI_Open(string);
					INI_WriteInt("Money", 0);
					INI_Save();
					INI_Close();
				}
				case 2: //Supply goods for your shop
				{
					new string[68];
					format(string, 68, "Goods price: %d$/good", GOOD_PRICE);
					ShowPlayerDialog(playerid, DIALOG_SUPPLY, DIALOG_STYLE_INPUT, "{33AA33}Enter the amount to buy", string, "OK", "Cancel");
				}
				case 3:
				{
					ShowPlayerDialog(playerid, DIALOG_SHOP, DIALOG_STYLE_LIST, "{33AA33}Select an item from your shop.", BusinessInfo[sID][bItemList], "Buy", "Cancel");
				}
			}
			return 1;
		}
		case DIALOG_FORSALE_BIZ:
		{
			if(!response) return 1;
			switch(listitem)
			{
				case 0:
				{
					if(GetPlayerMoney(playerid) < BusinessInfo[sID][bEarning]) return ShowNoMoneyMessage(playerid);
					GivePlayerMoney(playerid, -BusinessInfo[sID][bEarning]);
					EnterShop(playerid, sID);
				}
				case 1:
				{
					if(GetPlayerMoney(playerid) < BusinessInfo[sID][bPrice]) return ShowNoMoneyMessage(playerid);
					BuyShop(playerid, sID);
				}
			}
			return 1;
		}
		case DIALOG_MY_BIZ:
		{
			if(!response) return 1;
			switch(listitem)
			{
				case 0: //Enter your shop
				{
					EnterShop(playerid, sID);
				}
				case 1: //Open/Close the shop
				{
					LockUnlockShop(playerid, sID);
				}
				case 2: //Sell your shop
				{
					new string[64];
					format(string, 64, "{33AA33}Do you want to sell your store for %d$?\n{FF0000}All the money and the goods will remain there.", floatround(BusinessInfo[sID][bPrice]*SELL_MULTIPLIER));
					ShowPlayerDialog(playerid, DIALOG_SELL_SHOP, DIALOG_STYLE_MSGBOX, "{FF8000}CONFIRMATION", string, "Sell", "Don't sell");
				}
			}
			return 1;
		}
		case DIALOG_SELL_SHOP:
		{
			if(response)
			{
				SellShop(playerid, sID); // Changed in 2.2, previously it was hID, and it was making a bug where player couldn't sell their stores.
			}
			else
			{
				FS_MsgBox(playerid, BOX_STYLE_WARNING, "Store not sold.");
			}
			return 1;
		}
		case DIALOG_OTHERS_BIZ:
		{
			if(!response) return 1;
			if(BusinessInfo[sID][bLocked] == 1) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "This store is closed.");
			//if(BusinessInfo[sID][bGoods] <= 0) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "This store is out of stock.");
			if(GetPlayerMoney(playerid) < BusinessInfo[sID][bEarning]) return ShowNoMoneyMessage(playerid);
			
			GivePlayerMoney(playerid, -BusinessInfo[sID][bEarning]);
			EnterShop(playerid, sID);
			BusinessInfo[sID][bMoney] += BusinessInfo[sID][bEarning];
			//BusinessInfo[sID][bGoods] -= 1;
			new filename[128];
			format(filename, 128, SHOP_FILE, sID);
			INI_Open(filename);
			INI_WriteInt("Money", BusinessInfo[sID][bMoney]);
			//INI_WriteInt("Goods", BusinessInfo[sID][bGoods]);
			INI_Save();
			INI_Close();
			return 1;
		}
		case DIALOG_RENAME_SHOP:
		{
			sID = GetLastShop(playerid);
			if(!response) return 1;
			if(strlen(inputtext) > MAX_TITLE) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "The max length is "MAX_TITLE_STR"!");
			format(BusinessInfo[sID][bTitle], MAX_TITLE, inputtext);
			new filename[128];
			format(filename, 128, SHOP_FILE, sID);
			INI_Open(filename);
			INI_WriteString("Title", BusinessInfo[sID][bTitle]);
			INI_Save();
			INI_Close();
			format(filename, 128, "Store name changed to %s!", BusinessInfo[sID][bTitle]);
			FS_MsgBox(playerid, BOX_STYLE_CMD, filename); // I used again filename here to not create a new var and waste more cells.
			return 1;
		}
		case DIALOG_SUPPLY:
		{
			sID = GetLastShop(playerid);
			if(!response) return 1;
			new value = strval(inputtext);
			if(value <= 0 || value > 500) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "Enter an amount between 1 and 500!");
			new cost = GOOD_PRICE * value;
			if(GetPlayerMoney(playerid) < cost) return ShowNoMoneyMessage(playerid);
			BusinessInfo[sID][bGoods] += value;
			GivePlayerMoney(playerid, -cost);
			new filename[128];
			format(filename, 128, SHOP_FILE, sID);
			INI_Open(filename);
			INI_WriteInt("Goods", BusinessInfo[sID][bGoods]);
			INI_Save();
			INI_Close();
			format(filename, 128, "You just bought %d goods for your store for %d$!", value, cost);
			FS_MsgBox(playerid, BOX_STYLE_CMD, filename);
			return 1;
		}
	}
	return 0;
}

forward FS_MsgBox(playerid, caption[], text[]);
public FS_MsgBox(playerid, caption[], text[])
{
	ShowPlayerDialog(playerid, 469, DIALOG_STYLE_MSGBOX, caption, text, "OK", "");
	return 1;
}

forward FS_CreateHouse(Float:eX, Float:eY, Float:eZ, Float:iX, Float:iY, Float:iZ, price, interior, exterior, virtualWorld);
public FS_CreateHouse(Float:eX, Float:eY, Float:eZ, Float:iX, Float:iY, Float:iZ, price, interior, exterior, virtualWorld)
{
	static hCount;
	new hID = hCount; hCount += 1;
	
	HouseInfo[hID][Price] = price;
	HouseInfo[hID][Interior] = interior;
	HouseInfo[hID][Exterior] = exterior;
	HouseInfo[hID][VirtualWorld] = virtualWorld;
	HouseInfo[hID][InteriorX] = iX;
	HouseInfo[hID][InteriorY] = iY;
	HouseInfo[hID][InteriorZ] = iZ;
	HouseInfo[hID][ExteriorX] = eX;
	HouseInfo[hID][ExteriorY] = eY;
	HouseInfo[hID][ExteriorZ] = eZ;
	
	new housefile[64];
	format(housefile, 64, HOUSE_FILE, hID);
	
	if(!INI_Exist(housefile)) // If not existing
	{
		INI_Open(housefile);
		//
		format(HouseInfo[hID][Owner], MAX_PLAYER_NAME, INVALID_OWNER);   INI_WriteString("Owner", HouseInfo[hID][Owner]);
		HouseInfo[hID][Locked] = 1;  INI_WriteInt("Locked", HouseInfo[hID][Locked]);
		HouseInfo[hID][Money] = 0;  INI_WriteInt("Money", HouseInfo[hID][Money]);
		new key[24];
		for(new x = 0; x < 13; x ++) 
		{ 
			HouseInfo[hID][Weapon][x] = 0;  
			HouseInfo[hID][Ammo][x] = 0;  
			format(key, 24, "Weapon%d", x); INI_WriteInt(key, HouseInfo[hID][Weapon][x]);
			format(key, 24, "Ammo%d", x); INI_WriteInt(key, HouseInfo[hID][Ammo][x]); 
		}
		HouseInfo[hID][FCount] = 0;  INI_WriteInt("FCount", HouseInfo[hID][FCount]);
		for(new i = 0; i < MAX_FURNITURE; i ++)
		{
			HouseInfo[hID][FModel][i] = INVALID_FURNITURE_ID;
			HouseInfo[hID][FPosX][i] = 0.0; HouseInfo[hID][FPosY][i] = 0.0; HouseInfo[hID][FPosZ][i] = 0.0;
			HouseInfo[hID][FRotX][i] = 0.0; HouseInfo[hID][FRotY][i] = 0.0; HouseInfo[hID][FRotZ][i] = 0.0;
			format(key, 24, "FModel%d", i); INI_WriteInt(key, HouseInfo[hID][FModel][i]);
			format(key, 24, "FPosX%d", i); INI_WriteFloat(key, HouseInfo[hID][FPosX][i]);
			format(key, 24, "FPosY%d", i); INI_WriteFloat(key, HouseInfo[hID][FPosY][i]);
			format(key, 24, "FPosZ%d", i); INI_WriteFloat(key, HouseInfo[hID][FPosZ][i]);
			format(key, 24, "FRotX%d", i); INI_WriteFloat(key, HouseInfo[hID][FRotX][i]);
			format(key, 24, "FRotY%d", i); INI_WriteFloat(key, HouseInfo[hID][FRotY][i]);
			format(key, 24, "FRotZ%d", i); INI_WriteFloat(key, HouseInfo[hID][FRotZ][i]);
		}

		//
		INI_Save();
		INI_Close();
		
		#if CONSOLE == 1
		printf("Created new house - ID: %d - Ext: %d, %f, %f, %f - Int: %d, %f, %f, %f - Price: %d - World: %d", hID, HouseInfo[hID][Exterior], HouseInfo[hID][ExteriorX], HouseInfo[hID][ExteriorY], HouseInfo[hID][ExteriorZ], HouseInfo[hID][Interior], HouseInfo[hID][InteriorX], HouseInfo[hID][InteriorY], HouseInfo[hID][InteriorZ], HouseInfo[hID][Price], HouseInfo[hID][VirtualWorld]);
		#endif
	}
	else
	{
		INI_Open(housefile);
		//
		INI_ReadString(HouseInfo[hID][Owner], "Owner", MAX_PLAYER_NAME);
		HouseInfo[hID][Locked] = INI_ReadInt("Locked");
		HouseInfo[hID][Money] = INI_ReadInt("Money");
		new key[32];
		for(new x = 0; x < 13; x ++) 
		{ 
			format(key, 32, "Weapon%d", x);
			HouseInfo[hID][Weapon][x] = INI_ReadInt(key);
			format(key, 32, "Ammo%d", x);
			HouseInfo[hID][Ammo][x] = INI_ReadInt(key);
		}
		HouseInfo[hID][FCount] = INI_ReadInt("FCount");
		for(new i = 0; i < MAX_FURNITURE; i ++)
		{
			format(key, 32, "FModel%d", i); HouseInfo[hID][FModel][i] = INI_ReadInt(key);
			format(key, 32, "FPosX%d", i); HouseInfo[hID][FPosX][i] = INI_ReadFloat(key);
			format(key, 32, "FPosY%d", i); HouseInfo[hID][FPosY][i] = INI_ReadFloat(key);
			format(key, 32, "FPosZ%d", i); HouseInfo[hID][FPosZ][i] = INI_ReadFloat(key);
			format(key, 32, "FRotX%d", i); HouseInfo[hID][FRotX][i] = INI_ReadFloat(key);
			format(key, 32, "FRotY%d", i); HouseInfo[hID][FRotY][i] = INI_ReadFloat(key);
			format(key, 32, "FRotZ%d", i); HouseInfo[hID][FRotZ][i] = INI_ReadFloat(key);
			if(HouseInfo[hID][FPosX][i] != 0.0) HouseInfo[hID][FurnitureObj][i] = CreateDynamicObject(FurnitureInfo[HouseInfo[hID][FModel][i]][0], HouseInfo[hID][FPosX][i], HouseInfo[hID][FPosY][i], HouseInfo[hID][FPosZ][i], HouseInfo[hID][FRotX][i], HouseInfo[hID][FRotY][i], HouseInfo[hID][FRotZ][i], HouseInfo[hID][VirtualWorld], HouseInfo[hID][Interior], -1, 50.0);
		}
		//
		INI_Save();
		INI_Close();
		
		#if CONSOLE == 1
		printf("Loaded house - ID: %d - Owner: %s - Locked: %d", hID, HouseInfo[hID][Owner], HouseInfo[hID][Locked]);
		#endif
	}
	if(!strcmp(HouseInfo[hID][Owner], INVALID_OWNER, true)) //for sale
	{
		HousePickup[hID] = CreateDynamicPickup(1273, 23, HouseInfo[hID][ExteriorX], HouseInfo[hID][ExteriorY], HouseInfo[hID][ExteriorZ]);
		#if MAP_ICONS == 1
		HouseIcon[hID] = CreateDynamicMapIcon(HouseInfo[hID][ExteriorX], HouseInfo[hID][ExteriorY], HouseInfo[hID][ExteriorZ], 31, 0, _, _, _, 800.0);
		#endif
	}
	else // not for sale
	{
		HousePickup[hID] = CreateDynamicPickup(1318, 23, HouseInfo[hID][ExteriorX], HouseInfo[hID][ExteriorY], HouseInfo[hID][ExteriorZ]);
		#if MAP_ICONS == 1
		HouseIcon[hID] = CreateDynamicMapIcon(HouseInfo[hID][ExteriorX], HouseInfo[hID][ExteriorY], HouseInfo[hID][ExteriorZ], 32, 0, _, _, _, 800.0);
		#endif
	}
	HousePickup2[hID] = CreateDynamicPickup(1318, 23, HouseInfo[hID][InteriorX], HouseInfo[hID][InteriorY], HouseInfo[hID][InteriorZ]);
	Create3DTextLabel("House - Press "KEY_STRING" to open the menu", 0xFFFF00FF, HouseInfo[hID][ExteriorX],HouseInfo[hID][ExteriorY], HouseInfo[hID][ExteriorZ]+1, 20, 0, 1);
	Create3DTextLabel("Press "KEY_STRING" to exit", 0xFFFF00FF, HouseInfo[hID][InteriorX], HouseInfo[hID][InteriorY], HouseInfo[hID][InteriorZ]+1, 20, HouseInfo[hID][VirtualWorld], 1);
	return hID;
}

forward FS_CreateBusiness(title[MAX_PLAYER_NAME], earning, Float:eX, Float:eY, Float:eZ, Float:iX, Float:iY, Float:iZ, price, interior, exterior, virtualWorld, iconmarker, itemlist[1024]);
public FS_CreateBusiness(title[MAX_PLAYER_NAME], earning, Float:eX, Float:eY, Float:eZ, Float:iX, Float:iY, Float:iZ, price, interior, exterior, virtualWorld, iconmarker, itemlist[1024])
{
	static bCount;
	new hID = bCount; bCount += 1;
	
	BusinessInfo[hID][bPrice] = price; 
	BusinessInfo[hID][bInterior] = interior;
	BusinessInfo[hID][bExterior] = exterior; 
	BusinessInfo[hID][bVirtualWorld] = virtualWorld;
	BusinessInfo[hID][bInteriorX] = iX;
	BusinessInfo[hID][bInteriorY] = iY;
	BusinessInfo[hID][bInteriorZ] = iZ;
	BusinessInfo[hID][bExteriorX] = eX;
	BusinessInfo[hID][bExteriorY] = eY;
	BusinessInfo[hID][bExteriorZ] = eZ;
	BusinessInfo[hID][bEarning] = earning;
	if(strcmp(itemlist, "_") != 0) format(BusinessInfo[hID][bItemList], 1024, itemlist);
	else format(BusinessInfo[hID][bItemList], 1024, NO_ITEMS_STRING);
	
	new bizfile[64];
	format(bizfile, 64, SHOP_FILE, hID);
	
	if(!INI_Exist(bizfile)) // If not existing
	{
		INI_Open(bizfile);
		//
		format(BusinessInfo[hID][bTitle], MAX_PLAYER_NAME, title);   INI_WriteString("Title", BusinessInfo[hID][bTitle]);
		format(BusinessInfo[hID][bOwner], MAX_PLAYER_NAME, INVALID_OWNER);   INI_WriteString("Owner", BusinessInfo[hID][bOwner]);
		BusinessInfo[hID][bLocked] = 0;  INI_WriteInt("Locked", BusinessInfo[hID][bLocked]);
		BusinessInfo[hID][bMoney] = 0;  INI_WriteInt("Money", BusinessInfo[hID][bMoney]);
		BusinessInfo[hID][bGoods] = 10;  INI_WriteInt("Goods", BusinessInfo[hID][bGoods]);
		//
		INI_Save();
		INI_Close();
		
		#if CONSOLE == 1
		printf("Created new business - ID: %d - Name: %s - Ext: %d, %f, %f, %f - Int: %d, %f, %f, %f - Price: %d - World: %d", hID, BusinessInfo[hID][bTitle], BusinessInfo[hID][bExterior], BusinessInfo[hID][bExteriorX], BusinessInfo[hID][bExteriorY], BusinessInfo[hID][bExteriorZ], BusinessInfo[hID][bInterior], BusinessInfo[hID][bInteriorX], BusinessInfo[hID][bInteriorY], BusinessInfo[hID][bInteriorZ], BusinessInfo[hID][bPrice], BusinessInfo[hID][bVirtualWorld]);
		#endif
	}
	else
	{
		INI_Open(bizfile);
		//
		INI_ReadString(BusinessInfo[hID][bTitle], "Title", MAX_TITLE);
		INI_ReadString(BusinessInfo[hID][bOwner], "Owner", MAX_PLAYER_NAME);
		BusinessInfo[hID][bLocked] = INI_ReadInt("Locked");
		BusinessInfo[hID][bMoney] = INI_ReadInt("Money");
		BusinessInfo[hID][bGoods] = INI_ReadInt("Goods");
		//
		INI_Close();
		
		#if CONSOLE == 1
		printf("Loaded store - ID: %d - Title: %s - Owner: %s", hID, BusinessInfo[hID][bTitle], BusinessInfo[hID][bOwner]);
		#endif
	}
	if(!strcmp(BusinessInfo[hID][bOwner], INVALID_OWNER, true)) //for sale
	{
		BusinessPickup[hID] = CreateDynamicPickup(1272, 23, BusinessInfo[hID][bExteriorX], BusinessInfo[hID][bExteriorY], BusinessInfo[hID][bExteriorZ]);
	}
	else // not for sale
	{
		BusinessPickup[hID] = CreateDynamicPickup(1318, 23, BusinessInfo[hID][bExteriorX], BusinessInfo[hID][bExteriorY], BusinessInfo[hID][bExteriorZ]);
	}
	#if MAP_ICONS == 1
	BusinessIcon[hID] = CreateDynamicMapIcon(BusinessInfo[hID][bExteriorX], BusinessInfo[hID][bExteriorY], BusinessInfo[hID][bExteriorZ], iconmarker, 0, _, _, _, 800.0);
	#endif
	BusinessPickup2[hID] = CreateDynamicPickup(1318, 23, BusinessInfo[hID][bInteriorX], BusinessInfo[hID][bInteriorY], BusinessInfo[hID][bInteriorZ]);
	Create3DTextLabel("Business - Press "KEY_STRING" to open the menu", 0xFFFF00FF, BusinessInfo[hID][bExteriorX],BusinessInfo[hID][bExteriorY], BusinessInfo[hID][bExteriorZ]+1, 20, 0, 1);
	Create3DTextLabel("Press "KEY_STRING" to exit", 0xFFFF00FF, BusinessInfo[hID][bInteriorX], BusinessInfo[hID][bInteriorY], BusinessInfo[hID][bInteriorZ]+1, 20, BusinessInfo[hID][bVirtualWorld], 1);
	return hID;
}

forward FS_GiveBusinessMoney(shopid, money); 
public FS_GiveBusinessMoney(shopid, money) 
{ 
	if(BusinessInfo[shopid][bMoney] + money < 0) return 0;
	BusinessInfo[shopid][bMoney] += money;
	new filename[128];
	format(filename, 128, SHOP_FILE, shopid);
	INI_Open(filename);
	INI_WriteInt("Money", BusinessInfo[shopid][bMoney]);
	INI_Save();
	INI_Close();
	return 1; 
}

forward FS_GiveBusinessGoods(shopid, goods); 
public FS_GiveBusinessGoods(shopid, goods)
{
	if(!strcmp(BusinessInfo[shopid][bOwner], INVALID_OWNER, true)) return 1;
	if(BusinessInfo[shopid][bGoods] + goods < 0) return 0;
	BusinessInfo[shopid][bGoods] += goods;
	new filename[128];
	format(filename, 128, SHOP_FILE, shopid);
	INI_Open(filename);
	INI_WriteInt("Goods", BusinessInfo[shopid][bGoods]);
	INI_Save();
	INI_Close();
	return 1; 
}

forward FS_GetBusinessMoney(shopid); public FS_GetBusinessMoney(shopid) { return BusinessInfo[shopid][bMoney]; }
forward FS_GetBusinessGoods(shopid); public FS_GetBusinessGoods(shopid) { return BusinessInfo[shopid][bGoods]; }

stock BuyFurniture(playerid, houseid, modelid) // modelid is the furniture model id while fid is the instance id of a furniture.
{
	new fid = 0;
	while(fid < MAX_FURNITURE)
	{
		if(HouseInfo[houseid][FModel][fid] == INVALID_FURNITURE_ID) break;
		fid ++;
	}
	if(fid == MAX_FURNITURE || HouseInfo[houseid][FCount] >= MAX_FURNITURE) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "You can't buy anymore furniture.");
	HouseInfo[houseid][FCount] += 1;
	new fname[64]; format(fname, 64, HOUSE_FILE, houseid);
	new key[24];
	HouseInfo[houseid][FModel][fid] = modelid;
	GivePlayerMoney(playerid, -FurnitureInfo[modelid][1]);
	INI_Open(fname);
	INI_WriteInt("FCount", HouseInfo[houseid][FCount]);
	format(key, 24, "FModel%d", fid); INI_WriteInt(key, HouseInfo[houseid][FModel][fid]);
	INI_Save();
	INI_Close();
	ShowPlayerDialog(playerid, DIALOG_FURNITURE_BOUGHT, DIALOG_STYLE_MSGBOX, "{33AA33}Do you want to keep shopping?", "{33AA33}You bought a new furniture!\n{FFFFFF}To put it into your house open the menu and select \"Place/Edit furniture\".", "Continue", "Finish");
	return fid;
}

stock SaveFurniturePosition(houseid, furnid) // Furnid is the instance id of the furniture.
{
	new fname[64]; format(fname, 64, HOUSE_FILE, houseid);
	new key[32];
	INI_Open(fname);
	format(key, 24, "FPosX%d", furnid); INI_WriteFloat(key, HouseInfo[houseid][FPosX][furnid]);
	format(key, 24, "FPosY%d", furnid); INI_WriteFloat(key, HouseInfo[houseid][FPosY][furnid]);
	format(key, 24, "FPosZ%d", furnid); INI_WriteFloat(key, HouseInfo[houseid][FPosZ][furnid]);
	format(key, 24, "FRotX%d", furnid); INI_WriteFloat(key, HouseInfo[houseid][FRotX][furnid]);
	format(key, 24, "FRotY%d", furnid); INI_WriteFloat(key, HouseInfo[houseid][FRotY][furnid]);
	format(key, 24, "FRotZ%d", furnid); INI_WriteFloat(key, HouseInfo[houseid][FRotZ][furnid]);
	INI_Save();
	INI_Close();
	return 1;
}

stock OpenHouseDialog(playerid, houseid)
{
	if(!strcmp(HouseInfo[houseid][Owner], INVALID_OWNER, true)) // the house is for sale
	{
		new string[128];
		if(GetPlayerMoney(playerid) >= HouseInfo[houseid][Price]) format(string, 128, "{33AA33}Buy this house for %d$\n{33AA33}Visit this house", HouseInfo[houseid][Price]);
		else format(string, 128, "{FF0000}Buy this house for %d$\n{33AA33}Visit this house", HouseInfo[houseid][Price]);
		
		ShowPlayerDialog(playerid, DIALOG_FORSALE_HOUSE, DIALOG_STYLE_LIST, "{33AA33}House for sale!", string, "OK", "Close");
		return 1;
	}
	else // not for sale
	{
		new string[128];
		new string2[128];
		new name[24];
		GetPlayerName(playerid, name, 24);
		if(!strcmp(name, HouseInfo[houseid][Owner], true)) // The player is the owner
		{
			ShowPlayerDialog(playerid, DIALOG_MY_HOUSE, DIALOG_STYLE_LIST, "{33AA33}Owned House - Owner: you", "{33AA33}Enter your house\n{33AA33}Open/Close the door\n{33AA33}Sell your house", "OK", "Close");
			return 0;
		}
		else // The player is not the owner
		{
			format(string, 128, "{33AA33}Owned House - Owner: %s", HouseInfo[houseid][Owner]);
			if(HouseInfo[houseid][Locked] == 0) format(string2, 128, "{33AA33}Enter this house");
			else format(string2, 128, "{FF0000}Enter this house");
			ShowPlayerDialog(playerid, DIALOG_OTHERS_HOUSE, DIALOG_STYLE_LIST, string, string2, "OK", "Close");
			return -1;
		}
	}
}

stock OpenBusinessDialog(playerid, bizid)
{
	if(!strcmp(BusinessInfo[bizid][bOwner], INVALID_OWNER, true))
	{
		new string[128];
		if(GetPlayerMoney(playerid) >= BusinessInfo[bizid][bPrice]) format(string, 128, "{33AA33}Enter this store (%d$)\n{33AA33}Buy this store for %d$", BusinessInfo[bizid][bEarning], BusinessInfo[bizid][bPrice]);
		else format(string, 128, "{33AA33}Enter this store (%d$)\n{FF0000}Buy this store for %d$", BusinessInfo[bizid][bEarning], BusinessInfo[bizid][bPrice]);
		
		ShowPlayerDialog(playerid, DIALOG_FORSALE_BIZ, DIALOG_STYLE_LIST, "{33AA33}Store for sale!", string, "OK", "Close");
		return 1;
	}
	else
	{
		new string[128];
		new string2[256];
		new name[24];
		GetPlayerName(playerid, name, 24);
		if(!strcmp(name, BusinessInfo[bizid][bOwner], true))
		{
			format(string, 128, "{33AA33}%s - Owner: you - Goods: %d - Earnings: %d$", BusinessInfo[bizid][bTitle], BusinessInfo[bizid][bGoods], BusinessInfo[bizid][bMoney]);
			format(string2, 256, "{33AA33}Enter your store\n{33AA33}Open/Close the store\n{33AA33}Sell your store");								 
			ShowPlayerDialog(playerid, DIALOG_MY_BIZ, DIALOG_STYLE_LIST, string, string2, "OK", "Close");
			return 0;
		}
		else
		{
			format(string, 128, "{33AA33}%s - Owner: %s", BusinessInfo[bizid][bTitle], BusinessInfo[bizid][bOwner]);
			if(BusinessInfo[bizid][bLocked] == 0 || GetPlayerMoney(playerid) >= BusinessInfo[bizid][bEarning]) format(string2, 256, "{33AA33}Enter this store (%d$)", BusinessInfo[bizid][bEarning]);
			else format(string2, 256, "{FF0000}Enter this store (%d$)", BusinessInfo[bizid][bEarning]);
			ShowPlayerDialog(playerid, DIALOG_OTHERS_BIZ, DIALOG_STYLE_LIST, string, string2, "OK", "Close");
			return -1;
		}
	}
}

stock ShowHouseMenu(playerid)
{
	return ShowPlayerDialog(playerid, DIALOG_HOUSE_MENU, DIALOG_STYLE_LIST, "{33AA33}House Menu", "Store money\nWithdraw money\nStore weapons\nCollect weapons\nPlace/Edit furniture\nBuy new furniture\nSell furniture", "OK", "Cancel");
}

stock ShowBusinessMenu(playerid)
{
	return ShowPlayerDialog(playerid, DIALOG_SHOP_MENU, DIALOG_STYLE_LIST, "{33AA33}Store Menu", "Rename your store\nCollect your earnings\nSupply goods for your store\nBuy an item from your store", "OK", "Cancel");
}

stock GetHouseID(playerid)
{
	for(new i=0; i<MAX_HOUSES; i++)
	{
		if(IsPlayerInRangeOfPoint(playerid, 1, HouseInfo[i][ExteriorX], HouseInfo[i][ExteriorY], HouseInfo[i][ExteriorZ]))
		{
			return i;
		}
	}
	return INVALID_HOUSE_ID;
}

stock GetShopID(playerid)
{
	for(new i=0; i<MAX_SHOPS; i++)
	{
		if(IsPlayerInRangeOfPoint(playerid, 1, BusinessInfo[i][bExteriorX], BusinessInfo[i][bExteriorY], BusinessInfo[i][bExteriorZ]))
		{
			return i;
		}
	}
	return INVALID_HOUSE_ID;
}

stock BuyHouse(playerid, houseid)
{
	new string[64];
	new name[24];
	GetPlayerName(playerid, name, 24);
	GivePlayerMoney(playerid, -HouseInfo[houseid][Price]);
	format(HouseInfo[houseid][Owner], 24, name);
	HouseInfo[houseid][Locked] = 0;
	format(string, 64, HOUSE_FILE, houseid);
	INI_Open(string);
	INI_WriteString("Owner", HouseInfo[houseid][Owner]);
	INI_WriteInt("Locked", HouseInfo[houseid][Locked]);
	INI_Save();
	INI_Close();
	
	DestroyDynamicPickup(HousePickup[houseid]);
	HousePickup[houseid] = CreateDynamicPickup(1318, 23, HouseInfo[houseid][ExteriorX], HouseInfo[houseid][ExteriorY], HouseInfo[houseid][ExteriorZ]);
	#if MAP_ICONS == 1
	DestroyDynamicMapIcon(HouseIcon[houseid]);
	HouseIcon[houseid] = CreateDynamicMapIcon(HouseInfo[houseid][ExteriorX], HouseInfo[houseid][ExteriorY], HouseInfo[houseid][ExteriorZ], 32, 0, _, _, _, 800.0);
	#endif
	
	#if CONSOLE == 1
	printf("Player %s(%d) bought house ID %d.", name, playerid, houseid);
	#endif
	FS_MsgBox(playerid, "{33AA33}ACTION", "You bought this house.");
	return 1;
}

stock BuyShop(playerid, shopid)
{
	new string[64];
	new name[24];
	GetPlayerName(playerid, name, 24);
	GivePlayerMoney(playerid, -BusinessInfo[shopid][bPrice]);
	format(BusinessInfo[shopid][bOwner], 24, name);
	BusinessInfo[shopid][bLocked] = 0;
	format(string, 64, SHOP_FILE, shopid);
	INI_Open(string);
	INI_WriteString("Owner", BusinessInfo[shopid][bOwner]);
	INI_WriteInt("Locked", BusinessInfo[shopid][bLocked]);
	INI_Save();
	INI_Close();
	DestroyDynamicPickup(BusinessPickup[shopid]);
	BusinessPickup[shopid] = CreateDynamicPickup(1318, 23, BusinessInfo[shopid][bExteriorX], BusinessInfo[shopid][bExteriorY], BusinessInfo[shopid][bExteriorZ]);
	#if CONSOLE == 1
	printf("Player %s(%d) bought store ID %d.", name, playerid, shopid);
	#endif
	FS_MsgBox(playerid, "{33AA33}ACTION", "You bought this store.");
	return 1;
}

stock SellHouse(playerid, houseid)
{
	new string[256];
	new name[24];
	GetPlayerName(playerid, name, 24);
	GivePlayerMoney(playerid, floatround(HouseInfo[houseid][Price]*SELL_MULTIPLIER));
	format(HouseInfo[houseid][Owner], 24, INVALID_OWNER);
	HouseInfo[houseid][Locked] = 1;
	format(string, 256, HOUSE_FILE, houseid);
	INI_Open(string);
	INI_WriteString("Owner", HouseInfo[houseid][Owner]);
	INI_WriteInt("Locked", HouseInfo[houseid][Locked]);
	INI_Save();
	INI_Close();
	
	DestroyDynamicPickup(HousePickup[houseid]);
	HousePickup[houseid] = CreateDynamicPickup(1273, 23, HouseInfo[houseid][ExteriorX], HouseInfo[houseid][ExteriorY], HouseInfo[houseid][ExteriorZ]);
	#if MAP_ICONS == 1
	DestroyDynamicMapIcon(HouseIcon[houseid]);
	HouseIcon[houseid] = CreateDynamicMapIcon(HouseInfo[houseid][ExteriorX], HouseInfo[houseid][ExteriorY], HouseInfo[houseid][ExteriorZ], 31, 0, _, _, _, 800.0);
	#endif

	#if CONSOLE == 1
	printf("Player %s(%d) sold house ID %d.", name, playerid, houseid);
	#endif
	FS_MsgBox(playerid, "{33AA33}ACTION", "You sold this house.");
	return 1;
}

stock SellShop(playerid, shopid)
{
	new string[256];
	new name[24];
	GetPlayerName(playerid, name, 24);
	GivePlayerMoney(playerid, floatround(BusinessInfo[shopid][bPrice]*SELL_MULTIPLIER));
	format(BusinessInfo[shopid][bOwner], 24, INVALID_OWNER);
	BusinessInfo[shopid][bLocked] = 1;
	format(string, 256, SHOP_FILE, shopid);
	INI_Open(string);
	INI_WriteString("Owner", BusinessInfo[shopid][bOwner]);
	INI_WriteInt("Locked", BusinessInfo[shopid][bLocked]);
	INI_Save();
	INI_Close();
	DestroyDynamicPickup(BusinessPickup[shopid]);
	BusinessPickup[shopid] = CreateDynamicPickup(1272, 23, BusinessInfo[shopid][bExteriorX], BusinessInfo[shopid][bExteriorY], BusinessInfo[shopid][bExteriorZ]);
	#if CONSOLE == 1
	printf("Player %s(%d) sold store ID %d.", name, playerid, shopid);
	#endif
	FS_MsgBox(playerid, "{33AA33}ACTION", "You sold this store.");
	return 1;
}

forward player_unfreeze(playerid);
public player_unfreeze(playerid) { return TogglePlayerControllable(playerid, true); }

stock EnterHouse(playerid, houseid)
{
	SetPlayerPos(playerid, HouseInfo[houseid][InteriorX], HouseInfo[houseid][InteriorY], HouseInfo[houseid][InteriorZ]);
	SetPlayerInterior(playerid, HouseInfo[houseid][Interior]);
	SetPlayerVirtualWorld(playerid, HouseInfo[houseid][VirtualWorld]);
	SetLastHouse(playerid, houseid);
	TogglePlayerControllable(playerid, false);
	GameTextForPlayer(playerid, "~r~Please Wait", 2000, 5);
	SetTimerEx("player_unfreeze", 2000, false, "i", playerid);
	return 1;
}

stock EnterShop(playerid, shopid)
{
	SetPlayerPos(playerid, BusinessInfo[shopid][bInteriorX], BusinessInfo[shopid][bInteriorY], BusinessInfo[shopid][bInteriorZ]);
	SetPlayerInterior(playerid, BusinessInfo[shopid][bInterior]);
	SetPlayerVirtualWorld(playerid, BusinessInfo[shopid][bVirtualWorld]);
	SetLastShop(playerid, shopid);
	return 1;
}

forward ExitHouse(playerid, houseid);
public ExitHouse(playerid, houseid)
{
	SetPlayerPos(playerid, HouseInfo[houseid][ExteriorX], HouseInfo[houseid][ExteriorY], HouseInfo[houseid][ExteriorZ]);
	SetPlayerInterior(playerid, HouseInfo[houseid][Exterior]);
	SetPlayerVirtualWorld(playerid, 0);
	SetLastHouse(playerid, INVALID_HOUSE_ID);
	KillTimer(pVisitTimer[playerid]);
	return 1;
}

stock ExitShop(playerid, shopid)
{
	SetPlayerPos(playerid, BusinessInfo[shopid][bExteriorX], BusinessInfo[shopid][bExteriorY], BusinessInfo[shopid][bExteriorZ]);
	SetPlayerInterior(playerid, BusinessInfo[shopid][bExterior]);
	SetPlayerVirtualWorld(playerid, 0);
	SetLastShop(playerid, INVALID_HOUSE_ID);
	return 1;
}

stock LockUnlockHouse(playerid, houseid)
{
	if(HouseInfo[houseid][Locked] == 0) 
	{
		HouseInfo[houseid][Locked] = 1;
		FS_MsgBox(playerid, BOX_STYLE_CMD, "House {FF0000}locked");
	}
	else 
	{
		HouseInfo[houseid][Locked] = 0;
		FS_MsgBox(playerid, BOX_STYLE_CMD, "House {33AA33}unlocked");
	}
	new string[128];
	format(string, 128, HOUSE_FILE, houseid);
	INI_Open(string);
	INI_WriteInt("Locked", HouseInfo[houseid][Locked]);
	INI_Save();
	INI_Close();
	return 1;
}

stock LockUnlockShop(playerid, shopid)
{
	if(BusinessInfo[shopid][bLocked] == 0)
	{
		BusinessInfo[shopid][bLocked] = 1;
		FS_MsgBox(playerid, BOX_STYLE_CMD, "Store {FF0000}locked");
	}
	else 
	{
		BusinessInfo[shopid][bLocked] = 0;
		FS_MsgBox(playerid, BOX_STYLE_CMD, "Store {33AA33}unlocked");
	}
	new string[128];
	format(string, 128, SHOP_FILE, shopid);
	INI_Open(string);
	INI_WriteInt("Locked", BusinessInfo[shopid][bLocked]);
	INI_Save();
	INI_Close();
	return 1;
}

stock GetEarnings(playerid, shopid)
{
	if(BusinessInfo[shopid][Money] <= 0) return FS_MsgBox(playerid, BOX_STYLE_ERROR, "The cash register is empty!");
	new string[64];
	GivePlayerMoney(playerid, BusinessInfo[shopid][Money]);
	format(string, 64, "You withdrew %d$!", BusinessInfo[shopid][Money]);
	FS_MsgBox(playerid, "{33AA33}ACTION", string);
	BusinessInfo[shopid][bMoney] = 0;
	format(string, 64, SHOP_FILE, shopid);
	INI_Open(string);
	INI_WriteInt("Money", BusinessInfo[shopid][Money]);
	INI_Save();
	INI_Close();
	return 1;
}

stock AddEarnings(shopid, money)
{
	BusinessInfo[shopid][bMoney] += money;
	new string[64];
	format(string, 64, SHOP_FILE, shopid);
	INI_Open(string);
	INI_WriteInt("Money", BusinessInfo[shopid][Money]);
	INI_Save();
	INI_Close();
	return 1;
}

stock ShowFurnitureMenu(playerid)
{
	new bigstring[2048];
	new string[64];
	new money = GetPlayerMoney(playerid);
	new i = 1;
	while(i < FURNITURE_NUMBER)
	{
		if(money >= FurnitureInfo[i][1]) format(string, 64, "{33AA33}%s - %d$", FurnitureInfo[i][2], FurnitureInfo[i][1]);
		else format(string, 64, "{FF0000}%s - %d$", FurnitureInfo[i][2], FurnitureInfo[i][1]);
		format(bigstring, sizeof(bigstring), "%s%s\n", bigstring, string);
		i++;
	}
	ShowPlayerDialog(playerid, DIALOG_BUY_FURNITURE, DIALOG_STYLE_LIST, "{33AA33}Buy a new furniture!", bigstring, "Buy", "Cancel");
	return 1;
}

stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
    new Float:a;
    GetPlayerPos(playerid, x, y, a);
    GetPlayerFacingAngle(playerid, a);
    if (GetPlayerVehicleID(playerid))
    {
      GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
    }
    x += (distance * floatsin(-a, degrees));
    y += (distance * floatcos(-a, degrees));
}

stock strtok(const string[], &index) 
{
	new length = strlen(string);
	while ((index < length) && (string[index] <= ' '))
	{
		index++;
	}

	new offset = index;
	new result[20];
	while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}
 
stock strrest(const string[], &index)
{
	new length = strlen(string);
	while ((index < length) && (string[index] <= ' '))
	{
		index++;
	}
	new offset = index;
	new result[128];
	while ((index < length) && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}