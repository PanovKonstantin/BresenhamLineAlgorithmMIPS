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
	jal test_draw_line
	
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
	
	jr $ra
test_draw_line:
# Save return address
	addi $sp, $sp, -4
	sw $ra, 0($sp)

# Read image
	la $a0, imgdescriptor
	la $a1, fname
	jal read_bmp_file
	bltz $v0, main_exit

	la $a0, imgdescriptor	# descriptor
	la $a1, 15	# x1
	la $a2, 5	# y1
	la $a3, 3	# x2
	la $t0, 2	# y2
	jal draw_line

	la $a0, imgdescriptor
	la $a1, outfname
	jal save_bmp_file

# Get return address
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_line:
# Using t3-7 registers, because t1-2 registers are rewritten in set_pixel function
	la $t3, ($a1)	# x1
	la $t4, ($a2)	# y1
	la $t5, ($a3)	# x2
	la $t6, ($t0)	# y2
	la $t7, ($a0)	# descriptor
	
	sub $t6, $t6, $t4	# m_new = y2 - y1	
	sll $t6, $t6, 1		# m_new = m_new * 2
	sub $t0, $t5, $t3	# slope_error_new = x2 - x1
	sub $t0, $t6, $t0	# slope_error_new = m_new - slope_error_new
	
	la $t1, ($t3)	# x = x1
	la $t2, ($t4)	# y = y1
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal draw_line_loop
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

draw_line_loop:
	
	addi $sp, $sp, -16
	sw $ra, 12($sp)
	sw $t0, 8($sp)
	sw $t1, 4($sp)
	sw $t2, 0($sp)
	
	la $a0, ($t7)
	la $a1, ($t1)
	la $a2, ($t2)
	la $a3, 0
	jal set_pixel
	
	lw $ra, 12($sp)
	lw $t0, 8($sp)
	lw $t1, 4($sp)
	lw $t2, 0($sp)
	addi $sp, $sp, 16

	bge $t1, $t5, draw_line_loop_return	# while x <= x2
	
	add $t0, $t0, $t6	# slope_error_new += m_new
	add $t1, $t1, 1		# x++
	bltz $t0, draw_line_loop	#if slope_error_new >= 0, y++
	add $t2, $t2, 1
	sub $a1, $t5, $t3
	sll $a1, $a1, 1
	sub $t0, $t0, $a1
	j draw_line_loop

draw_line_loop_return:
	jr $ra
	
	
	



	
	

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
