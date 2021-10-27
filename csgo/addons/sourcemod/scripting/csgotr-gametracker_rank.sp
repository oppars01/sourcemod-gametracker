#include <sourcemod>
#include <SteamWorks>
#include <regex>

#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Gametracker Rank", 
	author = "oppa", 
	description = "Gametracker Shows Your Server Ranking", 
	version = "1.0", 
	url = "csgo-turkiye.com"
};

bool b_wait_status[MAXPLAYERS +1];

public void OnPluginStart()
{   
    RegConsoleCmd("sm_gametracker", GametrackerRank);
    RegConsoleCmd("sm_gt", GametrackerRank);
}

Action GametrackerRank(int client, int args)
{
    if (client==0 || !b_wait_status[client])
    {
        CreateTimer(300.0, WaitRemove, client);
    	b_wait_status[client] = true;
        char netIP[32];
        int pieces[4];
        int longip = GetConVarInt(FindConVar("hostip"));
        pieces[0] = (longip >> 24) & 0x000000FF;
        pieces[1] = (longip >> 16) & 0x000000FF;
        pieces[2] = (longip >> 8) & 0x000000FF;
        pieces[3] = longip & 0x000000FF;
        Format(netIP, sizeof(netIP), "%d.%d.%d.%d:%d", pieces[0], pieces[1], pieces[2], pieces[3], GetConVarInt(FindConVar("hostport")));
        Handle h_request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "https://cache.gametracker.com/components/html0/?");
        SteamWorks_SetHTTPRequestNetworkActivityTimeout(h_request, 10);
        SteamWorks_SetHTTPRequestGetOrPostParameter(h_request, "host", netIP);
        SteamWorks_SetHTTPCallbacks(h_request, GametrackerData);
        SteamWorks_SetHTTPRequestContextValue(h_request, client);
        SteamWorks_SendHTTPRequest(h_request);
	}else{
	    PrintToChat(client," \x02You need to wait 5 minutes to find out your Gametracker rank.");
	}
    return Plugin_Handled;
}

void GametrackerData(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client) 
{
    if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK) 
    {
        delete hRequest;
        if(client==0){
            PrintToServer("Failed to retrieve data from Gametracker site.");
        }else{
            if (IsClientConnected(client) && IsValidClient(client) && !IsFakeClient(client))
            {
                PrintToChat(client," \x02Failed to retrieve data from Gametracker site.");
            }
        }
        return;
    }
    int i_response_size;
    SteamWorks_GetHTTPResponseBodySize(hRequest, i_response_size);
    char[] s_response = new char[i_response_size];
    SteamWorks_GetHTTPResponseBodyData(hRequest, s_response, i_response_size);
    delete hRequest;
    Handle h_search = CompileRegex("Rank:</b>\n\t\t\t</div>\n\t\t\t<div class=\"item_float_right\">\n\t\t\t\t(.*)~");
    ReplaceString(s_response,i_response_size,"(","~");
    char s_rank[128];
    if(MatchRegex(h_search, s_response)) {
        char s_buffer[128],s_full[128];
        new cnt = 0;
        while(GetRegexSubString(h_search, cnt, s_buffer, sizeof(s_buffer)+1)) {
            switch(cnt) {
                case 0: s_full = s_buffer;
                case 1: s_rank = s_buffer;
                case 2: break;
            }
            cnt++;
        }
    }
    CloseHandle(h_search);
    if (!StrEqual(s_rank, "")){
        if(client==0){
            PrintToServer("Gametracker rank: %s", s_rank);
        }else{
            if (IsClientConnected(client) && IsValidClient(client) && !IsFakeClient(client))
            {
                PrintToChat(client," \x04Gametracker rank: \x0C%s", s_rank);
            }
        }  
    }else{
        if(client==0){
            PrintToServer("Gametracker rank not found.");
        }else{
            if (IsClientConnected(client) && IsValidClient(client) && !IsFakeClient(client))
            {
                PrintToChat(client," \x02Gametracker rank not found.");
            }
        }
    }
}

Action WaitRemove(Handle timer, int client )
{
	b_wait_status[client] = false;
}

stock bool IsValidClient(int client)
{
	if(client > 0 && client <= MaxClients)
	{
		if(IsClientInGame(client))
			return true;
	}
	return false;
}