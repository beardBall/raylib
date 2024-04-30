
#include<stdio.h>

int main(){

#if (defined(__STDC__) && __STDC_VERSION__ >= 199901L) || (defined(_MSC_VER) && _MSC_VER >= 1800)
// #include <stdbool.h>
printf("STDC version: %ld \n", __STDC_VERSION__);

#elif !defined(__cplusplus) && !defined(bool)
    typedef enum bool
    {
        false = 0,
        true = !false
    } bool;
#define RL_BOOL_TYPE
#endif

    printf("\nhello!\n");
    printf("STDC version: %ld \n", __STDC_VERSION__);
    // printf("__STDC_LIB_EXT1__: %ld \n", __STDC_LIB_EXT1__);
}