#include <stdio.h>  
#include "SDL.h"  
  
int main( int argc, char* args[] )   
{   
    //����SDL  
    if (SDL_Init( SDL_INIT_EVERYTHING ) != 0){  
        printf("SDL_Init Error: %s", SDL_GetError());  
        return 1;  
    }  
      
    //�˳�SDL   
    SDL_Quit();  
    system("pause");  
      
    return 0;  
}   

