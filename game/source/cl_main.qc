void() ToggleMenu =
{
	if(serverkey("constate") != "disconnected")
	{
		localcmd("pause\n");
		if(in_menu == MENU_NONE)
		{

			in_menu = MENU_MAIN;
			time_in_menu = 0;
			local float i;
			for(i = 0; i < BUTTONS_COUNT; i++)
			{
				buttons[i].active = 1;
			}
			setcursormode(TRUE,"menu/cursor");
		}
		else
		{
			in_menu = MENU_NONE;
			setcursormode(FALSE);
		}
	}
	else
	{
		in_menu = MENU_MAIN;
		time_in_menu = 0;
		setcursormode(TRUE,"menu/cursor");
	}
}

float(float old, float new, float maxamount) shiftangle =
{
	new = anglemod(new - old);
	while (new < -180) new += 360;
	while (new > 180) new -= 360;
	old += bound(-maxamount, new, maxamount);
	return old;
};

entity player;
vector aim_angles;
float oldrot;
float oldlerpfrac;
float oldframetime;
entity player_upper;
entity player_rifle;

void(entity legs, float yaw) update_torso =
{
	if (getstatf(STAT_HEALTH) <= 0)
	{
		pointparticles(particleeffectnum("weapons.blood"), player.origin + '0 0 20', '0 0 20');
		return;
	}
	
	float idx = gettagindex(player, "root");
	vector lowerpos = gettaginfo(player, idx);
	idx = gettagindex(player_upper, "waist");
	vector upperofs = gettaginfo(player_upper, idx) - player_upper.origin;
	setorigin(player_upper, lowerpos - upperofs);
	player_upper.angles = [0, yaw, 0];
	if (reload_time > 0) {
		player_upper.frame = 2;
		player_upper.frame1time += frametime * 1.5;
	}
	else if (shoot_time > 0) {
		player_upper.frame = 1;
		player_upper.frame1time = 0.1 - shoot_time;
	}
	else {
		player_upper.frame = 0;
		player_upper.frame1time = 0;
	}
	addentity(player_upper);
	
	idx = gettagindex(player_upper, "hand.R");
	setorigin(player_rifle, gettaginfo(player_upper, idx));
	player_rifle.angles = vectoangles(v_forward, v_up);
	addentity(player_rifle);
}

float(float isnew) playerlisten =
{
	if (isnew) crosshair_pos = [g_width / 2, g_height / 2, 0];
	
	player = self;
	vector newangles;
	vector ang = vectoangles(aim_normalized);
	newangles = -ang + '0 270 0';
	if (newangles_y < 0) newangles_y += 360;
	aim_angles = newangles;
	vector moveangle = vectoangles(player.velocity);
	float anglediff = newangles_y- moveangle_y;
	float oldnewdiff;
	if (anglediff <= -180) anglediff += 360;
	if (anglediff > 180) anglediff -= 360;
	//if (vlen(player.velocity) > 10) printf("%f, %f, %f\n", anglediff, moveangle_y, player.angles_y);
	
	if (vlen(player.velocity) < 10) 
	{
		player.frame = 0;
		player.angles_y = shiftangle(oldrot, newangles_y, 3 * frametime * 360);
		oldrot = player.angles_y;
		oldframetime = 0;
		update_torso(player, aim_angles_y);
		return TRUE;
	}
	
	player.frame = 1;
	player.frame2 = 2;
	
	float picked_frame;
	float angle_offset;
	float anim_dir;
	if (fabs(anglediff) <= 46) 
	{
		picked_frame = 1;
		angle_offset = anglediff;
		anim_dir = 1;
	}
	else if (fabs(anglediff) < 135) 
	{ 
		picked_frame = 2; 
		angle_offset = anglediff > 0 ? anglediff - 90 : anglediff + 90;
		anim_dir = anglediff < 0 ? -1 : 1;
	}
	else 
	{
		picked_frame = 1;
		angle_offset = anglediff > 0 ? anglediff - 180 : anglediff + 180;
		anim_dir = -1;
	}
	
	newangles_y -= angle_offset;
	player.angles_y = shiftangle(oldrot, newangles_y, 3 * frametime * 360);
	oldrot = player.angles_y;

	player.lerpfrac = picked_frame == 1 ? max(0, oldlerpfrac - frametime * 4) : min(1, oldlerpfrac + frametime * 4);
	player.frame1time = player.frame2time = oldframetime + anim_dir * frametime * (vlen(player.velocity) / 240);
	oldframetime = player.frame1time;
	oldlerpfrac = player.lerpfrac;
	
	update_torso(player, aim_angles_y);

	// printf("frame: %f\n", player.frame);
	return TRUE;
};

.float biomass_time;
float(float isnew) biomasslisten =
{
	// printf("biomass %f\n", self.biomass_time);
	if (isnew) self.biomass_time = 0;
	
	self.biomass_time += frametime * 0.25;
	self.biomass_time = min(self.biomass_time, 7.2);
	self.frame1time = self.biomass_time;
	
	return TRUE;
};

float dead_menu_toggled;
float voice_index;
void(float apiver, string enginename, float enginever) CSQC_Init =
{
	localcmd("slowmo 1\n");
	Init_Menu();
	registercommand("togglemenu");
	registercommand("reload");

	if(serverkey("constate") == "disconnected")
		ToggleMenu();
	
	precache_model("models/marine_bottom.iqm");
	precache_model("models/marine_top.iqm");
	precache_model("models/rifle.iqm");
	
	dead_menu_toggled = FALSE;
	voice_index = 0;
	precache_sound("sounds/gotta_reload.wav");
	precache_sound("sounds/im_reloadin.wav");
	precache_sound("sounds/changing_mags.wav");
	
	deltalisten("models/marine_bottom.iqm", playerlisten, 0);
	deltalisten("models/biomass.iqm", biomasslisten, 0);
	
	player_upper = spawn();
	player_rifle = spawn();
	setmodel(player_upper, "models/marine_top.iqm");
	setmodel(player_rifle, "models/rifle.iqm");
};


void() CSQC_WorldLoaded =
{
};

void(float isnew) CSQC_Ent_Update =
{
	// printf("csqc ent update %f\n", isnew);
}

struct tracer {
	vector start;
	vector end;
	float speed;
	float type;
	float timeleft;
};

const float MAX_TRACERS = 128;
tracer tracers[MAX_TRACERS];

void(vector start, vector end, float speed, float type, float lifetime) spawn_tracer =
{
	for (int i = 0; i < MAX_TRACERS; i++)
	{
		if (tracers[i].timeleft <= 0)
		{
			tracers[i].start = start;
			tracers[i].end = end;
			tracers[i].speed = speed;
			tracers[i].type = type;
			tracers[i].timeleft = lifetime;
			
			return;
		}
	}
};

void() update_tracers =
{
	for (int i = 0; i < MAX_TRACERS; i++)
	{
		if (tracers[i].timeleft <= 0) continue;
		
		vector col = '1 1 1';
		float a = 1;
		float width = 1;
		string shader = "tracer";
		
		switch (tracers[i].type)
		{
			case 0:
				col = '1 0.9 0.6';
				width = 1;
				tracers[i].timeleft -= frametime*16;
				break;
			case 1:
				col = '1 1 0.9';
				a = min(1, tracers[i].timeleft + 0.5);
				width = 15 + 20 * tracers[i].timeleft;
				tracers[i].timeleft -= frametime*50;
				shader = sprintf("mf%.0f", random()*2 + 1);
				break;
			default: 
				tracers[i].timeleft -= frametime;
				break;
		}
		
		vector forward = normalize(tracers[i].end - tracers[i].start);
		vector right = crossproduct(forward, '0 0 1');
		R_BeginPolygon(shader);
			R_PolygonVertex(tracers[i].start + right*width, [0, 0, 0], col, a);
			R_PolygonVertex(tracers[i].start - right*width, [1, 0, 0], col, a);
			R_PolygonVertex(tracers[i].end - right*width, [1, 1 - (tracers[i].speed * (1 - tracers[i].timeleft)), 0], col, a);
			R_PolygonVertex(tracers[i].end + right*width, [0, 1 - (tracers[i].speed * (1 - tracers[i].timeleft)), 0], col, a);
		R_EndPolygon();
	}
};

float dead_time;
void() draw_gameover =
{
	dead_time = dead_time + frametime * 0.25;
	string gameovertext = substring("YOU ARE DEAD...", 0, max(0, floor((min(dead_time, 1) * 16 * 2) - 8)));
	float textsize = 32;
	drawfill([0, 0], [g_width, g_height], [0, 0, 0], min(1,dead_time) * 0.7);
	drawstring([g_width/2 - strlen(gameovertext)*textsize*0.5, g_height/2 - textsize], gameovertext, [textsize, textsize], [0, 1, 0], min(dead_time, 0.6), 1);
	
	if (dead_time > 2 && !dead_menu_toggled)
	{
		dead_menu_toggled = TRUE;
		ToggleMenu();
	}	
};

float win_menu_toggled;
void() draw_win =
{
	wintime = wintime + frametime * 0.5;
	string gameovertext = substring("STAGE COMPLETE!", 0, max(0, floor((min(wintime, 1) * 16 * 2) - 8)));
	float textsize = 32;
	drawfill([0, 0], [g_width, g_height], [0, 0, 0], min(1,wintime) * 0.7);
	drawstring([g_width/2 - strlen(gameovertext)*textsize*0.5, g_height/2 - textsize], gameovertext, [textsize, textsize], [0, 1, 0], min(wintime, 0.6), 1);
	
	if (wintime > 2 && !win_menu_toggled)
	{
		win_menu_toggled = TRUE;
		ToggleMenu();
	}	
};

// CALLED EVERY CLIENT RENDER FRAME
void(float width, float height, float menushown) CSQC_UpdateView =
{
	//clear and update our global screen resolution vars
	clearscene();
	g_width = width;
	g_height = height;

	//disable quake status bar and quake crosshair
	setproperty(VF_DRAWENGINESBAR, 0);	
	setproperty(VF_DRAWCROSSHAIR, 0);

	campos = getproperty(VF_ORIGIN);
	camang = getproperty(VF_ANGLES);
	
	vector listenerpos = campos + '-50 0 500';
	SetListener(listenerpos, '1 0 0', '0 1 0', '0 0 1');
	
	aim_normalized = crosshair_pos - [g_width/2, g_height/2];
	aim_normalized /= g_height/2;
	campos += '-150 0 800' - [aim_normalized_y * 200, aim_normalized_x * 200, 0] + [crandom(), crandom()] * (shoot_time + (max(hurt_time - 0.2, 0) * 0.2)) * 10;
	camang = '80 0 0';

	setproperty(VF_ORIGIN, campos);
	setproperty(VF_ANGLES, camang);
	//autoadd entities received from servers for drawing	
	addentities(MASK_ENGINE);

	update_tracers();
	//does what you think it does
	renderscene();
	
	float ch_size = 32;
	vector ch_shake = shoot_time * [crandom(), crandom()] * 24;
	shoot_time -= frametime;
	shoot_time = max(0, shoot_time);
	if (reload_time > 0)
	{
		string rlstr = "RELOADING";
		float rltextsize = 8;
		drawpic(crosshair_pos - [ch_size/2, ch_size/2] + ch_shake, "textures/crosshair", [ch_size, ch_size], [shoot_time*4, 1, shoot_time*4], 0.175 + sin(reload_time * 25) * 0.15, 1);
		drawstring(crosshair_pos + [-strlen(rlstr) * rltextsize / 2, ch_size / 2] + ch_shake, rlstr, [rltextsize, rltextsize], [0, 1, 0], 0.25 + sin(reload_time * 25) * 0.15, 1);
		
		reload_time = max(reload_time - frametime, 0);
	}
	else
	{
		drawpic(crosshair_pos - [ch_size/2, ch_size/2] + ch_shake, "textures/crosshair", [ch_size, ch_size], [shoot_time*4, 1, shoot_time*4], 0.6 + shoot_time * 3, 1);
	}
	if (shoot_time > 0)
	{
		drawfill([0, 0], [g_width, g_height], [1, 0.8, 0.6], 0.5 * max(shoot_time - 0.05, 0), 1);
	}
	
	float health = getstatf(STAT_HEALTH);	
	if (health <= 0)
	{
		if (serverkey("constate") != "disconnected")
			draw_gameover();
	}
	if (wongame)
	{
		draw_win();
	}

	if(in_menu)
	{
		//in menu.qc
		Draw_Menu();
	}
	else
	{
		if(hurt_time > 0) drawfill([0, 0], [g_width, g_height], [1, 0.1, 0.05], min(hurt_time * 0.1, 0.5), 1);
		
		hurt_time -= frametime * 4;
		hurt_time = max(0, hurt_time);
		
		float hpbar_w = 160;
		float hpbar_h = 16;
		float hptext_h = 12;
		string hptext = sprintf("%.0f", health);
		float yoffset = 24;
		vector dmg_shake = [crandom(), crandom()]*0.5*hurt_time;
		drawfill([g_width/2 - (hpbar_w/2) - 2, yoffset - 2] + dmg_shake, [hpbar_w + 4, 1], [0, 1, 0], 0.25, 1);
		drawfill([g_width/2 - (hpbar_w/2) - 2, yoffset + hpbar_h + 1] + dmg_shake, [hpbar_w + 4, 1], [0, 1, 0], 0.25, 1);
		drawfill([g_width/2 - (hpbar_w/2) - 2, yoffset - 1] + dmg_shake, [1, hpbar_h + 2], [0, 1, 0], 0.25, 1);
		drawfill([g_width/2 + (hpbar_w/2) + 1, yoffset - 1] + dmg_shake, [1, hpbar_h + 2], [0, 1, 0], 0.25, 1);
		drawfill([g_width/2 - (hpbar_w/2), yoffset] + dmg_shake, [hpbar_w * (health/100), hpbar_h], [hurt_time * 0.2, 1, hurt_time * 0.2], 0.5, 1);
		drawstring([g_width/2 - (hpbar_w/2) - 2, yoffset - 2 - hptext_h] + dmg_shake, "HEALTH", [hptext_h, hptext_h], [0, 1, 0], 0.6, 1);
		drawstring([g_width/2 + (hpbar_w/2) + 2 - strlen(hptext)*hptext_h, yoffset - 2 - hptext_h] + dmg_shake, hptext, [hptext_h, hptext_h], [0, 1, 0], 0.6, 1);
		//drawstring([0.01*width, 0.94*height, 0], strcat("+",ftos(health)), [0.03*width, 0.03*width, 0], [1, 1, 1], 1, 1);
		
		float ammo_h = 3;
		float ammo_gap = 1;
		float ammo_w = 24;
		float ammo_count = getstatf(STAT_AMMO);
		float ammo_ofs_x = 4;
		float ammo_ofs_y = 4;
		vector ammo_shake = [crandom(), crandom()] * shoot_time * 24;
		drawstring(ammo_shake + [ammo_ofs_x, g_height / 2 - hptext_h], "AMMO", [hptext_h, hptext_h], [0, 1, 0], 0.6, 1);
		drawstring(ammo_shake + [ammo_ofs_x + ammo_w, g_height / 2], ftos(ammo_count), [hptext_h, hptext_h], [shoot_time * 5, 1, shoot_time * 5], 0.6 + shoot_time * 2, 1);
		drawfill(ammo_shake + 
			[ammo_ofs_x, g_height / 2 - (ammo_h + ammo_gap) + (max(shoot_time*10, 0)) * (ammo_h + ammo_gap)], 
			[ammo_w, ammo_h], 
			[shoot_time * 10, 1, shoot_time * 10], shoot_time * 8, 1); 
		for (int i = 0; i < ammo_count; i++)
		{
			drawfill(ammo_shake + 
				[ammo_ofs_x, g_height / 2 + i * (ammo_h + ammo_gap) + (max(shoot_time*10, 0)) * (ammo_h + ammo_gap)], 
				[ammo_w, ammo_h], 
				[reload_done_time * 10, 1, reload_done_time * 10], 0.5 + reload_done_time * 0.5, 1); 
		}
		reload_done_time = max(0, reload_done_time - frametime);
		
		float bombs = getstatf(STAT_ROCKETS);
		if (bombs > 0)
		{
			float bomb_size = 64;
			drawpic([g_width - bomb_size, g_height - bomb_size], "textures/bomb_icon_bw.png", [bomb_size, bomb_size], [0, 1, 0], 0.6, 1);
		}
		
		if (messagetime > 0)
		{
			float newtime = max(0, messagetime - 4.5);
			float oldtime = min(1, messagetime);
			float textsize = 16;
			drawstring([g_width/2 - textsize * 0.5 * strlen(messagetext), g_height/2 - 60], messagetext,  [textsize, textsize], [newtime, 1, newtime], oldtime*0.6 + newtime*0.4, 1);
			messagetime = max(0, messagetime - frametime);
		}
		
		if (doortimer > 0)
		{
			string timertext = sprintf("%.2f\n", doortimer);
			drawstring([g_width/2 - (32 * 0.5 * strlen(timertext) - 15), 48], timertext,  [32, 32], [0, 1, 0], 0.6, 1);
			doortimer = max(0, doortimer - frametime);
		}
	}
};

float(string cmd) CSQC_ConsoleCommand =
{
	tokenize(cmd);
	switch(argv(0))
	{
		case "togglemenu":
			ToggleMenu();
			return TRUE;
			break;
		case "reload":
			localcmd("impulse 100\n");
			return TRUE;
			break;
		case "pause":
			return FALSE;
			break;
		case "map":
			return FALSE;
			break;
		default:
			return FALSE;
	}
	return TRUE;
};

float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	switch(evtype)
	{
	case IE_KEYDOWN:
		if(in_menu != MENU_NONE)
		{
			if(active_bind_index > -1 && !menu_click_held)
			{
				
				Bind_Key(active_bind_index, scanx);
				return TRUE;
			}
			if(scanx == K_MOUSE1)
			{
				Menu_Click();
				return TRUE;
			}
		}
		return FALSE;
	case IE_KEYUP:
		if (scanx == K_MOUSE1)
		{
			Menu_Release();
		}
		return FALSE;
	case IE_MOUSEDELTA:
		float sens = cvar("sensitivity");
		crosshair_pos_x += scanx * sens;
		crosshair_pos_y += chary * sens;
		crosshair_pos_x = bound(0, crosshair_pos_x, g_width);
		crosshair_pos_y = bound(0, crosshair_pos_y, g_height);
		return FALSE;
	case IE_MOUSEABS:
		//if(devid != 0 && devid != 1)
		//	return FALSE;
		cursor_pos_x = scanx;
		cursor_pos_y = chary;
		return FALSE;
	}
	return FALSE;
};

vector old_dir;

void() CSQC_Input_Frame =
{
	input_movevalues_x = bound(-260, input_movevalues_x, 260);
	input_movevalues_y = bound(-260, input_movevalues_y, 260);
	if (player)
	{
		if (vlen(player.velocity) > 265) input_movevalues *= 0.25;
		
		float yaw = aim_angles_y;
		if (yaw > 180) yaw -= 360;
		input_angles = [0, yaw, 0];
	}

};

vector() readvector =
{
	vector r = '0 0 0';
	r_x = readcoord();
	r_y = readcoord();
	r_z = readcoord();
	return r;
};

void() reload_sound = {
	switch(voice_index) {
		case 0: sound(world, CHAN_VOICE, "sounds/gotta_reload.wav", 1, 0); break;
		case 1: sound(world, CHAN_VOICE, "sounds/im_reloadin.wav", 1, 0); break;
		case 2: sound(world, CHAN_VOICE, "sounds/changing_mags.wav", 1, 0); break;
		default: break;
	}
	voice_index += ceil(random() * 1.99);
	if (voice_index >= 3) voice_index = 0;
}

void() CSQC_Parse_Event =
{
	float first = readbyte();
	vector v1 = '0 0 0';
	vector v2 = '0 0 0';
	vector v3 = '0 0 0';
	switch(first) {
		case EV_SHOOT:
			float gun = readbyte();
			float shooter_num = readentitynum();
			v1 = readvector();
			v2 = readvector();
			v3 = readvector();
			vector forward = normalize(v2 - v1);
			if (shooter_num == player_localentnum) 
			{
				makevectors(player_rifle.angles);
				v1 = player_rifle.origin - v_right * 8;
				forward = -v_right;
				shoot_time = 0.1;
			}
			spawn_tracer(v1, v2, 1, 0, 0.2 + random()*0.5);
			
			spawn_tracer(v1 + forward * 16, v1 + forward * 128 * (random()*0.2 + 0.5), 0, 1, 0.5 + random()*0.5);
			
			pointparticles(particleeffectnum("weapons.impact"), v2, v3*50);
			break;
		case EV_HURT:
			if (player)
				pointparticles(particleeffectnum("weapons.bloodhit"), player.origin + '0 0 50', '0 0 40');
			hurt_time = readbyte() * 0.5; // dmg amount straight into timer
			v1 = readvector();
			break;
		case EV_RELOAD:
			reload_sound();
			float entnum = readentitynum();
			if (entnum == player_localentnum) reload_time = RIFLE_RELOAD;
			break;
		case EV_RELOAD_DONE:
			reload_done_time = 0.2;
			break;
		case EV_WIN:
			wongame = TRUE;
			wintime = 0;
			break;
		case EV_TEXT:
			float whichtext = readbyte();
			messagetime = 5;
			if (whichtext == 0) messagetext = "You got explosives!";
			if (whichtext == 1) messagetext = "Wait 60 seconds for the door!";
			if (whichtext == 2) messagetext = "You need explosives!";
			break;
		case EV_DOORTIMER:
			doortimer = 60;
			break;
		default:
			printf("No action for byte %f\n", first);
			break;
	}
};