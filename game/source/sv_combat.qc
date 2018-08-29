// Empty

const float DMG_BULLET = 0;
const float DMG_CLAW = 1;
const float DMG_BIOMASS = 2;
const float DMG_EXPLOSION = 3;

void(float dmg, entity victim, entity dealer, float type) damage =
{
	if (!victim.takes_damage) return;
	
	victim.health -= dmg;
	
	entity oldself = self;
	self = victim;
	victim.hurt(dmg, type, dealer);
	self = oldself;
	
	if (victim.health <= 0)
	{
		oldself = self;
		self = victim;
		victim.die(type, dealer);
		self = oldself;
		victim.dead = TRUE;
		return;
	}
};
