	.data						#data segment
prompt: .asciiz "Enter string with numbers: \n"		#string
buf:	.space 100					#buffer for users string
	.text						#text segment
	.globl main					#visible outside
main:	
	li $v0, 4					#print string
	la $a0, prompt					#from this
	syscall
	li $v0, 8					#read string
	la $a0, buf					#to this
	li $a1, 100					#max 100 bytes
	syscall
	la $t0, buf					#first local -> address of buffer
	lbu $t1, ($t0)					#second local -> first byte from buffer
	li $t2, 0					#third local -> actual number
	li $t3, 0					#fourth local -> temp number
	li $t4, 0xa					#fifth local -> static number to multiply
	beqz $t1, end					#check if equal zero then go to label "end"
loop:
	blt $t1, '0', next				#check if first lesser than second then go to label next
	bgt $t1, '9', next				#check if first greater than second then go to label next
	multu $t3, $t4					#multiply first with second
	mflo $t3					#save
	subu $t1, $t1, 0x30				#subtract third from second and store in first
	addu $t3, $t3, $t1 				#add third to second and store in first
	addi $t0, $t0, 1				#next address of buffer
	lbu $t1, ($t0)					#get next element
	bnez $t1, loop 					#check if not equal zero then go to label "loop"
next:
	bgtu $t3, $t2, save				#check if first is greater than second then go to label "save"
	addi $t0, $t0, 1				#next address
	lbu $t1, ($t0)					#get next element
	bnez $t1, loop					#check if not equal zero then go to label "loop"
	beqz $t1, end					#check if equal zero then go to label "end"
save:
	move $t2, $t3					#move from temp to actual number
	li $t3, 0					#temp is zero now
	addi $t0, $t0, 1				#next address of buffer
	lbu $t1, ($t0)					#get next element
	bnez $t1, loop					#check if not equal zero then to got label "loop"
end:
	li $v0, 1					#print integer
	la $a0, ($t2)					#from this
	syscall
	li $v0, 10					#terminate execution
	syscall
