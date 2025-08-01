nasm -f win64 distance_kernel.asm -o distance_kernel.obj
gcc -c main.c -o main.obj -m64
gcc main.obj distance_kernel.obj -o vector_distance.exe -m64 -lm
vector_distance.exe