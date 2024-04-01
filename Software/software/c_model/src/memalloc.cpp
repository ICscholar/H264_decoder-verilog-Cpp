#include "memalloc.h"
#include <memory.h>
#include <assert.h>
#include <malloc.h>

int get_mem2D(unsigned char ***array2D,unsigned short rows,unsigned short columns)
{
	int i;
	*array2D = (unsigned char**)calloc(rows, sizeof(unsigned char*));
	(*array2D)[0] = (unsigned char*)calloc(columns*rows, sizeof(unsigned char));

	for (i = 1;i < rows;i++)
	{
		(*array2D)[i] = (*array2D)[i - 1] + columns;
	}
	return rows * columns;
}

void free_mem2D(unsigned char** array2D)
{
	if (array2D)
	{
		if (array2D[0])
		{
			free(array2D[0]);
		}
		free(array2D);
	}
}

int get_mem2Dshort(unsigned short ***array2D, unsigned short rows, unsigned short columns, unsigned short init_value)
{
	int i;
	*array2D = (unsigned short**)calloc(rows, sizeof(unsigned short*));
	(*array2D)[0] = (unsigned short*)calloc(columns*rows, sizeof(unsigned short));
	
	if ( init_value )
	{
		/* memset只把columns * rows个字节初始化成2                                   */
		/* 把columns * rows个short类型的数据初始化成2,内存的结构应为0200, 0200,......*/
		/* memset((*array2D)[0], init_value, columns * rows);                        */
		for (i = 0; i < columns * rows; i++)
		{
			(*array2D)[0][i] = init_value;
		}
	}

	for (i = 1;i < rows;i++)
	{
		(*array2D)[i] = (*array2D)[i - 1] + columns;
	}
	return rows * columns;
}

void free_mem2Dshort(unsigned short** array2D)
{
	if (array2D)
	{
		if (array2D[0])
		{
			free(array2D[0]);
		}
		free(array2D);
	}
}

int get_mem2Dpixel(short ***array2D, unsigned short rows, unsigned short columns, short init_value)
{
	int i;
	*array2D = (short**)calloc(rows, sizeof(short*));
	(*array2D)[0] = (short*)calloc(columns*rows, sizeof(short));

	if ( init_value )
	{
		for (i = 0; i < columns * rows; i++)
		{
			(*array2D)[0][i] = init_value;
		}
	}

	for (i = 1;i < rows;i++)
	{
		(*array2D)[i] = (*array2D)[i - 1] + columns;
	}
	return rows * columns;
}

void free_mem2Dpixel(short** array2D)
{
	if (array2D)
	{
		if (array2D[0])
		{
			free(array2D[0]);
		}
		free(array2D);
	}
}

int get_mem3Dshort(unsigned short ****array3D, 
				   unsigned short frames, 
				   unsigned short rows,
				   unsigned short columns)
{
	unsigned short i;
	*array3D = (unsigned short***)calloc(frames, sizeof(unsigned short**));

	for (i = 0; i < frames; i++)
	{
		get_mem2Dshort(*array3D + i, rows, columns, 0);
	}
	return frames * rows * columns;
}

void free_mem3Dshort(unsigned short ***array3D, unsigned short frames)
{
	unsigned short i;
	if (array3D)
	{
		for (i = 0; i < frames; i++)
		{
			free_mem2Dshort(array3D[i]);
		}
		free(array3D);
	}
}

int get_mem3Dpixel( short **** array3D,
				   unsigned short frames,
				   unsigned short rows,
				   unsigned short columns)
{
	unsigned short i;
	*array3D = (short***)calloc(frames, sizeof(short**));

	for (i = 0; i < frames; i++)
	{
		get_mem2Dpixel(*array3D + i, rows, columns, 0);
	}
	return frames * rows * columns;
}

void free_mem3Dpixel(short*** array3D, unsigned short frames)
{
	unsigned short i;
	if ( array3D )
	{
		for ( i = 0; i < frames; i++ )
		{
			free_mem2Dpixel(array3D[i]);
		}
		free(array3D);
	}
}


