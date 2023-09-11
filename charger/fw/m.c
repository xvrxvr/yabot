#include "common.h"

#pragma save
#pragma disable_warning 59
static uint8_t _kernel_vc_20v(uint16_t voltage)
{
// A - hi(voltage)
// B - low(voltage)
    (void)voltage;
    __asm
    mov a, r2
    mov b, dpl
    mul ab
    mov r1, b
//  b_hi = hi(B*210/212)   => r1
    mov a, r2
    mov b, dph
    mul ab
    mov dpl, b
//  w = A*210/212       => dpl, a
    add a, r1
//  w += b_hi
    jnc 1$
    inc dpl
1$:
//  return hi(w)
    __endasm;
}
#pragma restore

// Divider = 1/10, Full scale = 2.1V (Scale selector - 2.56)
// Output is (volts-10) * 10
// Mult - 105/32768 (210/65536)  (1V - 3120, 0.05 - 156)
uint8_t vc_20v(uint16_t voltage)
{
    if (voltage == 0xFFFF) return VE_Overflow;   // 21.0
    if (voltage <= 31207-156) return 0; // 10V - minimum
    __asm__("mov r2, #210");
    return _kernel_vc_20v(voltage - (31207-156));
}

// Divider = 1/10, Full scale = 2.1V*1.01 (Scale selector - 2.56)
// Output is (volts-10) * 10
// Mult - 53/16384 (212/65536)  (1V - 3091, 0.05 - 155)
uint8_t vc_20_01v(uint16_t voltage)
{
    if (voltage == 0xFFFF) return VE_Overflow; // 21.2
    if (voltage <= 30913-155) return 0; // 10V - minimum
    __asm__("mov r2, #212");
    return _kernel_vc_20v(voltage - (30913-155));
}

// Divider = 1/10, Full scale = 0.525V*1.01 (Scale selector - 640mV)
// Output is (volts-2.5) * 100
uint8_t vc_4v(uint16_t voltage)
{
    if (voltage > 62876) return VE_Overflow;   // 5.08
    if (voltage <= (30899-62)) return 0; // 2.5V - minimum
    return vc_2v(voltage - (30899-62));
}

#pragma save
#pragma disable_warning 59
// Output is volts * 100
// Mult - 530/65536   (530 = 0x212)
uint8_t vc_2v(uint16_t voltage)
{
    // voltage+=62;
    // B - lo(voltage) - dpl
    // A - hi(voltage) - dph
    (void)voltage;
    __asm
    mov a, #62
    add a, dpl
    mov dpl, a
    jnc 1$
    inc dph
1$:
    // uint16_t tmp = B + 9*A;  -> b, a
    mov a, dph
    mov b, #9
    mul ab
    add a, dpl
    jnc 2$
    inc b
2$:
    // tmp <<= 1
    clr c
    rlc a
    mov r1, a  // lo(tmp) -> r1
    mov a, b
    rlc a
    mov r2, a  // hi(tmp) -> r2

    // tmp += hi(0x12*B);
    mov a, dpl
    mov b, #0x12
    mul ab
    mov a, b
    add a, r1
    jnc 3$
    inc r2
3$:
    // hi(tmp) += 2*A
    mov a, r2
    add a, dph
    add a, dph
    // return hi(tmp)
    mov dpl, a
    __endasm;
}

static uint8_t _ic_kernel(uint16_t value)
{
    (void)value;
    // A (hi) - dph
    // B (low) - dpl
    // out = value*0x01CD / 65536
    __asm
    // uint16_t tmp = B + 0xCD*A; -> b, a
    mov a, dph
    mov b, #0xCD
    mul ab
    add a, dpl
    jnc 2$
    inc b
2$:
    mov r1, b   // hi(tmp) -> r1
    xch a, dpl  // lo(tmp) -> dpl, B -> a

    // tmp += h1(0xCD*B);
    mov b, #0xCD
    mul ab
    mov a, b
    add a, dpl
    jnc 3$
    inc r1
3$:
    mov a, dph  // A -> a
    add a, r1  // hi(tmp) += A
    mov dpl, a // return hi(tmp)
    __endasm;
}
#pragma restore

// Output is I/14218*100 (I*461/65535)  +71
uint8_t ic(uint16_t current)
{
    if (current > 36037) return VE_Overflow;  // 2.53A
    return _ic_kernel(current+71);
}

static __idata uint8_t str_buf[5];

char* str_20v(uint8_t voltage)
{
    switch(voltage)
    {
        case 0: return " <10";
        case VE_Overflow: return " >21";
    }
    __asm
    mov	r0,#(_str_buf + 3)  // p = str_buf+3

	mov	b,#10
	mov	a,dpl
	div	ab     // voltage/10
    mov r1,a   // r1 = voltage/10
	mov	r6,b   // r6 = voltage%10
	mov	a,#0x30
	add	a,r6
	mov	@r0,a  // *p-- = '0' + r6
    dec r0

	mov	@r0,#0x2e // *p-- = '.'
    dec r0

	mov	b,#10
	mov	a,r1
	div	ab      // voltage/10
    mov	r1,a    // r1 = voltage/10
	mov	r6,b    // r6 = voltage%10
	mov	a,#0x30
    add a,r6
	mov	@r0,a   // *p-- = '0' + r6
	dec r0

    mov	a,#0x31
    add a,r1
	mov	@r0,a   // *p = '1' + r1
    __endasm;
    return str_buf;
}

char* str_4v(uint8_t voltage)
{
    if (voltage==VE_Overflow) return ">5.1";
    __asm
    mov dph, #25

_str_2v:
    mov	r0,#(_str_buf + 3)  // p = str_buf+3

    mov	b,#10
	mov	a,dpl
	div	ab     // voltage/10
    mov r1,a   // r1 = voltage/10
	mov	r6,b   // r6 = voltage%10
	mov	a,#0x30
	add	a,r6
	mov	@r0,a  // *p-- = '0' + r6
    dec r0

    mov	b,#10
	mov	a,r1
    add a, dph
	div	ab      // voltage/10
    mov	r1,a    // r1 = voltage/10
	mov	r6,b    // r6 = voltage%10
	mov	a,#0x30
    add a,r6
	mov	@r0,a   // *p-- = '0' + r6
	dec r0

    mov	@r0,#0x2e // *p-- = '.'
    dec r0

    mov	a,#0x30
    add a,r1
	mov	@r0,a   // *p = '0' + r1

    __endasm;
    return str_buf;
}

char* str_ic(uint8_t current)
{
    if (current==VE_Overflow) return ">2.5";
    return str_2v(current);
}
