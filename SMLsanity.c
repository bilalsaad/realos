#include "types.h"
#include "stat.h"
#include "user.h"

// SMLsanity.c : tests priority 3

enum priority   {PRIO_1 = 0, PRIO_2= 1, PRIO_3= 2};
const char * get_prio_name(enum priority prio) {
  return (prio == PRIO_1) ? "PRIO_1" :
         (prio == PRIO_2) ? "PRIO_2" :
         "PRIO_3";
}

void statistics(enum priority prio, int n, int time,
    const char * test_group){
  printf(1, "Average %s for %s is %d \n", test_group,
      get_prio_name(prio), time/n);
}

void turnaroundtime(enum priority p, int n, int info) {
  statistics(p, n, info, "total time");
}

int main(int argc, char **argv) {
  int n = 20, pid, i, j, h;
  int time[3]; // time[0] priority1, time[1] priority 2...
  time[0] = time [1] = time[2] = 0;
  int retime, rutime, stime;
  enum priority prio;

  if(argc > 1)
    n = atoi(argv[1]);
  for(i = 0; i < 3*n; ++i){
    pid = fork();
    if(pid == 0) { // Child
      set_prio((getpid() % 3)+1);
      for(j = 0; j < 100; ++j) 
        for(h = 0; h < 1000000; ++h){}
      exit();
    }
  }
  while( (pid = wait2(&retime, &rutime, &stime)) > 0 ) {
      prio = pid % 3; // To know which priority the child has
      printf(1, "process id: %d, priority: %s \n", pid, get_prio_name(prio));
      printf(1, "Time it took to complete: %d \n", rutime + retime + stime);
      time[prio] += rutime + retime + stime ;
  }
  turnaroundtime(PRIO_1, n, time[PRIO_1]);
  turnaroundtime(PRIO_2, n, time[PRIO_2]);
  turnaroundtime(PRIO_3, n, time[PRIO_3]);

  exit();
}


