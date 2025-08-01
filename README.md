<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/8f4d2555-ce7e-4a2b-b5d1-8a9d4f0e8a4c" />

Our analysis showed that assembly was faster at computing the distance of the vectors. Over 30 iterations, the C file took 0.007633 seconds on average while the Assembly file took 0.000867. This could be due to the following reasons:
- In assembly, instructions are manually controlled, allowing us to individually optimize loops, memory access, etc. The speed of our C program may be varied depending on the compiler.
- Our assembly code operates on 4 single-precision floats at once using xmm registers and SSE instructions, then does the math in parallel, which could be making it faster than the C program.
- The C program could be slower due to extra overhead from things such as type checking and function call conventions.
