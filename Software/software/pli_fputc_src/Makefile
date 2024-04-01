MTI_HOME="/d/modeltech64_10.4/"
CC=/mingw64_gcc/bin/gcc -c -I$(MTI_HOME)/include  
LD=/mingw64_gcc/bin/gcc -shared -Bsymbolic 
pli_fputc.dll : pli.c  
	$(CC) pli.c  
	$(LD) -o pli_fputc.dll pli.o  $(MTI_HOME)/win64/mtipli.lib 

# MTI_HOME = /E:/modelsim/
# CC = /D:/VSCode/MinGW/mingw/bin/ -c -I$(MTI_HOME)/include
# LD = /D:/VSCode/MinGW/mingw/bin/ -shared -Bsymbolic

# pli_fputc.dll: pli.c
#     $(CC) pli.c
#     $(LD) -o pli_fputc.dll pli.o $(MTI_HOME)/win64/mtipli.lib

# MTI_HOME="/e:/modelsim/"

# CC=D:/VSCode/MinGW/mingw/bin/gcc -c -I$(MTI_HOME)/include

# LD=D:/VSCode/MinGW/mingw/bin/gcc -shared -Bsymbolic

# pli_fputc.dll: pli.c
#     $(CC) pli.c
#     $(LD) -o pli_fputc.dll pli.o $(MTI_HOME)/win64/mtipli.lib



