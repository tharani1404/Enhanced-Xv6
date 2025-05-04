#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include<stddef.h>

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; 
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); 
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

void clear_syscall_log(void)
{
    struct syscall_log *log = syscall_log;
    while (log) {
        struct syscall_log *next_log = log->next; 
        kfree(log);  
        log = next_log;  
    }
    syscall_log = 0;  
}
int sys_getSysCount(void)
{
    int mask;
    int pid;
    argint(0, &mask);
    argint(1, &pid);

    if (mask < 0) 
    {
        return -1;
    }

    int syscall_num = 0;
    while ((mask >>= 1) != 0) 
    {
        syscall_num++;
    }
    if (syscall_num < 0 || syscall_num >= 31) {
        return -1;
    }

    
    int count = 0;
    struct syscall_log *log = syscall_log;
    
    while (log) {
        if (log->pid == pid) 
        {
            count += log->syscall_counts[syscall_num];
        }

        if (log->ppid == pid) 
        {
            count += log->syscall_counts[syscall_num];
        }

        log = log->next;
    }
    clear_syscall_log();
    return count;
}
int
sys_sigalarm(void)
{
    int ticks;
    //void (*handler)();
    
    // Extract arguments from user space
    argint(0, &ticks);
    if (ticks < 0)
        return -1;

    struct proc *p = myproc();
    
    // Set the alarmticks and handler for the process
    p->alarmticks = ticks;
    p->handler = p->trapframe->a1;
    p->ticks_passed = 0;
    p->alarm_active=0;
    
    return 0;
}
int
sys_sigreturn(void)
{
    struct proc *p = myproc();
    p->alarm_active = 0;
    p->ticks_passed=0;
    memmove(p->trapframe, &p->alarm_tf_backup, sizeof(struct trapframe));
    return p->trapframe->a0;
}
int
sys_settickets(void) {
  int n;
  argint(0, &n);
  if(n < 1)
    return -1;
  struct proc *p = myproc();
  p->tickets = n;
  return n;
}







