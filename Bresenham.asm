 # Drawing a straight line with Bresenham algorithm

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
img:		.space  buffor
fname:		.asciiz "empty.bmp"
outfname: 	.asciiz "outfile.bmp"


.text
main:
	
test_draw_line:
# Read image
	la $a0, imgdescriptor
	la $a1, fname
	jal read_bmp_file
	bltz $v0, main_exit

	la $a0, imgdescriptor	# descriptor
# 	INPUT
	la $a1, 13	# x1
	la $a2, 77	# y1
	la $a3, 34	# x2
	la $t0, 173	# y2
	jal draw_line

	la $a0, imgdescriptor
	la $a1, outfname
	jal save_bmp_file
main_exit:
	li $v0, 10
	syscall
	

test_draw_pixel:
# call read_bmp_file
	la $a0, imgdescriptor
	la $a1, fname
	jal read_bmp_file
	
	la $a0, imgdescriptor
	li $a1, 100 # x
	li $a2, 100 # y
	li $a3, 0 # color
	jal set_pixel
	
	la $a0, imgdescriptor
	la $a1, outfname
	jal save_bmp_file

draw_line:
# input:
# a0 -descriptor
# a1 - x1
# a2 - y1
# a3 - x2
# t0 - y2
	# parametrs:
	# a0 -descriptor
	# a1 - x1
	# a2 - y1
	# a3 - color
	# t0 - x2
	# t1 - y2
	# t2 - dx
	# t3 - dy
	# t4 - sx
	# t5 - sy
	# t6 - err
	# t7 - 2*err
	la $t1, ($t0) # t1 - y2
	la $t0, ($a3) # t0 - x2
	la $a3, 0 # color
# remember return address
	addiu $sp, $sp, -4
	sw $ra, ($sp)

	la $t4, 1 # sx = -1
	la $t5, -1 # sy = 1
	sub $t2, $t0, $a1	# dx = x2 - x1
	slt $t6, $t2, $zero
	beq $t6, $zero, dx_is_positive	# if  x1 > x2:
	sub $t2, $zero, $t2	# dx = |x2 - x1|
	la $t4, -1
dx_is_positive:
	sub $t3, $t1, $a2	# dy = y2 - y1
	slt $t6, $zero, $t3	
	beq $t6, $zero, dy_is_negative	# if  y1 < y2:
	sub $t3, $zero, $t3	# dy = -|y2- y1|
	la $t5, 1
dy_is_negative:
	add $t6, $t2, $t3
draw_line_loop:
# plot x, y
	addiu $sp, $sp, -12
	sw $t0, 8($sp)
	sw  $t1, 4($sp)
	sw $t2, 0($sp)
	jal set_pixel	
	lw $t2, 0($sp)
	lw $t1, 4($sp)
	lw $t0, 8($sp)
	addiu $sp, $sp, 12
# if x0 == x1 and y0 == y1, stop loop
	seq $t8, $a1, $t0
	beq $t8, $zero, increment_x
	seq $t8, $a2, $t1
	beq $t8, $zero, increment_x
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	jr $ra
increment_x:
	sll $t7, $t6, 1 # 2 * err
	blt $t7, $t3, increment_y
	add $t6, $t6, $t3	# err += dy
	add $a1, $a1, $t4	# x++
increment_y:
	sll $t7, $t6, 1 # 2 * err
	bgt $t7, $t3, draw_line_loop
	add $t6, $t6, $t2	# err += dx
	add $a2, $a2, $t5	# y++
	j draw_line_loop
	
read_bmp_file:
#$a0 - descriptor
#$a1 - file name

# save arguments in t registers
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
set_pixel:
# $a0 - descriptor
# $a1 - x
# $a2 - y
# $a3 - color
	lw $t0, rowsize($a0)
	mul $t0, $t0, $a2	# rowsize = rowsize * y_coordinate
	srl $t1, $a1, 3
	add $t0, $t0, $t1
	
	lw $t1, imgaddr($a0)
	add $t0, $t0, $t1	# Byte, which contains given pixel
	
	andi $t1, $a1, 0x07
	li $t2, 0x80
	srlv $t2, $t2, $t1
	lb $t1, 0($t0)
	
	beqz $a3, set_black
	or $t1, $t1, $t2
	sb $t1, 0($t0)
	
	jr $ra

set_black:
	not $t2, $t2
	and $t1, $t1, $t2
	sb $t1, 0($t0)
	jr $ra
