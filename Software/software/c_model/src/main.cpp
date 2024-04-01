#include <stdio.h>  
#include "SDL.h"  
  
int main( int argc, char* args[] )   
{   
    //Æô¶¯SDL  
    if (SDL_Init( SDL_INIT_EVERYTHING ) != 0){  
        printf("SDL_Init Error: %s", SDL_GetError());  
        return 1;  
    }  
      
    //ÍË³öSDL   
    SDL_Quit();  
    system("pause");  
      
    return 0;  
}   

