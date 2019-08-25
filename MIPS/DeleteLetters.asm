	.data						#data segment
prompt:	.asciiz "Enter string with numbers: \n"		#string
buf:	.space 100					#buffer for user string
	.text						#text segment
	.globl main					#visible outside
main:
	li $v0, 4					#print string
	la $a0, prompt					#from this
	syscall
	li $v0, 8					#read string
	la $a0, buf					#to this
	li $a1, 100					#max length
	syscall
	la $t0, buf					#first local -> address of buffer
	la $t1, ($t0)					#second local -> address of first local
	lbu $t2, ($t0)					#third local -> load byte from first element of buffer
	beqz $t2, end					#check if equal zero then go to label "end"
loop:
	blt $t2, '0', del				#check if first lesser than second then go to label "del"
	bgt $t2, '9', del				#check if first greater than second then go to label "del"
	sb $t2, ($t1)					#save byte to address of second
	sb $zero, ($t0) 				#save byte zero to address of second
	addi $t0, $t0, 1				#next element of buffer
	addi $t1, $t1, 1				#next address
	lbu $t2, ($t0)					#load byte from second
	bnez $t2, loop					#check if not equal zero then go to label "loop"
	beqz $t2, end					#check if equal zero then go to label "end"
del:
	sb $zero, ($t0) 				#save byte zero to address of second
	addi $t0, $t0, 1				#next element of buffer
	lbu $t2, ($t0)					#load byte from second
	bnez $t2, loop					#check if not equal zero then go to label "loop"
end:
	li $v0, 4					#print string
	la $a0, buf					#from this
	syscall
	li $v0, 10					#terminate execution
	syscall
