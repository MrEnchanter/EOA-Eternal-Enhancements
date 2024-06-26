version "3.7"

#include "actors/fancy_floors.zsc"
#include "actors/fancy_ceilings.zsc"
#include "actors/fancy_walls.zsc"

Class SpawnEnvActorHandler : EventHandler
{
	// In the interests of neatness, make each piece of the puzzle a different
	// function that can be easily commented out for debugging's sake
	override void WorldLoaded(WorldEvent e)
	{
		SpawnFloorActors();
		SpawnFloorActors_OldWay();
		SpawnCeilingActors();
		SpawnWallActors();
	}
	
	// Spawn stuff on the floor the "old way" (in the center of every sector,
	// regardless of whether that center is actually in the sector or not.
	// only useful for things that are very likely gonna be a square.
	// Devised by Gutawer!
	void SpawnFloorActors_OldWay()
	{
		for (int i = 0; i < level.Sectors.Size(); i++)
		{
			let c = level.Sectors[i].centerspot;
			Actor.Spawn("FancyEnvActorFloorOldWay", (c.x, c.y, level.Sectors[i].floorplane.ZAtPoint(c)));
		}
	}
	
	// Spawn Stuff on the floor in a "grid" across all playable map space.
	// Thanks to Gutawer, PhantomBeta and _Bryan for helping debug this!
	void SpawnFloorActors()
    {
        //32704
		int spamx = -32448;
		int spamy = 32448;
		int spamz = 0;
		
		Vector2 spam2 = (spamx, spamy);
		Vector3 spam3 = (spamx, spamy, spamz);
		
		while (spamy > -32448)
		{
			while (spamx < 32448)
			{
				spamz = Sector.pointInSector((spamx, spamy)).floorplane.zAtPoint((spamx, spamy));
				if (level.IsPointInMap(spam3))
				{
					Actor.Spawn("FancyEnvActorFloor", (spamx, spamy, spamz));
				}
				spamx += 128;
				spam3 = (spamx, spamy, spamz);
			}
			spamx = -32448;
			spamy -= 128;
		}
    }
	
	// Spawn Stuff on the ceiling. Same method as with SpawnFloorActors, just at
	// a larger grid size for the sake of performance.
	void SpawnCeilingActors()
    {
        //32704
		int spamx = -32448;
		int spamy = 32448;
		int spamz = 0;
		
		Vector2 spam2 = (spamx, spamy);
		Vector3 spam3 = (spamx, spamy, spamz);
		
		while (spamy > -32448)
		{
			while (spamx < 32448)
			{
				spamz = Sector.pointInSector((spamx, spamy)).floorplane.zAtPoint((spamx, spamy));
				if (level.IsPointInMap(spam3))
				{
					Actor.Spawn("FancyEnvActorCeiling", (spamx, spamy, spamz));
				}
				spamx += 256;
				spam3 = (spamx, spamy, spamz);
			}
			spamx = -32448;
			spamy -= 256;
		}
    }
	
	// Spawn stuff on walls. Specifically, in the middle of appropriate linedefs.
	// Thanks Nash and Phantombeta!
	void SpawnWallActors()
	{
		for (int i = 0; i < level.Lines.Size(); i++)
		{			
			Line l = level.Lines[i];
			int spamf = 0;
			int spamc = 0;

			// do front first, then back
			for (int ii = 0; ii < 2; ii++)
			{
				double lineLen = l.delta.Length ();
				Vector2 spawnCoords = level.Vec2Offset (l.v1.p, l.delta.Unit () * (lineLen * 0.5));
				spamc = Sector.pointInSector(spawnCoords).ceilingplane.zAtPoint(spawnCoords);
				spamf = Sector.pointInSector(spawnCoords).floorplane.zAtPoint(spawnCoords);
				
				/*
				if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture("PLANET1", TexMan.Type_Any))
				Actor.Spawn("FancyWallTestSound", (spawnCoords,(spamc - 32)));
				
				if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture("COMPUTE2", TexMan.Type_Any))
				Actor.Spawn("FancyWallTestSound", (spawnCoords,(spamc - (spamf * 0.5))));
				
				if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture("STEP6", TexMan.Type_Any))
				Actor.Spawn("FancyWallTestSound", (spawnCoords,spamf));
				*/
				
				// Plutonia Waterfall
				string WallWaterfall[8];
				WallWaterfall[0] = "WFALL1";
				WallWaterfall[1] = "WFALL2";
				WallWaterfall[2] = "WFALL3";
				WallWaterfall[3] = "WFALL4";
				// for WADSMOOSH
				WallWaterfall[4] = "PWFALL1";
				WallWaterfall[5] = "PWFALL2";
				WallWaterfall[6] = "PWFALL3";
				WallWaterfall[7] = "PWFALL4";
				for (int i = 0; i < 8; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallWaterfall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallWaterfall", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallWaterfall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallWaterfall", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallWaterfall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallWaterfall", (spawnCoords,spamf));
				}
				
				// Bloodfall
				string WallBloodfall[4];
				WallBloodfall[0] = "BFALL1";
				WallBloodfall[1] = "BFALL2";
				WallBloodfall[2] = "BFALL3";
				WallBloodfall[3] = "BFALL4";
				for (int i = 0; i < 4; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallBloodfall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallBloodfall", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallBloodfall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallBloodfall", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallBloodfall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallBloodfall", (spawnCoords,spamf));
				}
				
				// Doom 2 Slimefall
				string WallSlimefall[4];
				WallSlimefall[0] = "SFALL1";
				WallSlimefall[1] = "SFALL2";
				WallSlimefall[2] = "SFALL3";
				WallSlimefall[3] = "SFALL4";
				for (int i = 0; i < 4; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallSlimefall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallSlimefall", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallSlimefall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallSlimefall", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallSlimefall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallSlimefall", (spawnCoords,spamf));
				}
				
				// Lavafalls
				string WallLavafall[12];
				// ObAddon Lavafall. Probably other lavafalls, too...
				WallLavafall[0] = "LFALL1";
				WallLavafall[1] = "LFALL2";
				WallLavafall[2] = "LFALL3";
				WallLavafall[3] = "LFALL4";
				WallLavafall[4] = "LFAL21";
				WallLavafall[5] = "LFAL22";
				WallLavafall[6] = "LFAL23";
				WallLavafall[7] = "LFAL24";
				// CC4 Tex
				WallLavafall[8] = "LAVFALL1";
				WallLavafall[9] = "LAVFALL2";
				WallLavafall[10] = "LAVFALL3";
				WallLavafall[11] = "LAVFALL4";
				for (int i = 0; i < 12; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallLavafall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallLavafall", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallLavafall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallLavafall", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallLavafall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallLavafall", (spawnCoords,spamf));
				}
				
				
				// Doom 1 Slimedrip
				string WallSlimedrip[3];
				WallSlimedrip[0] = "SLADRIP1";
				WallSlimedrip[1] = "SLADRIP2";
				WallSlimedrip[2] = "SLADRIP3";
				for (int i = 0; i < 3; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallSlimedrip[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallSlimedrip", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallSlimedrip[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallSlimedrip", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallSlimedrip[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallSlimedrip", (spawnCoords,spamf));
				}
				
				// Gargoyle Blood Fountain
				string WallGargfont[3];
				WallGargfont[0] = "GSTFONT1";
				WallGargfont[1] = "GSTFONT2";
				WallGargfont[2] = "GSTFONT3";
				for (int i = 0; i < 3; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallGargfont[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallGargfont", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallGargfont[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallGargfont", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallGargfont[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallGargfont", (spawnCoords,spamf));
				}
				
				// Compstation
				string WallCompstation[7];
				WallCompstation[0] = "COMPSTA1";
				WallCompstation[1] = "COMPSTA2";
				// CC4 Tex
				WallCompstation[2] = "COMPSTA3";
				WallCompstation[3] = "COMPSTA4";
				WallCompstation[4] = "COMPSTA5";
				WallCompstation[5] = "COMPSTA6";
				WallCompstation[6] = "COMPTALR";
				for (int i = 0; i < 7; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallCompstation[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallCompstation", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallCompstation[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallCompstation", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallCompstation[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallCompstation", (spawnCoords,spamf));
				}
				
				// Fireblu
				string WallFireblu[2];
				WallFireblu[0] = "FIREBLU1";
				WallFireblu[1] = "FIREBLU2";
				for (int i = 0; i < 2; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallFireblu[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallFireblu", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallFireblu[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallFireblu", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallFireblu[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallFireblu", (spawnCoords,spamf));
				}
				
				// Firey Walls
				string WallFirewall[9];
				WallFirewall[0] = "FIREMAG1";
				WallFirewall[1] = "FIREMAG2";
				WallFirewall[2] = "FIREMAG3";
				WallFirewall[3] = "FIREWALL";
				WallFirewall[4] = "FIREWALA";
				WallFirewall[5] = "FIREWALB";
				WallFirewall[6] = "FIRELAVA";
				WallFirewall[7] = "FIRELAV2";
				WallFirewall[8] = "FIRELAV3";
				for (int i = 0; i < 9; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallFirewall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallFirewall", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallFirewall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallFirewall", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallFirewall[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallFirewall", (spawnCoords,spamf));
				}
				
				// Generic Hummy Tech
				string WallTechhum[9];
				WallTechhum[0] = "COMPTALL";
				WallTechhum[1] = "COMP2";
				WallTechhum[2] = "SPACEW3";
				WallTechhum[3] = "COMPUTE1";
				WallTechhum[4] = "PLANET1";
				// CC4 Tex
				WallTechhum[5] = "COMPUTE4";
				WallTechhum[6] = "COMPUTE7";
				WallTechhum[7] = "COMPUTE8";
				WallTechhum[8] = "COMPUTE9";
				for (int i = 0; i < 9; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallTechhum[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallTechhum", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallTechhum[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallTechhum", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallTechhum[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallTechhum", (spawnCoords,spamf));
				}
				
				// Wall-Based Lighting
				string WallLights[18];
				WallLights[0] = "LITE3";
				WallLights[1] = "LITE5";
				WallLights[2] = "LITEBLU1";
				WallLights[3] = "LITEBLU4";
				WallLights[4] = "BRICKLIT";
				WallLights[5] = "BSTONE3";
				WallLights[6] = "LITE2";
				WallLights[7] = "LITE96";
				WallLights[8] = "LITEMET";
				WallLights[9] = "LITERED";
				WallLights[10] = "LITESTON";
				WallLights[11] = "LITE4";
				WallLights[12] = "LITEGRN1";
				WallLights[13] = "LITERED1";
				WallLights[14] = "LITERED2";
				WallLights[15] = "LITEYEL1";
				WallLights[16] = "LITEYEL2";
				WallLights[17] = "LITEYEL3";
				for (int i = 0; i < 18; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallLights[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallLights", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallLights[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallLights", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallLights[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallLights", (spawnCoords,spamf));
				}
				
				// CCTEX4/ObAddon Static Monitor
				string WallStatic[4];
				WallStatic[0] = "COMPFUZ1";
				WallStatic[1] = "COMPFUZ2";
				WallStatic[2] = "COMPFUZ3";
				WallStatic[3] = "COMPFUZ4";
				for (int i = 0; i < 4; i++)
				{
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture(WallStatic[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallStatic", (spawnCoords,(spamc - 32)));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture(WallStatic[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallStatic", (spawnCoords,(spamc - (spamf * 0.5))));
					if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture(WallStatic[i], TexMan.Type_Any))
					Actor.Spawn("FancyWallStatic", (spawnCoords,spamf));
				}
				
				// One-Offs
				// Creepy Face Texture
				if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.top) == TexMan.CheckForTexture("SP_FACE1", TexMan.Type_Any))
				Actor.Spawn("FancyWallFaces", (spawnCoords,(spamc - 32)));
				if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.mid) == TexMan.CheckForTexture("SP_FACE1", TexMan.Type_Any))
				Actor.Spawn("FancyWallFaces", (spawnCoords,(spamc - (spamf * 0.5))));
				if (l.sidedef[ii] && l.sidedef[ii].GetTexture(Side.bottom) == TexMan.CheckForTexture("SP_FACE1", TexMan.Type_Any))
				Actor.Spawn("FancyWallFaces", (spawnCoords,spamf));
			}
		}
	}
}

class FancyEnvActorFloor : Actor
{
	Default
	{
		-SOLID
		+DONTSPLASH
		+NOTELEPORT
		+NOCLIP
		+NOBLOCKMAP
		RenderStyle "None";
		radius 1;
		height 1;
	}
	
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0
		{
			// this is marginally less dumb than last time
			
			// Nukage
			string FloorNukage[4];
			FloorNukage[0] = "NUKAGE1";
			FloorNukage[1] = "NUKAGE2";
			FloorNukage[2] = "NUKAGE3";
			FloorNukage[3] = "NUKAGE4";

			for (int i = 0; i < 4; i++)
			{
				if (floorpic == TexMan.CheckForTexture(FloorNukage[i], TexMan.Type_Any))
				{
					if (!CountProximity ("FancySectorNukageCore", 256))
					{
						A_SpawnItem("FancySectorNukageCore");
					}
					A_SpawnItem("FancySectorNukage");		
				}
			}
			
			// Water
			string FloorWater[4];
			FloorWater[0] = "FWATER1";
			FloorWater[1] = "FWATER2";
			FloorWater[2] = "FWATER3";
			FloorWater[3] = "FWATER4";
			for (int i = 0; i < 4; i++)
			{
				if (floorpic == TexMan.CheckForTexture(FloorWater[i], TexMan.Type_Any))
					A_SpawnItem("FancySectorWaterCore");			
			}
			
			// Slime
			string FloorSlime[12];
			FloorSlime[0] = "SLIME01";
			FloorSlime[1] = "SLIME02";
			FloorSlime[2] = "SLIME03";
			FloorSlime[3] = "SLIME04";
			FloorSlime[4] = "SLIME05";
			FloorSlime[5] = "SLIME06";
			FloorSlime[6] = "SLIME07";
			FloorSlime[7] = "SLIME08";
			// ObAddon black oil sludge
			FloorSlime[8] = "SLUDGE01";
			FloorSlime[9] = "SLUDGE02";
			FloorSlime[10] = "SLUDGE03";
			FloorSlime[11] = "SLUDGE04";
			for (int i = 0; i < 12; i++)
			{
				if (floorpic == TexMan.CheckForTexture(FloorSlime[i], TexMan.Type_Any))
					A_SpawnItem("FancySectorSlimeCore");			
			}
				
			// Lava
			string FloorLava[8];
			FloorLava[0] = "LAVA1";
			FloorLava[1] = "LAVA2";
			FloorLava[2] = "LAVA3";
			FloorLava[3] = "LAVA4";
			// ObAddon Quake Lava
			FloorLava[4] = "QLAVA1";
			FloorLava[5] = "QLAVA2";
			FloorLava[6] = "QLAVA3";
			FloorLava[7] = "QLAVA4";
			for (int i = 0; i < 8; i++)
			{
				if (floorpic == TexMan.CheckForTexture(FloorLava[i], TexMan.Type_Any))
				{
					
					if (!CountProximity ("FancySectorLavaCore", 256))
					{
						A_SpawnItem("FancySectorLavaCore");
					}
					A_SpawnItem("FancySectorLava");
				}		
			}
				
			// Blood
			string FloorBlood[4];
			FloorBlood[0] = "BLOOD1";
			FloorBlood[1] = "BLOOD2";
			FloorBlood[2] = "BLOOD3";
			FloorBlood[3] = "BLOOD4";
			for (int i = 0; i < 4; i++)
			{
				if (floorpic == TexMan.CheckForTexture(FloorBlood[i], TexMan.Type_Any))
					A_SpawnItem("FancySectorSlimeCore");			
			}
				
			// Hot
			string FloorHot[4];
			FloorHot[0] = "SLIME09";
			FloorHot[1] = "SLIME10";
			FloorHot[2] = "SLIME11";
			FloorHot[3] = "SLIME12";
			for (int i = 0; i < 4; i++)
			{
				if (floorpic == TexMan.CheckForTexture(FloorHot[i], TexMan.Type_Any))
					A_SpawnItem("FancySectorHotCore");			
			}
			
			// XWATER from ObAddon
			string FloorXWater[4];
			FloorXWater[0] = "XWATER1";
			FloorXWater[1] = "XWATER2";
			FloorXWater[2] = "XWATER3";
			FloorXWater[3] = "XWATER4";
			for (int i = 0; i < 4; i++)
			{
				if (floorpic == TexMan.CheckForTexture(FloorXWater[i], TexMan.Type_Any))
					A_SpawnItem("FancySectorXWaterCore");			
			}
		}
		Stop;
	Remove:
		TNT1 A 0;
		stop;
	}
}

class FancyEnvActorFloorOldWay : Actor
{
	Default
	{
		-SOLID
		+DONTSPLASH
		+NOTELEPORT
		+NOCLIP
		+NOBLOCKMAP
		RenderStyle "None";
		radius 1;
		height 1;
	}
	
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0
		{
			// Floor Teleporter
			string FloorTeleporter[10];
			FloorTeleporter[0] = "GATE1";
			FloorTeleporter[1] = "GATE2";
			FloorTeleporter[2] = "GATE3";
			FloorTeleporter[3] = "GATE4";
			// CC4 Tex
			FloorTeleporter[4] = "GATE3TN";
			FloorTeleporter[5] = "GATE4BL";
			FloorTeleporter[6] = "GATE4GN";
			FloorTeleporter[7] = "GATE4OR";
			FloorTeleporter[8] = "GATE4RD";
			FloorTeleporter[9] = "GATE4YL";
			for (int i = 0; i < 10; i++)
			{
				if (floorpic == TexMan.CheckForTexture(FloorTeleporter[i], TexMan.Type_Any))
					A_SpawnItem("FancySectorTeleporterCore");			
			}
		}
		Stop;
	Remove:
		TNT1 A 0;
		stop;
	}
}

class FancyEnvActorCeiling : Actor
{
	Default
	{
		-SOLID
		+DONTSPLASH
		+NOTELEPORT
		+NOCLIP
		+NOBLOCKMAP
		RenderStyle "None";
		radius 1;
		height 1;
	}
	
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0
		{
			// back to the dumb ways
			if (ceilingpic == TexMan.CheckForTexture("F_SKY1", TexMan.Type_Any))
				A_SpawnItem("FancySectorSky");	
				
			// Generic Ceiling Lights
			string CeilingLights[10];
			CeilingLights[0] = "CEIL1_2";
			CeilingLights[1] = "CEIL1_3";
			CeilingLights[2] = "CEIL3_6";
			CeilingLights[3] = "FLAT2";
			CeilingLights[4] = "FLAT17";
			CeilingLights[5] = "GRNLITE1";
			CeilingLights[6] = "TLITE6_1";
			CeilingLights[7] = "TLITE6_4";
			CeilingLights[8] = "TLITE6_5";
			CeilingLights[9] = "TLITE6_6";
			for (int i = 0; i < 10; i++)
			{
				if (ceilingpic == TexMan.CheckForTexture(CeilingLights[i], TexMan.Type_Any))
					A_SpawnItem("FancySectorCeilingLite");			
			}
		}
		Stop;
	}
}