	.data							#data segment
prompt:	.asciiz "Enter integer: \n"				#string
result:	.asciiz "The supplement of integer to 9 is: \n"		#result string
	.text							#text segment
	.globl main						#visible outside
main:
	li $v0, 4						#print string
	la $a0, prompt						#from this
	syscall
	li $v0, 5						#read integer
	syscall
	li $t0, 9						#first local -> number 9
	subu $t0, $t0, $v0 					#subtract third from second then save to first
end:
	li $v0, 4						#print string
	la $a0, result						#from this
	syscall
	li $v0, 1						#print integer
	la $a0, ($t0)						#from this (from second)
	syscall
	li $v0, 10						#terminate execution
	syscall
