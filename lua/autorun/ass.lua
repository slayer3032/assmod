if (SERVER) then
	include("ass_server.lua")
elseif (CLIENT) then
	include("ass_client.lua")
end