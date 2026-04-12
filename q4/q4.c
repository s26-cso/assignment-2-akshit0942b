#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int main() 
{
    char op[6];
    int num1, num2;

    while (scanf("%5s %d %d", op, &num1, &num2) == 3) 
    {
        char lib_name[32];
        snprintf(lib_name, sizeof(lib_name), "./lib%s.so", op);

        void *handle = dlopen(lib_name, RTLD_LAZY);
        if (!handle) {
            fprintf(stderr, "Error loading library: %s\n", dlerror());
            continue;
        }

        dlerror();

        typedef int (*op_func_t)(int, int);
        op_func_t op_func = (op_func_t) dlsym(handle, op);
        
        char *error = dlerror();
        if (error != NULL) {
            fprintf(stderr, "Error finding symbol: %s\n", error);
            dlclose(handle);
            continue;
        }

        // Execute the function and print the result
        int result = op_func(num1, num2);
        printf("%d\n", result);

        // Close the library to free memory
        if (dlclose(handle) != 0) {
            fprintf(stderr, "Error closing library: %s\n", dlerror());
        }
    }

    return 0;
}
