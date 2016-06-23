
ASS_Config["writer"] = "Default Writer"
ASS_Config["banlist"] = "Default Banlist"
ASS_Config["logger"] = "Default Logger"
ASS_Config["max_temp_admin_time"] = 	4 * 60
ASS_Config["max_temp_admin_ban_time"] = 1 * 60

ASS_Config["tell_admins_what_happened"] = true
ASS_Config["tell_clients_what_happened"] = true

if CLIENT then
	ASS_Config["reasons"] = {

		{	name = "(none)", 	reason = ""				},
		{	name = "Spamming",	reason = "Spamming"		},
		{	name = "Asshole",	reason = "Asshole"		},
		{	name = "Mingebag",	reason = "Mingebag"		},
		{	name = "General Idiot",	reason = "General Idiot"	},

	}

	ASS_Config["ban_times"] = {

		{ 	time = 5,		name = "5 Min"		},
		{ 	time = 30,		name = "30 Min" 	},
		{ 	time = 60,		name = "1 Hour"		},
		{ 	time = 120,		name = "2 Hours"	},
		{ 	time = 720,		name = "6 Hours"	},
		{ 	time = 1440,	name = "24 Hours"	},
		{ 	time = 2880,	name = "2 Days"		},
		{ 	time = 7200,	name = "5 Days"		},
		{ 	time = 10080,	name = "7 Days"		},
		{ 	time = 20160,	name = "2 Weeks"	},
		{ 	time = 40320,	name = "4 Weeks"	},
		{ 	time = 0,		name = "Permanent"	},

	}

	ASS_Config["temp_admin_times"] = {

		{ 	time = 5,		name = "5 Min"		},
		{ 	time = 15,		name = "15 Min"		},
		{ 	time = 30,		name = "30 Min" 	},
		{ 	time = 60,		name = "1 Hour"		},
		{ 	time = 120,		name = "2 Hours"	},
		{ 	time = 240,		name = "4 Hours"	},
		{ 	time = 480,		name = "8 Hours"	},
		{ 	time = 720,		name = "12 Hours"	},

	}
			
	ASS_Config["rcon"] = {

		{	cmd = "sv_voiceenable 1"	},
		{	cmd = "sv_voiceenable 0"	},
		
	}
end