//Cheat Managers are now separated to help make maintaining them easier. 
//This class contains all base commands contained in the Unreal CheatManager
//These are included in this mod to ensure all are unlocked for non-editor final release use.
class Yoshi_ConsoleCommandsPlus_CheatManager_Unreal extends Hat_CheatManager
    abstract;

//Broadcast doesn't work so we use this, which is literally just Broadcast.
static final function Print(coerce string msg)
{
    local WorldInfo wi;

	msg = "[CCP] " $ msg;

    wi = class'WorldInfo'.static.GetWorldInfo();
    if (wi != None)
    {
        if (wi.GetALocalPlayerController() != None)
            wi.GetALocalPlayerController().TeamMessage(None, msg, 'Event', 6);
        else
            wi.Game.Broadcast(wi, msg);
    }
}

//CheatManager
/**
 *	Finds the nearest pawn of the given class (excluding the owner's pawn) and
 *	plays the specified FaceFX animation.
 */
exec function FXPlay(class<Pawn> aClass, string FXAnimPath)
{
	local Pawn P, ClosestPawn;
	local float ThisDistance, ClosestPawnDistance;
	local string FxAnimGroup;
	local string FxAnimName;
	local int dotPos;

	if ( WorldInfo.NetMode == NM_Standalone )
	{
		ClosestPawn = None;
		ClosestPawnDistance = 10000000.0;
		ForEach DynamicActors(class'Pawn', P)
		{
			if( ClassIsChildOf(P.class, aClass) && (P != PlayerController(Owner).Pawn) )
			{
				ThisDistance = VSize(P.Location - PlayerController(Owner).Pawn.Location);
				if(ThisDistance < ClosestPawnDistance)
				{
					ClosestPawn = P;
					ClosestPawnDistance = ThisDistance;
				}
			}
		}

		if( ClosestPawn.Mesh != none )
	    {
			dotPos = InStr(FXAnimPath, ".");
			if( dotPos != -1 )
			{
				FXAnimGroup = Left(FXAnimPath, dotPos);
				FXAnimName  = Right(FXAnimPath, Len(FXAnimPath) - dotPos - 1);
				ClosestPawn.Mesh.PlayFaceFXAnim(None, FXAnimName, FXAnimGroup, none);
			}
	    }
	}
}

/**
 *	Finds the nearest pawn of the given class (excluding the owner's pawn) and
 *	stops any currently playing FaceFX animation.
 */
exec function FXStop(class<Pawn> aClass)
{
	local Pawn P, ClosestPawn;
	local float ThisDistance, ClosestPawnDistance;

	if ( WorldInfo.NetMode == NM_StandAlone )
	{
		ClosestPawn = None;
		ClosestPawnDistance = 10000000.0;
		ForEach DynamicActors(class'Pawn', P)
		{
			if( ClassIsChildOf(P.class, aClass) && (P != PlayerController(Owner).Pawn) )
			{
				ThisDistance = VSize(P.Location - PlayerController(Owner).Pawn.Location);
				if(ThisDistance < ClosestPawnDistance)
				{
					ClosestPawn = P;
					ClosestPawnDistance = ThisDistance;
				}
			}
		}

		if( ClosestPawn.Mesh != none )
	    {
			ClosestPawn.Mesh.StopFaceFXAnim();
		}
	}
}

exec function EditAIByTrace()
{
	local Vector CamLoc;
	local Rotator CamRot;
	local Vector HitLocation, HitNormal;
	local Pawn HitPawn;
	local Controller C;
	
	GetPlayerViewPoint( CamLoc, CamRot );
	HitPawn = Pawn(Trace( HitLocation, HitNormal, CamLoc + Vector(CamRot) * 10000, CamLoc, TRUE, vect(10,10,10) ));
	if( HitPawn != None )
	{
		C = HitPawn.Controller;
		if( C == None && HitPawn.DrivenVehicle != None )
		{
			C = HitPawn.DrivenVehicle.Controller;
		}

		if( C != None )
		{
			ConsoleCommand( "EDITACTOR NAME="$C.Name, TRUE );
		}		
	}
}

/** Dumps the pause state of the game */
exec function DebugPause()
{
	WorldInfo.Game.DebugPause();
}

exec function ListDynamicActors()
{
	local Actor A;
	local int i;

	ForEach DynamicActors(class'Actor',A)
	{
		i++;
		Print(i@A);
	}
	Print("Num dynamic actors: "$i);
}

exec function FreezeFrame(float delay)
{
	WorldInfo.Game.SetPause(Outer,Outer.CanUnpause);
	WorldInfo.PauseDelay = WorldInfo.TimeSeconds + delay;
}

exec function WriteToLog( string Param )
{
	Print("NOW! "$Param);
}

exec function KillViewedActor()
{
	if ( ViewTarget != None )
	{
		if ( (Pawn(ViewTarget) != None) && (Pawn(ViewTarget).Controller != None) )
			Pawn(ViewTarget).Controller.Destroy();
		ViewTarget.Destroy();
		SetViewTarget(None);
	}
}

/* Teleport()
Teleport to surface player is looking at
*/
exec function Teleport()
{
	local Actor		HitActor;
	local vector	HitNormal, HitLocation;
	local vector	ViewLocation;
	local rotator	ViewRotation;

	GetPlayerViewPoint( ViewLocation, ViewRotation );

	HitActor = Trace(HitLocation, HitNormal, ViewLocation + 1000000 * vector(ViewRotation), ViewLocation, true);
	if ( HitActor != None)
		HitLocation += HitNormal * 4.0;

	ViewTarget.SetLocation( HitLocation );
}

/*
Scale the player's size to be F * default size
*/
exec function ChangeSize( float F )
{
	Pawn.CylinderComponent.SetCylinderSize( Pawn.Default.CylinderComponent.CollisionRadius * F, Pawn.Default.CylinderComponent.CollisionHeight * F );
	Pawn.SetDrawScale(F);
	Pawn.SetLocation(Pawn.Location);
}

exec function Amphibious()
{
	Pawn.UnderwaterTime = +999999.0;
}

exec function Slomo( float T )
{
	WorldInfo.Game.SetGameSpeed(T);
}

exec function SetJumpZ( float F )
{
	Pawn.JumpZ = F;
}

exec function SetGravity( float F )
{
	WorldInfo.WorldGravityZ = F;
}

exec function SetSpeed( float F )
{
	Pawn.GroundSpeed = Pawn.Default.GroundSpeed * f;
	Pawn.WaterSpeed = Pawn.Default.WaterSpeed * f;
}

exec function KillAll(class<actor> aClass)
{
	local Actor A;
	local PlayerController PC;

	foreach WorldInfo.AllControllers(class'PlayerController', PC)
	{
		PC.ClientMessage("Killed all "$string(aClass));
	}

	if ( ClassIsChildOf(aClass, class'Pawn') )
	{
		KillAllPawns(class<Pawn>(aClass));
		return;
	}
	ForEach DynamicActors(class 'Actor', A)
		if ( ClassIsChildOf(A.class, aClass) )
			A.Destroy();
}

// Kill non-player pawns and their controllers
function KillAllPawns(class<Pawn> aClass)
{
	local Pawn P;

	ForEach DynamicActors(class'Pawn', P)
		if ( ClassIsChildOf(P.Class, aClass)
			&& !P.IsPlayerPawn() )
		{
			if ( P.Controller != None )
				P.Controller.Destroy();
			P.Destroy();
		}
}

exec function KillPawns()
{
	KillAllPawns(class'Pawn');
}

/**
 * Possess a pawn of the requested class
 */
exec function Avatar( name ClassName )
{
	local Pawn			P, TargetPawn, FirstPawn, OldPawn;
	local bool			bPickNextPawn;

	Foreach DynamicActors(class'Pawn', P)
	{
		if( P == Pawn )
		{
			bPickNextPawn = TRUE;
		}
		else if( P.IsA(ClassName) )
		{
			if( FirstPawn == None )
			{
				FirstPawn = P;
			}

			if( bPickNextPawn )
			{
				TargetPawn = P;
				break;
			}
		}
	}

	// if we went through the list without choosing a pawn, pick first available choice (loop)
	if( TargetPawn == None )
	{
		TargetPawn = FirstPawn;
	}

	if( TargetPawn != None )
	{
		// detach TargetPawn from its controller and kill its controller.
		TargetPawn.DetachFromController( TRUE );

		// detach player from current pawn and possess targetpawn
		if( Pawn != None )
		{
			OldPawn = Pawn;
			Pawn.DetachFromController();
		}

		Possess(TargetPawn, FALSE);

		// Spawn default controller for our ex-pawn (AI)
		if( OldPawn != None )
		{
			OldPawn.SpawnDefaultController();
		}
	}
	else
	{
		Print("Avatar: Couldn't find any Pawn to possess of class '" $ ClassName $ "'");
	}
}

exec function Summon( string ClassName )
{
	local class<actor> NewClass;
	local vector SpawnLoc;

	Print( "Fabricate " $ ClassName );
	NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class' ) );
	if( NewClass!=None )
	{
		if ( Pawn != None )
			SpawnLoc = Pawn.Location;
		else
			SpawnLoc = Location;
		Spawn( NewClass,,,SpawnLoc + 72 * Vector(Rotation) + vect(0,0,1) * 15 );
	}
}

/**
 * Give a specified weapon to the Pawn.
 * If weapon is not carried by player, then it is created.
 * Weapon given is returned as the function's return parmater.
 */
exec function Weapon GiveWeapon( String WeaponClassStr )
{
	Local Weapon		Weap;
	local class<Weapon> WeaponClass;

	WeaponClass = class<Weapon>(DynamicLoadObject(WeaponClassStr, class'Class'));
	Weap		= Weapon(Pawn.FindInventoryType(WeaponClass));
	if( Weap != None )
	{
		return Weap;
	}
	return Weapon(Pawn.CreateInventory( WeaponClass ));
}

exec function PlayersOnly()
{
	if (WorldInfo.bPlayersOnly || WorldInfo.bPlayersOnlyPending)
	{
		WorldInfo.bPlayersOnly = false;
		WorldInfo.bPlayersOnlyPending = false;
	}
	else
	{
		WorldInfo.bPlayersOnlyPending = !WorldInfo.bPlayersOnlyPending;
		// WorldInfo.bPlayersOnly is set after next tick of UWorld::Tick
	}	
}

exec function SuspendAI()
{
	WorldInfo.bSuspendAI = !WorldInfo.bSuspendAI;
}

/** Util for fracturing meshes within an area of the player. */
exec function DestroyFractures(optional float Radius)
{
	local FracturedStaticMeshActor FracActor;

	if(Radius == 0.0)
	{
		Radius = 256.0;
	}

	foreach CollidingActors(class'FracturedStaticMeshActor', FracActor, Radius, Pawn.Location, TRUE)
	{
		if(FracActor.Physics == PHYS_None)
		{
			// Make sure the impacted fractured mesh is visually relevant
			FracActor.BreakOffPartsInRadius(Pawn.Location, Radius, 500.0, TRUE);
		}
	}
}

/** Util for ensuring at least one piece is broken of each FSM in level */
exec function FractureAllMeshes()
{
	local FracturedStaticMeshActor FracActor;

	foreach AllActors(class'FracturedStaticMeshActor', FracActor)
	{
		FracActor.HideOneFragment();
	}
}

/** This will break all Fractured meshes in the map in a way to maximize memory usage **/
exec function FractureAllMeshesToMaximizeMemoryUsage()
{
	local FracturedStaticMeshActor FracActor;

	foreach AllActors(class'FracturedStaticMeshActor', FracActor)
	{
		FracActor.HideFragmentsToMaximizeMemoryUsage();
	}
}



// ***********************************************************
// Navigation Aids (for testing)

// remember spot for path testing (display path using ShowDebug)
exec function RememberSpot()
{
	if ( Pawn != None )
		SetDestinationPosition( Pawn.Location );
	else
		SetDestinationPosition( Location );
}

// ***********************************************************
// Changing viewtarget

exec function ViewSelf(optional bool bQuiet)
{
	Outer.ResetCameraMode();
	if ( Pawn != None )
		SetViewTarget(Pawn);
	else
		SetViewtarget(outer);
	if (!bQuiet )
		ClientMessage(OwnCamera, 'Event');

	FixFOV();
}

exec function ViewPlayer( string S )
{
	local Controller P;

	foreach WorldInfo.AllControllers(class'Controller', P)
	{
		if ( P.bIsPlayer && (P.PlayerReplicationInfo.PlayerName ~= S ) )
		{
			break;
		}
	}

	if ( P.Pawn != None )
	{
		ClientMessage(ViewingFrom@P.PlayerReplicationInfo.PlayerName, 'Event');
		SetViewTarget(P.Pawn);
	}
}

exec function ViewActor( name ActorName)
{
	local Actor A;

	ForEach AllActors(class'Actor', A)
		if ( A.Name == ActorName )
		{
			SetViewTarget(A);
	    SetCameraMode('ThirdPerson');
			return;
		}
}

exec function ViewBot()
{
	local actor first;
	local bool bFound;
	local AIController C;

	foreach WorldInfo.AllControllers(class'AIController', C)
	{
		if (C.Pawn != None && C.PlayerReplicationInfo != None)
		{
			if (bFound || first == None)
			{
				first = C;
				if (bFound)
				{
					break;
				}
			}
			if (C.PlayerReplicationInfo == RealViewTarget)
			{
				bFound = true;
			}
		}
	}

	if ( first != None )
	{
		Print("view "$first);
		SetViewTarget(first);
		SetCameraMode( 'ThirdPerson' );
		FixFOV();
	}
	else
		ViewSelf(true);
}

exec function ViewClass( class<actor> aClass )
{
	local actor other, first;
	local bool bFound;

	first = None;

	ForEach AllActors( aClass, other )
	{
		if ( bFound || (first == None) )
		{
			first = other;
			if ( bFound )
				break;
		}
		if ( other == ViewTarget )
			bFound = true;
	}

	if ( first != None )
	{
		if ( Pawn(first) != None )
			ClientMessage(ViewingFrom@First.GetHumanReadableName(), 'Event');
		else
			ClientMessage(ViewingFrom@first, 'Event');
		SetViewTarget(first);
		FixFOV();
	}
	else
		ViewSelf(false);
}

exec function Loaded()
{
	if( WorldInfo.Netmode!=NM_Standalone )
		return;

    AllWeapons();
    AllAmmo();
}

/** streaming level debugging */

function SetLevelStreamingStatus(name PackageName, bool bShouldBeLoaded, bool bShouldBeVisible)
{
	local PlayerController PC;
	local int i;

	if (PackageName != 'All')
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PC)
		{
			PC.ClientUpdateLevelStreamingStatus(PackageName, bShouldBeLoaded, bShouldBeVisible, FALSE );
		}
	}
	else
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PC)
		{
			for (i = 0; i < WorldInfo.StreamingLevels.length; i++)
			{
				PC.ClientUpdateLevelStreamingStatus(WorldInfo.StreamingLevels[i].PackageName, bShouldBeLoaded, bShouldBeVisible, FALSE );
			}
		}
	}
}

exec function StreamLevelIn(name PackageName)
{
	SetLevelStreamingStatus(PackageName, true, true);
}

exec function OnlyLoadLevel(name PackageName)
{
	SetLevelStreamingStatus(PackageName, true, false);
}

exec function StreamLevelOut(name PackageName)
{
	SetLevelStreamingStatus(PackageName, false, false);
}

/**
 * Logs the current session state for the game type and online layer
 */
exec function DumpOnlineSessionState()
{
	local int PlayerIndex;

	if (WorldInfo.NetMode != NM_Client)
	{
		Print("");
		Print("GameInfo state");
		Print("-------------------------------------------------------------");
		Print("");
		//Print game info data
		Print("Class: "$WorldInfo.Game.Class.Name);
		//Print player count information
		Print("  MaxPlayersAllowed: "$WorldInfo.Game.MaxPlayersAllowed);
		Print("  MaxPlayers: "$WorldInfo.Game.MaxPlayers);
		Print("  NumPlayers: "$WorldInfo.Game.NumPlayers);
		Print("  MaxSpectatorsAllowed: "$WorldInfo.Game.MaxSpectatorsAllowed);
		Print("  MaxSpectators: "$WorldInfo.Game.MaxSpectators);
		Print("  NumSpectators: "$WorldInfo.Game.NumSpectators);
		Print("  NumBots: "$WorldInfo.Game.NumBots);

		Print("  bUseSeamlessTravel: "$WorldInfo.Game.bUseSeamlessTravel);
		Print("  bRequiresPushToTalk: "$WorldInfo.Game.bRequiresPushToTalk);
		Print("  bHasNetworkError: "$WorldInfo.Game.bHasNetworkError);

		Print("  OnlineGameSettingsClass: "$WorldInfo.Game.OnlineGameSettingsClass);
		Print("  OnlineStatsWriteClass: "$WorldInfo.Game.OnlineStatsWriteClass);

		Print("  bUsingArbitration: "$WorldInfo.Game.bUsingArbitration);
		if (WorldInfo.Game.bUsingArbitration)
		{
			Print("  bHasArbitratedHandshakeBegun: "$WorldInfo.Game.bHasArbitratedHandshakeBegun);
			Print("  bNeedsEndGameHandshake: "$WorldInfo.Game.bNeedsEndGameHandshake);
			Print("  bIsEndGameHandshakeComplete: "$WorldInfo.Game.bIsEndGameHandshakeComplete);
			Print("  bHasEndGameHandshakeBegun: "$WorldInfo.Game.bHasEndGameHandshakeBegun);
			Print("  ArbitrationHandshakeTimeout: "$WorldInfo.Game.ArbitrationHandshakeTimeout);
			Print("  Number of pending arbitration PCs: "$WorldInfo.Game.PendingArbitrationPCs.Length);
			// List who we are waiting of for arbitration
			for (PlayerIndex = 0; PlayerIndex < WorldInfo.Game.PendingArbitrationPCs.Length; PlayerIndex++)
			{
				Print("    Player: "$WorldInfo.Game.PendingArbitrationPCs[PlayerIndex].PlayerReplicationInfo.PlayerName$" PC ("$WorldInfo.Game.PendingArbitrationPCs[PlayerIndex].Name$")");
			}
			Print("  Number of arbitration PCs: "$WorldInfo.Game.ArbitrationPCs.Length);
			// List all of the players that have completed arbitration
			for (PlayerIndex = 0; PlayerIndex < WorldInfo.Game.ArbitrationPCs.Length; PlayerIndex++)
			{
				Print("    Player: "$WorldInfo.Game.ArbitrationPCs[PlayerIndex].PlayerReplicationInfo.PlayerName$" PC ("$WorldInfo.Game.ArbitrationPCs[PlayerIndex].Name$")");
			}
		}
	}
	//Print PRI player info
	//DebugLogPRIs();
	//Print the online session state
	if (OnlineSub != None)
	{
		OnlineSub.DumpSessionState();
	}
}

/**
 * Changes the OS specific logging level
 *
 * @param DebugLevel the new debug level to use
 */
exec function SetOnlineDebugLevel(int DebugLevel)
{
	if (OnlineSub != None)
	{
		OnlineSub.SetDebugSpewLevel(DebugLevel);
	}
}

/**
 * tries to path from the player's current position to the position the player is looking at 
 *
 */
exec function TestNavMeshPath(optional bool bDrawPath=TRUE)
{
	local actor HitActor;
	local vector HitLoc,HitNorm, Start, End;
	local rotator Rot;

	if(NavigationHandle == none)
	{
		NavigationHandle = new(outer) class'NavigationHandle';
	}

	GetPlayerViewPoint(Start,Rot);
	End = Start + vector(rot) * 10000;

	HitActor = Trace(HitLoc,HitNorm,End,Start,false);
	if(HitActor != none)
	{ 
		class'NavmeshPath_Toward'.static.TowardPoint(NavigationHandle,HitLoc);
		class'NavMeshGoal_At'.static.AtLocation(NavigationHandle,HitLoc);
		
		NavigationHandle.bDebugConstraintsAndGoalEvals=true;
		NavigationHandle.bUltraVerbosePathDebugging=TRUE;
		if(NavigationHandle.FindPath())
		{
			DrawDebugLine(HitLoc,Start,0,255,0,TRUE);
			DrawDebugCoordinateSystem(HitLoc,rot(0,0,0),25.f,TRUE);
			if(bDrawPath)
			{
				NavigationHandle.DrawPathCache(,true);
			}
		}
		else
		{
			DrawDebugLine(HitLoc,Start,255,0,0,TRUE);
			DrawDebugCoordinateSystem(HitLoc,rot(0,0,0),25.f,TRUE);
			DrawDebugBox(Pawn.Location,Pawn.GetCollisionExtent(),255,0,0,TRUE);
		}
	}
}

exec function TestPylonConnectivity()
{
	local Pylon Py;
	foreach AllActors(class'Pylon',Py)
	{
		PY.VerifyTopLevelConnections();
	}
}

exec function VerbosePathDebug()
{
	local vector HitLoc,HitNorm, Start, End;
	local rotator Rot;
	local Pawn P;

	GetPlayerViewPoint(Start,Rot);
	End = Start + vector(rot) * 10000;

	foreach TraceActors(class'Pawn',P,HitLoc,HitNorm,End,Start,vect(1,1,1))
	{
		Pawn.MessagePlayer("Verbosepathdebug trace hit"@P);
		if(P != none && P.Controller != none)
		{
			P.Controller.NavigationHandle.bUltraVerbosePathDebugging=!P.Controller.NavigationHandle.bUltraVerbosePathDebugging;
		}
	}
}

/**
 * This will have all PlaySound function calls emit a warnf so you can see that name of 
 * the soundcue being played.
 **/
exec function LogPlaySoundCalls( bool bShouldLog ) {
	Super.LogPlaySoundCalls(bShouldLog);
}


/**
* This will have all ActivateSystem function calls emit a warnf so you can see that name of 
* the particlesystem being played.
**/
exec function LogParticleActivateSystemCalls( bool bShouldLog ) {
	Super.LogParticleActivateSystemCalls(bShouldLog);
}

/**
 * debug command, verifies that all path objects and path obstacls are valid 
 * (E.G.) that they haven't been deleted, but left registered
 */
exec function VerifyNavMeshObjects() {
	Super.VerifyNavMeshObjects();
}

/**
 * debug command, will draw all edges that are not supported for the passed pawn class
 */
exec function DrawUnsupportingEdges(coerce string PawnClassName) {
	Super.DrawUnsupportingEdges(PawnClassName);
}

/**
 * enables a timer to do periodic navmesh verification
 */
exec function NavMeshVerification(float interval=0.5)
{
	if(interval < 0)
	{
		ClearTimer(nameof(VerifyNavMeshObjects),outer);
	}
	else
	{
		SetTimer(interval,true,nameof(VerifyNavMeshObjects),outer);
	}
}

/**
 * debug command, prints all navmesh pathobject edges
 */
exec function PrintAllPathObjectEdges() {
	Super.PrintAllPathObjectEdges();
}

/**
 * debug command, prints all active navmesh obstaces
 */
exec function PrintNavMeshObstacles() {
	Super.PrintNavMeshObstacles();
}

/**
 * debug command, verifies all cover references
 */
exec function VerifyNavMeshCoverRefs() {
	Super.VerifyNavMeshCoverRefs();
}

/**
 * toggles AI logging
 */
exec function ToggleAILogging()
{
	local Engine Eng;
	Eng = class'Engine'.static.GetEngine();
	if(Pawn != none)
	{
		if( Eng.bDisableAILogging )
		{
			Pawn.MessagePlayer("OK! AI logging is now ON");
		}
		else
		{
			Pawn.MessagePlayer("OK! AI logging is now OFF");
		}
	}

	Eng.bDisableAILogging = !Eng.bDisableAILogging;

}

exec function DebugIniLocPatcher()
{
	if (OnlineSub != None &&
		OnlineSub.Patcher != None)
	{
		OnlineSub.Patcher.DownloadFiles();
	}
}

exec function DebugDownloadTitleFile(string Filename, optional bool bFromCache)
{
	if (OnlineSub != None)
	{
		if (bFromCache)
		{
			if (OnlineSub.TitleFileCacheInterface != None)
			{
				Print(`location @ "starting file load for"@Filename);

				OnlineSub.TitleFileCacheInterface.AddLoadTitleFileCompleteDelegate(OnLoadComplete);
				OnlineSub.TitleFileCacheInterface.LoadTitleFile(Filename);
			}
			else
			{
				Print(`location @ "OnlineTitleFileCacheInterface not supported");
			}
		}
		else
		{
			if (OnlineSub.TitleFileInterface != None)
			{
				Print(`location @ "starting file download request for"@Filename);

				OnlineSub.TitleFileInterface.AddReadTitleFileCompleteDelegate(OnDownloadComplete);
				OnlineSub.TitleFileInterface.ReadTitleFile(Filename);
			}
			else
			{
				Print(`location @ "OnlineTitleFileInterface not supported");
			}
		}
	}
}
function OnDownloadComplete(bool bWasSuccessful,string Filename)
{
	OnlineSub.TitleFileInterface.ClearReadTitleFileCompleteDelegate(OnDownloadComplete);

	Print(`location @ "download completed"
		@"bWasSuccessful="$bWasSuccessful
		@"FileName="$Filename);

	if (bWasSuccessful)
	{
		DebugSaveTitleFile(Filename);
	}
}
function OnLoadComplete(bool bWasSuccessful,string FileName)
{
	OnlineSub.TitleFileCacheInterface.ClearLoadTitleFileCompleteDelegate(OnLoadComplete);

	Print(`location @ "load completed"
		@"bWasSuccessful="$bWasSuccessful
		@"FileName="$Filename);

	DebugDownloadTitleFile(FileName,false);
}

exec function DebugSaveTitleFile(string Filename)
{
	local array<byte> FileContents;

	if (OnlineSub != None)
	{
		if (OnlineSub.TitleFileInterface != None)
		{
			if (OnlineSub.TitleFileInterface.GetTitleFileContents(Filename, FileContents))
			{
				Print(`location @ "found file in download cache. using file contents from download cache:"@Filename);						
			}
			else
			{
				Print(`location @ "couldn't find file in download cache:"@Filename);						
			}
		}
		else
		{
			Print(`location @ "OnlineTitleFileInterface not supported");
		}

		if (OnlineSub.TitleFileCacheInterface != None)
		{
			Print(`location @ "starting file save for"@Filename);

			OnlineSub.TitleFileCacheInterface.AddSaveTitleFileCompleteDelegate(OnSaveComplete);
			OnlineSub.TitleFileCacheInterface.SaveTitleFile(Filename, "TestName.ini", FileContents);		
		}
		else
		{
			Print(`location @ "OnlineTitleFileCacheInterface not supported");
		}
	}
}
function OnSaveComplete(bool bWasSuccessful,string FileName)
{
	OnlineSub.TitleFileCacheInterface.ClearSaveTitleFileCompleteDelegate(OnSaveComplete);

	Print(`location @ "save completed"
		@"bWasSuccessful="$bWasSuccessful
		@"FileName="$Filename);
}

exec function DebugDeleteTitleFiles()
{
	if (OnlineSub != None)
	{
		if (OnlineSub.TitleFileCacheInterface != None)
		{
			Print(`location @ "deleting all title files in cache dir");
			if (OnlineSub.TitleFileCacheInterface.DeleteTitleFiles(0))
			{
				Print(`location @ "delete succeeded");
			}
			else
			{
				Print(`location @ "cant delete. file ops in progress");
			}		
		}
		else
		{
			Print(`location @ "OnlineTitleFileCacheInterface not supported");
		}
	}
}

exec function DebugEmsDownload()
{
	if (OnlineSub != None &&
		OnlineSub.Patcher != None)
	{
		OnlineSub.Patcher.DownloadFiles();
	}
}

/**
 * debug command which prints out stats about memory usage by covernodes
 */
exec function DumpCoverStats() {
	Super.DumpCoverStats();
}

exec function DrawLocation(vector Loc)
{
	DrawDebugCoordinateSystem(Loc,rot(0,0,0),50.f,TRUE);
}

exec function DrawLocationXYZ(float X, Float Y, float Z)
{
	local vector DrawSpot;

	DrawSpot.X = X;
	DrawSpot.y = y;
	DrawSpot.z = z;
	DrawDebugCoordinateSystem(DrawSpot,rot(0,0,0),150.f,TRUE);
}

/**
 * Debug exec for scheduling a push notification
 *
 * @param MessageBody string to display in message box of notification
 * @param SecondsFromNow seconds to elapse before triggering the notification
 */
exec function DebugNotification(string MessageBody, int SecondsFromNow)
{
	local AppNotificationsBase AppNotification;
	local NotificationInfo NotificationInfo;
	local NotificationMessageInfo MessageInfo;

	AppNotification = class'PlatformInterfaceBase'.static.GetAppNotificationsInterface();
	if (AppNotification != None)
	{
		NotificationInfo.BadgeNumber = 1;
		NotificationInfo.MessageBody = MessageBody;

		MessageInfo.Key = "test key 1";
		MessageInfo.Value = "test val 1";
		NotificationInfo.MessageInfo.AddItem(MessageInfo);

		MessageInfo.Key = "test key 2";
		MessageInfo.Value = "test val 2";
		NotificationInfo.MessageInfo.AddItem(MessageInfo);

		Print(`location@""
			@" MessageBody="$MessageBody
			@" SecondsFromNow="$SecondsFromNow);

		AppNotification.OnReceivedLocalNotification = OnReceivedLocalNotificationDebug;
		AppNotification.ScheduleLocalNotification(NotificationInfo,SecondsFromNow);
	}
}
/**
 * Debug params from a local notification that was processed
 */
private function OnReceivedLocalNotificationDebug(const out NotificationInfo Notification, bool bWasAppActive)
{
	Print(`location@"bWasAppActive="$bWasAppActive);
	class'PlatformInterfaceBase'.static.GetAppNotificationsInterface().DebugLogNotification(Notification);
}

exec function DebugQueryUserFiles(string UserId)
{
	if (OnlineSub != None &&
		OnlineSub.UserCloudInterface != None)
	{
		OnlineSub.UserCloudInterface.AddEnumerateUserFileCompleteDelegate(OnEnumerateUserFilesComplete);
		OnlineSub.UserCloudInterface.EnumerateUserFiles(UserId);
	}
}

private function OnEnumerateUserFilesComplete(bool bWasSuccessful,string UserId)
{
	OnlineSub.UserCloudInterface.ClearEnumerateUserFileCompleteDelegate(OnEnumerateUserFilesComplete);

	ConsoleCommand("obj dump" @OnlineSub.UserCloudInterface.Name);

	Print(`location@""
		$" bWasSuccessful="$bWasSuccessful
		$" UserId="$UserId);
}

exec function DebugWriteUserFile(string UserId, string FileName)
{
	local int Idx;
	local array<byte> FileContents;

	if (OnlineSub != None &&
		OnlineSub.UserCloudInterface != None)
	{
		for (Idx=0; Idx < 1000; Idx++)
		{
			FileContents[Idx]=Idx;
		}
		OnlineSub.UserCloudInterface.AddWriteUserFileCompleteDelegate(OnWriteUserFileComplete);
		OnlineSub.UserCloudInterface.WriteUserFile(UserId,FileName,FileContents);
	}
}

private function OnWriteUserFileComplete(bool bWasSuccessful,string UserId,string FileName)
{
	OnlineSub.UserCloudInterface.ClearWriteUserFileCompleteDelegate(OnWriteUserFileComplete);

	ConsoleCommand("obj dump" @OnlineSub.UserCloudInterface.Name);

	Print(`location@""
		$" bWasSuccessful="$bWasSuccessful
		$" UserId="$UserId
		$" FileName="$FileName);
}

exec function DebugReadUserFile(string UserId, string FileName)
{
	if (OnlineSub != None &&
		OnlineSub.UserCloudInterface != None)
	{
		OnlineSub.UserCloudInterface.AddReadUserFileCompleteDelegate(OnReadUserFileComplete);
		OnlineSub.UserCloudInterface.ReadUserFile(UserId,FileName);
	}
}

private function OnReadUserFileComplete(bool bWasSuccessful,string UserId,string FileName)
{
	local array<byte> FileContents;

	OnlineSub.UserCloudInterface.ClearReadUserFileCompleteDelegate(OnReadUserFileComplete);
	OnlineSub.UserCloudInterface.GetFileContents(UserId,FileName,FileContents);

	ConsoleCommand("obj dump" @OnlineSub.UserCloudInterface.Name);

	Print(`location@""
		$" bWasSuccessful="$bWasSuccessful
		$" UserId="$UserId
		$" FileName="$FileName
		$" FileContents="$FileContents.Length);
}

exec function DebugDeleteUserFile(string UserId, string FileName)
{
	if (OnlineSub != None &&
		OnlineSub.UserCloudInterface != None)
	{
		OnlineSub.UserCloudInterface.AddDeleteUserFileCompleteDelegate(OnDeleteUserFileComplete);
		OnlineSub.UserCloudInterface.DeleteUserFile(UserId,FileName,true,true);
	}
}

private function OnDeleteUserFileComplete(bool bWasSuccessful,string UserId,string FileName)
{
	OnlineSub.UserCloudInterface.ClearDeleteUserFileCompleteDelegate(OnDeleteUserFileComplete);

	ConsoleCommand("obj dump" @OnlineSub.UserCloudInterface.Name);

	Print(`location@""
		$" bWasSuccessful="$bWasSuccessful
		$" UserId="$UserId
		$" FileName="$FileName);
}

defaultproperties
{
}

/**
 * Simple function to illustrate the use of the HttpRequest system.
 */
exec function TestHttp(string Verb, string Payload, string URL, optional bool bSendParallelRequest)
{
	local HttpRequestInterface R;

	// create the request instance using the factory (which handles
	// determining the proper type to create based on config).
	R = class'HttpFactory'.static.CreateRequest();
	// always set a delegate instance to handle the response.
	R.OnProcessRequestComplete = OnRequestComplete;
	Print("Created request");
	// you can make many requests from one request object.
	R.SetURL(URL);
	// Default verb is GET
	if (Len(Verb) > 0)
	{
		R.SetVerb(Verb);
	}
	else
	{
		Print("No Verb given, using the defaults.");
	}
	// Default Payload is empty
	if (Len(Payload) > 0)
	{
		R.SetContentAsString(Payload);
	}
	else
	{
		Print("No payload given.");
	}
	Print("Creating request for URL:"@URL);

	// there is currently no way to distinguish keys that are empty from keys that aren't there.
	Print("Key1 ="@R.GetURLParameter("Key1"));
	Print("Key2 ="@R.GetURLParameter("Key2"));
	Print("Key3NoValue ="@R.GetURLParameter("Key3NoValue"));
	Print("NonexistentKey ="@R.GetURLParameter("NonexistentKey"));
	// A header will not necessarily be present if you don't set one. Platform implementations
	// may add things like Content-Length when you send the request, but won't necessarily
	// be available in the Header.
	Print("NonExistentHeader ="@R.GetHeader("NonExistentHeader"));
	Print("CustomHeaderName ="@R.GetHeader("CustomHeaderName"));
	Print("ContentType ="@R.GetContentType());
	Print("ContentLength ="@R.GetContentLength());
	Print("URL ="@R.GetURL());
	Print("Verb ="@R.GetVerb());

	// multiple ProcessRequest calls can be made from the same instance if desired.
	if (!R.ProcessRequest())
	{
		Print("ProcessRequest failed. Unsuppress DevHttpRequest to see more details.");
	}
	else
	{
		Print("Request sent");
	}
	// send off a parallel request for testing.
	if (bSendParallelRequest)
	{
		if (!class'HttpFactory'.static.CreateRequest()
			.SetURL("http://www.epicgames.com")
			.SetVerb("GET")
			.SetHeader("Test", "Value")
			.SetProcessRequestCompleteDelegate(OnRequestComplete)
			.ProcessRequest())
		{
			Print("ProcessRequest for parallel request failed. Unsuppress DevHttpRequest to see more details.");
		}
		else
		{
			Print("Parallel Request sent");
		}
	}
}


/** Delegate to use for HttpResponses. */
function OnRequestComplete(HttpRequestInterface OriginalRequest, HttpResponseInterface Response, bool bDidSucceed)
{
	local array<String> Headers;
	local String Header;
	local String Payload;
	local int PayloadIndex;

	Print("Got response!!!!!!! Succeeded="@bDidSucceed);
	Print("URL="@OriginalRequest.GetURL());
	// if we didn't succeed, we can't really trust the payload, so you should always really check this.
	if (Response != None)
	{
		Print("ResponseURL="@Response.GetURL());
		Print("Response Code="@Response.GetResponseCode());
		Headers = Response.GetHeaders();
		foreach Headers(Header)
		{
			Print("Header:"@Header);
		}
		// GetContentAsString will make a copy of the payload to add the NULL terminator,
		// then copy it again to convert it to TCHAR, so this could be fairly inefficient.
		// This call also assumes the payload is UTF8 right now, as truly determining the encoding
		// is content-type dependent.
		// You also can't trust the content-length as you don't always get one. You should instead
		// always trust the length of the content payload you receive.
		Payload = Response.GetContentAsString();
		if (Len(Payload) > 1024)
		{
			PayloadIndex = 0;
			Print("Payload:");
			while (PayloadIndex < Len(Payload))
			{
				Print("    "@Mid(Payload, PayloadIndex, 1024));
				PayloadIndex = PayloadIndex + 1024;
			}
		}
		else
		{
			Print("Payload:"@Payload);
		}
	}
}

/**
 * Debug function to send an arbitrary analytics event.
 */
exec function SendAnalyticsEvent(string EventName, optional string AttributeName, optional string AttributeValue)
{
	local AnalyticEventsBase Analytics;

	Analytics = class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface();
	if (Len(AttributeName) > 0)
	{
		Analytics.LogStringEventParam(EventName, AttributeName, AttributeValue, false);
	}
	else
	{
		Analytics.LogStringEvent(EventName, false);
	}
}

/**
 * Debug function to test analytic user events
 */
exec function SendAnalyticsUserAttributeEvent(string AttributeName, string AttributeValue)
{
	class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface().LogUserAttributeUpdate(AttributeName, AttributeValue);
}

/**
 * Debug function to test analytic events
 */
exec function SendAnalyticsItemPurchaseEvent(string ItemId, string Currency, int PerItemCost, int ItemQuantity)
{
	class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface().LogItemPurchaseEvent(ItemId, Currency, PerItemCost, ItemQuantity);
}

/**
 * Debug function to test analytic events
 */
exec function SendAnalyticsCurrencyPurchaseEvent(string GameCurrencyType, int GameCurrencyAmount, string RealCurrencyType, float RealMoneyCost, string PaymentProvider)
{
	class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface().LogCurrencyPurchaseEvent(GameCurrencyType, GameCurrencyAmount, RealCurrencyType, RealMoneyCost, PaymentProvider);
}

/**
 * Debug function to test analytic events
 */
exec function SendAnalyticsCurrencyGivenEvent(string GameCurrencyType, int GameCurrencyAmount)
{
	class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface().LogCurrencyGivenEvent(GameCurrencyType, GameCurrencyAmount);
}

/**
 * Debug function to test analytic events
 */
exec function SendAnalyticsCachedEvents()
{
	class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface().SendCachedEvents();
}

/**
 * Debug function to test analytic events
 */
exec function SetAnalyticsUserId(string UserId)
{
	class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface().SetUserId(UserId);
	Print("Analytics UserId set to:"@UserId);
}

/**
 * Debug function to test analytic events
 */
exec function GetAnalyticsUserId() {
	Super.GetAnalyticsUserId();
}

/**
 * Debug function to test analytic events
 */
exec function AnalyticsStartSession()
{
	class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface().StartSession();
}

/**
 * Debug function to test analytic events
 */
exec function AnalyticsEndSession()
{
	class'PlatformInterfaceBase'.static.GetAnalyticEventsInterface().EndSession();
}

exec function GoogleAuth()
{
	local GoogleIntegration GI;

	GI = class'PlatformInterfaceBase'.static.GetGoogleIntegration();
	Print("Google integration is " $ GI);

	GI.AddDelegate(GDEL_AuthorizationComplete, OnGoogleAuthComplete);
	GI.AddDelegate(GDEL_FriendsListComplete, OnGoogleFriendsComplete);
	GI.AddDelegate(GDEL_YouTubeSubscriptionListComplete, OnGoogleSubscriptionsComplete);

	GI.Authorize();
}

function OnGoogleAuthComplete(const out PlatformInterfaceDelegateResult Result)
{
	local GoogleIntegration GI;

	Print("Google auth was successful " $ Result.bSuccessful);

	GI = class'PlatformInterfaceBase'.static.GetGoogleIntegration();
	GI.ClearDelegate(GDEL_AuthorizationComplete, OnGoogleAuthComplete);

	Print("Google user id is " $ GI.UserId);
	Print("Google user name is " $ GI.UserName);
	Print("Google user email is " $ GI.UserEmail);
}

exec function GoogleRevoke()
{
	local GoogleIntegration GI;

	Print("Google revoke is being called");
	GI = class'PlatformInterfaceBase'.static.GetGoogleIntegration();
	GI.RevokeAuthorization();
}

function OnGoogleFriendsComplete(const out PlatformInterfaceDelegateResult Result)
{
	local GoogleIntegration GI;
	local int Index;

	Print("Google friends list was successful " $ Result.bSuccessful);

	GI = class'PlatformInterfaceBase'.static.GetGoogleIntegration();
	GI.ClearDelegate(GDEL_FriendsListComplete, OnGoogleFriendsComplete);

	for (Index = 0; Index < GI.Friends.Length; Index++)
	{
		Print("Google friend[" $ Index $ "] user id is " $ GI.Friends[Index].Id);
		Print("Google friend[" $ Index $ "] user name is " $ GI.Friends[Index].DisplayName);
	}
}

function OnGoogleSubscriptionsComplete(const out PlatformInterfaceDelegateResult Result)
{
	local GoogleIntegration GI;
	local int Index;

	Print("Google subscriptions list was successful " $ Result.bSuccessful);

	GI = class'PlatformInterfaceBase'.static.GetGoogleIntegration();
	GI.ClearDelegate(GDEL_YouTubeSubscriptionListComplete, OnGoogleSubscriptionsComplete);

	for (Index = 0; Index < GI.Subscriptions.Length; Index++)
	{
		Print("YouTube subscription[" $ Index $ "] channel id is " $ GI.Subscriptions[Index].ChannelId);
		Print("YouTube subscription[" $ Index $ "] channel name is " $ GI.Subscriptions[Index].ChannelTitle);
		Print("YouTube subscription[" $ Index $ "] channel description is " $ GI.Subscriptions[Index].Description);
	}
}

exec function SubscribeToChairChannel()
{
	local GoogleIntegration GI;

	Print("Subscribing to the Chair channel");

	GI = class'PlatformInterfaceBase'.static.GetGoogleIntegration();
	GI.AddDelegate(GDEL_YouTubeSubscriptionAddComplete, OnGoogleSubscriptionAddComplete);

	GI.SubscribeToYouTubeChannel("UCWrp9sOz64Kj2iH8pY-2Jkw");
}

function OnGoogleSubscriptionAddComplete(const out PlatformInterfaceDelegateResult Result)
{
	local GoogleIntegration GI;

	Print("Google subscription add was successful " $ Result.bSuccessful $ " for channel " $ Result.Data.StringValue);

	GI = class'PlatformInterfaceBase'.static.GetGoogleIntegration();
	GI.ClearDelegate(GDEL_YouTubeSubscriptionAddComplete, OnGoogleSubscriptionAddComplete);
}

