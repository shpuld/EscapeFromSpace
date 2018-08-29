
//
//	Player.qc - Various stuff done for the player, including per-frame functions like PlayerPreThink and PlayerPostThink, also client specific stuff like PutClientInServer etc.
//

void() PlayerJump =
{
	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;
	
	self.weaponframe = 0;
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.button2 = 0;
};

.float reloading;
void() CheckImpulses =
{
	// if(self.impluse == 123) { ... }
	if (self.impulse == 100 && self.currentammo < RIFLE_MAG && !self.reloading)
	{
		self.reloading = TRUE;
		self.attack_finished = time + RIFLE_RELOAD;
		
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EV_RELOAD);
		WriteEntity(MSG_MULTICAST, self);
		multicast(self.origin, MULTICAST_PVS);		
	}
	self.impulse = 0;
};

void() player_shoot =
{
	if (self.currentammo <= 0)
	{
		if (!self.reloading)
		{
			self.reloading = TRUE;
			self.attack_finished = time + RIFLE_RELOAD;
			
			WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
			WriteByte(MSG_MULTICAST, EV_RELOAD);
			WriteEntity(MSG_MULTICAST, self);
			multicast(self.origin, MULTICAST_PVS);
			return;
		}
	}
	
	vector fire_org = self.origin + '0 0 48';
	float spread = 3;
	makevectors(self.aim_angles + [crandom()*spread, crandom()*spread]);
	traceline(fire_org, fire_org + v_forward * 10000, 0, self);
	
	if (trace_ent.takes_damage)
	{
		sound(trace_ent, CHAN_AUTO, "sounds/alien_hit.wav", 0.5, 0.5);
		pointparticles(particleeffectnum("weapons.alienblood"), trace_endpos, v_forward * 5);
		damage(8, trace_ent, self, DMG_BULLET);
	}
	
	sound(self, CHAN_WEAPON, "sounds/rifle.wav", 0.7, 0.5, 100 + crandom()*2);
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_SHOOT);
	WriteByte(MSG_MULTICAST, GUN_RIFLE);
	WriteEntity(MSG_MULTICAST, self);
	MulticastVector(fire_org);
	MulticastVector(trace_endpos);
	MulticastVector(trace_plane_normal);
	multicast(self.origin, MULTICAST_PVS);
	
	self.attack_finished = time + 0.075;
	self.currentammo -= 1;
};

void() PlayerPreThink =
{
	if (self.dead) return;
	CheckImpulses();
	
	if (self.reloading && time > self.attack_finished)
	{
		self.reloading = FALSE;
		self.currentammo = RIFLE_MAG;
		msg_entity = self;
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EV_RELOAD_DONE);
		multicast(self.origin, MULTICAST_ONE);
	}
	
	if(self.button0)
	{
		if (time > self.attack_finished) player_shoot();
	}
	if(self.button2)
	{
		PlayerJump();
	}
	else
	{
		self.flags = self.flags | FL_JUMPRELEASED;
	}
};

void() PlayerPostThink =
{
};

void() ClientKill =
{
};

//called when a client connects to the server
void() ClientConnect =
{
};


void(float type, entity killer) player_die =
{
	self.dead = TRUE;
};

void(float amount, float type, entity dealer) player_hurt =
{
	msg_entity = self;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_HURT);
	WriteByte(MSG_MULTICAST, amount);
	MulticastVector(dealer.origin);
	multicast(self.origin, MULTICAST_ONE); 
};

void() PlayerSpawn =
{
	local entity spawnpoint;
	spawnpoint = find(world, classname, "info_player_start");
	
	self.classname = "player";
	self.solid = SOLID_SLIDEBOX;
	setmodel(self, "models/marine_bottom.iqm");
	self.movetype = MOVETYPE_WALK;
	self.health = 100;
	self.takes_damage = TRUE;
	self.die = player_die;
	self.hurt = player_hurt;
	self.origin = spawnpoint.origin + [0,0,1];
	self.fixangle = TRUE;
	setsize(self, [-16, -16, 0], [16, 16, 64]);
	self.view_ofs = [0, 0, 56];
	
	self.currentammo = RIFLE_MAG;
	
	self.ammo_rockets = 0;
	
	self.takes_damage = TRUE;
};

//called when a client loads a map
void() PutClientInServer =
{
	PlayerSpawn();
};

//called when client disconnects from the server
void() ClientDisconnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has left the game.\n");
};


void() SetNewParms =
{
};

void() SetChangeParms =
{
};

void() info_player_start =
{
	
};

void() SV_RunClientCommand =
{
	if (player_won) input_movevalues = '0 0 0';
	self.aim_angles = input_angles;
	input_angles = '0 0 0';
	if (self.in_biomass > 0)
	{
		self.in_biomass -= input_timelength;
		if (vlen(self.velocity) > 100) input_movevalues *= 0.25;
	}
	runstandardplayerphysics(self);
	self.angles = self.aim_angles;
};


