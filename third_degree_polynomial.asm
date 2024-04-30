	.data
	.align 2
info:	.asciz	"Third degree polynomial generator (ax^3 + bx^2 + cx + d):\n"
prompt:	.asciz	"Insert coefficients of polynomial (all coefficients should be between [-128, 128):\n"
in:	.asciz	"in.bmp"
out:	.asciz	"out.bmp"
buffer:	.space	4	#bmp header
prompt_a:	.asciz	"Enter a:\n"
prompt_b:	.asciz	"Enter b:\n"
prompt_c:	.asciz	"Enter c:\n"
prompt_d:	.asciz 	"Enter d:\n"
error_m:	.asciz 	"Error occured\n"

	.align	2
width:	.space	4

	.align	2
height:	.space	4

	.align	2
size:	.space	4

	.align	2
start:	.space	4

	.align	2
offset:	.space	4

	.align	2
a:	.space	4 # ax^3

	.align	2
b:	.space	4 # bx^2

	.align	2
c:	.space	4 # cx

	.align	2
d:	.space	4 # d

	.align	2
parser:	.space	100

	.text
	.globl main
	# s0 - size
	# s1 - address of memory allocated on heap
	# s2 - width
	# s3 - height
	# s4 - x coor
	# s5 - counter
	# s6 - height /2
	# s7 - padding
	
main:	
	li a7, 4
	la a0, info
	ecall
	
read_bmp:

	#opening bmp file
	la a0, in
	li a1, 0
	li a7, 1024
	ecall
	
	#file descriptor
	mv t0, a0
	bltz t0, error
	
	#read 'BM'
	mv a0, t0
	la a1, buffer
	li a2, 2
	li a7, 63
	ecall
	
	#read size of file
	mv a0, t0
	la a1, size
	li a2, 4
	li a7, 63
	ecall
	
	lw s0, size
	
	#sbrk call
	mv a0, s0
	li a7, 9
	ecall
	
	#address of memory allocated on a heap
	mv s1, a0
	la t1, start
	sw s1, (t1)
	
	#read next 4 bytes
	mv a0, t0
	la a1, buffer
	li a2, 4
	li a7, 63
	ecall
	
	#read offset
	mv a0, t0
	la a1, offset
	li a2, 4
	li a7, 63
	ecall
	
	#read 4 bytes of info header
	mv a0, t0
	la a1, buffer
	li a2, 4
	li a7, 63
	ecall
	
	#read width of a pic
	mv a0, t0
	la a1, width
	li a2, 4
	li a7, 63
	ecall
	lw s2, width
	
	#read height of a pic
	mv a0, t0
	la a1, height
	li a2, 4
	li a7, 63
	ecall
	lw s3, height 
	
	#close input file
	mv a0, t0
	li a7, 57
	ecall

read_pixels:
	la a0, in
	li a1, 0
	li a7, 1024
	ecall
	
	mv t0, a0
	bltz t0, error
	
	mv a0, t0
	mv a1, s1
	mv a2, s0
	li a7, 63
	ecall
	
	mv a0, t0
	li a7, 57
	ecall
	
	# Q8.24
read_coefficients:
	li a7, 4
	la a0, prompt
	ecall
		
read_a:
	li a7, 4
	la a0, prompt_a
	ecall
	
	li a7, 5
	ecall
	
	mv t1, a0
	
	slli t1, t1, 24
	la t0, a
	sw t1, (t0)

read_b:
	li a7, 4
	la a0, prompt_b
	ecall
	
	li a7, 5
	ecall
	
	mv t1, a0
	
	slli t1, t1, 24
	la t0, b
	sw t1, (t0)	

read_c:
	li a7, 4
	la a0, prompt_c
	ecall
	
	li a7, 5
	ecall
	
	mv t1, a0
	
	slli t1, t1, 24
	la t0, c
	sw t1, (t0)
	
read_d:
	li a7, 4
	la a0, prompt_d
	ecall
	
	li a7, 5
	ecall
	
	mv t1, a0
	
	slli t1, t1, 24
	la t0, d
	sw t1, (t0)

set:
	li s4, 0xfe000000 #min value (-2)
	li s5, 0 #counter
	
	#height / 2
	srli s6, s3, 1
	
	#padding
	slli t0, s2, 1
	add t0, t0, s2
	andi s7, t0, 0x03

loop:
	lw t2, a
	lw t3, b
	lw t4, c
	lw t5, d
	
	#calculate ax^3
	li a7, 3 #counter
	mv t0, t2

a_inner_loop:

	mul a0, t0, s4
	mulh a1, t0, s4
	srli a0, a0, 24
	slli a1, a1, 8
	or t0, a0, a1
	addi a7, a7, -1
	bnez a7, a_inner_loop
	
	#calculate bx^2
	li a7, 2

b_inner_loop:
	
	mul a0, t3, s4
	mulh a1, t3, s4
	srli a0, a0, 24
	slli a1, a1, 8
	or t3, a0, a1
	addi a7, a7, -1
	bnez a7, b_inner_loop
	
	#calculate cx
	mul a0, t4, s4
	mulh a1, t4, s4
	srli a0, a0, 24
	slli a1, a1, 8
	or t4, a0, a1
	
	#add all
	add t0, t0, t3
	add t0, t0, t4
	add t0, t0, t5
	
	srai t0, t0, 16
	mv t1, s5
	li t6, 0x00010000
	add s4, s4, t6 # 1/256
	addi s5, s5, 1 # next pixel
	li t6, 511
	bgt t0, t6, loop
	li t6, -512
	blt t0, t6, loop #value out of borders
	add t0, t0, s6
	
change:
	# s0 - offset
	# s1 - start
	# s2 - width
	# s3 - height
	# s4 - x coor
	# s5 - counter
	# s6 - height / 2
	# s7 - padding
	
	lw s1, start
	lw s0, offset
	add s1, s1, s0
	
	# y coor
	slli t2, s2, 1
	add t2, t2, s2
	mul t2, t2, t0
	add s1, s1, t2
	
	# x coor
	mv a3, t1
	slli t1, t1, 1
	add t1, t1, a3
	add s1, s1, t1
	
	# padding
	mul t2, t0, s7
	add s1, s1, t2
	
	# colouring pixels
	li t2, 0xff
	sb t2, (s1)
	addi s1, s1, 1
	li t2, 0x00
	sb t2, (s1)
	addi s1, s1, 1
	sb t2, (s1)
	addi s1, s1, 1
	blt s5, s2, loop

save:
	# save new pic
	la a0, out
	li a1, 1
	li a7, 1024
	ecall
	
	mv t0, a0 #file descriptor
	bltz t0, error
	
	lw s0, size
	lw s1, start
	
	# save to file
	mv a0, t0
	mv a1, s1
	mv a2, s0
	li a7, 64
	ecall
	
	#close file
	mv a0, t0
	li a7, 57
	ecall
	


end:
	li a7, 10
	ecall

error:
	li a7, 4
	la a0, error_m
	ecall
	j end
