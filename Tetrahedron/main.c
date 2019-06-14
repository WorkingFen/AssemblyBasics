#include <stdio.h>
#include <stdlib.h>
#include <allegro.h>
#include <math.h>
#include <stdbool.h>

#include "tetra.h"

#define PI 3.14159265
#define UP 1
#define DOWN 0
#define RIGHT 1
#define LEFT 0

#define WIDTH 600
#define HEIGHT 600
#define DEPTH 600
#define ANGLE 90

void accuracy_change(vertex* v){
	v->x = (int)(round(v->real_x));
	v->y = (int)(round(v->real_y));
	v->z = (int)(round(v->real_z));	
}

void rotate_XZ(vertex* v, bool dir, int angle) {
	double rad, new_x, new_z, old_x, old_z;

	if(dir) rad = angle*PI/180;
	else rad = -angle*PI/180;

	old_x = v->real_x - WIDTH/2;
	old_z = v->real_z - DEPTH/2;

	new_x = old_x*cos(rad) - old_z*sin(rad);
	new_z = old_x*sin(rad) + old_z*cos(rad);

	v->real_x = new_x + WIDTH/2;
	v->real_z = new_z + DEPTH/2;
	accuracy_change(v);
}

void rotate_YZ(vertex* v, bool dir, int angle) {
	double rad, new_y, new_z, old_y, old_z;

	if(dir) rad = angle*PI/180;
	else rad = -angle*PI/180;

	old_y = v->real_y - HEIGHT/2;
	old_z = v->real_z - DEPTH/2;

	new_y = old_y*cos(rad) - old_z*sin(rad);
	new_z = old_y*sin(rad) + old_z*cos(rad);

	v->real_y = new_y + HEIGHT/2;
	v->real_z = new_z + DEPTH/2;
	accuracy_change(v);
}

void create_vertex(vertex* v, int x, int y, int z) {
	v->x = x;
	v->real_x = x;
	v->y = y;
	v->real_y = y;
	v->z = z;
	v->real_z = z;
} 

void logs(vertex* first, vertex* second, vertex* third, vertex* fourth) {
	printf("First vertex, %d, %d, %d\n", first->x, first->y, first->z);
	printf("Second vertex, %d, %d, %d\n", second->x, second->y, second->z);
	printf("Third vertex, %d, %d, %d\n", third->x, third->y, third->z);
	printf("Fourth vertex, %d, %d, %d\n", fourth->x, fourth->y, fourth->z);
}

int main(int argc, char* argv[]){
	if(argc < 13){
		printf("ERROR: Wrong amount of arguments\n");
	       	return 1;
	}

	bool change = false;

	allegro_init();
	install_keyboard();
	set_color_depth(24);
	set_gfx_mode(GFX_AUTODETECT_WINDOWED, WIDTH, HEIGHT, 0, 0);

	vertex* first = malloc(sizeof(vertex));
	vertex* second = malloc(sizeof(vertex));
	vertex* third = malloc(sizeof(vertex));
	vertex* fourth = malloc(sizeof(vertex));

	create_vertex(first, atoi(argv[1]), atoi(argv[2]), atoi(argv[3]));
	printf("First vertex, %d, %d, %d\n", first->x, first->y, first->z);

	create_vertex(second, atoi(argv[4]), atoi(argv[5]), atoi(argv[6]));
	printf("Second vertex, %d, %d, %d\n", second->x, second->y, second->z);

	create_vertex(third, atoi(argv[7]), atoi(argv[8]), atoi(argv[9]));
	printf("Third vertex, %d, %d, %d\n", third->x, third->y, third->z);

	create_vertex(fourth, atoi(argv[10]), atoi(argv[11]), atoi(argv[12]));
	printf("Fourth vertex, %d, %d, %d\n", fourth->x, fourth->y, fourth->z);

	BITMAP * canvas = create_bitmap_ex(24, WIDTH, HEIGHT); 
	if(!canvas){
		set_gfx_mode(GFX_TEXT, 0, 0, 0, 0);
		allegro_message("Can't create new bitmap!");
		allegro_exit();
		free(first);
		free(second);
		free(third);
		free(fourth);
		return 1;
	}

	BITMAP * zBuffer = create_bitmap_ex(16, WIDTH, HEIGHT); 
	if(!zBuffer){
		set_gfx_mode(GFX_TEXT, 0, 0, 0, 0);
		allegro_message("Can't create zBuffer!");
		allegro_exit();
		free(first);
		free(second);
		free(third);
		free(fourth);
		return 1;
	}
	
	clear_to_color(canvas, makecol(255,255,255));
	clear_to_color(zBuffer, makecol(255,255,255));
	tetra(canvas->line, canvas->w, canvas->h, zBuffer->line, first, second, third, fourth);
	blit(canvas, screen, 0, 0, 0, 0, canvas->w, canvas->h);
	while(!key[KEY_ESC]){
		if(key[KEY_H]){
			printf("## Help: \n");
			printf("# Upward Y Axis Rotation - UP/W \n");
			printf("# Downward Y Axis Rotation - DOWN/S \n");
			printf("# Upward X Axis Rotation - RIGHT/D \n");
			printf("# Downward X Axis Rotation - LEFT/A \n");
		}
		else if(key[KEY_UP] || key[KEY_W]){
			rotate_YZ(first, UP, ANGLE);
			rotate_YZ(second, UP, ANGLE);
			rotate_YZ(third, UP, ANGLE);
			rotate_YZ(fourth, UP, ANGLE);
			change = true;
			logs(first, second, third, fourth);
			printf("Changed UP\n");
		}
		else if(key[KEY_DOWN] || key[KEY_S]){
			rotate_YZ(first, DOWN, ANGLE);
			rotate_YZ(second, DOWN, ANGLE);
			rotate_YZ(third, DOWN, ANGLE);
			rotate_YZ(fourth, DOWN, ANGLE);
			change = true;
			logs(first, second, third, fourth);
			printf("Changed DOWN\n");
		}
		else if(key[KEY_LEFT] || key[KEY_A]){	
			rotate_XZ(first, LEFT, ANGLE);
			rotate_XZ(second, LEFT, ANGLE);
			rotate_XZ(third, LEFT, ANGLE);
			rotate_XZ(fourth, LEFT, ANGLE);
			change = true;
			logs(first, second, third, fourth);
			printf("Changed LEFT\n");
		}
		else if(key[KEY_RIGHT] || key[KEY_D]){
			rotate_XZ(first, RIGHT, ANGLE);
			rotate_XZ(second, RIGHT, ANGLE);
			rotate_XZ(third, RIGHT, ANGLE);
			rotate_XZ(fourth, RIGHT, ANGLE);
			change = true;
			logs(first, second, third, fourth);
			printf("Changed RIGHT\n");
		}	
		if(change){
			clear_to_color(canvas, makecol(255,255,255));
			clear_to_color(zBuffer, makecol(255,255,255));
			tetra(canvas->line, canvas->w, canvas->h, zBuffer->line, first, second, third, fourth);	
			blit(canvas, screen, 0, 0, 0, 0, canvas->w, canvas->h);
			change = false;
			printf("Change saved\n");		
		}				
		readkey();
	}
	destroy_bitmap(zBuffer);
	destroy_bitmap(canvas);
	allegro_exit();
	free(first);
	free(second);
	free(third);
	free(fourth);
	return 0;
}

