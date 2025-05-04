
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a8010113          	addi	sp,sp,-1408 # 80008a80 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ee70713          	addi	a4,a4,-1810 # 80008940 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	3dc78793          	addi	a5,a5,988 # 80006440 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd744f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	71e080e7          	jalr	1822(ra) # 8000284a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8f650513          	addi	a0,a0,-1802 # 80010a80 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8e648493          	addi	s1,s1,-1818 # 80010a80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	97690913          	addi	s2,s2,-1674 # 80010b18 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	4cc080e7          	jalr	1228(ra) # 80002694 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	20a080e7          	jalr	522(ra) # 800023e0 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	5e2080e7          	jalr	1506(ra) # 800027f4 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	85a50513          	addi	a0,a0,-1958 # 80010a80 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	84450513          	addi	a0,a0,-1980 # 80010a80 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8af72323          	sw	a5,-1882(a4) # 80010b18 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7b450513          	addi	a0,a0,1972 # 80010a80 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	5ae080e7          	jalr	1454(ra) # 800028a0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	78650513          	addi	a0,a0,1926 # 80010a80 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	76270713          	addi	a4,a4,1890 # 80010a80 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	73878793          	addi	a5,a5,1848 # 80010a80 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7a27a783          	lw	a5,1954(a5) # 80010b18 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6f670713          	addi	a4,a4,1782 # 80010a80 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6e648493          	addi	s1,s1,1766 # 80010a80 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6aa70713          	addi	a4,a4,1706 # 80010a80 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72a23          	sw	a5,1844(a4) # 80010b20 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	66e78793          	addi	a5,a5,1646 # 80010a80 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ec7a323          	sw	a2,1766(a5) # 80010b1c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6da50513          	addi	a0,a0,1754 # 80010b18 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	ffe080e7          	jalr	-2(ra) # 80002444 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	62050513          	addi	a0,a0,1568 # 80010a80 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00026797          	auipc	a5,0x26
    8000047c:	da078793          	addi	a5,a5,-608 # 80026218 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5e07ab23          	sw	zero,1526(a5) # 80010b40 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	38f72123          	sw	a5,898(a4) # 80008900 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	586dad83          	lw	s11,1414(s11) # 80010b40 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	53050513          	addi	a0,a0,1328 # 80010b28 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3d250513          	addi	a0,a0,978 # 80010b28 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	3b648493          	addi	s1,s1,950 # 80010b28 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	37650513          	addi	a0,a0,886 # 80010b48 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	1027a783          	lw	a5,258(a5) # 80008900 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0d27b783          	ld	a5,210(a5) # 80008908 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0d273703          	ld	a4,210(a4) # 80008910 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2e8a0a13          	addi	s4,s4,744 # 80010b48 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	0a048493          	addi	s1,s1,160 # 80008908 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	0a098993          	addi	s3,s3,160 # 80008910 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	bb2080e7          	jalr	-1102(ra) # 80002444 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	27a50513          	addi	a0,a0,634 # 80010b48 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0227a783          	lw	a5,34(a5) # 80008900 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	02873703          	ld	a4,40(a4) # 80008910 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0187b783          	ld	a5,24(a5) # 80008908 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	24c98993          	addi	s3,s3,588 # 80010b48 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	00448493          	addi	s1,s1,4 # 80008908 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	00490913          	addi	s2,s2,4 # 80008910 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	ac4080e7          	jalr	-1340(ra) # 800023e0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	21648493          	addi	s1,s1,534 # 80010b48 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fce7b523          	sd	a4,-54(a5) # 80008910 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	18c48493          	addi	s1,s1,396 # 80010b48 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00027797          	auipc	a5,0x27
    80000a02:	9b278793          	addi	a5,a5,-1614 # 800273b0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	16290913          	addi	s2,s2,354 # 80010b80 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0c650513          	addi	a0,a0,198 # 80010b80 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00027517          	auipc	a0,0x27
    80000ad2:	8e250513          	addi	a0,a0,-1822 # 800273b0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	09048493          	addi	s1,s1,144 # 80010b80 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	07850513          	addi	a0,a0,120 # 80010b80 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	04c50513          	addi	a0,a0,76 # 80010b80 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a9070713          	addi	a4,a4,-1392 # 80008918 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	cd6080e7          	jalr	-810(ra) # 80002b94 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	5ba080e7          	jalr	1466(ra) # 80006480 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	3f0080e7          	jalr	1008(ra) # 800022be <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	c36080e7          	jalr	-970(ra) # 80002b6c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	c56080e7          	jalr	-938(ra) # 80002b94 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	524080e7          	jalr	1316(ra) # 8000646a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	532080e7          	jalr	1330(ra) # 80006480 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	6d8080e7          	jalr	1752(ra) # 8000362e <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	d7c080e7          	jalr	-644(ra) # 80003cda <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	d1a080e7          	jalr	-742(ra) # 80004c80 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	61a080e7          	jalr	1562(ra) # 80006588 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d3a080e7          	jalr	-710(ra) # 80001cb0 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	98f72a23          	sw	a5,-1644(a4) # 80008918 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9887b783          	ld	a5,-1656(a5) # 80008920 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ca7b623          	sd	a0,1740(a5) # 80008920 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	78448493          	addi	s1,s1,1924 # 80010fd0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	0001aa17          	auipc	s4,0x1a
    8000186a:	76aa0a13          	addi	s4,s4,1898 # 8001bfd0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8599                	srai	a1,a1,0x6
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	2c048493          	addi	s1,s1,704
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2b850513          	addi	a0,a0,696 # 80010ba0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2b850513          	addi	a0,a0,696 # 80010bb8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6c048493          	addi	s1,s1,1728 # 80010fd0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	0001a997          	auipc	s3,0x1a
    80001936:	69e98993          	addi	s3,s3,1694 # 8001bfd0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8799                	srai	a5,a5,0x6
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	2c048493          	addi	s1,s1,704
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	23450513          	addi	a0,a0,564 # 80010bd0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1dc70713          	addi	a4,a4,476 # 80010ba0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	ea47a783          	lw	a5,-348(a5) # 800088a0 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	1a6080e7          	jalr	422(ra) # 80002bac <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e807a523          	sw	zero,-374(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	23a080e7          	jalr	570(ra) # 80003c5a <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	16a90913          	addi	s2,s2,362 # 80010ba0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e6478793          	addi	a5,a5,-412 # 800088ac <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	40e48493          	addi	s1,s1,1038 # 80010fd0 <proc>
    80001bca:	0001a917          	auipc	s2,0x1a
    80001bce:	40690913          	addi	s2,s2,1030 # 8001bfd0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	2c048493          	addi	s1,s1,704
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a8bd                	j	80001c72 <allocproc+0xbc>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c925                	beqz	a0,80001c80 <allocproc+0xca>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	cd25                	beqz	a0,80001c98 <allocproc+0xe2>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->tickets = 1;  // Default ticket count is 1
    80001c34:	4785                	li	a5,1
    80001c36:	2af4a623          	sw	a5,684(s1)
  p->arrival_time = ticks;  // Capture current time when process is created
    80001c3a:	00007717          	auipc	a4,0x7
    80001c3e:	d0272703          	lw	a4,-766(a4) # 8000893c <ticks>
    80001c42:	02071793          	slli	a5,a4,0x20
    80001c46:	9381                	srli	a5,a5,0x20
    80001c48:	2af4b823          	sd	a5,688(s1)
  p->current_priority=0;
    80001c4c:	2a04ac23          	sw	zero,696(s1)
  p->ticks_done=0;
    80001c50:	2a04ae23          	sw	zero,700(s1)
  p->context.ra = (uint64)forkret;
    80001c54:	00000797          	auipc	a5,0x0
    80001c58:	d9078793          	addi	a5,a5,-624 # 800019e4 <forkret>
    80001c5c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5e:	60bc                	ld	a5,64(s1)
    80001c60:	6685                	lui	a3,0x1
    80001c62:	97b6                	add	a5,a5,a3
    80001c64:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c66:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c6a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c6e:	16e4a623          	sw	a4,364(s1)
}
    80001c72:	8526                	mv	a0,s1
    80001c74:	60e2                	ld	ra,24(sp)
    80001c76:	6442                	ld	s0,16(sp)
    80001c78:	64a2                	ld	s1,8(sp)
    80001c7a:	6902                	ld	s2,0(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	edc080e7          	jalr	-292(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	bff1                	j	80001c72 <allocproc+0xbc>
    freeproc(p);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	ec4080e7          	jalr	-316(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	fe6080e7          	jalr	-26(ra) # 80000c8a <release>
    return 0;
    80001cac:	84ca                	mv	s1,s2
    80001cae:	b7d1                	j	80001c72 <allocproc+0xbc>

0000000080001cb0 <userinit>:
{
    80001cb0:	1101                	addi	sp,sp,-32
    80001cb2:	ec06                	sd	ra,24(sp)
    80001cb4:	e822                	sd	s0,16(sp)
    80001cb6:	e426                	sd	s1,8(sp)
    80001cb8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	efc080e7          	jalr	-260(ra) # 80001bb6 <allocproc>
    80001cc2:	84aa                	mv	s1,a0
  initproc = p;
    80001cc4:	00007797          	auipc	a5,0x7
    80001cc8:	c6a7b623          	sd	a0,-916(a5) # 80008930 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ccc:	03400613          	li	a2,52
    80001cd0:	00007597          	auipc	a1,0x7
    80001cd4:	be058593          	addi	a1,a1,-1056 # 800088b0 <initcode>
    80001cd8:	6928                	ld	a0,80(a0)
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	67c080e7          	jalr	1660(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001ce2:	6785                	lui	a5,0x1
    80001ce4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cec:	6cb8                	ld	a4,88(s1)
    80001cee:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf0:	4641                	li	a2,16
    80001cf2:	00006597          	auipc	a1,0x6
    80001cf6:	50e58593          	addi	a1,a1,1294 # 80008200 <digits+0x1c0>
    80001cfa:	15848513          	addi	a0,s1,344
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	11e080e7          	jalr	286(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d06:	00006517          	auipc	a0,0x6
    80001d0a:	50a50513          	addi	a0,a0,1290 # 80008210 <digits+0x1d0>
    80001d0e:	00003097          	auipc	ra,0x3
    80001d12:	96e080e7          	jalr	-1682(ra) # 8000467c <namei>
    80001d16:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1a:	478d                	li	a5,3
    80001d1c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	f6a080e7          	jalr	-150(ra) # 80000c8a <release>
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret

0000000080001d32 <growproc>:
{
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	e04a                	sd	s2,0(sp)
    80001d3c:	1000                	addi	s0,sp,32
    80001d3e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	c6c080e7          	jalr	-916(ra) # 800019ac <myproc>
    80001d48:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d4a:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d4c:	01204c63          	bgtz	s2,80001d64 <growproc+0x32>
  else if (n < 0)
    80001d50:	02094663          	bltz	s2,80001d7c <growproc+0x4a>
  p->sz = sz;
    80001d54:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d56:	4501                	li	a0,0
}
    80001d58:	60e2                	ld	ra,24(sp)
    80001d5a:	6442                	ld	s0,16(sp)
    80001d5c:	64a2                	ld	s1,8(sp)
    80001d5e:	6902                	ld	s2,0(sp)
    80001d60:	6105                	addi	sp,sp,32
    80001d62:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d64:	4691                	li	a3,4
    80001d66:	00b90633          	add	a2,s2,a1
    80001d6a:	6928                	ld	a0,80(a0)
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	6a4080e7          	jalr	1700(ra) # 80001410 <uvmalloc>
    80001d74:	85aa                	mv	a1,a0
    80001d76:	fd79                	bnez	a0,80001d54 <growproc+0x22>
      return -1;
    80001d78:	557d                	li	a0,-1
    80001d7a:	bff9                	j	80001d58 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d7c:	00b90633          	add	a2,s2,a1
    80001d80:	6928                	ld	a0,80(a0)
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	646080e7          	jalr	1606(ra) # 800013c8 <uvmdealloc>
    80001d8a:	85aa                	mv	a1,a0
    80001d8c:	b7e1                	j	80001d54 <growproc+0x22>

0000000080001d8e <fork>:
{
    80001d8e:	7139                	addi	sp,sp,-64
    80001d90:	fc06                	sd	ra,56(sp)
    80001d92:	f822                	sd	s0,48(sp)
    80001d94:	f426                	sd	s1,40(sp)
    80001d96:	f04a                	sd	s2,32(sp)
    80001d98:	ec4e                	sd	s3,24(sp)
    80001d9a:	e852                	sd	s4,16(sp)
    80001d9c:	e456                	sd	s5,8(sp)
    80001d9e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	c0c080e7          	jalr	-1012(ra) # 800019ac <myproc>
    80001da8:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001daa:	00000097          	auipc	ra,0x0
    80001dae:	e0c080e7          	jalr	-500(ra) # 80001bb6 <allocproc>
    80001db2:	12050063          	beqz	a0,80001ed2 <fork+0x144>
    80001db6:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001db8:	048ab603          	ld	a2,72(s5)
    80001dbc:	692c                	ld	a1,80(a0)
    80001dbe:	050ab503          	ld	a0,80(s5)
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	7a2080e7          	jalr	1954(ra) # 80001564 <uvmcopy>
    80001dca:	04054863          	bltz	a0,80001e1a <fork+0x8c>
  np->sz = p->sz;
    80001dce:	048ab783          	ld	a5,72(s5)
    80001dd2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd6:	058ab683          	ld	a3,88(s5)
    80001dda:	87b6                	mv	a5,a3
    80001ddc:	0589b703          	ld	a4,88(s3)
    80001de0:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80001de4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de8:	6788                	ld	a0,8(a5)
    80001dea:	6b8c                	ld	a1,16(a5)
    80001dec:	6f90                	ld	a2,24(a5)
    80001dee:	01073023          	sd	a6,0(a4)
    80001df2:	e708                	sd	a0,8(a4)
    80001df4:	eb0c                	sd	a1,16(a4)
    80001df6:	ef10                	sd	a2,24(a4)
    80001df8:	02078793          	addi	a5,a5,32
    80001dfc:	02070713          	addi	a4,a4,32
    80001e00:	fed792e3          	bne	a5,a3,80001de4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e04:	0589b783          	ld	a5,88(s3)
    80001e08:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e0c:	0d0a8493          	addi	s1,s5,208
    80001e10:	0d098913          	addi	s2,s3,208
    80001e14:	150a8a13          	addi	s4,s5,336
    80001e18:	a00d                	j	80001e3a <fork+0xac>
    freeproc(np);
    80001e1a:	854e                	mv	a0,s3
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	d42080e7          	jalr	-702(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e24:	854e                	mv	a0,s3
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	e64080e7          	jalr	-412(ra) # 80000c8a <release>
    return -1;
    80001e2e:	597d                	li	s2,-1
    80001e30:	a079                	j	80001ebe <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80001e32:	04a1                	addi	s1,s1,8
    80001e34:	0921                	addi	s2,s2,8
    80001e36:	01448b63          	beq	s1,s4,80001e4c <fork+0xbe>
    if (p->ofile[i])
    80001e3a:	6088                	ld	a0,0(s1)
    80001e3c:	d97d                	beqz	a0,80001e32 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3e:	00003097          	auipc	ra,0x3
    80001e42:	ed4080e7          	jalr	-300(ra) # 80004d12 <filedup>
    80001e46:	00a93023          	sd	a0,0(s2)
    80001e4a:	b7e5                	j	80001e32 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e4c:	150ab503          	ld	a0,336(s5)
    80001e50:	00002097          	auipc	ra,0x2
    80001e54:	048080e7          	jalr	72(ra) # 80003e98 <idup>
    80001e58:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5c:	4641                	li	a2,16
    80001e5e:	158a8593          	addi	a1,s5,344
    80001e62:	15898513          	addi	a0,s3,344
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	fb6080e7          	jalr	-74(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e6e:	0309a903          	lw	s2,48(s3)
  np->tickets=p->tickets;
    80001e72:	2acaa783          	lw	a5,684(s5)
    80001e76:	2af9a623          	sw	a5,684(s3)
  release(&np->lock);
    80001e7a:	854e                	mv	a0,s3
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e84:	0000f497          	auipc	s1,0xf
    80001e88:	d3448493          	addi	s1,s1,-716 # 80010bb8 <wait_lock>
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	d48080e7          	jalr	-696(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e96:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dee080e7          	jalr	-530(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ea4:	854e                	mv	a0,s3
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	d30080e7          	jalr	-720(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eae:	478d                	li	a5,3
    80001eb0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb4:	854e                	mv	a0,s3
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	dd4080e7          	jalr	-556(ra) # 80000c8a <release>
}
    80001ebe:	854a                	mv	a0,s2
    80001ec0:	70e2                	ld	ra,56(sp)
    80001ec2:	7442                	ld	s0,48(sp)
    80001ec4:	74a2                	ld	s1,40(sp)
    80001ec6:	7902                	ld	s2,32(sp)
    80001ec8:	69e2                	ld	s3,24(sp)
    80001eca:	6a42                	ld	s4,16(sp)
    80001ecc:	6aa2                	ld	s5,8(sp)
    80001ece:	6121                	addi	sp,sp,64
    80001ed0:	8082                	ret
    return -1;
    80001ed2:	597d                	li	s2,-1
    80001ed4:	b7ed                	j	80001ebe <fork+0x130>

0000000080001ed6 <random>:
random(void) {
    80001ed6:	1141                	addi	sp,sp,-16
    80001ed8:	e422                	sd	s0,8(sp)
    80001eda:	0800                	addi	s0,sp,16
  seed = seed * 1664525 + 1013904223;  // LCG parameters
    80001edc:	00007717          	auipc	a4,0x7
    80001ee0:	9cc70713          	addi	a4,a4,-1588 # 800088a8 <seed>
    80001ee4:	4308                	lw	a0,0(a4)
    80001ee6:	001967b7          	lui	a5,0x196
    80001eea:	60d7879b          	addiw	a5,a5,1549
    80001eee:	02f5053b          	mulw	a0,a0,a5
    80001ef2:	3c6ef7b7          	lui	a5,0x3c6ef
    80001ef6:	35f7879b          	addiw	a5,a5,863
    80001efa:	9d3d                	addw	a0,a0,a5
    80001efc:	c308                	sw	a0,0(a4)
}
    80001efe:	2501                	sext.w	a0,a0
    80001f00:	6422                	ld	s0,8(sp)
    80001f02:	0141                	addi	sp,sp,16
    80001f04:	8082                	ret

0000000080001f06 <lbs_scheduler>:
{
    80001f06:	715d                	addi	sp,sp,-80
    80001f08:	e486                	sd	ra,72(sp)
    80001f0a:	e0a2                	sd	s0,64(sp)
    80001f0c:	fc26                	sd	s1,56(sp)
    80001f0e:	f84a                	sd	s2,48(sp)
    80001f10:	f44e                	sd	s3,40(sp)
    80001f12:	f052                	sd	s4,32(sp)
    80001f14:	ec56                	sd	s5,24(sp)
    80001f16:	e85a                	sd	s6,16(sp)
    80001f18:	e45e                	sd	s7,8(sp)
    80001f1a:	e062                	sd	s8,0(sp)
    80001f1c:	0880                	addi	s0,sp,80
    80001f1e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f20:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f22:	00779b93          	slli	s7,a5,0x7
    80001f26:	0000f717          	auipc	a4,0xf
    80001f2a:	c7a70713          	addi	a4,a4,-902 # 80010ba0 <pid_lock>
    80001f2e:	975e                	add	a4,a4,s7
    80001f30:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &selected->context);
    80001f34:	0000f717          	auipc	a4,0xf
    80001f38:	ca470713          	addi	a4,a4,-860 # 80010bd8 <cpus+0x8>
    80001f3c:	9bba                	add	s7,s7,a4
    total_tickets = 0;
    80001f3e:	4a81                	li	s5,0
      if (p->state == RUNNABLE) 
    80001f40:	490d                	li	s2,3
    for (p = proc; p < &proc[NPROC]; p++) 
    80001f42:	0001a997          	auipc	s3,0x1a
    80001f46:	08e98993          	addi	s3,s3,142 # 8001bfd0 <tickslock>
      c->proc = selected;
    80001f4a:	079e                	slli	a5,a5,0x7
    80001f4c:	0000fb17          	auipc	s6,0xf
    80001f50:	c54b0b13          	addi	s6,s6,-940 # 80010ba0 <pid_lock>
    80001f54:	9b3e                	add	s6,s6,a5
    80001f56:	a861                	j	80001fee <lbs_scheduler+0xe8>
      release(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d30080e7          	jalr	-720(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++) 
    80001f62:	2c048493          	addi	s1,s1,704
    80001f66:	01348f63          	beq	s1,s3,80001f84 <lbs_scheduler+0x7e>
      acquire(&p->lock);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	c6a080e7          	jalr	-918(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE) 
    80001f74:	4c9c                	lw	a5,24(s1)
    80001f76:	ff2791e3          	bne	a5,s2,80001f58 <lbs_scheduler+0x52>
        total_tickets += p->tickets;
    80001f7a:	2ac4a783          	lw	a5,684(s1)
    80001f7e:	01878c3b          	addw	s8,a5,s8
    80001f82:	bfd9                	j	80001f58 <lbs_scheduler+0x52>
    winner_ticket = random() % total_tickets;  
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	f52080e7          	jalr	-174(ra) # 80001ed6 <random>
    80001f8c:	03857c3b          	remuw	s8,a0,s8
    int current_ticket = 0;
    80001f90:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++) 
    80001f92:	0000f497          	auipc	s1,0xf
    80001f96:	03e48493          	addi	s1,s1,62 # 80010fd0 <proc>
    80001f9a:	a811                	j	80001fae <lbs_scheduler+0xa8>
        release(&p->lock);  
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	cec080e7          	jalr	-788(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++) 
    80001fa6:	2c048493          	addi	s1,s1,704
    80001faa:	05348263          	beq	s1,s3,80001fee <lbs_scheduler+0xe8>
        acquire(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	c26080e7          	jalr	-986(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE) 
    80001fb8:	4c9c                	lw	a5,24(s1)
    80001fba:	ff2791e3          	bne	a5,s2,80001f9c <lbs_scheduler+0x96>
          current_ticket += p->tickets;
    80001fbe:	2ac4a783          	lw	a5,684(s1)
    80001fc2:	01478a3b          	addw	s4,a5,s4
          if (current_ticket > winner_ticket) 
    80001fc6:	fd4c5be3          	bge	s8,s4,80001f9c <lbs_scheduler+0x96>
      selected->state = RUNNING;
    80001fca:	4791                	li	a5,4
    80001fcc:	cc9c                	sw	a5,24(s1)
      c->proc = selected;
    80001fce:	029b3823          	sd	s1,48(s6)
      swtch(&c->context, &selected->context);
    80001fd2:	06048593          	addi	a1,s1,96
    80001fd6:	855e                	mv	a0,s7
    80001fd8:	00001097          	auipc	ra,0x1
    80001fdc:	b2a080e7          	jalr	-1238(ra) # 80002b02 <swtch>
      c->proc = 0;
    80001fe0:	020b3823          	sd	zero,48(s6)
      release(&selected->lock);  
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	ca4080e7          	jalr	-860(ra) # 80000c8a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff6:	10079073          	csrw	sstatus,a5
    total_tickets = 0;
    80001ffa:	8c56                	mv	s8,s5
    for (p = proc; p < &proc[NPROC]; p++) 
    80001ffc:	0000f497          	auipc	s1,0xf
    80002000:	fd448493          	addi	s1,s1,-44 # 80010fd0 <proc>
    80002004:	b79d                	j	80001f6a <lbs_scheduler+0x64>

0000000080002006 <mlfq_scheduler>:
{
    80002006:	7119                	addi	sp,sp,-128
    80002008:	fc86                	sd	ra,120(sp)
    8000200a:	f8a2                	sd	s0,112(sp)
    8000200c:	f4a6                	sd	s1,104(sp)
    8000200e:	f0ca                	sd	s2,96(sp)
    80002010:	ecce                	sd	s3,88(sp)
    80002012:	e8d2                	sd	s4,80(sp)
    80002014:	e4d6                	sd	s5,72(sp)
    80002016:	e0da                	sd	s6,64(sp)
    80002018:	fc5e                	sd	s7,56(sp)
    8000201a:	f862                	sd	s8,48(sp)
    8000201c:	f466                	sd	s9,40(sp)
    8000201e:	f06a                	sd	s10,32(sp)
    80002020:	ec6e                	sd	s11,24(sp)
    80002022:	0100                	addi	s0,sp,128
  asm volatile("mv %0, tp" : "=r" (x) );
    80002024:	8792                	mv	a5,tp
  int id = r_tp();
    80002026:	2781                	sext.w	a5,a5
    c->proc = 0;  
    80002028:	00779693          	slli	a3,a5,0x7
    8000202c:	0000f717          	auipc	a4,0xf
    80002030:	b7470713          	addi	a4,a4,-1164 # 80010ba0 <pid_lock>
    80002034:	9736                	add	a4,a4,a3
    80002036:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &selected->context);  
    8000203a:	0000f717          	auipc	a4,0xf
    8000203e:	b9e70713          	addi	a4,a4,-1122 # 80010bd8 <cpus+0x8>
    80002042:	9736                	add	a4,a4,a3
    80002044:	f8e43023          	sd	a4,-128(s0)
            for (p = proc; p < &proc[NPROC]; p++)
    80002048:	0001ab17          	auipc	s6,0x1a
    8000204c:	f88b0b13          	addi	s6,s6,-120 # 8001bfd0 <tickslock>
                if (p->ticks_done >= newticks[p->current_priority])
    80002050:	00007c17          	auipc	s8,0x7
    80002054:	860c0c13          	addi	s8,s8,-1952 # 800088b0 <initcode>
        if (c->proc != 0 && selected->current_priority < c->proc->current_priority)
    80002058:	0000f717          	auipc	a4,0xf
    8000205c:	b4870713          	addi	a4,a4,-1208 # 80010ba0 <pid_lock>
    80002060:	00d707b3          	add	a5,a4,a3
    80002064:	f8f43423          	sd	a5,-120(s0)
    80002068:	a215                	j	8000218c <mlfq_scheduler+0x186>
            sys_ticks = 0;  
    8000206a:	000d2023          	sw	zero,0(s10)
            for (p = proc; p < &proc[NPROC]; p++)
    8000206e:	0000f497          	auipc	s1,0xf
    80002072:	f6248493          	addi	s1,s1,-158 # 80010fd0 <proc>
    80002076:	a811                	j	8000208a <mlfq_scheduler+0x84>
                release(&p->lock);
    80002078:	8526                	mv	a0,s1
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>
            for (p = proc; p < &proc[NPROC]; p++)
    80002082:	2c048493          	addi	s1,s1,704
    80002086:	13648963          	beq	s1,s6,800021b8 <mlfq_scheduler+0x1b2>
                acquire(&p->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	b4a080e7          	jalr	-1206(ra) # 80000bd6 <acquire>
                if (p->state == RUNNABLE)
    80002094:	4c9c                	lw	a5,24(s1)
    80002096:	ff5791e3          	bne	a5,s5,80002078 <mlfq_scheduler+0x72>
                    p->current_priority = 0;  // Reset to highest priority
    8000209a:	2a04ac23          	sw	zero,696(s1)
                    p->ticks_done = 0;  // Reset ticks done
    8000209e:	2a04ae23          	sw	zero,700(s1)
    800020a2:	bfd9                	j	80002078 <mlfq_scheduler+0x72>
            release(&p->lock);
    800020a4:	8526                	mv	a0,s1
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	be4080e7          	jalr	-1052(ra) # 80000c8a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    800020ae:	2c048493          	addi	s1,s1,704
    800020b2:	05648163          	beq	s1,s6,800020f4 <mlfq_scheduler+0xee>
            acquire(&p->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	b1e080e7          	jalr	-1250(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE)
    800020c0:	4c9c                	lw	a5,24(s1)
    800020c2:	ff5791e3          	bne	a5,s5,800020a4 <mlfq_scheduler+0x9e>
                p->ticks_done++;
    800020c6:	2bc4a783          	lw	a5,700(s1)
    800020ca:	2785                	addiw	a5,a5,1
    800020cc:	0007869b          	sext.w	a3,a5
    800020d0:	2af4ae23          	sw	a5,700(s1)
                if (p->ticks_done >= newticks[p->current_priority])
    800020d4:	2b84a703          	lw	a4,696(s1)
    800020d8:	00271793          	slli	a5,a4,0x2
    800020dc:	97e2                	add	a5,a5,s8
    800020de:	5f9c                	lw	a5,56(a5)
    800020e0:	fcf6c2e3          	blt	a3,a5,800020a4 <mlfq_scheduler+0x9e>
                    p->ticks_done = 0;
    800020e4:	2a04ae23          	sw	zero,700(s1)
                    if (p->current_priority < 3)
    800020e8:	faeccee3          	blt	s9,a4,800020a4 <mlfq_scheduler+0x9e>
                        p->current_priority++;  // Move down a priority
    800020ec:	2705                	addiw	a4,a4,1
    800020ee:	2ae4ac23          	sw	a4,696(s1)
    800020f2:	bf4d                	j	800020a4 <mlfq_scheduler+0x9e>
    800020f4:	0000f497          	auipc	s1,0xf
    800020f8:	edc48493          	addi	s1,s1,-292 # 80010fd0 <proc>
    800020fc:	0000f917          	auipc	s2,0xf
    80002100:	19490913          	addi	s2,s2,404 # 80011290 <proc+0x2c0>
        selected = 0;
    80002104:	4b81                	li	s7,0
    80002106:	a02d                	j	80002130 <mlfq_scheduler+0x12a>
                if (selected == 0 || selected->current_priority > p->current_priority)
    80002108:	100b8963          	beqz	s7,8000221a <mlfq_scheduler+0x214>
    8000210c:	2b8ba703          	lw	a4,696(s7) # fffffffffffff2b8 <end+0xffffffff7ffd7f08>
    80002110:	ff892783          	lw	a5,-8(s2)
    80002114:	00e7d363          	bge	a5,a4,8000211a <mlfq_scheduler+0x114>
    80002118:	8ba6                	mv	s7,s1
            release(&p->lock);
    8000211a:	8552                	mv	a0,s4
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	b6e080e7          	jalr	-1170(ra) # 80000c8a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80002124:	0369fa63          	bgeu	s3,s6,80002158 <mlfq_scheduler+0x152>
    80002128:	2c048493          	addi	s1,s1,704
    8000212c:	2c090913          	addi	s2,s2,704
    80002130:	8a26                	mv	s4,s1
            acquire(&p->lock);
    80002132:	8526                	mv	a0,s1
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	aa2080e7          	jalr	-1374(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE)
    8000213c:	89ca                	mv	s3,s2
    8000213e:	d5892783          	lw	a5,-680(s2)
    80002142:	fd5783e3          	beq	a5,s5,80002108 <mlfq_scheduler+0x102>
            release(&p->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b42080e7          	jalr	-1214(ra) # 80000c8a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80002150:	fd696ce3          	bltu	s2,s6,80002128 <mlfq_scheduler+0x122>
        if (selected == 0)
    80002154:	040b8663          	beqz	s7,800021a0 <mlfq_scheduler+0x19a>
        if (c->proc != 0 && selected->current_priority < c->proc->current_priority)
    80002158:	f8843783          	ld	a5,-120(s0)
    8000215c:	7b88                	ld	a0,48(a5)
    8000215e:	c519                	beqz	a0,8000216c <mlfq_scheduler+0x166>
    80002160:	2b8ba703          	lw	a4,696(s7)
    80002164:	2b852783          	lw	a5,696(a0)
    80002168:	04f74d63          	blt	a4,a5,800021c2 <mlfq_scheduler+0x1bc>
        acquire(&selected->lock);
    8000216c:	84de                	mv	s1,s7
    8000216e:	855e                	mv	a0,s7
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	a66080e7          	jalr	-1434(ra) # 80000bd6 <acquire>
        if (selected->state == RUNNABLE)  // Ensure it's still runnable
    80002178:	018ba703          	lw	a4,24(s7)
    8000217c:	478d                	li	a5,3
    8000217e:	06f70c63          	beq	a4,a5,800021f6 <mlfq_scheduler+0x1f0>
        release(&selected->lock);  
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b06080e7          	jalr	-1274(ra) # 80000c8a <release>
        if (sys_ticks >= boost_ticks)
    8000218c:	00006d17          	auipc	s10,0x6
    80002190:	7acd0d13          	addi	s10,s10,1964 # 80008938 <sys_ticks>
    80002194:	00006d97          	auipc	s11,0x6
    80002198:	710d8d93          	addi	s11,s11,1808 # 800088a4 <boost_ticks>
                if (p->state == RUNNABLE)
    8000219c:	4a8d                	li	s5,3
                    if (p->current_priority < 3)
    8000219e:	4c89                	li	s9,2
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021a0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021a4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021a8:	10079073          	csrw	sstatus,a5
        if (sys_ticks >= boost_ticks)
    800021ac:	000d2703          	lw	a4,0(s10)
    800021b0:	000da783          	lw	a5,0(s11)
    800021b4:	eaf75be3          	bge	a4,a5,8000206a <mlfq_scheduler+0x64>
            for (p = proc; p < &proc[NPROC]; p++)
    800021b8:	0000f497          	auipc	s1,0xf
    800021bc:	e1848493          	addi	s1,s1,-488 # 80010fd0 <proc>
    800021c0:	bddd                	j	800020b6 <mlfq_scheduler+0xb0>
            acquire(&c->proc->lock);
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	a14080e7          	jalr	-1516(ra) # 80000bd6 <acquire>
            c->proc->state = RUNNABLE;  // Mark it runnable
    800021ca:	f8843683          	ld	a3,-120(s0)
    800021ce:	7a9c                	ld	a5,48(a3)
    800021d0:	470d                	li	a4,3
    800021d2:	cf98                	sw	a4,24(a5)
            if (c->proc->current_priority < 3)
    800021d4:	7a98                	ld	a4,48(a3)
    800021d6:	2b872783          	lw	a5,696(a4)
    800021da:	4689                	li	a3,2
    800021dc:	00f6c563          	blt	a3,a5,800021e6 <mlfq_scheduler+0x1e0>
                c->proc->current_priority++;
    800021e0:	2785                	addiw	a5,a5,1
    800021e2:	2af72c23          	sw	a5,696(a4)
            release(&c->proc->lock);
    800021e6:	f8843783          	ld	a5,-120(s0)
    800021ea:	7b88                	ld	a0,48(a5)
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	a9e080e7          	jalr	-1378(ra) # 80000c8a <release>
    800021f4:	bfa5                	j	8000216c <mlfq_scheduler+0x166>
            selected->state = RUNNING;  
    800021f6:	4791                	li	a5,4
    800021f8:	00fbac23          	sw	a5,24(s7)
            c->proc = selected;  
    800021fc:	f8843903          	ld	s2,-120(s0)
    80002200:	03793823          	sd	s7,48(s2)
            swtch(&c->context, &selected->context);  
    80002204:	060b8593          	addi	a1,s7,96
    80002208:	f8043503          	ld	a0,-128(s0)
    8000220c:	00001097          	auipc	ra,0x1
    80002210:	8f6080e7          	jalr	-1802(ra) # 80002b02 <swtch>
            c->proc = 0;  
    80002214:	02093823          	sd	zero,48(s2)
    80002218:	b7ad                	j	80002182 <mlfq_scheduler+0x17c>
    8000221a:	8ba6                	mv	s7,s1
    8000221c:	bdfd                	j	8000211a <mlfq_scheduler+0x114>

000000008000221e <rr_scheduler>:
 {
    8000221e:	7139                	addi	sp,sp,-64
    80002220:	fc06                	sd	ra,56(sp)
    80002222:	f822                	sd	s0,48(sp)
    80002224:	f426                	sd	s1,40(sp)
    80002226:	f04a                	sd	s2,32(sp)
    80002228:	ec4e                	sd	s3,24(sp)
    8000222a:	e852                	sd	s4,16(sp)
    8000222c:	e456                	sd	s5,8(sp)
    8000222e:	e05a                	sd	s6,0(sp)
    80002230:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80002232:	8792                	mv	a5,tp
  int id = r_tp();
    80002234:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002236:	00779a93          	slli	s5,a5,0x7
    8000223a:	0000f717          	auipc	a4,0xf
    8000223e:	96670713          	addi	a4,a4,-1690 # 80010ba0 <pid_lock>
    80002242:	9756                	add	a4,a4,s5
    80002244:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002248:	0000f717          	auipc	a4,0xf
    8000224c:	99070713          	addi	a4,a4,-1648 # 80010bd8 <cpus+0x8>
    80002250:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80002252:	498d                	li	s3,3
        p->state = RUNNING;
    80002254:	4b11                	li	s6,4
        c->proc = p;
    80002256:	079e                	slli	a5,a5,0x7
    80002258:	0000fa17          	auipc	s4,0xf
    8000225c:	948a0a13          	addi	s4,s4,-1720 # 80010ba0 <pid_lock>
    80002260:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002262:	0001a917          	auipc	s2,0x1a
    80002266:	d6e90913          	addi	s2,s2,-658 # 8001bfd0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000226a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000226e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002272:	10079073          	csrw	sstatus,a5
    80002276:	0000f497          	auipc	s1,0xf
    8000227a:	d5a48493          	addi	s1,s1,-678 # 80010fd0 <proc>
    8000227e:	a811                	j	80002292 <rr_scheduler+0x74>
      release(&p->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000228a:	2c048493          	addi	s1,s1,704
    8000228e:	fd248ee3          	beq	s1,s2,8000226a <rr_scheduler+0x4c>
      acquire(&p->lock);
    80002292:	8526                	mv	a0,s1
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	942080e7          	jalr	-1726(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    8000229c:	4c9c                	lw	a5,24(s1)
    8000229e:	ff3791e3          	bne	a5,s3,80002280 <rr_scheduler+0x62>
        p->state = RUNNING;
    800022a2:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800022a6:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800022aa:	06048593          	addi	a1,s1,96
    800022ae:	8556                	mv	a0,s5
    800022b0:	00001097          	auipc	ra,0x1
    800022b4:	852080e7          	jalr	-1966(ra) # 80002b02 <swtch>
        c->proc = 0;
    800022b8:	020a3823          	sd	zero,48(s4)
    800022bc:	b7d1                	j	80002280 <rr_scheduler+0x62>

00000000800022be <scheduler>:
 {
    800022be:	1141                	addi	sp,sp,-16
    800022c0:	e406                	sd	ra,8(sp)
    800022c2:	e022                	sd	s0,0(sp)
    800022c4:	0800                	addi	s0,sp,16
     lbs_scheduler();
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	c40080e7          	jalr	-960(ra) # 80001f06 <lbs_scheduler>

00000000800022ce <sched>:
{
    800022ce:	7179                	addi	sp,sp,-48
    800022d0:	f406                	sd	ra,40(sp)
    800022d2:	f022                	sd	s0,32(sp)
    800022d4:	ec26                	sd	s1,24(sp)
    800022d6:	e84a                	sd	s2,16(sp)
    800022d8:	e44e                	sd	s3,8(sp)
    800022da:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	6d0080e7          	jalr	1744(ra) # 800019ac <myproc>
    800022e4:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	876080e7          	jalr	-1930(ra) # 80000b5c <holding>
    800022ee:	c93d                	beqz	a0,80002364 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022f0:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022f2:	2781                	sext.w	a5,a5
    800022f4:	079e                	slli	a5,a5,0x7
    800022f6:	0000f717          	auipc	a4,0xf
    800022fa:	8aa70713          	addi	a4,a4,-1878 # 80010ba0 <pid_lock>
    800022fe:	97ba                	add	a5,a5,a4
    80002300:	0a87a703          	lw	a4,168(a5) # 3c6ef0a8 <_entry-0x43910f58>
    80002304:	4785                	li	a5,1
    80002306:	06f71763          	bne	a4,a5,80002374 <sched+0xa6>
  if (p->state == RUNNING)
    8000230a:	4c98                	lw	a4,24(s1)
    8000230c:	4791                	li	a5,4
    8000230e:	06f70b63          	beq	a4,a5,80002384 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002312:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002316:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002318:	efb5                	bnez	a5,80002394 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000231a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000231c:	0000f917          	auipc	s2,0xf
    80002320:	88490913          	addi	s2,s2,-1916 # 80010ba0 <pid_lock>
    80002324:	2781                	sext.w	a5,a5
    80002326:	079e                	slli	a5,a5,0x7
    80002328:	97ca                	add	a5,a5,s2
    8000232a:	0ac7a983          	lw	s3,172(a5)
    8000232e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002330:	2781                	sext.w	a5,a5
    80002332:	079e                	slli	a5,a5,0x7
    80002334:	0000f597          	auipc	a1,0xf
    80002338:	8a458593          	addi	a1,a1,-1884 # 80010bd8 <cpus+0x8>
    8000233c:	95be                	add	a1,a1,a5
    8000233e:	06048513          	addi	a0,s1,96
    80002342:	00000097          	auipc	ra,0x0
    80002346:	7c0080e7          	jalr	1984(ra) # 80002b02 <swtch>
    8000234a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000234c:	2781                	sext.w	a5,a5
    8000234e:	079e                	slli	a5,a5,0x7
    80002350:	97ca                	add	a5,a5,s2
    80002352:	0b37a623          	sw	s3,172(a5)
}
    80002356:	70a2                	ld	ra,40(sp)
    80002358:	7402                	ld	s0,32(sp)
    8000235a:	64e2                	ld	s1,24(sp)
    8000235c:	6942                	ld	s2,16(sp)
    8000235e:	69a2                	ld	s3,8(sp)
    80002360:	6145                	addi	sp,sp,48
    80002362:	8082                	ret
    panic("sched p->lock");
    80002364:	00006517          	auipc	a0,0x6
    80002368:	eb450513          	addi	a0,a0,-332 # 80008218 <digits+0x1d8>
    8000236c:	ffffe097          	auipc	ra,0xffffe
    80002370:	1d2080e7          	jalr	466(ra) # 8000053e <panic>
    panic("sched locks");
    80002374:	00006517          	auipc	a0,0x6
    80002378:	eb450513          	addi	a0,a0,-332 # 80008228 <digits+0x1e8>
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>
    panic("sched running");
    80002384:	00006517          	auipc	a0,0x6
    80002388:	eb450513          	addi	a0,a0,-332 # 80008238 <digits+0x1f8>
    8000238c:	ffffe097          	auipc	ra,0xffffe
    80002390:	1b2080e7          	jalr	434(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002394:	00006517          	auipc	a0,0x6
    80002398:	eb450513          	addi	a0,a0,-332 # 80008248 <digits+0x208>
    8000239c:	ffffe097          	auipc	ra,0xffffe
    800023a0:	1a2080e7          	jalr	418(ra) # 8000053e <panic>

00000000800023a4 <yield>:
{
    800023a4:	1101                	addi	sp,sp,-32
    800023a6:	ec06                	sd	ra,24(sp)
    800023a8:	e822                	sd	s0,16(sp)
    800023aa:	e426                	sd	s1,8(sp)
    800023ac:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	5fe080e7          	jalr	1534(ra) # 800019ac <myproc>
    800023b6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	81e080e7          	jalr	-2018(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800023c0:	478d                	li	a5,3
    800023c2:	cc9c                	sw	a5,24(s1)
  sched();
    800023c4:	00000097          	auipc	ra,0x0
    800023c8:	f0a080e7          	jalr	-246(ra) # 800022ce <sched>
  release(&p->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8bc080e7          	jalr	-1860(ra) # 80000c8a <release>
}
    800023d6:	60e2                	ld	ra,24(sp)
    800023d8:	6442                	ld	s0,16(sp)
    800023da:	64a2                	ld	s1,8(sp)
    800023dc:	6105                	addi	sp,sp,32
    800023de:	8082                	ret

00000000800023e0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023e0:	7179                	addi	sp,sp,-48
    800023e2:	f406                	sd	ra,40(sp)
    800023e4:	f022                	sd	s0,32(sp)
    800023e6:	ec26                	sd	s1,24(sp)
    800023e8:	e84a                	sd	s2,16(sp)
    800023ea:	e44e                	sd	s3,8(sp)
    800023ec:	1800                	addi	s0,sp,48
    800023ee:	89aa                	mv	s3,a0
    800023f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	5ba080e7          	jalr	1466(ra) # 800019ac <myproc>
    800023fa:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800023fc:	ffffe097          	auipc	ra,0xffffe
    80002400:	7da080e7          	jalr	2010(ra) # 80000bd6 <acquire>
  release(lk);
    80002404:	854a                	mv	a0,s2
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	884080e7          	jalr	-1916(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000240e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002412:	4789                	li	a5,2
    80002414:	cc9c                	sw	a5,24(s1)

  sched();
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	eb8080e7          	jalr	-328(ra) # 800022ce <sched>

  // Tidy up.
  p->chan = 0;
    8000241e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	866080e7          	jalr	-1946(ra) # 80000c8a <release>
  acquire(lk);
    8000242c:	854a                	mv	a0,s2
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7a8080e7          	jalr	1960(ra) # 80000bd6 <acquire>
}
    80002436:	70a2                	ld	ra,40(sp)
    80002438:	7402                	ld	s0,32(sp)
    8000243a:	64e2                	ld	s1,24(sp)
    8000243c:	6942                	ld	s2,16(sp)
    8000243e:	69a2                	ld	s3,8(sp)
    80002440:	6145                	addi	sp,sp,48
    80002442:	8082                	ret

0000000080002444 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002444:	7139                	addi	sp,sp,-64
    80002446:	fc06                	sd	ra,56(sp)
    80002448:	f822                	sd	s0,48(sp)
    8000244a:	f426                	sd	s1,40(sp)
    8000244c:	f04a                	sd	s2,32(sp)
    8000244e:	ec4e                	sd	s3,24(sp)
    80002450:	e852                	sd	s4,16(sp)
    80002452:	e456                	sd	s5,8(sp)
    80002454:	0080                	addi	s0,sp,64
    80002456:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002458:	0000f497          	auipc	s1,0xf
    8000245c:	b7848493          	addi	s1,s1,-1160 # 80010fd0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002460:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002462:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002464:	0001a917          	auipc	s2,0x1a
    80002468:	b6c90913          	addi	s2,s2,-1172 # 8001bfd0 <tickslock>
    8000246c:	a811                	j	80002480 <wakeup+0x3c>
      }
      release(&p->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	81a080e7          	jalr	-2022(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002478:	2c048493          	addi	s1,s1,704
    8000247c:	03248663          	beq	s1,s2,800024a8 <wakeup+0x64>
    if (p != myproc())
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	52c080e7          	jalr	1324(ra) # 800019ac <myproc>
    80002488:	fea488e3          	beq	s1,a0,80002478 <wakeup+0x34>
      acquire(&p->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	748080e7          	jalr	1864(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002496:	4c9c                	lw	a5,24(s1)
    80002498:	fd379be3          	bne	a5,s3,8000246e <wakeup+0x2a>
    8000249c:	709c                	ld	a5,32(s1)
    8000249e:	fd4798e3          	bne	a5,s4,8000246e <wakeup+0x2a>
        p->state = RUNNABLE;
    800024a2:	0154ac23          	sw	s5,24(s1)
    800024a6:	b7e1                	j	8000246e <wakeup+0x2a>
    }
  }
}
    800024a8:	70e2                	ld	ra,56(sp)
    800024aa:	7442                	ld	s0,48(sp)
    800024ac:	74a2                	ld	s1,40(sp)
    800024ae:	7902                	ld	s2,32(sp)
    800024b0:	69e2                	ld	s3,24(sp)
    800024b2:	6a42                	ld	s4,16(sp)
    800024b4:	6aa2                	ld	s5,8(sp)
    800024b6:	6121                	addi	sp,sp,64
    800024b8:	8082                	ret

00000000800024ba <reparent>:
{
    800024ba:	7179                	addi	sp,sp,-48
    800024bc:	f406                	sd	ra,40(sp)
    800024be:	f022                	sd	s0,32(sp)
    800024c0:	ec26                	sd	s1,24(sp)
    800024c2:	e84a                	sd	s2,16(sp)
    800024c4:	e44e                	sd	s3,8(sp)
    800024c6:	e052                	sd	s4,0(sp)
    800024c8:	1800                	addi	s0,sp,48
    800024ca:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024cc:	0000f497          	auipc	s1,0xf
    800024d0:	b0448493          	addi	s1,s1,-1276 # 80010fd0 <proc>
      pp->parent = initproc;
    800024d4:	00006a17          	auipc	s4,0x6
    800024d8:	45ca0a13          	addi	s4,s4,1116 # 80008930 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024dc:	0001a997          	auipc	s3,0x1a
    800024e0:	af498993          	addi	s3,s3,-1292 # 8001bfd0 <tickslock>
    800024e4:	a029                	j	800024ee <reparent+0x34>
    800024e6:	2c048493          	addi	s1,s1,704
    800024ea:	01348d63          	beq	s1,s3,80002504 <reparent+0x4a>
    if (pp->parent == p)
    800024ee:	7c9c                	ld	a5,56(s1)
    800024f0:	ff279be3          	bne	a5,s2,800024e6 <reparent+0x2c>
      pp->parent = initproc;
    800024f4:	000a3503          	ld	a0,0(s4)
    800024f8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024fa:	00000097          	auipc	ra,0x0
    800024fe:	f4a080e7          	jalr	-182(ra) # 80002444 <wakeup>
    80002502:	b7d5                	j	800024e6 <reparent+0x2c>
}
    80002504:	70a2                	ld	ra,40(sp)
    80002506:	7402                	ld	s0,32(sp)
    80002508:	64e2                	ld	s1,24(sp)
    8000250a:	6942                	ld	s2,16(sp)
    8000250c:	69a2                	ld	s3,8(sp)
    8000250e:	6a02                	ld	s4,0(sp)
    80002510:	6145                	addi	sp,sp,48
    80002512:	8082                	ret

0000000080002514 <exit>:
{
    80002514:	7179                	addi	sp,sp,-48
    80002516:	f406                	sd	ra,40(sp)
    80002518:	f022                	sd	s0,32(sp)
    8000251a:	ec26                	sd	s1,24(sp)
    8000251c:	e84a                	sd	s2,16(sp)
    8000251e:	e44e                	sd	s3,8(sp)
    80002520:	e052                	sd	s4,0(sp)
    80002522:	1800                	addi	s0,sp,48
    80002524:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	486080e7          	jalr	1158(ra) # 800019ac <myproc>
    8000252e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002530:	00006797          	auipc	a5,0x6
    80002534:	4007b783          	ld	a5,1024(a5) # 80008930 <initproc>
    80002538:	0d050493          	addi	s1,a0,208
    8000253c:	15050913          	addi	s2,a0,336
    80002540:	02a79363          	bne	a5,a0,80002566 <exit+0x52>
    panic("init exiting");
    80002544:	00006517          	auipc	a0,0x6
    80002548:	d1c50513          	addi	a0,a0,-740 # 80008260 <digits+0x220>
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	ff2080e7          	jalr	-14(ra) # 8000053e <panic>
      fileclose(f);
    80002554:	00003097          	auipc	ra,0x3
    80002558:	810080e7          	jalr	-2032(ra) # 80004d64 <fileclose>
      p->ofile[fd] = 0;
    8000255c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002560:	04a1                	addi	s1,s1,8
    80002562:	01248563          	beq	s1,s2,8000256c <exit+0x58>
    if (p->ofile[fd])
    80002566:	6088                	ld	a0,0(s1)
    80002568:	f575                	bnez	a0,80002554 <exit+0x40>
    8000256a:	bfdd                	j	80002560 <exit+0x4c>
  begin_op();
    8000256c:	00002097          	auipc	ra,0x2
    80002570:	32c080e7          	jalr	812(ra) # 80004898 <begin_op>
  iput(p->cwd);
    80002574:	1509b503          	ld	a0,336(s3)
    80002578:	00002097          	auipc	ra,0x2
    8000257c:	b18080e7          	jalr	-1256(ra) # 80004090 <iput>
  end_op();
    80002580:	00002097          	auipc	ra,0x2
    80002584:	398080e7          	jalr	920(ra) # 80004918 <end_op>
  p->cwd = 0;
    80002588:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000258c:	0000e497          	auipc	s1,0xe
    80002590:	62c48493          	addi	s1,s1,1580 # 80010bb8 <wait_lock>
    80002594:	8526                	mv	a0,s1
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	640080e7          	jalr	1600(ra) # 80000bd6 <acquire>
  reparent(p);
    8000259e:	854e                	mv	a0,s3
    800025a0:	00000097          	auipc	ra,0x0
    800025a4:	f1a080e7          	jalr	-230(ra) # 800024ba <reparent>
  wakeup(p->parent);
    800025a8:	0389b503          	ld	a0,56(s3)
    800025ac:	00000097          	auipc	ra,0x0
    800025b0:	e98080e7          	jalr	-360(ra) # 80002444 <wakeup>
  acquire(&p->lock);
    800025b4:	854e                	mv	a0,s3
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	620080e7          	jalr	1568(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800025be:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025c2:	4795                	li	a5,5
    800025c4:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800025c8:	00006797          	auipc	a5,0x6
    800025cc:	3747a783          	lw	a5,884(a5) # 8000893c <ticks>
    800025d0:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6b4080e7          	jalr	1716(ra) # 80000c8a <release>
  sched();
    800025de:	00000097          	auipc	ra,0x0
    800025e2:	cf0080e7          	jalr	-784(ra) # 800022ce <sched>
  panic("zombie exit");
    800025e6:	00006517          	auipc	a0,0x6
    800025ea:	c8a50513          	addi	a0,a0,-886 # 80008270 <digits+0x230>
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>

00000000800025f6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025f6:	7179                	addi	sp,sp,-48
    800025f8:	f406                	sd	ra,40(sp)
    800025fa:	f022                	sd	s0,32(sp)
    800025fc:	ec26                	sd	s1,24(sp)
    800025fe:	e84a                	sd	s2,16(sp)
    80002600:	e44e                	sd	s3,8(sp)
    80002602:	1800                	addi	s0,sp,48
    80002604:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002606:	0000f497          	auipc	s1,0xf
    8000260a:	9ca48493          	addi	s1,s1,-1590 # 80010fd0 <proc>
    8000260e:	0001a997          	auipc	s3,0x1a
    80002612:	9c298993          	addi	s3,s3,-1598 # 8001bfd0 <tickslock>
  {
    acquire(&p->lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	5be080e7          	jalr	1470(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002620:	589c                	lw	a5,48(s1)
    80002622:	01278d63          	beq	a5,s2,8000263c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002626:	8526                	mv	a0,s1
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	662080e7          	jalr	1634(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002630:	2c048493          	addi	s1,s1,704
    80002634:	ff3491e3          	bne	s1,s3,80002616 <kill+0x20>
  }
  return -1;
    80002638:	557d                	li	a0,-1
    8000263a:	a829                	j	80002654 <kill+0x5e>
      p->killed = 1;
    8000263c:	4785                	li	a5,1
    8000263e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002640:	4c98                	lw	a4,24(s1)
    80002642:	4789                	li	a5,2
    80002644:	00f70f63          	beq	a4,a5,80002662 <kill+0x6c>
      release(&p->lock);
    80002648:	8526                	mv	a0,s1
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	640080e7          	jalr	1600(ra) # 80000c8a <release>
      return 0;
    80002652:	4501                	li	a0,0
}
    80002654:	70a2                	ld	ra,40(sp)
    80002656:	7402                	ld	s0,32(sp)
    80002658:	64e2                	ld	s1,24(sp)
    8000265a:	6942                	ld	s2,16(sp)
    8000265c:	69a2                	ld	s3,8(sp)
    8000265e:	6145                	addi	sp,sp,48
    80002660:	8082                	ret
        p->state = RUNNABLE;
    80002662:	478d                	li	a5,3
    80002664:	cc9c                	sw	a5,24(s1)
    80002666:	b7cd                	j	80002648 <kill+0x52>

0000000080002668 <setkilled>:

void setkilled(struct proc *p)
{
    80002668:	1101                	addi	sp,sp,-32
    8000266a:	ec06                	sd	ra,24(sp)
    8000266c:	e822                	sd	s0,16(sp)
    8000266e:	e426                	sd	s1,8(sp)
    80002670:	1000                	addi	s0,sp,32
    80002672:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	562080e7          	jalr	1378(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000267c:	4785                	li	a5,1
    8000267e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002680:	8526                	mv	a0,s1
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	608080e7          	jalr	1544(ra) # 80000c8a <release>
}
    8000268a:	60e2                	ld	ra,24(sp)
    8000268c:	6442                	ld	s0,16(sp)
    8000268e:	64a2                	ld	s1,8(sp)
    80002690:	6105                	addi	sp,sp,32
    80002692:	8082                	ret

0000000080002694 <killed>:

int killed(struct proc *p)
{
    80002694:	1101                	addi	sp,sp,-32
    80002696:	ec06                	sd	ra,24(sp)
    80002698:	e822                	sd	s0,16(sp)
    8000269a:	e426                	sd	s1,8(sp)
    8000269c:	e04a                	sd	s2,0(sp)
    8000269e:	1000                	addi	s0,sp,32
    800026a0:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	534080e7          	jalr	1332(ra) # 80000bd6 <acquire>
  k = p->killed;
    800026aa:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800026ae:	8526                	mv	a0,s1
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	5da080e7          	jalr	1498(ra) # 80000c8a <release>
  return k;
}
    800026b8:	854a                	mv	a0,s2
    800026ba:	60e2                	ld	ra,24(sp)
    800026bc:	6442                	ld	s0,16(sp)
    800026be:	64a2                	ld	s1,8(sp)
    800026c0:	6902                	ld	s2,0(sp)
    800026c2:	6105                	addi	sp,sp,32
    800026c4:	8082                	ret

00000000800026c6 <wait>:
{
    800026c6:	715d                	addi	sp,sp,-80
    800026c8:	e486                	sd	ra,72(sp)
    800026ca:	e0a2                	sd	s0,64(sp)
    800026cc:	fc26                	sd	s1,56(sp)
    800026ce:	f84a                	sd	s2,48(sp)
    800026d0:	f44e                	sd	s3,40(sp)
    800026d2:	f052                	sd	s4,32(sp)
    800026d4:	ec56                	sd	s5,24(sp)
    800026d6:	e85a                	sd	s6,16(sp)
    800026d8:	e45e                	sd	s7,8(sp)
    800026da:	e062                	sd	s8,0(sp)
    800026dc:	0880                	addi	s0,sp,80
    800026de:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	2cc080e7          	jalr	716(ra) # 800019ac <myproc>
    800026e8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026ea:	0000e517          	auipc	a0,0xe
    800026ee:	4ce50513          	addi	a0,a0,1230 # 80010bb8 <wait_lock>
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	4e4080e7          	jalr	1252(ra) # 80000bd6 <acquire>
    havekids = 0;
    800026fa:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800026fc:	4a15                	li	s4,5
        havekids = 1;
    800026fe:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002700:	0001a997          	auipc	s3,0x1a
    80002704:	8d098993          	addi	s3,s3,-1840 # 8001bfd0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002708:	0000ec17          	auipc	s8,0xe
    8000270c:	4b0c0c13          	addi	s8,s8,1200 # 80010bb8 <wait_lock>
    havekids = 0;
    80002710:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002712:	0000f497          	auipc	s1,0xf
    80002716:	8be48493          	addi	s1,s1,-1858 # 80010fd0 <proc>
    8000271a:	a0bd                	j	80002788 <wait+0xc2>
          pid = pp->pid;
    8000271c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002720:	000b0e63          	beqz	s6,8000273c <wait+0x76>
    80002724:	4691                	li	a3,4
    80002726:	02c48613          	addi	a2,s1,44
    8000272a:	85da                	mv	a1,s6
    8000272c:	05093503          	ld	a0,80(s2)
    80002730:	fffff097          	auipc	ra,0xfffff
    80002734:	f38080e7          	jalr	-200(ra) # 80001668 <copyout>
    80002738:	02054563          	bltz	a0,80002762 <wait+0x9c>
          freeproc(pp);
    8000273c:	8526                	mv	a0,s1
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	420080e7          	jalr	1056(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	542080e7          	jalr	1346(ra) # 80000c8a <release>
          release(&wait_lock);
    80002750:	0000e517          	auipc	a0,0xe
    80002754:	46850513          	addi	a0,a0,1128 # 80010bb8 <wait_lock>
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	532080e7          	jalr	1330(ra) # 80000c8a <release>
          return pid;
    80002760:	a0b5                	j	800027cc <wait+0x106>
            release(&pp->lock);
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	526080e7          	jalr	1318(ra) # 80000c8a <release>
            release(&wait_lock);
    8000276c:	0000e517          	auipc	a0,0xe
    80002770:	44c50513          	addi	a0,a0,1100 # 80010bb8 <wait_lock>
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	516080e7          	jalr	1302(ra) # 80000c8a <release>
            return -1;
    8000277c:	59fd                	li	s3,-1
    8000277e:	a0b9                	j	800027cc <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002780:	2c048493          	addi	s1,s1,704
    80002784:	03348463          	beq	s1,s3,800027ac <wait+0xe6>
      if (pp->parent == p)
    80002788:	7c9c                	ld	a5,56(s1)
    8000278a:	ff279be3          	bne	a5,s2,80002780 <wait+0xba>
        acquire(&pp->lock);
    8000278e:	8526                	mv	a0,s1
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	446080e7          	jalr	1094(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002798:	4c9c                	lw	a5,24(s1)
    8000279a:	f94781e3          	beq	a5,s4,8000271c <wait+0x56>
        release(&pp->lock);
    8000279e:	8526                	mv	a0,s1
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	4ea080e7          	jalr	1258(ra) # 80000c8a <release>
        havekids = 1;
    800027a8:	8756                	mv	a4,s5
    800027aa:	bfd9                	j	80002780 <wait+0xba>
    if (!havekids || killed(p))
    800027ac:	c719                	beqz	a4,800027ba <wait+0xf4>
    800027ae:	854a                	mv	a0,s2
    800027b0:	00000097          	auipc	ra,0x0
    800027b4:	ee4080e7          	jalr	-284(ra) # 80002694 <killed>
    800027b8:	c51d                	beqz	a0,800027e6 <wait+0x120>
      release(&wait_lock);
    800027ba:	0000e517          	auipc	a0,0xe
    800027be:	3fe50513          	addi	a0,a0,1022 # 80010bb8 <wait_lock>
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	4c8080e7          	jalr	1224(ra) # 80000c8a <release>
      return -1;
    800027ca:	59fd                	li	s3,-1
}
    800027cc:	854e                	mv	a0,s3
    800027ce:	60a6                	ld	ra,72(sp)
    800027d0:	6406                	ld	s0,64(sp)
    800027d2:	74e2                	ld	s1,56(sp)
    800027d4:	7942                	ld	s2,48(sp)
    800027d6:	79a2                	ld	s3,40(sp)
    800027d8:	7a02                	ld	s4,32(sp)
    800027da:	6ae2                	ld	s5,24(sp)
    800027dc:	6b42                	ld	s6,16(sp)
    800027de:	6ba2                	ld	s7,8(sp)
    800027e0:	6c02                	ld	s8,0(sp)
    800027e2:	6161                	addi	sp,sp,80
    800027e4:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027e6:	85e2                	mv	a1,s8
    800027e8:	854a                	mv	a0,s2
    800027ea:	00000097          	auipc	ra,0x0
    800027ee:	bf6080e7          	jalr	-1034(ra) # 800023e0 <sleep>
    havekids = 0;
    800027f2:	bf39                	j	80002710 <wait+0x4a>

00000000800027f4 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027f4:	7179                	addi	sp,sp,-48
    800027f6:	f406                	sd	ra,40(sp)
    800027f8:	f022                	sd	s0,32(sp)
    800027fa:	ec26                	sd	s1,24(sp)
    800027fc:	e84a                	sd	s2,16(sp)
    800027fe:	e44e                	sd	s3,8(sp)
    80002800:	e052                	sd	s4,0(sp)
    80002802:	1800                	addi	s0,sp,48
    80002804:	84aa                	mv	s1,a0
    80002806:	892e                	mv	s2,a1
    80002808:	89b2                	mv	s3,a2
    8000280a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	1a0080e7          	jalr	416(ra) # 800019ac <myproc>
  if (user_dst)
    80002814:	c08d                	beqz	s1,80002836 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002816:	86d2                	mv	a3,s4
    80002818:	864e                	mv	a2,s3
    8000281a:	85ca                	mv	a1,s2
    8000281c:	6928                	ld	a0,80(a0)
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	e4a080e7          	jalr	-438(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002826:	70a2                	ld	ra,40(sp)
    80002828:	7402                	ld	s0,32(sp)
    8000282a:	64e2                	ld	s1,24(sp)
    8000282c:	6942                	ld	s2,16(sp)
    8000282e:	69a2                	ld	s3,8(sp)
    80002830:	6a02                	ld	s4,0(sp)
    80002832:	6145                	addi	sp,sp,48
    80002834:	8082                	ret
    memmove((char *)dst, src, len);
    80002836:	000a061b          	sext.w	a2,s4
    8000283a:	85ce                	mv	a1,s3
    8000283c:	854a                	mv	a0,s2
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	4f0080e7          	jalr	1264(ra) # 80000d2e <memmove>
    return 0;
    80002846:	8526                	mv	a0,s1
    80002848:	bff9                	j	80002826 <either_copyout+0x32>

000000008000284a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000284a:	7179                	addi	sp,sp,-48
    8000284c:	f406                	sd	ra,40(sp)
    8000284e:	f022                	sd	s0,32(sp)
    80002850:	ec26                	sd	s1,24(sp)
    80002852:	e84a                	sd	s2,16(sp)
    80002854:	e44e                	sd	s3,8(sp)
    80002856:	e052                	sd	s4,0(sp)
    80002858:	1800                	addi	s0,sp,48
    8000285a:	892a                	mv	s2,a0
    8000285c:	84ae                	mv	s1,a1
    8000285e:	89b2                	mv	s3,a2
    80002860:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	14a080e7          	jalr	330(ra) # 800019ac <myproc>
  if (user_src)
    8000286a:	c08d                	beqz	s1,8000288c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000286c:	86d2                	mv	a3,s4
    8000286e:	864e                	mv	a2,s3
    80002870:	85ca                	mv	a1,s2
    80002872:	6928                	ld	a0,80(a0)
    80002874:	fffff097          	auipc	ra,0xfffff
    80002878:	e80080e7          	jalr	-384(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000287c:	70a2                	ld	ra,40(sp)
    8000287e:	7402                	ld	s0,32(sp)
    80002880:	64e2                	ld	s1,24(sp)
    80002882:	6942                	ld	s2,16(sp)
    80002884:	69a2                	ld	s3,8(sp)
    80002886:	6a02                	ld	s4,0(sp)
    80002888:	6145                	addi	sp,sp,48
    8000288a:	8082                	ret
    memmove(dst, (char *)src, len);
    8000288c:	000a061b          	sext.w	a2,s4
    80002890:	85ce                	mv	a1,s3
    80002892:	854a                	mv	a0,s2
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	49a080e7          	jalr	1178(ra) # 80000d2e <memmove>
    return 0;
    8000289c:	8526                	mv	a0,s1
    8000289e:	bff9                	j	8000287c <either_copyin+0x32>

00000000800028a0 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800028a0:	715d                	addi	sp,sp,-80
    800028a2:	e486                	sd	ra,72(sp)
    800028a4:	e0a2                	sd	s0,64(sp)
    800028a6:	fc26                	sd	s1,56(sp)
    800028a8:	f84a                	sd	s2,48(sp)
    800028aa:	f44e                	sd	s3,40(sp)
    800028ac:	f052                	sd	s4,32(sp)
    800028ae:	ec56                	sd	s5,24(sp)
    800028b0:	e85a                	sd	s6,16(sp)
    800028b2:	e45e                	sd	s7,8(sp)
    800028b4:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800028b6:	00006517          	auipc	a0,0x6
    800028ba:	81250513          	addi	a0,a0,-2030 # 800080c8 <digits+0x88>
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	cca080e7          	jalr	-822(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028c6:	0000f497          	auipc	s1,0xf
    800028ca:	86248493          	addi	s1,s1,-1950 # 80011128 <proc+0x158>
    800028ce:	0001a917          	auipc	s2,0x1a
    800028d2:	85a90913          	addi	s2,s2,-1958 # 8001c128 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028d6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028d8:	00006997          	auipc	s3,0x6
    800028dc:	9a898993          	addi	s3,s3,-1624 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800028e0:	00006a97          	auipc	s5,0x6
    800028e4:	9a8a8a93          	addi	s5,s5,-1624 # 80008288 <digits+0x248>
    printf("\n");
    800028e8:	00005a17          	auipc	s4,0x5
    800028ec:	7e0a0a13          	addi	s4,s4,2016 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f0:	00006b97          	auipc	s7,0x6
    800028f4:	9d8b8b93          	addi	s7,s7,-1576 # 800082c8 <states.0>
    800028f8:	a00d                	j	8000291a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028fa:	ed86a583          	lw	a1,-296(a3)
    800028fe:	8556                	mv	a0,s5
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c88080e7          	jalr	-888(ra) # 80000588 <printf>
    printf("\n");
    80002908:	8552                	mv	a0,s4
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	c7e080e7          	jalr	-898(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002912:	2c048493          	addi	s1,s1,704
    80002916:	03248163          	beq	s1,s2,80002938 <procdump+0x98>
    if (p->state == UNUSED)
    8000291a:	86a6                	mv	a3,s1
    8000291c:	ec04a783          	lw	a5,-320(s1)
    80002920:	dbed                	beqz	a5,80002912 <procdump+0x72>
      state = "???";
    80002922:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002924:	fcfb6be3          	bltu	s6,a5,800028fa <procdump+0x5a>
    80002928:	1782                	slli	a5,a5,0x20
    8000292a:	9381                	srli	a5,a5,0x20
    8000292c:	078e                	slli	a5,a5,0x3
    8000292e:	97de                	add	a5,a5,s7
    80002930:	6390                	ld	a2,0(a5)
    80002932:	f661                	bnez	a2,800028fa <procdump+0x5a>
      state = "???";
    80002934:	864e                	mv	a2,s3
    80002936:	b7d1                	j	800028fa <procdump+0x5a>
  }
}
    80002938:	60a6                	ld	ra,72(sp)
    8000293a:	6406                	ld	s0,64(sp)
    8000293c:	74e2                	ld	s1,56(sp)
    8000293e:	7942                	ld	s2,48(sp)
    80002940:	79a2                	ld	s3,40(sp)
    80002942:	7a02                	ld	s4,32(sp)
    80002944:	6ae2                	ld	s5,24(sp)
    80002946:	6b42                	ld	s6,16(sp)
    80002948:	6ba2                	ld	s7,8(sp)
    8000294a:	6161                	addi	sp,sp,80
    8000294c:	8082                	ret

000000008000294e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000294e:	711d                	addi	sp,sp,-96
    80002950:	ec86                	sd	ra,88(sp)
    80002952:	e8a2                	sd	s0,80(sp)
    80002954:	e4a6                	sd	s1,72(sp)
    80002956:	e0ca                	sd	s2,64(sp)
    80002958:	fc4e                	sd	s3,56(sp)
    8000295a:	f852                	sd	s4,48(sp)
    8000295c:	f456                	sd	s5,40(sp)
    8000295e:	f05a                	sd	s6,32(sp)
    80002960:	ec5e                	sd	s7,24(sp)
    80002962:	e862                	sd	s8,16(sp)
    80002964:	e466                	sd	s9,8(sp)
    80002966:	e06a                	sd	s10,0(sp)
    80002968:	1080                	addi	s0,sp,96
    8000296a:	8b2a                	mv	s6,a0
    8000296c:	8bae                	mv	s7,a1
    8000296e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002970:	fffff097          	auipc	ra,0xfffff
    80002974:	03c080e7          	jalr	60(ra) # 800019ac <myproc>
    80002978:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000297a:	0000e517          	auipc	a0,0xe
    8000297e:	23e50513          	addi	a0,a0,574 # 80010bb8 <wait_lock>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	254080e7          	jalr	596(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000298a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000298c:	4a15                	li	s4,5
        havekids = 1;
    8000298e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002990:	00019997          	auipc	s3,0x19
    80002994:	64098993          	addi	s3,s3,1600 # 8001bfd0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002998:	0000ed17          	auipc	s10,0xe
    8000299c:	220d0d13          	addi	s10,s10,544 # 80010bb8 <wait_lock>
    havekids = 0;
    800029a0:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800029a2:	0000e497          	auipc	s1,0xe
    800029a6:	62e48493          	addi	s1,s1,1582 # 80010fd0 <proc>
    800029aa:	a059                	j	80002a30 <waitx+0xe2>
          pid = np->pid;
    800029ac:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800029b0:	1684a703          	lw	a4,360(s1)
    800029b4:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800029b8:	16c4a783          	lw	a5,364(s1)
    800029bc:	9f3d                	addw	a4,a4,a5
    800029be:	1704a783          	lw	a5,368(s1)
    800029c2:	9f99                	subw	a5,a5,a4
    800029c4:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800029c8:	000b0e63          	beqz	s6,800029e4 <waitx+0x96>
    800029cc:	4691                	li	a3,4
    800029ce:	02c48613          	addi	a2,s1,44
    800029d2:	85da                	mv	a1,s6
    800029d4:	05093503          	ld	a0,80(s2)
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	c90080e7          	jalr	-880(ra) # 80001668 <copyout>
    800029e0:	02054563          	bltz	a0,80002a0a <waitx+0xbc>
          freeproc(np);
    800029e4:	8526                	mv	a0,s1
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	178080e7          	jalr	376(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800029ee:	8526                	mv	a0,s1
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	29a080e7          	jalr	666(ra) # 80000c8a <release>
          release(&wait_lock);
    800029f8:	0000e517          	auipc	a0,0xe
    800029fc:	1c050513          	addi	a0,a0,448 # 80010bb8 <wait_lock>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	28a080e7          	jalr	650(ra) # 80000c8a <release>
          return pid;
    80002a08:	a09d                	j	80002a6e <waitx+0x120>
            release(&np->lock);
    80002a0a:	8526                	mv	a0,s1
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	27e080e7          	jalr	638(ra) # 80000c8a <release>
            release(&wait_lock);
    80002a14:	0000e517          	auipc	a0,0xe
    80002a18:	1a450513          	addi	a0,a0,420 # 80010bb8 <wait_lock>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	26e080e7          	jalr	622(ra) # 80000c8a <release>
            return -1;
    80002a24:	59fd                	li	s3,-1
    80002a26:	a0a1                	j	80002a6e <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002a28:	2c048493          	addi	s1,s1,704
    80002a2c:	03348463          	beq	s1,s3,80002a54 <waitx+0x106>
      if (np->parent == p)
    80002a30:	7c9c                	ld	a5,56(s1)
    80002a32:	ff279be3          	bne	a5,s2,80002a28 <waitx+0xda>
        acquire(&np->lock);
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	19e080e7          	jalr	414(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002a40:	4c9c                	lw	a5,24(s1)
    80002a42:	f74785e3          	beq	a5,s4,800029ac <waitx+0x5e>
        release(&np->lock);
    80002a46:	8526                	mv	a0,s1
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	242080e7          	jalr	578(ra) # 80000c8a <release>
        havekids = 1;
    80002a50:	8756                	mv	a4,s5
    80002a52:	bfd9                	j	80002a28 <waitx+0xda>
    if (!havekids || p->killed)
    80002a54:	c701                	beqz	a4,80002a5c <waitx+0x10e>
    80002a56:	02892783          	lw	a5,40(s2)
    80002a5a:	cb8d                	beqz	a5,80002a8c <waitx+0x13e>
      release(&wait_lock);
    80002a5c:	0000e517          	auipc	a0,0xe
    80002a60:	15c50513          	addi	a0,a0,348 # 80010bb8 <wait_lock>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	226080e7          	jalr	550(ra) # 80000c8a <release>
      return -1;
    80002a6c:	59fd                	li	s3,-1
  }
}
    80002a6e:	854e                	mv	a0,s3
    80002a70:	60e6                	ld	ra,88(sp)
    80002a72:	6446                	ld	s0,80(sp)
    80002a74:	64a6                	ld	s1,72(sp)
    80002a76:	6906                	ld	s2,64(sp)
    80002a78:	79e2                	ld	s3,56(sp)
    80002a7a:	7a42                	ld	s4,48(sp)
    80002a7c:	7aa2                	ld	s5,40(sp)
    80002a7e:	7b02                	ld	s6,32(sp)
    80002a80:	6be2                	ld	s7,24(sp)
    80002a82:	6c42                	ld	s8,16(sp)
    80002a84:	6ca2                	ld	s9,8(sp)
    80002a86:	6d02                	ld	s10,0(sp)
    80002a88:	6125                	addi	sp,sp,96
    80002a8a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a8c:	85ea                	mv	a1,s10
    80002a8e:	854a                	mv	a0,s2
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	950080e7          	jalr	-1712(ra) # 800023e0 <sleep>
    havekids = 0;
    80002a98:	b721                	j	800029a0 <waitx+0x52>

0000000080002a9a <update_time>:

void update_time()
{
    80002a9a:	7179                	addi	sp,sp,-48
    80002a9c:	f406                	sd	ra,40(sp)
    80002a9e:	f022                	sd	s0,32(sp)
    80002aa0:	ec26                	sd	s1,24(sp)
    80002aa2:	e84a                	sd	s2,16(sp)
    80002aa4:	e44e                	sd	s3,8(sp)
    80002aa6:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002aa8:	0000e497          	auipc	s1,0xe
    80002aac:	52848493          	addi	s1,s1,1320 # 80010fd0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002ab0:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002ab2:	00019917          	auipc	s2,0x19
    80002ab6:	51e90913          	addi	s2,s2,1310 # 8001bfd0 <tickslock>
    80002aba:	a811                	j	80002ace <update_time+0x34>
    {
      p->rtime++;
      p->ticks_done++;
    }
    release(&p->lock);
    80002abc:	8526                	mv	a0,s1
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	1cc080e7          	jalr	460(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ac6:	2c048493          	addi	s1,s1,704
    80002aca:	03248563          	beq	s1,s2,80002af4 <update_time+0x5a>
    acquire(&p->lock);
    80002ace:	8526                	mv	a0,s1
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	106080e7          	jalr	262(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002ad8:	4c9c                	lw	a5,24(s1)
    80002ada:	ff3791e3          	bne	a5,s3,80002abc <update_time+0x22>
      p->rtime++;
    80002ade:	1684a783          	lw	a5,360(s1)
    80002ae2:	2785                	addiw	a5,a5,1
    80002ae4:	16f4a423          	sw	a5,360(s1)
      p->ticks_done++;
    80002ae8:	2bc4a783          	lw	a5,700(s1)
    80002aec:	2785                	addiw	a5,a5,1
    80002aee:	2af4ae23          	sw	a5,700(s1)
    80002af2:	b7e9                	j	80002abc <update_time+0x22>
  }
}
    80002af4:	70a2                	ld	ra,40(sp)
    80002af6:	7402                	ld	s0,32(sp)
    80002af8:	64e2                	ld	s1,24(sp)
    80002afa:	6942                	ld	s2,16(sp)
    80002afc:	69a2                	ld	s3,8(sp)
    80002afe:	6145                	addi	sp,sp,48
    80002b00:	8082                	ret

0000000080002b02 <swtch>:
    80002b02:	00153023          	sd	ra,0(a0)
    80002b06:	00253423          	sd	sp,8(a0)
    80002b0a:	e900                	sd	s0,16(a0)
    80002b0c:	ed04                	sd	s1,24(a0)
    80002b0e:	03253023          	sd	s2,32(a0)
    80002b12:	03353423          	sd	s3,40(a0)
    80002b16:	03453823          	sd	s4,48(a0)
    80002b1a:	03553c23          	sd	s5,56(a0)
    80002b1e:	05653023          	sd	s6,64(a0)
    80002b22:	05753423          	sd	s7,72(a0)
    80002b26:	05853823          	sd	s8,80(a0)
    80002b2a:	05953c23          	sd	s9,88(a0)
    80002b2e:	07a53023          	sd	s10,96(a0)
    80002b32:	07b53423          	sd	s11,104(a0)
    80002b36:	0005b083          	ld	ra,0(a1)
    80002b3a:	0085b103          	ld	sp,8(a1)
    80002b3e:	6980                	ld	s0,16(a1)
    80002b40:	6d84                	ld	s1,24(a1)
    80002b42:	0205b903          	ld	s2,32(a1)
    80002b46:	0285b983          	ld	s3,40(a1)
    80002b4a:	0305ba03          	ld	s4,48(a1)
    80002b4e:	0385ba83          	ld	s5,56(a1)
    80002b52:	0405bb03          	ld	s6,64(a1)
    80002b56:	0485bb83          	ld	s7,72(a1)
    80002b5a:	0505bc03          	ld	s8,80(a1)
    80002b5e:	0585bc83          	ld	s9,88(a1)
    80002b62:	0605bd03          	ld	s10,96(a1)
    80002b66:	0685bd83          	ld	s11,104(a1)
    80002b6a:	8082                	ret

0000000080002b6c <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b6c:	1141                	addi	sp,sp,-16
    80002b6e:	e406                	sd	ra,8(sp)
    80002b70:	e022                	sd	s0,0(sp)
    80002b72:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b74:	00005597          	auipc	a1,0x5
    80002b78:	78458593          	addi	a1,a1,1924 # 800082f8 <states.0+0x30>
    80002b7c:	00019517          	auipc	a0,0x19
    80002b80:	45450513          	addi	a0,a0,1108 # 8001bfd0 <tickslock>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	fc2080e7          	jalr	-62(ra) # 80000b46 <initlock>
}
    80002b8c:	60a2                	ld	ra,8(sp)
    80002b8e:	6402                	ld	s0,0(sp)
    80002b90:	0141                	addi	sp,sp,16
    80002b92:	8082                	ret

0000000080002b94 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b94:	1141                	addi	sp,sp,-16
    80002b96:	e422                	sd	s0,8(sp)
    80002b98:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b9a:	00004797          	auipc	a5,0x4
    80002b9e:	81678793          	addi	a5,a5,-2026 # 800063b0 <kernelvec>
    80002ba2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ba6:	6422                	ld	s0,8(sp)
    80002ba8:	0141                	addi	sp,sp,16
    80002baa:	8082                	ret

0000000080002bac <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002bac:	1141                	addi	sp,sp,-16
    80002bae:	e406                	sd	ra,8(sp)
    80002bb0:	e022                	sd	s0,0(sp)
    80002bb2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	df8080e7          	jalr	-520(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bc0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bc6:	00004617          	auipc	a2,0x4
    80002bca:	43a60613          	addi	a2,a2,1082 # 80007000 <_trampoline>
    80002bce:	00004697          	auipc	a3,0x4
    80002bd2:	43268693          	addi	a3,a3,1074 # 80007000 <_trampoline>
    80002bd6:	8e91                	sub	a3,a3,a2
    80002bd8:	040007b7          	lui	a5,0x4000
    80002bdc:	17fd                	addi	a5,a5,-1
    80002bde:	07b2                	slli	a5,a5,0xc
    80002be0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002be2:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002be6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002be8:	180026f3          	csrr	a3,satp
    80002bec:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bee:	6d38                	ld	a4,88(a0)
    80002bf0:	6134                	ld	a3,64(a0)
    80002bf2:	6585                	lui	a1,0x1
    80002bf4:	96ae                	add	a3,a3,a1
    80002bf6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bf8:	6d38                	ld	a4,88(a0)
    80002bfa:	00000697          	auipc	a3,0x0
    80002bfe:	14c68693          	addi	a3,a3,332 # 80002d46 <usertrap>
    80002c02:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c04:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c06:	8692                	mv	a3,tp
    80002c08:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c0e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c12:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c16:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c1a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c1c:	6f18                	ld	a4,24(a4)
    80002c1e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c22:	6928                	ld	a0,80(a0)
    80002c24:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c26:	00004717          	auipc	a4,0x4
    80002c2a:	47670713          	addi	a4,a4,1142 # 8000709c <userret>
    80002c2e:	8f11                	sub	a4,a4,a2
    80002c30:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c32:	577d                	li	a4,-1
    80002c34:	177e                	slli	a4,a4,0x3f
    80002c36:	8d59                	or	a0,a0,a4
    80002c38:	9782                	jalr	a5
}
    80002c3a:	60a2                	ld	ra,8(sp)
    80002c3c:	6402                	ld	s0,0(sp)
    80002c3e:	0141                	addi	sp,sp,16
    80002c40:	8082                	ret

0000000080002c42 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}
int sys_ticks;
void clockintr()
{
    80002c42:	1101                	addi	sp,sp,-32
    80002c44:	ec06                	sd	ra,24(sp)
    80002c46:	e822                	sd	s0,16(sp)
    80002c48:	e426                	sd	s1,8(sp)
    80002c4a:	e04a                	sd	s2,0(sp)
    80002c4c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c4e:	00019917          	auipc	s2,0x19
    80002c52:	38290913          	addi	s2,s2,898 # 8001bfd0 <tickslock>
    80002c56:	854a                	mv	a0,s2
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	f7e080e7          	jalr	-130(ra) # 80000bd6 <acquire>
  ticks++;
    80002c60:	00006497          	auipc	s1,0x6
    80002c64:	cdc48493          	addi	s1,s1,-804 # 8000893c <ticks>
    80002c68:	409c                	lw	a5,0(s1)
    80002c6a:	2785                	addiw	a5,a5,1
    80002c6c:	c09c                	sw	a5,0(s1)
  sys_ticks++;
    80002c6e:	00006717          	auipc	a4,0x6
    80002c72:	cca70713          	addi	a4,a4,-822 # 80008938 <sys_ticks>
    80002c76:	431c                	lw	a5,0(a4)
    80002c78:	2785                	addiw	a5,a5,1
    80002c7a:	c31c                	sw	a5,0(a4)
  update_time();
    80002c7c:	00000097          	auipc	ra,0x0
    80002c80:	e1e080e7          	jalr	-482(ra) # 80002a9a <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002c84:	8526                	mv	a0,s1
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	7be080e7          	jalr	1982(ra) # 80002444 <wakeup>
  release(&tickslock);
    80002c8e:	854a                	mv	a0,s2
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	ffa080e7          	jalr	-6(ra) # 80000c8a <release>
}
    80002c98:	60e2                	ld	ra,24(sp)
    80002c9a:	6442                	ld	s0,16(sp)
    80002c9c:	64a2                	ld	s1,8(sp)
    80002c9e:	6902                	ld	s2,0(sp)
    80002ca0:	6105                	addi	sp,sp,32
    80002ca2:	8082                	ret

0000000080002ca4 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002ca4:	1101                	addi	sp,sp,-32
    80002ca6:	ec06                	sd	ra,24(sp)
    80002ca8:	e822                	sd	s0,16(sp)
    80002caa:	e426                	sd	s1,8(sp)
    80002cac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002cb2:	00074d63          	bltz	a4,80002ccc <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002cb6:	57fd                	li	a5,-1
    80002cb8:	17fe                	slli	a5,a5,0x3f
    80002cba:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002cbc:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002cbe:	06f70363          	beq	a4,a5,80002d24 <devintr+0x80>
  }
}
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	64a2                	ld	s1,8(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
      (scause & 0xff) == 9)
    80002ccc:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002cd0:	46a5                	li	a3,9
    80002cd2:	fed792e3          	bne	a5,a3,80002cb6 <devintr+0x12>
    int irq = plic_claim();
    80002cd6:	00003097          	auipc	ra,0x3
    80002cda:	7e2080e7          	jalr	2018(ra) # 800064b8 <plic_claim>
    80002cde:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ce0:	47a9                	li	a5,10
    80002ce2:	02f50763          	beq	a0,a5,80002d10 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002ce6:	4785                	li	a5,1
    80002ce8:	02f50963          	beq	a0,a5,80002d1a <devintr+0x76>
    return 1;
    80002cec:	4505                	li	a0,1
    else if (irq)
    80002cee:	d8f1                	beqz	s1,80002cc2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cf0:	85a6                	mv	a1,s1
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	60e50513          	addi	a0,a0,1550 # 80008300 <states.0+0x38>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	88e080e7          	jalr	-1906(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d02:	8526                	mv	a0,s1
    80002d04:	00003097          	auipc	ra,0x3
    80002d08:	7d8080e7          	jalr	2008(ra) # 800064dc <plic_complete>
    return 1;
    80002d0c:	4505                	li	a0,1
    80002d0e:	bf55                	j	80002cc2 <devintr+0x1e>
      uartintr();
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	c8a080e7          	jalr	-886(ra) # 8000099a <uartintr>
    80002d18:	b7ed                	j	80002d02 <devintr+0x5e>
      virtio_disk_intr();
    80002d1a:	00004097          	auipc	ra,0x4
    80002d1e:	c8e080e7          	jalr	-882(ra) # 800069a8 <virtio_disk_intr>
    80002d22:	b7c5                	j	80002d02 <devintr+0x5e>
    if (cpuid() == 0)
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	c5c080e7          	jalr	-932(ra) # 80001980 <cpuid>
    80002d2c:	c901                	beqz	a0,80002d3c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d2e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d34:	14479073          	csrw	sip,a5
    return 2;
    80002d38:	4509                	li	a0,2
    80002d3a:	b761                	j	80002cc2 <devintr+0x1e>
      clockintr();
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	f06080e7          	jalr	-250(ra) # 80002c42 <clockintr>
    80002d44:	b7ed                	j	80002d2e <devintr+0x8a>

0000000080002d46 <usertrap>:
{
    80002d46:	7179                	addi	sp,sp,-48
    80002d48:	f406                	sd	ra,40(sp)
    80002d4a:	f022                	sd	s0,32(sp)
    80002d4c:	ec26                	sd	s1,24(sp)
    80002d4e:	e84a                	sd	s2,16(sp)
    80002d50:	e44e                	sd	s3,8(sp)
    80002d52:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d54:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d58:	1007f793          	andi	a5,a5,256
    80002d5c:	eba5                	bnez	a5,80002dcc <usertrap+0x86>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d5e:	00003797          	auipc	a5,0x3
    80002d62:	65278793          	addi	a5,a5,1618 # 800063b0 <kernelvec>
    80002d66:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d6a:	fffff097          	auipc	ra,0xfffff
    80002d6e:	c42080e7          	jalr	-958(ra) # 800019ac <myproc>
    80002d72:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d74:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d76:	14102773          	csrr	a4,sepc
    80002d7a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d7c:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d80:	47a1                	li	a5,8
    80002d82:	04f70d63          	beq	a4,a5,80002ddc <usertrap+0x96>
  else if ((which_dev = devintr()) != 0)
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	f1e080e7          	jalr	-226(ra) # 80002ca4 <devintr>
    80002d8e:	892a                	mv	s2,a0
    80002d90:	c561                	beqz	a0,80002e58 <usertrap+0x112>
    struct proc *p = myproc();
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	c1a080e7          	jalr	-998(ra) # 800019ac <myproc>
    80002d9a:	89aa                	mv	s3,a0
    if (p && p->alarmticks > 0 && !p->alarm_active) {
    80002d9c:	c10d                	beqz	a0,80002dbe <usertrap+0x78>
    80002d9e:	17452783          	lw	a5,372(a0)
    80002da2:	00f05e63          	blez	a5,80002dbe <usertrap+0x78>
    80002da6:	2a852703          	lw	a4,680(a0)
    80002daa:	eb11                	bnez	a4,80002dbe <usertrap+0x78>
        p->ticks_passed++;
    80002dac:	17852703          	lw	a4,376(a0)
    80002db0:	2705                	addiw	a4,a4,1
    80002db2:	0007069b          	sext.w	a3,a4
    80002db6:	16e52c23          	sw	a4,376(a0)
        if (p->ticks_passed >= p->alarmticks) 
    80002dba:	06f6db63          	bge	a3,a5,80002e30 <usertrap+0xea>
  if (killed(p))
    80002dbe:	8526                	mv	a0,s1
    80002dc0:	00000097          	auipc	ra,0x0
    80002dc4:	8d4080e7          	jalr	-1836(ra) # 80002694 <killed>
    80002dc8:	c979                	beqz	a0,80002e9e <usertrap+0x158>
    80002dca:	a0e9                	j	80002e94 <usertrap+0x14e>
    panic("usertrap: not from user mode");
    80002dcc:	00005517          	auipc	a0,0x5
    80002dd0:	55450513          	addi	a0,a0,1364 # 80008320 <states.0+0x58>
    80002dd4:	ffffd097          	auipc	ra,0xffffd
    80002dd8:	76a080e7          	jalr	1898(ra) # 8000053e <panic>
    if (killed(p))
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	8b8080e7          	jalr	-1864(ra) # 80002694 <killed>
    80002de4:	e121                	bnez	a0,80002e24 <usertrap+0xde>
    p->trapframe->epc += 4;
    80002de6:	6cb8                	ld	a4,88(s1)
    80002de8:	6f1c                	ld	a5,24(a4)
    80002dea:	0791                	addi	a5,a5,4
    80002dec:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002df2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002df6:	10079073          	csrw	sstatus,a5
    syscall();
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	392080e7          	jalr	914(ra) # 8000318c <syscall>
  if (killed(p))
    80002e02:	8526                	mv	a0,s1
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	890080e7          	jalr	-1904(ra) # 80002694 <killed>
    80002e0c:	e159                	bnez	a0,80002e92 <usertrap+0x14c>
  usertrapret();
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	d9e080e7          	jalr	-610(ra) # 80002bac <usertrapret>
}
    80002e16:	70a2                	ld	ra,40(sp)
    80002e18:	7402                	ld	s0,32(sp)
    80002e1a:	64e2                	ld	s1,24(sp)
    80002e1c:	6942                	ld	s2,16(sp)
    80002e1e:	69a2                	ld	s3,8(sp)
    80002e20:	6145                	addi	sp,sp,48
    80002e22:	8082                	ret
      exit(-1);
    80002e24:	557d                	li	a0,-1
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	6ee080e7          	jalr	1774(ra) # 80002514 <exit>
    80002e2e:	bf65                	j	80002de6 <usertrap+0xa0>
            memmove(&p->alarm_tf_backup, p->trapframe, sizeof(struct trapframe));
    80002e30:	12000613          	li	a2,288
    80002e34:	6d2c                	ld	a1,88(a0)
    80002e36:	18850513          	addi	a0,a0,392
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	ef4080e7          	jalr	-268(ra) # 80000d2e <memmove>
            p->trapframe->epc = (uint64)p->handler;
    80002e42:	0589b783          	ld	a5,88(s3)
    80002e46:	1809b703          	ld	a4,384(s3)
    80002e4a:	ef98                	sd	a4,24(a5)
            p->alarm_active = 1;
    80002e4c:	4785                	li	a5,1
    80002e4e:	2af9a423          	sw	a5,680(s3)
            p->ticks_passed = 0;
    80002e52:	1609ac23          	sw	zero,376(s3)
    80002e56:	b7a5                	j	80002dbe <usertrap+0x78>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e58:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e5c:	5890                	lw	a2,48(s1)
    80002e5e:	00005517          	auipc	a0,0x5
    80002e62:	4e250513          	addi	a0,a0,1250 # 80008340 <states.0+0x78>
    80002e66:	ffffd097          	auipc	ra,0xffffd
    80002e6a:	722080e7          	jalr	1826(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e6e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e72:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e76:	00005517          	auipc	a0,0x5
    80002e7a:	4fa50513          	addi	a0,a0,1274 # 80008370 <states.0+0xa8>
    80002e7e:	ffffd097          	auipc	ra,0xffffd
    80002e82:	70a080e7          	jalr	1802(ra) # 80000588 <printf>
    setkilled(p);
    80002e86:	8526                	mv	a0,s1
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	7e0080e7          	jalr	2016(ra) # 80002668 <setkilled>
    80002e90:	bf8d                	j	80002e02 <usertrap+0xbc>
  if (killed(p))
    80002e92:	4901                	li	s2,0
    exit(-1);
    80002e94:	557d                	li	a0,-1
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	67e080e7          	jalr	1662(ra) # 80002514 <exit>
  if (which_dev == 2)
    80002e9e:	4789                	li	a5,2
    80002ea0:	f6f917e3          	bne	s2,a5,80002e0e <usertrap+0xc8>
    yield();
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	500080e7          	jalr	1280(ra) # 800023a4 <yield>
    80002eac:	b78d                	j	80002e0e <usertrap+0xc8>

0000000080002eae <kerneltrap>:
{
    80002eae:	7179                	addi	sp,sp,-48
    80002eb0:	f406                	sd	ra,40(sp)
    80002eb2:	f022                	sd	s0,32(sp)
    80002eb4:	ec26                	sd	s1,24(sp)
    80002eb6:	e84a                	sd	s2,16(sp)
    80002eb8:	e44e                	sd	s3,8(sp)
    80002eba:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ebc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ec4:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002ec8:	1004f793          	andi	a5,s1,256
    80002ecc:	cb85                	beqz	a5,80002efc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ece:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ed2:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002ed4:	ef85                	bnez	a5,80002f0c <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	dce080e7          	jalr	-562(ra) # 80002ca4 <devintr>
    80002ede:	cd1d                	beqz	a0,80002f1c <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ee0:	4789                	li	a5,2
    80002ee2:	06f50a63          	beq	a0,a5,80002f56 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ee6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eea:	10049073          	csrw	sstatus,s1
}
    80002eee:	70a2                	ld	ra,40(sp)
    80002ef0:	7402                	ld	s0,32(sp)
    80002ef2:	64e2                	ld	s1,24(sp)
    80002ef4:	6942                	ld	s2,16(sp)
    80002ef6:	69a2                	ld	s3,8(sp)
    80002ef8:	6145                	addi	sp,sp,48
    80002efa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002efc:	00005517          	auipc	a0,0x5
    80002f00:	49450513          	addi	a0,a0,1172 # 80008390 <states.0+0xc8>
    80002f04:	ffffd097          	auipc	ra,0xffffd
    80002f08:	63a080e7          	jalr	1594(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	4ac50513          	addi	a0,a0,1196 # 800083b8 <states.0+0xf0>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	62a080e7          	jalr	1578(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f1c:	85ce                	mv	a1,s3
    80002f1e:	00005517          	auipc	a0,0x5
    80002f22:	4ba50513          	addi	a0,a0,1210 # 800083d8 <states.0+0x110>
    80002f26:	ffffd097          	auipc	ra,0xffffd
    80002f2a:	662080e7          	jalr	1634(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f2e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f32:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f36:	00005517          	auipc	a0,0x5
    80002f3a:	4b250513          	addi	a0,a0,1202 # 800083e8 <states.0+0x120>
    80002f3e:	ffffd097          	auipc	ra,0xffffd
    80002f42:	64a080e7          	jalr	1610(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f46:	00005517          	auipc	a0,0x5
    80002f4a:	4ba50513          	addi	a0,a0,1210 # 80008400 <states.0+0x138>
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	5f0080e7          	jalr	1520(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	a56080e7          	jalr	-1450(ra) # 800019ac <myproc>
    80002f5e:	d541                	beqz	a0,80002ee6 <kerneltrap+0x38>
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	a4c080e7          	jalr	-1460(ra) # 800019ac <myproc>
    80002f68:	4d18                	lw	a4,24(a0)
    80002f6a:	4791                	li	a5,4
    80002f6c:	f6f71de3          	bne	a4,a5,80002ee6 <kerneltrap+0x38>
    yield();
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	434080e7          	jalr	1076(ra) # 800023a4 <yield>
    80002f78:	b7bd                	j	80002ee6 <kerneltrap+0x38>

0000000080002f7a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	e426                	sd	s1,8(sp)
    80002f82:	1000                	addi	s0,sp,32
    80002f84:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	a26080e7          	jalr	-1498(ra) # 800019ac <myproc>
  switch (n) {
    80002f8e:	4795                	li	a5,5
    80002f90:	0497e163          	bltu	a5,s1,80002fd2 <argraw+0x58>
    80002f94:	048a                	slli	s1,s1,0x2
    80002f96:	00005717          	auipc	a4,0x5
    80002f9a:	4da70713          	addi	a4,a4,1242 # 80008470 <states.0+0x1a8>
    80002f9e:	94ba                	add	s1,s1,a4
    80002fa0:	409c                	lw	a5,0(s1)
    80002fa2:	97ba                	add	a5,a5,a4
    80002fa4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fa6:	6d3c                	ld	a5,88(a0)
    80002fa8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	64a2                	ld	s1,8(sp)
    80002fb0:	6105                	addi	sp,sp,32
    80002fb2:	8082                	ret
    return p->trapframe->a1;
    80002fb4:	6d3c                	ld	a5,88(a0)
    80002fb6:	7fa8                	ld	a0,120(a5)
    80002fb8:	bfcd                	j	80002faa <argraw+0x30>
    return p->trapframe->a2;
    80002fba:	6d3c                	ld	a5,88(a0)
    80002fbc:	63c8                	ld	a0,128(a5)
    80002fbe:	b7f5                	j	80002faa <argraw+0x30>
    return p->trapframe->a3;
    80002fc0:	6d3c                	ld	a5,88(a0)
    80002fc2:	67c8                	ld	a0,136(a5)
    80002fc4:	b7dd                	j	80002faa <argraw+0x30>
    return p->trapframe->a4;
    80002fc6:	6d3c                	ld	a5,88(a0)
    80002fc8:	6bc8                	ld	a0,144(a5)
    80002fca:	b7c5                	j	80002faa <argraw+0x30>
    return p->trapframe->a5;
    80002fcc:	6d3c                	ld	a5,88(a0)
    80002fce:	6fc8                	ld	a0,152(a5)
    80002fd0:	bfe9                	j	80002faa <argraw+0x30>
  panic("argraw");
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	43e50513          	addi	a0,a0,1086 # 80008410 <states.0+0x148>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	564080e7          	jalr	1380(ra) # 8000053e <panic>

0000000080002fe2 <fetchaddr>:
{
    80002fe2:	1101                	addi	sp,sp,-32
    80002fe4:	ec06                	sd	ra,24(sp)
    80002fe6:	e822                	sd	s0,16(sp)
    80002fe8:	e426                	sd	s1,8(sp)
    80002fea:	e04a                	sd	s2,0(sp)
    80002fec:	1000                	addi	s0,sp,32
    80002fee:	84aa                	mv	s1,a0
    80002ff0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ff2:	fffff097          	auipc	ra,0xfffff
    80002ff6:	9ba080e7          	jalr	-1606(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ffa:	653c                	ld	a5,72(a0)
    80002ffc:	02f4f863          	bgeu	s1,a5,8000302c <fetchaddr+0x4a>
    80003000:	00848713          	addi	a4,s1,8
    80003004:	02e7e663          	bltu	a5,a4,80003030 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003008:	46a1                	li	a3,8
    8000300a:	8626                	mv	a2,s1
    8000300c:	85ca                	mv	a1,s2
    8000300e:	6928                	ld	a0,80(a0)
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	6e4080e7          	jalr	1764(ra) # 800016f4 <copyin>
    80003018:	00a03533          	snez	a0,a0
    8000301c:	40a00533          	neg	a0,a0
}
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	64a2                	ld	s1,8(sp)
    80003026:	6902                	ld	s2,0(sp)
    80003028:	6105                	addi	sp,sp,32
    8000302a:	8082                	ret
    return -1;
    8000302c:	557d                	li	a0,-1
    8000302e:	bfcd                	j	80003020 <fetchaddr+0x3e>
    80003030:	557d                	li	a0,-1
    80003032:	b7fd                	j	80003020 <fetchaddr+0x3e>

0000000080003034 <fetchstr>:
{
    80003034:	7179                	addi	sp,sp,-48
    80003036:	f406                	sd	ra,40(sp)
    80003038:	f022                	sd	s0,32(sp)
    8000303a:	ec26                	sd	s1,24(sp)
    8000303c:	e84a                	sd	s2,16(sp)
    8000303e:	e44e                	sd	s3,8(sp)
    80003040:	1800                	addi	s0,sp,48
    80003042:	892a                	mv	s2,a0
    80003044:	84ae                	mv	s1,a1
    80003046:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	964080e7          	jalr	-1692(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003050:	86ce                	mv	a3,s3
    80003052:	864a                	mv	a2,s2
    80003054:	85a6                	mv	a1,s1
    80003056:	6928                	ld	a0,80(a0)
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	72a080e7          	jalr	1834(ra) # 80001782 <copyinstr>
    80003060:	00054e63          	bltz	a0,8000307c <fetchstr+0x48>
  return strlen(buf);
    80003064:	8526                	mv	a0,s1
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	de8080e7          	jalr	-536(ra) # 80000e4e <strlen>
}
    8000306e:	70a2                	ld	ra,40(sp)
    80003070:	7402                	ld	s0,32(sp)
    80003072:	64e2                	ld	s1,24(sp)
    80003074:	6942                	ld	s2,16(sp)
    80003076:	69a2                	ld	s3,8(sp)
    80003078:	6145                	addi	sp,sp,48
    8000307a:	8082                	ret
    return -1;
    8000307c:	557d                	li	a0,-1
    8000307e:	bfc5                	j	8000306e <fetchstr+0x3a>

0000000080003080 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	e426                	sd	s1,8(sp)
    80003088:	1000                	addi	s0,sp,32
    8000308a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	eee080e7          	jalr	-274(ra) # 80002f7a <argraw>
    80003094:	c088                	sw	a0,0(s1)
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	64a2                	ld	s1,8(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret

00000000800030a0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	ece080e7          	jalr	-306(ra) # 80002f7a <argraw>
    800030b4:	e088                	sd	a0,0(s1)
}
    800030b6:	60e2                	ld	ra,24(sp)
    800030b8:	6442                	ld	s0,16(sp)
    800030ba:	64a2                	ld	s1,8(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret

00000000800030c0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030c0:	7179                	addi	sp,sp,-48
    800030c2:	f406                	sd	ra,40(sp)
    800030c4:	f022                	sd	s0,32(sp)
    800030c6:	ec26                	sd	s1,24(sp)
    800030c8:	e84a                	sd	s2,16(sp)
    800030ca:	1800                	addi	s0,sp,48
    800030cc:	84ae                	mv	s1,a1
    800030ce:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800030d0:	fd840593          	addi	a1,s0,-40
    800030d4:	00000097          	auipc	ra,0x0
    800030d8:	fcc080e7          	jalr	-52(ra) # 800030a0 <argaddr>
  return fetchstr(addr, buf, max);
    800030dc:	864a                	mv	a2,s2
    800030de:	85a6                	mv	a1,s1
    800030e0:	fd843503          	ld	a0,-40(s0)
    800030e4:	00000097          	auipc	ra,0x0
    800030e8:	f50080e7          	jalr	-176(ra) # 80003034 <fetchstr>
}
    800030ec:	70a2                	ld	ra,40(sp)
    800030ee:	7402                	ld	s0,32(sp)
    800030f0:	64e2                	ld	s1,24(sp)
    800030f2:	6942                	ld	s2,16(sp)
    800030f4:	6145                	addi	sp,sp,48
    800030f6:	8082                	ret

00000000800030f8 <log_syscall>:
[SYS_sigalarm]  sys_sigalarm,
[SYS_sigreturn] sys_sigreturn,
[SYS_settickets] sys_settickets,
};

void log_syscall(int pid, int ppid, int syscall_num) {
    800030f8:	7179                	addi	sp,sp,-48
    800030fa:	f406                	sd	ra,40(sp)
    800030fc:	f022                	sd	s0,32(sp)
    800030fe:	ec26                	sd	s1,24(sp)
    80003100:	e84a                	sd	s2,16(sp)
    80003102:	e44e                	sd	s3,8(sp)
    80003104:	e052                	sd	s4,0(sp)
    80003106:	1800                	addi	s0,sp,48
    80003108:	84aa                	mv	s1,a0
    8000310a:	8a2e                	mv	s4,a1
    8000310c:	8932                	mv	s2,a2
  struct syscall_log *log = syscall_log;
    8000310e:	00006797          	auipc	a5,0x6
    80003112:	81a7b783          	ld	a5,-2022(a5) # 80008928 <syscall_log>
  while (log) {
    80003116:	c791                	beqz	a5,80003122 <log_syscall+0x2a>
    if (log->pid == pid) {
    80003118:	4398                	lw	a4,0(a5)
    8000311a:	04970b63          	beq	a4,s1,80003170 <log_syscall+0x78>
      log->syscall_counts[syscall_num]++;
      return;
    }
    log = log->next;
    8000311e:	67dc                	ld	a5,136(a5)
  while (log) {
    80003120:	ffe5                	bnez	a5,80003118 <log_syscall+0x20>
  }
  struct syscall_log *new_log = (struct syscall_log *)kalloc();
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	9c4080e7          	jalr	-1596(ra) # 80000ae6 <kalloc>
    8000312a:	89aa                	mv	s3,a0
  if (new_log == NULL) {
    8000312c:	c921                	beqz	a0,8000317c <log_syscall+0x84>
    panic("log_syscall: failed to allocate memory for new_log");
  }

  new_log->pid = pid;
    8000312e:	c104                	sw	s1,0(a0)
  new_log->ppid = ppid;
    80003130:	01452223          	sw	s4,4(a0)
  memset(new_log->syscall_counts, 0, sizeof(new_log->syscall_counts));
    80003134:	07c00613          	li	a2,124
    80003138:	4581                	li	a1,0
    8000313a:	0521                	addi	a0,a0,8
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b96080e7          	jalr	-1130(ra) # 80000cd2 <memset>
  new_log->syscall_counts[syscall_num] = 1; 
    80003144:	090a                	slli	s2,s2,0x2
    80003146:	994e                	add	s2,s2,s3
    80003148:	4785                	li	a5,1
    8000314a:	00f92423          	sw	a5,8(s2)
  new_log->next = syscall_log;
    8000314e:	00005797          	auipc	a5,0x5
    80003152:	7da78793          	addi	a5,a5,2010 # 80008928 <syscall_log>
    80003156:	6398                	ld	a4,0(a5)
    80003158:	08e9b423          	sd	a4,136(s3)
  syscall_log = new_log; 
    8000315c:	0137b023          	sd	s3,0(a5)
}
    80003160:	70a2                	ld	ra,40(sp)
    80003162:	7402                	ld	s0,32(sp)
    80003164:	64e2                	ld	s1,24(sp)
    80003166:	6942                	ld	s2,16(sp)
    80003168:	69a2                	ld	s3,8(sp)
    8000316a:	6a02                	ld	s4,0(sp)
    8000316c:	6145                	addi	sp,sp,48
    8000316e:	8082                	ret
      log->syscall_counts[syscall_num]++;
    80003170:	090a                	slli	s2,s2,0x2
    80003172:	97ca                	add	a5,a5,s2
    80003174:	4798                	lw	a4,8(a5)
    80003176:	2705                	addiw	a4,a4,1
    80003178:	c798                	sw	a4,8(a5)
      return;
    8000317a:	b7dd                	j	80003160 <log_syscall+0x68>
    panic("log_syscall: failed to allocate memory for new_log");
    8000317c:	00005517          	auipc	a0,0x5
    80003180:	29c50513          	addi	a0,a0,668 # 80008418 <states.0+0x150>
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	3ba080e7          	jalr	954(ra) # 8000053e <panic>

000000008000318c <syscall>:

void
syscall(void)
{
    8000318c:	1101                	addi	sp,sp,-32
    8000318e:	ec06                	sd	ra,24(sp)
    80003190:	e822                	sd	s0,16(sp)
    80003192:	e426                	sd	s1,8(sp)
    80003194:	e04a                	sd	s2,0(sp)
    80003196:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003198:	fffff097          	auipc	ra,0xfffff
    8000319c:	814080e7          	jalr	-2028(ra) # 800019ac <myproc>
    800031a0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031a2:	6d3c                	ld	a5,88(a0)
    800031a4:	77dc                	ld	a5,168(a5)
    800031a6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031aa:	37fd                	addiw	a5,a5,-1
    800031ac:	4765                	li	a4,25
    800031ae:	02f76b63          	bltu	a4,a5,800031e4 <syscall+0x58>
    800031b2:	00369713          	slli	a4,a3,0x3
    800031b6:	00005797          	auipc	a5,0x5
    800031ba:	2d278793          	addi	a5,a5,722 # 80008488 <syscalls>
    800031be:	97ba                	add	a5,a5,a4
    800031c0:	0007b903          	ld	s2,0(a5)
    800031c4:	02090063          	beqz	s2,800031e4 <syscall+0x58>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    int ppid = (p->parent != NULL) ? p->parent->pid : -1;
    800031c8:	7d1c                	ld	a5,56(a0)
    800031ca:	55fd                	li	a1,-1
    800031cc:	c391                	beqz	a5,800031d0 <syscall+0x44>
    800031ce:	5b8c                	lw	a1,48(a5)
    log_syscall(p->pid, ppid, num);
    800031d0:	8636                	mv	a2,a3
    800031d2:	5888                	lw	a0,48(s1)
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	f24080e7          	jalr	-220(ra) # 800030f8 <log_syscall>
    p->trapframe->a0 = syscalls[num]();
    800031dc:	6ca4                	ld	s1,88(s1)
    800031de:	9902                	jalr	s2
    800031e0:	f8a8                	sd	a0,112(s1)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031e2:	a839                	j	80003200 <syscall+0x74>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031e4:	15848613          	addi	a2,s1,344
    800031e8:	588c                	lw	a1,48(s1)
    800031ea:	00005517          	auipc	a0,0x5
    800031ee:	26650513          	addi	a0,a0,614 # 80008450 <states.0+0x188>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	396080e7          	jalr	918(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031fa:	6cbc                	ld	a5,88(s1)
    800031fc:	577d                	li	a4,-1
    800031fe:	fbb8                	sd	a4,112(a5)
  }
}
    80003200:	60e2                	ld	ra,24(sp)
    80003202:	6442                	ld	s0,16(sp)
    80003204:	64a2                	ld	s1,8(sp)
    80003206:	6902                	ld	s2,0(sp)
    80003208:	6105                	addi	sp,sp,32
    8000320a:	8082                	ret

000000008000320c <sys_exit>:
#include "proc.h"
#include<stddef.h>

uint64
sys_exit(void)
{
    8000320c:	1101                	addi	sp,sp,-32
    8000320e:	ec06                	sd	ra,24(sp)
    80003210:	e822                	sd	s0,16(sp)
    80003212:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003214:	fec40593          	addi	a1,s0,-20
    80003218:	4501                	li	a0,0
    8000321a:	00000097          	auipc	ra,0x0
    8000321e:	e66080e7          	jalr	-410(ra) # 80003080 <argint>
  exit(n);
    80003222:	fec42503          	lw	a0,-20(s0)
    80003226:	fffff097          	auipc	ra,0xfffff
    8000322a:	2ee080e7          	jalr	750(ra) # 80002514 <exit>
  return 0; 
}
    8000322e:	4501                	li	a0,0
    80003230:	60e2                	ld	ra,24(sp)
    80003232:	6442                	ld	s0,16(sp)
    80003234:	6105                	addi	sp,sp,32
    80003236:	8082                	ret

0000000080003238 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003238:	1141                	addi	sp,sp,-16
    8000323a:	e406                	sd	ra,8(sp)
    8000323c:	e022                	sd	s0,0(sp)
    8000323e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	76c080e7          	jalr	1900(ra) # 800019ac <myproc>
}
    80003248:	5908                	lw	a0,48(a0)
    8000324a:	60a2                	ld	ra,8(sp)
    8000324c:	6402                	ld	s0,0(sp)
    8000324e:	0141                	addi	sp,sp,16
    80003250:	8082                	ret

0000000080003252 <sys_fork>:

uint64
sys_fork(void)
{
    80003252:	1141                	addi	sp,sp,-16
    80003254:	e406                	sd	ra,8(sp)
    80003256:	e022                	sd	s0,0(sp)
    80003258:	0800                	addi	s0,sp,16
  return fork();
    8000325a:	fffff097          	auipc	ra,0xfffff
    8000325e:	b34080e7          	jalr	-1228(ra) # 80001d8e <fork>
}
    80003262:	60a2                	ld	ra,8(sp)
    80003264:	6402                	ld	s0,0(sp)
    80003266:	0141                	addi	sp,sp,16
    80003268:	8082                	ret

000000008000326a <sys_wait>:

uint64
sys_wait(void)
{
    8000326a:	1101                	addi	sp,sp,-32
    8000326c:	ec06                	sd	ra,24(sp)
    8000326e:	e822                	sd	s0,16(sp)
    80003270:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003272:	fe840593          	addi	a1,s0,-24
    80003276:	4501                	li	a0,0
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	e28080e7          	jalr	-472(ra) # 800030a0 <argaddr>
  return wait(p);
    80003280:	fe843503          	ld	a0,-24(s0)
    80003284:	fffff097          	auipc	ra,0xfffff
    80003288:	442080e7          	jalr	1090(ra) # 800026c6 <wait>
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	6105                	addi	sp,sp,32
    80003292:	8082                	ret

0000000080003294 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003294:	7179                	addi	sp,sp,-48
    80003296:	f406                	sd	ra,40(sp)
    80003298:	f022                	sd	s0,32(sp)
    8000329a:	ec26                	sd	s1,24(sp)
    8000329c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000329e:	fdc40593          	addi	a1,s0,-36
    800032a2:	4501                	li	a0,0
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	ddc080e7          	jalr	-548(ra) # 80003080 <argint>
  addr = myproc()->sz;
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	700080e7          	jalr	1792(ra) # 800019ac <myproc>
    800032b4:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800032b6:	fdc42503          	lw	a0,-36(s0)
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	a78080e7          	jalr	-1416(ra) # 80001d32 <growproc>
    800032c2:	00054863          	bltz	a0,800032d2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800032c6:	8526                	mv	a0,s1
    800032c8:	70a2                	ld	ra,40(sp)
    800032ca:	7402                	ld	s0,32(sp)
    800032cc:	64e2                	ld	s1,24(sp)
    800032ce:	6145                	addi	sp,sp,48
    800032d0:	8082                	ret
    return -1;
    800032d2:	54fd                	li	s1,-1
    800032d4:	bfcd                	j	800032c6 <sys_sbrk+0x32>

00000000800032d6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032d6:	7139                	addi	sp,sp,-64
    800032d8:	fc06                	sd	ra,56(sp)
    800032da:	f822                	sd	s0,48(sp)
    800032dc:	f426                	sd	s1,40(sp)
    800032de:	f04a                	sd	s2,32(sp)
    800032e0:	ec4e                	sd	s3,24(sp)
    800032e2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032e4:	fcc40593          	addi	a1,s0,-52
    800032e8:	4501                	li	a0,0
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	d96080e7          	jalr	-618(ra) # 80003080 <argint>
  acquire(&tickslock);
    800032f2:	00019517          	auipc	a0,0x19
    800032f6:	cde50513          	addi	a0,a0,-802 # 8001bfd0 <tickslock>
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	8dc080e7          	jalr	-1828(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003302:	00005917          	auipc	s2,0x5
    80003306:	63a92903          	lw	s2,1594(s2) # 8000893c <ticks>
  while (ticks - ticks0 < n)
    8000330a:	fcc42783          	lw	a5,-52(s0)
    8000330e:	cf9d                	beqz	a5,8000334c <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003310:	00019997          	auipc	s3,0x19
    80003314:	cc098993          	addi	s3,s3,-832 # 8001bfd0 <tickslock>
    80003318:	00005497          	auipc	s1,0x5
    8000331c:	62448493          	addi	s1,s1,1572 # 8000893c <ticks>
    if (killed(myproc()))
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	68c080e7          	jalr	1676(ra) # 800019ac <myproc>
    80003328:	fffff097          	auipc	ra,0xfffff
    8000332c:	36c080e7          	jalr	876(ra) # 80002694 <killed>
    80003330:	ed15                	bnez	a0,8000336c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003332:	85ce                	mv	a1,s3
    80003334:	8526                	mv	a0,s1
    80003336:	fffff097          	auipc	ra,0xfffff
    8000333a:	0aa080e7          	jalr	170(ra) # 800023e0 <sleep>
  while (ticks - ticks0 < n)
    8000333e:	409c                	lw	a5,0(s1)
    80003340:	412787bb          	subw	a5,a5,s2
    80003344:	fcc42703          	lw	a4,-52(s0)
    80003348:	fce7ece3          	bltu	a5,a4,80003320 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000334c:	00019517          	auipc	a0,0x19
    80003350:	c8450513          	addi	a0,a0,-892 # 8001bfd0 <tickslock>
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	936080e7          	jalr	-1738(ra) # 80000c8a <release>
  return 0;
    8000335c:	4501                	li	a0,0
}
    8000335e:	70e2                	ld	ra,56(sp)
    80003360:	7442                	ld	s0,48(sp)
    80003362:	74a2                	ld	s1,40(sp)
    80003364:	7902                	ld	s2,32(sp)
    80003366:	69e2                	ld	s3,24(sp)
    80003368:	6121                	addi	sp,sp,64
    8000336a:	8082                	ret
      release(&tickslock);
    8000336c:	00019517          	auipc	a0,0x19
    80003370:	c6450513          	addi	a0,a0,-924 # 8001bfd0 <tickslock>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	916080e7          	jalr	-1770(ra) # 80000c8a <release>
      return -1;
    8000337c:	557d                	li	a0,-1
    8000337e:	b7c5                	j	8000335e <sys_sleep+0x88>

0000000080003380 <sys_kill>:

uint64
sys_kill(void)
{
    80003380:	1101                	addi	sp,sp,-32
    80003382:	ec06                	sd	ra,24(sp)
    80003384:	e822                	sd	s0,16(sp)
    80003386:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003388:	fec40593          	addi	a1,s0,-20
    8000338c:	4501                	li	a0,0
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	cf2080e7          	jalr	-782(ra) # 80003080 <argint>
  return kill(pid);
    80003396:	fec42503          	lw	a0,-20(s0)
    8000339a:	fffff097          	auipc	ra,0xfffff
    8000339e:	25c080e7          	jalr	604(ra) # 800025f6 <kill>
}
    800033a2:	60e2                	ld	ra,24(sp)
    800033a4:	6442                	ld	s0,16(sp)
    800033a6:	6105                	addi	sp,sp,32
    800033a8:	8082                	ret

00000000800033aa <sys_uptime>:
uint64
sys_uptime(void)
{
    800033aa:	1101                	addi	sp,sp,-32
    800033ac:	ec06                	sd	ra,24(sp)
    800033ae:	e822                	sd	s0,16(sp)
    800033b0:	e426                	sd	s1,8(sp)
    800033b2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033b4:	00019517          	auipc	a0,0x19
    800033b8:	c1c50513          	addi	a0,a0,-996 # 8001bfd0 <tickslock>
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	81a080e7          	jalr	-2022(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800033c4:	00005497          	auipc	s1,0x5
    800033c8:	5784a483          	lw	s1,1400(s1) # 8000893c <ticks>
  release(&tickslock);
    800033cc:	00019517          	auipc	a0,0x19
    800033d0:	c0450513          	addi	a0,a0,-1020 # 8001bfd0 <tickslock>
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	8b6080e7          	jalr	-1866(ra) # 80000c8a <release>
  return xticks;
}
    800033dc:	02049513          	slli	a0,s1,0x20
    800033e0:	9101                	srli	a0,a0,0x20
    800033e2:	60e2                	ld	ra,24(sp)
    800033e4:	6442                	ld	s0,16(sp)
    800033e6:	64a2                	ld	s1,8(sp)
    800033e8:	6105                	addi	sp,sp,32
    800033ea:	8082                	ret

00000000800033ec <sys_waitx>:

uint64
sys_waitx(void)
{
    800033ec:	7139                	addi	sp,sp,-64
    800033ee:	fc06                	sd	ra,56(sp)
    800033f0:	f822                	sd	s0,48(sp)
    800033f2:	f426                	sd	s1,40(sp)
    800033f4:	f04a                	sd	s2,32(sp)
    800033f6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800033f8:	fd840593          	addi	a1,s0,-40
    800033fc:	4501                	li	a0,0
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	ca2080e7          	jalr	-862(ra) # 800030a0 <argaddr>
  argaddr(1, &addr1); 
    80003406:	fd040593          	addi	a1,s0,-48
    8000340a:	4505                	li	a0,1
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	c94080e7          	jalr	-876(ra) # 800030a0 <argaddr>
  argaddr(2, &addr2);
    80003414:	fc840593          	addi	a1,s0,-56
    80003418:	4509                	li	a0,2
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	c86080e7          	jalr	-890(ra) # 800030a0 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003422:	fc040613          	addi	a2,s0,-64
    80003426:	fc440593          	addi	a1,s0,-60
    8000342a:	fd843503          	ld	a0,-40(s0)
    8000342e:	fffff097          	auipc	ra,0xfffff
    80003432:	520080e7          	jalr	1312(ra) # 8000294e <waitx>
    80003436:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	574080e7          	jalr	1396(ra) # 800019ac <myproc>
    80003440:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003442:	4691                	li	a3,4
    80003444:	fc440613          	addi	a2,s0,-60
    80003448:	fd043583          	ld	a1,-48(s0)
    8000344c:	6928                	ld	a0,80(a0)
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	21a080e7          	jalr	538(ra) # 80001668 <copyout>
    return -1;
    80003456:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003458:	00054f63          	bltz	a0,80003476 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000345c:	4691                	li	a3,4
    8000345e:	fc040613          	addi	a2,s0,-64
    80003462:	fc843583          	ld	a1,-56(s0)
    80003466:	68a8                	ld	a0,80(s1)
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	200080e7          	jalr	512(ra) # 80001668 <copyout>
    80003470:	00054a63          	bltz	a0,80003484 <sys_waitx+0x98>
    return -1;
  return ret;
    80003474:	87ca                	mv	a5,s2
}
    80003476:	853e                	mv	a0,a5
    80003478:	70e2                	ld	ra,56(sp)
    8000347a:	7442                	ld	s0,48(sp)
    8000347c:	74a2                	ld	s1,40(sp)
    8000347e:	7902                	ld	s2,32(sp)
    80003480:	6121                	addi	sp,sp,64
    80003482:	8082                	ret
    return -1;
    80003484:	57fd                	li	a5,-1
    80003486:	bfc5                	j	80003476 <sys_waitx+0x8a>

0000000080003488 <clear_syscall_log>:

void clear_syscall_log(void)
{
    80003488:	1101                	addi	sp,sp,-32
    8000348a:	ec06                	sd	ra,24(sp)
    8000348c:	e822                	sd	s0,16(sp)
    8000348e:	e426                	sd	s1,8(sp)
    80003490:	1000                	addi	s0,sp,32
    struct syscall_log *log = syscall_log;
    80003492:	00005497          	auipc	s1,0x5
    80003496:	4964b483          	ld	s1,1174(s1) # 80008928 <syscall_log>
    while (log) {
    8000349a:	c881                	beqz	s1,800034aa <clear_syscall_log+0x22>
        struct syscall_log *next_log = log->next; 
    8000349c:	8526                	mv	a0,s1
    8000349e:	64c4                	ld	s1,136(s1)
        kfree(log);  
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
    while (log) {
    800034a8:	f8f5                	bnez	s1,8000349c <clear_syscall_log+0x14>
        log = next_log;  
    }
    syscall_log = 0;  
    800034aa:	00005797          	auipc	a5,0x5
    800034ae:	4607bf23          	sd	zero,1150(a5) # 80008928 <syscall_log>
}
    800034b2:	60e2                	ld	ra,24(sp)
    800034b4:	6442                	ld	s0,16(sp)
    800034b6:	64a2                	ld	s1,8(sp)
    800034b8:	6105                	addi	sp,sp,32
    800034ba:	8082                	ret

00000000800034bc <sys_getSysCount>:
int sys_getSysCount(void)
{
    800034bc:	7179                	addi	sp,sp,-48
    800034be:	f406                	sd	ra,40(sp)
    800034c0:	f022                	sd	s0,32(sp)
    800034c2:	ec26                	sd	s1,24(sp)
    800034c4:	1800                	addi	s0,sp,48
    int mask;
    int pid;
    argint(0, &mask);
    800034c6:	fdc40593          	addi	a1,s0,-36
    800034ca:	4501                	li	a0,0
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	bb4080e7          	jalr	-1100(ra) # 80003080 <argint>
    argint(1, &pid);
    800034d4:	fd840593          	addi	a1,s0,-40
    800034d8:	4505                	li	a0,1
    800034da:	00000097          	auipc	ra,0x0
    800034de:	ba6080e7          	jalr	-1114(ra) # 80003080 <argint>

    if (mask < 0) 
    800034e2:	fdc42703          	lw	a4,-36(s0)
    800034e6:	06074e63          	bltz	a4,80003562 <sys_getSysCount+0xa6>
    {
        return -1;
    }

    int syscall_num = 0;
    while ((mask >>= 1) != 0) 
    800034ea:	4017571b          	sraiw	a4,a4,0x1
    800034ee:	0007079b          	sext.w	a5,a4
    800034f2:	fce42e23          	sw	a4,-36(s0)
    800034f6:	c79d                	beqz	a5,80003524 <sys_getSysCount+0x68>
    int syscall_num = 0;
    800034f8:	4701                	li	a4,0
    {
        syscall_num++;
    800034fa:	2705                	addiw	a4,a4,1
    while ((mask >>= 1) != 0) 
    800034fc:	4017d79b          	sraiw	a5,a5,0x1
    80003500:	ffed                	bnez	a5,800034fa <sys_getSysCount+0x3e>
    80003502:	fc042e23          	sw	zero,-36(s0)
    }
    if (syscall_num < 0 || syscall_num >= 31) {
    80003506:	0007079b          	sext.w	a5,a4
    8000350a:	46f9                	li	a3,30
    8000350c:	04f6ed63          	bltu	a3,a5,80003566 <sys_getSysCount+0xaa>
        return -1;
    }

    
    int count = 0;
    struct syscall_log *log = syscall_log;
    80003510:	00005797          	auipc	a5,0x5
    80003514:	4187b783          	ld	a5,1048(a5) # 80008928 <syscall_log>
    
    while (log) {
    80003518:	cb95                	beqz	a5,8000354c <sys_getSysCount+0x90>
        if (log->pid == pid) 
    8000351a:	fd842683          	lw	a3,-40(s0)
    int count = 0;
    8000351e:	4481                	li	s1,0
        {
            count += log->syscall_counts[syscall_num];
    80003520:	070a                	slli	a4,a4,0x2
    80003522:	a801                	j	80003532 <sys_getSysCount+0x76>
    int syscall_num = 0;
    80003524:	873e                	mv	a4,a5
    80003526:	b7ed                	j	80003510 <sys_getSysCount+0x54>
        }

        if (log->ppid == pid) 
    80003528:	43d0                	lw	a2,4(a5)
    8000352a:	00d60c63          	beq	a2,a3,80003542 <sys_getSysCount+0x86>
        {
            count += log->syscall_counts[syscall_num];
        }

        log = log->next;
    8000352e:	67dc                	ld	a5,136(a5)
    while (log) {
    80003530:	cf99                	beqz	a5,8000354e <sys_getSysCount+0x92>
        if (log->pid == pid) 
    80003532:	4390                	lw	a2,0(a5)
    80003534:	fed61ae3          	bne	a2,a3,80003528 <sys_getSysCount+0x6c>
            count += log->syscall_counts[syscall_num];
    80003538:	00e78633          	add	a2,a5,a4
    8000353c:	4610                	lw	a2,8(a2)
    8000353e:	9cb1                	addw	s1,s1,a2
    80003540:	b7e5                	j	80003528 <sys_getSysCount+0x6c>
            count += log->syscall_counts[syscall_num];
    80003542:	00e78633          	add	a2,a5,a4
    80003546:	4610                	lw	a2,8(a2)
    80003548:	9cb1                	addw	s1,s1,a2
    8000354a:	b7d5                	j	8000352e <sys_getSysCount+0x72>
    int count = 0;
    8000354c:	4481                	li	s1,0
    }
    clear_syscall_log();
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	f3a080e7          	jalr	-198(ra) # 80003488 <clear_syscall_log>
    return count;
}
    80003556:	8526                	mv	a0,s1
    80003558:	70a2                	ld	ra,40(sp)
    8000355a:	7402                	ld	s0,32(sp)
    8000355c:	64e2                	ld	s1,24(sp)
    8000355e:	6145                	addi	sp,sp,48
    80003560:	8082                	ret
        return -1;
    80003562:	54fd                	li	s1,-1
    80003564:	bfcd                	j	80003556 <sys_getSysCount+0x9a>
        return -1;
    80003566:	54fd                	li	s1,-1
    80003568:	b7fd                	j	80003556 <sys_getSysCount+0x9a>

000000008000356a <sys_sigalarm>:
int
sys_sigalarm(void)
{
    8000356a:	1101                	addi	sp,sp,-32
    8000356c:	ec06                	sd	ra,24(sp)
    8000356e:	e822                	sd	s0,16(sp)
    80003570:	1000                	addi	s0,sp,32
    int ticks;
    //void (*handler)();
    
    // Extract arguments from user space
    argint(0, &ticks);
    80003572:	fec40593          	addi	a1,s0,-20
    80003576:	4501                	li	a0,0
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	b08080e7          	jalr	-1272(ra) # 80003080 <argint>
    if (ticks < 0)
    80003580:	fec42783          	lw	a5,-20(s0)
    80003584:	0207c763          	bltz	a5,800035b2 <sys_sigalarm+0x48>
        return -1;

    struct proc *p = myproc();
    80003588:	ffffe097          	auipc	ra,0xffffe
    8000358c:	424080e7          	jalr	1060(ra) # 800019ac <myproc>
    
    // Set the alarmticks and handler for the process
    p->alarmticks = ticks;
    80003590:	fec42783          	lw	a5,-20(s0)
    80003594:	16f52a23          	sw	a5,372(a0)
    p->handler = p->trapframe->a1;
    80003598:	6d3c                	ld	a5,88(a0)
    8000359a:	7fbc                	ld	a5,120(a5)
    8000359c:	18f53023          	sd	a5,384(a0)
    p->ticks_passed = 0;
    800035a0:	16052c23          	sw	zero,376(a0)
    p->alarm_active=0;
    800035a4:	2a052423          	sw	zero,680(a0)
    
    return 0;
    800035a8:	4501                	li	a0,0
}
    800035aa:	60e2                	ld	ra,24(sp)
    800035ac:	6442                	ld	s0,16(sp)
    800035ae:	6105                	addi	sp,sp,32
    800035b0:	8082                	ret
        return -1;
    800035b2:	557d                	li	a0,-1
    800035b4:	bfdd                	j	800035aa <sys_sigalarm+0x40>

00000000800035b6 <sys_sigreturn>:
int
sys_sigreturn(void)
{
    800035b6:	1101                	addi	sp,sp,-32
    800035b8:	ec06                	sd	ra,24(sp)
    800035ba:	e822                	sd	s0,16(sp)
    800035bc:	e426                	sd	s1,8(sp)
    800035be:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800035c0:	ffffe097          	auipc	ra,0xffffe
    800035c4:	3ec080e7          	jalr	1004(ra) # 800019ac <myproc>
    800035c8:	84aa                	mv	s1,a0
    p->alarm_active = 0;
    800035ca:	2a052423          	sw	zero,680(a0)
    p->ticks_passed=0;
    800035ce:	16052c23          	sw	zero,376(a0)
    memmove(p->trapframe, &p->alarm_tf_backup, sizeof(struct trapframe));
    800035d2:	12000613          	li	a2,288
    800035d6:	18850593          	addi	a1,a0,392
    800035da:	6d28                	ld	a0,88(a0)
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	752080e7          	jalr	1874(ra) # 80000d2e <memmove>
    return p->trapframe->a0;
    800035e4:	6cbc                	ld	a5,88(s1)
}
    800035e6:	5ba8                	lw	a0,112(a5)
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	64a2                	ld	s1,8(sp)
    800035ee:	6105                	addi	sp,sp,32
    800035f0:	8082                	ret

00000000800035f2 <sys_settickets>:
int
sys_settickets(void) {
    800035f2:	1101                	addi	sp,sp,-32
    800035f4:	ec06                	sd	ra,24(sp)
    800035f6:	e822                	sd	s0,16(sp)
    800035f8:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800035fa:	fec40593          	addi	a1,s0,-20
    800035fe:	4501                	li	a0,0
    80003600:	00000097          	auipc	ra,0x0
    80003604:	a80080e7          	jalr	-1408(ra) # 80003080 <argint>
  if(n < 1)
    80003608:	fec42783          	lw	a5,-20(s0)
    8000360c:	00f05f63          	blez	a5,8000362a <sys_settickets+0x38>
    return -1;
  struct proc *p = myproc();
    80003610:	ffffe097          	auipc	ra,0xffffe
    80003614:	39c080e7          	jalr	924(ra) # 800019ac <myproc>
    80003618:	87aa                	mv	a5,a0
  p->tickets = n;
    8000361a:	fec42503          	lw	a0,-20(s0)
    8000361e:	2aa7a623          	sw	a0,684(a5)
  return n;
}
    80003622:	60e2                	ld	ra,24(sp)
    80003624:	6442                	ld	s0,16(sp)
    80003626:	6105                	addi	sp,sp,32
    80003628:	8082                	ret
    return -1;
    8000362a:	557d                	li	a0,-1
    8000362c:	bfdd                	j	80003622 <sys_settickets+0x30>

000000008000362e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000362e:	7179                	addi	sp,sp,-48
    80003630:	f406                	sd	ra,40(sp)
    80003632:	f022                	sd	s0,32(sp)
    80003634:	ec26                	sd	s1,24(sp)
    80003636:	e84a                	sd	s2,16(sp)
    80003638:	e44e                	sd	s3,8(sp)
    8000363a:	e052                	sd	s4,0(sp)
    8000363c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000363e:	00005597          	auipc	a1,0x5
    80003642:	f2258593          	addi	a1,a1,-222 # 80008560 <syscalls+0xd8>
    80003646:	00019517          	auipc	a0,0x19
    8000364a:	9a250513          	addi	a0,a0,-1630 # 8001bfe8 <bcache>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	4f8080e7          	jalr	1272(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003656:	00021797          	auipc	a5,0x21
    8000365a:	99278793          	addi	a5,a5,-1646 # 80023fe8 <bcache+0x8000>
    8000365e:	00021717          	auipc	a4,0x21
    80003662:	bf270713          	addi	a4,a4,-1038 # 80024250 <bcache+0x8268>
    80003666:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000366a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000366e:	00019497          	auipc	s1,0x19
    80003672:	99248493          	addi	s1,s1,-1646 # 8001c000 <bcache+0x18>
    b->next = bcache.head.next;
    80003676:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003678:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000367a:	00005a17          	auipc	s4,0x5
    8000367e:	eeea0a13          	addi	s4,s4,-274 # 80008568 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003682:	2b893783          	ld	a5,696(s2)
    80003686:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003688:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000368c:	85d2                	mv	a1,s4
    8000368e:	01048513          	addi	a0,s1,16
    80003692:	00001097          	auipc	ra,0x1
    80003696:	4c4080e7          	jalr	1220(ra) # 80004b56 <initsleeplock>
    bcache.head.next->prev = b;
    8000369a:	2b893783          	ld	a5,696(s2)
    8000369e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036a0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036a4:	45848493          	addi	s1,s1,1112
    800036a8:	fd349de3          	bne	s1,s3,80003682 <binit+0x54>
  }
}
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6a02                	ld	s4,0(sp)
    800036b8:	6145                	addi	sp,sp,48
    800036ba:	8082                	ret

00000000800036bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036bc:	7179                	addi	sp,sp,-48
    800036be:	f406                	sd	ra,40(sp)
    800036c0:	f022                	sd	s0,32(sp)
    800036c2:	ec26                	sd	s1,24(sp)
    800036c4:	e84a                	sd	s2,16(sp)
    800036c6:	e44e                	sd	s3,8(sp)
    800036c8:	1800                	addi	s0,sp,48
    800036ca:	892a                	mv	s2,a0
    800036cc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036ce:	00019517          	auipc	a0,0x19
    800036d2:	91a50513          	addi	a0,a0,-1766 # 8001bfe8 <bcache>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	500080e7          	jalr	1280(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036de:	00021497          	auipc	s1,0x21
    800036e2:	bc24b483          	ld	s1,-1086(s1) # 800242a0 <bcache+0x82b8>
    800036e6:	00021797          	auipc	a5,0x21
    800036ea:	b6a78793          	addi	a5,a5,-1174 # 80024250 <bcache+0x8268>
    800036ee:	02f48f63          	beq	s1,a5,8000372c <bread+0x70>
    800036f2:	873e                	mv	a4,a5
    800036f4:	a021                	j	800036fc <bread+0x40>
    800036f6:	68a4                	ld	s1,80(s1)
    800036f8:	02e48a63          	beq	s1,a4,8000372c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036fc:	449c                	lw	a5,8(s1)
    800036fe:	ff279ce3          	bne	a5,s2,800036f6 <bread+0x3a>
    80003702:	44dc                	lw	a5,12(s1)
    80003704:	ff3799e3          	bne	a5,s3,800036f6 <bread+0x3a>
      b->refcnt++;
    80003708:	40bc                	lw	a5,64(s1)
    8000370a:	2785                	addiw	a5,a5,1
    8000370c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000370e:	00019517          	auipc	a0,0x19
    80003712:	8da50513          	addi	a0,a0,-1830 # 8001bfe8 <bcache>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	574080e7          	jalr	1396(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000371e:	01048513          	addi	a0,s1,16
    80003722:	00001097          	auipc	ra,0x1
    80003726:	46e080e7          	jalr	1134(ra) # 80004b90 <acquiresleep>
      return b;
    8000372a:	a8b9                	j	80003788 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000372c:	00021497          	auipc	s1,0x21
    80003730:	b6c4b483          	ld	s1,-1172(s1) # 80024298 <bcache+0x82b0>
    80003734:	00021797          	auipc	a5,0x21
    80003738:	b1c78793          	addi	a5,a5,-1252 # 80024250 <bcache+0x8268>
    8000373c:	00f48863          	beq	s1,a5,8000374c <bread+0x90>
    80003740:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003742:	40bc                	lw	a5,64(s1)
    80003744:	cf81                	beqz	a5,8000375c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003746:	64a4                	ld	s1,72(s1)
    80003748:	fee49de3          	bne	s1,a4,80003742 <bread+0x86>
  panic("bget: no buffers");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	e2450513          	addi	a0,a0,-476 # 80008570 <syscalls+0xe8>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	dea080e7          	jalr	-534(ra) # 8000053e <panic>
      b->dev = dev;
    8000375c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003760:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003764:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003768:	4785                	li	a5,1
    8000376a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000376c:	00019517          	auipc	a0,0x19
    80003770:	87c50513          	addi	a0,a0,-1924 # 8001bfe8 <bcache>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	516080e7          	jalr	1302(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000377c:	01048513          	addi	a0,s1,16
    80003780:	00001097          	auipc	ra,0x1
    80003784:	410080e7          	jalr	1040(ra) # 80004b90 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003788:	409c                	lw	a5,0(s1)
    8000378a:	cb89                	beqz	a5,8000379c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000378c:	8526                	mv	a0,s1
    8000378e:	70a2                	ld	ra,40(sp)
    80003790:	7402                	ld	s0,32(sp)
    80003792:	64e2                	ld	s1,24(sp)
    80003794:	6942                	ld	s2,16(sp)
    80003796:	69a2                	ld	s3,8(sp)
    80003798:	6145                	addi	sp,sp,48
    8000379a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000379c:	4581                	li	a1,0
    8000379e:	8526                	mv	a0,s1
    800037a0:	00003097          	auipc	ra,0x3
    800037a4:	fd4080e7          	jalr	-44(ra) # 80006774 <virtio_disk_rw>
    b->valid = 1;
    800037a8:	4785                	li	a5,1
    800037aa:	c09c                	sw	a5,0(s1)
  return b;
    800037ac:	b7c5                	j	8000378c <bread+0xd0>

00000000800037ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	1000                	addi	s0,sp,32
    800037b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037ba:	0541                	addi	a0,a0,16
    800037bc:	00001097          	auipc	ra,0x1
    800037c0:	46e080e7          	jalr	1134(ra) # 80004c2a <holdingsleep>
    800037c4:	cd01                	beqz	a0,800037dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037c6:	4585                	li	a1,1
    800037c8:	8526                	mv	a0,s1
    800037ca:	00003097          	auipc	ra,0x3
    800037ce:	faa080e7          	jalr	-86(ra) # 80006774 <virtio_disk_rw>
}
    800037d2:	60e2                	ld	ra,24(sp)
    800037d4:	6442                	ld	s0,16(sp)
    800037d6:	64a2                	ld	s1,8(sp)
    800037d8:	6105                	addi	sp,sp,32
    800037da:	8082                	ret
    panic("bwrite");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	dac50513          	addi	a0,a0,-596 # 80008588 <syscalls+0x100>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d5a080e7          	jalr	-678(ra) # 8000053e <panic>

00000000800037ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037ec:	1101                	addi	sp,sp,-32
    800037ee:	ec06                	sd	ra,24(sp)
    800037f0:	e822                	sd	s0,16(sp)
    800037f2:	e426                	sd	s1,8(sp)
    800037f4:	e04a                	sd	s2,0(sp)
    800037f6:	1000                	addi	s0,sp,32
    800037f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037fa:	01050913          	addi	s2,a0,16
    800037fe:	854a                	mv	a0,s2
    80003800:	00001097          	auipc	ra,0x1
    80003804:	42a080e7          	jalr	1066(ra) # 80004c2a <holdingsleep>
    80003808:	c92d                	beqz	a0,8000387a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	3da080e7          	jalr	986(ra) # 80004be6 <releasesleep>

  acquire(&bcache.lock);
    80003814:	00018517          	auipc	a0,0x18
    80003818:	7d450513          	addi	a0,a0,2004 # 8001bfe8 <bcache>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	3ba080e7          	jalr	954(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003824:	40bc                	lw	a5,64(s1)
    80003826:	37fd                	addiw	a5,a5,-1
    80003828:	0007871b          	sext.w	a4,a5
    8000382c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000382e:	eb05                	bnez	a4,8000385e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003830:	68bc                	ld	a5,80(s1)
    80003832:	64b8                	ld	a4,72(s1)
    80003834:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003836:	64bc                	ld	a5,72(s1)
    80003838:	68b8                	ld	a4,80(s1)
    8000383a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000383c:	00020797          	auipc	a5,0x20
    80003840:	7ac78793          	addi	a5,a5,1964 # 80023fe8 <bcache+0x8000>
    80003844:	2b87b703          	ld	a4,696(a5)
    80003848:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000384a:	00021717          	auipc	a4,0x21
    8000384e:	a0670713          	addi	a4,a4,-1530 # 80024250 <bcache+0x8268>
    80003852:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003854:	2b87b703          	ld	a4,696(a5)
    80003858:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000385a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000385e:	00018517          	auipc	a0,0x18
    80003862:	78a50513          	addi	a0,a0,1930 # 8001bfe8 <bcache>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	424080e7          	jalr	1060(ra) # 80000c8a <release>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6902                	ld	s2,0(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret
    panic("brelse");
    8000387a:	00005517          	auipc	a0,0x5
    8000387e:	d1650513          	addi	a0,a0,-746 # 80008590 <syscalls+0x108>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	cbc080e7          	jalr	-836(ra) # 8000053e <panic>

000000008000388a <bpin>:

void
bpin(struct buf *b) {
    8000388a:	1101                	addi	sp,sp,-32
    8000388c:	ec06                	sd	ra,24(sp)
    8000388e:	e822                	sd	s0,16(sp)
    80003890:	e426                	sd	s1,8(sp)
    80003892:	1000                	addi	s0,sp,32
    80003894:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003896:	00018517          	auipc	a0,0x18
    8000389a:	75250513          	addi	a0,a0,1874 # 8001bfe8 <bcache>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	338080e7          	jalr	824(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800038a6:	40bc                	lw	a5,64(s1)
    800038a8:	2785                	addiw	a5,a5,1
    800038aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ac:	00018517          	auipc	a0,0x18
    800038b0:	73c50513          	addi	a0,a0,1852 # 8001bfe8 <bcache>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	3d6080e7          	jalr	982(ra) # 80000c8a <release>
}
    800038bc:	60e2                	ld	ra,24(sp)
    800038be:	6442                	ld	s0,16(sp)
    800038c0:	64a2                	ld	s1,8(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret

00000000800038c6 <bunpin>:

void
bunpin(struct buf *b) {
    800038c6:	1101                	addi	sp,sp,-32
    800038c8:	ec06                	sd	ra,24(sp)
    800038ca:	e822                	sd	s0,16(sp)
    800038cc:	e426                	sd	s1,8(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038d2:	00018517          	auipc	a0,0x18
    800038d6:	71650513          	addi	a0,a0,1814 # 8001bfe8 <bcache>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	2fc080e7          	jalr	764(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800038e2:	40bc                	lw	a5,64(s1)
    800038e4:	37fd                	addiw	a5,a5,-1
    800038e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038e8:	00018517          	auipc	a0,0x18
    800038ec:	70050513          	addi	a0,a0,1792 # 8001bfe8 <bcache>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	39a080e7          	jalr	922(ra) # 80000c8a <release>
}
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret

0000000080003902 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	e04a                	sd	s2,0(sp)
    8000390c:	1000                	addi	s0,sp,32
    8000390e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003910:	00d5d59b          	srliw	a1,a1,0xd
    80003914:	00021797          	auipc	a5,0x21
    80003918:	db07a783          	lw	a5,-592(a5) # 800246c4 <sb+0x1c>
    8000391c:	9dbd                	addw	a1,a1,a5
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	d9e080e7          	jalr	-610(ra) # 800036bc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003926:	0074f713          	andi	a4,s1,7
    8000392a:	4785                	li	a5,1
    8000392c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003930:	14ce                	slli	s1,s1,0x33
    80003932:	90d9                	srli	s1,s1,0x36
    80003934:	00950733          	add	a4,a0,s1
    80003938:	05874703          	lbu	a4,88(a4)
    8000393c:	00e7f6b3          	and	a3,a5,a4
    80003940:	c69d                	beqz	a3,8000396e <bfree+0x6c>
    80003942:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003944:	94aa                	add	s1,s1,a0
    80003946:	fff7c793          	not	a5,a5
    8000394a:	8ff9                	and	a5,a5,a4
    8000394c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003950:	00001097          	auipc	ra,0x1
    80003954:	120080e7          	jalr	288(ra) # 80004a70 <log_write>
  brelse(bp);
    80003958:	854a                	mv	a0,s2
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	e92080e7          	jalr	-366(ra) # 800037ec <brelse>
}
    80003962:	60e2                	ld	ra,24(sp)
    80003964:	6442                	ld	s0,16(sp)
    80003966:	64a2                	ld	s1,8(sp)
    80003968:	6902                	ld	s2,0(sp)
    8000396a:	6105                	addi	sp,sp,32
    8000396c:	8082                	ret
    panic("freeing free block");
    8000396e:	00005517          	auipc	a0,0x5
    80003972:	c2a50513          	addi	a0,a0,-982 # 80008598 <syscalls+0x110>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	bc8080e7          	jalr	-1080(ra) # 8000053e <panic>

000000008000397e <balloc>:
{
    8000397e:	711d                	addi	sp,sp,-96
    80003980:	ec86                	sd	ra,88(sp)
    80003982:	e8a2                	sd	s0,80(sp)
    80003984:	e4a6                	sd	s1,72(sp)
    80003986:	e0ca                	sd	s2,64(sp)
    80003988:	fc4e                	sd	s3,56(sp)
    8000398a:	f852                	sd	s4,48(sp)
    8000398c:	f456                	sd	s5,40(sp)
    8000398e:	f05a                	sd	s6,32(sp)
    80003990:	ec5e                	sd	s7,24(sp)
    80003992:	e862                	sd	s8,16(sp)
    80003994:	e466                	sd	s9,8(sp)
    80003996:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003998:	00021797          	auipc	a5,0x21
    8000399c:	d147a783          	lw	a5,-748(a5) # 800246ac <sb+0x4>
    800039a0:	10078163          	beqz	a5,80003aa2 <balloc+0x124>
    800039a4:	8baa                	mv	s7,a0
    800039a6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039a8:	00021b17          	auipc	s6,0x21
    800039ac:	d00b0b13          	addi	s6,s6,-768 # 800246a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039b2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039b6:	6c89                	lui	s9,0x2
    800039b8:	a061                	j	80003a40 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039ba:	974a                	add	a4,a4,s2
    800039bc:	8fd5                	or	a5,a5,a3
    800039be:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039c2:	854a                	mv	a0,s2
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	0ac080e7          	jalr	172(ra) # 80004a70 <log_write>
        brelse(bp);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	e1e080e7          	jalr	-482(ra) # 800037ec <brelse>
  bp = bread(dev, bno);
    800039d6:	85a6                	mv	a1,s1
    800039d8:	855e                	mv	a0,s7
    800039da:	00000097          	auipc	ra,0x0
    800039de:	ce2080e7          	jalr	-798(ra) # 800036bc <bread>
    800039e2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039e4:	40000613          	li	a2,1024
    800039e8:	4581                	li	a1,0
    800039ea:	05850513          	addi	a0,a0,88
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	2e4080e7          	jalr	740(ra) # 80000cd2 <memset>
  log_write(bp);
    800039f6:	854a                	mv	a0,s2
    800039f8:	00001097          	auipc	ra,0x1
    800039fc:	078080e7          	jalr	120(ra) # 80004a70 <log_write>
  brelse(bp);
    80003a00:	854a                	mv	a0,s2
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	dea080e7          	jalr	-534(ra) # 800037ec <brelse>
}
    80003a0a:	8526                	mv	a0,s1
    80003a0c:	60e6                	ld	ra,88(sp)
    80003a0e:	6446                	ld	s0,80(sp)
    80003a10:	64a6                	ld	s1,72(sp)
    80003a12:	6906                	ld	s2,64(sp)
    80003a14:	79e2                	ld	s3,56(sp)
    80003a16:	7a42                	ld	s4,48(sp)
    80003a18:	7aa2                	ld	s5,40(sp)
    80003a1a:	7b02                	ld	s6,32(sp)
    80003a1c:	6be2                	ld	s7,24(sp)
    80003a1e:	6c42                	ld	s8,16(sp)
    80003a20:	6ca2                	ld	s9,8(sp)
    80003a22:	6125                	addi	sp,sp,96
    80003a24:	8082                	ret
    brelse(bp);
    80003a26:	854a                	mv	a0,s2
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	dc4080e7          	jalr	-572(ra) # 800037ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a30:	015c87bb          	addw	a5,s9,s5
    80003a34:	00078a9b          	sext.w	s5,a5
    80003a38:	004b2703          	lw	a4,4(s6)
    80003a3c:	06eaf363          	bgeu	s5,a4,80003aa2 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003a40:	41fad79b          	sraiw	a5,s5,0x1f
    80003a44:	0137d79b          	srliw	a5,a5,0x13
    80003a48:	015787bb          	addw	a5,a5,s5
    80003a4c:	40d7d79b          	sraiw	a5,a5,0xd
    80003a50:	01cb2583          	lw	a1,28(s6)
    80003a54:	9dbd                	addw	a1,a1,a5
    80003a56:	855e                	mv	a0,s7
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	c64080e7          	jalr	-924(ra) # 800036bc <bread>
    80003a60:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a62:	004b2503          	lw	a0,4(s6)
    80003a66:	000a849b          	sext.w	s1,s5
    80003a6a:	8662                	mv	a2,s8
    80003a6c:	faa4fde3          	bgeu	s1,a0,80003a26 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003a70:	41f6579b          	sraiw	a5,a2,0x1f
    80003a74:	01d7d69b          	srliw	a3,a5,0x1d
    80003a78:	00c6873b          	addw	a4,a3,a2
    80003a7c:	00777793          	andi	a5,a4,7
    80003a80:	9f95                	subw	a5,a5,a3
    80003a82:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a86:	4037571b          	sraiw	a4,a4,0x3
    80003a8a:	00e906b3          	add	a3,s2,a4
    80003a8e:	0586c683          	lbu	a3,88(a3)
    80003a92:	00d7f5b3          	and	a1,a5,a3
    80003a96:	d195                	beqz	a1,800039ba <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a98:	2605                	addiw	a2,a2,1
    80003a9a:	2485                	addiw	s1,s1,1
    80003a9c:	fd4618e3          	bne	a2,s4,80003a6c <balloc+0xee>
    80003aa0:	b759                	j	80003a26 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003aa2:	00005517          	auipc	a0,0x5
    80003aa6:	b0e50513          	addi	a0,a0,-1266 # 800085b0 <syscalls+0x128>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	ade080e7          	jalr	-1314(ra) # 80000588 <printf>
  return 0;
    80003ab2:	4481                	li	s1,0
    80003ab4:	bf99                	j	80003a0a <balloc+0x8c>

0000000080003ab6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ab6:	7179                	addi	sp,sp,-48
    80003ab8:	f406                	sd	ra,40(sp)
    80003aba:	f022                	sd	s0,32(sp)
    80003abc:	ec26                	sd	s1,24(sp)
    80003abe:	e84a                	sd	s2,16(sp)
    80003ac0:	e44e                	sd	s3,8(sp)
    80003ac2:	e052                	sd	s4,0(sp)
    80003ac4:	1800                	addi	s0,sp,48
    80003ac6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ac8:	47ad                	li	a5,11
    80003aca:	02b7e763          	bltu	a5,a1,80003af8 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003ace:	02059493          	slli	s1,a1,0x20
    80003ad2:	9081                	srli	s1,s1,0x20
    80003ad4:	048a                	slli	s1,s1,0x2
    80003ad6:	94aa                	add	s1,s1,a0
    80003ad8:	0504a903          	lw	s2,80(s1)
    80003adc:	06091e63          	bnez	s2,80003b58 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003ae0:	4108                	lw	a0,0(a0)
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	e9c080e7          	jalr	-356(ra) # 8000397e <balloc>
    80003aea:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003aee:	06090563          	beqz	s2,80003b58 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003af2:	0524a823          	sw	s2,80(s1)
    80003af6:	a08d                	j	80003b58 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003af8:	ff45849b          	addiw	s1,a1,-12
    80003afc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b00:	0ff00793          	li	a5,255
    80003b04:	08e7e563          	bltu	a5,a4,80003b8e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003b08:	08052903          	lw	s2,128(a0)
    80003b0c:	00091d63          	bnez	s2,80003b26 <bmap+0x70>
      addr = balloc(ip->dev);
    80003b10:	4108                	lw	a0,0(a0)
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	e6c080e7          	jalr	-404(ra) # 8000397e <balloc>
    80003b1a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b1e:	02090d63          	beqz	s2,80003b58 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b22:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003b26:	85ca                	mv	a1,s2
    80003b28:	0009a503          	lw	a0,0(s3)
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	b90080e7          	jalr	-1136(ra) # 800036bc <bread>
    80003b34:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b36:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b3a:	02049593          	slli	a1,s1,0x20
    80003b3e:	9181                	srli	a1,a1,0x20
    80003b40:	058a                	slli	a1,a1,0x2
    80003b42:	00b784b3          	add	s1,a5,a1
    80003b46:	0004a903          	lw	s2,0(s1)
    80003b4a:	02090063          	beqz	s2,80003b6a <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b4e:	8552                	mv	a0,s4
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	c9c080e7          	jalr	-868(ra) # 800037ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b58:	854a                	mv	a0,s2
    80003b5a:	70a2                	ld	ra,40(sp)
    80003b5c:	7402                	ld	s0,32(sp)
    80003b5e:	64e2                	ld	s1,24(sp)
    80003b60:	6942                	ld	s2,16(sp)
    80003b62:	69a2                	ld	s3,8(sp)
    80003b64:	6a02                	ld	s4,0(sp)
    80003b66:	6145                	addi	sp,sp,48
    80003b68:	8082                	ret
      addr = balloc(ip->dev);
    80003b6a:	0009a503          	lw	a0,0(s3)
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	e10080e7          	jalr	-496(ra) # 8000397e <balloc>
    80003b76:	0005091b          	sext.w	s2,a0
      if(addr){
    80003b7a:	fc090ae3          	beqz	s2,80003b4e <bmap+0x98>
        a[bn] = addr;
    80003b7e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003b82:	8552                	mv	a0,s4
    80003b84:	00001097          	auipc	ra,0x1
    80003b88:	eec080e7          	jalr	-276(ra) # 80004a70 <log_write>
    80003b8c:	b7c9                	j	80003b4e <bmap+0x98>
  panic("bmap: out of range");
    80003b8e:	00005517          	auipc	a0,0x5
    80003b92:	a3a50513          	addi	a0,a0,-1478 # 800085c8 <syscalls+0x140>
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	9a8080e7          	jalr	-1624(ra) # 8000053e <panic>

0000000080003b9e <iget>:
{
    80003b9e:	7179                	addi	sp,sp,-48
    80003ba0:	f406                	sd	ra,40(sp)
    80003ba2:	f022                	sd	s0,32(sp)
    80003ba4:	ec26                	sd	s1,24(sp)
    80003ba6:	e84a                	sd	s2,16(sp)
    80003ba8:	e44e                	sd	s3,8(sp)
    80003baa:	e052                	sd	s4,0(sp)
    80003bac:	1800                	addi	s0,sp,48
    80003bae:	89aa                	mv	s3,a0
    80003bb0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bb2:	00021517          	auipc	a0,0x21
    80003bb6:	b1650513          	addi	a0,a0,-1258 # 800246c8 <itable>
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	01c080e7          	jalr	28(ra) # 80000bd6 <acquire>
  empty = 0;
    80003bc2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bc4:	00021497          	auipc	s1,0x21
    80003bc8:	b1c48493          	addi	s1,s1,-1252 # 800246e0 <itable+0x18>
    80003bcc:	00022697          	auipc	a3,0x22
    80003bd0:	5a468693          	addi	a3,a3,1444 # 80026170 <log>
    80003bd4:	a039                	j	80003be2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bd6:	02090b63          	beqz	s2,80003c0c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bda:	08848493          	addi	s1,s1,136
    80003bde:	02d48a63          	beq	s1,a3,80003c12 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003be2:	449c                	lw	a5,8(s1)
    80003be4:	fef059e3          	blez	a5,80003bd6 <iget+0x38>
    80003be8:	4098                	lw	a4,0(s1)
    80003bea:	ff3716e3          	bne	a4,s3,80003bd6 <iget+0x38>
    80003bee:	40d8                	lw	a4,4(s1)
    80003bf0:	ff4713e3          	bne	a4,s4,80003bd6 <iget+0x38>
      ip->ref++;
    80003bf4:	2785                	addiw	a5,a5,1
    80003bf6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bf8:	00021517          	auipc	a0,0x21
    80003bfc:	ad050513          	addi	a0,a0,-1328 # 800246c8 <itable>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	08a080e7          	jalr	138(ra) # 80000c8a <release>
      return ip;
    80003c08:	8926                	mv	s2,s1
    80003c0a:	a03d                	j	80003c38 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c0c:	f7f9                	bnez	a5,80003bda <iget+0x3c>
    80003c0e:	8926                	mv	s2,s1
    80003c10:	b7e9                	j	80003bda <iget+0x3c>
  if(empty == 0)
    80003c12:	02090c63          	beqz	s2,80003c4a <iget+0xac>
  ip->dev = dev;
    80003c16:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c1a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c1e:	4785                	li	a5,1
    80003c20:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c24:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c28:	00021517          	auipc	a0,0x21
    80003c2c:	aa050513          	addi	a0,a0,-1376 # 800246c8 <itable>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	05a080e7          	jalr	90(ra) # 80000c8a <release>
}
    80003c38:	854a                	mv	a0,s2
    80003c3a:	70a2                	ld	ra,40(sp)
    80003c3c:	7402                	ld	s0,32(sp)
    80003c3e:	64e2                	ld	s1,24(sp)
    80003c40:	6942                	ld	s2,16(sp)
    80003c42:	69a2                	ld	s3,8(sp)
    80003c44:	6a02                	ld	s4,0(sp)
    80003c46:	6145                	addi	sp,sp,48
    80003c48:	8082                	ret
    panic("iget: no inodes");
    80003c4a:	00005517          	auipc	a0,0x5
    80003c4e:	99650513          	addi	a0,a0,-1642 # 800085e0 <syscalls+0x158>
    80003c52:	ffffd097          	auipc	ra,0xffffd
    80003c56:	8ec080e7          	jalr	-1812(ra) # 8000053e <panic>

0000000080003c5a <fsinit>:
fsinit(int dev) {
    80003c5a:	7179                	addi	sp,sp,-48
    80003c5c:	f406                	sd	ra,40(sp)
    80003c5e:	f022                	sd	s0,32(sp)
    80003c60:	ec26                	sd	s1,24(sp)
    80003c62:	e84a                	sd	s2,16(sp)
    80003c64:	e44e                	sd	s3,8(sp)
    80003c66:	1800                	addi	s0,sp,48
    80003c68:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c6a:	4585                	li	a1,1
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	a50080e7          	jalr	-1456(ra) # 800036bc <bread>
    80003c74:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c76:	00021997          	auipc	s3,0x21
    80003c7a:	a3298993          	addi	s3,s3,-1486 # 800246a8 <sb>
    80003c7e:	02000613          	li	a2,32
    80003c82:	05850593          	addi	a1,a0,88
    80003c86:	854e                	mv	a0,s3
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	0a6080e7          	jalr	166(ra) # 80000d2e <memmove>
  brelse(bp);
    80003c90:	8526                	mv	a0,s1
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	b5a080e7          	jalr	-1190(ra) # 800037ec <brelse>
  if(sb.magic != FSMAGIC)
    80003c9a:	0009a703          	lw	a4,0(s3)
    80003c9e:	102037b7          	lui	a5,0x10203
    80003ca2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ca6:	02f71263          	bne	a4,a5,80003cca <fsinit+0x70>
  initlog(dev, &sb);
    80003caa:	00021597          	auipc	a1,0x21
    80003cae:	9fe58593          	addi	a1,a1,-1538 # 800246a8 <sb>
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	00001097          	auipc	ra,0x1
    80003cb8:	b40080e7          	jalr	-1216(ra) # 800047f4 <initlog>
}
    80003cbc:	70a2                	ld	ra,40(sp)
    80003cbe:	7402                	ld	s0,32(sp)
    80003cc0:	64e2                	ld	s1,24(sp)
    80003cc2:	6942                	ld	s2,16(sp)
    80003cc4:	69a2                	ld	s3,8(sp)
    80003cc6:	6145                	addi	sp,sp,48
    80003cc8:	8082                	ret
    panic("invalid file system");
    80003cca:	00005517          	auipc	a0,0x5
    80003cce:	92650513          	addi	a0,a0,-1754 # 800085f0 <syscalls+0x168>
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>

0000000080003cda <iinit>:
{
    80003cda:	7179                	addi	sp,sp,-48
    80003cdc:	f406                	sd	ra,40(sp)
    80003cde:	f022                	sd	s0,32(sp)
    80003ce0:	ec26                	sd	s1,24(sp)
    80003ce2:	e84a                	sd	s2,16(sp)
    80003ce4:	e44e                	sd	s3,8(sp)
    80003ce6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ce8:	00005597          	auipc	a1,0x5
    80003cec:	92058593          	addi	a1,a1,-1760 # 80008608 <syscalls+0x180>
    80003cf0:	00021517          	auipc	a0,0x21
    80003cf4:	9d850513          	addi	a0,a0,-1576 # 800246c8 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	e4e080e7          	jalr	-434(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d00:	00021497          	auipc	s1,0x21
    80003d04:	9f048493          	addi	s1,s1,-1552 # 800246f0 <itable+0x28>
    80003d08:	00022997          	auipc	s3,0x22
    80003d0c:	47898993          	addi	s3,s3,1144 # 80026180 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d10:	00005917          	auipc	s2,0x5
    80003d14:	90090913          	addi	s2,s2,-1792 # 80008610 <syscalls+0x188>
    80003d18:	85ca                	mv	a1,s2
    80003d1a:	8526                	mv	a0,s1
    80003d1c:	00001097          	auipc	ra,0x1
    80003d20:	e3a080e7          	jalr	-454(ra) # 80004b56 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d24:	08848493          	addi	s1,s1,136
    80003d28:	ff3498e3          	bne	s1,s3,80003d18 <iinit+0x3e>
}
    80003d2c:	70a2                	ld	ra,40(sp)
    80003d2e:	7402                	ld	s0,32(sp)
    80003d30:	64e2                	ld	s1,24(sp)
    80003d32:	6942                	ld	s2,16(sp)
    80003d34:	69a2                	ld	s3,8(sp)
    80003d36:	6145                	addi	sp,sp,48
    80003d38:	8082                	ret

0000000080003d3a <ialloc>:
{
    80003d3a:	715d                	addi	sp,sp,-80
    80003d3c:	e486                	sd	ra,72(sp)
    80003d3e:	e0a2                	sd	s0,64(sp)
    80003d40:	fc26                	sd	s1,56(sp)
    80003d42:	f84a                	sd	s2,48(sp)
    80003d44:	f44e                	sd	s3,40(sp)
    80003d46:	f052                	sd	s4,32(sp)
    80003d48:	ec56                	sd	s5,24(sp)
    80003d4a:	e85a                	sd	s6,16(sp)
    80003d4c:	e45e                	sd	s7,8(sp)
    80003d4e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d50:	00021717          	auipc	a4,0x21
    80003d54:	96472703          	lw	a4,-1692(a4) # 800246b4 <sb+0xc>
    80003d58:	4785                	li	a5,1
    80003d5a:	04e7fa63          	bgeu	a5,a4,80003dae <ialloc+0x74>
    80003d5e:	8aaa                	mv	s5,a0
    80003d60:	8bae                	mv	s7,a1
    80003d62:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d64:	00021a17          	auipc	s4,0x21
    80003d68:	944a0a13          	addi	s4,s4,-1724 # 800246a8 <sb>
    80003d6c:	00048b1b          	sext.w	s6,s1
    80003d70:	0044d793          	srli	a5,s1,0x4
    80003d74:	018a2583          	lw	a1,24(s4)
    80003d78:	9dbd                	addw	a1,a1,a5
    80003d7a:	8556                	mv	a0,s5
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	940080e7          	jalr	-1728(ra) # 800036bc <bread>
    80003d84:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d86:	05850993          	addi	s3,a0,88
    80003d8a:	00f4f793          	andi	a5,s1,15
    80003d8e:	079a                	slli	a5,a5,0x6
    80003d90:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d92:	00099783          	lh	a5,0(s3)
    80003d96:	c3a1                	beqz	a5,80003dd6 <ialloc+0x9c>
    brelse(bp);
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	a54080e7          	jalr	-1452(ra) # 800037ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003da0:	0485                	addi	s1,s1,1
    80003da2:	00ca2703          	lw	a4,12(s4)
    80003da6:	0004879b          	sext.w	a5,s1
    80003daa:	fce7e1e3          	bltu	a5,a4,80003d6c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003dae:	00005517          	auipc	a0,0x5
    80003db2:	86a50513          	addi	a0,a0,-1942 # 80008618 <syscalls+0x190>
    80003db6:	ffffc097          	auipc	ra,0xffffc
    80003dba:	7d2080e7          	jalr	2002(ra) # 80000588 <printf>
  return 0;
    80003dbe:	4501                	li	a0,0
}
    80003dc0:	60a6                	ld	ra,72(sp)
    80003dc2:	6406                	ld	s0,64(sp)
    80003dc4:	74e2                	ld	s1,56(sp)
    80003dc6:	7942                	ld	s2,48(sp)
    80003dc8:	79a2                	ld	s3,40(sp)
    80003dca:	7a02                	ld	s4,32(sp)
    80003dcc:	6ae2                	ld	s5,24(sp)
    80003dce:	6b42                	ld	s6,16(sp)
    80003dd0:	6ba2                	ld	s7,8(sp)
    80003dd2:	6161                	addi	sp,sp,80
    80003dd4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003dd6:	04000613          	li	a2,64
    80003dda:	4581                	li	a1,0
    80003ddc:	854e                	mv	a0,s3
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	ef4080e7          	jalr	-268(ra) # 80000cd2 <memset>
      dip->type = type;
    80003de6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dea:	854a                	mv	a0,s2
    80003dec:	00001097          	auipc	ra,0x1
    80003df0:	c84080e7          	jalr	-892(ra) # 80004a70 <log_write>
      brelse(bp);
    80003df4:	854a                	mv	a0,s2
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	9f6080e7          	jalr	-1546(ra) # 800037ec <brelse>
      return iget(dev, inum);
    80003dfe:	85da                	mv	a1,s6
    80003e00:	8556                	mv	a0,s5
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	d9c080e7          	jalr	-612(ra) # 80003b9e <iget>
    80003e0a:	bf5d                	j	80003dc0 <ialloc+0x86>

0000000080003e0c <iupdate>:
{
    80003e0c:	1101                	addi	sp,sp,-32
    80003e0e:	ec06                	sd	ra,24(sp)
    80003e10:	e822                	sd	s0,16(sp)
    80003e12:	e426                	sd	s1,8(sp)
    80003e14:	e04a                	sd	s2,0(sp)
    80003e16:	1000                	addi	s0,sp,32
    80003e18:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e1a:	415c                	lw	a5,4(a0)
    80003e1c:	0047d79b          	srliw	a5,a5,0x4
    80003e20:	00021597          	auipc	a1,0x21
    80003e24:	8a05a583          	lw	a1,-1888(a1) # 800246c0 <sb+0x18>
    80003e28:	9dbd                	addw	a1,a1,a5
    80003e2a:	4108                	lw	a0,0(a0)
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	890080e7          	jalr	-1904(ra) # 800036bc <bread>
    80003e34:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e36:	05850793          	addi	a5,a0,88
    80003e3a:	40c8                	lw	a0,4(s1)
    80003e3c:	893d                	andi	a0,a0,15
    80003e3e:	051a                	slli	a0,a0,0x6
    80003e40:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e42:	04449703          	lh	a4,68(s1)
    80003e46:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e4a:	04649703          	lh	a4,70(s1)
    80003e4e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e52:	04849703          	lh	a4,72(s1)
    80003e56:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e5a:	04a49703          	lh	a4,74(s1)
    80003e5e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e62:	44f8                	lw	a4,76(s1)
    80003e64:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e66:	03400613          	li	a2,52
    80003e6a:	05048593          	addi	a1,s1,80
    80003e6e:	0531                	addi	a0,a0,12
    80003e70:	ffffd097          	auipc	ra,0xffffd
    80003e74:	ebe080e7          	jalr	-322(ra) # 80000d2e <memmove>
  log_write(bp);
    80003e78:	854a                	mv	a0,s2
    80003e7a:	00001097          	auipc	ra,0x1
    80003e7e:	bf6080e7          	jalr	-1034(ra) # 80004a70 <log_write>
  brelse(bp);
    80003e82:	854a                	mv	a0,s2
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	968080e7          	jalr	-1688(ra) # 800037ec <brelse>
}
    80003e8c:	60e2                	ld	ra,24(sp)
    80003e8e:	6442                	ld	s0,16(sp)
    80003e90:	64a2                	ld	s1,8(sp)
    80003e92:	6902                	ld	s2,0(sp)
    80003e94:	6105                	addi	sp,sp,32
    80003e96:	8082                	ret

0000000080003e98 <idup>:
{
    80003e98:	1101                	addi	sp,sp,-32
    80003e9a:	ec06                	sd	ra,24(sp)
    80003e9c:	e822                	sd	s0,16(sp)
    80003e9e:	e426                	sd	s1,8(sp)
    80003ea0:	1000                	addi	s0,sp,32
    80003ea2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ea4:	00021517          	auipc	a0,0x21
    80003ea8:	82450513          	addi	a0,a0,-2012 # 800246c8 <itable>
    80003eac:	ffffd097          	auipc	ra,0xffffd
    80003eb0:	d2a080e7          	jalr	-726(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003eb4:	449c                	lw	a5,8(s1)
    80003eb6:	2785                	addiw	a5,a5,1
    80003eb8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003eba:	00021517          	auipc	a0,0x21
    80003ebe:	80e50513          	addi	a0,a0,-2034 # 800246c8 <itable>
    80003ec2:	ffffd097          	auipc	ra,0xffffd
    80003ec6:	dc8080e7          	jalr	-568(ra) # 80000c8a <release>
}
    80003eca:	8526                	mv	a0,s1
    80003ecc:	60e2                	ld	ra,24(sp)
    80003ece:	6442                	ld	s0,16(sp)
    80003ed0:	64a2                	ld	s1,8(sp)
    80003ed2:	6105                	addi	sp,sp,32
    80003ed4:	8082                	ret

0000000080003ed6 <ilock>:
{
    80003ed6:	1101                	addi	sp,sp,-32
    80003ed8:	ec06                	sd	ra,24(sp)
    80003eda:	e822                	sd	s0,16(sp)
    80003edc:	e426                	sd	s1,8(sp)
    80003ede:	e04a                	sd	s2,0(sp)
    80003ee0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ee2:	c115                	beqz	a0,80003f06 <ilock+0x30>
    80003ee4:	84aa                	mv	s1,a0
    80003ee6:	451c                	lw	a5,8(a0)
    80003ee8:	00f05f63          	blez	a5,80003f06 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003eec:	0541                	addi	a0,a0,16
    80003eee:	00001097          	auipc	ra,0x1
    80003ef2:	ca2080e7          	jalr	-862(ra) # 80004b90 <acquiresleep>
  if(ip->valid == 0){
    80003ef6:	40bc                	lw	a5,64(s1)
    80003ef8:	cf99                	beqz	a5,80003f16 <ilock+0x40>
}
    80003efa:	60e2                	ld	ra,24(sp)
    80003efc:	6442                	ld	s0,16(sp)
    80003efe:	64a2                	ld	s1,8(sp)
    80003f00:	6902                	ld	s2,0(sp)
    80003f02:	6105                	addi	sp,sp,32
    80003f04:	8082                	ret
    panic("ilock");
    80003f06:	00004517          	auipc	a0,0x4
    80003f0a:	72a50513          	addi	a0,a0,1834 # 80008630 <syscalls+0x1a8>
    80003f0e:	ffffc097          	auipc	ra,0xffffc
    80003f12:	630080e7          	jalr	1584(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f16:	40dc                	lw	a5,4(s1)
    80003f18:	0047d79b          	srliw	a5,a5,0x4
    80003f1c:	00020597          	auipc	a1,0x20
    80003f20:	7a45a583          	lw	a1,1956(a1) # 800246c0 <sb+0x18>
    80003f24:	9dbd                	addw	a1,a1,a5
    80003f26:	4088                	lw	a0,0(s1)
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	794080e7          	jalr	1940(ra) # 800036bc <bread>
    80003f30:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f32:	05850593          	addi	a1,a0,88
    80003f36:	40dc                	lw	a5,4(s1)
    80003f38:	8bbd                	andi	a5,a5,15
    80003f3a:	079a                	slli	a5,a5,0x6
    80003f3c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f3e:	00059783          	lh	a5,0(a1)
    80003f42:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f46:	00259783          	lh	a5,2(a1)
    80003f4a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f4e:	00459783          	lh	a5,4(a1)
    80003f52:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f56:	00659783          	lh	a5,6(a1)
    80003f5a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f5e:	459c                	lw	a5,8(a1)
    80003f60:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f62:	03400613          	li	a2,52
    80003f66:	05b1                	addi	a1,a1,12
    80003f68:	05048513          	addi	a0,s1,80
    80003f6c:	ffffd097          	auipc	ra,0xffffd
    80003f70:	dc2080e7          	jalr	-574(ra) # 80000d2e <memmove>
    brelse(bp);
    80003f74:	854a                	mv	a0,s2
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	876080e7          	jalr	-1930(ra) # 800037ec <brelse>
    ip->valid = 1;
    80003f7e:	4785                	li	a5,1
    80003f80:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f82:	04449783          	lh	a5,68(s1)
    80003f86:	fbb5                	bnez	a5,80003efa <ilock+0x24>
      panic("ilock: no type");
    80003f88:	00004517          	auipc	a0,0x4
    80003f8c:	6b050513          	addi	a0,a0,1712 # 80008638 <syscalls+0x1b0>
    80003f90:	ffffc097          	auipc	ra,0xffffc
    80003f94:	5ae080e7          	jalr	1454(ra) # 8000053e <panic>

0000000080003f98 <iunlock>:
{
    80003f98:	1101                	addi	sp,sp,-32
    80003f9a:	ec06                	sd	ra,24(sp)
    80003f9c:	e822                	sd	s0,16(sp)
    80003f9e:	e426                	sd	s1,8(sp)
    80003fa0:	e04a                	sd	s2,0(sp)
    80003fa2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fa4:	c905                	beqz	a0,80003fd4 <iunlock+0x3c>
    80003fa6:	84aa                	mv	s1,a0
    80003fa8:	01050913          	addi	s2,a0,16
    80003fac:	854a                	mv	a0,s2
    80003fae:	00001097          	auipc	ra,0x1
    80003fb2:	c7c080e7          	jalr	-900(ra) # 80004c2a <holdingsleep>
    80003fb6:	cd19                	beqz	a0,80003fd4 <iunlock+0x3c>
    80003fb8:	449c                	lw	a5,8(s1)
    80003fba:	00f05d63          	blez	a5,80003fd4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fbe:	854a                	mv	a0,s2
    80003fc0:	00001097          	auipc	ra,0x1
    80003fc4:	c26080e7          	jalr	-986(ra) # 80004be6 <releasesleep>
}
    80003fc8:	60e2                	ld	ra,24(sp)
    80003fca:	6442                	ld	s0,16(sp)
    80003fcc:	64a2                	ld	s1,8(sp)
    80003fce:	6902                	ld	s2,0(sp)
    80003fd0:	6105                	addi	sp,sp,32
    80003fd2:	8082                	ret
    panic("iunlock");
    80003fd4:	00004517          	auipc	a0,0x4
    80003fd8:	67450513          	addi	a0,a0,1652 # 80008648 <syscalls+0x1c0>
    80003fdc:	ffffc097          	auipc	ra,0xffffc
    80003fe0:	562080e7          	jalr	1378(ra) # 8000053e <panic>

0000000080003fe4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fe4:	7179                	addi	sp,sp,-48
    80003fe6:	f406                	sd	ra,40(sp)
    80003fe8:	f022                	sd	s0,32(sp)
    80003fea:	ec26                	sd	s1,24(sp)
    80003fec:	e84a                	sd	s2,16(sp)
    80003fee:	e44e                	sd	s3,8(sp)
    80003ff0:	e052                	sd	s4,0(sp)
    80003ff2:	1800                	addi	s0,sp,48
    80003ff4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ff6:	05050493          	addi	s1,a0,80
    80003ffa:	08050913          	addi	s2,a0,128
    80003ffe:	a021                	j	80004006 <itrunc+0x22>
    80004000:	0491                	addi	s1,s1,4
    80004002:	01248d63          	beq	s1,s2,8000401c <itrunc+0x38>
    if(ip->addrs[i]){
    80004006:	408c                	lw	a1,0(s1)
    80004008:	dde5                	beqz	a1,80004000 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000400a:	0009a503          	lw	a0,0(s3)
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	8f4080e7          	jalr	-1804(ra) # 80003902 <bfree>
      ip->addrs[i] = 0;
    80004016:	0004a023          	sw	zero,0(s1)
    8000401a:	b7dd                	j	80004000 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000401c:	0809a583          	lw	a1,128(s3)
    80004020:	e185                	bnez	a1,80004040 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004022:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004026:	854e                	mv	a0,s3
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	de4080e7          	jalr	-540(ra) # 80003e0c <iupdate>
}
    80004030:	70a2                	ld	ra,40(sp)
    80004032:	7402                	ld	s0,32(sp)
    80004034:	64e2                	ld	s1,24(sp)
    80004036:	6942                	ld	s2,16(sp)
    80004038:	69a2                	ld	s3,8(sp)
    8000403a:	6a02                	ld	s4,0(sp)
    8000403c:	6145                	addi	sp,sp,48
    8000403e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004040:	0009a503          	lw	a0,0(s3)
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	678080e7          	jalr	1656(ra) # 800036bc <bread>
    8000404c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000404e:	05850493          	addi	s1,a0,88
    80004052:	45850913          	addi	s2,a0,1112
    80004056:	a021                	j	8000405e <itrunc+0x7a>
    80004058:	0491                	addi	s1,s1,4
    8000405a:	01248b63          	beq	s1,s2,80004070 <itrunc+0x8c>
      if(a[j])
    8000405e:	408c                	lw	a1,0(s1)
    80004060:	dde5                	beqz	a1,80004058 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004062:	0009a503          	lw	a0,0(s3)
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	89c080e7          	jalr	-1892(ra) # 80003902 <bfree>
    8000406e:	b7ed                	j	80004058 <itrunc+0x74>
    brelse(bp);
    80004070:	8552                	mv	a0,s4
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	77a080e7          	jalr	1914(ra) # 800037ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000407a:	0809a583          	lw	a1,128(s3)
    8000407e:	0009a503          	lw	a0,0(s3)
    80004082:	00000097          	auipc	ra,0x0
    80004086:	880080e7          	jalr	-1920(ra) # 80003902 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000408a:	0809a023          	sw	zero,128(s3)
    8000408e:	bf51                	j	80004022 <itrunc+0x3e>

0000000080004090 <iput>:
{
    80004090:	1101                	addi	sp,sp,-32
    80004092:	ec06                	sd	ra,24(sp)
    80004094:	e822                	sd	s0,16(sp)
    80004096:	e426                	sd	s1,8(sp)
    80004098:	e04a                	sd	s2,0(sp)
    8000409a:	1000                	addi	s0,sp,32
    8000409c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000409e:	00020517          	auipc	a0,0x20
    800040a2:	62a50513          	addi	a0,a0,1578 # 800246c8 <itable>
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	b30080e7          	jalr	-1232(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040ae:	4498                	lw	a4,8(s1)
    800040b0:	4785                	li	a5,1
    800040b2:	02f70363          	beq	a4,a5,800040d8 <iput+0x48>
  ip->ref--;
    800040b6:	449c                	lw	a5,8(s1)
    800040b8:	37fd                	addiw	a5,a5,-1
    800040ba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040bc:	00020517          	auipc	a0,0x20
    800040c0:	60c50513          	addi	a0,a0,1548 # 800246c8 <itable>
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	bc6080e7          	jalr	-1082(ra) # 80000c8a <release>
}
    800040cc:	60e2                	ld	ra,24(sp)
    800040ce:	6442                	ld	s0,16(sp)
    800040d0:	64a2                	ld	s1,8(sp)
    800040d2:	6902                	ld	s2,0(sp)
    800040d4:	6105                	addi	sp,sp,32
    800040d6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040d8:	40bc                	lw	a5,64(s1)
    800040da:	dff1                	beqz	a5,800040b6 <iput+0x26>
    800040dc:	04a49783          	lh	a5,74(s1)
    800040e0:	fbf9                	bnez	a5,800040b6 <iput+0x26>
    acquiresleep(&ip->lock);
    800040e2:	01048913          	addi	s2,s1,16
    800040e6:	854a                	mv	a0,s2
    800040e8:	00001097          	auipc	ra,0x1
    800040ec:	aa8080e7          	jalr	-1368(ra) # 80004b90 <acquiresleep>
    release(&itable.lock);
    800040f0:	00020517          	auipc	a0,0x20
    800040f4:	5d850513          	addi	a0,a0,1496 # 800246c8 <itable>
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	b92080e7          	jalr	-1134(ra) # 80000c8a <release>
    itrunc(ip);
    80004100:	8526                	mv	a0,s1
    80004102:	00000097          	auipc	ra,0x0
    80004106:	ee2080e7          	jalr	-286(ra) # 80003fe4 <itrunc>
    ip->type = 0;
    8000410a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000410e:	8526                	mv	a0,s1
    80004110:	00000097          	auipc	ra,0x0
    80004114:	cfc080e7          	jalr	-772(ra) # 80003e0c <iupdate>
    ip->valid = 0;
    80004118:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000411c:	854a                	mv	a0,s2
    8000411e:	00001097          	auipc	ra,0x1
    80004122:	ac8080e7          	jalr	-1336(ra) # 80004be6 <releasesleep>
    acquire(&itable.lock);
    80004126:	00020517          	auipc	a0,0x20
    8000412a:	5a250513          	addi	a0,a0,1442 # 800246c8 <itable>
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	aa8080e7          	jalr	-1368(ra) # 80000bd6 <acquire>
    80004136:	b741                	j	800040b6 <iput+0x26>

0000000080004138 <iunlockput>:
{
    80004138:	1101                	addi	sp,sp,-32
    8000413a:	ec06                	sd	ra,24(sp)
    8000413c:	e822                	sd	s0,16(sp)
    8000413e:	e426                	sd	s1,8(sp)
    80004140:	1000                	addi	s0,sp,32
    80004142:	84aa                	mv	s1,a0
  iunlock(ip);
    80004144:	00000097          	auipc	ra,0x0
    80004148:	e54080e7          	jalr	-428(ra) # 80003f98 <iunlock>
  iput(ip);
    8000414c:	8526                	mv	a0,s1
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	f42080e7          	jalr	-190(ra) # 80004090 <iput>
}
    80004156:	60e2                	ld	ra,24(sp)
    80004158:	6442                	ld	s0,16(sp)
    8000415a:	64a2                	ld	s1,8(sp)
    8000415c:	6105                	addi	sp,sp,32
    8000415e:	8082                	ret

0000000080004160 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004160:	1141                	addi	sp,sp,-16
    80004162:	e422                	sd	s0,8(sp)
    80004164:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004166:	411c                	lw	a5,0(a0)
    80004168:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000416a:	415c                	lw	a5,4(a0)
    8000416c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000416e:	04451783          	lh	a5,68(a0)
    80004172:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004176:	04a51783          	lh	a5,74(a0)
    8000417a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000417e:	04c56783          	lwu	a5,76(a0)
    80004182:	e99c                	sd	a5,16(a1)
}
    80004184:	6422                	ld	s0,8(sp)
    80004186:	0141                	addi	sp,sp,16
    80004188:	8082                	ret

000000008000418a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000418a:	457c                	lw	a5,76(a0)
    8000418c:	0ed7e963          	bltu	a5,a3,8000427e <readi+0xf4>
{
    80004190:	7159                	addi	sp,sp,-112
    80004192:	f486                	sd	ra,104(sp)
    80004194:	f0a2                	sd	s0,96(sp)
    80004196:	eca6                	sd	s1,88(sp)
    80004198:	e8ca                	sd	s2,80(sp)
    8000419a:	e4ce                	sd	s3,72(sp)
    8000419c:	e0d2                	sd	s4,64(sp)
    8000419e:	fc56                	sd	s5,56(sp)
    800041a0:	f85a                	sd	s6,48(sp)
    800041a2:	f45e                	sd	s7,40(sp)
    800041a4:	f062                	sd	s8,32(sp)
    800041a6:	ec66                	sd	s9,24(sp)
    800041a8:	e86a                	sd	s10,16(sp)
    800041aa:	e46e                	sd	s11,8(sp)
    800041ac:	1880                	addi	s0,sp,112
    800041ae:	8b2a                	mv	s6,a0
    800041b0:	8bae                	mv	s7,a1
    800041b2:	8a32                	mv	s4,a2
    800041b4:	84b6                	mv	s1,a3
    800041b6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800041b8:	9f35                	addw	a4,a4,a3
    return 0;
    800041ba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041bc:	0ad76063          	bltu	a4,a3,8000425c <readi+0xd2>
  if(off + n > ip->size)
    800041c0:	00e7f463          	bgeu	a5,a4,800041c8 <readi+0x3e>
    n = ip->size - off;
    800041c4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041c8:	0a0a8963          	beqz	s5,8000427a <readi+0xf0>
    800041cc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ce:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041d2:	5c7d                	li	s8,-1
    800041d4:	a82d                	j	8000420e <readi+0x84>
    800041d6:	020d1d93          	slli	s11,s10,0x20
    800041da:	020ddd93          	srli	s11,s11,0x20
    800041de:	05890793          	addi	a5,s2,88
    800041e2:	86ee                	mv	a3,s11
    800041e4:	963e                	add	a2,a2,a5
    800041e6:	85d2                	mv	a1,s4
    800041e8:	855e                	mv	a0,s7
    800041ea:	ffffe097          	auipc	ra,0xffffe
    800041ee:	60a080e7          	jalr	1546(ra) # 800027f4 <either_copyout>
    800041f2:	05850d63          	beq	a0,s8,8000424c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041f6:	854a                	mv	a0,s2
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	5f4080e7          	jalr	1524(ra) # 800037ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004200:	013d09bb          	addw	s3,s10,s3
    80004204:	009d04bb          	addw	s1,s10,s1
    80004208:	9a6e                	add	s4,s4,s11
    8000420a:	0559f763          	bgeu	s3,s5,80004258 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000420e:	00a4d59b          	srliw	a1,s1,0xa
    80004212:	855a                	mv	a0,s6
    80004214:	00000097          	auipc	ra,0x0
    80004218:	8a2080e7          	jalr	-1886(ra) # 80003ab6 <bmap>
    8000421c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004220:	cd85                	beqz	a1,80004258 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004222:	000b2503          	lw	a0,0(s6)
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	496080e7          	jalr	1174(ra) # 800036bc <bread>
    8000422e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004230:	3ff4f613          	andi	a2,s1,1023
    80004234:	40cc87bb          	subw	a5,s9,a2
    80004238:	413a873b          	subw	a4,s5,s3
    8000423c:	8d3e                	mv	s10,a5
    8000423e:	2781                	sext.w	a5,a5
    80004240:	0007069b          	sext.w	a3,a4
    80004244:	f8f6f9e3          	bgeu	a3,a5,800041d6 <readi+0x4c>
    80004248:	8d3a                	mv	s10,a4
    8000424a:	b771                	j	800041d6 <readi+0x4c>
      brelse(bp);
    8000424c:	854a                	mv	a0,s2
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	59e080e7          	jalr	1438(ra) # 800037ec <brelse>
      tot = -1;
    80004256:	59fd                	li	s3,-1
  }
  return tot;
    80004258:	0009851b          	sext.w	a0,s3
}
    8000425c:	70a6                	ld	ra,104(sp)
    8000425e:	7406                	ld	s0,96(sp)
    80004260:	64e6                	ld	s1,88(sp)
    80004262:	6946                	ld	s2,80(sp)
    80004264:	69a6                	ld	s3,72(sp)
    80004266:	6a06                	ld	s4,64(sp)
    80004268:	7ae2                	ld	s5,56(sp)
    8000426a:	7b42                	ld	s6,48(sp)
    8000426c:	7ba2                	ld	s7,40(sp)
    8000426e:	7c02                	ld	s8,32(sp)
    80004270:	6ce2                	ld	s9,24(sp)
    80004272:	6d42                	ld	s10,16(sp)
    80004274:	6da2                	ld	s11,8(sp)
    80004276:	6165                	addi	sp,sp,112
    80004278:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000427a:	89d6                	mv	s3,s5
    8000427c:	bff1                	j	80004258 <readi+0xce>
    return 0;
    8000427e:	4501                	li	a0,0
}
    80004280:	8082                	ret

0000000080004282 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004282:	457c                	lw	a5,76(a0)
    80004284:	10d7e863          	bltu	a5,a3,80004394 <writei+0x112>
{
    80004288:	7159                	addi	sp,sp,-112
    8000428a:	f486                	sd	ra,104(sp)
    8000428c:	f0a2                	sd	s0,96(sp)
    8000428e:	eca6                	sd	s1,88(sp)
    80004290:	e8ca                	sd	s2,80(sp)
    80004292:	e4ce                	sd	s3,72(sp)
    80004294:	e0d2                	sd	s4,64(sp)
    80004296:	fc56                	sd	s5,56(sp)
    80004298:	f85a                	sd	s6,48(sp)
    8000429a:	f45e                	sd	s7,40(sp)
    8000429c:	f062                	sd	s8,32(sp)
    8000429e:	ec66                	sd	s9,24(sp)
    800042a0:	e86a                	sd	s10,16(sp)
    800042a2:	e46e                	sd	s11,8(sp)
    800042a4:	1880                	addi	s0,sp,112
    800042a6:	8aaa                	mv	s5,a0
    800042a8:	8bae                	mv	s7,a1
    800042aa:	8a32                	mv	s4,a2
    800042ac:	8936                	mv	s2,a3
    800042ae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042b0:	00e687bb          	addw	a5,a3,a4
    800042b4:	0ed7e263          	bltu	a5,a3,80004398 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042b8:	00043737          	lui	a4,0x43
    800042bc:	0ef76063          	bltu	a4,a5,8000439c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042c0:	0c0b0863          	beqz	s6,80004390 <writei+0x10e>
    800042c4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800042c6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042ca:	5c7d                	li	s8,-1
    800042cc:	a091                	j	80004310 <writei+0x8e>
    800042ce:	020d1d93          	slli	s11,s10,0x20
    800042d2:	020ddd93          	srli	s11,s11,0x20
    800042d6:	05848793          	addi	a5,s1,88
    800042da:	86ee                	mv	a3,s11
    800042dc:	8652                	mv	a2,s4
    800042de:	85de                	mv	a1,s7
    800042e0:	953e                	add	a0,a0,a5
    800042e2:	ffffe097          	auipc	ra,0xffffe
    800042e6:	568080e7          	jalr	1384(ra) # 8000284a <either_copyin>
    800042ea:	07850263          	beq	a0,s8,8000434e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042ee:	8526                	mv	a0,s1
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	780080e7          	jalr	1920(ra) # 80004a70 <log_write>
    brelse(bp);
    800042f8:	8526                	mv	a0,s1
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	4f2080e7          	jalr	1266(ra) # 800037ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004302:	013d09bb          	addw	s3,s10,s3
    80004306:	012d093b          	addw	s2,s10,s2
    8000430a:	9a6e                	add	s4,s4,s11
    8000430c:	0569f663          	bgeu	s3,s6,80004358 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004310:	00a9559b          	srliw	a1,s2,0xa
    80004314:	8556                	mv	a0,s5
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	7a0080e7          	jalr	1952(ra) # 80003ab6 <bmap>
    8000431e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004322:	c99d                	beqz	a1,80004358 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004324:	000aa503          	lw	a0,0(s5)
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	394080e7          	jalr	916(ra) # 800036bc <bread>
    80004330:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004332:	3ff97513          	andi	a0,s2,1023
    80004336:	40ac87bb          	subw	a5,s9,a0
    8000433a:	413b073b          	subw	a4,s6,s3
    8000433e:	8d3e                	mv	s10,a5
    80004340:	2781                	sext.w	a5,a5
    80004342:	0007069b          	sext.w	a3,a4
    80004346:	f8f6f4e3          	bgeu	a3,a5,800042ce <writei+0x4c>
    8000434a:	8d3a                	mv	s10,a4
    8000434c:	b749                	j	800042ce <writei+0x4c>
      brelse(bp);
    8000434e:	8526                	mv	a0,s1
    80004350:	fffff097          	auipc	ra,0xfffff
    80004354:	49c080e7          	jalr	1180(ra) # 800037ec <brelse>
  }

  if(off > ip->size)
    80004358:	04caa783          	lw	a5,76(s5)
    8000435c:	0127f463          	bgeu	a5,s2,80004364 <writei+0xe2>
    ip->size = off;
    80004360:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004364:	8556                	mv	a0,s5
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	aa6080e7          	jalr	-1370(ra) # 80003e0c <iupdate>

  return tot;
    8000436e:	0009851b          	sext.w	a0,s3
}
    80004372:	70a6                	ld	ra,104(sp)
    80004374:	7406                	ld	s0,96(sp)
    80004376:	64e6                	ld	s1,88(sp)
    80004378:	6946                	ld	s2,80(sp)
    8000437a:	69a6                	ld	s3,72(sp)
    8000437c:	6a06                	ld	s4,64(sp)
    8000437e:	7ae2                	ld	s5,56(sp)
    80004380:	7b42                	ld	s6,48(sp)
    80004382:	7ba2                	ld	s7,40(sp)
    80004384:	7c02                	ld	s8,32(sp)
    80004386:	6ce2                	ld	s9,24(sp)
    80004388:	6d42                	ld	s10,16(sp)
    8000438a:	6da2                	ld	s11,8(sp)
    8000438c:	6165                	addi	sp,sp,112
    8000438e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004390:	89da                	mv	s3,s6
    80004392:	bfc9                	j	80004364 <writei+0xe2>
    return -1;
    80004394:	557d                	li	a0,-1
}
    80004396:	8082                	ret
    return -1;
    80004398:	557d                	li	a0,-1
    8000439a:	bfe1                	j	80004372 <writei+0xf0>
    return -1;
    8000439c:	557d                	li	a0,-1
    8000439e:	bfd1                	j	80004372 <writei+0xf0>

00000000800043a0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043a0:	1141                	addi	sp,sp,-16
    800043a2:	e406                	sd	ra,8(sp)
    800043a4:	e022                	sd	s0,0(sp)
    800043a6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043a8:	4639                	li	a2,14
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	9f8080e7          	jalr	-1544(ra) # 80000da2 <strncmp>
}
    800043b2:	60a2                	ld	ra,8(sp)
    800043b4:	6402                	ld	s0,0(sp)
    800043b6:	0141                	addi	sp,sp,16
    800043b8:	8082                	ret

00000000800043ba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043ba:	7139                	addi	sp,sp,-64
    800043bc:	fc06                	sd	ra,56(sp)
    800043be:	f822                	sd	s0,48(sp)
    800043c0:	f426                	sd	s1,40(sp)
    800043c2:	f04a                	sd	s2,32(sp)
    800043c4:	ec4e                	sd	s3,24(sp)
    800043c6:	e852                	sd	s4,16(sp)
    800043c8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043ca:	04451703          	lh	a4,68(a0)
    800043ce:	4785                	li	a5,1
    800043d0:	00f71a63          	bne	a4,a5,800043e4 <dirlookup+0x2a>
    800043d4:	892a                	mv	s2,a0
    800043d6:	89ae                	mv	s3,a1
    800043d8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043da:	457c                	lw	a5,76(a0)
    800043dc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043de:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e0:	e79d                	bnez	a5,8000440e <dirlookup+0x54>
    800043e2:	a8a5                	j	8000445a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043e4:	00004517          	auipc	a0,0x4
    800043e8:	26c50513          	addi	a0,a0,620 # 80008650 <syscalls+0x1c8>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	152080e7          	jalr	338(ra) # 8000053e <panic>
      panic("dirlookup read");
    800043f4:	00004517          	auipc	a0,0x4
    800043f8:	27450513          	addi	a0,a0,628 # 80008668 <syscalls+0x1e0>
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	142080e7          	jalr	322(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004404:	24c1                	addiw	s1,s1,16
    80004406:	04c92783          	lw	a5,76(s2)
    8000440a:	04f4f763          	bgeu	s1,a5,80004458 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440e:	4741                	li	a4,16
    80004410:	86a6                	mv	a3,s1
    80004412:	fc040613          	addi	a2,s0,-64
    80004416:	4581                	li	a1,0
    80004418:	854a                	mv	a0,s2
    8000441a:	00000097          	auipc	ra,0x0
    8000441e:	d70080e7          	jalr	-656(ra) # 8000418a <readi>
    80004422:	47c1                	li	a5,16
    80004424:	fcf518e3          	bne	a0,a5,800043f4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004428:	fc045783          	lhu	a5,-64(s0)
    8000442c:	dfe1                	beqz	a5,80004404 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000442e:	fc240593          	addi	a1,s0,-62
    80004432:	854e                	mv	a0,s3
    80004434:	00000097          	auipc	ra,0x0
    80004438:	f6c080e7          	jalr	-148(ra) # 800043a0 <namecmp>
    8000443c:	f561                	bnez	a0,80004404 <dirlookup+0x4a>
      if(poff)
    8000443e:	000a0463          	beqz	s4,80004446 <dirlookup+0x8c>
        *poff = off;
    80004442:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004446:	fc045583          	lhu	a1,-64(s0)
    8000444a:	00092503          	lw	a0,0(s2)
    8000444e:	fffff097          	auipc	ra,0xfffff
    80004452:	750080e7          	jalr	1872(ra) # 80003b9e <iget>
    80004456:	a011                	j	8000445a <dirlookup+0xa0>
  return 0;
    80004458:	4501                	li	a0,0
}
    8000445a:	70e2                	ld	ra,56(sp)
    8000445c:	7442                	ld	s0,48(sp)
    8000445e:	74a2                	ld	s1,40(sp)
    80004460:	7902                	ld	s2,32(sp)
    80004462:	69e2                	ld	s3,24(sp)
    80004464:	6a42                	ld	s4,16(sp)
    80004466:	6121                	addi	sp,sp,64
    80004468:	8082                	ret

000000008000446a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000446a:	711d                	addi	sp,sp,-96
    8000446c:	ec86                	sd	ra,88(sp)
    8000446e:	e8a2                	sd	s0,80(sp)
    80004470:	e4a6                	sd	s1,72(sp)
    80004472:	e0ca                	sd	s2,64(sp)
    80004474:	fc4e                	sd	s3,56(sp)
    80004476:	f852                	sd	s4,48(sp)
    80004478:	f456                	sd	s5,40(sp)
    8000447a:	f05a                	sd	s6,32(sp)
    8000447c:	ec5e                	sd	s7,24(sp)
    8000447e:	e862                	sd	s8,16(sp)
    80004480:	e466                	sd	s9,8(sp)
    80004482:	1080                	addi	s0,sp,96
    80004484:	84aa                	mv	s1,a0
    80004486:	8aae                	mv	s5,a1
    80004488:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000448a:	00054703          	lbu	a4,0(a0)
    8000448e:	02f00793          	li	a5,47
    80004492:	02f70363          	beq	a4,a5,800044b8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	516080e7          	jalr	1302(ra) # 800019ac <myproc>
    8000449e:	15053503          	ld	a0,336(a0)
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	9f6080e7          	jalr	-1546(ra) # 80003e98 <idup>
    800044aa:	89aa                	mv	s3,a0
  while(*path == '/')
    800044ac:	02f00913          	li	s2,47
  len = path - s;
    800044b0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800044b2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044b4:	4b85                	li	s7,1
    800044b6:	a865                	j	8000456e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044b8:	4585                	li	a1,1
    800044ba:	4505                	li	a0,1
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	6e2080e7          	jalr	1762(ra) # 80003b9e <iget>
    800044c4:	89aa                	mv	s3,a0
    800044c6:	b7dd                	j	800044ac <namex+0x42>
      iunlockput(ip);
    800044c8:	854e                	mv	a0,s3
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	c6e080e7          	jalr	-914(ra) # 80004138 <iunlockput>
      return 0;
    800044d2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044d4:	854e                	mv	a0,s3
    800044d6:	60e6                	ld	ra,88(sp)
    800044d8:	6446                	ld	s0,80(sp)
    800044da:	64a6                	ld	s1,72(sp)
    800044dc:	6906                	ld	s2,64(sp)
    800044de:	79e2                	ld	s3,56(sp)
    800044e0:	7a42                	ld	s4,48(sp)
    800044e2:	7aa2                	ld	s5,40(sp)
    800044e4:	7b02                	ld	s6,32(sp)
    800044e6:	6be2                	ld	s7,24(sp)
    800044e8:	6c42                	ld	s8,16(sp)
    800044ea:	6ca2                	ld	s9,8(sp)
    800044ec:	6125                	addi	sp,sp,96
    800044ee:	8082                	ret
      iunlock(ip);
    800044f0:	854e                	mv	a0,s3
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	aa6080e7          	jalr	-1370(ra) # 80003f98 <iunlock>
      return ip;
    800044fa:	bfe9                	j	800044d4 <namex+0x6a>
      iunlockput(ip);
    800044fc:	854e                	mv	a0,s3
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	c3a080e7          	jalr	-966(ra) # 80004138 <iunlockput>
      return 0;
    80004506:	89e6                	mv	s3,s9
    80004508:	b7f1                	j	800044d4 <namex+0x6a>
  len = path - s;
    8000450a:	40b48633          	sub	a2,s1,a1
    8000450e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004512:	099c5463          	bge	s8,s9,8000459a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004516:	4639                	li	a2,14
    80004518:	8552                	mv	a0,s4
    8000451a:	ffffd097          	auipc	ra,0xffffd
    8000451e:	814080e7          	jalr	-2028(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004522:	0004c783          	lbu	a5,0(s1)
    80004526:	01279763          	bne	a5,s2,80004534 <namex+0xca>
    path++;
    8000452a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000452c:	0004c783          	lbu	a5,0(s1)
    80004530:	ff278de3          	beq	a5,s2,8000452a <namex+0xc0>
    ilock(ip);
    80004534:	854e                	mv	a0,s3
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	9a0080e7          	jalr	-1632(ra) # 80003ed6 <ilock>
    if(ip->type != T_DIR){
    8000453e:	04499783          	lh	a5,68(s3)
    80004542:	f97793e3          	bne	a5,s7,800044c8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004546:	000a8563          	beqz	s5,80004550 <namex+0xe6>
    8000454a:	0004c783          	lbu	a5,0(s1)
    8000454e:	d3cd                	beqz	a5,800044f0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004550:	865a                	mv	a2,s6
    80004552:	85d2                	mv	a1,s4
    80004554:	854e                	mv	a0,s3
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	e64080e7          	jalr	-412(ra) # 800043ba <dirlookup>
    8000455e:	8caa                	mv	s9,a0
    80004560:	dd51                	beqz	a0,800044fc <namex+0x92>
    iunlockput(ip);
    80004562:	854e                	mv	a0,s3
    80004564:	00000097          	auipc	ra,0x0
    80004568:	bd4080e7          	jalr	-1068(ra) # 80004138 <iunlockput>
    ip = next;
    8000456c:	89e6                	mv	s3,s9
  while(*path == '/')
    8000456e:	0004c783          	lbu	a5,0(s1)
    80004572:	05279763          	bne	a5,s2,800045c0 <namex+0x156>
    path++;
    80004576:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004578:	0004c783          	lbu	a5,0(s1)
    8000457c:	ff278de3          	beq	a5,s2,80004576 <namex+0x10c>
  if(*path == 0)
    80004580:	c79d                	beqz	a5,800045ae <namex+0x144>
    path++;
    80004582:	85a6                	mv	a1,s1
  len = path - s;
    80004584:	8cda                	mv	s9,s6
    80004586:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004588:	01278963          	beq	a5,s2,8000459a <namex+0x130>
    8000458c:	dfbd                	beqz	a5,8000450a <namex+0xa0>
    path++;
    8000458e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004590:	0004c783          	lbu	a5,0(s1)
    80004594:	ff279ce3          	bne	a5,s2,8000458c <namex+0x122>
    80004598:	bf8d                	j	8000450a <namex+0xa0>
    memmove(name, s, len);
    8000459a:	2601                	sext.w	a2,a2
    8000459c:	8552                	mv	a0,s4
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	790080e7          	jalr	1936(ra) # 80000d2e <memmove>
    name[len] = 0;
    800045a6:	9cd2                	add	s9,s9,s4
    800045a8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045ac:	bf9d                	j	80004522 <namex+0xb8>
  if(nameiparent){
    800045ae:	f20a83e3          	beqz	s5,800044d4 <namex+0x6a>
    iput(ip);
    800045b2:	854e                	mv	a0,s3
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	adc080e7          	jalr	-1316(ra) # 80004090 <iput>
    return 0;
    800045bc:	4981                	li	s3,0
    800045be:	bf19                	j	800044d4 <namex+0x6a>
  if(*path == 0)
    800045c0:	d7fd                	beqz	a5,800045ae <namex+0x144>
  while(*path != '/' && *path != 0)
    800045c2:	0004c783          	lbu	a5,0(s1)
    800045c6:	85a6                	mv	a1,s1
    800045c8:	b7d1                	j	8000458c <namex+0x122>

00000000800045ca <dirlink>:
{
    800045ca:	7139                	addi	sp,sp,-64
    800045cc:	fc06                	sd	ra,56(sp)
    800045ce:	f822                	sd	s0,48(sp)
    800045d0:	f426                	sd	s1,40(sp)
    800045d2:	f04a                	sd	s2,32(sp)
    800045d4:	ec4e                	sd	s3,24(sp)
    800045d6:	e852                	sd	s4,16(sp)
    800045d8:	0080                	addi	s0,sp,64
    800045da:	892a                	mv	s2,a0
    800045dc:	8a2e                	mv	s4,a1
    800045de:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045e0:	4601                	li	a2,0
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	dd8080e7          	jalr	-552(ra) # 800043ba <dirlookup>
    800045ea:	e93d                	bnez	a0,80004660 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045ec:	04c92483          	lw	s1,76(s2)
    800045f0:	c49d                	beqz	s1,8000461e <dirlink+0x54>
    800045f2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045f4:	4741                	li	a4,16
    800045f6:	86a6                	mv	a3,s1
    800045f8:	fc040613          	addi	a2,s0,-64
    800045fc:	4581                	li	a1,0
    800045fe:	854a                	mv	a0,s2
    80004600:	00000097          	auipc	ra,0x0
    80004604:	b8a080e7          	jalr	-1142(ra) # 8000418a <readi>
    80004608:	47c1                	li	a5,16
    8000460a:	06f51163          	bne	a0,a5,8000466c <dirlink+0xa2>
    if(de.inum == 0)
    8000460e:	fc045783          	lhu	a5,-64(s0)
    80004612:	c791                	beqz	a5,8000461e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004614:	24c1                	addiw	s1,s1,16
    80004616:	04c92783          	lw	a5,76(s2)
    8000461a:	fcf4ede3          	bltu	s1,a5,800045f4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000461e:	4639                	li	a2,14
    80004620:	85d2                	mv	a1,s4
    80004622:	fc240513          	addi	a0,s0,-62
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	7b8080e7          	jalr	1976(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000462e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004632:	4741                	li	a4,16
    80004634:	86a6                	mv	a3,s1
    80004636:	fc040613          	addi	a2,s0,-64
    8000463a:	4581                	li	a1,0
    8000463c:	854a                	mv	a0,s2
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	c44080e7          	jalr	-956(ra) # 80004282 <writei>
    80004646:	1541                	addi	a0,a0,-16
    80004648:	00a03533          	snez	a0,a0
    8000464c:	40a00533          	neg	a0,a0
}
    80004650:	70e2                	ld	ra,56(sp)
    80004652:	7442                	ld	s0,48(sp)
    80004654:	74a2                	ld	s1,40(sp)
    80004656:	7902                	ld	s2,32(sp)
    80004658:	69e2                	ld	s3,24(sp)
    8000465a:	6a42                	ld	s4,16(sp)
    8000465c:	6121                	addi	sp,sp,64
    8000465e:	8082                	ret
    iput(ip);
    80004660:	00000097          	auipc	ra,0x0
    80004664:	a30080e7          	jalr	-1488(ra) # 80004090 <iput>
    return -1;
    80004668:	557d                	li	a0,-1
    8000466a:	b7dd                	j	80004650 <dirlink+0x86>
      panic("dirlink read");
    8000466c:	00004517          	auipc	a0,0x4
    80004670:	00c50513          	addi	a0,a0,12 # 80008678 <syscalls+0x1f0>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>

000000008000467c <namei>:

struct inode*
namei(char *path)
{
    8000467c:	1101                	addi	sp,sp,-32
    8000467e:	ec06                	sd	ra,24(sp)
    80004680:	e822                	sd	s0,16(sp)
    80004682:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004684:	fe040613          	addi	a2,s0,-32
    80004688:	4581                	li	a1,0
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	de0080e7          	jalr	-544(ra) # 8000446a <namex>
}
    80004692:	60e2                	ld	ra,24(sp)
    80004694:	6442                	ld	s0,16(sp)
    80004696:	6105                	addi	sp,sp,32
    80004698:	8082                	ret

000000008000469a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000469a:	1141                	addi	sp,sp,-16
    8000469c:	e406                	sd	ra,8(sp)
    8000469e:	e022                	sd	s0,0(sp)
    800046a0:	0800                	addi	s0,sp,16
    800046a2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046a4:	4585                	li	a1,1
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	dc4080e7          	jalr	-572(ra) # 8000446a <namex>
}
    800046ae:	60a2                	ld	ra,8(sp)
    800046b0:	6402                	ld	s0,0(sp)
    800046b2:	0141                	addi	sp,sp,16
    800046b4:	8082                	ret

00000000800046b6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046b6:	1101                	addi	sp,sp,-32
    800046b8:	ec06                	sd	ra,24(sp)
    800046ba:	e822                	sd	s0,16(sp)
    800046bc:	e426                	sd	s1,8(sp)
    800046be:	e04a                	sd	s2,0(sp)
    800046c0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046c2:	00022917          	auipc	s2,0x22
    800046c6:	aae90913          	addi	s2,s2,-1362 # 80026170 <log>
    800046ca:	01892583          	lw	a1,24(s2)
    800046ce:	02892503          	lw	a0,40(s2)
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	fea080e7          	jalr	-22(ra) # 800036bc <bread>
    800046da:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046dc:	02c92683          	lw	a3,44(s2)
    800046e0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046e2:	02d05763          	blez	a3,80004710 <write_head+0x5a>
    800046e6:	00022797          	auipc	a5,0x22
    800046ea:	aba78793          	addi	a5,a5,-1350 # 800261a0 <log+0x30>
    800046ee:	05c50713          	addi	a4,a0,92
    800046f2:	36fd                	addiw	a3,a3,-1
    800046f4:	1682                	slli	a3,a3,0x20
    800046f6:	9281                	srli	a3,a3,0x20
    800046f8:	068a                	slli	a3,a3,0x2
    800046fa:	00022617          	auipc	a2,0x22
    800046fe:	aaa60613          	addi	a2,a2,-1366 # 800261a4 <log+0x34>
    80004702:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004704:	4390                	lw	a2,0(a5)
    80004706:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004708:	0791                	addi	a5,a5,4
    8000470a:	0711                	addi	a4,a4,4
    8000470c:	fed79ce3          	bne	a5,a3,80004704 <write_head+0x4e>
  }
  bwrite(buf);
    80004710:	8526                	mv	a0,s1
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	09c080e7          	jalr	156(ra) # 800037ae <bwrite>
  brelse(buf);
    8000471a:	8526                	mv	a0,s1
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	0d0080e7          	jalr	208(ra) # 800037ec <brelse>
}
    80004724:	60e2                	ld	ra,24(sp)
    80004726:	6442                	ld	s0,16(sp)
    80004728:	64a2                	ld	s1,8(sp)
    8000472a:	6902                	ld	s2,0(sp)
    8000472c:	6105                	addi	sp,sp,32
    8000472e:	8082                	ret

0000000080004730 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004730:	00022797          	auipc	a5,0x22
    80004734:	a6c7a783          	lw	a5,-1428(a5) # 8002619c <log+0x2c>
    80004738:	0af05d63          	blez	a5,800047f2 <install_trans+0xc2>
{
    8000473c:	7139                	addi	sp,sp,-64
    8000473e:	fc06                	sd	ra,56(sp)
    80004740:	f822                	sd	s0,48(sp)
    80004742:	f426                	sd	s1,40(sp)
    80004744:	f04a                	sd	s2,32(sp)
    80004746:	ec4e                	sd	s3,24(sp)
    80004748:	e852                	sd	s4,16(sp)
    8000474a:	e456                	sd	s5,8(sp)
    8000474c:	e05a                	sd	s6,0(sp)
    8000474e:	0080                	addi	s0,sp,64
    80004750:	8b2a                	mv	s6,a0
    80004752:	00022a97          	auipc	s5,0x22
    80004756:	a4ea8a93          	addi	s5,s5,-1458 # 800261a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000475a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000475c:	00022997          	auipc	s3,0x22
    80004760:	a1498993          	addi	s3,s3,-1516 # 80026170 <log>
    80004764:	a00d                	j	80004786 <install_trans+0x56>
    brelse(lbuf);
    80004766:	854a                	mv	a0,s2
    80004768:	fffff097          	auipc	ra,0xfffff
    8000476c:	084080e7          	jalr	132(ra) # 800037ec <brelse>
    brelse(dbuf);
    80004770:	8526                	mv	a0,s1
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	07a080e7          	jalr	122(ra) # 800037ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000477a:	2a05                	addiw	s4,s4,1
    8000477c:	0a91                	addi	s5,s5,4
    8000477e:	02c9a783          	lw	a5,44(s3)
    80004782:	04fa5e63          	bge	s4,a5,800047de <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004786:	0189a583          	lw	a1,24(s3)
    8000478a:	014585bb          	addw	a1,a1,s4
    8000478e:	2585                	addiw	a1,a1,1
    80004790:	0289a503          	lw	a0,40(s3)
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	f28080e7          	jalr	-216(ra) # 800036bc <bread>
    8000479c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000479e:	000aa583          	lw	a1,0(s5)
    800047a2:	0289a503          	lw	a0,40(s3)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	f16080e7          	jalr	-234(ra) # 800036bc <bread>
    800047ae:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047b0:	40000613          	li	a2,1024
    800047b4:	05890593          	addi	a1,s2,88
    800047b8:	05850513          	addi	a0,a0,88
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	572080e7          	jalr	1394(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800047c4:	8526                	mv	a0,s1
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	fe8080e7          	jalr	-24(ra) # 800037ae <bwrite>
    if(recovering == 0)
    800047ce:	f80b1ce3          	bnez	s6,80004766 <install_trans+0x36>
      bunpin(dbuf);
    800047d2:	8526                	mv	a0,s1
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	0f2080e7          	jalr	242(ra) # 800038c6 <bunpin>
    800047dc:	b769                	j	80004766 <install_trans+0x36>
}
    800047de:	70e2                	ld	ra,56(sp)
    800047e0:	7442                	ld	s0,48(sp)
    800047e2:	74a2                	ld	s1,40(sp)
    800047e4:	7902                	ld	s2,32(sp)
    800047e6:	69e2                	ld	s3,24(sp)
    800047e8:	6a42                	ld	s4,16(sp)
    800047ea:	6aa2                	ld	s5,8(sp)
    800047ec:	6b02                	ld	s6,0(sp)
    800047ee:	6121                	addi	sp,sp,64
    800047f0:	8082                	ret
    800047f2:	8082                	ret

00000000800047f4 <initlog>:
{
    800047f4:	7179                	addi	sp,sp,-48
    800047f6:	f406                	sd	ra,40(sp)
    800047f8:	f022                	sd	s0,32(sp)
    800047fa:	ec26                	sd	s1,24(sp)
    800047fc:	e84a                	sd	s2,16(sp)
    800047fe:	e44e                	sd	s3,8(sp)
    80004800:	1800                	addi	s0,sp,48
    80004802:	892a                	mv	s2,a0
    80004804:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004806:	00022497          	auipc	s1,0x22
    8000480a:	96a48493          	addi	s1,s1,-1686 # 80026170 <log>
    8000480e:	00004597          	auipc	a1,0x4
    80004812:	e7a58593          	addi	a1,a1,-390 # 80008688 <syscalls+0x200>
    80004816:	8526                	mv	a0,s1
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	32e080e7          	jalr	814(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004820:	0149a583          	lw	a1,20(s3)
    80004824:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004826:	0109a783          	lw	a5,16(s3)
    8000482a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000482c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004830:	854a                	mv	a0,s2
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	e8a080e7          	jalr	-374(ra) # 800036bc <bread>
  log.lh.n = lh->n;
    8000483a:	4d34                	lw	a3,88(a0)
    8000483c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000483e:	02d05563          	blez	a3,80004868 <initlog+0x74>
    80004842:	05c50793          	addi	a5,a0,92
    80004846:	00022717          	auipc	a4,0x22
    8000484a:	95a70713          	addi	a4,a4,-1702 # 800261a0 <log+0x30>
    8000484e:	36fd                	addiw	a3,a3,-1
    80004850:	1682                	slli	a3,a3,0x20
    80004852:	9281                	srli	a3,a3,0x20
    80004854:	068a                	slli	a3,a3,0x2
    80004856:	06050613          	addi	a2,a0,96
    8000485a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000485c:	4390                	lw	a2,0(a5)
    8000485e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004860:	0791                	addi	a5,a5,4
    80004862:	0711                	addi	a4,a4,4
    80004864:	fed79ce3          	bne	a5,a3,8000485c <initlog+0x68>
  brelse(buf);
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	f84080e7          	jalr	-124(ra) # 800037ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004870:	4505                	li	a0,1
    80004872:	00000097          	auipc	ra,0x0
    80004876:	ebe080e7          	jalr	-322(ra) # 80004730 <install_trans>
  log.lh.n = 0;
    8000487a:	00022797          	auipc	a5,0x22
    8000487e:	9207a123          	sw	zero,-1758(a5) # 8002619c <log+0x2c>
  write_head(); // clear the log
    80004882:	00000097          	auipc	ra,0x0
    80004886:	e34080e7          	jalr	-460(ra) # 800046b6 <write_head>
}
    8000488a:	70a2                	ld	ra,40(sp)
    8000488c:	7402                	ld	s0,32(sp)
    8000488e:	64e2                	ld	s1,24(sp)
    80004890:	6942                	ld	s2,16(sp)
    80004892:	69a2                	ld	s3,8(sp)
    80004894:	6145                	addi	sp,sp,48
    80004896:	8082                	ret

0000000080004898 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004898:	1101                	addi	sp,sp,-32
    8000489a:	ec06                	sd	ra,24(sp)
    8000489c:	e822                	sd	s0,16(sp)
    8000489e:	e426                	sd	s1,8(sp)
    800048a0:	e04a                	sd	s2,0(sp)
    800048a2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048a4:	00022517          	auipc	a0,0x22
    800048a8:	8cc50513          	addi	a0,a0,-1844 # 80026170 <log>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	32a080e7          	jalr	810(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800048b4:	00022497          	auipc	s1,0x22
    800048b8:	8bc48493          	addi	s1,s1,-1860 # 80026170 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048bc:	4979                	li	s2,30
    800048be:	a039                	j	800048cc <begin_op+0x34>
      sleep(&log, &log.lock);
    800048c0:	85a6                	mv	a1,s1
    800048c2:	8526                	mv	a0,s1
    800048c4:	ffffe097          	auipc	ra,0xffffe
    800048c8:	b1c080e7          	jalr	-1252(ra) # 800023e0 <sleep>
    if(log.committing){
    800048cc:	50dc                	lw	a5,36(s1)
    800048ce:	fbed                	bnez	a5,800048c0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048d0:	509c                	lw	a5,32(s1)
    800048d2:	0017871b          	addiw	a4,a5,1
    800048d6:	0007069b          	sext.w	a3,a4
    800048da:	0027179b          	slliw	a5,a4,0x2
    800048de:	9fb9                	addw	a5,a5,a4
    800048e0:	0017979b          	slliw	a5,a5,0x1
    800048e4:	54d8                	lw	a4,44(s1)
    800048e6:	9fb9                	addw	a5,a5,a4
    800048e8:	00f95963          	bge	s2,a5,800048fa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048ec:	85a6                	mv	a1,s1
    800048ee:	8526                	mv	a0,s1
    800048f0:	ffffe097          	auipc	ra,0xffffe
    800048f4:	af0080e7          	jalr	-1296(ra) # 800023e0 <sleep>
    800048f8:	bfd1                	j	800048cc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048fa:	00022517          	auipc	a0,0x22
    800048fe:	87650513          	addi	a0,a0,-1930 # 80026170 <log>
    80004902:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	386080e7          	jalr	902(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000490c:	60e2                	ld	ra,24(sp)
    8000490e:	6442                	ld	s0,16(sp)
    80004910:	64a2                	ld	s1,8(sp)
    80004912:	6902                	ld	s2,0(sp)
    80004914:	6105                	addi	sp,sp,32
    80004916:	8082                	ret

0000000080004918 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004918:	7139                	addi	sp,sp,-64
    8000491a:	fc06                	sd	ra,56(sp)
    8000491c:	f822                	sd	s0,48(sp)
    8000491e:	f426                	sd	s1,40(sp)
    80004920:	f04a                	sd	s2,32(sp)
    80004922:	ec4e                	sd	s3,24(sp)
    80004924:	e852                	sd	s4,16(sp)
    80004926:	e456                	sd	s5,8(sp)
    80004928:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000492a:	00022497          	auipc	s1,0x22
    8000492e:	84648493          	addi	s1,s1,-1978 # 80026170 <log>
    80004932:	8526                	mv	a0,s1
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	2a2080e7          	jalr	674(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000493c:	509c                	lw	a5,32(s1)
    8000493e:	37fd                	addiw	a5,a5,-1
    80004940:	0007891b          	sext.w	s2,a5
    80004944:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004946:	50dc                	lw	a5,36(s1)
    80004948:	e7b9                	bnez	a5,80004996 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000494a:	04091e63          	bnez	s2,800049a6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000494e:	00022497          	auipc	s1,0x22
    80004952:	82248493          	addi	s1,s1,-2014 # 80026170 <log>
    80004956:	4785                	li	a5,1
    80004958:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000495a:	8526                	mv	a0,s1
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	32e080e7          	jalr	814(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004964:	54dc                	lw	a5,44(s1)
    80004966:	06f04763          	bgtz	a5,800049d4 <end_op+0xbc>
    acquire(&log.lock);
    8000496a:	00022497          	auipc	s1,0x22
    8000496e:	80648493          	addi	s1,s1,-2042 # 80026170 <log>
    80004972:	8526                	mv	a0,s1
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	262080e7          	jalr	610(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000497c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004980:	8526                	mv	a0,s1
    80004982:	ffffe097          	auipc	ra,0xffffe
    80004986:	ac2080e7          	jalr	-1342(ra) # 80002444 <wakeup>
    release(&log.lock);
    8000498a:	8526                	mv	a0,s1
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	2fe080e7          	jalr	766(ra) # 80000c8a <release>
}
    80004994:	a03d                	j	800049c2 <end_op+0xaa>
    panic("log.committing");
    80004996:	00004517          	auipc	a0,0x4
    8000499a:	cfa50513          	addi	a0,a0,-774 # 80008690 <syscalls+0x208>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	ba0080e7          	jalr	-1120(ra) # 8000053e <panic>
    wakeup(&log);
    800049a6:	00021497          	auipc	s1,0x21
    800049aa:	7ca48493          	addi	s1,s1,1994 # 80026170 <log>
    800049ae:	8526                	mv	a0,s1
    800049b0:	ffffe097          	auipc	ra,0xffffe
    800049b4:	a94080e7          	jalr	-1388(ra) # 80002444 <wakeup>
  release(&log.lock);
    800049b8:	8526                	mv	a0,s1
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	2d0080e7          	jalr	720(ra) # 80000c8a <release>
}
    800049c2:	70e2                	ld	ra,56(sp)
    800049c4:	7442                	ld	s0,48(sp)
    800049c6:	74a2                	ld	s1,40(sp)
    800049c8:	7902                	ld	s2,32(sp)
    800049ca:	69e2                	ld	s3,24(sp)
    800049cc:	6a42                	ld	s4,16(sp)
    800049ce:	6aa2                	ld	s5,8(sp)
    800049d0:	6121                	addi	sp,sp,64
    800049d2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800049d4:	00021a97          	auipc	s5,0x21
    800049d8:	7cca8a93          	addi	s5,s5,1996 # 800261a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049dc:	00021a17          	auipc	s4,0x21
    800049e0:	794a0a13          	addi	s4,s4,1940 # 80026170 <log>
    800049e4:	018a2583          	lw	a1,24(s4)
    800049e8:	012585bb          	addw	a1,a1,s2
    800049ec:	2585                	addiw	a1,a1,1
    800049ee:	028a2503          	lw	a0,40(s4)
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	cca080e7          	jalr	-822(ra) # 800036bc <bread>
    800049fa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049fc:	000aa583          	lw	a1,0(s5)
    80004a00:	028a2503          	lw	a0,40(s4)
    80004a04:	fffff097          	auipc	ra,0xfffff
    80004a08:	cb8080e7          	jalr	-840(ra) # 800036bc <bread>
    80004a0c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a0e:	40000613          	li	a2,1024
    80004a12:	05850593          	addi	a1,a0,88
    80004a16:	05848513          	addi	a0,s1,88
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	314080e7          	jalr	788(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004a22:	8526                	mv	a0,s1
    80004a24:	fffff097          	auipc	ra,0xfffff
    80004a28:	d8a080e7          	jalr	-630(ra) # 800037ae <bwrite>
    brelse(from);
    80004a2c:	854e                	mv	a0,s3
    80004a2e:	fffff097          	auipc	ra,0xfffff
    80004a32:	dbe080e7          	jalr	-578(ra) # 800037ec <brelse>
    brelse(to);
    80004a36:	8526                	mv	a0,s1
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	db4080e7          	jalr	-588(ra) # 800037ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a40:	2905                	addiw	s2,s2,1
    80004a42:	0a91                	addi	s5,s5,4
    80004a44:	02ca2783          	lw	a5,44(s4)
    80004a48:	f8f94ee3          	blt	s2,a5,800049e4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a4c:	00000097          	auipc	ra,0x0
    80004a50:	c6a080e7          	jalr	-918(ra) # 800046b6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a54:	4501                	li	a0,0
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	cda080e7          	jalr	-806(ra) # 80004730 <install_trans>
    log.lh.n = 0;
    80004a5e:	00021797          	auipc	a5,0x21
    80004a62:	7207af23          	sw	zero,1854(a5) # 8002619c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	c50080e7          	jalr	-944(ra) # 800046b6 <write_head>
    80004a6e:	bdf5                	j	8000496a <end_op+0x52>

0000000080004a70 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a70:	1101                	addi	sp,sp,-32
    80004a72:	ec06                	sd	ra,24(sp)
    80004a74:	e822                	sd	s0,16(sp)
    80004a76:	e426                	sd	s1,8(sp)
    80004a78:	e04a                	sd	s2,0(sp)
    80004a7a:	1000                	addi	s0,sp,32
    80004a7c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a7e:	00021917          	auipc	s2,0x21
    80004a82:	6f290913          	addi	s2,s2,1778 # 80026170 <log>
    80004a86:	854a                	mv	a0,s2
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	14e080e7          	jalr	334(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a90:	02c92603          	lw	a2,44(s2)
    80004a94:	47f5                	li	a5,29
    80004a96:	06c7c563          	blt	a5,a2,80004b00 <log_write+0x90>
    80004a9a:	00021797          	auipc	a5,0x21
    80004a9e:	6f27a783          	lw	a5,1778(a5) # 8002618c <log+0x1c>
    80004aa2:	37fd                	addiw	a5,a5,-1
    80004aa4:	04f65e63          	bge	a2,a5,80004b00 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004aa8:	00021797          	auipc	a5,0x21
    80004aac:	6e87a783          	lw	a5,1768(a5) # 80026190 <log+0x20>
    80004ab0:	06f05063          	blez	a5,80004b10 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ab4:	4781                	li	a5,0
    80004ab6:	06c05563          	blez	a2,80004b20 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004aba:	44cc                	lw	a1,12(s1)
    80004abc:	00021717          	auipc	a4,0x21
    80004ac0:	6e470713          	addi	a4,a4,1764 # 800261a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ac4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ac6:	4314                	lw	a3,0(a4)
    80004ac8:	04b68c63          	beq	a3,a1,80004b20 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004acc:	2785                	addiw	a5,a5,1
    80004ace:	0711                	addi	a4,a4,4
    80004ad0:	fef61be3          	bne	a2,a5,80004ac6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ad4:	0621                	addi	a2,a2,8
    80004ad6:	060a                	slli	a2,a2,0x2
    80004ad8:	00021797          	auipc	a5,0x21
    80004adc:	69878793          	addi	a5,a5,1688 # 80026170 <log>
    80004ae0:	963e                	add	a2,a2,a5
    80004ae2:	44dc                	lw	a5,12(s1)
    80004ae4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	fffff097          	auipc	ra,0xfffff
    80004aec:	da2080e7          	jalr	-606(ra) # 8000388a <bpin>
    log.lh.n++;
    80004af0:	00021717          	auipc	a4,0x21
    80004af4:	68070713          	addi	a4,a4,1664 # 80026170 <log>
    80004af8:	575c                	lw	a5,44(a4)
    80004afa:	2785                	addiw	a5,a5,1
    80004afc:	d75c                	sw	a5,44(a4)
    80004afe:	a835                	j	80004b3a <log_write+0xca>
    panic("too big a transaction");
    80004b00:	00004517          	auipc	a0,0x4
    80004b04:	ba050513          	addi	a0,a0,-1120 # 800086a0 <syscalls+0x218>
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	a36080e7          	jalr	-1482(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004b10:	00004517          	auipc	a0,0x4
    80004b14:	ba850513          	addi	a0,a0,-1112 # 800086b8 <syscalls+0x230>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	a26080e7          	jalr	-1498(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b20:	00878713          	addi	a4,a5,8
    80004b24:	00271693          	slli	a3,a4,0x2
    80004b28:	00021717          	auipc	a4,0x21
    80004b2c:	64870713          	addi	a4,a4,1608 # 80026170 <log>
    80004b30:	9736                	add	a4,a4,a3
    80004b32:	44d4                	lw	a3,12(s1)
    80004b34:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b36:	faf608e3          	beq	a2,a5,80004ae6 <log_write+0x76>
  }
  release(&log.lock);
    80004b3a:	00021517          	auipc	a0,0x21
    80004b3e:	63650513          	addi	a0,a0,1590 # 80026170 <log>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	148080e7          	jalr	328(ra) # 80000c8a <release>
}
    80004b4a:	60e2                	ld	ra,24(sp)
    80004b4c:	6442                	ld	s0,16(sp)
    80004b4e:	64a2                	ld	s1,8(sp)
    80004b50:	6902                	ld	s2,0(sp)
    80004b52:	6105                	addi	sp,sp,32
    80004b54:	8082                	ret

0000000080004b56 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b56:	1101                	addi	sp,sp,-32
    80004b58:	ec06                	sd	ra,24(sp)
    80004b5a:	e822                	sd	s0,16(sp)
    80004b5c:	e426                	sd	s1,8(sp)
    80004b5e:	e04a                	sd	s2,0(sp)
    80004b60:	1000                	addi	s0,sp,32
    80004b62:	84aa                	mv	s1,a0
    80004b64:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b66:	00004597          	auipc	a1,0x4
    80004b6a:	b7258593          	addi	a1,a1,-1166 # 800086d8 <syscalls+0x250>
    80004b6e:	0521                	addi	a0,a0,8
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	fd6080e7          	jalr	-42(ra) # 80000b46 <initlock>
  lk->name = name;
    80004b78:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b7c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b80:	0204a423          	sw	zero,40(s1)
}
    80004b84:	60e2                	ld	ra,24(sp)
    80004b86:	6442                	ld	s0,16(sp)
    80004b88:	64a2                	ld	s1,8(sp)
    80004b8a:	6902                	ld	s2,0(sp)
    80004b8c:	6105                	addi	sp,sp,32
    80004b8e:	8082                	ret

0000000080004b90 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b90:	1101                	addi	sp,sp,-32
    80004b92:	ec06                	sd	ra,24(sp)
    80004b94:	e822                	sd	s0,16(sp)
    80004b96:	e426                	sd	s1,8(sp)
    80004b98:	e04a                	sd	s2,0(sp)
    80004b9a:	1000                	addi	s0,sp,32
    80004b9c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b9e:	00850913          	addi	s2,a0,8
    80004ba2:	854a                	mv	a0,s2
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	032080e7          	jalr	50(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004bac:	409c                	lw	a5,0(s1)
    80004bae:	cb89                	beqz	a5,80004bc0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bb0:	85ca                	mv	a1,s2
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffe097          	auipc	ra,0xffffe
    80004bb8:	82c080e7          	jalr	-2004(ra) # 800023e0 <sleep>
  while (lk->locked) {
    80004bbc:	409c                	lw	a5,0(s1)
    80004bbe:	fbed                	bnez	a5,80004bb0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bc0:	4785                	li	a5,1
    80004bc2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bc4:	ffffd097          	auipc	ra,0xffffd
    80004bc8:	de8080e7          	jalr	-536(ra) # 800019ac <myproc>
    80004bcc:	591c                	lw	a5,48(a0)
    80004bce:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bd0:	854a                	mv	a0,s2
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	0b8080e7          	jalr	184(ra) # 80000c8a <release>
}
    80004bda:	60e2                	ld	ra,24(sp)
    80004bdc:	6442                	ld	s0,16(sp)
    80004bde:	64a2                	ld	s1,8(sp)
    80004be0:	6902                	ld	s2,0(sp)
    80004be2:	6105                	addi	sp,sp,32
    80004be4:	8082                	ret

0000000080004be6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004be6:	1101                	addi	sp,sp,-32
    80004be8:	ec06                	sd	ra,24(sp)
    80004bea:	e822                	sd	s0,16(sp)
    80004bec:	e426                	sd	s1,8(sp)
    80004bee:	e04a                	sd	s2,0(sp)
    80004bf0:	1000                	addi	s0,sp,32
    80004bf2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bf4:	00850913          	addi	s2,a0,8
    80004bf8:	854a                	mv	a0,s2
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	fdc080e7          	jalr	-36(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004c02:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c06:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c0a:	8526                	mv	a0,s1
    80004c0c:	ffffe097          	auipc	ra,0xffffe
    80004c10:	838080e7          	jalr	-1992(ra) # 80002444 <wakeup>
  release(&lk->lk);
    80004c14:	854a                	mv	a0,s2
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	074080e7          	jalr	116(ra) # 80000c8a <release>
}
    80004c1e:	60e2                	ld	ra,24(sp)
    80004c20:	6442                	ld	s0,16(sp)
    80004c22:	64a2                	ld	s1,8(sp)
    80004c24:	6902                	ld	s2,0(sp)
    80004c26:	6105                	addi	sp,sp,32
    80004c28:	8082                	ret

0000000080004c2a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c2a:	7179                	addi	sp,sp,-48
    80004c2c:	f406                	sd	ra,40(sp)
    80004c2e:	f022                	sd	s0,32(sp)
    80004c30:	ec26                	sd	s1,24(sp)
    80004c32:	e84a                	sd	s2,16(sp)
    80004c34:	e44e                	sd	s3,8(sp)
    80004c36:	1800                	addi	s0,sp,48
    80004c38:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c3a:	00850913          	addi	s2,a0,8
    80004c3e:	854a                	mv	a0,s2
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	f96080e7          	jalr	-106(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c48:	409c                	lw	a5,0(s1)
    80004c4a:	ef99                	bnez	a5,80004c68 <holdingsleep+0x3e>
    80004c4c:	4481                	li	s1,0
  release(&lk->lk);
    80004c4e:	854a                	mv	a0,s2
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	03a080e7          	jalr	58(ra) # 80000c8a <release>
  return r;
}
    80004c58:	8526                	mv	a0,s1
    80004c5a:	70a2                	ld	ra,40(sp)
    80004c5c:	7402                	ld	s0,32(sp)
    80004c5e:	64e2                	ld	s1,24(sp)
    80004c60:	6942                	ld	s2,16(sp)
    80004c62:	69a2                	ld	s3,8(sp)
    80004c64:	6145                	addi	sp,sp,48
    80004c66:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c68:	0284a983          	lw	s3,40(s1)
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	d40080e7          	jalr	-704(ra) # 800019ac <myproc>
    80004c74:	5904                	lw	s1,48(a0)
    80004c76:	413484b3          	sub	s1,s1,s3
    80004c7a:	0014b493          	seqz	s1,s1
    80004c7e:	bfc1                	j	80004c4e <holdingsleep+0x24>

0000000080004c80 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c80:	1141                	addi	sp,sp,-16
    80004c82:	e406                	sd	ra,8(sp)
    80004c84:	e022                	sd	s0,0(sp)
    80004c86:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c88:	00004597          	auipc	a1,0x4
    80004c8c:	a6058593          	addi	a1,a1,-1440 # 800086e8 <syscalls+0x260>
    80004c90:	00021517          	auipc	a0,0x21
    80004c94:	62850513          	addi	a0,a0,1576 # 800262b8 <ftable>
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	eae080e7          	jalr	-338(ra) # 80000b46 <initlock>
}
    80004ca0:	60a2                	ld	ra,8(sp)
    80004ca2:	6402                	ld	s0,0(sp)
    80004ca4:	0141                	addi	sp,sp,16
    80004ca6:	8082                	ret

0000000080004ca8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ca8:	1101                	addi	sp,sp,-32
    80004caa:	ec06                	sd	ra,24(sp)
    80004cac:	e822                	sd	s0,16(sp)
    80004cae:	e426                	sd	s1,8(sp)
    80004cb0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004cb2:	00021517          	auipc	a0,0x21
    80004cb6:	60650513          	addi	a0,a0,1542 # 800262b8 <ftable>
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	f1c080e7          	jalr	-228(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cc2:	00021497          	auipc	s1,0x21
    80004cc6:	60e48493          	addi	s1,s1,1550 # 800262d0 <ftable+0x18>
    80004cca:	00022717          	auipc	a4,0x22
    80004cce:	5a670713          	addi	a4,a4,1446 # 80027270 <disk>
    if(f->ref == 0){
    80004cd2:	40dc                	lw	a5,4(s1)
    80004cd4:	cf99                	beqz	a5,80004cf2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cd6:	02848493          	addi	s1,s1,40
    80004cda:	fee49ce3          	bne	s1,a4,80004cd2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cde:	00021517          	auipc	a0,0x21
    80004ce2:	5da50513          	addi	a0,a0,1498 # 800262b8 <ftable>
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	fa4080e7          	jalr	-92(ra) # 80000c8a <release>
  return 0;
    80004cee:	4481                	li	s1,0
    80004cf0:	a819                	j	80004d06 <filealloc+0x5e>
      f->ref = 1;
    80004cf2:	4785                	li	a5,1
    80004cf4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004cf6:	00021517          	auipc	a0,0x21
    80004cfa:	5c250513          	addi	a0,a0,1474 # 800262b8 <ftable>
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	f8c080e7          	jalr	-116(ra) # 80000c8a <release>
}
    80004d06:	8526                	mv	a0,s1
    80004d08:	60e2                	ld	ra,24(sp)
    80004d0a:	6442                	ld	s0,16(sp)
    80004d0c:	64a2                	ld	s1,8(sp)
    80004d0e:	6105                	addi	sp,sp,32
    80004d10:	8082                	ret

0000000080004d12 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d12:	1101                	addi	sp,sp,-32
    80004d14:	ec06                	sd	ra,24(sp)
    80004d16:	e822                	sd	s0,16(sp)
    80004d18:	e426                	sd	s1,8(sp)
    80004d1a:	1000                	addi	s0,sp,32
    80004d1c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d1e:	00021517          	auipc	a0,0x21
    80004d22:	59a50513          	addi	a0,a0,1434 # 800262b8 <ftable>
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	eb0080e7          	jalr	-336(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004d2e:	40dc                	lw	a5,4(s1)
    80004d30:	02f05263          	blez	a5,80004d54 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d34:	2785                	addiw	a5,a5,1
    80004d36:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d38:	00021517          	auipc	a0,0x21
    80004d3c:	58050513          	addi	a0,a0,1408 # 800262b8 <ftable>
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	f4a080e7          	jalr	-182(ra) # 80000c8a <release>
  return f;
}
    80004d48:	8526                	mv	a0,s1
    80004d4a:	60e2                	ld	ra,24(sp)
    80004d4c:	6442                	ld	s0,16(sp)
    80004d4e:	64a2                	ld	s1,8(sp)
    80004d50:	6105                	addi	sp,sp,32
    80004d52:	8082                	ret
    panic("filedup");
    80004d54:	00004517          	auipc	a0,0x4
    80004d58:	99c50513          	addi	a0,a0,-1636 # 800086f0 <syscalls+0x268>
    80004d5c:	ffffb097          	auipc	ra,0xffffb
    80004d60:	7e2080e7          	jalr	2018(ra) # 8000053e <panic>

0000000080004d64 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d64:	7139                	addi	sp,sp,-64
    80004d66:	fc06                	sd	ra,56(sp)
    80004d68:	f822                	sd	s0,48(sp)
    80004d6a:	f426                	sd	s1,40(sp)
    80004d6c:	f04a                	sd	s2,32(sp)
    80004d6e:	ec4e                	sd	s3,24(sp)
    80004d70:	e852                	sd	s4,16(sp)
    80004d72:	e456                	sd	s5,8(sp)
    80004d74:	0080                	addi	s0,sp,64
    80004d76:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d78:	00021517          	auipc	a0,0x21
    80004d7c:	54050513          	addi	a0,a0,1344 # 800262b8 <ftable>
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	e56080e7          	jalr	-426(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004d88:	40dc                	lw	a5,4(s1)
    80004d8a:	06f05163          	blez	a5,80004dec <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d8e:	37fd                	addiw	a5,a5,-1
    80004d90:	0007871b          	sext.w	a4,a5
    80004d94:	c0dc                	sw	a5,4(s1)
    80004d96:	06e04363          	bgtz	a4,80004dfc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d9a:	0004a903          	lw	s2,0(s1)
    80004d9e:	0094ca83          	lbu	s5,9(s1)
    80004da2:	0104ba03          	ld	s4,16(s1)
    80004da6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004daa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dae:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004db2:	00021517          	auipc	a0,0x21
    80004db6:	50650513          	addi	a0,a0,1286 # 800262b8 <ftable>
    80004dba:	ffffc097          	auipc	ra,0xffffc
    80004dbe:	ed0080e7          	jalr	-304(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004dc2:	4785                	li	a5,1
    80004dc4:	04f90d63          	beq	s2,a5,80004e1e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004dc8:	3979                	addiw	s2,s2,-2
    80004dca:	4785                	li	a5,1
    80004dcc:	0527e063          	bltu	a5,s2,80004e0c <fileclose+0xa8>
    begin_op();
    80004dd0:	00000097          	auipc	ra,0x0
    80004dd4:	ac8080e7          	jalr	-1336(ra) # 80004898 <begin_op>
    iput(ff.ip);
    80004dd8:	854e                	mv	a0,s3
    80004dda:	fffff097          	auipc	ra,0xfffff
    80004dde:	2b6080e7          	jalr	694(ra) # 80004090 <iput>
    end_op();
    80004de2:	00000097          	auipc	ra,0x0
    80004de6:	b36080e7          	jalr	-1226(ra) # 80004918 <end_op>
    80004dea:	a00d                	j	80004e0c <fileclose+0xa8>
    panic("fileclose");
    80004dec:	00004517          	auipc	a0,0x4
    80004df0:	90c50513          	addi	a0,a0,-1780 # 800086f8 <syscalls+0x270>
    80004df4:	ffffb097          	auipc	ra,0xffffb
    80004df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004dfc:	00021517          	auipc	a0,0x21
    80004e00:	4bc50513          	addi	a0,a0,1212 # 800262b8 <ftable>
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	e86080e7          	jalr	-378(ra) # 80000c8a <release>
  }
}
    80004e0c:	70e2                	ld	ra,56(sp)
    80004e0e:	7442                	ld	s0,48(sp)
    80004e10:	74a2                	ld	s1,40(sp)
    80004e12:	7902                	ld	s2,32(sp)
    80004e14:	69e2                	ld	s3,24(sp)
    80004e16:	6a42                	ld	s4,16(sp)
    80004e18:	6aa2                	ld	s5,8(sp)
    80004e1a:	6121                	addi	sp,sp,64
    80004e1c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e1e:	85d6                	mv	a1,s5
    80004e20:	8552                	mv	a0,s4
    80004e22:	00000097          	auipc	ra,0x0
    80004e26:	34c080e7          	jalr	844(ra) # 8000516e <pipeclose>
    80004e2a:	b7cd                	j	80004e0c <fileclose+0xa8>

0000000080004e2c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e2c:	715d                	addi	sp,sp,-80
    80004e2e:	e486                	sd	ra,72(sp)
    80004e30:	e0a2                	sd	s0,64(sp)
    80004e32:	fc26                	sd	s1,56(sp)
    80004e34:	f84a                	sd	s2,48(sp)
    80004e36:	f44e                	sd	s3,40(sp)
    80004e38:	0880                	addi	s0,sp,80
    80004e3a:	84aa                	mv	s1,a0
    80004e3c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	b6e080e7          	jalr	-1170(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e46:	409c                	lw	a5,0(s1)
    80004e48:	37f9                	addiw	a5,a5,-2
    80004e4a:	4705                	li	a4,1
    80004e4c:	04f76763          	bltu	a4,a5,80004e9a <filestat+0x6e>
    80004e50:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e52:	6c88                	ld	a0,24(s1)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	082080e7          	jalr	130(ra) # 80003ed6 <ilock>
    stati(f->ip, &st);
    80004e5c:	fb840593          	addi	a1,s0,-72
    80004e60:	6c88                	ld	a0,24(s1)
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	2fe080e7          	jalr	766(ra) # 80004160 <stati>
    iunlock(f->ip);
    80004e6a:	6c88                	ld	a0,24(s1)
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	12c080e7          	jalr	300(ra) # 80003f98 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e74:	46e1                	li	a3,24
    80004e76:	fb840613          	addi	a2,s0,-72
    80004e7a:	85ce                	mv	a1,s3
    80004e7c:	05093503          	ld	a0,80(s2)
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	7e8080e7          	jalr	2024(ra) # 80001668 <copyout>
    80004e88:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e8c:	60a6                	ld	ra,72(sp)
    80004e8e:	6406                	ld	s0,64(sp)
    80004e90:	74e2                	ld	s1,56(sp)
    80004e92:	7942                	ld	s2,48(sp)
    80004e94:	79a2                	ld	s3,40(sp)
    80004e96:	6161                	addi	sp,sp,80
    80004e98:	8082                	ret
  return -1;
    80004e9a:	557d                	li	a0,-1
    80004e9c:	bfc5                	j	80004e8c <filestat+0x60>

0000000080004e9e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e9e:	7179                	addi	sp,sp,-48
    80004ea0:	f406                	sd	ra,40(sp)
    80004ea2:	f022                	sd	s0,32(sp)
    80004ea4:	ec26                	sd	s1,24(sp)
    80004ea6:	e84a                	sd	s2,16(sp)
    80004ea8:	e44e                	sd	s3,8(sp)
    80004eaa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004eac:	00854783          	lbu	a5,8(a0)
    80004eb0:	c3d5                	beqz	a5,80004f54 <fileread+0xb6>
    80004eb2:	84aa                	mv	s1,a0
    80004eb4:	89ae                	mv	s3,a1
    80004eb6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004eb8:	411c                	lw	a5,0(a0)
    80004eba:	4705                	li	a4,1
    80004ebc:	04e78963          	beq	a5,a4,80004f0e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ec0:	470d                	li	a4,3
    80004ec2:	04e78d63          	beq	a5,a4,80004f1c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ec6:	4709                	li	a4,2
    80004ec8:	06e79e63          	bne	a5,a4,80004f44 <fileread+0xa6>
    ilock(f->ip);
    80004ecc:	6d08                	ld	a0,24(a0)
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	008080e7          	jalr	8(ra) # 80003ed6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ed6:	874a                	mv	a4,s2
    80004ed8:	5094                	lw	a3,32(s1)
    80004eda:	864e                	mv	a2,s3
    80004edc:	4585                	li	a1,1
    80004ede:	6c88                	ld	a0,24(s1)
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	2aa080e7          	jalr	682(ra) # 8000418a <readi>
    80004ee8:	892a                	mv	s2,a0
    80004eea:	00a05563          	blez	a0,80004ef4 <fileread+0x56>
      f->off += r;
    80004eee:	509c                	lw	a5,32(s1)
    80004ef0:	9fa9                	addw	a5,a5,a0
    80004ef2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ef4:	6c88                	ld	a0,24(s1)
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	0a2080e7          	jalr	162(ra) # 80003f98 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004efe:	854a                	mv	a0,s2
    80004f00:	70a2                	ld	ra,40(sp)
    80004f02:	7402                	ld	s0,32(sp)
    80004f04:	64e2                	ld	s1,24(sp)
    80004f06:	6942                	ld	s2,16(sp)
    80004f08:	69a2                	ld	s3,8(sp)
    80004f0a:	6145                	addi	sp,sp,48
    80004f0c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f0e:	6908                	ld	a0,16(a0)
    80004f10:	00000097          	auipc	ra,0x0
    80004f14:	3c6080e7          	jalr	966(ra) # 800052d6 <piperead>
    80004f18:	892a                	mv	s2,a0
    80004f1a:	b7d5                	j	80004efe <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f1c:	02451783          	lh	a5,36(a0)
    80004f20:	03079693          	slli	a3,a5,0x30
    80004f24:	92c1                	srli	a3,a3,0x30
    80004f26:	4725                	li	a4,9
    80004f28:	02d76863          	bltu	a4,a3,80004f58 <fileread+0xba>
    80004f2c:	0792                	slli	a5,a5,0x4
    80004f2e:	00021717          	auipc	a4,0x21
    80004f32:	2ea70713          	addi	a4,a4,746 # 80026218 <devsw>
    80004f36:	97ba                	add	a5,a5,a4
    80004f38:	639c                	ld	a5,0(a5)
    80004f3a:	c38d                	beqz	a5,80004f5c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f3c:	4505                	li	a0,1
    80004f3e:	9782                	jalr	a5
    80004f40:	892a                	mv	s2,a0
    80004f42:	bf75                	j	80004efe <fileread+0x60>
    panic("fileread");
    80004f44:	00003517          	auipc	a0,0x3
    80004f48:	7c450513          	addi	a0,a0,1988 # 80008708 <syscalls+0x280>
    80004f4c:	ffffb097          	auipc	ra,0xffffb
    80004f50:	5f2080e7          	jalr	1522(ra) # 8000053e <panic>
    return -1;
    80004f54:	597d                	li	s2,-1
    80004f56:	b765                	j	80004efe <fileread+0x60>
      return -1;
    80004f58:	597d                	li	s2,-1
    80004f5a:	b755                	j	80004efe <fileread+0x60>
    80004f5c:	597d                	li	s2,-1
    80004f5e:	b745                	j	80004efe <fileread+0x60>

0000000080004f60 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f60:	715d                	addi	sp,sp,-80
    80004f62:	e486                	sd	ra,72(sp)
    80004f64:	e0a2                	sd	s0,64(sp)
    80004f66:	fc26                	sd	s1,56(sp)
    80004f68:	f84a                	sd	s2,48(sp)
    80004f6a:	f44e                	sd	s3,40(sp)
    80004f6c:	f052                	sd	s4,32(sp)
    80004f6e:	ec56                	sd	s5,24(sp)
    80004f70:	e85a                	sd	s6,16(sp)
    80004f72:	e45e                	sd	s7,8(sp)
    80004f74:	e062                	sd	s8,0(sp)
    80004f76:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f78:	00954783          	lbu	a5,9(a0)
    80004f7c:	10078663          	beqz	a5,80005088 <filewrite+0x128>
    80004f80:	892a                	mv	s2,a0
    80004f82:	8aae                	mv	s5,a1
    80004f84:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f86:	411c                	lw	a5,0(a0)
    80004f88:	4705                	li	a4,1
    80004f8a:	02e78263          	beq	a5,a4,80004fae <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f8e:	470d                	li	a4,3
    80004f90:	02e78663          	beq	a5,a4,80004fbc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f94:	4709                	li	a4,2
    80004f96:	0ee79163          	bne	a5,a4,80005078 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f9a:	0ac05d63          	blez	a2,80005054 <filewrite+0xf4>
    int i = 0;
    80004f9e:	4981                	li	s3,0
    80004fa0:	6b05                	lui	s6,0x1
    80004fa2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004fa6:	6b85                	lui	s7,0x1
    80004fa8:	c00b8b9b          	addiw	s7,s7,-1024
    80004fac:	a861                	j	80005044 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fae:	6908                	ld	a0,16(a0)
    80004fb0:	00000097          	auipc	ra,0x0
    80004fb4:	22e080e7          	jalr	558(ra) # 800051de <pipewrite>
    80004fb8:	8a2a                	mv	s4,a0
    80004fba:	a045                	j	8000505a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fbc:	02451783          	lh	a5,36(a0)
    80004fc0:	03079693          	slli	a3,a5,0x30
    80004fc4:	92c1                	srli	a3,a3,0x30
    80004fc6:	4725                	li	a4,9
    80004fc8:	0cd76263          	bltu	a4,a3,8000508c <filewrite+0x12c>
    80004fcc:	0792                	slli	a5,a5,0x4
    80004fce:	00021717          	auipc	a4,0x21
    80004fd2:	24a70713          	addi	a4,a4,586 # 80026218 <devsw>
    80004fd6:	97ba                	add	a5,a5,a4
    80004fd8:	679c                	ld	a5,8(a5)
    80004fda:	cbdd                	beqz	a5,80005090 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004fdc:	4505                	li	a0,1
    80004fde:	9782                	jalr	a5
    80004fe0:	8a2a                	mv	s4,a0
    80004fe2:	a8a5                	j	8000505a <filewrite+0xfa>
    80004fe4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004fe8:	00000097          	auipc	ra,0x0
    80004fec:	8b0080e7          	jalr	-1872(ra) # 80004898 <begin_op>
      ilock(f->ip);
    80004ff0:	01893503          	ld	a0,24(s2)
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	ee2080e7          	jalr	-286(ra) # 80003ed6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ffc:	8762                	mv	a4,s8
    80004ffe:	02092683          	lw	a3,32(s2)
    80005002:	01598633          	add	a2,s3,s5
    80005006:	4585                	li	a1,1
    80005008:	01893503          	ld	a0,24(s2)
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	276080e7          	jalr	630(ra) # 80004282 <writei>
    80005014:	84aa                	mv	s1,a0
    80005016:	00a05763          	blez	a0,80005024 <filewrite+0xc4>
        f->off += r;
    8000501a:	02092783          	lw	a5,32(s2)
    8000501e:	9fa9                	addw	a5,a5,a0
    80005020:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005024:	01893503          	ld	a0,24(s2)
    80005028:	fffff097          	auipc	ra,0xfffff
    8000502c:	f70080e7          	jalr	-144(ra) # 80003f98 <iunlock>
      end_op();
    80005030:	00000097          	auipc	ra,0x0
    80005034:	8e8080e7          	jalr	-1816(ra) # 80004918 <end_op>

      if(r != n1){
    80005038:	009c1f63          	bne	s8,s1,80005056 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000503c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005040:	0149db63          	bge	s3,s4,80005056 <filewrite+0xf6>
      int n1 = n - i;
    80005044:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005048:	84be                	mv	s1,a5
    8000504a:	2781                	sext.w	a5,a5
    8000504c:	f8fb5ce3          	bge	s6,a5,80004fe4 <filewrite+0x84>
    80005050:	84de                	mv	s1,s7
    80005052:	bf49                	j	80004fe4 <filewrite+0x84>
    int i = 0;
    80005054:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005056:	013a1f63          	bne	s4,s3,80005074 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000505a:	8552                	mv	a0,s4
    8000505c:	60a6                	ld	ra,72(sp)
    8000505e:	6406                	ld	s0,64(sp)
    80005060:	74e2                	ld	s1,56(sp)
    80005062:	7942                	ld	s2,48(sp)
    80005064:	79a2                	ld	s3,40(sp)
    80005066:	7a02                	ld	s4,32(sp)
    80005068:	6ae2                	ld	s5,24(sp)
    8000506a:	6b42                	ld	s6,16(sp)
    8000506c:	6ba2                	ld	s7,8(sp)
    8000506e:	6c02                	ld	s8,0(sp)
    80005070:	6161                	addi	sp,sp,80
    80005072:	8082                	ret
    ret = (i == n ? n : -1);
    80005074:	5a7d                	li	s4,-1
    80005076:	b7d5                	j	8000505a <filewrite+0xfa>
    panic("filewrite");
    80005078:	00003517          	auipc	a0,0x3
    8000507c:	6a050513          	addi	a0,a0,1696 # 80008718 <syscalls+0x290>
    80005080:	ffffb097          	auipc	ra,0xffffb
    80005084:	4be080e7          	jalr	1214(ra) # 8000053e <panic>
    return -1;
    80005088:	5a7d                	li	s4,-1
    8000508a:	bfc1                	j	8000505a <filewrite+0xfa>
      return -1;
    8000508c:	5a7d                	li	s4,-1
    8000508e:	b7f1                	j	8000505a <filewrite+0xfa>
    80005090:	5a7d                	li	s4,-1
    80005092:	b7e1                	j	8000505a <filewrite+0xfa>

0000000080005094 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005094:	7179                	addi	sp,sp,-48
    80005096:	f406                	sd	ra,40(sp)
    80005098:	f022                	sd	s0,32(sp)
    8000509a:	ec26                	sd	s1,24(sp)
    8000509c:	e84a                	sd	s2,16(sp)
    8000509e:	e44e                	sd	s3,8(sp)
    800050a0:	e052                	sd	s4,0(sp)
    800050a2:	1800                	addi	s0,sp,48
    800050a4:	84aa                	mv	s1,a0
    800050a6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050a8:	0005b023          	sd	zero,0(a1)
    800050ac:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050b0:	00000097          	auipc	ra,0x0
    800050b4:	bf8080e7          	jalr	-1032(ra) # 80004ca8 <filealloc>
    800050b8:	e088                	sd	a0,0(s1)
    800050ba:	c551                	beqz	a0,80005146 <pipealloc+0xb2>
    800050bc:	00000097          	auipc	ra,0x0
    800050c0:	bec080e7          	jalr	-1044(ra) # 80004ca8 <filealloc>
    800050c4:	00aa3023          	sd	a0,0(s4)
    800050c8:	c92d                	beqz	a0,8000513a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050ca:	ffffc097          	auipc	ra,0xffffc
    800050ce:	a1c080e7          	jalr	-1508(ra) # 80000ae6 <kalloc>
    800050d2:	892a                	mv	s2,a0
    800050d4:	c125                	beqz	a0,80005134 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050d6:	4985                	li	s3,1
    800050d8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050dc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050e0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050e4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050e8:	00003597          	auipc	a1,0x3
    800050ec:	64058593          	addi	a1,a1,1600 # 80008728 <syscalls+0x2a0>
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	a56080e7          	jalr	-1450(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800050f8:	609c                	ld	a5,0(s1)
    800050fa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050fe:	609c                	ld	a5,0(s1)
    80005100:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005104:	609c                	ld	a5,0(s1)
    80005106:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000510a:	609c                	ld	a5,0(s1)
    8000510c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005110:	000a3783          	ld	a5,0(s4)
    80005114:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005118:	000a3783          	ld	a5,0(s4)
    8000511c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005120:	000a3783          	ld	a5,0(s4)
    80005124:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005128:	000a3783          	ld	a5,0(s4)
    8000512c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005130:	4501                	li	a0,0
    80005132:	a025                	j	8000515a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005134:	6088                	ld	a0,0(s1)
    80005136:	e501                	bnez	a0,8000513e <pipealloc+0xaa>
    80005138:	a039                	j	80005146 <pipealloc+0xb2>
    8000513a:	6088                	ld	a0,0(s1)
    8000513c:	c51d                	beqz	a0,8000516a <pipealloc+0xd6>
    fileclose(*f0);
    8000513e:	00000097          	auipc	ra,0x0
    80005142:	c26080e7          	jalr	-986(ra) # 80004d64 <fileclose>
  if(*f1)
    80005146:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000514a:	557d                	li	a0,-1
  if(*f1)
    8000514c:	c799                	beqz	a5,8000515a <pipealloc+0xc6>
    fileclose(*f1);
    8000514e:	853e                	mv	a0,a5
    80005150:	00000097          	auipc	ra,0x0
    80005154:	c14080e7          	jalr	-1004(ra) # 80004d64 <fileclose>
  return -1;
    80005158:	557d                	li	a0,-1
}
    8000515a:	70a2                	ld	ra,40(sp)
    8000515c:	7402                	ld	s0,32(sp)
    8000515e:	64e2                	ld	s1,24(sp)
    80005160:	6942                	ld	s2,16(sp)
    80005162:	69a2                	ld	s3,8(sp)
    80005164:	6a02                	ld	s4,0(sp)
    80005166:	6145                	addi	sp,sp,48
    80005168:	8082                	ret
  return -1;
    8000516a:	557d                	li	a0,-1
    8000516c:	b7fd                	j	8000515a <pipealloc+0xc6>

000000008000516e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000516e:	1101                	addi	sp,sp,-32
    80005170:	ec06                	sd	ra,24(sp)
    80005172:	e822                	sd	s0,16(sp)
    80005174:	e426                	sd	s1,8(sp)
    80005176:	e04a                	sd	s2,0(sp)
    80005178:	1000                	addi	s0,sp,32
    8000517a:	84aa                	mv	s1,a0
    8000517c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000517e:	ffffc097          	auipc	ra,0xffffc
    80005182:	a58080e7          	jalr	-1448(ra) # 80000bd6 <acquire>
  if(writable){
    80005186:	02090d63          	beqz	s2,800051c0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000518a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000518e:	21848513          	addi	a0,s1,536
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	2b2080e7          	jalr	690(ra) # 80002444 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000519a:	2204b783          	ld	a5,544(s1)
    8000519e:	eb95                	bnez	a5,800051d2 <pipeclose+0x64>
    release(&pi->lock);
    800051a0:	8526                	mv	a0,s1
    800051a2:	ffffc097          	auipc	ra,0xffffc
    800051a6:	ae8080e7          	jalr	-1304(ra) # 80000c8a <release>
    kfree((char*)pi);
    800051aa:	8526                	mv	a0,s1
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	83e080e7          	jalr	-1986(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800051b4:	60e2                	ld	ra,24(sp)
    800051b6:	6442                	ld	s0,16(sp)
    800051b8:	64a2                	ld	s1,8(sp)
    800051ba:	6902                	ld	s2,0(sp)
    800051bc:	6105                	addi	sp,sp,32
    800051be:	8082                	ret
    pi->readopen = 0;
    800051c0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051c4:	21c48513          	addi	a0,s1,540
    800051c8:	ffffd097          	auipc	ra,0xffffd
    800051cc:	27c080e7          	jalr	636(ra) # 80002444 <wakeup>
    800051d0:	b7e9                	j	8000519a <pipeclose+0x2c>
    release(&pi->lock);
    800051d2:	8526                	mv	a0,s1
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	ab6080e7          	jalr	-1354(ra) # 80000c8a <release>
}
    800051dc:	bfe1                	j	800051b4 <pipeclose+0x46>

00000000800051de <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051de:	711d                	addi	sp,sp,-96
    800051e0:	ec86                	sd	ra,88(sp)
    800051e2:	e8a2                	sd	s0,80(sp)
    800051e4:	e4a6                	sd	s1,72(sp)
    800051e6:	e0ca                	sd	s2,64(sp)
    800051e8:	fc4e                	sd	s3,56(sp)
    800051ea:	f852                	sd	s4,48(sp)
    800051ec:	f456                	sd	s5,40(sp)
    800051ee:	f05a                	sd	s6,32(sp)
    800051f0:	ec5e                	sd	s7,24(sp)
    800051f2:	e862                	sd	s8,16(sp)
    800051f4:	1080                	addi	s0,sp,96
    800051f6:	84aa                	mv	s1,a0
    800051f8:	8aae                	mv	s5,a1
    800051fa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	7b0080e7          	jalr	1968(ra) # 800019ac <myproc>
    80005204:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005206:	8526                	mv	a0,s1
    80005208:	ffffc097          	auipc	ra,0xffffc
    8000520c:	9ce080e7          	jalr	-1586(ra) # 80000bd6 <acquire>
  while(i < n){
    80005210:	0b405663          	blez	s4,800052bc <pipewrite+0xde>
  int i = 0;
    80005214:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005216:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005218:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000521c:	21c48b93          	addi	s7,s1,540
    80005220:	a089                	j	80005262 <pipewrite+0x84>
      release(&pi->lock);
    80005222:	8526                	mv	a0,s1
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	a66080e7          	jalr	-1434(ra) # 80000c8a <release>
      return -1;
    8000522c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000522e:	854a                	mv	a0,s2
    80005230:	60e6                	ld	ra,88(sp)
    80005232:	6446                	ld	s0,80(sp)
    80005234:	64a6                	ld	s1,72(sp)
    80005236:	6906                	ld	s2,64(sp)
    80005238:	79e2                	ld	s3,56(sp)
    8000523a:	7a42                	ld	s4,48(sp)
    8000523c:	7aa2                	ld	s5,40(sp)
    8000523e:	7b02                	ld	s6,32(sp)
    80005240:	6be2                	ld	s7,24(sp)
    80005242:	6c42                	ld	s8,16(sp)
    80005244:	6125                	addi	sp,sp,96
    80005246:	8082                	ret
      wakeup(&pi->nread);
    80005248:	8562                	mv	a0,s8
    8000524a:	ffffd097          	auipc	ra,0xffffd
    8000524e:	1fa080e7          	jalr	506(ra) # 80002444 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005252:	85a6                	mv	a1,s1
    80005254:	855e                	mv	a0,s7
    80005256:	ffffd097          	auipc	ra,0xffffd
    8000525a:	18a080e7          	jalr	394(ra) # 800023e0 <sleep>
  while(i < n){
    8000525e:	07495063          	bge	s2,s4,800052be <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005262:	2204a783          	lw	a5,544(s1)
    80005266:	dfd5                	beqz	a5,80005222 <pipewrite+0x44>
    80005268:	854e                	mv	a0,s3
    8000526a:	ffffd097          	auipc	ra,0xffffd
    8000526e:	42a080e7          	jalr	1066(ra) # 80002694 <killed>
    80005272:	f945                	bnez	a0,80005222 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005274:	2184a783          	lw	a5,536(s1)
    80005278:	21c4a703          	lw	a4,540(s1)
    8000527c:	2007879b          	addiw	a5,a5,512
    80005280:	fcf704e3          	beq	a4,a5,80005248 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005284:	4685                	li	a3,1
    80005286:	01590633          	add	a2,s2,s5
    8000528a:	faf40593          	addi	a1,s0,-81
    8000528e:	0509b503          	ld	a0,80(s3)
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	462080e7          	jalr	1122(ra) # 800016f4 <copyin>
    8000529a:	03650263          	beq	a0,s6,800052be <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000529e:	21c4a783          	lw	a5,540(s1)
    800052a2:	0017871b          	addiw	a4,a5,1
    800052a6:	20e4ae23          	sw	a4,540(s1)
    800052aa:	1ff7f793          	andi	a5,a5,511
    800052ae:	97a6                	add	a5,a5,s1
    800052b0:	faf44703          	lbu	a4,-81(s0)
    800052b4:	00e78c23          	sb	a4,24(a5)
      i++;
    800052b8:	2905                	addiw	s2,s2,1
    800052ba:	b755                	j	8000525e <pipewrite+0x80>
  int i = 0;
    800052bc:	4901                	li	s2,0
  wakeup(&pi->nread);
    800052be:	21848513          	addi	a0,s1,536
    800052c2:	ffffd097          	auipc	ra,0xffffd
    800052c6:	182080e7          	jalr	386(ra) # 80002444 <wakeup>
  release(&pi->lock);
    800052ca:	8526                	mv	a0,s1
    800052cc:	ffffc097          	auipc	ra,0xffffc
    800052d0:	9be080e7          	jalr	-1602(ra) # 80000c8a <release>
  return i;
    800052d4:	bfa9                	j	8000522e <pipewrite+0x50>

00000000800052d6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052d6:	715d                	addi	sp,sp,-80
    800052d8:	e486                	sd	ra,72(sp)
    800052da:	e0a2                	sd	s0,64(sp)
    800052dc:	fc26                	sd	s1,56(sp)
    800052de:	f84a                	sd	s2,48(sp)
    800052e0:	f44e                	sd	s3,40(sp)
    800052e2:	f052                	sd	s4,32(sp)
    800052e4:	ec56                	sd	s5,24(sp)
    800052e6:	e85a                	sd	s6,16(sp)
    800052e8:	0880                	addi	s0,sp,80
    800052ea:	84aa                	mv	s1,a0
    800052ec:	892e                	mv	s2,a1
    800052ee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	6bc080e7          	jalr	1724(ra) # 800019ac <myproc>
    800052f8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052fa:	8526                	mv	a0,s1
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	8da080e7          	jalr	-1830(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005304:	2184a703          	lw	a4,536(s1)
    80005308:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000530c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005310:	02f71763          	bne	a4,a5,8000533e <piperead+0x68>
    80005314:	2244a783          	lw	a5,548(s1)
    80005318:	c39d                	beqz	a5,8000533e <piperead+0x68>
    if(killed(pr)){
    8000531a:	8552                	mv	a0,s4
    8000531c:	ffffd097          	auipc	ra,0xffffd
    80005320:	378080e7          	jalr	888(ra) # 80002694 <killed>
    80005324:	e941                	bnez	a0,800053b4 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005326:	85a6                	mv	a1,s1
    80005328:	854e                	mv	a0,s3
    8000532a:	ffffd097          	auipc	ra,0xffffd
    8000532e:	0b6080e7          	jalr	182(ra) # 800023e0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005332:	2184a703          	lw	a4,536(s1)
    80005336:	21c4a783          	lw	a5,540(s1)
    8000533a:	fcf70de3          	beq	a4,a5,80005314 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000533e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005340:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005342:	05505363          	blez	s5,80005388 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005346:	2184a783          	lw	a5,536(s1)
    8000534a:	21c4a703          	lw	a4,540(s1)
    8000534e:	02f70d63          	beq	a4,a5,80005388 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005352:	0017871b          	addiw	a4,a5,1
    80005356:	20e4ac23          	sw	a4,536(s1)
    8000535a:	1ff7f793          	andi	a5,a5,511
    8000535e:	97a6                	add	a5,a5,s1
    80005360:	0187c783          	lbu	a5,24(a5)
    80005364:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005368:	4685                	li	a3,1
    8000536a:	fbf40613          	addi	a2,s0,-65
    8000536e:	85ca                	mv	a1,s2
    80005370:	050a3503          	ld	a0,80(s4)
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	2f4080e7          	jalr	756(ra) # 80001668 <copyout>
    8000537c:	01650663          	beq	a0,s6,80005388 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005380:	2985                	addiw	s3,s3,1
    80005382:	0905                	addi	s2,s2,1
    80005384:	fd3a91e3          	bne	s5,s3,80005346 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005388:	21c48513          	addi	a0,s1,540
    8000538c:	ffffd097          	auipc	ra,0xffffd
    80005390:	0b8080e7          	jalr	184(ra) # 80002444 <wakeup>
  release(&pi->lock);
    80005394:	8526                	mv	a0,s1
    80005396:	ffffc097          	auipc	ra,0xffffc
    8000539a:	8f4080e7          	jalr	-1804(ra) # 80000c8a <release>
  return i;
}
    8000539e:	854e                	mv	a0,s3
    800053a0:	60a6                	ld	ra,72(sp)
    800053a2:	6406                	ld	s0,64(sp)
    800053a4:	74e2                	ld	s1,56(sp)
    800053a6:	7942                	ld	s2,48(sp)
    800053a8:	79a2                	ld	s3,40(sp)
    800053aa:	7a02                	ld	s4,32(sp)
    800053ac:	6ae2                	ld	s5,24(sp)
    800053ae:	6b42                	ld	s6,16(sp)
    800053b0:	6161                	addi	sp,sp,80
    800053b2:	8082                	ret
      release(&pi->lock);
    800053b4:	8526                	mv	a0,s1
    800053b6:	ffffc097          	auipc	ra,0xffffc
    800053ba:	8d4080e7          	jalr	-1836(ra) # 80000c8a <release>
      return -1;
    800053be:	59fd                	li	s3,-1
    800053c0:	bff9                	j	8000539e <piperead+0xc8>

00000000800053c2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800053c2:	1141                	addi	sp,sp,-16
    800053c4:	e422                	sd	s0,8(sp)
    800053c6:	0800                	addi	s0,sp,16
    800053c8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800053ca:	8905                	andi	a0,a0,1
    800053cc:	c111                	beqz	a0,800053d0 <flags2perm+0xe>
      perm = PTE_X;
    800053ce:	4521                	li	a0,8
    if(flags & 0x2)
    800053d0:	8b89                	andi	a5,a5,2
    800053d2:	c399                	beqz	a5,800053d8 <flags2perm+0x16>
      perm |= PTE_W;
    800053d4:	00456513          	ori	a0,a0,4
    return perm;
}
    800053d8:	6422                	ld	s0,8(sp)
    800053da:	0141                	addi	sp,sp,16
    800053dc:	8082                	ret

00000000800053de <exec>:

int
exec(char *path, char **argv)
{
    800053de:	de010113          	addi	sp,sp,-544
    800053e2:	20113c23          	sd	ra,536(sp)
    800053e6:	20813823          	sd	s0,528(sp)
    800053ea:	20913423          	sd	s1,520(sp)
    800053ee:	21213023          	sd	s2,512(sp)
    800053f2:	ffce                	sd	s3,504(sp)
    800053f4:	fbd2                	sd	s4,496(sp)
    800053f6:	f7d6                	sd	s5,488(sp)
    800053f8:	f3da                	sd	s6,480(sp)
    800053fa:	efde                	sd	s7,472(sp)
    800053fc:	ebe2                	sd	s8,464(sp)
    800053fe:	e7e6                	sd	s9,456(sp)
    80005400:	e3ea                	sd	s10,448(sp)
    80005402:	ff6e                	sd	s11,440(sp)
    80005404:	1400                	addi	s0,sp,544
    80005406:	892a                	mv	s2,a0
    80005408:	dea43423          	sd	a0,-536(s0)
    8000540c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	59c080e7          	jalr	1436(ra) # 800019ac <myproc>
    80005418:	84aa                	mv	s1,a0

  begin_op();
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	47e080e7          	jalr	1150(ra) # 80004898 <begin_op>

  if((ip = namei(path)) == 0){
    80005422:	854a                	mv	a0,s2
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	258080e7          	jalr	600(ra) # 8000467c <namei>
    8000542c:	c93d                	beqz	a0,800054a2 <exec+0xc4>
    8000542e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	aa6080e7          	jalr	-1370(ra) # 80003ed6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005438:	04000713          	li	a4,64
    8000543c:	4681                	li	a3,0
    8000543e:	e5040613          	addi	a2,s0,-432
    80005442:	4581                	li	a1,0
    80005444:	8556                	mv	a0,s5
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	d44080e7          	jalr	-700(ra) # 8000418a <readi>
    8000544e:	04000793          	li	a5,64
    80005452:	00f51a63          	bne	a0,a5,80005466 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005456:	e5042703          	lw	a4,-432(s0)
    8000545a:	464c47b7          	lui	a5,0x464c4
    8000545e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005462:	04f70663          	beq	a4,a5,800054ae <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005466:	8556                	mv	a0,s5
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	cd0080e7          	jalr	-816(ra) # 80004138 <iunlockput>
    end_op();
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	4a8080e7          	jalr	1192(ra) # 80004918 <end_op>
  }
  return -1;
    80005478:	557d                	li	a0,-1
}
    8000547a:	21813083          	ld	ra,536(sp)
    8000547e:	21013403          	ld	s0,528(sp)
    80005482:	20813483          	ld	s1,520(sp)
    80005486:	20013903          	ld	s2,512(sp)
    8000548a:	79fe                	ld	s3,504(sp)
    8000548c:	7a5e                	ld	s4,496(sp)
    8000548e:	7abe                	ld	s5,488(sp)
    80005490:	7b1e                	ld	s6,480(sp)
    80005492:	6bfe                	ld	s7,472(sp)
    80005494:	6c5e                	ld	s8,464(sp)
    80005496:	6cbe                	ld	s9,456(sp)
    80005498:	6d1e                	ld	s10,448(sp)
    8000549a:	7dfa                	ld	s11,440(sp)
    8000549c:	22010113          	addi	sp,sp,544
    800054a0:	8082                	ret
    end_op();
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	476080e7          	jalr	1142(ra) # 80004918 <end_op>
    return -1;
    800054aa:	557d                	li	a0,-1
    800054ac:	b7f9                	j	8000547a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffc097          	auipc	ra,0xffffc
    800054b4:	5c0080e7          	jalr	1472(ra) # 80001a70 <proc_pagetable>
    800054b8:	8b2a                	mv	s6,a0
    800054ba:	d555                	beqz	a0,80005466 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054bc:	e7042783          	lw	a5,-400(s0)
    800054c0:	e8845703          	lhu	a4,-376(s0)
    800054c4:	c735                	beqz	a4,80005530 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054c6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054c8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800054cc:	6a05                	lui	s4,0x1
    800054ce:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800054d2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800054d6:	6d85                	lui	s11,0x1
    800054d8:	7d7d                	lui	s10,0xfffff
    800054da:	a481                	j	8000571a <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054dc:	00003517          	auipc	a0,0x3
    800054e0:	25450513          	addi	a0,a0,596 # 80008730 <syscalls+0x2a8>
    800054e4:	ffffb097          	auipc	ra,0xffffb
    800054e8:	05a080e7          	jalr	90(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054ec:	874a                	mv	a4,s2
    800054ee:	009c86bb          	addw	a3,s9,s1
    800054f2:	4581                	li	a1,0
    800054f4:	8556                	mv	a0,s5
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	c94080e7          	jalr	-876(ra) # 8000418a <readi>
    800054fe:	2501                	sext.w	a0,a0
    80005500:	1aa91a63          	bne	s2,a0,800056b4 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005504:	009d84bb          	addw	s1,s11,s1
    80005508:	013d09bb          	addw	s3,s10,s3
    8000550c:	1f74f763          	bgeu	s1,s7,800056fa <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005510:	02049593          	slli	a1,s1,0x20
    80005514:	9181                	srli	a1,a1,0x20
    80005516:	95e2                	add	a1,a1,s8
    80005518:	855a                	mv	a0,s6
    8000551a:	ffffc097          	auipc	ra,0xffffc
    8000551e:	b42080e7          	jalr	-1214(ra) # 8000105c <walkaddr>
    80005522:	862a                	mv	a2,a0
    if(pa == 0)
    80005524:	dd45                	beqz	a0,800054dc <exec+0xfe>
      n = PGSIZE;
    80005526:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005528:	fd49f2e3          	bgeu	s3,s4,800054ec <exec+0x10e>
      n = sz - i;
    8000552c:	894e                	mv	s2,s3
    8000552e:	bf7d                	j	800054ec <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005530:	4901                	li	s2,0
  iunlockput(ip);
    80005532:	8556                	mv	a0,s5
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	c04080e7          	jalr	-1020(ra) # 80004138 <iunlockput>
  end_op();
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	3dc080e7          	jalr	988(ra) # 80004918 <end_op>
  p = myproc();
    80005544:	ffffc097          	auipc	ra,0xffffc
    80005548:	468080e7          	jalr	1128(ra) # 800019ac <myproc>
    8000554c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000554e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005552:	6785                	lui	a5,0x1
    80005554:	17fd                	addi	a5,a5,-1
    80005556:	993e                	add	s2,s2,a5
    80005558:	77fd                	lui	a5,0xfffff
    8000555a:	00f977b3          	and	a5,s2,a5
    8000555e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005562:	4691                	li	a3,4
    80005564:	6609                	lui	a2,0x2
    80005566:	963e                	add	a2,a2,a5
    80005568:	85be                	mv	a1,a5
    8000556a:	855a                	mv	a0,s6
    8000556c:	ffffc097          	auipc	ra,0xffffc
    80005570:	ea4080e7          	jalr	-348(ra) # 80001410 <uvmalloc>
    80005574:	8c2a                	mv	s8,a0
  ip = 0;
    80005576:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005578:	12050e63          	beqz	a0,800056b4 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000557c:	75f9                	lui	a1,0xffffe
    8000557e:	95aa                	add	a1,a1,a0
    80005580:	855a                	mv	a0,s6
    80005582:	ffffc097          	auipc	ra,0xffffc
    80005586:	0b4080e7          	jalr	180(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    8000558a:	7afd                	lui	s5,0xfffff
    8000558c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000558e:	df043783          	ld	a5,-528(s0)
    80005592:	6388                	ld	a0,0(a5)
    80005594:	c925                	beqz	a0,80005604 <exec+0x226>
    80005596:	e9040993          	addi	s3,s0,-368
    8000559a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000559e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800055a0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800055a2:	ffffc097          	auipc	ra,0xffffc
    800055a6:	8ac080e7          	jalr	-1876(ra) # 80000e4e <strlen>
    800055aa:	0015079b          	addiw	a5,a0,1
    800055ae:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800055b2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800055b6:	13596663          	bltu	s2,s5,800056e2 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800055ba:	df043d83          	ld	s11,-528(s0)
    800055be:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800055c2:	8552                	mv	a0,s4
    800055c4:	ffffc097          	auipc	ra,0xffffc
    800055c8:	88a080e7          	jalr	-1910(ra) # 80000e4e <strlen>
    800055cc:	0015069b          	addiw	a3,a0,1
    800055d0:	8652                	mv	a2,s4
    800055d2:	85ca                	mv	a1,s2
    800055d4:	855a                	mv	a0,s6
    800055d6:	ffffc097          	auipc	ra,0xffffc
    800055da:	092080e7          	jalr	146(ra) # 80001668 <copyout>
    800055de:	10054663          	bltz	a0,800056ea <exec+0x30c>
    ustack[argc] = sp;
    800055e2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055e6:	0485                	addi	s1,s1,1
    800055e8:	008d8793          	addi	a5,s11,8
    800055ec:	def43823          	sd	a5,-528(s0)
    800055f0:	008db503          	ld	a0,8(s11)
    800055f4:	c911                	beqz	a0,80005608 <exec+0x22a>
    if(argc >= MAXARG)
    800055f6:	09a1                	addi	s3,s3,8
    800055f8:	fb3c95e3          	bne	s9,s3,800055a2 <exec+0x1c4>
  sz = sz1;
    800055fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005600:	4a81                	li	s5,0
    80005602:	a84d                	j	800056b4 <exec+0x2d6>
  sp = sz;
    80005604:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005606:	4481                	li	s1,0
  ustack[argc] = 0;
    80005608:	00349793          	slli	a5,s1,0x3
    8000560c:	f9040713          	addi	a4,s0,-112
    80005610:	97ba                	add	a5,a5,a4
    80005612:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd7b50>
  sp -= (argc+1) * sizeof(uint64);
    80005616:	00148693          	addi	a3,s1,1
    8000561a:	068e                	slli	a3,a3,0x3
    8000561c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005620:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005624:	01597663          	bgeu	s2,s5,80005630 <exec+0x252>
  sz = sz1;
    80005628:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000562c:	4a81                	li	s5,0
    8000562e:	a059                	j	800056b4 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005630:	e9040613          	addi	a2,s0,-368
    80005634:	85ca                	mv	a1,s2
    80005636:	855a                	mv	a0,s6
    80005638:	ffffc097          	auipc	ra,0xffffc
    8000563c:	030080e7          	jalr	48(ra) # 80001668 <copyout>
    80005640:	0a054963          	bltz	a0,800056f2 <exec+0x314>
  p->trapframe->a1 = sp;
    80005644:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005648:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000564c:	de843783          	ld	a5,-536(s0)
    80005650:	0007c703          	lbu	a4,0(a5)
    80005654:	cf11                	beqz	a4,80005670 <exec+0x292>
    80005656:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005658:	02f00693          	li	a3,47
    8000565c:	a039                	j	8000566a <exec+0x28c>
      last = s+1;
    8000565e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005662:	0785                	addi	a5,a5,1
    80005664:	fff7c703          	lbu	a4,-1(a5)
    80005668:	c701                	beqz	a4,80005670 <exec+0x292>
    if(*s == '/')
    8000566a:	fed71ce3          	bne	a4,a3,80005662 <exec+0x284>
    8000566e:	bfc5                	j	8000565e <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005670:	4641                	li	a2,16
    80005672:	de843583          	ld	a1,-536(s0)
    80005676:	158b8513          	addi	a0,s7,344
    8000567a:	ffffb097          	auipc	ra,0xffffb
    8000567e:	7a2080e7          	jalr	1954(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005682:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005686:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000568a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000568e:	058bb783          	ld	a5,88(s7)
    80005692:	e6843703          	ld	a4,-408(s0)
    80005696:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005698:	058bb783          	ld	a5,88(s7)
    8000569c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800056a0:	85ea                	mv	a1,s10
    800056a2:	ffffc097          	auipc	ra,0xffffc
    800056a6:	46a080e7          	jalr	1130(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056aa:	0004851b          	sext.w	a0,s1
    800056ae:	b3f1                	j	8000547a <exec+0x9c>
    800056b0:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800056b4:	df843583          	ld	a1,-520(s0)
    800056b8:	855a                	mv	a0,s6
    800056ba:	ffffc097          	auipc	ra,0xffffc
    800056be:	452080e7          	jalr	1106(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800056c2:	da0a92e3          	bnez	s5,80005466 <exec+0x88>
  return -1;
    800056c6:	557d                	li	a0,-1
    800056c8:	bb4d                	j	8000547a <exec+0x9c>
    800056ca:	df243c23          	sd	s2,-520(s0)
    800056ce:	b7dd                	j	800056b4 <exec+0x2d6>
    800056d0:	df243c23          	sd	s2,-520(s0)
    800056d4:	b7c5                	j	800056b4 <exec+0x2d6>
    800056d6:	df243c23          	sd	s2,-520(s0)
    800056da:	bfe9                	j	800056b4 <exec+0x2d6>
    800056dc:	df243c23          	sd	s2,-520(s0)
    800056e0:	bfd1                	j	800056b4 <exec+0x2d6>
  sz = sz1;
    800056e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056e6:	4a81                	li	s5,0
    800056e8:	b7f1                	j	800056b4 <exec+0x2d6>
  sz = sz1;
    800056ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056ee:	4a81                	li	s5,0
    800056f0:	b7d1                	j	800056b4 <exec+0x2d6>
  sz = sz1;
    800056f2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056f6:	4a81                	li	s5,0
    800056f8:	bf75                	j	800056b4 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800056fa:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056fe:	e0843783          	ld	a5,-504(s0)
    80005702:	0017869b          	addiw	a3,a5,1
    80005706:	e0d43423          	sd	a3,-504(s0)
    8000570a:	e0043783          	ld	a5,-512(s0)
    8000570e:	0387879b          	addiw	a5,a5,56
    80005712:	e8845703          	lhu	a4,-376(s0)
    80005716:	e0e6dee3          	bge	a3,a4,80005532 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000571a:	2781                	sext.w	a5,a5
    8000571c:	e0f43023          	sd	a5,-512(s0)
    80005720:	03800713          	li	a4,56
    80005724:	86be                	mv	a3,a5
    80005726:	e1840613          	addi	a2,s0,-488
    8000572a:	4581                	li	a1,0
    8000572c:	8556                	mv	a0,s5
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	a5c080e7          	jalr	-1444(ra) # 8000418a <readi>
    80005736:	03800793          	li	a5,56
    8000573a:	f6f51be3          	bne	a0,a5,800056b0 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000573e:	e1842783          	lw	a5,-488(s0)
    80005742:	4705                	li	a4,1
    80005744:	fae79de3          	bne	a5,a4,800056fe <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005748:	e4043483          	ld	s1,-448(s0)
    8000574c:	e3843783          	ld	a5,-456(s0)
    80005750:	f6f4ede3          	bltu	s1,a5,800056ca <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005754:	e2843783          	ld	a5,-472(s0)
    80005758:	94be                	add	s1,s1,a5
    8000575a:	f6f4ebe3          	bltu	s1,a5,800056d0 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000575e:	de043703          	ld	a4,-544(s0)
    80005762:	8ff9                	and	a5,a5,a4
    80005764:	fbad                	bnez	a5,800056d6 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005766:	e1c42503          	lw	a0,-484(s0)
    8000576a:	00000097          	auipc	ra,0x0
    8000576e:	c58080e7          	jalr	-936(ra) # 800053c2 <flags2perm>
    80005772:	86aa                	mv	a3,a0
    80005774:	8626                	mv	a2,s1
    80005776:	85ca                	mv	a1,s2
    80005778:	855a                	mv	a0,s6
    8000577a:	ffffc097          	auipc	ra,0xffffc
    8000577e:	c96080e7          	jalr	-874(ra) # 80001410 <uvmalloc>
    80005782:	dea43c23          	sd	a0,-520(s0)
    80005786:	d939                	beqz	a0,800056dc <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005788:	e2843c03          	ld	s8,-472(s0)
    8000578c:	e2042c83          	lw	s9,-480(s0)
    80005790:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005794:	f60b83e3          	beqz	s7,800056fa <exec+0x31c>
    80005798:	89de                	mv	s3,s7
    8000579a:	4481                	li	s1,0
    8000579c:	bb95                	j	80005510 <exec+0x132>

000000008000579e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000579e:	7179                	addi	sp,sp,-48
    800057a0:	f406                	sd	ra,40(sp)
    800057a2:	f022                	sd	s0,32(sp)
    800057a4:	ec26                	sd	s1,24(sp)
    800057a6:	e84a                	sd	s2,16(sp)
    800057a8:	1800                	addi	s0,sp,48
    800057aa:	892e                	mv	s2,a1
    800057ac:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800057ae:	fdc40593          	addi	a1,s0,-36
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	8ce080e7          	jalr	-1842(ra) # 80003080 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057ba:	fdc42703          	lw	a4,-36(s0)
    800057be:	47bd                	li	a5,15
    800057c0:	02e7eb63          	bltu	a5,a4,800057f6 <argfd+0x58>
    800057c4:	ffffc097          	auipc	ra,0xffffc
    800057c8:	1e8080e7          	jalr	488(ra) # 800019ac <myproc>
    800057cc:	fdc42703          	lw	a4,-36(s0)
    800057d0:	01a70793          	addi	a5,a4,26
    800057d4:	078e                	slli	a5,a5,0x3
    800057d6:	953e                	add	a0,a0,a5
    800057d8:	611c                	ld	a5,0(a0)
    800057da:	c385                	beqz	a5,800057fa <argfd+0x5c>
    return -1;
  if(pfd)
    800057dc:	00090463          	beqz	s2,800057e4 <argfd+0x46>
    *pfd = fd;
    800057e0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057e4:	4501                	li	a0,0
  if(pf)
    800057e6:	c091                	beqz	s1,800057ea <argfd+0x4c>
    *pf = f;
    800057e8:	e09c                	sd	a5,0(s1)
}
    800057ea:	70a2                	ld	ra,40(sp)
    800057ec:	7402                	ld	s0,32(sp)
    800057ee:	64e2                	ld	s1,24(sp)
    800057f0:	6942                	ld	s2,16(sp)
    800057f2:	6145                	addi	sp,sp,48
    800057f4:	8082                	ret
    return -1;
    800057f6:	557d                	li	a0,-1
    800057f8:	bfcd                	j	800057ea <argfd+0x4c>
    800057fa:	557d                	li	a0,-1
    800057fc:	b7fd                	j	800057ea <argfd+0x4c>

00000000800057fe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057fe:	1101                	addi	sp,sp,-32
    80005800:	ec06                	sd	ra,24(sp)
    80005802:	e822                	sd	s0,16(sp)
    80005804:	e426                	sd	s1,8(sp)
    80005806:	1000                	addi	s0,sp,32
    80005808:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000580a:	ffffc097          	auipc	ra,0xffffc
    8000580e:	1a2080e7          	jalr	418(ra) # 800019ac <myproc>
    80005812:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005814:	0d050793          	addi	a5,a0,208
    80005818:	4501                	li	a0,0
    8000581a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000581c:	6398                	ld	a4,0(a5)
    8000581e:	cb19                	beqz	a4,80005834 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005820:	2505                	addiw	a0,a0,1
    80005822:	07a1                	addi	a5,a5,8
    80005824:	fed51ce3          	bne	a0,a3,8000581c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005828:	557d                	li	a0,-1
}
    8000582a:	60e2                	ld	ra,24(sp)
    8000582c:	6442                	ld	s0,16(sp)
    8000582e:	64a2                	ld	s1,8(sp)
    80005830:	6105                	addi	sp,sp,32
    80005832:	8082                	ret
      p->ofile[fd] = f;
    80005834:	01a50793          	addi	a5,a0,26
    80005838:	078e                	slli	a5,a5,0x3
    8000583a:	963e                	add	a2,a2,a5
    8000583c:	e204                	sd	s1,0(a2)
      return fd;
    8000583e:	b7f5                	j	8000582a <fdalloc+0x2c>

0000000080005840 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005840:	715d                	addi	sp,sp,-80
    80005842:	e486                	sd	ra,72(sp)
    80005844:	e0a2                	sd	s0,64(sp)
    80005846:	fc26                	sd	s1,56(sp)
    80005848:	f84a                	sd	s2,48(sp)
    8000584a:	f44e                	sd	s3,40(sp)
    8000584c:	f052                	sd	s4,32(sp)
    8000584e:	ec56                	sd	s5,24(sp)
    80005850:	e85a                	sd	s6,16(sp)
    80005852:	0880                	addi	s0,sp,80
    80005854:	8b2e                	mv	s6,a1
    80005856:	89b2                	mv	s3,a2
    80005858:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000585a:	fb040593          	addi	a1,s0,-80
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	e3c080e7          	jalr	-452(ra) # 8000469a <nameiparent>
    80005866:	84aa                	mv	s1,a0
    80005868:	14050f63          	beqz	a0,800059c6 <create+0x186>
    return 0;

  ilock(dp);
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	66a080e7          	jalr	1642(ra) # 80003ed6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005874:	4601                	li	a2,0
    80005876:	fb040593          	addi	a1,s0,-80
    8000587a:	8526                	mv	a0,s1
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	b3e080e7          	jalr	-1218(ra) # 800043ba <dirlookup>
    80005884:	8aaa                	mv	s5,a0
    80005886:	c931                	beqz	a0,800058da <create+0x9a>
    iunlockput(dp);
    80005888:	8526                	mv	a0,s1
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	8ae080e7          	jalr	-1874(ra) # 80004138 <iunlockput>
    ilock(ip);
    80005892:	8556                	mv	a0,s5
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	642080e7          	jalr	1602(ra) # 80003ed6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000589c:	000b059b          	sext.w	a1,s6
    800058a0:	4789                	li	a5,2
    800058a2:	02f59563          	bne	a1,a5,800058cc <create+0x8c>
    800058a6:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd7c94>
    800058aa:	37f9                	addiw	a5,a5,-2
    800058ac:	17c2                	slli	a5,a5,0x30
    800058ae:	93c1                	srli	a5,a5,0x30
    800058b0:	4705                	li	a4,1
    800058b2:	00f76d63          	bltu	a4,a5,800058cc <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800058b6:	8556                	mv	a0,s5
    800058b8:	60a6                	ld	ra,72(sp)
    800058ba:	6406                	ld	s0,64(sp)
    800058bc:	74e2                	ld	s1,56(sp)
    800058be:	7942                	ld	s2,48(sp)
    800058c0:	79a2                	ld	s3,40(sp)
    800058c2:	7a02                	ld	s4,32(sp)
    800058c4:	6ae2                	ld	s5,24(sp)
    800058c6:	6b42                	ld	s6,16(sp)
    800058c8:	6161                	addi	sp,sp,80
    800058ca:	8082                	ret
    iunlockput(ip);
    800058cc:	8556                	mv	a0,s5
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	86a080e7          	jalr	-1942(ra) # 80004138 <iunlockput>
    return 0;
    800058d6:	4a81                	li	s5,0
    800058d8:	bff9                	j	800058b6 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800058da:	85da                	mv	a1,s6
    800058dc:	4088                	lw	a0,0(s1)
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	45c080e7          	jalr	1116(ra) # 80003d3a <ialloc>
    800058e6:	8a2a                	mv	s4,a0
    800058e8:	c539                	beqz	a0,80005936 <create+0xf6>
  ilock(ip);
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	5ec080e7          	jalr	1516(ra) # 80003ed6 <ilock>
  ip->major = major;
    800058f2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800058f6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800058fa:	4905                	li	s2,1
    800058fc:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005900:	8552                	mv	a0,s4
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	50a080e7          	jalr	1290(ra) # 80003e0c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000590a:	000b059b          	sext.w	a1,s6
    8000590e:	03258b63          	beq	a1,s2,80005944 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005912:	004a2603          	lw	a2,4(s4)
    80005916:	fb040593          	addi	a1,s0,-80
    8000591a:	8526                	mv	a0,s1
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	cae080e7          	jalr	-850(ra) # 800045ca <dirlink>
    80005924:	06054f63          	bltz	a0,800059a2 <create+0x162>
  iunlockput(dp);
    80005928:	8526                	mv	a0,s1
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	80e080e7          	jalr	-2034(ra) # 80004138 <iunlockput>
  return ip;
    80005932:	8ad2                	mv	s5,s4
    80005934:	b749                	j	800058b6 <create+0x76>
    iunlockput(dp);
    80005936:	8526                	mv	a0,s1
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	800080e7          	jalr	-2048(ra) # 80004138 <iunlockput>
    return 0;
    80005940:	8ad2                	mv	s5,s4
    80005942:	bf95                	j	800058b6 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005944:	004a2603          	lw	a2,4(s4)
    80005948:	00003597          	auipc	a1,0x3
    8000594c:	e0858593          	addi	a1,a1,-504 # 80008750 <syscalls+0x2c8>
    80005950:	8552                	mv	a0,s4
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	c78080e7          	jalr	-904(ra) # 800045ca <dirlink>
    8000595a:	04054463          	bltz	a0,800059a2 <create+0x162>
    8000595e:	40d0                	lw	a2,4(s1)
    80005960:	00003597          	auipc	a1,0x3
    80005964:	df858593          	addi	a1,a1,-520 # 80008758 <syscalls+0x2d0>
    80005968:	8552                	mv	a0,s4
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	c60080e7          	jalr	-928(ra) # 800045ca <dirlink>
    80005972:	02054863          	bltz	a0,800059a2 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005976:	004a2603          	lw	a2,4(s4)
    8000597a:	fb040593          	addi	a1,s0,-80
    8000597e:	8526                	mv	a0,s1
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	c4a080e7          	jalr	-950(ra) # 800045ca <dirlink>
    80005988:	00054d63          	bltz	a0,800059a2 <create+0x162>
    dp->nlink++;  // for ".."
    8000598c:	04a4d783          	lhu	a5,74(s1)
    80005990:	2785                	addiw	a5,a5,1
    80005992:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	474080e7          	jalr	1140(ra) # 80003e0c <iupdate>
    800059a0:	b761                	j	80005928 <create+0xe8>
  ip->nlink = 0;
    800059a2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800059a6:	8552                	mv	a0,s4
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	464080e7          	jalr	1124(ra) # 80003e0c <iupdate>
  iunlockput(ip);
    800059b0:	8552                	mv	a0,s4
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	786080e7          	jalr	1926(ra) # 80004138 <iunlockput>
  iunlockput(dp);
    800059ba:	8526                	mv	a0,s1
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	77c080e7          	jalr	1916(ra) # 80004138 <iunlockput>
  return 0;
    800059c4:	bdcd                	j	800058b6 <create+0x76>
    return 0;
    800059c6:	8aaa                	mv	s5,a0
    800059c8:	b5fd                	j	800058b6 <create+0x76>

00000000800059ca <sys_dup>:
{
    800059ca:	7179                	addi	sp,sp,-48
    800059cc:	f406                	sd	ra,40(sp)
    800059ce:	f022                	sd	s0,32(sp)
    800059d0:	ec26                	sd	s1,24(sp)
    800059d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800059d4:	fd840613          	addi	a2,s0,-40
    800059d8:	4581                	li	a1,0
    800059da:	4501                	li	a0,0
    800059dc:	00000097          	auipc	ra,0x0
    800059e0:	dc2080e7          	jalr	-574(ra) # 8000579e <argfd>
    return -1;
    800059e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059e6:	02054363          	bltz	a0,80005a0c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800059ea:	fd843503          	ld	a0,-40(s0)
    800059ee:	00000097          	auipc	ra,0x0
    800059f2:	e10080e7          	jalr	-496(ra) # 800057fe <fdalloc>
    800059f6:	84aa                	mv	s1,a0
    return -1;
    800059f8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800059fa:	00054963          	bltz	a0,80005a0c <sys_dup+0x42>
  filedup(f);
    800059fe:	fd843503          	ld	a0,-40(s0)
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	310080e7          	jalr	784(ra) # 80004d12 <filedup>
  return fd;
    80005a0a:	87a6                	mv	a5,s1
}
    80005a0c:	853e                	mv	a0,a5
    80005a0e:	70a2                	ld	ra,40(sp)
    80005a10:	7402                	ld	s0,32(sp)
    80005a12:	64e2                	ld	s1,24(sp)
    80005a14:	6145                	addi	sp,sp,48
    80005a16:	8082                	ret

0000000080005a18 <sys_read>:
{
    80005a18:	7179                	addi	sp,sp,-48
    80005a1a:	f406                	sd	ra,40(sp)
    80005a1c:	f022                	sd	s0,32(sp)
    80005a1e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a20:	fd840593          	addi	a1,s0,-40
    80005a24:	4505                	li	a0,1
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	67a080e7          	jalr	1658(ra) # 800030a0 <argaddr>
  argint(2, &n);
    80005a2e:	fe440593          	addi	a1,s0,-28
    80005a32:	4509                	li	a0,2
    80005a34:	ffffd097          	auipc	ra,0xffffd
    80005a38:	64c080e7          	jalr	1612(ra) # 80003080 <argint>
  if(argfd(0, 0, &f) < 0)
    80005a3c:	fe840613          	addi	a2,s0,-24
    80005a40:	4581                	li	a1,0
    80005a42:	4501                	li	a0,0
    80005a44:	00000097          	auipc	ra,0x0
    80005a48:	d5a080e7          	jalr	-678(ra) # 8000579e <argfd>
    80005a4c:	87aa                	mv	a5,a0
    return -1;
    80005a4e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a50:	0007cc63          	bltz	a5,80005a68 <sys_read+0x50>
  return fileread(f, p, n);
    80005a54:	fe442603          	lw	a2,-28(s0)
    80005a58:	fd843583          	ld	a1,-40(s0)
    80005a5c:	fe843503          	ld	a0,-24(s0)
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	43e080e7          	jalr	1086(ra) # 80004e9e <fileread>
}
    80005a68:	70a2                	ld	ra,40(sp)
    80005a6a:	7402                	ld	s0,32(sp)
    80005a6c:	6145                	addi	sp,sp,48
    80005a6e:	8082                	ret

0000000080005a70 <sys_write>:
{
    80005a70:	7179                	addi	sp,sp,-48
    80005a72:	f406                	sd	ra,40(sp)
    80005a74:	f022                	sd	s0,32(sp)
    80005a76:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a78:	fd840593          	addi	a1,s0,-40
    80005a7c:	4505                	li	a0,1
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	622080e7          	jalr	1570(ra) # 800030a0 <argaddr>
  argint(2, &n);
    80005a86:	fe440593          	addi	a1,s0,-28
    80005a8a:	4509                	li	a0,2
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	5f4080e7          	jalr	1524(ra) # 80003080 <argint>
  if(argfd(0, 0, &f) < 0)
    80005a94:	fe840613          	addi	a2,s0,-24
    80005a98:	4581                	li	a1,0
    80005a9a:	4501                	li	a0,0
    80005a9c:	00000097          	auipc	ra,0x0
    80005aa0:	d02080e7          	jalr	-766(ra) # 8000579e <argfd>
    80005aa4:	87aa                	mv	a5,a0
    return -1;
    80005aa6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005aa8:	0007cc63          	bltz	a5,80005ac0 <sys_write+0x50>
  return filewrite(f, p, n);
    80005aac:	fe442603          	lw	a2,-28(s0)
    80005ab0:	fd843583          	ld	a1,-40(s0)
    80005ab4:	fe843503          	ld	a0,-24(s0)
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	4a8080e7          	jalr	1192(ra) # 80004f60 <filewrite>
}
    80005ac0:	70a2                	ld	ra,40(sp)
    80005ac2:	7402                	ld	s0,32(sp)
    80005ac4:	6145                	addi	sp,sp,48
    80005ac6:	8082                	ret

0000000080005ac8 <sys_close>:
{
    80005ac8:	1101                	addi	sp,sp,-32
    80005aca:	ec06                	sd	ra,24(sp)
    80005acc:	e822                	sd	s0,16(sp)
    80005ace:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ad0:	fe040613          	addi	a2,s0,-32
    80005ad4:	fec40593          	addi	a1,s0,-20
    80005ad8:	4501                	li	a0,0
    80005ada:	00000097          	auipc	ra,0x0
    80005ade:	cc4080e7          	jalr	-828(ra) # 8000579e <argfd>
    return -1;
    80005ae2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ae4:	02054463          	bltz	a0,80005b0c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005ae8:	ffffc097          	auipc	ra,0xffffc
    80005aec:	ec4080e7          	jalr	-316(ra) # 800019ac <myproc>
    80005af0:	fec42783          	lw	a5,-20(s0)
    80005af4:	07e9                	addi	a5,a5,26
    80005af6:	078e                	slli	a5,a5,0x3
    80005af8:	97aa                	add	a5,a5,a0
    80005afa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005afe:	fe043503          	ld	a0,-32(s0)
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	262080e7          	jalr	610(ra) # 80004d64 <fileclose>
  return 0;
    80005b0a:	4781                	li	a5,0
}
    80005b0c:	853e                	mv	a0,a5
    80005b0e:	60e2                	ld	ra,24(sp)
    80005b10:	6442                	ld	s0,16(sp)
    80005b12:	6105                	addi	sp,sp,32
    80005b14:	8082                	ret

0000000080005b16 <sys_fstat>:
{
    80005b16:	1101                	addi	sp,sp,-32
    80005b18:	ec06                	sd	ra,24(sp)
    80005b1a:	e822                	sd	s0,16(sp)
    80005b1c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005b1e:	fe040593          	addi	a1,s0,-32
    80005b22:	4505                	li	a0,1
    80005b24:	ffffd097          	auipc	ra,0xffffd
    80005b28:	57c080e7          	jalr	1404(ra) # 800030a0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005b2c:	fe840613          	addi	a2,s0,-24
    80005b30:	4581                	li	a1,0
    80005b32:	4501                	li	a0,0
    80005b34:	00000097          	auipc	ra,0x0
    80005b38:	c6a080e7          	jalr	-918(ra) # 8000579e <argfd>
    80005b3c:	87aa                	mv	a5,a0
    return -1;
    80005b3e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b40:	0007ca63          	bltz	a5,80005b54 <sys_fstat+0x3e>
  return filestat(f, st);
    80005b44:	fe043583          	ld	a1,-32(s0)
    80005b48:	fe843503          	ld	a0,-24(s0)
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	2e0080e7          	jalr	736(ra) # 80004e2c <filestat>
}
    80005b54:	60e2                	ld	ra,24(sp)
    80005b56:	6442                	ld	s0,16(sp)
    80005b58:	6105                	addi	sp,sp,32
    80005b5a:	8082                	ret

0000000080005b5c <sys_link>:
{
    80005b5c:	7169                	addi	sp,sp,-304
    80005b5e:	f606                	sd	ra,296(sp)
    80005b60:	f222                	sd	s0,288(sp)
    80005b62:	ee26                	sd	s1,280(sp)
    80005b64:	ea4a                	sd	s2,272(sp)
    80005b66:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b68:	08000613          	li	a2,128
    80005b6c:	ed040593          	addi	a1,s0,-304
    80005b70:	4501                	li	a0,0
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	54e080e7          	jalr	1358(ra) # 800030c0 <argstr>
    return -1;
    80005b7a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b7c:	10054e63          	bltz	a0,80005c98 <sys_link+0x13c>
    80005b80:	08000613          	li	a2,128
    80005b84:	f5040593          	addi	a1,s0,-176
    80005b88:	4505                	li	a0,1
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	536080e7          	jalr	1334(ra) # 800030c0 <argstr>
    return -1;
    80005b92:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b94:	10054263          	bltz	a0,80005c98 <sys_link+0x13c>
  begin_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	d00080e7          	jalr	-768(ra) # 80004898 <begin_op>
  if((ip = namei(old)) == 0){
    80005ba0:	ed040513          	addi	a0,s0,-304
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	ad8080e7          	jalr	-1320(ra) # 8000467c <namei>
    80005bac:	84aa                	mv	s1,a0
    80005bae:	c551                	beqz	a0,80005c3a <sys_link+0xde>
  ilock(ip);
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	326080e7          	jalr	806(ra) # 80003ed6 <ilock>
  if(ip->type == T_DIR){
    80005bb8:	04449703          	lh	a4,68(s1)
    80005bbc:	4785                	li	a5,1
    80005bbe:	08f70463          	beq	a4,a5,80005c46 <sys_link+0xea>
  ip->nlink++;
    80005bc2:	04a4d783          	lhu	a5,74(s1)
    80005bc6:	2785                	addiw	a5,a5,1
    80005bc8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bcc:	8526                	mv	a0,s1
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	23e080e7          	jalr	574(ra) # 80003e0c <iupdate>
  iunlock(ip);
    80005bd6:	8526                	mv	a0,s1
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	3c0080e7          	jalr	960(ra) # 80003f98 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005be0:	fd040593          	addi	a1,s0,-48
    80005be4:	f5040513          	addi	a0,s0,-176
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	ab2080e7          	jalr	-1358(ra) # 8000469a <nameiparent>
    80005bf0:	892a                	mv	s2,a0
    80005bf2:	c935                	beqz	a0,80005c66 <sys_link+0x10a>
  ilock(dp);
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	2e2080e7          	jalr	738(ra) # 80003ed6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005bfc:	00092703          	lw	a4,0(s2)
    80005c00:	409c                	lw	a5,0(s1)
    80005c02:	04f71d63          	bne	a4,a5,80005c5c <sys_link+0x100>
    80005c06:	40d0                	lw	a2,4(s1)
    80005c08:	fd040593          	addi	a1,s0,-48
    80005c0c:	854a                	mv	a0,s2
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	9bc080e7          	jalr	-1604(ra) # 800045ca <dirlink>
    80005c16:	04054363          	bltz	a0,80005c5c <sys_link+0x100>
  iunlockput(dp);
    80005c1a:	854a                	mv	a0,s2
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	51c080e7          	jalr	1308(ra) # 80004138 <iunlockput>
  iput(ip);
    80005c24:	8526                	mv	a0,s1
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	46a080e7          	jalr	1130(ra) # 80004090 <iput>
  end_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	cea080e7          	jalr	-790(ra) # 80004918 <end_op>
  return 0;
    80005c36:	4781                	li	a5,0
    80005c38:	a085                	j	80005c98 <sys_link+0x13c>
    end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	cde080e7          	jalr	-802(ra) # 80004918 <end_op>
    return -1;
    80005c42:	57fd                	li	a5,-1
    80005c44:	a891                	j	80005c98 <sys_link+0x13c>
    iunlockput(ip);
    80005c46:	8526                	mv	a0,s1
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	4f0080e7          	jalr	1264(ra) # 80004138 <iunlockput>
    end_op();
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	cc8080e7          	jalr	-824(ra) # 80004918 <end_op>
    return -1;
    80005c58:	57fd                	li	a5,-1
    80005c5a:	a83d                	j	80005c98 <sys_link+0x13c>
    iunlockput(dp);
    80005c5c:	854a                	mv	a0,s2
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	4da080e7          	jalr	1242(ra) # 80004138 <iunlockput>
  ilock(ip);
    80005c66:	8526                	mv	a0,s1
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	26e080e7          	jalr	622(ra) # 80003ed6 <ilock>
  ip->nlink--;
    80005c70:	04a4d783          	lhu	a5,74(s1)
    80005c74:	37fd                	addiw	a5,a5,-1
    80005c76:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c7a:	8526                	mv	a0,s1
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	190080e7          	jalr	400(ra) # 80003e0c <iupdate>
  iunlockput(ip);
    80005c84:	8526                	mv	a0,s1
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	4b2080e7          	jalr	1202(ra) # 80004138 <iunlockput>
  end_op();
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	c8a080e7          	jalr	-886(ra) # 80004918 <end_op>
  return -1;
    80005c96:	57fd                	li	a5,-1
}
    80005c98:	853e                	mv	a0,a5
    80005c9a:	70b2                	ld	ra,296(sp)
    80005c9c:	7412                	ld	s0,288(sp)
    80005c9e:	64f2                	ld	s1,280(sp)
    80005ca0:	6952                	ld	s2,272(sp)
    80005ca2:	6155                	addi	sp,sp,304
    80005ca4:	8082                	ret

0000000080005ca6 <sys_unlink>:
{
    80005ca6:	7151                	addi	sp,sp,-240
    80005ca8:	f586                	sd	ra,232(sp)
    80005caa:	f1a2                	sd	s0,224(sp)
    80005cac:	eda6                	sd	s1,216(sp)
    80005cae:	e9ca                	sd	s2,208(sp)
    80005cb0:	e5ce                	sd	s3,200(sp)
    80005cb2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005cb4:	08000613          	li	a2,128
    80005cb8:	f3040593          	addi	a1,s0,-208
    80005cbc:	4501                	li	a0,0
    80005cbe:	ffffd097          	auipc	ra,0xffffd
    80005cc2:	402080e7          	jalr	1026(ra) # 800030c0 <argstr>
    80005cc6:	18054163          	bltz	a0,80005e48 <sys_unlink+0x1a2>
  begin_op();
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	bce080e7          	jalr	-1074(ra) # 80004898 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005cd2:	fb040593          	addi	a1,s0,-80
    80005cd6:	f3040513          	addi	a0,s0,-208
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	9c0080e7          	jalr	-1600(ra) # 8000469a <nameiparent>
    80005ce2:	84aa                	mv	s1,a0
    80005ce4:	c979                	beqz	a0,80005dba <sys_unlink+0x114>
  ilock(dp);
    80005ce6:	ffffe097          	auipc	ra,0xffffe
    80005cea:	1f0080e7          	jalr	496(ra) # 80003ed6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005cee:	00003597          	auipc	a1,0x3
    80005cf2:	a6258593          	addi	a1,a1,-1438 # 80008750 <syscalls+0x2c8>
    80005cf6:	fb040513          	addi	a0,s0,-80
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	6a6080e7          	jalr	1702(ra) # 800043a0 <namecmp>
    80005d02:	14050a63          	beqz	a0,80005e56 <sys_unlink+0x1b0>
    80005d06:	00003597          	auipc	a1,0x3
    80005d0a:	a5258593          	addi	a1,a1,-1454 # 80008758 <syscalls+0x2d0>
    80005d0e:	fb040513          	addi	a0,s0,-80
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	68e080e7          	jalr	1678(ra) # 800043a0 <namecmp>
    80005d1a:	12050e63          	beqz	a0,80005e56 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d1e:	f2c40613          	addi	a2,s0,-212
    80005d22:	fb040593          	addi	a1,s0,-80
    80005d26:	8526                	mv	a0,s1
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	692080e7          	jalr	1682(ra) # 800043ba <dirlookup>
    80005d30:	892a                	mv	s2,a0
    80005d32:	12050263          	beqz	a0,80005e56 <sys_unlink+0x1b0>
  ilock(ip);
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	1a0080e7          	jalr	416(ra) # 80003ed6 <ilock>
  if(ip->nlink < 1)
    80005d3e:	04a91783          	lh	a5,74(s2)
    80005d42:	08f05263          	blez	a5,80005dc6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d46:	04491703          	lh	a4,68(s2)
    80005d4a:	4785                	li	a5,1
    80005d4c:	08f70563          	beq	a4,a5,80005dd6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d50:	4641                	li	a2,16
    80005d52:	4581                	li	a1,0
    80005d54:	fc040513          	addi	a0,s0,-64
    80005d58:	ffffb097          	auipc	ra,0xffffb
    80005d5c:	f7a080e7          	jalr	-134(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d60:	4741                	li	a4,16
    80005d62:	f2c42683          	lw	a3,-212(s0)
    80005d66:	fc040613          	addi	a2,s0,-64
    80005d6a:	4581                	li	a1,0
    80005d6c:	8526                	mv	a0,s1
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	514080e7          	jalr	1300(ra) # 80004282 <writei>
    80005d76:	47c1                	li	a5,16
    80005d78:	0af51563          	bne	a0,a5,80005e22 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d7c:	04491703          	lh	a4,68(s2)
    80005d80:	4785                	li	a5,1
    80005d82:	0af70863          	beq	a4,a5,80005e32 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d86:	8526                	mv	a0,s1
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	3b0080e7          	jalr	944(ra) # 80004138 <iunlockput>
  ip->nlink--;
    80005d90:	04a95783          	lhu	a5,74(s2)
    80005d94:	37fd                	addiw	a5,a5,-1
    80005d96:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d9a:	854a                	mv	a0,s2
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	070080e7          	jalr	112(ra) # 80003e0c <iupdate>
  iunlockput(ip);
    80005da4:	854a                	mv	a0,s2
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	392080e7          	jalr	914(ra) # 80004138 <iunlockput>
  end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	b6a080e7          	jalr	-1174(ra) # 80004918 <end_op>
  return 0;
    80005db6:	4501                	li	a0,0
    80005db8:	a84d                	j	80005e6a <sys_unlink+0x1c4>
    end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	b5e080e7          	jalr	-1186(ra) # 80004918 <end_op>
    return -1;
    80005dc2:	557d                	li	a0,-1
    80005dc4:	a05d                	j	80005e6a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005dc6:	00003517          	auipc	a0,0x3
    80005dca:	99a50513          	addi	a0,a0,-1638 # 80008760 <syscalls+0x2d8>
    80005dce:	ffffa097          	auipc	ra,0xffffa
    80005dd2:	770080e7          	jalr	1904(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005dd6:	04c92703          	lw	a4,76(s2)
    80005dda:	02000793          	li	a5,32
    80005dde:	f6e7f9e3          	bgeu	a5,a4,80005d50 <sys_unlink+0xaa>
    80005de2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005de6:	4741                	li	a4,16
    80005de8:	86ce                	mv	a3,s3
    80005dea:	f1840613          	addi	a2,s0,-232
    80005dee:	4581                	li	a1,0
    80005df0:	854a                	mv	a0,s2
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	398080e7          	jalr	920(ra) # 8000418a <readi>
    80005dfa:	47c1                	li	a5,16
    80005dfc:	00f51b63          	bne	a0,a5,80005e12 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e00:	f1845783          	lhu	a5,-232(s0)
    80005e04:	e7a1                	bnez	a5,80005e4c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e06:	29c1                	addiw	s3,s3,16
    80005e08:	04c92783          	lw	a5,76(s2)
    80005e0c:	fcf9ede3          	bltu	s3,a5,80005de6 <sys_unlink+0x140>
    80005e10:	b781                	j	80005d50 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e12:	00003517          	auipc	a0,0x3
    80005e16:	96650513          	addi	a0,a0,-1690 # 80008778 <syscalls+0x2f0>
    80005e1a:	ffffa097          	auipc	ra,0xffffa
    80005e1e:	724080e7          	jalr	1828(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e22:	00003517          	auipc	a0,0x3
    80005e26:	96e50513          	addi	a0,a0,-1682 # 80008790 <syscalls+0x308>
    80005e2a:	ffffa097          	auipc	ra,0xffffa
    80005e2e:	714080e7          	jalr	1812(ra) # 8000053e <panic>
    dp->nlink--;
    80005e32:	04a4d783          	lhu	a5,74(s1)
    80005e36:	37fd                	addiw	a5,a5,-1
    80005e38:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e3c:	8526                	mv	a0,s1
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	fce080e7          	jalr	-50(ra) # 80003e0c <iupdate>
    80005e46:	b781                	j	80005d86 <sys_unlink+0xe0>
    return -1;
    80005e48:	557d                	li	a0,-1
    80005e4a:	a005                	j	80005e6a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e4c:	854a                	mv	a0,s2
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	2ea080e7          	jalr	746(ra) # 80004138 <iunlockput>
  iunlockput(dp);
    80005e56:	8526                	mv	a0,s1
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	2e0080e7          	jalr	736(ra) # 80004138 <iunlockput>
  end_op();
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	ab8080e7          	jalr	-1352(ra) # 80004918 <end_op>
  return -1;
    80005e68:	557d                	li	a0,-1
}
    80005e6a:	70ae                	ld	ra,232(sp)
    80005e6c:	740e                	ld	s0,224(sp)
    80005e6e:	64ee                	ld	s1,216(sp)
    80005e70:	694e                	ld	s2,208(sp)
    80005e72:	69ae                	ld	s3,200(sp)
    80005e74:	616d                	addi	sp,sp,240
    80005e76:	8082                	ret

0000000080005e78 <sys_open>:

uint64
sys_open(void)
{
    80005e78:	7131                	addi	sp,sp,-192
    80005e7a:	fd06                	sd	ra,184(sp)
    80005e7c:	f922                	sd	s0,176(sp)
    80005e7e:	f526                	sd	s1,168(sp)
    80005e80:	f14a                	sd	s2,160(sp)
    80005e82:	ed4e                	sd	s3,152(sp)
    80005e84:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005e86:	f4c40593          	addi	a1,s0,-180
    80005e8a:	4505                	li	a0,1
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	1f4080e7          	jalr	500(ra) # 80003080 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e94:	08000613          	li	a2,128
    80005e98:	f5040593          	addi	a1,s0,-176
    80005e9c:	4501                	li	a0,0
    80005e9e:	ffffd097          	auipc	ra,0xffffd
    80005ea2:	222080e7          	jalr	546(ra) # 800030c0 <argstr>
    80005ea6:	87aa                	mv	a5,a0
    return -1;
    80005ea8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005eaa:	0a07c963          	bltz	a5,80005f5c <sys_open+0xe4>

  begin_op();
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	9ea080e7          	jalr	-1558(ra) # 80004898 <begin_op>

  if(omode & O_CREATE){
    80005eb6:	f4c42783          	lw	a5,-180(s0)
    80005eba:	2007f793          	andi	a5,a5,512
    80005ebe:	cfc5                	beqz	a5,80005f76 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ec0:	4681                	li	a3,0
    80005ec2:	4601                	li	a2,0
    80005ec4:	4589                	li	a1,2
    80005ec6:	f5040513          	addi	a0,s0,-176
    80005eca:	00000097          	auipc	ra,0x0
    80005ece:	976080e7          	jalr	-1674(ra) # 80005840 <create>
    80005ed2:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ed4:	c959                	beqz	a0,80005f6a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ed6:	04449703          	lh	a4,68(s1)
    80005eda:	478d                	li	a5,3
    80005edc:	00f71763          	bne	a4,a5,80005eea <sys_open+0x72>
    80005ee0:	0464d703          	lhu	a4,70(s1)
    80005ee4:	47a5                	li	a5,9
    80005ee6:	0ce7ed63          	bltu	a5,a4,80005fc0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	dbe080e7          	jalr	-578(ra) # 80004ca8 <filealloc>
    80005ef2:	89aa                	mv	s3,a0
    80005ef4:	10050363          	beqz	a0,80005ffa <sys_open+0x182>
    80005ef8:	00000097          	auipc	ra,0x0
    80005efc:	906080e7          	jalr	-1786(ra) # 800057fe <fdalloc>
    80005f00:	892a                	mv	s2,a0
    80005f02:	0e054763          	bltz	a0,80005ff0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f06:	04449703          	lh	a4,68(s1)
    80005f0a:	478d                	li	a5,3
    80005f0c:	0cf70563          	beq	a4,a5,80005fd6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f10:	4789                	li	a5,2
    80005f12:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f16:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f1a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f1e:	f4c42783          	lw	a5,-180(s0)
    80005f22:	0017c713          	xori	a4,a5,1
    80005f26:	8b05                	andi	a4,a4,1
    80005f28:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f2c:	0037f713          	andi	a4,a5,3
    80005f30:	00e03733          	snez	a4,a4
    80005f34:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f38:	4007f793          	andi	a5,a5,1024
    80005f3c:	c791                	beqz	a5,80005f48 <sys_open+0xd0>
    80005f3e:	04449703          	lh	a4,68(s1)
    80005f42:	4789                	li	a5,2
    80005f44:	0af70063          	beq	a4,a5,80005fe4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f48:	8526                	mv	a0,s1
    80005f4a:	ffffe097          	auipc	ra,0xffffe
    80005f4e:	04e080e7          	jalr	78(ra) # 80003f98 <iunlock>
  end_op();
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	9c6080e7          	jalr	-1594(ra) # 80004918 <end_op>

  return fd;
    80005f5a:	854a                	mv	a0,s2
}
    80005f5c:	70ea                	ld	ra,184(sp)
    80005f5e:	744a                	ld	s0,176(sp)
    80005f60:	74aa                	ld	s1,168(sp)
    80005f62:	790a                	ld	s2,160(sp)
    80005f64:	69ea                	ld	s3,152(sp)
    80005f66:	6129                	addi	sp,sp,192
    80005f68:	8082                	ret
      end_op();
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	9ae080e7          	jalr	-1618(ra) # 80004918 <end_op>
      return -1;
    80005f72:	557d                	li	a0,-1
    80005f74:	b7e5                	j	80005f5c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f76:	f5040513          	addi	a0,s0,-176
    80005f7a:	ffffe097          	auipc	ra,0xffffe
    80005f7e:	702080e7          	jalr	1794(ra) # 8000467c <namei>
    80005f82:	84aa                	mv	s1,a0
    80005f84:	c905                	beqz	a0,80005fb4 <sys_open+0x13c>
    ilock(ip);
    80005f86:	ffffe097          	auipc	ra,0xffffe
    80005f8a:	f50080e7          	jalr	-176(ra) # 80003ed6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f8e:	04449703          	lh	a4,68(s1)
    80005f92:	4785                	li	a5,1
    80005f94:	f4f711e3          	bne	a4,a5,80005ed6 <sys_open+0x5e>
    80005f98:	f4c42783          	lw	a5,-180(s0)
    80005f9c:	d7b9                	beqz	a5,80005eea <sys_open+0x72>
      iunlockput(ip);
    80005f9e:	8526                	mv	a0,s1
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	198080e7          	jalr	408(ra) # 80004138 <iunlockput>
      end_op();
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	970080e7          	jalr	-1680(ra) # 80004918 <end_op>
      return -1;
    80005fb0:	557d                	li	a0,-1
    80005fb2:	b76d                	j	80005f5c <sys_open+0xe4>
      end_op();
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	964080e7          	jalr	-1692(ra) # 80004918 <end_op>
      return -1;
    80005fbc:	557d                	li	a0,-1
    80005fbe:	bf79                	j	80005f5c <sys_open+0xe4>
    iunlockput(ip);
    80005fc0:	8526                	mv	a0,s1
    80005fc2:	ffffe097          	auipc	ra,0xffffe
    80005fc6:	176080e7          	jalr	374(ra) # 80004138 <iunlockput>
    end_op();
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	94e080e7          	jalr	-1714(ra) # 80004918 <end_op>
    return -1;
    80005fd2:	557d                	li	a0,-1
    80005fd4:	b761                	j	80005f5c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fd6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fda:	04649783          	lh	a5,70(s1)
    80005fde:	02f99223          	sh	a5,36(s3)
    80005fe2:	bf25                	j	80005f1a <sys_open+0xa2>
    itrunc(ip);
    80005fe4:	8526                	mv	a0,s1
    80005fe6:	ffffe097          	auipc	ra,0xffffe
    80005fea:	ffe080e7          	jalr	-2(ra) # 80003fe4 <itrunc>
    80005fee:	bfa9                	j	80005f48 <sys_open+0xd0>
      fileclose(f);
    80005ff0:	854e                	mv	a0,s3
    80005ff2:	fffff097          	auipc	ra,0xfffff
    80005ff6:	d72080e7          	jalr	-654(ra) # 80004d64 <fileclose>
    iunlockput(ip);
    80005ffa:	8526                	mv	a0,s1
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	13c080e7          	jalr	316(ra) # 80004138 <iunlockput>
    end_op();
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	914080e7          	jalr	-1772(ra) # 80004918 <end_op>
    return -1;
    8000600c:	557d                	li	a0,-1
    8000600e:	b7b9                	j	80005f5c <sys_open+0xe4>

0000000080006010 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006010:	7175                	addi	sp,sp,-144
    80006012:	e506                	sd	ra,136(sp)
    80006014:	e122                	sd	s0,128(sp)
    80006016:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006018:	fffff097          	auipc	ra,0xfffff
    8000601c:	880080e7          	jalr	-1920(ra) # 80004898 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006020:	08000613          	li	a2,128
    80006024:	f7040593          	addi	a1,s0,-144
    80006028:	4501                	li	a0,0
    8000602a:	ffffd097          	auipc	ra,0xffffd
    8000602e:	096080e7          	jalr	150(ra) # 800030c0 <argstr>
    80006032:	02054963          	bltz	a0,80006064 <sys_mkdir+0x54>
    80006036:	4681                	li	a3,0
    80006038:	4601                	li	a2,0
    8000603a:	4585                	li	a1,1
    8000603c:	f7040513          	addi	a0,s0,-144
    80006040:	00000097          	auipc	ra,0x0
    80006044:	800080e7          	jalr	-2048(ra) # 80005840 <create>
    80006048:	cd11                	beqz	a0,80006064 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	0ee080e7          	jalr	238(ra) # 80004138 <iunlockput>
  end_op();
    80006052:	fffff097          	auipc	ra,0xfffff
    80006056:	8c6080e7          	jalr	-1850(ra) # 80004918 <end_op>
  return 0;
    8000605a:	4501                	li	a0,0
}
    8000605c:	60aa                	ld	ra,136(sp)
    8000605e:	640a                	ld	s0,128(sp)
    80006060:	6149                	addi	sp,sp,144
    80006062:	8082                	ret
    end_op();
    80006064:	fffff097          	auipc	ra,0xfffff
    80006068:	8b4080e7          	jalr	-1868(ra) # 80004918 <end_op>
    return -1;
    8000606c:	557d                	li	a0,-1
    8000606e:	b7fd                	j	8000605c <sys_mkdir+0x4c>

0000000080006070 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006070:	7135                	addi	sp,sp,-160
    80006072:	ed06                	sd	ra,152(sp)
    80006074:	e922                	sd	s0,144(sp)
    80006076:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	820080e7          	jalr	-2016(ra) # 80004898 <begin_op>
  argint(1, &major);
    80006080:	f6c40593          	addi	a1,s0,-148
    80006084:	4505                	li	a0,1
    80006086:	ffffd097          	auipc	ra,0xffffd
    8000608a:	ffa080e7          	jalr	-6(ra) # 80003080 <argint>
  argint(2, &minor);
    8000608e:	f6840593          	addi	a1,s0,-152
    80006092:	4509                	li	a0,2
    80006094:	ffffd097          	auipc	ra,0xffffd
    80006098:	fec080e7          	jalr	-20(ra) # 80003080 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000609c:	08000613          	li	a2,128
    800060a0:	f7040593          	addi	a1,s0,-144
    800060a4:	4501                	li	a0,0
    800060a6:	ffffd097          	auipc	ra,0xffffd
    800060aa:	01a080e7          	jalr	26(ra) # 800030c0 <argstr>
    800060ae:	02054b63          	bltz	a0,800060e4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060b2:	f6841683          	lh	a3,-152(s0)
    800060b6:	f6c41603          	lh	a2,-148(s0)
    800060ba:	458d                	li	a1,3
    800060bc:	f7040513          	addi	a0,s0,-144
    800060c0:	fffff097          	auipc	ra,0xfffff
    800060c4:	780080e7          	jalr	1920(ra) # 80005840 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060c8:	cd11                	beqz	a0,800060e4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060ca:	ffffe097          	auipc	ra,0xffffe
    800060ce:	06e080e7          	jalr	110(ra) # 80004138 <iunlockput>
  end_op();
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	846080e7          	jalr	-1978(ra) # 80004918 <end_op>
  return 0;
    800060da:	4501                	li	a0,0
}
    800060dc:	60ea                	ld	ra,152(sp)
    800060de:	644a                	ld	s0,144(sp)
    800060e0:	610d                	addi	sp,sp,160
    800060e2:	8082                	ret
    end_op();
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	834080e7          	jalr	-1996(ra) # 80004918 <end_op>
    return -1;
    800060ec:	557d                	li	a0,-1
    800060ee:	b7fd                	j	800060dc <sys_mknod+0x6c>

00000000800060f0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800060f0:	7135                	addi	sp,sp,-160
    800060f2:	ed06                	sd	ra,152(sp)
    800060f4:	e922                	sd	s0,144(sp)
    800060f6:	e526                	sd	s1,136(sp)
    800060f8:	e14a                	sd	s2,128(sp)
    800060fa:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060fc:	ffffc097          	auipc	ra,0xffffc
    80006100:	8b0080e7          	jalr	-1872(ra) # 800019ac <myproc>
    80006104:	892a                	mv	s2,a0
  
  begin_op();
    80006106:	ffffe097          	auipc	ra,0xffffe
    8000610a:	792080e7          	jalr	1938(ra) # 80004898 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000610e:	08000613          	li	a2,128
    80006112:	f6040593          	addi	a1,s0,-160
    80006116:	4501                	li	a0,0
    80006118:	ffffd097          	auipc	ra,0xffffd
    8000611c:	fa8080e7          	jalr	-88(ra) # 800030c0 <argstr>
    80006120:	04054b63          	bltz	a0,80006176 <sys_chdir+0x86>
    80006124:	f6040513          	addi	a0,s0,-160
    80006128:	ffffe097          	auipc	ra,0xffffe
    8000612c:	554080e7          	jalr	1364(ra) # 8000467c <namei>
    80006130:	84aa                	mv	s1,a0
    80006132:	c131                	beqz	a0,80006176 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006134:	ffffe097          	auipc	ra,0xffffe
    80006138:	da2080e7          	jalr	-606(ra) # 80003ed6 <ilock>
  if(ip->type != T_DIR){
    8000613c:	04449703          	lh	a4,68(s1)
    80006140:	4785                	li	a5,1
    80006142:	04f71063          	bne	a4,a5,80006182 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006146:	8526                	mv	a0,s1
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	e50080e7          	jalr	-432(ra) # 80003f98 <iunlock>
  iput(p->cwd);
    80006150:	15093503          	ld	a0,336(s2)
    80006154:	ffffe097          	auipc	ra,0xffffe
    80006158:	f3c080e7          	jalr	-196(ra) # 80004090 <iput>
  end_op();
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	7bc080e7          	jalr	1980(ra) # 80004918 <end_op>
  p->cwd = ip;
    80006164:	14993823          	sd	s1,336(s2)
  return 0;
    80006168:	4501                	li	a0,0
}
    8000616a:	60ea                	ld	ra,152(sp)
    8000616c:	644a                	ld	s0,144(sp)
    8000616e:	64aa                	ld	s1,136(sp)
    80006170:	690a                	ld	s2,128(sp)
    80006172:	610d                	addi	sp,sp,160
    80006174:	8082                	ret
    end_op();
    80006176:	ffffe097          	auipc	ra,0xffffe
    8000617a:	7a2080e7          	jalr	1954(ra) # 80004918 <end_op>
    return -1;
    8000617e:	557d                	li	a0,-1
    80006180:	b7ed                	j	8000616a <sys_chdir+0x7a>
    iunlockput(ip);
    80006182:	8526                	mv	a0,s1
    80006184:	ffffe097          	auipc	ra,0xffffe
    80006188:	fb4080e7          	jalr	-76(ra) # 80004138 <iunlockput>
    end_op();
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	78c080e7          	jalr	1932(ra) # 80004918 <end_op>
    return -1;
    80006194:	557d                	li	a0,-1
    80006196:	bfd1                	j	8000616a <sys_chdir+0x7a>

0000000080006198 <sys_exec>:

uint64
sys_exec(void)
{
    80006198:	7145                	addi	sp,sp,-464
    8000619a:	e786                	sd	ra,456(sp)
    8000619c:	e3a2                	sd	s0,448(sp)
    8000619e:	ff26                	sd	s1,440(sp)
    800061a0:	fb4a                	sd	s2,432(sp)
    800061a2:	f74e                	sd	s3,424(sp)
    800061a4:	f352                	sd	s4,416(sp)
    800061a6:	ef56                	sd	s5,408(sp)
    800061a8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800061aa:	e3840593          	addi	a1,s0,-456
    800061ae:	4505                	li	a0,1
    800061b0:	ffffd097          	auipc	ra,0xffffd
    800061b4:	ef0080e7          	jalr	-272(ra) # 800030a0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800061b8:	08000613          	li	a2,128
    800061bc:	f4040593          	addi	a1,s0,-192
    800061c0:	4501                	li	a0,0
    800061c2:	ffffd097          	auipc	ra,0xffffd
    800061c6:	efe080e7          	jalr	-258(ra) # 800030c0 <argstr>
    800061ca:	87aa                	mv	a5,a0
    return -1;
    800061cc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800061ce:	0c07c263          	bltz	a5,80006292 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061d2:	10000613          	li	a2,256
    800061d6:	4581                	li	a1,0
    800061d8:	e4040513          	addi	a0,s0,-448
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	af6080e7          	jalr	-1290(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061e4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061e8:	89a6                	mv	s3,s1
    800061ea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061ec:	02000a13          	li	s4,32
    800061f0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061f4:	00391793          	slli	a5,s2,0x3
    800061f8:	e3040593          	addi	a1,s0,-464
    800061fc:	e3843503          	ld	a0,-456(s0)
    80006200:	953e                	add	a0,a0,a5
    80006202:	ffffd097          	auipc	ra,0xffffd
    80006206:	de0080e7          	jalr	-544(ra) # 80002fe2 <fetchaddr>
    8000620a:	02054a63          	bltz	a0,8000623e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000620e:	e3043783          	ld	a5,-464(s0)
    80006212:	c3b9                	beqz	a5,80006258 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006214:	ffffb097          	auipc	ra,0xffffb
    80006218:	8d2080e7          	jalr	-1838(ra) # 80000ae6 <kalloc>
    8000621c:	85aa                	mv	a1,a0
    8000621e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006222:	cd11                	beqz	a0,8000623e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006224:	6605                	lui	a2,0x1
    80006226:	e3043503          	ld	a0,-464(s0)
    8000622a:	ffffd097          	auipc	ra,0xffffd
    8000622e:	e0a080e7          	jalr	-502(ra) # 80003034 <fetchstr>
    80006232:	00054663          	bltz	a0,8000623e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006236:	0905                	addi	s2,s2,1
    80006238:	09a1                	addi	s3,s3,8
    8000623a:	fb491be3          	bne	s2,s4,800061f0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000623e:	10048913          	addi	s2,s1,256
    80006242:	6088                	ld	a0,0(s1)
    80006244:	c531                	beqz	a0,80006290 <sys_exec+0xf8>
    kfree(argv[i]);
    80006246:	ffffa097          	auipc	ra,0xffffa
    8000624a:	7a4080e7          	jalr	1956(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000624e:	04a1                	addi	s1,s1,8
    80006250:	ff2499e3          	bne	s1,s2,80006242 <sys_exec+0xaa>
  return -1;
    80006254:	557d                	li	a0,-1
    80006256:	a835                	j	80006292 <sys_exec+0xfa>
      argv[i] = 0;
    80006258:	0a8e                	slli	s5,s5,0x3
    8000625a:	fc040793          	addi	a5,s0,-64
    8000625e:	9abe                	add	s5,s5,a5
    80006260:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006264:	e4040593          	addi	a1,s0,-448
    80006268:	f4040513          	addi	a0,s0,-192
    8000626c:	fffff097          	auipc	ra,0xfffff
    80006270:	172080e7          	jalr	370(ra) # 800053de <exec>
    80006274:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006276:	10048993          	addi	s3,s1,256
    8000627a:	6088                	ld	a0,0(s1)
    8000627c:	c901                	beqz	a0,8000628c <sys_exec+0xf4>
    kfree(argv[i]);
    8000627e:	ffffa097          	auipc	ra,0xffffa
    80006282:	76c080e7          	jalr	1900(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006286:	04a1                	addi	s1,s1,8
    80006288:	ff3499e3          	bne	s1,s3,8000627a <sys_exec+0xe2>
  return ret;
    8000628c:	854a                	mv	a0,s2
    8000628e:	a011                	j	80006292 <sys_exec+0xfa>
  return -1;
    80006290:	557d                	li	a0,-1
}
    80006292:	60be                	ld	ra,456(sp)
    80006294:	641e                	ld	s0,448(sp)
    80006296:	74fa                	ld	s1,440(sp)
    80006298:	795a                	ld	s2,432(sp)
    8000629a:	79ba                	ld	s3,424(sp)
    8000629c:	7a1a                	ld	s4,416(sp)
    8000629e:	6afa                	ld	s5,408(sp)
    800062a0:	6179                	addi	sp,sp,464
    800062a2:	8082                	ret

00000000800062a4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062a4:	7139                	addi	sp,sp,-64
    800062a6:	fc06                	sd	ra,56(sp)
    800062a8:	f822                	sd	s0,48(sp)
    800062aa:	f426                	sd	s1,40(sp)
    800062ac:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062ae:	ffffb097          	auipc	ra,0xffffb
    800062b2:	6fe080e7          	jalr	1790(ra) # 800019ac <myproc>
    800062b6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800062b8:	fd840593          	addi	a1,s0,-40
    800062bc:	4501                	li	a0,0
    800062be:	ffffd097          	auipc	ra,0xffffd
    800062c2:	de2080e7          	jalr	-542(ra) # 800030a0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800062c6:	fc840593          	addi	a1,s0,-56
    800062ca:	fd040513          	addi	a0,s0,-48
    800062ce:	fffff097          	auipc	ra,0xfffff
    800062d2:	dc6080e7          	jalr	-570(ra) # 80005094 <pipealloc>
    return -1;
    800062d6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062d8:	0c054463          	bltz	a0,800063a0 <sys_pipe+0xfc>
  fd0 = -1;
    800062dc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062e0:	fd043503          	ld	a0,-48(s0)
    800062e4:	fffff097          	auipc	ra,0xfffff
    800062e8:	51a080e7          	jalr	1306(ra) # 800057fe <fdalloc>
    800062ec:	fca42223          	sw	a0,-60(s0)
    800062f0:	08054b63          	bltz	a0,80006386 <sys_pipe+0xe2>
    800062f4:	fc843503          	ld	a0,-56(s0)
    800062f8:	fffff097          	auipc	ra,0xfffff
    800062fc:	506080e7          	jalr	1286(ra) # 800057fe <fdalloc>
    80006300:	fca42023          	sw	a0,-64(s0)
    80006304:	06054863          	bltz	a0,80006374 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006308:	4691                	li	a3,4
    8000630a:	fc440613          	addi	a2,s0,-60
    8000630e:	fd843583          	ld	a1,-40(s0)
    80006312:	68a8                	ld	a0,80(s1)
    80006314:	ffffb097          	auipc	ra,0xffffb
    80006318:	354080e7          	jalr	852(ra) # 80001668 <copyout>
    8000631c:	02054063          	bltz	a0,8000633c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006320:	4691                	li	a3,4
    80006322:	fc040613          	addi	a2,s0,-64
    80006326:	fd843583          	ld	a1,-40(s0)
    8000632a:	0591                	addi	a1,a1,4
    8000632c:	68a8                	ld	a0,80(s1)
    8000632e:	ffffb097          	auipc	ra,0xffffb
    80006332:	33a080e7          	jalr	826(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006336:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006338:	06055463          	bgez	a0,800063a0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000633c:	fc442783          	lw	a5,-60(s0)
    80006340:	07e9                	addi	a5,a5,26
    80006342:	078e                	slli	a5,a5,0x3
    80006344:	97a6                	add	a5,a5,s1
    80006346:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000634a:	fc042503          	lw	a0,-64(s0)
    8000634e:	0569                	addi	a0,a0,26
    80006350:	050e                	slli	a0,a0,0x3
    80006352:	94aa                	add	s1,s1,a0
    80006354:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006358:	fd043503          	ld	a0,-48(s0)
    8000635c:	fffff097          	auipc	ra,0xfffff
    80006360:	a08080e7          	jalr	-1528(ra) # 80004d64 <fileclose>
    fileclose(wf);
    80006364:	fc843503          	ld	a0,-56(s0)
    80006368:	fffff097          	auipc	ra,0xfffff
    8000636c:	9fc080e7          	jalr	-1540(ra) # 80004d64 <fileclose>
    return -1;
    80006370:	57fd                	li	a5,-1
    80006372:	a03d                	j	800063a0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006374:	fc442783          	lw	a5,-60(s0)
    80006378:	0007c763          	bltz	a5,80006386 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000637c:	07e9                	addi	a5,a5,26
    8000637e:	078e                	slli	a5,a5,0x3
    80006380:	94be                	add	s1,s1,a5
    80006382:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006386:	fd043503          	ld	a0,-48(s0)
    8000638a:	fffff097          	auipc	ra,0xfffff
    8000638e:	9da080e7          	jalr	-1574(ra) # 80004d64 <fileclose>
    fileclose(wf);
    80006392:	fc843503          	ld	a0,-56(s0)
    80006396:	fffff097          	auipc	ra,0xfffff
    8000639a:	9ce080e7          	jalr	-1586(ra) # 80004d64 <fileclose>
    return -1;
    8000639e:	57fd                	li	a5,-1
}
    800063a0:	853e                	mv	a0,a5
    800063a2:	70e2                	ld	ra,56(sp)
    800063a4:	7442                	ld	s0,48(sp)
    800063a6:	74a2                	ld	s1,40(sp)
    800063a8:	6121                	addi	sp,sp,64
    800063aa:	8082                	ret
    800063ac:	0000                	unimp
	...

00000000800063b0 <kernelvec>:
    800063b0:	7111                	addi	sp,sp,-256
    800063b2:	e006                	sd	ra,0(sp)
    800063b4:	e40a                	sd	sp,8(sp)
    800063b6:	e80e                	sd	gp,16(sp)
    800063b8:	ec12                	sd	tp,24(sp)
    800063ba:	f016                	sd	t0,32(sp)
    800063bc:	f41a                	sd	t1,40(sp)
    800063be:	f81e                	sd	t2,48(sp)
    800063c0:	fc22                	sd	s0,56(sp)
    800063c2:	e0a6                	sd	s1,64(sp)
    800063c4:	e4aa                	sd	a0,72(sp)
    800063c6:	e8ae                	sd	a1,80(sp)
    800063c8:	ecb2                	sd	a2,88(sp)
    800063ca:	f0b6                	sd	a3,96(sp)
    800063cc:	f4ba                	sd	a4,104(sp)
    800063ce:	f8be                	sd	a5,112(sp)
    800063d0:	fcc2                	sd	a6,120(sp)
    800063d2:	e146                	sd	a7,128(sp)
    800063d4:	e54a                	sd	s2,136(sp)
    800063d6:	e94e                	sd	s3,144(sp)
    800063d8:	ed52                	sd	s4,152(sp)
    800063da:	f156                	sd	s5,160(sp)
    800063dc:	f55a                	sd	s6,168(sp)
    800063de:	f95e                	sd	s7,176(sp)
    800063e0:	fd62                	sd	s8,184(sp)
    800063e2:	e1e6                	sd	s9,192(sp)
    800063e4:	e5ea                	sd	s10,200(sp)
    800063e6:	e9ee                	sd	s11,208(sp)
    800063e8:	edf2                	sd	t3,216(sp)
    800063ea:	f1f6                	sd	t4,224(sp)
    800063ec:	f5fa                	sd	t5,232(sp)
    800063ee:	f9fe                	sd	t6,240(sp)
    800063f0:	abffc0ef          	jal	ra,80002eae <kerneltrap>
    800063f4:	6082                	ld	ra,0(sp)
    800063f6:	6122                	ld	sp,8(sp)
    800063f8:	61c2                	ld	gp,16(sp)
    800063fa:	7282                	ld	t0,32(sp)
    800063fc:	7322                	ld	t1,40(sp)
    800063fe:	73c2                	ld	t2,48(sp)
    80006400:	7462                	ld	s0,56(sp)
    80006402:	6486                	ld	s1,64(sp)
    80006404:	6526                	ld	a0,72(sp)
    80006406:	65c6                	ld	a1,80(sp)
    80006408:	6666                	ld	a2,88(sp)
    8000640a:	7686                	ld	a3,96(sp)
    8000640c:	7726                	ld	a4,104(sp)
    8000640e:	77c6                	ld	a5,112(sp)
    80006410:	7866                	ld	a6,120(sp)
    80006412:	688a                	ld	a7,128(sp)
    80006414:	692a                	ld	s2,136(sp)
    80006416:	69ca                	ld	s3,144(sp)
    80006418:	6a6a                	ld	s4,152(sp)
    8000641a:	7a8a                	ld	s5,160(sp)
    8000641c:	7b2a                	ld	s6,168(sp)
    8000641e:	7bca                	ld	s7,176(sp)
    80006420:	7c6a                	ld	s8,184(sp)
    80006422:	6c8e                	ld	s9,192(sp)
    80006424:	6d2e                	ld	s10,200(sp)
    80006426:	6dce                	ld	s11,208(sp)
    80006428:	6e6e                	ld	t3,216(sp)
    8000642a:	7e8e                	ld	t4,224(sp)
    8000642c:	7f2e                	ld	t5,232(sp)
    8000642e:	7fce                	ld	t6,240(sp)
    80006430:	6111                	addi	sp,sp,256
    80006432:	10200073          	sret
    80006436:	00000013          	nop
    8000643a:	00000013          	nop
    8000643e:	0001                	nop

0000000080006440 <timervec>:
    80006440:	34051573          	csrrw	a0,mscratch,a0
    80006444:	e10c                	sd	a1,0(a0)
    80006446:	e510                	sd	a2,8(a0)
    80006448:	e914                	sd	a3,16(a0)
    8000644a:	6d0c                	ld	a1,24(a0)
    8000644c:	7110                	ld	a2,32(a0)
    8000644e:	6194                	ld	a3,0(a1)
    80006450:	96b2                	add	a3,a3,a2
    80006452:	e194                	sd	a3,0(a1)
    80006454:	4589                	li	a1,2
    80006456:	14459073          	csrw	sip,a1
    8000645a:	6914                	ld	a3,16(a0)
    8000645c:	6510                	ld	a2,8(a0)
    8000645e:	610c                	ld	a1,0(a0)
    80006460:	34051573          	csrrw	a0,mscratch,a0
    80006464:	30200073          	mret
	...

000000008000646a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000646a:	1141                	addi	sp,sp,-16
    8000646c:	e422                	sd	s0,8(sp)
    8000646e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006470:	0c0007b7          	lui	a5,0xc000
    80006474:	4705                	li	a4,1
    80006476:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006478:	c3d8                	sw	a4,4(a5)
}
    8000647a:	6422                	ld	s0,8(sp)
    8000647c:	0141                	addi	sp,sp,16
    8000647e:	8082                	ret

0000000080006480 <plicinithart>:

void
plicinithart(void)
{
    80006480:	1141                	addi	sp,sp,-16
    80006482:	e406                	sd	ra,8(sp)
    80006484:	e022                	sd	s0,0(sp)
    80006486:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006488:	ffffb097          	auipc	ra,0xffffb
    8000648c:	4f8080e7          	jalr	1272(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006490:	0085171b          	slliw	a4,a0,0x8
    80006494:	0c0027b7          	lui	a5,0xc002
    80006498:	97ba                	add	a5,a5,a4
    8000649a:	40200713          	li	a4,1026
    8000649e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064a2:	00d5151b          	slliw	a0,a0,0xd
    800064a6:	0c2017b7          	lui	a5,0xc201
    800064aa:	953e                	add	a0,a0,a5
    800064ac:	00052023          	sw	zero,0(a0)
}
    800064b0:	60a2                	ld	ra,8(sp)
    800064b2:	6402                	ld	s0,0(sp)
    800064b4:	0141                	addi	sp,sp,16
    800064b6:	8082                	ret

00000000800064b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064b8:	1141                	addi	sp,sp,-16
    800064ba:	e406                	sd	ra,8(sp)
    800064bc:	e022                	sd	s0,0(sp)
    800064be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064c0:	ffffb097          	auipc	ra,0xffffb
    800064c4:	4c0080e7          	jalr	1216(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064c8:	00d5179b          	slliw	a5,a0,0xd
    800064cc:	0c201537          	lui	a0,0xc201
    800064d0:	953e                	add	a0,a0,a5
  return irq;
}
    800064d2:	4148                	lw	a0,4(a0)
    800064d4:	60a2                	ld	ra,8(sp)
    800064d6:	6402                	ld	s0,0(sp)
    800064d8:	0141                	addi	sp,sp,16
    800064da:	8082                	ret

00000000800064dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064dc:	1101                	addi	sp,sp,-32
    800064de:	ec06                	sd	ra,24(sp)
    800064e0:	e822                	sd	s0,16(sp)
    800064e2:	e426                	sd	s1,8(sp)
    800064e4:	1000                	addi	s0,sp,32
    800064e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064e8:	ffffb097          	auipc	ra,0xffffb
    800064ec:	498080e7          	jalr	1176(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064f0:	00d5151b          	slliw	a0,a0,0xd
    800064f4:	0c2017b7          	lui	a5,0xc201
    800064f8:	97aa                	add	a5,a5,a0
    800064fa:	c3c4                	sw	s1,4(a5)
}
    800064fc:	60e2                	ld	ra,24(sp)
    800064fe:	6442                	ld	s0,16(sp)
    80006500:	64a2                	ld	s1,8(sp)
    80006502:	6105                	addi	sp,sp,32
    80006504:	8082                	ret

0000000080006506 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006506:	1141                	addi	sp,sp,-16
    80006508:	e406                	sd	ra,8(sp)
    8000650a:	e022                	sd	s0,0(sp)
    8000650c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000650e:	479d                	li	a5,7
    80006510:	04a7cc63          	blt	a5,a0,80006568 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006514:	00021797          	auipc	a5,0x21
    80006518:	d5c78793          	addi	a5,a5,-676 # 80027270 <disk>
    8000651c:	97aa                	add	a5,a5,a0
    8000651e:	0187c783          	lbu	a5,24(a5)
    80006522:	ebb9                	bnez	a5,80006578 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006524:	00451613          	slli	a2,a0,0x4
    80006528:	00021797          	auipc	a5,0x21
    8000652c:	d4878793          	addi	a5,a5,-696 # 80027270 <disk>
    80006530:	6394                	ld	a3,0(a5)
    80006532:	96b2                	add	a3,a3,a2
    80006534:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006538:	6398                	ld	a4,0(a5)
    8000653a:	9732                	add	a4,a4,a2
    8000653c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006540:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006544:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006548:	953e                	add	a0,a0,a5
    8000654a:	4785                	li	a5,1
    8000654c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006550:	00021517          	auipc	a0,0x21
    80006554:	d3850513          	addi	a0,a0,-712 # 80027288 <disk+0x18>
    80006558:	ffffc097          	auipc	ra,0xffffc
    8000655c:	eec080e7          	jalr	-276(ra) # 80002444 <wakeup>
}
    80006560:	60a2                	ld	ra,8(sp)
    80006562:	6402                	ld	s0,0(sp)
    80006564:	0141                	addi	sp,sp,16
    80006566:	8082                	ret
    panic("free_desc 1");
    80006568:	00002517          	auipc	a0,0x2
    8000656c:	23850513          	addi	a0,a0,568 # 800087a0 <syscalls+0x318>
    80006570:	ffffa097          	auipc	ra,0xffffa
    80006574:	fce080e7          	jalr	-50(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006578:	00002517          	auipc	a0,0x2
    8000657c:	23850513          	addi	a0,a0,568 # 800087b0 <syscalls+0x328>
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	fbe080e7          	jalr	-66(ra) # 8000053e <panic>

0000000080006588 <virtio_disk_init>:
{
    80006588:	1101                	addi	sp,sp,-32
    8000658a:	ec06                	sd	ra,24(sp)
    8000658c:	e822                	sd	s0,16(sp)
    8000658e:	e426                	sd	s1,8(sp)
    80006590:	e04a                	sd	s2,0(sp)
    80006592:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006594:	00002597          	auipc	a1,0x2
    80006598:	22c58593          	addi	a1,a1,556 # 800087c0 <syscalls+0x338>
    8000659c:	00021517          	auipc	a0,0x21
    800065a0:	dfc50513          	addi	a0,a0,-516 # 80027398 <disk+0x128>
    800065a4:	ffffa097          	auipc	ra,0xffffa
    800065a8:	5a2080e7          	jalr	1442(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065ac:	100017b7          	lui	a5,0x10001
    800065b0:	4398                	lw	a4,0(a5)
    800065b2:	2701                	sext.w	a4,a4
    800065b4:	747277b7          	lui	a5,0x74727
    800065b8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065bc:	14f71c63          	bne	a4,a5,80006714 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065c0:	100017b7          	lui	a5,0x10001
    800065c4:	43dc                	lw	a5,4(a5)
    800065c6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065c8:	4709                	li	a4,2
    800065ca:	14e79563          	bne	a5,a4,80006714 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065ce:	100017b7          	lui	a5,0x10001
    800065d2:	479c                	lw	a5,8(a5)
    800065d4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065d6:	12e79f63          	bne	a5,a4,80006714 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065da:	100017b7          	lui	a5,0x10001
    800065de:	47d8                	lw	a4,12(a5)
    800065e0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065e2:	554d47b7          	lui	a5,0x554d4
    800065e6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065ea:	12f71563          	bne	a4,a5,80006714 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065ee:	100017b7          	lui	a5,0x10001
    800065f2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065f6:	4705                	li	a4,1
    800065f8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065fa:	470d                	li	a4,3
    800065fc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065fe:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006600:	c7ffe737          	lui	a4,0xc7ffe
    80006604:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd73af>
    80006608:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000660a:	2701                	sext.w	a4,a4
    8000660c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000660e:	472d                	li	a4,11
    80006610:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006612:	5bbc                	lw	a5,112(a5)
    80006614:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006618:	8ba1                	andi	a5,a5,8
    8000661a:	10078563          	beqz	a5,80006724 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000661e:	100017b7          	lui	a5,0x10001
    80006622:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006626:	43fc                	lw	a5,68(a5)
    80006628:	2781                	sext.w	a5,a5
    8000662a:	10079563          	bnez	a5,80006734 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000662e:	100017b7          	lui	a5,0x10001
    80006632:	5bdc                	lw	a5,52(a5)
    80006634:	2781                	sext.w	a5,a5
  if(max == 0)
    80006636:	10078763          	beqz	a5,80006744 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000663a:	471d                	li	a4,7
    8000663c:	10f77c63          	bgeu	a4,a5,80006754 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006640:	ffffa097          	auipc	ra,0xffffa
    80006644:	4a6080e7          	jalr	1190(ra) # 80000ae6 <kalloc>
    80006648:	00021497          	auipc	s1,0x21
    8000664c:	c2848493          	addi	s1,s1,-984 # 80027270 <disk>
    80006650:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006652:	ffffa097          	auipc	ra,0xffffa
    80006656:	494080e7          	jalr	1172(ra) # 80000ae6 <kalloc>
    8000665a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000665c:	ffffa097          	auipc	ra,0xffffa
    80006660:	48a080e7          	jalr	1162(ra) # 80000ae6 <kalloc>
    80006664:	87aa                	mv	a5,a0
    80006666:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006668:	6088                	ld	a0,0(s1)
    8000666a:	cd6d                	beqz	a0,80006764 <virtio_disk_init+0x1dc>
    8000666c:	00021717          	auipc	a4,0x21
    80006670:	c0c73703          	ld	a4,-1012(a4) # 80027278 <disk+0x8>
    80006674:	cb65                	beqz	a4,80006764 <virtio_disk_init+0x1dc>
    80006676:	c7fd                	beqz	a5,80006764 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006678:	6605                	lui	a2,0x1
    8000667a:	4581                	li	a1,0
    8000667c:	ffffa097          	auipc	ra,0xffffa
    80006680:	656080e7          	jalr	1622(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006684:	00021497          	auipc	s1,0x21
    80006688:	bec48493          	addi	s1,s1,-1044 # 80027270 <disk>
    8000668c:	6605                	lui	a2,0x1
    8000668e:	4581                	li	a1,0
    80006690:	6488                	ld	a0,8(s1)
    80006692:	ffffa097          	auipc	ra,0xffffa
    80006696:	640080e7          	jalr	1600(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000669a:	6605                	lui	a2,0x1
    8000669c:	4581                	li	a1,0
    8000669e:	6888                	ld	a0,16(s1)
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	632080e7          	jalr	1586(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800066a8:	100017b7          	lui	a5,0x10001
    800066ac:	4721                	li	a4,8
    800066ae:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800066b0:	4098                	lw	a4,0(s1)
    800066b2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800066b6:	40d8                	lw	a4,4(s1)
    800066b8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800066bc:	6498                	ld	a4,8(s1)
    800066be:	0007069b          	sext.w	a3,a4
    800066c2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800066c6:	9701                	srai	a4,a4,0x20
    800066c8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800066cc:	6898                	ld	a4,16(s1)
    800066ce:	0007069b          	sext.w	a3,a4
    800066d2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800066d6:	9701                	srai	a4,a4,0x20
    800066d8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800066dc:	4705                	li	a4,1
    800066de:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800066e0:	00e48c23          	sb	a4,24(s1)
    800066e4:	00e48ca3          	sb	a4,25(s1)
    800066e8:	00e48d23          	sb	a4,26(s1)
    800066ec:	00e48da3          	sb	a4,27(s1)
    800066f0:	00e48e23          	sb	a4,28(s1)
    800066f4:	00e48ea3          	sb	a4,29(s1)
    800066f8:	00e48f23          	sb	a4,30(s1)
    800066fc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006700:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006704:	0727a823          	sw	s2,112(a5)
}
    80006708:	60e2                	ld	ra,24(sp)
    8000670a:	6442                	ld	s0,16(sp)
    8000670c:	64a2                	ld	s1,8(sp)
    8000670e:	6902                	ld	s2,0(sp)
    80006710:	6105                	addi	sp,sp,32
    80006712:	8082                	ret
    panic("could not find virtio disk");
    80006714:	00002517          	auipc	a0,0x2
    80006718:	0bc50513          	addi	a0,a0,188 # 800087d0 <syscalls+0x348>
    8000671c:	ffffa097          	auipc	ra,0xffffa
    80006720:	e22080e7          	jalr	-478(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006724:	00002517          	auipc	a0,0x2
    80006728:	0cc50513          	addi	a0,a0,204 # 800087f0 <syscalls+0x368>
    8000672c:	ffffa097          	auipc	ra,0xffffa
    80006730:	e12080e7          	jalr	-494(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006734:	00002517          	auipc	a0,0x2
    80006738:	0dc50513          	addi	a0,a0,220 # 80008810 <syscalls+0x388>
    8000673c:	ffffa097          	auipc	ra,0xffffa
    80006740:	e02080e7          	jalr	-510(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006744:	00002517          	auipc	a0,0x2
    80006748:	0ec50513          	addi	a0,a0,236 # 80008830 <syscalls+0x3a8>
    8000674c:	ffffa097          	auipc	ra,0xffffa
    80006750:	df2080e7          	jalr	-526(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006754:	00002517          	auipc	a0,0x2
    80006758:	0fc50513          	addi	a0,a0,252 # 80008850 <syscalls+0x3c8>
    8000675c:	ffffa097          	auipc	ra,0xffffa
    80006760:	de2080e7          	jalr	-542(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006764:	00002517          	auipc	a0,0x2
    80006768:	10c50513          	addi	a0,a0,268 # 80008870 <syscalls+0x3e8>
    8000676c:	ffffa097          	auipc	ra,0xffffa
    80006770:	dd2080e7          	jalr	-558(ra) # 8000053e <panic>

0000000080006774 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006774:	7119                	addi	sp,sp,-128
    80006776:	fc86                	sd	ra,120(sp)
    80006778:	f8a2                	sd	s0,112(sp)
    8000677a:	f4a6                	sd	s1,104(sp)
    8000677c:	f0ca                	sd	s2,96(sp)
    8000677e:	ecce                	sd	s3,88(sp)
    80006780:	e8d2                	sd	s4,80(sp)
    80006782:	e4d6                	sd	s5,72(sp)
    80006784:	e0da                	sd	s6,64(sp)
    80006786:	fc5e                	sd	s7,56(sp)
    80006788:	f862                	sd	s8,48(sp)
    8000678a:	f466                	sd	s9,40(sp)
    8000678c:	f06a                	sd	s10,32(sp)
    8000678e:	ec6e                	sd	s11,24(sp)
    80006790:	0100                	addi	s0,sp,128
    80006792:	8aaa                	mv	s5,a0
    80006794:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006796:	00c52d03          	lw	s10,12(a0)
    8000679a:	001d1d1b          	slliw	s10,s10,0x1
    8000679e:	1d02                	slli	s10,s10,0x20
    800067a0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800067a4:	00021517          	auipc	a0,0x21
    800067a8:	bf450513          	addi	a0,a0,-1036 # 80027398 <disk+0x128>
    800067ac:	ffffa097          	auipc	ra,0xffffa
    800067b0:	42a080e7          	jalr	1066(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800067b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800067b6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800067b8:	00021b97          	auipc	s7,0x21
    800067bc:	ab8b8b93          	addi	s7,s7,-1352 # 80027270 <disk>
  for(int i = 0; i < 3; i++){
    800067c0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067c2:	00021c97          	auipc	s9,0x21
    800067c6:	bd6c8c93          	addi	s9,s9,-1066 # 80027398 <disk+0x128>
    800067ca:	a08d                	j	8000682c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800067cc:	00fb8733          	add	a4,s7,a5
    800067d0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800067d4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800067d6:	0207c563          	bltz	a5,80006800 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800067da:	2905                	addiw	s2,s2,1
    800067dc:	0611                	addi	a2,a2,4
    800067de:	05690c63          	beq	s2,s6,80006836 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800067e2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800067e4:	00021717          	auipc	a4,0x21
    800067e8:	a8c70713          	addi	a4,a4,-1396 # 80027270 <disk>
    800067ec:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800067ee:	01874683          	lbu	a3,24(a4)
    800067f2:	fee9                	bnez	a3,800067cc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800067f4:	2785                	addiw	a5,a5,1
    800067f6:	0705                	addi	a4,a4,1
    800067f8:	fe979be3          	bne	a5,s1,800067ee <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800067fc:	57fd                	li	a5,-1
    800067fe:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006800:	01205d63          	blez	s2,8000681a <virtio_disk_rw+0xa6>
    80006804:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006806:	000a2503          	lw	a0,0(s4)
    8000680a:	00000097          	auipc	ra,0x0
    8000680e:	cfc080e7          	jalr	-772(ra) # 80006506 <free_desc>
      for(int j = 0; j < i; j++)
    80006812:	2d85                	addiw	s11,s11,1
    80006814:	0a11                	addi	s4,s4,4
    80006816:	ffb918e3          	bne	s2,s11,80006806 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000681a:	85e6                	mv	a1,s9
    8000681c:	00021517          	auipc	a0,0x21
    80006820:	a6c50513          	addi	a0,a0,-1428 # 80027288 <disk+0x18>
    80006824:	ffffc097          	auipc	ra,0xffffc
    80006828:	bbc080e7          	jalr	-1092(ra) # 800023e0 <sleep>
  for(int i = 0; i < 3; i++){
    8000682c:	f8040a13          	addi	s4,s0,-128
{
    80006830:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006832:	894e                	mv	s2,s3
    80006834:	b77d                	j	800067e2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006836:	f8042583          	lw	a1,-128(s0)
    8000683a:	00a58793          	addi	a5,a1,10
    8000683e:	0792                	slli	a5,a5,0x4

  if(write)
    80006840:	00021617          	auipc	a2,0x21
    80006844:	a3060613          	addi	a2,a2,-1488 # 80027270 <disk>
    80006848:	00f60733          	add	a4,a2,a5
    8000684c:	018036b3          	snez	a3,s8
    80006850:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006852:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006856:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000685a:	f6078693          	addi	a3,a5,-160
    8000685e:	6218                	ld	a4,0(a2)
    80006860:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006862:	00878513          	addi	a0,a5,8
    80006866:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006868:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000686a:	6208                	ld	a0,0(a2)
    8000686c:	96aa                	add	a3,a3,a0
    8000686e:	4741                	li	a4,16
    80006870:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006872:	4705                	li	a4,1
    80006874:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006878:	f8442703          	lw	a4,-124(s0)
    8000687c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006880:	0712                	slli	a4,a4,0x4
    80006882:	953a                	add	a0,a0,a4
    80006884:	058a8693          	addi	a3,s5,88
    80006888:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000688a:	6208                	ld	a0,0(a2)
    8000688c:	972a                	add	a4,a4,a0
    8000688e:	40000693          	li	a3,1024
    80006892:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006894:	001c3c13          	seqz	s8,s8
    80006898:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000689a:	001c6c13          	ori	s8,s8,1
    8000689e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800068a2:	f8842603          	lw	a2,-120(s0)
    800068a6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800068aa:	00021697          	auipc	a3,0x21
    800068ae:	9c668693          	addi	a3,a3,-1594 # 80027270 <disk>
    800068b2:	00258713          	addi	a4,a1,2
    800068b6:	0712                	slli	a4,a4,0x4
    800068b8:	9736                	add	a4,a4,a3
    800068ba:	587d                	li	a6,-1
    800068bc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068c0:	0612                	slli	a2,a2,0x4
    800068c2:	9532                	add	a0,a0,a2
    800068c4:	f9078793          	addi	a5,a5,-112
    800068c8:	97b6                	add	a5,a5,a3
    800068ca:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800068cc:	629c                	ld	a5,0(a3)
    800068ce:	97b2                	add	a5,a5,a2
    800068d0:	4605                	li	a2,1
    800068d2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068d4:	4509                	li	a0,2
    800068d6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800068da:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800068de:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800068e2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800068e6:	6698                	ld	a4,8(a3)
    800068e8:	00275783          	lhu	a5,2(a4)
    800068ec:	8b9d                	andi	a5,a5,7
    800068ee:	0786                	slli	a5,a5,0x1
    800068f0:	97ba                	add	a5,a5,a4
    800068f2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800068f6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800068fa:	6698                	ld	a4,8(a3)
    800068fc:	00275783          	lhu	a5,2(a4)
    80006900:	2785                	addiw	a5,a5,1
    80006902:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006906:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000690a:	100017b7          	lui	a5,0x10001
    8000690e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006912:	004aa783          	lw	a5,4(s5)
    80006916:	02c79163          	bne	a5,a2,80006938 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000691a:	00021917          	auipc	s2,0x21
    8000691e:	a7e90913          	addi	s2,s2,-1410 # 80027398 <disk+0x128>
  while(b->disk == 1) {
    80006922:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006924:	85ca                	mv	a1,s2
    80006926:	8556                	mv	a0,s5
    80006928:	ffffc097          	auipc	ra,0xffffc
    8000692c:	ab8080e7          	jalr	-1352(ra) # 800023e0 <sleep>
  while(b->disk == 1) {
    80006930:	004aa783          	lw	a5,4(s5)
    80006934:	fe9788e3          	beq	a5,s1,80006924 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006938:	f8042903          	lw	s2,-128(s0)
    8000693c:	00290793          	addi	a5,s2,2
    80006940:	00479713          	slli	a4,a5,0x4
    80006944:	00021797          	auipc	a5,0x21
    80006948:	92c78793          	addi	a5,a5,-1748 # 80027270 <disk>
    8000694c:	97ba                	add	a5,a5,a4
    8000694e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006952:	00021997          	auipc	s3,0x21
    80006956:	91e98993          	addi	s3,s3,-1762 # 80027270 <disk>
    8000695a:	00491713          	slli	a4,s2,0x4
    8000695e:	0009b783          	ld	a5,0(s3)
    80006962:	97ba                	add	a5,a5,a4
    80006964:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006968:	854a                	mv	a0,s2
    8000696a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000696e:	00000097          	auipc	ra,0x0
    80006972:	b98080e7          	jalr	-1128(ra) # 80006506 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006976:	8885                	andi	s1,s1,1
    80006978:	f0ed                	bnez	s1,8000695a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000697a:	00021517          	auipc	a0,0x21
    8000697e:	a1e50513          	addi	a0,a0,-1506 # 80027398 <disk+0x128>
    80006982:	ffffa097          	auipc	ra,0xffffa
    80006986:	308080e7          	jalr	776(ra) # 80000c8a <release>
}
    8000698a:	70e6                	ld	ra,120(sp)
    8000698c:	7446                	ld	s0,112(sp)
    8000698e:	74a6                	ld	s1,104(sp)
    80006990:	7906                	ld	s2,96(sp)
    80006992:	69e6                	ld	s3,88(sp)
    80006994:	6a46                	ld	s4,80(sp)
    80006996:	6aa6                	ld	s5,72(sp)
    80006998:	6b06                	ld	s6,64(sp)
    8000699a:	7be2                	ld	s7,56(sp)
    8000699c:	7c42                	ld	s8,48(sp)
    8000699e:	7ca2                	ld	s9,40(sp)
    800069a0:	7d02                	ld	s10,32(sp)
    800069a2:	6de2                	ld	s11,24(sp)
    800069a4:	6109                	addi	sp,sp,128
    800069a6:	8082                	ret

00000000800069a8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800069a8:	1101                	addi	sp,sp,-32
    800069aa:	ec06                	sd	ra,24(sp)
    800069ac:	e822                	sd	s0,16(sp)
    800069ae:	e426                	sd	s1,8(sp)
    800069b0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069b2:	00021497          	auipc	s1,0x21
    800069b6:	8be48493          	addi	s1,s1,-1858 # 80027270 <disk>
    800069ba:	00021517          	auipc	a0,0x21
    800069be:	9de50513          	addi	a0,a0,-1570 # 80027398 <disk+0x128>
    800069c2:	ffffa097          	auipc	ra,0xffffa
    800069c6:	214080e7          	jalr	532(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069ca:	10001737          	lui	a4,0x10001
    800069ce:	533c                	lw	a5,96(a4)
    800069d0:	8b8d                	andi	a5,a5,3
    800069d2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069d4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069d8:	689c                	ld	a5,16(s1)
    800069da:	0204d703          	lhu	a4,32(s1)
    800069de:	0027d783          	lhu	a5,2(a5)
    800069e2:	04f70863          	beq	a4,a5,80006a32 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800069e6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069ea:	6898                	ld	a4,16(s1)
    800069ec:	0204d783          	lhu	a5,32(s1)
    800069f0:	8b9d                	andi	a5,a5,7
    800069f2:	078e                	slli	a5,a5,0x3
    800069f4:	97ba                	add	a5,a5,a4
    800069f6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069f8:	00278713          	addi	a4,a5,2
    800069fc:	0712                	slli	a4,a4,0x4
    800069fe:	9726                	add	a4,a4,s1
    80006a00:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006a04:	e721                	bnez	a4,80006a4c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a06:	0789                	addi	a5,a5,2
    80006a08:	0792                	slli	a5,a5,0x4
    80006a0a:	97a6                	add	a5,a5,s1
    80006a0c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006a0e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a12:	ffffc097          	auipc	ra,0xffffc
    80006a16:	a32080e7          	jalr	-1486(ra) # 80002444 <wakeup>

    disk.used_idx += 1;
    80006a1a:	0204d783          	lhu	a5,32(s1)
    80006a1e:	2785                	addiw	a5,a5,1
    80006a20:	17c2                	slli	a5,a5,0x30
    80006a22:	93c1                	srli	a5,a5,0x30
    80006a24:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a28:	6898                	ld	a4,16(s1)
    80006a2a:	00275703          	lhu	a4,2(a4)
    80006a2e:	faf71ce3          	bne	a4,a5,800069e6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006a32:	00021517          	auipc	a0,0x21
    80006a36:	96650513          	addi	a0,a0,-1690 # 80027398 <disk+0x128>
    80006a3a:	ffffa097          	auipc	ra,0xffffa
    80006a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80006a42:	60e2                	ld	ra,24(sp)
    80006a44:	6442                	ld	s0,16(sp)
    80006a46:	64a2                	ld	s1,8(sp)
    80006a48:	6105                	addi	sp,sp,32
    80006a4a:	8082                	ret
      panic("virtio_disk_intr status");
    80006a4c:	00002517          	auipc	a0,0x2
    80006a50:	e3c50513          	addi	a0,a0,-452 # 80008888 <syscalls+0x400>
    80006a54:	ffffa097          	auipc	ra,0xffffa
    80006a58:	aea080e7          	jalr	-1302(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
