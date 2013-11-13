
	
L1:
	.asciz "NULL return"
	
L2:
	.asciz "Not NULL return"
	
L3:
	.asciz "\nSum of 5 numbers:"
	
L4:
	.asciz "%i"
	
L5:
	.asciz "\nSum of other 5 numbers:"
	
L6:
	.asciz "%i"
	.text
	.global main
	
Compute_1:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#28
	mov v1,#0
	mov a1,v1
	b .L3exit
	
.L3exit:
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
	
Compute_0:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#28
	add v5,a2,a3
	add v3,v5,a4
	ldr v4,[fp,#4]
	add v1,v3,v4
	ldr v4,[fp,#8]
	rsb v2,v4,#0
	sub v4,v1,v2
	mov a1,v4
	b .L2exit
	
.L2exit:
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
	
main:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#44
	mov v5,#0
	cmp v5,#0
	moveq v2,#1
	movne v2,#0
	orr a3,v2,#0
	cmp a3,#0
	moveq a3,#0
	movne a3,#1
	and v5,a3,v5
	cmp v5,#0
	moveq v5,#0
	movne v5,#1
	ldr a1,[fp,#-32]
	bl Compute_1(PLT)
	mov v3,a1
	cmp v3,#0
	moveq a2,#1
	movne a2,#0
	cmp a2,#0
	beq .1
	ldr a1,=L1
	bl printf(PLT)
	b .2
	
.1:
	ldr a1,=L2
	bl printf(PLT)
	
.2:
	mov a1,#12
	bl _Znwj(PLT)
	mov a4,a1
	sub sp,sp,#8
	str a4,[fp,#-32]
	ldr a1,[fp,#-32]
	mov a2,#1
	mov a3,#2
	mov a4,#3
	mov v4,#4
	str v4,[sp,#0]
	mov v4,#5
	str v4,[sp,#4]
	bl Compute_0(PLT)
	add sp,sp,#8
	mov a4,a1
	str a4,[fp,#-28]
	ldr a1,=L3
	bl printf(PLT)
	ldr a4,[fp,#-28]
	ldr a1,=L4
	mov a2,a4
	bl printf(PLT)
	mov v4,#5
	rsb a4,v4,#0
	sub sp,sp,#8
	str a4,[fp,#-40]
	ldr a1,[fp,#-32]
	ldr a2,[fp,#-40]
	mov a3,#6
	mov a4,#7
	mov v4,#8
	str v4,[sp,#0]
	mov v4,#9
	str v4,[sp,#4]
	bl Compute_0(PLT)
	add sp,sp,#8
	mov v4,a1
	ldr a1,=L5
	bl printf(PLT)
	ldr a1,=L6
	mov a2,v4
	bl printf(PLT)
	
.L1exit:
	mov a4,#0
	mov a1,a4
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
