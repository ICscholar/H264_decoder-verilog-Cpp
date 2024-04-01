//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------


#include <stdio.h>
int main ()
{
	int buffer32bit;
	unsigned short buffer16bit;
	unsigned char  buffer8bit;
	int nibble;
	int type;
	char inFileName[256];
	char outFileName[256];
	FILE * inFile;
	FILE * outFile;

	printf("file name for input : ");
	scanf("%s", inFileName);
	inFile  = fopen (inFileName, "r");
	if (inFile == NULL)
	{
		printf("can not open file.");
		getchar();
		return 0;
	}

	printf("file name for output : ");
	scanf("%s", outFileName);
	outFile  = fopen (outFileName, "wb");
	if (outFile == NULL)
	{
		printf("can not open file.");
		getchar();
		return 0;
	}
	while(1)
	{
		nibble = fgetc(inFile);
		if (nibble == EOF){
			break;
		}
		if (nibble >= '0' && nibble <= '9'){
			buffer8bit = (nibble - '0') << 4;
		}
		else if (nibble >= 'a' && nibble <= 'f'){
			buffer8bit = (nibble - 'a' + 10) << 4;
		}
		else if (nibble >= 'A' && nibble <= 'A'){
			buffer8bit = (nibble - 'A' + 10) << 4;
		}
		
		nibble = fgetc(inFile);
		if (nibble == EOF){
			break;
		}
		if (nibble >= '0' && nibble <= '9'){
			buffer8bit |= (nibble - '0');
		}
		else if (nibble >= 'a' && nibble <= 'f'){
			buffer8bit |= (nibble - 'a' + 10);
		}
		else if (nibble >= 'A' && nibble <= 'A'){
			buffer8bit |= (nibble - 'A' + 10);
		}
		fwrite  (&buffer8bit,1,1,outFile);
	}

	fclose (inFile);
	fclose (outFile);
    return 0;
}


