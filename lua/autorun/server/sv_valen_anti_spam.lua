util.AddNetworkString( "Valen_AntiPropSpam" )

local propLimitCvar = CreateConVar( "sv_antipropspam_proplimit", 10, FCVAR_ARCHIVE, "How many props can be spawned within the time limit before being locked out.", 0 )
local propSpawnTimeCvar = CreateConVar( "sv_antipropspam_propspawntime", 2, FCVAR_ARCHIVE, "The length in seconds of the time limit to count prop spam in.", 0 )
local lockoutTimeCvar = CreateConVar( "sv_antipropspam_lockouttime", 6, FCVAR_ARCHIVE, "The length in seconds of the time limit to lock players out for.", 0 )

local function initFields( ply )
    local tbl = {}
    tbl.RecentPropsSpawned = {}
    tbl.RecentPropSpawnTime = 0
    tbl.LockoutTime = 0
    tbl.CanSpawnProps = true

    ply.AntiPropSpam = tbl
end

hook.Add( "PlayerInitialSpawn", "Valen_AntiPropSpam", function( ply )
    initFields( ply )
end )

hook.Add( "PlayerSpawnedProp", "Valen_AntiPropSpam", function( ply, _, ent )
    if ply.AdvDupe2 and ply.AdvDupe2.Pasting then return end

    if not ply.AntiPropSpam then initFields( ply ) end

    local plyTbl = ply.AntiPropSpam
    local time = CurTime()
    table.insert( plyTbl.RecentPropsSpawned, ent )

    if time - plyTbl.RecentPropSpawnTime >= lockoutTimeCvar:GetInt() then
        plyTbl.RecentPropSpawnTime = time
        plyTbl.RecentPropsSpawned = { ent }

        return
    end

    if time - plyTbl.RecentPropSpawnTime <= propSpawnTimeCvar:GetInt() and #plyTbl.RecentPropsSpawned >= propLimitCvar:GetInt() then
        plyTbl.LockoutTime = time + lockoutTimeCvar:GetInt()
        plyTbl.CanSpawnProps = false

        for _, prop in pairs( plyTbl.RecentPropsSpawned ) do
            if prop:CPPIGetOwner() == ply then
                local canFreeze = not ( prop:IsWeapon() or prop:GetUnFreezable() or prop:IsPlayer() )
                local physicsObj = prop:GetPhysicsObject()

                if IsValid( physicsObj ) and canFreeze then
                    physicsObj:EnableMotion( false )
                    physicsObj:Sleep()
                end
            end
        end
    end
end )

hook.Add( "PlayerSpawnObject", "Valen_AntiPropSpam", function( ply, _ )
    local time = CurTime()

    if not ply.AntiPropSpam then initFields( ply ) end

    local plyTbl = ply.AntiPropSpam

    if time - plyTbl.RecentPropSpawnTime >= lockoutTimeCvar:GetInt() then
        plyTbl.RecentPropsSpawned = {}
        plyTbl.CanSpawnProps = true

        return
    end

    if not plyTbl.CanSpawnProps then
        net.Start( "Valen_AntiPropSpam" )
        net.WriteInt( math.ceil( plyTbl.LockoutTime - time ), 8 )
        net.Send( ply )

        return false
    end
end )