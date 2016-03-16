
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
      62:	e8 be 0f 00 00       	call   1025 <exit>
  
  switch(cmd->type){
      67:	8b 45 08             	mov    0x8(%ebp),%eax
      6a:	8b 00                	mov    (%eax),%eax
      6c:	83 f8 05             	cmp    $0x5,%eax
      6f:	77 09                	ja     7a <runcmd+0x24>
      71:	8b 04 85 b0 15 00 00 	mov    0x15b0(,%eax,4),%eax
      78:	ff e0                	jmp    *%eax
  default:
    panic("runcmd");
      7a:	c7 04 24 84 15 00 00 	movl   $0x1584,(%esp)
      81:	e8 44 03 00 00       	call   3ca <panic>

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
      96:	e8 8a 0f 00 00       	call   1025 <exit>
    exec(ecmd->argv[0], ecmd->argv);
      9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
      9e:	8d 50 04             	lea    0x4(%eax),%edx
      a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
      a4:	8b 40 04             	mov    0x4(%eax),%eax
      a7:	89 54 24 04          	mov    %edx,0x4(%esp)
      ab:	89 04 24             	mov    %eax,(%esp)
      ae:	e8 aa 0f 00 00       	call   105d <exec>
    printf(2, "exec %s failed\n", ecmd->argv[0]);
      b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
      b6:	8b 40 04             	mov    0x4(%eax),%eax
      b9:	89 44 24 08          	mov    %eax,0x8(%esp)
      bd:	c7 44 24 04 8b 15 00 	movl   $0x158b,0x4(%esp)
      c4:	00 
      c5:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
      cc:	e8 e4 10 00 00       	call   11b5 <printf>
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
      e5:	e8 63 0f 00 00       	call   104d <close>
    if(open(rcmd->file, rcmd->mode) < 0){
      ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
      ed:	8b 50 10             	mov    0x10(%eax),%edx
      f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
      f3:	8b 40 08             	mov    0x8(%eax),%eax
      f6:	89 54 24 04          	mov    %edx,0x4(%esp)
      fa:	89 04 24             	mov    %eax,(%esp)
      fd:	e8 63 0f 00 00       	call   1065 <open>
     102:	85 c0                	test   %eax,%eax
     104:	79 23                	jns    129 <runcmd+0xd3>
      printf(2, "open %s failed\n", rcmd->file);
     106:	8b 45 f0             	mov    -0x10(%ebp),%eax
     109:	8b 40 08             	mov    0x8(%eax),%eax
     10c:	89 44 24 08          	mov    %eax,0x8(%esp)
     110:	c7 44 24 04 9b 15 00 	movl   $0x159b,0x4(%esp)
     117:	00 
     118:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     11f:	e8 91 10 00 00       	call   11b5 <printf>
      exit();
     124:	e8 fc 0e 00 00       	call   1025 <exit>
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
     142:	e8 a9 02 00 00       	call   3f0 <fork1>
     147:	85 c0                	test   %eax,%eax
     149:	75 0e                	jne    159 <runcmd+0x103>
      runcmd(lcmd->left);
     14b:	8b 45 ec             	mov    -0x14(%ebp),%eax
     14e:	8b 40 04             	mov    0x4(%eax),%eax
     151:	89 04 24             	mov    %eax,(%esp)
     154:	e8 fd fe ff ff       	call   56 <runcmd>
    wait();
     159:	e8 cf 0e 00 00       	call   102d <wait>
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
     17d:	e8 b3 0e 00 00       	call   1035 <pipe>
     182:	85 c0                	test   %eax,%eax
     184:	79 0c                	jns    192 <runcmd+0x13c>
      panic("pipe");
     186:	c7 04 24 ab 15 00 00 	movl   $0x15ab,(%esp)
     18d:	e8 38 02 00 00       	call   3ca <panic>
    if(fork1() == 0){
     192:	e8 59 02 00 00       	call   3f0 <fork1>
     197:	85 c0                	test   %eax,%eax
     199:	75 3b                	jne    1d6 <runcmd+0x180>
      close(1);
     19b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     1a2:	e8 a6 0e 00 00       	call   104d <close>
      dup(p[1]);
     1a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
     1aa:	89 04 24             	mov    %eax,(%esp)
     1ad:	e8 eb 0e 00 00       	call   109d <dup>
      close(p[0]);
     1b2:	8b 45 dc             	mov    -0x24(%ebp),%eax
     1b5:	89 04 24             	mov    %eax,(%esp)
     1b8:	e8 90 0e 00 00       	call   104d <close>
      close(p[1]);
     1bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
     1c0:	89 04 24             	mov    %eax,(%esp)
     1c3:	e8 85 0e 00 00       	call   104d <close>
      runcmd(pcmd->left);
     1c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
     1cb:	8b 40 04             	mov    0x4(%eax),%eax
     1ce:	89 04 24             	mov    %eax,(%esp)
     1d1:	e8 80 fe ff ff       	call   56 <runcmd>
    }
    if(fork1() == 0){
     1d6:	e8 15 02 00 00       	call   3f0 <fork1>
     1db:	85 c0                	test   %eax,%eax
     1dd:	75 3b                	jne    21a <runcmd+0x1c4>
      close(0);
     1df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
     1e6:	e8 62 0e 00 00       	call   104d <close>
      dup(p[0]);
     1eb:	8b 45 dc             	mov    -0x24(%ebp),%eax
     1ee:	89 04 24             	mov    %eax,(%esp)
     1f1:	e8 a7 0e 00 00       	call   109d <dup>
      close(p[0]);
     1f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
     1f9:	89 04 24             	mov    %eax,(%esp)
     1fc:	e8 4c 0e 00 00       	call   104d <close>
      close(p[1]);
     201:	8b 45 e0             	mov    -0x20(%ebp),%eax
     204:	89 04 24             	mov    %eax,(%esp)
     207:	e8 41 0e 00 00       	call   104d <close>
      runcmd(pcmd->right);
     20c:	8b 45 e8             	mov    -0x18(%ebp),%eax
     20f:	8b 40 08             	mov    0x8(%eax),%eax
     212:	89 04 24             	mov    %eax,(%esp)
     215:	e8 3c fe ff ff       	call   56 <runcmd>
    }
    close(p[0]);
     21a:	8b 45 dc             	mov    -0x24(%ebp),%eax
     21d:	89 04 24             	mov    %eax,(%esp)
     220:	e8 28 0e 00 00       	call   104d <close>
    close(p[1]);
     225:	8b 45 e0             	mov    -0x20(%ebp),%eax
     228:	89 04 24             	mov    %eax,(%esp)
     22b:	e8 1d 0e 00 00       	call   104d <close>
    wait();
     230:	e8 f8 0d 00 00       	call   102d <wait>
    wait();
     235:	e8 f3 0d 00 00       	call   102d <wait>
    break;
     23a:	eb 20                	jmp    25c <runcmd+0x206>
    
  case BACK:
    bcmd = (struct backcmd*)cmd;
     23c:	8b 45 08             	mov    0x8(%ebp),%eax
     23f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(fork1() == 0)
     242:	e8 a9 01 00 00       	call   3f0 <fork1>
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
     25c:	e8 c4 0d 00 00       	call   1025 <exit>

00000261 <getcmd>:
}

int
getcmd(char *buf, int nbuf)
{
     261:	55                   	push   %ebp
     262:	89 e5                	mov    %esp,%ebp
     264:	83 ec 18             	sub    $0x18,%esp
  printf(2, "$ ");
     267:	c7 44 24 04 c8 15 00 	movl   $0x15c8,0x4(%esp)
     26e:	00 
     26f:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     276:	e8 3a 0f 00 00       	call   11b5 <printf>
  memset(buf, 0, nbuf);
     27b:	8b 45 0c             	mov    0xc(%ebp),%eax
     27e:	89 44 24 08          	mov    %eax,0x8(%esp)
     282:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     289:	00 
     28a:	8b 45 08             	mov    0x8(%ebp),%eax
     28d:	89 04 24             	mov    %eax,(%esp)
     290:	e8 e3 0b 00 00       	call   e78 <memset>
  gets(buf, nbuf);
     295:	8b 45 0c             	mov    0xc(%ebp),%eax
     298:	89 44 24 04          	mov    %eax,0x4(%esp)
     29c:	8b 45 08             	mov    0x8(%ebp),%eax
     29f:	89 04 24             	mov    %eax,(%esp)
     2a2:	e8 28 0c 00 00       	call   ecf <gets>
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
     2d8:	e8 70 0d 00 00       	call   104d <close>
      break;
     2dd:	eb 1f                	jmp    2fe <main+0x3f>
{
  static char buf[100];
  int fd;
  
  // Assumes three file descriptors open.
  while((fd = open("console", O_RDWR)) >= 0){
     2df:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
     2e6:	00 
     2e7:	c7 04 24 cb 15 00 00 	movl   $0x15cb,(%esp)
     2ee:	e8 72 0d 00 00       	call   1065 <open>
     2f3:	89 44 24 1c          	mov    %eax,0x1c(%esp)
     2f7:	83 7c 24 1c 00       	cmpl   $0x0,0x1c(%esp)
     2fc:	79 cc                	jns    2ca <main+0xb>
      break;
    }
  }
  
  // Read and run input commands.
  while(getcmd(buf, sizeof(buf)) >= 0){
     2fe:	e9 a6 00 00 00       	jmp    3a9 <main+0xea>
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
     32b:	e8 21 0b 00 00       	call   e51 <strlen>
     330:	83 e8 01             	sub    $0x1,%eax
     333:	c6 80 80 1b 00 00 00 	movb   $0x0,0x1b80(%eax)
      if(chdir(buf+3) < 0)
     33a:	c7 04 24 83 1b 00 00 	movl   $0x1b83,(%esp)
     341:	e8 4f 0d 00 00       	call   1095 <chdir>
     346:	85 c0                	test   %eax,%eax
     348:	79 1e                	jns    368 <main+0xa9>
        printf(2, "cannot cd %s\n", buf+3);
     34a:	c7 44 24 08 83 1b 00 	movl   $0x1b83,0x8(%esp)
     351:	00 
     352:	c7 44 24 04 d3 15 00 	movl   $0x15d3,0x4(%esp)
     359:	00 
     35a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     361:	e8 4f 0e 00 00       	call   11b5 <printf>
      continue;
     366:	eb 41                	jmp    3a9 <main+0xea>
     368:	eb 3f                	jmp    3a9 <main+0xea>
    } else if (buf[0] == 'h' && buf[1] =='i') {
     36a:	0f b6 05 80 1b 00 00 	movzbl 0x1b80,%eax
     371:	3c 68                	cmp    $0x68,%al
     373:	75 12                	jne    387 <main+0xc8>
     375:	0f b6 05 81 1b 00 00 	movzbl 0x1b81,%eax
     37c:	3c 69                	cmp    $0x69,%al
     37e:	75 07                	jne    387 <main+0xc8>
      display_history();
     380:	e8 e7 09 00 00       	call   d6c <display_history>
      continue;
     385:	eb 22                	jmp    3a9 <main+0xea>
    }
    if(fork1() == 0)
     387:	e8 64 00 00 00       	call   3f0 <fork1>
     38c:	85 c0                	test   %eax,%eax
     38e:	75 14                	jne    3a4 <main+0xe5>
      runcmd(parsecmd(buf));
     390:	c7 04 24 80 1b 00 00 	movl   $0x1b80,(%esp)
     397:	e8 c9 03 00 00       	call   765 <parsecmd>
     39c:	89 04 24             	mov    %eax,(%esp)
     39f:	e8 b2 fc ff ff       	call   56 <runcmd>
    wait();
     3a4:	e8 84 0c 00 00       	call   102d <wait>
      break;
    }
  }
  
  // Read and run input commands.
  while(getcmd(buf, sizeof(buf)) >= 0){
     3a9:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
     3b0:	00 
     3b1:	c7 04 24 80 1b 00 00 	movl   $0x1b80,(%esp)
     3b8:	e8 a4 fe ff ff       	call   261 <getcmd>
     3bd:	85 c0                	test   %eax,%eax
     3bf:	0f 89 3e ff ff ff    	jns    303 <main+0x44>
    }
    if(fork1() == 0)
      runcmd(parsecmd(buf));
    wait();
  }
  exit();
     3c5:	e8 5b 0c 00 00       	call   1025 <exit>

000003ca <panic>:
}

void
panic(char *s)
{
     3ca:	55                   	push   %ebp
     3cb:	89 e5                	mov    %esp,%ebp
     3cd:	83 ec 18             	sub    $0x18,%esp
  printf(2, "%s\n", s);
     3d0:	8b 45 08             	mov    0x8(%ebp),%eax
     3d3:	89 44 24 08          	mov    %eax,0x8(%esp)
     3d7:	c7 44 24 04 e1 15 00 	movl   $0x15e1,0x4(%esp)
     3de:	00 
     3df:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     3e6:	e8 ca 0d 00 00       	call   11b5 <printf>
  exit();
     3eb:	e8 35 0c 00 00       	call   1025 <exit>

000003f0 <fork1>:
}

int
fork1(void)
{
     3f0:	55                   	push   %ebp
     3f1:	89 e5                	mov    %esp,%ebp
     3f3:	83 ec 28             	sub    $0x28,%esp
  int pid;
  
  pid = fork();
     3f6:	e8 22 0c 00 00       	call   101d <fork>
     3fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pid == -1)
     3fe:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
     402:	75 0c                	jne    410 <fork1+0x20>
    panic("fork");
     404:	c7 04 24 e5 15 00 00 	movl   $0x15e5,(%esp)
     40b:	e8 ba ff ff ff       	call   3ca <panic>
  return pid;
     410:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     413:	c9                   	leave  
     414:	c3                   	ret    

00000415 <execcmd>:
//PAGEBREAK!
// Constructors

struct cmd*
execcmd(void)
{
     415:	55                   	push   %ebp
     416:	89 e5                	mov    %esp,%ebp
     418:	83 ec 28             	sub    $0x28,%esp
  struct execcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     41b:	c7 04 24 54 00 00 00 	movl   $0x54,(%esp)
     422:	e8 7a 10 00 00       	call   14a1 <malloc>
     427:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     42a:	c7 44 24 08 54 00 00 	movl   $0x54,0x8(%esp)
     431:	00 
     432:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     439:	00 
     43a:	8b 45 f4             	mov    -0xc(%ebp),%eax
     43d:	89 04 24             	mov    %eax,(%esp)
     440:	e8 33 0a 00 00       	call   e78 <memset>
  cmd->type = EXEC;
     445:	8b 45 f4             	mov    -0xc(%ebp),%eax
     448:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  return (struct cmd*)cmd;
     44e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     451:	c9                   	leave  
     452:	c3                   	ret    

00000453 <redircmd>:

struct cmd*
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
     453:	55                   	push   %ebp
     454:	89 e5                	mov    %esp,%ebp
     456:	83 ec 28             	sub    $0x28,%esp
  struct redircmd *cmd;

  cmd = malloc(sizeof(*cmd));
     459:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
     460:	e8 3c 10 00 00       	call   14a1 <malloc>
     465:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     468:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
     46f:	00 
     470:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     477:	00 
     478:	8b 45 f4             	mov    -0xc(%ebp),%eax
     47b:	89 04 24             	mov    %eax,(%esp)
     47e:	e8 f5 09 00 00       	call   e78 <memset>
  cmd->type = REDIR;
     483:	8b 45 f4             	mov    -0xc(%ebp),%eax
     486:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  cmd->cmd = subcmd;
     48c:	8b 45 f4             	mov    -0xc(%ebp),%eax
     48f:	8b 55 08             	mov    0x8(%ebp),%edx
     492:	89 50 04             	mov    %edx,0x4(%eax)
  cmd->file = file;
     495:	8b 45 f4             	mov    -0xc(%ebp),%eax
     498:	8b 55 0c             	mov    0xc(%ebp),%edx
     49b:	89 50 08             	mov    %edx,0x8(%eax)
  cmd->efile = efile;
     49e:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4a1:	8b 55 10             	mov    0x10(%ebp),%edx
     4a4:	89 50 0c             	mov    %edx,0xc(%eax)
  cmd->mode = mode;
     4a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4aa:	8b 55 14             	mov    0x14(%ebp),%edx
     4ad:	89 50 10             	mov    %edx,0x10(%eax)
  cmd->fd = fd;
     4b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4b3:	8b 55 18             	mov    0x18(%ebp),%edx
     4b6:	89 50 14             	mov    %edx,0x14(%eax)
  return (struct cmd*)cmd;
     4b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     4bc:	c9                   	leave  
     4bd:	c3                   	ret    

000004be <pipecmd>:

struct cmd*
pipecmd(struct cmd *left, struct cmd *right)
{
     4be:	55                   	push   %ebp
     4bf:	89 e5                	mov    %esp,%ebp
     4c1:	83 ec 28             	sub    $0x28,%esp
  struct pipecmd *cmd;

  cmd = malloc(sizeof(*cmd));
     4c4:	c7 04 24 0c 00 00 00 	movl   $0xc,(%esp)
     4cb:	e8 d1 0f 00 00       	call   14a1 <malloc>
     4d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     4d3:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
     4da:	00 
     4db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     4e2:	00 
     4e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4e6:	89 04 24             	mov    %eax,(%esp)
     4e9:	e8 8a 09 00 00       	call   e78 <memset>
  cmd->type = PIPE;
     4ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4f1:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
  cmd->left = left;
     4f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4fa:	8b 55 08             	mov    0x8(%ebp),%edx
     4fd:	89 50 04             	mov    %edx,0x4(%eax)
  cmd->right = right;
     500:	8b 45 f4             	mov    -0xc(%ebp),%eax
     503:	8b 55 0c             	mov    0xc(%ebp),%edx
     506:	89 50 08             	mov    %edx,0x8(%eax)
  return (struct cmd*)cmd;
     509:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     50c:	c9                   	leave  
     50d:	c3                   	ret    

0000050e <listcmd>:

struct cmd*
listcmd(struct cmd *left, struct cmd *right)
{
     50e:	55                   	push   %ebp
     50f:	89 e5                	mov    %esp,%ebp
     511:	83 ec 28             	sub    $0x28,%esp
  struct listcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     514:	c7 04 24 0c 00 00 00 	movl   $0xc,(%esp)
     51b:	e8 81 0f 00 00       	call   14a1 <malloc>
     520:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     523:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
     52a:	00 
     52b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     532:	00 
     533:	8b 45 f4             	mov    -0xc(%ebp),%eax
     536:	89 04 24             	mov    %eax,(%esp)
     539:	e8 3a 09 00 00       	call   e78 <memset>
  cmd->type = LIST;
     53e:	8b 45 f4             	mov    -0xc(%ebp),%eax
     541:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
  cmd->left = left;
     547:	8b 45 f4             	mov    -0xc(%ebp),%eax
     54a:	8b 55 08             	mov    0x8(%ebp),%edx
     54d:	89 50 04             	mov    %edx,0x4(%eax)
  cmd->right = right;
     550:	8b 45 f4             	mov    -0xc(%ebp),%eax
     553:	8b 55 0c             	mov    0xc(%ebp),%edx
     556:	89 50 08             	mov    %edx,0x8(%eax)
  return (struct cmd*)cmd;
     559:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     55c:	c9                   	leave  
     55d:	c3                   	ret    

0000055e <backcmd>:

struct cmd*
backcmd(struct cmd *subcmd)
{
     55e:	55                   	push   %ebp
     55f:	89 e5                	mov    %esp,%ebp
     561:	83 ec 28             	sub    $0x28,%esp
  struct backcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     564:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
     56b:	e8 31 0f 00 00       	call   14a1 <malloc>
     570:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(cmd, 0, sizeof(*cmd));
     573:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
     57a:	00 
     57b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     582:	00 
     583:	8b 45 f4             	mov    -0xc(%ebp),%eax
     586:	89 04 24             	mov    %eax,(%esp)
     589:	e8 ea 08 00 00       	call   e78 <memset>
  cmd->type = BACK;
     58e:	8b 45 f4             	mov    -0xc(%ebp),%eax
     591:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
  cmd->cmd = subcmd;
     597:	8b 45 f4             	mov    -0xc(%ebp),%eax
     59a:	8b 55 08             	mov    0x8(%ebp),%edx
     59d:	89 50 04             	mov    %edx,0x4(%eax)
  return (struct cmd*)cmd;
     5a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     5a3:	c9                   	leave  
     5a4:	c3                   	ret    

000005a5 <gettoken>:
char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>&;()";

int
gettoken(char **ps, char *es, char **q, char **eq)
{
     5a5:	55                   	push   %ebp
     5a6:	89 e5                	mov    %esp,%ebp
     5a8:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int ret;
  
  s = *ps;
     5ab:	8b 45 08             	mov    0x8(%ebp),%eax
     5ae:	8b 00                	mov    (%eax),%eax
     5b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(s < es && strchr(whitespace, *s))
     5b3:	eb 04                	jmp    5b9 <gettoken+0x14>
    s++;
     5b5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
{
  char *s;
  int ret;
  
  s = *ps;
  while(s < es && strchr(whitespace, *s))
     5b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
     5bc:	3b 45 0c             	cmp    0xc(%ebp),%eax
     5bf:	73 1d                	jae    5de <gettoken+0x39>
     5c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
     5c4:	0f b6 00             	movzbl (%eax),%eax
     5c7:	0f be c0             	movsbl %al,%eax
     5ca:	89 44 24 04          	mov    %eax,0x4(%esp)
     5ce:	c7 04 24 44 1b 00 00 	movl   $0x1b44,(%esp)
     5d5:	e8 c2 08 00 00       	call   e9c <strchr>
     5da:	85 c0                	test   %eax,%eax
     5dc:	75 d7                	jne    5b5 <gettoken+0x10>
    s++;
  if(q)
     5de:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
     5e2:	74 08                	je     5ec <gettoken+0x47>
    *q = s;
     5e4:	8b 45 10             	mov    0x10(%ebp),%eax
     5e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
     5ea:	89 10                	mov    %edx,(%eax)
  ret = *s;
     5ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
     5ef:	0f b6 00             	movzbl (%eax),%eax
     5f2:	0f be c0             	movsbl %al,%eax
     5f5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  switch(*s){
     5f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
     5fb:	0f b6 00             	movzbl (%eax),%eax
     5fe:	0f be c0             	movsbl %al,%eax
     601:	83 f8 29             	cmp    $0x29,%eax
     604:	7f 14                	jg     61a <gettoken+0x75>
     606:	83 f8 28             	cmp    $0x28,%eax
     609:	7d 28                	jge    633 <gettoken+0x8e>
     60b:	85 c0                	test   %eax,%eax
     60d:	0f 84 94 00 00 00    	je     6a7 <gettoken+0x102>
     613:	83 f8 26             	cmp    $0x26,%eax
     616:	74 1b                	je     633 <gettoken+0x8e>
     618:	eb 3c                	jmp    656 <gettoken+0xb1>
     61a:	83 f8 3e             	cmp    $0x3e,%eax
     61d:	74 1a                	je     639 <gettoken+0x94>
     61f:	83 f8 3e             	cmp    $0x3e,%eax
     622:	7f 0a                	jg     62e <gettoken+0x89>
     624:	83 e8 3b             	sub    $0x3b,%eax
     627:	83 f8 01             	cmp    $0x1,%eax
     62a:	77 2a                	ja     656 <gettoken+0xb1>
     62c:	eb 05                	jmp    633 <gettoken+0x8e>
     62e:	83 f8 7c             	cmp    $0x7c,%eax
     631:	75 23                	jne    656 <gettoken+0xb1>
  case '(':
  case ')':
  case ';':
  case '&':
  case '<':
    s++;
     633:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    break;
     637:	eb 6f                	jmp    6a8 <gettoken+0x103>
  case '>':
    s++;
     639:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(*s == '>'){
     63d:	8b 45 f4             	mov    -0xc(%ebp),%eax
     640:	0f b6 00             	movzbl (%eax),%eax
     643:	3c 3e                	cmp    $0x3e,%al
     645:	75 0d                	jne    654 <gettoken+0xaf>
      ret = '+';
     647:	c7 45 f0 2b 00 00 00 	movl   $0x2b,-0x10(%ebp)
      s++;
     64e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    }
    break;
     652:	eb 54                	jmp    6a8 <gettoken+0x103>
     654:	eb 52                	jmp    6a8 <gettoken+0x103>
  default:
    ret = 'a';
     656:	c7 45 f0 61 00 00 00 	movl   $0x61,-0x10(%ebp)
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     65d:	eb 04                	jmp    663 <gettoken+0xbe>
      s++;
     65f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      s++;
    }
    break;
  default:
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     663:	8b 45 f4             	mov    -0xc(%ebp),%eax
     666:	3b 45 0c             	cmp    0xc(%ebp),%eax
     669:	73 3a                	jae    6a5 <gettoken+0x100>
     66b:	8b 45 f4             	mov    -0xc(%ebp),%eax
     66e:	0f b6 00             	movzbl (%eax),%eax
     671:	0f be c0             	movsbl %al,%eax
     674:	89 44 24 04          	mov    %eax,0x4(%esp)
     678:	c7 04 24 44 1b 00 00 	movl   $0x1b44,(%esp)
     67f:	e8 18 08 00 00       	call   e9c <strchr>
     684:	85 c0                	test   %eax,%eax
     686:	75 1d                	jne    6a5 <gettoken+0x100>
     688:	8b 45 f4             	mov    -0xc(%ebp),%eax
     68b:	0f b6 00             	movzbl (%eax),%eax
     68e:	0f be c0             	movsbl %al,%eax
     691:	89 44 24 04          	mov    %eax,0x4(%esp)
     695:	c7 04 24 4a 1b 00 00 	movl   $0x1b4a,(%esp)
     69c:	e8 fb 07 00 00       	call   e9c <strchr>
     6a1:	85 c0                	test   %eax,%eax
     6a3:	74 ba                	je     65f <gettoken+0xba>
      s++;
    break;
     6a5:	eb 01                	jmp    6a8 <gettoken+0x103>
  if(q)
    *q = s;
  ret = *s;
  switch(*s){
  case 0:
    break;
     6a7:	90                   	nop
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
      s++;
    break;
  }
  if(eq)
     6a8:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
     6ac:	74 0a                	je     6b8 <gettoken+0x113>
    *eq = s;
     6ae:	8b 45 14             	mov    0x14(%ebp),%eax
     6b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
     6b4:	89 10                	mov    %edx,(%eax)
  
  while(s < es && strchr(whitespace, *s))
     6b6:	eb 06                	jmp    6be <gettoken+0x119>
     6b8:	eb 04                	jmp    6be <gettoken+0x119>
    s++;
     6ba:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    break;
  }
  if(eq)
    *eq = s;
  
  while(s < es && strchr(whitespace, *s))
     6be:	8b 45 f4             	mov    -0xc(%ebp),%eax
     6c1:	3b 45 0c             	cmp    0xc(%ebp),%eax
     6c4:	73 1d                	jae    6e3 <gettoken+0x13e>
     6c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
     6c9:	0f b6 00             	movzbl (%eax),%eax
     6cc:	0f be c0             	movsbl %al,%eax
     6cf:	89 44 24 04          	mov    %eax,0x4(%esp)
     6d3:	c7 04 24 44 1b 00 00 	movl   $0x1b44,(%esp)
     6da:	e8 bd 07 00 00       	call   e9c <strchr>
     6df:	85 c0                	test   %eax,%eax
     6e1:	75 d7                	jne    6ba <gettoken+0x115>
    s++;
  *ps = s;
     6e3:	8b 45 08             	mov    0x8(%ebp),%eax
     6e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
     6e9:	89 10                	mov    %edx,(%eax)
  return ret;
     6eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
     6ee:	c9                   	leave  
     6ef:	c3                   	ret    

000006f0 <peek>:

int
peek(char **ps, char *es, char *toks)
{
     6f0:	55                   	push   %ebp
     6f1:	89 e5                	mov    %esp,%ebp
     6f3:	83 ec 28             	sub    $0x28,%esp
  char *s;
  
  s = *ps;
     6f6:	8b 45 08             	mov    0x8(%ebp),%eax
     6f9:	8b 00                	mov    (%eax),%eax
     6fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(s < es && strchr(whitespace, *s))
     6fe:	eb 04                	jmp    704 <peek+0x14>
    s++;
     700:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
peek(char **ps, char *es, char *toks)
{
  char *s;
  
  s = *ps;
  while(s < es && strchr(whitespace, *s))
     704:	8b 45 f4             	mov    -0xc(%ebp),%eax
     707:	3b 45 0c             	cmp    0xc(%ebp),%eax
     70a:	73 1d                	jae    729 <peek+0x39>
     70c:	8b 45 f4             	mov    -0xc(%ebp),%eax
     70f:	0f b6 00             	movzbl (%eax),%eax
     712:	0f be c0             	movsbl %al,%eax
     715:	89 44 24 04          	mov    %eax,0x4(%esp)
     719:	c7 04 24 44 1b 00 00 	movl   $0x1b44,(%esp)
     720:	e8 77 07 00 00       	call   e9c <strchr>
     725:	85 c0                	test   %eax,%eax
     727:	75 d7                	jne    700 <peek+0x10>
    s++;
  *ps = s;
     729:	8b 45 08             	mov    0x8(%ebp),%eax
     72c:	8b 55 f4             	mov    -0xc(%ebp),%edx
     72f:	89 10                	mov    %edx,(%eax)
  return *s && strchr(toks, *s);
     731:	8b 45 f4             	mov    -0xc(%ebp),%eax
     734:	0f b6 00             	movzbl (%eax),%eax
     737:	84 c0                	test   %al,%al
     739:	74 23                	je     75e <peek+0x6e>
     73b:	8b 45 f4             	mov    -0xc(%ebp),%eax
     73e:	0f b6 00             	movzbl (%eax),%eax
     741:	0f be c0             	movsbl %al,%eax
     744:	89 44 24 04          	mov    %eax,0x4(%esp)
     748:	8b 45 10             	mov    0x10(%ebp),%eax
     74b:	89 04 24             	mov    %eax,(%esp)
     74e:	e8 49 07 00 00       	call   e9c <strchr>
     753:	85 c0                	test   %eax,%eax
     755:	74 07                	je     75e <peek+0x6e>
     757:	b8 01 00 00 00       	mov    $0x1,%eax
     75c:	eb 05                	jmp    763 <peek+0x73>
     75e:	b8 00 00 00 00       	mov    $0x0,%eax
}
     763:	c9                   	leave  
     764:	c3                   	ret    

00000765 <parsecmd>:
struct cmd *parseexec(char**, char*);
struct cmd *nulterminate(struct cmd*);

struct cmd*
parsecmd(char *s)
{
     765:	55                   	push   %ebp
     766:	89 e5                	mov    %esp,%ebp
     768:	53                   	push   %ebx
     769:	83 ec 24             	sub    $0x24,%esp
  char *es;
  struct cmd *cmd;

  es = s + strlen(s);
     76c:	8b 5d 08             	mov    0x8(%ebp),%ebx
     76f:	8b 45 08             	mov    0x8(%ebp),%eax
     772:	89 04 24             	mov    %eax,(%esp)
     775:	e8 d7 06 00 00       	call   e51 <strlen>
     77a:	01 d8                	add    %ebx,%eax
     77c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  cmd = parseline(&s, es);
     77f:	8b 45 f4             	mov    -0xc(%ebp),%eax
     782:	89 44 24 04          	mov    %eax,0x4(%esp)
     786:	8d 45 08             	lea    0x8(%ebp),%eax
     789:	89 04 24             	mov    %eax,(%esp)
     78c:	e8 60 00 00 00       	call   7f1 <parseline>
     791:	89 45 f0             	mov    %eax,-0x10(%ebp)
  peek(&s, es, "");
     794:	c7 44 24 08 ea 15 00 	movl   $0x15ea,0x8(%esp)
     79b:	00 
     79c:	8b 45 f4             	mov    -0xc(%ebp),%eax
     79f:	89 44 24 04          	mov    %eax,0x4(%esp)
     7a3:	8d 45 08             	lea    0x8(%ebp),%eax
     7a6:	89 04 24             	mov    %eax,(%esp)
     7a9:	e8 42 ff ff ff       	call   6f0 <peek>
  if(s != es){
     7ae:	8b 45 08             	mov    0x8(%ebp),%eax
     7b1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
     7b4:	74 27                	je     7dd <parsecmd+0x78>
    printf(2, "leftovers: %s\n", s);
     7b6:	8b 45 08             	mov    0x8(%ebp),%eax
     7b9:	89 44 24 08          	mov    %eax,0x8(%esp)
     7bd:	c7 44 24 04 eb 15 00 	movl   $0x15eb,0x4(%esp)
     7c4:	00 
     7c5:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
     7cc:	e8 e4 09 00 00       	call   11b5 <printf>
    panic("syntax");
     7d1:	c7 04 24 fa 15 00 00 	movl   $0x15fa,(%esp)
     7d8:	e8 ed fb ff ff       	call   3ca <panic>
  }
  nulterminate(cmd);
     7dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
     7e0:	89 04 24             	mov    %eax,(%esp)
     7e3:	e8 a3 04 00 00       	call   c8b <nulterminate>
  return cmd;
     7e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
     7eb:	83 c4 24             	add    $0x24,%esp
     7ee:	5b                   	pop    %ebx
     7ef:	5d                   	pop    %ebp
     7f0:	c3                   	ret    

000007f1 <parseline>:

struct cmd*
parseline(char **ps, char *es)
{
     7f1:	55                   	push   %ebp
     7f2:	89 e5                	mov    %esp,%ebp
     7f4:	83 ec 28             	sub    $0x28,%esp
  struct cmd *cmd;

  cmd = parsepipe(ps, es);
     7f7:	8b 45 0c             	mov    0xc(%ebp),%eax
     7fa:	89 44 24 04          	mov    %eax,0x4(%esp)
     7fe:	8b 45 08             	mov    0x8(%ebp),%eax
     801:	89 04 24             	mov    %eax,(%esp)
     804:	e8 bc 00 00 00       	call   8c5 <parsepipe>
     809:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(peek(ps, es, "&")){
     80c:	eb 30                	jmp    83e <parseline+0x4d>
    gettoken(ps, es, 0, 0);
     80e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     815:	00 
     816:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     81d:	00 
     81e:	8b 45 0c             	mov    0xc(%ebp),%eax
     821:	89 44 24 04          	mov    %eax,0x4(%esp)
     825:	8b 45 08             	mov    0x8(%ebp),%eax
     828:	89 04 24             	mov    %eax,(%esp)
     82b:	e8 75 fd ff ff       	call   5a5 <gettoken>
    cmd = backcmd(cmd);
     830:	8b 45 f4             	mov    -0xc(%ebp),%eax
     833:	89 04 24             	mov    %eax,(%esp)
     836:	e8 23 fd ff ff       	call   55e <backcmd>
     83b:	89 45 f4             	mov    %eax,-0xc(%ebp)
parseline(char **ps, char *es)
{
  struct cmd *cmd;

  cmd = parsepipe(ps, es);
  while(peek(ps, es, "&")){
     83e:	c7 44 24 08 01 16 00 	movl   $0x1601,0x8(%esp)
     845:	00 
     846:	8b 45 0c             	mov    0xc(%ebp),%eax
     849:	89 44 24 04          	mov    %eax,0x4(%esp)
     84d:	8b 45 08             	mov    0x8(%ebp),%eax
     850:	89 04 24             	mov    %eax,(%esp)
     853:	e8 98 fe ff ff       	call   6f0 <peek>
     858:	85 c0                	test   %eax,%eax
     85a:	75 b2                	jne    80e <parseline+0x1d>
    gettoken(ps, es, 0, 0);
    cmd = backcmd(cmd);
  }
  if(peek(ps, es, ";")){
     85c:	c7 44 24 08 03 16 00 	movl   $0x1603,0x8(%esp)
     863:	00 
     864:	8b 45 0c             	mov    0xc(%ebp),%eax
     867:	89 44 24 04          	mov    %eax,0x4(%esp)
     86b:	8b 45 08             	mov    0x8(%ebp),%eax
     86e:	89 04 24             	mov    %eax,(%esp)
     871:	e8 7a fe ff ff       	call   6f0 <peek>
     876:	85 c0                	test   %eax,%eax
     878:	74 46                	je     8c0 <parseline+0xcf>
    gettoken(ps, es, 0, 0);
     87a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     881:	00 
     882:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     889:	00 
     88a:	8b 45 0c             	mov    0xc(%ebp),%eax
     88d:	89 44 24 04          	mov    %eax,0x4(%esp)
     891:	8b 45 08             	mov    0x8(%ebp),%eax
     894:	89 04 24             	mov    %eax,(%esp)
     897:	e8 09 fd ff ff       	call   5a5 <gettoken>
    cmd = listcmd(cmd, parseline(ps, es));
     89c:	8b 45 0c             	mov    0xc(%ebp),%eax
     89f:	89 44 24 04          	mov    %eax,0x4(%esp)
     8a3:	8b 45 08             	mov    0x8(%ebp),%eax
     8a6:	89 04 24             	mov    %eax,(%esp)
     8a9:	e8 43 ff ff ff       	call   7f1 <parseline>
     8ae:	89 44 24 04          	mov    %eax,0x4(%esp)
     8b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
     8b5:	89 04 24             	mov    %eax,(%esp)
     8b8:	e8 51 fc ff ff       	call   50e <listcmd>
     8bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  }
  return cmd;
     8c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     8c3:	c9                   	leave  
     8c4:	c3                   	ret    

000008c5 <parsepipe>:

struct cmd*
parsepipe(char **ps, char *es)
{
     8c5:	55                   	push   %ebp
     8c6:	89 e5                	mov    %esp,%ebp
     8c8:	83 ec 28             	sub    $0x28,%esp
  struct cmd *cmd;

  cmd = parseexec(ps, es);
     8cb:	8b 45 0c             	mov    0xc(%ebp),%eax
     8ce:	89 44 24 04          	mov    %eax,0x4(%esp)
     8d2:	8b 45 08             	mov    0x8(%ebp),%eax
     8d5:	89 04 24             	mov    %eax,(%esp)
     8d8:	e8 68 02 00 00       	call   b45 <parseexec>
     8dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(peek(ps, es, "|")){
     8e0:	c7 44 24 08 05 16 00 	movl   $0x1605,0x8(%esp)
     8e7:	00 
     8e8:	8b 45 0c             	mov    0xc(%ebp),%eax
     8eb:	89 44 24 04          	mov    %eax,0x4(%esp)
     8ef:	8b 45 08             	mov    0x8(%ebp),%eax
     8f2:	89 04 24             	mov    %eax,(%esp)
     8f5:	e8 f6 fd ff ff       	call   6f0 <peek>
     8fa:	85 c0                	test   %eax,%eax
     8fc:	74 46                	je     944 <parsepipe+0x7f>
    gettoken(ps, es, 0, 0);
     8fe:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     905:	00 
     906:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     90d:	00 
     90e:	8b 45 0c             	mov    0xc(%ebp),%eax
     911:	89 44 24 04          	mov    %eax,0x4(%esp)
     915:	8b 45 08             	mov    0x8(%ebp),%eax
     918:	89 04 24             	mov    %eax,(%esp)
     91b:	e8 85 fc ff ff       	call   5a5 <gettoken>
    cmd = pipecmd(cmd, parsepipe(ps, es));
     920:	8b 45 0c             	mov    0xc(%ebp),%eax
     923:	89 44 24 04          	mov    %eax,0x4(%esp)
     927:	8b 45 08             	mov    0x8(%ebp),%eax
     92a:	89 04 24             	mov    %eax,(%esp)
     92d:	e8 93 ff ff ff       	call   8c5 <parsepipe>
     932:	89 44 24 04          	mov    %eax,0x4(%esp)
     936:	8b 45 f4             	mov    -0xc(%ebp),%eax
     939:	89 04 24             	mov    %eax,(%esp)
     93c:	e8 7d fb ff ff       	call   4be <pipecmd>
     941:	89 45 f4             	mov    %eax,-0xc(%ebp)
  }
  return cmd;
     944:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     947:	c9                   	leave  
     948:	c3                   	ret    

00000949 <parseredirs>:

struct cmd*
parseredirs(struct cmd *cmd, char **ps, char *es)
{
     949:	55                   	push   %ebp
     94a:	89 e5                	mov    %esp,%ebp
     94c:	83 ec 38             	sub    $0x38,%esp
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
     94f:	e9 f6 00 00 00       	jmp    a4a <parseredirs+0x101>
    tok = gettoken(ps, es, 0, 0);
     954:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     95b:	00 
     95c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     963:	00 
     964:	8b 45 10             	mov    0x10(%ebp),%eax
     967:	89 44 24 04          	mov    %eax,0x4(%esp)
     96b:	8b 45 0c             	mov    0xc(%ebp),%eax
     96e:	89 04 24             	mov    %eax,(%esp)
     971:	e8 2f fc ff ff       	call   5a5 <gettoken>
     976:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(gettoken(ps, es, &q, &eq) != 'a')
     979:	8d 45 ec             	lea    -0x14(%ebp),%eax
     97c:	89 44 24 0c          	mov    %eax,0xc(%esp)
     980:	8d 45 f0             	lea    -0x10(%ebp),%eax
     983:	89 44 24 08          	mov    %eax,0x8(%esp)
     987:	8b 45 10             	mov    0x10(%ebp),%eax
     98a:	89 44 24 04          	mov    %eax,0x4(%esp)
     98e:	8b 45 0c             	mov    0xc(%ebp),%eax
     991:	89 04 24             	mov    %eax,(%esp)
     994:	e8 0c fc ff ff       	call   5a5 <gettoken>
     999:	83 f8 61             	cmp    $0x61,%eax
     99c:	74 0c                	je     9aa <parseredirs+0x61>
      panic("missing file for redirection");
     99e:	c7 04 24 07 16 00 00 	movl   $0x1607,(%esp)
     9a5:	e8 20 fa ff ff       	call   3ca <panic>
    switch(tok){
     9aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
     9ad:	83 f8 3c             	cmp    $0x3c,%eax
     9b0:	74 0f                	je     9c1 <parseredirs+0x78>
     9b2:	83 f8 3e             	cmp    $0x3e,%eax
     9b5:	74 38                	je     9ef <parseredirs+0xa6>
     9b7:	83 f8 2b             	cmp    $0x2b,%eax
     9ba:	74 61                	je     a1d <parseredirs+0xd4>
     9bc:	e9 89 00 00 00       	jmp    a4a <parseredirs+0x101>
    case '<':
      cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
     9c1:	8b 55 ec             	mov    -0x14(%ebp),%edx
     9c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
     9c7:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
     9ce:	00 
     9cf:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     9d6:	00 
     9d7:	89 54 24 08          	mov    %edx,0x8(%esp)
     9db:	89 44 24 04          	mov    %eax,0x4(%esp)
     9df:	8b 45 08             	mov    0x8(%ebp),%eax
     9e2:	89 04 24             	mov    %eax,(%esp)
     9e5:	e8 69 fa ff ff       	call   453 <redircmd>
     9ea:	89 45 08             	mov    %eax,0x8(%ebp)
      break;
     9ed:	eb 5b                	jmp    a4a <parseredirs+0x101>
    case '>':
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
     9ef:	8b 55 ec             	mov    -0x14(%ebp),%edx
     9f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
     9f5:	c7 44 24 10 01 00 00 	movl   $0x1,0x10(%esp)
     9fc:	00 
     9fd:	c7 44 24 0c 01 02 00 	movl   $0x201,0xc(%esp)
     a04:	00 
     a05:	89 54 24 08          	mov    %edx,0x8(%esp)
     a09:	89 44 24 04          	mov    %eax,0x4(%esp)
     a0d:	8b 45 08             	mov    0x8(%ebp),%eax
     a10:	89 04 24             	mov    %eax,(%esp)
     a13:	e8 3b fa ff ff       	call   453 <redircmd>
     a18:	89 45 08             	mov    %eax,0x8(%ebp)
      break;
     a1b:	eb 2d                	jmp    a4a <parseredirs+0x101>
    case '+':  // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
     a1d:	8b 55 ec             	mov    -0x14(%ebp),%edx
     a20:	8b 45 f0             	mov    -0x10(%ebp),%eax
     a23:	c7 44 24 10 01 00 00 	movl   $0x1,0x10(%esp)
     a2a:	00 
     a2b:	c7 44 24 0c 01 02 00 	movl   $0x201,0xc(%esp)
     a32:	00 
     a33:	89 54 24 08          	mov    %edx,0x8(%esp)
     a37:	89 44 24 04          	mov    %eax,0x4(%esp)
     a3b:	8b 45 08             	mov    0x8(%ebp),%eax
     a3e:	89 04 24             	mov    %eax,(%esp)
     a41:	e8 0d fa ff ff       	call   453 <redircmd>
     a46:	89 45 08             	mov    %eax,0x8(%ebp)
      break;
     a49:	90                   	nop
parseredirs(struct cmd *cmd, char **ps, char *es)
{
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
     a4a:	c7 44 24 08 24 16 00 	movl   $0x1624,0x8(%esp)
     a51:	00 
     a52:	8b 45 10             	mov    0x10(%ebp),%eax
     a55:	89 44 24 04          	mov    %eax,0x4(%esp)
     a59:	8b 45 0c             	mov    0xc(%ebp),%eax
     a5c:	89 04 24             	mov    %eax,(%esp)
     a5f:	e8 8c fc ff ff       	call   6f0 <peek>
     a64:	85 c0                	test   %eax,%eax
     a66:	0f 85 e8 fe ff ff    	jne    954 <parseredirs+0xb>
    case '+':  // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
      break;
    }
  }
  return cmd;
     a6c:	8b 45 08             	mov    0x8(%ebp),%eax
}
     a6f:	c9                   	leave  
     a70:	c3                   	ret    

00000a71 <parseblock>:

struct cmd*
parseblock(char **ps, char *es)
{
     a71:	55                   	push   %ebp
     a72:	89 e5                	mov    %esp,%ebp
     a74:	83 ec 28             	sub    $0x28,%esp
  struct cmd *cmd;

  if(!peek(ps, es, "("))
     a77:	c7 44 24 08 27 16 00 	movl   $0x1627,0x8(%esp)
     a7e:	00 
     a7f:	8b 45 0c             	mov    0xc(%ebp),%eax
     a82:	89 44 24 04          	mov    %eax,0x4(%esp)
     a86:	8b 45 08             	mov    0x8(%ebp),%eax
     a89:	89 04 24             	mov    %eax,(%esp)
     a8c:	e8 5f fc ff ff       	call   6f0 <peek>
     a91:	85 c0                	test   %eax,%eax
     a93:	75 0c                	jne    aa1 <parseblock+0x30>
    panic("parseblock");
     a95:	c7 04 24 29 16 00 00 	movl   $0x1629,(%esp)
     a9c:	e8 29 f9 ff ff       	call   3ca <panic>
  gettoken(ps, es, 0, 0);
     aa1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     aa8:	00 
     aa9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     ab0:	00 
     ab1:	8b 45 0c             	mov    0xc(%ebp),%eax
     ab4:	89 44 24 04          	mov    %eax,0x4(%esp)
     ab8:	8b 45 08             	mov    0x8(%ebp),%eax
     abb:	89 04 24             	mov    %eax,(%esp)
     abe:	e8 e2 fa ff ff       	call   5a5 <gettoken>
  cmd = parseline(ps, es);
     ac3:	8b 45 0c             	mov    0xc(%ebp),%eax
     ac6:	89 44 24 04          	mov    %eax,0x4(%esp)
     aca:	8b 45 08             	mov    0x8(%ebp),%eax
     acd:	89 04 24             	mov    %eax,(%esp)
     ad0:	e8 1c fd ff ff       	call   7f1 <parseline>
     ad5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!peek(ps, es, ")"))
     ad8:	c7 44 24 08 34 16 00 	movl   $0x1634,0x8(%esp)
     adf:	00 
     ae0:	8b 45 0c             	mov    0xc(%ebp),%eax
     ae3:	89 44 24 04          	mov    %eax,0x4(%esp)
     ae7:	8b 45 08             	mov    0x8(%ebp),%eax
     aea:	89 04 24             	mov    %eax,(%esp)
     aed:	e8 fe fb ff ff       	call   6f0 <peek>
     af2:	85 c0                	test   %eax,%eax
     af4:	75 0c                	jne    b02 <parseblock+0x91>
    panic("syntax - missing )");
     af6:	c7 04 24 36 16 00 00 	movl   $0x1636,(%esp)
     afd:	e8 c8 f8 ff ff       	call   3ca <panic>
  gettoken(ps, es, 0, 0);
     b02:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
     b09:	00 
     b0a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
     b11:	00 
     b12:	8b 45 0c             	mov    0xc(%ebp),%eax
     b15:	89 44 24 04          	mov    %eax,0x4(%esp)
     b19:	8b 45 08             	mov    0x8(%ebp),%eax
     b1c:	89 04 24             	mov    %eax,(%esp)
     b1f:	e8 81 fa ff ff       	call   5a5 <gettoken>
  cmd = parseredirs(cmd, ps, es);
     b24:	8b 45 0c             	mov    0xc(%ebp),%eax
     b27:	89 44 24 08          	mov    %eax,0x8(%esp)
     b2b:	8b 45 08             	mov    0x8(%ebp),%eax
     b2e:	89 44 24 04          	mov    %eax,0x4(%esp)
     b32:	8b 45 f4             	mov    -0xc(%ebp),%eax
     b35:	89 04 24             	mov    %eax,(%esp)
     b38:	e8 0c fe ff ff       	call   949 <parseredirs>
     b3d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  return cmd;
     b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
     b43:	c9                   	leave  
     b44:	c3                   	ret    

00000b45 <parseexec>:

struct cmd*
parseexec(char **ps, char *es)
{
     b45:	55                   	push   %ebp
     b46:	89 e5                	mov    %esp,%ebp
     b48:	83 ec 38             	sub    $0x38,%esp
  char *q, *eq;
  int tok, argc;
  struct execcmd *cmd;
  struct cmd *ret;
  
  if(peek(ps, es, "("))
     b4b:	c7 44 24 08 27 16 00 	movl   $0x1627,0x8(%esp)
     b52:	00 
     b53:	8b 45 0c             	mov    0xc(%ebp),%eax
     b56:	89 44 24 04          	mov    %eax,0x4(%esp)
     b5a:	8b 45 08             	mov    0x8(%ebp),%eax
     b5d:	89 04 24             	mov    %eax,(%esp)
     b60:	e8 8b fb ff ff       	call   6f0 <peek>
     b65:	85 c0                	test   %eax,%eax
     b67:	74 17                	je     b80 <parseexec+0x3b>
    return parseblock(ps, es);
     b69:	8b 45 0c             	mov    0xc(%ebp),%eax
     b6c:	89 44 24 04          	mov    %eax,0x4(%esp)
     b70:	8b 45 08             	mov    0x8(%ebp),%eax
     b73:	89 04 24             	mov    %eax,(%esp)
     b76:	e8 f6 fe ff ff       	call   a71 <parseblock>
     b7b:	e9 09 01 00 00       	jmp    c89 <parseexec+0x144>

  ret = execcmd();
     b80:	e8 90 f8 ff ff       	call   415 <execcmd>
     b85:	89 45 f0             	mov    %eax,-0x10(%ebp)
  cmd = (struct execcmd*)ret;
     b88:	8b 45 f0             	mov    -0x10(%ebp),%eax
     b8b:	89 45 ec             	mov    %eax,-0x14(%ebp)

  argc = 0;
     b8e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  ret = parseredirs(ret, ps, es);
     b95:	8b 45 0c             	mov    0xc(%ebp),%eax
     b98:	89 44 24 08          	mov    %eax,0x8(%esp)
     b9c:	8b 45 08             	mov    0x8(%ebp),%eax
     b9f:	89 44 24 04          	mov    %eax,0x4(%esp)
     ba3:	8b 45 f0             	mov    -0x10(%ebp),%eax
     ba6:	89 04 24             	mov    %eax,(%esp)
     ba9:	e8 9b fd ff ff       	call   949 <parseredirs>
     bae:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while(!peek(ps, es, "|)&;")){
     bb1:	e9 8f 00 00 00       	jmp    c45 <parseexec+0x100>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
     bb6:	8d 45 e0             	lea    -0x20(%ebp),%eax
     bb9:	89 44 24 0c          	mov    %eax,0xc(%esp)
     bbd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
     bc0:	89 44 24 08          	mov    %eax,0x8(%esp)
     bc4:	8b 45 0c             	mov    0xc(%ebp),%eax
     bc7:	89 44 24 04          	mov    %eax,0x4(%esp)
     bcb:	8b 45 08             	mov    0x8(%ebp),%eax
     bce:	89 04 24             	mov    %eax,(%esp)
     bd1:	e8 cf f9 ff ff       	call   5a5 <gettoken>
     bd6:	89 45 e8             	mov    %eax,-0x18(%ebp)
     bd9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     bdd:	75 05                	jne    be4 <parseexec+0x9f>
      break;
     bdf:	e9 83 00 00 00       	jmp    c67 <parseexec+0x122>
    if(tok != 'a')
     be4:	83 7d e8 61          	cmpl   $0x61,-0x18(%ebp)
     be8:	74 0c                	je     bf6 <parseexec+0xb1>
      panic("syntax");
     bea:	c7 04 24 fa 15 00 00 	movl   $0x15fa,(%esp)
     bf1:	e8 d4 f7 ff ff       	call   3ca <panic>
    cmd->argv[argc] = q;
     bf6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
     bf9:	8b 45 ec             	mov    -0x14(%ebp),%eax
     bfc:	8b 55 f4             	mov    -0xc(%ebp),%edx
     bff:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
    cmd->eargv[argc] = eq;
     c03:	8b 55 e0             	mov    -0x20(%ebp),%edx
     c06:	8b 45 ec             	mov    -0x14(%ebp),%eax
     c09:	8b 4d f4             	mov    -0xc(%ebp),%ecx
     c0c:	83 c1 08             	add    $0x8,%ecx
     c0f:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    argc++;
     c13:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(argc >= MAXARGS)
     c17:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
     c1b:	7e 0c                	jle    c29 <parseexec+0xe4>
      panic("too many args");
     c1d:	c7 04 24 49 16 00 00 	movl   $0x1649,(%esp)
     c24:	e8 a1 f7 ff ff       	call   3ca <panic>
    ret = parseredirs(ret, ps, es);
     c29:	8b 45 0c             	mov    0xc(%ebp),%eax
     c2c:	89 44 24 08          	mov    %eax,0x8(%esp)
     c30:	8b 45 08             	mov    0x8(%ebp),%eax
     c33:	89 44 24 04          	mov    %eax,0x4(%esp)
     c37:	8b 45 f0             	mov    -0x10(%ebp),%eax
     c3a:	89 04 24             	mov    %eax,(%esp)
     c3d:	e8 07 fd ff ff       	call   949 <parseredirs>
     c42:	89 45 f0             	mov    %eax,-0x10(%ebp)
  ret = execcmd();
  cmd = (struct execcmd*)ret;

  argc = 0;
  ret = parseredirs(ret, ps, es);
  while(!peek(ps, es, "|)&;")){
     c45:	c7 44 24 08 57 16 00 	movl   $0x1657,0x8(%esp)
     c4c:	00 
     c4d:	8b 45 0c             	mov    0xc(%ebp),%eax
     c50:	89 44 24 04          	mov    %eax,0x4(%esp)
     c54:	8b 45 08             	mov    0x8(%ebp),%eax
     c57:	89 04 24             	mov    %eax,(%esp)
     c5a:	e8 91 fa ff ff       	call   6f0 <peek>
     c5f:	85 c0                	test   %eax,%eax
     c61:	0f 84 4f ff ff ff    	je     bb6 <parseexec+0x71>
    argc++;
    if(argc >= MAXARGS)
      panic("too many args");
    ret = parseredirs(ret, ps, es);
  }
  cmd->argv[argc] = 0;
     c67:	8b 45 ec             	mov    -0x14(%ebp),%eax
     c6a:	8b 55 f4             	mov    -0xc(%ebp),%edx
     c6d:	c7 44 90 04 00 00 00 	movl   $0x0,0x4(%eax,%edx,4)
     c74:	00 
  cmd->eargv[argc] = 0;
     c75:	8b 45 ec             	mov    -0x14(%ebp),%eax
     c78:	8b 55 f4             	mov    -0xc(%ebp),%edx
     c7b:	83 c2 08             	add    $0x8,%edx
     c7e:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
     c85:	00 
  return ret;
     c86:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
     c89:	c9                   	leave  
     c8a:	c3                   	ret    

00000c8b <nulterminate>:

// NUL-terminate all the counted strings.
struct cmd*
nulterminate(struct cmd *cmd)
{
     c8b:	55                   	push   %ebp
     c8c:	89 e5                	mov    %esp,%ebp
     c8e:	83 ec 38             	sub    $0x38,%esp
  struct execcmd *ecmd;
  struct listcmd *lcmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if(cmd == 0)
     c91:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
     c95:	75 0a                	jne    ca1 <nulterminate+0x16>
    return 0;
     c97:	b8 00 00 00 00       	mov    $0x0,%eax
     c9c:	e9 c9 00 00 00       	jmp    d6a <nulterminate+0xdf>
  
  switch(cmd->type){
     ca1:	8b 45 08             	mov    0x8(%ebp),%eax
     ca4:	8b 00                	mov    (%eax),%eax
     ca6:	83 f8 05             	cmp    $0x5,%eax
     ca9:	0f 87 b8 00 00 00    	ja     d67 <nulterminate+0xdc>
     caf:	8b 04 85 5c 16 00 00 	mov    0x165c(,%eax,4),%eax
     cb6:	ff e0                	jmp    *%eax
  case EXEC:
    ecmd = (struct execcmd*)cmd;
     cb8:	8b 45 08             	mov    0x8(%ebp),%eax
     cbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    for(i=0; ecmd->argv[i]; i++)
     cbe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     cc5:	eb 14                	jmp    cdb <nulterminate+0x50>
      *ecmd->eargv[i] = 0;
     cc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
     cca:	8b 55 f4             	mov    -0xc(%ebp),%edx
     ccd:	83 c2 08             	add    $0x8,%edx
     cd0:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
     cd4:	c6 00 00             	movb   $0x0,(%eax)
    return 0;
  
  switch(cmd->type){
  case EXEC:
    ecmd = (struct execcmd*)cmd;
    for(i=0; ecmd->argv[i]; i++)
     cd7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     cdb:	8b 45 f0             	mov    -0x10(%ebp),%eax
     cde:	8b 55 f4             	mov    -0xc(%ebp),%edx
     ce1:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
     ce5:	85 c0                	test   %eax,%eax
     ce7:	75 de                	jne    cc7 <nulterminate+0x3c>
      *ecmd->eargv[i] = 0;
    break;
     ce9:	eb 7c                	jmp    d67 <nulterminate+0xdc>

  case REDIR:
    rcmd = (struct redircmd*)cmd;
     ceb:	8b 45 08             	mov    0x8(%ebp),%eax
     cee:	89 45 ec             	mov    %eax,-0x14(%ebp)
    nulterminate(rcmd->cmd);
     cf1:	8b 45 ec             	mov    -0x14(%ebp),%eax
     cf4:	8b 40 04             	mov    0x4(%eax),%eax
     cf7:	89 04 24             	mov    %eax,(%esp)
     cfa:	e8 8c ff ff ff       	call   c8b <nulterminate>
    *rcmd->efile = 0;
     cff:	8b 45 ec             	mov    -0x14(%ebp),%eax
     d02:	8b 40 0c             	mov    0xc(%eax),%eax
     d05:	c6 00 00             	movb   $0x0,(%eax)
    break;
     d08:	eb 5d                	jmp    d67 <nulterminate+0xdc>

  case PIPE:
    pcmd = (struct pipecmd*)cmd;
     d0a:	8b 45 08             	mov    0x8(%ebp),%eax
     d0d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    nulterminate(pcmd->left);
     d10:	8b 45 e8             	mov    -0x18(%ebp),%eax
     d13:	8b 40 04             	mov    0x4(%eax),%eax
     d16:	89 04 24             	mov    %eax,(%esp)
     d19:	e8 6d ff ff ff       	call   c8b <nulterminate>
    nulterminate(pcmd->right);
     d1e:	8b 45 e8             	mov    -0x18(%ebp),%eax
     d21:	8b 40 08             	mov    0x8(%eax),%eax
     d24:	89 04 24             	mov    %eax,(%esp)
     d27:	e8 5f ff ff ff       	call   c8b <nulterminate>
    break;
     d2c:	eb 39                	jmp    d67 <nulterminate+0xdc>
    
  case LIST:
    lcmd = (struct listcmd*)cmd;
     d2e:	8b 45 08             	mov    0x8(%ebp),%eax
     d31:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    nulterminate(lcmd->left);
     d34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     d37:	8b 40 04             	mov    0x4(%eax),%eax
     d3a:	89 04 24             	mov    %eax,(%esp)
     d3d:	e8 49 ff ff ff       	call   c8b <nulterminate>
    nulterminate(lcmd->right);
     d42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     d45:	8b 40 08             	mov    0x8(%eax),%eax
     d48:	89 04 24             	mov    %eax,(%esp)
     d4b:	e8 3b ff ff ff       	call   c8b <nulterminate>
    break;
     d50:	eb 15                	jmp    d67 <nulterminate+0xdc>

  case BACK:
    bcmd = (struct backcmd*)cmd;
     d52:	8b 45 08             	mov    0x8(%ebp),%eax
     d55:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nulterminate(bcmd->cmd);
     d58:	8b 45 e0             	mov    -0x20(%ebp),%eax
     d5b:	8b 40 04             	mov    0x4(%eax),%eax
     d5e:	89 04 24             	mov    %eax,(%esp)
     d61:	e8 25 ff ff ff       	call   c8b <nulterminate>
    break;
     d66:	90                   	nop
  }
  return cmd;
     d67:	8b 45 08             	mov    0x8(%ebp),%eax
}
     d6a:	c9                   	leave  
     d6b:	c3                   	ret    

00000d6c <display_history>:

void display_history(void) {
     d6c:	55                   	push   %ebp
     d6d:	89 e5                	mov    %esp,%ebp
     d6f:	83 ec 28             	sub    $0x28,%esp
 static char buff[100];
 int index = 0;
     d72:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

 while(history(buff, index++) == 0)
     d79:	eb 23                	jmp    d9e <display_history+0x32>
   printf(1,"%d: %s \n", index, buff);
     d7b:	c7 44 24 0c 00 1c 00 	movl   $0x1c00,0xc(%esp)
     d82:	00 
     d83:	8b 45 f4             	mov    -0xc(%ebp),%eax
     d86:	89 44 24 08          	mov    %eax,0x8(%esp)
     d8a:	c7 44 24 04 74 16 00 	movl   $0x1674,0x4(%esp)
     d91:	00 
     d92:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     d99:	e8 17 04 00 00       	call   11b5 <printf>

void display_history(void) {
 static char buff[100];
 int index = 0;

 while(history(buff, index++) == 0)
     d9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
     da1:	8d 50 01             	lea    0x1(%eax),%edx
     da4:	89 55 f4             	mov    %edx,-0xc(%ebp)
     da7:	89 44 24 04          	mov    %eax,0x4(%esp)
     dab:	c7 04 24 00 1c 00 00 	movl   $0x1c00,(%esp)
     db2:	e8 0e 03 00 00       	call   10c5 <history>
     db7:	85 c0                	test   %eax,%eax
     db9:	74 c0                	je     d7b <display_history+0xf>
   printf(1,"%d: %s \n", index, buff);

}
     dbb:	c9                   	leave  
     dbc:	c3                   	ret    

00000dbd <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
     dbd:	55                   	push   %ebp
     dbe:	89 e5                	mov    %esp,%ebp
     dc0:	57                   	push   %edi
     dc1:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
     dc2:	8b 4d 08             	mov    0x8(%ebp),%ecx
     dc5:	8b 55 10             	mov    0x10(%ebp),%edx
     dc8:	8b 45 0c             	mov    0xc(%ebp),%eax
     dcb:	89 cb                	mov    %ecx,%ebx
     dcd:	89 df                	mov    %ebx,%edi
     dcf:	89 d1                	mov    %edx,%ecx
     dd1:	fc                   	cld    
     dd2:	f3 aa                	rep stos %al,%es:(%edi)
     dd4:	89 ca                	mov    %ecx,%edx
     dd6:	89 fb                	mov    %edi,%ebx
     dd8:	89 5d 08             	mov    %ebx,0x8(%ebp)
     ddb:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
     dde:	5b                   	pop    %ebx
     ddf:	5f                   	pop    %edi
     de0:	5d                   	pop    %ebp
     de1:	c3                   	ret    

00000de2 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
     de2:	55                   	push   %ebp
     de3:	89 e5                	mov    %esp,%ebp
     de5:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
     de8:	8b 45 08             	mov    0x8(%ebp),%eax
     deb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
     dee:	90                   	nop
     def:	8b 45 08             	mov    0x8(%ebp),%eax
     df2:	8d 50 01             	lea    0x1(%eax),%edx
     df5:	89 55 08             	mov    %edx,0x8(%ebp)
     df8:	8b 55 0c             	mov    0xc(%ebp),%edx
     dfb:	8d 4a 01             	lea    0x1(%edx),%ecx
     dfe:	89 4d 0c             	mov    %ecx,0xc(%ebp)
     e01:	0f b6 12             	movzbl (%edx),%edx
     e04:	88 10                	mov    %dl,(%eax)
     e06:	0f b6 00             	movzbl (%eax),%eax
     e09:	84 c0                	test   %al,%al
     e0b:	75 e2                	jne    def <strcpy+0xd>
    ;
  return os;
     e0d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
     e10:	c9                   	leave  
     e11:	c3                   	ret    

00000e12 <strcmp>:

int
strcmp(const char *p, const char *q)
{
     e12:	55                   	push   %ebp
     e13:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
     e15:	eb 08                	jmp    e1f <strcmp+0xd>
    p++, q++;
     e17:	83 45 08 01          	addl   $0x1,0x8(%ebp)
     e1b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
     e1f:	8b 45 08             	mov    0x8(%ebp),%eax
     e22:	0f b6 00             	movzbl (%eax),%eax
     e25:	84 c0                	test   %al,%al
     e27:	74 10                	je     e39 <strcmp+0x27>
     e29:	8b 45 08             	mov    0x8(%ebp),%eax
     e2c:	0f b6 10             	movzbl (%eax),%edx
     e2f:	8b 45 0c             	mov    0xc(%ebp),%eax
     e32:	0f b6 00             	movzbl (%eax),%eax
     e35:	38 c2                	cmp    %al,%dl
     e37:	74 de                	je     e17 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
     e39:	8b 45 08             	mov    0x8(%ebp),%eax
     e3c:	0f b6 00             	movzbl (%eax),%eax
     e3f:	0f b6 d0             	movzbl %al,%edx
     e42:	8b 45 0c             	mov    0xc(%ebp),%eax
     e45:	0f b6 00             	movzbl (%eax),%eax
     e48:	0f b6 c0             	movzbl %al,%eax
     e4b:	29 c2                	sub    %eax,%edx
     e4d:	89 d0                	mov    %edx,%eax
}
     e4f:	5d                   	pop    %ebp
     e50:	c3                   	ret    

00000e51 <strlen>:

uint
strlen(char *s)
{
     e51:	55                   	push   %ebp
     e52:	89 e5                	mov    %esp,%ebp
     e54:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
     e57:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
     e5e:	eb 04                	jmp    e64 <strlen+0x13>
     e60:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
     e64:	8b 55 fc             	mov    -0x4(%ebp),%edx
     e67:	8b 45 08             	mov    0x8(%ebp),%eax
     e6a:	01 d0                	add    %edx,%eax
     e6c:	0f b6 00             	movzbl (%eax),%eax
     e6f:	84 c0                	test   %al,%al
     e71:	75 ed                	jne    e60 <strlen+0xf>
    ;
  return n;
     e73:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
     e76:	c9                   	leave  
     e77:	c3                   	ret    

00000e78 <memset>:

void*
memset(void *dst, int c, uint n)
{
     e78:	55                   	push   %ebp
     e79:	89 e5                	mov    %esp,%ebp
     e7b:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
     e7e:	8b 45 10             	mov    0x10(%ebp),%eax
     e81:	89 44 24 08          	mov    %eax,0x8(%esp)
     e85:	8b 45 0c             	mov    0xc(%ebp),%eax
     e88:	89 44 24 04          	mov    %eax,0x4(%esp)
     e8c:	8b 45 08             	mov    0x8(%ebp),%eax
     e8f:	89 04 24             	mov    %eax,(%esp)
     e92:	e8 26 ff ff ff       	call   dbd <stosb>
  return dst;
     e97:	8b 45 08             	mov    0x8(%ebp),%eax
}
     e9a:	c9                   	leave  
     e9b:	c3                   	ret    

00000e9c <strchr>:

char*
strchr(const char *s, char c)
{
     e9c:	55                   	push   %ebp
     e9d:	89 e5                	mov    %esp,%ebp
     e9f:	83 ec 04             	sub    $0x4,%esp
     ea2:	8b 45 0c             	mov    0xc(%ebp),%eax
     ea5:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
     ea8:	eb 14                	jmp    ebe <strchr+0x22>
    if(*s == c)
     eaa:	8b 45 08             	mov    0x8(%ebp),%eax
     ead:	0f b6 00             	movzbl (%eax),%eax
     eb0:	3a 45 fc             	cmp    -0x4(%ebp),%al
     eb3:	75 05                	jne    eba <strchr+0x1e>
      return (char*)s;
     eb5:	8b 45 08             	mov    0x8(%ebp),%eax
     eb8:	eb 13                	jmp    ecd <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
     eba:	83 45 08 01          	addl   $0x1,0x8(%ebp)
     ebe:	8b 45 08             	mov    0x8(%ebp),%eax
     ec1:	0f b6 00             	movzbl (%eax),%eax
     ec4:	84 c0                	test   %al,%al
     ec6:	75 e2                	jne    eaa <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
     ec8:	b8 00 00 00 00       	mov    $0x0,%eax
}
     ecd:	c9                   	leave  
     ece:	c3                   	ret    

00000ecf <gets>:

char*
gets(char *buf, int max)
{
     ecf:	55                   	push   %ebp
     ed0:	89 e5                	mov    %esp,%ebp
     ed2:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     ed5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     edc:	eb 4c                	jmp    f2a <gets+0x5b>
    cc = read(0, &c, 1);
     ede:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
     ee5:	00 
     ee6:	8d 45 ef             	lea    -0x11(%ebp),%eax
     ee9:	89 44 24 04          	mov    %eax,0x4(%esp)
     eed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
     ef4:	e8 44 01 00 00       	call   103d <read>
     ef9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
     efc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
     f00:	7f 02                	jg     f04 <gets+0x35>
      break;
     f02:	eb 31                	jmp    f35 <gets+0x66>
    buf[i++] = c;
     f04:	8b 45 f4             	mov    -0xc(%ebp),%eax
     f07:	8d 50 01             	lea    0x1(%eax),%edx
     f0a:	89 55 f4             	mov    %edx,-0xc(%ebp)
     f0d:	89 c2                	mov    %eax,%edx
     f0f:	8b 45 08             	mov    0x8(%ebp),%eax
     f12:	01 c2                	add    %eax,%edx
     f14:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
     f18:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
     f1a:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
     f1e:	3c 0a                	cmp    $0xa,%al
     f20:	74 13                	je     f35 <gets+0x66>
     f22:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
     f26:	3c 0d                	cmp    $0xd,%al
     f28:	74 0b                	je     f35 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     f2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
     f2d:	83 c0 01             	add    $0x1,%eax
     f30:	3b 45 0c             	cmp    0xc(%ebp),%eax
     f33:	7c a9                	jl     ede <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
     f35:	8b 55 f4             	mov    -0xc(%ebp),%edx
     f38:	8b 45 08             	mov    0x8(%ebp),%eax
     f3b:	01 d0                	add    %edx,%eax
     f3d:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
     f40:	8b 45 08             	mov    0x8(%ebp),%eax
}
     f43:	c9                   	leave  
     f44:	c3                   	ret    

00000f45 <stat>:

int
stat(char *n, struct stat *st)
{
     f45:	55                   	push   %ebp
     f46:	89 e5                	mov    %esp,%ebp
     f48:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     f4b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     f52:	00 
     f53:	8b 45 08             	mov    0x8(%ebp),%eax
     f56:	89 04 24             	mov    %eax,(%esp)
     f59:	e8 07 01 00 00       	call   1065 <open>
     f5e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
     f61:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
     f65:	79 07                	jns    f6e <stat+0x29>
    return -1;
     f67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
     f6c:	eb 23                	jmp    f91 <stat+0x4c>
  r = fstat(fd, st);
     f6e:	8b 45 0c             	mov    0xc(%ebp),%eax
     f71:	89 44 24 04          	mov    %eax,0x4(%esp)
     f75:	8b 45 f4             	mov    -0xc(%ebp),%eax
     f78:	89 04 24             	mov    %eax,(%esp)
     f7b:	e8 fd 00 00 00       	call   107d <fstat>
     f80:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
     f83:	8b 45 f4             	mov    -0xc(%ebp),%eax
     f86:	89 04 24             	mov    %eax,(%esp)
     f89:	e8 bf 00 00 00       	call   104d <close>
  return r;
     f8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
     f91:	c9                   	leave  
     f92:	c3                   	ret    

00000f93 <atoi>:

int
atoi(const char *s)
{
     f93:	55                   	push   %ebp
     f94:	89 e5                	mov    %esp,%ebp
     f96:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
     f99:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
     fa0:	eb 25                	jmp    fc7 <atoi+0x34>
    n = n*10 + *s++ - '0';
     fa2:	8b 55 fc             	mov    -0x4(%ebp),%edx
     fa5:	89 d0                	mov    %edx,%eax
     fa7:	c1 e0 02             	shl    $0x2,%eax
     faa:	01 d0                	add    %edx,%eax
     fac:	01 c0                	add    %eax,%eax
     fae:	89 c1                	mov    %eax,%ecx
     fb0:	8b 45 08             	mov    0x8(%ebp),%eax
     fb3:	8d 50 01             	lea    0x1(%eax),%edx
     fb6:	89 55 08             	mov    %edx,0x8(%ebp)
     fb9:	0f b6 00             	movzbl (%eax),%eax
     fbc:	0f be c0             	movsbl %al,%eax
     fbf:	01 c8                	add    %ecx,%eax
     fc1:	83 e8 30             	sub    $0x30,%eax
     fc4:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     fc7:	8b 45 08             	mov    0x8(%ebp),%eax
     fca:	0f b6 00             	movzbl (%eax),%eax
     fcd:	3c 2f                	cmp    $0x2f,%al
     fcf:	7e 0a                	jle    fdb <atoi+0x48>
     fd1:	8b 45 08             	mov    0x8(%ebp),%eax
     fd4:	0f b6 00             	movzbl (%eax),%eax
     fd7:	3c 39                	cmp    $0x39,%al
     fd9:	7e c7                	jle    fa2 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
     fdb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
     fde:	c9                   	leave  
     fdf:	c3                   	ret    

00000fe0 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
     fe0:	55                   	push   %ebp
     fe1:	89 e5                	mov    %esp,%ebp
     fe3:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
     fe6:	8b 45 08             	mov    0x8(%ebp),%eax
     fe9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
     fec:	8b 45 0c             	mov    0xc(%ebp),%eax
     fef:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
     ff2:	eb 17                	jmp    100b <memmove+0x2b>
    *dst++ = *src++;
     ff4:	8b 45 fc             	mov    -0x4(%ebp),%eax
     ff7:	8d 50 01             	lea    0x1(%eax),%edx
     ffa:	89 55 fc             	mov    %edx,-0x4(%ebp)
     ffd:	8b 55 f8             	mov    -0x8(%ebp),%edx
    1000:	8d 4a 01             	lea    0x1(%edx),%ecx
    1003:	89 4d f8             	mov    %ecx,-0x8(%ebp)
    1006:	0f b6 12             	movzbl (%edx),%edx
    1009:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
    100b:	8b 45 10             	mov    0x10(%ebp),%eax
    100e:	8d 50 ff             	lea    -0x1(%eax),%edx
    1011:	89 55 10             	mov    %edx,0x10(%ebp)
    1014:	85 c0                	test   %eax,%eax
    1016:	7f dc                	jg     ff4 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
    1018:	8b 45 08             	mov    0x8(%ebp),%eax
}
    101b:	c9                   	leave  
    101c:	c3                   	ret    

0000101d <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
    101d:	b8 01 00 00 00       	mov    $0x1,%eax
    1022:	cd 40                	int    $0x40
    1024:	c3                   	ret    

00001025 <exit>:
SYSCALL(exit)
    1025:	b8 02 00 00 00       	mov    $0x2,%eax
    102a:	cd 40                	int    $0x40
    102c:	c3                   	ret    

0000102d <wait>:
SYSCALL(wait)
    102d:	b8 03 00 00 00       	mov    $0x3,%eax
    1032:	cd 40                	int    $0x40
    1034:	c3                   	ret    

00001035 <pipe>:
SYSCALL(pipe)
    1035:	b8 04 00 00 00       	mov    $0x4,%eax
    103a:	cd 40                	int    $0x40
    103c:	c3                   	ret    

0000103d <read>:
SYSCALL(read)
    103d:	b8 05 00 00 00       	mov    $0x5,%eax
    1042:	cd 40                	int    $0x40
    1044:	c3                   	ret    

00001045 <write>:
SYSCALL(write)
    1045:	b8 10 00 00 00       	mov    $0x10,%eax
    104a:	cd 40                	int    $0x40
    104c:	c3                   	ret    

0000104d <close>:
SYSCALL(close)
    104d:	b8 15 00 00 00       	mov    $0x15,%eax
    1052:	cd 40                	int    $0x40
    1054:	c3                   	ret    

00001055 <kill>:
SYSCALL(kill)
    1055:	b8 06 00 00 00       	mov    $0x6,%eax
    105a:	cd 40                	int    $0x40
    105c:	c3                   	ret    

0000105d <exec>:
SYSCALL(exec)
    105d:	b8 07 00 00 00       	mov    $0x7,%eax
    1062:	cd 40                	int    $0x40
    1064:	c3                   	ret    

00001065 <open>:
SYSCALL(open)
    1065:	b8 0f 00 00 00       	mov    $0xf,%eax
    106a:	cd 40                	int    $0x40
    106c:	c3                   	ret    

0000106d <mknod>:
SYSCALL(mknod)
    106d:	b8 11 00 00 00       	mov    $0x11,%eax
    1072:	cd 40                	int    $0x40
    1074:	c3                   	ret    

00001075 <unlink>:
SYSCALL(unlink)
    1075:	b8 12 00 00 00       	mov    $0x12,%eax
    107a:	cd 40                	int    $0x40
    107c:	c3                   	ret    

0000107d <fstat>:
SYSCALL(fstat)
    107d:	b8 08 00 00 00       	mov    $0x8,%eax
    1082:	cd 40                	int    $0x40
    1084:	c3                   	ret    

00001085 <link>:
SYSCALL(link)
    1085:	b8 13 00 00 00       	mov    $0x13,%eax
    108a:	cd 40                	int    $0x40
    108c:	c3                   	ret    

0000108d <mkdir>:
SYSCALL(mkdir)
    108d:	b8 14 00 00 00       	mov    $0x14,%eax
    1092:	cd 40                	int    $0x40
    1094:	c3                   	ret    

00001095 <chdir>:
SYSCALL(chdir)
    1095:	b8 09 00 00 00       	mov    $0x9,%eax
    109a:	cd 40                	int    $0x40
    109c:	c3                   	ret    

0000109d <dup>:
SYSCALL(dup)
    109d:	b8 0a 00 00 00       	mov    $0xa,%eax
    10a2:	cd 40                	int    $0x40
    10a4:	c3                   	ret    

000010a5 <getpid>:
SYSCALL(getpid)
    10a5:	b8 0b 00 00 00       	mov    $0xb,%eax
    10aa:	cd 40                	int    $0x40
    10ac:	c3                   	ret    

000010ad <sbrk>:
SYSCALL(sbrk)
    10ad:	b8 0c 00 00 00       	mov    $0xc,%eax
    10b2:	cd 40                	int    $0x40
    10b4:	c3                   	ret    

000010b5 <sleep>:
SYSCALL(sleep)
    10b5:	b8 0d 00 00 00       	mov    $0xd,%eax
    10ba:	cd 40                	int    $0x40
    10bc:	c3                   	ret    

000010bd <uptime>:
SYSCALL(uptime)
    10bd:	b8 0e 00 00 00       	mov    $0xe,%eax
    10c2:	cd 40                	int    $0x40
    10c4:	c3                   	ret    

000010c5 <history>:
SYSCALL(history)
    10c5:	b8 16 00 00 00       	mov    $0x16,%eax
    10ca:	cd 40                	int    $0x40
    10cc:	c3                   	ret    

000010cd <wait2>:
SYSCALL(wait2)
    10cd:	b8 17 00 00 00       	mov    $0x17,%eax
    10d2:	cd 40                	int    $0x40
    10d4:	c3                   	ret    

000010d5 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
    10d5:	55                   	push   %ebp
    10d6:	89 e5                	mov    %esp,%ebp
    10d8:	83 ec 18             	sub    $0x18,%esp
    10db:	8b 45 0c             	mov    0xc(%ebp),%eax
    10de:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
    10e1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
    10e8:	00 
    10e9:	8d 45 f4             	lea    -0xc(%ebp),%eax
    10ec:	89 44 24 04          	mov    %eax,0x4(%esp)
    10f0:	8b 45 08             	mov    0x8(%ebp),%eax
    10f3:	89 04 24             	mov    %eax,(%esp)
    10f6:	e8 4a ff ff ff       	call   1045 <write>
}
    10fb:	c9                   	leave  
    10fc:	c3                   	ret    

000010fd <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
    10fd:	55                   	push   %ebp
    10fe:	89 e5                	mov    %esp,%ebp
    1100:	56                   	push   %esi
    1101:	53                   	push   %ebx
    1102:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
    1105:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
    110c:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
    1110:	74 17                	je     1129 <printint+0x2c>
    1112:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
    1116:	79 11                	jns    1129 <printint+0x2c>
    neg = 1;
    1118:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
    111f:	8b 45 0c             	mov    0xc(%ebp),%eax
    1122:	f7 d8                	neg    %eax
    1124:	89 45 ec             	mov    %eax,-0x14(%ebp)
    1127:	eb 06                	jmp    112f <printint+0x32>
  } else {
    x = xx;
    1129:	8b 45 0c             	mov    0xc(%ebp),%eax
    112c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
    112f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
    1136:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    1139:	8d 41 01             	lea    0x1(%ecx),%eax
    113c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    113f:	8b 5d 10             	mov    0x10(%ebp),%ebx
    1142:	8b 45 ec             	mov    -0x14(%ebp),%eax
    1145:	ba 00 00 00 00       	mov    $0x0,%edx
    114a:	f7 f3                	div    %ebx
    114c:	89 d0                	mov    %edx,%eax
    114e:	0f b6 80 52 1b 00 00 	movzbl 0x1b52(%eax),%eax
    1155:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
    1159:	8b 75 10             	mov    0x10(%ebp),%esi
    115c:	8b 45 ec             	mov    -0x14(%ebp),%eax
    115f:	ba 00 00 00 00       	mov    $0x0,%edx
    1164:	f7 f6                	div    %esi
    1166:	89 45 ec             	mov    %eax,-0x14(%ebp)
    1169:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    116d:	75 c7                	jne    1136 <printint+0x39>
  if(neg)
    116f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    1173:	74 10                	je     1185 <printint+0x88>
    buf[i++] = '-';
    1175:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1178:	8d 50 01             	lea    0x1(%eax),%edx
    117b:	89 55 f4             	mov    %edx,-0xc(%ebp)
    117e:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
    1183:	eb 1f                	jmp    11a4 <printint+0xa7>
    1185:	eb 1d                	jmp    11a4 <printint+0xa7>
    putc(fd, buf[i]);
    1187:	8d 55 dc             	lea    -0x24(%ebp),%edx
    118a:	8b 45 f4             	mov    -0xc(%ebp),%eax
    118d:	01 d0                	add    %edx,%eax
    118f:	0f b6 00             	movzbl (%eax),%eax
    1192:	0f be c0             	movsbl %al,%eax
    1195:	89 44 24 04          	mov    %eax,0x4(%esp)
    1199:	8b 45 08             	mov    0x8(%ebp),%eax
    119c:	89 04 24             	mov    %eax,(%esp)
    119f:	e8 31 ff ff ff       	call   10d5 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
    11a4:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
    11a8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    11ac:	79 d9                	jns    1187 <printint+0x8a>
    putc(fd, buf[i]);
}
    11ae:	83 c4 30             	add    $0x30,%esp
    11b1:	5b                   	pop    %ebx
    11b2:	5e                   	pop    %esi
    11b3:	5d                   	pop    %ebp
    11b4:	c3                   	ret    

000011b5 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
    11b5:	55                   	push   %ebp
    11b6:	89 e5                	mov    %esp,%ebp
    11b8:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
    11bb:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
    11c2:	8d 45 0c             	lea    0xc(%ebp),%eax
    11c5:	83 c0 04             	add    $0x4,%eax
    11c8:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
    11cb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    11d2:	e9 7c 01 00 00       	jmp    1353 <printf+0x19e>
    c = fmt[i] & 0xff;
    11d7:	8b 55 0c             	mov    0xc(%ebp),%edx
    11da:	8b 45 f0             	mov    -0x10(%ebp),%eax
    11dd:	01 d0                	add    %edx,%eax
    11df:	0f b6 00             	movzbl (%eax),%eax
    11e2:	0f be c0             	movsbl %al,%eax
    11e5:	25 ff 00 00 00       	and    $0xff,%eax
    11ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
    11ed:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    11f1:	75 2c                	jne    121f <printf+0x6a>
      if(c == '%'){
    11f3:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
    11f7:	75 0c                	jne    1205 <printf+0x50>
        state = '%';
    11f9:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
    1200:	e9 4a 01 00 00       	jmp    134f <printf+0x19a>
      } else {
        putc(fd, c);
    1205:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    1208:	0f be c0             	movsbl %al,%eax
    120b:	89 44 24 04          	mov    %eax,0x4(%esp)
    120f:	8b 45 08             	mov    0x8(%ebp),%eax
    1212:	89 04 24             	mov    %eax,(%esp)
    1215:	e8 bb fe ff ff       	call   10d5 <putc>
    121a:	e9 30 01 00 00       	jmp    134f <printf+0x19a>
      }
    } else if(state == '%'){
    121f:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
    1223:	0f 85 26 01 00 00    	jne    134f <printf+0x19a>
      if(c == 'd'){
    1229:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
    122d:	75 2d                	jne    125c <printf+0xa7>
        printint(fd, *ap, 10, 1);
    122f:	8b 45 e8             	mov    -0x18(%ebp),%eax
    1232:	8b 00                	mov    (%eax),%eax
    1234:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
    123b:	00 
    123c:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
    1243:	00 
    1244:	89 44 24 04          	mov    %eax,0x4(%esp)
    1248:	8b 45 08             	mov    0x8(%ebp),%eax
    124b:	89 04 24             	mov    %eax,(%esp)
    124e:	e8 aa fe ff ff       	call   10fd <printint>
        ap++;
    1253:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    1257:	e9 ec 00 00 00       	jmp    1348 <printf+0x193>
      } else if(c == 'x' || c == 'p'){
    125c:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
    1260:	74 06                	je     1268 <printf+0xb3>
    1262:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
    1266:	75 2d                	jne    1295 <printf+0xe0>
        printint(fd, *ap, 16, 0);
    1268:	8b 45 e8             	mov    -0x18(%ebp),%eax
    126b:	8b 00                	mov    (%eax),%eax
    126d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
    1274:	00 
    1275:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
    127c:	00 
    127d:	89 44 24 04          	mov    %eax,0x4(%esp)
    1281:	8b 45 08             	mov    0x8(%ebp),%eax
    1284:	89 04 24             	mov    %eax,(%esp)
    1287:	e8 71 fe ff ff       	call   10fd <printint>
        ap++;
    128c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    1290:	e9 b3 00 00 00       	jmp    1348 <printf+0x193>
      } else if(c == 's'){
    1295:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
    1299:	75 45                	jne    12e0 <printf+0x12b>
        s = (char*)*ap;
    129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
    129e:	8b 00                	mov    (%eax),%eax
    12a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
    12a3:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
    12a7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    12ab:	75 09                	jne    12b6 <printf+0x101>
          s = "(null)";
    12ad:	c7 45 f4 7d 16 00 00 	movl   $0x167d,-0xc(%ebp)
        while(*s != 0){
    12b4:	eb 1e                	jmp    12d4 <printf+0x11f>
    12b6:	eb 1c                	jmp    12d4 <printf+0x11f>
          putc(fd, *s);
    12b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
    12bb:	0f b6 00             	movzbl (%eax),%eax
    12be:	0f be c0             	movsbl %al,%eax
    12c1:	89 44 24 04          	mov    %eax,0x4(%esp)
    12c5:	8b 45 08             	mov    0x8(%ebp),%eax
    12c8:	89 04 24             	mov    %eax,(%esp)
    12cb:	e8 05 fe ff ff       	call   10d5 <putc>
          s++;
    12d0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
    12d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
    12d7:	0f b6 00             	movzbl (%eax),%eax
    12da:	84 c0                	test   %al,%al
    12dc:	75 da                	jne    12b8 <printf+0x103>
    12de:	eb 68                	jmp    1348 <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    12e0:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
    12e4:	75 1d                	jne    1303 <printf+0x14e>
        putc(fd, *ap);
    12e6:	8b 45 e8             	mov    -0x18(%ebp),%eax
    12e9:	8b 00                	mov    (%eax),%eax
    12eb:	0f be c0             	movsbl %al,%eax
    12ee:	89 44 24 04          	mov    %eax,0x4(%esp)
    12f2:	8b 45 08             	mov    0x8(%ebp),%eax
    12f5:	89 04 24             	mov    %eax,(%esp)
    12f8:	e8 d8 fd ff ff       	call   10d5 <putc>
        ap++;
    12fd:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    1301:	eb 45                	jmp    1348 <printf+0x193>
      } else if(c == '%'){
    1303:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
    1307:	75 17                	jne    1320 <printf+0x16b>
        putc(fd, c);
    1309:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    130c:	0f be c0             	movsbl %al,%eax
    130f:	89 44 24 04          	mov    %eax,0x4(%esp)
    1313:	8b 45 08             	mov    0x8(%ebp),%eax
    1316:	89 04 24             	mov    %eax,(%esp)
    1319:	e8 b7 fd ff ff       	call   10d5 <putc>
    131e:	eb 28                	jmp    1348 <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    1320:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
    1327:	00 
    1328:	8b 45 08             	mov    0x8(%ebp),%eax
    132b:	89 04 24             	mov    %eax,(%esp)
    132e:	e8 a2 fd ff ff       	call   10d5 <putc>
        putc(fd, c);
    1333:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    1336:	0f be c0             	movsbl %al,%eax
    1339:	89 44 24 04          	mov    %eax,0x4(%esp)
    133d:	8b 45 08             	mov    0x8(%ebp),%eax
    1340:	89 04 24             	mov    %eax,(%esp)
    1343:	e8 8d fd ff ff       	call   10d5 <putc>
      }
      state = 0;
    1348:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
    134f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    1353:	8b 55 0c             	mov    0xc(%ebp),%edx
    1356:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1359:	01 d0                	add    %edx,%eax
    135b:	0f b6 00             	movzbl (%eax),%eax
    135e:	84 c0                	test   %al,%al
    1360:	0f 85 71 fe ff ff    	jne    11d7 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
    1366:	c9                   	leave  
    1367:	c3                   	ret    

00001368 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    1368:	55                   	push   %ebp
    1369:	89 e5                	mov    %esp,%ebp
    136b:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
    136e:	8b 45 08             	mov    0x8(%ebp),%eax
    1371:	83 e8 08             	sub    $0x8,%eax
    1374:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1377:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
    137c:	89 45 fc             	mov    %eax,-0x4(%ebp)
    137f:	eb 24                	jmp    13a5 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1381:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1384:	8b 00                	mov    (%eax),%eax
    1386:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    1389:	77 12                	ja     139d <free+0x35>
    138b:	8b 45 f8             	mov    -0x8(%ebp),%eax
    138e:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    1391:	77 24                	ja     13b7 <free+0x4f>
    1393:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1396:	8b 00                	mov    (%eax),%eax
    1398:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    139b:	77 1a                	ja     13b7 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    139d:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13a0:	8b 00                	mov    (%eax),%eax
    13a2:	89 45 fc             	mov    %eax,-0x4(%ebp)
    13a5:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13a8:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    13ab:	76 d4                	jbe    1381 <free+0x19>
    13ad:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13b0:	8b 00                	mov    (%eax),%eax
    13b2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    13b5:	76 ca                	jbe    1381 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    13b7:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13ba:	8b 40 04             	mov    0x4(%eax),%eax
    13bd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
    13c4:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13c7:	01 c2                	add    %eax,%edx
    13c9:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13cc:	8b 00                	mov    (%eax),%eax
    13ce:	39 c2                	cmp    %eax,%edx
    13d0:	75 24                	jne    13f6 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
    13d2:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13d5:	8b 50 04             	mov    0x4(%eax),%edx
    13d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13db:	8b 00                	mov    (%eax),%eax
    13dd:	8b 40 04             	mov    0x4(%eax),%eax
    13e0:	01 c2                	add    %eax,%edx
    13e2:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13e5:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
    13e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13eb:	8b 00                	mov    (%eax),%eax
    13ed:	8b 10                	mov    (%eax),%edx
    13ef:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13f2:	89 10                	mov    %edx,(%eax)
    13f4:	eb 0a                	jmp    1400 <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
    13f6:	8b 45 fc             	mov    -0x4(%ebp),%eax
    13f9:	8b 10                	mov    (%eax),%edx
    13fb:	8b 45 f8             	mov    -0x8(%ebp),%eax
    13fe:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
    1400:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1403:	8b 40 04             	mov    0x4(%eax),%eax
    1406:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
    140d:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1410:	01 d0                	add    %edx,%eax
    1412:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    1415:	75 20                	jne    1437 <free+0xcf>
    p->s.size += bp->s.size;
    1417:	8b 45 fc             	mov    -0x4(%ebp),%eax
    141a:	8b 50 04             	mov    0x4(%eax),%edx
    141d:	8b 45 f8             	mov    -0x8(%ebp),%eax
    1420:	8b 40 04             	mov    0x4(%eax),%eax
    1423:	01 c2                	add    %eax,%edx
    1425:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1428:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
    142b:	8b 45 f8             	mov    -0x8(%ebp),%eax
    142e:	8b 10                	mov    (%eax),%edx
    1430:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1433:	89 10                	mov    %edx,(%eax)
    1435:	eb 08                	jmp    143f <free+0xd7>
  } else
    p->s.ptr = bp;
    1437:	8b 45 fc             	mov    -0x4(%ebp),%eax
    143a:	8b 55 f8             	mov    -0x8(%ebp),%edx
    143d:	89 10                	mov    %edx,(%eax)
  freep = p;
    143f:	8b 45 fc             	mov    -0x4(%ebp),%eax
    1442:	a3 6c 1c 00 00       	mov    %eax,0x1c6c
}
    1447:	c9                   	leave  
    1448:	c3                   	ret    

00001449 <morecore>:

static Header*
morecore(uint nu)
{
    1449:	55                   	push   %ebp
    144a:	89 e5                	mov    %esp,%ebp
    144c:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
    144f:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
    1456:	77 07                	ja     145f <morecore+0x16>
    nu = 4096;
    1458:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
    145f:	8b 45 08             	mov    0x8(%ebp),%eax
    1462:	c1 e0 03             	shl    $0x3,%eax
    1465:	89 04 24             	mov    %eax,(%esp)
    1468:	e8 40 fc ff ff       	call   10ad <sbrk>
    146d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
    1470:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
    1474:	75 07                	jne    147d <morecore+0x34>
    return 0;
    1476:	b8 00 00 00 00       	mov    $0x0,%eax
    147b:	eb 22                	jmp    149f <morecore+0x56>
  hp = (Header*)p;
    147d:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1480:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
    1483:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1486:	8b 55 08             	mov    0x8(%ebp),%edx
    1489:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
    148c:	8b 45 f0             	mov    -0x10(%ebp),%eax
    148f:	83 c0 08             	add    $0x8,%eax
    1492:	89 04 24             	mov    %eax,(%esp)
    1495:	e8 ce fe ff ff       	call   1368 <free>
  return freep;
    149a:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
}
    149f:	c9                   	leave  
    14a0:	c3                   	ret    

000014a1 <malloc>:

void*
malloc(uint nbytes)
{
    14a1:	55                   	push   %ebp
    14a2:	89 e5                	mov    %esp,%ebp
    14a4:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    14a7:	8b 45 08             	mov    0x8(%ebp),%eax
    14aa:	83 c0 07             	add    $0x7,%eax
    14ad:	c1 e8 03             	shr    $0x3,%eax
    14b0:	83 c0 01             	add    $0x1,%eax
    14b3:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
    14b6:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
    14bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    14be:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    14c2:	75 23                	jne    14e7 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
    14c4:	c7 45 f0 64 1c 00 00 	movl   $0x1c64,-0x10(%ebp)
    14cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
    14ce:	a3 6c 1c 00 00       	mov    %eax,0x1c6c
    14d3:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
    14d8:	a3 64 1c 00 00       	mov    %eax,0x1c64
    base.s.size = 0;
    14dd:	c7 05 68 1c 00 00 00 	movl   $0x0,0x1c68
    14e4:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    14e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
    14ea:	8b 00                	mov    (%eax),%eax
    14ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
    14ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
    14f2:	8b 40 04             	mov    0x4(%eax),%eax
    14f5:	3b 45 ec             	cmp    -0x14(%ebp),%eax
    14f8:	72 4d                	jb     1547 <malloc+0xa6>
      if(p->s.size == nunits)
    14fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
    14fd:	8b 40 04             	mov    0x4(%eax),%eax
    1500:	3b 45 ec             	cmp    -0x14(%ebp),%eax
    1503:	75 0c                	jne    1511 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
    1505:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1508:	8b 10                	mov    (%eax),%edx
    150a:	8b 45 f0             	mov    -0x10(%ebp),%eax
    150d:	89 10                	mov    %edx,(%eax)
    150f:	eb 26                	jmp    1537 <malloc+0x96>
      else {
        p->s.size -= nunits;
    1511:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1514:	8b 40 04             	mov    0x4(%eax),%eax
    1517:	2b 45 ec             	sub    -0x14(%ebp),%eax
    151a:	89 c2                	mov    %eax,%edx
    151c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    151f:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
    1522:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1525:	8b 40 04             	mov    0x4(%eax),%eax
    1528:	c1 e0 03             	shl    $0x3,%eax
    152b:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
    152e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1531:	8b 55 ec             	mov    -0x14(%ebp),%edx
    1534:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
    1537:	8b 45 f0             	mov    -0x10(%ebp),%eax
    153a:	a3 6c 1c 00 00       	mov    %eax,0x1c6c
      return (void*)(p + 1);
    153f:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1542:	83 c0 08             	add    $0x8,%eax
    1545:	eb 38                	jmp    157f <malloc+0xde>
    }
    if(p == freep)
    1547:	a1 6c 1c 00 00       	mov    0x1c6c,%eax
    154c:	39 45 f4             	cmp    %eax,-0xc(%ebp)
    154f:	75 1b                	jne    156c <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
    1551:	8b 45 ec             	mov    -0x14(%ebp),%eax
    1554:	89 04 24             	mov    %eax,(%esp)
    1557:	e8 ed fe ff ff       	call   1449 <morecore>
    155c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    155f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1563:	75 07                	jne    156c <malloc+0xcb>
        return 0;
    1565:	b8 00 00 00 00       	mov    $0x0,%eax
    156a:	eb 13                	jmp    157f <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    156c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    156f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    1572:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1575:	8b 00                	mov    (%eax),%eax
    1577:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
    157a:	e9 70 ff ff ff       	jmp    14ef <malloc+0x4e>
}
    157f:	c9                   	leave  
    1580:	c3                   	ret    
