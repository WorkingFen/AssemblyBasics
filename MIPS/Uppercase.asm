	.data				#data segment
prompt:	.asciiz "Enter string: \n"	#string
buf:	.space 100			#buffer with 100 bytes
	.text				#text segment
	.globl main			#visible outside
main:	
	li $v0, 4			#print string
	la $a0, prompt			#from this
	syscall
	li $v0, 8			#read string
	la $a0, buf			#to this
	li $a1, 100			#max amount
	syscall
	la $t0, buf			#first local -> address of buffer
	lb $t1, ($t0)			#second local -> first byte from address
	beqz $t1, end			#check if equals \0 then go to label "exit"
loop:
	blt $t1, 'a', next		#check if first less than second? then go to label "next" : move to next instruction
	bgt $t1, 'z', next		#check if first grater than second? then go to label "next" : move to next instruction
	subu $t1, $t1, 0x20		#subtract third from second then save to first
	sb $t1, ($t0)			#store byte from first to second
next:
	addi $t0, $t0, 1		#move to next address 
	lb $t1, ($t0)			#load byte from second to first
	bnez $t1, loop			#check if not equals \0 then go to label "loop"
end:
	li $v0, 4			#print string
	la $a0, buf			#from this
	syscall
	li $v0, 10			#terminate execution
	syscall
