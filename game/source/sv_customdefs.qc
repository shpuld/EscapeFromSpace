// put custom server-only globals and fields here

const float FL_JUMPRELEASED = 4096;

float framecount;
float deathmatch;

float player_won;

.float attack_finished;
.float takes_damage;
.float dead;

.float paintime;

.void(float type, entity killer) die;
.void(float amount, float type, entity dealer) hurt;

.float in_biomass;

.vector aim_angles;

.float startafter;

void() sub_remove =
{
	remove(self);
};

void(vector vec) MulticastVector =
{
	WriteCoord(MSG_MULTICAST, vec_x);
	WriteCoord(MSG_MULTICAST, vec_y);
	WriteCoord(MSG_MULTICAST, vec_z);
}

void() light =
{
	remove(self);
}

void() nothing = {};

