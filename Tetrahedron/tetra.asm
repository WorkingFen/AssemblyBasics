;############## Comments ##########################################################
;; Registers for integers and pointers while passing arguments
	;%rdi - canvas->line [first element of bitmap, upper-left corner]
	;%rsi - canvas->w [width]
	;%rdx - canvas->h [height]
	;%rcx - zBuffer->line [first element of buffer with depth]
	;%r8  - first [pointer to first vertex]
	;%r9  - second [pointer to second vertex]
;; Registers for doubles 
	;%xmm0 - 
	;%xmm1 - 
	;%xmm2 - 
	;%xmm3 - 
	;%xmm4 - 
	;%xmm5 - 
	;%xmm6 - 
	;%xmm7 -
;; Other arguments are stored in [rbp + 16], [rbp + 24], [rbp + 32] and so on... 

;; How to get int from structure
;mov		rY1d, [rX]			; x
;mov		rY2d, [rX + 4]		; y
;mov		rY3d, [rX + 8]		; z
;First choose row, then column

;; How macros should look
; %macro write_string 2
;	mov		eax, 4
;	mov		ebx, 1
;	mov		ecx, %1
;	mov		edx, %2
;	int		80h
; %endmacro
;##################################################################################
;############## Macros ############################################################
%macro start_reg 0
	mov 	r10, [rbp + 16]			; Third vertex
	mov 	r11, [rbp + 24]			; Fourth vertex

	mov		[rsp - 8], rdi			; canvas->line
	mov		[rsp - 16], rcx			; zBuffer->line
	mov		[rsp - 24], rsi			; canvas->w [width]
	mov		[rsp - 32], rdx			; canvas->h [height]
	mov		[rsp - 40], r8			; Pointer to first vertex
	mov		[rsp - 48], r9			; Pointer to second vertex
	mov		[rsp - 56], r10			; Pointer to third vertex
	mov		[rsp - 64], r11			; Pointer to fourth vertex

	mov		ax, 0x1
	mov		[rsp - 114], ax			; Actual number of triangles
%endmacro

;%macro prepare_pixel 4

;%endmacro

%macro create_z_coor 4
	mov		ecx, %2					; Get y from vertex
	mov		%4, [rsp - 16]			; Get pointer to zBuffer->line
	mov		rdi, [rsp - 32]			; Get height
	add		rcx, 0x1				; Add one to y
	sub		rdi, rcx				; H-(y+1)
	shl		rdi, 0x3				; Every line is represented as 64 bits address
	add		%4, rdi					; Move to proper line

	mov		eax, %1					; Get x from vertex
	mov		rcx, [%4]				; Get line
	mov		rdi, 0x2				; Get 16 bytes
	mul		rdi						; for each pixel
	add		rcx, rax				; Go to proper pixel
	mov		eax, %3					; Get z from vertex
	cmp		[rcx], eax				; Compare if actual z coordinate is lesser

	jb		$+69					; Jump if there is lesser z value to label ;not:

	mov		[rcx], eax				; Z pixel
%endmacro

%macro draw_pixel 4
	create_z_coor %1, %2, %3, %4

	mov		ecx, %2					; Get y from vertex
	mov 	%4, [rsp - 8]			; Get pointer to canvas->line
	mov		rdi, [rsp - 32]			; Get height
	add		rcx, 0x1				; Add one to y
	sub		rdi, rcx				; H-(y+1)
	shl		rdi, 0x3				; Every line is represented as 64 bits address
	add		%4, rdi					; Move to proper line

	mov		eax, %1					; Get x from vertex
	mov		rcx, [%4]				; Get line
	mov		rdi, 0x3				; Get 24 bytes
	mul		rdi						; for each pixel
	add		rcx, rax				; Go to proper pixel
	mov		al, 0x0
	;mov		al, [rsp - 84]			; 
	mov		[rcx], al				; R = 0x00
	;mov		al, [rsp - 85]		; 
	mov		[rcx + 1], al			; G = 0x00
	;mov		al, [rsp - 86]		; 
	mov		[rcx + 2], al			; B = 0x00
%endmacro

%macro prepare_factor 7
	mov		r11d, %1					; [A1]
	sub		r11d, %3					; (A1-A2)
	mov		r10d, %2					; [B1]
	sub		r10d, %4					; (B1-B2)
	mov		r9d, %3						; [A2]
	sub		r9d, %5						; (A2-A3)
	mov		r12d, %4					; [B2]
	sub		r12d, %6					; (B2-B3)
	mov		eax, r11d
	mul		r12d
	mov		r11d, eax					; (A1-A2)(B2-B3)
	mov		eax, r10d
	mul		r9d
	mov		r10d, eax					; (B1-B2)(A2-A3)
	sub		r11d, r10d					; (A1-A2)(B2-B3)-(B1-B2)(A2-A3) => factor
	mov		[rsp - %7], r11d			; Save to proper address
%endmacro

%macro find_maxmin 6
	mov		r12d, %1
	mov		r11d, %2
	mov		r10d, %3
	cmp		r12d, r11d					; If A1 > A2
	ja		$+26						; Go to label ;cOgTw:
	cmp		r10d, r11d					; If A3 > A2
	ja		$+73						; Go to label ;cThgTw:
	cmp		r10d, r12d					; If A3 > A1
	ja		$+82						; Go to label ;cThgO:
	mov		[rsp - %4], r11w			; Max
	mov		[rsp - %5], r10w			; Min
	jmp		%6
;cOgTw:
	cmp		r11d, r10d					; If A2 > A3
	ja		$+21						; Go to label ;cTwgTh:
	cmp		r12d, r10d					; If A1 > A3
	ja		$+30						; Go to label ;cOgTh:
	mov		[rsp - %4], r10w			; Max
	mov		[rsp - %5], r11w			; Min
	jmp		%6		
;cTwgTh:
	mov		[rsp - %4], r12w			; Max
	mov		[rsp - %5], r10w			; Min
	jmp		%6
;cOgTh:
	mov		[rsp - %4], r12w			; Max
	mov		[rsp - %5], r11w			; Min
	jmp		%6
;cThgTw:
	mov		[rsp - %4], r10w			; Max
	mov		[rsp - %5], r12w			; Min
	jmp		%6
;cThgO:
	mov		[rsp - %4], r11w			; Max
	mov		[rsp - %5], r12w			; Min
%endmacro

%macro prepare_denominator 7
	mov		eax, %1
	mov		r8d, %4
	mul		r8d
	mov		r12d, eax					; A1*B2
	mov		eax, %2
	mov		r8d, %3
	mul		r8d
	mov		r11d, eax					; A2*B1
	mov		r10d, %2
	sub		r10d, %4					; [A2-B2]
	mov		r9d, %3
	sub		r9d, %1						; [B1-A1]
	mov		eax, %5
	mul		r10d
	mov		r10d, eax					; C1[A2-B2]
	mov		eax, %6
	mul		r9d
	mov		r9d, eax					; C2[B1-A1]
	add		r10d, r9d					; C1[A2-B2] + C2[B1-A1]
	add		r10d, r12d					; C1[A2-B2] + C2[B1-A1] + A1*B2
	sub		r10d, r11d					; C1[A2-B2] + C2[B1-A1] + A1*B2 - A2*B1
	mov		[rsp - %7], r10d
%endmacro

%macro prepare_vertices 7
	mov		r12d, %1					; Get first X
	mov		r11d, %2					; Get first Y
	mov		r10d, %3					; Get first Z
	mov		r9d, %4						; Get second X
	mov		r8d, %5						; Get second Y
	mov		ebx, %6						; Get second Z
	mov		ax, %7
	mov		[rsp - 112], ax				; Number of line
	cmp		r12d, r9d					; If X1 > X2
	ja		swap						; Swap coordinates
%endmacro

%macro swap_coor 2
	mov		eax, %1
	mov		%1, %2
	mov		%2, eax
%endmacro

%macro exloop 5
	mov		eax, %1
	mov		%5, %2
	cmp		eax, %5
	jle		%3
	mov		eax, [rsp - 112]
	mov		%5, 0x3
	cmp		eax, %5
	je		%4
	jmp		nextl
%endmacro
;##################################################################################
;############## Code ##############################################################
section .text
	global tetra

tetra:
;---------------------Prepare registers ----------------------
	push	rbp
	mov		rbp, rsp

	start_reg

	mov		r15, [rsp - 40]					; First vertex
	mov		r14, [rsp - 48]					; Third vertex
	mov		r13, [rsp - 56]					; Fourth vertex
	mov		r12, [rsp - 64]					; Fourth vertex
	draw_pixel 	[r15], [r15 + 4], [r15 + 8], r8
	draw_pixel	[r14], [r14 + 4], [r14 + 8], r8
	draw_pixel	[r13], [r13 + 4], [r13 + 8], r8
	draw_pixel	[r12], [r12 + 4], [r12 + 8], r8

;---------------------Prepare planes -------------------------
	;; Plane equation := [a(x-x0) + b(y-y0) + c(z-z0) = 0]
ntr:
	mov		r15w, [rsp - 114]
	cmp		r15w, 0x2
	jb		trfi
	cmp		r15w, 0x3
	jb		trs
	cmp		r15w, 0x4
	jb		trt
trfo:
	mov		r15, [rsp - 40]					; First vertex
	mov		r14, [rsp - 56]					; Third vertex
	mov		r13, [rsp - 64]					; Fourth vertex
	mov		r12d, 0xFF0000					; Color of triangle
	mov		[rsp - 84], r12d
	jmp pplane
trt:
	mov		r15, [rsp - 48]					; Second vertex
	mov		r14, [rsp - 56]					; Third vertex
	mov		r13, [rsp - 64]					; Fourth vertex
	mov		r12d, 0xFF00					; Color of triangle
	mov		[rsp - 84], r12d
	jmp pplane
trs:
	mov		r15, [rsp - 40]					; First vertex
	mov		r14, [rsp - 48]					; Second vertex
	mov		r13, [rsp - 64]					; Fourth vertex
	mov		r12d, 0xFF						; Color of triangle
	mov		[rsp - 84], r12d
	jmp pplane
trfi:
	mov		r15, [rsp - 40]					; First vertex
	mov		r14, [rsp - 48]					; Second vertex
	mov		r13, [rsp - 56]					; Third vertex
	mov		r12d, 0xC8FF					; Color of triangle
	mov		[rsp - 84], r12d
pplane:
	prepare_factor	[r15 + 4], [r15 + 8], [r14 + 4], [r14 + 8], [r13 + 4], [r13 + 8], 0x48	; Factor A
	prepare_factor	[r15 + 8], [r15], [r14 + 8], [r14], [r13 + 8], [r13], 0x4C				; Factor B
	prepare_factor	[r15], [r15 + 4], [r14], [r14 + 4], [r13], [r13 + 4], 0x50				; Factor C

;---------------------Find MAX and MIN Coordinates -----------
mimaX:	
	find_maxmin	[r15], [r14], [r13], 0x58, 0x5A, mimaY								; Find max and min of X
mimaY:
	find_maxmin [r15 + 4], [r14 + 4], [r13 + 4], 0x5C, 0x5E, denomi					; Find max and min of Y

;---------------------Prepare denominator --------------------
denomi:
	prepare_denominator	[r15], [r15 + 4], [r14], [r14 + 4], [r13], [r13 + 4], 0x6C	; Denominator for filling triangles

;---------------------Prepare vertices -----------------------
	;; Frist and Second vertices
first:
	prepare_vertices [r15], [r15 + 4], [r15 + 8], [r14], [r14 + 4], [r14 + 8], 0x1
	jmp		lines
	
	;; Second and Third vertices
second:
	prepare_vertices [r14], [r14 + 4], [r14 + 8], [r13], [r13 + 4], [r13 + 8], 0x2
	jmp		lines
	
	;; Third and First vertices
third:
	prepare_vertices [r13], [r13 + 4], [r13 + 8], [r15], [r15 + 4], [r15 + 8], 0x3

;---------------------Types of lines -------------------------
lines:
	mov		ecx, r9d
	sub		ecx, r12d							; ecx := deltaX
	mov		eax, 0x2
	mul		ecx									
	mov		edi, eax							; edi := 2*deltaX
	cmp		r11d, r8d							; If Y1 > Y2
	ja		decl

	;; Ascending [less than 45 and more than 0 degrees] and horizontal lines
ascen:
	mov		ecx, r8d
	sub		ecx, r11d
	mov		eax, 0x2
	mul		ecx
	mov		[rsp - 96], eax						; [rsp - 96]: a := 2*deltaY
	sub		eax, edi
	mov		[rsp - 100], eax					; [rsp - 100]: b := 2*deltaY - 2*deltaX
	mov 	ecx, 0x0
	cmp		eax, ecx
	jg		ascen45
	mov		ecx, r9d
	sub		ecx, r12d							; ecx := deltaX
	mov		eax, [rsp - 96]
	sub		eax, ecx
	mov		[rsp - 104], eax					; [rsp - 104]: Pk := 2*deltaY - deltaX

loopas:
	draw_pixel r12d, r11d, r10d, r8

nextas:
	mov		eax, 0x0
	mov		ecx, [rsp - 104]
	cmp		ecx, eax					; If Pk > 0
	jg		upas						; Go to up ascending
	mov		eax, [rsp - 96]
	add		ecx, eax
	mov		[rsp - 104], ecx			; Pk := Pk-1 + a
	add		r12d, 0x1					; Xk := Xk-1 + 1
	;; Changing z
	mov		ecx, [rsp - 72]				; Plane a
	mov		r8d, [rsp - 80]				; Plane c
	mov		eax, r8d
	mul		r10d						; Pc*Zk-1
	sub		eax, ecx					; Pc*Zk := Pc*Zk-1 - Pa
	div		r8d
	mov		r10d, eax					; Zk := Zk-1 - Pa/Pc
	;; ############################
	exloop	r12d, r9d, loopas, fill, r8d

upas:
	mov		ecx, [rsp - 104]
	mov		eax, [rsp - 100]
	add		ecx, eax
	mov		[rsp - 104], ecx			; Pk := Pk-1 + b
	add		r12d, 0x1					; Xk := Xk-1 + 1
	add		r11d, 0x1					; Yk := Yk-1 + 1
	;; Changing z
	mov		ecx, [rsp - 72]				; Plane a
	mov		r8d, [rsp - 76]				; Plane b
	add		ecx, r8d					; Pa+Pb
	mov		r8d, [rsp - 80]				; Plane c
	mov		eax, r8d
	mul		r10d						; Pc*Zk-1
	sub		eax, ecx					; Pc*Zk := Pc*Zk-1 - [Pa+Pb]
	div		r8d
	mov		r10d, eax					; Zk := Zk-1 - [Pa+Pb]/Pc
	;; ############################
	exloop	r12d, r9d, loopas, fill, r8d

	;; Ascending [less than 90 and more than 45 degrees]
ascen45:
	mov		ecx, r8d
	sub		ecx, r11d							; ecx := deltaY
	mov		eax, 0x2
	mul		ecx
	mov		edi, eax							; edi := 2*deltaY
	mov		ecx, r9d
	sub		ecx, r12d							; ecx := deltaX
	mov		eax, 0x2
	mul		ecx
	mov		[rsp - 96], eax						; [rsp - 96]: a := 2*deltaX
	sub		eax, edi
	mov		[rsp - 100], eax					; [rsp - 100]: b := 2*deltaX - 2*deltaY
	mov		ecx, r8d
	sub		ecx, r11d							; ecx := deltaY
	mov		eax, [rsp - 96]
	sub		eax, ecx
	mov		[rsp - 104], eax					; [rsp - 104]: Pk := 2*deltaX - deltaY

loopas45:
	draw_pixel r12d, r11d, r10d, r9

onas45:
	mov		eax, 0x0
	mov		ecx, [rsp - 104]
	cmp		ecx, eax					; If Pk > 0
	jg		upas45						; Go to up ascending
	mov		eax, [rsp - 96]
	add		ecx, eax
	mov		[rsp - 104], ecx			; Pk := Pk-1 + a
	add		r11d, 0x1					; Yk := Yk-1 + 1
	;; Changing z
	mov		ecx, [rsp - 76]				; Plane b
	mov		r9d, [rsp - 80]				; Plane c
	mov		eax, r9d
	mul		r10d						; Pc*Zk-1
	sub		eax, ecx					; Pc*Zk := Pc*Zk-1 - Pb
	div		r9d
	mov		r10d, eax					; Zk := Zk-1 - Pb/Pc
	;; ############################
	exloop	r11d, r8d, loopas45, fill, r9d

upas45:
	mov		ecx, [rsp - 104]
	mov		eax, [rsp - 100]
	add		ecx, eax
	mov		[rsp - 104], ecx			; Pk := Pk-1 + b
	add		r12d, 0x1					; Xk := Xk-1 + 1
	add		r11d, 0x1					; Yk := Yk-1 + 1
	;; Changing z
	mov		ecx, [rsp - 72]				; Plane a
	mov		r9d, [rsp - 76]				; Plane b
	add		ecx, r9d					; Pa+Pb
	mov		r9d, [rsp - 80]				; Plane c
	mov		eax, r9d
	mul		r10d						; Pc*Zk-1
	sub		eax, ecx					; Pc*Zk := Pc*Zk-1 - [Pa+Pb]
	div		r9d
	mov		r10d, eax					; Zk := Zk-1 - [Pa+Pb]/Pc
	;; ############################
	exloop	r11d, r8d, loopas45, fill, r9d

	;; Declining lines [less than 0 and more than -45 degrees]
decl:
	mov		ecx, r11d
	sub		ecx, r8d
	mov		eax, 0x2
	mul		ecx
	mov		[rsp - 96], eax						; [rsp - 96]: a := 2*deltaY
	sub		eax, edi
	mov		[rsp - 100], eax					; [rsp - 100]: b := 2*deltaY - 2*deltaX
	mov 	ecx, 0x0
	cmp		eax, ecx
	jg		decl45
	mov		ecx, r9d
	sub		ecx, r12d							; ecx := deltaX
	mov		eax, [rsp - 96]
	sub		eax, ecx
	mov		[rsp - 104], eax					; [rsp - 104]: Pk := 2*deltaY - deltaX

loopde:
	draw_pixel r12d, r11d, r10d, r8

nextde:
	mov		eax, 0x0
	mov		ecx, [rsp - 104]
	cmp		ecx, eax					; If Pk > 0
	jg		downde						; Go to down descending
	mov		eax, [rsp - 96]
	add		ecx, eax
	mov		[rsp - 104], ecx			; Pk := Pk-1 + a
	add		r12d, 0x1					; Xk := Xk-1 + 1
	;; Changing z
	mov		ecx, [rsp - 72]				; Plane a
	mov		r8d, [rsp - 80]				; Plane c
	mov		eax, r8d
	mul		r10d						; Pc*Zk-1
	sub		eax, ecx					; Pc*Zk := Pc*Zk-1 - Pa
	div		r8d
	mov		r10d, eax					; Zk := Zk-1 - Pa/Pc
	;; ############################
	exloop	r12d, r9d, loopde, fill, r8d

downde:
	mov		ecx, [rsp - 104]
	mov		eax, [rsp - 100]
	add		ecx, eax
	mov		[rsp - 104], ecx			; Pk := Pk-1 + b
	add		r12d, 0x1					; Xk := Xk-1 + 1
	sub		r11d, 0x1					; Yk := Yk-1 - 1
	;; Changing z
	mov		ecx, [rsp - 72]				; Plane a
	mov		r8d, [rsp - 76]				; Plane b
	sub		ecx, r8d					; Pa-Pb
	mov		r8d, [rsp - 80]				; Plane c
	mov		eax, r8d
	mul		r10d						; Pc*Zk-1
	sub		eax, ecx					; Pc*Zk := Pc*Zk-1 - [Pa-Pb]
	div		r8d
	mov		r10d, eax					; Zk := Zk-1 - [Pa-Pb]/Pc
	;; ############################
	exloop	r12d, r9d, loopde, fill, r8d

	;; Declining lines [less than -45 and more than -90 degrees]
decl45:
	mov		ecx, r11d
	sub		ecx, r8d							; ecx := deltaY
	mov		eax, 0x2
	mul		ecx
	mov		edi, eax							; edi := 2*deltaY
	mov		ecx, r9d
	sub		ecx, r12d							; ecx := deltaX
	mov		eax, 0x2
	mul		ecx
	mov		[rsp - 96], eax						; [rsp - 96]: a := 2*deltaX
	sub		eax, edi
	mov		[rsp - 100], eax					; [rsp - 100]: b := 2*deltaX - 2*deltaY
	mov		ecx, r8d
	sub		ecx, r11d							; ecx := deltaY
	mov		eax, [rsp - 96]
	sub		eax, ecx
	mov		[rsp - 104], eax					; [rsp - 104]: Pk := 2*deltaX - deltaY

loopde45:
	draw_pixel r12d, r11d, r10d, r9

underde45:
	mov		eax, 0x0
	mov		ecx, [rsp - 104]
	cmp		ecx, eax					; If Pk > 0
	jg		downde45					; Go to up ascending
	mov		eax, [rsp - 96]
	add		ecx, eax
	mov		[rsp - 104], ecx			; Pk := Pk-1 + a
	sub		r11d, 0x1					; Yk := Yk-1 - 1
	;; Changing z
	mov		ecx, [rsp - 76]				; Plane b
	mov		r9d, [rsp - 80]				; Plane c
	mov		eax, r9d
	mul		r10d						; Pc*Zk-1
	add		eax, ecx					; Pc*Zk := Pc*Zk-1 + Pb
	div		r9d
	mov		r10d, eax					; Zk := Zk-1 + Pb/Pc
	;; ############################
	exloop	r8d, r11d, loopde45, fill, r9d

downde45:
	mov		ecx, [rsp - 104]
	mov		eax, [rsp - 100]
	add		ecx, eax
	mov		[rsp - 104], ecx			; Pk := Pk-1 + b
	add		r12d, 0x1					; Xk := Xk-1 + 1
	sub		r11d, 0x1					; Yk := Yk-1 + 1
	;; Changing z
	mov		ecx, [rsp - 72]				; Plane a
	mov		r9d, [rsp - 76]				; Plane b
	sub		ecx, r9d					; Pa-Pb
	mov		r9d, [rsp - 80]				; Plane c
	mov		eax, r9d
	mul		r10d						; Pc*Zk-1
	sub		eax, ecx					; Pc*Zk := Pc*Zk-1 - [Pa-Pb]
	div		r9d
	mov		r10d, eax					; Zk := Zk-1 - [Pa-Pb]/Pc
	;; ############################
	exloop	r8d, r11d, loopde45, fill, r9d

;---------------------Filling triangle -----------------------
fill:

;lfillr:

;lfillc:

;wrong:

;baric:

;chckbr:

;nexY:
	jmp		end
;---------------------Vertices modifying ---------------------
swap:
	swap_coor	r12d, r9d						; Swap X coordinates
	swap_coor	r11d, r8d						; Swap Y coordinates
	swap_coor	r10d, ebx						; Swap Z coordinates
	jmp		lines 

	;; Which line should be drawn next?
nextl:
	mov		ax, [rsp - 112]
	mov		dx, 0x1
	cmp		ax, dx
	je		second
	mov		dx, 0x2
	cmp		ax, dx
	je		third

;---------------------Next triangle --------------------------
nxtrn:
	mov		ax, [rsp - 114]
	add		ax, 0x1
	mov		[rsp - 114], ax
	cmp		ax, 0x4
	jb		ntr		
;---------------------End of function ------------------------
end:
	mov		rsp, rbp
	pop		rbp
	ret
;##################################################################################