//
//	Shpuld's CSQC Menu Utils
//	Updated 08-2018
//
//	Very basic, very lacking, supports buttons, sliders and keybinders.
//	No proper containers or scrolling, just screens (groups), no support
//	for customizing individual UI components, no keyboard navigation.
//
//	Made with the purpose of making very quick CSQC menus that just work,
//	mostly for prototype purposes. For more complicated use you might want
//	to check out Spike's menusys instead, and use menuqc in general.
//
//	These utils are provided without any licence or warranty, feel free to
//	use them however you want.
//

void() menu_single =
{
	in_menu = MENU_SINGLE;
	time_in_menu = 0;
};

void() menu_settings =
{
	in_menu = MENU_SETTINGS;
	time_in_menu = 0;
};

void() menu_video =
{
	in_menu = MENU_VIDEO;
	time_in_menu = 0;
};

void() menu_quit =
{
	localcmd("quit\n");
};

void() menu_back =
{
	in_menu = MENU_MAIN;
	time_in_menu = 0;
};

void() menu_load1 =
{
	localcmd("map ld42; music 1\n");
};

void() menu_load2 =
{
	localcmd("map ld42_2; music 1\n");
};


void() video_800 =
{
	localcmd("vid_conautoscale 1; vid_fullscreen 0; vid_width 800; vid_height 800; vid_restart\n");
};

void() video_720 =
{
	localcmd("vid_conautoscale 1.5; vid_fullscreen 0; vid_width 1280; vid_height 720; vid_restart\n");
};

void() video_900 =
{
	localcmd("vid_conautoscale 2; vid_fullscreen 0; vid_width 1600; vid_height 900; vid_restart\n");
};

void() video_fullscreen =
{
	localcmd("vid_conautoscale 2; vid_fullscreen_standalone 1; vid_restart\n");
};


const vector menu_text_color = '0 0.75 0';
const vector menu_fill_color = '0 0.2 0';
const vector menu_line_color = '0 0.5 0';

//struct for all buttons, note pos and scale are going to be multiplied with width/height in draw step, so keep them between 0 and 1
var struct 
{
	vector pos;
	vector scale;
	string text;
	float active; //used for mouseover hilight (positive values) and alpha (negative values)
	void() action; //function that is called when the button is pressed
	float group; //a bit field, button will be usable/visible when these bits are active
} buttons[] = {
		{[0.025, 0.500], [0.25, 0.05], "Start Game", -1, menu_single, MENU_MAIN},
		{[0.025, 0.500], [0.25, 0.05], "Stage 1", -1, menu_load1, MENU_SINGLE},
		{[0.025, 0.575], [0.25, 0.05], "Stage 2", -1, menu_load2, MENU_SINGLE},
		{[0.025, 0.650], [0.25, 0.05], "Controls", -1, menu_settings, MENU_MAIN},
		{[0.025, 0.725], [0.25, 0.05], "Video", -1, menu_video, MENU_MAIN},
		{[0.025, 0.925], [0.25, 0.05], "Quit", -1, menu_quit, MENU_MAIN},
		{[0.025, 0.925], [0.25, 0.05], "Back", -1, menu_back, MENU_SINGLE + MENU_SETTINGS + MENU_VIDEO},
		{[0.025, 0.500], [0.25, 0.05], "800x600", -1, video_800, MENU_VIDEO},
		{[0.025, 0.575], [0.25, 0.05], "1280x720", -1, video_720, MENU_VIDEO},
		{[0.025, 0.650], [0.25, 0.05], "1600x900", -1, video_900, MENU_VIDEO},
		{[0.025, 0.725], [0.25, 0.05], "Fullscreen", -1, video_fullscreen, MENU_VIDEO}
	};
	
const int BUTTONS_COUNT = buttons.length;

void(float val) sens_slider_action = 
{
	cvar_set("sensitivity", ftos(val));
}

float(float min, float max, float step) sens_slider_get =
{
	float sens = cvar("sensitivity");
	sens = bound(min, sens, max); 
	return sens;
};
var struct
{
	vector pos;
	vector scale;
	string text;
	float active;
	float(float, float, float) init;
	void(float) action;
	float value;
	float min;
	float max;
	float steps;
	float group;
} sliders[] =
{
	{ [0.5, 0.55, 0], [0.3, 0.05, 0], "", -1, sens_slider_get, sens_slider_action, 1, 0.01, 5, 0, MENU_SETTINGS }
};

const float SLIDERS_COUNT = sliders.length;


var struct
{
	vector pos;
	vector scale;
	string command;
	string value;
	float active;
	float group;
} binders[] =
{
	{[0.225, 0.50], [0.15, 0.05], "+forward", "w", -1, MENU_SETTINGS},
	{[0.225, 0.55], [0.15, 0.05], "+back", "s", -1, MENU_SETTINGS},
	{[0.225, 0.60], [0.15, 0.05], "+moveleft", "a", -1, MENU_SETTINGS},
	{[0.225, 0.65], [0.15, 0.05], "+moveright", "d", -1, MENU_SETTINGS},
	{[0.225, 0.70], [0.15, 0.05], "+attack", "mouse1", -1, MENU_SETTINGS},
	{[0.225, 0.75], [0.15, 0.05], "reload", "r", -1, MENU_SETTINGS}
};

const float BINDERS_COUNT = binders.length;

void(float index) Update_Binder =
{
	if(in_menu != in_menu & binders[index].group)
		binders[index].active = -1;
		
	if(binders[index].active == -1)
	{
		if(in_menu == in_menu & binders[index].group)
			binders[index].active = 1;
		else
			return;
	}
	
	vector pos = binders[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;
	vector scale = binders[index].scale;
	scale_x *= g_width;
	scale_y *= g_height;
	
	float alphafactor = 0.5;
	
	string keyname = binders[index].value == "01" ? "unbound" : binders[index].value;

	if(cursor_pos_x > pos_x && cursor_pos_x < pos_x + scale_x && cursor_pos_y > pos_y && cursor_pos_y < pos_y + scale_y )
		alphafactor = 1;
	
	drawfill(pos, scale, menu_fill_color + menu_fill_color*binders[index].active, 0.3 * alphafactor);
	drawline(1, pos, [pos_x + scale_x, pos_y, 0], menu_line_color, 0.5, 1); //top outline
	drawline(1, pos, [pos_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //left outline
	drawline(1, [pos_x, pos_y + scale_y, 0], [pos_x + scale_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //bottom outline
	drawline(1, [pos_x + scale_x, pos_y, 0], [pos_x + scale_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //right outline
	drawstring(pos + [scale_x*0.05, scale_y*0.25, 0], keyname, [scale_y*0.5, scale_y*0.5, 1], menu_text_color, 0.5 + alphafactor*0.5, 1);
	
	if (active_bind_index == index)
	{
		string bindprompt = sprintf("Press key for <%s>", binders[index].command);
		float textsize = 16;
		drawfill([0, 0], [g_width, g_width], [0, 0, 0], 0.5);
		drawstring([g_width*0.5 - strlen(bindprompt)*textsize*0.5, g_height * 0.3], bindprompt, [textsize, textsize], menu_text_color, 1, 0);
	}
};


void(float index) Binder_Click = 
{
	//don't click if not active
	if(binders[index].active == -1)
		return;
		
	vector pos = binders[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;
	vector scale = binders[index].scale;
	scale_x *= g_width;
	scale_y *= g_height;
	
	if(cursor_pos_x > pos_x && cursor_pos_x < pos_x + scale_x && cursor_pos_y > pos_y && cursor_pos_y < pos_y + scale_y )
	{
		//buttons[index].action(); //do whatever this button is supposed to do
		//tokenize(findkeysforcommand(binders[index].command));
		//string keyname = keynumtostring(stof(argv(0)));
		active_bind_index = index;
	}
};

void() Cancel_Bind =
{
	active_bind_index = -1;
}

void(float index) Remove_Bind =
{
	tokenize(findkeysforcommand(binders[index].command));
	string keyname = keynumtostring(stof(argv(0)));
	string altkeyname = keynumtostring(stof(argv(1)));
	localcmd(sprintf("unbind %s\n", keyname));
	localcmd(sprintf("unbind %s\n", altkeyname));
	active_bind_index = -1;
	binders[index].value = "01";
}

void(float index, float key) Bind_Key =
{
	if (menu_click_held) return;
	if (key == K_ESCAPE) 
	{
		Cancel_Bind();
		return;
	}
	if (key == K_BACKSPACE)
	{
		Remove_Bind(index);
		return;
	}
	string keyname = keynumtostring(key);
	Remove_Bind(index);
	localcmd(sprintf("bind %s %s\n", keyname, binders[index].command));
	binders[index].value = keyname;
	active_bind_index = -1; 
};


//this function handles drawing the buttons and checking if they should be active/hilighted
void(float index) Update_Button = 
{
	if(in_menu != in_menu & buttons[index].group)
		buttons[index].active = -1;
		
	if(buttons[index].active == -1)
	{
		if(in_menu == in_menu & buttons[index].group)
			buttons[index].active = 1;
		else
			return;
	}
	
	vector pos = buttons[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;
	vector scale = buttons[index].scale;
	scale_x *= g_width;
	scale_y *= g_height;
	
	float alphafactor = 0.5;
	if(cursor_pos_x > pos_x && cursor_pos_x < pos_x + scale_x && cursor_pos_y > pos_y && cursor_pos_y < pos_y + scale_y )
		alphafactor = 1;
	
	drawfill(pos, scale, menu_fill_color + menu_fill_color*buttons[index].active, 0.3 * alphafactor);
	drawline(1, pos, [pos_x + scale_x, pos_y, 0], menu_line_color, 0.5, 1); //top outline
	drawline(1, pos, [pos_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //left outline
	drawline(1, [pos_x, pos_y + scale_y, 0], [pos_x + scale_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //bottom outline
	drawline(1, [pos_x + scale_x, pos_y, 0], [pos_x + scale_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //right outline
	drawstring(pos + [scale_x*0.05, scale_y*0.25, 0], buttons[index].text, [scale_y*0.5, scale_y*0.5, 1], menu_text_color,  0.5 + alphafactor*0.5, 1);
};


void(float index) Button_Click = 
{
	//don't click if not active
	if(buttons[index].active == -1)
		return;
		
	vector pos = buttons[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;
	vector scale = buttons[index].scale;
	scale_x *= g_width;
	scale_y *= g_height;
	
	if(cursor_pos_x > pos_x && cursor_pos_x < pos_x + scale_x && cursor_pos_y > pos_y && cursor_pos_y < pos_y + scale_y )
	{
		buttons[index].action(); //do whatever this button is supposed to do
	}
};

float slider_held_index;
void(float index) Update_Slider =
{
	if (in_menu != in_menu & sliders[index].group)
		sliders[index].active = -1;
		
	if (sliders[index].active == -1)
	{
		if (in_menu == in_menu & sliders[index].group)
			sliders[index].active = 1;
		else
			return;
	}
	
	vector pos = sliders[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;
	vector scale = sliders[index].scale;
	scale_x *= g_width;
	scale_y *= g_height;
	float slide_ratio = (sliders[index].value - sliders[index].min) / (sliders[index].max - sliders[index].min);
	float slide_width = slide_ratio * scale_x;
	
	float alphafactor;

	alphafactor = 0.8;
	if (cursor_pos_x > pos_x && cursor_pos_x < pos_x + scale_x && cursor_pos_y > pos_y && cursor_pos_y < pos_y + scale_y ) {
		alphafactor = 1;
	}
	
	drawfill(pos, [slide_width, scale_y], menu_fill_color + menu_fill_color*sliders[index].active, 0.5 * alphafactor);
	drawline(1, pos, [pos_x + scale_x, pos_y, 0], menu_line_color, 0.5, 1); //top outline
	drawline(1, pos, [pos_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //left outline
	drawline(1, [pos_x, pos_y + scale_y, 0], [pos_x + scale_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //bottom outline
	drawline(1, [pos_x + scale_x, pos_y, 0], [pos_x + scale_x, pos_y + scale_y, 0], menu_line_color, 0.5, 1); //right outline
	drawstring(pos + [scale_x*0.05, scale_y*0.25, 0], sliders[index].text, [scale_y*0.5, scale_y*0.5, 1], menu_text_color,  0.5 + alphafactor*0.5, 1);
}

void(float index) Slider_Click =
{
	if(sliders[index].active == -1)
		return;
		
	vector pos = sliders[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;
	vector scale = sliders[index].scale;
	scale_x *= g_width;
	scale_y *= g_height;
	
	if(cursor_pos_x > pos_x && cursor_pos_x < pos_x + scale_x && cursor_pos_y > pos_y && cursor_pos_y < pos_y + scale_y )
	{
		float click_ratio = (cursor_pos_x - pos_x) / scale_x;
		if (sliders[index].steps > 0)
			click_ratio = rint(click_ratio * sliders[index].steps) / sliders[index].steps;
		sliders[index].value = sliders[index].min + click_ratio * (sliders[index].max - sliders[index].min);
		sliders[index].action(sliders[index].value);
		
		slider_held_index = index;
	}
}

void(float index) Slider_Hold =
{
	if(sliders[index].active == -1)
		return;
		
	vector pos = sliders[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;
	vector scale = sliders[index].scale;
	scale_x *= g_width;
	scale_y *= g_height;
	
	float click_ratio = (cursor_pos_x - pos_x) / scale_x;
	click_ratio = bound(0, click_ratio, 1);
	if (sliders[index].steps > 0)
		click_ratio = rint(click_ratio * sliders[index].steps) / sliders[index].steps;
	sliders[index].value = sliders[index].min + click_ratio * (sliders[index].max - sliders[index].min);
	sliders[index].action(sliders[index].value);
}

void() Menu_Click =
{
	float i;
	for(i = 0; i < BUTTONS_COUNT; i++)
	{
		Button_Click(i);
	}
	for(i = 0; i < SLIDERS_COUNT; i++)
	{
		Slider_Click(i);
	}
	for(i = 0; i < BINDERS_COUNT; i++)
	{
		Binder_Click(i);
	}
	menu_click_held = TRUE;
};

void() Menu_Release =
{
	menu_click_held = FALSE;
	slider_held_index = -1;
}

void() Draw_Menu =
{
	drawfill([0, 0], [g_width, g_height], [0, 0, 0], 0.3);
	//Title with a simple but nice animation
	string title = "";
	switch(in_menu)
	{
		case MENU_MAIN:
			title = "LD42: Escape from Space";
			drawstring([0.0275*g_width, 0.300*g_height], "Compo", [g_height * 0.035, g_height * 0.035], menu_text_color, 1, 1);
			break;
		case MENU_SINGLE:
			title = "Start Game";
			drawstring([0.025*g_width, 0.650*g_height], "You're a marine in need of a vacation.", [g_height * 0.025, g_height * 0.025], menu_text_color, 1, 1);
			drawstring([0.025*g_width, 0.700*g_height], "Escape the infested ship before you get eaten by it.", [g_height * 0.025, g_height * 0.025], menu_text_color, 1, 1);
			drawstring([0.025*g_width, 0.800*g_height], "Ludum Dare 42 Compo Entry by Shp.", [g_height * 0.025, g_height * 0.025], menu_text_color, 1, 1);
			drawstring([0.025*g_width, 0.850*g_height], "Powered by the FTE Quakeworld Engine.", [g_height * 0.025, g_height * 0.025], menu_text_color, 1, 1);
			break;
		case MENU_SETTINGS:
			title = "Controls";
			drawstring([0.025*g_width, (0.50 + 0.0125)*g_height], "Forward", [0.025*g_height, 0.025*g_height], menu_text_color, 1, 1);
			drawstring([0.025*g_width, (0.55 + 0.0125)*g_height], "Back", [0.025*g_height, 0.025*g_height], menu_text_color, 1, 1);
			drawstring([0.025*g_width, (0.60 + 0.0125)*g_height], "Left", [0.025*g_height, 0.025*g_height], menu_text_color, 1, 1);
			drawstring([0.025*g_width, (0.65 + 0.0125)*g_height], "Right", [0.025*g_height, 0.025*g_height], menu_text_color, 1, 1);
			drawstring([0.025*g_width, (0.70 + 0.0125)*g_height], "Fire", [0.025*g_height, 0.025*g_height], menu_text_color, 1, 1);
			drawstring([0.025*g_width, (0.75 + 0.0125)*g_height], "Reload", [0.025*g_height, 0.025*g_height], menu_text_color, 1, 1);
			drawstring([0.5*g_width, (0.50 + 0.0125)*g_height], "Sensitivity", [0.025*g_height, 0.025*g_height], menu_text_color, 1, 1);
			string sensval = sprintf("%.2f", cvar("sensitivity"));
			drawstring([(0.5 + 0.3)*g_width - 0.025*strlen(sensval)*g_height, (0.50 + 0.0125)*g_height], sensval, [0.025*g_height, 0.025*g_height], menu_text_color, 1, 1);
			break;
		case MENU_VIDEO:
			title = "Video";
			break;
		default:
			title = "LD42: Escape from Space";
	}
	
	drawstring([0.025*g_width, 0.25*g_height, 0], title, [g_height * 0.05, g_height * 0.05, 1], menu_text_color, 1, 1);
	
	float i;

	for (i = 0; i < BUTTONS_COUNT; i++)
	{
		Update_Button(i);
	}
	
	for (i = 0; i < SLIDERS_COUNT; i++)
	{
		Update_Slider(i);
	}
	
	for (i = 0; i < BINDERS_COUNT; i++)
	{
		Update_Binder(i);
	}
	
	if (slider_held_index > -1)
	{
		Slider_Hold(slider_held_index);
	}
};

void() Init_Menu =
{
	slider_held_index = -1;
	active_bind_index = -1;
	
	float i;
	for (i = 0; i < BINDERS_COUNT; i++)
	{
		tokenize(findkeysforcommand(binders[i].command));
		string keyname = keynumtostring(stof(argv(0)));
		// string altkeyname = keynumtostring(stof(argv(1)));
		binders[i].value = keyname;
	}
	
	for (i = 0; i < SLIDERS_COUNT; i++)
	{
		sliders[i].value = sliders[i].init(sliders[i].min, sliders[i].max, sliders[i].steps);
	}
}
