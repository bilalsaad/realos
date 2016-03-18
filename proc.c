#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"
#include "spinlock.h"
#define QUEUE_SIZE NPROC
struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

static struct proc *initproc;

int nextpid = 1;
extern void forkret(void);
extern void trapret(void);

static void wakeup1(void *chan);
void enq_to_scheduler (struct proc * p); 

typedef struct {
  int count;
  int tail;
  int head;
  struct proc* proc[QUEUE_SIZE];
} queue; 

void queue_init(queue* q) {
  q->tail = 0;
  q->count = 0;
  q->head = 0;
}

void enqueue(queue* q, struct proc* p){
  q->proc[q->tail] = p;
  q->tail = (q->tail + 1) % QUEUE_SIZE;
  ++q->count;
}

struct proc * dequeue(queue* q) {
 struct proc* tmp = q->proc[q->head]; 
 --q->count;
 q->head = (q->head + 1) % QUEUE_SIZE;
 return tmp;
}

typedef struct {
  queue pr1;
  queue pr2;
  queue pr3;
} multi_level_queue;

void multi_level_enq(multi_level_queue* q, struct proc * p) {
 switch (p->priority) {
    case LOW_PRIO:
      enqueue(&q->pr1, p);
    break;
    case MED_PRIO:
      enqueue(&q->pr2, p);
    break;
    case HIGH_PRIO:
    default: 
      enqueue(&q->pr3, p);
 }
} 

struct proc* multi_level_dequeue(multi_level_queue* q) {
  return (q->pr1.count > 0) ? dequeue(&q->pr1) :
         (q->pr2.count > 0) ? dequeue(&q->pr2) :
         (q->pr3.count > 0) ? dequeue(&q->pr3) : 0;
}

struct proc* fcfs_dequeue(queue* q) {
  struct proc * min = q->proc[q->head];  
  int i = (q->head+1) % QUEUE_SIZE;
  if (q->count == 0) return 0;
  while (i != q->tail) {
      min = (min->ctime > q->proc[i]->ctime &&
          q->proc[i]->state ==  RUNNABLE) ?
        q->proc[i] : min;
      i = (i+1) % QUEUE_SIZE;
  }
  if(min->state != RUNNABLE) 
    panic("dequeued a non runnable process fcfs_dequeue \n");
  return min;
}
#if defined(SML) || defined(DML)
  multi_level_queue sch_queue;
  void init_queue() {
    queue_init(&sch_queue.pr1);
    queue_init(&sch_queue.pr2);
    queue_init(&sch_queue.pr3);
  } 
#endif

#ifdef FCFS
  queue sch_queue;
  void init_queue() {
    queue_init(&sch_queue); 
  }
#endif


void
pinit(void)
{
  initlock(&ptable.lock, "ptable");
#ifndef DEFAULT
  init_queue();
#endif
}

//PAGEBREAK: 32
// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{ // here we can choose to which queue we want him to be sent..
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
    return 0;
  }
  sp = p->kstack + KSTACKSIZE;
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
  p->tf = (struct trapframe*)sp;
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
  *(uint*)sp = (uint)trapret;

  sp -= sizeof *p->context;
  p->context = (struct context*)sp;
  memset(p->context, 0, sizeof *p->context);
  p->context->eip = (uint)forkret;

  return p;
}

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  initproc = p;
  if((p->pgdir = setupkvm()) == 0)
    panic("userinit: out of memory?");
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  p->sz = PGSIZE;
  memset(p->tf, 0, sizeof(*p->tf));
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  p->tf->es = p->tf->ds;
  p->tf->ss = p->tf->ds;
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0;  // beginning of initcode.S


  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
  p->ctime = 0;
  p->priority = MED_PRIO;
  p->dml_opts = DEFAULT_OPT;
  enq_to_scheduler(p);
}

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  
  sz = proc->sz;
  if(n > 0){
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  proc->sz = sz;
  switchuvm(proc);
  return 0;
}
// Adds the newly created process to the appropriate queue.
void enq_to_scheduler (struct proc * p) {
#ifdef DEFAULT
  return;
#endif
#ifdef FCFS 
  enqueue(&sch_queue, p);
#endif
#ifdef SML 
  multi_level_enq(&sch_queue,p);
#endif
#ifdef DML
  switch (p->dml_opts) {
    case RETURNING_FROM_SLEEP: 
      p->priority = HIGH_PRIO;
    break;
    case FULL_QUANTA:
      p->priority -= (p->priority > LOW_PRIO) ? 1 : 0;
    break;
    default: ;
  }
  multi_level_enq(&sch_queue, p);
#endif
}
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return -1;
  np->ctime = ticks;
  np->stime = 0;
  np->retime = 0;
  np->rutime = 0;
  np->priority = proc->priority;
  np->dml_opts = DEFAULT_OPT;
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  np->parent = proc;
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);

  safestrcpy(np->name, proc->name, sizeof(proc->name));
 
  pid = np->pid;

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
  np->state = RUNNABLE;
  enq_to_scheduler(np);
  release(&ptable.lock);
  
  return pid;
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
  struct proc *p;
  int fd;

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd]){
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(proc->cwd);
  end_op();
  proc->cwd = 0;

  acquire(&ptable.lock);

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == proc){
      p->parent = initproc;
      if(p->state == ZOMBIE)
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
        freevm(p->pgdir);
        p->state = UNUSED;
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
        release(&ptable.lock);
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  }
}

int wait2(void) {
  char *retime, *rutime, *stime;
  int pid = 0;
  struct proc * p;
  if(argptr(0,&retime,sizeof(int)) < 0
      || argptr(1,&rutime,sizeof(int)) < 0
      || argptr(2,&stime,sizeof(int)) < 0) 
    return -1;
  pid = wait(); 
  // now we have the pid of a child  process - now we can 
  // find it in the ptable and foo foo 
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC] && pid > 0; ++p) 
    if(p->pid == pid){ //found the child 
      *retime = p->retime;
      *rutime = p->rutime;
      *stime = p->stime;
      release(&ptable.lock);
      return pid;
    }
  release(&ptable.lock);
  return -1;
}
// This method is icrements the time fields for all the processes
// each tick, it is called in trap.c when we increment the total amount of 
// ticks we lock the ptable here!
//
void increment_process_times(void) {
  struct proc * p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; ++p)
    switch (p->state) {
      case SLEEPING:
        ++p->stime;
      break;
      case RUNNING:
        ++p->rutime;
      break;
      case RUNNABLE:
        ++p->retime;
      break;
      default:
      break;
    }
   release(&ptable.lock);  
}

#ifdef DEFAULT
  // The default scheduling scheme
  struct proc* first_process(){
     return ptable.proc; 
  }

  int end_of_round(struct proc* p){
    return p == &ptable.proc[NPROC];
  }
  
  struct proc* next_proc(struct proc* p){
    return p+1;
  }
#endif 

#ifdef FCFS
  // The First Come First Serve scheduling scheme
  // non preemtive policy that selects the process with lowest ctime
  int end_of_round(struct proc* p) {
    return p == 0;
  } 
  
  struct proc* next_proc(struct proc* p) {
    return fcfs_dequeue(&sch_queue);
  } 

  struct proc* first_process() {
   return next_proc(0); 
  }
#endif

#if defined(SML) || defined(DML)
  // Multi level queue that includes 3 priority levels.
  int end_of_round(struct proc* p) {
    return p == 0;
  }
  struct proc* next_proc(struct proc* p) {
    return multi_level_dequeue(&sch_queue);
  }
  struct proc* first_process() {
    return next_proc(0);
  }
#endif
//PAGEBREAK: 42
// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = first_process(); !end_of_round(p); p = next_proc(p)){
      if(p->state != RUNNABLE)
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
      switchuvm(p);
      p->state = RUNNING;
      swtch(&cpu->scheduler, proc->context);
      switchkvm();

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
  }
}

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
  int intena;

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
    panic("sched locks");
  if(proc->state == RUNNING)
    panic("sched running");
  if(readeflags()&FL_IF)
    panic("sched interruptible");
  intena = cpu->intena;
  swtch(&proc->context, cpu->scheduler);
  cpu->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  acquire(&ptable.lock);  //DOC: yieldlock
  proc->state = RUNNABLE;
  enq_to_scheduler(proc);
  sched();
  release(&ptable.lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);

  if (first) {
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
    iinit(ROOTDEV);
    initlog(ROOTDEV);
  }
  
  // Return to "caller", actually trapret (see allocproc).
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  if(proc == 0)
    panic("sleep");

  if(lk == 0)
    panic("sleep without lk");

  // Must acquire ptable.lock in order to
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
    acquire(&ptable.lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  proc->chan = chan;
  proc->state = SLEEPING;
  sched();

  // Tidy up.
  proc->chan = 0;

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  }
}

//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == SLEEPING && p->chan == chan) {
      p->state = RUNNABLE;
      p->dml_opts = RETURNING_FROM_SLEEP;
      enq_to_scheduler(p);
    }
}

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
}

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING) {
        p->state = RUNNABLE;
        enq_to_scheduler(p);
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}

//PAGEBREAK: 36
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [EMBRYO]    "embryo",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
