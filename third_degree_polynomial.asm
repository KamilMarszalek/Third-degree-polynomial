	.data
info:	.asciz	"Third degree polynomial generator (ax^3 + bx^2 + cx + d):\n"
prompt:	.asciz	"Insert coefficients of polynomial (all coefficients should be between [-16, 16):\n"
in:	.asciz	"input1.bmp"
out:	.asciz	"output1.bmp"
buffer:	.space	4	
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
	
	# Prompt for input
    	li a7, 4                      
    	la a0, prompt_a               
    	ecall                         

    	li a7, 8                      
    	la a0, parser                 
    	li a1, 100                    
    	ecall                         

    	la a3, parser                 
    	li t5, '.'                   
    	li t3, '0'                   
    	li t4, 10 
    	li s11, 0 # length of fraction part 
    	li t0, '-'                    

	li a6, 0                      
    	li t1, 0 

a_check_sign:
	
	# Check if input is negative
	lb t6, (a3)
	li a5, 1
	bne t6, t0, a_loop_int_part                                   
	li a5, -1
	addi a3, a3, 1
	
a_loop_int_part:
	
	#calculate the int part
    	lb t6, (a3)                   
    	beqz t6, a_loop_fraction_part 
    	blt t6, t3, a_loop_fraction_part  
    	beq t6, t5, a_loop_fraction_part  
    	addi t6, t6, -48
    	mul a6, a6, t4 
    	add a6, a6, t6 
    	addi a3, a3, 1   
    	j a_loop_int_part

a_loop_fraction_part:
	
	# skip '.'
    	addi a3, a3, 1         

a_fraction_part_loop:
	
	# calculate fraction part as int
    	lb t6, (a3)                   
    	blt t6, t3, a_count_comp_factor    
    	addi t6, t6, -48 
    	mul t1, t1, t4
    	add t1, t1, t6
    	addi a3, a3, 1
    	addi s11, s11, 1                
    	j a_fraction_part_loop     
    
a_count_comp_factor:
	
	# calculate the closest '1' for fraction part
	li a0, 1
	
a_count_comp_factor_loop:
	
	beqz s11, a_calc_fraction_part
	mul a0, a0, t4
	addi s11, s11, -1
	j a_count_comp_factor_loop

a_calc_fraction_part:

	# calculate binary equivalent of fraction part
	li s10, 0 # fraction 
	mv t3, t1
	li t2, 0 #counter
	li t0, 23

a_calc_fraction_part_loop:
	
	slli t3, t3, 1
	beq t3, a0, a_add_1
	beq t2, t0, a_prepare_to_store
	blt t3, a0, a_add_0

a_add_1:
	
	li t6, 1
	sub s9, t0, t2
	sll t6, t6, s9
	add s10, s10, t6
	sub t3, t3, a0
	beqz t3, a_prepare_to_store

a_add_0:
	
	addi t2, t2, 1
	j a_calc_fraction_part_loop 
	
a_prepare_to_store: 
	
	# Sum int and fraction part
    	slli a6, a6, 24                 
    	add a6, a6, s10 
    	mul a6, a6, a5               
    	la t6, a                      
    	sw a6, (t6)

read_b:
	
	# Prompt for input
    	li a7, 4                      
    	la a0, prompt_b              
    	ecall                         

    	li a7, 8                      
    	la a0, parser                 
    	li a1, 100                    
    	ecall                         

    	la a3, parser                 
    	li t5, '.'                   
    	li t3, '0'                   
    	li t4, 10 
    	li s11, 0 # length of fraction part 
    	li t0, '-'                    

	li a6, 0                      
    	li t1, 0 

b_check_sign:
	
	# Check if input is negative
	lb t6, (a3)
	li a5, 1
	bne t6, t0, b_loop_int_part                                   
	li a5, -1
	addi a3, a3, 1
	
b_loop_int_part:
	
	#calculate the int part
    	lb t6, (a3)                   
    	beqz t6, b_loop_fraction_part 
    	blt t6, t3, b_loop_fraction_part  
    	beq t6, t5, b_loop_fraction_part  
    	addi t6, t6, -48
    	mul a6, a6, t4 
    	add a6, a6, t6 
    	addi a3, a3, 1   
    	j b_loop_int_part

b_loop_fraction_part:
	
	# skip '.'
    	addi a3, a3, 1         

b_fraction_part_loop:
	
	# calculate fraction part as int
    	lb t6, (a3)                   
    	blt t6, t3, b_count_comp_factor    
    	addi t6, t6, -48 
    	mul t1, t1, t4
    	add t1, t1, t6
    	addi a3, a3, 1
    	addi s11, s11, 1                
    	j b_fraction_part_loop     
    
b_count_comp_factor:
	
	# calculate the closest '1' for fraction part
	li a0, 1
	
b_count_comp_factor_loop:
	
	beqz s11, b_calc_fraction_part
	mul a0, a0, t4
	addi s11, s11, -1
	j b_count_comp_factor_loop

b_calc_fraction_part:

	# calculate binary equivalent of fraction part
	li s10, 0 # fraction 
	mv t3, t1
	li t2, 0 #counter
	li t0, 23

b_calc_fraction_part_loop:

	slli t3, t3, 1
	beq t3, a0, b_add_1
	beq t2, t0, b_prepare_to_store
	blt t3, a0, b_add_0

b_add_1:

	li t6, 1
	sub s9, t0, t2
	sll t6, t6, s9
	add s10, s10, t6
	sub t3, t3, a0
	beqz t3, b_prepare_to_store

b_add_0:
	
	addi t2, t2, 1
	j b_calc_fraction_part_loop 
	
b_prepare_to_store: 
	
	# Sum int and fraction part
    	slli a6, a6, 24                 
    	add a6, a6, s10 
    	mul a6, a6, a5               
    	la t6, b                      
    	sw a6, (t6)

read_c:
	
	# Prompt for input
    	li a7, 4                      
    	la a0, prompt_c               
    	ecall                         

    	li a7, 8                      
    	la a0, parser                 
    	li a1, 100                    
    	ecall                         

    	la a3, parser                 
    	li t5, '.'                   
    	li t3, '0'                   
    	li t4, 10 
    	li s11, 0 # length of fraction part 
    	li t0, '-'                    

	li a6, 0                      
    	li t1, 0 

c_check_sign:
	
	# Check if input is negative
	lb t6, (a3)
	li a5, 1
	bne t6, t0, c_loop_int_part                                   
	li a5, -1
	addi a3, a3, 1
	
c_loop_int_part:
	
	#calculate the int part
    	lb t6, (a3)                   
    	beqz t6, c_loop_fraction_part 
    	blt t6, t3, c_loop_fraction_part  
    	beq t6, t5, c_loop_fraction_part  
    	addi t6, t6, -48
    	mul a6, a6, t4 
    	add a6, a6, t6 
    	addi a3, a3, 1   
    	j c_loop_int_part

c_loop_fraction_part:
	
	# skip '.'
    	addi a3, a3, 1         

c_fraction_part_loop:
	
	# calculate fraction part as int
    	lb t6, (a3)                   
    	blt t6, t3, c_count_comp_factor    
    	addi t6, t6, -48 
    	mul t1, t1, t4
    	add t1, t1, t6
    	addi a3, a3, 1
    	addi s11, s11, 1                
    	j c_fraction_part_loop     
    
c_count_comp_factor:
	
	# calculate the closest '1' for fraction part
	li a0, 1
	
c_count_comp_factor_loop:
	
	beqz s11, c_calc_fraction_part
	mul a0, a0, t4
	addi s11, s11, -1
	j c_count_comp_factor_loop

c_calc_fraction_part:
	
	# calculate binary equivalent of fraction part
	li s10, 0 # fraction 
	mv t3, t1
	li t2, 0 #counter
	li t0, 23
	
c_calc_fraction_part_loop:
	
	slli t3, t3, 1
	beq t3, a0, c_add_1
	beq t2, t0, c_prepare_to_store
	blt t3, a0, c_add_0

c_add_1:
	
	li t6, 1
	sub s9, t0, t2
	sll t6, t6, s9
	add s10, s10, t6
	sub t3, t3, a0
	beqz t3, c_prepare_to_store

c_add_0:
	
	addi t2, t2, 1
	j c_calc_fraction_part_loop 
	
c_prepare_to_store: 
	
	# Sum int and fraction part
    	slli a6, a6, 24                 
    	add a6, a6, s10 
    	mul a6, a6, a5               
    	la t6, c                      
    	sw a6, (t6)

read_d:
	
	# Prompt for input
    	li a7, 4                      
    	la a0, prompt_d               
    	ecall                         

    	li a7, 8                      
    	la a0, parser                 
    	li a1, 100                    
    	ecall                         

    	la a3, parser                 
    	li t5, '.'                   
    	li t3, '0'                   
    	li t4, 10 
    	li s11, 0 # length of fraction part 
    	li t0, '-'                    

	li a6, 0                      
    	li t1, 0 

d_check_sign:
	
	# Check if input is negative
	lb t6, (a3)
	li a5, 1
	bne t6, t0, d_loop_int_part                                   
	li a5, -1
	addi a3, a3, 1
	
d_loop_int_part:
	
	#calculate the int part
    	lb t6, (a3)                   
    	beqz t6, d_loop_fraction_part 
    	blt t6, t3, d_loop_fraction_part  
    	beq t6, t5, d_loop_fraction_part  
    	addi t6, t6, -48
    	mul a6, a6, t4 
    	add a6, a6, t6 
    	addi a3, a3, 1   
    	j d_loop_int_part

d_loop_fraction_part:
	
	# skip '.'
    	addi a3, a3, 1         

d_fraction_part_loop:
	
	# calculate fraction part as int
    	lb t6, (a3)                   
    	blt t6, t3, d_count_comp_factor    
    	addi t6, t6, -48 
    	mul t1, t1, t4
    	add t1, t1, t6
    	addi a3, a3, 1
    	addi s11, s11, 1                
    	j d_fraction_part_loop     
    
d_count_comp_factor:
	
	# calculate the closest '1' for fraction part
	li a0, 1

d_count_comp_factor_loop:
	
	beqz s11, d_calc_fraction_part
	mul a0, a0, t4
	addi s11, s11, -1
	j d_count_comp_factor_loop

d_calc_fraction_part:
	
	# calculate binary equivalent of fraction part
	li s10, 0 # fraction 
	mv t3, t1
	li t2, 0 #counter
	li t0, 23
	
d_calc_fraction_part_loop:
	
	slli t3, t3, 1
	beq t3, a0, d_add_1
	beq t2, t0, d_prepare_to_store
	blt t3, a0, d_add_0

d_add_1:
	
	li t6, 1
	sub s9, t0, t2
	sll t6, t6, s9
	add s10, s10, t6
	sub t3, t3, a0
	beqz t3, d_prepare_to_store

d_add_0:
	
	addi t2, t2, 1
	j d_calc_fraction_part_loop 
	
d_prepare_to_store: 
	
	# Sum int and fraction part
    	slli a6, a6, 24                 
    	add a6, a6, s10 
    	mul a6, a6, a5               
    	la t6, d                      
    	sw a6, (t6)

set:
	
	li s4, 0xf8000000 #min value (-8)
	li s5, 0 #counter
	
	#height / 2
	srli s6, s3, 1
	
	#padding
	slli t0, s2, 1
	add t0, t0, s2
	andi s7, t0, 0x03 #mod 4
	
	#finding borders of pic
	la t1, width 
	lw s8, (t1)
	mv s9, s8
	srli s8, s8, 1 # maximal px
	addi s8, s8, -1
	srli s9, s9, 1 
	neg s9, s9 #minimal px
	
	#calculate scale based on image width
	li t6, 1024
	div t6, t6, s2 
	mv s10, t6 #Scale factor based on standard width 1024
	li t6, 18 #Standard shift amount for 1024x1024
	add t6, t6, s10 #Adjust shift based on scale
	addi t6, t6, -1
	mv s11, t6 #Shift amount

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
	li a7, 2 #counter

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
	
	#apply scale and shift
	sra t0, t0, s11
	
	
	mv t1, s5
	li t6, 0x00040000
	mul t6, t6, s10
	add s4, s4, t6 # Increment x-coordinate 
	addi s5, s5, 1 # next pixel
	bgt t0, s8, loop #value out of borders
	blt t0, s9, loop #value out of borders
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
	li t2, 0x00
	sb t2, (s1)
	addi s1, s1, 1
	sb t2, (s1)
	addi s1, s1, 1
	li t2, 0xff
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
