.data
    str1: .string "jsssss7890111111"    # 母串
    str2: .string "0987"              # 子串

.macro push %a
    addi    sp, sp, -4
    sw      %a, 0(sp) 
.end_macro

.macro pop %a
    lw      %a, 0(sp) 
    addi    sp, sp, 4
.end_macro

.macro print %r, %m
    ori     a0, %r, 0
    ori     a7, zero, %m
    ecall
.end_macro

.text
.globl MAIN
MAIN:
    lui     a1, %hi(str1)       
    addi    a1, a1, %lo(str1)       # 加载母串地址到a1
    
    lui     a2, %hi(str2)
    addi    a2, a2, %lo(str2)       # 加载子串地址到a2
    addi    a3, zero, 16          # 母串长度
    addi    a4, zero, 4           # 子串长度
    addi    a0, zero, -1          # FUNC返回结果（初始化为-1）
    addi    s10, a3, -1

    jal     ra, FUNC 

    # 打印查找结果
    print   a0, 1           # 打印FUNC返回结果a0中的值，系统调用号为1
    
    addi    a7, zero, 10    # 系统调用号为10 (exit)
    ecall                   # 系统调用退出

FUNC:
    push    ra              # 保护现场 
    push    t1              
    addi    t3, zero, -1          # 初始化位置索引为-1
    addi    t5, zero,0            # 初始化外循环索引i
LOOP:
    bge     t5, a3, EXIT    # 如果i >= 母串长度，跳出循环
    add     t6, a1, t5      # 计算母串当前检查位置的地址

    addi    t4, zero, 0           # 初始化内循环索引j
    add     s3, a2, zero         # 设置子串的起始地址
INNER_LOOP:
    bge     t4, a4, MATCH_FOUND # 如果j >= 子串长度，匹配成功
    lb      t0, 0(t6)       # 加载母串当前字符
    lb      t1, 0(s3)       # 加载子串当前字符
    bne     t0, t1, UPDATE_I # 如果字符不匹配，跳到更新i的逻辑

    addi    t6, t6, 1       # 移动到母串的下一个字符
    addi    s3, s3, 1       # 移动到子串的下一个字符
    addi    t4, t4, 1       # j++
    jal     zero, INNER_LOOP      # 继续内部循环

MATCH_FOUND:
    add     t3, t5, zero          # 找到匹配，设置位置索引t3为当前外循环索引i
    jal     zero, EXIT            # 跳出主循环

UPDATE_I:
    addi    t5, t5, 1             # i++
    jal     zero, LOOP            # 返回到外部循环的起始位置

EXIT:
    beq     t3, s10, JUDGE        # 若找不到(索引为15)，索引改为-1
    add     a0, t3, zero          # t3的值传入a0作为FUNC返回值
    pop     t1              
    pop     ra              # 恢复现场
    jalr    zero, ra, 0                     
JUDGE:
    jalr    zero, ra, 0
    
