
	
L1:
	.asciz "true"
	
L2:
	.asciz "false"
	
L3:
	.asciz "true"
	
L4:
	.asciz "false"
	.text
	.global main
	
main:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#48
	mov v5,#4
	mov v2,#5
	mov a3,#1
	mov v3,#0
	and a2,a3,v3
	cmp a2,#0
	moveq a2,#0
	movne a2,#1
	orr a4,a2,v3
	cmp a4,#0
	moveq a4,#0
	movne a4,#1
	orr v4,a3,v3
	cmp v4,#0
	moveq v4,#0
	movne v4,#1
	orr v1,a4,v4
	cmp v1,#0
	moveq v1,#0
	movne v1,#1
	cmp v5,v2
	movlt a1,#1
	movge a1,#0
	and v3,a1,v1
	cmp v3,#0
	moveq v3,#0
	movne v3,#1
	cmp v3,#0
	beq .1
	ldr a1,=L1
	bl printf(PLT)
	b .2
	
.1:
	ldr a1,=L2
	bl printf(PLT)
	
.2:
	str v5,[fp,#-28]
	cmp v5,v2
	movgt v5,#1
	movle v5,#0
	orr v3,v1,v5
	cmp v3,#0
	moveq v3,#0
	movne v3,#1
	cmp v3,#0
	beq .3
	ldr a1,=L3
	bl printf(PLT)
	b .4
	
.3:
	ldr a1,=L4
	bl printf(PLT)
	
.4:
	
.L1exit:
	mov a4,#0
	mov a1,a4
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
