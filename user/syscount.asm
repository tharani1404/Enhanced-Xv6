
user/_syscount:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <syscallname>:
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"
char *syscallname(int mask) {
    int syscall_num = -1;
    while ((mask >>= 1) != 0)
   0:	8505                	srai	a0,a0,0x1
   2:	c935                	beqz	a0,76 <syscallname+0x76>
char *syscallname(int mask) {
   4:	7131                	addi	sp,sp,-192
   6:	fd22                	sd	s0,184(sp)
   8:	0180                	addi	s0,sp,192
    int syscall_num = -1;
   a:	577d                	li	a4,-1
        syscall_num++;
   c:	2705                	addiw	a4,a4,1
    while ((mask >>= 1) != 0)
   e:	4015551b          	sraiw	a0,a0,0x1
  12:	fd6d                	bnez	a0,c <syscallname+0xc>

    char *syscalls[] = {
  14:	00001797          	auipc	a5,0x1
  18:	a7478793          	addi	a5,a5,-1420 # a88 <malloc+0x242>
  1c:	f4040693          	addi	a3,s0,-192
  20:	00001897          	auipc	a7,0x1
  24:	b0888893          	addi	a7,a7,-1272 # b28 <malloc+0x2e2>
  28:	0007b803          	ld	a6,0(a5)
  2c:	6788                	ld	a0,8(a5)
  2e:	6b8c                	ld	a1,16(a5)
  30:	6f90                	ld	a2,24(a5)
  32:	0106b023          	sd	a6,0(a3)
  36:	e688                	sd	a0,8(a3)
  38:	ea8c                	sd	a1,16(a3)
  3a:	ee90                	sd	a2,24(a3)
  3c:	02078793          	addi	a5,a5,32
  40:	02068693          	addi	a3,a3,32
  44:	ff1792e3          	bne	a5,a7,28 <syscallname+0x28>
  48:	6390                	ld	a2,0(a5)
  4a:	679c                	ld	a5,8(a5)
  4c:	e290                	sd	a2,0(a3)
  4e:	e69c                	sd	a5,8(a3)
        "fork", "exit", "wait", "pipe", "read", "kill", "exec", "fstat", "chdir",
        "dup", "getpid", "sbrk", "sleep", "uptime", "open", "write", "mknod", "unlink", 
        "link", "mkdir", "close","waitx"
    };

    if (syscall_num >= 0 && syscall_num < sizeof(syscalls) / sizeof(syscalls[0])) {
  50:	0007079b          	sext.w	a5,a4
  54:	46d5                	li	a3,21
        return syscalls[syscall_num];
    }
    return "unknown";
  56:	00001517          	auipc	a0,0x1
  5a:	98a50513          	addi	a0,a0,-1654 # 9e0 <malloc+0x19a>
    if (syscall_num >= 0 && syscall_num < sizeof(syscalls) / sizeof(syscalls[0])) {
  5e:	00f6f563          	bgeu	a3,a5,68 <syscallname+0x68>
}
  62:	746a                	ld	s0,184(sp)
  64:	6129                	addi	sp,sp,192
  66:	8082                	ret
        return syscalls[syscall_num];
  68:	070e                	slli	a4,a4,0x3
  6a:	ff040793          	addi	a5,s0,-16
  6e:	973e                	add	a4,a4,a5
  70:	f5073503          	ld	a0,-176(a4)
  74:	b7fd                	j	62 <syscallname+0x62>
    return "unknown";
  76:	00001517          	auipc	a0,0x1
  7a:	96a50513          	addi	a0,a0,-1686 # 9e0 <malloc+0x19a>
}
  7e:	8082                	ret

0000000000000080 <main>:



int main(int argc, char *argv[]) {
  80:	7139                	addi	sp,sp,-64
  82:	fc06                	sd	ra,56(sp)
  84:	f822                	sd	s0,48(sp)
  86:	f426                	sd	s1,40(sp)
  88:	f04a                	sd	s2,32(sp)
  8a:	ec4e                	sd	s3,24(sp)
  8c:	0080                	addi	s0,sp,64
    if (argc < 3) {
  8e:	4789                	li	a5,2
  90:	00a7cf63          	blt	a5,a0,ae <main+0x2e>
        printf("Usage: syscount <mask> command [args]\n");
  94:	00001517          	auipc	a0,0x1
  98:	95450513          	addi	a0,a0,-1708 # 9e8 <malloc+0x1a2>
  9c:	00000097          	auipc	ra,0x0
  a0:	6ec080e7          	jalr	1772(ra) # 788 <printf>
        exit(1);
  a4:	4505                	li	a0,1
  a6:	00000097          	auipc	ra,0x0
  aa:	342080e7          	jalr	834(ra) # 3e8 <exit>
  ae:	84ae                	mv	s1,a1
    }

    int mask = atoi(argv[1]);
  b0:	6588                	ld	a0,8(a1)
  b2:	00000097          	auipc	ra,0x0
  b6:	23a080e7          	jalr	570(ra) # 2ec <atoi>
  ba:	89aa                	mv	s3,a0
    int pid = fork();
  bc:	00000097          	auipc	ra,0x0
  c0:	324080e7          	jalr	804(ra) # 3e0 <fork>
  c4:	892a                	mv	s2,a0

    if (pid == 0) {
  c6:	c139                	beqz	a0,10c <main+0x8c>
        exec(argv[2], &argv[2]);
        printf("Error: exec failed\n");
        exit(1);
    } else if (pid > 0) {
  c8:	06a05f63          	blez	a0,146 <main+0xc6>
        int status;
        wait(&status);
  cc:	fcc40513          	addi	a0,s0,-52
  d0:	00000097          	auipc	ra,0x0
  d4:	320080e7          	jalr	800(ra) # 3f0 <wait>
        int count = getSysCount(mask,pid);
  d8:	85ca                	mv	a1,s2
  da:	854e                	mv	a0,s3
  dc:	00000097          	auipc	ra,0x0
  e0:	3b4080e7          	jalr	948(ra) # 490 <getSysCount>
  e4:	84aa                	mv	s1,a0
        if (count >= 0) {
  e6:	04054763          	bltz	a0,134 <main+0xb4>
            printf("PID %d called %s %d times.\n", pid, syscallname(mask), count);
  ea:	854e                	mv	a0,s3
  ec:	00000097          	auipc	ra,0x0
  f0:	f14080e7          	jalr	-236(ra) # 0 <syscallname>
  f4:	862a                	mv	a2,a0
  f6:	86a6                	mv	a3,s1
  f8:	85ca                	mv	a1,s2
  fa:	00001517          	auipc	a0,0x1
  fe:	92e50513          	addi	a0,a0,-1746 # a28 <malloc+0x1e2>
 102:	00000097          	auipc	ra,0x0
 106:	686080e7          	jalr	1670(ra) # 788 <printf>
 10a:	a0b1                	j	156 <main+0xd6>
        exec(argv[2], &argv[2]);
 10c:	01048593          	addi	a1,s1,16
 110:	6888                	ld	a0,16(s1)
 112:	00000097          	auipc	ra,0x0
 116:	30e080e7          	jalr	782(ra) # 420 <exec>
        printf("Error: exec failed\n");
 11a:	00001517          	auipc	a0,0x1
 11e:	8f650513          	addi	a0,a0,-1802 # a10 <malloc+0x1ca>
 122:	00000097          	auipc	ra,0x0
 126:	666080e7          	jalr	1638(ra) # 788 <printf>
        exit(1);
 12a:	4505                	li	a0,1
 12c:	00000097          	auipc	ra,0x0
 130:	2bc080e7          	jalr	700(ra) # 3e8 <exit>
        } else {
            printf("Error: failed to get system call count\n");
 134:	00001517          	auipc	a0,0x1
 138:	91450513          	addi	a0,a0,-1772 # a48 <malloc+0x202>
 13c:	00000097          	auipc	ra,0x0
 140:	64c080e7          	jalr	1612(ra) # 788 <printf>
 144:	a809                	j	156 <main+0xd6>
        }
    } else {
        printf("Error: fork failed\n");
 146:	00001517          	auipc	a0,0x1
 14a:	92a50513          	addi	a0,a0,-1750 # a70 <malloc+0x22a>
 14e:	00000097          	auipc	ra,0x0
 152:	63a080e7          	jalr	1594(ra) # 788 <printf>
    }

    exit(0);
 156:	4501                	li	a0,0
 158:	00000097          	auipc	ra,0x0
 15c:	290080e7          	jalr	656(ra) # 3e8 <exit>

0000000000000160 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 160:	1141                	addi	sp,sp,-16
 162:	e406                	sd	ra,8(sp)
 164:	e022                	sd	s0,0(sp)
 166:	0800                	addi	s0,sp,16
  extern int main();
  main();
 168:	00000097          	auipc	ra,0x0
 16c:	f18080e7          	jalr	-232(ra) # 80 <main>
  exit(0);
 170:	4501                	li	a0,0
 172:	00000097          	auipc	ra,0x0
 176:	276080e7          	jalr	630(ra) # 3e8 <exit>

000000000000017a <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 17a:	1141                	addi	sp,sp,-16
 17c:	e422                	sd	s0,8(sp)
 17e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 180:	87aa                	mv	a5,a0
 182:	0585                	addi	a1,a1,1
 184:	0785                	addi	a5,a5,1
 186:	fff5c703          	lbu	a4,-1(a1)
 18a:	fee78fa3          	sb	a4,-1(a5)
 18e:	fb75                	bnez	a4,182 <strcpy+0x8>
    ;
  return os;
}
 190:	6422                	ld	s0,8(sp)
 192:	0141                	addi	sp,sp,16
 194:	8082                	ret

0000000000000196 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 196:	1141                	addi	sp,sp,-16
 198:	e422                	sd	s0,8(sp)
 19a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 19c:	00054783          	lbu	a5,0(a0)
 1a0:	cb91                	beqz	a5,1b4 <strcmp+0x1e>
 1a2:	0005c703          	lbu	a4,0(a1)
 1a6:	00f71763          	bne	a4,a5,1b4 <strcmp+0x1e>
    p++, q++;
 1aa:	0505                	addi	a0,a0,1
 1ac:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1ae:	00054783          	lbu	a5,0(a0)
 1b2:	fbe5                	bnez	a5,1a2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1b4:	0005c503          	lbu	a0,0(a1)
}
 1b8:	40a7853b          	subw	a0,a5,a0
 1bc:	6422                	ld	s0,8(sp)
 1be:	0141                	addi	sp,sp,16
 1c0:	8082                	ret

00000000000001c2 <strlen>:

uint
strlen(const char *s)
{
 1c2:	1141                	addi	sp,sp,-16
 1c4:	e422                	sd	s0,8(sp)
 1c6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1c8:	00054783          	lbu	a5,0(a0)
 1cc:	cf91                	beqz	a5,1e8 <strlen+0x26>
 1ce:	0505                	addi	a0,a0,1
 1d0:	87aa                	mv	a5,a0
 1d2:	4685                	li	a3,1
 1d4:	9e89                	subw	a3,a3,a0
 1d6:	00f6853b          	addw	a0,a3,a5
 1da:	0785                	addi	a5,a5,1
 1dc:	fff7c703          	lbu	a4,-1(a5)
 1e0:	fb7d                	bnez	a4,1d6 <strlen+0x14>
    ;
  return n;
}
 1e2:	6422                	ld	s0,8(sp)
 1e4:	0141                	addi	sp,sp,16
 1e6:	8082                	ret
  for(n = 0; s[n]; n++)
 1e8:	4501                	li	a0,0
 1ea:	bfe5                	j	1e2 <strlen+0x20>

00000000000001ec <memset>:

void*
memset(void *dst, int c, uint n)
{
 1ec:	1141                	addi	sp,sp,-16
 1ee:	e422                	sd	s0,8(sp)
 1f0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1f2:	ca19                	beqz	a2,208 <memset+0x1c>
 1f4:	87aa                	mv	a5,a0
 1f6:	1602                	slli	a2,a2,0x20
 1f8:	9201                	srli	a2,a2,0x20
 1fa:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 1fe:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 202:	0785                	addi	a5,a5,1
 204:	fee79de3          	bne	a5,a4,1fe <memset+0x12>
  }
  return dst;
}
 208:	6422                	ld	s0,8(sp)
 20a:	0141                	addi	sp,sp,16
 20c:	8082                	ret

000000000000020e <strchr>:

char*
strchr(const char *s, char c)
{
 20e:	1141                	addi	sp,sp,-16
 210:	e422                	sd	s0,8(sp)
 212:	0800                	addi	s0,sp,16
  for(; *s; s++)
 214:	00054783          	lbu	a5,0(a0)
 218:	cb99                	beqz	a5,22e <strchr+0x20>
    if(*s == c)
 21a:	00f58763          	beq	a1,a5,228 <strchr+0x1a>
  for(; *s; s++)
 21e:	0505                	addi	a0,a0,1
 220:	00054783          	lbu	a5,0(a0)
 224:	fbfd                	bnez	a5,21a <strchr+0xc>
      return (char*)s;
  return 0;
 226:	4501                	li	a0,0
}
 228:	6422                	ld	s0,8(sp)
 22a:	0141                	addi	sp,sp,16
 22c:	8082                	ret
  return 0;
 22e:	4501                	li	a0,0
 230:	bfe5                	j	228 <strchr+0x1a>

0000000000000232 <gets>:

char*
gets(char *buf, int max)
{
 232:	711d                	addi	sp,sp,-96
 234:	ec86                	sd	ra,88(sp)
 236:	e8a2                	sd	s0,80(sp)
 238:	e4a6                	sd	s1,72(sp)
 23a:	e0ca                	sd	s2,64(sp)
 23c:	fc4e                	sd	s3,56(sp)
 23e:	f852                	sd	s4,48(sp)
 240:	f456                	sd	s5,40(sp)
 242:	f05a                	sd	s6,32(sp)
 244:	ec5e                	sd	s7,24(sp)
 246:	1080                	addi	s0,sp,96
 248:	8baa                	mv	s7,a0
 24a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 24c:	892a                	mv	s2,a0
 24e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 250:	4aa9                	li	s5,10
 252:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 254:	89a6                	mv	s3,s1
 256:	2485                	addiw	s1,s1,1
 258:	0344d863          	bge	s1,s4,288 <gets+0x56>
    cc = read(0, &c, 1);
 25c:	4605                	li	a2,1
 25e:	faf40593          	addi	a1,s0,-81
 262:	4501                	li	a0,0
 264:	00000097          	auipc	ra,0x0
 268:	19c080e7          	jalr	412(ra) # 400 <read>
    if(cc < 1)
 26c:	00a05e63          	blez	a0,288 <gets+0x56>
    buf[i++] = c;
 270:	faf44783          	lbu	a5,-81(s0)
 274:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 278:	01578763          	beq	a5,s5,286 <gets+0x54>
 27c:	0905                	addi	s2,s2,1
 27e:	fd679be3          	bne	a5,s6,254 <gets+0x22>
  for(i=0; i+1 < max; ){
 282:	89a6                	mv	s3,s1
 284:	a011                	j	288 <gets+0x56>
 286:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 288:	99de                	add	s3,s3,s7
 28a:	00098023          	sb	zero,0(s3)
  return buf;
}
 28e:	855e                	mv	a0,s7
 290:	60e6                	ld	ra,88(sp)
 292:	6446                	ld	s0,80(sp)
 294:	64a6                	ld	s1,72(sp)
 296:	6906                	ld	s2,64(sp)
 298:	79e2                	ld	s3,56(sp)
 29a:	7a42                	ld	s4,48(sp)
 29c:	7aa2                	ld	s5,40(sp)
 29e:	7b02                	ld	s6,32(sp)
 2a0:	6be2                	ld	s7,24(sp)
 2a2:	6125                	addi	sp,sp,96
 2a4:	8082                	ret

00000000000002a6 <stat>:

int
stat(const char *n, struct stat *st)
{
 2a6:	1101                	addi	sp,sp,-32
 2a8:	ec06                	sd	ra,24(sp)
 2aa:	e822                	sd	s0,16(sp)
 2ac:	e426                	sd	s1,8(sp)
 2ae:	e04a                	sd	s2,0(sp)
 2b0:	1000                	addi	s0,sp,32
 2b2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2b4:	4581                	li	a1,0
 2b6:	00000097          	auipc	ra,0x0
 2ba:	172080e7          	jalr	370(ra) # 428 <open>
  if(fd < 0)
 2be:	02054563          	bltz	a0,2e8 <stat+0x42>
 2c2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2c4:	85ca                	mv	a1,s2
 2c6:	00000097          	auipc	ra,0x0
 2ca:	17a080e7          	jalr	378(ra) # 440 <fstat>
 2ce:	892a                	mv	s2,a0
  close(fd);
 2d0:	8526                	mv	a0,s1
 2d2:	00000097          	auipc	ra,0x0
 2d6:	13e080e7          	jalr	318(ra) # 410 <close>
  return r;
}
 2da:	854a                	mv	a0,s2
 2dc:	60e2                	ld	ra,24(sp)
 2de:	6442                	ld	s0,16(sp)
 2e0:	64a2                	ld	s1,8(sp)
 2e2:	6902                	ld	s2,0(sp)
 2e4:	6105                	addi	sp,sp,32
 2e6:	8082                	ret
    return -1;
 2e8:	597d                	li	s2,-1
 2ea:	bfc5                	j	2da <stat+0x34>

00000000000002ec <atoi>:

int
atoi(const char *s)
{
 2ec:	1141                	addi	sp,sp,-16
 2ee:	e422                	sd	s0,8(sp)
 2f0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2f2:	00054603          	lbu	a2,0(a0)
 2f6:	fd06079b          	addiw	a5,a2,-48
 2fa:	0ff7f793          	andi	a5,a5,255
 2fe:	4725                	li	a4,9
 300:	02f76963          	bltu	a4,a5,332 <atoi+0x46>
 304:	86aa                	mv	a3,a0
  n = 0;
 306:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 308:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 30a:	0685                	addi	a3,a3,1
 30c:	0025179b          	slliw	a5,a0,0x2
 310:	9fa9                	addw	a5,a5,a0
 312:	0017979b          	slliw	a5,a5,0x1
 316:	9fb1                	addw	a5,a5,a2
 318:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 31c:	0006c603          	lbu	a2,0(a3)
 320:	fd06071b          	addiw	a4,a2,-48
 324:	0ff77713          	andi	a4,a4,255
 328:	fee5f1e3          	bgeu	a1,a4,30a <atoi+0x1e>
  return n;
}
 32c:	6422                	ld	s0,8(sp)
 32e:	0141                	addi	sp,sp,16
 330:	8082                	ret
  n = 0;
 332:	4501                	li	a0,0
 334:	bfe5                	j	32c <atoi+0x40>

0000000000000336 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 336:	1141                	addi	sp,sp,-16
 338:	e422                	sd	s0,8(sp)
 33a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 33c:	02b57463          	bgeu	a0,a1,364 <memmove+0x2e>
    while(n-- > 0)
 340:	00c05f63          	blez	a2,35e <memmove+0x28>
 344:	1602                	slli	a2,a2,0x20
 346:	9201                	srli	a2,a2,0x20
 348:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 34c:	872a                	mv	a4,a0
      *dst++ = *src++;
 34e:	0585                	addi	a1,a1,1
 350:	0705                	addi	a4,a4,1
 352:	fff5c683          	lbu	a3,-1(a1)
 356:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 35a:	fee79ae3          	bne	a5,a4,34e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 35e:	6422                	ld	s0,8(sp)
 360:	0141                	addi	sp,sp,16
 362:	8082                	ret
    dst += n;
 364:	00c50733          	add	a4,a0,a2
    src += n;
 368:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 36a:	fec05ae3          	blez	a2,35e <memmove+0x28>
 36e:	fff6079b          	addiw	a5,a2,-1
 372:	1782                	slli	a5,a5,0x20
 374:	9381                	srli	a5,a5,0x20
 376:	fff7c793          	not	a5,a5
 37a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 37c:	15fd                	addi	a1,a1,-1
 37e:	177d                	addi	a4,a4,-1
 380:	0005c683          	lbu	a3,0(a1)
 384:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 388:	fee79ae3          	bne	a5,a4,37c <memmove+0x46>
 38c:	bfc9                	j	35e <memmove+0x28>

000000000000038e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 38e:	1141                	addi	sp,sp,-16
 390:	e422                	sd	s0,8(sp)
 392:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 394:	ca05                	beqz	a2,3c4 <memcmp+0x36>
 396:	fff6069b          	addiw	a3,a2,-1
 39a:	1682                	slli	a3,a3,0x20
 39c:	9281                	srli	a3,a3,0x20
 39e:	0685                	addi	a3,a3,1
 3a0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3a2:	00054783          	lbu	a5,0(a0)
 3a6:	0005c703          	lbu	a4,0(a1)
 3aa:	00e79863          	bne	a5,a4,3ba <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ae:	0505                	addi	a0,a0,1
    p2++;
 3b0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3b2:	fed518e3          	bne	a0,a3,3a2 <memcmp+0x14>
  }
  return 0;
 3b6:	4501                	li	a0,0
 3b8:	a019                	j	3be <memcmp+0x30>
      return *p1 - *p2;
 3ba:	40e7853b          	subw	a0,a5,a4
}
 3be:	6422                	ld	s0,8(sp)
 3c0:	0141                	addi	sp,sp,16
 3c2:	8082                	ret
  return 0;
 3c4:	4501                	li	a0,0
 3c6:	bfe5                	j	3be <memcmp+0x30>

00000000000003c8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3c8:	1141                	addi	sp,sp,-16
 3ca:	e406                	sd	ra,8(sp)
 3cc:	e022                	sd	s0,0(sp)
 3ce:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3d0:	00000097          	auipc	ra,0x0
 3d4:	f66080e7          	jalr	-154(ra) # 336 <memmove>
}
 3d8:	60a2                	ld	ra,8(sp)
 3da:	6402                	ld	s0,0(sp)
 3dc:	0141                	addi	sp,sp,16
 3de:	8082                	ret

00000000000003e0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3e0:	4885                	li	a7,1
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3e8:	4889                	li	a7,2
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3f0:	488d                	li	a7,3
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3f8:	4891                	li	a7,4
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <read>:
.global read
read:
 li a7, SYS_read
 400:	4895                	li	a7,5
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <write>:
.global write
write:
 li a7, SYS_write
 408:	48c1                	li	a7,16
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <close>:
.global close
close:
 li a7, SYS_close
 410:	48d5                	li	a7,21
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <kill>:
.global kill
kill:
 li a7, SYS_kill
 418:	4899                	li	a7,6
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <exec>:
.global exec
exec:
 li a7, SYS_exec
 420:	489d                	li	a7,7
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <open>:
.global open
open:
 li a7, SYS_open
 428:	48bd                	li	a7,15
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 430:	48c5                	li	a7,17
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 438:	48c9                	li	a7,18
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 440:	48a1                	li	a7,8
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <link>:
.global link
link:
 li a7, SYS_link
 448:	48cd                	li	a7,19
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 450:	48d1                	li	a7,20
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 458:	48a5                	li	a7,9
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <dup>:
.global dup
dup:
 li a7, SYS_dup
 460:	48a9                	li	a7,10
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 468:	48ad                	li	a7,11
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 470:	48b1                	li	a7,12
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 478:	48b5                	li	a7,13
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 480:	48b9                	li	a7,14
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 488:	48d9                	li	a7,22
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <getSysCount>:
.global getSysCount
getSysCount:
 li a7, SYS_getSysCount
 490:	48dd                	li	a7,23
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 498:	48e1                	li	a7,24
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 4a0:	48e5                	li	a7,25
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 4a8:	48e9                	li	a7,26
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4b0:	1101                	addi	sp,sp,-32
 4b2:	ec06                	sd	ra,24(sp)
 4b4:	e822                	sd	s0,16(sp)
 4b6:	1000                	addi	s0,sp,32
 4b8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4bc:	4605                	li	a2,1
 4be:	fef40593          	addi	a1,s0,-17
 4c2:	00000097          	auipc	ra,0x0
 4c6:	f46080e7          	jalr	-186(ra) # 408 <write>
}
 4ca:	60e2                	ld	ra,24(sp)
 4cc:	6442                	ld	s0,16(sp)
 4ce:	6105                	addi	sp,sp,32
 4d0:	8082                	ret

00000000000004d2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4d2:	7139                	addi	sp,sp,-64
 4d4:	fc06                	sd	ra,56(sp)
 4d6:	f822                	sd	s0,48(sp)
 4d8:	f426                	sd	s1,40(sp)
 4da:	f04a                	sd	s2,32(sp)
 4dc:	ec4e                	sd	s3,24(sp)
 4de:	0080                	addi	s0,sp,64
 4e0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4e2:	c299                	beqz	a3,4e8 <printint+0x16>
 4e4:	0805c863          	bltz	a1,574 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4e8:	2581                	sext.w	a1,a1
  neg = 0;
 4ea:	4881                	li	a7,0
 4ec:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4f0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4f2:	2601                	sext.w	a2,a2
 4f4:	00000517          	auipc	a0,0x0
 4f8:	64c50513          	addi	a0,a0,1612 # b40 <digits>
 4fc:	883a                	mv	a6,a4
 4fe:	2705                	addiw	a4,a4,1
 500:	02c5f7bb          	remuw	a5,a1,a2
 504:	1782                	slli	a5,a5,0x20
 506:	9381                	srli	a5,a5,0x20
 508:	97aa                	add	a5,a5,a0
 50a:	0007c783          	lbu	a5,0(a5)
 50e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 512:	0005879b          	sext.w	a5,a1
 516:	02c5d5bb          	divuw	a1,a1,a2
 51a:	0685                	addi	a3,a3,1
 51c:	fec7f0e3          	bgeu	a5,a2,4fc <printint+0x2a>
  if(neg)
 520:	00088b63          	beqz	a7,536 <printint+0x64>
    buf[i++] = '-';
 524:	fd040793          	addi	a5,s0,-48
 528:	973e                	add	a4,a4,a5
 52a:	02d00793          	li	a5,45
 52e:	fef70823          	sb	a5,-16(a4)
 532:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 536:	02e05863          	blez	a4,566 <printint+0x94>
 53a:	fc040793          	addi	a5,s0,-64
 53e:	00e78933          	add	s2,a5,a4
 542:	fff78993          	addi	s3,a5,-1
 546:	99ba                	add	s3,s3,a4
 548:	377d                	addiw	a4,a4,-1
 54a:	1702                	slli	a4,a4,0x20
 54c:	9301                	srli	a4,a4,0x20
 54e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 552:	fff94583          	lbu	a1,-1(s2)
 556:	8526                	mv	a0,s1
 558:	00000097          	auipc	ra,0x0
 55c:	f58080e7          	jalr	-168(ra) # 4b0 <putc>
  while(--i >= 0)
 560:	197d                	addi	s2,s2,-1
 562:	ff3918e3          	bne	s2,s3,552 <printint+0x80>
}
 566:	70e2                	ld	ra,56(sp)
 568:	7442                	ld	s0,48(sp)
 56a:	74a2                	ld	s1,40(sp)
 56c:	7902                	ld	s2,32(sp)
 56e:	69e2                	ld	s3,24(sp)
 570:	6121                	addi	sp,sp,64
 572:	8082                	ret
    x = -xx;
 574:	40b005bb          	negw	a1,a1
    neg = 1;
 578:	4885                	li	a7,1
    x = -xx;
 57a:	bf8d                	j	4ec <printint+0x1a>

000000000000057c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 57c:	7119                	addi	sp,sp,-128
 57e:	fc86                	sd	ra,120(sp)
 580:	f8a2                	sd	s0,112(sp)
 582:	f4a6                	sd	s1,104(sp)
 584:	f0ca                	sd	s2,96(sp)
 586:	ecce                	sd	s3,88(sp)
 588:	e8d2                	sd	s4,80(sp)
 58a:	e4d6                	sd	s5,72(sp)
 58c:	e0da                	sd	s6,64(sp)
 58e:	fc5e                	sd	s7,56(sp)
 590:	f862                	sd	s8,48(sp)
 592:	f466                	sd	s9,40(sp)
 594:	f06a                	sd	s10,32(sp)
 596:	ec6e                	sd	s11,24(sp)
 598:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 59a:	0005c903          	lbu	s2,0(a1)
 59e:	18090f63          	beqz	s2,73c <vprintf+0x1c0>
 5a2:	8aaa                	mv	s5,a0
 5a4:	8b32                	mv	s6,a2
 5a6:	00158493          	addi	s1,a1,1
  state = 0;
 5aa:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5ac:	02500a13          	li	s4,37
      if(c == 'd'){
 5b0:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5b4:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5b8:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5bc:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5c0:	00000b97          	auipc	s7,0x0
 5c4:	580b8b93          	addi	s7,s7,1408 # b40 <digits>
 5c8:	a839                	j	5e6 <vprintf+0x6a>
        putc(fd, c);
 5ca:	85ca                	mv	a1,s2
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	ee2080e7          	jalr	-286(ra) # 4b0 <putc>
 5d6:	a019                	j	5dc <vprintf+0x60>
    } else if(state == '%'){
 5d8:	01498f63          	beq	s3,s4,5f6 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5dc:	0485                	addi	s1,s1,1
 5de:	fff4c903          	lbu	s2,-1(s1)
 5e2:	14090d63          	beqz	s2,73c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5e6:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5ea:	fe0997e3          	bnez	s3,5d8 <vprintf+0x5c>
      if(c == '%'){
 5ee:	fd479ee3          	bne	a5,s4,5ca <vprintf+0x4e>
        state = '%';
 5f2:	89be                	mv	s3,a5
 5f4:	b7e5                	j	5dc <vprintf+0x60>
      if(c == 'd'){
 5f6:	05878063          	beq	a5,s8,636 <vprintf+0xba>
      } else if(c == 'l') {
 5fa:	05978c63          	beq	a5,s9,652 <vprintf+0xd6>
      } else if(c == 'x') {
 5fe:	07a78863          	beq	a5,s10,66e <vprintf+0xf2>
      } else if(c == 'p') {
 602:	09b78463          	beq	a5,s11,68a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 606:	07300713          	li	a4,115
 60a:	0ce78663          	beq	a5,a4,6d6 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 60e:	06300713          	li	a4,99
 612:	0ee78e63          	beq	a5,a4,70e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 616:	11478863          	beq	a5,s4,726 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 61a:	85d2                	mv	a1,s4
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	e92080e7          	jalr	-366(ra) # 4b0 <putc>
        putc(fd, c);
 626:	85ca                	mv	a1,s2
 628:	8556                	mv	a0,s5
 62a:	00000097          	auipc	ra,0x0
 62e:	e86080e7          	jalr	-378(ra) # 4b0 <putc>
      }
      state = 0;
 632:	4981                	li	s3,0
 634:	b765                	j	5dc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 636:	008b0913          	addi	s2,s6,8
 63a:	4685                	li	a3,1
 63c:	4629                	li	a2,10
 63e:	000b2583          	lw	a1,0(s6)
 642:	8556                	mv	a0,s5
 644:	00000097          	auipc	ra,0x0
 648:	e8e080e7          	jalr	-370(ra) # 4d2 <printint>
 64c:	8b4a                	mv	s6,s2
      state = 0;
 64e:	4981                	li	s3,0
 650:	b771                	j	5dc <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 652:	008b0913          	addi	s2,s6,8
 656:	4681                	li	a3,0
 658:	4629                	li	a2,10
 65a:	000b2583          	lw	a1,0(s6)
 65e:	8556                	mv	a0,s5
 660:	00000097          	auipc	ra,0x0
 664:	e72080e7          	jalr	-398(ra) # 4d2 <printint>
 668:	8b4a                	mv	s6,s2
      state = 0;
 66a:	4981                	li	s3,0
 66c:	bf85                	j	5dc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 66e:	008b0913          	addi	s2,s6,8
 672:	4681                	li	a3,0
 674:	4641                	li	a2,16
 676:	000b2583          	lw	a1,0(s6)
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	e56080e7          	jalr	-426(ra) # 4d2 <printint>
 684:	8b4a                	mv	s6,s2
      state = 0;
 686:	4981                	li	s3,0
 688:	bf91                	j	5dc <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 68a:	008b0793          	addi	a5,s6,8
 68e:	f8f43423          	sd	a5,-120(s0)
 692:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 696:	03000593          	li	a1,48
 69a:	8556                	mv	a0,s5
 69c:	00000097          	auipc	ra,0x0
 6a0:	e14080e7          	jalr	-492(ra) # 4b0 <putc>
  putc(fd, 'x');
 6a4:	85ea                	mv	a1,s10
 6a6:	8556                	mv	a0,s5
 6a8:	00000097          	auipc	ra,0x0
 6ac:	e08080e7          	jalr	-504(ra) # 4b0 <putc>
 6b0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6b2:	03c9d793          	srli	a5,s3,0x3c
 6b6:	97de                	add	a5,a5,s7
 6b8:	0007c583          	lbu	a1,0(a5)
 6bc:	8556                	mv	a0,s5
 6be:	00000097          	auipc	ra,0x0
 6c2:	df2080e7          	jalr	-526(ra) # 4b0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6c6:	0992                	slli	s3,s3,0x4
 6c8:	397d                	addiw	s2,s2,-1
 6ca:	fe0914e3          	bnez	s2,6b2 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6ce:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6d2:	4981                	li	s3,0
 6d4:	b721                	j	5dc <vprintf+0x60>
        s = va_arg(ap, char*);
 6d6:	008b0993          	addi	s3,s6,8
 6da:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6de:	02090163          	beqz	s2,700 <vprintf+0x184>
        while(*s != 0){
 6e2:	00094583          	lbu	a1,0(s2)
 6e6:	c9a1                	beqz	a1,736 <vprintf+0x1ba>
          putc(fd, *s);
 6e8:	8556                	mv	a0,s5
 6ea:	00000097          	auipc	ra,0x0
 6ee:	dc6080e7          	jalr	-570(ra) # 4b0 <putc>
          s++;
 6f2:	0905                	addi	s2,s2,1
        while(*s != 0){
 6f4:	00094583          	lbu	a1,0(s2)
 6f8:	f9e5                	bnez	a1,6e8 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6fa:	8b4e                	mv	s6,s3
      state = 0;
 6fc:	4981                	li	s3,0
 6fe:	bdf9                	j	5dc <vprintf+0x60>
          s = "(null)";
 700:	00000917          	auipc	s2,0x0
 704:	43890913          	addi	s2,s2,1080 # b38 <malloc+0x2f2>
        while(*s != 0){
 708:	02800593          	li	a1,40
 70c:	bff1                	j	6e8 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 70e:	008b0913          	addi	s2,s6,8
 712:	000b4583          	lbu	a1,0(s6)
 716:	8556                	mv	a0,s5
 718:	00000097          	auipc	ra,0x0
 71c:	d98080e7          	jalr	-616(ra) # 4b0 <putc>
 720:	8b4a                	mv	s6,s2
      state = 0;
 722:	4981                	li	s3,0
 724:	bd65                	j	5dc <vprintf+0x60>
        putc(fd, c);
 726:	85d2                	mv	a1,s4
 728:	8556                	mv	a0,s5
 72a:	00000097          	auipc	ra,0x0
 72e:	d86080e7          	jalr	-634(ra) # 4b0 <putc>
      state = 0;
 732:	4981                	li	s3,0
 734:	b565                	j	5dc <vprintf+0x60>
        s = va_arg(ap, char*);
 736:	8b4e                	mv	s6,s3
      state = 0;
 738:	4981                	li	s3,0
 73a:	b54d                	j	5dc <vprintf+0x60>
    }
  }
}
 73c:	70e6                	ld	ra,120(sp)
 73e:	7446                	ld	s0,112(sp)
 740:	74a6                	ld	s1,104(sp)
 742:	7906                	ld	s2,96(sp)
 744:	69e6                	ld	s3,88(sp)
 746:	6a46                	ld	s4,80(sp)
 748:	6aa6                	ld	s5,72(sp)
 74a:	6b06                	ld	s6,64(sp)
 74c:	7be2                	ld	s7,56(sp)
 74e:	7c42                	ld	s8,48(sp)
 750:	7ca2                	ld	s9,40(sp)
 752:	7d02                	ld	s10,32(sp)
 754:	6de2                	ld	s11,24(sp)
 756:	6109                	addi	sp,sp,128
 758:	8082                	ret

000000000000075a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 75a:	715d                	addi	sp,sp,-80
 75c:	ec06                	sd	ra,24(sp)
 75e:	e822                	sd	s0,16(sp)
 760:	1000                	addi	s0,sp,32
 762:	e010                	sd	a2,0(s0)
 764:	e414                	sd	a3,8(s0)
 766:	e818                	sd	a4,16(s0)
 768:	ec1c                	sd	a5,24(s0)
 76a:	03043023          	sd	a6,32(s0)
 76e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 772:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 776:	8622                	mv	a2,s0
 778:	00000097          	auipc	ra,0x0
 77c:	e04080e7          	jalr	-508(ra) # 57c <vprintf>
}
 780:	60e2                	ld	ra,24(sp)
 782:	6442                	ld	s0,16(sp)
 784:	6161                	addi	sp,sp,80
 786:	8082                	ret

0000000000000788 <printf>:

void
printf(const char *fmt, ...)
{
 788:	711d                	addi	sp,sp,-96
 78a:	ec06                	sd	ra,24(sp)
 78c:	e822                	sd	s0,16(sp)
 78e:	1000                	addi	s0,sp,32
 790:	e40c                	sd	a1,8(s0)
 792:	e810                	sd	a2,16(s0)
 794:	ec14                	sd	a3,24(s0)
 796:	f018                	sd	a4,32(s0)
 798:	f41c                	sd	a5,40(s0)
 79a:	03043823          	sd	a6,48(s0)
 79e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7a2:	00840613          	addi	a2,s0,8
 7a6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7aa:	85aa                	mv	a1,a0
 7ac:	4505                	li	a0,1
 7ae:	00000097          	auipc	ra,0x0
 7b2:	dce080e7          	jalr	-562(ra) # 57c <vprintf>
}
 7b6:	60e2                	ld	ra,24(sp)
 7b8:	6442                	ld	s0,16(sp)
 7ba:	6125                	addi	sp,sp,96
 7bc:	8082                	ret

00000000000007be <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7be:	1141                	addi	sp,sp,-16
 7c0:	e422                	sd	s0,8(sp)
 7c2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7c4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7c8:	00001797          	auipc	a5,0x1
 7cc:	8387b783          	ld	a5,-1992(a5) # 1000 <freep>
 7d0:	a805                	j	800 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7d2:	4618                	lw	a4,8(a2)
 7d4:	9db9                	addw	a1,a1,a4
 7d6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7da:	6398                	ld	a4,0(a5)
 7dc:	6318                	ld	a4,0(a4)
 7de:	fee53823          	sd	a4,-16(a0)
 7e2:	a091                	j	826 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7e4:	ff852703          	lw	a4,-8(a0)
 7e8:	9e39                	addw	a2,a2,a4
 7ea:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7ec:	ff053703          	ld	a4,-16(a0)
 7f0:	e398                	sd	a4,0(a5)
 7f2:	a099                	j	838 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7f4:	6398                	ld	a4,0(a5)
 7f6:	00e7e463          	bltu	a5,a4,7fe <free+0x40>
 7fa:	00e6ea63          	bltu	a3,a4,80e <free+0x50>
{
 7fe:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 800:	fed7fae3          	bgeu	a5,a3,7f4 <free+0x36>
 804:	6398                	ld	a4,0(a5)
 806:	00e6e463          	bltu	a3,a4,80e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 80a:	fee7eae3          	bltu	a5,a4,7fe <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 80e:	ff852583          	lw	a1,-8(a0)
 812:	6390                	ld	a2,0(a5)
 814:	02059713          	slli	a4,a1,0x20
 818:	9301                	srli	a4,a4,0x20
 81a:	0712                	slli	a4,a4,0x4
 81c:	9736                	add	a4,a4,a3
 81e:	fae60ae3          	beq	a2,a4,7d2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 822:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 826:	4790                	lw	a2,8(a5)
 828:	02061713          	slli	a4,a2,0x20
 82c:	9301                	srli	a4,a4,0x20
 82e:	0712                	slli	a4,a4,0x4
 830:	973e                	add	a4,a4,a5
 832:	fae689e3          	beq	a3,a4,7e4 <free+0x26>
  } else
    p->s.ptr = bp;
 836:	e394                	sd	a3,0(a5)
  freep = p;
 838:	00000717          	auipc	a4,0x0
 83c:	7cf73423          	sd	a5,1992(a4) # 1000 <freep>
}
 840:	6422                	ld	s0,8(sp)
 842:	0141                	addi	sp,sp,16
 844:	8082                	ret

0000000000000846 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 846:	7139                	addi	sp,sp,-64
 848:	fc06                	sd	ra,56(sp)
 84a:	f822                	sd	s0,48(sp)
 84c:	f426                	sd	s1,40(sp)
 84e:	f04a                	sd	s2,32(sp)
 850:	ec4e                	sd	s3,24(sp)
 852:	e852                	sd	s4,16(sp)
 854:	e456                	sd	s5,8(sp)
 856:	e05a                	sd	s6,0(sp)
 858:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 85a:	02051493          	slli	s1,a0,0x20
 85e:	9081                	srli	s1,s1,0x20
 860:	04bd                	addi	s1,s1,15
 862:	8091                	srli	s1,s1,0x4
 864:	0014899b          	addiw	s3,s1,1
 868:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 86a:	00000517          	auipc	a0,0x0
 86e:	79653503          	ld	a0,1942(a0) # 1000 <freep>
 872:	c515                	beqz	a0,89e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 874:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 876:	4798                	lw	a4,8(a5)
 878:	02977f63          	bgeu	a4,s1,8b6 <malloc+0x70>
 87c:	8a4e                	mv	s4,s3
 87e:	0009871b          	sext.w	a4,s3
 882:	6685                	lui	a3,0x1
 884:	00d77363          	bgeu	a4,a3,88a <malloc+0x44>
 888:	6a05                	lui	s4,0x1
 88a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 88e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 892:	00000917          	auipc	s2,0x0
 896:	76e90913          	addi	s2,s2,1902 # 1000 <freep>
  if(p == (char*)-1)
 89a:	5afd                	li	s5,-1
 89c:	a88d                	j	90e <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 89e:	00000797          	auipc	a5,0x0
 8a2:	77278793          	addi	a5,a5,1906 # 1010 <base>
 8a6:	00000717          	auipc	a4,0x0
 8aa:	74f73d23          	sd	a5,1882(a4) # 1000 <freep>
 8ae:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8b0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8b4:	b7e1                	j	87c <malloc+0x36>
      if(p->s.size == nunits)
 8b6:	02e48b63          	beq	s1,a4,8ec <malloc+0xa6>
        p->s.size -= nunits;
 8ba:	4137073b          	subw	a4,a4,s3
 8be:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8c0:	1702                	slli	a4,a4,0x20
 8c2:	9301                	srli	a4,a4,0x20
 8c4:	0712                	slli	a4,a4,0x4
 8c6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8c8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8cc:	00000717          	auipc	a4,0x0
 8d0:	72a73a23          	sd	a0,1844(a4) # 1000 <freep>
      return (void*)(p + 1);
 8d4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8d8:	70e2                	ld	ra,56(sp)
 8da:	7442                	ld	s0,48(sp)
 8dc:	74a2                	ld	s1,40(sp)
 8de:	7902                	ld	s2,32(sp)
 8e0:	69e2                	ld	s3,24(sp)
 8e2:	6a42                	ld	s4,16(sp)
 8e4:	6aa2                	ld	s5,8(sp)
 8e6:	6b02                	ld	s6,0(sp)
 8e8:	6121                	addi	sp,sp,64
 8ea:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8ec:	6398                	ld	a4,0(a5)
 8ee:	e118                	sd	a4,0(a0)
 8f0:	bff1                	j	8cc <malloc+0x86>
  hp->s.size = nu;
 8f2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8f6:	0541                	addi	a0,a0,16
 8f8:	00000097          	auipc	ra,0x0
 8fc:	ec6080e7          	jalr	-314(ra) # 7be <free>
  return freep;
 900:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 904:	d971                	beqz	a0,8d8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 906:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 908:	4798                	lw	a4,8(a5)
 90a:	fa9776e3          	bgeu	a4,s1,8b6 <malloc+0x70>
    if(p == freep)
 90e:	00093703          	ld	a4,0(s2)
 912:	853e                	mv	a0,a5
 914:	fef719e3          	bne	a4,a5,906 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 918:	8552                	mv	a0,s4
 91a:	00000097          	auipc	ra,0x0
 91e:	b56080e7          	jalr	-1194(ra) # 470 <sbrk>
  if(p == (char*)-1)
 922:	fd5518e3          	bne	a0,s5,8f2 <malloc+0xac>
        return 0;
 926:	4501                	li	a0,0
 928:	bf45                	j	8d8 <malloc+0x92>
