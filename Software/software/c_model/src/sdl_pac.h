//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#define UP_KEY		( 0xff & SDLK_UP )
#define DOWN_KEY    ( 0xff & SDLK_DOWN )
#define LEFT_KEY	( 0xff & SDLK_LEFT )
#define RIGHT_KEY   ( 0xff & SDLK_RIGHT )
#define ENTER_KEY	( 0xff & SDLK_RETURN )
#define ESC_KEY     ( 0xff & SDLK_ESCAPE )
#define K_KEY       ( 0xff & SDLK_k )
#define SPACE_KEY   ( 0xff & SDLK_SPACE )

void WriteBlock(int x,int y,int width,int height,int type,char *data);
void WriteBlockYUV(int x,int y,int width,int height, short **data_y, short **data_u, short **data_v);
void GetBlock(int x, int y, int width, int height, int type, char *data);
void Rectangle(int x0, int y0, int x1, int y1, int type);
void SDLTextOut(int x, int y, char* string, int type);
void ClearScreen();
void Refresh();

int CheckKey(char key);
void ReleaseKey(char key);

void Delay(int ms);
void GetTime(struct Time *t);
int GetTicks();

int SDL_quit(int exit_code);
int sdl_event();
void SDL_init(int width, int height);

struct Time
{
	int year;
	char month;
	char day;
	char week;
	char hour;
	char minute;
	char second;
	int  milliseconds;
};

#define SCREEN_WIDTH  (800)
#define SCREEN_HEIGHT (500)


void start_trans();
void stop_trans();
//#define SEND_BACK_EXAMPLE
#ifdef SEND_BACK_EXAMPLE
#define TOTAL_BYTES_NUM (1024*1024*16)
#else
#define TOTAL_BYTES_NUM (1024*1024)
#endif
