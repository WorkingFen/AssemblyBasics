#ifndef TETRA_H_
#define TETRA_H_

typedef struct Vertex{
	int x;
	int y;
	int z;
	double real_x;
	double real_y;
	double real_z;
}vertex;

void tetra(unsigned char* line[], int widht, int height, unsigned char* zBuffer[], vertex* first, vertex* second, vertex* third, vertex* fourth);
#endif // TETRA_h_
