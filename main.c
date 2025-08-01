#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <string.h>

extern void calculate_distances_asm(int n, float* x1, float* x2, float* y1, float* y2, float* z);

void calculate_distances_c(int n, float* x1, float* x2, float* y1, float* y2, float* z) {
    for (int i = 0; i < n; i++) {
        float dx = x2[i] - x1[i];
        float dy = y2[i] - y1[i];
        z[i] = sqrtf(dx * dx + dy * dy);
    }
}

void initialize_vectors(int n, float* x1, float* x2, float* y1, float* y2) {
    srand(time(NULL));
    for (int i = 0; i < n; i++) {
        x1[i] = (float)rand() / RAND_MAX * 10.0f;
        x2[i] = (float)rand() / RAND_MAX * 10.0f;
        y1[i] = (float)rand() / RAND_MAX * 10.0f;
        y2[i] = (float)rand() / RAND_MAX * 10.0f;
    }
}

int verify_results(int n, float* z_c, float* z_asm, float tolerance) {
    for (int i = 0; i < n; i++) {
        if (fabs(z_c[i] - z_asm[i]) > tolerance) {
            printf("Mismatch at index %d: C=%.6f, ASM=%.6f\n", i, z_c[i], z_asm[i]);
            return 0;
        }
    }
    return 1;
}

double time_kernel(void (*kernel)(int, float*, float*, float*, float*, float*), 
                   int n, float* x1, float* x2, float* y1, float* y2, float* z, int iterations) {
    clock_t start = clock();
    for (int i = 0; i < iterations; i++) {
        kernel(n, x1, x2, y1, y2, z);
    }
    clock_t end = clock();
    return ((double)(end - start)) / CLOCKS_PER_SEC / iterations;
}

int main() {
    unsigned int iterations;
    printf("Enter the number of iterations for performance testing: ");
    if (scanf("%u", &iterations) != 1 || iterations == 0) {
        printf("Invalid input. Using default value of 30 iterations.\n");
        iterations = 30;
    }
    
    int sizes[] = {1048576, 16777216, 134217728}; // 2^20, 2^24, 2^30
    int num_sizes = sizeof(sizes) / sizeof(sizes[0]);
    
    printf("%u Iterations\n", iterations);
    printf("%-12s %-15s %-15s\n", "Vector Size", "C RunTime", "ASM RunTime");
    printf("-------------------------------------------------------\n");
    
    for (int s = 0; s < num_sizes; s++) {
        int n = sizes[s];
        
        // Allocate memory
        float* x1 = (float*)malloc(n * sizeof(float));
        float* x2 = (float*)malloc(n * sizeof(float));
        float* y1 = (float*)malloc(n * sizeof(float));
        float* y2 = (float*)malloc(n * sizeof(float));
        float* z_c = (float*)malloc(n * sizeof(float));
        float* z_asm = (float*)malloc(n * sizeof(float));
        
        if (!x1 || !x2 || !y1 || !y2 || !z_c || !z_asm) {
            printf("Memory allocation failed for size %d\n", n);
            continue;
        }
        
        // Initialize vectors
        initialize_vectors(n, x1, x2, y1, y2);
        
        // Time C version
        double time_c = time_kernel(calculate_distances_c, n, x1, x2, y1, y2, z_c, iterations);
        
        // Time ASM version
        double time_asm = time_kernel(calculate_distances_asm, n, x1, x2, y1, y2, z_asm, iterations);
        
        // Verify correctness for first 100 elements
        int verify_count = (n < 100) ? n : 100;
        int correct = verify_results(verify_count, z_c, z_asm, 1e-5f);
        
        double speedup = time_c / time_asm;
        
        printf("%-12d %-15.6f %-15.6f %-10.2fx %s\n", n, time_c, time_asm, speedup, 
               correct ? "" : "(INCORRECT)");
        
        // Display first 10 elements for smallest size
        if (n == sizes[0]) {
            printf("\nFirst 10 elements comparison:\n");
            printf("Index:  C Result     ASM Result   Difference\n");
            for (int i = 0; i < 10 && i < n; i++) {
                printf("%-6d  %-11.6f  %-11.6f  %.2e\n", i, z_c[i], z_asm[i], 
                       fabs(z_c[i] - z_asm[i]));
            }
            printf("\n");
        }
        
        // Free memory
        free(x1); free(x2); free(y1); free(y2); free(z_c); free(z_asm);
    }
    

    
    return 0;
}