#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void func(char*);

int main(int argc, char* argv[]){
    char* uText = (char*)0;

    if(argc<2){
        printf("Not enough arguments.\n Run program as \"%s<some alphanumeric text>\"\n", argv[0]);
        return -1;
    }

    uText = malloc(strlen(argv[1])+1);
    if(uText == NULL){
        printf("Memory allocation failed");
        return -1;
    }

    strcpy(uText, argv[1]);

    func(uText);

    printf("Original text and modified text:\n %s\n %s\n", argv[1], uText);

    free(uText);

    return 0;
}