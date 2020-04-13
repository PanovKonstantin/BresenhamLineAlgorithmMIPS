 # Drawing a straight line with Bresenham algorithm on a BMP image with sizes being a power of 2. 

.eqv	headeraddr 	0
.eqv    filesize   	4
.eqv	imgaddr    	8
.eqv	imgwidth   	12
.eqv    imgheight  	16
.eqv    rowsize		20
.eqv	buffor		16384

.data
imgdescriptor: 	.word 0
		.word 0
		.word 0
		.word 0
		.word 0
		.word 0
coordinates:	.word 0
		.word 0
		.word 0
		.word 0
img:		.space  buffor
fname:		.asciiz "empty.bmp"
outfname: 	.asciiz "outfile.bmp"


.text
main:
	j draw_line_test
main_exit:
	li $v0, 10
	syscall


draw_line_test:
# Read image
	la $a0, imgdescriptor
	la $a1, fname
	jal read_bmp_file
	bltz $v0, main_exit

	la $s0, 128	# x1
	la $s1, 128	# y1
	la $s2, 0	# x2
	la $s3, 0	# y2

draw_line_test_1:
	la $a0, imgdescriptor
	la $a1, coordinates
	sw $s0, 0($a1)
	sw $s1, 4($a1)
	sw $s2, 8($a1)
	sw $s3, 12($a1)
	jal draw_line
	add $s2, $s2, 64
	ble $s2, 256, draw_line_test_1
	la $s2, 0
	add $s3, $s3, 64
	ble $s3, 256, draw_line_test_1
	
draw_lines_test_close:
	la $a0, imgdescriptor
	la $a1, outfname
	jal save_bmp_file
	j main_exit

draw_line:
# remember the return address
	addiu $sp, $sp, -4
	sw $ra, ($sp)
	# $a0 - desc
	# $a1 - x1
	# $a2 - y1
	# $a3 - mask
	# $t0 - pixel address
	# $t1 - extra
	# $t2 - x2
	# $t3 - y2
	# $t4 - dx
	# $t5 - dy
	# $t6 - sx
	# $t7 - sy
	# $t8 - err
	# $t9 - bytes_per_row
	la $t0, ($a1)	# t0 - coordinates
	lw $a1, 0($t0)  # a1 - x1
	lw $a2, 4($t0)  # a2 - y1
	lw $t2, 8($t0)  # t2 - x2
	lw $t3, 12($t0) # t3 - y2



	la $t6, 1 # sx = 1 	increment or decrement x
	la $t7, -1 # sy = -1	increment or decrement y
	sub $t4, $t2, $a1	# dx = x2 - x1
	slt $t8, $t4, $zero
	beq $t8, $zero, dx_is_positive	# if  x1 > x2:
	sub $t4, $zero, $t4	# dx = |x2 - x1|
	la $t6, -1	# set sx to decrement
dx_is_positive:
	sub $t5, $t3, $a2	# dy = y2 - y1
	slt $t8, $zero, $t5
	beq $t8, $zero, dy_is_negative	# if  y1 < y2:
	sub $t5, $zero, $t5	# dy = -|y2- y1|
	la $t7, 1	# set sy to increment
dy_is_negative:
	add $t8, $t4, $t5	# error = dx + dy
	lw $t9, rowsize($a0)	# Bytes per row
	mul $t0, $t9, $a2	# t0 = y * bytes per row
	srl $t1, $a1, 3		# t1 = x >> 3
	add $t0, $t0, $t1	# t0 = y*bytes per row + x >> 8
	lw $t1, imgaddr($a0)	# image address
	add $t0, $t0, $t1	# t0 = y * bytes_per_row + x >> 8 + image_address


draw_line_loop:
# plot x, y
	
# create mask
	andi $t1, $a1, 0x07	# x and 00000111
	li $a3, 0x80		# t2 -  10000000
	srlv $a3, $a3, $t1	# 1 <-> 10000000
	lb $t1, 0($t0)		
	not $a3, $a3		# set pixel black
	and $t1 $t1, $a3
	sb $t1, 0($t0)
	
# if x0 == x1 and y0 == y1, stop loop
	seq $t1, $a1, $t2
	beq $t1, $zero, increment_x
	seq $t1, $a2, $t3
	beq $t1, $zero, increment_y
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
	
increment_x:

	sll $t1, $t8, 1 # 2 * err
	blt $t1, $t5, increment_y	# if err * 2 >= dy
	add $t8, $t8, $t5	# err += dy
	srl $t1, $a1, 3
	sub $t0, $t0, $t1
	add $a1, $a1, $t6	# x++ / x--
	srl $t1, $a1, 3
	add $t0, $t0, $t1
	seq $t1, $a2, $t3
	beq $t1, $zero, increment_y
	j draw_line_loop
	
increment_y:
	sll $t1, $t8, 1 # 2 * err
	bgt $t1, $t4, draw_line_loop	# if err * 2 < dx
	add $t8, $t8, $t4	# err += dx
	add $a2, $a2, $t7	# y++ / y--
	blt $t7, $zero, draw_down
	add $t0, $t0, $t9
	j draw_line_loop
draw_down:
	sub $t0, $t0, $t9
	j draw_line_loop


read_bmp_file:
#$a0 - descriptor
#$a1 - file name
	la $t1, ($a0)	# imgdescriptor
# syscall 13 - open file, returns descriptor
	la $a0, ($a1)
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
# in case of error jump to exit	
	bltz $v0, main_exit
# syscall 14 - read file, returns number of characters(file size) read
	move $a0, $v0	#load descriptor as first argument
	la $a1, img
	li $a2,	buffor
	li $v0, 14
	syscall
	bltz $v0, main_exit
	move $t0, $v0	#load number of file size in t0 register

# syscall 16 - close file
	la $v0, 16
	syscall

# saving image information
	la $a0, ($t1)
	sw $t0, filesize($a0)
	sw $a1, headeraddr($a0)
	lhu $t0, 10($a1)
	addu $t1, $a1, $t0	# image address
	sw $t1, imgaddr($a0)
	lhu $t0, 18($a1)	# width
	sw $t0, imgwidth($a0)
	lhu $t0, 22($a1)	# heigth
	sw $t0, imgheight($a0)
	# getting row size
	lw $t0, imgwidth($a0)
	addiu $t0, $t0, 31
	srl $t0, $t0, 5	# logical right shift by 5
	sll $t0, $t0, 2	# logical left shift by 2
	sw $t0, rowsize($a0)
	
	jr $ra
	
	

save_bmp_file:
# $a0 - descriptor
# $a1 - file name

	la $t0, ($a0)
	la $a0, ($a1)
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	move $a0, $v0
	lw $a1, headeraddr($t0)
	lw $a2, filesize($t0)
	li $v0, 15
	syscall
	li $v0, 16
	syscall
	
	jr $ra
