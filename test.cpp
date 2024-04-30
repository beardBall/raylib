
#include<stdio.h>

int main(){
#define boool

#ifndef bool
printf("\nbool not defined!\n");
#endif

bool b = true;
printf("\nhello! %d  \n", b);
printf("STDC version:  \n");
// printf("__STDC_LIB_EXT1__: %ld \n", __STDC_LIB_EXT1__);
}