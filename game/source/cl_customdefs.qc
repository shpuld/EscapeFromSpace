//Various globals that are used in this FTEQW example are defined here, they are not used by the engine itself

#pragma warning disable Q302
vector cursor_pos; /* Current mouse cursor position, updated in csqc_inputevent */
float g_width, g_height; /* Globals for screen width and height */

vector crosshair_pos; /* Topdown crosshair constrained inside window */
vector aim_normalized; /* from -1 to 1 on Y, X not completely normalized, affected by aspect ratio */

//Menu stuff
float in_menu; //what menu are we in
float time_in_menu;

// for keybinding
float active_bind_index;
float menu_click_held;

const float MENU_NONE = 0;
const float MENU_MAIN = 1;
const float MENU_SINGLE = 2;
const float MENU_SETTINGS = 4;
const float MENU_VIDEO = 8;

vector campos;
vector camang;

float hurt_time;

float shoot_time;
float reload_time;
float reload_done_time;

float wongame;
float wintime;

string messagetext;
float messagetime;

float doortimer;