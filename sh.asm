
_sh:     file format elf32-i386


Disassembly of section .text:

00000000 <strcmpaa>:
void panic(char*);
struct cmd *parsecmd(char*);
void display_history();
int
strcmpaa(const char *p, const char *q, uint n)
{
       0:	55                   	push   %ebp
       1:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
       3:	eb 0c                	jmp    11 <strcmpaa+0x11>
    n--, p++, q++;
       5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
       9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
       d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
struct cmd *parsecmd(char*);
void display_history();
int
strcmpaa(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
      11:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
      15:	74 1a                	je     31 <strcmpaa+0x31>
      17:	8b 45 08             	mov    0x8(%ebp),%eax
      1a:	0f b6 00             	movzbl (%eax),%eax
      1d:	84 c0                	test   %al,%al
      1f:	74 10                	je     31 <strcmpaa+0x31>
      21:	8b 45 08             	mov    0x8(%ebp),%eax
      24:	0f b6 10             	movzbl (%eax),%edx
      27:	8b 45 0c             	mov    0xc(%ebp),%eax
      2a:	0f b6 00             	movzbl (%eax),%eax
      2d:	38 c2                	cmp    %al,%dl
      2f:	74 d4                	je     5 <strcmpaa+0x5>
    n--, p++, q++;
  if(n == 0)
      31:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
      35:	75 07                	jne    3e <strcmpaa+0x3e>
    return 0;
      37:	b8 00 00 00 00       	mov    $0x0,%eax
      3c:	eb 16                	jmp    54 <strcmpaa+0x54>
  return (uchar)*p - (uchar)*q;
      3e:	8b 45 08             	mov    0x8(%ebp),%eax
      41:	0f b6 00             	movzbl (%eax),%eax
      44:	0f b6 d0             	movzbl %al,%edx
      47:	8b 45 0c             	mov    0xc(%ebp),%eax
      4a:	0f b6 00             	movzbl (%eax),%eax
      4d:	0f b6 c0             	movzbl %al,%eax
      50:	29 c2                	sub    %eax,%edx
      52:	89 d0                	mov    %edx,%eax
}
      54:	5d                   	pop    %ebp
      55:	c3                   	ret    

00000056 <runcmd>:

// Execute cmd.  Never returns.
void
runcmd(struct cmd *cmd)
{
      56:	55                   	push   %ebp
      57:	89 e5                	mov    %esp,%ebp
      59:	83 ec 38             	sub    $0x38,%esp
  struct execcmd *ecmd;
  struct listcmd *lcmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if(cmd == 0)
      5c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
      60:	75 05                	jne    67 <runcmd+0x11>
    exit();
      62:	e8 c0 0f 00 00       	call   1027 <exit>
  
  switch(cmd->type){
      67:	8b 45 08             	mov    0x8(%ebp),%eax
      6a:	8b 00                	mov    (%eax),%eax
      6c:	83 f8 05             	cmp    $0x5,%eax
      6f:	77 09                	ja     7a <runcmd+0x24>
      71:	8b 04 85 b8 15 00 00 	mov    0x15b8(,%eax,4),%eax
      78:	ff e0                	jmp    *%eax
  default:
    panic("runcmd");
      7a:	c7 04 24 8c 15 00 00 	movl   $0x158c,(%esp)
      81:	e8 46 03 00 00       	call   3cc <panic>

  case EXEC:
    ecmd = (struct execcmd*)cmd;
      86:	8b 45 08             	mov    0x8(%ebp),%eax
      89:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ecmd->argv[0] == 0)
      8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
      8f:	8b 40 04             	mov    0x4(%eax),%eax
      92:	85 c0                	test   %eax,%eax
      94:	75 05                	jne    9b <runcmd+0x45>
      exit();
      96:	e8 8c 0f 00 00       	call   1027 <exit>
    exec(ecmd->argv[0], ecmd->argv);
      9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
      9e:	8d 50 04             	lea    0x4(%eax),%edx
      a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
      a4:	8b 40 04             	mov    0x4(%eax),%eax
      a7:	89 54 24 04          	mov    %edx,0x4(%esp)
      ab:	89 04 24             	mov    %eax,(%esp)
      ae:	e8 ac 0f 00 00       	call   105f <exec>
    printf(2, "exec %s failed\n", ecmd->argv[0]);
      b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
      b6:	8b 40 04             	mov    0x4(%eax),%eax
      b9:	89 44 24 08          	mov    %eax,0x8(%esp)
      bd:	c7 44 24 04 93 15 00 	movl   $0x1593,0x4(%esp)
      c4:	00 
      c5:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
      cc:	e8 ee 10 00 00       	call   11bf <printf>
    break;
      d1:	e9 86 01 00 00       	jmp    25c <runcmd+0x206>

  case REDIR:
    rcmd = (struct redircmd*)cmd;
      d6:	8b 45 08             	mov    0x8(%ebp),%eax
      d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    close(rcmd->fd);
      dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
      df:	8b 40 14             	mov    0x14(%eax),%eax
      e2:	89 04 24             	mov    %eax,(%esp)
      e5:	e8 65 0f 00 00       	call   104f <close>
    if(open(rcmd->file, rcmd->mode) < 0){
      ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
      ed:	8b 50 10             	mov    0x10(%eax),%edx
      f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
      f3:	8b 40 08             	mov    0x8(%eax),%eax
      f6:	89 54 24 04          	mov    %edx,0x4(%esp)
      fa:	89 04 24             	mov    %eax,(%esp)
      fd:	e8 65 0f 00 00       	call   1067 <open>
     102:	85 c0                	test   %eax,%eax
     104:	79 23                	jns    129 <runcmd+0xd3>
      printf(2, "open %s failed\n", rcmd->file);
     106:	8b 45 f0             	mov    -0x10(%ebp),%eax
     109:	8b 40 08             	mov    0x8(%eax),%eax
     10c:	89 44 24 08          	mov    %eax,0x8(%esp)
     110:	c7 44 24 04 a3 15 00 	movl   $0x15a3,0x4(%esp)
     117:	00 
     118:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     11f:	e8 9b 10 00 00       	call   11bf <printf>
      exit();
     124:	e8 fe 0e 00 00       	call   1027 <exit>
    }
    runcmd(rcmd->cmd);
     129:	8b 45 f0             	mov    -0x10(%ebp),%eax
     12c:	8b 40 04             	mov    0x4(%eax),%eax
     12f:	89 04 24             	mov    %eax,(%esp)
     132:	e8 1f ff ff ff       	call   56 <runcmd>
    break;
     137:	e9 20 01 00 00       	jmp    25c <runcmd+0x206>

  case LIST:
    lcmd = (struct listcmd*)cmd;
     13c:	8b 45 08             	mov    0x8(%ebp),%eax
     13f:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(fork1() == 0)
     142:	e8 ab 02 00 00       	call   3f2 <fork1>
     147:	85 c0                	test   %eax,%eax
     149:	75 0e                	jne    159 <runcmd+0x103>
      runcmd(lcmd->left);
     14b:	8b 45 ec             	mov    -0x14(%ebp),%eax
     14e:	8b 40 04             	mov    0x4(%eax),%eax
     151:	89 04 24             	mov    %eax,(%esp)
     154:	e8 fd fe ff ff       	call   56 <runcmd>
    wait();
     159:	e8 d1 0e 00 00       	call   102f <wait>
    runcmd(lcmd->right);
     15e:	8b 45 ec             	mov    -0x14(%ebp),%eax
     161:	8b 40 08             	mov    0x8(%eax),%eax
     164:	89 04 24             	mov    %eax,(%esp)
     167:	e8 ea fe ff ff       	call   56 <runcmd>
    break;
     16c:	e9 eb 00 00 00       	jmp    25c <runcmd+0x206>

  case PIPE:
    pcmd = (struct pipecmd*)cmd;
     171:	8b 45 08             	mov    0x8(%ebp),%eax
     174:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pipe(p) < 0)
     177:	8d 45 dc             	lea    -0x24(%ebp),%eax
     17a:	89 04 24             	mov    %eax,(%esp)
     17d:	e8 b5 0e 00 00       	call   1037 <pipe>
     182:	85 c0                	test   %eax,%eax
     184:	79 0c                	jns    192 <runcmd+0x13c>
      panic("pipe");
     186:	c7 04 24 b3 15 00 00 	movl   $0x15b3,(%esp)
     18d:	e8 3a 02 00 00       	call   3cc <panic>
    if(fork1() == 0){
     192:	e8 5b 02 00 00       	call   3f2 <fork1>
     197:	85 c0                	test   %eax,%eax
     199:	75 3b                	jne    1d6 <runcmd+0x180>
      close(1);
     19b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     1a2:	e8 a8 0e 00 00       	call   104f <close>
      dup(p[1]);
     1a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
     1aa:	89 04 24             	mov    %eax,(%esp)
     1ad:	e8 ed 0e 00 00       	call   109f <dup>
      close(p[0]);
     1b2:	8b 45 dc             	mov    -0x24(%ebp),%eax
     1b5:	89 04 24             	mov    %eax,(%esp)
     1b8:	e8 92 0e 00 00       	call   104f <close>
      close(p[1]);
     1bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
     1c0:	89 04 24             	mov    %eax,(%esp)
     1c3:	e8 87 0e 00 00       	call   104f <close>
      runcmd(pcmd->left);
     1c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
     1cb:	8b 40 04             	mov    0x4(%eax),%eax
     1ce:	89 04 24             	mov    %eax,(%esp)
     1d1:	e8 80 fe ff ff       	call   56 <runcmd>
    }
    if(fork1() == 0){
     1d6:	e8 17 02 00 00       	call   3f2 <fork1>
     1db:	85 c0                	test   %eax,%eax
     1dd:	75 3b                	jne    21a <runcmd+0x1c4>
      close(0);
     1df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
     1e6:	e8 64 0e 00 00       	call   104f <close>
      dup(p[0]);
     1eb:	8b 45 dc             	mov    -0x24(%ebp),%eax
     1ee:	89 04 24             	mov    %eax,(%esp)
     1f1:	e8 a9 0e 00 00       	call   109f <dup>
      close(p[0]);
     1f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
     1f9:	89 04 24             	mov    %eax,(%esp)
     1fc:	e8 4e 0e 00 00       	call   104f <close>
      close(p[1]);
     201:	8b 45 e0             	mov    -0x20(%ebp),%eax
     204:	89 04 24             	mov    %eax,(%esp)
     207:	e8 43 0e 00 00       	call   104f <close>
      runcmd(pcmd->right);
     20c:	8b 45 e8             	mov    -0x18(%ebp),%eax
     20f:	8b 40 08             	mov    0x8(%eax),%eax
     212:	89 04 24             	mov    %eax,(%esp)
     215:	e8 3c fe ff ff       	call   56 <runcmd>
    }
    close(p[0]);
     21a:	8b 45 dc             	mov    -0x24(%ebp),%eax
     21d:	89 04 24             	mov    %eax,(%esp)
     220:	e8 2a 0e 00 00       	call   104f <close>
    close(p[1]);
     225:	8b 45 e0             	mov    -0x20(%ebp),%eax
     228:	89 04 24             	mov    %eax,(%esp)
     22b:	e8 1f 0e 00 00       	call   104f <close>
    wait();
     230:	e8 fa 0d 00 00       	call   102f <wait>
    wait();
     235:	e8 f5 0d 00 00       	call   102f <wait>
    break;
     23a:	eb 20                	jmp    25c <runcmd+0x206>
    
  case BACK:
    bcmd = (struct backcmd*)cmd;
     23c:	8b 45 08             	mov    0x8(%ebp),%eax
     23f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(fork1() == 0)
     242:	e8 ab 01 00 00       	call   3f2 <fork1>
     247:	85 c0                	test   %eax,%eax
     249:	75 10                	jne    25b <runcmd+0x205>
      runcmd(bcmd->cmd);
     24b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     24e:	8b 40 04             	mov    0x4(%eax),%eax
     251:	89 04 24             	mov    %eax,(%esp)
     254:	e8 fd fd ff ff       	call   56 <runcmd>
    break;
     259:	eb 00                	jmp    25b <runcmd+0x205>
     25b:	90                   	nop
  }
  exit();
     25c:	e8 c6 0d 00 00       	call   1027 <exit>

00000261 <getcmd>:
}

int
getcmd(char *buf, int nbuf)
{
     261:	55                   	push   %ebp
     262:	89 e5                	mov    %esp,%ebp
     264:	83 ec 18             	sub    $0x18,%esp
  printf(2, "$ ");
     267:	c7 44 24 04 d0 15 00 	movl   $0x15d0,0x4(%esp)
     26e:	00 
     26f:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     276:	e8 44 0f 00 00       	call   11bf <printf>
  memset(buf, 0, nbuf);
     27b:	8b 45 0c             	mov    0xc(%ebp),%eax
     27e:	89 44 24 08          	mov    %eax,0x8(%esp)
     282:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     289:	00 
     28a:	8b 45 08             	mov    0x8(%ebp),%eax
     28d:	89 04 24             	mov    %eax,(%esp)
     290:	e8 e5 0b 00 00       	call   e7a <memset>
  gets(buf, nbuf);
     295:	8b 45 0c             	mov    0xc(%ebp),%eax
     298:	89 44 24 04          	mov    %eax,0x4(%esp)
     29c:	8b 45 08             	mov    0x8(%ebp),%eax
     29f:	89 04 24             	mov    %eax,(%esp)
     2a2:	e8 2a 0c 00 00       	call   ed1 <gets>
  if(buf[0] == 0) // EOF
     2a7:	8b 45 08             	mov    0x8(%ebp),%eax
     2aa:	0f b6 00             	movzbl (%eax),%eax
     2ad:	84 c0                	test   %al,%al
     2af:	75 07                	jne    2b8 <getcmd+0x57>
    return -1;
     2b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
     2b6:	eb 05                	jmp    2bd <getcmd+0x5c>
  return 0;
     2b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
     2bd:	c9                   	leave  
     2be:	c3                   	ret    

000002bf <main>:

int
main(void)
{
     2bf:	55                   	push   %ebp
     2c0:	89 e5                	mov    %esp,%ebp
     2c2:	83 e4 f0             	and    $0xfffffff0,%esp
     2c5:	83 ec 20             	sub    $0x20,%esp
  static char buf[100];
  int fd;
  
  // Assumes three file descriptors open.
  while((fd = open("console", O_RDWR)) >= 0){
     2c8:	eb 15                	jmp    2df <main+0x20>
    if(fd >= 3){
     2ca:	83 7c 24 1c 02       	cmpl   $0x2,0x1c(%esp)
     2cf:	7e 0e                	jle    2df <main+0x20>
      close(fd);
     2d1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
     2d5:	89 04 24             	mov    %eax,(%esp)
     2d8:	e8 72 0d 00 00       	call   104f <close>
      break;
     2dd:	eb 1f                	jmp    2fe <main+0x3f>
{
  static char buf[100];
  int fd;
  
  // Assumes three file descriptors open.
  while((fd = open("console", O_RDWR)) >= 0){
     2df:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
     2e6:	00 
     2e7:	c7 04 24 d3 15 00 00 	movl   $0x15d3,(%esp)
     2ee:	e8 74 0d 00 00       	call   1067 <open>
     2f3:	89 44 24 1c          	mov    %eax,0x1c(%esp)
     2f7:	83 7c 24 1c 00       	cmpl   $0x0,0x1c(%esp)
     2fc:	79 cc                	jns    2ca <main+0xb>
      break;
    }
  }
  
  // Read and run input commands.
  while(getcmd(buf, sizeof(buf)) >= 0){
     2fe:	e9 a8 00 00 00       	jmp    3ab <main+0xec>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     303:	0f b6 05 80 1b 00 00 	movzbl 0x1b80,%eax
     30a:	3c 63                	cmp    $0x63,%al
     30c:	75 5c                	jne    36a <main+0xab>
     30e:	0f b6 05 81 1b 00 00 	movzbl 0x1b81,%eax
     315:	3c 64                	cmp    $0x64,%al
     317:	75 51                	jne    36a <main+0xab>
     319:	0f b6 05 82 1b 00 00 	movzbl 0x1b82,%eax
     320:	3c 20                	cmp    $0x20,%al
     322:	75 46                	jne    36a <main+0xab>
      // Clumsy but will have to do for now.
      // Chdir has no effect on the parent if run in the child.
      buf[strlen(buf)-1] = 0;  // chop \n
     324:	c7 04 24 80 1b 00 00 	movl   $0x1b80,(%esp)
     32b:	e8 23 0b 00 00       	call   e53 <strlen>
     330:	83 e8 01             	sub    $0x1,%eax
     333:	c6 80 80 1b 00 00 00 	movb   $0x0,0x1b80(%eax)
      if(chdir(buf+3) < 0)
     33a:	c7 04 24 83 1b 00 00 	movl   $0x1b83,(%esp)
     341:	e8 51 0d 00 00       	call   1097 <chdir>
     346:	85 c0                	test   %eax,%eax
     348:	79 1e                	jns    368 <main+0xa9>
        printf(2, "cannot cd %s\n", buf+3);
     34a:	c7 44 24 08 83 1b 00 	movl   $0x1b83,0x8(%esp)
     351:	00 
     352:	c7 44 24 04 db 15 00 	movl   $0x15db,0x4(%esp)
     359:	00 
     35a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     361:	e8 59 0e 00 00       	call   11bf <printf>
      continue;
     366:	eb 43                	jmp    3ab <main+0xec>
     368:	eb 41                	jmp    3ab <main+0xec>
    } else if (strcmp("history\n", buf) == 0) {
     36a:	c7 44 24 04 80 1b 00 	movl   $0x1b80,0x4(%esp)
     371:	00 
     372:	c7 04 24 e9 15 00 00 	movl   $0x15e9,(%esp)
     379:	e8 96 0a 00 00       	call   e14 <strcmp>
     37e:	85 c0                	test   %eax,%eax
     380:	75 07                	jne    389 <main+0xca>
      display_history();
     382:	e8 e7 09 00 00       	call   d6e <display_history>
      continue;
     387:	eb 22                	jmp    3ab <main+0xec>
    }
    if(fork1() == 0)
     389:	e8 64 00 00 00       	call   3f2 <fork1>
     38e:	85 c0                	test   %eax,%eax
     390:	75 14                	jne    3a6 <main+0xe7>
      runcmd(parsecmd(buf));
     392:	c7 04 24 80 1b 00 00 	movl   $0x1b80,(%esp)
     399:	e8 c9 03 00 00       	call   767 <parsecmd>
     39e:	89 04 24             	mov    %eax,(%esp)
     3a1:	e8 b0 fc ff ff       	call   56 <runcmd>
    wait();
     3a6:	e8 84 0c 00 00       	call   102f <wait>
      break;
    }
  }
  
  // Read and run input commands.
  while(getcmd(buf, sizeof(buf)) >= 0){
     3ab:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
     3b2:	00 
     3b3:	c7 04 24 80 1b 00 00 	movl   $0x1b80,(%esp)
     3ba:	e8 a2 fe ff ff       	call   261 <getcmd>
     3bf:	85 c0                	test   %eax,%eax
     3c1:	0f 89 3c ff ff ff    	jns    303 <main+0x44>
    }
    if(fork1() == 0)
      runcmd(parsecmd(buf));
    wait();
  }
  exit();
     3c7:	e8 5b 0c 00 00       	call   1027 <exit>

000003cc <panic>:
}

void
panic(char *s)
{
     3cc:	55                   	push   %ebp
     3cd:	89 e5                	mov    %esp,%ebp
     3cf:	83 ec 18             	sub    $0x18,%esp
  printf(2, "%s\n", s);
     3d2:	8b 45 08             	mov    0x8(%ebp),%eax
     3d5:	89 44 24 08          	mov    %eax,0x8(%esp)
     3d9:	c7 44 24 04 f2 15 00 	movl   $0x15f2,0x4(%esp)
     3e0:	00 
     3e1:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     3e8:	e8 d2 0d 00 00       	call   11bf <printf>
  exit();
     3ed:	e8 35 0c 00 00       	call   1027 <exit>

000003f2 <fork1>:
}

int
fork1(void)
{
     3f2:	55                   	push   %ebp
     3f3:	89 e5                	mov    %esp,%ebp
     3f5:	83 ec 28             	sub    $0x28,%esp
  int pid;
  
  pid = fork();
     3f8:	e8 22 0c 00 00       	call   101f <fork>
     3fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pid == -1)
     400:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
     404:	75 0c                	jne    412 <fork1+0x20>
    panic("fork");
     406:	c7 04 24 f6 15 00 00 	movl   $0x15f6,(%esp)
     40d:	e8 ba ff ff ff       	call   3cc <panic>
  return pid;
     412:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     415:	c9                   	leave  
     416:	c3                   	ret    

00000417 <execcmd>:
//PAGEBREAK!
// Constructors

struct cmd*
execcmd(void)
{
     417:	55                   	push   %ebp
     418:	89 e5                	mov    %esp,%ebp
     41a:	83 ec 28             	sub    $0x28,%esp
  struct execcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     41d:	c7 04 24 54 00 00 00 	movl   $0x54,(%esp)
     424:	e8 82 10 00 00       	call   14ab <malloc>
     429:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     42c:	c7 44 24 08 54 00 00 	movl   $0x54,0x8(%esp)
     433:	00 
     434:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     43b:	00 
     43c:	8b 45 f4             	mov    -0xc(%ebp),%eax
     43f:	89 04 24             	mov    %eax,(%esp)
     442:	e8 33 0a 00 00       	call   e7a <memset>
  cmd->type = EXEC;
     447:	8b 45 f4             	mov    -0xc(%ebp),%eax
     44a:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  return (struct cmd*)cmd;
     450:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     453:	c9                   	leave  
     454:	c3                   	ret    

00000455 <redircmd>:

struct cmd*
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
     455:	55                   	push   %ebp
     456:	89 e5                	mov    %esp,%ebp
     458:	83 ec 28             	sub    $0x28,%esp
  struct redircmd *cmd;

  cmd = malloc(sizeof(*cmd));
     45b:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
     462:	e8 44 10 00 00       	call   14ab <malloc>
     467:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     46a:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
     471:	00 
     472:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     479:	00 
     47a:	8b 45 f4             	mov    -0xc(%ebp),%eax
     47d:	89 04 24             	mov    %eax,(%esp)
     480:	e8 f5 09 00 00       	call   e7a <memset>
  cmd->type = REDIR;
     485:	8b 45 f4             	mov    -0xc(%ebp),%eax
     488:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  cmd->cmd = subcmd;
     48e:	8b 45 f4             	mov    -0xc(%ebp),%eax
     491:	8b 55 08             	mov    0x8(%ebp),%edx
     494:	89 50 04             	mov    %edx,0x4(%eax)
  cmd->file = file;
     497:	8b 45 f4             	mov    -0xc(%ebp),%eax
     49a:	8b 55 0c             	mov    0xc(%ebp),%edx
     49d:	89 50 08             	mov    %edx,0x8(%eax)
  cmd->efile = efile;
     4a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4a3:	8b 55 10             	mov    0x10(%ebp),%edx
     4a6:	89 50 0c             	mov    %edx,0xc(%eax)
  cmd->mode = mode;
     4a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4ac:	8b 55 14             	mov    0x14(%ebp),%edx
     4af:	89 50 10             	mov    %edx,0x10(%eax)
  cmd->fd = fd;
     4b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4b5:	8b 55 18             	mov    0x18(%ebp),%edx
     4b8:	89 50 14             	mov    %edx,0x14(%eax)
  return (struct cmd*)cmd;
     4bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     4be:	c9                   	leave  
     4bf:	c3                   	ret    

000004c0 <pipecmd>:

struct cmd*
pipecmd(struct cmd *left, struct cmd *right)
{
     4c0:	55                   	push   %ebp
     4c1:	89 e5                	mov    %esp,%ebp
     4c3:	83 ec 28             	sub    $0x28,%esp
  struct pipecmd *cmd;

  cmd = malloc(sizeof(*cmd));
     4c6:	c7 04 24 0c 00 00 00 	movl   $0xc,(%esp)
     4cd:	e8 d9 0f 00 00       	call   14ab <malloc>
     4d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     4d5:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
     4dc:	00 
     4dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     4e4:	00 
     4e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4e8:	89 04 24             	mov    %eax,(%esp)
     4eb:	e8 8a 09 00 00       	call   e7a <memset>
  cmd->type = PIPE;
     4f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4f3:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
  cmd->left = left;
     4f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4fc:	8b 55 08             	mov    0x8(%ebp),%edx
     4ff:	89 50 04             	mov    %edx,0x4(%eax)
  cmd->right = right;
     502:	8b 45 f4             	mov    -0xc(%ebp),%eax
     505:	8b 55 0c             	mov    0xc(%ebp),%edx
     508:	89 50 08             	mov    %edx,0x8(%eax)
  return (struct cmd*)cmd;
     50b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     50e:	c9                   	leave  
     50f:	c3                   	ret    

00000510 <listcmd>:

struct cmd*
listcmd(struct cmd *left, struct cmd *right)
{
     510:	55                   	push   %ebp
     511:	89 e5                	mov    %esp,%ebp
     513:	83 ec 28             	sub    $0x28,%esp
  struct listcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     516:	c7 04 24 0c 00 00 00 	movl   $0xc,(%esp)
     51d:	e8 89 0f 00 00       	call   14ab <malloc>
     522:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     525:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
     52c:	00 
     52d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     534:	00 
     535:	8b 45 f4             	mov    -0xc(%ebp),%eax
     538:	89 04 24             	mov    %eax,(%esp)
     53b:	e8 3a 09 00 00       	call   e7a <memset>
  cmd->type = LIST;
     540:	8b 45 f4             	mov    -0xc(%ebp),%eax
     543:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
  cmd->left = left;
     549:	8b 45 f4             	mov    -0xc(%ebp),%eax
     54c:	8b 55 08             	mov    0x8(%ebp),%edx
     54f:	89 50 04             	mov    %edx,0x4(%eax)
  cmd->right = right;
     552:	8b 45 f4             	mov    -0xc(%ebp),%eax
     555:	8b 55 0c             	mov    0xc(%ebp),%edx
     558:	89 50 08             	mov    %edx,0x8(%eax)
  return (struct cmd*)cmd;
     55b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     55e:	c9                   	leave  
     55f:	c3                   	ret    

00000560 <backcmd>:

struct cmd*
backcmd(struct cmd *subcmd)
{
     560:	55                   	push   %ebp
     561:	89 e5                	mov    %esp,%ebp
     563:	83 ec 28             	sub    $0x28,%esp
  struct backcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     566:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
     56d:	e8 39 0f 00 00       	call   14ab <malloc>
     572:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     575:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
     57c:	00 
     57d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     584:	00 
     585:	8b 45 f4             	mov    -0xc(%ebp),%eax
     588:	89 04 24             	mov    %eax,(%esp)
     58b:	e8 ea 08 00 00       	call   e7a <memset>
  cmd->type = BACK;
     590:	8b 45 f4             	mov    -0xc(%ebp),%eax
     593:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
  cmd->cmd = subcmd;
     599:	8b 45 f4             	mov    -0xc(%ebp),%eax
     59c:	8b 55 08             	mov    0x8(%ebp),%edx
     59f:	89 50 04             	mov    %edx,0x4(%eax)
  return (struct cmd*)cmd;
     5a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     5a5:	c9                   	leave  
     5a6:	c3                   	ret    

000005a7 <gettoken>:
char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>&;()";

int
gettoken(char **ps, char *es, char **q, char **eq)
{
     5a7:	55                   	push   %ebp
     5a8:	89 e5                	mov    %esp,%ebp
     5aa:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int ret;
  
  s = *ps;
     5ad:	8b 45 08             	mov    0x8(%ebp),%eax
     5b0:	8b 00                	mov    (%eax),%eax
     5b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(s < es && strchr(whitespace, *s))
     5b5:	eb 04                	jmp    5bb <gettoken+0x14>
    s++;
     5b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
{
  char *s;
  int ret;
  
  s = *ps;
  while(s < es && strchr(whitespace, *s))
     5bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
     5be:	3b 45 0c             	cmp    0xc(%ebp),%eax
     5c1:	73 1d                	jae    5e0 <gettoken+0x39>
     5c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
     5c6:	0f b6 00             	movzbl (%eax),%eax
     5c9:	0f be c0             	movsbl %al,%eax
     5cc:	89 44 24 04          	mov    %eax,0x4(%esp)
     5d0:	c7 04 24 58 1b 00 00 	movl   $0x1b58,(%esp)
     5d7:	e8 c2 08 00 00       	call   e9e <strchr>
     5dc:	85 c0                	test   %eax,%eax
     5de:	75 d7                	jne    5b7 <gettoken+0x10>
    s++;
  if(q)
     5e0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
     5e4:	74 08                	je     5ee <gettoken+0x47>
    *q = s;
     5e6:	8b 45 10             	mov    0x10(%ebp),%eax
     5e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
     5ec:	89 10                	mov    %edx,(%eax)
  ret = *s;
     5ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
     5f1:	0f b6 00             	movzbl (%eax),%eax
     5f4:	0f be c0             	movsbl %al,%eax
     5f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  switch(*s){
     5fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
     5fd:	0f b6 00             	movzbl (%eax),%eax
     600:	0f be c0             	movsbl %al,%eax
     603:	83 f8 29             	cmp    $0x29,%eax
     606:	7f 14                	jg     61c <gettoken+0x75>
     608:	83 f8 28             	cmp    $0x28,%eax
     60b:	7d 28                	jge    635 <gettoken+0x8e>
     60d:	85 c0                	test   %eax,%eax
     60f:	0f 84 94 00 00 00    	je     6a9 <gettoken+0x102>
     615:	83 f8 26             	cmp    $0x26,%eax
     618:	74 1b                	je     635 <gettoken+0x8e>
     61a:	eb 3c                	jmp    658 <gettoken+0xb1>
     61c:	83 f8 3e             	cmp    $0x3e,%eax
     61f:	74 1a                	je     63b <gettoken+0x94>
     621:	83 f8 3e             	cmp    $0x3e,%eax
     624:	7f 0a                	jg     630 <gettoken+0x89>
     626:	83 e8 3b             	sub    $0x3b,%eax
     629:	83 f8 01             	cmp    $0x1,%eax
     62c:	77 2a                	ja     658 <gettoken+0xb1>
     62e:	eb 05                	jmp    635 <gettoken+0x8e>
     630:	83 f8 7c             	cmp    $0x7c,%eax
     633:	75 23                	jne    658 <gettoken+0xb1>
  case '(':
  case ')':
  case ';':
  case '&':
  case '<':
    s++;
     635:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    break;
     639:	eb 6f                	jmp    6aa <gettoken+0x103>
  case '>':
    s++;
     63b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(*s == '>'){
     63f:	8b 45 f4             	mov    -0xc(%ebp),%eax
     642:	0f b6 00             	movzbl (%eax),%eax
     645:	3c 3e                	cmp    $0x3e,%al
     647:	75 0d                	jne    656 <gettoken+0xaf>
      ret = '+';
     649:	c7 45 f0 2b 00 00 00 	movl   $0x2b,-0x10(%ebp)
      s++;
     650:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    }
    break;
     654:	eb 54                	jmp    6aa <gettoken+0x103>
     656:	eb 52                	jmp    6aa <gettoken+0x103>
  default:
    ret = 'a';
     658:	c7 45 f0 61 00 00 00 	movl   $0x61,-0x10(%ebp)
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     65f:	eb 04                	jmp    665 <gettoken+0xbe>
      s++;
     661:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      s++;
    }
    break;
  default:
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     665:	8b 45 f4             	mov    -0xc(%ebp),%eax
     668:	3b 45 0c             	cmp    0xc(%ebp),%eax
     66b:	73 3a                	jae    6a7 <gettoken+0x100>
     66d:	8b 45 f4             	mov    -0xc(%ebp),%eax
     670:	0f b6 00             	movzbl (%eax),%eax
     673:	0f be c0             	movsbl %al,%eax
     676:	89 44 24 04          	mov    %eax,0x4(%esp)
     67a:	c7 04 24 58 1b 00 00 	movl   $0x1b58,(%esp)
     681:	e8 18 08 00 00       	call   e9e <strchr>
     686:	85 c0                	test   %eax,%eax
     688:	75 1d                	jne    6a7 <gettoken+0x100>
     68a:	8b 45 f4             	mov    -0xc(%ebp),%eax
     68d:	0f b6 00             	movzbl (%eax),%eax
     690:	0f be c0             	movsbl %al,%eax
     693:	89 44 24 04          	mov    %eax,0x4(%esp)
     697:	c7 04 24 5e 1b 00 00 	movl   $0x1b5e,(%esp)
     69e:	e8 fb 07 00 00       	call   e9e <strchr>
     6a3:	85 c0                	test   %eax,%eax
     6a5:	74 ba                	je     661 <gettoken+0xba>
      s++;
    break;
     6a7:	eb 01                	jmp    6aa <gettoken+0x103>
  if(q)
    *q = s;
  ret = *s;
  switch(*s){
  case 0:
    break;
     6a9:	90                   	nop
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
      s++;
    break;
  }
  if(eq)
     6aa:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
     6ae:	74 0a                	je     6ba <gettoken+0x113>
    *eq = s;
     6b0:	8b 45 14             	mov    0x14(%ebp),%eax
     6b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
     6b6:	89 10                	mov    %edx,(%eax)
  
  while(s < es && strchr(whitespace, *s))
     6b8:	eb 06                	jmp    6c0 <gettoken+0x119>
     6ba:	eb 04                	jmp    6c0 <gettoken+0x119>
    s++;
     6bc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    break;
  }
  if(eq)
    *eq = s;
  
  while(s < es && strchr(whitespace, *s))
     6c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
     6c3:	3b 45 0c             	cmp    0xc(%ebp),%eax
     6c6:	73 1d                	jae    6e5 <gettoken+0x13e>
     6c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
     6cb:	0f b6 00             	movzbl (%eax),%eax
     6ce:	0f be c0             	movsbl %al,%eax
     6d1:	89 44 24 04          	mov    %eax,0x4(%esp)
     6d5:	c7 04 24 58 1b 00 00 	movl   $0x1b58,(%esp)
     6dc:	e8 bd 07 00 00       	call   e9e <strchr>
     6e1:	85 c0                	test   %eax,%eax
     6e3:	75 d7                	jne    6bc <gettoken+0x115>
    s++;
  *ps = s;
     6e5:	8b 45 08             	mov    0x8(%ebp),%eax
     6e8:	8b 55 f4             	mov    -0xc(%ebp),%edx
     6eb:	89 10                	mov    %edx,(%eax)
  return ret;
     6ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
     6f0:	c9                   	leave  
     6f1:	c3                   	ret    

000006f2 <peek>:

int
peek(char **ps, char *es, char *toks)
{
     6f2:	55                   	push   %ebp
     6f3:	89 e5                	mov    %esp,%ebp
     6f5:	83 ec 28             	sub    $0x28,%esp
  char *s;
  
  s = *ps;
     6f8:	8b 45 08             	mov    0x8(%ebp),%eax
     6fb:	8b 00                	mov    (%eax),%eax
     6fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(s < es && strchr(whitespace, *s))
     700:	eb 04                	jmp    706 <peek+0x14>
    s++;
     702:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
peek(char **ps, char *es, char *toks)
{
  char *s;
  
  s = *ps;
  while(s < es && strchr(whitespace, *s))
     706:	8b 45 f4             	mov    -0xc(%ebp),%eax
     709:	3b 45 0c             	cmp    0xc(%ebp),%eax
     70c:	73 1d                	jae    72b <peek+0x39>
     70e:	8b 45 f4             	mov    -0xc(%ebp),%eax
     711:	0f b6 00             	movzbl (%eax),%eax
     714:	0f be c0             	movsbl %al,%eax
     717:	89 44 24 04          	mov    %eax,0x4(%esp)
     71b:	c7 04 24 58 1b 00 00 	movl   $0x1b58,(%esp)
     722:	e8 77 07 00 00       	call   e9e <strchr>
     727:	85 c0                	test   %eax,%eax
     729:	75 d7                	jne    702 <peek+0x10>
    s++;
  *ps = s;
     72b:	8b 45 08             	mov    0x8(%ebp),%eax
     72e:	8b 55 f4             	mov    -0xc(%ebp),%edx
     731:	89 10                	mov    %edx,(%eax)
  return *s && strchr(toks, *s);
     733:	8b 45 f4             	mov    -0xc(%ebp),%eax
     736:	0f b6 00             	movzbl (%eax),%eax
     739:	84 c0                	test   %al,%al
     73b:	74 23                	je     760 <peek+0x6e>
     73d:	8b 45 f4             	mov    -0xc(%ebp),%eax
     740:	0f b6 00             	movzbl (%eax),%eax
     743:	0f be c0             	movsbl %al,%eax
     746:	89 44 24 04          	mov    %eax,0x4(%esp)
     74a:	8b 45 10             	mov    0x10(%ebp),%eax
     74d:	89 04 24             	mov    %eax,(%esp)
     750:	e8 49 07 00 00       	call   e9e <strchr>
     755:	85 c0                	test   %eax,%eax
     757:	74 07                	je     760 <peek+0x6e>
     759:	b8 01 00 00 00       	mov    $0x1,%eax
     75e:	eb 05                	jmp    765 <peek+0x73>
     760:	b8 00 00 00 00       	mov    $0x0,%eax
}
     765:	c9                   	leave  
     766:	c3                   	ret    

00000767 <parsecmd>:
struct cmd *parseexec(char**, char*);
struct cmd *nulterminate(struct cmd*);

struct cmd*
parsecmd(char *s)
{
     767:	55                   	push   %ebp
     768:	89 e5                	mov    %esp,%ebp
     76a:	53                   	push   %ebx
     76b:	83 ec 24             	sub    $0x24,%esp
  char *es;
  struct cmd *cmd;

  es = s + strlen(s);
     76e:	8b 5d 08             	mov    0x8(%ebp),%ebx
     771:	8b 45 08             	mov    0x8(%ebp),%eax
     774:	89 04 24             	mov    %eax,(%esp)
     777:	e8 d7 06 00 00       	call   e53 <strlen>
     77c:	01 d8                	add    %ebx,%eax
     77e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  cmd = parseline(&s, es);
     781:	8b 45 f4             	mov    -0xc(%ebp),%eax
     784:	89 44 24 04          	mov    %eax,0x4(%esp)
     788:	8d 45 08             	lea    0x8(%ebp),%eax
     78b:	89 04 24             	mov    %eax,(%esp)
     78e:	e8 60 00 00 00       	call   7f3 <parseline>
     793:	89 45 f0             	mov    %eax,-0x10(%ebp)
  peek(&s, es, "");
     796:	c7 44 24 08 fb 15 00 	movl   $0x15fb,0x8(%esp)
     79d:	00 
     79e:	8b 45 f4             	mov    -0xc(%ebp),%eax
     7a1:	89 44 24 04          	mov    %eax,0x4(%esp)
     7a5:	8d 45 08             	lea    0x8(%ebp),%eax
     7a8:	89 04 24             	mov    %eax,(%esp)
     7ab:	e8 42 ff ff ff       	call   6f2 <peek>
  if(s != es){
     7b0:	8b 45 08             	mov    0x8(%ebp),%eax
     7b3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
     7b6:	74 27                	je     7df <parsecmd+0x78>
    printf(2, "leftovers: %s\n", s);
     7b8:	8b 45 08             	mov    0x8(%ebp),%eax
     7bb:	89 44 24 08          	mov    %eax,0x8(%esp)
     7bf:	c7 44 24 04 fc 15 00 	movl   $0x15fc,0x4(%esp)
     7c6:	00 
     7c7:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     7ce:	e8 ec 09 00 00       	call   11bf <printf>
    panic("syntax");
     7d3:	c7 04 24 0b 16 00 00 	movl   $0x160b,(%esp)
     7da:	e8 ed fb ff ff       	call   3cc <panic>
  }
  nulterminate(cmd);
     7df:	8b 45 f0             	mov    -0x10(%ebp),%eax
     7e2:	89 04 24             	mov    %eax,(%esp)
     7e5:	e8 a3 04 00 00       	call   c8d <nulterminate>
  return cmd;
     7ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
     7ed:	83 c4 24             	add    $0x24,%esp
     7f0:	5b                   	pop    %ebx
     7f1:	5d                   	pop    %ebp
     7f2:	c3                   	ret    

000007f3 <parseline>:

struct cmd*
parseline(char **ps, char *es)
{
     7f3:	55                   	push   %ebp
     7f4:	89 e5                	mov    %esp,%ebp
     7f6:	83 ec 28             	sub    $0x28,%esp
  struct cmd *cmd;

  cmd = parsepipe(ps, es);
     7f9:	8b 45 0c             	mov    0xc(%ebp),%eax
     7fc:	89 44 24 04          	mov    %eax,0x4(%esp)
     800:	8b 45 08             	mov    0x8(%ebp),%eax
     803:	89 04 24             	mov    %eax,(%esp)
     806:	e8 bc 00 00 00       	call   8c7 <parsepipe>
     80b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(peek(ps, es, "&")){
     80e:	eb 30                	jmp    840 <parseline+0x4d>
    gettoken(ps, es, 0, 0);
     810:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     817:	00 
     818:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     81f:	00 
     820:	8b 45 0c             	mov    0xc(%ebp),%eax
     823:	89 44 24 04          	mov    %eax,0x4(%esp)
     827:	8b 45 08             	mov    0x8(%ebp),%eax
     82a:	89 04 24             	mov    %eax,(%esp)
     82d:	e8 75 fd ff ff       	call   5a7 <gettoken>
    cmd = backcmd(cmd);
     832:	8b 45 f4             	mov    -0xc(%ebp),%eax
     835:	89 04 24             	mov    %eax,(%esp)
     838:	e8 23 fd ff ff       	call   560 <backcmd>
     83d:	89 45 f4             	mov    %eax,-0xc(%ebp)
parseline(char **ps, char *es)
{
  struct cmd *cmd;

  cmd = parsepipe(ps, es);
  while(peek(ps, es, "&")){
     840:	c7 44 24 08 12 16 00 	movl   $0x1612,0x8(%esp)
     847:	00 
     848:	8b 45 0c             	mov    0xc(%ebp),%eax
     84b:	89 44 24 04          	mov    %eax,0x4(%esp)
     84f:	8b 45 08             	mov    0x8(%ebp),%eax
     852:	89 04 24             	mov    %eax,(%esp)
     855:	e8 98 fe ff ff       	call   6f2 <peek>
     85a:	85 c0                	test   %eax,%eax
     85c:	75 b2                	jne    810 <parseline+0x1d>
    gettoken(ps, es, 0, 0);
    cmd = backcmd(cmd);
  }
  if(peek(ps, es, ";")){
     85e:	c7 44 24 08 14 16 00 	movl   $0x1614,0x8(%esp)
     865:	00 
     866:	8b 45 0c             	mov    0xc(%ebp),%eax
     869:	89 44 24 04          	mov    %eax,0x4(%esp)
     86d:	8b 45 08             	mov    0x8(%ebp),%eax
     870:	89 04 24             	mov    %eax,(%esp)
     873:	e8 7a fe ff ff       	call   6f2 <peek>
     878:	85 c0                	test   %eax,%eax
     87a:	74 46                	je     8c2 <parseline+0xcf>
    gettoken(ps, es, 0, 0);
     87c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     883:	00 
     884:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     88b:	00 
     88c:	8b 45 0c             	mov    0xc(%ebp),%eax
     88f:	89 44 24 04          	mov    %eax,0x4(%esp)
     893:	8b 45 08             	mov    0x8(%ebp),%eax
     896:	89 04 24             	mov    %eax,(%esp)
     899:	e8 09 fd ff ff       	call   5a7 <gettoken>
    cmd = listcmd(cmd, parseline(ps, es));
     89e:	8b 45 0c             	mov    0xc(%ebp),%eax
     8a1:	89 44 24 04          	mov    %eax,0x4(%esp)
     8a5:	8b 45 08             	mov    0x8(%ebp),%eax
     8a8:	89 04 24             	mov    %eax,(%esp)
     8ab:	e8 43 ff ff ff       	call   7f3 <parseline>
     8b0:	89 44 24 04          	mov    %eax,0x4(%esp)
     8b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
     8b7:	89 04 24             	mov    %eax,(%esp)
     8ba:	e8 51 fc ff ff       	call   510 <listcmd>
     8bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  }
  return cmd;
     8c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     8c5:	c9                   	leave  
     8c6:	c3                   	ret    

000008c7 <parsepipe>:

struct cmd*
parsepipe(char **ps, char *es)
{
     8c7:	55                   	push   %ebp
     8c8:	89 e5                	mov    %esp,%ebp
     8ca:	83 ec 28             	sub    $0x28,%esp
  struct cmd *cmd;

  cmd = parseexec(ps, es);
     8cd:	8b 45 0c             	mov    0xc(%ebp),%eax
     8d0:	89 44 24 04          	mov    %eax,0x4(%esp)
     8d4:	8b 45 08             	mov    0x8(%ebp),%eax
     8d7:	89 04 24             	mov    %eax,(%esp)
     8da:	e8 68 02 00 00       	call   b47 <parseexec>
     8df:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(peek(ps, es, "|")){
     8e2:	c7 44 24 08 16 16 00 	movl   $0x1616,0x8(%esp)
     8e9:	00 
     8ea:	8b 45 0c             	mov    0xc(%ebp),%eax
     8ed:	89 44 24 04          	mov    %eax,0x4(%esp)
     8f1:	8b 45 08             	mov    0x8(%ebp),%eax
     8f4:	89 04 24             	mov    %eax,(%esp)
     8f7:	e8 f6 fd ff ff       	call   6f2 <peek>
     8fc:	85 c0                	test   %eax,%eax
     8fe:	74 46                	je     946 <parsepipe+0x7f>
    gettoken(ps, es, 0, 0);
     900:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     907:	00 
     908:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     90f:	00 
     910:	8b 45 0c             	mov    0xc(%ebp),%eax
     913:	89 44 24 04          	mov    %eax,0x4(%esp)
     917:	8b 45 08             	mov    0x8(%ebp),%eax
     91a:	89 04 24             	mov    %eax,(%esp)
     91d:	e8 85 fc ff ff       	call   5a7 <gettoken>
    cmd = pipecmd(cmd, parsepipe(ps, es));
     922:	8b 45 0c             	mov    0xc(%ebp),%eax
     925:	89 44 24 04          	mov    %eax,0x4(%esp)
     929:	8b 45 08             	mov    0x8(%ebp),%eax
     92c:	89 04 24             	mov    %eax,(%esp)
     92f:	e8 93 ff ff ff       	call   8c7 <parsepipe>
     934:	89 44 24 04          	mov    %eax,0x4(%esp)
     938:	8b 45 f4             	mov    -0xc(%ebp),%eax
     93b:	89 04 24             	mov    %eax,(%esp)
     93e:	e8 7d fb ff ff       	call   4c0 <pipecmd>
     943:	89 45 f4             	mov    %eax,-0xc(%ebp)
  }
  return cmd;
     946:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     949:	c9                   	leave  
     94a:	c3                   	ret    

0000094b <parseredirs>:

struct cmd*
parseredirs(struct cmd *cmd, char **ps, char *es)
{
     94b:	55                   	push   %ebp
     94c:	89 e5                	mov    %esp,%ebp
     94e:	83 ec 38             	sub    $0x38,%esp
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
     951:	e9 f6 00 00 00       	jmp    a4c <parseredirs+0x101>
    tok = gettoken(ps, es, 0, 0);
     956:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     95d:	00 
     95e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     965:	00 
     966:	8b 45 10             	mov    0x10(%ebp),%eax
     969:	89 44 24 04          	mov    %eax,0x4(%esp)
     96d:	8b 45 0c             	mov    0xc(%ebp),%eax
     970:	89 04 24             	mov    %eax,(%esp)
     973:	e8 2f fc ff ff       	call   5a7 <gettoken>
     978:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(gettoken(ps, es, &q, &eq) != 'a')
     97b:	8d 45 ec             	lea    -0x14(%ebp),%eax
     97e:	89 44 24 0c          	mov    %eax,0xc(%esp)
     982:	8d 45 f0             	lea    -0x10(%ebp),%eax
     985:	89 44 24 08          	mov    %eax,0x8(%esp)
     989:	8b 45 10             	mov    0x10(%ebp),%eax
     98c:	89 44 24 04          	mov    %eax,0x4(%esp)
     990:	8b 45 0c             	mov    0xc(%ebp),%eax
     993:	89 04 24             	mov    %eax,(%esp)
     996:	e8 0c fc ff ff       	call   5a7 <gettoken>
     99b:	83 f8 61             	cmp    $0x61,%eax
     99e:	74 0c                	je     9ac <parseredirs+0x61>
      panic("missing file for redirection");
     9a0:	c7 04 24 18 16 00 00 	movl   $0x1618,(%esp)
     9a7:	e8 20 fa ff ff       	call   3cc <panic>
    switch(tok){
     9ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
     9af:	83 f8 3c             	cmp    $0x3c,%eax
     9b2:	74 0f                	je     9c3 <parseredirs+0x78>
     9b4:	83 f8 3e             	cmp    $0x3e,%eax
     9b7:	74 38                	je     9f1 <parseredirs+0xa6>
     9b9:	83 f8 2b             	cmp    $0x2b,%eax
     9bc:	74 61                	je     a1f <parseredirs+0xd4>
     9be:	e9 89 00 00 00       	jmp    a4c <parseredirs+0x101>
    case '<':
      cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
     9c3:	8b 55 ec             	mov    -0x14(%ebp),%edx
     9c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
     9c9:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
     9d0:	00 
     9d1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     9d8:	00 
     9d9:	89 54 24 08          	mov    %edx,0x8(%esp)
     9dd:	89 44 24 04          	mov    %eax,0x4(%esp)
     9e1:	8b 45 08             	mov    0x8(%ebp),%eax
     9e4:	89 04 24             	mov    %eax,(%esp)
     9e7:	e8 69 fa ff ff       	call   455 <redircmd>
     9ec:	89 45 08             	mov    %eax,0x8(%ebp)
      break;
     9ef:	eb 5b                	jmp    a4c <parseredirs+0x101>
    case '>':
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
     9f1:	8b 55 ec             	mov    -0x14(%ebp),%edx
     9f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
     9f7:	c7 44 24 10 01 00 00 	movl   $0x1,0x10(%esp)
     9fe:	00 
     9ff:	c7 44 24 0c 01 02 00 	movl   $0x201,0xc(%esp)
     a06:	00 
     a07:	89 54 24 08          	mov    %edx,0x8(%esp)
     a0b:	89 44 24 04          	mov    %eax,0x4(%esp)
     a0f:	8b 45 08             	mov    0x8(%ebp),%eax
     a12:	89 04 24             	mov    %eax,(%esp)
     a15:	e8 3b fa ff ff       	call   455 <redircmd>
     a1a:	89 45 08             	mov    %eax,0x8(%ebp)
      break;
     a1d:	eb 2d                	jmp    a4c <parseredirs+0x101>
    case '+':  // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
     a1f:	8b 55 ec             	mov    -0x14(%ebp),%edx
     a22:	8b 45 f0             	mov    -0x10(%ebp),%eax
     a25:	c7 44 24 10 01 00 00 	movl   $0x1,0x10(%esp)
     a2c:	00 
     a2d:	c7 44 24 0c 01 02 00 	movl   $0x201,0xc(%esp)
     a34:	00 
     a35:	89 54 24 08          	mov    %edx,0x8(%esp)
     a39:	89 44 24 04          	mov    %eax,0x4(%esp)
     a3d:	8b 45 08             	mov    0x8(%ebp),%eax
     a40:	89 04 24             	mov    %eax,(%esp)
     a43:	e8 0d fa ff ff       	call   455 <redircmd>
     a48:	89 45 08             	mov    %eax,0x8(%ebp)
      break;
     a4b:	90                   	nop
parseredirs(struct cmd *cmd, char **ps, char *es)
{
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
     a4c:	c7 44 24 08 35 16 00 	movl   $0x1635,0x8(%esp)
     a53:	00 
     a54:	8b 45 10             	mov    0x10(%ebp),%eax
     a57:	89 44 24 04          	mov    %eax,0x4(%esp)
     a5b:	8b 45 0c             	mov    0xc(%ebp),%eax
     a5e:	89 04 24             	mov    %eax,(%esp)
     a61:	e8 8c fc ff ff       	call   6f2 <peek>
     a66:	85 c0                	test   %eax,%eax
     a68:	0f 85 e8 fe ff ff    	jne    956 <parseredirs+0xb>
    case '+':  // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
      break;
    }
  }
  return cmd;
     a6e:	8b 45 08             	mov    0x8(%ebp),%eax
}
     a71:	c9                   	leave  
     a72:	c3                   	ret    

00000a73 <parseblock>:

struct cmd*
parseblock(char **ps, char *es)
{
     a73:	55                   	push   %ebp
     a74:	89 e5                	mov    %esp,%ebp
     a76:	83 ec 28             	sub    $0x28,%esp
  struct cmd *cmd;

  if(!peek(ps, es, "("))
     a79:	c7 44 24 08 38 16 00 	movl   $0x1638,0x8(%esp)
     a80:	00 
     a81:	8b 45 0c             	mov    0xc(%ebp),%eax
     a84:	89 44 24 04          	mov    %eax,0x4(%esp)
     a88:	8b 45 08             	mov    0x8(%ebp),%eax
     a8b:	89 04 24             	mov    %eax,(%esp)
     a8e:	e8 5f fc ff ff       	call   6f2 <peek>
     a93:	85 c0                	test   %eax,%eax
     a95:	75 0c                	jne    aa3 <parseblock+0x30>
    panic("parseblock");
     a97:	c7 04 24 3a 16 00 00 	movl   $0x163a,(%esp)
     a9e:	e8 29 f9 ff ff       	call   3cc <panic>
  gettoken(ps, es, 0, 0);
     aa3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     aaa:	00 
     aab:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     ab2:	00 
     ab3:	8b 45 0c             	mov    0xc(%ebp),%eax
     ab6:	89 44 24 04          	mov    %eax,0x4(%esp)
     aba:	8b 45 08             	mov    0x8(%ebp),%eax
     abd:	89 04 24             	mov    %eax,(%esp)
     ac0:	e8 e2 fa ff ff       	call   5a7 <gettoken>
  cmd = parseline(ps, es);
     ac5:	8b 45 0c             	mov    0xc(%ebp),%eax
     ac8:	89 44 24 04          	mov    %eax,0x4(%esp)
     acc:	8b 45 08             	mov    0x8(%ebp),%eax
     acf:	89 04 24             	mov    %eax,(%esp)
     ad2:	e8 1c fd ff ff       	call   7f3 <parseline>
     ad7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!peek(ps, es, ")"))
     ada:	c7 44 24 08 45 16 00 	movl   $0x1645,0x8(%esp)
     ae1:	00 
     ae2:	8b 45 0c             	mov    0xc(%ebp),%eax
     ae5:	89 44 24 04          	mov    %eax,0x4(%esp)
     ae9:	8b 45 08             	mov    0x8(%ebp),%eax
     aec:	89 04 24             	mov    %eax,(%esp)
     aef:	e8 fe fb ff ff       	call   6f2 <peek>
     af4:	85 c0                	test   %eax,%eax
     af6:	75 0c                	jne    b04 <parseblock+0x91>
    panic("syntax - missing )");
     af8:	c7 04 24 47 16 00 00 	movl   $0x1647,(%esp)
     aff:	e8 c8 f8 ff ff       	call   3cc <panic>
  gettoken(ps, es, 0, 0);
     b04:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     b0b:	00 
     b0c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     b13:	00 
     b14:	8b 45 0c             	mov    0xc(%ebp),%eax
     b17:	89 44 24 04          	mov    %eax,0x4(%esp)
     b1b:	8b 45 08             	mov    0x8(%ebp),%eax
     b1e:	89 04 24             	mov    %eax,(%esp)
     b21:	e8 81 fa ff ff       	call   5a7 <gettoken>
  cmd = parseredirs(cmd, ps, es);
     b26:	8b 45 0c             	mov    0xc(%ebp),%eax
     b29:	89 44 24 08          	mov    %eax,0x8(%esp)
     b2d:	8b 45 08             	mov    0x8(%ebp),%eax
     b30:	89 44 24 04          	mov    %eax,0x4(%esp)
     b34:	8b 45 f4             	mov    -0xc(%ebp),%eax
     b37:	89 04 24             	mov    %eax,(%esp)
     b3a:	e8 0c fe ff ff       	call   94b <parseredirs>
     b3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  return cmd;
     b42:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     b45:	c9                   	leave  
     b46:	c3                   	ret    

00000b47 <parseexec>:

struct cmd*
parseexec(char **ps, char *es)
{
     b47:	55                   	push   %ebp
     b48:	89 e5                	mov    %esp,%ebp
     b4a:	83 ec 38             	sub    $0x38,%esp
  char *q, *eq;
  int tok, argc;
  struct execcmd *cmd;
  struct cmd *ret;
  
  if(peek(ps, es, "("))
     b4d:	c7 44 24 08 38 16 00 	movl   $0x1638,0x8(%esp)
     b54:	00 
     b55:	8b 45 0c             	mov    0xc(%ebp),%eax
     b58:	89 44 24 04          	mov    %eax,0x4(%esp)
     b5c:	8b 45 08             	mov    0x8(%ebp),%eax
     b5f:	89 04 24             	mov    %eax,(%esp)
     b62:	e8 8b fb ff ff       	call   6f2 <peek>
     b67:	85 c0                	test   %eax,%eax
     b69:	74 17                	je     b82 <parseexec+0x3b>
    return parseblock(ps, es);
     b6b:	8b 45 0c             	mov    0xc(%ebp),%eax
     b6e:	89 44 24 04          	mov    %eax,0x4(%esp)
     b72:	8b 45 08             	mov    0x8(%ebp),%eax
     b75:	89 04 24             	mov    %eax,(%esp)
     b78:	e8 f6 fe ff ff       	call   a73 <parseblock>
     b7d:	e9 09 01 00 00       	jmp    c8b <parseexec+0x144>

  ret = execcmd();
     b82:	e8 90 f8 ff ff       	call   417 <execcmd>
     b87:	89 45 f0             	mov    %eax,-0x10(%ebp)
  cmd = (struct execcmd*)ret;
     b8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
     b8d:	89 45 ec             	mov    %eax,-0x14(%ebp)

  argc = 0;
     b90:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  ret = parseredirs(ret, ps, es);
     b97:	8b 45 0c             	mov    0xc(%ebp),%eax
     b9a:	89 44 24 08          	mov    %eax,0x8(%esp)
     b9e:	8b 45 08             	mov    0x8(%ebp),%eax
     ba1:	89 44 24 04          	mov    %eax,0x4(%esp)
     ba5:	8b 45 f0             	mov    -0x10(%ebp),%eax
     ba8:	89 04 24             	mov    %eax,(%esp)
     bab:	e8 9b fd ff ff       	call   94b <parseredirs>
     bb0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(!peek(ps, es, "|)&;")){
     bb3:	e9 8f 00 00 00       	jmp    c47 <parseexec+0x100>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
     bb8:	8d 45 e0             	lea    -0x20(%ebp),%eax
     bbb:	89 44 24 0c          	mov    %eax,0xc(%esp)
     bbf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
     bc2:	89 44 24 08          	mov    %eax,0x8(%esp)
     bc6:	8b 45 0c             	mov    0xc(%ebp),%eax
     bc9:	89 44 24 04          	mov    %eax,0x4(%esp)
     bcd:	8b 45 08             	mov    0x8(%ebp),%eax
     bd0:	89 04 24             	mov    %eax,(%esp)
     bd3:	e8 cf f9 ff ff       	call   5a7 <gettoken>
     bd8:	89 45 e8             	mov    %eax,-0x18(%ebp)
     bdb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     bdf:	75 05                	jne    be6 <parseexec+0x9f>
      break;
     be1:	e9 83 00 00 00       	jmp    c69 <parseexec+0x122>
    if(tok != 'a')
     be6:	83 7d e8 61          	cmpl   $0x61,-0x18(%ebp)
     bea:	74 0c                	je     bf8 <parseexec+0xb1>
      panic("syntax");
     bec:	c7 04 24 0b 16 00 00 	movl   $0x160b,(%esp)
     bf3:	e8 d4 f7 ff ff       	call   3cc <panic>
    cmd->argv[argc] = q;
     bf8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
     bfb:	8b 45 ec             	mov    -0x14(%ebp),%eax
     bfe:	8b 55 f4             	mov    -0xc(%ebp),%edx
     c01:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
    cmd->eargv[argc] = eq;
     c05:	8b 55 e0             	mov    -0x20(%ebp),%edx
     c08:	8b 45 ec             	mov    -0x14(%ebp),%eax
     c0b:	8b 4d f4             	mov    -0xc(%ebp),%ecx
     c0e:	83 c1 08             	add    $0x8,%ecx
     c11:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    argc++;
     c15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(argc >= MAXARGS)
     c19:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
     c1d:	7e 0c                	jle    c2b <parseexec+0xe4>
      panic("too many args");
     c1f:	c7 04 24 5a 16 00 00 	movl   $0x165a,(%esp)
     c26:	e8 a1 f7 ff ff       	call   3cc <panic>
    ret = parseredirs(ret, ps, es);
     c2b:	8b 45 0c             	mov    0xc(%ebp),%eax
     c2e:	89 44 24 08          	mov    %eax,0x8(%esp)
     c32:	8b 45 08             	mov    0x8(%ebp),%eax
     c35:	89 44 24 04          	mov    %eax,0x4(%esp)
     c39:	8b 45 f0             	mov    -0x10(%ebp),%eax
     c3c:	89 04 24             	mov    %eax,(%esp)
     c3f:	e8 07 fd ff ff       	call   94b <parseredirs>
     c44:	89 45 f0             	mov    %eax,-0x10(%ebp)
  ret = execcmd();
  cmd = (struct execcmd*)ret;

  argc = 0;
  ret = parseredirs(ret, ps, es);
  while(!peek(ps, es, "|)&;")){
     c47:	c7 44 24 08 68 16 00 	movl   $0x1668,0x8(%esp)
     c4e:	00 
     c4f:	8b 45 0c             	mov    0xc(%ebp),%eax
     c52:	89 44 24 04          	mov    %eax,0x4(%esp)
     c56:	8b 45 08             	mov    0x8(%ebp),%eax
     c59:	89 04 24             	mov    %eax,(%esp)
     c5c:	e8 91 fa ff ff       	call   6f2 <peek>
     c61:	85 c0                	test   %eax,%eax
     c63:	0f 84 4f ff ff ff    	je     bb8 <parseexec+0x71>
    argc++;
    if(argc >= MAXARGS)
      panic("too many args");
    ret = parseredirs(ret, ps, es);
  }
  cmd->argv[argc] = 0;
     c69:	8b 45 ec             	mov    -0x14(%ebp),%eax
     c6c:	8b 55 f4             	mov    -0xc(%ebp),%edx
     c6f:	c7 44 90 04 00 00 00 	movl   $0x0,0x4(%eax,%edx,4)
     c76:	00 
  cmd->eargv[argc] = 0;
     c77:	8b 45 ec             	mov    -0x14(%ebp),%eax
     c7a:	8b 55 f4             	mov    -0xc(%ebp),%edx
     c7d:	83 c2 08             	add    $0x8,%edx
     c80:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
     c87:	00 
  return ret;
     c88:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
     c8b:	c9                   	leave  
     c8c:	c3                   	ret    

00000c8d <nulterminate>:

// NUL-terminate all the counted strings.
struct cmd*
nulterminate(struct cmd *cmd)
{
     c8d:	55                   	push   %ebp
     c8e:	89 e5                	mov    %esp,%ebp
     c90:	83 ec 38             	sub    $0x38,%esp
  struct execcmd *ecmd;
  struct listcmd *lcmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if(cmd == 0)
     c93:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
     c97:	75 0a                	jne    ca3 <nulterminate+0x16>
    return 0;
     c99:	b8 00 00 00 00       	mov    $0x0,%eax
     c9e:	e9 c9 00 00 00       	jmp    d6c <nulterminate+0xdf>
  
  switch(cmd->type){
     ca3:	8b 45 08             	mov    0x8(%ebp),%eax
     ca6:	8b 00                	mov    (%eax),%eax
     ca8:	83 f8 05             	cmp    $0x5,%eax
     cab:	0f 87 b8 00 00 00    	ja     d69 <nulterminate+0xdc>
     cb1:	8b 04 85 70 16 00 00 	mov    0x1670(,%eax,4),%eax
     cb8:	ff e0                	jmp    *%eax
  case EXEC:
    ecmd = (struct execcmd*)cmd;
     cba:	8b 45 08             	mov    0x8(%ebp),%eax
     cbd:	89 45 f0             	mov    %eax,-0x10(%ebp)
    for(i=0; ecmd->argv[i]; i++)
     cc0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     cc7:	eb 14                	jmp    cdd <nulterminate+0x50>
      *ecmd->eargv[i] = 0;
     cc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
     ccc:	8b 55 f4             	mov    -0xc(%ebp),%edx
     ccf:	83 c2 08             	add    $0x8,%edx
     cd2:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
     cd6:	c6 00 00             	movb   $0x0,(%eax)
    return 0;
  
  switch(cmd->type){
  case EXEC:
    ecmd = (struct execcmd*)cmd;
    for(i=0; ecmd->argv[i]; i++)
     cd9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     cdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
     ce0:	8b 55 f4             	mov    -0xc(%ebp),%edx
     ce3:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
     ce7:	85 c0                	test   %eax,%eax
     ce9:	75 de                	jne    cc9 <nulterminate+0x3c>
      *ecmd->eargv[i] = 0;
    break;
     ceb:	eb 7c                	jmp    d69 <nulterminate+0xdc>

  case REDIR:
    rcmd = (struct redircmd*)cmd;
     ced:	8b 45 08             	mov    0x8(%ebp),%eax
     cf0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    nulterminate(rcmd->cmd);
     cf3:	8b 45 ec             	mov    -0x14(%ebp),%eax
     cf6:	8b 40 04             	mov    0x4(%eax),%eax
     cf9:	89 04 24             	mov    %eax,(%esp)
     cfc:	e8 8c ff ff ff       	call   c8d <nulterminate>
    *rcmd->efile = 0;
     d01:	8b 45 ec             	mov    -0x14(%ebp),%eax
     d04:	8b 40 0c             	mov    0xc(%eax),%eax
     d07:	c6 00 00             	movb   $0x0,(%eax)
    break;
     d0a:	eb 5d                	jmp    d69 <nulterminate+0xdc>

  case PIPE:
    pcmd = (struct pipecmd*)cmd;
     d0c:	8b 45 08             	mov    0x8(%ebp),%eax
     d0f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    nulterminate(pcmd->left);
     d12:	8b 45 e8             	mov    -0x18(%ebp),%eax
     d15:	8b 40 04             	mov    0x4(%eax),%eax
     d18:	89 04 24             	mov    %eax,(%esp)
     d1b:	e8 6d ff ff ff       	call   c8d <nulterminate>
    nulterminate(pcmd->right);
     d20:	8b 45 e8             	mov    -0x18(%ebp),%eax
     d23:	8b 40 08             	mov    0x8(%eax),%eax
     d26:	89 04 24             	mov    %eax,(%esp)
     d29:	e8 5f ff ff ff       	call   c8d <nulterminate>
    break;
     d2e:	eb 39                	jmp    d69 <nulterminate+0xdc>
    
  case LIST:
    lcmd = (struct listcmd*)cmd;
     d30:	8b 45 08             	mov    0x8(%ebp),%eax
     d33:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    nulterminate(lcmd->left);
     d36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     d39:	8b 40 04             	mov    0x4(%eax),%eax
     d3c:	89 04 24             	mov    %eax,(%esp)
     d3f:	e8 49 ff ff ff       	call   c8d <nulterminate>
    nulterminate(lcmd->right);
     d44:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     d47:	8b 40 08             	mov    0x8(%eax),%eax
     d4a:	89 04 24             	mov    %eax,(%esp)
     d4d:	e8 3b ff ff ff       	call   c8d <nulterminate>
    break;
     d52:	eb 15                	jmp    d69 <nulterminate+0xdc>

  case BACK:
    bcmd = (struct backcmd*)cmd;
     d54:	8b 45 08             	mov    0x8(%ebp),%eax
     d57:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nulterminate(bcmd->cmd);
     d5a:	8b 45 e0             	mov    -0x20(%ebp),%eax
     d5d:	8b 40 04             	mov    0x4(%eax),%eax
     d60:	89 04 24             	mov    %eax,(%esp)
     d63:	e8 25 ff ff ff       	call   c8d <nulterminate>
    break;
     d68:	90                   	nop
  }
  return cmd;
     d69:	8b 45 08             	mov    0x8(%ebp),%eax
}
     d6c:	c9                   	leave  
     d6d:	c3                   	ret    

00000d6e <display_history>:

void display_history(void) {
     d6e:	55                   	push   %ebp
     d6f:	89 e5                	mov    %esp,%ebp
     d71:	83 ec 28             	sub    $0x28,%esp
 static char buff[100];
 int index = 0;
     d74:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

 while(history(buff, index++) == 0)
     d7b:	eb 23                	jmp    da0 <display_history+0x32>
   printf(1,"%d: %s \n", index, buff);
     d7d:	c7 44 24 0c 00 1c 00 	movl   $0x1c00,0xc(%esp)
     d84:	00 
     d85:	8b 45 f4             	mov    -0xc(%ebp),%eax
     d88:	89 44 24 08          	mov    %eax,0x8(%esp)
     d8c:	c7 44 24 04 88 16 00 	movl   $0x1688,0x4(%esp)
     d93:	00 
     d94:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     d9b:	e8 1f 04 00 00       	call   11bf <printf>

void display_history(void) {
 static char buff[100];
 int index = 0;

 while(history(buff, index++) == 0)
     da0:	8b 45 f4             	mov    -0xc(%ebp),%eax
     da3:	8d 50 01             	lea    0x1(%eax),%edx
     da6:	89 55 f4             	mov    %edx,-0xc(%ebp)
     da9:	89 44 24 04          	mov    %eax,0x4(%esp)
     dad:	c7 04 24 00 1c 00 00 	movl   $0x1c00,(%esp)
     db4:	e8 0e 03 00 00       	call   10c7 <history>
     db9:	85 c0                	test   %eax,%eax
     dbb:	74 c0                	je     d7d <display_history+0xf>
   printf(1,"%d: %s \n", index, buff);

}
     dbd:	c9                   	leave  
     dbe:	c3                   	ret    

00000dbf <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
     dbf:	55                   	push   %ebp
     dc0:	89 e5                	mov    %esp,%ebp
     dc2:	57                   	push   %edi
     dc3:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
     dc4:	8b 4d 08             	mov    0x8(%ebp),%ecx
     dc7:	8b 55 10             	mov    0x10(%ebp),%edx
     dca:	8b 45 0c             	mov    0xc(%ebp),%eax
     dcd:	89 cb                	mov    %ecx,%ebx
     dcf:	89 df                	mov    %ebx,%edi
     dd1:	89 d1                	mov    %edx,%ecx
     dd3:	fc                   	cld    
     dd4:	f3 aa                	rep stos %al,%es:(%edi)
     dd6:	89 ca                	mov    %ecx,%edx
     dd8:	89 fb                	mov    %edi,%ebx
     dda:	89 5d 08             	mov    %ebx,0x8(%ebp)
     ddd:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
     de0:	5b                   	pop    %ebx
     de1:	5f                   	pop    %edi
     de2:	5d                   	pop    %ebp
     de3:	c3                   	ret    

00000de4 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
     de4:	55                   	push   %ebp
     de5:	89 e5                	mov    %esp,%ebp
     de7:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
     dea:	8b 45 08             	mov    0x8(%ebp),%eax
     ded:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
     df0:	90                   	nop
     df1:	8b 45 08             	mov    0x8(%ebp),%eax
     df4:	8d 50 01             	lea    0x1(%eax),%edx
     df7:	89 55 08             	mov    %edx,0x8(%ebp)
     dfa:	8b 55 0c             	mov    0xc(%ebp),%edx
     dfd:	8d 4a 01             	lea    0x1(%edx),%ecx
     e00:	89 4d 0c             	mov    %ecx,0xc(%ebp)
     e03:	0f b6 12             	movzbl (%edx),%edx
     e06:	88 10                	mov    %dl,(%eax)
     e08:	0f b6 00             	movzbl (%eax),%eax
     e0b:	84 c0                	test   %al,%al
     e0d:	75 e2                	jne    df1 <strcpy+0xd>
    ;
  return os;
     e0f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
     e12:	c9                   	leave  
     e13:	c3                   	ret    

00000e14 <strcmp>:

int
strcmp(const char *p, const char *q)
{
     e14:	55                   	push   %ebp
     e15:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
     e17:	eb 08                	jmp    e21 <strcmp+0xd>
    p++, q++;
     e19:	83 45 08 01          	addl   $0x1,0x8(%ebp)
     e1d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
     e21:	8b 45 08             	mov    0x8(%ebp),%eax
     e24:	0f b6 00             	movzbl (%eax),%eax
     e27:	84 c0                	test   %al,%al
     e29:	74 10                	je     e3b <strcmp+0x27>
     e2b:	8b 45 08             	mov    0x8(%ebp),%eax
     e2e:	0f b6 10             	movzbl (%eax),%edx
     e31:	8b 45 0c             	mov    0xc(%ebp),%eax
     e34:	0f b6 00             	movzbl (%eax),%eax
     e37:	38 c2                	cmp    %al,%dl
     e39:	74 de                	je     e19 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
     e3b:	8b 45 08             	mov    0x8(%ebp),%eax
     e3e:	0f b6 00             	movzbl (%eax),%eax
     e41:	0f b6 d0             	movzbl %al,%edx
     e44:	8b 45 0c             	mov    0xc(%ebp),%eax
     e47:	0f b6 00             	movzbl (%eax),%eax
     e4a:	0f b6 c0             	movzbl %al,%eax
     e4d:	29 c2                	sub    %eax,%edx
     e4f:	89 d0                	mov    %edx,%eax
}
     e51:	5d                   	pop    %ebp
     e52:	c3                   	ret    

00000e53 <strlen>:

uint
strlen(char *s)
{
     e53:	55                   	push   %ebp
     e54:	89 e5                	mov    %esp,%ebp
     e56:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
     e59:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
     e60:	eb 04                	jmp    e66 <strlen+0x13>
     e62:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
     e66:	8b 55 fc             	mov    -0x4(%ebp),%edx
     e69:	8b 45 08             	mov    0x8(%ebp),%eax
     e6c:	01 d0                	add    %edx,%eax
     e6e:	0f b6 00             	movzbl (%eax),%eax
     e71:	84 c0                	test   %al,%al
     e73:	75 ed                	jne    e62 <strlen+0xf>
    ;
  return n;
     e75:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
     e78:	c9                   	leave  
     e79:	c3                   	ret    

00000e7a <memset>:

void*
memset(void *dst, int c, uint n)
{
     e7a:	55                   	push   %ebp
     e7b:	89 e5                	mov    %esp,%ebp
     e7d:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
     e80:	8b 45 10             	mov    0x10(%ebp),%eax
     e83:	89 44 24 08          	mov    %eax,0x8(%esp)
     e87:	8b 45 0c             	mov    0xc(%ebp),%eax
     e8a:	89 44 24 04          	mov    %eax,0x4(%esp)
     e8e:	8b 45 08             	mov    0x8(%ebp),%eax
     e91:	89 04 24             	mov    %eax,(%esp)
     e94:	e8 26 ff ff ff       	call   dbf <stosb>
  return dst;
     e99:	8b 45 08             	mov    0x8(%ebp),%eax
}
     e9c:	c9                   	leave  
     e9d:	c3                   	ret    

00000e9e <strchr>:

char*
strchr(const char *s, char c)
{
     e9e:	55                   	push   %ebp
     e9f:	89 e5                	mov    %esp,%ebp
     ea1:	83 ec 04             	sub    $0x4,%esp
     ea4:	8b 45 0c             	mov    0xc(%ebp),%eax
     ea7:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
     eaa:	eb 14                	jmp    ec0 <strchr+0x22>
    if(*s == c)
     eac:	8b 45 08             	mov    0x8(%ebp),%eax
     eaf:	0f b6 00             	movzbl (%eax),%eax
     eb2:	3a 45 fc             	cmp    -0x4(%ebp),%al
     eb5:	75 05                	jne    ebc <strchr+0x1e>
      return (char*)s;
     eb7:	8b 45 08             	mov    0x8(%ebp),%eax
     eba:	eb 13                	jmp    ecf <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
     ebc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
     ec0:	8b 45 08             	mov    0x8(%ebp),%eax
     ec3:	0f b6 00             	movzbl (%eax),%eax
     ec6:	84 c0                	test   %al,%al
     ec8:	75 e2                	jne    eac <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
     eca:	b8 00 00 00 00       	mov    $0x0,%eax
}
     ecf:	c9                   	leave  
     ed0:	c3                   	ret    

00000ed1 <gets>:

char*
gets(char *buf, int max)
{
     ed1:	55                   	push   %ebp
     ed2:	89 e5                	mov    %esp,%ebp
     ed4:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     ed7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     ede:	eb 4c                	jmp    f2c <gets+0x5b>
    cc = read(0, &c, 1);
     ee0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
     ee7:	00 
     ee8:	8d 45 ef             	lea    -0x11(%ebp),%eax
     eeb:	89 44 24 04          	mov    %eax,0x4(%esp)
     eef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
     ef6:	e8 44 01 00 00       	call   103f <read>
     efb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
     efe:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
     f02:	7f 02                	jg     f06 <gets+0x35>
      break;
     f04:	eb 31                	jmp    f37 <gets+0x66>
    buf[i++] = c;
     f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
     f09:	8d 50 01             	lea    0x1(%eax),%edx
     f0c:	89 55 f4             	mov    %edx,-0xc(%ebp)
     f0f:	89 c2                	mov    %eax,%edx
     f11:	8b 45 08             	mov    0x8(%ebp),%eax
     f14:	01 c2                	add    %eax,%edx
     f16:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
     f1a:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
     f1c:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
     f20:	3c 0a                	cmp    $0xa,%al
     f22:	74 13                	je     f37 <gets+0x66>
     f24:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
     f28:	3c 0d                	cmp    $0xd,%al
     f2a:	74 0b                	je     f37 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     f2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
     f2f:	83 c0 01             	add    $0x1,%eax
     f32:	3b 45 0c             	cmp    0xc(%ebp),%eax
     f35:	7c a9                	jl     ee0 <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
     f37:	8b 55 f4             	mov    -0xc(%ebp),%edx
     f3a:	8b 45 08             	mov    0x8(%ebp),%eax
     f3d:	01 d0                	add    %edx,%eax
     f3f:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
     f42:	8b 45 08             	mov    0x8(%ebp),%eax
}
     f45:	c9                   	leave  
     f46:	c3                   	ret    

00000f47 <stat>:

int
stat(char *n, struct stat *st)
{
     f47:	55                   	push   %ebp
     f48:	89 e5                	mov    %esp,%ebp
     f4a:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     f4d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     f54:	00 
     f55:	8b 45 08             	mov    0x8(%ebp),%eax
     f58:	89 04 24             	mov    %eax,(%esp)
     f5b:	e8 07 01 00 00       	call   1067 <open>
     f60:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
     f63:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
     f67:	79 07                	jns    f70 <stat+0x29>
    return -1;
     f69:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
     f6e:	eb 23                	jmp    f93 <stat+0x4c>
  r = fstat(fd, st);
     f70:	8b 45 0c             	mov    0xc(%ebp),%eax
     f73:	89 44 24 04          	mov    %eax,0x4(%esp)
     f77:	8b 45 f4             	mov    -0xc(%ebp),%eax
     f7a:	89 04 24             	mov    %eax,(%esp)
     f7d:	e8 fd 00 00 00       	call   107f <fstat>
     f82:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
     f85:	8b 45 f4             	mov    -0xc(%ebp),%eax
     f88:	89 04 24             	mov    %eax,(%esp)
     f8b:	e8 bf 00 00 00       	call   104f <close>
  return r;
     f90:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
     f93:	c9                   	leave  
     f94:	c3                   	ret    

00000f95 <atoi>:

int
atoi(const char *s)
{
     f95:	55                   	push   %ebp
     f96:	89 e5                	mov    %esp,%ebp
     f98:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
     f9b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
     fa2:	eb 25                	jmp    fc9 <atoi+0x34>
    n = n*10 + *s++ - '0';
     fa4:	8b 55 fc             	mov    -0x4(%ebp),%edx
     fa7:	89 d0                	mov    %edx,%eax
     fa9:	c1 e0 02             	shl    $0x2,%eax
     fac:	01 d0                	add    %edx,%eax
     fae:	01 c0                	add    %eax,%eax
     fb0:	89 c1                	mov    %eax,%ecx
     fb2:	8b 45 08             	mov    0x8(%ebp),%eax
     fb5:	8d 50 01             	lea    0x1(%eax),%edx
     fb8:	89 55 08             	mov    %edx,0x8(%ebp)
     fbb:	0f b6 00             	movzbl (%eax),%eax
     fbe:	0f be c0             	movsbl %al,%eax
     fc1:	01 c8                	add    %ecx,%eax
     fc3:	83 e8 30             	sub    $0x30,%eax
     fc6:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     fc9:	8b 45 08             	mov    0x8(%ebp),%eax
     fcc:	0f b6 00             	movzbl (%eax),%eax
     fcf:	3c 2f                	cmp    $0x2f,%al
     fd1:	7e 0a                	jle    fdd <atoi+0x48>
     fd3:	8b 45 08             	mov    0x8(%ebp),%eax
     fd6:	0f b6 00             	movzbl (%eax),%eax
     fd9:	3c 39                	cmp    $0x39,%al
     fdb:	7e c7                	jle    fa4 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
     fdd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
     fe0:	c9                   	leave  
     fe1:	c3                   	ret    

00000fe2 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
     fe2:	55                   	push   %ebp
     fe3:	89 e5                	mov    %esp,%ebp
     fe5:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
     fe8:	8b 45 08             	mov    0x8(%ebp),%eax
     feb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
     fee:	8b 45 0c             	mov    0xc(%ebp),%eax
     ff1:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
     ff4:	eb 17                	jmp    100d <memmove+0x2b>
    *dst++ = *src++;
     ff6:	8b 45 fc             	mov    -0x4(%ebp),%eax
     ff9:	8d 50 01             	lea    0x1(%eax),%edx
     ffc:	89 55 fc             	mov    %edx,-0x4(%ebp)
     fff:	8b 55 f8             	mov    -0x8(%ebp),%edx
    1002:	8d 4a 01             	lea    0x1(%edx),%ecx
    1005:	89 4d f8             	mov    %ecx,-0x8(%ebp)
    1008:	0f b6 12             	movzbl (%edx),%edx
    100b:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
    100d:	8b 45 10             	mov    0x10(%ebp),%eax
    1010:	8d 50 ff             	lea    -0x1(%eax),%edx
    1013:	89 55 10             	mov    %edx,0x10(%ebp)
    1016:	85 c0                	test   %eax,%eax
    1018:	7f dc                	jg     ff6 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
    101a:	8b 45 08             	mov    0x8(%ebp),%eax
}
    101d:	c9                   	leave  
    101e:	c3                   	ret    

0000101f <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
    101f:	b8 01 00 00 00       	mov    $0x1,%eax
    1024:	cd 40                	int    $0x40
    1026:	c3                   	ret    

00001027 <exit>:
SYSCALL(exit)
    1027:	b8 02 00 00 00       	mov    $0x2,%eax
    102c:	cd 40                	int    $0x40
    102e:	c3                   	ret    

0000102f <wait>:
SYSCALL(wait)
    102f:	b8 03 00 00 00       	mov    $0x3,%eax
    1034:	cd 40                	int    $0x40
    1036:	c3                   	ret    

00001037 <pipe>:
SYSCALL(pipe)
    1037:	b8 04 00 00 00       	mov    $0x4,%eax
    103c:	cd 40                	int    $0x40
    103e:	c3                   	ret    

0000103f <read>:
SYSCALL(read)
    103f:	b8 05 00 00 00       	mov    $0x5,%eax
    1044:	cd 40                	int    $0x40
    1046:	c3                   	ret    

00001047 <write>:
SYSCALL(write)
    1047:	b8 10 00 00 00       	mov    $0x10,%eax
    104c:	cd 40                	int    $0x40
    104e:	c3                   	ret    

0000104f <close>:
SYSCALL(close)
    104f:	b8 15 00 00 00       	mov    $0x15,%eax
    1054:	cd 40                	int    $0x40
    1056:	c3                   	ret    

00001057 <kill>:
SYSCALL(kill)
    1057:	b8 06 00 00 00       	mov    $0x6,%eax
    105c:	cd 40                	int    $0x40
    105e:	c3                   	ret    

0000105f <exec>:
SYSCALL(exec)
    105f:	b8 07 00 00 00       	mov    $0x7,%eax
    1064:	cd 40                	int    $0x40
    1066:	c3                   	ret    

00001067 <open>:
SYSCALL(open)
    1067:	b8 0f 00 00 00       	mov    $0xf,%eax
    106c:	cd 40                	int    $0x40
    106e:	c3                   	ret    

0000106f <mknod>:
SYSCALL(mknod)
    106f:	b8 11 00 00 00       	mov    $0x11,%eax
    1074:	cd 40                	int    $0x40
    1076:	c3                   	ret    

00001077 <unlink>:
SYSCALL(unlink)
    1077:	b8 12 00 00 00       	mov    $0x12,%eax
    107c:	cd 40                	int    $0x40
    107e:	c3                   	ret    

0000107f <fstat>:
SYSCALL(fstat)
    107f:	b8 08 00 00 00       	mov    $0x8,%eax
    1084:	cd 40                	int    $0x40
    1086:	c3                   	ret    

00001087 <link>:
SYSCALL(link)
    1087:	b8 13 00 00 00       	mov    $0x13,%eax
    108c:	cd 40                	int    $0x40
    108e:	c3                   	ret    

0000108f <mkdir>:
SYSCALL(mkdir)
    108f:	b8 14 00 00 00       	mov    $0x14,%eax
    1094:	cd 40                	int    $0x40
    1096:	c3                   	ret    

00001097 <chdir>:
SYSCALL(chdir)
    1097:	b8 09 00 00 00       	mov    $0x9,%eax
    109c:	cd 40                	int    $0x40
    109e:	c3                   	ret    

0000109f <dup>:
SYSCALL(dup)
    109f:	b8 0a 00 00 00       	mov    $0xa,%eax
    10a4:	cd 40                	int    $0x40
    10a6:	c3                   	ret    

000010a7 <getpid>:
SYSCALL(getpid)
    10a7:	b8 0b 00 00 00       	mov    $0xb,%eax
    10ac:	cd 40                	int    $0x40
    10ae:	c3                   	ret    

000010af <sbrk>:
SYSCALL(sbrk)
    10af:	b8 0c 00 00 00       	mov    $0xc,%eax
    10b4:	cd 40                	int    $0x40
    10b6:	c3                   	ret    

000010b7 <sleep>:
SYSCALL(sleep)
    10b7:	b8 0d 00 00 00       	mov    $0xd,%eax
    10bc:	cd 40                	int    $0x40
    10be:	c3                   	ret    

000010bf <uptime>:
SYSCALL(uptime)
    10bf:	b8 0e 00 00 00       	mov    $0xe,%eax
    10c4:	cd 40                	int    $0x40
    10c6:	c3                   	ret    

000010c7 <history>:
SYSCALL(history)
    10c7:	b8 16 00 00 00       	mov    $0x16,%eax
    10cc:	cd 40                	int    $0x40
    10ce:	c3                   	ret    

000010cf <wait2>:
SYSCALL(wait2)
    10cf:	b8 17 00 00 00       	mov    $0x17,%eax
    10d4:	cd 40                	int    $0x40
    10d6:	c3                   	ret    

000010d7 <set_prio>:
SYSCALL(set_prio)
    10d7:	b8 18 00 00 00       	mov    $0x18,%eax
    10dc:	cd 40                	int    $0x40
    10de:	c3                   	ret    

000010df <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
    10df:	55                   	push   %ebp
    10e0:	89 e5                	mov    %esp,%ebp
    10e2:	83 ec 18             	sub    $0x18,%esp
    10e5:	8b 45 0c             	mov    0xc(%ebp),%eax
    10e8:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
    10eb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
    10f2:	00 
    10f3:	8d 45 f4             	lea    -0xc(%ebp),%eax
    10f6:	89 44 24 04          	mov    %eax,0x4(%esp)
    10fa:	8b 45 08             	mov    0x8(%ebp),%eax
    10fd:	89 04 24             	mov    %eax,(%esp)
    1100:	e8 42 ff ff ff       	call   1047 <write>
}
    1105:	c9                   	leave  
    1106:	c3                   	ret    

00001107 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
    1107:	55                   	push   %ebp
    1108:	89 e5                	mov    %esp,%ebp
    110a:	56                   	push   %esi
    110b:	53                   	push   %ebx
    110c:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
    110f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
    1116:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
    111a:	74 17                	je     1133 <printint+0x2c>
    111c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
    1120:	79 11                	jns    1133 <printint+0x2c>
    neg = 1;
    1122:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
    1129:	8b 45 0c             	mov    0xc(%ebp),%eax
    112c:	f7 d8                	neg    %eax
    112e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    1131:	eb 06                	jmp    1139 <printint+0x32>
  } else {
    x = xx;
    1133:	8b 45 0c             	mov    0xc(%ebp),%eax
    1136:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
    1139:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
    1140:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    1143:	8d 41 01             	lea    0x1(%ecx),%eax
    1146:	89 45 f4             	mov    %eax,-0xc(%ebp)
    1149:	8b 5d 10             	mov    0x10(%ebp),%ebx
    114c:	8b 45 ec             	mov    -0x14(%ebp),%eax
    114f:	ba 00 00 00 00       	mov    $0x0,%edx
    1154:	f7 f3                	div    %ebx
    1156:	89 d0                	mov    %edx,%eax
    1158:	0f b6 80 66 1b 00 00 	movzbl 0x1b66(%eax),%eax
    115f:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
    1163:	8b 75 10             	mov    0x10(%ebp),%esi
    1166:	8b 45 ec             	mov    -0x14(%ebp),%eax
    1169:	ba 00 00 00 00       	mov    $0x0,%edx
    116e:	f7 f6                	div    %esi
    1170:	89 45 ec             	mov    %eax,-0x14(%ebp)
    1173:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    1177:	75 c7                	jne    1140 <printint+0x39>
  if(neg)
    1179:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    117d:	74 10                	je     118f <printint+0x88>
    buf[i++] = '-';
    117f:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1182:	8d 50 01             	lea    0x1(%eax),%edx
    1185:	89 55 f4             	mov    %edx,-0xc(%ebp)
    1188:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
    118d:	eb 1f                	jmp    11ae <printint+0xa7>
    118f:	eb 1d                	jmp    11ae <printint+0xa7>
    putc(fd, buf[i]);
    1191:	8d 55 dc             	lea    -0x24(%ebp),%edx
    1194:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1197:	01 d0                	add    %edx,%eax
    1199:	0f b6 00             	movzbl (%eax),%eax
    119c:	0f be c0             	movsbl %al,%eax
    119f:	89 44 24 04          	mov    %eax,0x4(%esp)
    11a3:	8b 45 08             	mov    0x8(%ebp),%eax
    11a6:	89 04 24             	mov    %eax,(%esp)
    11a9:	e8 31 ff ff ff       	call   10df <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
    11ae:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
    11b2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    11b6:	79 d9                	jns    1191 <printint+0x8a>
    putc(fd, buf[i]);
}
    11b8:	83 c4 30             	add    $0x30,%esp
    11bb:	5b                   	pop    %ebx
    11bc:	5e                   	pop    %esi
    11bd:	5d                   	pop    %ebp
    11be:	c3                   	ret    

000011bf <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
    11bf:	55                   	push   %ebp
    11c0:	89 e5                	mov    %esp,%ebp
    11c2:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
    11c5:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
    11cc:	8d 45 0c             	lea    0xc(%ebp),%eax
    11cf:	83 c0 04             	add    $0x4,%eax
    11d2:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
    11d5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    11dc:	e9 7c 01 00 00       	jmp    135d <printf+0x19e>
    c = fmt[i] & 0xff;
    11e1:	8b 55 0c             	mov    0xc(%ebp),%edx
    11e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
    11e7:	01 d0                	add    %edx,%eax
    11e9:	0f b6 00             	movzbl (%eax),%eax
    11ec:	0f be c0             	movsbl %al,%eax
    11ef:	25 ff 00 00 00       	and    $0xff,%eax
    11f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
    11f7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    11fb:	75 2c                	jne    1229 <printf+0x6a>
      if(c == '%'){
    11fd:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
    1201:	75 0c                	jne    120f <printf+0x50>
        state = '%';
    1203:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
    120a:	e9 4a 01 00 00       	jmp    1359 <printf+0x19a>
      } else {
        putc(fd, c);
    120f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    1212:	0f be c0             	movsbl %al,%eax
    1215:	89 44 24 04          	mov    %eax,0x4(%esp)
    1219:	8b 45 08             	mov    0x8(%ebp),%eax
    121c:	89 04 24             	mov    %eax,(%esp)
    121f:	e8 bb fe ff ff       	call   10df <putc>
    1224:	e9 30 01 00 00       	jmp    1359 <printf+0x19a>
      }
    } else if(state == '%'){
    1229:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
    122d:	0f 85 26 01 00 00    	jne    1359 <printf+0x19a>
      if(c == 'd'){
    1233:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
    1237:	75 2d                	jne    1266 <printf+0xa7>
        printint(fd, *ap, 10, 1);
    1239:	8b 45 e8             	mov    -0x18(%ebp),%eax
    123c:	8b 00                	mov    (%eax),%eax
    123e:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
    1245:	00 
    1246:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
    124d:	00 
    124e:	89 44 24 04          	mov    %eax,0x4(%esp)
    1252:	8b 45 08             	mov    0x8(%ebp),%eax
    1255:	89 04 24             	mov    %eax,(%esp)
    1258:	e8 aa fe ff ff       	call   1107 <printint>
        ap++;
    125d:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    1261:	e9 ec 00 00 00       	jmp    1352 <printf+0x193>
      } else if(c == 'x' || c == 'p'){
    1266:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
    126a:	74 06                	je     1272 <printf+0xb3>
    126c:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
    1270:	75 2d                	jne    129f <printf+0xe0>
        printint(fd, *ap, 16, 0);
    1272:	8b 45 e8             	mov    -0x18(%ebp),%eax
    1275:	8b 00                	mov    (%eax),%eax
    1277:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
    127e:	00 
    127f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
    1286:	00 
    1287:	89 44 24 04          	mov    %eax,0x4(%esp)
    128b:	8b 45 08             	mov    0x8(%ebp),%eax
    128e:	89 04 24             	mov    %eax,(%esp)
    1291:	e8 71 fe ff ff       	call   1107 <printint>
        ap++;
    1296:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    129a:	e9 b3 00 00 00       	jmp    1352 <printf+0x193>
      } else if(c == 's'){
    129f:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
    12a3:	75 45                	jne    12ea <printf+0x12b>
        s = (char*)*ap;
    12a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
    12a8:	8b 00                	mov    (%eax),%eax
    12aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
    12ad:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
    12b1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    12b5:	75 09                	jne    12c0 <printf+0x101>
          s = "(null)";
    12b7:	c7 45 f4 91 16 00 00 	movl   $0x1691,-0xc(%ebp)
        while(*s != 0){
    12be:	eb 1e                	jmp    12de <printf+0x11f>
    12c0:	eb 1c                	jmp    12de <printf+0x11f>
          putc(fd, *s);
    12c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
    12c5:	0f b6 00             	movzbl (%eax),%eax
    12c8:	0f be c0             	movsbl %al,%eax
    12cb:	89 44 24 04          	mov    %eax,0x4(%esp)
    12cf:	8b 45 08             	mov    0x8(%ebp),%eax
    12d2:	89 04 24             	mov    %eax,(%esp)
    12d5:	e8 05 fe ff ff       	call   10df <putc>
          s++;
    12da:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
    12de:	8b 45 f4             	mov    -0xc(%ebp),%eax
    12e1:	0f b6 00             	movzbl (%eax),%eax
    12e4:	84 c0                	test   %al,%al
    12e6:	75 da                	jne    12c2 <printf+0x103>
    12e8:	eb 68                	jmp    1352 <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    12ea:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
    12ee:	75 1d                	jne    130d <printf+0x14e>
        putc(fd, *ap);
    12f0:	8b 45 e8             	mov    -0x18(%ebp),%eax
    12f3:	8b 00                	mov    (%eax),%eax
    12f5:	0f be c0             	movsbl %al,%eax
    12f8:	89 44 24 04          	mov    %eax,0x4(%esp)
    12fc:	8b 45 08             	mov    0x8(%ebp),%eax
    12ff:	89 04 24             	mov    %eax,(%esp)
    1302:	e8 d8 fd ff ff       	call   10df <putc>
        ap++;
    1307:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    130b:	eb 45                	jmp    1352 <printf+0x193>
      } else if(c == '%'){
    130d:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
    1311:	75 17                	jne    132a <printf+0x16b>
        putc(fd, c);
    1313:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    1316:	0f be c0             	movsbl %al,%eax
    1319:	89 44 24 04          	mov    %eax,0x4(%esp)
    131d:	8b 45 08             	mov    0x8(%ebp),%eax
    1320:	89 04 24             	mov    %eax,(%esp)
    1323:	e8 b7 fd ff ff       	call   10df <putc>
    1328:	eb 28                	jmp    1352 <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    132a:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
    1331:	00 
    1332:	8b 45 08             	mov    0x8(%ebp),%eax
    1335:	89 04 24             	mov    %eax,(%esp)
    1338:	e8 a2 fd ff ff       	call   10df <putc>
        putc(fd, c);
    133d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    1340:	0f be c0             	movsbl %al,%eax
    1343:	89 44 24 04          	mov    %eax,0x4(%esp)
    1347:	8b 45 08             	mov    0x8(%ebp),%eax
    134a:	89 04 24             	mov    %eax,(%esp)
    134d:	e8 8d fd ff ff       	call   10df <putc>
      }
      state = 0;
    1352:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
    1359:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    135d:	8b 55 0c             	mov    0xc(%ebp),%edx
    1360:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1363:	01 d0                	add    %edx,%eax
    1365:	0f b6 00             	movzbl (%eax),%eax
    1368:	84 c0                	test   %al,%al
    136a:	0f 85 71 fe ff ff    	jne    11e1 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
    1370:	c9                   	leave  
    1371:	c3                   	ret    

00001372 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    1372:	55                   	push   %ebp
    1373:	89 e5                	mov    %esp,%ebp
    1375:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
    1378:	8b 45 08             	mov    0x8(%ebp),%eax
    137b:	83 e8 08             	sub    $0x8,%eax
    137e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1381:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
    1386:	89 45 fc             	mov    %eax,-0x4(%ebp)
    1389:	eb 24                	jmp    13af <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    138b:	8b 45 fc             	mov    -0x4(%ebp),%eax
    138e:	8b 00                	mov    (%eax),%eax
    1390:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    1393:	77 12                	ja     13a7 <free+0x35>
    1395:	8b 45 f8             	mov    -0x8(%ebp),%eax
    1398:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    139b:	77 24                	ja     13c1 <free+0x4f>
    139d:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13a0:	8b 00                	mov    (%eax),%eax
    13a2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    13a5:	77 1a                	ja     13c1 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    13a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13aa:	8b 00                	mov    (%eax),%eax
    13ac:	89 45 fc             	mov    %eax,-0x4(%ebp)
    13af:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13b2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    13b5:	76 d4                	jbe    138b <free+0x19>
    13b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13ba:	8b 00                	mov    (%eax),%eax
    13bc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    13bf:	76 ca                	jbe    138b <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    13c1:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13c4:	8b 40 04             	mov    0x4(%eax),%eax
    13c7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
    13ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13d1:	01 c2                	add    %eax,%edx
    13d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13d6:	8b 00                	mov    (%eax),%eax
    13d8:	39 c2                	cmp    %eax,%edx
    13da:	75 24                	jne    1400 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
    13dc:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13df:	8b 50 04             	mov    0x4(%eax),%edx
    13e2:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13e5:	8b 00                	mov    (%eax),%eax
    13e7:	8b 40 04             	mov    0x4(%eax),%eax
    13ea:	01 c2                	add    %eax,%edx
    13ec:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13ef:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
    13f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13f5:	8b 00                	mov    (%eax),%eax
    13f7:	8b 10                	mov    (%eax),%edx
    13f9:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13fc:	89 10                	mov    %edx,(%eax)
    13fe:	eb 0a                	jmp    140a <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
    1400:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1403:	8b 10                	mov    (%eax),%edx
    1405:	8b 45 f8             	mov    -0x8(%ebp),%eax
    1408:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
    140a:	8b 45 fc             	mov    -0x4(%ebp),%eax
    140d:	8b 40 04             	mov    0x4(%eax),%eax
    1410:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
    1417:	8b 45 fc             	mov    -0x4(%ebp),%eax
    141a:	01 d0                	add    %edx,%eax
    141c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    141f:	75 20                	jne    1441 <free+0xcf>
    p->s.size += bp->s.size;
    1421:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1424:	8b 50 04             	mov    0x4(%eax),%edx
    1427:	8b 45 f8             	mov    -0x8(%ebp),%eax
    142a:	8b 40 04             	mov    0x4(%eax),%eax
    142d:	01 c2                	add    %eax,%edx
    142f:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1432:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
    1435:	8b 45 f8             	mov    -0x8(%ebp),%eax
    1438:	8b 10                	mov    (%eax),%edx
    143a:	8b 45 fc             	mov    -0x4(%ebp),%eax
    143d:	89 10                	mov    %edx,(%eax)
    143f:	eb 08                	jmp    1449 <free+0xd7>
  } else
    p->s.ptr = bp;
    1441:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1444:	8b 55 f8             	mov    -0x8(%ebp),%edx
    1447:	89 10                	mov    %edx,(%eax)
  freep = p;
    1449:	8b 45 fc             	mov    -0x4(%ebp),%eax
    144c:	a3 6c 1c 00 00       	mov    %eax,0x1c6c
}
    1451:	c9                   	leave  
    1452:	c3                   	ret    

00001453 <morecore>:

static Header*
morecore(uint nu)
{
    1453:	55                   	push   %ebp
    1454:	89 e5                	mov    %esp,%ebp
    1456:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
    1459:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
    1460:	77 07                	ja     1469 <morecore+0x16>
    nu = 4096;
    1462:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
    1469:	8b 45 08             	mov    0x8(%ebp),%eax
    146c:	c1 e0 03             	shl    $0x3,%eax
    146f:	89 04 24             	mov    %eax,(%esp)
    1472:	e8 38 fc ff ff       	call   10af <sbrk>
    1477:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
    147a:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
    147e:	75 07                	jne    1487 <morecore+0x34>
    return 0;
    1480:	b8 00 00 00 00       	mov    $0x0,%eax
    1485:	eb 22                	jmp    14a9 <morecore+0x56>
  hp = (Header*)p;
    1487:	8b 45 f4             	mov    -0xc(%ebp),%eax
    148a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
    148d:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1490:	8b 55 08             	mov    0x8(%ebp),%edx
    1493:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
    1496:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1499:	83 c0 08             	add    $0x8,%eax
    149c:	89 04 24             	mov    %eax,(%esp)
    149f:	e8 ce fe ff ff       	call   1372 <free>
  return freep;
    14a4:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
}
    14a9:	c9                   	leave  
    14aa:	c3                   	ret    

000014ab <malloc>:

void*
malloc(uint nbytes)
{
    14ab:	55                   	push   %ebp
    14ac:	89 e5                	mov    %esp,%ebp
    14ae:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    14b1:	8b 45 08             	mov    0x8(%ebp),%eax
    14b4:	83 c0 07             	add    $0x7,%eax
    14b7:	c1 e8 03             	shr    $0x3,%eax
    14ba:	83 c0 01             	add    $0x1,%eax
    14bd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
    14c0:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
    14c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    14c8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    14cc:	75 23                	jne    14f1 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
    14ce:	c7 45 f0 64 1c 00 00 	movl   $0x1c64,-0x10(%ebp)
    14d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
    14d8:	a3 6c 1c 00 00       	mov    %eax,0x1c6c
    14dd:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
    14e2:	a3 64 1c 00 00       	mov    %eax,0x1c64
    base.s.size = 0;
    14e7:	c7 05 68 1c 00 00 00 	movl   $0x0,0x1c68
    14ee:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    14f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
    14f4:	8b 00                	mov    (%eax),%eax
    14f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
    14f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
    14fc:	8b 40 04             	mov    0x4(%eax),%eax
    14ff:	3b 45 ec             	cmp    -0x14(%ebp),%eax
    1502:	72 4d                	jb     1551 <malloc+0xa6>
      if(p->s.size == nunits)
    1504:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1507:	8b 40 04             	mov    0x4(%eax),%eax
    150a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
    150d:	75 0c                	jne    151b <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
    150f:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1512:	8b 10                	mov    (%eax),%edx
    1514:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1517:	89 10                	mov    %edx,(%eax)
    1519:	eb 26                	jmp    1541 <malloc+0x96>
      else {
        p->s.size -= nunits;
    151b:	8b 45 f4             	mov    -0xc(%ebp),%eax
    151e:	8b 40 04             	mov    0x4(%eax),%eax
    1521:	2b 45 ec             	sub    -0x14(%ebp),%eax
    1524:	89 c2                	mov    %eax,%edx
    1526:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1529:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
    152c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    152f:	8b 40 04             	mov    0x4(%eax),%eax
    1532:	c1 e0 03             	shl    $0x3,%eax
    1535:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
    1538:	8b 45 f4             	mov    -0xc(%ebp),%eax
    153b:	8b 55 ec             	mov    -0x14(%ebp),%edx
    153e:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
    1541:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1544:	a3 6c 1c 00 00       	mov    %eax,0x1c6c
      return (void*)(p + 1);
    1549:	8b 45 f4             	mov    -0xc(%ebp),%eax
    154c:	83 c0 08             	add    $0x8,%eax
    154f:	eb 38                	jmp    1589 <malloc+0xde>
    }
    if(p == freep)
    1551:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
    1556:	39 45 f4             	cmp    %eax,-0xc(%ebp)
    1559:	75 1b                	jne    1576 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
    155b:	8b 45 ec             	mov    -0x14(%ebp),%eax
    155e:	89 04 24             	mov    %eax,(%esp)
    1561:	e8 ed fe ff ff       	call   1453 <morecore>
    1566:	89 45 f4             	mov    %eax,-0xc(%ebp)
    1569:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    156d:	75 07                	jne    1576 <malloc+0xcb>
        return 0;
    156f:	b8 00 00 00 00       	mov    $0x0,%eax
    1574:	eb 13                	jmp    1589 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1576:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1579:	89 45 f0             	mov    %eax,-0x10(%ebp)
    157c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    157f:	8b 00                	mov    (%eax),%eax
    1581:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
    1584:	e9 70 ff ff ff       	jmp    14f9 <malloc+0x4e>
}
    1589:	c9                   	leave  
    158a:	c3                   	ret    
