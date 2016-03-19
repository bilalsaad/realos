#include "types.h"
#include "stat.h"
#include "user.h"
// sanity.c : gets a nubmer n as an argument and then it will fork 3n times
// and wait until all of them finish for each child process that ends print
// its satistics 
enum test_type {CPU = 0, S_CPU = 1 , IO = 2};
const char * get_test_name(enum test_type test){
  return  (test  == CPU) ? "CPU" :
          (test == S_CPU) ? "S-CPU" :
			   	"IO" ;
}

void statistics(enum test_type test, int n, int sleeptime,
    const char * test_group){
  printf(1, "Average %s for %s is %d \n",test_group,
      get_test_name(test), sleeptime/n);
}

void sleeptime(enum test_type test, int n, int info) {
  statistics(test, n, info, "sleeptime");
}

void readytime(enum test_type test, int n, int info) {
  statistics(test, n, info, "readytime");
}

void turnaroundtime(enum test_type test, int n, int info) {
  statistics(test, n, info, "turn around time");
}

int
main(int argc, char *argv[]){
  int n, pid, i , j, h;
  int stime_cpu = 0,stime_scpu = 0, stime_IO = 0;
  int retime_cpu = 0, retime_scpu = 0, retime_IO  = 0;
  int tatime_cpu = 0, tatime_scpu = 0, tatime_IO = 0;
  enum test_type test;
  
  if (argc != 2) 
    return -1;
  n = atoi(argv[1]);
  for(i = 0 ; i < 3 * n ; ++i) {
    pid = fork();
    if(pid == 0) {
      test = getpid() % 3;
      if(test == CPU) {
        for(j = 0 ; j < 100 ; ++j)
          for(h = 0 ; h < 1000000 ; ++h){}
      } 
      else if(test == S_CPU) {
        for(j = 0 ; j < 100 ; ++j) {
            for(h = 0 ; h < 1000000 ; ++h){}
            yield();
          }
      } 
      else { //IO
        for(j = 0 ; j < 100 ; ++j)
          sleep(1);
      }
      exit();
    }
    else if (pid < 0) {
      printf(1, "fork numver %d, failed!!! \n", i);
    }
    else { // pid != 0 (parent code)
      int retime, rutime, stime;
      test = pid % 3;
      wait2(&retime, &rutime, &stime);
      printf(1, "process id: %d, type: %s \n", pid, get_test_name(test));
      printf(1,"wait time: %d, run time: %d, IO time: %d \n",
					     retime, rutime, stime);
      switch(test) {
        case CPU:
         stime_cpu += stime;
         retime_cpu += retime;
         tatime_cpu += stime + retime + rutime;
        break;
        case S_CPU:
         stime_scpu += stime;
         retime_scpu += retime;
         tatime_scpu += stime + retime + rutime;
        break; 
        case IO:
         stime_IO += stime;
         retime_IO += retime;
         tatime_IO += stime + retime + rutime;
        break;
      } 
				
    }
  }
  sleeptime(CPU,n,stime_cpu);
  sleeptime(S_CPU,n,stime_scpu);
  sleeptime(IO,n,stime_IO);

  readytime(CPU,n,retime_cpu);
  readytime(S_CPU,n,retime_scpu);
  readytime(IO,n,retime_IO);

  turnaroundtime(CPU,n,tatime_cpu);
  turnaroundtime(S_CPU,n,tatime_scpu);
  turnaroundtime(IO,n,tatime_IO);
  
  exit();
}
