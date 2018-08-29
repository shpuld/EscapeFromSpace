// ents
.float biomass_phase;

void() biomass_think =
{
	if (self.biomass_phase < 16) 
	{
		self.biomass_phase += 0.5;
	}
	
	entity head = findradius(self.origin, self.biomass_phase * 13);
	while (head)
	{
		if (head.classname == "player")
		{
			damage(self.biomass_phase / 2, head, self, DMG_BIOMASS);
			head.in_biomass = 0.5;
		}
		head = head.chain;
	}
	
	self.nextthink = time + 0.5;
	self.think = biomass_think;
};

void() biomass_start =
{
	sound(self, CHAN_AUTO, "sounds/biomass.wav", 1, 0.5);
	setmodel(self, "models/biomass.iqm");
	self.think = biomass_think;
	self.nextthink = time + 1;
	
}

void() alien_biomass =
{
	setsize(self, '-64 -64 0', '64 64 64');
	self.biomass_phase = 0;
	self.angles_y = random() * 360;
	
	self.nextthink = time + self.startafter + random() * 5;
	self.think = biomass_start;
};

void(float amount, float type, entity dealer) crawler_hurt =
{
	self.paintime = 0.25;
};

void(vector position, vector vel, string model) spawn_gib =
{
	entity gib = spawn();
	setmodel(gib, model);
	setsize(gib, '0 0 0', '0 0 0');
	setorigin(gib, position);
	gib.traileffectnum = particleeffectnum("weapons.alienblood_trail");
	gib.movetype = MOVETYPE_BOUNCE;
	gib.solid = SOLID_NOT;
	gib.avelocity = randomvec() * vlen(vel);
	gib.velocity = vel;
	gib.nextthink = time + 10 + random() * 10;
	gib.think = sub_remove;
}

void(float type, entity killer) crawler_die =
{
	vector dir = normalize(self.origin + '0 0 48' - killer.origin);
	pointparticles(particleeffectnum("weapons.alienblood_explode"), self.origin + '0 0 32');
	sound(trace_ent, CHAN_AUTO, "sounds/alien_die.wav", 1, 0.5);
	spawn_gib(self.origin, [crandom() * 100, crandom() * 100, 130 + random() * 200] + dir * 140, "models/crawler_gib1.iqm");
	spawn_gib(self.origin, [crandom() * 100, crandom() * 100, 130 + random() * 200] + dir * 140, "models/crawler_gib1.iqm");
	spawn_gib(self.origin, [crandom() * 100, crandom() * 100, 130 + random() * 200] + dir * 140, "models/crawler_gib2.iqm");
	spawn_gib(self.origin, [crandom() * 100, crandom() * 100, 130 + random() * 200] + dir * 140, "models/crawler_gib3.iqm");
	spawn_gib(self.origin, [crandom() * 100, crandom() * 100, 130 + random() * 200] + dir * 140, "models/crawler_gib3.iqm");
	spawn_gib(self.origin, [crandom() * 100, crandom() * 100, 130 + random() * 200] + dir * 140, "models/crawler_gib3.iqm");
	remove(self);
};

float(float angle, float amount) walkmove_try_harder =
{
	if (walkmove(angle, amount)) return TRUE;
	if (walkmove(angle - 15, amount)) return TRUE;
	if (walkmove(angle + 15, amount)) return TRUE;
	if (walkmove(angle - 35, amount)) return TRUE;
	if (walkmove(angle + 35, amount)) return TRUE;
	if (walkmove(angle - 55, amount)) return TRUE;
	if (walkmove(angle + 55, amount)) return TRUE;
	return FALSE;
};

void() crawler_think;

void() crawler_finish_attack =
{
	self.frame = 0;
	self.nextthink = time + 0.05;
	self.think = crawler_think;
};

void() crawler_attack =
{
	if (player_won) return;
	
	walkmove_try_harder(self.angles_y, 20);
	if (vlen(self.enemy.origin - self.origin) < 72)
	{
		damage(5 + floor(random()*5), self.enemy, self, DMG_CLAW);
	}
	self.nextthink = time + 0.3;
	self.think = crawler_finish_attack;
};

// to navigate corners
.vector last_seen;
.float soundtime;

void() crawler_think =
{
	if (player_won) return;
	
	self.frame = 0;
	makevectors(self.angles);
	float walkres;
	vector trofs = '0 0 12';
	if (self.paintime > 0) 
	{
		walkres = walkmove_try_harder(self.angles_y, 5);
		self.paintime -= 0.05;
	}
	else 
	{
		walkres = walkmove_try_harder(self.angles_y, 10 + ((self.enemy != world) * 5));
		if (time > self.soundtime)
		{
			float ra = random();
			if (ra < 0.05) 
			{
				sound(self, CHAN_AUTO, "sounds/alien_idle1.wav", 0.5, 0.5, 70);
				self.soundtime = time + 6 + random() * 3;
			}
			else if(ra < 0.1)
			{
				sound(self, CHAN_AUTO, "sounds/alien_idle2.wav", 0.5, 0.5, 60);
				self.soundtime = time + 7 + random() * 3;
			}
		}
	}
	
	if (!self.enemy)
	{
		//traceline(self.origin + '0 0 8', self.origin + '0 0 8' + v_forward * 80, MOVE_NOMONSTERS, self);
		if (!walkres)
		{
			self.angles_y += crandom() * 30;
		}
		else
			self.angles_y += crandom() * 3;
		
		entity pl = find(world, classname, "player");
		if (pl)
		{
			traceline(self.origin + trofs, pl.origin + trofs, MOVE_NOMONSTERS, self);
			if (trace_fraction >= 1) 
			{
				self.enemy = pl;
				self.last_seen = pl.origin + trofs;
			}
		}
	}
	else
	{
		traceline(self.origin + trofs, self.enemy.origin + trofs, MOVE_NOMONSTERS, self);
		float player_visible = trace_fraction >= 1;
		
		if (!walkres)
		{
			traceline(self.origin + v_right * 12 + trofs, self.origin + v_right * 12 + trofs + v_forward * 24, MOVE_NOMONSTERS, self);
			if (trace_fraction < 1) 
			{
				walkmove(self.ideal_yaw + 90, 15);
			}
			else 
			{
				traceline(self.origin - v_right * 12 + trofs, self.origin - v_right * 12 + trofs + v_forward * 24, MOVE_NOMONSTERS, self);
				if (trace_fraction < 1) 
				{
					walkmove(self.ideal_yaw - 90, 15);
				}
			}
		}

		if (player_visible) 
		{
			self.last_seen = self.enemy.origin + trofs;
			vector dir_to_pl = normalize(self.enemy.origin - self.origin);
			vector ang_to_pl = vectoangles(dir_to_pl);
			self.ideal_yaw = ang_to_pl.y;
			
			changeyaw();
			
			if (vlen(self.enemy.origin - self.origin) < 64)
			{
				sound(self, CHAN_AUTO, "sounds/alien_idle1.wav", 1, 0.5);
				self.soundtime = time + 5;
				self.frame = 1;
				self.nextthink = time + 0.35;
				self.think = crawler_attack;
				return;
			}
		}
		else
		{
			vector dir_to_ls = normalize(self.last_seen - self.origin);
			vector ang_to_ls = vectoangles(dir_to_ls);
			self.ideal_yaw = ang_to_ls.y;
			changeyaw();
			if (vlen(self.last_seen - self.origin) < 48)
			{
				self.enemy = world;
			}
		}
	}

	self.think = crawler_think;
	self.nextthink = time + 0.05;
};

void() alien_crawler =
{
	setmodel(self, "models/crawler.iqm");
	setsize(self, '-16 -16 0', '16 16 56');
	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_STEP;
	self.health = 60;
	self.takes_damage = TRUE;
	self.think = crawler_think;
	self.nextthink = time + 0.05;
	self.die = crawler_die;
	self.hurt = crawler_hurt;
	self.gravity = 1;
	self.yaw_speed = 20;
};

void() info_corner = {};

.entity corner;
void() spawner_think =
{
	vector trofs = '0 0 12';
	entity pl = find(world, classname, "player");
	if (pl && pl.health > 0)
	{
		traceline(self.corner.origin + trofs, pl.origin + trofs, MOVE_NOMONSTERS, self);
		if (trace_fraction >= 1) 
		{
			entity alien = spawn();
			setorigin(alien, self.origin);
			alien.classname = "alien_crawler";
			alien.angles = vectoangles(self.corner.origin - self.origin);
			alien.angles_x = 0;
			
			entity oldself = self;
			self = alien;
			alien_crawler();
			self = oldself;
			
			alien.last_seen = self.corner.origin;
			alien.enemy = pl;
		}
	}
	self.nextthink = time + 3 + random() * 3;
	self.think = spawner_think;
};

void() alien_spawner =
{
	self.corner = find(world, targetname, self.target);
	if (!self.corner)
	{
		print("Spawner without a corner point!\n");
		return;
	}
	self.nextthink = time + 3 + random() * 3;
	self.think = spawner_think;
};

void() voice_touch =
{
	if (other.classname != "player") return;
	sound(other, CHAN_VOICE, sprintf("sounds/%s.wav", self.target), 1, 0);
	remove(self);
};

void() trigger_once =
{
	self.touch = voice_touch;
	setmodel(self, self.model);
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
	
	precache_sound(sprintf("sounds/%s.wav", self.target));
};

void() bombexplode =
{
	pointparticles(particleeffectnum("weapons.explosion"), self.origin, '0 0 50');
	sound(self, CHAN_AUTO, "sounds/bomb.wav", 1, 0.1);
	sound(self, CHAN_AUTO, "sounds/rifle.wav", 1, 0.1);
	remove(self);
};


void() bombtimer = 
{
	sound(self, CHAN_AUTO, "sounds/bombtimer.wav", 1, 0.5, 120 + (50 - self.ammo_rockets * 10));
	self.ammo_rockets -= 1;
	if (self.ammo_rockets <= 0)
	{
		self.nextthink = time + 1;
		self.think = bombexplode;
		return;
	}
	self.nextthink = time + 1;
	self.think = bombtimer;
};

void() plant_door_bomb =
{
	if (other.classname != "player") return;
	
	if (other.ammo_rockets <= 0) 
	{
		if (time > self.soundtime)
		{
			sound(self, CHAN_AUTO, "sounds/door_denied.wav", 1, 1, 80);
			self.soundtime = time + 3;
			
			msg_entity = other;
			WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
			WriteByte(MSG_MULTICAST, EV_TEXT);
			WriteByte(MSG_MULTICAST, 2);
			multicast('0 0 0', MULTICAST_ONE_R);
		}
		return;
	}
	
	other.ammo_rockets -= 1;
	
	entity newbomb = spawn();
	setorigin(newbomb, other.origin + '0 0 30');
	newbomb.velocity = randomvec()*30 + '0 0 150';
	newbomb.movetype = MOVETYPE_BOUNCE;
	newbomb.avelocity = [0, crandom() * 90, 0];
	setmodel(newbomb, "models/bomb.iqm");
	newbomb.nextthink = time + 1;
	newbomb.think = bombtimer;
	newbomb.ammo_rockets = 5;
	
	self.touch = nothing;
	self.nextthink = time + 6;
	self.think = sub_remove;
};

void() func_door =
{
	precache_model("models/bomb.iqm");
	precache_sound("sounds/bombtimer.wav");
	precache_sound("sounds/bomb.wav");
	precache_sound("sounds/door_denied.wav");
	self.touch = plant_door_bomb;
	setmodel(self, self.model);
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_NONE;
};

void() explosives_touch =
{
	if (other.classname != "player") return;
	
	other.ammo_rockets += 1;
	
	msg_entity = other;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_TEXT);
	WriteByte(MSG_MULTICAST, 0);
	multicast('0 0 0', MULTICAST_ONE_R);
	
	sound(other, CHAN_VOICE, "sounds/useful.wav", 1, 0.5);
	
	remove(self);
};

void() item_explosives =
{
	precache_model("models/bomb.iqm");
	precache_sound("sounds/bombtimer.wav");
	precache_sound("sounds/bomb.wav");
	precache_sound("sounds/useful.wav");
	setmodel(self, "models/bomb.iqm");
	self.solid = SOLID_TRIGGER;
	setsize(self, '-16 -16 0', '16 16 64');
	self.touch = explosives_touch;
};

void() timeout_door_touch =
{
	if (other.classname != "player") return;
	if (time > self.soundtime)
	{
		sound(self, CHAN_AUTO, "sounds/door_denied.wav", 1, 1, 80);
		self.soundtime = time + 3;
	}
};

void() func_bossgate =
{
	precache_sound("sounds/door_denied.wav");
	self.touch = timeout_door_touch;
	setmodel(self, self.model);
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_NONE;
};

void() timeout_door_f_this =
{
	pointparticles(particleeffectnum("weapons.explosion"), (self.absmin + self.absmax) * 0.5, '0 0 50');
	sound(self, CHAN_AUTO, "sounds/bomb.wav", 1, 0);
	sound(self, CHAN_AUTO, "sounds/rifle.wav", 1, 0);
	remove(self);
};

void() activate_timeout_door =
{
	self.goalentity.nextthink = time + 60;
	self.goalentity.think = timeout_door_f_this;

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_DOORTIMER);
	multicast('0 0 0', MULTICAST_ALL_R);
	
	
	//printf("timeout door activated on %s\n", self.goalentity.classname);
	sound(self, CHAN_AUTO, "sounds/door_intercom.wav", 1, 0);
	sound(self, CHAN_AUTO, "sounds/endsong.ogg", 0.6, 0);
	remove(self);
};

void() deferred_activate =
{
	entity tgt = find(world, targetname, self.target);
	if (tgt)
	{
		self.goalentity = tgt;
		self.touch = activate_timeout_door;
	}
}

void() trigger_push =
{
	precache_sound("sounds/door_intercom.wav");
	setmodel(self, self.model);
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
	self.nextthink = time + 0.001;
	self.think = deferred_activate;
};

void() jumptrigger_touch =
{
	if (other.classname != "alien_crawler") return;
	setorigin(other, other.origin + '0 0 2');
	other.flags -= other.flags & FL_ONGROUND;
	other.velocity = [150+random()*150, 0, 100];
};

void() trigger_monsterjump =
{
	setmodel(self, self.model);
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
	self.touch = jumptrigger_touch;
};

void() win_touch =
{
	if (other.classname != "player") return;
	
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_WIN);
	multicast('0 0 0', MULTICAST_ALL_R);
	
	localcmd("slowmo 0.5\n");
	player_won = TRUE;
	
	remove(self);
};

void() trigger_win =
{
	setmodel(self, self.model);
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
	self.touch = win_touch;
};

