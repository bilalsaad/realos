
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 b0 10 00       	mov    $0x10b000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 d6 10 80       	mov    $0x8010d650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 a6 3d 10 80       	mov    $0x80103da6,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 50 8a 10 	movl   $0x80108a50,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100049:	e8 18 54 00 00       	call   80105466 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 15 11 80 64 	movl   $0x80111564,0x80111570
80100055:	15 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 15 11 80 64 	movl   $0x80111564,0x80111574
8010005f:	15 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 d6 10 80 	movl   $0x8010d694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 15 11 80    	mov    0x80111574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 15 11 80 	movl   $0x80111564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 15 11 80       	mov    0x80111574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 15 11 80       	mov    %eax,0x80111574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 15 11 80 	cmpl   $0x80111564,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801000bd:	e8 c5 53 00 00       	call   80105487 <acquire>

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 15 11 80       	mov    0x80111574,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->blockno == blockno){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	83 c8 01             	or     $0x1,%eax
801000f6:	89 c2                	mov    %eax,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100104:	e8 e0 53 00 00       	call   801054e9 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 d6 10 	movl   $0x8010d660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 99 50 00 00       	call   801051bd <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 15 11 80 	cmpl   $0x80111564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 15 11 80       	mov    0x80111570,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010017c:	e8 68 53 00 00       	call   801054e9 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 64 15 11 80 	cmpl   $0x80111564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 57 8a 10 80 	movl   $0x80108a57,(%esp)
8010019f:	e8 96 03 00 00       	call   8010053a <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID)) {
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 62 2c 00 00       	call   80102e3a <iderw>
  }
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 68 8a 10 80 	movl   $0x80108a68,(%esp)
801001f6:	e8 3f 03 00 00       	call   8010053a <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	83 c8 04             	or     $0x4,%eax
80100203:	89 c2                	mov    %eax,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 25 2c 00 00       	call   80102e3a <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 6f 8a 10 80 	movl   $0x80108a6f,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010023c:	e8 46 52 00 00       	call   80105487 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 74 15 11 80    	mov    0x80111574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 15 11 80 	movl   $0x80111564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 15 11 80       	mov    0x80111574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 15 11 80       	mov    %eax,0x80111574

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	83 e0 fe             	and    $0xfffffffe,%eax
80100290:	89 c2                	mov    %eax,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 f4 4f 00 00       	call   80105296 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801002a9:	e8 3b 52 00 00       	call   801054e9 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	83 ec 14             	sub    $0x14,%esp
801002b6:	8b 45 08             	mov    0x8(%ebp),%eax
801002b9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002bd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002c1:	89 c2                	mov    %eax,%edx
801002c3:	ec                   	in     (%dx),%al
801002c4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002c7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002cb:	c9                   	leave  
801002cc:	c3                   	ret    

801002cd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002cd:	55                   	push   %ebp
801002ce:	89 e5                	mov    %esp,%ebp
801002d0:	83 ec 08             	sub    $0x8,%esp
801002d3:	8b 55 08             	mov    0x8(%ebp),%edx
801002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801002d9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002dd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002e0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002e4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002e8:	ee                   	out    %al,(%dx)
}
801002e9:	c9                   	leave  
801002ea:	c3                   	ret    

801002eb <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002eb:	55                   	push   %ebp
801002ec:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002ee:	fa                   	cli    
}
801002ef:	5d                   	pop    %ebp
801002f0:	c3                   	ret    

801002f1 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002f1:	55                   	push   %ebp
801002f2:	89 e5                	mov    %esp,%ebp
801002f4:	56                   	push   %esi
801002f5:	53                   	push   %ebx
801002f6:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
801002f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801002fd:	74 1c                	je     8010031b <printint+0x2a>
801002ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100302:	c1 e8 1f             	shr    $0x1f,%eax
80100305:	0f b6 c0             	movzbl %al,%eax
80100308:	89 45 10             	mov    %eax,0x10(%ebp)
8010030b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010030f:	74 0a                	je     8010031b <printint+0x2a>
    x = -xx;
80100311:	8b 45 08             	mov    0x8(%ebp),%eax
80100314:	f7 d8                	neg    %eax
80100316:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100319:	eb 06                	jmp    80100321 <printint+0x30>
  else
    x = xx;
8010031b:	8b 45 08             	mov    0x8(%ebp),%eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100328:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010032b:	8d 41 01             	lea    0x1(%ecx),%eax
8010032e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100331:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100337:	ba 00 00 00 00       	mov    $0x0,%edx
8010033c:	f7 f3                	div    %ebx
8010033e:	89 d0                	mov    %edx,%eax
80100340:	0f b6 80 04 a0 10 80 	movzbl -0x7fef5ffc(%eax),%eax
80100347:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
8010034b:	8b 75 0c             	mov    0xc(%ebp),%esi
8010034e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100351:	ba 00 00 00 00       	mov    $0x0,%edx
80100356:	f7 f6                	div    %esi
80100358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010035b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010035f:	75 c7                	jne    80100328 <printint+0x37>

  if(sign)
80100361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100365:	74 10                	je     80100377 <printint+0x86>
    buf[i++] = '-';
80100367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010036a:	8d 50 01             	lea    0x1(%eax),%edx
8010036d:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100370:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
80100375:	eb 18                	jmp    8010038f <printint+0x9e>
80100377:	eb 16                	jmp    8010038f <printint+0x9e>
    consputc(buf[i]);
80100379:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037f:	01 d0                	add    %edx,%eax
80100381:	0f b6 00             	movzbl (%eax),%eax
80100384:	0f be c0             	movsbl %al,%eax
80100387:	89 04 24             	mov    %eax,(%esp)
8010038a:	e8 38 05 00 00       	call   801008c7 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010038f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100397:	79 e0                	jns    80100379 <printint+0x88>
    consputc(buf[i]);
}
80100399:	83 c4 30             	add    $0x30,%esp
8010039c:	5b                   	pop    %ebx
8010039d:	5e                   	pop    %esi
8010039e:	5d                   	pop    %ebp
8010039f:	c3                   	ret    

801003a0 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a0:	55                   	push   %ebp
801003a1:	89 e5                	mov    %esp,%ebp
801003a3:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a6:	a1 f4 c5 10 80       	mov    0x8010c5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
801003bb:	e8 c7 50 00 00       	call   80105487 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 76 8a 10 80 	movl   $0x80108a76,(%esp)
801003ce:	e8 67 01 00 00       	call   8010053a <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d3:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e0:	e9 21 01 00 00       	jmp    80100506 <cprintf+0x166>
    if(c != '%'){
801003e5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003e9:	74 10                	je     801003fb <cprintf+0x5b>
      consputc(c);
801003eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ee:	89 04 24             	mov    %eax,(%esp)
801003f1:	e8 d1 04 00 00       	call   801008c7 <consputc>
      continue;
801003f6:	e9 07 01 00 00       	jmp    80100502 <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
801003fb:	8b 55 08             	mov    0x8(%ebp),%edx
801003fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100405:	01 d0                	add    %edx,%eax
80100407:	0f b6 00             	movzbl (%eax),%eax
8010040a:	0f be c0             	movsbl %al,%eax
8010040d:	25 ff 00 00 00       	and    $0xff,%eax
80100412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100415:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100419:	75 05                	jne    80100420 <cprintf+0x80>
      break;
8010041b:	e9 06 01 00 00       	jmp    80100526 <cprintf+0x186>
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4f                	je     80100477 <cprintf+0xd7>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0xa0>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13c>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xaf>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x14a>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 57                	je     8010049c <cprintf+0xfc>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2d                	je     80100477 <cprintf+0xd7>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8d 50 04             	lea    0x4(%eax),%edx
80100455:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100458:	8b 00                	mov    (%eax),%eax
8010045a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100461:	00 
80100462:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100469:	00 
8010046a:	89 04 24             	mov    %eax,(%esp)
8010046d:	e8 7f fe ff ff       	call   801002f1 <printint>
      break;
80100472:	e9 8b 00 00 00       	jmp    80100502 <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 57 fe ff ff       	call   801002f1 <printint>
      break;
8010049a:	eb 66                	jmp    80100502 <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
8010049c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049f:	8d 50 04             	lea    0x4(%eax),%edx
801004a2:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a5:	8b 00                	mov    (%eax),%eax
801004a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004aa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ae:	75 09                	jne    801004b9 <cprintf+0x119>
        s = "(null)";
801004b0:	c7 45 ec 7f 8a 10 80 	movl   $0x80108a7f,-0x14(%ebp)
      for(; *s; s++)
801004b7:	eb 17                	jmp    801004d0 <cprintf+0x130>
801004b9:	eb 15                	jmp    801004d0 <cprintf+0x130>
        consputc(*s);
801004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004be:	0f b6 00             	movzbl (%eax),%eax
801004c1:	0f be c0             	movsbl %al,%eax
801004c4:	89 04 24             	mov    %eax,(%esp)
801004c7:	e8 fb 03 00 00       	call   801008c7 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004cc:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 e1                	jne    801004bb <cprintf+0x11b>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x162>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 df 03 00 00       	call   801008c7 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 d1 03 00 00       	call   801008c7 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 c6 03 00 00       	call   801008c7 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 bf fe ff ff    	jne    801003e5 <cprintf+0x45>
      consputc(c);
      break;
    }
  }

  if(locking)
80100526:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052a:	74 0c                	je     80100538 <cprintf+0x198>
    release(&cons.lock);
8010052c:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100533:	e8 b1 4f 00 00       	call   801054e9 <release>
}
80100538:	c9                   	leave  
80100539:	c3                   	ret    

8010053a <panic>:

void
panic(char *s)
{
8010053a:	55                   	push   %ebp
8010053b:	89 e5                	mov    %esp,%ebp
8010053d:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100540:	e8 a6 fd ff ff       	call   801002eb <cli>
  cons.locking = 0;
80100545:	c7 05 f4 c5 10 80 00 	movl   $0x0,0x8010c5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 86 8a 10 80 	movl   $0x80108a86,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 95 8a 10 80 	movl   $0x80108a95,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 a4 4f 00 00       	call   80105538 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 97 8a 10 80 	movl   $0x80108a97,(%esp)
801005af:	e8 ec fd ff ff       	call   801003a0 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005b8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bc:	7e df                	jle    8010059d <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005be:	c7 05 a0 c5 10 80 01 	movl   $0x1,0x8010c5a0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <shift_buffer_right>:
#define LEFTARROW 228 
#define RIGHTARROW 229
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory
void 
shift_buffer_right(char* start, char* end) {
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	83 ec 10             	sub    $0x10,%esp
  char * tail = end - 1;
801005d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801005d3:	83 e8 01             	sub    $0x1,%eax
801005d6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(end != start) {
801005d9:	eb 17                	jmp    801005f2 <shift_buffer_right+0x28>
    *end-- = *tail--;
801005db:	8b 45 0c             	mov    0xc(%ebp),%eax
801005de:	8d 50 ff             	lea    -0x1(%eax),%edx
801005e1:	89 55 0c             	mov    %edx,0xc(%ebp)
801005e4:	8b 55 fc             	mov    -0x4(%ebp),%edx
801005e7:	8d 4a ff             	lea    -0x1(%edx),%ecx
801005ea:	89 4d fc             	mov    %ecx,-0x4(%ebp)
801005ed:	0f b6 12             	movzbl (%edx),%edx
801005f0:	88 10                	mov    %dl,(%eax)
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory
void 
shift_buffer_right(char* start, char* end) {
  char * tail = end - 1;
  while(end != start) {
801005f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801005f5:	3b 45 08             	cmp    0x8(%ebp),%eax
801005f8:	75 e1                	jne    801005db <shift_buffer_right+0x11>
    *end-- = *tail--;
  }
}
801005fa:	c9                   	leave  
801005fb:	c3                   	ret    

801005fc <shift_buffer_left>:
void
shift_buffer_left(char * start, char * end) {
801005fc:	55                   	push   %ebp
801005fd:	89 e5                	mov    %esp,%ebp
801005ff:	83 ec 10             	sub    $0x10,%esp
 char * hare = start + 1;
80100602:	8b 45 08             	mov    0x8(%ebp),%eax
80100605:	83 c0 01             	add    $0x1,%eax
80100608:	89 45 fc             	mov    %eax,-0x4(%ebp)
 while (hare != end)
8010060b:	eb 17                	jmp    80100624 <shift_buffer_left+0x28>
   *start++=*hare++;
8010060d:	8b 45 08             	mov    0x8(%ebp),%eax
80100610:	8d 50 01             	lea    0x1(%eax),%edx
80100613:	89 55 08             	mov    %edx,0x8(%ebp)
80100616:	8b 55 fc             	mov    -0x4(%ebp),%edx
80100619:	8d 4a 01             	lea    0x1(%edx),%ecx
8010061c:	89 4d fc             	mov    %ecx,-0x4(%ebp)
8010061f:	0f b6 12             	movzbl (%edx),%edx
80100622:	88 10                	mov    %dl,(%eax)
  }
}
void
shift_buffer_left(char * start, char * end) {
 char * hare = start + 1;
 while (hare != end)
80100624:	8b 45 fc             	mov    -0x4(%ebp),%eax
80100627:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010062a:	75 e1                	jne    8010060d <shift_buffer_left+0x11>
   *start++=*hare++;
}
8010062c:	c9                   	leave  
8010062d:	c3                   	ret    

8010062e <cgaputc>:
static int left_strides = 0;
static void
cgaputc(int c)
{
8010062e:	55                   	push   %ebp
8010062f:	89 e5                	mov    %esp,%ebp
80100631:	53                   	push   %ebx
80100632:	83 ec 24             	sub    $0x24,%esp
  int pos, i=0;
80100635:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
8010063c:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
80100643:	00 
80100644:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010064b:	e8 7d fc ff ff       	call   801002cd <outb>
  pos = inb(CRTPORT+1) << 8;
80100650:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100657:	e8 54 fc ff ff       	call   801002b0 <inb>
8010065c:	0f b6 c0             	movzbl %al,%eax
8010065f:	c1 e0 08             	shl    $0x8,%eax
80100662:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
80100665:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010066c:	00 
8010066d:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100674:	e8 54 fc ff ff       	call   801002cd <outb>
  pos |= inb(CRTPORT+1);
80100679:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100680:	e8 2b fc ff ff       	call   801002b0 <inb>
80100685:	0f b6 c0             	movzbl %al,%eax
80100688:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010068b:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
8010068f:	75 33                	jne    801006c4 <cgaputc+0x96>
    pos += 80 - pos%80;
80100691:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100694:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100699:	89 c8                	mov    %ecx,%eax
8010069b:	f7 ea                	imul   %edx
8010069d:	c1 fa 05             	sar    $0x5,%edx
801006a0:	89 c8                	mov    %ecx,%eax
801006a2:	c1 f8 1f             	sar    $0x1f,%eax
801006a5:	29 c2                	sub    %eax,%edx
801006a7:	89 d0                	mov    %edx,%eax
801006a9:	c1 e0 02             	shl    $0x2,%eax
801006ac:	01 d0                	add    %edx,%eax
801006ae:	c1 e0 04             	shl    $0x4,%eax
801006b1:	29 c1                	sub    %eax,%ecx
801006b3:	89 ca                	mov    %ecx,%edx
801006b5:	b8 50 00 00 00       	mov    $0x50,%eax
801006ba:	29 d0                	sub    %edx,%eax
801006bc:	01 45 f4             	add    %eax,-0xc(%ebp)
801006bf:	e9 e8 00 00 00       	jmp    801007ac <cgaputc+0x17e>
  else if(c == BACKSPACE){
801006c4:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801006cb:	75 59                	jne    80100726 <cgaputc+0xf8>
    if(pos > 0) --pos;
801006cd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801006d1:	7e 04                	jle    801006d7 <cgaputc+0xa9>
801006d3:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
    if (left_strides > 0) {
801006d7:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
801006dc:	85 c0                	test   %eax,%eax
801006de:	0f 8e c8 00 00 00    	jle    801007ac <cgaputc+0x17e>
	for ( i = pos; i<=left_strides+pos; ++i)
801006e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801006ea:	eb 25                	jmp    80100711 <cgaputc+0xe3>
	  crt[i]=crt[i+1];
801006ec:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801006f1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801006f4:	01 d2                	add    %edx,%edx
801006f6:	01 c2                	add    %eax,%edx
801006f8:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801006fd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80100700:	83 c1 01             	add    $0x1,%ecx
80100703:	01 c9                	add    %ecx,%ecx
80100705:	01 c8                	add    %ecx,%eax
80100707:	0f b7 00             	movzwl (%eax),%eax
8010070a:	66 89 02             	mov    %ax,(%edx)
  if(c == '\n')
    pos += 80 - pos%80;
  else if(c == BACKSPACE){
    if(pos > 0) --pos;
    if (left_strides > 0) {
	for ( i = pos; i<=left_strides+pos; ++i)
8010070d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80100711:	8b 15 f8 c5 10 80    	mov    0x8010c5f8,%edx
80100717:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010071a:	01 d0                	add    %edx,%eax
8010071c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010071f:	7d cb                	jge    801006ec <cgaputc+0xbe>
80100721:	e9 86 00 00 00       	jmp    801007ac <cgaputc+0x17e>
	  crt[i]=crt[i+1];
    }
  } else if (c == LEFTARROW) {
80100726:	81 7d 08 e4 00 00 00 	cmpl   $0xe4,0x8(%ebp)
8010072d:	75 0c                	jne    8010073b <cgaputc+0x10d>
    if (pos > 0) --pos;
8010072f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100733:	7e 77                	jle    801007ac <cgaputc+0x17e>
80100735:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100739:	eb 71                	jmp    801007ac <cgaputc+0x17e>
  } else if (c == RIGHTARROW) {
8010073b:	81 7d 08 e5 00 00 00 	cmpl   $0xe5,0x8(%ebp)
80100742:	75 06                	jne    8010074a <cgaputc+0x11c>
      ++pos;
80100744:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100748:	eb 62                	jmp    801007ac <cgaputc+0x17e>
  } else{
      i = left_strides;
8010074a:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
8010074f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      while(i-->0){
80100752:	eb 2b                	jmp    8010077f <cgaputc+0x151>
	crt[pos + i + 1]=crt[pos + i];
80100754:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100759:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010075c:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010075f:	01 ca                	add    %ecx,%edx
80100761:	83 c2 01             	add    $0x1,%edx
80100764:	01 d2                	add    %edx,%edx
80100766:	01 c2                	add    %eax,%edx
80100768:	a1 00 a0 10 80       	mov    0x8010a000,%eax
8010076d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80100770:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80100773:	01 d9                	add    %ebx,%ecx
80100775:	01 c9                	add    %ecx,%ecx
80100777:	01 c8                	add    %ecx,%eax
80100779:	0f b7 00             	movzwl (%eax),%eax
8010077c:	66 89 02             	mov    %ax,(%edx)
    if (pos > 0) --pos;
  } else if (c == RIGHTARROW) {
      ++pos;
  } else{
      i = left_strides;
      while(i-->0){
8010077f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100782:	8d 50 ff             	lea    -0x1(%eax),%edx
80100785:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100788:	85 c0                	test   %eax,%eax
8010078a:	7f c8                	jg     80100754 <cgaputc+0x126>
	crt[pos + i + 1]=crt[pos + i];
      }
      crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010078c:	8b 0d 00 a0 10 80    	mov    0x8010a000,%ecx
80100792:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100795:	8d 50 01             	lea    0x1(%eax),%edx
80100798:	89 55 f4             	mov    %edx,-0xc(%ebp)
8010079b:	01 c0                	add    %eax,%eax
8010079d:	8d 14 01             	lea    (%ecx,%eax,1),%edx
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	0f b6 c0             	movzbl %al,%eax
801007a6:	80 cc 07             	or     $0x7,%ah
801007a9:	66 89 02             	mov    %ax,(%edx)
  }
  if(pos < 0 || pos > 25*80)
801007ac:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801007b0:	78 09                	js     801007bb <cgaputc+0x18d>
801007b2:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
801007b9:	7e 0c                	jle    801007c7 <cgaputc+0x199>
    panic("pos under/overflow");
801007bb:	c7 04 24 9b 8a 10 80 	movl   $0x80108a9b,(%esp)
801007c2:	e8 73 fd ff ff       	call   8010053a <panic>
  
  if((pos/80) >= 24){  // Scroll up.
801007c7:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
801007ce:	7e 53                	jle    80100823 <cgaputc+0x1f5>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801007d0:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801007d5:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
801007db:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801007e0:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801007e7:	00 
801007e8:	89 54 24 04          	mov    %edx,0x4(%esp)
801007ec:	89 04 24             	mov    %eax,(%esp)
801007ef:	e8 b6 4f 00 00       	call   801057aa <memmove>
    pos -= 80;
801007f4:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801007f8:	b8 80 07 00 00       	mov    $0x780,%eax
801007fd:	2b 45 f4             	sub    -0xc(%ebp),%eax
80100800:	8d 14 00             	lea    (%eax,%eax,1),%edx
80100803:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100808:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010080b:	01 c9                	add    %ecx,%ecx
8010080d:	01 c8                	add    %ecx,%eax
8010080f:	89 54 24 08          	mov    %edx,0x8(%esp)
80100813:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010081a:	00 
8010081b:	89 04 24             	mov    %eax,(%esp)
8010081e:	e8 b8 4e 00 00       	call   801056db <memset>
  }
  
  outb(CRTPORT, 14);
80100823:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
8010082a:	00 
8010082b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100832:	e8 96 fa ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos>>8);
80100837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010083a:	c1 f8 08             	sar    $0x8,%eax
8010083d:	0f b6 c0             	movzbl %al,%eax
80100840:	89 44 24 04          	mov    %eax,0x4(%esp)
80100844:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010084b:	e8 7d fa ff ff       	call   801002cd <outb>
  outb(CRTPORT, 15);
80100850:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100857:	00 
80100858:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010085f:	e8 69 fa ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos);
80100864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100867:	0f b6 c0             	movzbl %al,%eax
8010086a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010086e:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100875:	e8 53 fa ff ff       	call   801002cd <outb>
  if (BACKSPACE != c || left_strides > 0)
8010087a:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
80100881:	75 09                	jne    8010088c <cgaputc+0x25e>
80100883:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100888:	85 c0                	test   %eax,%eax
8010088a:	7e 24                	jle    801008b0 <cgaputc+0x282>
    crt[pos]= crt[pos] | 0x0700;
8010088c:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100891:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100894:	01 d2                	add    %edx,%edx
80100896:	01 d0                	add    %edx,%eax
80100898:	8b 15 00 a0 10 80    	mov    0x8010a000,%edx
8010089e:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801008a1:	01 c9                	add    %ecx,%ecx
801008a3:	01 ca                	add    %ecx,%edx
801008a5:	0f b7 12             	movzwl (%edx),%edx
801008a8:	80 ce 07             	or     $0x7,%dh
801008ab:	66 89 10             	mov    %dx,(%eax)
801008ae:	eb 11                	jmp    801008c1 <cgaputc+0x293>
  else
    crt[pos] = ' ' | 0x0700;
801008b0:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801008b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008b8:	01 d2                	add    %edx,%edx
801008ba:	01 d0                	add    %edx,%eax
801008bc:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
801008c1:	83 c4 24             	add    $0x24,%esp
801008c4:	5b                   	pop    %ebx
801008c5:	5d                   	pop    %ebp
801008c6:	c3                   	ret    

801008c7 <consputc>:

void
consputc(int c)
{
801008c7:	55                   	push   %ebp
801008c8:	89 e5                	mov    %esp,%ebp
801008ca:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
801008cd:	a1 a0 c5 10 80       	mov    0x8010c5a0,%eax
801008d2:	85 c0                	test   %eax,%eax
801008d4:	74 07                	je     801008dd <consputc+0x16>
    cli();
801008d6:	e8 10 fa ff ff       	call   801002eb <cli>
    for(;;)
      ;
801008db:	eb fe                	jmp    801008db <consputc+0x14>
  }

  if(c == BACKSPACE){
801008dd:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801008e4:	75 26                	jne    8010090c <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
801008e6:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801008ed:	e8 a0 67 00 00       	call   80107092 <uartputc>
801008f2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801008f9:	e8 94 67 00 00       	call   80107092 <uartputc>
801008fe:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100905:	e8 88 67 00 00       	call   80107092 <uartputc>
8010090a:	eb 1d                	jmp    80100929 <consputc+0x62>
  } else if (c == LEFTARROW || RIGHTARROW == c) {
8010090c:	81 7d 08 e4 00 00 00 	cmpl   $0xe4,0x8(%ebp)
80100913:	74 14                	je     80100929 <consputc+0x62>
80100915:	81 7d 08 e5 00 00 00 	cmpl   $0xe5,0x8(%ebp)
8010091c:	74 0b                	je     80100929 <consputc+0x62>

  } else 
    uartputc(c);
8010091e:	8b 45 08             	mov    0x8(%ebp),%eax
80100921:	89 04 24             	mov    %eax,(%esp)
80100924:	e8 69 67 00 00       	call   80107092 <uartputc>
  cgaputc(c);
80100929:	8b 45 08             	mov    0x8(%ebp),%eax
8010092c:	89 04 24             	mov    %eax,(%esp)
8010092f:	e8 fa fc ff ff       	call   8010062e <cgaputc>
}
80100934:	c9                   	leave  
80100935:	c3                   	ret    

80100936 <add_to_history>:
  int display_command;
} history;

//adds a string from start to end to history
void
add_to_history(char * start, char * end){
80100936:	55                   	push   %ebp
80100937:	89 e5                	mov    %esp,%ebp
80100939:	83 ec 28             	sub    $0x28,%esp
 int i;
 if (history.lastcommand == MAX_HISTORY){
8010093c:	a1 60 20 11 80       	mov    0x80112060,%eax
80100941:	83 f8 10             	cmp    $0x10,%eax
80100944:	75 5d                	jne    801009a3 <add_to_history+0x6d>
  for(i=0; i<MAX_HISTORY-1; ++i)
80100946:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010094d:	eb 41                	jmp    80100990 <add_to_history+0x5a>
    memmove(history.commands[i],history.commands[i+1],
	    history.command_sizes[i+1]);
8010094f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100952:	83 c0 01             	add    $0x1,%eax
80100955:	05 00 02 00 00       	add    $0x200,%eax
8010095a:	8b 04 85 20 18 11 80 	mov    -0x7feee7e0(,%eax,4),%eax
void
add_to_history(char * start, char * end){
 int i;
 if (history.lastcommand == MAX_HISTORY){
  for(i=0; i<MAX_HISTORY-1; ++i)
    memmove(history.commands[i],history.commands[i+1],
80100961:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100964:	83 c2 01             	add    $0x1,%edx
80100967:	c1 e2 07             	shl    $0x7,%edx
8010096a:	8d 8a 20 18 11 80    	lea    -0x7feee7e0(%edx),%ecx
80100970:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100973:	c1 e2 07             	shl    $0x7,%edx
80100976:	81 c2 20 18 11 80    	add    $0x80111820,%edx
8010097c:	89 44 24 08          	mov    %eax,0x8(%esp)
80100980:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80100984:	89 14 24             	mov    %edx,(%esp)
80100987:	e8 1e 4e 00 00       	call   801057aa <memmove>
//adds a string from start to end to history
void
add_to_history(char * start, char * end){
 int i;
 if (history.lastcommand == MAX_HISTORY){
  for(i=0; i<MAX_HISTORY-1; ++i)
8010098c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100990:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80100994:	7e b9                	jle    8010094f <add_to_history+0x19>
    memmove(history.commands[i],history.commands[i+1],
	    history.command_sizes[i+1]);
  --history.lastcommand;
80100996:	a1 60 20 11 80       	mov    0x80112060,%eax
8010099b:	83 e8 01             	sub    $0x1,%eax
8010099e:	a3 60 20 11 80       	mov    %eax,0x80112060
 }
 history.command_sizes[history.lastcommand] = end - start;
801009a3:	a1 60 20 11 80       	mov    0x80112060,%eax
801009a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801009ab:	8b 55 08             	mov    0x8(%ebp),%edx
801009ae:	29 d1                	sub    %edx,%ecx
801009b0:	89 ca                	mov    %ecx,%edx
801009b2:	05 00 02 00 00       	add    $0x200,%eax
801009b7:	89 14 85 20 18 11 80 	mov    %edx,-0x7feee7e0(,%eax,4)
 memmove(history.commands[history.lastcommand++],start,end-start);
801009be:	8b 55 0c             	mov    0xc(%ebp),%edx
801009c1:	8b 45 08             	mov    0x8(%ebp),%eax
801009c4:	29 c2                	sub    %eax,%edx
801009c6:	89 d0                	mov    %edx,%eax
801009c8:	89 c2                	mov    %eax,%edx
801009ca:	a1 60 20 11 80       	mov    0x80112060,%eax
801009cf:	8d 48 01             	lea    0x1(%eax),%ecx
801009d2:	89 0d 60 20 11 80    	mov    %ecx,0x80112060
801009d8:	c1 e0 07             	shl    $0x7,%eax
801009db:	8d 88 20 18 11 80    	lea    -0x7feee7e0(%eax),%ecx
801009e1:	89 54 24 08          	mov    %edx,0x8(%esp)
801009e5:	8b 45 08             	mov    0x8(%ebp),%eax
801009e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801009ec:	89 0c 24             	mov    %ecx,(%esp)
801009ef:	e8 b6 4d 00 00       	call   801057aa <memmove>
 history.display_command = history.lastcommand - 1;
801009f4:	a1 60 20 11 80       	mov    0x80112060,%eax
801009f9:	83 e8 01             	sub    $0x1,%eax
801009fc:	a3 64 20 11 80       	mov    %eax,0x80112064
}
80100a01:	c9                   	leave  
80100a02:	c3                   	ret    

80100a03 <kill_line>:

void 
kill_line(){
80100a03:	55                   	push   %ebp
80100a04:	89 e5                	mov    %esp,%ebp
80100a06:	83 ec 18             	sub    $0x18,%esp
  while(input.e != input.w &&
80100a09:	eb 19                	jmp    80100a24 <kill_line+0x21>
	input.buf[(input.e-1) % INPUT_BUF] != '\n'){
    input.e--;
80100a0b:	a1 08 18 11 80       	mov    0x80111808,%eax
80100a10:	83 e8 01             	sub    $0x1,%eax
80100a13:	a3 08 18 11 80       	mov    %eax,0x80111808
    consputc(BACKSPACE);
80100a18:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100a1f:	e8 a3 fe ff ff       	call   801008c7 <consputc>
 history.display_command = history.lastcommand - 1;
}

void 
kill_line(){
  while(input.e != input.w &&
80100a24:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100a2a:	a1 04 18 11 80       	mov    0x80111804,%eax
80100a2f:	39 c2                	cmp    %eax,%edx
80100a31:	74 16                	je     80100a49 <kill_line+0x46>
	input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100a33:	a1 08 18 11 80       	mov    0x80111808,%eax
80100a38:	83 e8 01             	sub    $0x1,%eax
80100a3b:	83 e0 7f             	and    $0x7f,%eax
80100a3e:	0f b6 80 80 17 11 80 	movzbl -0x7feee880(%eax),%eax
 history.display_command = history.lastcommand - 1;
}

void 
kill_line(){
  while(input.e != input.w &&
80100a45:	3c 0a                	cmp    $0xa,%al
80100a47:	75 c2                	jne    80100a0b <kill_line+0x8>
	input.buf[(input.e-1) % INPUT_BUF] != '\n'){
    input.e--;
    consputc(BACKSPACE);
  }
}
80100a49:	c9                   	leave  
80100a4a:	c3                   	ret    

80100a4b <display_history>:

void 
display_history(){
80100a4b:	55                   	push   %ebp
80100a4c:	89 e5                	mov    %esp,%ebp
80100a4e:	83 ec 28             	sub    $0x28,%esp
 int i =0;
80100a51:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 int size = history.command_sizes[history.display_command];
80100a58:	a1 64 20 11 80       	mov    0x80112064,%eax
80100a5d:	05 00 02 00 00       	add    $0x200,%eax
80100a62:	8b 04 85 20 18 11 80 	mov    -0x7feee7e0(,%eax,4),%eax
80100a69:	89 45 ec             	mov    %eax,-0x14(%ebp)
 char * cmd = history.commands[history.display_command];
80100a6c:	a1 64 20 11 80       	mov    0x80112064,%eax
80100a71:	c1 e0 07             	shl    $0x7,%eax
80100a74:	05 20 18 11 80       	add    $0x80111820,%eax
80100a79:	89 45 f0             	mov    %eax,-0x10(%ebp)
 kill_line();
80100a7c:	e8 82 ff ff ff       	call   80100a03 <kill_line>
 input.e = input.w;
80100a81:	a1 04 18 11 80       	mov    0x80111804,%eax
80100a86:	a3 08 18 11 80       	mov    %eax,0x80111808
 memmove(input.buf + input.w, cmd, size);
80100a8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100a8e:	8b 15 04 18 11 80    	mov    0x80111804,%edx
80100a94:	81 c2 80 17 11 80    	add    $0x80111780,%edx
80100a9a:	89 44 24 08          	mov    %eax,0x8(%esp)
80100a9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100aa1:	89 44 24 04          	mov    %eax,0x4(%esp)
80100aa5:	89 14 24             	mov    %edx,(%esp)
80100aa8:	e8 fd 4c 00 00       	call   801057aa <memmove>
 for (i = 0; i < size; ++i){
80100aad:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100ab4:	eb 1b                	jmp    80100ad1 <display_history+0x86>
   consputc(*cmd++);
80100ab6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100ab9:	8d 50 01             	lea    0x1(%eax),%edx
80100abc:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100abf:	0f b6 00             	movzbl (%eax),%eax
80100ac2:	0f be c0             	movsbl %al,%eax
80100ac5:	89 04 24             	mov    %eax,(%esp)
80100ac8:	e8 fa fd ff ff       	call   801008c7 <consputc>
 int size = history.command_sizes[history.display_command];
 char * cmd = history.commands[history.display_command];
 kill_line();
 input.e = input.w;
 memmove(input.buf + input.w, cmd, size);
 for (i = 0; i < size; ++i){
80100acd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ad4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100ad7:	7c dd                	jl     80100ab6 <display_history+0x6b>
   consputc(*cmd++);
 }
 input.e+=size % INPUT_BUF;
80100ad9:	8b 0d 08 18 11 80    	mov    0x80111808,%ecx
80100adf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ae2:	99                   	cltd   
80100ae3:	c1 ea 19             	shr    $0x19,%edx
80100ae6:	01 d0                	add    %edx,%eax
80100ae8:	83 e0 7f             	and    $0x7f,%eax
80100aeb:	29 d0                	sub    %edx,%eax
80100aed:	01 c8                	add    %ecx,%eax
80100aef:	a3 08 18 11 80       	mov    %eax,0x80111808
}
80100af4:	c9                   	leave  
80100af5:	c3                   	ret    

80100af6 <consoleintr>:
 
void
consoleintr(int (*getc)(void))
{
80100af6:	55                   	push   %ebp
80100af7:	89 e5                	mov    %esp,%ebp
80100af9:	83 ec 28             	sub    $0x28,%esp
  int c, doprocdump = 0;
80100afc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
80100b03:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100b0a:	e8 78 49 00 00       	call   80105487 <acquire>
  while((c = getc()) >= 0){
80100b0f:	e9 35 03 00 00       	jmp    80100e49 <consoleintr+0x353>
    switch(c){
80100b14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100b17:	83 f8 7f             	cmp    $0x7f,%eax
80100b1a:	0f 84 ac 00 00 00    	je     80100bcc <consoleintr+0xd6>
80100b20:	83 f8 7f             	cmp    $0x7f,%eax
80100b23:	7f 18                	jg     80100b3d <consoleintr+0x47>
80100b25:	83 f8 10             	cmp    $0x10,%eax
80100b28:	74 50                	je     80100b7a <consoleintr+0x84>
80100b2a:	83 f8 15             	cmp    $0x15,%eax
80100b2d:	74 72                	je     80100ba1 <consoleintr+0xab>
80100b2f:	83 f8 08             	cmp    $0x8,%eax
80100b32:	0f 84 94 00 00 00    	je     80100bcc <consoleintr+0xd6>
80100b38:	e9 e8 01 00 00       	jmp    80100d25 <consoleintr+0x22f>
80100b3d:	3d e3 00 00 00       	cmp    $0xe3,%eax
80100b42:	0f 84 97 01 00 00    	je     80100cdf <consoleintr+0x1e9>
80100b48:	3d e3 00 00 00       	cmp    $0xe3,%eax
80100b4d:	7f 10                	jg     80100b5f <consoleintr+0x69>
80100b4f:	3d e2 00 00 00       	cmp    $0xe2,%eax
80100b54:	0f 84 51 01 00 00    	je     80100cab <consoleintr+0x1b5>
80100b5a:	e9 c6 01 00 00       	jmp    80100d25 <consoleintr+0x22f>
80100b5f:	3d e4 00 00 00       	cmp    $0xe4,%eax
80100b64:	0f 84 c9 00 00 00    	je     80100c33 <consoleintr+0x13d>
80100b6a:	3d e5 00 00 00       	cmp    $0xe5,%eax
80100b6f:	0f 84 fd 00 00 00    	je     80100c72 <consoleintr+0x17c>
80100b75:	e9 ab 01 00 00       	jmp    80100d25 <consoleintr+0x22f>
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
80100b7a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
80100b81:	e9 c3 02 00 00       	jmp    80100e49 <consoleintr+0x353>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100b86:	a1 08 18 11 80       	mov    0x80111808,%eax
80100b8b:	83 e8 01             	sub    $0x1,%eax
80100b8e:	a3 08 18 11 80       	mov    %eax,0x80111808
        consputc(BACKSPACE);
80100b93:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100b9a:	e8 28 fd ff ff       	call   801008c7 <consputc>
80100b9f:	eb 01                	jmp    80100ba2 <consoleintr+0xac>
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100ba1:	90                   	nop
80100ba2:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100ba8:	a1 04 18 11 80       	mov    0x80111804,%eax
80100bad:	39 c2                	cmp    %eax,%edx
80100baf:	74 16                	je     80100bc7 <consoleintr+0xd1>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100bb1:	a1 08 18 11 80       	mov    0x80111808,%eax
80100bb6:	83 e8 01             	sub    $0x1,%eax
80100bb9:	83 e0 7f             	and    $0x7f,%eax
80100bbc:	0f b6 80 80 17 11 80 	movzbl -0x7feee880(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100bc3:	3c 0a                	cmp    $0xa,%al
80100bc5:	75 bf                	jne    80100b86 <consoleintr+0x90>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100bc7:	e9 7d 02 00 00       	jmp    80100e49 <consoleintr+0x353>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
80100bcc:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100bd2:	a1 04 18 11 80       	mov    0x80111804,%eax
80100bd7:	39 c2                	cmp    %eax,%edx
80100bd9:	74 53                	je     80100c2e <consoleintr+0x138>
        input.e--;
80100bdb:	a1 08 18 11 80       	mov    0x80111808,%eax
80100be0:	83 e8 01             	sub    $0x1,%eax
80100be3:	a3 08 18 11 80       	mov    %eax,0x80111808
        if(left_strides > 0){
80100be8:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100bed:	85 c0                	test   %eax,%eax
80100bef:	7e 2c                	jle    80100c1d <consoleintr+0x127>
         shift_buffer_left(input.buf + input.e,
               input.buf + input.e + left_strides +1);
80100bf1:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100bf7:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100bfc:	01 d0                	add    %edx,%eax
80100bfe:	83 c0 01             	add    $0x1,%eax
      break;
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        if(left_strides > 0){
         shift_buffer_left(input.buf + input.e,
80100c01:	8d 90 80 17 11 80    	lea    -0x7feee880(%eax),%edx
80100c07:	a1 08 18 11 80       	mov    0x80111808,%eax
80100c0c:	05 80 17 11 80       	add    $0x80111780,%eax
80100c11:	89 54 24 04          	mov    %edx,0x4(%esp)
80100c15:	89 04 24             	mov    %eax,(%esp)
80100c18:	e8 df f9 ff ff       	call   801005fc <shift_buffer_left>
               input.buf + input.e + left_strides +1);
              
        }
            consputc(BACKSPACE);
80100c1d:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100c24:	e8 9e fc ff ff       	call   801008c7 <consputc>
      }
      break;
80100c29:	e9 1b 02 00 00       	jmp    80100e49 <consoleintr+0x353>
80100c2e:	e9 16 02 00 00       	jmp    80100e49 <consoleintr+0x353>
     case LEFTARROW: //makeshift left arrow
      if(input.e != input.w) { //we want to shift the buffer to the right
80100c33:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100c39:	a1 04 18 11 80       	mov    0x80111804,%eax
80100c3e:	39 c2                	cmp    %eax,%edx
80100c40:	74 2b                	je     80100c6d <consoleintr+0x177>
       cgaputc(LEFTARROW);
80100c42:	c7 04 24 e4 00 00 00 	movl   $0xe4,(%esp)
80100c49:	e8 e0 f9 ff ff       	call   8010062e <cgaputc>
       ++left_strides;
80100c4e:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100c53:	83 c0 01             	add    $0x1,%eax
80100c56:	a3 f8 c5 10 80       	mov    %eax,0x8010c5f8
       --input.e;
80100c5b:	a1 08 18 11 80       	mov    0x80111808,%eax
80100c60:	83 e8 01             	sub    $0x1,%eax
80100c63:	a3 08 18 11 80       	mov    %eax,0x80111808
      }
      break;
80100c68:	e9 dc 01 00 00       	jmp    80100e49 <consoleintr+0x353>
80100c6d:	e9 d7 01 00 00       	jmp    80100e49 <consoleintr+0x353>
     case RIGHTARROW:
      if(left_strides > 0) {
80100c72:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100c77:	85 c0                	test   %eax,%eax
80100c79:	7e 2b                	jle    80100ca6 <consoleintr+0x1b0>
        cgaputc(RIGHTARROW);
80100c7b:	c7 04 24 e5 00 00 00 	movl   $0xe5,(%esp)
80100c82:	e8 a7 f9 ff ff       	call   8010062e <cgaputc>
        --left_strides;
80100c87:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100c8c:	83 e8 01             	sub    $0x1,%eax
80100c8f:	a3 f8 c5 10 80       	mov    %eax,0x8010c5f8
        ++input.e;
80100c94:	a1 08 18 11 80       	mov    0x80111808,%eax
80100c99:	83 c0 01             	add    $0x1,%eax
80100c9c:	a3 08 18 11 80       	mov    %eax,0x80111808
      }
      break;
80100ca1:	e9 a3 01 00 00       	jmp    80100e49 <consoleintr+0x353>
80100ca6:	e9 9e 01 00 00       	jmp    80100e49 <consoleintr+0x353>
     case KEY_UP: 
       if(history.lastcommand > 0) {
80100cab:	a1 60 20 11 80       	mov    0x80112060,%eax
80100cb0:	85 c0                	test   %eax,%eax
80100cb2:	7e 26                	jle    80100cda <consoleintr+0x1e4>
           display_history();
80100cb4:	e8 92 fd ff ff       	call   80100a4b <display_history>
	   history.display_command -= (history.display_command) ? 1 :0;
80100cb9:	8b 15 64 20 11 80    	mov    0x80112064,%edx
80100cbf:	a1 64 20 11 80       	mov    0x80112064,%eax
80100cc4:	85 c0                	test   %eax,%eax
80100cc6:	0f 95 c0             	setne  %al
80100cc9:	0f b6 c0             	movzbl %al,%eax
80100ccc:	29 c2                	sub    %eax,%edx
80100cce:	89 d0                	mov    %edx,%eax
80100cd0:	a3 64 20 11 80       	mov    %eax,0x80112064
       }
     break;
80100cd5:	e9 6f 01 00 00       	jmp    80100e49 <consoleintr+0x353>
80100cda:	e9 6a 01 00 00       	jmp    80100e49 <consoleintr+0x353>
     case KEY_DN: 
	if((history.lastcommand - history.display_command ) > 1) {
80100cdf:	8b 15 60 20 11 80    	mov    0x80112060,%edx
80100ce5:	a1 64 20 11 80       	mov    0x80112064,%eax
80100cea:	29 c2                	sub    %eax,%edx
80100cec:	89 d0                	mov    %edx,%eax
80100cee:	83 f8 01             	cmp    $0x1,%eax
80100cf1:	7e 14                	jle    80100d07 <consoleintr+0x211>
	 ++history.display_command;
80100cf3:	a1 64 20 11 80       	mov    0x80112064,%eax
80100cf8:	83 c0 01             	add    $0x1,%eax
80100cfb:	a3 64 20 11 80       	mov    %eax,0x80112064
	 display_history();
80100d00:	e8 46 fd ff ff       	call   80100a4b <display_history>
80100d05:	eb 19                	jmp    80100d20 <consoleintr+0x22a>
	}
	else if (history.lastcommand > history.display_command)
80100d07:	8b 15 60 20 11 80    	mov    0x80112060,%edx
80100d0d:	a1 64 20 11 80       	mov    0x80112064,%eax
80100d12:	39 c2                	cmp    %eax,%edx
80100d14:	7e 0a                	jle    80100d20 <consoleintr+0x22a>
	  kill_line();
80100d16:	e8 e8 fc ff ff       	call   80100a03 <kill_line>
     break;
80100d1b:	e9 29 01 00 00       	jmp    80100e49 <consoleintr+0x353>
80100d20:	e9 24 01 00 00       	jmp    80100e49 <consoleintr+0x353>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100d25:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100d29:	0f 84 19 01 00 00    	je     80100e48 <consoleintr+0x352>
80100d2f:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100d35:	a1 00 18 11 80       	mov    0x80111800,%eax
80100d3a:	29 c2                	sub    %eax,%edx
80100d3c:	89 d0                	mov    %edx,%eax
80100d3e:	83 f8 7f             	cmp    $0x7f,%eax
80100d41:	0f 87 01 01 00 00    	ja     80100e48 <consoleintr+0x352>
        c = (c == '\r') ? '\n' : c;
80100d47:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80100d4b:	74 05                	je     80100d52 <consoleintr+0x25c>
80100d4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100d50:	eb 05                	jmp    80100d57 <consoleintr+0x261>
80100d52:	b8 0a 00 00 00       	mov    $0xa,%eax
80100d57:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if('\n' == c){  // if we press enter we want the whole buffer to be
80100d5a:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100d5e:	75 4f                	jne    80100daf <consoleintr+0x2b9>
          input.e = (input.e + left_strides) % INPUT_BUF;
80100d60:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100d66:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100d6b:	01 d0                	add    %edx,%eax
80100d6d:	83 e0 7f             	and    $0x7f,%eax
80100d70:	a3 08 18 11 80       	mov    %eax,0x80111808
           if(input.e != input.w) 
80100d75:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100d7b:	a1 04 18 11 80       	mov    0x80111804,%eax
80100d80:	39 c2                	cmp    %eax,%edx
80100d82:	74 21                	je     80100da5 <consoleintr+0x2af>
	     add_to_history(input.buf + input.w,
               input.buf + input.e);
80100d84:	a1 08 18 11 80       	mov    0x80111808,%eax
      if(c != 0 && input.e-input.r < INPUT_BUF){
        c = (c == '\r') ? '\n' : c;
        if('\n' == c){  // if we press enter we want the whole buffer to be
          input.e = (input.e + left_strides) % INPUT_BUF;
           if(input.e != input.w) 
	     add_to_history(input.buf + input.w,
80100d89:	8d 90 80 17 11 80    	lea    -0x7feee880(%eax),%edx
80100d8f:	a1 04 18 11 80       	mov    0x80111804,%eax
80100d94:	05 80 17 11 80       	add    $0x80111780,%eax
80100d99:	89 54 24 04          	mov    %edx,0x4(%esp)
80100d9d:	89 04 24             	mov    %eax,(%esp)
80100da0:	e8 91 fb ff ff       	call   80100936 <add_to_history>
               input.buf + input.e);
            left_strides  = 0;
80100da5:	c7 05 f8 c5 10 80 00 	movl   $0x0,0x8010c5f8
80100dac:	00 00 00 
        }
       
        if (left_strides > 0) { //if we've taken a left and then we write.
80100daf:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100db4:	85 c0                	test   %eax,%eax
80100db6:	7e 29                	jle    80100de1 <consoleintr+0x2eb>
          shift_buffer_right(input.buf + input.e,
               input.buf + input.e + left_strides);
80100db8:	8b 15 08 18 11 80    	mov    0x80111808,%edx
80100dbe:	a1 f8 c5 10 80       	mov    0x8010c5f8,%eax
80100dc3:	01 d0                	add    %edx,%eax
               input.buf + input.e);
            left_strides  = 0;
        }
       
        if (left_strides > 0) { //if we've taken a left and then we write.
          shift_buffer_right(input.buf + input.e,
80100dc5:	8d 90 80 17 11 80    	lea    -0x7feee880(%eax),%edx
80100dcb:	a1 08 18 11 80       	mov    0x80111808,%eax
80100dd0:	05 80 17 11 80       	add    $0x80111780,%eax
80100dd5:	89 54 24 04          	mov    %edx,0x4(%esp)
80100dd9:	89 04 24             	mov    %eax,(%esp)
80100ddc:	e8 e9 f7 ff ff       	call   801005ca <shift_buffer_right>
               input.buf + input.e + left_strides);
        }
        input.buf[input.e++ % INPUT_BUF] = c;
80100de1:	a1 08 18 11 80       	mov    0x80111808,%eax
80100de6:	8d 50 01             	lea    0x1(%eax),%edx
80100de9:	89 15 08 18 11 80    	mov    %edx,0x80111808
80100def:	83 e0 7f             	and    $0x7f,%eax
80100df2:	89 c2                	mov    %eax,%edx
80100df4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100df7:	88 82 80 17 11 80    	mov    %al,-0x7feee880(%edx)
        consputc(c);
80100dfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e00:	89 04 24             	mov    %eax,(%esp)
80100e03:	e8 bf fa ff ff       	call   801008c7 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
80100e08:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100e0c:	74 18                	je     80100e26 <consoleintr+0x330>
80100e0e:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100e12:	74 12                	je     80100e26 <consoleintr+0x330>
80100e14:	a1 08 18 11 80       	mov    0x80111808,%eax
80100e19:	8b 15 00 18 11 80    	mov    0x80111800,%edx
80100e1f:	83 ea 80             	sub    $0xffffff80,%edx
80100e22:	39 d0                	cmp    %edx,%eax
80100e24:	75 22                	jne    80100e48 <consoleintr+0x352>
          left_strides = 0;
80100e26:	c7 05 f8 c5 10 80 00 	movl   $0x0,0x8010c5f8
80100e2d:	00 00 00 
          input.w = input.e;
80100e30:	a1 08 18 11 80       	mov    0x80111808,%eax
80100e35:	a3 04 18 11 80       	mov    %eax,0x80111804
          wakeup(&input.r);
80100e3a:	c7 04 24 00 18 11 80 	movl   $0x80111800,(%esp)
80100e41:	e8 50 44 00 00       	call   80105296 <wakeup>
        }
      }
        break;
80100e46:	eb 00                	jmp    80100e48 <consoleintr+0x352>
80100e48:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c, doprocdump = 0;

  acquire(&cons.lock);
  while((c = getc()) >= 0){
80100e49:	8b 45 08             	mov    0x8(%ebp),%eax
80100e4c:	ff d0                	call   *%eax
80100e4e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e51:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100e55:	0f 89 b9 fc ff ff    	jns    80100b14 <consoleintr+0x1e>
        }
      }
        break;
      }
  }
  release(&cons.lock);
80100e5b:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100e62:	e8 82 46 00 00       	call   801054e9 <release>
  if(doprocdump) {
80100e67:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100e6b:	74 05                	je     80100e72 <consoleintr+0x37c>
        procdump();  // now call procdump() wo. cons.lock held
80100e6d:	e8 c7 44 00 00       	call   80105339 <procdump>
      }
}
80100e72:	c9                   	leave  
80100e73:	c3                   	ret    

80100e74 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100e74:	55                   	push   %ebp
80100e75:	89 e5                	mov    %esp,%ebp
80100e77:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;
  iunlock(ip);
80100e7a:	8b 45 08             	mov    0x8(%ebp),%eax
80100e7d:	89 04 24             	mov    %eax,(%esp)
80100e80:	e8 86 11 00 00       	call   8010200b <iunlock>
  target = n;
80100e85:	8b 45 10             	mov    0x10(%ebp),%eax
80100e88:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
80100e8b:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100e92:	e8 f0 45 00 00       	call   80105487 <acquire>
  while(n > 0){
80100e97:	e9 aa 00 00 00       	jmp    80100f46 <consoleread+0xd2>
    while(input.r == input.w){
80100e9c:	eb 42                	jmp    80100ee0 <consoleread+0x6c>
      if(proc->killed){
80100e9e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea4:	8b 40 24             	mov    0x24(%eax),%eax
80100ea7:	85 c0                	test   %eax,%eax
80100ea9:	74 21                	je     80100ecc <consoleread+0x58>
        release(&cons.lock);
80100eab:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100eb2:	e8 32 46 00 00       	call   801054e9 <release>
        ilock(ip);
80100eb7:	8b 45 08             	mov    0x8(%ebp),%eax
80100eba:	89 04 24             	mov    %eax,(%esp)
80100ebd:	e8 f5 0f 00 00       	call   80101eb7 <ilock>
        return -1;
80100ec2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100ec7:	e9 a5 00 00 00       	jmp    80100f71 <consoleread+0xfd>
      }
      sleep(&input.r, &cons.lock);
80100ecc:	c7 44 24 04 c0 c5 10 	movl   $0x8010c5c0,0x4(%esp)
80100ed3:	80 
80100ed4:	c7 04 24 00 18 11 80 	movl   $0x80111800,(%esp)
80100edb:	e8 dd 42 00 00       	call   801051bd <sleep>
  int c;
  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
    while(input.r == input.w){
80100ee0:	8b 15 00 18 11 80    	mov    0x80111800,%edx
80100ee6:	a1 04 18 11 80       	mov    0x80111804,%eax
80100eeb:	39 c2                	cmp    %eax,%edx
80100eed:	74 af                	je     80100e9e <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100eef:	a1 00 18 11 80       	mov    0x80111800,%eax
80100ef4:	8d 50 01             	lea    0x1(%eax),%edx
80100ef7:	89 15 00 18 11 80    	mov    %edx,0x80111800
80100efd:	83 e0 7f             	and    $0x7f,%eax
80100f00:	0f b6 80 80 17 11 80 	movzbl -0x7feee880(%eax),%eax
80100f07:	0f be c0             	movsbl %al,%eax
80100f0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
80100f0d:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100f11:	75 19                	jne    80100f2c <consoleread+0xb8>
      if(n < target){
80100f13:	8b 45 10             	mov    0x10(%ebp),%eax
80100f16:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80100f19:	73 0f                	jae    80100f2a <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
80100f1b:	a1 00 18 11 80       	mov    0x80111800,%eax
80100f20:	83 e8 01             	sub    $0x1,%eax
80100f23:	a3 00 18 11 80       	mov    %eax,0x80111800
      }
      break;
80100f28:	eb 26                	jmp    80100f50 <consoleread+0xdc>
80100f2a:	eb 24                	jmp    80100f50 <consoleread+0xdc>
    }
    *dst++ = c;
80100f2c:	8b 45 0c             	mov    0xc(%ebp),%eax
80100f2f:	8d 50 01             	lea    0x1(%eax),%edx
80100f32:	89 55 0c             	mov    %edx,0xc(%ebp)
80100f35:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100f38:	88 10                	mov    %dl,(%eax)
    --n;
80100f3a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100f3e:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100f42:	75 02                	jne    80100f46 <consoleread+0xd2>
      break;
80100f44:	eb 0a                	jmp    80100f50 <consoleread+0xdc>
  uint target;
  int c;
  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
80100f46:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100f4a:	0f 8f 4c ff ff ff    	jg     80100e9c <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&cons.lock);
80100f50:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100f57:	e8 8d 45 00 00       	call   801054e9 <release>
  ilock(ip);
80100f5c:	8b 45 08             	mov    0x8(%ebp),%eax
80100f5f:	89 04 24             	mov    %eax,(%esp)
80100f62:	e8 50 0f 00 00       	call   80101eb7 <ilock>

  return target - n;
80100f67:	8b 45 10             	mov    0x10(%ebp),%eax
80100f6a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100f6d:	29 c2                	sub    %eax,%edx
80100f6f:	89 d0                	mov    %edx,%eax
}
80100f71:	c9                   	leave  
80100f72:	c3                   	ret    

80100f73 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100f73:	55                   	push   %ebp
80100f74:	89 e5                	mov    %esp,%ebp
80100f76:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100f79:	8b 45 08             	mov    0x8(%ebp),%eax
80100f7c:	89 04 24             	mov    %eax,(%esp)
80100f7f:	e8 87 10 00 00       	call   8010200b <iunlock>
  acquire(&cons.lock);
80100f84:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100f8b:	e8 f7 44 00 00       	call   80105487 <acquire>
  for(i = 0; i < n; i++)
80100f90:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100f97:	eb 1d                	jmp    80100fb6 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100f99:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100f9c:	8b 45 0c             	mov    0xc(%ebp),%eax
80100f9f:	01 d0                	add    %edx,%eax
80100fa1:	0f b6 00             	movzbl (%eax),%eax
80100fa4:	0f be c0             	movsbl %al,%eax
80100fa7:	0f b6 c0             	movzbl %al,%eax
80100faa:	89 04 24             	mov    %eax,(%esp)
80100fad:	e8 15 f9 ff ff       	call   801008c7 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100fb2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100fb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100fb9:	3b 45 10             	cmp    0x10(%ebp),%eax
80100fbc:	7c db                	jl     80100f99 <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100fbe:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100fc5:	e8 1f 45 00 00       	call   801054e9 <release>
  ilock(ip);
80100fca:	8b 45 08             	mov    0x8(%ebp),%eax
80100fcd:	89 04 24             	mov    %eax,(%esp)
80100fd0:	e8 e2 0e 00 00       	call   80101eb7 <ilock>

  return n;
80100fd5:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100fd8:	c9                   	leave  
80100fd9:	c3                   	ret    

80100fda <consoleinit>:

void
consoleinit(void)
{
80100fda:	55                   	push   %ebp
80100fdb:	89 e5                	mov    %esp,%ebp
80100fdd:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100fe0:	c7 44 24 04 ae 8a 10 	movl   $0x80108aae,0x4(%esp)
80100fe7:	80 
80100fe8:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100fef:	e8 72 44 00 00       	call   80105466 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100ff4:	c7 05 2c 2a 11 80 73 	movl   $0x80100f73,0x80112a2c
80100ffb:	0f 10 80 
  devsw[CONSOLE].read = consoleread;
80100ffe:	c7 05 28 2a 11 80 74 	movl   $0x80100e74,0x80112a28
80101005:	0e 10 80 
  cons.locking = 1;
80101008:	c7 05 f4 c5 10 80 01 	movl   $0x1,0x8010c5f4
8010100f:	00 00 00 

  picenable(IRQ_KBD);
80101012:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101019:	e8 20 34 00 00       	call   8010443e <picenable>
  ioapicenable(IRQ_KBD, 0);
8010101e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101025:	00 
80101026:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010102d:	e8 c4 1f 00 00       	call   80102ff6 <ioapicenable>
}
80101032:	c9                   	leave  
80101033:	c3                   	ret    

80101034 <sys_history>:

// This is the implementation of sys_history huzzah
int 
sys_history(void) {
80101034:	55                   	push   %ebp
80101035:	89 e5                	mov    %esp,%ebp
80101037:	83 ec 28             	sub    $0x28,%esp
  char * buffer; 
  int index;

  if(argstr(0, &buffer) < 0 || argint(1, &index)) 
8010103a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010103d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101041:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80101048:	e8 60 4a 00 00       	call   80105aad <argstr>
8010104d:	85 c0                	test   %eax,%eax
8010104f:	78 17                	js     80101068 <sys_history+0x34>
80101051:	8d 45 f0             	lea    -0x10(%ebp),%eax
80101054:	89 44 24 04          	mov    %eax,0x4(%esp)
80101058:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010105f:	e8 b9 49 00 00       	call   80105a1d <argint>
80101064:	85 c0                	test   %eax,%eax
80101066:	74 07                	je     8010106f <sys_history+0x3b>
    return -1;
80101068:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010106d:	eb 7c                	jmp    801010eb <sys_history+0xb7>
  if(index >= history.lastcommand && index < INPUT_BUF)
8010106f:	8b 15 60 20 11 80    	mov    0x80112060,%edx
80101075:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101078:	39 c2                	cmp    %eax,%edx
8010107a:	7f 0f                	jg     8010108b <sys_history+0x57>
8010107c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010107f:	83 f8 7f             	cmp    $0x7f,%eax
80101082:	7f 07                	jg     8010108b <sys_history+0x57>
    return -2;
80101084:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
80101089:	eb 60                	jmp    801010eb <sys_history+0xb7>
  else if (index > history.lastcommand) 
8010108b:	8b 15 60 20 11 80    	mov    0x80112060,%edx
80101091:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101094:	39 c2                	cmp    %eax,%edx
80101096:	7d 07                	jge    8010109f <sys_history+0x6b>
    return -1;
80101098:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010109d:	eb 4c                	jmp    801010eb <sys_history+0xb7>
  memmove(buffer, history.commands[index], history.command_sizes[index]);
8010109f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010a2:	05 00 02 00 00       	add    $0x200,%eax
801010a7:	8b 04 85 20 18 11 80 	mov    -0x7feee7e0(,%eax,4),%eax
801010ae:	89 c2                	mov    %eax,%edx
801010b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010b3:	c1 e0 07             	shl    $0x7,%eax
801010b6:	8d 88 20 18 11 80    	lea    -0x7feee7e0(%eax),%ecx
801010bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801010bf:	89 54 24 08          	mov    %edx,0x8(%esp)
801010c3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801010c7:	89 04 24             	mov    %eax,(%esp)
801010ca:	e8 db 46 00 00       	call   801057aa <memmove>
  buffer[history.command_sizes[index]] = 0;
801010cf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801010d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010d5:	05 00 02 00 00       	add    $0x200,%eax
801010da:	8b 04 85 20 18 11 80 	mov    -0x7feee7e0(,%eax,4),%eax
801010e1:	01 d0                	add    %edx,%eax
801010e3:	c6 00 00             	movb   $0x0,(%eax)
  return 0;
801010e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801010eb:	c9                   	leave  
801010ec:	c3                   	ret    

801010ed <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801010ed:	55                   	push   %ebp
801010ee:	89 e5                	mov    %esp,%ebp
801010f0:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
801010f6:	e8 a4 29 00 00       	call   80103a9f <begin_op>
  if((ip = namei(path)) == 0){
801010fb:	8b 45 08             	mov    0x8(%ebp),%eax
801010fe:	89 04 24             	mov    %eax,(%esp)
80101101:	e8 62 19 00 00       	call   80102a68 <namei>
80101106:	89 45 d8             	mov    %eax,-0x28(%ebp)
80101109:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
8010110d:	75 0f                	jne    8010111e <exec+0x31>
    end_op();
8010110f:	e8 0f 2a 00 00       	call   80103b23 <end_op>
    return -1;
80101114:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101119:	e9 e8 03 00 00       	jmp    80101506 <exec+0x419>
  }
  ilock(ip);
8010111e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101121:	89 04 24             	mov    %eax,(%esp)
80101124:	e8 8e 0d 00 00       	call   80101eb7 <ilock>
  pgdir = 0;
80101129:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80101130:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80101137:	00 
80101138:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010113f:	00 
80101140:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80101146:	89 44 24 04          	mov    %eax,0x4(%esp)
8010114a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010114d:	89 04 24             	mov    %eax,(%esp)
80101150:	e8 75 12 00 00       	call   801023ca <readi>
80101155:	83 f8 33             	cmp    $0x33,%eax
80101158:	77 05                	ja     8010115f <exec+0x72>
    goto bad;
8010115a:	e9 7b 03 00 00       	jmp    801014da <exec+0x3ed>
  if(elf.magic != ELF_MAGIC)
8010115f:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80101165:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
8010116a:	74 05                	je     80101171 <exec+0x84>
    goto bad;
8010116c:	e9 69 03 00 00       	jmp    801014da <exec+0x3ed>

  if((pgdir = setupkvm()) == 0)
80101171:	e8 6d 70 00 00       	call   801081e3 <setupkvm>
80101176:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80101179:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
8010117d:	75 05                	jne    80101184 <exec+0x97>
    goto bad;
8010117f:	e9 56 03 00 00       	jmp    801014da <exec+0x3ed>

  // Load program into memory.
  sz = 0;
80101184:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
8010118b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101192:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80101198:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010119b:	e9 cb 00 00 00       	jmp    8010126b <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801011a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801011a3:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
801011aa:	00 
801011ab:	89 44 24 08          	mov    %eax,0x8(%esp)
801011af:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
801011b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801011b9:	8b 45 d8             	mov    -0x28(%ebp),%eax
801011bc:	89 04 24             	mov    %eax,(%esp)
801011bf:	e8 06 12 00 00       	call   801023ca <readi>
801011c4:	83 f8 20             	cmp    $0x20,%eax
801011c7:	74 05                	je     801011ce <exec+0xe1>
      goto bad;
801011c9:	e9 0c 03 00 00       	jmp    801014da <exec+0x3ed>
    if(ph.type != ELF_PROG_LOAD)
801011ce:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
801011d4:	83 f8 01             	cmp    $0x1,%eax
801011d7:	74 05                	je     801011de <exec+0xf1>
      continue;
801011d9:	e9 80 00 00 00       	jmp    8010125e <exec+0x171>
    if(ph.memsz < ph.filesz)
801011de:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
801011e4:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
801011ea:	39 c2                	cmp    %eax,%edx
801011ec:	73 05                	jae    801011f3 <exec+0x106>
      goto bad;
801011ee:	e9 e7 02 00 00       	jmp    801014da <exec+0x3ed>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801011f3:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
801011f9:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
801011ff:	01 d0                	add    %edx,%eax
80101201:	89 44 24 08          	mov    %eax,0x8(%esp)
80101205:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101208:	89 44 24 04          	mov    %eax,0x4(%esp)
8010120c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010120f:	89 04 24             	mov    %eax,(%esp)
80101212:	e8 9a 73 00 00       	call   801085b1 <allocuvm>
80101217:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010121a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010121e:	75 05                	jne    80101225 <exec+0x138>
      goto bad;
80101220:	e9 b5 02 00 00       	jmp    801014da <exec+0x3ed>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80101225:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
8010122b:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80101231:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80101237:	89 4c 24 10          	mov    %ecx,0x10(%esp)
8010123b:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010123f:	8b 55 d8             	mov    -0x28(%ebp),%edx
80101242:	89 54 24 08          	mov    %edx,0x8(%esp)
80101246:	89 44 24 04          	mov    %eax,0x4(%esp)
8010124a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010124d:	89 04 24             	mov    %eax,(%esp)
80101250:	e8 71 72 00 00       	call   801084c6 <loaduvm>
80101255:	85 c0                	test   %eax,%eax
80101257:	79 05                	jns    8010125e <exec+0x171>
      goto bad;
80101259:	e9 7c 02 00 00       	jmp    801014da <exec+0x3ed>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
8010125e:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80101262:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101265:	83 c0 20             	add    $0x20,%eax
80101268:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010126b:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80101272:	0f b7 c0             	movzwl %ax,%eax
80101275:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101278:	0f 8f 22 ff ff ff    	jg     801011a0 <exec+0xb3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
8010127e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101281:	89 04 24             	mov    %eax,(%esp)
80101284:	e8 b8 0e 00 00       	call   80102141 <iunlockput>
  end_op();
80101289:	e8 95 28 00 00       	call   80103b23 <end_op>
  ip = 0;
8010128e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80101295:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101298:	05 ff 0f 00 00       	add    $0xfff,%eax
8010129d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801012a2:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
801012a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801012a8:	05 00 20 00 00       	add    $0x2000,%eax
801012ad:	89 44 24 08          	mov    %eax,0x8(%esp)
801012b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801012b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801012b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801012bb:	89 04 24             	mov    %eax,(%esp)
801012be:	e8 ee 72 00 00       	call   801085b1 <allocuvm>
801012c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
801012c6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801012ca:	75 05                	jne    801012d1 <exec+0x1e4>
    goto bad;
801012cc:	e9 09 02 00 00       	jmp    801014da <exec+0x3ed>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
801012d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801012d4:	2d 00 20 00 00       	sub    $0x2000,%eax
801012d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801012dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801012e0:	89 04 24             	mov    %eax,(%esp)
801012e3:	e8 f9 74 00 00       	call   801087e1 <clearpteu>
  sp = sz;
801012e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801012eb:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
801012ee:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801012f5:	e9 9a 00 00 00       	jmp    80101394 <exec+0x2a7>
    if(argc >= MAXARG)
801012fa:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
801012fe:	76 05                	jbe    80101305 <exec+0x218>
      goto bad;
80101300:	e9 d5 01 00 00       	jmp    801014da <exec+0x3ed>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80101305:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101308:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010130f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101312:	01 d0                	add    %edx,%eax
80101314:	8b 00                	mov    (%eax),%eax
80101316:	89 04 24             	mov    %eax,(%esp)
80101319:	e8 27 46 00 00       	call   80105945 <strlen>
8010131e:	8b 55 dc             	mov    -0x24(%ebp),%edx
80101321:	29 c2                	sub    %eax,%edx
80101323:	89 d0                	mov    %edx,%eax
80101325:	83 e8 01             	sub    $0x1,%eax
80101328:	83 e0 fc             	and    $0xfffffffc,%eax
8010132b:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
8010132e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101331:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101338:	8b 45 0c             	mov    0xc(%ebp),%eax
8010133b:	01 d0                	add    %edx,%eax
8010133d:	8b 00                	mov    (%eax),%eax
8010133f:	89 04 24             	mov    %eax,(%esp)
80101342:	e8 fe 45 00 00       	call   80105945 <strlen>
80101347:	83 c0 01             	add    $0x1,%eax
8010134a:	89 c2                	mov    %eax,%edx
8010134c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010134f:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80101356:	8b 45 0c             	mov    0xc(%ebp),%eax
80101359:	01 c8                	add    %ecx,%eax
8010135b:	8b 00                	mov    (%eax),%eax
8010135d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80101361:	89 44 24 08          	mov    %eax,0x8(%esp)
80101365:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101368:	89 44 24 04          	mov    %eax,0x4(%esp)
8010136c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010136f:	89 04 24             	mov    %eax,(%esp)
80101372:	e8 2f 76 00 00       	call   801089a6 <copyout>
80101377:	85 c0                	test   %eax,%eax
80101379:	79 05                	jns    80101380 <exec+0x293>
      goto bad;
8010137b:	e9 5a 01 00 00       	jmp    801014da <exec+0x3ed>
    ustack[3+argc] = sp;
80101380:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101383:	8d 50 03             	lea    0x3(%eax),%edx
80101386:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101389:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80101390:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80101394:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101397:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010139e:	8b 45 0c             	mov    0xc(%ebp),%eax
801013a1:	01 d0                	add    %edx,%eax
801013a3:	8b 00                	mov    (%eax),%eax
801013a5:	85 c0                	test   %eax,%eax
801013a7:	0f 85 4d ff ff ff    	jne    801012fa <exec+0x20d>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
801013ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013b0:	83 c0 03             	add    $0x3,%eax
801013b3:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
801013ba:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
801013be:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
801013c5:	ff ff ff 
  ustack[1] = argc;
801013c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013cb:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
801013d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013d4:	83 c0 01             	add    $0x1,%eax
801013d7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801013de:	8b 45 dc             	mov    -0x24(%ebp),%eax
801013e1:	29 d0                	sub    %edx,%eax
801013e3:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
801013e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013ec:	83 c0 04             	add    $0x4,%eax
801013ef:	c1 e0 02             	shl    $0x2,%eax
801013f2:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
801013f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013f8:	83 c0 04             	add    $0x4,%eax
801013fb:	c1 e0 02             	shl    $0x2,%eax
801013fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101402:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80101408:	89 44 24 08          	mov    %eax,0x8(%esp)
8010140c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010140f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101413:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101416:	89 04 24             	mov    %eax,(%esp)
80101419:	e8 88 75 00 00       	call   801089a6 <copyout>
8010141e:	85 c0                	test   %eax,%eax
80101420:	79 05                	jns    80101427 <exec+0x33a>
    goto bad;
80101422:	e9 b3 00 00 00       	jmp    801014da <exec+0x3ed>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80101427:	8b 45 08             	mov    0x8(%ebp),%eax
8010142a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010142d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101430:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101433:	eb 17                	jmp    8010144c <exec+0x35f>
    if(*s == '/')
80101435:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101438:	0f b6 00             	movzbl (%eax),%eax
8010143b:	3c 2f                	cmp    $0x2f,%al
8010143d:	75 09                	jne    80101448 <exec+0x35b>
      last = s+1;
8010143f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101442:	83 c0 01             	add    $0x1,%eax
80101445:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80101448:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010144c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010144f:	0f b6 00             	movzbl (%eax),%eax
80101452:	84 c0                	test   %al,%al
80101454:	75 df                	jne    80101435 <exec+0x348>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80101456:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010145c:	8d 50 6c             	lea    0x6c(%eax),%edx
8010145f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101466:	00 
80101467:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010146a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010146e:	89 14 24             	mov    %edx,(%esp)
80101471:	e8 85 44 00 00       	call   801058fb <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80101476:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010147c:	8b 40 04             	mov    0x4(%eax),%eax
8010147f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80101482:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101488:	8b 55 d4             	mov    -0x2c(%ebp),%edx
8010148b:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
8010148e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101494:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101497:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80101499:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010149f:	8b 40 18             	mov    0x18(%eax),%eax
801014a2:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
801014a8:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
801014ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014b1:	8b 40 18             	mov    0x18(%eax),%eax
801014b4:	8b 55 dc             	mov    -0x24(%ebp),%edx
801014b7:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
801014ba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014c0:	89 04 24             	mov    %eax,(%esp)
801014c3:	e8 0c 6e 00 00       	call   801082d4 <switchuvm>
  freevm(oldpgdir);
801014c8:	8b 45 d0             	mov    -0x30(%ebp),%eax
801014cb:	89 04 24             	mov    %eax,(%esp)
801014ce:	e8 74 72 00 00       	call   80108747 <freevm>
  return 0;
801014d3:	b8 00 00 00 00       	mov    $0x0,%eax
801014d8:	eb 2c                	jmp    80101506 <exec+0x419>

 bad:
  if(pgdir)
801014da:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
801014de:	74 0b                	je     801014eb <exec+0x3fe>
    freevm(pgdir);
801014e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801014e3:	89 04 24             	mov    %eax,(%esp)
801014e6:	e8 5c 72 00 00       	call   80108747 <freevm>
  if(ip){
801014eb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
801014ef:	74 10                	je     80101501 <exec+0x414>
    iunlockput(ip);
801014f1:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014f4:	89 04 24             	mov    %eax,(%esp)
801014f7:	e8 45 0c 00 00       	call   80102141 <iunlockput>
    end_op();
801014fc:	e8 22 26 00 00       	call   80103b23 <end_op>
  }
  return -1;
80101501:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101506:	c9                   	leave  
80101507:	c3                   	ret    

80101508 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80101508:	55                   	push   %ebp
80101509:	89 e5                	mov    %esp,%ebp
8010150b:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
8010150e:	c7 44 24 04 b6 8a 10 	movl   $0x80108ab6,0x4(%esp)
80101515:	80 
80101516:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
8010151d:	e8 44 3f 00 00       	call   80105466 <initlock>
}
80101522:	c9                   	leave  
80101523:	c3                   	ret    

80101524 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101524:	55                   	push   %ebp
80101525:	89 e5                	mov    %esp,%ebp
80101527:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
8010152a:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
80101531:	e8 51 3f 00 00       	call   80105487 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101536:	c7 45 f4 b4 20 11 80 	movl   $0x801120b4,-0xc(%ebp)
8010153d:	eb 29                	jmp    80101568 <filealloc+0x44>
    if(f->ref == 0){
8010153f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101542:	8b 40 04             	mov    0x4(%eax),%eax
80101545:	85 c0                	test   %eax,%eax
80101547:	75 1b                	jne    80101564 <filealloc+0x40>
      f->ref = 1;
80101549:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010154c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80101553:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
8010155a:	e8 8a 3f 00 00       	call   801054e9 <release>
      return f;
8010155f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101562:	eb 1e                	jmp    80101582 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101564:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80101568:	81 7d f4 14 2a 11 80 	cmpl   $0x80112a14,-0xc(%ebp)
8010156f:	72 ce                	jb     8010153f <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80101571:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
80101578:	e8 6c 3f 00 00       	call   801054e9 <release>
  return 0;
8010157d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101582:	c9                   	leave  
80101583:	c3                   	ret    

80101584 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80101584:	55                   	push   %ebp
80101585:	89 e5                	mov    %esp,%ebp
80101587:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
8010158a:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
80101591:	e8 f1 3e 00 00       	call   80105487 <acquire>
  if(f->ref < 1)
80101596:	8b 45 08             	mov    0x8(%ebp),%eax
80101599:	8b 40 04             	mov    0x4(%eax),%eax
8010159c:	85 c0                	test   %eax,%eax
8010159e:	7f 0c                	jg     801015ac <filedup+0x28>
    panic("filedup");
801015a0:	c7 04 24 bd 8a 10 80 	movl   $0x80108abd,(%esp)
801015a7:	e8 8e ef ff ff       	call   8010053a <panic>
  f->ref++;
801015ac:	8b 45 08             	mov    0x8(%ebp),%eax
801015af:	8b 40 04             	mov    0x4(%eax),%eax
801015b2:	8d 50 01             	lea    0x1(%eax),%edx
801015b5:	8b 45 08             	mov    0x8(%ebp),%eax
801015b8:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801015bb:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
801015c2:	e8 22 3f 00 00       	call   801054e9 <release>
  return f;
801015c7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801015ca:	c9                   	leave  
801015cb:	c3                   	ret    

801015cc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801015cc:	55                   	push   %ebp
801015cd:	89 e5                	mov    %esp,%ebp
801015cf:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
801015d2:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
801015d9:	e8 a9 3e 00 00       	call   80105487 <acquire>
  if(f->ref < 1)
801015de:	8b 45 08             	mov    0x8(%ebp),%eax
801015e1:	8b 40 04             	mov    0x4(%eax),%eax
801015e4:	85 c0                	test   %eax,%eax
801015e6:	7f 0c                	jg     801015f4 <fileclose+0x28>
    panic("fileclose");
801015e8:	c7 04 24 c5 8a 10 80 	movl   $0x80108ac5,(%esp)
801015ef:	e8 46 ef ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
801015f4:	8b 45 08             	mov    0x8(%ebp),%eax
801015f7:	8b 40 04             	mov    0x4(%eax),%eax
801015fa:	8d 50 ff             	lea    -0x1(%eax),%edx
801015fd:	8b 45 08             	mov    0x8(%ebp),%eax
80101600:	89 50 04             	mov    %edx,0x4(%eax)
80101603:	8b 45 08             	mov    0x8(%ebp),%eax
80101606:	8b 40 04             	mov    0x4(%eax),%eax
80101609:	85 c0                	test   %eax,%eax
8010160b:	7e 11                	jle    8010161e <fileclose+0x52>
    release(&ftable.lock);
8010160d:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
80101614:	e8 d0 3e 00 00       	call   801054e9 <release>
80101619:	e9 82 00 00 00       	jmp    801016a0 <fileclose+0xd4>
    return;
  }
  ff = *f;
8010161e:	8b 45 08             	mov    0x8(%ebp),%eax
80101621:	8b 10                	mov    (%eax),%edx
80101623:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101626:	8b 50 04             	mov    0x4(%eax),%edx
80101629:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010162c:	8b 50 08             	mov    0x8(%eax),%edx
8010162f:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101632:	8b 50 0c             	mov    0xc(%eax),%edx
80101635:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101638:	8b 50 10             	mov    0x10(%eax),%edx
8010163b:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010163e:	8b 40 14             	mov    0x14(%eax),%eax
80101641:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101644:	8b 45 08             	mov    0x8(%ebp),%eax
80101647:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010164e:	8b 45 08             	mov    0x8(%ebp),%eax
80101651:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101657:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
8010165e:	e8 86 3e 00 00       	call   801054e9 <release>
  
  if(ff.type == FD_PIPE)
80101663:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101666:	83 f8 01             	cmp    $0x1,%eax
80101669:	75 18                	jne    80101683 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010166b:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010166f:	0f be d0             	movsbl %al,%edx
80101672:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101675:	89 54 24 04          	mov    %edx,0x4(%esp)
80101679:	89 04 24             	mov    %eax,(%esp)
8010167c:	e8 6d 30 00 00       	call   801046ee <pipeclose>
80101681:	eb 1d                	jmp    801016a0 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101683:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101686:	83 f8 02             	cmp    $0x2,%eax
80101689:	75 15                	jne    801016a0 <fileclose+0xd4>
    begin_op();
8010168b:	e8 0f 24 00 00       	call   80103a9f <begin_op>
    iput(ff.ip);
80101690:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101693:	89 04 24             	mov    %eax,(%esp)
80101696:	e8 d5 09 00 00       	call   80102070 <iput>
    end_op();
8010169b:	e8 83 24 00 00       	call   80103b23 <end_op>
  }
}
801016a0:	c9                   	leave  
801016a1:	c3                   	ret    

801016a2 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801016a2:	55                   	push   %ebp
801016a3:	89 e5                	mov    %esp,%ebp
801016a5:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801016a8:	8b 45 08             	mov    0x8(%ebp),%eax
801016ab:	8b 00                	mov    (%eax),%eax
801016ad:	83 f8 02             	cmp    $0x2,%eax
801016b0:	75 38                	jne    801016ea <filestat+0x48>
    ilock(f->ip);
801016b2:	8b 45 08             	mov    0x8(%ebp),%eax
801016b5:	8b 40 10             	mov    0x10(%eax),%eax
801016b8:	89 04 24             	mov    %eax,(%esp)
801016bb:	e8 f7 07 00 00       	call   80101eb7 <ilock>
    stati(f->ip, st);
801016c0:	8b 45 08             	mov    0x8(%ebp),%eax
801016c3:	8b 40 10             	mov    0x10(%eax),%eax
801016c6:	8b 55 0c             	mov    0xc(%ebp),%edx
801016c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801016cd:	89 04 24             	mov    %eax,(%esp)
801016d0:	e8 b0 0c 00 00       	call   80102385 <stati>
    iunlock(f->ip);
801016d5:	8b 45 08             	mov    0x8(%ebp),%eax
801016d8:	8b 40 10             	mov    0x10(%eax),%eax
801016db:	89 04 24             	mov    %eax,(%esp)
801016de:	e8 28 09 00 00       	call   8010200b <iunlock>
    return 0;
801016e3:	b8 00 00 00 00       	mov    $0x0,%eax
801016e8:	eb 05                	jmp    801016ef <filestat+0x4d>
  }
  return -1;
801016ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801016ef:	c9                   	leave  
801016f0:	c3                   	ret    

801016f1 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801016f1:	55                   	push   %ebp
801016f2:	89 e5                	mov    %esp,%ebp
801016f4:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801016f7:	8b 45 08             	mov    0x8(%ebp),%eax
801016fa:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801016fe:	84 c0                	test   %al,%al
80101700:	75 0a                	jne    8010170c <fileread+0x1b>
    return -1;
80101702:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101707:	e9 9f 00 00 00       	jmp    801017ab <fileread+0xba>
  if(f->type == FD_PIPE)
8010170c:	8b 45 08             	mov    0x8(%ebp),%eax
8010170f:	8b 00                	mov    (%eax),%eax
80101711:	83 f8 01             	cmp    $0x1,%eax
80101714:	75 1e                	jne    80101734 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101716:	8b 45 08             	mov    0x8(%ebp),%eax
80101719:	8b 40 0c             	mov    0xc(%eax),%eax
8010171c:	8b 55 10             	mov    0x10(%ebp),%edx
8010171f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101723:	8b 55 0c             	mov    0xc(%ebp),%edx
80101726:	89 54 24 04          	mov    %edx,0x4(%esp)
8010172a:	89 04 24             	mov    %eax,(%esp)
8010172d:	e8 3d 31 00 00       	call   8010486f <piperead>
80101732:	eb 77                	jmp    801017ab <fileread+0xba>
  if(f->type == FD_INODE){
80101734:	8b 45 08             	mov    0x8(%ebp),%eax
80101737:	8b 00                	mov    (%eax),%eax
80101739:	83 f8 02             	cmp    $0x2,%eax
8010173c:	75 61                	jne    8010179f <fileread+0xae>
    ilock(f->ip);
8010173e:	8b 45 08             	mov    0x8(%ebp),%eax
80101741:	8b 40 10             	mov    0x10(%eax),%eax
80101744:	89 04 24             	mov    %eax,(%esp)
80101747:	e8 6b 07 00 00       	call   80101eb7 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010174c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010174f:	8b 45 08             	mov    0x8(%ebp),%eax
80101752:	8b 50 14             	mov    0x14(%eax),%edx
80101755:	8b 45 08             	mov    0x8(%ebp),%eax
80101758:	8b 40 10             	mov    0x10(%eax),%eax
8010175b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010175f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101763:	8b 55 0c             	mov    0xc(%ebp),%edx
80101766:	89 54 24 04          	mov    %edx,0x4(%esp)
8010176a:	89 04 24             	mov    %eax,(%esp)
8010176d:	e8 58 0c 00 00       	call   801023ca <readi>
80101772:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101775:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101779:	7e 11                	jle    8010178c <fileread+0x9b>
      f->off += r;
8010177b:	8b 45 08             	mov    0x8(%ebp),%eax
8010177e:	8b 50 14             	mov    0x14(%eax),%edx
80101781:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101784:	01 c2                	add    %eax,%edx
80101786:	8b 45 08             	mov    0x8(%ebp),%eax
80101789:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010178c:	8b 45 08             	mov    0x8(%ebp),%eax
8010178f:	8b 40 10             	mov    0x10(%eax),%eax
80101792:	89 04 24             	mov    %eax,(%esp)
80101795:	e8 71 08 00 00       	call   8010200b <iunlock>
    return r;
8010179a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179d:	eb 0c                	jmp    801017ab <fileread+0xba>
  }
  panic("fileread");
8010179f:	c7 04 24 cf 8a 10 80 	movl   $0x80108acf,(%esp)
801017a6:	e8 8f ed ff ff       	call   8010053a <panic>
}
801017ab:	c9                   	leave  
801017ac:	c3                   	ret    

801017ad <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801017ad:	55                   	push   %ebp
801017ae:	89 e5                	mov    %esp,%ebp
801017b0:	53                   	push   %ebx
801017b1:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801017b4:	8b 45 08             	mov    0x8(%ebp),%eax
801017b7:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801017bb:	84 c0                	test   %al,%al
801017bd:	75 0a                	jne    801017c9 <filewrite+0x1c>
    return -1;
801017bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801017c4:	e9 20 01 00 00       	jmp    801018e9 <filewrite+0x13c>
  if(f->type == FD_PIPE)
801017c9:	8b 45 08             	mov    0x8(%ebp),%eax
801017cc:	8b 00                	mov    (%eax),%eax
801017ce:	83 f8 01             	cmp    $0x1,%eax
801017d1:	75 21                	jne    801017f4 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801017d3:	8b 45 08             	mov    0x8(%ebp),%eax
801017d6:	8b 40 0c             	mov    0xc(%eax),%eax
801017d9:	8b 55 10             	mov    0x10(%ebp),%edx
801017dc:	89 54 24 08          	mov    %edx,0x8(%esp)
801017e0:	8b 55 0c             	mov    0xc(%ebp),%edx
801017e3:	89 54 24 04          	mov    %edx,0x4(%esp)
801017e7:	89 04 24             	mov    %eax,(%esp)
801017ea:	e8 91 2f 00 00       	call   80104780 <pipewrite>
801017ef:	e9 f5 00 00 00       	jmp    801018e9 <filewrite+0x13c>
  if(f->type == FD_INODE){
801017f4:	8b 45 08             	mov    0x8(%ebp),%eax
801017f7:	8b 00                	mov    (%eax),%eax
801017f9:	83 f8 02             	cmp    $0x2,%eax
801017fc:	0f 85 db 00 00 00    	jne    801018dd <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101802:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
80101809:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101810:	e9 a8 00 00 00       	jmp    801018bd <filewrite+0x110>
      int n1 = n - i;
80101815:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101818:	8b 55 10             	mov    0x10(%ebp),%edx
8010181b:	29 c2                	sub    %eax,%edx
8010181d:	89 d0                	mov    %edx,%eax
8010181f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101822:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101825:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101828:	7e 06                	jle    80101830 <filewrite+0x83>
        n1 = max;
8010182a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010182d:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101830:	e8 6a 22 00 00       	call   80103a9f <begin_op>
      ilock(f->ip);
80101835:	8b 45 08             	mov    0x8(%ebp),%eax
80101838:	8b 40 10             	mov    0x10(%eax),%eax
8010183b:	89 04 24             	mov    %eax,(%esp)
8010183e:	e8 74 06 00 00       	call   80101eb7 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101843:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101846:	8b 45 08             	mov    0x8(%ebp),%eax
80101849:	8b 50 14             	mov    0x14(%eax),%edx
8010184c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
8010184f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101852:	01 c3                	add    %eax,%ebx
80101854:	8b 45 08             	mov    0x8(%ebp),%eax
80101857:	8b 40 10             	mov    0x10(%eax),%eax
8010185a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010185e:	89 54 24 08          	mov    %edx,0x8(%esp)
80101862:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101866:	89 04 24             	mov    %eax,(%esp)
80101869:	e8 c0 0c 00 00       	call   8010252e <writei>
8010186e:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101871:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101875:	7e 11                	jle    80101888 <filewrite+0xdb>
        f->off += r;
80101877:	8b 45 08             	mov    0x8(%ebp),%eax
8010187a:	8b 50 14             	mov    0x14(%eax),%edx
8010187d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101880:	01 c2                	add    %eax,%edx
80101882:	8b 45 08             	mov    0x8(%ebp),%eax
80101885:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101888:	8b 45 08             	mov    0x8(%ebp),%eax
8010188b:	8b 40 10             	mov    0x10(%eax),%eax
8010188e:	89 04 24             	mov    %eax,(%esp)
80101891:	e8 75 07 00 00       	call   8010200b <iunlock>
      end_op();
80101896:	e8 88 22 00 00       	call   80103b23 <end_op>

      if(r < 0)
8010189b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010189f:	79 02                	jns    801018a3 <filewrite+0xf6>
        break;
801018a1:	eb 26                	jmp    801018c9 <filewrite+0x11c>
      if(r != n1)
801018a3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018a6:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801018a9:	74 0c                	je     801018b7 <filewrite+0x10a>
        panic("short filewrite");
801018ab:	c7 04 24 d8 8a 10 80 	movl   $0x80108ad8,(%esp)
801018b2:	e8 83 ec ff ff       	call   8010053a <panic>
      i += r;
801018b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018ba:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801018bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018c0:	3b 45 10             	cmp    0x10(%ebp),%eax
801018c3:	0f 8c 4c ff ff ff    	jl     80101815 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801018c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018cc:	3b 45 10             	cmp    0x10(%ebp),%eax
801018cf:	75 05                	jne    801018d6 <filewrite+0x129>
801018d1:	8b 45 10             	mov    0x10(%ebp),%eax
801018d4:	eb 05                	jmp    801018db <filewrite+0x12e>
801018d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801018db:	eb 0c                	jmp    801018e9 <filewrite+0x13c>
  }
  panic("filewrite");
801018dd:	c7 04 24 e8 8a 10 80 	movl   $0x80108ae8,(%esp)
801018e4:	e8 51 ec ff ff       	call   8010053a <panic>
}
801018e9:	83 c4 24             	add    $0x24,%esp
801018ec:	5b                   	pop    %ebx
801018ed:	5d                   	pop    %ebp
801018ee:	c3                   	ret    

801018ef <readsb>:
struct superblock sb;   // there should be one per dev, but we run with one dev

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801018ef:	55                   	push   %ebp
801018f0:	89 e5                	mov    %esp,%ebp
801018f2:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801018ff:	00 
80101900:	89 04 24             	mov    %eax,(%esp)
80101903:	e8 9e e8 ff ff       	call   801001a6 <bread>
80101908:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010190b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010190e:	83 c0 18             	add    $0x18,%eax
80101911:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
80101918:	00 
80101919:	89 44 24 04          	mov    %eax,0x4(%esp)
8010191d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101920:	89 04 24             	mov    %eax,(%esp)
80101923:	e8 82 3e 00 00       	call   801057aa <memmove>
  brelse(bp);
80101928:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010192b:	89 04 24             	mov    %eax,(%esp)
8010192e:	e8 e4 e8 ff ff       	call   80100217 <brelse>
}
80101933:	c9                   	leave  
80101934:	c3                   	ret    

80101935 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101935:	55                   	push   %ebp
80101936:	89 e5                	mov    %esp,%ebp
80101938:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010193b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010193e:	8b 45 08             	mov    0x8(%ebp),%eax
80101941:	89 54 24 04          	mov    %edx,0x4(%esp)
80101945:	89 04 24             	mov    %eax,(%esp)
80101948:	e8 59 e8 ff ff       	call   801001a6 <bread>
8010194d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101950:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101953:	83 c0 18             	add    $0x18,%eax
80101956:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010195d:	00 
8010195e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101965:	00 
80101966:	89 04 24             	mov    %eax,(%esp)
80101969:	e8 6d 3d 00 00       	call   801056db <memset>
  log_write(bp);
8010196e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101971:	89 04 24             	mov    %eax,(%esp)
80101974:	e8 31 23 00 00       	call   80103caa <log_write>
  brelse(bp);
80101979:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010197c:	89 04 24             	mov    %eax,(%esp)
8010197f:	e8 93 e8 ff ff       	call   80100217 <brelse>
}
80101984:	c9                   	leave  
80101985:	c3                   	ret    

80101986 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101986:	55                   	push   %ebp
80101987:	89 e5                	mov    %esp,%ebp
80101989:	83 ec 28             	sub    $0x28,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
8010198c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101993:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010199a:	e9 07 01 00 00       	jmp    80101aa6 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
8010199f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019a2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801019a8:	85 c0                	test   %eax,%eax
801019aa:	0f 48 c2             	cmovs  %edx,%eax
801019ad:	c1 f8 0c             	sar    $0xc,%eax
801019b0:	89 c2                	mov    %eax,%edx
801019b2:	a1 98 2a 11 80       	mov    0x80112a98,%eax
801019b7:	01 d0                	add    %edx,%eax
801019b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801019bd:	8b 45 08             	mov    0x8(%ebp),%eax
801019c0:	89 04 24             	mov    %eax,(%esp)
801019c3:	e8 de e7 ff ff       	call   801001a6 <bread>
801019c8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801019cb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801019d2:	e9 9d 00 00 00       	jmp    80101a74 <balloc+0xee>
      m = 1 << (bi % 8);
801019d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019da:	99                   	cltd   
801019db:	c1 ea 1d             	shr    $0x1d,%edx
801019de:	01 d0                	add    %edx,%eax
801019e0:	83 e0 07             	and    $0x7,%eax
801019e3:	29 d0                	sub    %edx,%eax
801019e5:	ba 01 00 00 00       	mov    $0x1,%edx
801019ea:	89 c1                	mov    %eax,%ecx
801019ec:	d3 e2                	shl    %cl,%edx
801019ee:	89 d0                	mov    %edx,%eax
801019f0:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801019f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019f6:	8d 50 07             	lea    0x7(%eax),%edx
801019f9:	85 c0                	test   %eax,%eax
801019fb:	0f 48 c2             	cmovs  %edx,%eax
801019fe:	c1 f8 03             	sar    $0x3,%eax
80101a01:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101a04:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101a09:	0f b6 c0             	movzbl %al,%eax
80101a0c:	23 45 e8             	and    -0x18(%ebp),%eax
80101a0f:	85 c0                	test   %eax,%eax
80101a11:	75 5d                	jne    80101a70 <balloc+0xea>
        bp->data[bi/8] |= m;  // Mark block in use.
80101a13:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a16:	8d 50 07             	lea    0x7(%eax),%edx
80101a19:	85 c0                	test   %eax,%eax
80101a1b:	0f 48 c2             	cmovs  %edx,%eax
80101a1e:	c1 f8 03             	sar    $0x3,%eax
80101a21:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101a24:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101a29:	89 d1                	mov    %edx,%ecx
80101a2b:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101a2e:	09 ca                	or     %ecx,%edx
80101a30:	89 d1                	mov    %edx,%ecx
80101a32:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101a35:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101a39:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101a3c:	89 04 24             	mov    %eax,(%esp)
80101a3f:	e8 66 22 00 00       	call   80103caa <log_write>
        brelse(bp);
80101a44:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101a47:	89 04 24             	mov    %eax,(%esp)
80101a4a:	e8 c8 e7 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101a4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a52:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101a55:	01 c2                	add    %eax,%edx
80101a57:	8b 45 08             	mov    0x8(%ebp),%eax
80101a5a:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a5e:	89 04 24             	mov    %eax,(%esp)
80101a61:	e8 cf fe ff ff       	call   80101935 <bzero>
        return b + bi;
80101a66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a69:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101a6c:	01 d0                	add    %edx,%eax
80101a6e:	eb 52                	jmp    80101ac2 <balloc+0x13c>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101a70:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101a74:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101a7b:	7f 17                	jg     80101a94 <balloc+0x10e>
80101a7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a80:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101a83:	01 d0                	add    %edx,%eax
80101a85:	89 c2                	mov    %eax,%edx
80101a87:	a1 80 2a 11 80       	mov    0x80112a80,%eax
80101a8c:	39 c2                	cmp    %eax,%edx
80101a8e:	0f 82 43 ff ff ff    	jb     801019d7 <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101a94:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101a97:	89 04 24             	mov    %eax,(%esp)
80101a9a:	e8 78 e7 ff ff       	call   80100217 <brelse>
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
80101a9f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101aa6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101aa9:	a1 80 2a 11 80       	mov    0x80112a80,%eax
80101aae:	39 c2                	cmp    %eax,%edx
80101ab0:	0f 82 e9 fe ff ff    	jb     8010199f <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101ab6:	c7 04 24 f4 8a 10 80 	movl   $0x80108af4,(%esp)
80101abd:	e8 78 ea ff ff       	call   8010053a <panic>
}
80101ac2:	c9                   	leave  
80101ac3:	c3                   	ret    

80101ac4 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101ac4:	55                   	push   %ebp
80101ac5:	89 e5                	mov    %esp,%ebp
80101ac7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
80101aca:	c7 44 24 04 80 2a 11 	movl   $0x80112a80,0x4(%esp)
80101ad1:	80 
80101ad2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad5:	89 04 24             	mov    %eax,(%esp)
80101ad8:	e8 12 fe ff ff       	call   801018ef <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101add:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ae0:	c1 e8 0c             	shr    $0xc,%eax
80101ae3:	89 c2                	mov    %eax,%edx
80101ae5:	a1 98 2a 11 80       	mov    0x80112a98,%eax
80101aea:	01 c2                	add    %eax,%edx
80101aec:	8b 45 08             	mov    0x8(%ebp),%eax
80101aef:	89 54 24 04          	mov    %edx,0x4(%esp)
80101af3:	89 04 24             	mov    %eax,(%esp)
80101af6:	e8 ab e6 ff ff       	call   801001a6 <bread>
80101afb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101afe:	8b 45 0c             	mov    0xc(%ebp),%eax
80101b01:	25 ff 0f 00 00       	and    $0xfff,%eax
80101b06:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101b09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b0c:	99                   	cltd   
80101b0d:	c1 ea 1d             	shr    $0x1d,%edx
80101b10:	01 d0                	add    %edx,%eax
80101b12:	83 e0 07             	and    $0x7,%eax
80101b15:	29 d0                	sub    %edx,%eax
80101b17:	ba 01 00 00 00       	mov    $0x1,%edx
80101b1c:	89 c1                	mov    %eax,%ecx
80101b1e:	d3 e2                	shl    %cl,%edx
80101b20:	89 d0                	mov    %edx,%eax
80101b22:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101b25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b28:	8d 50 07             	lea    0x7(%eax),%edx
80101b2b:	85 c0                	test   %eax,%eax
80101b2d:	0f 48 c2             	cmovs  %edx,%eax
80101b30:	c1 f8 03             	sar    $0x3,%eax
80101b33:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b36:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101b3b:	0f b6 c0             	movzbl %al,%eax
80101b3e:	23 45 ec             	and    -0x14(%ebp),%eax
80101b41:	85 c0                	test   %eax,%eax
80101b43:	75 0c                	jne    80101b51 <bfree+0x8d>
    panic("freeing free block");
80101b45:	c7 04 24 0a 8b 10 80 	movl   $0x80108b0a,(%esp)
80101b4c:	e8 e9 e9 ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101b51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b54:	8d 50 07             	lea    0x7(%eax),%edx
80101b57:	85 c0                	test   %eax,%eax
80101b59:	0f 48 c2             	cmovs  %edx,%eax
80101b5c:	c1 f8 03             	sar    $0x3,%eax
80101b5f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b62:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101b67:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101b6a:	f7 d1                	not    %ecx
80101b6c:	21 ca                	and    %ecx,%edx
80101b6e:	89 d1                	mov    %edx,%ecx
80101b70:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b73:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101b77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b7a:	89 04 24             	mov    %eax,(%esp)
80101b7d:	e8 28 21 00 00       	call   80103caa <log_write>
  brelse(bp);
80101b82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b85:	89 04 24             	mov    %eax,(%esp)
80101b88:	e8 8a e6 ff ff       	call   80100217 <brelse>
}
80101b8d:	c9                   	leave  
80101b8e:	c3                   	ret    

80101b8f <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
80101b8f:	55                   	push   %ebp
80101b90:	89 e5                	mov    %esp,%ebp
80101b92:	57                   	push   %edi
80101b93:	56                   	push   %esi
80101b94:	53                   	push   %ebx
80101b95:	83 ec 3c             	sub    $0x3c,%esp
  initlock(&icache.lock, "icache");
80101b98:	c7 44 24 04 1d 8b 10 	movl   $0x80108b1d,0x4(%esp)
80101b9f:	80 
80101ba0:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101ba7:	e8 ba 38 00 00       	call   80105466 <initlock>
  readsb(dev, &sb);
80101bac:	c7 44 24 04 80 2a 11 	movl   $0x80112a80,0x4(%esp)
80101bb3:	80 
80101bb4:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb7:	89 04 24             	mov    %eax,(%esp)
80101bba:	e8 30 fd ff ff       	call   801018ef <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d inodestart %d bmap start %d\n", sb.size,
80101bbf:	a1 98 2a 11 80       	mov    0x80112a98,%eax
80101bc4:	8b 3d 94 2a 11 80    	mov    0x80112a94,%edi
80101bca:	8b 35 90 2a 11 80    	mov    0x80112a90,%esi
80101bd0:	8b 1d 8c 2a 11 80    	mov    0x80112a8c,%ebx
80101bd6:	8b 0d 88 2a 11 80    	mov    0x80112a88,%ecx
80101bdc:	8b 15 84 2a 11 80    	mov    0x80112a84,%edx
80101be2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101be5:	8b 15 80 2a 11 80    	mov    0x80112a80,%edx
80101beb:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101bef:	89 7c 24 18          	mov    %edi,0x18(%esp)
80101bf3:	89 74 24 14          	mov    %esi,0x14(%esp)
80101bf7:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80101bfb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101bff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101c02:	89 44 24 08          	mov    %eax,0x8(%esp)
80101c06:	89 d0                	mov    %edx,%eax
80101c08:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c0c:	c7 04 24 24 8b 10 80 	movl   $0x80108b24,(%esp)
80101c13:	e8 88 e7 ff ff       	call   801003a0 <cprintf>
          sb.nblocks, sb.ninodes, sb.nlog, sb.logstart, sb.inodestart, sb.bmapstart);
}
80101c18:	83 c4 3c             	add    $0x3c,%esp
80101c1b:	5b                   	pop    %ebx
80101c1c:	5e                   	pop    %esi
80101c1d:	5f                   	pop    %edi
80101c1e:	5d                   	pop    %ebp
80101c1f:	c3                   	ret    

80101c20 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101c20:	55                   	push   %ebp
80101c21:	89 e5                	mov    %esp,%ebp
80101c23:	83 ec 28             	sub    $0x28,%esp
80101c26:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c29:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101c2d:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101c34:	e9 9e 00 00 00       	jmp    80101cd7 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
80101c39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c3c:	c1 e8 03             	shr    $0x3,%eax
80101c3f:	89 c2                	mov    %eax,%edx
80101c41:	a1 94 2a 11 80       	mov    0x80112a94,%eax
80101c46:	01 d0                	add    %edx,%eax
80101c48:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4f:	89 04 24             	mov    %eax,(%esp)
80101c52:	e8 4f e5 ff ff       	call   801001a6 <bread>
80101c57:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101c5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c5d:	8d 50 18             	lea    0x18(%eax),%edx
80101c60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c63:	83 e0 07             	and    $0x7,%eax
80101c66:	c1 e0 06             	shl    $0x6,%eax
80101c69:	01 d0                	add    %edx,%eax
80101c6b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101c6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c71:	0f b7 00             	movzwl (%eax),%eax
80101c74:	66 85 c0             	test   %ax,%ax
80101c77:	75 4f                	jne    80101cc8 <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
80101c79:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101c80:	00 
80101c81:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101c88:	00 
80101c89:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c8c:	89 04 24             	mov    %eax,(%esp)
80101c8f:	e8 47 3a 00 00       	call   801056db <memset>
      dip->type = type;
80101c94:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c97:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
80101c9b:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101c9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca1:	89 04 24             	mov    %eax,(%esp)
80101ca4:	e8 01 20 00 00       	call   80103caa <log_write>
      brelse(bp);
80101ca9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cac:	89 04 24             	mov    %eax,(%esp)
80101caf:	e8 63 e5 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101cb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cbb:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbe:	89 04 24             	mov    %eax,(%esp)
80101cc1:	e8 ed 00 00 00       	call   80101db3 <iget>
80101cc6:	eb 2b                	jmp    80101cf3 <ialloc+0xd3>
    }
    brelse(bp);
80101cc8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ccb:	89 04 24             	mov    %eax,(%esp)
80101cce:	e8 44 e5 ff ff       	call   80100217 <brelse>
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101cd3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101cd7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cda:	a1 88 2a 11 80       	mov    0x80112a88,%eax
80101cdf:	39 c2                	cmp    %eax,%edx
80101ce1:	0f 82 52 ff ff ff    	jb     80101c39 <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101ce7:	c7 04 24 77 8b 10 80 	movl   $0x80108b77,(%esp)
80101cee:	e8 47 e8 ff ff       	call   8010053a <panic>
}
80101cf3:	c9                   	leave  
80101cf4:	c3                   	ret    

80101cf5 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101cf5:	55                   	push   %ebp
80101cf6:	89 e5                	mov    %esp,%ebp
80101cf8:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101cfb:	8b 45 08             	mov    0x8(%ebp),%eax
80101cfe:	8b 40 04             	mov    0x4(%eax),%eax
80101d01:	c1 e8 03             	shr    $0x3,%eax
80101d04:	89 c2                	mov    %eax,%edx
80101d06:	a1 94 2a 11 80       	mov    0x80112a94,%eax
80101d0b:	01 c2                	add    %eax,%edx
80101d0d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d10:	8b 00                	mov    (%eax),%eax
80101d12:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d16:	89 04 24             	mov    %eax,(%esp)
80101d19:	e8 88 e4 ff ff       	call   801001a6 <bread>
80101d1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101d21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d24:	8d 50 18             	lea    0x18(%eax),%edx
80101d27:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2a:	8b 40 04             	mov    0x4(%eax),%eax
80101d2d:	83 e0 07             	and    $0x7,%eax
80101d30:	c1 e0 06             	shl    $0x6,%eax
80101d33:	01 d0                	add    %edx,%eax
80101d35:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101d38:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3b:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d42:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101d45:	8b 45 08             	mov    0x8(%ebp),%eax
80101d48:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101d4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d4f:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101d53:	8b 45 08             	mov    0x8(%ebp),%eax
80101d56:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101d5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d5d:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101d61:	8b 45 08             	mov    0x8(%ebp),%eax
80101d64:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d6b:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101d6f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d72:	8b 50 18             	mov    0x18(%eax),%edx
80101d75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d78:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101d7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7e:	8d 50 1c             	lea    0x1c(%eax),%edx
80101d81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d84:	83 c0 0c             	add    $0xc,%eax
80101d87:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101d8e:	00 
80101d8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d93:	89 04 24             	mov    %eax,(%esp)
80101d96:	e8 0f 3a 00 00       	call   801057aa <memmove>
  log_write(bp);
80101d9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d9e:	89 04 24             	mov    %eax,(%esp)
80101da1:	e8 04 1f 00 00       	call   80103caa <log_write>
  brelse(bp);
80101da6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101da9:	89 04 24             	mov    %eax,(%esp)
80101dac:	e8 66 e4 ff ff       	call   80100217 <brelse>
}
80101db1:	c9                   	leave  
80101db2:	c3                   	ret    

80101db3 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101db3:	55                   	push   %ebp
80101db4:	89 e5                	mov    %esp,%ebp
80101db6:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101db9:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101dc0:	e8 c2 36 00 00       	call   80105487 <acquire>

  // Is the inode already cached?
  empty = 0;
80101dc5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101dcc:	c7 45 f4 d4 2a 11 80 	movl   $0x80112ad4,-0xc(%ebp)
80101dd3:	eb 59                	jmp    80101e2e <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101dd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dd8:	8b 40 08             	mov    0x8(%eax),%eax
80101ddb:	85 c0                	test   %eax,%eax
80101ddd:	7e 35                	jle    80101e14 <iget+0x61>
80101ddf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101de2:	8b 00                	mov    (%eax),%eax
80101de4:	3b 45 08             	cmp    0x8(%ebp),%eax
80101de7:	75 2b                	jne    80101e14 <iget+0x61>
80101de9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dec:	8b 40 04             	mov    0x4(%eax),%eax
80101def:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101df2:	75 20                	jne    80101e14 <iget+0x61>
      ip->ref++;
80101df4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101df7:	8b 40 08             	mov    0x8(%eax),%eax
80101dfa:	8d 50 01             	lea    0x1(%eax),%edx
80101dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e00:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101e03:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101e0a:	e8 da 36 00 00       	call   801054e9 <release>
      return ip;
80101e0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e12:	eb 6f                	jmp    80101e83 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101e14:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101e18:	75 10                	jne    80101e2a <iget+0x77>
80101e1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e1d:	8b 40 08             	mov    0x8(%eax),%eax
80101e20:	85 c0                	test   %eax,%eax
80101e22:	75 06                	jne    80101e2a <iget+0x77>
      empty = ip;
80101e24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e27:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101e2a:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101e2e:	81 7d f4 74 3a 11 80 	cmpl   $0x80113a74,-0xc(%ebp)
80101e35:	72 9e                	jb     80101dd5 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101e37:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101e3b:	75 0c                	jne    80101e49 <iget+0x96>
    panic("iget: no inodes");
80101e3d:	c7 04 24 89 8b 10 80 	movl   $0x80108b89,(%esp)
80101e44:	e8 f1 e6 ff ff       	call   8010053a <panic>

  ip = empty;
80101e49:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101e4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e52:	8b 55 08             	mov    0x8(%ebp),%edx
80101e55:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e5a:	8b 55 0c             	mov    0xc(%ebp),%edx
80101e5d:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101e60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e63:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101e6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e6d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101e74:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101e7b:	e8 69 36 00 00       	call   801054e9 <release>

  return ip;
80101e80:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101e83:	c9                   	leave  
80101e84:	c3                   	ret    

80101e85 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101e85:	55                   	push   %ebp
80101e86:	89 e5                	mov    %esp,%ebp
80101e88:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101e8b:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101e92:	e8 f0 35 00 00       	call   80105487 <acquire>
  ip->ref++;
80101e97:	8b 45 08             	mov    0x8(%ebp),%eax
80101e9a:	8b 40 08             	mov    0x8(%eax),%eax
80101e9d:	8d 50 01             	lea    0x1(%eax),%edx
80101ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea3:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ea6:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101ead:	e8 37 36 00 00       	call   801054e9 <release>
  return ip;
80101eb2:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101eb5:	c9                   	leave  
80101eb6:	c3                   	ret    

80101eb7 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101eb7:	55                   	push   %ebp
80101eb8:	89 e5                	mov    %esp,%ebp
80101eba:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101ebd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101ec1:	74 0a                	je     80101ecd <ilock+0x16>
80101ec3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec6:	8b 40 08             	mov    0x8(%eax),%eax
80101ec9:	85 c0                	test   %eax,%eax
80101ecb:	7f 0c                	jg     80101ed9 <ilock+0x22>
    panic("ilock");
80101ecd:	c7 04 24 99 8b 10 80 	movl   $0x80108b99,(%esp)
80101ed4:	e8 61 e6 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101ed9:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101ee0:	e8 a2 35 00 00       	call   80105487 <acquire>
  while(ip->flags & I_BUSY)
80101ee5:	eb 13                	jmp    80101efa <ilock+0x43>
    sleep(ip, &icache.lock);
80101ee7:	c7 44 24 04 a0 2a 11 	movl   $0x80112aa0,0x4(%esp)
80101eee:	80 
80101eef:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef2:	89 04 24             	mov    %eax,(%esp)
80101ef5:	e8 c3 32 00 00       	call   801051bd <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101efa:	8b 45 08             	mov    0x8(%ebp),%eax
80101efd:	8b 40 0c             	mov    0xc(%eax),%eax
80101f00:	83 e0 01             	and    $0x1,%eax
80101f03:	85 c0                	test   %eax,%eax
80101f05:	75 e0                	jne    80101ee7 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101f07:	8b 45 08             	mov    0x8(%ebp),%eax
80101f0a:	8b 40 0c             	mov    0xc(%eax),%eax
80101f0d:	83 c8 01             	or     $0x1,%eax
80101f10:	89 c2                	mov    %eax,%edx
80101f12:	8b 45 08             	mov    0x8(%ebp),%eax
80101f15:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101f18:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101f1f:	e8 c5 35 00 00       	call   801054e9 <release>

  if(!(ip->flags & I_VALID)){
80101f24:	8b 45 08             	mov    0x8(%ebp),%eax
80101f27:	8b 40 0c             	mov    0xc(%eax),%eax
80101f2a:	83 e0 02             	and    $0x2,%eax
80101f2d:	85 c0                	test   %eax,%eax
80101f2f:	0f 85 d4 00 00 00    	jne    80102009 <ilock+0x152>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101f35:	8b 45 08             	mov    0x8(%ebp),%eax
80101f38:	8b 40 04             	mov    0x4(%eax),%eax
80101f3b:	c1 e8 03             	shr    $0x3,%eax
80101f3e:	89 c2                	mov    %eax,%edx
80101f40:	a1 94 2a 11 80       	mov    0x80112a94,%eax
80101f45:	01 c2                	add    %eax,%edx
80101f47:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4a:	8b 00                	mov    (%eax),%eax
80101f4c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f50:	89 04 24             	mov    %eax,(%esp)
80101f53:	e8 4e e2 ff ff       	call   801001a6 <bread>
80101f58:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101f5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f5e:	8d 50 18             	lea    0x18(%eax),%edx
80101f61:	8b 45 08             	mov    0x8(%ebp),%eax
80101f64:	8b 40 04             	mov    0x4(%eax),%eax
80101f67:	83 e0 07             	and    $0x7,%eax
80101f6a:	c1 e0 06             	shl    $0x6,%eax
80101f6d:	01 d0                	add    %edx,%eax
80101f6f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101f72:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f75:	0f b7 10             	movzwl (%eax),%edx
80101f78:	8b 45 08             	mov    0x8(%ebp),%eax
80101f7b:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101f7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f82:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101f86:	8b 45 08             	mov    0x8(%ebp),%eax
80101f89:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101f8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f90:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101f94:	8b 45 08             	mov    0x8(%ebp),%eax
80101f97:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101f9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f9e:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101fa2:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa5:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101fa9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fac:	8b 50 08             	mov    0x8(%eax),%edx
80101faf:	8b 45 08             	mov    0x8(%ebp),%eax
80101fb2:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101fb5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fb8:	8d 50 0c             	lea    0xc(%eax),%edx
80101fbb:	8b 45 08             	mov    0x8(%ebp),%eax
80101fbe:	83 c0 1c             	add    $0x1c,%eax
80101fc1:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101fc8:	00 
80101fc9:	89 54 24 04          	mov    %edx,0x4(%esp)
80101fcd:	89 04 24             	mov    %eax,(%esp)
80101fd0:	e8 d5 37 00 00       	call   801057aa <memmove>
    brelse(bp);
80101fd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fd8:	89 04 24             	mov    %eax,(%esp)
80101fdb:	e8 37 e2 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe3:	8b 40 0c             	mov    0xc(%eax),%eax
80101fe6:	83 c8 02             	or     $0x2,%eax
80101fe9:	89 c2                	mov    %eax,%edx
80101feb:	8b 45 08             	mov    0x8(%ebp),%eax
80101fee:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101ff1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ff4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101ff8:	66 85 c0             	test   %ax,%ax
80101ffb:	75 0c                	jne    80102009 <ilock+0x152>
      panic("ilock: no type");
80101ffd:	c7 04 24 9f 8b 10 80 	movl   $0x80108b9f,(%esp)
80102004:	e8 31 e5 ff ff       	call   8010053a <panic>
  }
}
80102009:	c9                   	leave  
8010200a:	c3                   	ret    

8010200b <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
8010200b:	55                   	push   %ebp
8010200c:	89 e5                	mov    %esp,%ebp
8010200e:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80102011:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102015:	74 17                	je     8010202e <iunlock+0x23>
80102017:	8b 45 08             	mov    0x8(%ebp),%eax
8010201a:	8b 40 0c             	mov    0xc(%eax),%eax
8010201d:	83 e0 01             	and    $0x1,%eax
80102020:	85 c0                	test   %eax,%eax
80102022:	74 0a                	je     8010202e <iunlock+0x23>
80102024:	8b 45 08             	mov    0x8(%ebp),%eax
80102027:	8b 40 08             	mov    0x8(%eax),%eax
8010202a:	85 c0                	test   %eax,%eax
8010202c:	7f 0c                	jg     8010203a <iunlock+0x2f>
    panic("iunlock");
8010202e:	c7 04 24 ae 8b 10 80 	movl   $0x80108bae,(%esp)
80102035:	e8 00 e5 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
8010203a:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80102041:	e8 41 34 00 00       	call   80105487 <acquire>
  ip->flags &= ~I_BUSY;
80102046:	8b 45 08             	mov    0x8(%ebp),%eax
80102049:	8b 40 0c             	mov    0xc(%eax),%eax
8010204c:	83 e0 fe             	and    $0xfffffffe,%eax
8010204f:	89 c2                	mov    %eax,%edx
80102051:	8b 45 08             	mov    0x8(%ebp),%eax
80102054:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80102057:	8b 45 08             	mov    0x8(%ebp),%eax
8010205a:	89 04 24             	mov    %eax,(%esp)
8010205d:	e8 34 32 00 00       	call   80105296 <wakeup>
  release(&icache.lock);
80102062:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80102069:	e8 7b 34 00 00       	call   801054e9 <release>
}
8010206e:	c9                   	leave  
8010206f:	c3                   	ret    

80102070 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80102070:	55                   	push   %ebp
80102071:	89 e5                	mov    %esp,%ebp
80102073:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80102076:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
8010207d:	e8 05 34 00 00       	call   80105487 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80102082:	8b 45 08             	mov    0x8(%ebp),%eax
80102085:	8b 40 08             	mov    0x8(%eax),%eax
80102088:	83 f8 01             	cmp    $0x1,%eax
8010208b:	0f 85 93 00 00 00    	jne    80102124 <iput+0xb4>
80102091:	8b 45 08             	mov    0x8(%ebp),%eax
80102094:	8b 40 0c             	mov    0xc(%eax),%eax
80102097:	83 e0 02             	and    $0x2,%eax
8010209a:	85 c0                	test   %eax,%eax
8010209c:	0f 84 82 00 00 00    	je     80102124 <iput+0xb4>
801020a2:	8b 45 08             	mov    0x8(%ebp),%eax
801020a5:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801020a9:	66 85 c0             	test   %ax,%ax
801020ac:	75 76                	jne    80102124 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
801020ae:	8b 45 08             	mov    0x8(%ebp),%eax
801020b1:	8b 40 0c             	mov    0xc(%eax),%eax
801020b4:	83 e0 01             	and    $0x1,%eax
801020b7:	85 c0                	test   %eax,%eax
801020b9:	74 0c                	je     801020c7 <iput+0x57>
      panic("iput busy");
801020bb:	c7 04 24 b6 8b 10 80 	movl   $0x80108bb6,(%esp)
801020c2:	e8 73 e4 ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
801020c7:	8b 45 08             	mov    0x8(%ebp),%eax
801020ca:	8b 40 0c             	mov    0xc(%eax),%eax
801020cd:	83 c8 01             	or     $0x1,%eax
801020d0:	89 c2                	mov    %eax,%edx
801020d2:	8b 45 08             	mov    0x8(%ebp),%eax
801020d5:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
801020d8:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
801020df:	e8 05 34 00 00       	call   801054e9 <release>
    itrunc(ip);
801020e4:	8b 45 08             	mov    0x8(%ebp),%eax
801020e7:	89 04 24             	mov    %eax,(%esp)
801020ea:	e8 7d 01 00 00       	call   8010226c <itrunc>
    ip->type = 0;
801020ef:	8b 45 08             	mov    0x8(%ebp),%eax
801020f2:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
801020f8:	8b 45 08             	mov    0x8(%ebp),%eax
801020fb:	89 04 24             	mov    %eax,(%esp)
801020fe:	e8 f2 fb ff ff       	call   80101cf5 <iupdate>
    acquire(&icache.lock);
80102103:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
8010210a:	e8 78 33 00 00       	call   80105487 <acquire>
    ip->flags = 0;
8010210f:	8b 45 08             	mov    0x8(%ebp),%eax
80102112:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102119:	8b 45 08             	mov    0x8(%ebp),%eax
8010211c:	89 04 24             	mov    %eax,(%esp)
8010211f:	e8 72 31 00 00       	call   80105296 <wakeup>
  }
  ip->ref--;
80102124:	8b 45 08             	mov    0x8(%ebp),%eax
80102127:	8b 40 08             	mov    0x8(%eax),%eax
8010212a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010212d:	8b 45 08             	mov    0x8(%ebp),%eax
80102130:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80102133:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
8010213a:	e8 aa 33 00 00       	call   801054e9 <release>
}
8010213f:	c9                   	leave  
80102140:	c3                   	ret    

80102141 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80102141:	55                   	push   %ebp
80102142:	89 e5                	mov    %esp,%ebp
80102144:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80102147:	8b 45 08             	mov    0x8(%ebp),%eax
8010214a:	89 04 24             	mov    %eax,(%esp)
8010214d:	e8 b9 fe ff ff       	call   8010200b <iunlock>
  iput(ip);
80102152:	8b 45 08             	mov    0x8(%ebp),%eax
80102155:	89 04 24             	mov    %eax,(%esp)
80102158:	e8 13 ff ff ff       	call   80102070 <iput>
}
8010215d:	c9                   	leave  
8010215e:	c3                   	ret    

8010215f <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
8010215f:	55                   	push   %ebp
80102160:	89 e5                	mov    %esp,%ebp
80102162:	53                   	push   %ebx
80102163:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80102166:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
8010216a:	77 3e                	ja     801021aa <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
8010216c:	8b 45 08             	mov    0x8(%ebp),%eax
8010216f:	8b 55 0c             	mov    0xc(%ebp),%edx
80102172:	83 c2 04             	add    $0x4,%edx
80102175:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102179:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010217c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102180:	75 20                	jne    801021a2 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80102182:	8b 45 08             	mov    0x8(%ebp),%eax
80102185:	8b 00                	mov    (%eax),%eax
80102187:	89 04 24             	mov    %eax,(%esp)
8010218a:	e8 f7 f7 ff ff       	call   80101986 <balloc>
8010218f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102192:	8b 45 08             	mov    0x8(%ebp),%eax
80102195:	8b 55 0c             	mov    0xc(%ebp),%edx
80102198:	8d 4a 04             	lea    0x4(%edx),%ecx
8010219b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010219e:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801021a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021a5:	e9 bc 00 00 00       	jmp    80102266 <bmap+0x107>
  }
  bn -= NDIRECT;
801021aa:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801021ae:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801021b2:	0f 87 a2 00 00 00    	ja     8010225a <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
801021b8:	8b 45 08             	mov    0x8(%ebp),%eax
801021bb:	8b 40 4c             	mov    0x4c(%eax),%eax
801021be:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021c1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801021c5:	75 19                	jne    801021e0 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801021c7:	8b 45 08             	mov    0x8(%ebp),%eax
801021ca:	8b 00                	mov    (%eax),%eax
801021cc:	89 04 24             	mov    %eax,(%esp)
801021cf:	e8 b2 f7 ff ff       	call   80101986 <balloc>
801021d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021d7:	8b 45 08             	mov    0x8(%ebp),%eax
801021da:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021dd:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
801021e0:	8b 45 08             	mov    0x8(%ebp),%eax
801021e3:	8b 00                	mov    (%eax),%eax
801021e5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021e8:	89 54 24 04          	mov    %edx,0x4(%esp)
801021ec:	89 04 24             	mov    %eax,(%esp)
801021ef:	e8 b2 df ff ff       	call   801001a6 <bread>
801021f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
801021f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021fa:	83 c0 18             	add    $0x18,%eax
801021fd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80102200:	8b 45 0c             	mov    0xc(%ebp),%eax
80102203:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010220a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010220d:	01 d0                	add    %edx,%eax
8010220f:	8b 00                	mov    (%eax),%eax
80102211:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102214:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102218:	75 30                	jne    8010224a <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
8010221a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010221d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102224:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102227:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010222a:	8b 45 08             	mov    0x8(%ebp),%eax
8010222d:	8b 00                	mov    (%eax),%eax
8010222f:	89 04 24             	mov    %eax,(%esp)
80102232:	e8 4f f7 ff ff       	call   80101986 <balloc>
80102237:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010223a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010223d:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
8010223f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102242:	89 04 24             	mov    %eax,(%esp)
80102245:	e8 60 1a 00 00       	call   80103caa <log_write>
    }
    brelse(bp);
8010224a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010224d:	89 04 24             	mov    %eax,(%esp)
80102250:	e8 c2 df ff ff       	call   80100217 <brelse>
    return addr;
80102255:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102258:	eb 0c                	jmp    80102266 <bmap+0x107>
  }

  panic("bmap: out of range");
8010225a:	c7 04 24 c0 8b 10 80 	movl   $0x80108bc0,(%esp)
80102261:	e8 d4 e2 ff ff       	call   8010053a <panic>
}
80102266:	83 c4 24             	add    $0x24,%esp
80102269:	5b                   	pop    %ebx
8010226a:	5d                   	pop    %ebp
8010226b:	c3                   	ret    

8010226c <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
8010226c:	55                   	push   %ebp
8010226d:	89 e5                	mov    %esp,%ebp
8010226f:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102272:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102279:	eb 44                	jmp    801022bf <itrunc+0x53>
    if(ip->addrs[i]){
8010227b:	8b 45 08             	mov    0x8(%ebp),%eax
8010227e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102281:	83 c2 04             	add    $0x4,%edx
80102284:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102288:	85 c0                	test   %eax,%eax
8010228a:	74 2f                	je     801022bb <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
8010228c:	8b 45 08             	mov    0x8(%ebp),%eax
8010228f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102292:	83 c2 04             	add    $0x4,%edx
80102295:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80102299:	8b 45 08             	mov    0x8(%ebp),%eax
8010229c:	8b 00                	mov    (%eax),%eax
8010229e:	89 54 24 04          	mov    %edx,0x4(%esp)
801022a2:	89 04 24             	mov    %eax,(%esp)
801022a5:	e8 1a f8 ff ff       	call   80101ac4 <bfree>
      ip->addrs[i] = 0;
801022aa:	8b 45 08             	mov    0x8(%ebp),%eax
801022ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022b0:	83 c2 04             	add    $0x4,%edx
801022b3:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801022ba:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801022bb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801022bf:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
801022c3:	7e b6                	jle    8010227b <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
801022c5:	8b 45 08             	mov    0x8(%ebp),%eax
801022c8:	8b 40 4c             	mov    0x4c(%eax),%eax
801022cb:	85 c0                	test   %eax,%eax
801022cd:	0f 84 9b 00 00 00    	je     8010236e <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801022d3:	8b 45 08             	mov    0x8(%ebp),%eax
801022d6:	8b 50 4c             	mov    0x4c(%eax),%edx
801022d9:	8b 45 08             	mov    0x8(%ebp),%eax
801022dc:	8b 00                	mov    (%eax),%eax
801022de:	89 54 24 04          	mov    %edx,0x4(%esp)
801022e2:	89 04 24             	mov    %eax,(%esp)
801022e5:	e8 bc de ff ff       	call   801001a6 <bread>
801022ea:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
801022ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022f0:	83 c0 18             	add    $0x18,%eax
801022f3:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
801022f6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801022fd:	eb 3b                	jmp    8010233a <itrunc+0xce>
      if(a[j])
801022ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102302:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102309:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010230c:	01 d0                	add    %edx,%eax
8010230e:	8b 00                	mov    (%eax),%eax
80102310:	85 c0                	test   %eax,%eax
80102312:	74 22                	je     80102336 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80102314:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102317:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010231e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102321:	01 d0                	add    %edx,%eax
80102323:	8b 10                	mov    (%eax),%edx
80102325:	8b 45 08             	mov    0x8(%ebp),%eax
80102328:	8b 00                	mov    (%eax),%eax
8010232a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010232e:	89 04 24             	mov    %eax,(%esp)
80102331:	e8 8e f7 ff ff       	call   80101ac4 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102336:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010233a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010233d:	83 f8 7f             	cmp    $0x7f,%eax
80102340:	76 bd                	jbe    801022ff <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80102342:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102345:	89 04 24             	mov    %eax,(%esp)
80102348:	e8 ca de ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
8010234d:	8b 45 08             	mov    0x8(%ebp),%eax
80102350:	8b 50 4c             	mov    0x4c(%eax),%edx
80102353:	8b 45 08             	mov    0x8(%ebp),%eax
80102356:	8b 00                	mov    (%eax),%eax
80102358:	89 54 24 04          	mov    %edx,0x4(%esp)
8010235c:	89 04 24             	mov    %eax,(%esp)
8010235f:	e8 60 f7 ff ff       	call   80101ac4 <bfree>
    ip->addrs[NDIRECT] = 0;
80102364:	8b 45 08             	mov    0x8(%ebp),%eax
80102367:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
8010236e:	8b 45 08             	mov    0x8(%ebp),%eax
80102371:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102378:	8b 45 08             	mov    0x8(%ebp),%eax
8010237b:	89 04 24             	mov    %eax,(%esp)
8010237e:	e8 72 f9 ff ff       	call   80101cf5 <iupdate>
}
80102383:	c9                   	leave  
80102384:	c3                   	ret    

80102385 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80102385:	55                   	push   %ebp
80102386:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80102388:	8b 45 08             	mov    0x8(%ebp),%eax
8010238b:	8b 00                	mov    (%eax),%eax
8010238d:	89 c2                	mov    %eax,%edx
8010238f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102392:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80102395:	8b 45 08             	mov    0x8(%ebp),%eax
80102398:	8b 50 04             	mov    0x4(%eax),%edx
8010239b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010239e:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
801023a1:	8b 45 08             	mov    0x8(%ebp),%eax
801023a4:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801023a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801023ab:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
801023ae:	8b 45 08             	mov    0x8(%ebp),%eax
801023b1:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801023b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801023b8:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
801023bc:	8b 45 08             	mov    0x8(%ebp),%eax
801023bf:	8b 50 18             	mov    0x18(%eax),%edx
801023c2:	8b 45 0c             	mov    0xc(%ebp),%eax
801023c5:	89 50 10             	mov    %edx,0x10(%eax)
}
801023c8:	5d                   	pop    %ebp
801023c9:	c3                   	ret    

801023ca <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
801023ca:	55                   	push   %ebp
801023cb:	89 e5                	mov    %esp,%ebp
801023cd:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
801023d0:	8b 45 08             	mov    0x8(%ebp),%eax
801023d3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801023d7:	66 83 f8 03          	cmp    $0x3,%ax
801023db:	75 60                	jne    8010243d <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801023dd:	8b 45 08             	mov    0x8(%ebp),%eax
801023e0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801023e4:	66 85 c0             	test   %ax,%ax
801023e7:	78 20                	js     80102409 <readi+0x3f>
801023e9:	8b 45 08             	mov    0x8(%ebp),%eax
801023ec:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801023f0:	66 83 f8 09          	cmp    $0x9,%ax
801023f4:	7f 13                	jg     80102409 <readi+0x3f>
801023f6:	8b 45 08             	mov    0x8(%ebp),%eax
801023f9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801023fd:	98                   	cwtl   
801023fe:	8b 04 c5 20 2a 11 80 	mov    -0x7feed5e0(,%eax,8),%eax
80102405:	85 c0                	test   %eax,%eax
80102407:	75 0a                	jne    80102413 <readi+0x49>
      return -1;
80102409:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010240e:	e9 19 01 00 00       	jmp    8010252c <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80102413:	8b 45 08             	mov    0x8(%ebp),%eax
80102416:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010241a:	98                   	cwtl   
8010241b:	8b 04 c5 20 2a 11 80 	mov    -0x7feed5e0(,%eax,8),%eax
80102422:	8b 55 14             	mov    0x14(%ebp),%edx
80102425:	89 54 24 08          	mov    %edx,0x8(%esp)
80102429:	8b 55 0c             	mov    0xc(%ebp),%edx
8010242c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102430:	8b 55 08             	mov    0x8(%ebp),%edx
80102433:	89 14 24             	mov    %edx,(%esp)
80102436:	ff d0                	call   *%eax
80102438:	e9 ef 00 00 00       	jmp    8010252c <readi+0x162>
  }

  if(off > ip->size || off + n < off)
8010243d:	8b 45 08             	mov    0x8(%ebp),%eax
80102440:	8b 40 18             	mov    0x18(%eax),%eax
80102443:	3b 45 10             	cmp    0x10(%ebp),%eax
80102446:	72 0d                	jb     80102455 <readi+0x8b>
80102448:	8b 45 14             	mov    0x14(%ebp),%eax
8010244b:	8b 55 10             	mov    0x10(%ebp),%edx
8010244e:	01 d0                	add    %edx,%eax
80102450:	3b 45 10             	cmp    0x10(%ebp),%eax
80102453:	73 0a                	jae    8010245f <readi+0x95>
    return -1;
80102455:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010245a:	e9 cd 00 00 00       	jmp    8010252c <readi+0x162>
  if(off + n > ip->size)
8010245f:	8b 45 14             	mov    0x14(%ebp),%eax
80102462:	8b 55 10             	mov    0x10(%ebp),%edx
80102465:	01 c2                	add    %eax,%edx
80102467:	8b 45 08             	mov    0x8(%ebp),%eax
8010246a:	8b 40 18             	mov    0x18(%eax),%eax
8010246d:	39 c2                	cmp    %eax,%edx
8010246f:	76 0c                	jbe    8010247d <readi+0xb3>
    n = ip->size - off;
80102471:	8b 45 08             	mov    0x8(%ebp),%eax
80102474:	8b 40 18             	mov    0x18(%eax),%eax
80102477:	2b 45 10             	sub    0x10(%ebp),%eax
8010247a:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010247d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102484:	e9 94 00 00 00       	jmp    8010251d <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102489:	8b 45 10             	mov    0x10(%ebp),%eax
8010248c:	c1 e8 09             	shr    $0x9,%eax
8010248f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102493:	8b 45 08             	mov    0x8(%ebp),%eax
80102496:	89 04 24             	mov    %eax,(%esp)
80102499:	e8 c1 fc ff ff       	call   8010215f <bmap>
8010249e:	8b 55 08             	mov    0x8(%ebp),%edx
801024a1:	8b 12                	mov    (%edx),%edx
801024a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801024a7:	89 14 24             	mov    %edx,(%esp)
801024aa:	e8 f7 dc ff ff       	call   801001a6 <bread>
801024af:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801024b2:	8b 45 10             	mov    0x10(%ebp),%eax
801024b5:	25 ff 01 00 00       	and    $0x1ff,%eax
801024ba:	89 c2                	mov    %eax,%edx
801024bc:	b8 00 02 00 00       	mov    $0x200,%eax
801024c1:	29 d0                	sub    %edx,%eax
801024c3:	89 c2                	mov    %eax,%edx
801024c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024c8:	8b 4d 14             	mov    0x14(%ebp),%ecx
801024cb:	29 c1                	sub    %eax,%ecx
801024cd:	89 c8                	mov    %ecx,%eax
801024cf:	39 c2                	cmp    %eax,%edx
801024d1:	0f 46 c2             	cmovbe %edx,%eax
801024d4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
801024d7:	8b 45 10             	mov    0x10(%ebp),%eax
801024da:	25 ff 01 00 00       	and    $0x1ff,%eax
801024df:	8d 50 10             	lea    0x10(%eax),%edx
801024e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024e5:	01 d0                	add    %edx,%eax
801024e7:	8d 50 08             	lea    0x8(%eax),%edx
801024ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
801024ed:	89 44 24 08          	mov    %eax,0x8(%esp)
801024f1:	89 54 24 04          	mov    %edx,0x4(%esp)
801024f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801024f8:	89 04 24             	mov    %eax,(%esp)
801024fb:	e8 aa 32 00 00       	call   801057aa <memmove>
    brelse(bp);
80102500:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102503:	89 04 24             	mov    %eax,(%esp)
80102506:	e8 0c dd ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010250b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010250e:	01 45 f4             	add    %eax,-0xc(%ebp)
80102511:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102514:	01 45 10             	add    %eax,0x10(%ebp)
80102517:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010251a:	01 45 0c             	add    %eax,0xc(%ebp)
8010251d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102520:	3b 45 14             	cmp    0x14(%ebp),%eax
80102523:	0f 82 60 ff ff ff    	jb     80102489 <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102529:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010252c:	c9                   	leave  
8010252d:	c3                   	ret    

8010252e <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
8010252e:	55                   	push   %ebp
8010252f:	89 e5                	mov    %esp,%ebp
80102531:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102534:	8b 45 08             	mov    0x8(%ebp),%eax
80102537:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010253b:	66 83 f8 03          	cmp    $0x3,%ax
8010253f:	75 60                	jne    801025a1 <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102541:	8b 45 08             	mov    0x8(%ebp),%eax
80102544:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102548:	66 85 c0             	test   %ax,%ax
8010254b:	78 20                	js     8010256d <writei+0x3f>
8010254d:	8b 45 08             	mov    0x8(%ebp),%eax
80102550:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102554:	66 83 f8 09          	cmp    $0x9,%ax
80102558:	7f 13                	jg     8010256d <writei+0x3f>
8010255a:	8b 45 08             	mov    0x8(%ebp),%eax
8010255d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102561:	98                   	cwtl   
80102562:	8b 04 c5 24 2a 11 80 	mov    -0x7feed5dc(,%eax,8),%eax
80102569:	85 c0                	test   %eax,%eax
8010256b:	75 0a                	jne    80102577 <writei+0x49>
      return -1;
8010256d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102572:	e9 44 01 00 00       	jmp    801026bb <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
80102577:	8b 45 08             	mov    0x8(%ebp),%eax
8010257a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010257e:	98                   	cwtl   
8010257f:	8b 04 c5 24 2a 11 80 	mov    -0x7feed5dc(,%eax,8),%eax
80102586:	8b 55 14             	mov    0x14(%ebp),%edx
80102589:	89 54 24 08          	mov    %edx,0x8(%esp)
8010258d:	8b 55 0c             	mov    0xc(%ebp),%edx
80102590:	89 54 24 04          	mov    %edx,0x4(%esp)
80102594:	8b 55 08             	mov    0x8(%ebp),%edx
80102597:	89 14 24             	mov    %edx,(%esp)
8010259a:	ff d0                	call   *%eax
8010259c:	e9 1a 01 00 00       	jmp    801026bb <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
801025a1:	8b 45 08             	mov    0x8(%ebp),%eax
801025a4:	8b 40 18             	mov    0x18(%eax),%eax
801025a7:	3b 45 10             	cmp    0x10(%ebp),%eax
801025aa:	72 0d                	jb     801025b9 <writei+0x8b>
801025ac:	8b 45 14             	mov    0x14(%ebp),%eax
801025af:	8b 55 10             	mov    0x10(%ebp),%edx
801025b2:	01 d0                	add    %edx,%eax
801025b4:	3b 45 10             	cmp    0x10(%ebp),%eax
801025b7:	73 0a                	jae    801025c3 <writei+0x95>
    return -1;
801025b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025be:	e9 f8 00 00 00       	jmp    801026bb <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
801025c3:	8b 45 14             	mov    0x14(%ebp),%eax
801025c6:	8b 55 10             	mov    0x10(%ebp),%edx
801025c9:	01 d0                	add    %edx,%eax
801025cb:	3d 00 18 01 00       	cmp    $0x11800,%eax
801025d0:	76 0a                	jbe    801025dc <writei+0xae>
    return -1;
801025d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025d7:	e9 df 00 00 00       	jmp    801026bb <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801025dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801025e3:	e9 9f 00 00 00       	jmp    80102687 <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801025e8:	8b 45 10             	mov    0x10(%ebp),%eax
801025eb:	c1 e8 09             	shr    $0x9,%eax
801025ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801025f2:	8b 45 08             	mov    0x8(%ebp),%eax
801025f5:	89 04 24             	mov    %eax,(%esp)
801025f8:	e8 62 fb ff ff       	call   8010215f <bmap>
801025fd:	8b 55 08             	mov    0x8(%ebp),%edx
80102600:	8b 12                	mov    (%edx),%edx
80102602:	89 44 24 04          	mov    %eax,0x4(%esp)
80102606:	89 14 24             	mov    %edx,(%esp)
80102609:	e8 98 db ff ff       	call   801001a6 <bread>
8010260e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102611:	8b 45 10             	mov    0x10(%ebp),%eax
80102614:	25 ff 01 00 00       	and    $0x1ff,%eax
80102619:	89 c2                	mov    %eax,%edx
8010261b:	b8 00 02 00 00       	mov    $0x200,%eax
80102620:	29 d0                	sub    %edx,%eax
80102622:	89 c2                	mov    %eax,%edx
80102624:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102627:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010262a:	29 c1                	sub    %eax,%ecx
8010262c:	89 c8                	mov    %ecx,%eax
8010262e:	39 c2                	cmp    %eax,%edx
80102630:	0f 46 c2             	cmovbe %edx,%eax
80102633:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102636:	8b 45 10             	mov    0x10(%ebp),%eax
80102639:	25 ff 01 00 00       	and    $0x1ff,%eax
8010263e:	8d 50 10             	lea    0x10(%eax),%edx
80102641:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102644:	01 d0                	add    %edx,%eax
80102646:	8d 50 08             	lea    0x8(%eax),%edx
80102649:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010264c:	89 44 24 08          	mov    %eax,0x8(%esp)
80102650:	8b 45 0c             	mov    0xc(%ebp),%eax
80102653:	89 44 24 04          	mov    %eax,0x4(%esp)
80102657:	89 14 24             	mov    %edx,(%esp)
8010265a:	e8 4b 31 00 00       	call   801057aa <memmove>
    log_write(bp);
8010265f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102662:	89 04 24             	mov    %eax,(%esp)
80102665:	e8 40 16 00 00       	call   80103caa <log_write>
    brelse(bp);
8010266a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010266d:	89 04 24             	mov    %eax,(%esp)
80102670:	e8 a2 db ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102675:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102678:	01 45 f4             	add    %eax,-0xc(%ebp)
8010267b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010267e:	01 45 10             	add    %eax,0x10(%ebp)
80102681:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102684:	01 45 0c             	add    %eax,0xc(%ebp)
80102687:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010268a:	3b 45 14             	cmp    0x14(%ebp),%eax
8010268d:	0f 82 55 ff ff ff    	jb     801025e8 <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102693:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102697:	74 1f                	je     801026b8 <writei+0x18a>
80102699:	8b 45 08             	mov    0x8(%ebp),%eax
8010269c:	8b 40 18             	mov    0x18(%eax),%eax
8010269f:	3b 45 10             	cmp    0x10(%ebp),%eax
801026a2:	73 14                	jae    801026b8 <writei+0x18a>
    ip->size = off;
801026a4:	8b 45 08             	mov    0x8(%ebp),%eax
801026a7:	8b 55 10             	mov    0x10(%ebp),%edx
801026aa:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
801026ad:	8b 45 08             	mov    0x8(%ebp),%eax
801026b0:	89 04 24             	mov    %eax,(%esp)
801026b3:	e8 3d f6 ff ff       	call   80101cf5 <iupdate>
  }
  return n;
801026b8:	8b 45 14             	mov    0x14(%ebp),%eax
}
801026bb:	c9                   	leave  
801026bc:	c3                   	ret    

801026bd <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801026bd:	55                   	push   %ebp
801026be:	89 e5                	mov    %esp,%ebp
801026c0:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801026c3:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801026ca:	00 
801026cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801026ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801026d2:	8b 45 08             	mov    0x8(%ebp),%eax
801026d5:	89 04 24             	mov    %eax,(%esp)
801026d8:	e8 70 31 00 00       	call   8010584d <strncmp>
}
801026dd:	c9                   	leave  
801026de:	c3                   	ret    

801026df <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801026df:	55                   	push   %ebp
801026e0:	89 e5                	mov    %esp,%ebp
801026e2:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801026e5:	8b 45 08             	mov    0x8(%ebp),%eax
801026e8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801026ec:	66 83 f8 01          	cmp    $0x1,%ax
801026f0:	74 0c                	je     801026fe <dirlookup+0x1f>
    panic("dirlookup not DIR");
801026f2:	c7 04 24 d3 8b 10 80 	movl   $0x80108bd3,(%esp)
801026f9:	e8 3c de ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801026fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102705:	e9 88 00 00 00       	jmp    80102792 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010270a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102711:	00 
80102712:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102715:	89 44 24 08          	mov    %eax,0x8(%esp)
80102719:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010271c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102720:	8b 45 08             	mov    0x8(%ebp),%eax
80102723:	89 04 24             	mov    %eax,(%esp)
80102726:	e8 9f fc ff ff       	call   801023ca <readi>
8010272b:	83 f8 10             	cmp    $0x10,%eax
8010272e:	74 0c                	je     8010273c <dirlookup+0x5d>
      panic("dirlink read");
80102730:	c7 04 24 e5 8b 10 80 	movl   $0x80108be5,(%esp)
80102737:	e8 fe dd ff ff       	call   8010053a <panic>
    if(de.inum == 0)
8010273c:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102740:	66 85 c0             	test   %ax,%ax
80102743:	75 02                	jne    80102747 <dirlookup+0x68>
      continue;
80102745:	eb 47                	jmp    8010278e <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
80102747:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010274a:	83 c0 02             	add    $0x2,%eax
8010274d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102751:	8b 45 0c             	mov    0xc(%ebp),%eax
80102754:	89 04 24             	mov    %eax,(%esp)
80102757:	e8 61 ff ff ff       	call   801026bd <namecmp>
8010275c:	85 c0                	test   %eax,%eax
8010275e:	75 2e                	jne    8010278e <dirlookup+0xaf>
      // entry matches path element
      if(poff)
80102760:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102764:	74 08                	je     8010276e <dirlookup+0x8f>
        *poff = off;
80102766:	8b 45 10             	mov    0x10(%ebp),%eax
80102769:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010276c:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010276e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102772:	0f b7 c0             	movzwl %ax,%eax
80102775:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102778:	8b 45 08             	mov    0x8(%ebp),%eax
8010277b:	8b 00                	mov    (%eax),%eax
8010277d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102780:	89 54 24 04          	mov    %edx,0x4(%esp)
80102784:	89 04 24             	mov    %eax,(%esp)
80102787:	e8 27 f6 ff ff       	call   80101db3 <iget>
8010278c:	eb 18                	jmp    801027a6 <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010278e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102792:	8b 45 08             	mov    0x8(%ebp),%eax
80102795:	8b 40 18             	mov    0x18(%eax),%eax
80102798:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010279b:	0f 87 69 ff ff ff    	ja     8010270a <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801027a1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801027a6:	c9                   	leave  
801027a7:	c3                   	ret    

801027a8 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801027a8:	55                   	push   %ebp
801027a9:	89 e5                	mov    %esp,%ebp
801027ab:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801027ae:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801027b5:	00 
801027b6:	8b 45 0c             	mov    0xc(%ebp),%eax
801027b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801027bd:	8b 45 08             	mov    0x8(%ebp),%eax
801027c0:	89 04 24             	mov    %eax,(%esp)
801027c3:	e8 17 ff ff ff       	call   801026df <dirlookup>
801027c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801027cb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801027cf:	74 15                	je     801027e6 <dirlink+0x3e>
    iput(ip);
801027d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027d4:	89 04 24             	mov    %eax,(%esp)
801027d7:	e8 94 f8 ff ff       	call   80102070 <iput>
    return -1;
801027dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801027e1:	e9 b7 00 00 00       	jmp    8010289d <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801027e6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801027ed:	eb 46                	jmp    80102835 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801027ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027f2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801027f9:	00 
801027fa:	89 44 24 08          	mov    %eax,0x8(%esp)
801027fe:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102801:	89 44 24 04          	mov    %eax,0x4(%esp)
80102805:	8b 45 08             	mov    0x8(%ebp),%eax
80102808:	89 04 24             	mov    %eax,(%esp)
8010280b:	e8 ba fb ff ff       	call   801023ca <readi>
80102810:	83 f8 10             	cmp    $0x10,%eax
80102813:	74 0c                	je     80102821 <dirlink+0x79>
      panic("dirlink read");
80102815:	c7 04 24 e5 8b 10 80 	movl   $0x80108be5,(%esp)
8010281c:	e8 19 dd ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102821:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102825:	66 85 c0             	test   %ax,%ax
80102828:	75 02                	jne    8010282c <dirlink+0x84>
      break;
8010282a:	eb 16                	jmp    80102842 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010282c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010282f:	83 c0 10             	add    $0x10,%eax
80102832:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102835:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102838:	8b 45 08             	mov    0x8(%ebp),%eax
8010283b:	8b 40 18             	mov    0x18(%eax),%eax
8010283e:	39 c2                	cmp    %eax,%edx
80102840:	72 ad                	jb     801027ef <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
80102842:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102849:	00 
8010284a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010284d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102851:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102854:	83 c0 02             	add    $0x2,%eax
80102857:	89 04 24             	mov    %eax,(%esp)
8010285a:	e8 44 30 00 00       	call   801058a3 <strncpy>
  de.inum = inum;
8010285f:	8b 45 10             	mov    0x10(%ebp),%eax
80102862:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102866:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102869:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102870:	00 
80102871:	89 44 24 08          	mov    %eax,0x8(%esp)
80102875:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102878:	89 44 24 04          	mov    %eax,0x4(%esp)
8010287c:	8b 45 08             	mov    0x8(%ebp),%eax
8010287f:	89 04 24             	mov    %eax,(%esp)
80102882:	e8 a7 fc ff ff       	call   8010252e <writei>
80102887:	83 f8 10             	cmp    $0x10,%eax
8010288a:	74 0c                	je     80102898 <dirlink+0xf0>
    panic("dirlink");
8010288c:	c7 04 24 f2 8b 10 80 	movl   $0x80108bf2,(%esp)
80102893:	e8 a2 dc ff ff       	call   8010053a <panic>
  
  return 0;
80102898:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010289d:	c9                   	leave  
8010289e:	c3                   	ret    

8010289f <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
8010289f:	55                   	push   %ebp
801028a0:	89 e5                	mov    %esp,%ebp
801028a2:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801028a5:	eb 04                	jmp    801028ab <skipelem+0xc>
    path++;
801028a7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801028ab:	8b 45 08             	mov    0x8(%ebp),%eax
801028ae:	0f b6 00             	movzbl (%eax),%eax
801028b1:	3c 2f                	cmp    $0x2f,%al
801028b3:	74 f2                	je     801028a7 <skipelem+0x8>
    path++;
  if(*path == 0)
801028b5:	8b 45 08             	mov    0x8(%ebp),%eax
801028b8:	0f b6 00             	movzbl (%eax),%eax
801028bb:	84 c0                	test   %al,%al
801028bd:	75 0a                	jne    801028c9 <skipelem+0x2a>
    return 0;
801028bf:	b8 00 00 00 00       	mov    $0x0,%eax
801028c4:	e9 86 00 00 00       	jmp    8010294f <skipelem+0xb0>
  s = path;
801028c9:	8b 45 08             	mov    0x8(%ebp),%eax
801028cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801028cf:	eb 04                	jmp    801028d5 <skipelem+0x36>
    path++;
801028d1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801028d5:	8b 45 08             	mov    0x8(%ebp),%eax
801028d8:	0f b6 00             	movzbl (%eax),%eax
801028db:	3c 2f                	cmp    $0x2f,%al
801028dd:	74 0a                	je     801028e9 <skipelem+0x4a>
801028df:	8b 45 08             	mov    0x8(%ebp),%eax
801028e2:	0f b6 00             	movzbl (%eax),%eax
801028e5:	84 c0                	test   %al,%al
801028e7:	75 e8                	jne    801028d1 <skipelem+0x32>
    path++;
  len = path - s;
801028e9:	8b 55 08             	mov    0x8(%ebp),%edx
801028ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ef:	29 c2                	sub    %eax,%edx
801028f1:	89 d0                	mov    %edx,%eax
801028f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801028f6:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801028fa:	7e 1c                	jle    80102918 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
801028fc:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102903:	00 
80102904:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102907:	89 44 24 04          	mov    %eax,0x4(%esp)
8010290b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010290e:	89 04 24             	mov    %eax,(%esp)
80102911:	e8 94 2e 00 00       	call   801057aa <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102916:	eb 2a                	jmp    80102942 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102918:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010291b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010291f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102922:	89 44 24 04          	mov    %eax,0x4(%esp)
80102926:	8b 45 0c             	mov    0xc(%ebp),%eax
80102929:	89 04 24             	mov    %eax,(%esp)
8010292c:	e8 79 2e 00 00       	call   801057aa <memmove>
    name[len] = 0;
80102931:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102934:	8b 45 0c             	mov    0xc(%ebp),%eax
80102937:	01 d0                	add    %edx,%eax
80102939:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010293c:	eb 04                	jmp    80102942 <skipelem+0xa3>
    path++;
8010293e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102942:	8b 45 08             	mov    0x8(%ebp),%eax
80102945:	0f b6 00             	movzbl (%eax),%eax
80102948:	3c 2f                	cmp    $0x2f,%al
8010294a:	74 f2                	je     8010293e <skipelem+0x9f>
    path++;
  return path;
8010294c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010294f:	c9                   	leave  
80102950:	c3                   	ret    

80102951 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102951:	55                   	push   %ebp
80102952:	89 e5                	mov    %esp,%ebp
80102954:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102957:	8b 45 08             	mov    0x8(%ebp),%eax
8010295a:	0f b6 00             	movzbl (%eax),%eax
8010295d:	3c 2f                	cmp    $0x2f,%al
8010295f:	75 1c                	jne    8010297d <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102961:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102968:	00 
80102969:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102970:	e8 3e f4 ff ff       	call   80101db3 <iget>
80102975:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102978:	e9 af 00 00 00       	jmp    80102a2c <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010297d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102983:	8b 40 68             	mov    0x68(%eax),%eax
80102986:	89 04 24             	mov    %eax,(%esp)
80102989:	e8 f7 f4 ff ff       	call   80101e85 <idup>
8010298e:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102991:	e9 96 00 00 00       	jmp    80102a2c <namex+0xdb>
    ilock(ip);
80102996:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102999:	89 04 24             	mov    %eax,(%esp)
8010299c:	e8 16 f5 ff ff       	call   80101eb7 <ilock>
    if(ip->type != T_DIR){
801029a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029a4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801029a8:	66 83 f8 01          	cmp    $0x1,%ax
801029ac:	74 15                	je     801029c3 <namex+0x72>
      iunlockput(ip);
801029ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029b1:	89 04 24             	mov    %eax,(%esp)
801029b4:	e8 88 f7 ff ff       	call   80102141 <iunlockput>
      return 0;
801029b9:	b8 00 00 00 00       	mov    $0x0,%eax
801029be:	e9 a3 00 00 00       	jmp    80102a66 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801029c3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801029c7:	74 1d                	je     801029e6 <namex+0x95>
801029c9:	8b 45 08             	mov    0x8(%ebp),%eax
801029cc:	0f b6 00             	movzbl (%eax),%eax
801029cf:	84 c0                	test   %al,%al
801029d1:	75 13                	jne    801029e6 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
801029d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029d6:	89 04 24             	mov    %eax,(%esp)
801029d9:	e8 2d f6 ff ff       	call   8010200b <iunlock>
      return ip;
801029de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e1:	e9 80 00 00 00       	jmp    80102a66 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801029e6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801029ed:	00 
801029ee:	8b 45 10             	mov    0x10(%ebp),%eax
801029f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801029f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f8:	89 04 24             	mov    %eax,(%esp)
801029fb:	e8 df fc ff ff       	call   801026df <dirlookup>
80102a00:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102a03:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102a07:	75 12                	jne    80102a1b <namex+0xca>
      iunlockput(ip);
80102a09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a0c:	89 04 24             	mov    %eax,(%esp)
80102a0f:	e8 2d f7 ff ff       	call   80102141 <iunlockput>
      return 0;
80102a14:	b8 00 00 00 00       	mov    $0x0,%eax
80102a19:	eb 4b                	jmp    80102a66 <namex+0x115>
    }
    iunlockput(ip);
80102a1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a1e:	89 04 24             	mov    %eax,(%esp)
80102a21:	e8 1b f7 ff ff       	call   80102141 <iunlockput>
    ip = next;
80102a26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a29:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102a2c:	8b 45 10             	mov    0x10(%ebp),%eax
80102a2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a33:	8b 45 08             	mov    0x8(%ebp),%eax
80102a36:	89 04 24             	mov    %eax,(%esp)
80102a39:	e8 61 fe ff ff       	call   8010289f <skipelem>
80102a3e:	89 45 08             	mov    %eax,0x8(%ebp)
80102a41:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102a45:	0f 85 4b ff ff ff    	jne    80102996 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102a4b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102a4f:	74 12                	je     80102a63 <namex+0x112>
    iput(ip);
80102a51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a54:	89 04 24             	mov    %eax,(%esp)
80102a57:	e8 14 f6 ff ff       	call   80102070 <iput>
    return 0;
80102a5c:	b8 00 00 00 00       	mov    $0x0,%eax
80102a61:	eb 03                	jmp    80102a66 <namex+0x115>
  }
  return ip;
80102a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102a66:	c9                   	leave  
80102a67:	c3                   	ret    

80102a68 <namei>:

struct inode*
namei(char *path)
{
80102a68:	55                   	push   %ebp
80102a69:	89 e5                	mov    %esp,%ebp
80102a6b:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102a6e:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102a71:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a75:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a7c:	00 
80102a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a80:	89 04 24             	mov    %eax,(%esp)
80102a83:	e8 c9 fe ff ff       	call   80102951 <namex>
}
80102a88:	c9                   	leave  
80102a89:	c3                   	ret    

80102a8a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102a8a:	55                   	push   %ebp
80102a8b:	89 e5                	mov    %esp,%ebp
80102a8d:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102a90:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a93:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a97:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102a9e:	00 
80102a9f:	8b 45 08             	mov    0x8(%ebp),%eax
80102aa2:	89 04 24             	mov    %eax,(%esp)
80102aa5:	e8 a7 fe ff ff       	call   80102951 <namex>
}
80102aaa:	c9                   	leave  
80102aab:	c3                   	ret    

80102aac <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102aac:	55                   	push   %ebp
80102aad:	89 e5                	mov    %esp,%ebp
80102aaf:	83 ec 14             	sub    $0x14,%esp
80102ab2:	8b 45 08             	mov    0x8(%ebp),%eax
80102ab5:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ab9:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102abd:	89 c2                	mov    %eax,%edx
80102abf:	ec                   	in     (%dx),%al
80102ac0:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102ac3:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102ac7:	c9                   	leave  
80102ac8:	c3                   	ret    

80102ac9 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102ac9:	55                   	push   %ebp
80102aca:	89 e5                	mov    %esp,%ebp
80102acc:	57                   	push   %edi
80102acd:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102ace:	8b 55 08             	mov    0x8(%ebp),%edx
80102ad1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102ad4:	8b 45 10             	mov    0x10(%ebp),%eax
80102ad7:	89 cb                	mov    %ecx,%ebx
80102ad9:	89 df                	mov    %ebx,%edi
80102adb:	89 c1                	mov    %eax,%ecx
80102add:	fc                   	cld    
80102ade:	f3 6d                	rep insl (%dx),%es:(%edi)
80102ae0:	89 c8                	mov    %ecx,%eax
80102ae2:	89 fb                	mov    %edi,%ebx
80102ae4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102ae7:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102aea:	5b                   	pop    %ebx
80102aeb:	5f                   	pop    %edi
80102aec:	5d                   	pop    %ebp
80102aed:	c3                   	ret    

80102aee <outb>:

static inline void
outb(ushort port, uchar data)
{
80102aee:	55                   	push   %ebp
80102aef:	89 e5                	mov    %esp,%ebp
80102af1:	83 ec 08             	sub    $0x8,%esp
80102af4:	8b 55 08             	mov    0x8(%ebp),%edx
80102af7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102afa:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102afe:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102b01:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102b05:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102b09:	ee                   	out    %al,(%dx)
}
80102b0a:	c9                   	leave  
80102b0b:	c3                   	ret    

80102b0c <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102b0c:	55                   	push   %ebp
80102b0d:	89 e5                	mov    %esp,%ebp
80102b0f:	56                   	push   %esi
80102b10:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102b11:	8b 55 08             	mov    0x8(%ebp),%edx
80102b14:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b17:	8b 45 10             	mov    0x10(%ebp),%eax
80102b1a:	89 cb                	mov    %ecx,%ebx
80102b1c:	89 de                	mov    %ebx,%esi
80102b1e:	89 c1                	mov    %eax,%ecx
80102b20:	fc                   	cld    
80102b21:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102b23:	89 c8                	mov    %ecx,%eax
80102b25:	89 f3                	mov    %esi,%ebx
80102b27:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b2a:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102b2d:	5b                   	pop    %ebx
80102b2e:	5e                   	pop    %esi
80102b2f:	5d                   	pop    %ebp
80102b30:	c3                   	ret    

80102b31 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102b31:	55                   	push   %ebp
80102b32:	89 e5                	mov    %esp,%ebp
80102b34:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102b37:	90                   	nop
80102b38:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102b3f:	e8 68 ff ff ff       	call   80102aac <inb>
80102b44:	0f b6 c0             	movzbl %al,%eax
80102b47:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102b4a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102b4d:	25 c0 00 00 00       	and    $0xc0,%eax
80102b52:	83 f8 40             	cmp    $0x40,%eax
80102b55:	75 e1                	jne    80102b38 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102b57:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102b5b:	74 11                	je     80102b6e <idewait+0x3d>
80102b5d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102b60:	83 e0 21             	and    $0x21,%eax
80102b63:	85 c0                	test   %eax,%eax
80102b65:	74 07                	je     80102b6e <idewait+0x3d>
    return -1;
80102b67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102b6c:	eb 05                	jmp    80102b73 <idewait+0x42>
  return 0;
80102b6e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102b73:	c9                   	leave  
80102b74:	c3                   	ret    

80102b75 <ideinit>:

void
ideinit(void)
{
80102b75:	55                   	push   %ebp
80102b76:	89 e5                	mov    %esp,%ebp
80102b78:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102b7b:	c7 44 24 04 fa 8b 10 	movl   $0x80108bfa,0x4(%esp)
80102b82:	80 
80102b83:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102b8a:	e8 d7 28 00 00       	call   80105466 <initlock>
  picenable(IRQ_IDE);
80102b8f:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102b96:	e8 a3 18 00 00       	call   8010443e <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102b9b:	a1 a0 41 11 80       	mov    0x801141a0,%eax
80102ba0:	83 e8 01             	sub    $0x1,%eax
80102ba3:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ba7:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102bae:	e8 43 04 00 00       	call   80102ff6 <ioapicenable>
  idewait(0);
80102bb3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102bba:	e8 72 ff ff ff       	call   80102b31 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102bbf:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102bc6:	00 
80102bc7:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102bce:	e8 1b ff ff ff       	call   80102aee <outb>
  for(i=0; i<1000; i++){
80102bd3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102bda:	eb 20                	jmp    80102bfc <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102bdc:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102be3:	e8 c4 fe ff ff       	call   80102aac <inb>
80102be8:	84 c0                	test   %al,%al
80102bea:	74 0c                	je     80102bf8 <ideinit+0x83>
      havedisk1 = 1;
80102bec:	c7 05 38 c6 10 80 01 	movl   $0x1,0x8010c638
80102bf3:	00 00 00 
      break;
80102bf6:	eb 0d                	jmp    80102c05 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102bf8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102bfc:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102c03:	7e d7                	jle    80102bdc <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102c05:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102c0c:	00 
80102c0d:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c14:	e8 d5 fe ff ff       	call   80102aee <outb>
}
80102c19:	c9                   	leave  
80102c1a:	c3                   	ret    

80102c1b <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102c1b:	55                   	push   %ebp
80102c1c:	89 e5                	mov    %esp,%ebp
80102c1e:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102c21:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102c25:	75 0c                	jne    80102c33 <idestart+0x18>
    panic("idestart");
80102c27:	c7 04 24 fe 8b 10 80 	movl   $0x80108bfe,(%esp)
80102c2e:	e8 07 d9 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102c33:	8b 45 08             	mov    0x8(%ebp),%eax
80102c36:	8b 40 08             	mov    0x8(%eax),%eax
80102c39:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102c3e:	76 0c                	jbe    80102c4c <idestart+0x31>
    panic("incorrect blockno");
80102c40:	c7 04 24 07 8c 10 80 	movl   $0x80108c07,(%esp)
80102c47:	e8 ee d8 ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102c4c:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102c53:	8b 45 08             	mov    0x8(%ebp),%eax
80102c56:	8b 50 08             	mov    0x8(%eax),%edx
80102c59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c5c:	0f af c2             	imul   %edx,%eax
80102c5f:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102c62:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102c66:	7e 0c                	jle    80102c74 <idestart+0x59>
80102c68:	c7 04 24 fe 8b 10 80 	movl   $0x80108bfe,(%esp)
80102c6f:	e8 c6 d8 ff ff       	call   8010053a <panic>
  
  idewait(0);
80102c74:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102c7b:	e8 b1 fe ff ff       	call   80102b31 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102c80:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102c87:	00 
80102c88:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102c8f:	e8 5a fe ff ff       	call   80102aee <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102c94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c97:	0f b6 c0             	movzbl %al,%eax
80102c9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c9e:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102ca5:	e8 44 fe ff ff       	call   80102aee <outb>
  outb(0x1f3, sector & 0xff);
80102caa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102cad:	0f b6 c0             	movzbl %al,%eax
80102cb0:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cb4:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102cbb:	e8 2e fe ff ff       	call   80102aee <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102cc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102cc3:	c1 f8 08             	sar    $0x8,%eax
80102cc6:	0f b6 c0             	movzbl %al,%eax
80102cc9:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ccd:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102cd4:	e8 15 fe ff ff       	call   80102aee <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102cd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102cdc:	c1 f8 10             	sar    $0x10,%eax
80102cdf:	0f b6 c0             	movzbl %al,%eax
80102ce2:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ce6:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102ced:	e8 fc fd ff ff       	call   80102aee <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102cf2:	8b 45 08             	mov    0x8(%ebp),%eax
80102cf5:	8b 40 04             	mov    0x4(%eax),%eax
80102cf8:	83 e0 01             	and    $0x1,%eax
80102cfb:	c1 e0 04             	shl    $0x4,%eax
80102cfe:	89 c2                	mov    %eax,%edx
80102d00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d03:	c1 f8 18             	sar    $0x18,%eax
80102d06:	83 e0 0f             	and    $0xf,%eax
80102d09:	09 d0                	or     %edx,%eax
80102d0b:	83 c8 e0             	or     $0xffffffe0,%eax
80102d0e:	0f b6 c0             	movzbl %al,%eax
80102d11:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d15:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102d1c:	e8 cd fd ff ff       	call   80102aee <outb>
  if(b->flags & B_DIRTY){
80102d21:	8b 45 08             	mov    0x8(%ebp),%eax
80102d24:	8b 00                	mov    (%eax),%eax
80102d26:	83 e0 04             	and    $0x4,%eax
80102d29:	85 c0                	test   %eax,%eax
80102d2b:	74 34                	je     80102d61 <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102d2d:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102d34:	00 
80102d35:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102d3c:	e8 ad fd ff ff       	call   80102aee <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102d41:	8b 45 08             	mov    0x8(%ebp),%eax
80102d44:	83 c0 18             	add    $0x18,%eax
80102d47:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102d4e:	00 
80102d4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d53:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102d5a:	e8 ad fd ff ff       	call   80102b0c <outsl>
80102d5f:	eb 14                	jmp    80102d75 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102d61:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102d68:	00 
80102d69:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102d70:	e8 79 fd ff ff       	call   80102aee <outb>
  }
}
80102d75:	c9                   	leave  
80102d76:	c3                   	ret    

80102d77 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102d77:	55                   	push   %ebp
80102d78:	89 e5                	mov    %esp,%ebp
80102d7a:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102d7d:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102d84:	e8 fe 26 00 00       	call   80105487 <acquire>
  if((b = idequeue) == 0){
80102d89:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102d8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102d91:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102d95:	75 11                	jne    80102da8 <ideintr+0x31>
    release(&idelock);
80102d97:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102d9e:	e8 46 27 00 00       	call   801054e9 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102da3:	e9 90 00 00 00       	jmp    80102e38 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102da8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dab:	8b 40 14             	mov    0x14(%eax),%eax
80102dae:	a3 34 c6 10 80       	mov    %eax,0x8010c634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102db3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102db6:	8b 00                	mov    (%eax),%eax
80102db8:	83 e0 04             	and    $0x4,%eax
80102dbb:	85 c0                	test   %eax,%eax
80102dbd:	75 2e                	jne    80102ded <ideintr+0x76>
80102dbf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102dc6:	e8 66 fd ff ff       	call   80102b31 <idewait>
80102dcb:	85 c0                	test   %eax,%eax
80102dcd:	78 1e                	js     80102ded <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dd2:	83 c0 18             	add    $0x18,%eax
80102dd5:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102ddc:	00 
80102ddd:	89 44 24 04          	mov    %eax,0x4(%esp)
80102de1:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102de8:	e8 dc fc ff ff       	call   80102ac9 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102ded:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102df0:	8b 00                	mov    (%eax),%eax
80102df2:	83 c8 02             	or     $0x2,%eax
80102df5:	89 c2                	mov    %eax,%edx
80102df7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dfa:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102dfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dff:	8b 00                	mov    (%eax),%eax
80102e01:	83 e0 fb             	and    $0xfffffffb,%eax
80102e04:	89 c2                	mov    %eax,%edx
80102e06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e09:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102e0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e0e:	89 04 24             	mov    %eax,(%esp)
80102e11:	e8 80 24 00 00       	call   80105296 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102e16:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102e1b:	85 c0                	test   %eax,%eax
80102e1d:	74 0d                	je     80102e2c <ideintr+0xb5>
    idestart(idequeue);
80102e1f:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102e24:	89 04 24             	mov    %eax,(%esp)
80102e27:	e8 ef fd ff ff       	call   80102c1b <idestart>

  release(&idelock);
80102e2c:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102e33:	e8 b1 26 00 00       	call   801054e9 <release>
}
80102e38:	c9                   	leave  
80102e39:	c3                   	ret    

80102e3a <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102e3a:	55                   	push   %ebp
80102e3b:	89 e5                	mov    %esp,%ebp
80102e3d:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102e40:	8b 45 08             	mov    0x8(%ebp),%eax
80102e43:	8b 00                	mov    (%eax),%eax
80102e45:	83 e0 01             	and    $0x1,%eax
80102e48:	85 c0                	test   %eax,%eax
80102e4a:	75 0c                	jne    80102e58 <iderw+0x1e>
    panic("iderw: buf not busy");
80102e4c:	c7 04 24 19 8c 10 80 	movl   $0x80108c19,(%esp)
80102e53:	e8 e2 d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102e58:	8b 45 08             	mov    0x8(%ebp),%eax
80102e5b:	8b 00                	mov    (%eax),%eax
80102e5d:	83 e0 06             	and    $0x6,%eax
80102e60:	83 f8 02             	cmp    $0x2,%eax
80102e63:	75 0c                	jne    80102e71 <iderw+0x37>
    panic("iderw: nothing to do");
80102e65:	c7 04 24 2d 8c 10 80 	movl   $0x80108c2d,(%esp)
80102e6c:	e8 c9 d6 ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102e71:	8b 45 08             	mov    0x8(%ebp),%eax
80102e74:	8b 40 04             	mov    0x4(%eax),%eax
80102e77:	85 c0                	test   %eax,%eax
80102e79:	74 15                	je     80102e90 <iderw+0x56>
80102e7b:	a1 38 c6 10 80       	mov    0x8010c638,%eax
80102e80:	85 c0                	test   %eax,%eax
80102e82:	75 0c                	jne    80102e90 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102e84:	c7 04 24 42 8c 10 80 	movl   $0x80108c42,(%esp)
80102e8b:	e8 aa d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102e90:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102e97:	e8 eb 25 00 00       	call   80105487 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102e9c:	8b 45 08             	mov    0x8(%ebp),%eax
80102e9f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102ea6:	c7 45 f4 34 c6 10 80 	movl   $0x8010c634,-0xc(%ebp)
80102ead:	eb 0b                	jmp    80102eba <iderw+0x80>
80102eaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102eb2:	8b 00                	mov    (%eax),%eax
80102eb4:	83 c0 14             	add    $0x14,%eax
80102eb7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102eba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ebd:	8b 00                	mov    (%eax),%eax
80102ebf:	85 c0                	test   %eax,%eax
80102ec1:	75 ec                	jne    80102eaf <iderw+0x75>
    ;
  *pp = b;
80102ec3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ec6:	8b 55 08             	mov    0x8(%ebp),%edx
80102ec9:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102ecb:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102ed0:	3b 45 08             	cmp    0x8(%ebp),%eax
80102ed3:	75 0d                	jne    80102ee2 <iderw+0xa8>
    idestart(b);
80102ed5:	8b 45 08             	mov    0x8(%ebp),%eax
80102ed8:	89 04 24             	mov    %eax,(%esp)
80102edb:	e8 3b fd ff ff       	call   80102c1b <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102ee0:	eb 15                	jmp    80102ef7 <iderw+0xbd>
80102ee2:	eb 13                	jmp    80102ef7 <iderw+0xbd>
    sleep(b, &idelock);
80102ee4:	c7 44 24 04 00 c6 10 	movl   $0x8010c600,0x4(%esp)
80102eeb:	80 
80102eec:	8b 45 08             	mov    0x8(%ebp),%eax
80102eef:	89 04 24             	mov    %eax,(%esp)
80102ef2:	e8 c6 22 00 00       	call   801051bd <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102ef7:	8b 45 08             	mov    0x8(%ebp),%eax
80102efa:	8b 00                	mov    (%eax),%eax
80102efc:	83 e0 06             	and    $0x6,%eax
80102eff:	83 f8 02             	cmp    $0x2,%eax
80102f02:	75 e0                	jne    80102ee4 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102f04:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102f0b:	e8 d9 25 00 00       	call   801054e9 <release>
}
80102f10:	c9                   	leave  
80102f11:	c3                   	ret    

80102f12 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102f12:	55                   	push   %ebp
80102f13:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102f15:	a1 74 3a 11 80       	mov    0x80113a74,%eax
80102f1a:	8b 55 08             	mov    0x8(%ebp),%edx
80102f1d:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102f1f:	a1 74 3a 11 80       	mov    0x80113a74,%eax
80102f24:	8b 40 10             	mov    0x10(%eax),%eax
}
80102f27:	5d                   	pop    %ebp
80102f28:	c3                   	ret    

80102f29 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102f29:	55                   	push   %ebp
80102f2a:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102f2c:	a1 74 3a 11 80       	mov    0x80113a74,%eax
80102f31:	8b 55 08             	mov    0x8(%ebp),%edx
80102f34:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102f36:	a1 74 3a 11 80       	mov    0x80113a74,%eax
80102f3b:	8b 55 0c             	mov    0xc(%ebp),%edx
80102f3e:	89 50 10             	mov    %edx,0x10(%eax)
}
80102f41:	5d                   	pop    %ebp
80102f42:	c3                   	ret    

80102f43 <ioapicinit>:

void
ioapicinit(void)
{
80102f43:	55                   	push   %ebp
80102f44:	89 e5                	mov    %esp,%ebp
80102f46:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102f49:	a1 a4 3b 11 80       	mov    0x80113ba4,%eax
80102f4e:	85 c0                	test   %eax,%eax
80102f50:	75 05                	jne    80102f57 <ioapicinit+0x14>
    return;
80102f52:	e9 9d 00 00 00       	jmp    80102ff4 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102f57:	c7 05 74 3a 11 80 00 	movl   $0xfec00000,0x80113a74
80102f5e:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102f61:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102f68:	e8 a5 ff ff ff       	call   80102f12 <ioapicread>
80102f6d:	c1 e8 10             	shr    $0x10,%eax
80102f70:	25 ff 00 00 00       	and    $0xff,%eax
80102f75:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102f78:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102f7f:	e8 8e ff ff ff       	call   80102f12 <ioapicread>
80102f84:	c1 e8 18             	shr    $0x18,%eax
80102f87:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102f8a:	0f b6 05 a0 3b 11 80 	movzbl 0x80113ba0,%eax
80102f91:	0f b6 c0             	movzbl %al,%eax
80102f94:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102f97:	74 0c                	je     80102fa5 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102f99:	c7 04 24 60 8c 10 80 	movl   $0x80108c60,(%esp)
80102fa0:	e8 fb d3 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102fa5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102fac:	eb 3e                	jmp    80102fec <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102fae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fb1:	83 c0 20             	add    $0x20,%eax
80102fb4:	0d 00 00 01 00       	or     $0x10000,%eax
80102fb9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102fbc:	83 c2 08             	add    $0x8,%edx
80102fbf:	01 d2                	add    %edx,%edx
80102fc1:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fc5:	89 14 24             	mov    %edx,(%esp)
80102fc8:	e8 5c ff ff ff       	call   80102f29 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102fcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fd0:	83 c0 08             	add    $0x8,%eax
80102fd3:	01 c0                	add    %eax,%eax
80102fd5:	83 c0 01             	add    $0x1,%eax
80102fd8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fdf:	00 
80102fe0:	89 04 24             	mov    %eax,(%esp)
80102fe3:	e8 41 ff ff ff       	call   80102f29 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102fe8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102fec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fef:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102ff2:	7e ba                	jle    80102fae <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102ff4:	c9                   	leave  
80102ff5:	c3                   	ret    

80102ff6 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102ff6:	55                   	push   %ebp
80102ff7:	89 e5                	mov    %esp,%ebp
80102ff9:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102ffc:	a1 a4 3b 11 80       	mov    0x80113ba4,%eax
80103001:	85 c0                	test   %eax,%eax
80103003:	75 02                	jne    80103007 <ioapicenable+0x11>
    return;
80103005:	eb 37                	jmp    8010303e <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103007:	8b 45 08             	mov    0x8(%ebp),%eax
8010300a:	83 c0 20             	add    $0x20,%eax
8010300d:	8b 55 08             	mov    0x8(%ebp),%edx
80103010:	83 c2 08             	add    $0x8,%edx
80103013:	01 d2                	add    %edx,%edx
80103015:	89 44 24 04          	mov    %eax,0x4(%esp)
80103019:	89 14 24             	mov    %edx,(%esp)
8010301c:	e8 08 ff ff ff       	call   80102f29 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103021:	8b 45 0c             	mov    0xc(%ebp),%eax
80103024:	c1 e0 18             	shl    $0x18,%eax
80103027:	8b 55 08             	mov    0x8(%ebp),%edx
8010302a:	83 c2 08             	add    $0x8,%edx
8010302d:	01 d2                	add    %edx,%edx
8010302f:	83 c2 01             	add    $0x1,%edx
80103032:	89 44 24 04          	mov    %eax,0x4(%esp)
80103036:	89 14 24             	mov    %edx,(%esp)
80103039:	e8 eb fe ff ff       	call   80102f29 <ioapicwrite>
}
8010303e:	c9                   	leave  
8010303f:	c3                   	ret    

80103040 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103040:	55                   	push   %ebp
80103041:	89 e5                	mov    %esp,%ebp
80103043:	8b 45 08             	mov    0x8(%ebp),%eax
80103046:	05 00 00 00 80       	add    $0x80000000,%eax
8010304b:	5d                   	pop    %ebp
8010304c:	c3                   	ret    

8010304d <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
8010304d:	55                   	push   %ebp
8010304e:	89 e5                	mov    %esp,%ebp
80103050:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103053:	c7 44 24 04 92 8c 10 	movl   $0x80108c92,0x4(%esp)
8010305a:	80 
8010305b:	c7 04 24 80 3a 11 80 	movl   $0x80113a80,(%esp)
80103062:	e8 ff 23 00 00       	call   80105466 <initlock>
  kmem.use_lock = 0;
80103067:	c7 05 b4 3a 11 80 00 	movl   $0x0,0x80113ab4
8010306e:	00 00 00 
  freerange(vstart, vend);
80103071:	8b 45 0c             	mov    0xc(%ebp),%eax
80103074:	89 44 24 04          	mov    %eax,0x4(%esp)
80103078:	8b 45 08             	mov    0x8(%ebp),%eax
8010307b:	89 04 24             	mov    %eax,(%esp)
8010307e:	e8 26 00 00 00       	call   801030a9 <freerange>
}
80103083:	c9                   	leave  
80103084:	c3                   	ret    

80103085 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103085:	55                   	push   %ebp
80103086:	89 e5                	mov    %esp,%ebp
80103088:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
8010308b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010308e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103092:	8b 45 08             	mov    0x8(%ebp),%eax
80103095:	89 04 24             	mov    %eax,(%esp)
80103098:	e8 0c 00 00 00       	call   801030a9 <freerange>
  kmem.use_lock = 1;
8010309d:	c7 05 b4 3a 11 80 01 	movl   $0x1,0x80113ab4
801030a4:	00 00 00 
}
801030a7:	c9                   	leave  
801030a8:	c3                   	ret    

801030a9 <freerange>:

void
freerange(void *vstart, void *vend)
{
801030a9:	55                   	push   %ebp
801030aa:	89 e5                	mov    %esp,%ebp
801030ac:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
801030af:	8b 45 08             	mov    0x8(%ebp),%eax
801030b2:	05 ff 0f 00 00       	add    $0xfff,%eax
801030b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801030bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801030bf:	eb 12                	jmp    801030d3 <freerange+0x2a>
    kfree(p);
801030c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030c4:	89 04 24             	mov    %eax,(%esp)
801030c7:	e8 16 00 00 00       	call   801030e2 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801030cc:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801030d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030d6:	05 00 10 00 00       	add    $0x1000,%eax
801030db:	3b 45 0c             	cmp    0xc(%ebp),%eax
801030de:	76 e1                	jbe    801030c1 <freerange+0x18>
    kfree(p);
}
801030e0:	c9                   	leave  
801030e1:	c3                   	ret    

801030e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
801030e2:	55                   	push   %ebp
801030e3:	89 e5                	mov    %esp,%ebp
801030e5:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
801030e8:	8b 45 08             	mov    0x8(%ebp),%eax
801030eb:	25 ff 0f 00 00       	and    $0xfff,%eax
801030f0:	85 c0                	test   %eax,%eax
801030f2:	75 1b                	jne    8010310f <kfree+0x2d>
801030f4:	81 7d 08 9c 69 11 80 	cmpl   $0x8011699c,0x8(%ebp)
801030fb:	72 12                	jb     8010310f <kfree+0x2d>
801030fd:	8b 45 08             	mov    0x8(%ebp),%eax
80103100:	89 04 24             	mov    %eax,(%esp)
80103103:	e8 38 ff ff ff       	call   80103040 <v2p>
80103108:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
8010310d:	76 0c                	jbe    8010311b <kfree+0x39>
    panic("kfree");
8010310f:	c7 04 24 97 8c 10 80 	movl   $0x80108c97,(%esp)
80103116:	e8 1f d4 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
8010311b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103122:	00 
80103123:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010312a:	00 
8010312b:	8b 45 08             	mov    0x8(%ebp),%eax
8010312e:	89 04 24             	mov    %eax,(%esp)
80103131:	e8 a5 25 00 00       	call   801056db <memset>

  if(kmem.use_lock)
80103136:	a1 b4 3a 11 80       	mov    0x80113ab4,%eax
8010313b:	85 c0                	test   %eax,%eax
8010313d:	74 0c                	je     8010314b <kfree+0x69>
    acquire(&kmem.lock);
8010313f:	c7 04 24 80 3a 11 80 	movl   $0x80113a80,(%esp)
80103146:	e8 3c 23 00 00       	call   80105487 <acquire>
  r = (struct run*)v;
8010314b:	8b 45 08             	mov    0x8(%ebp),%eax
8010314e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103151:	8b 15 b8 3a 11 80    	mov    0x80113ab8,%edx
80103157:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010315a:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
8010315c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010315f:	a3 b8 3a 11 80       	mov    %eax,0x80113ab8
  if(kmem.use_lock)
80103164:	a1 b4 3a 11 80       	mov    0x80113ab4,%eax
80103169:	85 c0                	test   %eax,%eax
8010316b:	74 0c                	je     80103179 <kfree+0x97>
    release(&kmem.lock);
8010316d:	c7 04 24 80 3a 11 80 	movl   $0x80113a80,(%esp)
80103174:	e8 70 23 00 00       	call   801054e9 <release>
}
80103179:	c9                   	leave  
8010317a:	c3                   	ret    

8010317b <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
8010317b:	55                   	push   %ebp
8010317c:	89 e5                	mov    %esp,%ebp
8010317e:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103181:	a1 b4 3a 11 80       	mov    0x80113ab4,%eax
80103186:	85 c0                	test   %eax,%eax
80103188:	74 0c                	je     80103196 <kalloc+0x1b>
    acquire(&kmem.lock);
8010318a:	c7 04 24 80 3a 11 80 	movl   $0x80113a80,(%esp)
80103191:	e8 f1 22 00 00       	call   80105487 <acquire>
  r = kmem.freelist;
80103196:	a1 b8 3a 11 80       	mov    0x80113ab8,%eax
8010319b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
8010319e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801031a2:	74 0a                	je     801031ae <kalloc+0x33>
    kmem.freelist = r->next;
801031a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031a7:	8b 00                	mov    (%eax),%eax
801031a9:	a3 b8 3a 11 80       	mov    %eax,0x80113ab8
  if(kmem.use_lock)
801031ae:	a1 b4 3a 11 80       	mov    0x80113ab4,%eax
801031b3:	85 c0                	test   %eax,%eax
801031b5:	74 0c                	je     801031c3 <kalloc+0x48>
    release(&kmem.lock);
801031b7:	c7 04 24 80 3a 11 80 	movl   $0x80113a80,(%esp)
801031be:	e8 26 23 00 00       	call   801054e9 <release>
  return (char*)r;
801031c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801031c6:	c9                   	leave  
801031c7:	c3                   	ret    

801031c8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801031c8:	55                   	push   %ebp
801031c9:	89 e5                	mov    %esp,%ebp
801031cb:	83 ec 14             	sub    $0x14,%esp
801031ce:	8b 45 08             	mov    0x8(%ebp),%eax
801031d1:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801031d5:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801031d9:	89 c2                	mov    %eax,%edx
801031db:	ec                   	in     (%dx),%al
801031dc:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801031df:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801031e3:	c9                   	leave  
801031e4:	c3                   	ret    

801031e5 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801031e5:	55                   	push   %ebp
801031e6:	89 e5                	mov    %esp,%ebp
801031e8:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
801031eb:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801031f2:	e8 d1 ff ff ff       	call   801031c8 <inb>
801031f7:	0f b6 c0             	movzbl %al,%eax
801031fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
801031fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103200:	83 e0 01             	and    $0x1,%eax
80103203:	85 c0                	test   %eax,%eax
80103205:	75 0a                	jne    80103211 <kbdgetc+0x2c>
    return -1;
80103207:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010320c:	e9 25 01 00 00       	jmp    80103336 <kbdgetc+0x151>
  data = inb(KBDATAP);
80103211:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103218:	e8 ab ff ff ff       	call   801031c8 <inb>
8010321d:	0f b6 c0             	movzbl %al,%eax
80103220:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103223:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
8010322a:	75 17                	jne    80103243 <kbdgetc+0x5e>
    shift |= E0ESC;
8010322c:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80103231:	83 c8 40             	or     $0x40,%eax
80103234:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
80103239:	b8 00 00 00 00       	mov    $0x0,%eax
8010323e:	e9 f3 00 00 00       	jmp    80103336 <kbdgetc+0x151>
  } else if(data & 0x80){
80103243:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103246:	25 80 00 00 00       	and    $0x80,%eax
8010324b:	85 c0                	test   %eax,%eax
8010324d:	74 45                	je     80103294 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
8010324f:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80103254:	83 e0 40             	and    $0x40,%eax
80103257:	85 c0                	test   %eax,%eax
80103259:	75 08                	jne    80103263 <kbdgetc+0x7e>
8010325b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010325e:	83 e0 7f             	and    $0x7f,%eax
80103261:	eb 03                	jmp    80103266 <kbdgetc+0x81>
80103263:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103266:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103269:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010326c:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103271:	0f b6 00             	movzbl (%eax),%eax
80103274:	83 c8 40             	or     $0x40,%eax
80103277:	0f b6 c0             	movzbl %al,%eax
8010327a:	f7 d0                	not    %eax
8010327c:	89 c2                	mov    %eax,%edx
8010327e:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80103283:	21 d0                	and    %edx,%eax
80103285:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
8010328a:	b8 00 00 00 00       	mov    $0x0,%eax
8010328f:	e9 a2 00 00 00       	jmp    80103336 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80103294:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80103299:	83 e0 40             	and    $0x40,%eax
8010329c:	85 c0                	test   %eax,%eax
8010329e:	74 14                	je     801032b4 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801032a0:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801032a7:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
801032ac:	83 e0 bf             	and    $0xffffffbf,%eax
801032af:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  }

  shift |= shiftcode[data];
801032b4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801032b7:	05 20 a0 10 80       	add    $0x8010a020,%eax
801032bc:	0f b6 00             	movzbl (%eax),%eax
801032bf:	0f b6 d0             	movzbl %al,%edx
801032c2:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
801032c7:	09 d0                	or     %edx,%eax
801032c9:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  shift ^= togglecode[data];
801032ce:	8b 45 fc             	mov    -0x4(%ebp),%eax
801032d1:	05 20 a1 10 80       	add    $0x8010a120,%eax
801032d6:	0f b6 00             	movzbl (%eax),%eax
801032d9:	0f b6 d0             	movzbl %al,%edx
801032dc:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
801032e1:	31 d0                	xor    %edx,%eax
801032e3:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  c = charcode[shift & (CTL | SHIFT)][data];
801032e8:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
801032ed:	83 e0 03             	and    $0x3,%eax
801032f0:	8b 14 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%edx
801032f7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801032fa:	01 d0                	add    %edx,%eax
801032fc:	0f b6 00             	movzbl (%eax),%eax
801032ff:	0f b6 c0             	movzbl %al,%eax
80103302:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103305:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
8010330a:	83 e0 08             	and    $0x8,%eax
8010330d:	85 c0                	test   %eax,%eax
8010330f:	74 22                	je     80103333 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80103311:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103315:	76 0c                	jbe    80103323 <kbdgetc+0x13e>
80103317:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
8010331b:	77 06                	ja     80103323 <kbdgetc+0x13e>
      c += 'A' - 'a';
8010331d:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103321:	eb 10                	jmp    80103333 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80103323:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103327:	76 0a                	jbe    80103333 <kbdgetc+0x14e>
80103329:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
8010332d:	77 04                	ja     80103333 <kbdgetc+0x14e>
      c += 'a' - 'A';
8010332f:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103333:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103336:	c9                   	leave  
80103337:	c3                   	ret    

80103338 <kbdintr>:

void
kbdintr(void)
{
80103338:	55                   	push   %ebp
80103339:	89 e5                	mov    %esp,%ebp
8010333b:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
8010333e:	c7 04 24 e5 31 10 80 	movl   $0x801031e5,(%esp)
80103345:	e8 ac d7 ff ff       	call   80100af6 <consoleintr>
}
8010334a:	c9                   	leave  
8010334b:	c3                   	ret    

8010334c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010334c:	55                   	push   %ebp
8010334d:	89 e5                	mov    %esp,%ebp
8010334f:	83 ec 14             	sub    $0x14,%esp
80103352:	8b 45 08             	mov    0x8(%ebp),%eax
80103355:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103359:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010335d:	89 c2                	mov    %eax,%edx
8010335f:	ec                   	in     (%dx),%al
80103360:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103363:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103367:	c9                   	leave  
80103368:	c3                   	ret    

80103369 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103369:	55                   	push   %ebp
8010336a:	89 e5                	mov    %esp,%ebp
8010336c:	83 ec 08             	sub    $0x8,%esp
8010336f:	8b 55 08             	mov    0x8(%ebp),%edx
80103372:	8b 45 0c             	mov    0xc(%ebp),%eax
80103375:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103379:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010337c:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103380:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103384:	ee                   	out    %al,(%dx)
}
80103385:	c9                   	leave  
80103386:	c3                   	ret    

80103387 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103387:	55                   	push   %ebp
80103388:	89 e5                	mov    %esp,%ebp
8010338a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010338d:	9c                   	pushf  
8010338e:	58                   	pop    %eax
8010338f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80103392:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103395:	c9                   	leave  
80103396:	c3                   	ret    

80103397 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103397:	55                   	push   %ebp
80103398:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010339a:	a1 bc 3a 11 80       	mov    0x80113abc,%eax
8010339f:	8b 55 08             	mov    0x8(%ebp),%edx
801033a2:	c1 e2 02             	shl    $0x2,%edx
801033a5:	01 c2                	add    %eax,%edx
801033a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801033aa:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801033ac:	a1 bc 3a 11 80       	mov    0x80113abc,%eax
801033b1:	83 c0 20             	add    $0x20,%eax
801033b4:	8b 00                	mov    (%eax),%eax
}
801033b6:	5d                   	pop    %ebp
801033b7:	c3                   	ret    

801033b8 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
801033b8:	55                   	push   %ebp
801033b9:	89 e5                	mov    %esp,%ebp
801033bb:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801033be:	a1 bc 3a 11 80       	mov    0x80113abc,%eax
801033c3:	85 c0                	test   %eax,%eax
801033c5:	75 05                	jne    801033cc <lapicinit+0x14>
    return;
801033c7:	e9 43 01 00 00       	jmp    8010350f <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801033cc:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801033d3:	00 
801033d4:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801033db:	e8 b7 ff ff ff       	call   80103397 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801033e0:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801033e7:	00 
801033e8:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801033ef:	e8 a3 ff ff ff       	call   80103397 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801033f4:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801033fb:	00 
801033fc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103403:	e8 8f ff ff ff       	call   80103397 <lapicw>
  lapicw(TICR, 10000000); 
80103408:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
8010340f:	00 
80103410:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103417:	e8 7b ff ff ff       	call   80103397 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010341c:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103423:	00 
80103424:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010342b:	e8 67 ff ff ff       	call   80103397 <lapicw>
  lapicw(LINT1, MASKED);
80103430:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103437:	00 
80103438:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010343f:	e8 53 ff ff ff       	call   80103397 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103444:	a1 bc 3a 11 80       	mov    0x80113abc,%eax
80103449:	83 c0 30             	add    $0x30,%eax
8010344c:	8b 00                	mov    (%eax),%eax
8010344e:	c1 e8 10             	shr    $0x10,%eax
80103451:	0f b6 c0             	movzbl %al,%eax
80103454:	83 f8 03             	cmp    $0x3,%eax
80103457:	76 14                	jbe    8010346d <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80103459:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103460:	00 
80103461:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103468:	e8 2a ff ff ff       	call   80103397 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010346d:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103474:	00 
80103475:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
8010347c:	e8 16 ff ff ff       	call   80103397 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103481:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103488:	00 
80103489:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103490:	e8 02 ff ff ff       	call   80103397 <lapicw>
  lapicw(ESR, 0);
80103495:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010349c:	00 
8010349d:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801034a4:	e8 ee fe ff ff       	call   80103397 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801034a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034b0:	00 
801034b1:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801034b8:	e8 da fe ff ff       	call   80103397 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801034bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034c4:	00 
801034c5:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801034cc:	e8 c6 fe ff ff       	call   80103397 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801034d1:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801034d8:	00 
801034d9:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801034e0:	e8 b2 fe ff ff       	call   80103397 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801034e5:	90                   	nop
801034e6:	a1 bc 3a 11 80       	mov    0x80113abc,%eax
801034eb:	05 00 03 00 00       	add    $0x300,%eax
801034f0:	8b 00                	mov    (%eax),%eax
801034f2:	25 00 10 00 00       	and    $0x1000,%eax
801034f7:	85 c0                	test   %eax,%eax
801034f9:	75 eb                	jne    801034e6 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801034fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103502:	00 
80103503:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010350a:	e8 88 fe ff ff       	call   80103397 <lapicw>
}
8010350f:	c9                   	leave  
80103510:	c3                   	ret    

80103511 <cpunum>:

int
cpunum(void)
{
80103511:	55                   	push   %ebp
80103512:	89 e5                	mov    %esp,%ebp
80103514:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103517:	e8 6b fe ff ff       	call   80103387 <readeflags>
8010351c:	25 00 02 00 00       	and    $0x200,%eax
80103521:	85 c0                	test   %eax,%eax
80103523:	74 25                	je     8010354a <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103525:	a1 40 c6 10 80       	mov    0x8010c640,%eax
8010352a:	8d 50 01             	lea    0x1(%eax),%edx
8010352d:	89 15 40 c6 10 80    	mov    %edx,0x8010c640
80103533:	85 c0                	test   %eax,%eax
80103535:	75 13                	jne    8010354a <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80103537:	8b 45 04             	mov    0x4(%ebp),%eax
8010353a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010353e:	c7 04 24 a0 8c 10 80 	movl   $0x80108ca0,(%esp)
80103545:	e8 56 ce ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
8010354a:	a1 bc 3a 11 80       	mov    0x80113abc,%eax
8010354f:	85 c0                	test   %eax,%eax
80103551:	74 0f                	je     80103562 <cpunum+0x51>
    return lapic[ID]>>24;
80103553:	a1 bc 3a 11 80       	mov    0x80113abc,%eax
80103558:	83 c0 20             	add    $0x20,%eax
8010355b:	8b 00                	mov    (%eax),%eax
8010355d:	c1 e8 18             	shr    $0x18,%eax
80103560:	eb 05                	jmp    80103567 <cpunum+0x56>
  return 0;
80103562:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103567:	c9                   	leave  
80103568:	c3                   	ret    

80103569 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103569:	55                   	push   %ebp
8010356a:	89 e5                	mov    %esp,%ebp
8010356c:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010356f:	a1 bc 3a 11 80       	mov    0x80113abc,%eax
80103574:	85 c0                	test   %eax,%eax
80103576:	74 14                	je     8010358c <lapiceoi+0x23>
    lapicw(EOI, 0);
80103578:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010357f:	00 
80103580:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103587:	e8 0b fe ff ff       	call   80103397 <lapicw>
}
8010358c:	c9                   	leave  
8010358d:	c3                   	ret    

8010358e <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010358e:	55                   	push   %ebp
8010358f:	89 e5                	mov    %esp,%ebp
}
80103591:	5d                   	pop    %ebp
80103592:	c3                   	ret    

80103593 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103593:	55                   	push   %ebp
80103594:	89 e5                	mov    %esp,%ebp
80103596:	83 ec 1c             	sub    $0x1c,%esp
80103599:	8b 45 08             	mov    0x8(%ebp),%eax
8010359c:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
8010359f:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801035a6:	00 
801035a7:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801035ae:	e8 b6 fd ff ff       	call   80103369 <outb>
  outb(CMOS_PORT+1, 0x0A);
801035b3:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801035ba:	00 
801035bb:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801035c2:	e8 a2 fd ff ff       	call   80103369 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801035c7:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801035ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
801035d1:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801035d6:	8b 45 f8             	mov    -0x8(%ebp),%eax
801035d9:	8d 50 02             	lea    0x2(%eax),%edx
801035dc:	8b 45 0c             	mov    0xc(%ebp),%eax
801035df:	c1 e8 04             	shr    $0x4,%eax
801035e2:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801035e5:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801035e9:	c1 e0 18             	shl    $0x18,%eax
801035ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801035f0:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801035f7:	e8 9b fd ff ff       	call   80103397 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801035fc:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103603:	00 
80103604:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010360b:	e8 87 fd ff ff       	call   80103397 <lapicw>
  microdelay(200);
80103610:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103617:	e8 72 ff ff ff       	call   8010358e <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
8010361c:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103623:	00 
80103624:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010362b:	e8 67 fd ff ff       	call   80103397 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103630:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103637:	e8 52 ff ff ff       	call   8010358e <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010363c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103643:	eb 40                	jmp    80103685 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103645:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103649:	c1 e0 18             	shl    $0x18,%eax
8010364c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103650:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103657:	e8 3b fd ff ff       	call   80103397 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010365c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010365f:	c1 e8 0c             	shr    $0xc,%eax
80103662:	80 cc 06             	or     $0x6,%ah
80103665:	89 44 24 04          	mov    %eax,0x4(%esp)
80103669:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103670:	e8 22 fd ff ff       	call   80103397 <lapicw>
    microdelay(200);
80103675:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010367c:	e8 0d ff ff ff       	call   8010358e <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103681:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103685:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103689:	7e ba                	jle    80103645 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010368b:	c9                   	leave  
8010368c:	c3                   	ret    

8010368d <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
8010368d:	55                   	push   %ebp
8010368e:	89 e5                	mov    %esp,%ebp
80103690:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80103693:	8b 45 08             	mov    0x8(%ebp),%eax
80103696:	0f b6 c0             	movzbl %al,%eax
80103699:	89 44 24 04          	mov    %eax,0x4(%esp)
8010369d:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801036a4:	e8 c0 fc ff ff       	call   80103369 <outb>
  microdelay(200);
801036a9:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801036b0:	e8 d9 fe ff ff       	call   8010358e <microdelay>

  return inb(CMOS_RETURN);
801036b5:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801036bc:	e8 8b fc ff ff       	call   8010334c <inb>
801036c1:	0f b6 c0             	movzbl %al,%eax
}
801036c4:	c9                   	leave  
801036c5:	c3                   	ret    

801036c6 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801036c6:	55                   	push   %ebp
801036c7:	89 e5                	mov    %esp,%ebp
801036c9:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
801036cc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801036d3:	e8 b5 ff ff ff       	call   8010368d <cmos_read>
801036d8:	8b 55 08             	mov    0x8(%ebp),%edx
801036db:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
801036dd:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801036e4:	e8 a4 ff ff ff       	call   8010368d <cmos_read>
801036e9:	8b 55 08             	mov    0x8(%ebp),%edx
801036ec:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
801036ef:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801036f6:	e8 92 ff ff ff       	call   8010368d <cmos_read>
801036fb:	8b 55 08             	mov    0x8(%ebp),%edx
801036fe:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
80103701:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
80103708:	e8 80 ff ff ff       	call   8010368d <cmos_read>
8010370d:	8b 55 08             	mov    0x8(%ebp),%edx
80103710:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103713:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010371a:	e8 6e ff ff ff       	call   8010368d <cmos_read>
8010371f:	8b 55 08             	mov    0x8(%ebp),%edx
80103722:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103725:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
8010372c:	e8 5c ff ff ff       	call   8010368d <cmos_read>
80103731:	8b 55 08             	mov    0x8(%ebp),%edx
80103734:	89 42 14             	mov    %eax,0x14(%edx)
}
80103737:	c9                   	leave  
80103738:	c3                   	ret    

80103739 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80103739:	55                   	push   %ebp
8010373a:	89 e5                	mov    %esp,%ebp
8010373c:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010373f:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
80103746:	e8 42 ff ff ff       	call   8010368d <cmos_read>
8010374b:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
8010374e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103751:	83 e0 04             	and    $0x4,%eax
80103754:	85 c0                	test   %eax,%eax
80103756:	0f 94 c0             	sete   %al
80103759:	0f b6 c0             	movzbl %al,%eax
8010375c:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
8010375f:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103762:	89 04 24             	mov    %eax,(%esp)
80103765:	e8 5c ff ff ff       	call   801036c6 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
8010376a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80103771:	e8 17 ff ff ff       	call   8010368d <cmos_read>
80103776:	25 80 00 00 00       	and    $0x80,%eax
8010377b:	85 c0                	test   %eax,%eax
8010377d:	74 02                	je     80103781 <cmostime+0x48>
        continue;
8010377f:	eb 36                	jmp    801037b7 <cmostime+0x7e>
    fill_rtcdate(&t2);
80103781:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103784:	89 04 24             	mov    %eax,(%esp)
80103787:	e8 3a ff ff ff       	call   801036c6 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
8010378c:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80103793:	00 
80103794:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103797:	89 44 24 04          	mov    %eax,0x4(%esp)
8010379b:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010379e:	89 04 24             	mov    %eax,(%esp)
801037a1:	e8 ac 1f 00 00       	call   80105752 <memcmp>
801037a6:	85 c0                	test   %eax,%eax
801037a8:	75 0d                	jne    801037b7 <cmostime+0x7e>
      break;
801037aa:	90                   	nop
  }

  // convert
  if (bcd) {
801037ab:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801037af:	0f 84 ac 00 00 00    	je     80103861 <cmostime+0x128>
801037b5:	eb 02                	jmp    801037b9 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801037b7:	eb a6                	jmp    8010375f <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801037b9:	8b 45 d8             	mov    -0x28(%ebp),%eax
801037bc:	c1 e8 04             	shr    $0x4,%eax
801037bf:	89 c2                	mov    %eax,%edx
801037c1:	89 d0                	mov    %edx,%eax
801037c3:	c1 e0 02             	shl    $0x2,%eax
801037c6:	01 d0                	add    %edx,%eax
801037c8:	01 c0                	add    %eax,%eax
801037ca:	8b 55 d8             	mov    -0x28(%ebp),%edx
801037cd:	83 e2 0f             	and    $0xf,%edx
801037d0:	01 d0                	add    %edx,%eax
801037d2:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
801037d5:	8b 45 dc             	mov    -0x24(%ebp),%eax
801037d8:	c1 e8 04             	shr    $0x4,%eax
801037db:	89 c2                	mov    %eax,%edx
801037dd:	89 d0                	mov    %edx,%eax
801037df:	c1 e0 02             	shl    $0x2,%eax
801037e2:	01 d0                	add    %edx,%eax
801037e4:	01 c0                	add    %eax,%eax
801037e6:	8b 55 dc             	mov    -0x24(%ebp),%edx
801037e9:	83 e2 0f             	and    $0xf,%edx
801037ec:	01 d0                	add    %edx,%eax
801037ee:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
801037f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801037f4:	c1 e8 04             	shr    $0x4,%eax
801037f7:	89 c2                	mov    %eax,%edx
801037f9:	89 d0                	mov    %edx,%eax
801037fb:	c1 e0 02             	shl    $0x2,%eax
801037fe:	01 d0                	add    %edx,%eax
80103800:	01 c0                	add    %eax,%eax
80103802:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103805:	83 e2 0f             	and    $0xf,%edx
80103808:	01 d0                	add    %edx,%eax
8010380a:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
8010380d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103810:	c1 e8 04             	shr    $0x4,%eax
80103813:	89 c2                	mov    %eax,%edx
80103815:	89 d0                	mov    %edx,%eax
80103817:	c1 e0 02             	shl    $0x2,%eax
8010381a:	01 d0                	add    %edx,%eax
8010381c:	01 c0                	add    %eax,%eax
8010381e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103821:	83 e2 0f             	and    $0xf,%edx
80103824:	01 d0                	add    %edx,%eax
80103826:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103829:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010382c:	c1 e8 04             	shr    $0x4,%eax
8010382f:	89 c2                	mov    %eax,%edx
80103831:	89 d0                	mov    %edx,%eax
80103833:	c1 e0 02             	shl    $0x2,%eax
80103836:	01 d0                	add    %edx,%eax
80103838:	01 c0                	add    %eax,%eax
8010383a:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010383d:	83 e2 0f             	and    $0xf,%edx
80103840:	01 d0                	add    %edx,%eax
80103842:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
80103845:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103848:	c1 e8 04             	shr    $0x4,%eax
8010384b:	89 c2                	mov    %eax,%edx
8010384d:	89 d0                	mov    %edx,%eax
8010384f:	c1 e0 02             	shl    $0x2,%eax
80103852:	01 d0                	add    %edx,%eax
80103854:	01 c0                	add    %eax,%eax
80103856:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103859:	83 e2 0f             	and    $0xf,%edx
8010385c:	01 d0                	add    %edx,%eax
8010385e:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
80103861:	8b 45 08             	mov    0x8(%ebp),%eax
80103864:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103867:	89 10                	mov    %edx,(%eax)
80103869:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010386c:	89 50 04             	mov    %edx,0x4(%eax)
8010386f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103872:	89 50 08             	mov    %edx,0x8(%eax)
80103875:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103878:	89 50 0c             	mov    %edx,0xc(%eax)
8010387b:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010387e:	89 50 10             	mov    %edx,0x10(%eax)
80103881:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103884:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103887:	8b 45 08             	mov    0x8(%ebp),%eax
8010388a:	8b 40 14             	mov    0x14(%eax),%eax
8010388d:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
80103893:	8b 45 08             	mov    0x8(%ebp),%eax
80103896:	89 50 14             	mov    %edx,0x14(%eax)
}
80103899:	c9                   	leave  
8010389a:	c3                   	ret    

8010389b <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
8010389b:	55                   	push   %ebp
8010389c:	89 e5                	mov    %esp,%ebp
8010389e:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801038a1:	c7 44 24 04 cc 8c 10 	movl   $0x80108ccc,0x4(%esp)
801038a8:	80 
801038a9:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
801038b0:	e8 b1 1b 00 00       	call   80105466 <initlock>
  readsb(dev, &sb);
801038b5:	8d 45 dc             	lea    -0x24(%ebp),%eax
801038b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801038bc:	8b 45 08             	mov    0x8(%ebp),%eax
801038bf:	89 04 24             	mov    %eax,(%esp)
801038c2:	e8 28 e0 ff ff       	call   801018ef <readsb>
  log.start = sb.logstart;
801038c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801038ca:	a3 f4 3a 11 80       	mov    %eax,0x80113af4
  log.size = sb.nlog;
801038cf:	8b 45 e8             	mov    -0x18(%ebp),%eax
801038d2:	a3 f8 3a 11 80       	mov    %eax,0x80113af8
  log.dev = dev;
801038d7:	8b 45 08             	mov    0x8(%ebp),%eax
801038da:	a3 04 3b 11 80       	mov    %eax,0x80113b04
  recover_from_log();
801038df:	e8 9a 01 00 00       	call   80103a7e <recover_from_log>
}
801038e4:	c9                   	leave  
801038e5:	c3                   	ret    

801038e6 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801038e6:	55                   	push   %ebp
801038e7:	89 e5                	mov    %esp,%ebp
801038e9:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801038ec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801038f3:	e9 8c 00 00 00       	jmp    80103984 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801038f8:	8b 15 f4 3a 11 80    	mov    0x80113af4,%edx
801038fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103901:	01 d0                	add    %edx,%eax
80103903:	83 c0 01             	add    $0x1,%eax
80103906:	89 c2                	mov    %eax,%edx
80103908:	a1 04 3b 11 80       	mov    0x80113b04,%eax
8010390d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103911:	89 04 24             	mov    %eax,(%esp)
80103914:	e8 8d c8 ff ff       	call   801001a6 <bread>
80103919:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010391c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010391f:	83 c0 10             	add    $0x10,%eax
80103922:	8b 04 85 cc 3a 11 80 	mov    -0x7feec534(,%eax,4),%eax
80103929:	89 c2                	mov    %eax,%edx
8010392b:	a1 04 3b 11 80       	mov    0x80113b04,%eax
80103930:	89 54 24 04          	mov    %edx,0x4(%esp)
80103934:	89 04 24             	mov    %eax,(%esp)
80103937:	e8 6a c8 ff ff       	call   801001a6 <bread>
8010393c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
8010393f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103942:	8d 50 18             	lea    0x18(%eax),%edx
80103945:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103948:	83 c0 18             	add    $0x18,%eax
8010394b:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103952:	00 
80103953:	89 54 24 04          	mov    %edx,0x4(%esp)
80103957:	89 04 24             	mov    %eax,(%esp)
8010395a:	e8 4b 1e 00 00       	call   801057aa <memmove>
    bwrite(dbuf);  // write dst to disk
8010395f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103962:	89 04 24             	mov    %eax,(%esp)
80103965:	e8 73 c8 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
8010396a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010396d:	89 04 24             	mov    %eax,(%esp)
80103970:	e8 a2 c8 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103975:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103978:	89 04 24             	mov    %eax,(%esp)
8010397b:	e8 97 c8 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103980:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103984:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103989:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010398c:	0f 8f 66 ff ff ff    	jg     801038f8 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103992:	c9                   	leave  
80103993:	c3                   	ret    

80103994 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103994:	55                   	push   %ebp
80103995:	89 e5                	mov    %esp,%ebp
80103997:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010399a:	a1 f4 3a 11 80       	mov    0x80113af4,%eax
8010399f:	89 c2                	mov    %eax,%edx
801039a1:	a1 04 3b 11 80       	mov    0x80113b04,%eax
801039a6:	89 54 24 04          	mov    %edx,0x4(%esp)
801039aa:	89 04 24             	mov    %eax,(%esp)
801039ad:	e8 f4 c7 ff ff       	call   801001a6 <bread>
801039b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801039b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039b8:	83 c0 18             	add    $0x18,%eax
801039bb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801039be:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039c1:	8b 00                	mov    (%eax),%eax
801039c3:	a3 08 3b 11 80       	mov    %eax,0x80113b08
  for (i = 0; i < log.lh.n; i++) {
801039c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801039cf:	eb 1b                	jmp    801039ec <read_head+0x58>
    log.lh.block[i] = lh->block[i];
801039d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801039d7:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801039db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801039de:	83 c2 10             	add    $0x10,%edx
801039e1:	89 04 95 cc 3a 11 80 	mov    %eax,-0x7feec534(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801039e8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801039ec:	a1 08 3b 11 80       	mov    0x80113b08,%eax
801039f1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801039f4:	7f db                	jg     801039d1 <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
801039f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039f9:	89 04 24             	mov    %eax,(%esp)
801039fc:	e8 16 c8 ff ff       	call   80100217 <brelse>
}
80103a01:	c9                   	leave  
80103a02:	c3                   	ret    

80103a03 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103a03:	55                   	push   %ebp
80103a04:	89 e5                	mov    %esp,%ebp
80103a06:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103a09:	a1 f4 3a 11 80       	mov    0x80113af4,%eax
80103a0e:	89 c2                	mov    %eax,%edx
80103a10:	a1 04 3b 11 80       	mov    0x80113b04,%eax
80103a15:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a19:	89 04 24             	mov    %eax,(%esp)
80103a1c:	e8 85 c7 ff ff       	call   801001a6 <bread>
80103a21:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103a24:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a27:	83 c0 18             	add    $0x18,%eax
80103a2a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103a2d:	8b 15 08 3b 11 80    	mov    0x80113b08,%edx
80103a33:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a36:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103a38:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a3f:	eb 1b                	jmp    80103a5c <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a44:	83 c0 10             	add    $0x10,%eax
80103a47:	8b 0c 85 cc 3a 11 80 	mov    -0x7feec534(,%eax,4),%ecx
80103a4e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a51:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103a54:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103a58:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a5c:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103a61:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a64:	7f db                	jg     80103a41 <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103a66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a69:	89 04 24             	mov    %eax,(%esp)
80103a6c:	e8 6c c7 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103a71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a74:	89 04 24             	mov    %eax,(%esp)
80103a77:	e8 9b c7 ff ff       	call   80100217 <brelse>
}
80103a7c:	c9                   	leave  
80103a7d:	c3                   	ret    

80103a7e <recover_from_log>:

static void
recover_from_log(void)
{
80103a7e:	55                   	push   %ebp
80103a7f:	89 e5                	mov    %esp,%ebp
80103a81:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103a84:	e8 0b ff ff ff       	call   80103994 <read_head>
  install_trans(); // if committed, copy from log to disk
80103a89:	e8 58 fe ff ff       	call   801038e6 <install_trans>
  log.lh.n = 0;
80103a8e:	c7 05 08 3b 11 80 00 	movl   $0x0,0x80113b08
80103a95:	00 00 00 
  write_head(); // clear the log
80103a98:	e8 66 ff ff ff       	call   80103a03 <write_head>
}
80103a9d:	c9                   	leave  
80103a9e:	c3                   	ret    

80103a9f <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103a9f:	55                   	push   %ebp
80103aa0:	89 e5                	mov    %esp,%ebp
80103aa2:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103aa5:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103aac:	e8 d6 19 00 00       	call   80105487 <acquire>
  while(1){
    if(log.committing){
80103ab1:	a1 00 3b 11 80       	mov    0x80113b00,%eax
80103ab6:	85 c0                	test   %eax,%eax
80103ab8:	74 16                	je     80103ad0 <begin_op+0x31>
      sleep(&log, &log.lock);
80103aba:	c7 44 24 04 c0 3a 11 	movl   $0x80113ac0,0x4(%esp)
80103ac1:	80 
80103ac2:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103ac9:	e8 ef 16 00 00       	call   801051bd <sleep>
80103ace:	eb 4f                	jmp    80103b1f <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103ad0:	8b 0d 08 3b 11 80    	mov    0x80113b08,%ecx
80103ad6:	a1 fc 3a 11 80       	mov    0x80113afc,%eax
80103adb:	8d 50 01             	lea    0x1(%eax),%edx
80103ade:	89 d0                	mov    %edx,%eax
80103ae0:	c1 e0 02             	shl    $0x2,%eax
80103ae3:	01 d0                	add    %edx,%eax
80103ae5:	01 c0                	add    %eax,%eax
80103ae7:	01 c8                	add    %ecx,%eax
80103ae9:	83 f8 1e             	cmp    $0x1e,%eax
80103aec:	7e 16                	jle    80103b04 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103aee:	c7 44 24 04 c0 3a 11 	movl   $0x80113ac0,0x4(%esp)
80103af5:	80 
80103af6:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103afd:	e8 bb 16 00 00       	call   801051bd <sleep>
80103b02:	eb 1b                	jmp    80103b1f <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103b04:	a1 fc 3a 11 80       	mov    0x80113afc,%eax
80103b09:	83 c0 01             	add    $0x1,%eax
80103b0c:	a3 fc 3a 11 80       	mov    %eax,0x80113afc
      release(&log.lock);
80103b11:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103b18:	e8 cc 19 00 00       	call   801054e9 <release>
      break;
80103b1d:	eb 02                	jmp    80103b21 <begin_op+0x82>
    }
  }
80103b1f:	eb 90                	jmp    80103ab1 <begin_op+0x12>
}
80103b21:	c9                   	leave  
80103b22:	c3                   	ret    

80103b23 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103b23:	55                   	push   %ebp
80103b24:	89 e5                	mov    %esp,%ebp
80103b26:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103b29:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103b30:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103b37:	e8 4b 19 00 00       	call   80105487 <acquire>
  log.outstanding -= 1;
80103b3c:	a1 fc 3a 11 80       	mov    0x80113afc,%eax
80103b41:	83 e8 01             	sub    $0x1,%eax
80103b44:	a3 fc 3a 11 80       	mov    %eax,0x80113afc
  if(log.committing)
80103b49:	a1 00 3b 11 80       	mov    0x80113b00,%eax
80103b4e:	85 c0                	test   %eax,%eax
80103b50:	74 0c                	je     80103b5e <end_op+0x3b>
    panic("log.committing");
80103b52:	c7 04 24 d0 8c 10 80 	movl   $0x80108cd0,(%esp)
80103b59:	e8 dc c9 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103b5e:	a1 fc 3a 11 80       	mov    0x80113afc,%eax
80103b63:	85 c0                	test   %eax,%eax
80103b65:	75 13                	jne    80103b7a <end_op+0x57>
    do_commit = 1;
80103b67:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103b6e:	c7 05 00 3b 11 80 01 	movl   $0x1,0x80113b00
80103b75:	00 00 00 
80103b78:	eb 0c                	jmp    80103b86 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103b7a:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103b81:	e8 10 17 00 00       	call   80105296 <wakeup>
  }
  release(&log.lock);
80103b86:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103b8d:	e8 57 19 00 00       	call   801054e9 <release>

  if(do_commit){
80103b92:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103b96:	74 33                	je     80103bcb <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103b98:	e8 de 00 00 00       	call   80103c7b <commit>
    acquire(&log.lock);
80103b9d:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103ba4:	e8 de 18 00 00       	call   80105487 <acquire>
    log.committing = 0;
80103ba9:	c7 05 00 3b 11 80 00 	movl   $0x0,0x80113b00
80103bb0:	00 00 00 
    wakeup(&log);
80103bb3:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103bba:	e8 d7 16 00 00       	call   80105296 <wakeup>
    release(&log.lock);
80103bbf:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103bc6:	e8 1e 19 00 00       	call   801054e9 <release>
  }
}
80103bcb:	c9                   	leave  
80103bcc:	c3                   	ret    

80103bcd <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103bcd:	55                   	push   %ebp
80103bce:	89 e5                	mov    %esp,%ebp
80103bd0:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103bd3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103bda:	e9 8c 00 00 00       	jmp    80103c6b <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103bdf:	8b 15 f4 3a 11 80    	mov    0x80113af4,%edx
80103be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103be8:	01 d0                	add    %edx,%eax
80103bea:	83 c0 01             	add    $0x1,%eax
80103bed:	89 c2                	mov    %eax,%edx
80103bef:	a1 04 3b 11 80       	mov    0x80113b04,%eax
80103bf4:	89 54 24 04          	mov    %edx,0x4(%esp)
80103bf8:	89 04 24             	mov    %eax,(%esp)
80103bfb:	e8 a6 c5 ff ff       	call   801001a6 <bread>
80103c00:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103c03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c06:	83 c0 10             	add    $0x10,%eax
80103c09:	8b 04 85 cc 3a 11 80 	mov    -0x7feec534(,%eax,4),%eax
80103c10:	89 c2                	mov    %eax,%edx
80103c12:	a1 04 3b 11 80       	mov    0x80113b04,%eax
80103c17:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c1b:	89 04 24             	mov    %eax,(%esp)
80103c1e:	e8 83 c5 ff ff       	call   801001a6 <bread>
80103c23:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103c26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c29:	8d 50 18             	lea    0x18(%eax),%edx
80103c2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c2f:	83 c0 18             	add    $0x18,%eax
80103c32:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103c39:	00 
80103c3a:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c3e:	89 04 24             	mov    %eax,(%esp)
80103c41:	e8 64 1b 00 00       	call   801057aa <memmove>
    bwrite(to);  // write the log
80103c46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c49:	89 04 24             	mov    %eax,(%esp)
80103c4c:	e8 8c c5 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103c51:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c54:	89 04 24             	mov    %eax,(%esp)
80103c57:	e8 bb c5 ff ff       	call   80100217 <brelse>
    brelse(to);
80103c5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c5f:	89 04 24             	mov    %eax,(%esp)
80103c62:	e8 b0 c5 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103c67:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103c6b:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103c70:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103c73:	0f 8f 66 ff ff ff    	jg     80103bdf <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103c79:	c9                   	leave  
80103c7a:	c3                   	ret    

80103c7b <commit>:

static void
commit()
{
80103c7b:	55                   	push   %ebp
80103c7c:	89 e5                	mov    %esp,%ebp
80103c7e:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103c81:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103c86:	85 c0                	test   %eax,%eax
80103c88:	7e 1e                	jle    80103ca8 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103c8a:	e8 3e ff ff ff       	call   80103bcd <write_log>
    write_head();    // Write header to disk -- the real commit
80103c8f:	e8 6f fd ff ff       	call   80103a03 <write_head>
    install_trans(); // Now install writes to home locations
80103c94:	e8 4d fc ff ff       	call   801038e6 <install_trans>
    log.lh.n = 0; 
80103c99:	c7 05 08 3b 11 80 00 	movl   $0x0,0x80113b08
80103ca0:	00 00 00 
    write_head();    // Erase the transaction from the log
80103ca3:	e8 5b fd ff ff       	call   80103a03 <write_head>
  }
}
80103ca8:	c9                   	leave  
80103ca9:	c3                   	ret    

80103caa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103caa:	55                   	push   %ebp
80103cab:	89 e5                	mov    %esp,%ebp
80103cad:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103cb0:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103cb5:	83 f8 1d             	cmp    $0x1d,%eax
80103cb8:	7f 12                	jg     80103ccc <log_write+0x22>
80103cba:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103cbf:	8b 15 f8 3a 11 80    	mov    0x80113af8,%edx
80103cc5:	83 ea 01             	sub    $0x1,%edx
80103cc8:	39 d0                	cmp    %edx,%eax
80103cca:	7c 0c                	jl     80103cd8 <log_write+0x2e>
    panic("too big a transaction");
80103ccc:	c7 04 24 df 8c 10 80 	movl   $0x80108cdf,(%esp)
80103cd3:	e8 62 c8 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103cd8:	a1 fc 3a 11 80       	mov    0x80113afc,%eax
80103cdd:	85 c0                	test   %eax,%eax
80103cdf:	7f 0c                	jg     80103ced <log_write+0x43>
    panic("log_write outside of trans");
80103ce1:	c7 04 24 f5 8c 10 80 	movl   $0x80108cf5,(%esp)
80103ce8:	e8 4d c8 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103ced:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103cf4:	e8 8e 17 00 00       	call   80105487 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103cf9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103d00:	eb 1f                	jmp    80103d21 <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103d02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d05:	83 c0 10             	add    $0x10,%eax
80103d08:	8b 04 85 cc 3a 11 80 	mov    -0x7feec534(,%eax,4),%eax
80103d0f:	89 c2                	mov    %eax,%edx
80103d11:	8b 45 08             	mov    0x8(%ebp),%eax
80103d14:	8b 40 08             	mov    0x8(%eax),%eax
80103d17:	39 c2                	cmp    %eax,%edx
80103d19:	75 02                	jne    80103d1d <log_write+0x73>
      break;
80103d1b:	eb 0e                	jmp    80103d2b <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103d1d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d21:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103d26:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d29:	7f d7                	jg     80103d02 <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103d2b:	8b 45 08             	mov    0x8(%ebp),%eax
80103d2e:	8b 40 08             	mov    0x8(%eax),%eax
80103d31:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d34:	83 c2 10             	add    $0x10,%edx
80103d37:	89 04 95 cc 3a 11 80 	mov    %eax,-0x7feec534(,%edx,4)
  if (i == log.lh.n)
80103d3e:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103d43:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d46:	75 0d                	jne    80103d55 <log_write+0xab>
    log.lh.n++;
80103d48:	a1 08 3b 11 80       	mov    0x80113b08,%eax
80103d4d:	83 c0 01             	add    $0x1,%eax
80103d50:	a3 08 3b 11 80       	mov    %eax,0x80113b08
  b->flags |= B_DIRTY; // prevent eviction
80103d55:	8b 45 08             	mov    0x8(%ebp),%eax
80103d58:	8b 00                	mov    (%eax),%eax
80103d5a:	83 c8 04             	or     $0x4,%eax
80103d5d:	89 c2                	mov    %eax,%edx
80103d5f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d62:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103d64:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103d6b:	e8 79 17 00 00       	call   801054e9 <release>
}
80103d70:	c9                   	leave  
80103d71:	c3                   	ret    

80103d72 <v2p>:
80103d72:	55                   	push   %ebp
80103d73:	89 e5                	mov    %esp,%ebp
80103d75:	8b 45 08             	mov    0x8(%ebp),%eax
80103d78:	05 00 00 00 80       	add    $0x80000000,%eax
80103d7d:	5d                   	pop    %ebp
80103d7e:	c3                   	ret    

80103d7f <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103d7f:	55                   	push   %ebp
80103d80:	89 e5                	mov    %esp,%ebp
80103d82:	8b 45 08             	mov    0x8(%ebp),%eax
80103d85:	05 00 00 00 80       	add    $0x80000000,%eax
80103d8a:	5d                   	pop    %ebp
80103d8b:	c3                   	ret    

80103d8c <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103d8c:	55                   	push   %ebp
80103d8d:	89 e5                	mov    %esp,%ebp
80103d8f:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103d92:	8b 55 08             	mov    0x8(%ebp),%edx
80103d95:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d98:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103d9b:	f0 87 02             	lock xchg %eax,(%edx)
80103d9e:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103da1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103da4:	c9                   	leave  
80103da5:	c3                   	ret    

80103da6 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103da6:	55                   	push   %ebp
80103da7:	89 e5                	mov    %esp,%ebp
80103da9:	83 e4 f0             	and    $0xfffffff0,%esp
80103dac:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103daf:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103db6:	80 
80103db7:	c7 04 24 9c 69 11 80 	movl   $0x8011699c,(%esp)
80103dbe:	e8 8a f2 ff ff       	call   8010304d <kinit1>
  kvmalloc();      // kernel page table
80103dc3:	e8 d8 44 00 00       	call   801082a0 <kvmalloc>
  mpinit();        // collect info about this machine
80103dc8:	e8 41 04 00 00       	call   8010420e <mpinit>
  lapicinit();
80103dcd:	e8 e6 f5 ff ff       	call   801033b8 <lapicinit>
  seginit();       // set up segments
80103dd2:	e8 5c 3e 00 00       	call   80107c33 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103dd7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ddd:	0f b6 00             	movzbl (%eax),%eax
80103de0:	0f b6 c0             	movzbl %al,%eax
80103de3:	89 44 24 04          	mov    %eax,0x4(%esp)
80103de7:	c7 04 24 10 8d 10 80 	movl   $0x80108d10,(%esp)
80103dee:	e8 ad c5 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103df3:	e8 74 06 00 00       	call   8010446c <picinit>
  ioapicinit();    // another interrupt controller
80103df8:	e8 46 f1 ff ff       	call   80102f43 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103dfd:	e8 d8 d1 ff ff       	call   80100fda <consoleinit>
  uartinit();      // serial port
80103e02:	e8 7b 31 00 00       	call   80106f82 <uartinit>
  pinit();         // process table
80103e07:	e8 6a 0b 00 00       	call   80104976 <pinit>
  tvinit();        // trap vectors
80103e0c:	e8 23 2d 00 00       	call   80106b34 <tvinit>
  binit();         // buffer cache
80103e11:	e8 1e c2 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103e16:	e8 ed d6 ff ff       	call   80101508 <fileinit>
  ideinit();       // disk
80103e1b:	e8 55 ed ff ff       	call   80102b75 <ideinit>
  if(!ismp)
80103e20:	a1 a4 3b 11 80       	mov    0x80113ba4,%eax
80103e25:	85 c0                	test   %eax,%eax
80103e27:	75 05                	jne    80103e2e <main+0x88>
    timerinit();   // uniprocessor timer
80103e29:	e8 51 2c 00 00       	call   80106a7f <timerinit>
  startothers();   // start other processors
80103e2e:	e8 7f 00 00 00       	call   80103eb2 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103e33:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103e3a:	8e 
80103e3b:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103e42:	e8 3e f2 ff ff       	call   80103085 <kinit2>
  userinit();      // first user process
80103e47:	e8 45 0c 00 00       	call   80104a91 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103e4c:	e8 1a 00 00 00       	call   80103e6b <mpmain>

80103e51 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103e51:	55                   	push   %ebp
80103e52:	89 e5                	mov    %esp,%ebp
80103e54:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103e57:	e8 5b 44 00 00       	call   801082b7 <switchkvm>
  seginit();
80103e5c:	e8 d2 3d 00 00       	call   80107c33 <seginit>
  lapicinit();
80103e61:	e8 52 f5 ff ff       	call   801033b8 <lapicinit>
  mpmain();
80103e66:	e8 00 00 00 00       	call   80103e6b <mpmain>

80103e6b <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103e6b:	55                   	push   %ebp
80103e6c:	89 e5                	mov    %esp,%ebp
80103e6e:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103e71:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103e77:	0f b6 00             	movzbl (%eax),%eax
80103e7a:	0f b6 c0             	movzbl %al,%eax
80103e7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e81:	c7 04 24 27 8d 10 80 	movl   $0x80108d27,(%esp)
80103e88:	e8 13 c5 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103e8d:	e8 16 2e 00 00       	call   80106ca8 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103e92:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103e98:	05 a8 00 00 00       	add    $0xa8,%eax
80103e9d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103ea4:	00 
80103ea5:	89 04 24             	mov    %eax,(%esp)
80103ea8:	e8 df fe ff ff       	call   80103d8c <xchg>
  scheduler();     // start running processes
80103ead:	e8 50 11 00 00       	call   80105002 <scheduler>

80103eb2 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103eb2:	55                   	push   %ebp
80103eb3:	89 e5                	mov    %esp,%ebp
80103eb5:	53                   	push   %ebx
80103eb6:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103eb9:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103ec0:	e8 ba fe ff ff       	call   80103d7f <p2v>
80103ec5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103ec8:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103ecd:	89 44 24 08          	mov    %eax,0x8(%esp)
80103ed1:	c7 44 24 04 0c c5 10 	movl   $0x8010c50c,0x4(%esp)
80103ed8:	80 
80103ed9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103edc:	89 04 24             	mov    %eax,(%esp)
80103edf:	e8 c6 18 00 00       	call   801057aa <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103ee4:	c7 45 f4 c0 3b 11 80 	movl   $0x80113bc0,-0xc(%ebp)
80103eeb:	e9 85 00 00 00       	jmp    80103f75 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103ef0:	e8 1c f6 ff ff       	call   80103511 <cpunum>
80103ef5:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103efb:	05 c0 3b 11 80       	add    $0x80113bc0,%eax
80103f00:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103f03:	75 02                	jne    80103f07 <startothers+0x55>
      continue;
80103f05:	eb 67                	jmp    80103f6e <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103f07:	e8 6f f2 ff ff       	call   8010317b <kalloc>
80103f0c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103f0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f12:	83 e8 04             	sub    $0x4,%eax
80103f15:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103f18:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103f1e:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103f20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f23:	83 e8 08             	sub    $0x8,%eax
80103f26:	c7 00 51 3e 10 80    	movl   $0x80103e51,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103f2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f2f:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103f32:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80103f39:	e8 34 fe ff ff       	call   80103d72 <v2p>
80103f3e:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103f40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f43:	89 04 24             	mov    %eax,(%esp)
80103f46:	e8 27 fe ff ff       	call   80103d72 <v2p>
80103f4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f4e:	0f b6 12             	movzbl (%edx),%edx
80103f51:	0f b6 d2             	movzbl %dl,%edx
80103f54:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f58:	89 14 24             	mov    %edx,(%esp)
80103f5b:	e8 33 f6 ff ff       	call   80103593 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103f60:	90                   	nop
80103f61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f64:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103f6a:	85 c0                	test   %eax,%eax
80103f6c:	74 f3                	je     80103f61 <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103f6e:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103f75:	a1 a0 41 11 80       	mov    0x801141a0,%eax
80103f7a:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103f80:	05 c0 3b 11 80       	add    $0x80113bc0,%eax
80103f85:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103f88:	0f 87 62 ff ff ff    	ja     80103ef0 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103f8e:	83 c4 24             	add    $0x24,%esp
80103f91:	5b                   	pop    %ebx
80103f92:	5d                   	pop    %ebp
80103f93:	c3                   	ret    

80103f94 <p2v>:
80103f94:	55                   	push   %ebp
80103f95:	89 e5                	mov    %esp,%ebp
80103f97:	8b 45 08             	mov    0x8(%ebp),%eax
80103f9a:	05 00 00 00 80       	add    $0x80000000,%eax
80103f9f:	5d                   	pop    %ebp
80103fa0:	c3                   	ret    

80103fa1 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103fa1:	55                   	push   %ebp
80103fa2:	89 e5                	mov    %esp,%ebp
80103fa4:	83 ec 14             	sub    $0x14,%esp
80103fa7:	8b 45 08             	mov    0x8(%ebp),%eax
80103faa:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103fae:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103fb2:	89 c2                	mov    %eax,%edx
80103fb4:	ec                   	in     (%dx),%al
80103fb5:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103fb8:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103fbc:	c9                   	leave  
80103fbd:	c3                   	ret    

80103fbe <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103fbe:	55                   	push   %ebp
80103fbf:	89 e5                	mov    %esp,%ebp
80103fc1:	83 ec 08             	sub    $0x8,%esp
80103fc4:	8b 55 08             	mov    0x8(%ebp),%edx
80103fc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fca:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103fce:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103fd1:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103fd5:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103fd9:	ee                   	out    %al,(%dx)
}
80103fda:	c9                   	leave  
80103fdb:	c3                   	ret    

80103fdc <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103fdc:	55                   	push   %ebp
80103fdd:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103fdf:	a1 44 c6 10 80       	mov    0x8010c644,%eax
80103fe4:	89 c2                	mov    %eax,%edx
80103fe6:	b8 c0 3b 11 80       	mov    $0x80113bc0,%eax
80103feb:	29 c2                	sub    %eax,%edx
80103fed:	89 d0                	mov    %edx,%eax
80103fef:	c1 f8 02             	sar    $0x2,%eax
80103ff2:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103ff8:	5d                   	pop    %ebp
80103ff9:	c3                   	ret    

80103ffa <sum>:

static uchar
sum(uchar *addr, int len)
{
80103ffa:	55                   	push   %ebp
80103ffb:	89 e5                	mov    %esp,%ebp
80103ffd:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80104000:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104007:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010400e:	eb 15                	jmp    80104025 <sum+0x2b>
    sum += addr[i];
80104010:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104013:	8b 45 08             	mov    0x8(%ebp),%eax
80104016:	01 d0                	add    %edx,%eax
80104018:	0f b6 00             	movzbl (%eax),%eax
8010401b:	0f b6 c0             	movzbl %al,%eax
8010401e:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80104021:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104025:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104028:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010402b:	7c e3                	jl     80104010 <sum+0x16>
    sum += addr[i];
  return sum;
8010402d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104030:	c9                   	leave  
80104031:	c3                   	ret    

80104032 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80104032:	55                   	push   %ebp
80104033:	89 e5                	mov    %esp,%ebp
80104035:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104038:	8b 45 08             	mov    0x8(%ebp),%eax
8010403b:	89 04 24             	mov    %eax,(%esp)
8010403e:	e8 51 ff ff ff       	call   80103f94 <p2v>
80104043:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104046:	8b 55 0c             	mov    0xc(%ebp),%edx
80104049:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010404c:	01 d0                	add    %edx,%eax
8010404e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104051:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104054:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104057:	eb 3f                	jmp    80104098 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104059:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104060:	00 
80104061:	c7 44 24 04 38 8d 10 	movl   $0x80108d38,0x4(%esp)
80104068:	80 
80104069:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010406c:	89 04 24             	mov    %eax,(%esp)
8010406f:	e8 de 16 00 00       	call   80105752 <memcmp>
80104074:	85 c0                	test   %eax,%eax
80104076:	75 1c                	jne    80104094 <mpsearch1+0x62>
80104078:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010407f:	00 
80104080:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104083:	89 04 24             	mov    %eax,(%esp)
80104086:	e8 6f ff ff ff       	call   80103ffa <sum>
8010408b:	84 c0                	test   %al,%al
8010408d:	75 05                	jne    80104094 <mpsearch1+0x62>
      return (struct mp*)p;
8010408f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104092:	eb 11                	jmp    801040a5 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80104094:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80104098:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010409b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010409e:	72 b9                	jb     80104059 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801040a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040a5:	c9                   	leave  
801040a6:	c3                   	ret    

801040a7 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801040a7:	55                   	push   %ebp
801040a8:	89 e5                	mov    %esp,%ebp
801040aa:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801040ad:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801040b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040b7:	83 c0 0f             	add    $0xf,%eax
801040ba:	0f b6 00             	movzbl (%eax),%eax
801040bd:	0f b6 c0             	movzbl %al,%eax
801040c0:	c1 e0 08             	shl    $0x8,%eax
801040c3:	89 c2                	mov    %eax,%edx
801040c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040c8:	83 c0 0e             	add    $0xe,%eax
801040cb:	0f b6 00             	movzbl (%eax),%eax
801040ce:	0f b6 c0             	movzbl %al,%eax
801040d1:	09 d0                	or     %edx,%eax
801040d3:	c1 e0 04             	shl    $0x4,%eax
801040d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801040d9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801040dd:	74 21                	je     80104100 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801040df:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801040e6:	00 
801040e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040ea:	89 04 24             	mov    %eax,(%esp)
801040ed:	e8 40 ff ff ff       	call   80104032 <mpsearch1>
801040f2:	89 45 ec             	mov    %eax,-0x14(%ebp)
801040f5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801040f9:	74 50                	je     8010414b <mpsearch+0xa4>
      return mp;
801040fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801040fe:	eb 5f                	jmp    8010415f <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104100:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104103:	83 c0 14             	add    $0x14,%eax
80104106:	0f b6 00             	movzbl (%eax),%eax
80104109:	0f b6 c0             	movzbl %al,%eax
8010410c:	c1 e0 08             	shl    $0x8,%eax
8010410f:	89 c2                	mov    %eax,%edx
80104111:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104114:	83 c0 13             	add    $0x13,%eax
80104117:	0f b6 00             	movzbl (%eax),%eax
8010411a:	0f b6 c0             	movzbl %al,%eax
8010411d:	09 d0                	or     %edx,%eax
8010411f:	c1 e0 0a             	shl    $0xa,%eax
80104122:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104125:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104128:	2d 00 04 00 00       	sub    $0x400,%eax
8010412d:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104134:	00 
80104135:	89 04 24             	mov    %eax,(%esp)
80104138:	e8 f5 fe ff ff       	call   80104032 <mpsearch1>
8010413d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104140:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104144:	74 05                	je     8010414b <mpsearch+0xa4>
      return mp;
80104146:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104149:	eb 14                	jmp    8010415f <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
8010414b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104152:	00 
80104153:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
8010415a:	e8 d3 fe ff ff       	call   80104032 <mpsearch1>
}
8010415f:	c9                   	leave  
80104160:	c3                   	ret    

80104161 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104161:	55                   	push   %ebp
80104162:	89 e5                	mov    %esp,%ebp
80104164:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104167:	e8 3b ff ff ff       	call   801040a7 <mpsearch>
8010416c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010416f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104173:	74 0a                	je     8010417f <mpconfig+0x1e>
80104175:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104178:	8b 40 04             	mov    0x4(%eax),%eax
8010417b:	85 c0                	test   %eax,%eax
8010417d:	75 0a                	jne    80104189 <mpconfig+0x28>
    return 0;
8010417f:	b8 00 00 00 00       	mov    $0x0,%eax
80104184:	e9 83 00 00 00       	jmp    8010420c <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104189:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010418c:	8b 40 04             	mov    0x4(%eax),%eax
8010418f:	89 04 24             	mov    %eax,(%esp)
80104192:	e8 fd fd ff ff       	call   80103f94 <p2v>
80104197:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
8010419a:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801041a1:	00 
801041a2:	c7 44 24 04 3d 8d 10 	movl   $0x80108d3d,0x4(%esp)
801041a9:	80 
801041aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041ad:	89 04 24             	mov    %eax,(%esp)
801041b0:	e8 9d 15 00 00       	call   80105752 <memcmp>
801041b5:	85 c0                	test   %eax,%eax
801041b7:	74 07                	je     801041c0 <mpconfig+0x5f>
    return 0;
801041b9:	b8 00 00 00 00       	mov    $0x0,%eax
801041be:	eb 4c                	jmp    8010420c <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801041c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041c3:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801041c7:	3c 01                	cmp    $0x1,%al
801041c9:	74 12                	je     801041dd <mpconfig+0x7c>
801041cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041ce:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801041d2:	3c 04                	cmp    $0x4,%al
801041d4:	74 07                	je     801041dd <mpconfig+0x7c>
    return 0;
801041d6:	b8 00 00 00 00       	mov    $0x0,%eax
801041db:	eb 2f                	jmp    8010420c <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801041dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041e0:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801041e4:	0f b7 c0             	movzwl %ax,%eax
801041e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801041eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041ee:	89 04 24             	mov    %eax,(%esp)
801041f1:	e8 04 fe ff ff       	call   80103ffa <sum>
801041f6:	84 c0                	test   %al,%al
801041f8:	74 07                	je     80104201 <mpconfig+0xa0>
    return 0;
801041fa:	b8 00 00 00 00       	mov    $0x0,%eax
801041ff:	eb 0b                	jmp    8010420c <mpconfig+0xab>
  *pmp = mp;
80104201:	8b 45 08             	mov    0x8(%ebp),%eax
80104204:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104207:	89 10                	mov    %edx,(%eax)
  return conf;
80104209:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010420c:	c9                   	leave  
8010420d:	c3                   	ret    

8010420e <mpinit>:

void
mpinit(void)
{
8010420e:	55                   	push   %ebp
8010420f:	89 e5                	mov    %esp,%ebp
80104211:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104214:	c7 05 44 c6 10 80 c0 	movl   $0x80113bc0,0x8010c644
8010421b:	3b 11 80 
  if((conf = mpconfig(&mp)) == 0)
8010421e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104221:	89 04 24             	mov    %eax,(%esp)
80104224:	e8 38 ff ff ff       	call   80104161 <mpconfig>
80104229:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010422c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104230:	75 05                	jne    80104237 <mpinit+0x29>
    return;
80104232:	e9 9c 01 00 00       	jmp    801043d3 <mpinit+0x1c5>
  ismp = 1;
80104237:	c7 05 a4 3b 11 80 01 	movl   $0x1,0x80113ba4
8010423e:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104241:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104244:	8b 40 24             	mov    0x24(%eax),%eax
80104247:	a3 bc 3a 11 80       	mov    %eax,0x80113abc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010424c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010424f:	83 c0 2c             	add    $0x2c,%eax
80104252:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104255:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104258:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010425c:	0f b7 d0             	movzwl %ax,%edx
8010425f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104262:	01 d0                	add    %edx,%eax
80104264:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104267:	e9 f4 00 00 00       	jmp    80104360 <mpinit+0x152>
    switch(*p){
8010426c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010426f:	0f b6 00             	movzbl (%eax),%eax
80104272:	0f b6 c0             	movzbl %al,%eax
80104275:	83 f8 04             	cmp    $0x4,%eax
80104278:	0f 87 bf 00 00 00    	ja     8010433d <mpinit+0x12f>
8010427e:	8b 04 85 80 8d 10 80 	mov    -0x7fef7280(,%eax,4),%eax
80104285:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104287:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010428a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
8010428d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104290:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104294:	0f b6 d0             	movzbl %al,%edx
80104297:	a1 a0 41 11 80       	mov    0x801141a0,%eax
8010429c:	39 c2                	cmp    %eax,%edx
8010429e:	74 2d                	je     801042cd <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801042a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801042a3:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801042a7:	0f b6 d0             	movzbl %al,%edx
801042aa:	a1 a0 41 11 80       	mov    0x801141a0,%eax
801042af:	89 54 24 08          	mov    %edx,0x8(%esp)
801042b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801042b7:	c7 04 24 42 8d 10 80 	movl   $0x80108d42,(%esp)
801042be:	e8 dd c0 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
801042c3:	c7 05 a4 3b 11 80 00 	movl   $0x0,0x80113ba4
801042ca:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801042cd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801042d0:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801042d4:	0f b6 c0             	movzbl %al,%eax
801042d7:	83 e0 02             	and    $0x2,%eax
801042da:	85 c0                	test   %eax,%eax
801042dc:	74 15                	je     801042f3 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
801042de:	a1 a0 41 11 80       	mov    0x801141a0,%eax
801042e3:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801042e9:	05 c0 3b 11 80       	add    $0x80113bc0,%eax
801042ee:	a3 44 c6 10 80       	mov    %eax,0x8010c644
      cpus[ncpu].id = ncpu;
801042f3:	8b 15 a0 41 11 80    	mov    0x801141a0,%edx
801042f9:	a1 a0 41 11 80       	mov    0x801141a0,%eax
801042fe:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104304:	81 c2 c0 3b 11 80    	add    $0x80113bc0,%edx
8010430a:	88 02                	mov    %al,(%edx)
      ncpu++;
8010430c:	a1 a0 41 11 80       	mov    0x801141a0,%eax
80104311:	83 c0 01             	add    $0x1,%eax
80104314:	a3 a0 41 11 80       	mov    %eax,0x801141a0
      p += sizeof(struct mpproc);
80104319:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
8010431d:	eb 41                	jmp    80104360 <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
8010431f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104322:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104325:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104328:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010432c:	a2 a0 3b 11 80       	mov    %al,0x80113ba0
      p += sizeof(struct mpioapic);
80104331:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104335:	eb 29                	jmp    80104360 <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104337:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010433b:	eb 23                	jmp    80104360 <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
8010433d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104340:	0f b6 00             	movzbl (%eax),%eax
80104343:	0f b6 c0             	movzbl %al,%eax
80104346:	89 44 24 04          	mov    %eax,0x4(%esp)
8010434a:	c7 04 24 60 8d 10 80 	movl   $0x80108d60,(%esp)
80104351:	e8 4a c0 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80104356:	c7 05 a4 3b 11 80 00 	movl   $0x0,0x80113ba4
8010435d:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104363:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104366:	0f 82 00 ff ff ff    	jb     8010426c <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
8010436c:	a1 a4 3b 11 80       	mov    0x80113ba4,%eax
80104371:	85 c0                	test   %eax,%eax
80104373:	75 1d                	jne    80104392 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104375:	c7 05 a0 41 11 80 01 	movl   $0x1,0x801141a0
8010437c:	00 00 00 
    lapic = 0;
8010437f:	c7 05 bc 3a 11 80 00 	movl   $0x0,0x80113abc
80104386:	00 00 00 
    ioapicid = 0;
80104389:	c6 05 a0 3b 11 80 00 	movb   $0x0,0x80113ba0
    return;
80104390:	eb 41                	jmp    801043d3 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80104392:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104395:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104399:	84 c0                	test   %al,%al
8010439b:	74 36                	je     801043d3 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
8010439d:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801043a4:	00 
801043a5:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801043ac:	e8 0d fc ff ff       	call   80103fbe <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801043b1:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801043b8:	e8 e4 fb ff ff       	call   80103fa1 <inb>
801043bd:	83 c8 01             	or     $0x1,%eax
801043c0:	0f b6 c0             	movzbl %al,%eax
801043c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801043c7:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801043ce:	e8 eb fb ff ff       	call   80103fbe <outb>
  }
}
801043d3:	c9                   	leave  
801043d4:	c3                   	ret    

801043d5 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801043d5:	55                   	push   %ebp
801043d6:	89 e5                	mov    %esp,%ebp
801043d8:	83 ec 08             	sub    $0x8,%esp
801043db:	8b 55 08             	mov    0x8(%ebp),%edx
801043de:	8b 45 0c             	mov    0xc(%ebp),%eax
801043e1:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801043e5:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801043e8:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801043ec:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801043f0:	ee                   	out    %al,(%dx)
}
801043f1:	c9                   	leave  
801043f2:	c3                   	ret    

801043f3 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
801043f3:	55                   	push   %ebp
801043f4:	89 e5                	mov    %esp,%ebp
801043f6:	83 ec 0c             	sub    $0xc,%esp
801043f9:	8b 45 08             	mov    0x8(%ebp),%eax
801043fc:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104400:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104404:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
8010440a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010440e:	0f b6 c0             	movzbl %al,%eax
80104411:	89 44 24 04          	mov    %eax,0x4(%esp)
80104415:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010441c:	e8 b4 ff ff ff       	call   801043d5 <outb>
  outb(IO_PIC2+1, mask >> 8);
80104421:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104425:	66 c1 e8 08          	shr    $0x8,%ax
80104429:	0f b6 c0             	movzbl %al,%eax
8010442c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104430:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104437:	e8 99 ff ff ff       	call   801043d5 <outb>
}
8010443c:	c9                   	leave  
8010443d:	c3                   	ret    

8010443e <picenable>:

void
picenable(int irq)
{
8010443e:	55                   	push   %ebp
8010443f:	89 e5                	mov    %esp,%ebp
80104441:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104444:	8b 45 08             	mov    0x8(%ebp),%eax
80104447:	ba 01 00 00 00       	mov    $0x1,%edx
8010444c:	89 c1                	mov    %eax,%ecx
8010444e:	d3 e2                	shl    %cl,%edx
80104450:	89 d0                	mov    %edx,%eax
80104452:	f7 d0                	not    %eax
80104454:	89 c2                	mov    %eax,%edx
80104456:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010445d:	21 d0                	and    %edx,%eax
8010445f:	0f b7 c0             	movzwl %ax,%eax
80104462:	89 04 24             	mov    %eax,(%esp)
80104465:	e8 89 ff ff ff       	call   801043f3 <picsetmask>
}
8010446a:	c9                   	leave  
8010446b:	c3                   	ret    

8010446c <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
8010446c:	55                   	push   %ebp
8010446d:	89 e5                	mov    %esp,%ebp
8010446f:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104472:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104479:	00 
8010447a:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104481:	e8 4f ff ff ff       	call   801043d5 <outb>
  outb(IO_PIC2+1, 0xFF);
80104486:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010448d:	00 
8010448e:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104495:	e8 3b ff ff ff       	call   801043d5 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
8010449a:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801044a1:	00 
801044a2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801044a9:	e8 27 ff ff ff       	call   801043d5 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801044ae:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801044b5:	00 
801044b6:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801044bd:	e8 13 ff ff ff       	call   801043d5 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801044c2:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801044c9:	00 
801044ca:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801044d1:	e8 ff fe ff ff       	call   801043d5 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801044d6:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801044dd:	00 
801044de:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801044e5:	e8 eb fe ff ff       	call   801043d5 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
801044ea:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801044f1:	00 
801044f2:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801044f9:	e8 d7 fe ff ff       	call   801043d5 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
801044fe:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104505:	00 
80104506:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010450d:	e8 c3 fe ff ff       	call   801043d5 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104512:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104519:	00 
8010451a:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104521:	e8 af fe ff ff       	call   801043d5 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104526:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010452d:	00 
8010452e:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104535:	e8 9b fe ff ff       	call   801043d5 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
8010453a:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104541:	00 
80104542:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104549:	e8 87 fe ff ff       	call   801043d5 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
8010454e:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104555:	00 
80104556:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010455d:	e8 73 fe ff ff       	call   801043d5 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104562:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104569:	00 
8010456a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104571:	e8 5f fe ff ff       	call   801043d5 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104576:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010457d:	00 
8010457e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104585:	e8 4b fe ff ff       	call   801043d5 <outb>

  if(irqmask != 0xFFFF)
8010458a:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104591:	66 83 f8 ff          	cmp    $0xffff,%ax
80104595:	74 12                	je     801045a9 <picinit+0x13d>
    picsetmask(irqmask);
80104597:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010459e:	0f b7 c0             	movzwl %ax,%eax
801045a1:	89 04 24             	mov    %eax,(%esp)
801045a4:	e8 4a fe ff ff       	call   801043f3 <picsetmask>
}
801045a9:	c9                   	leave  
801045aa:	c3                   	ret    

801045ab <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801045ab:	55                   	push   %ebp
801045ac:	89 e5                	mov    %esp,%ebp
801045ae:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801045b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801045b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801045bb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801045c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801045c4:	8b 10                	mov    (%eax),%edx
801045c6:	8b 45 08             	mov    0x8(%ebp),%eax
801045c9:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801045cb:	e8 54 cf ff ff       	call   80101524 <filealloc>
801045d0:	8b 55 08             	mov    0x8(%ebp),%edx
801045d3:	89 02                	mov    %eax,(%edx)
801045d5:	8b 45 08             	mov    0x8(%ebp),%eax
801045d8:	8b 00                	mov    (%eax),%eax
801045da:	85 c0                	test   %eax,%eax
801045dc:	0f 84 c8 00 00 00    	je     801046aa <pipealloc+0xff>
801045e2:	e8 3d cf ff ff       	call   80101524 <filealloc>
801045e7:	8b 55 0c             	mov    0xc(%ebp),%edx
801045ea:	89 02                	mov    %eax,(%edx)
801045ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801045ef:	8b 00                	mov    (%eax),%eax
801045f1:	85 c0                	test   %eax,%eax
801045f3:	0f 84 b1 00 00 00    	je     801046aa <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
801045f9:	e8 7d eb ff ff       	call   8010317b <kalloc>
801045fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104601:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104605:	75 05                	jne    8010460c <pipealloc+0x61>
    goto bad;
80104607:	e9 9e 00 00 00       	jmp    801046aa <pipealloc+0xff>
  p->readopen = 1;
8010460c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010460f:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104616:	00 00 00 
  p->writeopen = 1;
80104619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010461c:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104623:	00 00 00 
  p->nwrite = 0;
80104626:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104629:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104630:	00 00 00 
  p->nread = 0;
80104633:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104636:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
8010463d:	00 00 00 
  initlock(&p->lock, "pipe");
80104640:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104643:	c7 44 24 04 94 8d 10 	movl   $0x80108d94,0x4(%esp)
8010464a:	80 
8010464b:	89 04 24             	mov    %eax,(%esp)
8010464e:	e8 13 0e 00 00       	call   80105466 <initlock>
  (*f0)->type = FD_PIPE;
80104653:	8b 45 08             	mov    0x8(%ebp),%eax
80104656:	8b 00                	mov    (%eax),%eax
80104658:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
8010465e:	8b 45 08             	mov    0x8(%ebp),%eax
80104661:	8b 00                	mov    (%eax),%eax
80104663:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104667:	8b 45 08             	mov    0x8(%ebp),%eax
8010466a:	8b 00                	mov    (%eax),%eax
8010466c:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104670:	8b 45 08             	mov    0x8(%ebp),%eax
80104673:	8b 00                	mov    (%eax),%eax
80104675:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104678:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010467b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010467e:	8b 00                	mov    (%eax),%eax
80104680:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104686:	8b 45 0c             	mov    0xc(%ebp),%eax
80104689:	8b 00                	mov    (%eax),%eax
8010468b:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010468f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104692:	8b 00                	mov    (%eax),%eax
80104694:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104698:	8b 45 0c             	mov    0xc(%ebp),%eax
8010469b:	8b 00                	mov    (%eax),%eax
8010469d:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046a0:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801046a3:	b8 00 00 00 00       	mov    $0x0,%eax
801046a8:	eb 42                	jmp    801046ec <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
801046aa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046ae:	74 0b                	je     801046bb <pipealloc+0x110>
    kfree((char*)p);
801046b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046b3:	89 04 24             	mov    %eax,(%esp)
801046b6:	e8 27 ea ff ff       	call   801030e2 <kfree>
  if(*f0)
801046bb:	8b 45 08             	mov    0x8(%ebp),%eax
801046be:	8b 00                	mov    (%eax),%eax
801046c0:	85 c0                	test   %eax,%eax
801046c2:	74 0d                	je     801046d1 <pipealloc+0x126>
    fileclose(*f0);
801046c4:	8b 45 08             	mov    0x8(%ebp),%eax
801046c7:	8b 00                	mov    (%eax),%eax
801046c9:	89 04 24             	mov    %eax,(%esp)
801046cc:	e8 fb ce ff ff       	call   801015cc <fileclose>
  if(*f1)
801046d1:	8b 45 0c             	mov    0xc(%ebp),%eax
801046d4:	8b 00                	mov    (%eax),%eax
801046d6:	85 c0                	test   %eax,%eax
801046d8:	74 0d                	je     801046e7 <pipealloc+0x13c>
    fileclose(*f1);
801046da:	8b 45 0c             	mov    0xc(%ebp),%eax
801046dd:	8b 00                	mov    (%eax),%eax
801046df:	89 04 24             	mov    %eax,(%esp)
801046e2:	e8 e5 ce ff ff       	call   801015cc <fileclose>
  return -1;
801046e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801046ec:	c9                   	leave  
801046ed:	c3                   	ret    

801046ee <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801046ee:	55                   	push   %ebp
801046ef:	89 e5                	mov    %esp,%ebp
801046f1:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801046f4:	8b 45 08             	mov    0x8(%ebp),%eax
801046f7:	89 04 24             	mov    %eax,(%esp)
801046fa:	e8 88 0d 00 00       	call   80105487 <acquire>
  if(writable){
801046ff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104703:	74 1f                	je     80104724 <pipeclose+0x36>
    p->writeopen = 0;
80104705:	8b 45 08             	mov    0x8(%ebp),%eax
80104708:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
8010470f:	00 00 00 
    wakeup(&p->nread);
80104712:	8b 45 08             	mov    0x8(%ebp),%eax
80104715:	05 34 02 00 00       	add    $0x234,%eax
8010471a:	89 04 24             	mov    %eax,(%esp)
8010471d:	e8 74 0b 00 00       	call   80105296 <wakeup>
80104722:	eb 1d                	jmp    80104741 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104724:	8b 45 08             	mov    0x8(%ebp),%eax
80104727:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
8010472e:	00 00 00 
    wakeup(&p->nwrite);
80104731:	8b 45 08             	mov    0x8(%ebp),%eax
80104734:	05 38 02 00 00       	add    $0x238,%eax
80104739:	89 04 24             	mov    %eax,(%esp)
8010473c:	e8 55 0b 00 00       	call   80105296 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104741:	8b 45 08             	mov    0x8(%ebp),%eax
80104744:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010474a:	85 c0                	test   %eax,%eax
8010474c:	75 25                	jne    80104773 <pipeclose+0x85>
8010474e:	8b 45 08             	mov    0x8(%ebp),%eax
80104751:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104757:	85 c0                	test   %eax,%eax
80104759:	75 18                	jne    80104773 <pipeclose+0x85>
    release(&p->lock);
8010475b:	8b 45 08             	mov    0x8(%ebp),%eax
8010475e:	89 04 24             	mov    %eax,(%esp)
80104761:	e8 83 0d 00 00       	call   801054e9 <release>
    kfree((char*)p);
80104766:	8b 45 08             	mov    0x8(%ebp),%eax
80104769:	89 04 24             	mov    %eax,(%esp)
8010476c:	e8 71 e9 ff ff       	call   801030e2 <kfree>
80104771:	eb 0b                	jmp    8010477e <pipeclose+0x90>
  } else
    release(&p->lock);
80104773:	8b 45 08             	mov    0x8(%ebp),%eax
80104776:	89 04 24             	mov    %eax,(%esp)
80104779:	e8 6b 0d 00 00       	call   801054e9 <release>
}
8010477e:	c9                   	leave  
8010477f:	c3                   	ret    

80104780 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104780:	55                   	push   %ebp
80104781:	89 e5                	mov    %esp,%ebp
80104783:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104786:	8b 45 08             	mov    0x8(%ebp),%eax
80104789:	89 04 24             	mov    %eax,(%esp)
8010478c:	e8 f6 0c 00 00       	call   80105487 <acquire>
  for(i = 0; i < n; i++){
80104791:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104798:	e9 a6 00 00 00       	jmp    80104843 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010479d:	eb 57                	jmp    801047f6 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
8010479f:	8b 45 08             	mov    0x8(%ebp),%eax
801047a2:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801047a8:	85 c0                	test   %eax,%eax
801047aa:	74 0d                	je     801047b9 <pipewrite+0x39>
801047ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047b2:	8b 40 24             	mov    0x24(%eax),%eax
801047b5:	85 c0                	test   %eax,%eax
801047b7:	74 15                	je     801047ce <pipewrite+0x4e>
        release(&p->lock);
801047b9:	8b 45 08             	mov    0x8(%ebp),%eax
801047bc:	89 04 24             	mov    %eax,(%esp)
801047bf:	e8 25 0d 00 00       	call   801054e9 <release>
        return -1;
801047c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047c9:	e9 9f 00 00 00       	jmp    8010486d <pipewrite+0xed>
      }
      wakeup(&p->nread);
801047ce:	8b 45 08             	mov    0x8(%ebp),%eax
801047d1:	05 34 02 00 00       	add    $0x234,%eax
801047d6:	89 04 24             	mov    %eax,(%esp)
801047d9:	e8 b8 0a 00 00       	call   80105296 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801047de:	8b 45 08             	mov    0x8(%ebp),%eax
801047e1:	8b 55 08             	mov    0x8(%ebp),%edx
801047e4:	81 c2 38 02 00 00    	add    $0x238,%edx
801047ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801047ee:	89 14 24             	mov    %edx,(%esp)
801047f1:	e8 c7 09 00 00       	call   801051bd <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801047f6:	8b 45 08             	mov    0x8(%ebp),%eax
801047f9:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801047ff:	8b 45 08             	mov    0x8(%ebp),%eax
80104802:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104808:	05 00 02 00 00       	add    $0x200,%eax
8010480d:	39 c2                	cmp    %eax,%edx
8010480f:	74 8e                	je     8010479f <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104811:	8b 45 08             	mov    0x8(%ebp),%eax
80104814:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010481a:	8d 48 01             	lea    0x1(%eax),%ecx
8010481d:	8b 55 08             	mov    0x8(%ebp),%edx
80104820:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104826:	25 ff 01 00 00       	and    $0x1ff,%eax
8010482b:	89 c1                	mov    %eax,%ecx
8010482d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104830:	8b 45 0c             	mov    0xc(%ebp),%eax
80104833:	01 d0                	add    %edx,%eax
80104835:	0f b6 10             	movzbl (%eax),%edx
80104838:	8b 45 08             	mov    0x8(%ebp),%eax
8010483b:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
8010483f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104843:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104846:	3b 45 10             	cmp    0x10(%ebp),%eax
80104849:	0f 8c 4e ff ff ff    	jl     8010479d <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010484f:	8b 45 08             	mov    0x8(%ebp),%eax
80104852:	05 34 02 00 00       	add    $0x234,%eax
80104857:	89 04 24             	mov    %eax,(%esp)
8010485a:	e8 37 0a 00 00       	call   80105296 <wakeup>
  release(&p->lock);
8010485f:	8b 45 08             	mov    0x8(%ebp),%eax
80104862:	89 04 24             	mov    %eax,(%esp)
80104865:	e8 7f 0c 00 00       	call   801054e9 <release>
  return n;
8010486a:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010486d:	c9                   	leave  
8010486e:	c3                   	ret    

8010486f <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
8010486f:	55                   	push   %ebp
80104870:	89 e5                	mov    %esp,%ebp
80104872:	53                   	push   %ebx
80104873:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104876:	8b 45 08             	mov    0x8(%ebp),%eax
80104879:	89 04 24             	mov    %eax,(%esp)
8010487c:	e8 06 0c 00 00       	call   80105487 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104881:	eb 3a                	jmp    801048bd <piperead+0x4e>
    if(proc->killed){
80104883:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104889:	8b 40 24             	mov    0x24(%eax),%eax
8010488c:	85 c0                	test   %eax,%eax
8010488e:	74 15                	je     801048a5 <piperead+0x36>
      release(&p->lock);
80104890:	8b 45 08             	mov    0x8(%ebp),%eax
80104893:	89 04 24             	mov    %eax,(%esp)
80104896:	e8 4e 0c 00 00       	call   801054e9 <release>
      return -1;
8010489b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048a0:	e9 b5 00 00 00       	jmp    8010495a <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801048a5:	8b 45 08             	mov    0x8(%ebp),%eax
801048a8:	8b 55 08             	mov    0x8(%ebp),%edx
801048ab:	81 c2 34 02 00 00    	add    $0x234,%edx
801048b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801048b5:	89 14 24             	mov    %edx,(%esp)
801048b8:	e8 00 09 00 00       	call   801051bd <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801048bd:	8b 45 08             	mov    0x8(%ebp),%eax
801048c0:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801048c6:	8b 45 08             	mov    0x8(%ebp),%eax
801048c9:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801048cf:	39 c2                	cmp    %eax,%edx
801048d1:	75 0d                	jne    801048e0 <piperead+0x71>
801048d3:	8b 45 08             	mov    0x8(%ebp),%eax
801048d6:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801048dc:	85 c0                	test   %eax,%eax
801048de:	75 a3                	jne    80104883 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801048e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801048e7:	eb 4b                	jmp    80104934 <piperead+0xc5>
    if(p->nread == p->nwrite)
801048e9:	8b 45 08             	mov    0x8(%ebp),%eax
801048ec:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801048f2:	8b 45 08             	mov    0x8(%ebp),%eax
801048f5:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801048fb:	39 c2                	cmp    %eax,%edx
801048fd:	75 02                	jne    80104901 <piperead+0x92>
      break;
801048ff:	eb 3b                	jmp    8010493c <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104901:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104904:	8b 45 0c             	mov    0xc(%ebp),%eax
80104907:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010490a:	8b 45 08             	mov    0x8(%ebp),%eax
8010490d:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104913:	8d 48 01             	lea    0x1(%eax),%ecx
80104916:	8b 55 08             	mov    0x8(%ebp),%edx
80104919:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
8010491f:	25 ff 01 00 00       	and    $0x1ff,%eax
80104924:	89 c2                	mov    %eax,%edx
80104926:	8b 45 08             	mov    0x8(%ebp),%eax
80104929:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
8010492e:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104930:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104934:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104937:	3b 45 10             	cmp    0x10(%ebp),%eax
8010493a:	7c ad                	jl     801048e9 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010493c:	8b 45 08             	mov    0x8(%ebp),%eax
8010493f:	05 38 02 00 00       	add    $0x238,%eax
80104944:	89 04 24             	mov    %eax,(%esp)
80104947:	e8 4a 09 00 00       	call   80105296 <wakeup>
  release(&p->lock);
8010494c:	8b 45 08             	mov    0x8(%ebp),%eax
8010494f:	89 04 24             	mov    %eax,(%esp)
80104952:	e8 92 0b 00 00       	call   801054e9 <release>
  return i;
80104957:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010495a:	83 c4 24             	add    $0x24,%esp
8010495d:	5b                   	pop    %ebx
8010495e:	5d                   	pop    %ebp
8010495f:	c3                   	ret    

80104960 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104960:	55                   	push   %ebp
80104961:	89 e5                	mov    %esp,%ebp
80104963:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104966:	9c                   	pushf  
80104967:	58                   	pop    %eax
80104968:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
8010496b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010496e:	c9                   	leave  
8010496f:	c3                   	ret    

80104970 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104970:	55                   	push   %ebp
80104971:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104973:	fb                   	sti    
}
80104974:	5d                   	pop    %ebp
80104975:	c3                   	ret    

80104976 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104976:	55                   	push   %ebp
80104977:	89 e5                	mov    %esp,%ebp
80104979:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
8010497c:	c7 44 24 04 99 8d 10 	movl   $0x80108d99,0x4(%esp)
80104983:	80 
80104984:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010498b:	e8 d6 0a 00 00       	call   80105466 <initlock>
}
80104990:	c9                   	leave  
80104991:	c3                   	ret    

80104992 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104992:	55                   	push   %ebp
80104993:	89 e5                	mov    %esp,%ebp
80104995:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104998:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010499f:	e8 e3 0a 00 00       	call   80105487 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801049a4:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
801049ab:	eb 50                	jmp    801049fd <allocproc+0x6b>
    if(p->state == UNUSED)
801049ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049b0:	8b 40 0c             	mov    0xc(%eax),%eax
801049b3:	85 c0                	test   %eax,%eax
801049b5:	75 42                	jne    801049f9 <allocproc+0x67>
      goto found;
801049b7:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801049b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049bb:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801049c2:	a1 04 c0 10 80       	mov    0x8010c004,%eax
801049c7:	8d 50 01             	lea    0x1(%eax),%edx
801049ca:	89 15 04 c0 10 80    	mov    %edx,0x8010c004
801049d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049d3:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
801049d6:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801049dd:	e8 07 0b 00 00       	call   801054e9 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801049e2:	e8 94 e7 ff ff       	call   8010317b <kalloc>
801049e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049ea:	89 42 08             	mov    %eax,0x8(%edx)
801049ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049f0:	8b 40 08             	mov    0x8(%eax),%eax
801049f3:	85 c0                	test   %eax,%eax
801049f5:	75 33                	jne    80104a2a <allocproc+0x98>
801049f7:	eb 20                	jmp    80104a19 <allocproc+0x87>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801049f9:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801049fd:	81 7d f4 f4 60 11 80 	cmpl   $0x801160f4,-0xc(%ebp)
80104a04:	72 a7                	jb     801049ad <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104a06:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104a0d:	e8 d7 0a 00 00       	call   801054e9 <release>
  return 0;
80104a12:	b8 00 00 00 00       	mov    $0x0,%eax
80104a17:	eb 76                	jmp    80104a8f <allocproc+0xfd>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
80104a19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a1c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104a23:	b8 00 00 00 00       	mov    $0x0,%eax
80104a28:	eb 65                	jmp    80104a8f <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80104a2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a2d:	8b 40 08             	mov    0x8(%eax),%eax
80104a30:	05 00 10 00 00       	add    $0x1000,%eax
80104a35:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104a38:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104a3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a3f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104a42:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104a45:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104a49:	ba ef 6a 10 80       	mov    $0x80106aef,%edx
80104a4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a51:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104a53:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104a57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104a5d:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104a60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a63:	8b 40 1c             	mov    0x1c(%eax),%eax
80104a66:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104a6d:	00 
80104a6e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104a75:	00 
80104a76:	89 04 24             	mov    %eax,(%esp)
80104a79:	e8 5d 0c 00 00       	call   801056db <memset>
  p->context->eip = (uint)forkret;
80104a7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a81:	8b 40 1c             	mov    0x1c(%eax),%eax
80104a84:	ba 7e 51 10 80       	mov    $0x8010517e,%edx
80104a89:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a8f:	c9                   	leave  
80104a90:	c3                   	ret    

80104a91 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104a91:	55                   	push   %ebp
80104a92:	89 e5                	mov    %esp,%ebp
80104a94:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104a97:	e8 f6 fe ff ff       	call   80104992 <allocproc>
80104a9c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104a9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa2:	a3 48 c6 10 80       	mov    %eax,0x8010c648
  if((p->pgdir = setupkvm()) == 0)
80104aa7:	e8 37 37 00 00       	call   801081e3 <setupkvm>
80104aac:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104aaf:	89 42 04             	mov    %eax,0x4(%edx)
80104ab2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab5:	8b 40 04             	mov    0x4(%eax),%eax
80104ab8:	85 c0                	test   %eax,%eax
80104aba:	75 0c                	jne    80104ac8 <userinit+0x37>
    panic("userinit: out of memory?");
80104abc:	c7 04 24 a0 8d 10 80 	movl   $0x80108da0,(%esp)
80104ac3:	e8 72 ba ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104ac8:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104acd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad0:	8b 40 04             	mov    0x4(%eax),%eax
80104ad3:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ad7:	c7 44 24 04 e0 c4 10 	movl   $0x8010c4e0,0x4(%esp)
80104ade:	80 
80104adf:	89 04 24             	mov    %eax,(%esp)
80104ae2:	e8 54 39 00 00       	call   8010843b <inituvm>
  p->sz = PGSIZE;
80104ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aea:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104af0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104af3:	8b 40 18             	mov    0x18(%eax),%eax
80104af6:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104afd:	00 
80104afe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b05:	00 
80104b06:	89 04 24             	mov    %eax,(%esp)
80104b09:	e8 cd 0b 00 00       	call   801056db <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104b0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b11:	8b 40 18             	mov    0x18(%eax),%eax
80104b14:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104b1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b1d:	8b 40 18             	mov    0x18(%eax),%eax
80104b20:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104b26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b29:	8b 40 18             	mov    0x18(%eax),%eax
80104b2c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b2f:	8b 52 18             	mov    0x18(%edx),%edx
80104b32:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104b36:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104b3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b3d:	8b 40 18             	mov    0x18(%eax),%eax
80104b40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b43:	8b 52 18             	mov    0x18(%edx),%edx
80104b46:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104b4a:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104b4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b51:	8b 40 18             	mov    0x18(%eax),%eax
80104b54:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b5e:	8b 40 18             	mov    0x18(%eax),%eax
80104b61:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104b68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b6b:	8b 40 18             	mov    0x18(%eax),%eax
80104b6e:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104b75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b78:	83 c0 6c             	add    $0x6c,%eax
80104b7b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104b82:	00 
80104b83:	c7 44 24 04 b9 8d 10 	movl   $0x80108db9,0x4(%esp)
80104b8a:	80 
80104b8b:	89 04 24             	mov    %eax,(%esp)
80104b8e:	e8 68 0d 00 00       	call   801058fb <safestrcpy>
  p->cwd = namei("/");
80104b93:	c7 04 24 c2 8d 10 80 	movl   $0x80108dc2,(%esp)
80104b9a:	e8 c9 de ff ff       	call   80102a68 <namei>
80104b9f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ba2:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104baf:	c9                   	leave  
80104bb0:	c3                   	ret    

80104bb1 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104bb1:	55                   	push   %ebp
80104bb2:	89 e5                	mov    %esp,%ebp
80104bb4:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104bb7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bbd:	8b 00                	mov    (%eax),%eax
80104bbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104bc2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104bc6:	7e 34                	jle    80104bfc <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104bc8:	8b 55 08             	mov    0x8(%ebp),%edx
80104bcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bce:	01 c2                	add    %eax,%edx
80104bd0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bd6:	8b 40 04             	mov    0x4(%eax),%eax
80104bd9:	89 54 24 08          	mov    %edx,0x8(%esp)
80104bdd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104be0:	89 54 24 04          	mov    %edx,0x4(%esp)
80104be4:	89 04 24             	mov    %eax,(%esp)
80104be7:	e8 c5 39 00 00       	call   801085b1 <allocuvm>
80104bec:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104bef:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104bf3:	75 41                	jne    80104c36 <growproc+0x85>
      return -1;
80104bf5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bfa:	eb 58                	jmp    80104c54 <growproc+0xa3>
  } else if(n < 0){
80104bfc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104c00:	79 34                	jns    80104c36 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104c02:	8b 55 08             	mov    0x8(%ebp),%edx
80104c05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c08:	01 c2                	add    %eax,%edx
80104c0a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c10:	8b 40 04             	mov    0x4(%eax),%eax
80104c13:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c17:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c1a:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c1e:	89 04 24             	mov    %eax,(%esp)
80104c21:	e8 65 3a 00 00       	call   8010868b <deallocuvm>
80104c26:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104c29:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104c2d:	75 07                	jne    80104c36 <growproc+0x85>
      return -1;
80104c2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c34:	eb 1e                	jmp    80104c54 <growproc+0xa3>
  }
  proc->sz = sz;
80104c36:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c3c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c3f:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104c41:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c47:	89 04 24             	mov    %eax,(%esp)
80104c4a:	e8 85 36 00 00       	call   801082d4 <switchuvm>
  return 0;
80104c4f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c54:	c9                   	leave  
80104c55:	c3                   	ret    

80104c56 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104c56:	55                   	push   %ebp
80104c57:	89 e5                	mov    %esp,%ebp
80104c59:	57                   	push   %edi
80104c5a:	56                   	push   %esi
80104c5b:	53                   	push   %ebx
80104c5c:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104c5f:	e8 2e fd ff ff       	call   80104992 <allocproc>
80104c64:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104c67:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104c6b:	75 0a                	jne    80104c77 <fork+0x21>
    return -1;
80104c6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c72:	e9 52 01 00 00       	jmp    80104dc9 <fork+0x173>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104c77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c7d:	8b 10                	mov    (%eax),%edx
80104c7f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c85:	8b 40 04             	mov    0x4(%eax),%eax
80104c88:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c8c:	89 04 24             	mov    %eax,(%esp)
80104c8f:	e8 93 3b 00 00       	call   80108827 <copyuvm>
80104c94:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104c97:	89 42 04             	mov    %eax,0x4(%edx)
80104c9a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c9d:	8b 40 04             	mov    0x4(%eax),%eax
80104ca0:	85 c0                	test   %eax,%eax
80104ca2:	75 2c                	jne    80104cd0 <fork+0x7a>
    kfree(np->kstack);
80104ca4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ca7:	8b 40 08             	mov    0x8(%eax),%eax
80104caa:	89 04 24             	mov    %eax,(%esp)
80104cad:	e8 30 e4 ff ff       	call   801030e2 <kfree>
    np->kstack = 0;
80104cb2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cb5:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104cbc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cbf:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104cc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ccb:	e9 f9 00 00 00       	jmp    80104dc9 <fork+0x173>
  }
  np->sz = proc->sz;
80104cd0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cd6:	8b 10                	mov    (%eax),%edx
80104cd8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cdb:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104cdd:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104ce4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ce7:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104cea:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ced:	8b 50 18             	mov    0x18(%eax),%edx
80104cf0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cf6:	8b 40 18             	mov    0x18(%eax),%eax
80104cf9:	89 c3                	mov    %eax,%ebx
80104cfb:	b8 13 00 00 00       	mov    $0x13,%eax
80104d00:	89 d7                	mov    %edx,%edi
80104d02:	89 de                	mov    %ebx,%esi
80104d04:	89 c1                	mov    %eax,%ecx
80104d06:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104d08:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104d0b:	8b 40 18             	mov    0x18(%eax),%eax
80104d0e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104d15:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104d1c:	eb 3d                	jmp    80104d5b <fork+0x105>
    if(proc->ofile[i])
80104d1e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d24:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104d27:	83 c2 08             	add    $0x8,%edx
80104d2a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104d2e:	85 c0                	test   %eax,%eax
80104d30:	74 25                	je     80104d57 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104d32:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d38:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104d3b:	83 c2 08             	add    $0x8,%edx
80104d3e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104d42:	89 04 24             	mov    %eax,(%esp)
80104d45:	e8 3a c8 ff ff       	call   80101584 <filedup>
80104d4a:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104d4d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104d50:	83 c1 08             	add    $0x8,%ecx
80104d53:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104d57:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104d5b:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104d5f:	7e bd                	jle    80104d1e <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104d61:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d67:	8b 40 68             	mov    0x68(%eax),%eax
80104d6a:	89 04 24             	mov    %eax,(%esp)
80104d6d:	e8 13 d1 ff ff       	call   80101e85 <idup>
80104d72:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104d75:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104d78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d7e:	8d 50 6c             	lea    0x6c(%eax),%edx
80104d81:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104d84:	83 c0 6c             	add    $0x6c,%eax
80104d87:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d8e:	00 
80104d8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80104d93:	89 04 24             	mov    %eax,(%esp)
80104d96:	e8 60 0b 00 00       	call   801058fb <safestrcpy>
 
  pid = np->pid;
80104d9b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104d9e:	8b 40 10             	mov    0x10(%eax),%eax
80104da1:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
80104da4:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104dab:	e8 d7 06 00 00       	call   80105487 <acquire>
  np->state = RUNNABLE;
80104db0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104db3:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
80104dba:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104dc1:	e8 23 07 00 00       	call   801054e9 <release>
  
  return pid;
80104dc6:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104dc9:	83 c4 2c             	add    $0x2c,%esp
80104dcc:	5b                   	pop    %ebx
80104dcd:	5e                   	pop    %esi
80104dce:	5f                   	pop    %edi
80104dcf:	5d                   	pop    %ebp
80104dd0:	c3                   	ret    

80104dd1 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104dd1:	55                   	push   %ebp
80104dd2:	89 e5                	mov    %esp,%ebp
80104dd4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104dd7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104dde:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104de3:	39 c2                	cmp    %eax,%edx
80104de5:	75 0c                	jne    80104df3 <exit+0x22>
    panic("init exiting");
80104de7:	c7 04 24 c4 8d 10 80 	movl   $0x80108dc4,(%esp)
80104dee:	e8 47 b7 ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104df3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104dfa:	eb 44                	jmp    80104e40 <exit+0x6f>
    if(proc->ofile[fd]){
80104dfc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e02:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e05:	83 c2 08             	add    $0x8,%edx
80104e08:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e0c:	85 c0                	test   %eax,%eax
80104e0e:	74 2c                	je     80104e3c <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104e10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e16:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e19:	83 c2 08             	add    $0x8,%edx
80104e1c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e20:	89 04 24             	mov    %eax,(%esp)
80104e23:	e8 a4 c7 ff ff       	call   801015cc <fileclose>
      proc->ofile[fd] = 0;
80104e28:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e2e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e31:	83 c2 08             	add    $0x8,%edx
80104e34:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104e3b:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104e3c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104e40:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104e44:	7e b6                	jle    80104dfc <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
80104e46:	e8 54 ec ff ff       	call   80103a9f <begin_op>
  iput(proc->cwd);
80104e4b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e51:	8b 40 68             	mov    0x68(%eax),%eax
80104e54:	89 04 24             	mov    %eax,(%esp)
80104e57:	e8 14 d2 ff ff       	call   80102070 <iput>
  end_op();
80104e5c:	e8 c2 ec ff ff       	call   80103b23 <end_op>
  proc->cwd = 0;
80104e61:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e67:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104e6e:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104e75:	e8 0d 06 00 00       	call   80105487 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104e7a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e80:	8b 40 14             	mov    0x14(%eax),%eax
80104e83:	89 04 24             	mov    %eax,(%esp)
80104e86:	e8 cd 03 00 00       	call   80105258 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e8b:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
80104e92:	eb 38                	jmp    80104ecc <exit+0xfb>
    if(p->parent == proc){
80104e94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e97:	8b 50 14             	mov    0x14(%eax),%edx
80104e9a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ea0:	39 c2                	cmp    %eax,%edx
80104ea2:	75 24                	jne    80104ec8 <exit+0xf7>
      p->parent = initproc;
80104ea4:	8b 15 48 c6 10 80    	mov    0x8010c648,%edx
80104eaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ead:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104eb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eb3:	8b 40 0c             	mov    0xc(%eax),%eax
80104eb6:	83 f8 05             	cmp    $0x5,%eax
80104eb9:	75 0d                	jne    80104ec8 <exit+0xf7>
        wakeup1(initproc);
80104ebb:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104ec0:	89 04 24             	mov    %eax,(%esp)
80104ec3:	e8 90 03 00 00       	call   80105258 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ec8:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104ecc:	81 7d f4 f4 60 11 80 	cmpl   $0x801160f4,-0xc(%ebp)
80104ed3:	72 bf                	jb     80104e94 <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104ed5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104edb:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104ee2:	e8 b3 01 00 00       	call   8010509a <sched>
  panic("zombie exit");
80104ee7:	c7 04 24 d1 8d 10 80 	movl   $0x80108dd1,(%esp)
80104eee:	e8 47 b6 ff ff       	call   8010053a <panic>

80104ef3 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104ef3:	55                   	push   %ebp
80104ef4:	89 e5                	mov    %esp,%ebp
80104ef6:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104ef9:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104f00:	e8 82 05 00 00       	call   80105487 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104f05:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f0c:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
80104f13:	e9 9a 00 00 00       	jmp    80104fb2 <wait+0xbf>
      if(p->parent != proc)
80104f18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f1b:	8b 50 14             	mov    0x14(%eax),%edx
80104f1e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f24:	39 c2                	cmp    %eax,%edx
80104f26:	74 05                	je     80104f2d <wait+0x3a>
        continue;
80104f28:	e9 81 00 00 00       	jmp    80104fae <wait+0xbb>
      havekids = 1;
80104f2d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104f34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f37:	8b 40 0c             	mov    0xc(%eax),%eax
80104f3a:	83 f8 05             	cmp    $0x5,%eax
80104f3d:	75 6f                	jne    80104fae <wait+0xbb>
        // Found one.
        pid = p->pid;
80104f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f42:	8b 40 10             	mov    0x10(%eax),%eax
80104f45:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104f48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f4b:	8b 40 08             	mov    0x8(%eax),%eax
80104f4e:	89 04 24             	mov    %eax,(%esp)
80104f51:	e8 8c e1 ff ff       	call   801030e2 <kfree>
        p->kstack = 0;
80104f56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f59:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104f60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f63:	8b 40 04             	mov    0x4(%eax),%eax
80104f66:	89 04 24             	mov    %eax,(%esp)
80104f69:	e8 d9 37 00 00       	call   80108747 <freevm>
        p->state = UNUSED;
80104f6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f71:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104f78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f7b:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104f82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f85:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104f8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f8f:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104f93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f96:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104f9d:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104fa4:	e8 40 05 00 00       	call   801054e9 <release>
        return pid;
80104fa9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104fac:	eb 52                	jmp    80105000 <wait+0x10d>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104fae:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104fb2:	81 7d f4 f4 60 11 80 	cmpl   $0x801160f4,-0xc(%ebp)
80104fb9:	0f 82 59 ff ff ff    	jb     80104f18 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104fbf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104fc3:	74 0d                	je     80104fd2 <wait+0xdf>
80104fc5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fcb:	8b 40 24             	mov    0x24(%eax),%eax
80104fce:	85 c0                	test   %eax,%eax
80104fd0:	74 13                	je     80104fe5 <wait+0xf2>
      release(&ptable.lock);
80104fd2:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104fd9:	e8 0b 05 00 00       	call   801054e9 <release>
      return -1;
80104fde:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fe3:	eb 1b                	jmp    80105000 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104fe5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104feb:	c7 44 24 04 c0 41 11 	movl   $0x801141c0,0x4(%esp)
80104ff2:	80 
80104ff3:	89 04 24             	mov    %eax,(%esp)
80104ff6:	e8 c2 01 00 00       	call   801051bd <sleep>
  }
80104ffb:	e9 05 ff ff ff       	jmp    80104f05 <wait+0x12>
}
80105000:	c9                   	leave  
80105001:	c3                   	ret    

80105002 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105002:	55                   	push   %ebp
80105003:	89 e5                	mov    %esp,%ebp
80105005:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80105008:	e8 63 f9 ff ff       	call   80104970 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010500d:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105014:	e8 6e 04 00 00       	call   80105487 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105019:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
80105020:	eb 5e                	jmp    80105080 <scheduler+0x7e>
      if(p->state != RUNNABLE)
80105022:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105025:	8b 40 0c             	mov    0xc(%eax),%eax
80105028:	83 f8 03             	cmp    $0x3,%eax
8010502b:	74 02                	je     8010502f <scheduler+0x2d>
        continue;
8010502d:	eb 4d                	jmp    8010507c <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
8010502f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105032:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80105038:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010503b:	89 04 24             	mov    %eax,(%esp)
8010503e:	e8 91 32 00 00       	call   801082d4 <switchuvm>
      p->state = RUNNING;
80105043:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105046:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
8010504d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105053:	8b 40 1c             	mov    0x1c(%eax),%eax
80105056:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010505d:	83 c2 04             	add    $0x4,%edx
80105060:	89 44 24 04          	mov    %eax,0x4(%esp)
80105064:	89 14 24             	mov    %edx,(%esp)
80105067:	e8 00 09 00 00       	call   8010596c <swtch>
      switchkvm();
8010506c:	e8 46 32 00 00       	call   801082b7 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105071:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105078:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010507c:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105080:	81 7d f4 f4 60 11 80 	cmpl   $0x801160f4,-0xc(%ebp)
80105087:	72 99                	jb     80105022 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105089:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105090:	e8 54 04 00 00       	call   801054e9 <release>

  }
80105095:	e9 6e ff ff ff       	jmp    80105008 <scheduler+0x6>

8010509a <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
8010509a:	55                   	push   %ebp
8010509b:	89 e5                	mov    %esp,%ebp
8010509d:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
801050a0:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801050a7:	e8 05 05 00 00       	call   801055b1 <holding>
801050ac:	85 c0                	test   %eax,%eax
801050ae:	75 0c                	jne    801050bc <sched+0x22>
    panic("sched ptable.lock");
801050b0:	c7 04 24 dd 8d 10 80 	movl   $0x80108ddd,(%esp)
801050b7:	e8 7e b4 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
801050bc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801050c2:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801050c8:	83 f8 01             	cmp    $0x1,%eax
801050cb:	74 0c                	je     801050d9 <sched+0x3f>
    panic("sched locks");
801050cd:	c7 04 24 ef 8d 10 80 	movl   $0x80108def,(%esp)
801050d4:	e8 61 b4 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
801050d9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050df:	8b 40 0c             	mov    0xc(%eax),%eax
801050e2:	83 f8 04             	cmp    $0x4,%eax
801050e5:	75 0c                	jne    801050f3 <sched+0x59>
    panic("sched running");
801050e7:	c7 04 24 fb 8d 10 80 	movl   $0x80108dfb,(%esp)
801050ee:	e8 47 b4 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
801050f3:	e8 68 f8 ff ff       	call   80104960 <readeflags>
801050f8:	25 00 02 00 00       	and    $0x200,%eax
801050fd:	85 c0                	test   %eax,%eax
801050ff:	74 0c                	je     8010510d <sched+0x73>
    panic("sched interruptible");
80105101:	c7 04 24 09 8e 10 80 	movl   $0x80108e09,(%esp)
80105108:	e8 2d b4 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
8010510d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105113:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105119:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
8010511c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105122:	8b 40 04             	mov    0x4(%eax),%eax
80105125:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010512c:	83 c2 1c             	add    $0x1c,%edx
8010512f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105133:	89 14 24             	mov    %edx,(%esp)
80105136:	e8 31 08 00 00       	call   8010596c <swtch>
  cpu->intena = intena;
8010513b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105141:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105144:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010514a:	c9                   	leave  
8010514b:	c3                   	ret    

8010514c <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
8010514c:	55                   	push   %ebp
8010514d:	89 e5                	mov    %esp,%ebp
8010514f:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105152:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105159:	e8 29 03 00 00       	call   80105487 <acquire>
  proc->state = RUNNABLE;
8010515e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105164:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010516b:	e8 2a ff ff ff       	call   8010509a <sched>
  release(&ptable.lock);
80105170:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105177:	e8 6d 03 00 00       	call   801054e9 <release>
}
8010517c:	c9                   	leave  
8010517d:	c3                   	ret    

8010517e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
8010517e:	55                   	push   %ebp
8010517f:	89 e5                	mov    %esp,%ebp
80105181:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105184:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010518b:	e8 59 03 00 00       	call   801054e9 <release>

  if (first) {
80105190:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80105195:	85 c0                	test   %eax,%eax
80105197:	74 22                	je     801051bb <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105199:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
801051a0:	00 00 00 
    iinit(ROOTDEV);
801051a3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801051aa:	e8 e0 c9 ff ff       	call   80101b8f <iinit>
    initlog(ROOTDEV);
801051af:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801051b6:	e8 e0 e6 ff ff       	call   8010389b <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
801051bb:	c9                   	leave  
801051bc:	c3                   	ret    

801051bd <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
801051bd:	55                   	push   %ebp
801051be:	89 e5                	mov    %esp,%ebp
801051c0:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
801051c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051c9:	85 c0                	test   %eax,%eax
801051cb:	75 0c                	jne    801051d9 <sleep+0x1c>
    panic("sleep");
801051cd:	c7 04 24 1d 8e 10 80 	movl   $0x80108e1d,(%esp)
801051d4:	e8 61 b3 ff ff       	call   8010053a <panic>

  if(lk == 0)
801051d9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801051dd:	75 0c                	jne    801051eb <sleep+0x2e>
    panic("sleep without lk");
801051df:	c7 04 24 23 8e 10 80 	movl   $0x80108e23,(%esp)
801051e6:	e8 4f b3 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801051eb:	81 7d 0c c0 41 11 80 	cmpl   $0x801141c0,0xc(%ebp)
801051f2:	74 17                	je     8010520b <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801051f4:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801051fb:	e8 87 02 00 00       	call   80105487 <acquire>
    release(lk);
80105200:	8b 45 0c             	mov    0xc(%ebp),%eax
80105203:	89 04 24             	mov    %eax,(%esp)
80105206:	e8 de 02 00 00       	call   801054e9 <release>
  }

  // Go to sleep.
  proc->chan = chan;
8010520b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105211:	8b 55 08             	mov    0x8(%ebp),%edx
80105214:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80105217:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010521d:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80105224:	e8 71 fe ff ff       	call   8010509a <sched>

  // Tidy up.
  proc->chan = 0;
80105229:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010522f:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80105236:	81 7d 0c c0 41 11 80 	cmpl   $0x801141c0,0xc(%ebp)
8010523d:	74 17                	je     80105256 <sleep+0x99>
    release(&ptable.lock);
8010523f:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105246:	e8 9e 02 00 00       	call   801054e9 <release>
    acquire(lk);
8010524b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010524e:	89 04 24             	mov    %eax,(%esp)
80105251:	e8 31 02 00 00       	call   80105487 <acquire>
  }
}
80105256:	c9                   	leave  
80105257:	c3                   	ret    

80105258 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105258:	55                   	push   %ebp
80105259:	89 e5                	mov    %esp,%ebp
8010525b:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010525e:	c7 45 fc f4 41 11 80 	movl   $0x801141f4,-0x4(%ebp)
80105265:	eb 24                	jmp    8010528b <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105267:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010526a:	8b 40 0c             	mov    0xc(%eax),%eax
8010526d:	83 f8 02             	cmp    $0x2,%eax
80105270:	75 15                	jne    80105287 <wakeup1+0x2f>
80105272:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105275:	8b 40 20             	mov    0x20(%eax),%eax
80105278:	3b 45 08             	cmp    0x8(%ebp),%eax
8010527b:	75 0a                	jne    80105287 <wakeup1+0x2f>
      p->state = RUNNABLE;
8010527d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105280:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105287:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
8010528b:	81 7d fc f4 60 11 80 	cmpl   $0x801160f4,-0x4(%ebp)
80105292:	72 d3                	jb     80105267 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105294:	c9                   	leave  
80105295:	c3                   	ret    

80105296 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105296:	55                   	push   %ebp
80105297:	89 e5                	mov    %esp,%ebp
80105299:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
8010529c:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801052a3:	e8 df 01 00 00       	call   80105487 <acquire>
  wakeup1(chan);
801052a8:	8b 45 08             	mov    0x8(%ebp),%eax
801052ab:	89 04 24             	mov    %eax,(%esp)
801052ae:	e8 a5 ff ff ff       	call   80105258 <wakeup1>
  release(&ptable.lock);
801052b3:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801052ba:	e8 2a 02 00 00       	call   801054e9 <release>
}
801052bf:	c9                   	leave  
801052c0:	c3                   	ret    

801052c1 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
801052c1:	55                   	push   %ebp
801052c2:	89 e5                	mov    %esp,%ebp
801052c4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
801052c7:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801052ce:	e8 b4 01 00 00       	call   80105487 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052d3:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
801052da:	eb 41                	jmp    8010531d <kill+0x5c>
    if(p->pid == pid){
801052dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052df:	8b 40 10             	mov    0x10(%eax),%eax
801052e2:	3b 45 08             	cmp    0x8(%ebp),%eax
801052e5:	75 32                	jne    80105319 <kill+0x58>
      p->killed = 1;
801052e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ea:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801052f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052f4:	8b 40 0c             	mov    0xc(%eax),%eax
801052f7:	83 f8 02             	cmp    $0x2,%eax
801052fa:	75 0a                	jne    80105306 <kill+0x45>
        p->state = RUNNABLE;
801052fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ff:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80105306:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010530d:	e8 d7 01 00 00       	call   801054e9 <release>
      return 0;
80105312:	b8 00 00 00 00       	mov    $0x0,%eax
80105317:	eb 1e                	jmp    80105337 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105319:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010531d:	81 7d f4 f4 60 11 80 	cmpl   $0x801160f4,-0xc(%ebp)
80105324:	72 b6                	jb     801052dc <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105326:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010532d:	e8 b7 01 00 00       	call   801054e9 <release>
  return -1;
80105332:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105337:	c9                   	leave  
80105338:	c3                   	ret    

80105339 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105339:	55                   	push   %ebp
8010533a:	89 e5                	mov    %esp,%ebp
8010533c:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010533f:	c7 45 f0 f4 41 11 80 	movl   $0x801141f4,-0x10(%ebp)
80105346:	e9 d6 00 00 00       	jmp    80105421 <procdump+0xe8>
    if(p->state == UNUSED)
8010534b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010534e:	8b 40 0c             	mov    0xc(%eax),%eax
80105351:	85 c0                	test   %eax,%eax
80105353:	75 05                	jne    8010535a <procdump+0x21>
      continue;
80105355:	e9 c3 00 00 00       	jmp    8010541d <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
8010535a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010535d:	8b 40 0c             	mov    0xc(%eax),%eax
80105360:	83 f8 05             	cmp    $0x5,%eax
80105363:	77 23                	ja     80105388 <procdump+0x4f>
80105365:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105368:	8b 40 0c             	mov    0xc(%eax),%eax
8010536b:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80105372:	85 c0                	test   %eax,%eax
80105374:	74 12                	je     80105388 <procdump+0x4f>
      state = states[p->state];
80105376:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105379:	8b 40 0c             	mov    0xc(%eax),%eax
8010537c:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80105383:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105386:	eb 07                	jmp    8010538f <procdump+0x56>
    else
      state = "???";
80105388:	c7 45 ec 34 8e 10 80 	movl   $0x80108e34,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
8010538f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105392:	8d 50 6c             	lea    0x6c(%eax),%edx
80105395:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105398:	8b 40 10             	mov    0x10(%eax),%eax
8010539b:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010539f:	8b 55 ec             	mov    -0x14(%ebp),%edx
801053a2:	89 54 24 08          	mov    %edx,0x8(%esp)
801053a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801053aa:	c7 04 24 38 8e 10 80 	movl   $0x80108e38,(%esp)
801053b1:	e8 ea af ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
801053b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801053b9:	8b 40 0c             	mov    0xc(%eax),%eax
801053bc:	83 f8 02             	cmp    $0x2,%eax
801053bf:	75 50                	jne    80105411 <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801053c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801053c4:	8b 40 1c             	mov    0x1c(%eax),%eax
801053c7:	8b 40 0c             	mov    0xc(%eax),%eax
801053ca:	83 c0 08             	add    $0x8,%eax
801053cd:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801053d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801053d4:	89 04 24             	mov    %eax,(%esp)
801053d7:	e8 5c 01 00 00       	call   80105538 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801053dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801053e3:	eb 1b                	jmp    80105400 <procdump+0xc7>
        cprintf(" %p", pc[i]);
801053e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053e8:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801053ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801053f0:	c7 04 24 41 8e 10 80 	movl   $0x80108e41,(%esp)
801053f7:	e8 a4 af ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801053fc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105400:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105404:	7f 0b                	jg     80105411 <procdump+0xd8>
80105406:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105409:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
8010540d:	85 c0                	test   %eax,%eax
8010540f:	75 d4                	jne    801053e5 <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105411:	c7 04 24 45 8e 10 80 	movl   $0x80108e45,(%esp)
80105418:	e8 83 af ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010541d:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80105421:	81 7d f0 f4 60 11 80 	cmpl   $0x801160f4,-0x10(%ebp)
80105428:	0f 82 1d ff ff ff    	jb     8010534b <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
8010542e:	c9                   	leave  
8010542f:	c3                   	ret    

80105430 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105430:	55                   	push   %ebp
80105431:	89 e5                	mov    %esp,%ebp
80105433:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105436:	9c                   	pushf  
80105437:	58                   	pop    %eax
80105438:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
8010543b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010543e:	c9                   	leave  
8010543f:	c3                   	ret    

80105440 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105440:	55                   	push   %ebp
80105441:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105443:	fa                   	cli    
}
80105444:	5d                   	pop    %ebp
80105445:	c3                   	ret    

80105446 <sti>:

static inline void
sti(void)
{
80105446:	55                   	push   %ebp
80105447:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105449:	fb                   	sti    
}
8010544a:	5d                   	pop    %ebp
8010544b:	c3                   	ret    

8010544c <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010544c:	55                   	push   %ebp
8010544d:	89 e5                	mov    %esp,%ebp
8010544f:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105452:	8b 55 08             	mov    0x8(%ebp),%edx
80105455:	8b 45 0c             	mov    0xc(%ebp),%eax
80105458:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010545b:	f0 87 02             	lock xchg %eax,(%edx)
8010545e:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105461:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105464:	c9                   	leave  
80105465:	c3                   	ret    

80105466 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105466:	55                   	push   %ebp
80105467:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105469:	8b 45 08             	mov    0x8(%ebp),%eax
8010546c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010546f:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105472:	8b 45 08             	mov    0x8(%ebp),%eax
80105475:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
8010547b:	8b 45 08             	mov    0x8(%ebp),%eax
8010547e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105485:	5d                   	pop    %ebp
80105486:	c3                   	ret    

80105487 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105487:	55                   	push   %ebp
80105488:	89 e5                	mov    %esp,%ebp
8010548a:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
8010548d:	e8 49 01 00 00       	call   801055db <pushcli>
  if(holding(lk))
80105492:	8b 45 08             	mov    0x8(%ebp),%eax
80105495:	89 04 24             	mov    %eax,(%esp)
80105498:	e8 14 01 00 00       	call   801055b1 <holding>
8010549d:	85 c0                	test   %eax,%eax
8010549f:	74 0c                	je     801054ad <acquire+0x26>
    panic("acquire");
801054a1:	c7 04 24 71 8e 10 80 	movl   $0x80108e71,(%esp)
801054a8:	e8 8d b0 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
801054ad:	90                   	nop
801054ae:	8b 45 08             	mov    0x8(%ebp),%eax
801054b1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801054b8:	00 
801054b9:	89 04 24             	mov    %eax,(%esp)
801054bc:	e8 8b ff ff ff       	call   8010544c <xchg>
801054c1:	85 c0                	test   %eax,%eax
801054c3:	75 e9                	jne    801054ae <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801054c5:	8b 45 08             	mov    0x8(%ebp),%eax
801054c8:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801054cf:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
801054d2:	8b 45 08             	mov    0x8(%ebp),%eax
801054d5:	83 c0 0c             	add    $0xc,%eax
801054d8:	89 44 24 04          	mov    %eax,0x4(%esp)
801054dc:	8d 45 08             	lea    0x8(%ebp),%eax
801054df:	89 04 24             	mov    %eax,(%esp)
801054e2:	e8 51 00 00 00       	call   80105538 <getcallerpcs>
}
801054e7:	c9                   	leave  
801054e8:	c3                   	ret    

801054e9 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
801054e9:	55                   	push   %ebp
801054ea:	89 e5                	mov    %esp,%ebp
801054ec:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801054ef:	8b 45 08             	mov    0x8(%ebp),%eax
801054f2:	89 04 24             	mov    %eax,(%esp)
801054f5:	e8 b7 00 00 00       	call   801055b1 <holding>
801054fa:	85 c0                	test   %eax,%eax
801054fc:	75 0c                	jne    8010550a <release+0x21>
    panic("release");
801054fe:	c7 04 24 79 8e 10 80 	movl   $0x80108e79,(%esp)
80105505:	e8 30 b0 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
8010550a:	8b 45 08             	mov    0x8(%ebp),%eax
8010550d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105514:	8b 45 08             	mov    0x8(%ebp),%eax
80105517:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
8010551e:	8b 45 08             	mov    0x8(%ebp),%eax
80105521:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105528:	00 
80105529:	89 04 24             	mov    %eax,(%esp)
8010552c:	e8 1b ff ff ff       	call   8010544c <xchg>

  popcli();
80105531:	e8 e9 00 00 00       	call   8010561f <popcli>
}
80105536:	c9                   	leave  
80105537:	c3                   	ret    

80105538 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105538:	55                   	push   %ebp
80105539:	89 e5                	mov    %esp,%ebp
8010553b:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
8010553e:	8b 45 08             	mov    0x8(%ebp),%eax
80105541:	83 e8 08             	sub    $0x8,%eax
80105544:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105547:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010554e:	eb 38                	jmp    80105588 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105550:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105554:	74 38                	je     8010558e <getcallerpcs+0x56>
80105556:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010555d:	76 2f                	jbe    8010558e <getcallerpcs+0x56>
8010555f:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105563:	74 29                	je     8010558e <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105565:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105568:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010556f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105572:	01 c2                	add    %eax,%edx
80105574:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105577:	8b 40 04             	mov    0x4(%eax),%eax
8010557a:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
8010557c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010557f:	8b 00                	mov    (%eax),%eax
80105581:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105584:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105588:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010558c:	7e c2                	jle    80105550 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010558e:	eb 19                	jmp    801055a9 <getcallerpcs+0x71>
    pcs[i] = 0;
80105590:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105593:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010559a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010559d:	01 d0                	add    %edx,%eax
8010559f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801055a5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801055a9:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801055ad:	7e e1                	jle    80105590 <getcallerpcs+0x58>
    pcs[i] = 0;
}
801055af:	c9                   	leave  
801055b0:	c3                   	ret    

801055b1 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801055b1:	55                   	push   %ebp
801055b2:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
801055b4:	8b 45 08             	mov    0x8(%ebp),%eax
801055b7:	8b 00                	mov    (%eax),%eax
801055b9:	85 c0                	test   %eax,%eax
801055bb:	74 17                	je     801055d4 <holding+0x23>
801055bd:	8b 45 08             	mov    0x8(%ebp),%eax
801055c0:	8b 50 08             	mov    0x8(%eax),%edx
801055c3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801055c9:	39 c2                	cmp    %eax,%edx
801055cb:	75 07                	jne    801055d4 <holding+0x23>
801055cd:	b8 01 00 00 00       	mov    $0x1,%eax
801055d2:	eb 05                	jmp    801055d9 <holding+0x28>
801055d4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055d9:	5d                   	pop    %ebp
801055da:	c3                   	ret    

801055db <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801055db:	55                   	push   %ebp
801055dc:	89 e5                	mov    %esp,%ebp
801055de:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
801055e1:	e8 4a fe ff ff       	call   80105430 <readeflags>
801055e6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
801055e9:	e8 52 fe ff ff       	call   80105440 <cli>
  if(cpu->ncli++ == 0)
801055ee:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801055f5:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
801055fb:	8d 48 01             	lea    0x1(%eax),%ecx
801055fe:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105604:	85 c0                	test   %eax,%eax
80105606:	75 15                	jne    8010561d <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105608:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010560e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105611:	81 e2 00 02 00 00    	and    $0x200,%edx
80105617:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010561d:	c9                   	leave  
8010561e:	c3                   	ret    

8010561f <popcli>:

void
popcli(void)
{
8010561f:	55                   	push   %ebp
80105620:	89 e5                	mov    %esp,%ebp
80105622:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105625:	e8 06 fe ff ff       	call   80105430 <readeflags>
8010562a:	25 00 02 00 00       	and    $0x200,%eax
8010562f:	85 c0                	test   %eax,%eax
80105631:	74 0c                	je     8010563f <popcli+0x20>
    panic("popcli - interruptible");
80105633:	c7 04 24 81 8e 10 80 	movl   $0x80108e81,(%esp)
8010563a:	e8 fb ae ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
8010563f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105645:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
8010564b:	83 ea 01             	sub    $0x1,%edx
8010564e:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105654:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010565a:	85 c0                	test   %eax,%eax
8010565c:	79 0c                	jns    8010566a <popcli+0x4b>
    panic("popcli");
8010565e:	c7 04 24 98 8e 10 80 	movl   $0x80108e98,(%esp)
80105665:	e8 d0 ae ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
8010566a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105670:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105676:	85 c0                	test   %eax,%eax
80105678:	75 15                	jne    8010568f <popcli+0x70>
8010567a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105680:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105686:	85 c0                	test   %eax,%eax
80105688:	74 05                	je     8010568f <popcli+0x70>
    sti();
8010568a:	e8 b7 fd ff ff       	call   80105446 <sti>
}
8010568f:	c9                   	leave  
80105690:	c3                   	ret    

80105691 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105691:	55                   	push   %ebp
80105692:	89 e5                	mov    %esp,%ebp
80105694:	57                   	push   %edi
80105695:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105696:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105699:	8b 55 10             	mov    0x10(%ebp),%edx
8010569c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010569f:	89 cb                	mov    %ecx,%ebx
801056a1:	89 df                	mov    %ebx,%edi
801056a3:	89 d1                	mov    %edx,%ecx
801056a5:	fc                   	cld    
801056a6:	f3 aa                	rep stos %al,%es:(%edi)
801056a8:	89 ca                	mov    %ecx,%edx
801056aa:	89 fb                	mov    %edi,%ebx
801056ac:	89 5d 08             	mov    %ebx,0x8(%ebp)
801056af:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801056b2:	5b                   	pop    %ebx
801056b3:	5f                   	pop    %edi
801056b4:	5d                   	pop    %ebp
801056b5:	c3                   	ret    

801056b6 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801056b6:	55                   	push   %ebp
801056b7:	89 e5                	mov    %esp,%ebp
801056b9:	57                   	push   %edi
801056ba:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801056bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
801056be:	8b 55 10             	mov    0x10(%ebp),%edx
801056c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801056c4:	89 cb                	mov    %ecx,%ebx
801056c6:	89 df                	mov    %ebx,%edi
801056c8:	89 d1                	mov    %edx,%ecx
801056ca:	fc                   	cld    
801056cb:	f3 ab                	rep stos %eax,%es:(%edi)
801056cd:	89 ca                	mov    %ecx,%edx
801056cf:	89 fb                	mov    %edi,%ebx
801056d1:	89 5d 08             	mov    %ebx,0x8(%ebp)
801056d4:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801056d7:	5b                   	pop    %ebx
801056d8:	5f                   	pop    %edi
801056d9:	5d                   	pop    %ebp
801056da:	c3                   	ret    

801056db <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801056db:	55                   	push   %ebp
801056dc:	89 e5                	mov    %esp,%ebp
801056de:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801056e1:	8b 45 08             	mov    0x8(%ebp),%eax
801056e4:	83 e0 03             	and    $0x3,%eax
801056e7:	85 c0                	test   %eax,%eax
801056e9:	75 49                	jne    80105734 <memset+0x59>
801056eb:	8b 45 10             	mov    0x10(%ebp),%eax
801056ee:	83 e0 03             	and    $0x3,%eax
801056f1:	85 c0                	test   %eax,%eax
801056f3:	75 3f                	jne    80105734 <memset+0x59>
    c &= 0xFF;
801056f5:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801056fc:	8b 45 10             	mov    0x10(%ebp),%eax
801056ff:	c1 e8 02             	shr    $0x2,%eax
80105702:	89 c2                	mov    %eax,%edx
80105704:	8b 45 0c             	mov    0xc(%ebp),%eax
80105707:	c1 e0 18             	shl    $0x18,%eax
8010570a:	89 c1                	mov    %eax,%ecx
8010570c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010570f:	c1 e0 10             	shl    $0x10,%eax
80105712:	09 c1                	or     %eax,%ecx
80105714:	8b 45 0c             	mov    0xc(%ebp),%eax
80105717:	c1 e0 08             	shl    $0x8,%eax
8010571a:	09 c8                	or     %ecx,%eax
8010571c:	0b 45 0c             	or     0xc(%ebp),%eax
8010571f:	89 54 24 08          	mov    %edx,0x8(%esp)
80105723:	89 44 24 04          	mov    %eax,0x4(%esp)
80105727:	8b 45 08             	mov    0x8(%ebp),%eax
8010572a:	89 04 24             	mov    %eax,(%esp)
8010572d:	e8 84 ff ff ff       	call   801056b6 <stosl>
80105732:	eb 19                	jmp    8010574d <memset+0x72>
  } else
    stosb(dst, c, n);
80105734:	8b 45 10             	mov    0x10(%ebp),%eax
80105737:	89 44 24 08          	mov    %eax,0x8(%esp)
8010573b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010573e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105742:	8b 45 08             	mov    0x8(%ebp),%eax
80105745:	89 04 24             	mov    %eax,(%esp)
80105748:	e8 44 ff ff ff       	call   80105691 <stosb>
  return dst;
8010574d:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105750:	c9                   	leave  
80105751:	c3                   	ret    

80105752 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105752:	55                   	push   %ebp
80105753:	89 e5                	mov    %esp,%ebp
80105755:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105758:	8b 45 08             	mov    0x8(%ebp),%eax
8010575b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
8010575e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105761:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105764:	eb 30                	jmp    80105796 <memcmp+0x44>
    if(*s1 != *s2)
80105766:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105769:	0f b6 10             	movzbl (%eax),%edx
8010576c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010576f:	0f b6 00             	movzbl (%eax),%eax
80105772:	38 c2                	cmp    %al,%dl
80105774:	74 18                	je     8010578e <memcmp+0x3c>
      return *s1 - *s2;
80105776:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105779:	0f b6 00             	movzbl (%eax),%eax
8010577c:	0f b6 d0             	movzbl %al,%edx
8010577f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105782:	0f b6 00             	movzbl (%eax),%eax
80105785:	0f b6 c0             	movzbl %al,%eax
80105788:	29 c2                	sub    %eax,%edx
8010578a:	89 d0                	mov    %edx,%eax
8010578c:	eb 1a                	jmp    801057a8 <memcmp+0x56>
    s1++, s2++;
8010578e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105792:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105796:	8b 45 10             	mov    0x10(%ebp),%eax
80105799:	8d 50 ff             	lea    -0x1(%eax),%edx
8010579c:	89 55 10             	mov    %edx,0x10(%ebp)
8010579f:	85 c0                	test   %eax,%eax
801057a1:	75 c3                	jne    80105766 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
801057a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801057a8:	c9                   	leave  
801057a9:	c3                   	ret    

801057aa <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801057aa:	55                   	push   %ebp
801057ab:	89 e5                	mov    %esp,%ebp
801057ad:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
801057b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801057b3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
801057b6:	8b 45 08             	mov    0x8(%ebp),%eax
801057b9:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
801057bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
801057bf:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801057c2:	73 3d                	jae    80105801 <memmove+0x57>
801057c4:	8b 45 10             	mov    0x10(%ebp),%eax
801057c7:	8b 55 fc             	mov    -0x4(%ebp),%edx
801057ca:	01 d0                	add    %edx,%eax
801057cc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801057cf:	76 30                	jbe    80105801 <memmove+0x57>
    s += n;
801057d1:	8b 45 10             	mov    0x10(%ebp),%eax
801057d4:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801057d7:	8b 45 10             	mov    0x10(%ebp),%eax
801057da:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801057dd:	eb 13                	jmp    801057f2 <memmove+0x48>
      *--d = *--s;
801057df:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801057e3:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801057e7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801057ea:	0f b6 10             	movzbl (%eax),%edx
801057ed:	8b 45 f8             	mov    -0x8(%ebp),%eax
801057f0:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
801057f2:	8b 45 10             	mov    0x10(%ebp),%eax
801057f5:	8d 50 ff             	lea    -0x1(%eax),%edx
801057f8:	89 55 10             	mov    %edx,0x10(%ebp)
801057fb:	85 c0                	test   %eax,%eax
801057fd:	75 e0                	jne    801057df <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801057ff:	eb 26                	jmp    80105827 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105801:	eb 17                	jmp    8010581a <memmove+0x70>
      *d++ = *s++;
80105803:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105806:	8d 50 01             	lea    0x1(%eax),%edx
80105809:	89 55 f8             	mov    %edx,-0x8(%ebp)
8010580c:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010580f:	8d 4a 01             	lea    0x1(%edx),%ecx
80105812:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105815:	0f b6 12             	movzbl (%edx),%edx
80105818:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010581a:	8b 45 10             	mov    0x10(%ebp),%eax
8010581d:	8d 50 ff             	lea    -0x1(%eax),%edx
80105820:	89 55 10             	mov    %edx,0x10(%ebp)
80105823:	85 c0                	test   %eax,%eax
80105825:	75 dc                	jne    80105803 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105827:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010582a:	c9                   	leave  
8010582b:	c3                   	ret    

8010582c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
8010582c:	55                   	push   %ebp
8010582d:	89 e5                	mov    %esp,%ebp
8010582f:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105832:	8b 45 10             	mov    0x10(%ebp),%eax
80105835:	89 44 24 08          	mov    %eax,0x8(%esp)
80105839:	8b 45 0c             	mov    0xc(%ebp),%eax
8010583c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105840:	8b 45 08             	mov    0x8(%ebp),%eax
80105843:	89 04 24             	mov    %eax,(%esp)
80105846:	e8 5f ff ff ff       	call   801057aa <memmove>
}
8010584b:	c9                   	leave  
8010584c:	c3                   	ret    

8010584d <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010584d:	55                   	push   %ebp
8010584e:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105850:	eb 0c                	jmp    8010585e <strncmp+0x11>
    n--, p++, q++;
80105852:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105856:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010585a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
8010585e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105862:	74 1a                	je     8010587e <strncmp+0x31>
80105864:	8b 45 08             	mov    0x8(%ebp),%eax
80105867:	0f b6 00             	movzbl (%eax),%eax
8010586a:	84 c0                	test   %al,%al
8010586c:	74 10                	je     8010587e <strncmp+0x31>
8010586e:	8b 45 08             	mov    0x8(%ebp),%eax
80105871:	0f b6 10             	movzbl (%eax),%edx
80105874:	8b 45 0c             	mov    0xc(%ebp),%eax
80105877:	0f b6 00             	movzbl (%eax),%eax
8010587a:	38 c2                	cmp    %al,%dl
8010587c:	74 d4                	je     80105852 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
8010587e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105882:	75 07                	jne    8010588b <strncmp+0x3e>
    return 0;
80105884:	b8 00 00 00 00       	mov    $0x0,%eax
80105889:	eb 16                	jmp    801058a1 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
8010588b:	8b 45 08             	mov    0x8(%ebp),%eax
8010588e:	0f b6 00             	movzbl (%eax),%eax
80105891:	0f b6 d0             	movzbl %al,%edx
80105894:	8b 45 0c             	mov    0xc(%ebp),%eax
80105897:	0f b6 00             	movzbl (%eax),%eax
8010589a:	0f b6 c0             	movzbl %al,%eax
8010589d:	29 c2                	sub    %eax,%edx
8010589f:	89 d0                	mov    %edx,%eax
}
801058a1:	5d                   	pop    %ebp
801058a2:	c3                   	ret    

801058a3 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801058a3:	55                   	push   %ebp
801058a4:	89 e5                	mov    %esp,%ebp
801058a6:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801058a9:	8b 45 08             	mov    0x8(%ebp),%eax
801058ac:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801058af:	90                   	nop
801058b0:	8b 45 10             	mov    0x10(%ebp),%eax
801058b3:	8d 50 ff             	lea    -0x1(%eax),%edx
801058b6:	89 55 10             	mov    %edx,0x10(%ebp)
801058b9:	85 c0                	test   %eax,%eax
801058bb:	7e 1e                	jle    801058db <strncpy+0x38>
801058bd:	8b 45 08             	mov    0x8(%ebp),%eax
801058c0:	8d 50 01             	lea    0x1(%eax),%edx
801058c3:	89 55 08             	mov    %edx,0x8(%ebp)
801058c6:	8b 55 0c             	mov    0xc(%ebp),%edx
801058c9:	8d 4a 01             	lea    0x1(%edx),%ecx
801058cc:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801058cf:	0f b6 12             	movzbl (%edx),%edx
801058d2:	88 10                	mov    %dl,(%eax)
801058d4:	0f b6 00             	movzbl (%eax),%eax
801058d7:	84 c0                	test   %al,%al
801058d9:	75 d5                	jne    801058b0 <strncpy+0xd>
    ;
  while(n-- > 0)
801058db:	eb 0c                	jmp    801058e9 <strncpy+0x46>
    *s++ = 0;
801058dd:	8b 45 08             	mov    0x8(%ebp),%eax
801058e0:	8d 50 01             	lea    0x1(%eax),%edx
801058e3:	89 55 08             	mov    %edx,0x8(%ebp)
801058e6:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801058e9:	8b 45 10             	mov    0x10(%ebp),%eax
801058ec:	8d 50 ff             	lea    -0x1(%eax),%edx
801058ef:	89 55 10             	mov    %edx,0x10(%ebp)
801058f2:	85 c0                	test   %eax,%eax
801058f4:	7f e7                	jg     801058dd <strncpy+0x3a>
    *s++ = 0;
  return os;
801058f6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801058f9:	c9                   	leave  
801058fa:	c3                   	ret    

801058fb <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801058fb:	55                   	push   %ebp
801058fc:	89 e5                	mov    %esp,%ebp
801058fe:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105901:	8b 45 08             	mov    0x8(%ebp),%eax
80105904:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105907:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010590b:	7f 05                	jg     80105912 <safestrcpy+0x17>
    return os;
8010590d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105910:	eb 31                	jmp    80105943 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105912:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105916:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010591a:	7e 1e                	jle    8010593a <safestrcpy+0x3f>
8010591c:	8b 45 08             	mov    0x8(%ebp),%eax
8010591f:	8d 50 01             	lea    0x1(%eax),%edx
80105922:	89 55 08             	mov    %edx,0x8(%ebp)
80105925:	8b 55 0c             	mov    0xc(%ebp),%edx
80105928:	8d 4a 01             	lea    0x1(%edx),%ecx
8010592b:	89 4d 0c             	mov    %ecx,0xc(%ebp)
8010592e:	0f b6 12             	movzbl (%edx),%edx
80105931:	88 10                	mov    %dl,(%eax)
80105933:	0f b6 00             	movzbl (%eax),%eax
80105936:	84 c0                	test   %al,%al
80105938:	75 d8                	jne    80105912 <safestrcpy+0x17>
    ;
  *s = 0;
8010593a:	8b 45 08             	mov    0x8(%ebp),%eax
8010593d:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105940:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105943:	c9                   	leave  
80105944:	c3                   	ret    

80105945 <strlen>:

int
strlen(const char *s)
{
80105945:	55                   	push   %ebp
80105946:	89 e5                	mov    %esp,%ebp
80105948:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010594b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105952:	eb 04                	jmp    80105958 <strlen+0x13>
80105954:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105958:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010595b:	8b 45 08             	mov    0x8(%ebp),%eax
8010595e:	01 d0                	add    %edx,%eax
80105960:	0f b6 00             	movzbl (%eax),%eax
80105963:	84 c0                	test   %al,%al
80105965:	75 ed                	jne    80105954 <strlen+0xf>
    ;
  return n;
80105967:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010596a:	c9                   	leave  
8010596b:	c3                   	ret    

8010596c <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
8010596c:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105970:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105974:	55                   	push   %ebp
  pushl %ebx
80105975:	53                   	push   %ebx
  pushl %esi
80105976:	56                   	push   %esi
  pushl %edi
80105977:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105978:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010597a:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010597c:	5f                   	pop    %edi
  popl %esi
8010597d:	5e                   	pop    %esi
  popl %ebx
8010597e:	5b                   	pop    %ebx
  popl %ebp
8010597f:	5d                   	pop    %ebp
  ret
80105980:	c3                   	ret    

80105981 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105981:	55                   	push   %ebp
80105982:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105984:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010598a:	8b 00                	mov    (%eax),%eax
8010598c:	3b 45 08             	cmp    0x8(%ebp),%eax
8010598f:	76 12                	jbe    801059a3 <fetchint+0x22>
80105991:	8b 45 08             	mov    0x8(%ebp),%eax
80105994:	8d 50 04             	lea    0x4(%eax),%edx
80105997:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010599d:	8b 00                	mov    (%eax),%eax
8010599f:	39 c2                	cmp    %eax,%edx
801059a1:	76 07                	jbe    801059aa <fetchint+0x29>
    return -1;
801059a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059a8:	eb 0f                	jmp    801059b9 <fetchint+0x38>
  *ip = *(int*)(addr);
801059aa:	8b 45 08             	mov    0x8(%ebp),%eax
801059ad:	8b 10                	mov    (%eax),%edx
801059af:	8b 45 0c             	mov    0xc(%ebp),%eax
801059b2:	89 10                	mov    %edx,(%eax)
  return 0;
801059b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801059b9:	5d                   	pop    %ebp
801059ba:	c3                   	ret    

801059bb <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801059bb:	55                   	push   %ebp
801059bc:	89 e5                	mov    %esp,%ebp
801059be:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
801059c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059c7:	8b 00                	mov    (%eax),%eax
801059c9:	3b 45 08             	cmp    0x8(%ebp),%eax
801059cc:	77 07                	ja     801059d5 <fetchstr+0x1a>
    return -1;
801059ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059d3:	eb 46                	jmp    80105a1b <fetchstr+0x60>
  *pp = (char*)addr;
801059d5:	8b 55 08             	mov    0x8(%ebp),%edx
801059d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801059db:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
801059dd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059e3:	8b 00                	mov    (%eax),%eax
801059e5:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
801059e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801059eb:	8b 00                	mov    (%eax),%eax
801059ed:	89 45 fc             	mov    %eax,-0x4(%ebp)
801059f0:	eb 1c                	jmp    80105a0e <fetchstr+0x53>
    if(*s == 0)
801059f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059f5:	0f b6 00             	movzbl (%eax),%eax
801059f8:	84 c0                	test   %al,%al
801059fa:	75 0e                	jne    80105a0a <fetchstr+0x4f>
      return s - *pp;
801059fc:	8b 55 fc             	mov    -0x4(%ebp),%edx
801059ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a02:	8b 00                	mov    (%eax),%eax
80105a04:	29 c2                	sub    %eax,%edx
80105a06:	89 d0                	mov    %edx,%eax
80105a08:	eb 11                	jmp    80105a1b <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105a0a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105a0e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a11:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105a14:	72 dc                	jb     801059f2 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105a16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a1b:	c9                   	leave  
80105a1c:	c3                   	ret    

80105a1d <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105a1d:	55                   	push   %ebp
80105a1e:	89 e5                	mov    %esp,%ebp
80105a20:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105a23:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a29:	8b 40 18             	mov    0x18(%eax),%eax
80105a2c:	8b 50 44             	mov    0x44(%eax),%edx
80105a2f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a32:	c1 e0 02             	shl    $0x2,%eax
80105a35:	01 d0                	add    %edx,%eax
80105a37:	8d 50 04             	lea    0x4(%eax),%edx
80105a3a:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a3d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a41:	89 14 24             	mov    %edx,(%esp)
80105a44:	e8 38 ff ff ff       	call   80105981 <fetchint>
}
80105a49:	c9                   	leave  
80105a4a:	c3                   	ret    

80105a4b <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105a4b:	55                   	push   %ebp
80105a4c:	89 e5                	mov    %esp,%ebp
80105a4e:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105a51:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105a54:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a58:	8b 45 08             	mov    0x8(%ebp),%eax
80105a5b:	89 04 24             	mov    %eax,(%esp)
80105a5e:	e8 ba ff ff ff       	call   80105a1d <argint>
80105a63:	85 c0                	test   %eax,%eax
80105a65:	79 07                	jns    80105a6e <argptr+0x23>
    return -1;
80105a67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a6c:	eb 3d                	jmp    80105aab <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105a6e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a71:	89 c2                	mov    %eax,%edx
80105a73:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a79:	8b 00                	mov    (%eax),%eax
80105a7b:	39 c2                	cmp    %eax,%edx
80105a7d:	73 16                	jae    80105a95 <argptr+0x4a>
80105a7f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a82:	89 c2                	mov    %eax,%edx
80105a84:	8b 45 10             	mov    0x10(%ebp),%eax
80105a87:	01 c2                	add    %eax,%edx
80105a89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a8f:	8b 00                	mov    (%eax),%eax
80105a91:	39 c2                	cmp    %eax,%edx
80105a93:	76 07                	jbe    80105a9c <argptr+0x51>
    return -1;
80105a95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a9a:	eb 0f                	jmp    80105aab <argptr+0x60>
  *pp = (char*)i;
80105a9c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a9f:	89 c2                	mov    %eax,%edx
80105aa1:	8b 45 0c             	mov    0xc(%ebp),%eax
80105aa4:	89 10                	mov    %edx,(%eax)
  return 0;
80105aa6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105aab:	c9                   	leave  
80105aac:	c3                   	ret    

80105aad <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105aad:	55                   	push   %ebp
80105aae:	89 e5                	mov    %esp,%ebp
80105ab0:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105ab3:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105ab6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105aba:	8b 45 08             	mov    0x8(%ebp),%eax
80105abd:	89 04 24             	mov    %eax,(%esp)
80105ac0:	e8 58 ff ff ff       	call   80105a1d <argint>
80105ac5:	85 c0                	test   %eax,%eax
80105ac7:	79 07                	jns    80105ad0 <argstr+0x23>
    return -1;
80105ac9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ace:	eb 12                	jmp    80105ae2 <argstr+0x35>
  return fetchstr(addr, pp);
80105ad0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ad3:	8b 55 0c             	mov    0xc(%ebp),%edx
80105ad6:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ada:	89 04 24             	mov    %eax,(%esp)
80105add:	e8 d9 fe ff ff       	call   801059bb <fetchstr>
}
80105ae2:	c9                   	leave  
80105ae3:	c3                   	ret    

80105ae4 <syscall>:
[SYS_history] sys_history,
};

void
syscall(void)
{
80105ae4:	55                   	push   %ebp
80105ae5:	89 e5                	mov    %esp,%ebp
80105ae7:	53                   	push   %ebx
80105ae8:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105aeb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105af1:	8b 40 18             	mov    0x18(%eax),%eax
80105af4:	8b 40 1c             	mov    0x1c(%eax),%eax
80105af7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105afa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105afe:	7e 30                	jle    80105b30 <syscall+0x4c>
80105b00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b03:	83 f8 16             	cmp    $0x16,%eax
80105b06:	77 28                	ja     80105b30 <syscall+0x4c>
80105b08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b0b:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105b12:	85 c0                	test   %eax,%eax
80105b14:	74 1a                	je     80105b30 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105b16:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b1c:	8b 58 18             	mov    0x18(%eax),%ebx
80105b1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b22:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105b29:	ff d0                	call   *%eax
80105b2b:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105b2e:	eb 3d                	jmp    80105b6d <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105b30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b36:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105b39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105b3f:	8b 40 10             	mov    0x10(%eax),%eax
80105b42:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105b45:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105b49:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105b4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b51:	c7 04 24 9f 8e 10 80 	movl   $0x80108e9f,(%esp)
80105b58:	e8 43 a8 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105b5d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b63:	8b 40 18             	mov    0x18(%eax),%eax
80105b66:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105b6d:	83 c4 24             	add    $0x24,%esp
80105b70:	5b                   	pop    %ebx
80105b71:	5d                   	pop    %ebp
80105b72:	c3                   	ret    

80105b73 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105b73:	55                   	push   %ebp
80105b74:	89 e5                	mov    %esp,%ebp
80105b76:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105b79:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105b7c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b80:	8b 45 08             	mov    0x8(%ebp),%eax
80105b83:	89 04 24             	mov    %eax,(%esp)
80105b86:	e8 92 fe ff ff       	call   80105a1d <argint>
80105b8b:	85 c0                	test   %eax,%eax
80105b8d:	79 07                	jns    80105b96 <argfd+0x23>
    return -1;
80105b8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b94:	eb 50                	jmp    80105be6 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105b96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b99:	85 c0                	test   %eax,%eax
80105b9b:	78 21                	js     80105bbe <argfd+0x4b>
80105b9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ba0:	83 f8 0f             	cmp    $0xf,%eax
80105ba3:	7f 19                	jg     80105bbe <argfd+0x4b>
80105ba5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bab:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105bae:	83 c2 08             	add    $0x8,%edx
80105bb1:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105bb5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105bb8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105bbc:	75 07                	jne    80105bc5 <argfd+0x52>
    return -1;
80105bbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105bc3:	eb 21                	jmp    80105be6 <argfd+0x73>
  if(pfd)
80105bc5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105bc9:	74 08                	je     80105bd3 <argfd+0x60>
    *pfd = fd;
80105bcb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105bce:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bd1:	89 10                	mov    %edx,(%eax)
  if(pf)
80105bd3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bd7:	74 08                	je     80105be1 <argfd+0x6e>
    *pf = f;
80105bd9:	8b 45 10             	mov    0x10(%ebp),%eax
80105bdc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105bdf:	89 10                	mov    %edx,(%eax)
  return 0;
80105be1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105be6:	c9                   	leave  
80105be7:	c3                   	ret    

80105be8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105be8:	55                   	push   %ebp
80105be9:	89 e5                	mov    %esp,%ebp
80105beb:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105bee:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105bf5:	eb 30                	jmp    80105c27 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105bf7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bfd:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c00:	83 c2 08             	add    $0x8,%edx
80105c03:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105c07:	85 c0                	test   %eax,%eax
80105c09:	75 18                	jne    80105c23 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105c0b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c11:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c14:	8d 4a 08             	lea    0x8(%edx),%ecx
80105c17:	8b 55 08             	mov    0x8(%ebp),%edx
80105c1a:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105c1e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c21:	eb 0f                	jmp    80105c32 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105c23:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c27:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105c2b:	7e ca                	jle    80105bf7 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105c2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105c32:	c9                   	leave  
80105c33:	c3                   	ret    

80105c34 <sys_dup>:

int
sys_dup(void)
{
80105c34:	55                   	push   %ebp
80105c35:	89 e5                	mov    %esp,%ebp
80105c37:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105c3a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105c3d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c41:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105c48:	00 
80105c49:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105c50:	e8 1e ff ff ff       	call   80105b73 <argfd>
80105c55:	85 c0                	test   %eax,%eax
80105c57:	79 07                	jns    80105c60 <sys_dup+0x2c>
    return -1;
80105c59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c5e:	eb 29                	jmp    80105c89 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105c60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c63:	89 04 24             	mov    %eax,(%esp)
80105c66:	e8 7d ff ff ff       	call   80105be8 <fdalloc>
80105c6b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105c6e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c72:	79 07                	jns    80105c7b <sys_dup+0x47>
    return -1;
80105c74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c79:	eb 0e                	jmp    80105c89 <sys_dup+0x55>
  filedup(f);
80105c7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c7e:	89 04 24             	mov    %eax,(%esp)
80105c81:	e8 fe b8 ff ff       	call   80101584 <filedup>
  return fd;
80105c86:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105c89:	c9                   	leave  
80105c8a:	c3                   	ret    

80105c8b <sys_read>:

int
sys_read(void)
{
80105c8b:	55                   	push   %ebp
80105c8c:	89 e5                	mov    %esp,%ebp
80105c8e:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105c91:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105c94:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c98:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105c9f:	00 
80105ca0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ca7:	e8 c7 fe ff ff       	call   80105b73 <argfd>
80105cac:	85 c0                	test   %eax,%eax
80105cae:	78 35                	js     80105ce5 <sys_read+0x5a>
80105cb0:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105cb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cb7:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105cbe:	e8 5a fd ff ff       	call   80105a1d <argint>
80105cc3:	85 c0                	test   %eax,%eax
80105cc5:	78 1e                	js     80105ce5 <sys_read+0x5a>
80105cc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cca:	89 44 24 08          	mov    %eax,0x8(%esp)
80105cce:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105cd1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cd5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105cdc:	e8 6a fd ff ff       	call   80105a4b <argptr>
80105ce1:	85 c0                	test   %eax,%eax
80105ce3:	79 07                	jns    80105cec <sys_read+0x61>
    return -1;
80105ce5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cea:	eb 19                	jmp    80105d05 <sys_read+0x7a>
  return fileread(f, p, n);
80105cec:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105cef:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cf5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105cf9:	89 54 24 04          	mov    %edx,0x4(%esp)
80105cfd:	89 04 24             	mov    %eax,(%esp)
80105d00:	e8 ec b9 ff ff       	call   801016f1 <fileread>
}
80105d05:	c9                   	leave  
80105d06:	c3                   	ret    

80105d07 <sys_write>:

int
sys_write(void)
{
80105d07:	55                   	push   %ebp
80105d08:	89 e5                	mov    %esp,%ebp
80105d0a:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105d0d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105d10:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d14:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105d1b:	00 
80105d1c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d23:	e8 4b fe ff ff       	call   80105b73 <argfd>
80105d28:	85 c0                	test   %eax,%eax
80105d2a:	78 35                	js     80105d61 <sys_write+0x5a>
80105d2c:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d33:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105d3a:	e8 de fc ff ff       	call   80105a1d <argint>
80105d3f:	85 c0                	test   %eax,%eax
80105d41:	78 1e                	js     80105d61 <sys_write+0x5a>
80105d43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d46:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d4a:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105d4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d51:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105d58:	e8 ee fc ff ff       	call   80105a4b <argptr>
80105d5d:	85 c0                	test   %eax,%eax
80105d5f:	79 07                	jns    80105d68 <sys_write+0x61>
    return -1;
80105d61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d66:	eb 19                	jmp    80105d81 <sys_write+0x7a>
  return filewrite(f, p, n);
80105d68:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105d6b:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105d6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d71:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105d75:	89 54 24 04          	mov    %edx,0x4(%esp)
80105d79:	89 04 24             	mov    %eax,(%esp)
80105d7c:	e8 2c ba ff ff       	call   801017ad <filewrite>
}
80105d81:	c9                   	leave  
80105d82:	c3                   	ret    

80105d83 <sys_close>:

int
sys_close(void)
{
80105d83:	55                   	push   %ebp
80105d84:	89 e5                	mov    %esp,%ebp
80105d86:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105d89:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d8c:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d90:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105d93:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d97:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d9e:	e8 d0 fd ff ff       	call   80105b73 <argfd>
80105da3:	85 c0                	test   %eax,%eax
80105da5:	79 07                	jns    80105dae <sys_close+0x2b>
    return -1;
80105da7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dac:	eb 24                	jmp    80105dd2 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105dae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105db4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105db7:	83 c2 08             	add    $0x8,%edx
80105dba:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105dc1:	00 
  fileclose(f);
80105dc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc5:	89 04 24             	mov    %eax,(%esp)
80105dc8:	e8 ff b7 ff ff       	call   801015cc <fileclose>
  return 0;
80105dcd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dd2:	c9                   	leave  
80105dd3:	c3                   	ret    

80105dd4 <sys_fstat>:

int
sys_fstat(void)
{
80105dd4:	55                   	push   %ebp
80105dd5:	89 e5                	mov    %esp,%ebp
80105dd7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105dda:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105ddd:	89 44 24 08          	mov    %eax,0x8(%esp)
80105de1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105de8:	00 
80105de9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105df0:	e8 7e fd ff ff       	call   80105b73 <argfd>
80105df5:	85 c0                	test   %eax,%eax
80105df7:	78 1f                	js     80105e18 <sys_fstat+0x44>
80105df9:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105e00:	00 
80105e01:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e04:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e08:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105e0f:	e8 37 fc ff ff       	call   80105a4b <argptr>
80105e14:	85 c0                	test   %eax,%eax
80105e16:	79 07                	jns    80105e1f <sys_fstat+0x4b>
    return -1;
80105e18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e1d:	eb 12                	jmp    80105e31 <sys_fstat+0x5d>
  return filestat(f, st);
80105e1f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105e22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e25:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e29:	89 04 24             	mov    %eax,(%esp)
80105e2c:	e8 71 b8 ff ff       	call   801016a2 <filestat>
}
80105e31:	c9                   	leave  
80105e32:	c3                   	ret    

80105e33 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105e33:	55                   	push   %ebp
80105e34:	89 e5                	mov    %esp,%ebp
80105e36:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105e39:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105e3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e40:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e47:	e8 61 fc ff ff       	call   80105aad <argstr>
80105e4c:	85 c0                	test   %eax,%eax
80105e4e:	78 17                	js     80105e67 <sys_link+0x34>
80105e50:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105e53:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e57:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105e5e:	e8 4a fc ff ff       	call   80105aad <argstr>
80105e63:	85 c0                	test   %eax,%eax
80105e65:	79 0a                	jns    80105e71 <sys_link+0x3e>
    return -1;
80105e67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e6c:	e9 42 01 00 00       	jmp    80105fb3 <sys_link+0x180>

  begin_op();
80105e71:	e8 29 dc ff ff       	call   80103a9f <begin_op>
  if((ip = namei(old)) == 0){
80105e76:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105e79:	89 04 24             	mov    %eax,(%esp)
80105e7c:	e8 e7 cb ff ff       	call   80102a68 <namei>
80105e81:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e84:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e88:	75 0f                	jne    80105e99 <sys_link+0x66>
    end_op();
80105e8a:	e8 94 dc ff ff       	call   80103b23 <end_op>
    return -1;
80105e8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e94:	e9 1a 01 00 00       	jmp    80105fb3 <sys_link+0x180>
  }

  ilock(ip);
80105e99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e9c:	89 04 24             	mov    %eax,(%esp)
80105e9f:	e8 13 c0 ff ff       	call   80101eb7 <ilock>
  if(ip->type == T_DIR){
80105ea4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ea7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105eab:	66 83 f8 01          	cmp    $0x1,%ax
80105eaf:	75 1a                	jne    80105ecb <sys_link+0x98>
    iunlockput(ip);
80105eb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105eb4:	89 04 24             	mov    %eax,(%esp)
80105eb7:	e8 85 c2 ff ff       	call   80102141 <iunlockput>
    end_op();
80105ebc:	e8 62 dc ff ff       	call   80103b23 <end_op>
    return -1;
80105ec1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ec6:	e9 e8 00 00 00       	jmp    80105fb3 <sys_link+0x180>
  }

  ip->nlink++;
80105ecb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ece:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105ed2:	8d 50 01             	lea    0x1(%eax),%edx
80105ed5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ed8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105edc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105edf:	89 04 24             	mov    %eax,(%esp)
80105ee2:	e8 0e be ff ff       	call   80101cf5 <iupdate>
  iunlock(ip);
80105ee7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105eea:	89 04 24             	mov    %eax,(%esp)
80105eed:	e8 19 c1 ff ff       	call   8010200b <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105ef2:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105ef5:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105ef8:	89 54 24 04          	mov    %edx,0x4(%esp)
80105efc:	89 04 24             	mov    %eax,(%esp)
80105eff:	e8 86 cb ff ff       	call   80102a8a <nameiparent>
80105f04:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f07:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f0b:	75 02                	jne    80105f0f <sys_link+0xdc>
    goto bad;
80105f0d:	eb 68                	jmp    80105f77 <sys_link+0x144>
  ilock(dp);
80105f0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f12:	89 04 24             	mov    %eax,(%esp)
80105f15:	e8 9d bf ff ff       	call   80101eb7 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105f1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f1d:	8b 10                	mov    (%eax),%edx
80105f1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f22:	8b 00                	mov    (%eax),%eax
80105f24:	39 c2                	cmp    %eax,%edx
80105f26:	75 20                	jne    80105f48 <sys_link+0x115>
80105f28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f2b:	8b 40 04             	mov    0x4(%eax),%eax
80105f2e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f32:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105f35:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f3c:	89 04 24             	mov    %eax,(%esp)
80105f3f:	e8 64 c8 ff ff       	call   801027a8 <dirlink>
80105f44:	85 c0                	test   %eax,%eax
80105f46:	79 0d                	jns    80105f55 <sys_link+0x122>
    iunlockput(dp);
80105f48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f4b:	89 04 24             	mov    %eax,(%esp)
80105f4e:	e8 ee c1 ff ff       	call   80102141 <iunlockput>
    goto bad;
80105f53:	eb 22                	jmp    80105f77 <sys_link+0x144>
  }
  iunlockput(dp);
80105f55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f58:	89 04 24             	mov    %eax,(%esp)
80105f5b:	e8 e1 c1 ff ff       	call   80102141 <iunlockput>
  iput(ip);
80105f60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f63:	89 04 24             	mov    %eax,(%esp)
80105f66:	e8 05 c1 ff ff       	call   80102070 <iput>

  end_op();
80105f6b:	e8 b3 db ff ff       	call   80103b23 <end_op>

  return 0;
80105f70:	b8 00 00 00 00       	mov    $0x0,%eax
80105f75:	eb 3c                	jmp    80105fb3 <sys_link+0x180>

bad:
  ilock(ip);
80105f77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f7a:	89 04 24             	mov    %eax,(%esp)
80105f7d:	e8 35 bf ff ff       	call   80101eb7 <ilock>
  ip->nlink--;
80105f82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f85:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105f89:	8d 50 ff             	lea    -0x1(%eax),%edx
80105f8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f8f:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105f93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f96:	89 04 24             	mov    %eax,(%esp)
80105f99:	e8 57 bd ff ff       	call   80101cf5 <iupdate>
  iunlockput(ip);
80105f9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fa1:	89 04 24             	mov    %eax,(%esp)
80105fa4:	e8 98 c1 ff ff       	call   80102141 <iunlockput>
  end_op();
80105fa9:	e8 75 db ff ff       	call   80103b23 <end_op>
  return -1;
80105fae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105fb3:	c9                   	leave  
80105fb4:	c3                   	ret    

80105fb5 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105fb5:	55                   	push   %ebp
80105fb6:	89 e5                	mov    %esp,%ebp
80105fb8:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105fbb:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105fc2:	eb 4b                	jmp    8010600f <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105fc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fc7:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105fce:	00 
80105fcf:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fd3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105fd6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fda:	8b 45 08             	mov    0x8(%ebp),%eax
80105fdd:	89 04 24             	mov    %eax,(%esp)
80105fe0:	e8 e5 c3 ff ff       	call   801023ca <readi>
80105fe5:	83 f8 10             	cmp    $0x10,%eax
80105fe8:	74 0c                	je     80105ff6 <isdirempty+0x41>
      panic("isdirempty: readi");
80105fea:	c7 04 24 bb 8e 10 80 	movl   $0x80108ebb,(%esp)
80105ff1:	e8 44 a5 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80105ff6:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105ffa:	66 85 c0             	test   %ax,%ax
80105ffd:	74 07                	je     80106006 <isdirempty+0x51>
      return 0;
80105fff:	b8 00 00 00 00       	mov    $0x0,%eax
80106004:	eb 1b                	jmp    80106021 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106006:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106009:	83 c0 10             	add    $0x10,%eax
8010600c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010600f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106012:	8b 45 08             	mov    0x8(%ebp),%eax
80106015:	8b 40 18             	mov    0x18(%eax),%eax
80106018:	39 c2                	cmp    %eax,%edx
8010601a:	72 a8                	jb     80105fc4 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010601c:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106021:	c9                   	leave  
80106022:	c3                   	ret    

80106023 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106023:	55                   	push   %ebp
80106024:	89 e5                	mov    %esp,%ebp
80106026:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106029:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010602c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106030:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106037:	e8 71 fa ff ff       	call   80105aad <argstr>
8010603c:	85 c0                	test   %eax,%eax
8010603e:	79 0a                	jns    8010604a <sys_unlink+0x27>
    return -1;
80106040:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106045:	e9 af 01 00 00       	jmp    801061f9 <sys_unlink+0x1d6>

  begin_op();
8010604a:	e8 50 da ff ff       	call   80103a9f <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010604f:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106052:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106055:	89 54 24 04          	mov    %edx,0x4(%esp)
80106059:	89 04 24             	mov    %eax,(%esp)
8010605c:	e8 29 ca ff ff       	call   80102a8a <nameiparent>
80106061:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106064:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106068:	75 0f                	jne    80106079 <sys_unlink+0x56>
    end_op();
8010606a:	e8 b4 da ff ff       	call   80103b23 <end_op>
    return -1;
8010606f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106074:	e9 80 01 00 00       	jmp    801061f9 <sys_unlink+0x1d6>
  }

  ilock(dp);
80106079:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010607c:	89 04 24             	mov    %eax,(%esp)
8010607f:	e8 33 be ff ff       	call   80101eb7 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106084:	c7 44 24 04 cd 8e 10 	movl   $0x80108ecd,0x4(%esp)
8010608b:	80 
8010608c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010608f:	89 04 24             	mov    %eax,(%esp)
80106092:	e8 26 c6 ff ff       	call   801026bd <namecmp>
80106097:	85 c0                	test   %eax,%eax
80106099:	0f 84 45 01 00 00    	je     801061e4 <sys_unlink+0x1c1>
8010609f:	c7 44 24 04 cf 8e 10 	movl   $0x80108ecf,0x4(%esp)
801060a6:	80 
801060a7:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801060aa:	89 04 24             	mov    %eax,(%esp)
801060ad:	e8 0b c6 ff ff       	call   801026bd <namecmp>
801060b2:	85 c0                	test   %eax,%eax
801060b4:	0f 84 2a 01 00 00    	je     801061e4 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801060ba:	8d 45 c8             	lea    -0x38(%ebp),%eax
801060bd:	89 44 24 08          	mov    %eax,0x8(%esp)
801060c1:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801060c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801060c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060cb:	89 04 24             	mov    %eax,(%esp)
801060ce:	e8 0c c6 ff ff       	call   801026df <dirlookup>
801060d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060d6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801060da:	75 05                	jne    801060e1 <sys_unlink+0xbe>
    goto bad;
801060dc:	e9 03 01 00 00       	jmp    801061e4 <sys_unlink+0x1c1>
  ilock(ip);
801060e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060e4:	89 04 24             	mov    %eax,(%esp)
801060e7:	e8 cb bd ff ff       	call   80101eb7 <ilock>

  if(ip->nlink < 1)
801060ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ef:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801060f3:	66 85 c0             	test   %ax,%ax
801060f6:	7f 0c                	jg     80106104 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
801060f8:	c7 04 24 d2 8e 10 80 	movl   $0x80108ed2,(%esp)
801060ff:	e8 36 a4 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106104:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106107:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010610b:	66 83 f8 01          	cmp    $0x1,%ax
8010610f:	75 1f                	jne    80106130 <sys_unlink+0x10d>
80106111:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106114:	89 04 24             	mov    %eax,(%esp)
80106117:	e8 99 fe ff ff       	call   80105fb5 <isdirempty>
8010611c:	85 c0                	test   %eax,%eax
8010611e:	75 10                	jne    80106130 <sys_unlink+0x10d>
    iunlockput(ip);
80106120:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106123:	89 04 24             	mov    %eax,(%esp)
80106126:	e8 16 c0 ff ff       	call   80102141 <iunlockput>
    goto bad;
8010612b:	e9 b4 00 00 00       	jmp    801061e4 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80106130:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106137:	00 
80106138:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010613f:	00 
80106140:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106143:	89 04 24             	mov    %eax,(%esp)
80106146:	e8 90 f5 ff ff       	call   801056db <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010614b:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010614e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106155:	00 
80106156:	89 44 24 08          	mov    %eax,0x8(%esp)
8010615a:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010615d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106161:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106164:	89 04 24             	mov    %eax,(%esp)
80106167:	e8 c2 c3 ff ff       	call   8010252e <writei>
8010616c:	83 f8 10             	cmp    $0x10,%eax
8010616f:	74 0c                	je     8010617d <sys_unlink+0x15a>
    panic("unlink: writei");
80106171:	c7 04 24 e4 8e 10 80 	movl   $0x80108ee4,(%esp)
80106178:	e8 bd a3 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
8010617d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106180:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106184:	66 83 f8 01          	cmp    $0x1,%ax
80106188:	75 1c                	jne    801061a6 <sys_unlink+0x183>
    dp->nlink--;
8010618a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010618d:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106191:	8d 50 ff             	lea    -0x1(%eax),%edx
80106194:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106197:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010619b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010619e:	89 04 24             	mov    %eax,(%esp)
801061a1:	e8 4f bb ff ff       	call   80101cf5 <iupdate>
  }
  iunlockput(dp);
801061a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061a9:	89 04 24             	mov    %eax,(%esp)
801061ac:	e8 90 bf ff ff       	call   80102141 <iunlockput>

  ip->nlink--;
801061b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801061b8:	8d 50 ff             	lea    -0x1(%eax),%edx
801061bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061be:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801061c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061c5:	89 04 24             	mov    %eax,(%esp)
801061c8:	e8 28 bb ff ff       	call   80101cf5 <iupdate>
  iunlockput(ip);
801061cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061d0:	89 04 24             	mov    %eax,(%esp)
801061d3:	e8 69 bf ff ff       	call   80102141 <iunlockput>

  end_op();
801061d8:	e8 46 d9 ff ff       	call   80103b23 <end_op>

  return 0;
801061dd:	b8 00 00 00 00       	mov    $0x0,%eax
801061e2:	eb 15                	jmp    801061f9 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
801061e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061e7:	89 04 24             	mov    %eax,(%esp)
801061ea:	e8 52 bf ff ff       	call   80102141 <iunlockput>
  end_op();
801061ef:	e8 2f d9 ff ff       	call   80103b23 <end_op>
  return -1;
801061f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801061f9:	c9                   	leave  
801061fa:	c3                   	ret    

801061fb <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801061fb:	55                   	push   %ebp
801061fc:	89 e5                	mov    %esp,%ebp
801061fe:	83 ec 48             	sub    $0x48,%esp
80106201:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106204:	8b 55 10             	mov    0x10(%ebp),%edx
80106207:	8b 45 14             	mov    0x14(%ebp),%eax
8010620a:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
8010620e:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106212:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106216:	8d 45 de             	lea    -0x22(%ebp),%eax
80106219:	89 44 24 04          	mov    %eax,0x4(%esp)
8010621d:	8b 45 08             	mov    0x8(%ebp),%eax
80106220:	89 04 24             	mov    %eax,(%esp)
80106223:	e8 62 c8 ff ff       	call   80102a8a <nameiparent>
80106228:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010622b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010622f:	75 0a                	jne    8010623b <create+0x40>
    return 0;
80106231:	b8 00 00 00 00       	mov    $0x0,%eax
80106236:	e9 7e 01 00 00       	jmp    801063b9 <create+0x1be>
  ilock(dp);
8010623b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010623e:	89 04 24             	mov    %eax,(%esp)
80106241:	e8 71 bc ff ff       	call   80101eb7 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106246:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106249:	89 44 24 08          	mov    %eax,0x8(%esp)
8010624d:	8d 45 de             	lea    -0x22(%ebp),%eax
80106250:	89 44 24 04          	mov    %eax,0x4(%esp)
80106254:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106257:	89 04 24             	mov    %eax,(%esp)
8010625a:	e8 80 c4 ff ff       	call   801026df <dirlookup>
8010625f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106262:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106266:	74 47                	je     801062af <create+0xb4>
    iunlockput(dp);
80106268:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010626b:	89 04 24             	mov    %eax,(%esp)
8010626e:	e8 ce be ff ff       	call   80102141 <iunlockput>
    ilock(ip);
80106273:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106276:	89 04 24             	mov    %eax,(%esp)
80106279:	e8 39 bc ff ff       	call   80101eb7 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010627e:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106283:	75 15                	jne    8010629a <create+0x9f>
80106285:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106288:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010628c:	66 83 f8 02          	cmp    $0x2,%ax
80106290:	75 08                	jne    8010629a <create+0x9f>
      return ip;
80106292:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106295:	e9 1f 01 00 00       	jmp    801063b9 <create+0x1be>
    iunlockput(ip);
8010629a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010629d:	89 04 24             	mov    %eax,(%esp)
801062a0:	e8 9c be ff ff       	call   80102141 <iunlockput>
    return 0;
801062a5:	b8 00 00 00 00       	mov    $0x0,%eax
801062aa:	e9 0a 01 00 00       	jmp    801063b9 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801062af:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801062b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b6:	8b 00                	mov    (%eax),%eax
801062b8:	89 54 24 04          	mov    %edx,0x4(%esp)
801062bc:	89 04 24             	mov    %eax,(%esp)
801062bf:	e8 5c b9 ff ff       	call   80101c20 <ialloc>
801062c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801062c7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801062cb:	75 0c                	jne    801062d9 <create+0xde>
    panic("create: ialloc");
801062cd:	c7 04 24 f3 8e 10 80 	movl   $0x80108ef3,(%esp)
801062d4:	e8 61 a2 ff ff       	call   8010053a <panic>

  ilock(ip);
801062d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062dc:	89 04 24             	mov    %eax,(%esp)
801062df:	e8 d3 bb ff ff       	call   80101eb7 <ilock>
  ip->major = major;
801062e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062e7:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801062eb:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801062ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062f2:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801062f6:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801062fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062fd:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106303:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106306:	89 04 24             	mov    %eax,(%esp)
80106309:	e8 e7 b9 ff ff       	call   80101cf5 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
8010630e:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106313:	75 6a                	jne    8010637f <create+0x184>
    dp->nlink++;  // for ".."
80106315:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106318:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010631c:	8d 50 01             	lea    0x1(%eax),%edx
8010631f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106322:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106326:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106329:	89 04 24             	mov    %eax,(%esp)
8010632c:	e8 c4 b9 ff ff       	call   80101cf5 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106331:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106334:	8b 40 04             	mov    0x4(%eax),%eax
80106337:	89 44 24 08          	mov    %eax,0x8(%esp)
8010633b:	c7 44 24 04 cd 8e 10 	movl   $0x80108ecd,0x4(%esp)
80106342:	80 
80106343:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106346:	89 04 24             	mov    %eax,(%esp)
80106349:	e8 5a c4 ff ff       	call   801027a8 <dirlink>
8010634e:	85 c0                	test   %eax,%eax
80106350:	78 21                	js     80106373 <create+0x178>
80106352:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106355:	8b 40 04             	mov    0x4(%eax),%eax
80106358:	89 44 24 08          	mov    %eax,0x8(%esp)
8010635c:	c7 44 24 04 cf 8e 10 	movl   $0x80108ecf,0x4(%esp)
80106363:	80 
80106364:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106367:	89 04 24             	mov    %eax,(%esp)
8010636a:	e8 39 c4 ff ff       	call   801027a8 <dirlink>
8010636f:	85 c0                	test   %eax,%eax
80106371:	79 0c                	jns    8010637f <create+0x184>
      panic("create dots");
80106373:	c7 04 24 02 8f 10 80 	movl   $0x80108f02,(%esp)
8010637a:	e8 bb a1 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
8010637f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106382:	8b 40 04             	mov    0x4(%eax),%eax
80106385:	89 44 24 08          	mov    %eax,0x8(%esp)
80106389:	8d 45 de             	lea    -0x22(%ebp),%eax
8010638c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106390:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106393:	89 04 24             	mov    %eax,(%esp)
80106396:	e8 0d c4 ff ff       	call   801027a8 <dirlink>
8010639b:	85 c0                	test   %eax,%eax
8010639d:	79 0c                	jns    801063ab <create+0x1b0>
    panic("create: dirlink");
8010639f:	c7 04 24 0e 8f 10 80 	movl   $0x80108f0e,(%esp)
801063a6:	e8 8f a1 ff ff       	call   8010053a <panic>

  iunlockput(dp);
801063ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063ae:	89 04 24             	mov    %eax,(%esp)
801063b1:	e8 8b bd ff ff       	call   80102141 <iunlockput>

  return ip;
801063b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801063b9:	c9                   	leave  
801063ba:	c3                   	ret    

801063bb <sys_open>:

int
sys_open(void)
{
801063bb:	55                   	push   %ebp
801063bc:	89 e5                	mov    %esp,%ebp
801063be:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801063c1:	8d 45 e8             	lea    -0x18(%ebp),%eax
801063c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801063c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063cf:	e8 d9 f6 ff ff       	call   80105aad <argstr>
801063d4:	85 c0                	test   %eax,%eax
801063d6:	78 17                	js     801063ef <sys_open+0x34>
801063d8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801063db:	89 44 24 04          	mov    %eax,0x4(%esp)
801063df:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801063e6:	e8 32 f6 ff ff       	call   80105a1d <argint>
801063eb:	85 c0                	test   %eax,%eax
801063ed:	79 0a                	jns    801063f9 <sys_open+0x3e>
    return -1;
801063ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063f4:	e9 5c 01 00 00       	jmp    80106555 <sys_open+0x19a>

  begin_op();
801063f9:	e8 a1 d6 ff ff       	call   80103a9f <begin_op>

  if(omode & O_CREATE){
801063fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106401:	25 00 02 00 00       	and    $0x200,%eax
80106406:	85 c0                	test   %eax,%eax
80106408:	74 3b                	je     80106445 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
8010640a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010640d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106414:	00 
80106415:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010641c:	00 
8010641d:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106424:	00 
80106425:	89 04 24             	mov    %eax,(%esp)
80106428:	e8 ce fd ff ff       	call   801061fb <create>
8010642d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106430:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106434:	75 6b                	jne    801064a1 <sys_open+0xe6>
      end_op();
80106436:	e8 e8 d6 ff ff       	call   80103b23 <end_op>
      return -1;
8010643b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106440:	e9 10 01 00 00       	jmp    80106555 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80106445:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106448:	89 04 24             	mov    %eax,(%esp)
8010644b:	e8 18 c6 ff ff       	call   80102a68 <namei>
80106450:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106453:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106457:	75 0f                	jne    80106468 <sys_open+0xad>
      end_op();
80106459:	e8 c5 d6 ff ff       	call   80103b23 <end_op>
      return -1;
8010645e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106463:	e9 ed 00 00 00       	jmp    80106555 <sys_open+0x19a>
    }
    ilock(ip);
80106468:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010646b:	89 04 24             	mov    %eax,(%esp)
8010646e:	e8 44 ba ff ff       	call   80101eb7 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106476:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010647a:	66 83 f8 01          	cmp    $0x1,%ax
8010647e:	75 21                	jne    801064a1 <sys_open+0xe6>
80106480:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106483:	85 c0                	test   %eax,%eax
80106485:	74 1a                	je     801064a1 <sys_open+0xe6>
      iunlockput(ip);
80106487:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010648a:	89 04 24             	mov    %eax,(%esp)
8010648d:	e8 af bc ff ff       	call   80102141 <iunlockput>
      end_op();
80106492:	e8 8c d6 ff ff       	call   80103b23 <end_op>
      return -1;
80106497:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010649c:	e9 b4 00 00 00       	jmp    80106555 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801064a1:	e8 7e b0 ff ff       	call   80101524 <filealloc>
801064a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801064a9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064ad:	74 14                	je     801064c3 <sys_open+0x108>
801064af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064b2:	89 04 24             	mov    %eax,(%esp)
801064b5:	e8 2e f7 ff ff       	call   80105be8 <fdalloc>
801064ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
801064bd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801064c1:	79 28                	jns    801064eb <sys_open+0x130>
    if(f)
801064c3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064c7:	74 0b                	je     801064d4 <sys_open+0x119>
      fileclose(f);
801064c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064cc:	89 04 24             	mov    %eax,(%esp)
801064cf:	e8 f8 b0 ff ff       	call   801015cc <fileclose>
    iunlockput(ip);
801064d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064d7:	89 04 24             	mov    %eax,(%esp)
801064da:	e8 62 bc ff ff       	call   80102141 <iunlockput>
    end_op();
801064df:	e8 3f d6 ff ff       	call   80103b23 <end_op>
    return -1;
801064e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064e9:	eb 6a                	jmp    80106555 <sys_open+0x19a>
  }
  iunlock(ip);
801064eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ee:	89 04 24             	mov    %eax,(%esp)
801064f1:	e8 15 bb ff ff       	call   8010200b <iunlock>
  end_op();
801064f6:	e8 28 d6 ff ff       	call   80103b23 <end_op>

  f->type = FD_INODE;
801064fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064fe:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106504:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106507:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010650a:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010650d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106510:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106517:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010651a:	83 e0 01             	and    $0x1,%eax
8010651d:	85 c0                	test   %eax,%eax
8010651f:	0f 94 c0             	sete   %al
80106522:	89 c2                	mov    %eax,%edx
80106524:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106527:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010652a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010652d:	83 e0 01             	and    $0x1,%eax
80106530:	85 c0                	test   %eax,%eax
80106532:	75 0a                	jne    8010653e <sys_open+0x183>
80106534:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106537:	83 e0 02             	and    $0x2,%eax
8010653a:	85 c0                	test   %eax,%eax
8010653c:	74 07                	je     80106545 <sys_open+0x18a>
8010653e:	b8 01 00 00 00       	mov    $0x1,%eax
80106543:	eb 05                	jmp    8010654a <sys_open+0x18f>
80106545:	b8 00 00 00 00       	mov    $0x0,%eax
8010654a:	89 c2                	mov    %eax,%edx
8010654c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010654f:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106552:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106555:	c9                   	leave  
80106556:	c3                   	ret    

80106557 <sys_mkdir>:

int
sys_mkdir(void)
{
80106557:	55                   	push   %ebp
80106558:	89 e5                	mov    %esp,%ebp
8010655a:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010655d:	e8 3d d5 ff ff       	call   80103a9f <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106562:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106565:	89 44 24 04          	mov    %eax,0x4(%esp)
80106569:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106570:	e8 38 f5 ff ff       	call   80105aad <argstr>
80106575:	85 c0                	test   %eax,%eax
80106577:	78 2c                	js     801065a5 <sys_mkdir+0x4e>
80106579:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010657c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106583:	00 
80106584:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010658b:	00 
8010658c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106593:	00 
80106594:	89 04 24             	mov    %eax,(%esp)
80106597:	e8 5f fc ff ff       	call   801061fb <create>
8010659c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010659f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065a3:	75 0c                	jne    801065b1 <sys_mkdir+0x5a>
    end_op();
801065a5:	e8 79 d5 ff ff       	call   80103b23 <end_op>
    return -1;
801065aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065af:	eb 15                	jmp    801065c6 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801065b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b4:	89 04 24             	mov    %eax,(%esp)
801065b7:	e8 85 bb ff ff       	call   80102141 <iunlockput>
  end_op();
801065bc:	e8 62 d5 ff ff       	call   80103b23 <end_op>
  return 0;
801065c1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065c6:	c9                   	leave  
801065c7:	c3                   	ret    

801065c8 <sys_mknod>:

int
sys_mknod(void)
{
801065c8:	55                   	push   %ebp
801065c9:	89 e5                	mov    %esp,%ebp
801065cb:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801065ce:	e8 cc d4 ff ff       	call   80103a9f <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801065d3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801065d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801065da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065e1:	e8 c7 f4 ff ff       	call   80105aad <argstr>
801065e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801065e9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065ed:	78 5e                	js     8010664d <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801065ef:	8d 45 e8             	lea    -0x18(%ebp),%eax
801065f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801065f6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065fd:	e8 1b f4 ff ff       	call   80105a1d <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106602:	85 c0                	test   %eax,%eax
80106604:	78 47                	js     8010664d <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106606:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106609:	89 44 24 04          	mov    %eax,0x4(%esp)
8010660d:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106614:	e8 04 f4 ff ff       	call   80105a1d <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106619:	85 c0                	test   %eax,%eax
8010661b:	78 30                	js     8010664d <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
8010661d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106620:	0f bf c8             	movswl %ax,%ecx
80106623:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106626:	0f bf d0             	movswl %ax,%edx
80106629:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010662c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106630:	89 54 24 08          	mov    %edx,0x8(%esp)
80106634:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010663b:	00 
8010663c:	89 04 24             	mov    %eax,(%esp)
8010663f:	e8 b7 fb ff ff       	call   801061fb <create>
80106644:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106647:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010664b:	75 0c                	jne    80106659 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
8010664d:	e8 d1 d4 ff ff       	call   80103b23 <end_op>
    return -1;
80106652:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106657:	eb 15                	jmp    8010666e <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106659:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010665c:	89 04 24             	mov    %eax,(%esp)
8010665f:	e8 dd ba ff ff       	call   80102141 <iunlockput>
  end_op();
80106664:	e8 ba d4 ff ff       	call   80103b23 <end_op>
  return 0;
80106669:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010666e:	c9                   	leave  
8010666f:	c3                   	ret    

80106670 <sys_chdir>:

int
sys_chdir(void)
{
80106670:	55                   	push   %ebp
80106671:	89 e5                	mov    %esp,%ebp
80106673:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106676:	e8 24 d4 ff ff       	call   80103a9f <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
8010667b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010667e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106682:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106689:	e8 1f f4 ff ff       	call   80105aad <argstr>
8010668e:	85 c0                	test   %eax,%eax
80106690:	78 14                	js     801066a6 <sys_chdir+0x36>
80106692:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106695:	89 04 24             	mov    %eax,(%esp)
80106698:	e8 cb c3 ff ff       	call   80102a68 <namei>
8010669d:	89 45 f4             	mov    %eax,-0xc(%ebp)
801066a0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801066a4:	75 0c                	jne    801066b2 <sys_chdir+0x42>
    end_op();
801066a6:	e8 78 d4 ff ff       	call   80103b23 <end_op>
    return -1;
801066ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066b0:	eb 61                	jmp    80106713 <sys_chdir+0xa3>
  }
  ilock(ip);
801066b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066b5:	89 04 24             	mov    %eax,(%esp)
801066b8:	e8 fa b7 ff ff       	call   80101eb7 <ilock>
  if(ip->type != T_DIR){
801066bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066c0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801066c4:	66 83 f8 01          	cmp    $0x1,%ax
801066c8:	74 17                	je     801066e1 <sys_chdir+0x71>
    iunlockput(ip);
801066ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066cd:	89 04 24             	mov    %eax,(%esp)
801066d0:	e8 6c ba ff ff       	call   80102141 <iunlockput>
    end_op();
801066d5:	e8 49 d4 ff ff       	call   80103b23 <end_op>
    return -1;
801066da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066df:	eb 32                	jmp    80106713 <sys_chdir+0xa3>
  }
  iunlock(ip);
801066e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e4:	89 04 24             	mov    %eax,(%esp)
801066e7:	e8 1f b9 ff ff       	call   8010200b <iunlock>
  iput(proc->cwd);
801066ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066f2:	8b 40 68             	mov    0x68(%eax),%eax
801066f5:	89 04 24             	mov    %eax,(%esp)
801066f8:	e8 73 b9 ff ff       	call   80102070 <iput>
  end_op();
801066fd:	e8 21 d4 ff ff       	call   80103b23 <end_op>
  proc->cwd = ip;
80106702:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106708:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010670b:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
8010670e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106713:	c9                   	leave  
80106714:	c3                   	ret    

80106715 <sys_exec>:

int
sys_exec(void)
{
80106715:	55                   	push   %ebp
80106716:	89 e5                	mov    %esp,%ebp
80106718:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
8010671e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106721:	89 44 24 04          	mov    %eax,0x4(%esp)
80106725:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010672c:	e8 7c f3 ff ff       	call   80105aad <argstr>
80106731:	85 c0                	test   %eax,%eax
80106733:	78 1a                	js     8010674f <sys_exec+0x3a>
80106735:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010673b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010673f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106746:	e8 d2 f2 ff ff       	call   80105a1d <argint>
8010674b:	85 c0                	test   %eax,%eax
8010674d:	79 0a                	jns    80106759 <sys_exec+0x44>
    return -1;
8010674f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106754:	e9 c8 00 00 00       	jmp    80106821 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106759:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106760:	00 
80106761:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106768:	00 
80106769:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010676f:	89 04 24             	mov    %eax,(%esp)
80106772:	e8 64 ef ff ff       	call   801056db <memset>
  for(i=0;; i++){
80106777:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
8010677e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106781:	83 f8 1f             	cmp    $0x1f,%eax
80106784:	76 0a                	jbe    80106790 <sys_exec+0x7b>
      return -1;
80106786:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010678b:	e9 91 00 00 00       	jmp    80106821 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106790:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106793:	c1 e0 02             	shl    $0x2,%eax
80106796:	89 c2                	mov    %eax,%edx
80106798:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
8010679e:	01 c2                	add    %eax,%edx
801067a0:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
801067a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801067aa:	89 14 24             	mov    %edx,(%esp)
801067ad:	e8 cf f1 ff ff       	call   80105981 <fetchint>
801067b2:	85 c0                	test   %eax,%eax
801067b4:	79 07                	jns    801067bd <sys_exec+0xa8>
      return -1;
801067b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067bb:	eb 64                	jmp    80106821 <sys_exec+0x10c>
    if(uarg == 0){
801067bd:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801067c3:	85 c0                	test   %eax,%eax
801067c5:	75 26                	jne    801067ed <sys_exec+0xd8>
      argv[i] = 0;
801067c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ca:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801067d1:	00 00 00 00 
      break;
801067d5:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801067d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067d9:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801067df:	89 54 24 04          	mov    %edx,0x4(%esp)
801067e3:	89 04 24             	mov    %eax,(%esp)
801067e6:	e8 02 a9 ff ff       	call   801010ed <exec>
801067eb:	eb 34                	jmp    80106821 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
801067ed:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801067f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801067f6:	c1 e2 02             	shl    $0x2,%edx
801067f9:	01 c2                	add    %eax,%edx
801067fb:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106801:	89 54 24 04          	mov    %edx,0x4(%esp)
80106805:	89 04 24             	mov    %eax,(%esp)
80106808:	e8 ae f1 ff ff       	call   801059bb <fetchstr>
8010680d:	85 c0                	test   %eax,%eax
8010680f:	79 07                	jns    80106818 <sys_exec+0x103>
      return -1;
80106811:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106816:	eb 09                	jmp    80106821 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106818:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
8010681c:	e9 5d ff ff ff       	jmp    8010677e <sys_exec+0x69>
  return exec(path, argv);
}
80106821:	c9                   	leave  
80106822:	c3                   	ret    

80106823 <sys_pipe>:

int
sys_pipe(void)
{
80106823:	55                   	push   %ebp
80106824:	89 e5                	mov    %esp,%ebp
80106826:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106829:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106830:	00 
80106831:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106834:	89 44 24 04          	mov    %eax,0x4(%esp)
80106838:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010683f:	e8 07 f2 ff ff       	call   80105a4b <argptr>
80106844:	85 c0                	test   %eax,%eax
80106846:	79 0a                	jns    80106852 <sys_pipe+0x2f>
    return -1;
80106848:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010684d:	e9 9b 00 00 00       	jmp    801068ed <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106852:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106855:	89 44 24 04          	mov    %eax,0x4(%esp)
80106859:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010685c:	89 04 24             	mov    %eax,(%esp)
8010685f:	e8 47 dd ff ff       	call   801045ab <pipealloc>
80106864:	85 c0                	test   %eax,%eax
80106866:	79 07                	jns    8010686f <sys_pipe+0x4c>
    return -1;
80106868:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010686d:	eb 7e                	jmp    801068ed <sys_pipe+0xca>
  fd0 = -1;
8010686f:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106876:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106879:	89 04 24             	mov    %eax,(%esp)
8010687c:	e8 67 f3 ff ff       	call   80105be8 <fdalloc>
80106881:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106884:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106888:	78 14                	js     8010689e <sys_pipe+0x7b>
8010688a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010688d:	89 04 24             	mov    %eax,(%esp)
80106890:	e8 53 f3 ff ff       	call   80105be8 <fdalloc>
80106895:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106898:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010689c:	79 37                	jns    801068d5 <sys_pipe+0xb2>
    if(fd0 >= 0)
8010689e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068a2:	78 14                	js     801068b8 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801068a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801068ad:	83 c2 08             	add    $0x8,%edx
801068b0:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801068b7:	00 
    fileclose(rf);
801068b8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801068bb:	89 04 24             	mov    %eax,(%esp)
801068be:	e8 09 ad ff ff       	call   801015cc <fileclose>
    fileclose(wf);
801068c3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801068c6:	89 04 24             	mov    %eax,(%esp)
801068c9:	e8 fe ac ff ff       	call   801015cc <fileclose>
    return -1;
801068ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068d3:	eb 18                	jmp    801068ed <sys_pipe+0xca>
  }
  fd[0] = fd0;
801068d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801068d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801068db:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801068dd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801068e0:	8d 50 04             	lea    0x4(%eax),%edx
801068e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068e6:	89 02                	mov    %eax,(%edx)
  return 0;
801068e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068ed:	c9                   	leave  
801068ee:	c3                   	ret    

801068ef <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801068ef:	55                   	push   %ebp
801068f0:	89 e5                	mov    %esp,%ebp
801068f2:	83 ec 08             	sub    $0x8,%esp
  return fork();
801068f5:	e8 5c e3 ff ff       	call   80104c56 <fork>
}
801068fa:	c9                   	leave  
801068fb:	c3                   	ret    

801068fc <sys_exit>:

int
sys_exit(void)
{
801068fc:	55                   	push   %ebp
801068fd:	89 e5                	mov    %esp,%ebp
801068ff:	83 ec 08             	sub    $0x8,%esp
  exit();
80106902:	e8 ca e4 ff ff       	call   80104dd1 <exit>
  return 0;  // not reached
80106907:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010690c:	c9                   	leave  
8010690d:	c3                   	ret    

8010690e <sys_wait>:

int
sys_wait(void)
{
8010690e:	55                   	push   %ebp
8010690f:	89 e5                	mov    %esp,%ebp
80106911:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106914:	e8 da e5 ff ff       	call   80104ef3 <wait>
}
80106919:	c9                   	leave  
8010691a:	c3                   	ret    

8010691b <sys_kill>:

int
sys_kill(void)
{
8010691b:	55                   	push   %ebp
8010691c:	89 e5                	mov    %esp,%ebp
8010691e:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106921:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106924:	89 44 24 04          	mov    %eax,0x4(%esp)
80106928:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010692f:	e8 e9 f0 ff ff       	call   80105a1d <argint>
80106934:	85 c0                	test   %eax,%eax
80106936:	79 07                	jns    8010693f <sys_kill+0x24>
    return -1;
80106938:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010693d:	eb 0b                	jmp    8010694a <sys_kill+0x2f>
  return kill(pid);
8010693f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106942:	89 04 24             	mov    %eax,(%esp)
80106945:	e8 77 e9 ff ff       	call   801052c1 <kill>
}
8010694a:	c9                   	leave  
8010694b:	c3                   	ret    

8010694c <sys_getpid>:

int
sys_getpid(void)
{
8010694c:	55                   	push   %ebp
8010694d:	89 e5                	mov    %esp,%ebp
  return proc->pid;
8010694f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106955:	8b 40 10             	mov    0x10(%eax),%eax
}
80106958:	5d                   	pop    %ebp
80106959:	c3                   	ret    

8010695a <sys_sbrk>:

int
sys_sbrk(void)
{
8010695a:	55                   	push   %ebp
8010695b:	89 e5                	mov    %esp,%ebp
8010695d:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106960:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106963:	89 44 24 04          	mov    %eax,0x4(%esp)
80106967:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010696e:	e8 aa f0 ff ff       	call   80105a1d <argint>
80106973:	85 c0                	test   %eax,%eax
80106975:	79 07                	jns    8010697e <sys_sbrk+0x24>
    return -1;
80106977:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010697c:	eb 24                	jmp    801069a2 <sys_sbrk+0x48>
  addr = proc->sz;
8010697e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106984:	8b 00                	mov    (%eax),%eax
80106986:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106989:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010698c:	89 04 24             	mov    %eax,(%esp)
8010698f:	e8 1d e2 ff ff       	call   80104bb1 <growproc>
80106994:	85 c0                	test   %eax,%eax
80106996:	79 07                	jns    8010699f <sys_sbrk+0x45>
    return -1;
80106998:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010699d:	eb 03                	jmp    801069a2 <sys_sbrk+0x48>
  return addr;
8010699f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801069a2:	c9                   	leave  
801069a3:	c3                   	ret    

801069a4 <sys_sleep>:

int
sys_sleep(void)
{
801069a4:	55                   	push   %ebp
801069a5:	89 e5                	mov    %esp,%ebp
801069a7:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801069aa:	8d 45 f0             	lea    -0x10(%ebp),%eax
801069ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801069b1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069b8:	e8 60 f0 ff ff       	call   80105a1d <argint>
801069bd:	85 c0                	test   %eax,%eax
801069bf:	79 07                	jns    801069c8 <sys_sleep+0x24>
    return -1;
801069c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069c6:	eb 6c                	jmp    80106a34 <sys_sleep+0x90>
  acquire(&tickslock);
801069c8:	c7 04 24 00 61 11 80 	movl   $0x80116100,(%esp)
801069cf:	e8 b3 ea ff ff       	call   80105487 <acquire>
  ticks0 = ticks;
801069d4:	a1 40 69 11 80       	mov    0x80116940,%eax
801069d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801069dc:	eb 34                	jmp    80106a12 <sys_sleep+0x6e>
    if(proc->killed){
801069de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069e4:	8b 40 24             	mov    0x24(%eax),%eax
801069e7:	85 c0                	test   %eax,%eax
801069e9:	74 13                	je     801069fe <sys_sleep+0x5a>
      release(&tickslock);
801069eb:	c7 04 24 00 61 11 80 	movl   $0x80116100,(%esp)
801069f2:	e8 f2 ea ff ff       	call   801054e9 <release>
      return -1;
801069f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069fc:	eb 36                	jmp    80106a34 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801069fe:	c7 44 24 04 00 61 11 	movl   $0x80116100,0x4(%esp)
80106a05:	80 
80106a06:	c7 04 24 40 69 11 80 	movl   $0x80116940,(%esp)
80106a0d:	e8 ab e7 ff ff       	call   801051bd <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106a12:	a1 40 69 11 80       	mov    0x80116940,%eax
80106a17:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106a1a:	89 c2                	mov    %eax,%edx
80106a1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a1f:	39 c2                	cmp    %eax,%edx
80106a21:	72 bb                	jb     801069de <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106a23:	c7 04 24 00 61 11 80 	movl   $0x80116100,(%esp)
80106a2a:	e8 ba ea ff ff       	call   801054e9 <release>
  return 0;
80106a2f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a34:	c9                   	leave  
80106a35:	c3                   	ret    

80106a36 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106a36:	55                   	push   %ebp
80106a37:	89 e5                	mov    %esp,%ebp
80106a39:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106a3c:	c7 04 24 00 61 11 80 	movl   $0x80116100,(%esp)
80106a43:	e8 3f ea ff ff       	call   80105487 <acquire>
  xticks = ticks;
80106a48:	a1 40 69 11 80       	mov    0x80116940,%eax
80106a4d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106a50:	c7 04 24 00 61 11 80 	movl   $0x80116100,(%esp)
80106a57:	e8 8d ea ff ff       	call   801054e9 <release>
  return xticks;
80106a5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106a5f:	c9                   	leave  
80106a60:	c3                   	ret    

80106a61 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106a61:	55                   	push   %ebp
80106a62:	89 e5                	mov    %esp,%ebp
80106a64:	83 ec 08             	sub    $0x8,%esp
80106a67:	8b 55 08             	mov    0x8(%ebp),%edx
80106a6a:	8b 45 0c             	mov    0xc(%ebp),%eax
80106a6d:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106a71:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106a74:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106a78:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106a7c:	ee                   	out    %al,(%dx)
}
80106a7d:	c9                   	leave  
80106a7e:	c3                   	ret    

80106a7f <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106a7f:	55                   	push   %ebp
80106a80:	89 e5                	mov    %esp,%ebp
80106a82:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106a85:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106a8c:	00 
80106a8d:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106a94:	e8 c8 ff ff ff       	call   80106a61 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106a99:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106aa0:	00 
80106aa1:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106aa8:	e8 b4 ff ff ff       	call   80106a61 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106aad:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106ab4:	00 
80106ab5:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106abc:	e8 a0 ff ff ff       	call   80106a61 <outb>
  picenable(IRQ_TIMER);
80106ac1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ac8:	e8 71 d9 ff ff       	call   8010443e <picenable>
}
80106acd:	c9                   	leave  
80106ace:	c3                   	ret    

80106acf <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106acf:	1e                   	push   %ds
  pushl %es
80106ad0:	06                   	push   %es
  pushl %fs
80106ad1:	0f a0                	push   %fs
  pushl %gs
80106ad3:	0f a8                	push   %gs
  pushal
80106ad5:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106ad6:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106ada:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106adc:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106ade:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106ae2:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106ae4:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106ae6:	54                   	push   %esp
  call trap
80106ae7:	e8 d8 01 00 00       	call   80106cc4 <trap>
  addl $4, %esp
80106aec:	83 c4 04             	add    $0x4,%esp

80106aef <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106aef:	61                   	popa   
  popl %gs
80106af0:	0f a9                	pop    %gs
  popl %fs
80106af2:	0f a1                	pop    %fs
  popl %es
80106af4:	07                   	pop    %es
  popl %ds
80106af5:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106af6:	83 c4 08             	add    $0x8,%esp
  iret
80106af9:	cf                   	iret   

80106afa <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106afa:	55                   	push   %ebp
80106afb:	89 e5                	mov    %esp,%ebp
80106afd:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106b00:	8b 45 0c             	mov    0xc(%ebp),%eax
80106b03:	83 e8 01             	sub    $0x1,%eax
80106b06:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80106b0d:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106b11:	8b 45 08             	mov    0x8(%ebp),%eax
80106b14:	c1 e8 10             	shr    $0x10,%eax
80106b17:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106b1b:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106b1e:	0f 01 18             	lidtl  (%eax)
}
80106b21:	c9                   	leave  
80106b22:	c3                   	ret    

80106b23 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106b23:	55                   	push   %ebp
80106b24:	89 e5                	mov    %esp,%ebp
80106b26:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106b29:	0f 20 d0             	mov    %cr2,%eax
80106b2c:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106b2f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106b32:	c9                   	leave  
80106b33:	c3                   	ret    

80106b34 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106b34:	55                   	push   %ebp
80106b35:	89 e5                	mov    %esp,%ebp
80106b37:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106b3a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106b41:	e9 c3 00 00 00       	jmp    80106c09 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b49:	8b 04 85 9c c0 10 80 	mov    -0x7fef3f64(,%eax,4),%eax
80106b50:	89 c2                	mov    %eax,%edx
80106b52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b55:	66 89 14 c5 40 61 11 	mov    %dx,-0x7fee9ec0(,%eax,8)
80106b5c:	80 
80106b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b60:	66 c7 04 c5 42 61 11 	movw   $0x8,-0x7fee9ebe(,%eax,8)
80106b67:	80 08 00 
80106b6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b6d:	0f b6 14 c5 44 61 11 	movzbl -0x7fee9ebc(,%eax,8),%edx
80106b74:	80 
80106b75:	83 e2 e0             	and    $0xffffffe0,%edx
80106b78:	88 14 c5 44 61 11 80 	mov    %dl,-0x7fee9ebc(,%eax,8)
80106b7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b82:	0f b6 14 c5 44 61 11 	movzbl -0x7fee9ebc(,%eax,8),%edx
80106b89:	80 
80106b8a:	83 e2 1f             	and    $0x1f,%edx
80106b8d:	88 14 c5 44 61 11 80 	mov    %dl,-0x7fee9ebc(,%eax,8)
80106b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b97:	0f b6 14 c5 45 61 11 	movzbl -0x7fee9ebb(,%eax,8),%edx
80106b9e:	80 
80106b9f:	83 e2 f0             	and    $0xfffffff0,%edx
80106ba2:	83 ca 0e             	or     $0xe,%edx
80106ba5:	88 14 c5 45 61 11 80 	mov    %dl,-0x7fee9ebb(,%eax,8)
80106bac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106baf:	0f b6 14 c5 45 61 11 	movzbl -0x7fee9ebb(,%eax,8),%edx
80106bb6:	80 
80106bb7:	83 e2 ef             	and    $0xffffffef,%edx
80106bba:	88 14 c5 45 61 11 80 	mov    %dl,-0x7fee9ebb(,%eax,8)
80106bc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bc4:	0f b6 14 c5 45 61 11 	movzbl -0x7fee9ebb(,%eax,8),%edx
80106bcb:	80 
80106bcc:	83 e2 9f             	and    $0xffffff9f,%edx
80106bcf:	88 14 c5 45 61 11 80 	mov    %dl,-0x7fee9ebb(,%eax,8)
80106bd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bd9:	0f b6 14 c5 45 61 11 	movzbl -0x7fee9ebb(,%eax,8),%edx
80106be0:	80 
80106be1:	83 ca 80             	or     $0xffffff80,%edx
80106be4:	88 14 c5 45 61 11 80 	mov    %dl,-0x7fee9ebb(,%eax,8)
80106beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bee:	8b 04 85 9c c0 10 80 	mov    -0x7fef3f64(,%eax,4),%eax
80106bf5:	c1 e8 10             	shr    $0x10,%eax
80106bf8:	89 c2                	mov    %eax,%edx
80106bfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bfd:	66 89 14 c5 46 61 11 	mov    %dx,-0x7fee9eba(,%eax,8)
80106c04:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106c05:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c09:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106c10:	0f 8e 30 ff ff ff    	jle    80106b46 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106c16:	a1 9c c1 10 80       	mov    0x8010c19c,%eax
80106c1b:	66 a3 40 63 11 80    	mov    %ax,0x80116340
80106c21:	66 c7 05 42 63 11 80 	movw   $0x8,0x80116342
80106c28:	08 00 
80106c2a:	0f b6 05 44 63 11 80 	movzbl 0x80116344,%eax
80106c31:	83 e0 e0             	and    $0xffffffe0,%eax
80106c34:	a2 44 63 11 80       	mov    %al,0x80116344
80106c39:	0f b6 05 44 63 11 80 	movzbl 0x80116344,%eax
80106c40:	83 e0 1f             	and    $0x1f,%eax
80106c43:	a2 44 63 11 80       	mov    %al,0x80116344
80106c48:	0f b6 05 45 63 11 80 	movzbl 0x80116345,%eax
80106c4f:	83 c8 0f             	or     $0xf,%eax
80106c52:	a2 45 63 11 80       	mov    %al,0x80116345
80106c57:	0f b6 05 45 63 11 80 	movzbl 0x80116345,%eax
80106c5e:	83 e0 ef             	and    $0xffffffef,%eax
80106c61:	a2 45 63 11 80       	mov    %al,0x80116345
80106c66:	0f b6 05 45 63 11 80 	movzbl 0x80116345,%eax
80106c6d:	83 c8 60             	or     $0x60,%eax
80106c70:	a2 45 63 11 80       	mov    %al,0x80116345
80106c75:	0f b6 05 45 63 11 80 	movzbl 0x80116345,%eax
80106c7c:	83 c8 80             	or     $0xffffff80,%eax
80106c7f:	a2 45 63 11 80       	mov    %al,0x80116345
80106c84:	a1 9c c1 10 80       	mov    0x8010c19c,%eax
80106c89:	c1 e8 10             	shr    $0x10,%eax
80106c8c:	66 a3 46 63 11 80    	mov    %ax,0x80116346
  
  initlock(&tickslock, "time");
80106c92:	c7 44 24 04 20 8f 10 	movl   $0x80108f20,0x4(%esp)
80106c99:	80 
80106c9a:	c7 04 24 00 61 11 80 	movl   $0x80116100,(%esp)
80106ca1:	e8 c0 e7 ff ff       	call   80105466 <initlock>
}
80106ca6:	c9                   	leave  
80106ca7:	c3                   	ret    

80106ca8 <idtinit>:

void
idtinit(void)
{
80106ca8:	55                   	push   %ebp
80106ca9:	89 e5                	mov    %esp,%ebp
80106cab:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106cae:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106cb5:	00 
80106cb6:	c7 04 24 40 61 11 80 	movl   $0x80116140,(%esp)
80106cbd:	e8 38 fe ff ff       	call   80106afa <lidt>
}
80106cc2:	c9                   	leave  
80106cc3:	c3                   	ret    

80106cc4 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106cc4:	55                   	push   %ebp
80106cc5:	89 e5                	mov    %esp,%ebp
80106cc7:	57                   	push   %edi
80106cc8:	56                   	push   %esi
80106cc9:	53                   	push   %ebx
80106cca:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106ccd:	8b 45 08             	mov    0x8(%ebp),%eax
80106cd0:	8b 40 30             	mov    0x30(%eax),%eax
80106cd3:	83 f8 40             	cmp    $0x40,%eax
80106cd6:	75 3f                	jne    80106d17 <trap+0x53>
    if(proc->killed)
80106cd8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cde:	8b 40 24             	mov    0x24(%eax),%eax
80106ce1:	85 c0                	test   %eax,%eax
80106ce3:	74 05                	je     80106cea <trap+0x26>
      exit();
80106ce5:	e8 e7 e0 ff ff       	call   80104dd1 <exit>
    proc->tf = tf;
80106cea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cf0:	8b 55 08             	mov    0x8(%ebp),%edx
80106cf3:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106cf6:	e8 e9 ed ff ff       	call   80105ae4 <syscall>
    if(proc->killed)
80106cfb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d01:	8b 40 24             	mov    0x24(%eax),%eax
80106d04:	85 c0                	test   %eax,%eax
80106d06:	74 0a                	je     80106d12 <trap+0x4e>
      exit();
80106d08:	e8 c4 e0 ff ff       	call   80104dd1 <exit>
    return;
80106d0d:	e9 2d 02 00 00       	jmp    80106f3f <trap+0x27b>
80106d12:	e9 28 02 00 00       	jmp    80106f3f <trap+0x27b>
  }

  switch(tf->trapno){
80106d17:	8b 45 08             	mov    0x8(%ebp),%eax
80106d1a:	8b 40 30             	mov    0x30(%eax),%eax
80106d1d:	83 e8 20             	sub    $0x20,%eax
80106d20:	83 f8 1f             	cmp    $0x1f,%eax
80106d23:	0f 87 bc 00 00 00    	ja     80106de5 <trap+0x121>
80106d29:	8b 04 85 c8 8f 10 80 	mov    -0x7fef7038(,%eax,4),%eax
80106d30:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106d32:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106d38:	0f b6 00             	movzbl (%eax),%eax
80106d3b:	84 c0                	test   %al,%al
80106d3d:	75 31                	jne    80106d70 <trap+0xac>
      acquire(&tickslock);
80106d3f:	c7 04 24 00 61 11 80 	movl   $0x80116100,(%esp)
80106d46:	e8 3c e7 ff ff       	call   80105487 <acquire>
      ticks++;
80106d4b:	a1 40 69 11 80       	mov    0x80116940,%eax
80106d50:	83 c0 01             	add    $0x1,%eax
80106d53:	a3 40 69 11 80       	mov    %eax,0x80116940
      wakeup(&ticks);
80106d58:	c7 04 24 40 69 11 80 	movl   $0x80116940,(%esp)
80106d5f:	e8 32 e5 ff ff       	call   80105296 <wakeup>
      release(&tickslock);
80106d64:	c7 04 24 00 61 11 80 	movl   $0x80116100,(%esp)
80106d6b:	e8 79 e7 ff ff       	call   801054e9 <release>
    }
    lapiceoi();
80106d70:	e8 f4 c7 ff ff       	call   80103569 <lapiceoi>
    break;
80106d75:	e9 41 01 00 00       	jmp    80106ebb <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106d7a:	e8 f8 bf ff ff       	call   80102d77 <ideintr>
    lapiceoi();
80106d7f:	e8 e5 c7 ff ff       	call   80103569 <lapiceoi>
    break;
80106d84:	e9 32 01 00 00       	jmp    80106ebb <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106d89:	e8 aa c5 ff ff       	call   80103338 <kbdintr>
    lapiceoi();
80106d8e:	e8 d6 c7 ff ff       	call   80103569 <lapiceoi>
    break;
80106d93:	e9 23 01 00 00       	jmp    80106ebb <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106d98:	e8 97 03 00 00       	call   80107134 <uartintr>
    lapiceoi();
80106d9d:	e8 c7 c7 ff ff       	call   80103569 <lapiceoi>
    break;
80106da2:	e9 14 01 00 00       	jmp    80106ebb <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106da7:	8b 45 08             	mov    0x8(%ebp),%eax
80106daa:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106dad:	8b 45 08             	mov    0x8(%ebp),%eax
80106db0:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106db4:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106db7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106dbd:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106dc0:	0f b6 c0             	movzbl %al,%eax
80106dc3:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106dc7:	89 54 24 08          	mov    %edx,0x8(%esp)
80106dcb:	89 44 24 04          	mov    %eax,0x4(%esp)
80106dcf:	c7 04 24 28 8f 10 80 	movl   $0x80108f28,(%esp)
80106dd6:	e8 c5 95 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106ddb:	e8 89 c7 ff ff       	call   80103569 <lapiceoi>
    break;
80106de0:	e9 d6 00 00 00       	jmp    80106ebb <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106de5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106deb:	85 c0                	test   %eax,%eax
80106ded:	74 11                	je     80106e00 <trap+0x13c>
80106def:	8b 45 08             	mov    0x8(%ebp),%eax
80106df2:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106df6:	0f b7 c0             	movzwl %ax,%eax
80106df9:	83 e0 03             	and    $0x3,%eax
80106dfc:	85 c0                	test   %eax,%eax
80106dfe:	75 46                	jne    80106e46 <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106e00:	e8 1e fd ff ff       	call   80106b23 <rcr2>
80106e05:	8b 55 08             	mov    0x8(%ebp),%edx
80106e08:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106e0b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106e12:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106e15:	0f b6 ca             	movzbl %dl,%ecx
80106e18:	8b 55 08             	mov    0x8(%ebp),%edx
80106e1b:	8b 52 30             	mov    0x30(%edx),%edx
80106e1e:	89 44 24 10          	mov    %eax,0x10(%esp)
80106e22:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106e26:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106e2a:	89 54 24 04          	mov    %edx,0x4(%esp)
80106e2e:	c7 04 24 4c 8f 10 80 	movl   $0x80108f4c,(%esp)
80106e35:	e8 66 95 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106e3a:	c7 04 24 7e 8f 10 80 	movl   $0x80108f7e,(%esp)
80106e41:	e8 f4 96 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106e46:	e8 d8 fc ff ff       	call   80106b23 <rcr2>
80106e4b:	89 c2                	mov    %eax,%edx
80106e4d:	8b 45 08             	mov    0x8(%ebp),%eax
80106e50:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106e53:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106e59:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106e5c:	0f b6 f0             	movzbl %al,%esi
80106e5f:	8b 45 08             	mov    0x8(%ebp),%eax
80106e62:	8b 58 34             	mov    0x34(%eax),%ebx
80106e65:	8b 45 08             	mov    0x8(%ebp),%eax
80106e68:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106e6b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e71:	83 c0 6c             	add    $0x6c,%eax
80106e74:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106e77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106e7d:	8b 40 10             	mov    0x10(%eax),%eax
80106e80:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106e84:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106e88:	89 74 24 14          	mov    %esi,0x14(%esp)
80106e8c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106e90:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106e94:	8b 75 e4             	mov    -0x1c(%ebp),%esi
80106e97:	89 74 24 08          	mov    %esi,0x8(%esp)
80106e9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e9f:	c7 04 24 84 8f 10 80 	movl   $0x80108f84,(%esp)
80106ea6:	e8 f5 94 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106eab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106eb1:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106eb8:	eb 01                	jmp    80106ebb <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106eba:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106ebb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ec1:	85 c0                	test   %eax,%eax
80106ec3:	74 24                	je     80106ee9 <trap+0x225>
80106ec5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ecb:	8b 40 24             	mov    0x24(%eax),%eax
80106ece:	85 c0                	test   %eax,%eax
80106ed0:	74 17                	je     80106ee9 <trap+0x225>
80106ed2:	8b 45 08             	mov    0x8(%ebp),%eax
80106ed5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106ed9:	0f b7 c0             	movzwl %ax,%eax
80106edc:	83 e0 03             	and    $0x3,%eax
80106edf:	83 f8 03             	cmp    $0x3,%eax
80106ee2:	75 05                	jne    80106ee9 <trap+0x225>
    exit();
80106ee4:	e8 e8 de ff ff       	call   80104dd1 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106ee9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106eef:	85 c0                	test   %eax,%eax
80106ef1:	74 1e                	je     80106f11 <trap+0x24d>
80106ef3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ef9:	8b 40 0c             	mov    0xc(%eax),%eax
80106efc:	83 f8 04             	cmp    $0x4,%eax
80106eff:	75 10                	jne    80106f11 <trap+0x24d>
80106f01:	8b 45 08             	mov    0x8(%ebp),%eax
80106f04:	8b 40 30             	mov    0x30(%eax),%eax
80106f07:	83 f8 20             	cmp    $0x20,%eax
80106f0a:	75 05                	jne    80106f11 <trap+0x24d>
    yield();
80106f0c:	e8 3b e2 ff ff       	call   8010514c <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106f11:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106f17:	85 c0                	test   %eax,%eax
80106f19:	74 24                	je     80106f3f <trap+0x27b>
80106f1b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106f21:	8b 40 24             	mov    0x24(%eax),%eax
80106f24:	85 c0                	test   %eax,%eax
80106f26:	74 17                	je     80106f3f <trap+0x27b>
80106f28:	8b 45 08             	mov    0x8(%ebp),%eax
80106f2b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106f2f:	0f b7 c0             	movzwl %ax,%eax
80106f32:	83 e0 03             	and    $0x3,%eax
80106f35:	83 f8 03             	cmp    $0x3,%eax
80106f38:	75 05                	jne    80106f3f <trap+0x27b>
    exit();
80106f3a:	e8 92 de ff ff       	call   80104dd1 <exit>
}
80106f3f:	83 c4 3c             	add    $0x3c,%esp
80106f42:	5b                   	pop    %ebx
80106f43:	5e                   	pop    %esi
80106f44:	5f                   	pop    %edi
80106f45:	5d                   	pop    %ebp
80106f46:	c3                   	ret    

80106f47 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106f47:	55                   	push   %ebp
80106f48:	89 e5                	mov    %esp,%ebp
80106f4a:	83 ec 14             	sub    $0x14,%esp
80106f4d:	8b 45 08             	mov    0x8(%ebp),%eax
80106f50:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106f54:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80106f58:	89 c2                	mov    %eax,%edx
80106f5a:	ec                   	in     (%dx),%al
80106f5b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80106f5e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80106f62:	c9                   	leave  
80106f63:	c3                   	ret    

80106f64 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106f64:	55                   	push   %ebp
80106f65:	89 e5                	mov    %esp,%ebp
80106f67:	83 ec 08             	sub    $0x8,%esp
80106f6a:	8b 55 08             	mov    0x8(%ebp),%edx
80106f6d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f70:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106f74:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106f77:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106f7b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106f7f:	ee                   	out    %al,(%dx)
}
80106f80:	c9                   	leave  
80106f81:	c3                   	ret    

80106f82 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106f82:	55                   	push   %ebp
80106f83:	89 e5                	mov    %esp,%ebp
80106f85:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106f88:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106f8f:	00 
80106f90:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106f97:	e8 c8 ff ff ff       	call   80106f64 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106f9c:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106fa3:	00 
80106fa4:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106fab:	e8 b4 ff ff ff       	call   80106f64 <outb>
  outb(COM1+0, 115200/9600);
80106fb0:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106fb7:	00 
80106fb8:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106fbf:	e8 a0 ff ff ff       	call   80106f64 <outb>
  outb(COM1+1, 0);
80106fc4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106fcb:	00 
80106fcc:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106fd3:	e8 8c ff ff ff       	call   80106f64 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106fd8:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106fdf:	00 
80106fe0:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106fe7:	e8 78 ff ff ff       	call   80106f64 <outb>
  outb(COM1+4, 0);
80106fec:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106ff3:	00 
80106ff4:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106ffb:	e8 64 ff ff ff       	call   80106f64 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107000:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107007:	00 
80107008:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010700f:	e8 50 ff ff ff       	call   80106f64 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107014:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010701b:	e8 27 ff ff ff       	call   80106f47 <inb>
80107020:	3c ff                	cmp    $0xff,%al
80107022:	75 02                	jne    80107026 <uartinit+0xa4>
    return;
80107024:	eb 6a                	jmp    80107090 <uartinit+0x10e>
  uart = 1;
80107026:	c7 05 4c c6 10 80 01 	movl   $0x1,0x8010c64c
8010702d:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107030:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107037:	e8 0b ff ff ff       	call   80106f47 <inb>
  inb(COM1+0);
8010703c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107043:	e8 ff fe ff ff       	call   80106f47 <inb>
  picenable(IRQ_COM1);
80107048:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010704f:	e8 ea d3 ff ff       	call   8010443e <picenable>
  ioapicenable(IRQ_COM1, 0);
80107054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010705b:	00 
8010705c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107063:	e8 8e bf ff ff       	call   80102ff6 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107068:	c7 45 f4 48 90 10 80 	movl   $0x80109048,-0xc(%ebp)
8010706f:	eb 15                	jmp    80107086 <uartinit+0x104>
    uartputc(*p);
80107071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107074:	0f b6 00             	movzbl (%eax),%eax
80107077:	0f be c0             	movsbl %al,%eax
8010707a:	89 04 24             	mov    %eax,(%esp)
8010707d:	e8 10 00 00 00       	call   80107092 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107082:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107086:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107089:	0f b6 00             	movzbl (%eax),%eax
8010708c:	84 c0                	test   %al,%al
8010708e:	75 e1                	jne    80107071 <uartinit+0xef>
    uartputc(*p);
}
80107090:	c9                   	leave  
80107091:	c3                   	ret    

80107092 <uartputc>:

void
uartputc(int c)
{
80107092:	55                   	push   %ebp
80107093:	89 e5                	mov    %esp,%ebp
80107095:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107098:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
8010709d:	85 c0                	test   %eax,%eax
8010709f:	75 02                	jne    801070a3 <uartputc+0x11>
    return;
801070a1:	eb 4b                	jmp    801070ee <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801070a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801070aa:	eb 10                	jmp    801070bc <uartputc+0x2a>
    microdelay(10);
801070ac:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801070b3:	e8 d6 c4 ff ff       	call   8010358e <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801070b8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801070bc:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801070c0:	7f 16                	jg     801070d8 <uartputc+0x46>
801070c2:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801070c9:	e8 79 fe ff ff       	call   80106f47 <inb>
801070ce:	0f b6 c0             	movzbl %al,%eax
801070d1:	83 e0 20             	and    $0x20,%eax
801070d4:	85 c0                	test   %eax,%eax
801070d6:	74 d4                	je     801070ac <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
801070d8:	8b 45 08             	mov    0x8(%ebp),%eax
801070db:	0f b6 c0             	movzbl %al,%eax
801070de:	89 44 24 04          	mov    %eax,0x4(%esp)
801070e2:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801070e9:	e8 76 fe ff ff       	call   80106f64 <outb>
}
801070ee:	c9                   	leave  
801070ef:	c3                   	ret    

801070f0 <uartgetc>:

static int
uartgetc(void)
{
801070f0:	55                   	push   %ebp
801070f1:	89 e5                	mov    %esp,%ebp
801070f3:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801070f6:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
801070fb:	85 c0                	test   %eax,%eax
801070fd:	75 07                	jne    80107106 <uartgetc+0x16>
    return -1;
801070ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107104:	eb 2c                	jmp    80107132 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107106:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010710d:	e8 35 fe ff ff       	call   80106f47 <inb>
80107112:	0f b6 c0             	movzbl %al,%eax
80107115:	83 e0 01             	and    $0x1,%eax
80107118:	85 c0                	test   %eax,%eax
8010711a:	75 07                	jne    80107123 <uartgetc+0x33>
    return -1;
8010711c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107121:	eb 0f                	jmp    80107132 <uartgetc+0x42>
  return inb(COM1+0);
80107123:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010712a:	e8 18 fe ff ff       	call   80106f47 <inb>
8010712f:	0f b6 c0             	movzbl %al,%eax
}
80107132:	c9                   	leave  
80107133:	c3                   	ret    

80107134 <uartintr>:

void
uartintr(void)
{
80107134:	55                   	push   %ebp
80107135:	89 e5                	mov    %esp,%ebp
80107137:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
8010713a:	c7 04 24 f0 70 10 80 	movl   $0x801070f0,(%esp)
80107141:	e8 b0 99 ff ff       	call   80100af6 <consoleintr>
}
80107146:	c9                   	leave  
80107147:	c3                   	ret    

80107148 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107148:	6a 00                	push   $0x0
  pushl $0
8010714a:	6a 00                	push   $0x0
  jmp alltraps
8010714c:	e9 7e f9 ff ff       	jmp    80106acf <alltraps>

80107151 <vector1>:
.globl vector1
vector1:
  pushl $0
80107151:	6a 00                	push   $0x0
  pushl $1
80107153:	6a 01                	push   $0x1
  jmp alltraps
80107155:	e9 75 f9 ff ff       	jmp    80106acf <alltraps>

8010715a <vector2>:
.globl vector2
vector2:
  pushl $0
8010715a:	6a 00                	push   $0x0
  pushl $2
8010715c:	6a 02                	push   $0x2
  jmp alltraps
8010715e:	e9 6c f9 ff ff       	jmp    80106acf <alltraps>

80107163 <vector3>:
.globl vector3
vector3:
  pushl $0
80107163:	6a 00                	push   $0x0
  pushl $3
80107165:	6a 03                	push   $0x3
  jmp alltraps
80107167:	e9 63 f9 ff ff       	jmp    80106acf <alltraps>

8010716c <vector4>:
.globl vector4
vector4:
  pushl $0
8010716c:	6a 00                	push   $0x0
  pushl $4
8010716e:	6a 04                	push   $0x4
  jmp alltraps
80107170:	e9 5a f9 ff ff       	jmp    80106acf <alltraps>

80107175 <vector5>:
.globl vector5
vector5:
  pushl $0
80107175:	6a 00                	push   $0x0
  pushl $5
80107177:	6a 05                	push   $0x5
  jmp alltraps
80107179:	e9 51 f9 ff ff       	jmp    80106acf <alltraps>

8010717e <vector6>:
.globl vector6
vector6:
  pushl $0
8010717e:	6a 00                	push   $0x0
  pushl $6
80107180:	6a 06                	push   $0x6
  jmp alltraps
80107182:	e9 48 f9 ff ff       	jmp    80106acf <alltraps>

80107187 <vector7>:
.globl vector7
vector7:
  pushl $0
80107187:	6a 00                	push   $0x0
  pushl $7
80107189:	6a 07                	push   $0x7
  jmp alltraps
8010718b:	e9 3f f9 ff ff       	jmp    80106acf <alltraps>

80107190 <vector8>:
.globl vector8
vector8:
  pushl $8
80107190:	6a 08                	push   $0x8
  jmp alltraps
80107192:	e9 38 f9 ff ff       	jmp    80106acf <alltraps>

80107197 <vector9>:
.globl vector9
vector9:
  pushl $0
80107197:	6a 00                	push   $0x0
  pushl $9
80107199:	6a 09                	push   $0x9
  jmp alltraps
8010719b:	e9 2f f9 ff ff       	jmp    80106acf <alltraps>

801071a0 <vector10>:
.globl vector10
vector10:
  pushl $10
801071a0:	6a 0a                	push   $0xa
  jmp alltraps
801071a2:	e9 28 f9 ff ff       	jmp    80106acf <alltraps>

801071a7 <vector11>:
.globl vector11
vector11:
  pushl $11
801071a7:	6a 0b                	push   $0xb
  jmp alltraps
801071a9:	e9 21 f9 ff ff       	jmp    80106acf <alltraps>

801071ae <vector12>:
.globl vector12
vector12:
  pushl $12
801071ae:	6a 0c                	push   $0xc
  jmp alltraps
801071b0:	e9 1a f9 ff ff       	jmp    80106acf <alltraps>

801071b5 <vector13>:
.globl vector13
vector13:
  pushl $13
801071b5:	6a 0d                	push   $0xd
  jmp alltraps
801071b7:	e9 13 f9 ff ff       	jmp    80106acf <alltraps>

801071bc <vector14>:
.globl vector14
vector14:
  pushl $14
801071bc:	6a 0e                	push   $0xe
  jmp alltraps
801071be:	e9 0c f9 ff ff       	jmp    80106acf <alltraps>

801071c3 <vector15>:
.globl vector15
vector15:
  pushl $0
801071c3:	6a 00                	push   $0x0
  pushl $15
801071c5:	6a 0f                	push   $0xf
  jmp alltraps
801071c7:	e9 03 f9 ff ff       	jmp    80106acf <alltraps>

801071cc <vector16>:
.globl vector16
vector16:
  pushl $0
801071cc:	6a 00                	push   $0x0
  pushl $16
801071ce:	6a 10                	push   $0x10
  jmp alltraps
801071d0:	e9 fa f8 ff ff       	jmp    80106acf <alltraps>

801071d5 <vector17>:
.globl vector17
vector17:
  pushl $17
801071d5:	6a 11                	push   $0x11
  jmp alltraps
801071d7:	e9 f3 f8 ff ff       	jmp    80106acf <alltraps>

801071dc <vector18>:
.globl vector18
vector18:
  pushl $0
801071dc:	6a 00                	push   $0x0
  pushl $18
801071de:	6a 12                	push   $0x12
  jmp alltraps
801071e0:	e9 ea f8 ff ff       	jmp    80106acf <alltraps>

801071e5 <vector19>:
.globl vector19
vector19:
  pushl $0
801071e5:	6a 00                	push   $0x0
  pushl $19
801071e7:	6a 13                	push   $0x13
  jmp alltraps
801071e9:	e9 e1 f8 ff ff       	jmp    80106acf <alltraps>

801071ee <vector20>:
.globl vector20
vector20:
  pushl $0
801071ee:	6a 00                	push   $0x0
  pushl $20
801071f0:	6a 14                	push   $0x14
  jmp alltraps
801071f2:	e9 d8 f8 ff ff       	jmp    80106acf <alltraps>

801071f7 <vector21>:
.globl vector21
vector21:
  pushl $0
801071f7:	6a 00                	push   $0x0
  pushl $21
801071f9:	6a 15                	push   $0x15
  jmp alltraps
801071fb:	e9 cf f8 ff ff       	jmp    80106acf <alltraps>

80107200 <vector22>:
.globl vector22
vector22:
  pushl $0
80107200:	6a 00                	push   $0x0
  pushl $22
80107202:	6a 16                	push   $0x16
  jmp alltraps
80107204:	e9 c6 f8 ff ff       	jmp    80106acf <alltraps>

80107209 <vector23>:
.globl vector23
vector23:
  pushl $0
80107209:	6a 00                	push   $0x0
  pushl $23
8010720b:	6a 17                	push   $0x17
  jmp alltraps
8010720d:	e9 bd f8 ff ff       	jmp    80106acf <alltraps>

80107212 <vector24>:
.globl vector24
vector24:
  pushl $0
80107212:	6a 00                	push   $0x0
  pushl $24
80107214:	6a 18                	push   $0x18
  jmp alltraps
80107216:	e9 b4 f8 ff ff       	jmp    80106acf <alltraps>

8010721b <vector25>:
.globl vector25
vector25:
  pushl $0
8010721b:	6a 00                	push   $0x0
  pushl $25
8010721d:	6a 19                	push   $0x19
  jmp alltraps
8010721f:	e9 ab f8 ff ff       	jmp    80106acf <alltraps>

80107224 <vector26>:
.globl vector26
vector26:
  pushl $0
80107224:	6a 00                	push   $0x0
  pushl $26
80107226:	6a 1a                	push   $0x1a
  jmp alltraps
80107228:	e9 a2 f8 ff ff       	jmp    80106acf <alltraps>

8010722d <vector27>:
.globl vector27
vector27:
  pushl $0
8010722d:	6a 00                	push   $0x0
  pushl $27
8010722f:	6a 1b                	push   $0x1b
  jmp alltraps
80107231:	e9 99 f8 ff ff       	jmp    80106acf <alltraps>

80107236 <vector28>:
.globl vector28
vector28:
  pushl $0
80107236:	6a 00                	push   $0x0
  pushl $28
80107238:	6a 1c                	push   $0x1c
  jmp alltraps
8010723a:	e9 90 f8 ff ff       	jmp    80106acf <alltraps>

8010723f <vector29>:
.globl vector29
vector29:
  pushl $0
8010723f:	6a 00                	push   $0x0
  pushl $29
80107241:	6a 1d                	push   $0x1d
  jmp alltraps
80107243:	e9 87 f8 ff ff       	jmp    80106acf <alltraps>

80107248 <vector30>:
.globl vector30
vector30:
  pushl $0
80107248:	6a 00                	push   $0x0
  pushl $30
8010724a:	6a 1e                	push   $0x1e
  jmp alltraps
8010724c:	e9 7e f8 ff ff       	jmp    80106acf <alltraps>

80107251 <vector31>:
.globl vector31
vector31:
  pushl $0
80107251:	6a 00                	push   $0x0
  pushl $31
80107253:	6a 1f                	push   $0x1f
  jmp alltraps
80107255:	e9 75 f8 ff ff       	jmp    80106acf <alltraps>

8010725a <vector32>:
.globl vector32
vector32:
  pushl $0
8010725a:	6a 00                	push   $0x0
  pushl $32
8010725c:	6a 20                	push   $0x20
  jmp alltraps
8010725e:	e9 6c f8 ff ff       	jmp    80106acf <alltraps>

80107263 <vector33>:
.globl vector33
vector33:
  pushl $0
80107263:	6a 00                	push   $0x0
  pushl $33
80107265:	6a 21                	push   $0x21
  jmp alltraps
80107267:	e9 63 f8 ff ff       	jmp    80106acf <alltraps>

8010726c <vector34>:
.globl vector34
vector34:
  pushl $0
8010726c:	6a 00                	push   $0x0
  pushl $34
8010726e:	6a 22                	push   $0x22
  jmp alltraps
80107270:	e9 5a f8 ff ff       	jmp    80106acf <alltraps>

80107275 <vector35>:
.globl vector35
vector35:
  pushl $0
80107275:	6a 00                	push   $0x0
  pushl $35
80107277:	6a 23                	push   $0x23
  jmp alltraps
80107279:	e9 51 f8 ff ff       	jmp    80106acf <alltraps>

8010727e <vector36>:
.globl vector36
vector36:
  pushl $0
8010727e:	6a 00                	push   $0x0
  pushl $36
80107280:	6a 24                	push   $0x24
  jmp alltraps
80107282:	e9 48 f8 ff ff       	jmp    80106acf <alltraps>

80107287 <vector37>:
.globl vector37
vector37:
  pushl $0
80107287:	6a 00                	push   $0x0
  pushl $37
80107289:	6a 25                	push   $0x25
  jmp alltraps
8010728b:	e9 3f f8 ff ff       	jmp    80106acf <alltraps>

80107290 <vector38>:
.globl vector38
vector38:
  pushl $0
80107290:	6a 00                	push   $0x0
  pushl $38
80107292:	6a 26                	push   $0x26
  jmp alltraps
80107294:	e9 36 f8 ff ff       	jmp    80106acf <alltraps>

80107299 <vector39>:
.globl vector39
vector39:
  pushl $0
80107299:	6a 00                	push   $0x0
  pushl $39
8010729b:	6a 27                	push   $0x27
  jmp alltraps
8010729d:	e9 2d f8 ff ff       	jmp    80106acf <alltraps>

801072a2 <vector40>:
.globl vector40
vector40:
  pushl $0
801072a2:	6a 00                	push   $0x0
  pushl $40
801072a4:	6a 28                	push   $0x28
  jmp alltraps
801072a6:	e9 24 f8 ff ff       	jmp    80106acf <alltraps>

801072ab <vector41>:
.globl vector41
vector41:
  pushl $0
801072ab:	6a 00                	push   $0x0
  pushl $41
801072ad:	6a 29                	push   $0x29
  jmp alltraps
801072af:	e9 1b f8 ff ff       	jmp    80106acf <alltraps>

801072b4 <vector42>:
.globl vector42
vector42:
  pushl $0
801072b4:	6a 00                	push   $0x0
  pushl $42
801072b6:	6a 2a                	push   $0x2a
  jmp alltraps
801072b8:	e9 12 f8 ff ff       	jmp    80106acf <alltraps>

801072bd <vector43>:
.globl vector43
vector43:
  pushl $0
801072bd:	6a 00                	push   $0x0
  pushl $43
801072bf:	6a 2b                	push   $0x2b
  jmp alltraps
801072c1:	e9 09 f8 ff ff       	jmp    80106acf <alltraps>

801072c6 <vector44>:
.globl vector44
vector44:
  pushl $0
801072c6:	6a 00                	push   $0x0
  pushl $44
801072c8:	6a 2c                	push   $0x2c
  jmp alltraps
801072ca:	e9 00 f8 ff ff       	jmp    80106acf <alltraps>

801072cf <vector45>:
.globl vector45
vector45:
  pushl $0
801072cf:	6a 00                	push   $0x0
  pushl $45
801072d1:	6a 2d                	push   $0x2d
  jmp alltraps
801072d3:	e9 f7 f7 ff ff       	jmp    80106acf <alltraps>

801072d8 <vector46>:
.globl vector46
vector46:
  pushl $0
801072d8:	6a 00                	push   $0x0
  pushl $46
801072da:	6a 2e                	push   $0x2e
  jmp alltraps
801072dc:	e9 ee f7 ff ff       	jmp    80106acf <alltraps>

801072e1 <vector47>:
.globl vector47
vector47:
  pushl $0
801072e1:	6a 00                	push   $0x0
  pushl $47
801072e3:	6a 2f                	push   $0x2f
  jmp alltraps
801072e5:	e9 e5 f7 ff ff       	jmp    80106acf <alltraps>

801072ea <vector48>:
.globl vector48
vector48:
  pushl $0
801072ea:	6a 00                	push   $0x0
  pushl $48
801072ec:	6a 30                	push   $0x30
  jmp alltraps
801072ee:	e9 dc f7 ff ff       	jmp    80106acf <alltraps>

801072f3 <vector49>:
.globl vector49
vector49:
  pushl $0
801072f3:	6a 00                	push   $0x0
  pushl $49
801072f5:	6a 31                	push   $0x31
  jmp alltraps
801072f7:	e9 d3 f7 ff ff       	jmp    80106acf <alltraps>

801072fc <vector50>:
.globl vector50
vector50:
  pushl $0
801072fc:	6a 00                	push   $0x0
  pushl $50
801072fe:	6a 32                	push   $0x32
  jmp alltraps
80107300:	e9 ca f7 ff ff       	jmp    80106acf <alltraps>

80107305 <vector51>:
.globl vector51
vector51:
  pushl $0
80107305:	6a 00                	push   $0x0
  pushl $51
80107307:	6a 33                	push   $0x33
  jmp alltraps
80107309:	e9 c1 f7 ff ff       	jmp    80106acf <alltraps>

8010730e <vector52>:
.globl vector52
vector52:
  pushl $0
8010730e:	6a 00                	push   $0x0
  pushl $52
80107310:	6a 34                	push   $0x34
  jmp alltraps
80107312:	e9 b8 f7 ff ff       	jmp    80106acf <alltraps>

80107317 <vector53>:
.globl vector53
vector53:
  pushl $0
80107317:	6a 00                	push   $0x0
  pushl $53
80107319:	6a 35                	push   $0x35
  jmp alltraps
8010731b:	e9 af f7 ff ff       	jmp    80106acf <alltraps>

80107320 <vector54>:
.globl vector54
vector54:
  pushl $0
80107320:	6a 00                	push   $0x0
  pushl $54
80107322:	6a 36                	push   $0x36
  jmp alltraps
80107324:	e9 a6 f7 ff ff       	jmp    80106acf <alltraps>

80107329 <vector55>:
.globl vector55
vector55:
  pushl $0
80107329:	6a 00                	push   $0x0
  pushl $55
8010732b:	6a 37                	push   $0x37
  jmp alltraps
8010732d:	e9 9d f7 ff ff       	jmp    80106acf <alltraps>

80107332 <vector56>:
.globl vector56
vector56:
  pushl $0
80107332:	6a 00                	push   $0x0
  pushl $56
80107334:	6a 38                	push   $0x38
  jmp alltraps
80107336:	e9 94 f7 ff ff       	jmp    80106acf <alltraps>

8010733b <vector57>:
.globl vector57
vector57:
  pushl $0
8010733b:	6a 00                	push   $0x0
  pushl $57
8010733d:	6a 39                	push   $0x39
  jmp alltraps
8010733f:	e9 8b f7 ff ff       	jmp    80106acf <alltraps>

80107344 <vector58>:
.globl vector58
vector58:
  pushl $0
80107344:	6a 00                	push   $0x0
  pushl $58
80107346:	6a 3a                	push   $0x3a
  jmp alltraps
80107348:	e9 82 f7 ff ff       	jmp    80106acf <alltraps>

8010734d <vector59>:
.globl vector59
vector59:
  pushl $0
8010734d:	6a 00                	push   $0x0
  pushl $59
8010734f:	6a 3b                	push   $0x3b
  jmp alltraps
80107351:	e9 79 f7 ff ff       	jmp    80106acf <alltraps>

80107356 <vector60>:
.globl vector60
vector60:
  pushl $0
80107356:	6a 00                	push   $0x0
  pushl $60
80107358:	6a 3c                	push   $0x3c
  jmp alltraps
8010735a:	e9 70 f7 ff ff       	jmp    80106acf <alltraps>

8010735f <vector61>:
.globl vector61
vector61:
  pushl $0
8010735f:	6a 00                	push   $0x0
  pushl $61
80107361:	6a 3d                	push   $0x3d
  jmp alltraps
80107363:	e9 67 f7 ff ff       	jmp    80106acf <alltraps>

80107368 <vector62>:
.globl vector62
vector62:
  pushl $0
80107368:	6a 00                	push   $0x0
  pushl $62
8010736a:	6a 3e                	push   $0x3e
  jmp alltraps
8010736c:	e9 5e f7 ff ff       	jmp    80106acf <alltraps>

80107371 <vector63>:
.globl vector63
vector63:
  pushl $0
80107371:	6a 00                	push   $0x0
  pushl $63
80107373:	6a 3f                	push   $0x3f
  jmp alltraps
80107375:	e9 55 f7 ff ff       	jmp    80106acf <alltraps>

8010737a <vector64>:
.globl vector64
vector64:
  pushl $0
8010737a:	6a 00                	push   $0x0
  pushl $64
8010737c:	6a 40                	push   $0x40
  jmp alltraps
8010737e:	e9 4c f7 ff ff       	jmp    80106acf <alltraps>

80107383 <vector65>:
.globl vector65
vector65:
  pushl $0
80107383:	6a 00                	push   $0x0
  pushl $65
80107385:	6a 41                	push   $0x41
  jmp alltraps
80107387:	e9 43 f7 ff ff       	jmp    80106acf <alltraps>

8010738c <vector66>:
.globl vector66
vector66:
  pushl $0
8010738c:	6a 00                	push   $0x0
  pushl $66
8010738e:	6a 42                	push   $0x42
  jmp alltraps
80107390:	e9 3a f7 ff ff       	jmp    80106acf <alltraps>

80107395 <vector67>:
.globl vector67
vector67:
  pushl $0
80107395:	6a 00                	push   $0x0
  pushl $67
80107397:	6a 43                	push   $0x43
  jmp alltraps
80107399:	e9 31 f7 ff ff       	jmp    80106acf <alltraps>

8010739e <vector68>:
.globl vector68
vector68:
  pushl $0
8010739e:	6a 00                	push   $0x0
  pushl $68
801073a0:	6a 44                	push   $0x44
  jmp alltraps
801073a2:	e9 28 f7 ff ff       	jmp    80106acf <alltraps>

801073a7 <vector69>:
.globl vector69
vector69:
  pushl $0
801073a7:	6a 00                	push   $0x0
  pushl $69
801073a9:	6a 45                	push   $0x45
  jmp alltraps
801073ab:	e9 1f f7 ff ff       	jmp    80106acf <alltraps>

801073b0 <vector70>:
.globl vector70
vector70:
  pushl $0
801073b0:	6a 00                	push   $0x0
  pushl $70
801073b2:	6a 46                	push   $0x46
  jmp alltraps
801073b4:	e9 16 f7 ff ff       	jmp    80106acf <alltraps>

801073b9 <vector71>:
.globl vector71
vector71:
  pushl $0
801073b9:	6a 00                	push   $0x0
  pushl $71
801073bb:	6a 47                	push   $0x47
  jmp alltraps
801073bd:	e9 0d f7 ff ff       	jmp    80106acf <alltraps>

801073c2 <vector72>:
.globl vector72
vector72:
  pushl $0
801073c2:	6a 00                	push   $0x0
  pushl $72
801073c4:	6a 48                	push   $0x48
  jmp alltraps
801073c6:	e9 04 f7 ff ff       	jmp    80106acf <alltraps>

801073cb <vector73>:
.globl vector73
vector73:
  pushl $0
801073cb:	6a 00                	push   $0x0
  pushl $73
801073cd:	6a 49                	push   $0x49
  jmp alltraps
801073cf:	e9 fb f6 ff ff       	jmp    80106acf <alltraps>

801073d4 <vector74>:
.globl vector74
vector74:
  pushl $0
801073d4:	6a 00                	push   $0x0
  pushl $74
801073d6:	6a 4a                	push   $0x4a
  jmp alltraps
801073d8:	e9 f2 f6 ff ff       	jmp    80106acf <alltraps>

801073dd <vector75>:
.globl vector75
vector75:
  pushl $0
801073dd:	6a 00                	push   $0x0
  pushl $75
801073df:	6a 4b                	push   $0x4b
  jmp alltraps
801073e1:	e9 e9 f6 ff ff       	jmp    80106acf <alltraps>

801073e6 <vector76>:
.globl vector76
vector76:
  pushl $0
801073e6:	6a 00                	push   $0x0
  pushl $76
801073e8:	6a 4c                	push   $0x4c
  jmp alltraps
801073ea:	e9 e0 f6 ff ff       	jmp    80106acf <alltraps>

801073ef <vector77>:
.globl vector77
vector77:
  pushl $0
801073ef:	6a 00                	push   $0x0
  pushl $77
801073f1:	6a 4d                	push   $0x4d
  jmp alltraps
801073f3:	e9 d7 f6 ff ff       	jmp    80106acf <alltraps>

801073f8 <vector78>:
.globl vector78
vector78:
  pushl $0
801073f8:	6a 00                	push   $0x0
  pushl $78
801073fa:	6a 4e                	push   $0x4e
  jmp alltraps
801073fc:	e9 ce f6 ff ff       	jmp    80106acf <alltraps>

80107401 <vector79>:
.globl vector79
vector79:
  pushl $0
80107401:	6a 00                	push   $0x0
  pushl $79
80107403:	6a 4f                	push   $0x4f
  jmp alltraps
80107405:	e9 c5 f6 ff ff       	jmp    80106acf <alltraps>

8010740a <vector80>:
.globl vector80
vector80:
  pushl $0
8010740a:	6a 00                	push   $0x0
  pushl $80
8010740c:	6a 50                	push   $0x50
  jmp alltraps
8010740e:	e9 bc f6 ff ff       	jmp    80106acf <alltraps>

80107413 <vector81>:
.globl vector81
vector81:
  pushl $0
80107413:	6a 00                	push   $0x0
  pushl $81
80107415:	6a 51                	push   $0x51
  jmp alltraps
80107417:	e9 b3 f6 ff ff       	jmp    80106acf <alltraps>

8010741c <vector82>:
.globl vector82
vector82:
  pushl $0
8010741c:	6a 00                	push   $0x0
  pushl $82
8010741e:	6a 52                	push   $0x52
  jmp alltraps
80107420:	e9 aa f6 ff ff       	jmp    80106acf <alltraps>

80107425 <vector83>:
.globl vector83
vector83:
  pushl $0
80107425:	6a 00                	push   $0x0
  pushl $83
80107427:	6a 53                	push   $0x53
  jmp alltraps
80107429:	e9 a1 f6 ff ff       	jmp    80106acf <alltraps>

8010742e <vector84>:
.globl vector84
vector84:
  pushl $0
8010742e:	6a 00                	push   $0x0
  pushl $84
80107430:	6a 54                	push   $0x54
  jmp alltraps
80107432:	e9 98 f6 ff ff       	jmp    80106acf <alltraps>

80107437 <vector85>:
.globl vector85
vector85:
  pushl $0
80107437:	6a 00                	push   $0x0
  pushl $85
80107439:	6a 55                	push   $0x55
  jmp alltraps
8010743b:	e9 8f f6 ff ff       	jmp    80106acf <alltraps>

80107440 <vector86>:
.globl vector86
vector86:
  pushl $0
80107440:	6a 00                	push   $0x0
  pushl $86
80107442:	6a 56                	push   $0x56
  jmp alltraps
80107444:	e9 86 f6 ff ff       	jmp    80106acf <alltraps>

80107449 <vector87>:
.globl vector87
vector87:
  pushl $0
80107449:	6a 00                	push   $0x0
  pushl $87
8010744b:	6a 57                	push   $0x57
  jmp alltraps
8010744d:	e9 7d f6 ff ff       	jmp    80106acf <alltraps>

80107452 <vector88>:
.globl vector88
vector88:
  pushl $0
80107452:	6a 00                	push   $0x0
  pushl $88
80107454:	6a 58                	push   $0x58
  jmp alltraps
80107456:	e9 74 f6 ff ff       	jmp    80106acf <alltraps>

8010745b <vector89>:
.globl vector89
vector89:
  pushl $0
8010745b:	6a 00                	push   $0x0
  pushl $89
8010745d:	6a 59                	push   $0x59
  jmp alltraps
8010745f:	e9 6b f6 ff ff       	jmp    80106acf <alltraps>

80107464 <vector90>:
.globl vector90
vector90:
  pushl $0
80107464:	6a 00                	push   $0x0
  pushl $90
80107466:	6a 5a                	push   $0x5a
  jmp alltraps
80107468:	e9 62 f6 ff ff       	jmp    80106acf <alltraps>

8010746d <vector91>:
.globl vector91
vector91:
  pushl $0
8010746d:	6a 00                	push   $0x0
  pushl $91
8010746f:	6a 5b                	push   $0x5b
  jmp alltraps
80107471:	e9 59 f6 ff ff       	jmp    80106acf <alltraps>

80107476 <vector92>:
.globl vector92
vector92:
  pushl $0
80107476:	6a 00                	push   $0x0
  pushl $92
80107478:	6a 5c                	push   $0x5c
  jmp alltraps
8010747a:	e9 50 f6 ff ff       	jmp    80106acf <alltraps>

8010747f <vector93>:
.globl vector93
vector93:
  pushl $0
8010747f:	6a 00                	push   $0x0
  pushl $93
80107481:	6a 5d                	push   $0x5d
  jmp alltraps
80107483:	e9 47 f6 ff ff       	jmp    80106acf <alltraps>

80107488 <vector94>:
.globl vector94
vector94:
  pushl $0
80107488:	6a 00                	push   $0x0
  pushl $94
8010748a:	6a 5e                	push   $0x5e
  jmp alltraps
8010748c:	e9 3e f6 ff ff       	jmp    80106acf <alltraps>

80107491 <vector95>:
.globl vector95
vector95:
  pushl $0
80107491:	6a 00                	push   $0x0
  pushl $95
80107493:	6a 5f                	push   $0x5f
  jmp alltraps
80107495:	e9 35 f6 ff ff       	jmp    80106acf <alltraps>

8010749a <vector96>:
.globl vector96
vector96:
  pushl $0
8010749a:	6a 00                	push   $0x0
  pushl $96
8010749c:	6a 60                	push   $0x60
  jmp alltraps
8010749e:	e9 2c f6 ff ff       	jmp    80106acf <alltraps>

801074a3 <vector97>:
.globl vector97
vector97:
  pushl $0
801074a3:	6a 00                	push   $0x0
  pushl $97
801074a5:	6a 61                	push   $0x61
  jmp alltraps
801074a7:	e9 23 f6 ff ff       	jmp    80106acf <alltraps>

801074ac <vector98>:
.globl vector98
vector98:
  pushl $0
801074ac:	6a 00                	push   $0x0
  pushl $98
801074ae:	6a 62                	push   $0x62
  jmp alltraps
801074b0:	e9 1a f6 ff ff       	jmp    80106acf <alltraps>

801074b5 <vector99>:
.globl vector99
vector99:
  pushl $0
801074b5:	6a 00                	push   $0x0
  pushl $99
801074b7:	6a 63                	push   $0x63
  jmp alltraps
801074b9:	e9 11 f6 ff ff       	jmp    80106acf <alltraps>

801074be <vector100>:
.globl vector100
vector100:
  pushl $0
801074be:	6a 00                	push   $0x0
  pushl $100
801074c0:	6a 64                	push   $0x64
  jmp alltraps
801074c2:	e9 08 f6 ff ff       	jmp    80106acf <alltraps>

801074c7 <vector101>:
.globl vector101
vector101:
  pushl $0
801074c7:	6a 00                	push   $0x0
  pushl $101
801074c9:	6a 65                	push   $0x65
  jmp alltraps
801074cb:	e9 ff f5 ff ff       	jmp    80106acf <alltraps>

801074d0 <vector102>:
.globl vector102
vector102:
  pushl $0
801074d0:	6a 00                	push   $0x0
  pushl $102
801074d2:	6a 66                	push   $0x66
  jmp alltraps
801074d4:	e9 f6 f5 ff ff       	jmp    80106acf <alltraps>

801074d9 <vector103>:
.globl vector103
vector103:
  pushl $0
801074d9:	6a 00                	push   $0x0
  pushl $103
801074db:	6a 67                	push   $0x67
  jmp alltraps
801074dd:	e9 ed f5 ff ff       	jmp    80106acf <alltraps>

801074e2 <vector104>:
.globl vector104
vector104:
  pushl $0
801074e2:	6a 00                	push   $0x0
  pushl $104
801074e4:	6a 68                	push   $0x68
  jmp alltraps
801074e6:	e9 e4 f5 ff ff       	jmp    80106acf <alltraps>

801074eb <vector105>:
.globl vector105
vector105:
  pushl $0
801074eb:	6a 00                	push   $0x0
  pushl $105
801074ed:	6a 69                	push   $0x69
  jmp alltraps
801074ef:	e9 db f5 ff ff       	jmp    80106acf <alltraps>

801074f4 <vector106>:
.globl vector106
vector106:
  pushl $0
801074f4:	6a 00                	push   $0x0
  pushl $106
801074f6:	6a 6a                	push   $0x6a
  jmp alltraps
801074f8:	e9 d2 f5 ff ff       	jmp    80106acf <alltraps>

801074fd <vector107>:
.globl vector107
vector107:
  pushl $0
801074fd:	6a 00                	push   $0x0
  pushl $107
801074ff:	6a 6b                	push   $0x6b
  jmp alltraps
80107501:	e9 c9 f5 ff ff       	jmp    80106acf <alltraps>

80107506 <vector108>:
.globl vector108
vector108:
  pushl $0
80107506:	6a 00                	push   $0x0
  pushl $108
80107508:	6a 6c                	push   $0x6c
  jmp alltraps
8010750a:	e9 c0 f5 ff ff       	jmp    80106acf <alltraps>

8010750f <vector109>:
.globl vector109
vector109:
  pushl $0
8010750f:	6a 00                	push   $0x0
  pushl $109
80107511:	6a 6d                	push   $0x6d
  jmp alltraps
80107513:	e9 b7 f5 ff ff       	jmp    80106acf <alltraps>

80107518 <vector110>:
.globl vector110
vector110:
  pushl $0
80107518:	6a 00                	push   $0x0
  pushl $110
8010751a:	6a 6e                	push   $0x6e
  jmp alltraps
8010751c:	e9 ae f5 ff ff       	jmp    80106acf <alltraps>

80107521 <vector111>:
.globl vector111
vector111:
  pushl $0
80107521:	6a 00                	push   $0x0
  pushl $111
80107523:	6a 6f                	push   $0x6f
  jmp alltraps
80107525:	e9 a5 f5 ff ff       	jmp    80106acf <alltraps>

8010752a <vector112>:
.globl vector112
vector112:
  pushl $0
8010752a:	6a 00                	push   $0x0
  pushl $112
8010752c:	6a 70                	push   $0x70
  jmp alltraps
8010752e:	e9 9c f5 ff ff       	jmp    80106acf <alltraps>

80107533 <vector113>:
.globl vector113
vector113:
  pushl $0
80107533:	6a 00                	push   $0x0
  pushl $113
80107535:	6a 71                	push   $0x71
  jmp alltraps
80107537:	e9 93 f5 ff ff       	jmp    80106acf <alltraps>

8010753c <vector114>:
.globl vector114
vector114:
  pushl $0
8010753c:	6a 00                	push   $0x0
  pushl $114
8010753e:	6a 72                	push   $0x72
  jmp alltraps
80107540:	e9 8a f5 ff ff       	jmp    80106acf <alltraps>

80107545 <vector115>:
.globl vector115
vector115:
  pushl $0
80107545:	6a 00                	push   $0x0
  pushl $115
80107547:	6a 73                	push   $0x73
  jmp alltraps
80107549:	e9 81 f5 ff ff       	jmp    80106acf <alltraps>

8010754e <vector116>:
.globl vector116
vector116:
  pushl $0
8010754e:	6a 00                	push   $0x0
  pushl $116
80107550:	6a 74                	push   $0x74
  jmp alltraps
80107552:	e9 78 f5 ff ff       	jmp    80106acf <alltraps>

80107557 <vector117>:
.globl vector117
vector117:
  pushl $0
80107557:	6a 00                	push   $0x0
  pushl $117
80107559:	6a 75                	push   $0x75
  jmp alltraps
8010755b:	e9 6f f5 ff ff       	jmp    80106acf <alltraps>

80107560 <vector118>:
.globl vector118
vector118:
  pushl $0
80107560:	6a 00                	push   $0x0
  pushl $118
80107562:	6a 76                	push   $0x76
  jmp alltraps
80107564:	e9 66 f5 ff ff       	jmp    80106acf <alltraps>

80107569 <vector119>:
.globl vector119
vector119:
  pushl $0
80107569:	6a 00                	push   $0x0
  pushl $119
8010756b:	6a 77                	push   $0x77
  jmp alltraps
8010756d:	e9 5d f5 ff ff       	jmp    80106acf <alltraps>

80107572 <vector120>:
.globl vector120
vector120:
  pushl $0
80107572:	6a 00                	push   $0x0
  pushl $120
80107574:	6a 78                	push   $0x78
  jmp alltraps
80107576:	e9 54 f5 ff ff       	jmp    80106acf <alltraps>

8010757b <vector121>:
.globl vector121
vector121:
  pushl $0
8010757b:	6a 00                	push   $0x0
  pushl $121
8010757d:	6a 79                	push   $0x79
  jmp alltraps
8010757f:	e9 4b f5 ff ff       	jmp    80106acf <alltraps>

80107584 <vector122>:
.globl vector122
vector122:
  pushl $0
80107584:	6a 00                	push   $0x0
  pushl $122
80107586:	6a 7a                	push   $0x7a
  jmp alltraps
80107588:	e9 42 f5 ff ff       	jmp    80106acf <alltraps>

8010758d <vector123>:
.globl vector123
vector123:
  pushl $0
8010758d:	6a 00                	push   $0x0
  pushl $123
8010758f:	6a 7b                	push   $0x7b
  jmp alltraps
80107591:	e9 39 f5 ff ff       	jmp    80106acf <alltraps>

80107596 <vector124>:
.globl vector124
vector124:
  pushl $0
80107596:	6a 00                	push   $0x0
  pushl $124
80107598:	6a 7c                	push   $0x7c
  jmp alltraps
8010759a:	e9 30 f5 ff ff       	jmp    80106acf <alltraps>

8010759f <vector125>:
.globl vector125
vector125:
  pushl $0
8010759f:	6a 00                	push   $0x0
  pushl $125
801075a1:	6a 7d                	push   $0x7d
  jmp alltraps
801075a3:	e9 27 f5 ff ff       	jmp    80106acf <alltraps>

801075a8 <vector126>:
.globl vector126
vector126:
  pushl $0
801075a8:	6a 00                	push   $0x0
  pushl $126
801075aa:	6a 7e                	push   $0x7e
  jmp alltraps
801075ac:	e9 1e f5 ff ff       	jmp    80106acf <alltraps>

801075b1 <vector127>:
.globl vector127
vector127:
  pushl $0
801075b1:	6a 00                	push   $0x0
  pushl $127
801075b3:	6a 7f                	push   $0x7f
  jmp alltraps
801075b5:	e9 15 f5 ff ff       	jmp    80106acf <alltraps>

801075ba <vector128>:
.globl vector128
vector128:
  pushl $0
801075ba:	6a 00                	push   $0x0
  pushl $128
801075bc:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801075c1:	e9 09 f5 ff ff       	jmp    80106acf <alltraps>

801075c6 <vector129>:
.globl vector129
vector129:
  pushl $0
801075c6:	6a 00                	push   $0x0
  pushl $129
801075c8:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801075cd:	e9 fd f4 ff ff       	jmp    80106acf <alltraps>

801075d2 <vector130>:
.globl vector130
vector130:
  pushl $0
801075d2:	6a 00                	push   $0x0
  pushl $130
801075d4:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801075d9:	e9 f1 f4 ff ff       	jmp    80106acf <alltraps>

801075de <vector131>:
.globl vector131
vector131:
  pushl $0
801075de:	6a 00                	push   $0x0
  pushl $131
801075e0:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801075e5:	e9 e5 f4 ff ff       	jmp    80106acf <alltraps>

801075ea <vector132>:
.globl vector132
vector132:
  pushl $0
801075ea:	6a 00                	push   $0x0
  pushl $132
801075ec:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801075f1:	e9 d9 f4 ff ff       	jmp    80106acf <alltraps>

801075f6 <vector133>:
.globl vector133
vector133:
  pushl $0
801075f6:	6a 00                	push   $0x0
  pushl $133
801075f8:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801075fd:	e9 cd f4 ff ff       	jmp    80106acf <alltraps>

80107602 <vector134>:
.globl vector134
vector134:
  pushl $0
80107602:	6a 00                	push   $0x0
  pushl $134
80107604:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107609:	e9 c1 f4 ff ff       	jmp    80106acf <alltraps>

8010760e <vector135>:
.globl vector135
vector135:
  pushl $0
8010760e:	6a 00                	push   $0x0
  pushl $135
80107610:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107615:	e9 b5 f4 ff ff       	jmp    80106acf <alltraps>

8010761a <vector136>:
.globl vector136
vector136:
  pushl $0
8010761a:	6a 00                	push   $0x0
  pushl $136
8010761c:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107621:	e9 a9 f4 ff ff       	jmp    80106acf <alltraps>

80107626 <vector137>:
.globl vector137
vector137:
  pushl $0
80107626:	6a 00                	push   $0x0
  pushl $137
80107628:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010762d:	e9 9d f4 ff ff       	jmp    80106acf <alltraps>

80107632 <vector138>:
.globl vector138
vector138:
  pushl $0
80107632:	6a 00                	push   $0x0
  pushl $138
80107634:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107639:	e9 91 f4 ff ff       	jmp    80106acf <alltraps>

8010763e <vector139>:
.globl vector139
vector139:
  pushl $0
8010763e:	6a 00                	push   $0x0
  pushl $139
80107640:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107645:	e9 85 f4 ff ff       	jmp    80106acf <alltraps>

8010764a <vector140>:
.globl vector140
vector140:
  pushl $0
8010764a:	6a 00                	push   $0x0
  pushl $140
8010764c:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107651:	e9 79 f4 ff ff       	jmp    80106acf <alltraps>

80107656 <vector141>:
.globl vector141
vector141:
  pushl $0
80107656:	6a 00                	push   $0x0
  pushl $141
80107658:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010765d:	e9 6d f4 ff ff       	jmp    80106acf <alltraps>

80107662 <vector142>:
.globl vector142
vector142:
  pushl $0
80107662:	6a 00                	push   $0x0
  pushl $142
80107664:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107669:	e9 61 f4 ff ff       	jmp    80106acf <alltraps>

8010766e <vector143>:
.globl vector143
vector143:
  pushl $0
8010766e:	6a 00                	push   $0x0
  pushl $143
80107670:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107675:	e9 55 f4 ff ff       	jmp    80106acf <alltraps>

8010767a <vector144>:
.globl vector144
vector144:
  pushl $0
8010767a:	6a 00                	push   $0x0
  pushl $144
8010767c:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107681:	e9 49 f4 ff ff       	jmp    80106acf <alltraps>

80107686 <vector145>:
.globl vector145
vector145:
  pushl $0
80107686:	6a 00                	push   $0x0
  pushl $145
80107688:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010768d:	e9 3d f4 ff ff       	jmp    80106acf <alltraps>

80107692 <vector146>:
.globl vector146
vector146:
  pushl $0
80107692:	6a 00                	push   $0x0
  pushl $146
80107694:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107699:	e9 31 f4 ff ff       	jmp    80106acf <alltraps>

8010769e <vector147>:
.globl vector147
vector147:
  pushl $0
8010769e:	6a 00                	push   $0x0
  pushl $147
801076a0:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801076a5:	e9 25 f4 ff ff       	jmp    80106acf <alltraps>

801076aa <vector148>:
.globl vector148
vector148:
  pushl $0
801076aa:	6a 00                	push   $0x0
  pushl $148
801076ac:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801076b1:	e9 19 f4 ff ff       	jmp    80106acf <alltraps>

801076b6 <vector149>:
.globl vector149
vector149:
  pushl $0
801076b6:	6a 00                	push   $0x0
  pushl $149
801076b8:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801076bd:	e9 0d f4 ff ff       	jmp    80106acf <alltraps>

801076c2 <vector150>:
.globl vector150
vector150:
  pushl $0
801076c2:	6a 00                	push   $0x0
  pushl $150
801076c4:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801076c9:	e9 01 f4 ff ff       	jmp    80106acf <alltraps>

801076ce <vector151>:
.globl vector151
vector151:
  pushl $0
801076ce:	6a 00                	push   $0x0
  pushl $151
801076d0:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801076d5:	e9 f5 f3 ff ff       	jmp    80106acf <alltraps>

801076da <vector152>:
.globl vector152
vector152:
  pushl $0
801076da:	6a 00                	push   $0x0
  pushl $152
801076dc:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801076e1:	e9 e9 f3 ff ff       	jmp    80106acf <alltraps>

801076e6 <vector153>:
.globl vector153
vector153:
  pushl $0
801076e6:	6a 00                	push   $0x0
  pushl $153
801076e8:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801076ed:	e9 dd f3 ff ff       	jmp    80106acf <alltraps>

801076f2 <vector154>:
.globl vector154
vector154:
  pushl $0
801076f2:	6a 00                	push   $0x0
  pushl $154
801076f4:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801076f9:	e9 d1 f3 ff ff       	jmp    80106acf <alltraps>

801076fe <vector155>:
.globl vector155
vector155:
  pushl $0
801076fe:	6a 00                	push   $0x0
  pushl $155
80107700:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107705:	e9 c5 f3 ff ff       	jmp    80106acf <alltraps>

8010770a <vector156>:
.globl vector156
vector156:
  pushl $0
8010770a:	6a 00                	push   $0x0
  pushl $156
8010770c:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107711:	e9 b9 f3 ff ff       	jmp    80106acf <alltraps>

80107716 <vector157>:
.globl vector157
vector157:
  pushl $0
80107716:	6a 00                	push   $0x0
  pushl $157
80107718:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010771d:	e9 ad f3 ff ff       	jmp    80106acf <alltraps>

80107722 <vector158>:
.globl vector158
vector158:
  pushl $0
80107722:	6a 00                	push   $0x0
  pushl $158
80107724:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107729:	e9 a1 f3 ff ff       	jmp    80106acf <alltraps>

8010772e <vector159>:
.globl vector159
vector159:
  pushl $0
8010772e:	6a 00                	push   $0x0
  pushl $159
80107730:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107735:	e9 95 f3 ff ff       	jmp    80106acf <alltraps>

8010773a <vector160>:
.globl vector160
vector160:
  pushl $0
8010773a:	6a 00                	push   $0x0
  pushl $160
8010773c:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107741:	e9 89 f3 ff ff       	jmp    80106acf <alltraps>

80107746 <vector161>:
.globl vector161
vector161:
  pushl $0
80107746:	6a 00                	push   $0x0
  pushl $161
80107748:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010774d:	e9 7d f3 ff ff       	jmp    80106acf <alltraps>

80107752 <vector162>:
.globl vector162
vector162:
  pushl $0
80107752:	6a 00                	push   $0x0
  pushl $162
80107754:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107759:	e9 71 f3 ff ff       	jmp    80106acf <alltraps>

8010775e <vector163>:
.globl vector163
vector163:
  pushl $0
8010775e:	6a 00                	push   $0x0
  pushl $163
80107760:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107765:	e9 65 f3 ff ff       	jmp    80106acf <alltraps>

8010776a <vector164>:
.globl vector164
vector164:
  pushl $0
8010776a:	6a 00                	push   $0x0
  pushl $164
8010776c:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107771:	e9 59 f3 ff ff       	jmp    80106acf <alltraps>

80107776 <vector165>:
.globl vector165
vector165:
  pushl $0
80107776:	6a 00                	push   $0x0
  pushl $165
80107778:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010777d:	e9 4d f3 ff ff       	jmp    80106acf <alltraps>

80107782 <vector166>:
.globl vector166
vector166:
  pushl $0
80107782:	6a 00                	push   $0x0
  pushl $166
80107784:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107789:	e9 41 f3 ff ff       	jmp    80106acf <alltraps>

8010778e <vector167>:
.globl vector167
vector167:
  pushl $0
8010778e:	6a 00                	push   $0x0
  pushl $167
80107790:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107795:	e9 35 f3 ff ff       	jmp    80106acf <alltraps>

8010779a <vector168>:
.globl vector168
vector168:
  pushl $0
8010779a:	6a 00                	push   $0x0
  pushl $168
8010779c:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801077a1:	e9 29 f3 ff ff       	jmp    80106acf <alltraps>

801077a6 <vector169>:
.globl vector169
vector169:
  pushl $0
801077a6:	6a 00                	push   $0x0
  pushl $169
801077a8:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801077ad:	e9 1d f3 ff ff       	jmp    80106acf <alltraps>

801077b2 <vector170>:
.globl vector170
vector170:
  pushl $0
801077b2:	6a 00                	push   $0x0
  pushl $170
801077b4:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801077b9:	e9 11 f3 ff ff       	jmp    80106acf <alltraps>

801077be <vector171>:
.globl vector171
vector171:
  pushl $0
801077be:	6a 00                	push   $0x0
  pushl $171
801077c0:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801077c5:	e9 05 f3 ff ff       	jmp    80106acf <alltraps>

801077ca <vector172>:
.globl vector172
vector172:
  pushl $0
801077ca:	6a 00                	push   $0x0
  pushl $172
801077cc:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801077d1:	e9 f9 f2 ff ff       	jmp    80106acf <alltraps>

801077d6 <vector173>:
.globl vector173
vector173:
  pushl $0
801077d6:	6a 00                	push   $0x0
  pushl $173
801077d8:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801077dd:	e9 ed f2 ff ff       	jmp    80106acf <alltraps>

801077e2 <vector174>:
.globl vector174
vector174:
  pushl $0
801077e2:	6a 00                	push   $0x0
  pushl $174
801077e4:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801077e9:	e9 e1 f2 ff ff       	jmp    80106acf <alltraps>

801077ee <vector175>:
.globl vector175
vector175:
  pushl $0
801077ee:	6a 00                	push   $0x0
  pushl $175
801077f0:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801077f5:	e9 d5 f2 ff ff       	jmp    80106acf <alltraps>

801077fa <vector176>:
.globl vector176
vector176:
  pushl $0
801077fa:	6a 00                	push   $0x0
  pushl $176
801077fc:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107801:	e9 c9 f2 ff ff       	jmp    80106acf <alltraps>

80107806 <vector177>:
.globl vector177
vector177:
  pushl $0
80107806:	6a 00                	push   $0x0
  pushl $177
80107808:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010780d:	e9 bd f2 ff ff       	jmp    80106acf <alltraps>

80107812 <vector178>:
.globl vector178
vector178:
  pushl $0
80107812:	6a 00                	push   $0x0
  pushl $178
80107814:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107819:	e9 b1 f2 ff ff       	jmp    80106acf <alltraps>

8010781e <vector179>:
.globl vector179
vector179:
  pushl $0
8010781e:	6a 00                	push   $0x0
  pushl $179
80107820:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107825:	e9 a5 f2 ff ff       	jmp    80106acf <alltraps>

8010782a <vector180>:
.globl vector180
vector180:
  pushl $0
8010782a:	6a 00                	push   $0x0
  pushl $180
8010782c:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107831:	e9 99 f2 ff ff       	jmp    80106acf <alltraps>

80107836 <vector181>:
.globl vector181
vector181:
  pushl $0
80107836:	6a 00                	push   $0x0
  pushl $181
80107838:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010783d:	e9 8d f2 ff ff       	jmp    80106acf <alltraps>

80107842 <vector182>:
.globl vector182
vector182:
  pushl $0
80107842:	6a 00                	push   $0x0
  pushl $182
80107844:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107849:	e9 81 f2 ff ff       	jmp    80106acf <alltraps>

8010784e <vector183>:
.globl vector183
vector183:
  pushl $0
8010784e:	6a 00                	push   $0x0
  pushl $183
80107850:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107855:	e9 75 f2 ff ff       	jmp    80106acf <alltraps>

8010785a <vector184>:
.globl vector184
vector184:
  pushl $0
8010785a:	6a 00                	push   $0x0
  pushl $184
8010785c:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107861:	e9 69 f2 ff ff       	jmp    80106acf <alltraps>

80107866 <vector185>:
.globl vector185
vector185:
  pushl $0
80107866:	6a 00                	push   $0x0
  pushl $185
80107868:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
8010786d:	e9 5d f2 ff ff       	jmp    80106acf <alltraps>

80107872 <vector186>:
.globl vector186
vector186:
  pushl $0
80107872:	6a 00                	push   $0x0
  pushl $186
80107874:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107879:	e9 51 f2 ff ff       	jmp    80106acf <alltraps>

8010787e <vector187>:
.globl vector187
vector187:
  pushl $0
8010787e:	6a 00                	push   $0x0
  pushl $187
80107880:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107885:	e9 45 f2 ff ff       	jmp    80106acf <alltraps>

8010788a <vector188>:
.globl vector188
vector188:
  pushl $0
8010788a:	6a 00                	push   $0x0
  pushl $188
8010788c:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107891:	e9 39 f2 ff ff       	jmp    80106acf <alltraps>

80107896 <vector189>:
.globl vector189
vector189:
  pushl $0
80107896:	6a 00                	push   $0x0
  pushl $189
80107898:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
8010789d:	e9 2d f2 ff ff       	jmp    80106acf <alltraps>

801078a2 <vector190>:
.globl vector190
vector190:
  pushl $0
801078a2:	6a 00                	push   $0x0
  pushl $190
801078a4:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801078a9:	e9 21 f2 ff ff       	jmp    80106acf <alltraps>

801078ae <vector191>:
.globl vector191
vector191:
  pushl $0
801078ae:	6a 00                	push   $0x0
  pushl $191
801078b0:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801078b5:	e9 15 f2 ff ff       	jmp    80106acf <alltraps>

801078ba <vector192>:
.globl vector192
vector192:
  pushl $0
801078ba:	6a 00                	push   $0x0
  pushl $192
801078bc:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801078c1:	e9 09 f2 ff ff       	jmp    80106acf <alltraps>

801078c6 <vector193>:
.globl vector193
vector193:
  pushl $0
801078c6:	6a 00                	push   $0x0
  pushl $193
801078c8:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801078cd:	e9 fd f1 ff ff       	jmp    80106acf <alltraps>

801078d2 <vector194>:
.globl vector194
vector194:
  pushl $0
801078d2:	6a 00                	push   $0x0
  pushl $194
801078d4:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801078d9:	e9 f1 f1 ff ff       	jmp    80106acf <alltraps>

801078de <vector195>:
.globl vector195
vector195:
  pushl $0
801078de:	6a 00                	push   $0x0
  pushl $195
801078e0:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801078e5:	e9 e5 f1 ff ff       	jmp    80106acf <alltraps>

801078ea <vector196>:
.globl vector196
vector196:
  pushl $0
801078ea:	6a 00                	push   $0x0
  pushl $196
801078ec:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801078f1:	e9 d9 f1 ff ff       	jmp    80106acf <alltraps>

801078f6 <vector197>:
.globl vector197
vector197:
  pushl $0
801078f6:	6a 00                	push   $0x0
  pushl $197
801078f8:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801078fd:	e9 cd f1 ff ff       	jmp    80106acf <alltraps>

80107902 <vector198>:
.globl vector198
vector198:
  pushl $0
80107902:	6a 00                	push   $0x0
  pushl $198
80107904:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107909:	e9 c1 f1 ff ff       	jmp    80106acf <alltraps>

8010790e <vector199>:
.globl vector199
vector199:
  pushl $0
8010790e:	6a 00                	push   $0x0
  pushl $199
80107910:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107915:	e9 b5 f1 ff ff       	jmp    80106acf <alltraps>

8010791a <vector200>:
.globl vector200
vector200:
  pushl $0
8010791a:	6a 00                	push   $0x0
  pushl $200
8010791c:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107921:	e9 a9 f1 ff ff       	jmp    80106acf <alltraps>

80107926 <vector201>:
.globl vector201
vector201:
  pushl $0
80107926:	6a 00                	push   $0x0
  pushl $201
80107928:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
8010792d:	e9 9d f1 ff ff       	jmp    80106acf <alltraps>

80107932 <vector202>:
.globl vector202
vector202:
  pushl $0
80107932:	6a 00                	push   $0x0
  pushl $202
80107934:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107939:	e9 91 f1 ff ff       	jmp    80106acf <alltraps>

8010793e <vector203>:
.globl vector203
vector203:
  pushl $0
8010793e:	6a 00                	push   $0x0
  pushl $203
80107940:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107945:	e9 85 f1 ff ff       	jmp    80106acf <alltraps>

8010794a <vector204>:
.globl vector204
vector204:
  pushl $0
8010794a:	6a 00                	push   $0x0
  pushl $204
8010794c:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107951:	e9 79 f1 ff ff       	jmp    80106acf <alltraps>

80107956 <vector205>:
.globl vector205
vector205:
  pushl $0
80107956:	6a 00                	push   $0x0
  pushl $205
80107958:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
8010795d:	e9 6d f1 ff ff       	jmp    80106acf <alltraps>

80107962 <vector206>:
.globl vector206
vector206:
  pushl $0
80107962:	6a 00                	push   $0x0
  pushl $206
80107964:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107969:	e9 61 f1 ff ff       	jmp    80106acf <alltraps>

8010796e <vector207>:
.globl vector207
vector207:
  pushl $0
8010796e:	6a 00                	push   $0x0
  pushl $207
80107970:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107975:	e9 55 f1 ff ff       	jmp    80106acf <alltraps>

8010797a <vector208>:
.globl vector208
vector208:
  pushl $0
8010797a:	6a 00                	push   $0x0
  pushl $208
8010797c:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107981:	e9 49 f1 ff ff       	jmp    80106acf <alltraps>

80107986 <vector209>:
.globl vector209
vector209:
  pushl $0
80107986:	6a 00                	push   $0x0
  pushl $209
80107988:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
8010798d:	e9 3d f1 ff ff       	jmp    80106acf <alltraps>

80107992 <vector210>:
.globl vector210
vector210:
  pushl $0
80107992:	6a 00                	push   $0x0
  pushl $210
80107994:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107999:	e9 31 f1 ff ff       	jmp    80106acf <alltraps>

8010799e <vector211>:
.globl vector211
vector211:
  pushl $0
8010799e:	6a 00                	push   $0x0
  pushl $211
801079a0:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801079a5:	e9 25 f1 ff ff       	jmp    80106acf <alltraps>

801079aa <vector212>:
.globl vector212
vector212:
  pushl $0
801079aa:	6a 00                	push   $0x0
  pushl $212
801079ac:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801079b1:	e9 19 f1 ff ff       	jmp    80106acf <alltraps>

801079b6 <vector213>:
.globl vector213
vector213:
  pushl $0
801079b6:	6a 00                	push   $0x0
  pushl $213
801079b8:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801079bd:	e9 0d f1 ff ff       	jmp    80106acf <alltraps>

801079c2 <vector214>:
.globl vector214
vector214:
  pushl $0
801079c2:	6a 00                	push   $0x0
  pushl $214
801079c4:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801079c9:	e9 01 f1 ff ff       	jmp    80106acf <alltraps>

801079ce <vector215>:
.globl vector215
vector215:
  pushl $0
801079ce:	6a 00                	push   $0x0
  pushl $215
801079d0:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801079d5:	e9 f5 f0 ff ff       	jmp    80106acf <alltraps>

801079da <vector216>:
.globl vector216
vector216:
  pushl $0
801079da:	6a 00                	push   $0x0
  pushl $216
801079dc:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801079e1:	e9 e9 f0 ff ff       	jmp    80106acf <alltraps>

801079e6 <vector217>:
.globl vector217
vector217:
  pushl $0
801079e6:	6a 00                	push   $0x0
  pushl $217
801079e8:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801079ed:	e9 dd f0 ff ff       	jmp    80106acf <alltraps>

801079f2 <vector218>:
.globl vector218
vector218:
  pushl $0
801079f2:	6a 00                	push   $0x0
  pushl $218
801079f4:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801079f9:	e9 d1 f0 ff ff       	jmp    80106acf <alltraps>

801079fe <vector219>:
.globl vector219
vector219:
  pushl $0
801079fe:	6a 00                	push   $0x0
  pushl $219
80107a00:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107a05:	e9 c5 f0 ff ff       	jmp    80106acf <alltraps>

80107a0a <vector220>:
.globl vector220
vector220:
  pushl $0
80107a0a:	6a 00                	push   $0x0
  pushl $220
80107a0c:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107a11:	e9 b9 f0 ff ff       	jmp    80106acf <alltraps>

80107a16 <vector221>:
.globl vector221
vector221:
  pushl $0
80107a16:	6a 00                	push   $0x0
  pushl $221
80107a18:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107a1d:	e9 ad f0 ff ff       	jmp    80106acf <alltraps>

80107a22 <vector222>:
.globl vector222
vector222:
  pushl $0
80107a22:	6a 00                	push   $0x0
  pushl $222
80107a24:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107a29:	e9 a1 f0 ff ff       	jmp    80106acf <alltraps>

80107a2e <vector223>:
.globl vector223
vector223:
  pushl $0
80107a2e:	6a 00                	push   $0x0
  pushl $223
80107a30:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107a35:	e9 95 f0 ff ff       	jmp    80106acf <alltraps>

80107a3a <vector224>:
.globl vector224
vector224:
  pushl $0
80107a3a:	6a 00                	push   $0x0
  pushl $224
80107a3c:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107a41:	e9 89 f0 ff ff       	jmp    80106acf <alltraps>

80107a46 <vector225>:
.globl vector225
vector225:
  pushl $0
80107a46:	6a 00                	push   $0x0
  pushl $225
80107a48:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107a4d:	e9 7d f0 ff ff       	jmp    80106acf <alltraps>

80107a52 <vector226>:
.globl vector226
vector226:
  pushl $0
80107a52:	6a 00                	push   $0x0
  pushl $226
80107a54:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107a59:	e9 71 f0 ff ff       	jmp    80106acf <alltraps>

80107a5e <vector227>:
.globl vector227
vector227:
  pushl $0
80107a5e:	6a 00                	push   $0x0
  pushl $227
80107a60:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107a65:	e9 65 f0 ff ff       	jmp    80106acf <alltraps>

80107a6a <vector228>:
.globl vector228
vector228:
  pushl $0
80107a6a:	6a 00                	push   $0x0
  pushl $228
80107a6c:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107a71:	e9 59 f0 ff ff       	jmp    80106acf <alltraps>

80107a76 <vector229>:
.globl vector229
vector229:
  pushl $0
80107a76:	6a 00                	push   $0x0
  pushl $229
80107a78:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107a7d:	e9 4d f0 ff ff       	jmp    80106acf <alltraps>

80107a82 <vector230>:
.globl vector230
vector230:
  pushl $0
80107a82:	6a 00                	push   $0x0
  pushl $230
80107a84:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107a89:	e9 41 f0 ff ff       	jmp    80106acf <alltraps>

80107a8e <vector231>:
.globl vector231
vector231:
  pushl $0
80107a8e:	6a 00                	push   $0x0
  pushl $231
80107a90:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107a95:	e9 35 f0 ff ff       	jmp    80106acf <alltraps>

80107a9a <vector232>:
.globl vector232
vector232:
  pushl $0
80107a9a:	6a 00                	push   $0x0
  pushl $232
80107a9c:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107aa1:	e9 29 f0 ff ff       	jmp    80106acf <alltraps>

80107aa6 <vector233>:
.globl vector233
vector233:
  pushl $0
80107aa6:	6a 00                	push   $0x0
  pushl $233
80107aa8:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107aad:	e9 1d f0 ff ff       	jmp    80106acf <alltraps>

80107ab2 <vector234>:
.globl vector234
vector234:
  pushl $0
80107ab2:	6a 00                	push   $0x0
  pushl $234
80107ab4:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107ab9:	e9 11 f0 ff ff       	jmp    80106acf <alltraps>

80107abe <vector235>:
.globl vector235
vector235:
  pushl $0
80107abe:	6a 00                	push   $0x0
  pushl $235
80107ac0:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107ac5:	e9 05 f0 ff ff       	jmp    80106acf <alltraps>

80107aca <vector236>:
.globl vector236
vector236:
  pushl $0
80107aca:	6a 00                	push   $0x0
  pushl $236
80107acc:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107ad1:	e9 f9 ef ff ff       	jmp    80106acf <alltraps>

80107ad6 <vector237>:
.globl vector237
vector237:
  pushl $0
80107ad6:	6a 00                	push   $0x0
  pushl $237
80107ad8:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107add:	e9 ed ef ff ff       	jmp    80106acf <alltraps>

80107ae2 <vector238>:
.globl vector238
vector238:
  pushl $0
80107ae2:	6a 00                	push   $0x0
  pushl $238
80107ae4:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107ae9:	e9 e1 ef ff ff       	jmp    80106acf <alltraps>

80107aee <vector239>:
.globl vector239
vector239:
  pushl $0
80107aee:	6a 00                	push   $0x0
  pushl $239
80107af0:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107af5:	e9 d5 ef ff ff       	jmp    80106acf <alltraps>

80107afa <vector240>:
.globl vector240
vector240:
  pushl $0
80107afa:	6a 00                	push   $0x0
  pushl $240
80107afc:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107b01:	e9 c9 ef ff ff       	jmp    80106acf <alltraps>

80107b06 <vector241>:
.globl vector241
vector241:
  pushl $0
80107b06:	6a 00                	push   $0x0
  pushl $241
80107b08:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107b0d:	e9 bd ef ff ff       	jmp    80106acf <alltraps>

80107b12 <vector242>:
.globl vector242
vector242:
  pushl $0
80107b12:	6a 00                	push   $0x0
  pushl $242
80107b14:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107b19:	e9 b1 ef ff ff       	jmp    80106acf <alltraps>

80107b1e <vector243>:
.globl vector243
vector243:
  pushl $0
80107b1e:	6a 00                	push   $0x0
  pushl $243
80107b20:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107b25:	e9 a5 ef ff ff       	jmp    80106acf <alltraps>

80107b2a <vector244>:
.globl vector244
vector244:
  pushl $0
80107b2a:	6a 00                	push   $0x0
  pushl $244
80107b2c:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107b31:	e9 99 ef ff ff       	jmp    80106acf <alltraps>

80107b36 <vector245>:
.globl vector245
vector245:
  pushl $0
80107b36:	6a 00                	push   $0x0
  pushl $245
80107b38:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107b3d:	e9 8d ef ff ff       	jmp    80106acf <alltraps>

80107b42 <vector246>:
.globl vector246
vector246:
  pushl $0
80107b42:	6a 00                	push   $0x0
  pushl $246
80107b44:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107b49:	e9 81 ef ff ff       	jmp    80106acf <alltraps>

80107b4e <vector247>:
.globl vector247
vector247:
  pushl $0
80107b4e:	6a 00                	push   $0x0
  pushl $247
80107b50:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107b55:	e9 75 ef ff ff       	jmp    80106acf <alltraps>

80107b5a <vector248>:
.globl vector248
vector248:
  pushl $0
80107b5a:	6a 00                	push   $0x0
  pushl $248
80107b5c:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107b61:	e9 69 ef ff ff       	jmp    80106acf <alltraps>

80107b66 <vector249>:
.globl vector249
vector249:
  pushl $0
80107b66:	6a 00                	push   $0x0
  pushl $249
80107b68:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107b6d:	e9 5d ef ff ff       	jmp    80106acf <alltraps>

80107b72 <vector250>:
.globl vector250
vector250:
  pushl $0
80107b72:	6a 00                	push   $0x0
  pushl $250
80107b74:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107b79:	e9 51 ef ff ff       	jmp    80106acf <alltraps>

80107b7e <vector251>:
.globl vector251
vector251:
  pushl $0
80107b7e:	6a 00                	push   $0x0
  pushl $251
80107b80:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107b85:	e9 45 ef ff ff       	jmp    80106acf <alltraps>

80107b8a <vector252>:
.globl vector252
vector252:
  pushl $0
80107b8a:	6a 00                	push   $0x0
  pushl $252
80107b8c:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107b91:	e9 39 ef ff ff       	jmp    80106acf <alltraps>

80107b96 <vector253>:
.globl vector253
vector253:
  pushl $0
80107b96:	6a 00                	push   $0x0
  pushl $253
80107b98:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107b9d:	e9 2d ef ff ff       	jmp    80106acf <alltraps>

80107ba2 <vector254>:
.globl vector254
vector254:
  pushl $0
80107ba2:	6a 00                	push   $0x0
  pushl $254
80107ba4:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107ba9:	e9 21 ef ff ff       	jmp    80106acf <alltraps>

80107bae <vector255>:
.globl vector255
vector255:
  pushl $0
80107bae:	6a 00                	push   $0x0
  pushl $255
80107bb0:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107bb5:	e9 15 ef ff ff       	jmp    80106acf <alltraps>

80107bba <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107bba:	55                   	push   %ebp
80107bbb:	89 e5                	mov    %esp,%ebp
80107bbd:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107bc0:	8b 45 0c             	mov    0xc(%ebp),%eax
80107bc3:	83 e8 01             	sub    $0x1,%eax
80107bc6:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107bca:	8b 45 08             	mov    0x8(%ebp),%eax
80107bcd:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107bd1:	8b 45 08             	mov    0x8(%ebp),%eax
80107bd4:	c1 e8 10             	shr    $0x10,%eax
80107bd7:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107bdb:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107bde:	0f 01 10             	lgdtl  (%eax)
}
80107be1:	c9                   	leave  
80107be2:	c3                   	ret    

80107be3 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107be3:	55                   	push   %ebp
80107be4:	89 e5                	mov    %esp,%ebp
80107be6:	83 ec 04             	sub    $0x4,%esp
80107be9:	8b 45 08             	mov    0x8(%ebp),%eax
80107bec:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107bf0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107bf4:	0f 00 d8             	ltr    %ax
}
80107bf7:	c9                   	leave  
80107bf8:	c3                   	ret    

80107bf9 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107bf9:	55                   	push   %ebp
80107bfa:	89 e5                	mov    %esp,%ebp
80107bfc:	83 ec 04             	sub    $0x4,%esp
80107bff:	8b 45 08             	mov    0x8(%ebp),%eax
80107c02:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107c06:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107c0a:	8e e8                	mov    %eax,%gs
}
80107c0c:	c9                   	leave  
80107c0d:	c3                   	ret    

80107c0e <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107c0e:	55                   	push   %ebp
80107c0f:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107c11:	8b 45 08             	mov    0x8(%ebp),%eax
80107c14:	0f 22 d8             	mov    %eax,%cr3
}
80107c17:	5d                   	pop    %ebp
80107c18:	c3                   	ret    

80107c19 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107c19:	55                   	push   %ebp
80107c1a:	89 e5                	mov    %esp,%ebp
80107c1c:	8b 45 08             	mov    0x8(%ebp),%eax
80107c1f:	05 00 00 00 80       	add    $0x80000000,%eax
80107c24:	5d                   	pop    %ebp
80107c25:	c3                   	ret    

80107c26 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107c26:	55                   	push   %ebp
80107c27:	89 e5                	mov    %esp,%ebp
80107c29:	8b 45 08             	mov    0x8(%ebp),%eax
80107c2c:	05 00 00 00 80       	add    $0x80000000,%eax
80107c31:	5d                   	pop    %ebp
80107c32:	c3                   	ret    

80107c33 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107c33:	55                   	push   %ebp
80107c34:	89 e5                	mov    %esp,%ebp
80107c36:	53                   	push   %ebx
80107c37:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107c3a:	e8 d2 b8 ff ff       	call   80103511 <cpunum>
80107c3f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107c45:	05 c0 3b 11 80       	add    $0x80113bc0,%eax
80107c4a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107c4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c50:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107c56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c59:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107c5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c62:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107c66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c69:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107c6d:	83 e2 f0             	and    $0xfffffff0,%edx
80107c70:	83 ca 0a             	or     $0xa,%edx
80107c73:	88 50 7d             	mov    %dl,0x7d(%eax)
80107c76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c79:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107c7d:	83 ca 10             	or     $0x10,%edx
80107c80:	88 50 7d             	mov    %dl,0x7d(%eax)
80107c83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c86:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107c8a:	83 e2 9f             	and    $0xffffff9f,%edx
80107c8d:	88 50 7d             	mov    %dl,0x7d(%eax)
80107c90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c93:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107c97:	83 ca 80             	or     $0xffffff80,%edx
80107c9a:	88 50 7d             	mov    %dl,0x7d(%eax)
80107c9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ca0:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ca4:	83 ca 0f             	or     $0xf,%edx
80107ca7:	88 50 7e             	mov    %dl,0x7e(%eax)
80107caa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cad:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107cb1:	83 e2 ef             	and    $0xffffffef,%edx
80107cb4:	88 50 7e             	mov    %dl,0x7e(%eax)
80107cb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cba:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107cbe:	83 e2 df             	and    $0xffffffdf,%edx
80107cc1:	88 50 7e             	mov    %dl,0x7e(%eax)
80107cc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cc7:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ccb:	83 ca 40             	or     $0x40,%edx
80107cce:	88 50 7e             	mov    %dl,0x7e(%eax)
80107cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cd4:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107cd8:	83 ca 80             	or     $0xffffff80,%edx
80107cdb:	88 50 7e             	mov    %dl,0x7e(%eax)
80107cde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce1:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107ce5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce8:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107cef:	ff ff 
80107cf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cf4:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107cfb:	00 00 
80107cfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d00:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107d07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d0a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107d11:	83 e2 f0             	and    $0xfffffff0,%edx
80107d14:	83 ca 02             	or     $0x2,%edx
80107d17:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d20:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107d27:	83 ca 10             	or     $0x10,%edx
80107d2a:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107d30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d33:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107d3a:	83 e2 9f             	and    $0xffffff9f,%edx
80107d3d:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107d43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d46:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107d4d:	83 ca 80             	or     $0xffffff80,%edx
80107d50:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107d56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d59:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107d60:	83 ca 0f             	or     $0xf,%edx
80107d63:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107d69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d6c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107d73:	83 e2 ef             	and    $0xffffffef,%edx
80107d76:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107d7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d7f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107d86:	83 e2 df             	and    $0xffffffdf,%edx
80107d89:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107d8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d92:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107d99:	83 ca 40             	or     $0x40,%edx
80107d9c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107da2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da5:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107dac:	83 ca 80             	or     $0xffffff80,%edx
80107daf:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107db5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db8:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107dbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dc2:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107dc9:	ff ff 
80107dcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dce:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107dd5:	00 00 
80107dd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dda:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107de1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107de4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107deb:	83 e2 f0             	and    $0xfffffff0,%edx
80107dee:	83 ca 0a             	or     $0xa,%edx
80107df1:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107df7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dfa:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107e01:	83 ca 10             	or     $0x10,%edx
80107e04:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107e0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e0d:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107e14:	83 ca 60             	or     $0x60,%edx
80107e17:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e20:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107e27:	83 ca 80             	or     $0xffffff80,%edx
80107e2a:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e33:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107e3a:	83 ca 0f             	or     $0xf,%edx
80107e3d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107e43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e46:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107e4d:	83 e2 ef             	and    $0xffffffef,%edx
80107e50:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107e56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e59:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107e60:	83 e2 df             	and    $0xffffffdf,%edx
80107e63:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107e69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e6c:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107e73:	83 ca 40             	or     $0x40,%edx
80107e76:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107e7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e7f:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107e86:	83 ca 80             	or     $0xffffff80,%edx
80107e89:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107e8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e92:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107e99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e9c:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107ea3:	ff ff 
80107ea5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ea8:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107eaf:	00 00 
80107eb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107eb4:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107ebb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ebe:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107ec5:	83 e2 f0             	and    $0xfffffff0,%edx
80107ec8:	83 ca 02             	or     $0x2,%edx
80107ecb:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107ed1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ed4:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107edb:	83 ca 10             	or     $0x10,%edx
80107ede:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107ee4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ee7:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107eee:	83 ca 60             	or     $0x60,%edx
80107ef1:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107ef7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107efa:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107f01:	83 ca 80             	or     $0xffffff80,%edx
80107f04:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107f0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f0d:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107f14:	83 ca 0f             	or     $0xf,%edx
80107f17:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107f1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f20:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107f27:	83 e2 ef             	and    $0xffffffef,%edx
80107f2a:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107f30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f33:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107f3a:	83 e2 df             	and    $0xffffffdf,%edx
80107f3d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107f43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f46:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107f4d:	83 ca 40             	or     $0x40,%edx
80107f50:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107f56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f59:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107f60:	83 ca 80             	or     $0xffffff80,%edx
80107f63:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107f69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f6c:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107f73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f76:	05 b4 00 00 00       	add    $0xb4,%eax
80107f7b:	89 c3                	mov    %eax,%ebx
80107f7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f80:	05 b4 00 00 00       	add    $0xb4,%eax
80107f85:	c1 e8 10             	shr    $0x10,%eax
80107f88:	89 c1                	mov    %eax,%ecx
80107f8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f8d:	05 b4 00 00 00       	add    $0xb4,%eax
80107f92:	c1 e8 18             	shr    $0x18,%eax
80107f95:	89 c2                	mov    %eax,%edx
80107f97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f9a:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107fa1:	00 00 
80107fa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fa6:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107fad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fb0:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107fb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fb9:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107fc0:	83 e1 f0             	and    $0xfffffff0,%ecx
80107fc3:	83 c9 02             	or     $0x2,%ecx
80107fc6:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107fcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fcf:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107fd6:	83 c9 10             	or     $0x10,%ecx
80107fd9:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107fdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fe2:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107fe9:	83 e1 9f             	and    $0xffffff9f,%ecx
80107fec:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107ff2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff5:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107ffc:	83 c9 80             	or     $0xffffff80,%ecx
80107fff:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108005:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108008:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010800f:	83 e1 f0             	and    $0xfffffff0,%ecx
80108012:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108018:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010801b:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108022:	83 e1 ef             	and    $0xffffffef,%ecx
80108025:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010802b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010802e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108035:	83 e1 df             	and    $0xffffffdf,%ecx
80108038:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010803e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108041:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108048:	83 c9 40             	or     $0x40,%ecx
8010804b:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108051:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108054:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010805b:	83 c9 80             	or     $0xffffff80,%ecx
8010805e:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108064:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108067:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010806d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108070:	83 c0 70             	add    $0x70,%eax
80108073:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010807a:	00 
8010807b:	89 04 24             	mov    %eax,(%esp)
8010807e:	e8 37 fb ff ff       	call   80107bba <lgdt>
  loadgs(SEG_KCPU << 3);
80108083:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
8010808a:	e8 6a fb ff ff       	call   80107bf9 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
8010808f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108092:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108098:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010809f:	00 00 00 00 
}
801080a3:	83 c4 24             	add    $0x24,%esp
801080a6:	5b                   	pop    %ebx
801080a7:	5d                   	pop    %ebp
801080a8:	c3                   	ret    

801080a9 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801080a9:	55                   	push   %ebp
801080aa:	89 e5                	mov    %esp,%ebp
801080ac:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801080af:	8b 45 0c             	mov    0xc(%ebp),%eax
801080b2:	c1 e8 16             	shr    $0x16,%eax
801080b5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801080bc:	8b 45 08             	mov    0x8(%ebp),%eax
801080bf:	01 d0                	add    %edx,%eax
801080c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801080c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080c7:	8b 00                	mov    (%eax),%eax
801080c9:	83 e0 01             	and    $0x1,%eax
801080cc:	85 c0                	test   %eax,%eax
801080ce:	74 17                	je     801080e7 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801080d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080d3:	8b 00                	mov    (%eax),%eax
801080d5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080da:	89 04 24             	mov    %eax,(%esp)
801080dd:	e8 44 fb ff ff       	call   80107c26 <p2v>
801080e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801080e5:	eb 4b                	jmp    80108132 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801080e7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801080eb:	74 0e                	je     801080fb <walkpgdir+0x52>
801080ed:	e8 89 b0 ff ff       	call   8010317b <kalloc>
801080f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801080f5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801080f9:	75 07                	jne    80108102 <walkpgdir+0x59>
      return 0;
801080fb:	b8 00 00 00 00       	mov    $0x0,%eax
80108100:	eb 47                	jmp    80108149 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108102:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108109:	00 
8010810a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108111:	00 
80108112:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108115:	89 04 24             	mov    %eax,(%esp)
80108118:	e8 be d5 ff ff       	call   801056db <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
8010811d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108120:	89 04 24             	mov    %eax,(%esp)
80108123:	e8 f1 fa ff ff       	call   80107c19 <v2p>
80108128:	83 c8 07             	or     $0x7,%eax
8010812b:	89 c2                	mov    %eax,%edx
8010812d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108130:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108132:	8b 45 0c             	mov    0xc(%ebp),%eax
80108135:	c1 e8 0c             	shr    $0xc,%eax
80108138:	25 ff 03 00 00       	and    $0x3ff,%eax
8010813d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108144:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108147:	01 d0                	add    %edx,%eax
}
80108149:	c9                   	leave  
8010814a:	c3                   	ret    

8010814b <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010814b:	55                   	push   %ebp
8010814c:	89 e5                	mov    %esp,%ebp
8010814e:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108151:	8b 45 0c             	mov    0xc(%ebp),%eax
80108154:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108159:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010815c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010815f:	8b 45 10             	mov    0x10(%ebp),%eax
80108162:	01 d0                	add    %edx,%eax
80108164:	83 e8 01             	sub    $0x1,%eax
80108167:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010816c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010816f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108176:	00 
80108177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010817e:	8b 45 08             	mov    0x8(%ebp),%eax
80108181:	89 04 24             	mov    %eax,(%esp)
80108184:	e8 20 ff ff ff       	call   801080a9 <walkpgdir>
80108189:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010818c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108190:	75 07                	jne    80108199 <mappages+0x4e>
      return -1;
80108192:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108197:	eb 48                	jmp    801081e1 <mappages+0x96>
    if(*pte & PTE_P)
80108199:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010819c:	8b 00                	mov    (%eax),%eax
8010819e:	83 e0 01             	and    $0x1,%eax
801081a1:	85 c0                	test   %eax,%eax
801081a3:	74 0c                	je     801081b1 <mappages+0x66>
      panic("remap");
801081a5:	c7 04 24 50 90 10 80 	movl   $0x80109050,(%esp)
801081ac:	e8 89 83 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
801081b1:	8b 45 18             	mov    0x18(%ebp),%eax
801081b4:	0b 45 14             	or     0x14(%ebp),%eax
801081b7:	83 c8 01             	or     $0x1,%eax
801081ba:	89 c2                	mov    %eax,%edx
801081bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081bf:	89 10                	mov    %edx,(%eax)
    if(a == last)
801081c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801081c7:	75 08                	jne    801081d1 <mappages+0x86>
      break;
801081c9:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
801081ca:	b8 00 00 00 00       	mov    $0x0,%eax
801081cf:	eb 10                	jmp    801081e1 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
801081d1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
801081d8:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801081df:	eb 8e                	jmp    8010816f <mappages+0x24>
  return 0;
}
801081e1:	c9                   	leave  
801081e2:	c3                   	ret    

801081e3 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
801081e3:	55                   	push   %ebp
801081e4:	89 e5                	mov    %esp,%ebp
801081e6:	53                   	push   %ebx
801081e7:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801081ea:	e8 8c af ff ff       	call   8010317b <kalloc>
801081ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
801081f2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801081f6:	75 0a                	jne    80108202 <setupkvm+0x1f>
    return 0;
801081f8:	b8 00 00 00 00       	mov    $0x0,%eax
801081fd:	e9 98 00 00 00       	jmp    8010829a <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108202:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108209:	00 
8010820a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108211:	00 
80108212:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108215:	89 04 24             	mov    %eax,(%esp)
80108218:	e8 be d4 ff ff       	call   801056db <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
8010821d:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108224:	e8 fd f9 ff ff       	call   80107c26 <p2v>
80108229:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
8010822e:	76 0c                	jbe    8010823c <setupkvm+0x59>
    panic("PHYSTOP too high");
80108230:	c7 04 24 56 90 10 80 	movl   $0x80109056,(%esp)
80108237:	e8 fe 82 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010823c:	c7 45 f4 a0 c4 10 80 	movl   $0x8010c4a0,-0xc(%ebp)
80108243:	eb 49                	jmp    8010828e <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108245:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108248:	8b 48 0c             	mov    0xc(%eax),%ecx
8010824b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010824e:	8b 50 04             	mov    0x4(%eax),%edx
80108251:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108254:	8b 58 08             	mov    0x8(%eax),%ebx
80108257:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010825a:	8b 40 04             	mov    0x4(%eax),%eax
8010825d:	29 c3                	sub    %eax,%ebx
8010825f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108262:	8b 00                	mov    (%eax),%eax
80108264:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108268:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010826c:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108270:	89 44 24 04          	mov    %eax,0x4(%esp)
80108274:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108277:	89 04 24             	mov    %eax,(%esp)
8010827a:	e8 cc fe ff ff       	call   8010814b <mappages>
8010827f:	85 c0                	test   %eax,%eax
80108281:	79 07                	jns    8010828a <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108283:	b8 00 00 00 00       	mov    $0x0,%eax
80108288:	eb 10                	jmp    8010829a <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010828a:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010828e:	81 7d f4 e0 c4 10 80 	cmpl   $0x8010c4e0,-0xc(%ebp)
80108295:	72 ae                	jb     80108245 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108297:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010829a:	83 c4 34             	add    $0x34,%esp
8010829d:	5b                   	pop    %ebx
8010829e:	5d                   	pop    %ebp
8010829f:	c3                   	ret    

801082a0 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
801082a0:	55                   	push   %ebp
801082a1:	89 e5                	mov    %esp,%ebp
801082a3:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801082a6:	e8 38 ff ff ff       	call   801081e3 <setupkvm>
801082ab:	a3 98 69 11 80       	mov    %eax,0x80116998
  switchkvm();
801082b0:	e8 02 00 00 00       	call   801082b7 <switchkvm>
}
801082b5:	c9                   	leave  
801082b6:	c3                   	ret    

801082b7 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801082b7:	55                   	push   %ebp
801082b8:	89 e5                	mov    %esp,%ebp
801082ba:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801082bd:	a1 98 69 11 80       	mov    0x80116998,%eax
801082c2:	89 04 24             	mov    %eax,(%esp)
801082c5:	e8 4f f9 ff ff       	call   80107c19 <v2p>
801082ca:	89 04 24             	mov    %eax,(%esp)
801082cd:	e8 3c f9 ff ff       	call   80107c0e <lcr3>
}
801082d2:	c9                   	leave  
801082d3:	c3                   	ret    

801082d4 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801082d4:	55                   	push   %ebp
801082d5:	89 e5                	mov    %esp,%ebp
801082d7:	53                   	push   %ebx
801082d8:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801082db:	e8 fb d2 ff ff       	call   801055db <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801082e0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801082e6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801082ed:	83 c2 08             	add    $0x8,%edx
801082f0:	89 d3                	mov    %edx,%ebx
801082f2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801082f9:	83 c2 08             	add    $0x8,%edx
801082fc:	c1 ea 10             	shr    $0x10,%edx
801082ff:	89 d1                	mov    %edx,%ecx
80108301:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108308:	83 c2 08             	add    $0x8,%edx
8010830b:	c1 ea 18             	shr    $0x18,%edx
8010830e:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108315:	67 00 
80108317:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
8010831e:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108324:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010832b:	83 e1 f0             	and    $0xfffffff0,%ecx
8010832e:	83 c9 09             	or     $0x9,%ecx
80108331:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108337:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010833e:	83 c9 10             	or     $0x10,%ecx
80108341:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108347:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010834e:	83 e1 9f             	and    $0xffffff9f,%ecx
80108351:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108357:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010835e:	83 c9 80             	or     $0xffffff80,%ecx
80108361:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108367:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010836e:	83 e1 f0             	and    $0xfffffff0,%ecx
80108371:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108377:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010837e:	83 e1 ef             	and    $0xffffffef,%ecx
80108381:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108387:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010838e:	83 e1 df             	and    $0xffffffdf,%ecx
80108391:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108397:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010839e:	83 c9 40             	or     $0x40,%ecx
801083a1:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801083a7:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801083ae:	83 e1 7f             	and    $0x7f,%ecx
801083b1:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801083b7:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801083bd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801083c3:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801083ca:	83 e2 ef             	and    $0xffffffef,%edx
801083cd:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801083d3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801083d9:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801083df:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801083e5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801083ec:	8b 52 08             	mov    0x8(%edx),%edx
801083ef:	81 c2 00 10 00 00    	add    $0x1000,%edx
801083f5:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801083f8:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801083ff:	e8 df f7 ff ff       	call   80107be3 <ltr>
  if(p->pgdir == 0)
80108404:	8b 45 08             	mov    0x8(%ebp),%eax
80108407:	8b 40 04             	mov    0x4(%eax),%eax
8010840a:	85 c0                	test   %eax,%eax
8010840c:	75 0c                	jne    8010841a <switchuvm+0x146>
    panic("switchuvm: no pgdir");
8010840e:	c7 04 24 67 90 10 80 	movl   $0x80109067,(%esp)
80108415:	e8 20 81 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
8010841a:	8b 45 08             	mov    0x8(%ebp),%eax
8010841d:	8b 40 04             	mov    0x4(%eax),%eax
80108420:	89 04 24             	mov    %eax,(%esp)
80108423:	e8 f1 f7 ff ff       	call   80107c19 <v2p>
80108428:	89 04 24             	mov    %eax,(%esp)
8010842b:	e8 de f7 ff ff       	call   80107c0e <lcr3>
  popcli();
80108430:	e8 ea d1 ff ff       	call   8010561f <popcli>
}
80108435:	83 c4 14             	add    $0x14,%esp
80108438:	5b                   	pop    %ebx
80108439:	5d                   	pop    %ebp
8010843a:	c3                   	ret    

8010843b <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010843b:	55                   	push   %ebp
8010843c:	89 e5                	mov    %esp,%ebp
8010843e:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108441:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108448:	76 0c                	jbe    80108456 <inituvm+0x1b>
    panic("inituvm: more than a page");
8010844a:	c7 04 24 7b 90 10 80 	movl   $0x8010907b,(%esp)
80108451:	e8 e4 80 ff ff       	call   8010053a <panic>
  mem = kalloc();
80108456:	e8 20 ad ff ff       	call   8010317b <kalloc>
8010845b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
8010845e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108465:	00 
80108466:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010846d:	00 
8010846e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108471:	89 04 24             	mov    %eax,(%esp)
80108474:	e8 62 d2 ff ff       	call   801056db <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108479:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010847c:	89 04 24             	mov    %eax,(%esp)
8010847f:	e8 95 f7 ff ff       	call   80107c19 <v2p>
80108484:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010848b:	00 
8010848c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108490:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108497:	00 
80108498:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010849f:	00 
801084a0:	8b 45 08             	mov    0x8(%ebp),%eax
801084a3:	89 04 24             	mov    %eax,(%esp)
801084a6:	e8 a0 fc ff ff       	call   8010814b <mappages>
  memmove(mem, init, sz);
801084ab:	8b 45 10             	mov    0x10(%ebp),%eax
801084ae:	89 44 24 08          	mov    %eax,0x8(%esp)
801084b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801084b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801084b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084bc:	89 04 24             	mov    %eax,(%esp)
801084bf:	e8 e6 d2 ff ff       	call   801057aa <memmove>
}
801084c4:	c9                   	leave  
801084c5:	c3                   	ret    

801084c6 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801084c6:	55                   	push   %ebp
801084c7:	89 e5                	mov    %esp,%ebp
801084c9:	53                   	push   %ebx
801084ca:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801084cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801084d0:	25 ff 0f 00 00       	and    $0xfff,%eax
801084d5:	85 c0                	test   %eax,%eax
801084d7:	74 0c                	je     801084e5 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801084d9:	c7 04 24 98 90 10 80 	movl   $0x80109098,(%esp)
801084e0:	e8 55 80 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
801084e5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801084ec:	e9 a9 00 00 00       	jmp    8010859a <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801084f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f4:	8b 55 0c             	mov    0xc(%ebp),%edx
801084f7:	01 d0                	add    %edx,%eax
801084f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108500:	00 
80108501:	89 44 24 04          	mov    %eax,0x4(%esp)
80108505:	8b 45 08             	mov    0x8(%ebp),%eax
80108508:	89 04 24             	mov    %eax,(%esp)
8010850b:	e8 99 fb ff ff       	call   801080a9 <walkpgdir>
80108510:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108513:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108517:	75 0c                	jne    80108525 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108519:	c7 04 24 bb 90 10 80 	movl   $0x801090bb,(%esp)
80108520:	e8 15 80 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108525:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108528:	8b 00                	mov    (%eax),%eax
8010852a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010852f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108532:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108535:	8b 55 18             	mov    0x18(%ebp),%edx
80108538:	29 c2                	sub    %eax,%edx
8010853a:	89 d0                	mov    %edx,%eax
8010853c:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108541:	77 0f                	ja     80108552 <loaduvm+0x8c>
      n = sz - i;
80108543:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108546:	8b 55 18             	mov    0x18(%ebp),%edx
80108549:	29 c2                	sub    %eax,%edx
8010854b:	89 d0                	mov    %edx,%eax
8010854d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108550:	eb 07                	jmp    80108559 <loaduvm+0x93>
    else
      n = PGSIZE;
80108552:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108559:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010855c:	8b 55 14             	mov    0x14(%ebp),%edx
8010855f:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108562:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108565:	89 04 24             	mov    %eax,(%esp)
80108568:	e8 b9 f6 ff ff       	call   80107c26 <p2v>
8010856d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108570:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108574:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108578:	89 44 24 04          	mov    %eax,0x4(%esp)
8010857c:	8b 45 10             	mov    0x10(%ebp),%eax
8010857f:	89 04 24             	mov    %eax,(%esp)
80108582:	e8 43 9e ff ff       	call   801023ca <readi>
80108587:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010858a:	74 07                	je     80108593 <loaduvm+0xcd>
      return -1;
8010858c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108591:	eb 18                	jmp    801085ab <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108593:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010859a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010859d:	3b 45 18             	cmp    0x18(%ebp),%eax
801085a0:	0f 82 4b ff ff ff    	jb     801084f1 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801085a6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801085ab:	83 c4 24             	add    $0x24,%esp
801085ae:	5b                   	pop    %ebx
801085af:	5d                   	pop    %ebp
801085b0:	c3                   	ret    

801085b1 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801085b1:	55                   	push   %ebp
801085b2:	89 e5                	mov    %esp,%ebp
801085b4:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
801085b7:	8b 45 10             	mov    0x10(%ebp),%eax
801085ba:	85 c0                	test   %eax,%eax
801085bc:	79 0a                	jns    801085c8 <allocuvm+0x17>
    return 0;
801085be:	b8 00 00 00 00       	mov    $0x0,%eax
801085c3:	e9 c1 00 00 00       	jmp    80108689 <allocuvm+0xd8>
  if(newsz < oldsz)
801085c8:	8b 45 10             	mov    0x10(%ebp),%eax
801085cb:	3b 45 0c             	cmp    0xc(%ebp),%eax
801085ce:	73 08                	jae    801085d8 <allocuvm+0x27>
    return oldsz;
801085d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801085d3:	e9 b1 00 00 00       	jmp    80108689 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
801085d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801085db:	05 ff 0f 00 00       	add    $0xfff,%eax
801085e0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801085e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801085e8:	e9 8d 00 00 00       	jmp    8010867a <allocuvm+0xc9>
    mem = kalloc();
801085ed:	e8 89 ab ff ff       	call   8010317b <kalloc>
801085f2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
801085f5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801085f9:	75 2c                	jne    80108627 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
801085fb:	c7 04 24 d9 90 10 80 	movl   $0x801090d9,(%esp)
80108602:	e8 99 7d ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108607:	8b 45 0c             	mov    0xc(%ebp),%eax
8010860a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010860e:	8b 45 10             	mov    0x10(%ebp),%eax
80108611:	89 44 24 04          	mov    %eax,0x4(%esp)
80108615:	8b 45 08             	mov    0x8(%ebp),%eax
80108618:	89 04 24             	mov    %eax,(%esp)
8010861b:	e8 6b 00 00 00       	call   8010868b <deallocuvm>
      return 0;
80108620:	b8 00 00 00 00       	mov    $0x0,%eax
80108625:	eb 62                	jmp    80108689 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108627:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010862e:	00 
8010862f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108636:	00 
80108637:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010863a:	89 04 24             	mov    %eax,(%esp)
8010863d:	e8 99 d0 ff ff       	call   801056db <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108642:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108645:	89 04 24             	mov    %eax,(%esp)
80108648:	e8 cc f5 ff ff       	call   80107c19 <v2p>
8010864d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108650:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108657:	00 
80108658:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010865c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108663:	00 
80108664:	89 54 24 04          	mov    %edx,0x4(%esp)
80108668:	8b 45 08             	mov    0x8(%ebp),%eax
8010866b:	89 04 24             	mov    %eax,(%esp)
8010866e:	e8 d8 fa ff ff       	call   8010814b <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108673:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010867a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010867d:	3b 45 10             	cmp    0x10(%ebp),%eax
80108680:	0f 82 67 ff ff ff    	jb     801085ed <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108686:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108689:	c9                   	leave  
8010868a:	c3                   	ret    

8010868b <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010868b:	55                   	push   %ebp
8010868c:	89 e5                	mov    %esp,%ebp
8010868e:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108691:	8b 45 10             	mov    0x10(%ebp),%eax
80108694:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108697:	72 08                	jb     801086a1 <deallocuvm+0x16>
    return oldsz;
80108699:	8b 45 0c             	mov    0xc(%ebp),%eax
8010869c:	e9 a4 00 00 00       	jmp    80108745 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
801086a1:	8b 45 10             	mov    0x10(%ebp),%eax
801086a4:	05 ff 0f 00 00       	add    $0xfff,%eax
801086a9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801086ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801086b1:	e9 80 00 00 00       	jmp    80108736 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801086b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086b9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801086c0:	00 
801086c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801086c5:	8b 45 08             	mov    0x8(%ebp),%eax
801086c8:	89 04 24             	mov    %eax,(%esp)
801086cb:	e8 d9 f9 ff ff       	call   801080a9 <walkpgdir>
801086d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801086d3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801086d7:	75 09                	jne    801086e2 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801086d9:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801086e0:	eb 4d                	jmp    8010872f <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801086e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801086e5:	8b 00                	mov    (%eax),%eax
801086e7:	83 e0 01             	and    $0x1,%eax
801086ea:	85 c0                	test   %eax,%eax
801086ec:	74 41                	je     8010872f <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
801086ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801086f1:	8b 00                	mov    (%eax),%eax
801086f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801086f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801086fb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801086ff:	75 0c                	jne    8010870d <deallocuvm+0x82>
        panic("kfree");
80108701:	c7 04 24 f1 90 10 80 	movl   $0x801090f1,(%esp)
80108708:	e8 2d 7e ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
8010870d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108710:	89 04 24             	mov    %eax,(%esp)
80108713:	e8 0e f5 ff ff       	call   80107c26 <p2v>
80108718:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
8010871b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010871e:	89 04 24             	mov    %eax,(%esp)
80108721:	e8 bc a9 ff ff       	call   801030e2 <kfree>
      *pte = 0;
80108726:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108729:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
8010872f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108739:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010873c:	0f 82 74 ff ff ff    	jb     801086b6 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108742:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108745:	c9                   	leave  
80108746:	c3                   	ret    

80108747 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108747:	55                   	push   %ebp
80108748:	89 e5                	mov    %esp,%ebp
8010874a:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
8010874d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108751:	75 0c                	jne    8010875f <freevm+0x18>
    panic("freevm: no pgdir");
80108753:	c7 04 24 f7 90 10 80 	movl   $0x801090f7,(%esp)
8010875a:	e8 db 7d ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010875f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108766:	00 
80108767:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
8010876e:	80 
8010876f:	8b 45 08             	mov    0x8(%ebp),%eax
80108772:	89 04 24             	mov    %eax,(%esp)
80108775:	e8 11 ff ff ff       	call   8010868b <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010877a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108781:	eb 48                	jmp    801087cb <freevm+0x84>
    if(pgdir[i] & PTE_P){
80108783:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108786:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010878d:	8b 45 08             	mov    0x8(%ebp),%eax
80108790:	01 d0                	add    %edx,%eax
80108792:	8b 00                	mov    (%eax),%eax
80108794:	83 e0 01             	and    $0x1,%eax
80108797:	85 c0                	test   %eax,%eax
80108799:	74 2c                	je     801087c7 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010879b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010879e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801087a5:	8b 45 08             	mov    0x8(%ebp),%eax
801087a8:	01 d0                	add    %edx,%eax
801087aa:	8b 00                	mov    (%eax),%eax
801087ac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801087b1:	89 04 24             	mov    %eax,(%esp)
801087b4:	e8 6d f4 ff ff       	call   80107c26 <p2v>
801087b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801087bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801087bf:	89 04 24             	mov    %eax,(%esp)
801087c2:	e8 1b a9 ff ff       	call   801030e2 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801087c7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801087cb:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801087d2:	76 af                	jbe    80108783 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801087d4:	8b 45 08             	mov    0x8(%ebp),%eax
801087d7:	89 04 24             	mov    %eax,(%esp)
801087da:	e8 03 a9 ff ff       	call   801030e2 <kfree>
}
801087df:	c9                   	leave  
801087e0:	c3                   	ret    

801087e1 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801087e1:	55                   	push   %ebp
801087e2:	89 e5                	mov    %esp,%ebp
801087e4:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801087e7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801087ee:	00 
801087ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801087f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801087f6:	8b 45 08             	mov    0x8(%ebp),%eax
801087f9:	89 04 24             	mov    %eax,(%esp)
801087fc:	e8 a8 f8 ff ff       	call   801080a9 <walkpgdir>
80108801:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108804:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108808:	75 0c                	jne    80108816 <clearpteu+0x35>
    panic("clearpteu");
8010880a:	c7 04 24 08 91 10 80 	movl   $0x80109108,(%esp)
80108811:	e8 24 7d ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108816:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108819:	8b 00                	mov    (%eax),%eax
8010881b:	83 e0 fb             	and    $0xfffffffb,%eax
8010881e:	89 c2                	mov    %eax,%edx
80108820:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108823:	89 10                	mov    %edx,(%eax)
}
80108825:	c9                   	leave  
80108826:	c3                   	ret    

80108827 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108827:	55                   	push   %ebp
80108828:	89 e5                	mov    %esp,%ebp
8010882a:	53                   	push   %ebx
8010882b:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010882e:	e8 b0 f9 ff ff       	call   801081e3 <setupkvm>
80108833:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108836:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010883a:	75 0a                	jne    80108846 <copyuvm+0x1f>
    return 0;
8010883c:	b8 00 00 00 00       	mov    $0x0,%eax
80108841:	e9 fd 00 00 00       	jmp    80108943 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
80108846:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010884d:	e9 d0 00 00 00       	jmp    80108922 <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108852:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108855:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010885c:	00 
8010885d:	89 44 24 04          	mov    %eax,0x4(%esp)
80108861:	8b 45 08             	mov    0x8(%ebp),%eax
80108864:	89 04 24             	mov    %eax,(%esp)
80108867:	e8 3d f8 ff ff       	call   801080a9 <walkpgdir>
8010886c:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010886f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108873:	75 0c                	jne    80108881 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80108875:	c7 04 24 12 91 10 80 	movl   $0x80109112,(%esp)
8010887c:	e8 b9 7c ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108881:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108884:	8b 00                	mov    (%eax),%eax
80108886:	83 e0 01             	and    $0x1,%eax
80108889:	85 c0                	test   %eax,%eax
8010888b:	75 0c                	jne    80108899 <copyuvm+0x72>
      panic("copyuvm: page not present");
8010888d:	c7 04 24 2c 91 10 80 	movl   $0x8010912c,(%esp)
80108894:	e8 a1 7c ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108899:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010889c:	8b 00                	mov    (%eax),%eax
8010889e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088a3:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
801088a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088a9:	8b 00                	mov    (%eax),%eax
801088ab:	25 ff 0f 00 00       	and    $0xfff,%eax
801088b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
801088b3:	e8 c3 a8 ff ff       	call   8010317b <kalloc>
801088b8:	89 45 e0             	mov    %eax,-0x20(%ebp)
801088bb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801088bf:	75 02                	jne    801088c3 <copyuvm+0x9c>
      goto bad;
801088c1:	eb 70                	jmp    80108933 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
801088c3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801088c6:	89 04 24             	mov    %eax,(%esp)
801088c9:	e8 58 f3 ff ff       	call   80107c26 <p2v>
801088ce:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801088d5:	00 
801088d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801088da:	8b 45 e0             	mov    -0x20(%ebp),%eax
801088dd:	89 04 24             	mov    %eax,(%esp)
801088e0:	e8 c5 ce ff ff       	call   801057aa <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
801088e5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801088e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801088eb:	89 04 24             	mov    %eax,(%esp)
801088ee:	e8 26 f3 ff ff       	call   80107c19 <v2p>
801088f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801088f6:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801088fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
801088fe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108905:	00 
80108906:	89 54 24 04          	mov    %edx,0x4(%esp)
8010890a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010890d:	89 04 24             	mov    %eax,(%esp)
80108910:	e8 36 f8 ff ff       	call   8010814b <mappages>
80108915:	85 c0                	test   %eax,%eax
80108917:	79 02                	jns    8010891b <copyuvm+0xf4>
      goto bad;
80108919:	eb 18                	jmp    80108933 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010891b:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108922:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108925:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108928:	0f 82 24 ff ff ff    	jb     80108852 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
8010892e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108931:	eb 10                	jmp    80108943 <copyuvm+0x11c>

bad:
  freevm(d);
80108933:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108936:	89 04 24             	mov    %eax,(%esp)
80108939:	e8 09 fe ff ff       	call   80108747 <freevm>
  return 0;
8010893e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108943:	83 c4 44             	add    $0x44,%esp
80108946:	5b                   	pop    %ebx
80108947:	5d                   	pop    %ebp
80108948:	c3                   	ret    

80108949 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108949:	55                   	push   %ebp
8010894a:	89 e5                	mov    %esp,%ebp
8010894c:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010894f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108956:	00 
80108957:	8b 45 0c             	mov    0xc(%ebp),%eax
8010895a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010895e:	8b 45 08             	mov    0x8(%ebp),%eax
80108961:	89 04 24             	mov    %eax,(%esp)
80108964:	e8 40 f7 ff ff       	call   801080a9 <walkpgdir>
80108969:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
8010896c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010896f:	8b 00                	mov    (%eax),%eax
80108971:	83 e0 01             	and    $0x1,%eax
80108974:	85 c0                	test   %eax,%eax
80108976:	75 07                	jne    8010897f <uva2ka+0x36>
    return 0;
80108978:	b8 00 00 00 00       	mov    $0x0,%eax
8010897d:	eb 25                	jmp    801089a4 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
8010897f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108982:	8b 00                	mov    (%eax),%eax
80108984:	83 e0 04             	and    $0x4,%eax
80108987:	85 c0                	test   %eax,%eax
80108989:	75 07                	jne    80108992 <uva2ka+0x49>
    return 0;
8010898b:	b8 00 00 00 00       	mov    $0x0,%eax
80108990:	eb 12                	jmp    801089a4 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108992:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108995:	8b 00                	mov    (%eax),%eax
80108997:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010899c:	89 04 24             	mov    %eax,(%esp)
8010899f:	e8 82 f2 ff ff       	call   80107c26 <p2v>
}
801089a4:	c9                   	leave  
801089a5:	c3                   	ret    

801089a6 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801089a6:	55                   	push   %ebp
801089a7:	89 e5                	mov    %esp,%ebp
801089a9:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801089ac:	8b 45 10             	mov    0x10(%ebp),%eax
801089af:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801089b2:	e9 87 00 00 00       	jmp    80108a3e <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
801089b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801089ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089bf:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801089c2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801089c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801089c9:	8b 45 08             	mov    0x8(%ebp),%eax
801089cc:	89 04 24             	mov    %eax,(%esp)
801089cf:	e8 75 ff ff ff       	call   80108949 <uva2ka>
801089d4:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801089d7:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801089db:	75 07                	jne    801089e4 <copyout+0x3e>
      return -1;
801089dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801089e2:	eb 69                	jmp    80108a4d <copyout+0xa7>
    n = PGSIZE - (va - va0);
801089e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801089e7:	8b 55 ec             	mov    -0x14(%ebp),%edx
801089ea:	29 c2                	sub    %eax,%edx
801089ec:	89 d0                	mov    %edx,%eax
801089ee:	05 00 10 00 00       	add    $0x1000,%eax
801089f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801089f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801089f9:	3b 45 14             	cmp    0x14(%ebp),%eax
801089fc:	76 06                	jbe    80108a04 <copyout+0x5e>
      n = len;
801089fe:	8b 45 14             	mov    0x14(%ebp),%eax
80108a01:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108a04:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a07:	8b 55 0c             	mov    0xc(%ebp),%edx
80108a0a:	29 c2                	sub    %eax,%edx
80108a0c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108a0f:	01 c2                	add    %eax,%edx
80108a11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a14:	89 44 24 08          	mov    %eax,0x8(%esp)
80108a18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a1b:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a1f:	89 14 24             	mov    %edx,(%esp)
80108a22:	e8 83 cd ff ff       	call   801057aa <memmove>
    len -= n;
80108a27:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a2a:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108a2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a30:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108a33:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a36:	05 00 10 00 00       	add    $0x1000,%eax
80108a3b:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108a3e:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108a42:	0f 85 6f ff ff ff    	jne    801089b7 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108a48:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108a4d:	c9                   	leave  
80108a4e:	c3                   	ret    
