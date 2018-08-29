//shared definitions

#define printf(x, ...) print(sprintf(x, __VA_ARGS__))

float() crandom =
{
	return (random() * 2) - 1;
};

const float EV_SHOOT = 0;
const float EV_HURT = 1;
const float EV_RELOAD = 2;
const float EV_RELOAD_DONE = 3;
const float EV_WIN = 4;
const float EV_TEXT = 5;
const float EV_DOORTIMER = 6;

const float GUN_RIFLE = 0;

const float RIFLE_MAG = 50;
const float RIFLE_RELOAD = 2.2;