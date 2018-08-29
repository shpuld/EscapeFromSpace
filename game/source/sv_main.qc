//
//	Main.qc - mostly functions that will be called from the engine and are expected to exist
//

void() main =
{
}

//called for each frame that QC runs
void() StartFrame =
{
	deathmatch = cvar("deathmatch");
	framecount = framecount + 1;
}

//called when map loaded
void() worldspawn =
{
	player_won = FALSE;
	// localcmd("slowmo 1\n");
	precache_model("models/marine_bottom.iqm");
	precache_model("models/biomass.iqm");
	precache_model("models/crawler.iqm");
	precache_model("models/crawler_gib1.iqm");
	precache_model("models/crawler_gib2.iqm");
	precache_model("models/crawler_gib3.iqm");
	
	precache_sound("sounds/rifle.wav");
	precache_sound("sounds/biomass.wav");
	precache_sound("sounds/alien_idle1.wav");
	precache_sound("sounds/alien_idle2.wav");
	precache_sound("sounds/alien_hit.wav");
	precache_sound("sounds/alien_die.wav");
	
	precache_sound("demon/dland2.wav"); // fuck you
	precache_sound("sounds/endsong.ogg");
}

void() SpectatorConnect =
{
}

