net.Receive( "Valen_AntiPropSpam", function()
    local lockoutTime = net.ReadInt( 8 )

    surface.PlaySound( "buttons/button10.wav" )
    notification.AddLegacy( "You're spawning props too quickly and can begin spawning again in " .. lockoutTime .. " seconds.", NOTIFY_ERROR, 2 )
end )