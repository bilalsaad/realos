
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
8010003a:	c7 44 24 04 40 8c 10 	movl   $0x80108c40,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100049:	e8 f5 55 00 00       	call   80105643 <initlock>

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
801000bd:	e8 a2 55 00 00       	call   80105664 <acquire>

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
80100104:	e8 bd 55 00 00       	call   801056c6 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 d6 10 	movl   $0x8010d660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 6d 52 00 00       	call   80105391 <sleep>
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
8010017c:	e8 45 55 00 00       	call   801056c6 <release>
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
80100198:	c7 04 24 47 8c 10 80 	movl   $0x80108c47,(%esp)
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
801001ef:	c7 04 24 58 8c 10 80 	movl   $0x80108c58,(%esp)
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
80100229:	c7 04 24 5f 8c 10 80 	movl   $0x80108c5f,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010023c:	e8 23 54 00 00       	call   80105664 <acquire>

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
8010029d:	e8 cb 51 00 00       	call   8010546d <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801002a9:	e8 18 54 00 00       	call   801056c6 <release>
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
801003bb:	e8 a4 52 00 00       	call   80105664 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 66 8c 10 80 	movl   $0x80108c66,(%esp)
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
801004b0:	c7 45 ec 6f 8c 10 80 	movl   $0x80108c6f,-0x14(%ebp)
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
80100533:	e8 8e 51 00 00       	call   801056c6 <release>
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
8010055f:	c7 04 24 76 8c 10 80 	movl   $0x80108c76,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 85 8c 10 80 	movl   $0x80108c85,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 81 51 00 00       	call   80105715 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 87 8c 10 80 	movl   $0x80108c87,(%esp)
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
801007bb:	c7 04 24 8b 8c 10 80 	movl   $0x80108c8b,(%esp)
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
801007ef:	e8 93 51 00 00       	call   80105987 <memmove>
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
8010081e:	e8 95 50 00 00       	call   801058b8 <memset>
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
801008ed:	e8 8f 69 00 00       	call   80107281 <uartputc>
801008f2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801008f9:	e8 83 69 00 00       	call   80107281 <uartputc>
801008fe:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100905:	e8 77 69 00 00       	call   80107281 <uartputc>
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
80100924:	e8 58 69 00 00       	call   80107281 <uartputc>
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
80100987:	e8 fb 4f 00 00       	call   80105987 <memmove>
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
801009ef:	e8 93 4f 00 00       	call   80105987 <memmove>
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
80100aa8:	e8 da 4e 00 00       	call   80105987 <memmove>
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
80100b0a:	e8 55 4b 00 00       	call   80105664 <acquire>
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
80100e41:	e8 27 46 00 00       	call   8010546d <wakeup>
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
80100e62:	e8 5f 48 00 00       	call   801056c6 <release>
  if(doprocdump) {
80100e67:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100e6b:	74 05                	je     80100e72 <consoleintr+0x37c>
        procdump();  // now call procdump() wo. cons.lock held
80100e6d:	e8 a1 46 00 00       	call   80105513 <procdump>
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
80100e92:	e8 cd 47 00 00       	call   80105664 <acquire>
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
80100eb2:	e8 0f 48 00 00       	call   801056c6 <release>
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
80100edb:	e8 b1 44 00 00       	call   80105391 <sleep>
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
80100f57:	e8 6a 47 00 00       	call   801056c6 <release>
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
80100f8b:	e8 d4 46 00 00       	call   80105664 <acquire>
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
80100fc5:	e8 fc 46 00 00       	call   801056c6 <release>
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
80100fe0:	c7 44 24 04 9e 8c 10 	movl   $0x80108c9e,0x4(%esp)
80100fe7:	80 
80100fe8:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100fef:	e8 4f 46 00 00       	call   80105643 <initlock>

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
80101048:	e8 3d 4c 00 00       	call   80105c8a <argstr>
8010104d:	85 c0                	test   %eax,%eax
8010104f:	78 17                	js     80101068 <sys_history+0x34>
80101051:	8d 45 f0             	lea    -0x10(%ebp),%eax
80101054:	89 44 24 04          	mov    %eax,0x4(%esp)
80101058:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010105f:	e8 96 4b 00 00       	call   80105bfa <argint>
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
801010ca:	e8 b8 48 00 00       	call   80105987 <memmove>
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
80101171:	e8 5c 72 00 00       	call   801083d2 <setupkvm>
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
80101212:	e8 89 75 00 00       	call   801087a0 <allocuvm>
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
80101250:	e8 60 74 00 00       	call   801086b5 <loaduvm>
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
801012be:	e8 dd 74 00 00       	call   801087a0 <allocuvm>
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
801012e3:	e8 e8 76 00 00       	call   801089d0 <clearpteu>
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
80101319:	e8 04 48 00 00       	call   80105b22 <strlen>
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
80101342:	e8 db 47 00 00       	call   80105b22 <strlen>
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
80101372:	e8 1e 78 00 00       	call   80108b95 <copyout>
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
80101419:	e8 77 77 00 00       	call   80108b95 <copyout>
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
80101471:	e8 62 46 00 00       	call   80105ad8 <safestrcpy>

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
801014c3:	e8 fb 6f 00 00       	call   801084c3 <switchuvm>
  freevm(oldpgdir);
801014c8:	8b 45 d0             	mov    -0x30(%ebp),%eax
801014cb:	89 04 24             	mov    %eax,(%esp)
801014ce:	e8 63 74 00 00       	call   80108936 <freevm>
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
801014e6:	e8 4b 74 00 00       	call   80108936 <freevm>
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
8010150e:	c7 44 24 04 a6 8c 10 	movl   $0x80108ca6,0x4(%esp)
80101515:	80 
80101516:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
8010151d:	e8 21 41 00 00       	call   80105643 <initlock>
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
80101531:	e8 2e 41 00 00       	call   80105664 <acquire>
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
8010155a:	e8 67 41 00 00       	call   801056c6 <release>
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
80101578:	e8 49 41 00 00       	call   801056c6 <release>
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
80101591:	e8 ce 40 00 00       	call   80105664 <acquire>
  if(f->ref < 1)
80101596:	8b 45 08             	mov    0x8(%ebp),%eax
80101599:	8b 40 04             	mov    0x4(%eax),%eax
8010159c:	85 c0                	test   %eax,%eax
8010159e:	7f 0c                	jg     801015ac <filedup+0x28>
    panic("filedup");
801015a0:	c7 04 24 ad 8c 10 80 	movl   $0x80108cad,(%esp)
801015a7:	e8 8e ef ff ff       	call   8010053a <panic>
  f->ref++;
801015ac:	8b 45 08             	mov    0x8(%ebp),%eax
801015af:	8b 40 04             	mov    0x4(%eax),%eax
801015b2:	8d 50 01             	lea    0x1(%eax),%edx
801015b5:	8b 45 08             	mov    0x8(%ebp),%eax
801015b8:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801015bb:	c7 04 24 80 20 11 80 	movl   $0x80112080,(%esp)
801015c2:	e8 ff 40 00 00       	call   801056c6 <release>
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
801015d9:	e8 86 40 00 00       	call   80105664 <acquire>
  if(f->ref < 1)
801015de:	8b 45 08             	mov    0x8(%ebp),%eax
801015e1:	8b 40 04             	mov    0x4(%eax),%eax
801015e4:	85 c0                	test   %eax,%eax
801015e6:	7f 0c                	jg     801015f4 <fileclose+0x28>
    panic("fileclose");
801015e8:	c7 04 24 b5 8c 10 80 	movl   $0x80108cb5,(%esp)
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
80101614:	e8 ad 40 00 00       	call   801056c6 <release>
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
8010165e:	e8 63 40 00 00       	call   801056c6 <release>
  
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
8010179f:	c7 04 24 bf 8c 10 80 	movl   $0x80108cbf,(%esp)
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
801018ab:	c7 04 24 c8 8c 10 80 	movl   $0x80108cc8,(%esp)
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
801018dd:	c7 04 24 d8 8c 10 80 	movl   $0x80108cd8,(%esp)
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
80101923:	e8 5f 40 00 00       	call   80105987 <memmove>
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
80101969:	e8 4a 3f 00 00       	call   801058b8 <memset>
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
80101ab6:	c7 04 24 e4 8c 10 80 	movl   $0x80108ce4,(%esp)
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
80101b45:	c7 04 24 fa 8c 10 80 	movl   $0x80108cfa,(%esp)
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
80101b98:	c7 44 24 04 0d 8d 10 	movl   $0x80108d0d,0x4(%esp)
80101b9f:	80 
80101ba0:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101ba7:	e8 97 3a 00 00       	call   80105643 <initlock>
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
80101c0c:	c7 04 24 14 8d 10 80 	movl   $0x80108d14,(%esp)
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
80101c8f:	e8 24 3c 00 00       	call   801058b8 <memset>
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
80101ce7:	c7 04 24 67 8d 10 80 	movl   $0x80108d67,(%esp)
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
80101d96:	e8 ec 3b 00 00       	call   80105987 <memmove>
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
80101dc0:	e8 9f 38 00 00       	call   80105664 <acquire>

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
80101e0a:	e8 b7 38 00 00       	call   801056c6 <release>
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
80101e3d:	c7 04 24 79 8d 10 80 	movl   $0x80108d79,(%esp)
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
80101e7b:	e8 46 38 00 00       	call   801056c6 <release>

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
80101e92:	e8 cd 37 00 00       	call   80105664 <acquire>
  ip->ref++;
80101e97:	8b 45 08             	mov    0x8(%ebp),%eax
80101e9a:	8b 40 08             	mov    0x8(%eax),%eax
80101e9d:	8d 50 01             	lea    0x1(%eax),%edx
80101ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea3:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ea6:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101ead:	e8 14 38 00 00       	call   801056c6 <release>
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
80101ecd:	c7 04 24 89 8d 10 80 	movl   $0x80108d89,(%esp)
80101ed4:	e8 61 e6 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101ed9:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80101ee0:	e8 7f 37 00 00       	call   80105664 <acquire>
  while(ip->flags & I_BUSY)
80101ee5:	eb 13                	jmp    80101efa <ilock+0x43>
    sleep(ip, &icache.lock);
80101ee7:	c7 44 24 04 a0 2a 11 	movl   $0x80112aa0,0x4(%esp)
80101eee:	80 
80101eef:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef2:	89 04 24             	mov    %eax,(%esp)
80101ef5:	e8 97 34 00 00       	call   80105391 <sleep>

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
80101f1f:	e8 a2 37 00 00       	call   801056c6 <release>

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
80101fd0:	e8 b2 39 00 00       	call   80105987 <memmove>
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
80101ffd:	c7 04 24 8f 8d 10 80 	movl   $0x80108d8f,(%esp)
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
8010202e:	c7 04 24 9e 8d 10 80 	movl   $0x80108d9e,(%esp)
80102035:	e8 00 e5 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
8010203a:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80102041:	e8 1e 36 00 00       	call   80105664 <acquire>
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
8010205d:	e8 0b 34 00 00       	call   8010546d <wakeup>
  release(&icache.lock);
80102062:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80102069:	e8 58 36 00 00       	call   801056c6 <release>
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
8010207d:	e8 e2 35 00 00       	call   80105664 <acquire>
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
801020bb:	c7 04 24 a6 8d 10 80 	movl   $0x80108da6,(%esp)
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
801020df:	e8 e2 35 00 00       	call   801056c6 <release>
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
8010210a:	e8 55 35 00 00       	call   80105664 <acquire>
    ip->flags = 0;
8010210f:	8b 45 08             	mov    0x8(%ebp),%eax
80102112:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102119:	8b 45 08             	mov    0x8(%ebp),%eax
8010211c:	89 04 24             	mov    %eax,(%esp)
8010211f:	e8 49 33 00 00       	call   8010546d <wakeup>
  }
  ip->ref--;
80102124:	8b 45 08             	mov    0x8(%ebp),%eax
80102127:	8b 40 08             	mov    0x8(%eax),%eax
8010212a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010212d:	8b 45 08             	mov    0x8(%ebp),%eax
80102130:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80102133:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
8010213a:	e8 87 35 00 00       	call   801056c6 <release>
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
8010225a:	c7 04 24 b0 8d 10 80 	movl   $0x80108db0,(%esp)
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
801024fb:	e8 87 34 00 00       	call   80105987 <memmove>
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
8010265a:	e8 28 33 00 00       	call   80105987 <memmove>
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
801026d8:	e8 4d 33 00 00       	call   80105a2a <strncmp>
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
801026f2:	c7 04 24 c3 8d 10 80 	movl   $0x80108dc3,(%esp)
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
80102730:	c7 04 24 d5 8d 10 80 	movl   $0x80108dd5,(%esp)
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
80102815:	c7 04 24 d5 8d 10 80 	movl   $0x80108dd5,(%esp)
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
8010285a:	e8 21 32 00 00       	call   80105a80 <strncpy>
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
8010288c:	c7 04 24 e2 8d 10 80 	movl   $0x80108de2,(%esp)
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
80102911:	e8 71 30 00 00       	call   80105987 <memmove>
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
8010292c:	e8 56 30 00 00       	call   80105987 <memmove>
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
80102b7b:	c7 44 24 04 ea 8d 10 	movl   $0x80108dea,0x4(%esp)
80102b82:	80 
80102b83:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102b8a:	e8 b4 2a 00 00       	call   80105643 <initlock>
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
80102c27:	c7 04 24 ee 8d 10 80 	movl   $0x80108dee,(%esp)
80102c2e:	e8 07 d9 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102c33:	8b 45 08             	mov    0x8(%ebp),%eax
80102c36:	8b 40 08             	mov    0x8(%eax),%eax
80102c39:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102c3e:	76 0c                	jbe    80102c4c <idestart+0x31>
    panic("incorrect blockno");
80102c40:	c7 04 24 f7 8d 10 80 	movl   $0x80108df7,(%esp)
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
80102c68:	c7 04 24 ee 8d 10 80 	movl   $0x80108dee,(%esp)
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
80102d84:	e8 db 28 00 00       	call   80105664 <acquire>
  if((b = idequeue) == 0){
80102d89:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102d8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102d91:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102d95:	75 11                	jne    80102da8 <ideintr+0x31>
    release(&idelock);
80102d97:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102d9e:	e8 23 29 00 00       	call   801056c6 <release>
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
80102e11:	e8 57 26 00 00       	call   8010546d <wakeup>
  
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
80102e33:	e8 8e 28 00 00       	call   801056c6 <release>
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
80102e4c:	c7 04 24 09 8e 10 80 	movl   $0x80108e09,(%esp)
80102e53:	e8 e2 d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102e58:	8b 45 08             	mov    0x8(%ebp),%eax
80102e5b:	8b 00                	mov    (%eax),%eax
80102e5d:	83 e0 06             	and    $0x6,%eax
80102e60:	83 f8 02             	cmp    $0x2,%eax
80102e63:	75 0c                	jne    80102e71 <iderw+0x37>
    panic("iderw: nothing to do");
80102e65:	c7 04 24 1d 8e 10 80 	movl   $0x80108e1d,(%esp)
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
80102e84:	c7 04 24 32 8e 10 80 	movl   $0x80108e32,(%esp)
80102e8b:	e8 aa d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102e90:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102e97:	e8 c8 27 00 00       	call   80105664 <acquire>

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
80102ef2:	e8 9a 24 00 00       	call   80105391 <sleep>
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
80102f0b:	e8 b6 27 00 00       	call   801056c6 <release>
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
80102f99:	c7 04 24 50 8e 10 80 	movl   $0x80108e50,(%esp)
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
80103053:	c7 44 24 04 82 8e 10 	movl   $0x80108e82,0x4(%esp)
8010305a:	80 
8010305b:	c7 04 24 80 3a 11 80 	movl   $0x80113a80,(%esp)
80103062:	e8 dc 25 00 00       	call   80105643 <initlock>
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
801030f4:	81 7d 08 9c 6d 11 80 	cmpl   $0x80116d9c,0x8(%ebp)
801030fb:	72 12                	jb     8010310f <kfree+0x2d>
801030fd:	8b 45 08             	mov    0x8(%ebp),%eax
80103100:	89 04 24             	mov    %eax,(%esp)
80103103:	e8 38 ff ff ff       	call   80103040 <v2p>
80103108:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
8010310d:	76 0c                	jbe    8010311b <kfree+0x39>
    panic("kfree");
8010310f:	c7 04 24 87 8e 10 80 	movl   $0x80108e87,(%esp)
80103116:	e8 1f d4 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
8010311b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103122:	00 
80103123:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010312a:	00 
8010312b:	8b 45 08             	mov    0x8(%ebp),%eax
8010312e:	89 04 24             	mov    %eax,(%esp)
80103131:	e8 82 27 00 00       	call   801058b8 <memset>

  if(kmem.use_lock)
80103136:	a1 b4 3a 11 80       	mov    0x80113ab4,%eax
8010313b:	85 c0                	test   %eax,%eax
8010313d:	74 0c                	je     8010314b <kfree+0x69>
    acquire(&kmem.lock);
8010313f:	c7 04 24 80 3a 11 80 	movl   $0x80113a80,(%esp)
80103146:	e8 19 25 00 00       	call   80105664 <acquire>
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
80103174:	e8 4d 25 00 00       	call   801056c6 <release>
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
80103191:	e8 ce 24 00 00       	call   80105664 <acquire>
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
801031be:	e8 03 25 00 00       	call   801056c6 <release>
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
8010353e:	c7 04 24 90 8e 10 80 	movl   $0x80108e90,(%esp)
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
801037a1:	e8 89 21 00 00       	call   8010592f <memcmp>
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
801038a1:	c7 44 24 04 bc 8e 10 	movl   $0x80108ebc,0x4(%esp)
801038a8:	80 
801038a9:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
801038b0:	e8 8e 1d 00 00       	call   80105643 <initlock>
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
8010395a:	e8 28 20 00 00       	call   80105987 <memmove>
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
80103aac:	e8 b3 1b 00 00       	call   80105664 <acquire>
  while(1){
    if(log.committing){
80103ab1:	a1 00 3b 11 80       	mov    0x80113b00,%eax
80103ab6:	85 c0                	test   %eax,%eax
80103ab8:	74 16                	je     80103ad0 <begin_op+0x31>
      sleep(&log, &log.lock);
80103aba:	c7 44 24 04 c0 3a 11 	movl   $0x80113ac0,0x4(%esp)
80103ac1:	80 
80103ac2:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103ac9:	e8 c3 18 00 00       	call   80105391 <sleep>
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
80103afd:	e8 8f 18 00 00       	call   80105391 <sleep>
80103b02:	eb 1b                	jmp    80103b1f <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103b04:	a1 fc 3a 11 80       	mov    0x80113afc,%eax
80103b09:	83 c0 01             	add    $0x1,%eax
80103b0c:	a3 fc 3a 11 80       	mov    %eax,0x80113afc
      release(&log.lock);
80103b11:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103b18:	e8 a9 1b 00 00       	call   801056c6 <release>
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
80103b37:	e8 28 1b 00 00       	call   80105664 <acquire>
  log.outstanding -= 1;
80103b3c:	a1 fc 3a 11 80       	mov    0x80113afc,%eax
80103b41:	83 e8 01             	sub    $0x1,%eax
80103b44:	a3 fc 3a 11 80       	mov    %eax,0x80113afc
  if(log.committing)
80103b49:	a1 00 3b 11 80       	mov    0x80113b00,%eax
80103b4e:	85 c0                	test   %eax,%eax
80103b50:	74 0c                	je     80103b5e <end_op+0x3b>
    panic("log.committing");
80103b52:	c7 04 24 c0 8e 10 80 	movl   $0x80108ec0,(%esp)
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
80103b81:	e8 e7 18 00 00       	call   8010546d <wakeup>
  }
  release(&log.lock);
80103b86:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103b8d:	e8 34 1b 00 00       	call   801056c6 <release>

  if(do_commit){
80103b92:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103b96:	74 33                	je     80103bcb <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103b98:	e8 de 00 00 00       	call   80103c7b <commit>
    acquire(&log.lock);
80103b9d:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103ba4:	e8 bb 1a 00 00       	call   80105664 <acquire>
    log.committing = 0;
80103ba9:	c7 05 00 3b 11 80 00 	movl   $0x0,0x80113b00
80103bb0:	00 00 00 
    wakeup(&log);
80103bb3:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103bba:	e8 ae 18 00 00       	call   8010546d <wakeup>
    release(&log.lock);
80103bbf:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103bc6:	e8 fb 1a 00 00       	call   801056c6 <release>
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
80103c41:	e8 41 1d 00 00       	call   80105987 <memmove>
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
80103ccc:	c7 04 24 cf 8e 10 80 	movl   $0x80108ecf,(%esp)
80103cd3:	e8 62 c8 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103cd8:	a1 fc 3a 11 80       	mov    0x80113afc,%eax
80103cdd:	85 c0                	test   %eax,%eax
80103cdf:	7f 0c                	jg     80103ced <log_write+0x43>
    panic("log_write outside of trans");
80103ce1:	c7 04 24 e5 8e 10 80 	movl   $0x80108ee5,(%esp)
80103ce8:	e8 4d c8 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103ced:	c7 04 24 c0 3a 11 80 	movl   $0x80113ac0,(%esp)
80103cf4:	e8 6b 19 00 00       	call   80105664 <acquire>
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
80103d6b:	e8 56 19 00 00       	call   801056c6 <release>
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
80103db7:	c7 04 24 9c 6d 11 80 	movl   $0x80116d9c,(%esp)
80103dbe:	e8 8a f2 ff ff       	call   8010304d <kinit1>
  kvmalloc();      // kernel page table
80103dc3:	e8 c7 46 00 00       	call   8010848f <kvmalloc>
  mpinit();        // collect info about this machine
80103dc8:	e8 41 04 00 00       	call   8010420e <mpinit>
  lapicinit();
80103dcd:	e8 e6 f5 ff ff       	call   801033b8 <lapicinit>
  seginit();       // set up segments
80103dd2:	e8 4b 40 00 00       	call   80107e22 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103dd7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ddd:	0f b6 00             	movzbl (%eax),%eax
80103de0:	0f b6 c0             	movzbl %al,%eax
80103de3:	89 44 24 04          	mov    %eax,0x4(%esp)
80103de7:	c7 04 24 00 8f 10 80 	movl   $0x80108f00,(%esp)
80103dee:	e8 ad c5 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103df3:	e8 74 06 00 00       	call   8010446c <picinit>
  ioapicinit();    // another interrupt controller
80103df8:	e8 46 f1 ff ff       	call   80102f43 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103dfd:	e8 d8 d1 ff ff       	call   80100fda <consoleinit>
  uartinit();      // serial port
80103e02:	e8 6a 33 00 00       	call   80107171 <uartinit>
  pinit();         // process table
80103e07:	e8 6a 0b 00 00       	call   80104976 <pinit>
  tvinit();        // trap vectors
80103e0c:	e8 0d 2f 00 00       	call   80106d1e <tvinit>
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
80103e29:	e8 3b 2e 00 00       	call   80106c69 <timerinit>
  startothers();   // start other processors
80103e2e:	e8 7f 00 00 00       	call   80103eb2 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103e33:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103e3a:	8e 
80103e3b:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103e42:	e8 3e f2 ff ff       	call   80103085 <kinit2>
  userinit();      // first user process
80103e47:	e8 48 0c 00 00       	call   80104a94 <userinit>
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
80103e57:	e8 4a 46 00 00       	call   801084a6 <switchkvm>
  seginit();
80103e5c:	e8 c1 3f 00 00       	call   80107e22 <seginit>
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
80103e81:	c7 04 24 17 8f 10 80 	movl   $0x80108f17,(%esp)
80103e88:	e8 13 c5 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103e8d:	e8 00 30 00 00       	call   80106e92 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103e92:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103e98:	05 a8 00 00 00       	add    $0xa8,%eax
80103e9d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103ea4:	00 
80103ea5:	89 04 24             	mov    %eax,(%esp)
80103ea8:	e8 df fe ff ff       	call   80103d8c <xchg>
  scheduler();     // start running processes
80103ead:	e8 21 13 00 00       	call   801051d3 <scheduler>

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
80103edf:	e8 a3 1a 00 00       	call   80105987 <memmove>

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
80104061:	c7 44 24 04 28 8f 10 	movl   $0x80108f28,0x4(%esp)
80104068:	80 
80104069:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010406c:	89 04 24             	mov    %eax,(%esp)
8010406f:	e8 bb 18 00 00       	call   8010592f <memcmp>
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
801041a2:	c7 44 24 04 2d 8f 10 	movl   $0x80108f2d,0x4(%esp)
801041a9:	80 
801041aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041ad:	89 04 24             	mov    %eax,(%esp)
801041b0:	e8 7a 17 00 00       	call   8010592f <memcmp>
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
8010427e:	8b 04 85 70 8f 10 80 	mov    -0x7fef7090(,%eax,4),%eax
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
801042b7:	c7 04 24 32 8f 10 80 	movl   $0x80108f32,(%esp)
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
8010434a:	c7 04 24 50 8f 10 80 	movl   $0x80108f50,(%esp)
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
80104643:	c7 44 24 04 84 8f 10 	movl   $0x80108f84,0x4(%esp)
8010464a:	80 
8010464b:	89 04 24             	mov    %eax,(%esp)
8010464e:	e8 f0 0f 00 00       	call   80105643 <initlock>
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
801046fa:	e8 65 0f 00 00       	call   80105664 <acquire>
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
8010471d:	e8 4b 0d 00 00       	call   8010546d <wakeup>
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
8010473c:	e8 2c 0d 00 00       	call   8010546d <wakeup>
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
80104761:	e8 60 0f 00 00       	call   801056c6 <release>
    kfree((char*)p);
80104766:	8b 45 08             	mov    0x8(%ebp),%eax
80104769:	89 04 24             	mov    %eax,(%esp)
8010476c:	e8 71 e9 ff ff       	call   801030e2 <kfree>
80104771:	eb 0b                	jmp    8010477e <pipeclose+0x90>
  } else
    release(&p->lock);
80104773:	8b 45 08             	mov    0x8(%ebp),%eax
80104776:	89 04 24             	mov    %eax,(%esp)
80104779:	e8 48 0f 00 00       	call   801056c6 <release>
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
8010478c:	e8 d3 0e 00 00       	call   80105664 <acquire>
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
801047bf:	e8 02 0f 00 00       	call   801056c6 <release>
        return -1;
801047c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047c9:	e9 9f 00 00 00       	jmp    8010486d <pipewrite+0xed>
      }
      wakeup(&p->nread);
801047ce:	8b 45 08             	mov    0x8(%ebp),%eax
801047d1:	05 34 02 00 00       	add    $0x234,%eax
801047d6:	89 04 24             	mov    %eax,(%esp)
801047d9:	e8 8f 0c 00 00       	call   8010546d <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801047de:	8b 45 08             	mov    0x8(%ebp),%eax
801047e1:	8b 55 08             	mov    0x8(%ebp),%edx
801047e4:	81 c2 38 02 00 00    	add    $0x238,%edx
801047ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801047ee:	89 14 24             	mov    %edx,(%esp)
801047f1:	e8 9b 0b 00 00       	call   80105391 <sleep>
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
8010485a:	e8 0e 0c 00 00       	call   8010546d <wakeup>
  release(&p->lock);
8010485f:	8b 45 08             	mov    0x8(%ebp),%eax
80104862:	89 04 24             	mov    %eax,(%esp)
80104865:	e8 5c 0e 00 00       	call   801056c6 <release>
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
8010487c:	e8 e3 0d 00 00       	call   80105664 <acquire>
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
80104896:	e8 2b 0e 00 00       	call   801056c6 <release>
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
801048b8:	e8 d4 0a 00 00       	call   80105391 <sleep>
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
80104947:	e8 21 0b 00 00       	call   8010546d <wakeup>
  release(&p->lock);
8010494c:	8b 45 08             	mov    0x8(%ebp),%eax
8010494f:	89 04 24             	mov    %eax,(%esp)
80104952:	e8 6f 0d 00 00       	call   801056c6 <release>
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
8010497c:	c7 44 24 04 89 8f 10 	movl   $0x80108f89,0x4(%esp)
80104983:	80 
80104984:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010498b:	e8 b3 0c 00 00       	call   80105643 <initlock>
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
8010499f:	e8 c0 0c 00 00       	call   80105664 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801049a4:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
801049ab:	eb 53                	jmp    80104a00 <allocproc+0x6e>
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
801049dd:	e8 e4 0c 00 00       	call   801056c6 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801049e2:	e8 94 e7 ff ff       	call   8010317b <kalloc>
801049e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049ea:	89 42 08             	mov    %eax,0x8(%edx)
801049ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049f0:	8b 40 08             	mov    0x8(%eax),%eax
801049f3:	85 c0                	test   %eax,%eax
801049f5:	75 36                	jne    80104a2d <allocproc+0x9b>
801049f7:	eb 23                	jmp    80104a1c <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801049f9:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104a00:	81 7d f4 f4 64 11 80 	cmpl   $0x801164f4,-0xc(%ebp)
80104a07:	72 a4                	jb     801049ad <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104a09:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104a10:	e8 b1 0c 00 00       	call   801056c6 <release>
  return 0;
80104a15:	b8 00 00 00 00       	mov    $0x0,%eax
80104a1a:	eb 76                	jmp    80104a92 <allocproc+0x100>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
80104a1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a1f:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104a26:	b8 00 00 00 00       	mov    $0x0,%eax
80104a2b:	eb 65                	jmp    80104a92 <allocproc+0x100>
  }
  sp = p->kstack + KSTACKSIZE;
80104a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a30:	8b 40 08             	mov    0x8(%eax),%eax
80104a33:	05 00 10 00 00       	add    $0x1000,%eax
80104a38:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104a3b:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104a3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a42:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104a45:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104a48:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104a4c:	ba d9 6c 10 80       	mov    $0x80106cd9,%edx
80104a51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a54:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104a56:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104a60:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a66:	8b 40 1c             	mov    0x1c(%eax),%eax
80104a69:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104a70:	00 
80104a71:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104a78:	00 
80104a79:	89 04 24             	mov    %eax,(%esp)
80104a7c:	e8 37 0e 00 00       	call   801058b8 <memset>
  p->context->eip = (uint)forkret;
80104a81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a84:	8b 40 1c             	mov    0x1c(%eax),%eax
80104a87:	ba 52 53 10 80       	mov    $0x80105352,%edx
80104a8c:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104a8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a92:	c9                   	leave  
80104a93:	c3                   	ret    

80104a94 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104a94:	55                   	push   %ebp
80104a95:	89 e5                	mov    %esp,%ebp
80104a97:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104a9a:	e8 f3 fe ff ff       	call   80104992 <allocproc>
80104a9f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104aa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa5:	a3 48 c6 10 80       	mov    %eax,0x8010c648
  if((p->pgdir = setupkvm()) == 0)
80104aaa:	e8 23 39 00 00       	call   801083d2 <setupkvm>
80104aaf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ab2:	89 42 04             	mov    %eax,0x4(%edx)
80104ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab8:	8b 40 04             	mov    0x4(%eax),%eax
80104abb:	85 c0                	test   %eax,%eax
80104abd:	75 0c                	jne    80104acb <userinit+0x37>
    panic("userinit: out of memory?");
80104abf:	c7 04 24 90 8f 10 80 	movl   $0x80108f90,(%esp)
80104ac6:	e8 6f ba ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104acb:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104ad0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad3:	8b 40 04             	mov    0x4(%eax),%eax
80104ad6:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ada:	c7 44 24 04 e0 c4 10 	movl   $0x8010c4e0,0x4(%esp)
80104ae1:	80 
80104ae2:	89 04 24             	mov    %eax,(%esp)
80104ae5:	e8 40 3b 00 00       	call   8010862a <inituvm>
  p->sz = PGSIZE;
80104aea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aed:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104af3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104af6:	8b 40 18             	mov    0x18(%eax),%eax
80104af9:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104b00:	00 
80104b01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b08:	00 
80104b09:	89 04 24             	mov    %eax,(%esp)
80104b0c:	e8 a7 0d 00 00       	call   801058b8 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104b11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b14:	8b 40 18             	mov    0x18(%eax),%eax
80104b17:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104b1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b20:	8b 40 18             	mov    0x18(%eax),%eax
80104b23:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104b29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b2c:	8b 40 18             	mov    0x18(%eax),%eax
80104b2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b32:	8b 52 18             	mov    0x18(%edx),%edx
80104b35:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104b39:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104b3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b40:	8b 40 18             	mov    0x18(%eax),%eax
80104b43:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b46:	8b 52 18             	mov    0x18(%edx),%edx
80104b49:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104b4d:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104b51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b54:	8b 40 18             	mov    0x18(%eax),%eax
80104b57:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104b5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b61:	8b 40 18             	mov    0x18(%eax),%eax
80104b64:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104b6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b6e:	8b 40 18             	mov    0x18(%eax),%eax
80104b71:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104b78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b7b:	83 c0 6c             	add    $0x6c,%eax
80104b7e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104b85:	00 
80104b86:	c7 44 24 04 a9 8f 10 	movl   $0x80108fa9,0x4(%esp)
80104b8d:	80 
80104b8e:	89 04 24             	mov    %eax,(%esp)
80104b91:	e8 42 0f 00 00       	call   80105ad8 <safestrcpy>
  p->cwd = namei("/");
80104b96:	c7 04 24 b2 8f 10 80 	movl   $0x80108fb2,(%esp)
80104b9d:	e8 c6 de ff ff       	call   80102a68 <namei>
80104ba2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ba5:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104ba8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bab:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104bb2:	c9                   	leave  
80104bb3:	c3                   	ret    

80104bb4 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104bb4:	55                   	push   %ebp
80104bb5:	89 e5                	mov    %esp,%ebp
80104bb7:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104bba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bc0:	8b 00                	mov    (%eax),%eax
80104bc2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104bc5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104bc9:	7e 34                	jle    80104bff <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104bcb:	8b 55 08             	mov    0x8(%ebp),%edx
80104bce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bd1:	01 c2                	add    %eax,%edx
80104bd3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bd9:	8b 40 04             	mov    0x4(%eax),%eax
80104bdc:	89 54 24 08          	mov    %edx,0x8(%esp)
80104be0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104be3:	89 54 24 04          	mov    %edx,0x4(%esp)
80104be7:	89 04 24             	mov    %eax,(%esp)
80104bea:	e8 b1 3b 00 00       	call   801087a0 <allocuvm>
80104bef:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104bf2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104bf6:	75 41                	jne    80104c39 <growproc+0x85>
      return -1;
80104bf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bfd:	eb 58                	jmp    80104c57 <growproc+0xa3>
  } else if(n < 0){
80104bff:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104c03:	79 34                	jns    80104c39 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104c05:	8b 55 08             	mov    0x8(%ebp),%edx
80104c08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c0b:	01 c2                	add    %eax,%edx
80104c0d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c13:	8b 40 04             	mov    0x4(%eax),%eax
80104c16:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c1a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c1d:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c21:	89 04 24             	mov    %eax,(%esp)
80104c24:	e8 51 3c 00 00       	call   8010887a <deallocuvm>
80104c29:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104c2c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104c30:	75 07                	jne    80104c39 <growproc+0x85>
      return -1;
80104c32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c37:	eb 1e                	jmp    80104c57 <growproc+0xa3>
  }
  proc->sz = sz;
80104c39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c3f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c42:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104c44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c4a:	89 04 24             	mov    %eax,(%esp)
80104c4d:	e8 71 38 00 00       	call   801084c3 <switchuvm>
  return 0;
80104c52:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c57:	c9                   	leave  
80104c58:	c3                   	ret    

80104c59 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104c59:	55                   	push   %ebp
80104c5a:	89 e5                	mov    %esp,%ebp
80104c5c:	57                   	push   %edi
80104c5d:	56                   	push   %esi
80104c5e:	53                   	push   %ebx
80104c5f:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104c62:	e8 2b fd ff ff       	call   80104992 <allocproc>
80104c67:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104c6a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104c6e:	75 0a                	jne    80104c7a <fork+0x21>
    return -1;
80104c70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c75:	e9 86 01 00 00       	jmp    80104e00 <fork+0x1a7>
  np->ctime = ticks;
80104c7a:	a1 40 6d 11 80       	mov    0x80116d40,%eax
80104c7f:	89 c2                	mov    %eax,%edx
80104c81:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c84:	89 50 7c             	mov    %edx,0x7c(%eax)
  np->stime = 0;
80104c87:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c8a:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104c91:	00 00 00 
  np->retime = 0;
80104c94:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c97:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104c9e:	00 00 00 
  np->rutime = 0;
80104ca1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ca4:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104cab:	00 00 00 
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104cae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cb4:	8b 10                	mov    (%eax),%edx
80104cb6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cbc:	8b 40 04             	mov    0x4(%eax),%eax
80104cbf:	89 54 24 04          	mov    %edx,0x4(%esp)
80104cc3:	89 04 24             	mov    %eax,(%esp)
80104cc6:	e8 4b 3d 00 00       	call   80108a16 <copyuvm>
80104ccb:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104cce:	89 42 04             	mov    %eax,0x4(%edx)
80104cd1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cd4:	8b 40 04             	mov    0x4(%eax),%eax
80104cd7:	85 c0                	test   %eax,%eax
80104cd9:	75 2c                	jne    80104d07 <fork+0xae>
    kfree(np->kstack);
80104cdb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cde:	8b 40 08             	mov    0x8(%eax),%eax
80104ce1:	89 04 24             	mov    %eax,(%esp)
80104ce4:	e8 f9 e3 ff ff       	call   801030e2 <kfree>
    np->kstack = 0;
80104ce9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cec:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104cf3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cf6:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104cfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d02:	e9 f9 00 00 00       	jmp    80104e00 <fork+0x1a7>
  }
  np->sz = proc->sz;
80104d07:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d0d:	8b 10                	mov    (%eax),%edx
80104d0f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104d12:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104d14:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104d1b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104d1e:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104d21:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104d24:	8b 50 18             	mov    0x18(%eax),%edx
80104d27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d2d:	8b 40 18             	mov    0x18(%eax),%eax
80104d30:	89 c3                	mov    %eax,%ebx
80104d32:	b8 13 00 00 00       	mov    $0x13,%eax
80104d37:	89 d7                	mov    %edx,%edi
80104d39:	89 de                	mov    %ebx,%esi
80104d3b:	89 c1                	mov    %eax,%ecx
80104d3d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104d3f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104d42:	8b 40 18             	mov    0x18(%eax),%eax
80104d45:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104d4c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104d53:	eb 3d                	jmp    80104d92 <fork+0x139>
    if(proc->ofile[i])
80104d55:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d5b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104d5e:	83 c2 08             	add    $0x8,%edx
80104d61:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104d65:	85 c0                	test   %eax,%eax
80104d67:	74 25                	je     80104d8e <fork+0x135>
      np->ofile[i] = filedup(proc->ofile[i]);
80104d69:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d6f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104d72:	83 c2 08             	add    $0x8,%edx
80104d75:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104d79:	89 04 24             	mov    %eax,(%esp)
80104d7c:	e8 03 c8 ff ff       	call   80101584 <filedup>
80104d81:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104d84:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104d87:	83 c1 08             	add    $0x8,%ecx
80104d8a:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104d8e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104d92:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104d96:	7e bd                	jle    80104d55 <fork+0xfc>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104d98:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d9e:	8b 40 68             	mov    0x68(%eax),%eax
80104da1:	89 04 24             	mov    %eax,(%esp)
80104da4:	e8 dc d0 ff ff       	call   80101e85 <idup>
80104da9:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104dac:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104daf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104db5:	8d 50 6c             	lea    0x6c(%eax),%edx
80104db8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104dbb:	83 c0 6c             	add    $0x6c,%eax
80104dbe:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104dc5:	00 
80104dc6:	89 54 24 04          	mov    %edx,0x4(%esp)
80104dca:	89 04 24             	mov    %eax,(%esp)
80104dcd:	e8 06 0d 00 00       	call   80105ad8 <safestrcpy>
 
  pid = np->pid;
80104dd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104dd5:	8b 40 10             	mov    0x10(%eax),%eax
80104dd8:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
80104ddb:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104de2:	e8 7d 08 00 00       	call   80105664 <acquire>
  np->state = RUNNABLE;
80104de7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104dea:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
80104df1:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104df8:	e8 c9 08 00 00       	call   801056c6 <release>
  
  return pid;
80104dfd:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104e00:	83 c4 2c             	add    $0x2c,%esp
80104e03:	5b                   	pop    %ebx
80104e04:	5e                   	pop    %esi
80104e05:	5f                   	pop    %edi
80104e06:	5d                   	pop    %ebp
80104e07:	c3                   	ret    

80104e08 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104e08:	55                   	push   %ebp
80104e09:	89 e5                	mov    %esp,%ebp
80104e0b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104e0e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e15:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104e1a:	39 c2                	cmp    %eax,%edx
80104e1c:	75 0c                	jne    80104e2a <exit+0x22>
    panic("init exiting");
80104e1e:	c7 04 24 b4 8f 10 80 	movl   $0x80108fb4,(%esp)
80104e25:	e8 10 b7 ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104e2a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104e31:	eb 44                	jmp    80104e77 <exit+0x6f>
    if(proc->ofile[fd]){
80104e33:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e39:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e3c:	83 c2 08             	add    $0x8,%edx
80104e3f:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e43:	85 c0                	test   %eax,%eax
80104e45:	74 2c                	je     80104e73 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104e47:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e4d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e50:	83 c2 08             	add    $0x8,%edx
80104e53:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e57:	89 04 24             	mov    %eax,(%esp)
80104e5a:	e8 6d c7 ff ff       	call   801015cc <fileclose>
      proc->ofile[fd] = 0;
80104e5f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e65:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e68:	83 c2 08             	add    $0x8,%edx
80104e6b:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104e72:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104e73:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104e77:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104e7b:	7e b6                	jle    80104e33 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
80104e7d:	e8 1d ec ff ff       	call   80103a9f <begin_op>
  iput(proc->cwd);
80104e82:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e88:	8b 40 68             	mov    0x68(%eax),%eax
80104e8b:	89 04 24             	mov    %eax,(%esp)
80104e8e:	e8 dd d1 ff ff       	call   80102070 <iput>
  end_op();
80104e93:	e8 8b ec ff ff       	call   80103b23 <end_op>
  proc->cwd = 0;
80104e98:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e9e:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104ea5:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104eac:	e8 b3 07 00 00       	call   80105664 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104eb1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eb7:	8b 40 14             	mov    0x14(%eax),%eax
80104eba:	89 04 24             	mov    %eax,(%esp)
80104ebd:	e8 6a 05 00 00       	call   8010542c <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ec2:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
80104ec9:	eb 3b                	jmp    80104f06 <exit+0xfe>
    if(p->parent == proc){
80104ecb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ece:	8b 50 14             	mov    0x14(%eax),%edx
80104ed1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ed7:	39 c2                	cmp    %eax,%edx
80104ed9:	75 24                	jne    80104eff <exit+0xf7>
      p->parent = initproc;
80104edb:	8b 15 48 c6 10 80    	mov    0x8010c648,%edx
80104ee1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ee4:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104ee7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eea:	8b 40 0c             	mov    0xc(%eax),%eax
80104eed:	83 f8 05             	cmp    $0x5,%eax
80104ef0:	75 0d                	jne    80104eff <exit+0xf7>
        wakeup1(initproc);
80104ef2:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104ef7:	89 04 24             	mov    %eax,(%esp)
80104efa:	e8 2d 05 00 00       	call   8010542c <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104eff:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104f06:	81 7d f4 f4 64 11 80 	cmpl   $0x801164f4,-0xc(%ebp)
80104f0d:	72 bc                	jb     80104ecb <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104f0f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f15:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104f1c:	e8 4d 03 00 00       	call   8010526e <sched>
  panic("zombie exit");
80104f21:	c7 04 24 c1 8f 10 80 	movl   $0x80108fc1,(%esp)
80104f28:	e8 0d b6 ff ff       	call   8010053a <panic>

80104f2d <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104f2d:	55                   	push   %ebp
80104f2e:	89 e5                	mov    %esp,%ebp
80104f30:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104f33:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104f3a:	e8 25 07 00 00       	call   80105664 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104f3f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f46:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
80104f4d:	e9 9d 00 00 00       	jmp    80104fef <wait+0xc2>
      if(p->parent != proc)
80104f52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f55:	8b 50 14             	mov    0x14(%eax),%edx
80104f58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f5e:	39 c2                	cmp    %eax,%edx
80104f60:	74 05                	je     80104f67 <wait+0x3a>
        continue;
80104f62:	e9 81 00 00 00       	jmp    80104fe8 <wait+0xbb>
      havekids = 1;
80104f67:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104f6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f71:	8b 40 0c             	mov    0xc(%eax),%eax
80104f74:	83 f8 05             	cmp    $0x5,%eax
80104f77:	75 6f                	jne    80104fe8 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104f79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f7c:	8b 40 10             	mov    0x10(%eax),%eax
80104f7f:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104f82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f85:	8b 40 08             	mov    0x8(%eax),%eax
80104f88:	89 04 24             	mov    %eax,(%esp)
80104f8b:	e8 52 e1 ff ff       	call   801030e2 <kfree>
        p->kstack = 0;
80104f90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f93:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104f9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f9d:	8b 40 04             	mov    0x4(%eax),%eax
80104fa0:	89 04 24             	mov    %eax,(%esp)
80104fa3:	e8 8e 39 00 00       	call   80108936 <freevm>
        p->state = UNUSED;
80104fa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fab:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104fb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fb5:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104fbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fbf:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104fc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fc9:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104fcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fd0:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104fd7:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80104fde:	e8 e3 06 00 00       	call   801056c6 <release>
        return pid;
80104fe3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104fe6:	eb 55                	jmp    8010503d <wait+0x110>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104fe8:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104fef:	81 7d f4 f4 64 11 80 	cmpl   $0x801164f4,-0xc(%ebp)
80104ff6:	0f 82 56 ff ff ff    	jb     80104f52 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104ffc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105000:	74 0d                	je     8010500f <wait+0xe2>
80105002:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105008:	8b 40 24             	mov    0x24(%eax),%eax
8010500b:	85 c0                	test   %eax,%eax
8010500d:	74 13                	je     80105022 <wait+0xf5>
      release(&ptable.lock);
8010500f:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105016:	e8 ab 06 00 00       	call   801056c6 <release>
      return -1;
8010501b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105020:	eb 1b                	jmp    8010503d <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105022:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105028:	c7 44 24 04 c0 41 11 	movl   $0x801141c0,0x4(%esp)
8010502f:	80 
80105030:	89 04 24             	mov    %eax,(%esp)
80105033:	e8 59 03 00 00       	call   80105391 <sleep>
  }
80105038:	e9 02 ff ff ff       	jmp    80104f3f <wait+0x12>
}
8010503d:	c9                   	leave  
8010503e:	c3                   	ret    

8010503f <wait2>:

int wait2(void) {
8010503f:	55                   	push   %ebp
80105040:	89 e5                	mov    %esp,%ebp
80105042:	83 ec 38             	sub    $0x38,%esp
  char *retime, *rutime, *stime;
  int pid = 0;
80105045:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  struct proc * p;
  if(argptr(0,&retime,sizeof(int)) < 0
8010504c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80105053:	00 
80105054:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105057:	89 44 24 04          	mov    %eax,0x4(%esp)
8010505b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105062:	e8 c1 0b 00 00       	call   80105c28 <argptr>
80105067:	85 c0                	test   %eax,%eax
80105069:	78 3e                	js     801050a9 <wait2+0x6a>
      || argptr(1,&rutime,sizeof(int)) < 0
8010506b:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80105072:	00 
80105073:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105076:	89 44 24 04          	mov    %eax,0x4(%esp)
8010507a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105081:	e8 a2 0b 00 00       	call   80105c28 <argptr>
80105086:	85 c0                	test   %eax,%eax
80105088:	78 1f                	js     801050a9 <wait2+0x6a>
      || argptr(2,&stime,sizeof(int)) < 0) 
8010508a:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80105091:	00 
80105092:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105095:	89 44 24 04          	mov    %eax,0x4(%esp)
80105099:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801050a0:	e8 83 0b 00 00       	call   80105c28 <argptr>
801050a5:	85 c0                	test   %eax,%eax
801050a7:	79 0a                	jns    801050b3 <wait2+0x74>
    return -1;
801050a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050ae:	e9 8a 00 00 00       	jmp    8010513d <wait2+0xfe>
  pid = wait(); 
801050b3:	e8 75 fe ff ff       	call   80104f2d <wait>
801050b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  // now we have athe pid of a child  process - now we can 
  // find it in the ptable and foo foo 
  acquire(&ptable.lock);
801050bb:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801050c2:	e8 9d 05 00 00       	call   80105664 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC] && pid > 0; ++p) 
801050c7:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
801050ce:	eb 4d                	jmp    8010511d <wait2+0xde>
    if(p->pid == pid){ //found the child 
801050d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050d3:	8b 40 10             	mov    0x10(%eax),%eax
801050d6:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801050d9:	75 3b                	jne    80105116 <wait2+0xd7>
      *retime = p->retime;
801050db:	8b 45 ec             	mov    -0x14(%ebp),%eax
801050de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050e1:	8b 92 84 00 00 00    	mov    0x84(%edx),%edx
801050e7:	88 10                	mov    %dl,(%eax)
      *rutime = p->rutime;
801050e9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801050ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050ef:	8b 92 88 00 00 00    	mov    0x88(%edx),%edx
801050f5:	88 10                	mov    %dl,(%eax)
      *stime = p->stime;
801050f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801050fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050fd:	8b 92 80 00 00 00    	mov    0x80(%edx),%edx
80105103:	88 10                	mov    %dl,(%eax)
      release(&ptable.lock);
80105105:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010510c:	e8 b5 05 00 00       	call   801056c6 <release>
      return pid;
80105111:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105114:	eb 27                	jmp    8010513d <wait2+0xfe>
    return -1;
  pid = wait(); 
  // now we have athe pid of a child  process - now we can 
  // find it in the ptable and foo foo 
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC] && pid > 0; ++p) 
80105116:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
8010511d:	81 7d f4 f4 64 11 80 	cmpl   $0x801164f4,-0xc(%ebp)
80105124:	73 06                	jae    8010512c <wait2+0xed>
80105126:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010512a:	7f a4                	jg     801050d0 <wait2+0x91>
      *rutime = p->rutime;
      *stime = p->stime;
      release(&ptable.lock);
      return pid;
    }
  release(&ptable.lock);
8010512c:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105133:	e8 8e 05 00 00       	call   801056c6 <release>
  return -1;
80105138:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010513d:	c9                   	leave  
8010513e:	c3                   	ret    

8010513f <increment_process_times>:
// This method is icrements the time fields for all the processes
// each tick, it is called in trap.c when we increment the total amount of 
// ticks we lock the ptable here!
//
void increment_process_times(void) {
8010513f:	55                   	push   %ebp
80105140:	89 e5                	mov    %esp,%ebp
80105142:	83 ec 28             	sub    $0x28,%esp
  struct proc * p;
  acquire(&ptable.lock);
80105145:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010514c:	e8 13 05 00 00       	call   80105664 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; ++p)
80105151:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
80105158:	eb 62                	jmp    801051bc <increment_process_times+0x7d>
    switch (p->state) {
8010515a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010515d:	8b 40 0c             	mov    0xc(%eax),%eax
80105160:	83 f8 03             	cmp    $0x3,%eax
80105163:	74 3a                	je     8010519f <increment_process_times+0x60>
80105165:	83 f8 04             	cmp    $0x4,%eax
80105168:	74 1e                	je     80105188 <increment_process_times+0x49>
8010516a:	83 f8 02             	cmp    $0x2,%eax
8010516d:	74 02                	je     80105171 <increment_process_times+0x32>
      break;
      case RUNNABLE:
        ++p->retime;
      break;
      default:
      break;
8010516f:	eb 44                	jmp    801051b5 <increment_process_times+0x76>
  struct proc * p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; ++p)
    switch (p->state) {
      case SLEEPING:
        ++p->stime;
80105171:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105174:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
8010517a:	8d 50 01             	lea    0x1(%eax),%edx
8010517d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105180:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      break;
80105186:	eb 2d                	jmp    801051b5 <increment_process_times+0x76>
      case RUNNING:
        ++p->rutime;
80105188:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010518b:	8b 80 88 00 00 00    	mov    0x88(%eax),%eax
80105191:	8d 50 01             	lea    0x1(%eax),%edx
80105194:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105197:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
      break;
8010519d:	eb 16                	jmp    801051b5 <increment_process_times+0x76>
      case RUNNABLE:
        ++p->retime;
8010519f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051a2:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
801051a8:	8d 50 01             	lea    0x1(%eax),%edx
801051ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ae:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
      break;
801051b4:	90                   	nop
// ticks we lock the ptable here!
//
void increment_process_times(void) {
  struct proc * p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; ++p)
801051b5:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
801051bc:	81 7d f4 f4 64 11 80 	cmpl   $0x801164f4,-0xc(%ebp)
801051c3:	72 95                	jb     8010515a <increment_process_times+0x1b>
        ++p->retime;
      break;
      default:
      break;
    }
   release(&ptable.lock);  
801051c5:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801051cc:	e8 f5 04 00 00       	call   801056c6 <release>
}
801051d1:	c9                   	leave  
801051d2:	c3                   	ret    

801051d3 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801051d3:	55                   	push   %ebp
801051d4:	89 e5                	mov    %esp,%ebp
801051d6:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801051d9:	e8 92 f7 ff ff       	call   80104970 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801051de:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801051e5:	e8 7a 04 00 00       	call   80105664 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051ea:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
801051f1:	eb 61                	jmp    80105254 <scheduler+0x81>
      if(p->state != RUNNABLE)
801051f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051f6:	8b 40 0c             	mov    0xc(%eax),%eax
801051f9:	83 f8 03             	cmp    $0x3,%eax
801051fc:	74 02                	je     80105200 <scheduler+0x2d>
        continue;
801051fe:	eb 4d                	jmp    8010524d <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80105200:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105203:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80105209:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010520c:	89 04 24             	mov    %eax,(%esp)
8010520f:	e8 af 32 00 00       	call   801084c3 <switchuvm>
      p->state = RUNNING;
80105214:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105217:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
8010521e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105224:	8b 40 1c             	mov    0x1c(%eax),%eax
80105227:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010522e:	83 c2 04             	add    $0x4,%edx
80105231:	89 44 24 04          	mov    %eax,0x4(%esp)
80105235:	89 14 24             	mov    %edx,(%esp)
80105238:	e8 0c 09 00 00       	call   80105b49 <swtch>
      switchkvm();
8010523d:	e8 64 32 00 00       	call   801084a6 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105242:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105249:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010524d:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80105254:	81 7d f4 f4 64 11 80 	cmpl   $0x801164f4,-0xc(%ebp)
8010525b:	72 96                	jb     801051f3 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
8010525d:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105264:	e8 5d 04 00 00       	call   801056c6 <release>

  }
80105269:	e9 6b ff ff ff       	jmp    801051d9 <scheduler+0x6>

8010526e <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
8010526e:	55                   	push   %ebp
8010526f:	89 e5                	mov    %esp,%ebp
80105271:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105274:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010527b:	e8 0e 05 00 00       	call   8010578e <holding>
80105280:	85 c0                	test   %eax,%eax
80105282:	75 0c                	jne    80105290 <sched+0x22>
    panic("sched ptable.lock");
80105284:	c7 04 24 cd 8f 10 80 	movl   $0x80108fcd,(%esp)
8010528b:	e8 aa b2 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80105290:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105296:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010529c:	83 f8 01             	cmp    $0x1,%eax
8010529f:	74 0c                	je     801052ad <sched+0x3f>
    panic("sched locks");
801052a1:	c7 04 24 df 8f 10 80 	movl   $0x80108fdf,(%esp)
801052a8:	e8 8d b2 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
801052ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052b3:	8b 40 0c             	mov    0xc(%eax),%eax
801052b6:	83 f8 04             	cmp    $0x4,%eax
801052b9:	75 0c                	jne    801052c7 <sched+0x59>
    panic("sched running");
801052bb:	c7 04 24 eb 8f 10 80 	movl   $0x80108feb,(%esp)
801052c2:	e8 73 b2 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
801052c7:	e8 94 f6 ff ff       	call   80104960 <readeflags>
801052cc:	25 00 02 00 00       	and    $0x200,%eax
801052d1:	85 c0                	test   %eax,%eax
801052d3:	74 0c                	je     801052e1 <sched+0x73>
    panic("sched interruptible");
801052d5:	c7 04 24 f9 8f 10 80 	movl   $0x80108ff9,(%esp)
801052dc:	e8 59 b2 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
801052e1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052e7:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801052ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801052f0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052f6:	8b 40 04             	mov    0x4(%eax),%eax
801052f9:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105300:	83 c2 1c             	add    $0x1c,%edx
80105303:	89 44 24 04          	mov    %eax,0x4(%esp)
80105307:	89 14 24             	mov    %edx,(%esp)
8010530a:	e8 3a 08 00 00       	call   80105b49 <swtch>
  cpu->intena = intena;
8010530f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105315:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105318:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010531e:	c9                   	leave  
8010531f:	c3                   	ret    

80105320 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105320:	55                   	push   %ebp
80105321:	89 e5                	mov    %esp,%ebp
80105323:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105326:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010532d:	e8 32 03 00 00       	call   80105664 <acquire>
  proc->state = RUNNABLE;
80105332:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105338:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010533f:	e8 2a ff ff ff       	call   8010526e <sched>
  release(&ptable.lock);
80105344:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010534b:	e8 76 03 00 00       	call   801056c6 <release>
}
80105350:	c9                   	leave  
80105351:	c3                   	ret    

80105352 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105352:	55                   	push   %ebp
80105353:	89 e5                	mov    %esp,%ebp
80105355:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105358:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010535f:	e8 62 03 00 00       	call   801056c6 <release>

  if (first) {
80105364:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80105369:	85 c0                	test   %eax,%eax
8010536b:	74 22                	je     8010538f <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010536d:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
80105374:	00 00 00 
    iinit(ROOTDEV);
80105377:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010537e:	e8 0c c8 ff ff       	call   80101b8f <iinit>
    initlog(ROOTDEV);
80105383:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010538a:	e8 0c e5 ff ff       	call   8010389b <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
8010538f:	c9                   	leave  
80105390:	c3                   	ret    

80105391 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105391:	55                   	push   %ebp
80105392:	89 e5                	mov    %esp,%ebp
80105394:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105397:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010539d:	85 c0                	test   %eax,%eax
8010539f:	75 0c                	jne    801053ad <sleep+0x1c>
    panic("sleep");
801053a1:	c7 04 24 0d 90 10 80 	movl   $0x8010900d,(%esp)
801053a8:	e8 8d b1 ff ff       	call   8010053a <panic>

  if(lk == 0)
801053ad:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801053b1:	75 0c                	jne    801053bf <sleep+0x2e>
    panic("sleep without lk");
801053b3:	c7 04 24 13 90 10 80 	movl   $0x80109013,(%esp)
801053ba:	e8 7b b1 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801053bf:	81 7d 0c c0 41 11 80 	cmpl   $0x801141c0,0xc(%ebp)
801053c6:	74 17                	je     801053df <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801053c8:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801053cf:	e8 90 02 00 00       	call   80105664 <acquire>
    release(lk);
801053d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801053d7:	89 04 24             	mov    %eax,(%esp)
801053da:	e8 e7 02 00 00       	call   801056c6 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801053df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053e5:	8b 55 08             	mov    0x8(%ebp),%edx
801053e8:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801053eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053f1:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801053f8:	e8 71 fe ff ff       	call   8010526e <sched>

  // Tidy up.
  proc->chan = 0;
801053fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105403:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
8010540a:	81 7d 0c c0 41 11 80 	cmpl   $0x801141c0,0xc(%ebp)
80105411:	74 17                	je     8010542a <sleep+0x99>
    release(&ptable.lock);
80105413:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010541a:	e8 a7 02 00 00       	call   801056c6 <release>
    acquire(lk);
8010541f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105422:	89 04 24             	mov    %eax,(%esp)
80105425:	e8 3a 02 00 00       	call   80105664 <acquire>
  }
}
8010542a:	c9                   	leave  
8010542b:	c3                   	ret    

8010542c <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
8010542c:	55                   	push   %ebp
8010542d:	89 e5                	mov    %esp,%ebp
8010542f:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105432:	c7 45 fc f4 41 11 80 	movl   $0x801141f4,-0x4(%ebp)
80105439:	eb 27                	jmp    80105462 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
8010543b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010543e:	8b 40 0c             	mov    0xc(%eax),%eax
80105441:	83 f8 02             	cmp    $0x2,%eax
80105444:	75 15                	jne    8010545b <wakeup1+0x2f>
80105446:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105449:	8b 40 20             	mov    0x20(%eax),%eax
8010544c:	3b 45 08             	cmp    0x8(%ebp),%eax
8010544f:	75 0a                	jne    8010545b <wakeup1+0x2f>
      p->state = RUNNABLE;
80105451:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105454:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010545b:	81 45 fc 8c 00 00 00 	addl   $0x8c,-0x4(%ebp)
80105462:	81 7d fc f4 64 11 80 	cmpl   $0x801164f4,-0x4(%ebp)
80105469:	72 d0                	jb     8010543b <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
8010546b:	c9                   	leave  
8010546c:	c3                   	ret    

8010546d <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
8010546d:	55                   	push   %ebp
8010546e:	89 e5                	mov    %esp,%ebp
80105470:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105473:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
8010547a:	e8 e5 01 00 00       	call   80105664 <acquire>
  wakeup1(chan);
8010547f:	8b 45 08             	mov    0x8(%ebp),%eax
80105482:	89 04 24             	mov    %eax,(%esp)
80105485:	e8 a2 ff ff ff       	call   8010542c <wakeup1>
  release(&ptable.lock);
8010548a:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105491:	e8 30 02 00 00       	call   801056c6 <release>
}
80105496:	c9                   	leave  
80105497:	c3                   	ret    

80105498 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105498:	55                   	push   %ebp
80105499:	89 e5                	mov    %esp,%ebp
8010549b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
8010549e:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801054a5:	e8 ba 01 00 00       	call   80105664 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801054aa:	c7 45 f4 f4 41 11 80 	movl   $0x801141f4,-0xc(%ebp)
801054b1:	eb 44                	jmp    801054f7 <kill+0x5f>
    if(p->pid == pid){
801054b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054b6:	8b 40 10             	mov    0x10(%eax),%eax
801054b9:	3b 45 08             	cmp    0x8(%ebp),%eax
801054bc:	75 32                	jne    801054f0 <kill+0x58>
      p->killed = 1;
801054be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054c1:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801054c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054cb:	8b 40 0c             	mov    0xc(%eax),%eax
801054ce:	83 f8 02             	cmp    $0x2,%eax
801054d1:	75 0a                	jne    801054dd <kill+0x45>
        p->state = RUNNABLE;
801054d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054d6:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
801054dd:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
801054e4:	e8 dd 01 00 00       	call   801056c6 <release>
      return 0;
801054e9:	b8 00 00 00 00       	mov    $0x0,%eax
801054ee:	eb 21                	jmp    80105511 <kill+0x79>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801054f0:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
801054f7:	81 7d f4 f4 64 11 80 	cmpl   $0x801164f4,-0xc(%ebp)
801054fe:	72 b3                	jb     801054b3 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105500:	c7 04 24 c0 41 11 80 	movl   $0x801141c0,(%esp)
80105507:	e8 ba 01 00 00       	call   801056c6 <release>
  return -1;
8010550c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105511:	c9                   	leave  
80105512:	c3                   	ret    

80105513 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105513:	55                   	push   %ebp
80105514:	89 e5                	mov    %esp,%ebp
80105516:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105519:	c7 45 f0 f4 41 11 80 	movl   $0x801141f4,-0x10(%ebp)
80105520:	e9 d9 00 00 00       	jmp    801055fe <procdump+0xeb>
    if(p->state == UNUSED)
80105525:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105528:	8b 40 0c             	mov    0xc(%eax),%eax
8010552b:	85 c0                	test   %eax,%eax
8010552d:	75 05                	jne    80105534 <procdump+0x21>
      continue;
8010552f:	e9 c3 00 00 00       	jmp    801055f7 <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105534:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105537:	8b 40 0c             	mov    0xc(%eax),%eax
8010553a:	83 f8 05             	cmp    $0x5,%eax
8010553d:	77 23                	ja     80105562 <procdump+0x4f>
8010553f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105542:	8b 40 0c             	mov    0xc(%eax),%eax
80105545:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
8010554c:	85 c0                	test   %eax,%eax
8010554e:	74 12                	je     80105562 <procdump+0x4f>
      state = states[p->state];
80105550:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105553:	8b 40 0c             	mov    0xc(%eax),%eax
80105556:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
8010555d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105560:	eb 07                	jmp    80105569 <procdump+0x56>
    else
      state = "???";
80105562:	c7 45 ec 24 90 10 80 	movl   $0x80109024,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105569:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010556c:	8d 50 6c             	lea    0x6c(%eax),%edx
8010556f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105572:	8b 40 10             	mov    0x10(%eax),%eax
80105575:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105579:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010557c:	89 54 24 08          	mov    %edx,0x8(%esp)
80105580:	89 44 24 04          	mov    %eax,0x4(%esp)
80105584:	c7 04 24 28 90 10 80 	movl   $0x80109028,(%esp)
8010558b:	e8 10 ae ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80105590:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105593:	8b 40 0c             	mov    0xc(%eax),%eax
80105596:	83 f8 02             	cmp    $0x2,%eax
80105599:	75 50                	jne    801055eb <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
8010559b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010559e:	8b 40 1c             	mov    0x1c(%eax),%eax
801055a1:	8b 40 0c             	mov    0xc(%eax),%eax
801055a4:	83 c0 08             	add    $0x8,%eax
801055a7:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801055aa:	89 54 24 04          	mov    %edx,0x4(%esp)
801055ae:	89 04 24             	mov    %eax,(%esp)
801055b1:	e8 5f 01 00 00       	call   80105715 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801055b6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801055bd:	eb 1b                	jmp    801055da <procdump+0xc7>
        cprintf(" %p", pc[i]);
801055bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055c2:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801055c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801055ca:	c7 04 24 31 90 10 80 	movl   $0x80109031,(%esp)
801055d1:	e8 ca ad ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801055d6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801055da:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801055de:	7f 0b                	jg     801055eb <procdump+0xd8>
801055e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055e3:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801055e7:	85 c0                	test   %eax,%eax
801055e9:	75 d4                	jne    801055bf <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801055eb:	c7 04 24 35 90 10 80 	movl   $0x80109035,(%esp)
801055f2:	e8 a9 ad ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055f7:	81 45 f0 8c 00 00 00 	addl   $0x8c,-0x10(%ebp)
801055fe:	81 7d f0 f4 64 11 80 	cmpl   $0x801164f4,-0x10(%ebp)
80105605:	0f 82 1a ff ff ff    	jb     80105525 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
8010560b:	c9                   	leave  
8010560c:	c3                   	ret    

8010560d <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010560d:	55                   	push   %ebp
8010560e:	89 e5                	mov    %esp,%ebp
80105610:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105613:	9c                   	pushf  
80105614:	58                   	pop    %eax
80105615:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105618:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010561b:	c9                   	leave  
8010561c:	c3                   	ret    

8010561d <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010561d:	55                   	push   %ebp
8010561e:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105620:	fa                   	cli    
}
80105621:	5d                   	pop    %ebp
80105622:	c3                   	ret    

80105623 <sti>:

static inline void
sti(void)
{
80105623:	55                   	push   %ebp
80105624:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105626:	fb                   	sti    
}
80105627:	5d                   	pop    %ebp
80105628:	c3                   	ret    

80105629 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105629:	55                   	push   %ebp
8010562a:	89 e5                	mov    %esp,%ebp
8010562c:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010562f:	8b 55 08             	mov    0x8(%ebp),%edx
80105632:	8b 45 0c             	mov    0xc(%ebp),%eax
80105635:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105638:	f0 87 02             	lock xchg %eax,(%edx)
8010563b:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010563e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105641:	c9                   	leave  
80105642:	c3                   	ret    

80105643 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105643:	55                   	push   %ebp
80105644:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105646:	8b 45 08             	mov    0x8(%ebp),%eax
80105649:	8b 55 0c             	mov    0xc(%ebp),%edx
8010564c:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010564f:	8b 45 08             	mov    0x8(%ebp),%eax
80105652:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105658:	8b 45 08             	mov    0x8(%ebp),%eax
8010565b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105662:	5d                   	pop    %ebp
80105663:	c3                   	ret    

80105664 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105664:	55                   	push   %ebp
80105665:	89 e5                	mov    %esp,%ebp
80105667:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
8010566a:	e8 49 01 00 00       	call   801057b8 <pushcli>
  if(holding(lk))
8010566f:	8b 45 08             	mov    0x8(%ebp),%eax
80105672:	89 04 24             	mov    %eax,(%esp)
80105675:	e8 14 01 00 00       	call   8010578e <holding>
8010567a:	85 c0                	test   %eax,%eax
8010567c:	74 0c                	je     8010568a <acquire+0x26>
    panic("acquire");
8010567e:	c7 04 24 61 90 10 80 	movl   $0x80109061,(%esp)
80105685:	e8 b0 ae ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
8010568a:	90                   	nop
8010568b:	8b 45 08             	mov    0x8(%ebp),%eax
8010568e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105695:	00 
80105696:	89 04 24             	mov    %eax,(%esp)
80105699:	e8 8b ff ff ff       	call   80105629 <xchg>
8010569e:	85 c0                	test   %eax,%eax
801056a0:	75 e9                	jne    8010568b <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801056a2:	8b 45 08             	mov    0x8(%ebp),%eax
801056a5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801056ac:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
801056af:	8b 45 08             	mov    0x8(%ebp),%eax
801056b2:	83 c0 0c             	add    $0xc,%eax
801056b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801056b9:	8d 45 08             	lea    0x8(%ebp),%eax
801056bc:	89 04 24             	mov    %eax,(%esp)
801056bf:	e8 51 00 00 00       	call   80105715 <getcallerpcs>
}
801056c4:	c9                   	leave  
801056c5:	c3                   	ret    

801056c6 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
801056c6:	55                   	push   %ebp
801056c7:	89 e5                	mov    %esp,%ebp
801056c9:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801056cc:	8b 45 08             	mov    0x8(%ebp),%eax
801056cf:	89 04 24             	mov    %eax,(%esp)
801056d2:	e8 b7 00 00 00       	call   8010578e <holding>
801056d7:	85 c0                	test   %eax,%eax
801056d9:	75 0c                	jne    801056e7 <release+0x21>
    panic("release");
801056db:	c7 04 24 69 90 10 80 	movl   $0x80109069,(%esp)
801056e2:	e8 53 ae ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
801056e7:	8b 45 08             	mov    0x8(%ebp),%eax
801056ea:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801056f1:	8b 45 08             	mov    0x8(%ebp),%eax
801056f4:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
801056fb:	8b 45 08             	mov    0x8(%ebp),%eax
801056fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105705:	00 
80105706:	89 04 24             	mov    %eax,(%esp)
80105709:	e8 1b ff ff ff       	call   80105629 <xchg>

  popcli();
8010570e:	e8 e9 00 00 00       	call   801057fc <popcli>
}
80105713:	c9                   	leave  
80105714:	c3                   	ret    

80105715 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105715:	55                   	push   %ebp
80105716:	89 e5                	mov    %esp,%ebp
80105718:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
8010571b:	8b 45 08             	mov    0x8(%ebp),%eax
8010571e:	83 e8 08             	sub    $0x8,%eax
80105721:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105724:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010572b:	eb 38                	jmp    80105765 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
8010572d:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105731:	74 38                	je     8010576b <getcallerpcs+0x56>
80105733:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010573a:	76 2f                	jbe    8010576b <getcallerpcs+0x56>
8010573c:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105740:	74 29                	je     8010576b <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105742:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105745:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010574c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010574f:	01 c2                	add    %eax,%edx
80105751:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105754:	8b 40 04             	mov    0x4(%eax),%eax
80105757:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105759:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010575c:	8b 00                	mov    (%eax),%eax
8010575e:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105761:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105765:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105769:	7e c2                	jle    8010572d <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010576b:	eb 19                	jmp    80105786 <getcallerpcs+0x71>
    pcs[i] = 0;
8010576d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105770:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105777:	8b 45 0c             	mov    0xc(%ebp),%eax
8010577a:	01 d0                	add    %edx,%eax
8010577c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105782:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105786:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010578a:	7e e1                	jle    8010576d <getcallerpcs+0x58>
    pcs[i] = 0;
}
8010578c:	c9                   	leave  
8010578d:	c3                   	ret    

8010578e <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
8010578e:	55                   	push   %ebp
8010578f:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105791:	8b 45 08             	mov    0x8(%ebp),%eax
80105794:	8b 00                	mov    (%eax),%eax
80105796:	85 c0                	test   %eax,%eax
80105798:	74 17                	je     801057b1 <holding+0x23>
8010579a:	8b 45 08             	mov    0x8(%ebp),%eax
8010579d:	8b 50 08             	mov    0x8(%eax),%edx
801057a0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801057a6:	39 c2                	cmp    %eax,%edx
801057a8:	75 07                	jne    801057b1 <holding+0x23>
801057aa:	b8 01 00 00 00       	mov    $0x1,%eax
801057af:	eb 05                	jmp    801057b6 <holding+0x28>
801057b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801057b6:	5d                   	pop    %ebp
801057b7:	c3                   	ret    

801057b8 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801057b8:	55                   	push   %ebp
801057b9:	89 e5                	mov    %esp,%ebp
801057bb:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
801057be:	e8 4a fe ff ff       	call   8010560d <readeflags>
801057c3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
801057c6:	e8 52 fe ff ff       	call   8010561d <cli>
  if(cpu->ncli++ == 0)
801057cb:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801057d2:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
801057d8:	8d 48 01             	lea    0x1(%eax),%ecx
801057db:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
801057e1:	85 c0                	test   %eax,%eax
801057e3:	75 15                	jne    801057fa <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
801057e5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801057eb:	8b 55 fc             	mov    -0x4(%ebp),%edx
801057ee:	81 e2 00 02 00 00    	and    $0x200,%edx
801057f4:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801057fa:	c9                   	leave  
801057fb:	c3                   	ret    

801057fc <popcli>:

void
popcli(void)
{
801057fc:	55                   	push   %ebp
801057fd:	89 e5                	mov    %esp,%ebp
801057ff:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105802:	e8 06 fe ff ff       	call   8010560d <readeflags>
80105807:	25 00 02 00 00       	and    $0x200,%eax
8010580c:	85 c0                	test   %eax,%eax
8010580e:	74 0c                	je     8010581c <popcli+0x20>
    panic("popcli - interruptible");
80105810:	c7 04 24 71 90 10 80 	movl   $0x80109071,(%esp)
80105817:	e8 1e ad ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
8010581c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105822:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105828:	83 ea 01             	sub    $0x1,%edx
8010582b:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105831:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105837:	85 c0                	test   %eax,%eax
80105839:	79 0c                	jns    80105847 <popcli+0x4b>
    panic("popcli");
8010583b:	c7 04 24 88 90 10 80 	movl   $0x80109088,(%esp)
80105842:	e8 f3 ac ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105847:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010584d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105853:	85 c0                	test   %eax,%eax
80105855:	75 15                	jne    8010586c <popcli+0x70>
80105857:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010585d:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105863:	85 c0                	test   %eax,%eax
80105865:	74 05                	je     8010586c <popcli+0x70>
    sti();
80105867:	e8 b7 fd ff ff       	call   80105623 <sti>
}
8010586c:	c9                   	leave  
8010586d:	c3                   	ret    

8010586e <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
8010586e:	55                   	push   %ebp
8010586f:	89 e5                	mov    %esp,%ebp
80105871:	57                   	push   %edi
80105872:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105873:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105876:	8b 55 10             	mov    0x10(%ebp),%edx
80105879:	8b 45 0c             	mov    0xc(%ebp),%eax
8010587c:	89 cb                	mov    %ecx,%ebx
8010587e:	89 df                	mov    %ebx,%edi
80105880:	89 d1                	mov    %edx,%ecx
80105882:	fc                   	cld    
80105883:	f3 aa                	rep stos %al,%es:(%edi)
80105885:	89 ca                	mov    %ecx,%edx
80105887:	89 fb                	mov    %edi,%ebx
80105889:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010588c:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010588f:	5b                   	pop    %ebx
80105890:	5f                   	pop    %edi
80105891:	5d                   	pop    %ebp
80105892:	c3                   	ret    

80105893 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105893:	55                   	push   %ebp
80105894:	89 e5                	mov    %esp,%ebp
80105896:	57                   	push   %edi
80105897:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105898:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010589b:	8b 55 10             	mov    0x10(%ebp),%edx
8010589e:	8b 45 0c             	mov    0xc(%ebp),%eax
801058a1:	89 cb                	mov    %ecx,%ebx
801058a3:	89 df                	mov    %ebx,%edi
801058a5:	89 d1                	mov    %edx,%ecx
801058a7:	fc                   	cld    
801058a8:	f3 ab                	rep stos %eax,%es:(%edi)
801058aa:	89 ca                	mov    %ecx,%edx
801058ac:	89 fb                	mov    %edi,%ebx
801058ae:	89 5d 08             	mov    %ebx,0x8(%ebp)
801058b1:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801058b4:	5b                   	pop    %ebx
801058b5:	5f                   	pop    %edi
801058b6:	5d                   	pop    %ebp
801058b7:	c3                   	ret    

801058b8 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801058b8:	55                   	push   %ebp
801058b9:	89 e5                	mov    %esp,%ebp
801058bb:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801058be:	8b 45 08             	mov    0x8(%ebp),%eax
801058c1:	83 e0 03             	and    $0x3,%eax
801058c4:	85 c0                	test   %eax,%eax
801058c6:	75 49                	jne    80105911 <memset+0x59>
801058c8:	8b 45 10             	mov    0x10(%ebp),%eax
801058cb:	83 e0 03             	and    $0x3,%eax
801058ce:	85 c0                	test   %eax,%eax
801058d0:	75 3f                	jne    80105911 <memset+0x59>
    c &= 0xFF;
801058d2:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801058d9:	8b 45 10             	mov    0x10(%ebp),%eax
801058dc:	c1 e8 02             	shr    $0x2,%eax
801058df:	89 c2                	mov    %eax,%edx
801058e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801058e4:	c1 e0 18             	shl    $0x18,%eax
801058e7:	89 c1                	mov    %eax,%ecx
801058e9:	8b 45 0c             	mov    0xc(%ebp),%eax
801058ec:	c1 e0 10             	shl    $0x10,%eax
801058ef:	09 c1                	or     %eax,%ecx
801058f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801058f4:	c1 e0 08             	shl    $0x8,%eax
801058f7:	09 c8                	or     %ecx,%eax
801058f9:	0b 45 0c             	or     0xc(%ebp),%eax
801058fc:	89 54 24 08          	mov    %edx,0x8(%esp)
80105900:	89 44 24 04          	mov    %eax,0x4(%esp)
80105904:	8b 45 08             	mov    0x8(%ebp),%eax
80105907:	89 04 24             	mov    %eax,(%esp)
8010590a:	e8 84 ff ff ff       	call   80105893 <stosl>
8010590f:	eb 19                	jmp    8010592a <memset+0x72>
  } else
    stosb(dst, c, n);
80105911:	8b 45 10             	mov    0x10(%ebp),%eax
80105914:	89 44 24 08          	mov    %eax,0x8(%esp)
80105918:	8b 45 0c             	mov    0xc(%ebp),%eax
8010591b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010591f:	8b 45 08             	mov    0x8(%ebp),%eax
80105922:	89 04 24             	mov    %eax,(%esp)
80105925:	e8 44 ff ff ff       	call   8010586e <stosb>
  return dst;
8010592a:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010592d:	c9                   	leave  
8010592e:	c3                   	ret    

8010592f <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
8010592f:	55                   	push   %ebp
80105930:	89 e5                	mov    %esp,%ebp
80105932:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105935:	8b 45 08             	mov    0x8(%ebp),%eax
80105938:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
8010593b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010593e:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105941:	eb 30                	jmp    80105973 <memcmp+0x44>
    if(*s1 != *s2)
80105943:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105946:	0f b6 10             	movzbl (%eax),%edx
80105949:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010594c:	0f b6 00             	movzbl (%eax),%eax
8010594f:	38 c2                	cmp    %al,%dl
80105951:	74 18                	je     8010596b <memcmp+0x3c>
      return *s1 - *s2;
80105953:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105956:	0f b6 00             	movzbl (%eax),%eax
80105959:	0f b6 d0             	movzbl %al,%edx
8010595c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010595f:	0f b6 00             	movzbl (%eax),%eax
80105962:	0f b6 c0             	movzbl %al,%eax
80105965:	29 c2                	sub    %eax,%edx
80105967:	89 d0                	mov    %edx,%eax
80105969:	eb 1a                	jmp    80105985 <memcmp+0x56>
    s1++, s2++;
8010596b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010596f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105973:	8b 45 10             	mov    0x10(%ebp),%eax
80105976:	8d 50 ff             	lea    -0x1(%eax),%edx
80105979:	89 55 10             	mov    %edx,0x10(%ebp)
8010597c:	85 c0                	test   %eax,%eax
8010597e:	75 c3                	jne    80105943 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105980:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105985:	c9                   	leave  
80105986:	c3                   	ret    

80105987 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105987:	55                   	push   %ebp
80105988:	89 e5                	mov    %esp,%ebp
8010598a:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
8010598d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105990:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105993:	8b 45 08             	mov    0x8(%ebp),%eax
80105996:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105999:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010599c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010599f:	73 3d                	jae    801059de <memmove+0x57>
801059a1:	8b 45 10             	mov    0x10(%ebp),%eax
801059a4:	8b 55 fc             	mov    -0x4(%ebp),%edx
801059a7:	01 d0                	add    %edx,%eax
801059a9:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801059ac:	76 30                	jbe    801059de <memmove+0x57>
    s += n;
801059ae:	8b 45 10             	mov    0x10(%ebp),%eax
801059b1:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801059b4:	8b 45 10             	mov    0x10(%ebp),%eax
801059b7:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801059ba:	eb 13                	jmp    801059cf <memmove+0x48>
      *--d = *--s;
801059bc:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801059c0:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801059c4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059c7:	0f b6 10             	movzbl (%eax),%edx
801059ca:	8b 45 f8             	mov    -0x8(%ebp),%eax
801059cd:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
801059cf:	8b 45 10             	mov    0x10(%ebp),%eax
801059d2:	8d 50 ff             	lea    -0x1(%eax),%edx
801059d5:	89 55 10             	mov    %edx,0x10(%ebp)
801059d8:	85 c0                	test   %eax,%eax
801059da:	75 e0                	jne    801059bc <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801059dc:	eb 26                	jmp    80105a04 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801059de:	eb 17                	jmp    801059f7 <memmove+0x70>
      *d++ = *s++;
801059e0:	8b 45 f8             	mov    -0x8(%ebp),%eax
801059e3:	8d 50 01             	lea    0x1(%eax),%edx
801059e6:	89 55 f8             	mov    %edx,-0x8(%ebp)
801059e9:	8b 55 fc             	mov    -0x4(%ebp),%edx
801059ec:	8d 4a 01             	lea    0x1(%edx),%ecx
801059ef:	89 4d fc             	mov    %ecx,-0x4(%ebp)
801059f2:	0f b6 12             	movzbl (%edx),%edx
801059f5:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801059f7:	8b 45 10             	mov    0x10(%ebp),%eax
801059fa:	8d 50 ff             	lea    -0x1(%eax),%edx
801059fd:	89 55 10             	mov    %edx,0x10(%ebp)
80105a00:	85 c0                	test   %eax,%eax
80105a02:	75 dc                	jne    801059e0 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105a04:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105a07:	c9                   	leave  
80105a08:	c3                   	ret    

80105a09 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105a09:	55                   	push   %ebp
80105a0a:	89 e5                	mov    %esp,%ebp
80105a0c:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105a0f:	8b 45 10             	mov    0x10(%ebp),%eax
80105a12:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a16:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a19:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a1d:	8b 45 08             	mov    0x8(%ebp),%eax
80105a20:	89 04 24             	mov    %eax,(%esp)
80105a23:	e8 5f ff ff ff       	call   80105987 <memmove>
}
80105a28:	c9                   	leave  
80105a29:	c3                   	ret    

80105a2a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105a2a:	55                   	push   %ebp
80105a2b:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105a2d:	eb 0c                	jmp    80105a3b <strncmp+0x11>
    n--, p++, q++;
80105a2f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105a33:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105a37:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105a3b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105a3f:	74 1a                	je     80105a5b <strncmp+0x31>
80105a41:	8b 45 08             	mov    0x8(%ebp),%eax
80105a44:	0f b6 00             	movzbl (%eax),%eax
80105a47:	84 c0                	test   %al,%al
80105a49:	74 10                	je     80105a5b <strncmp+0x31>
80105a4b:	8b 45 08             	mov    0x8(%ebp),%eax
80105a4e:	0f b6 10             	movzbl (%eax),%edx
80105a51:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a54:	0f b6 00             	movzbl (%eax),%eax
80105a57:	38 c2                	cmp    %al,%dl
80105a59:	74 d4                	je     80105a2f <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105a5b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105a5f:	75 07                	jne    80105a68 <strncmp+0x3e>
    return 0;
80105a61:	b8 00 00 00 00       	mov    $0x0,%eax
80105a66:	eb 16                	jmp    80105a7e <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105a68:	8b 45 08             	mov    0x8(%ebp),%eax
80105a6b:	0f b6 00             	movzbl (%eax),%eax
80105a6e:	0f b6 d0             	movzbl %al,%edx
80105a71:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a74:	0f b6 00             	movzbl (%eax),%eax
80105a77:	0f b6 c0             	movzbl %al,%eax
80105a7a:	29 c2                	sub    %eax,%edx
80105a7c:	89 d0                	mov    %edx,%eax
}
80105a7e:	5d                   	pop    %ebp
80105a7f:	c3                   	ret    

80105a80 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105a80:	55                   	push   %ebp
80105a81:	89 e5                	mov    %esp,%ebp
80105a83:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105a86:	8b 45 08             	mov    0x8(%ebp),%eax
80105a89:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105a8c:	90                   	nop
80105a8d:	8b 45 10             	mov    0x10(%ebp),%eax
80105a90:	8d 50 ff             	lea    -0x1(%eax),%edx
80105a93:	89 55 10             	mov    %edx,0x10(%ebp)
80105a96:	85 c0                	test   %eax,%eax
80105a98:	7e 1e                	jle    80105ab8 <strncpy+0x38>
80105a9a:	8b 45 08             	mov    0x8(%ebp),%eax
80105a9d:	8d 50 01             	lea    0x1(%eax),%edx
80105aa0:	89 55 08             	mov    %edx,0x8(%ebp)
80105aa3:	8b 55 0c             	mov    0xc(%ebp),%edx
80105aa6:	8d 4a 01             	lea    0x1(%edx),%ecx
80105aa9:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105aac:	0f b6 12             	movzbl (%edx),%edx
80105aaf:	88 10                	mov    %dl,(%eax)
80105ab1:	0f b6 00             	movzbl (%eax),%eax
80105ab4:	84 c0                	test   %al,%al
80105ab6:	75 d5                	jne    80105a8d <strncpy+0xd>
    ;
  while(n-- > 0)
80105ab8:	eb 0c                	jmp    80105ac6 <strncpy+0x46>
    *s++ = 0;
80105aba:	8b 45 08             	mov    0x8(%ebp),%eax
80105abd:	8d 50 01             	lea    0x1(%eax),%edx
80105ac0:	89 55 08             	mov    %edx,0x8(%ebp)
80105ac3:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105ac6:	8b 45 10             	mov    0x10(%ebp),%eax
80105ac9:	8d 50 ff             	lea    -0x1(%eax),%edx
80105acc:	89 55 10             	mov    %edx,0x10(%ebp)
80105acf:	85 c0                	test   %eax,%eax
80105ad1:	7f e7                	jg     80105aba <strncpy+0x3a>
    *s++ = 0;
  return os;
80105ad3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105ad6:	c9                   	leave  
80105ad7:	c3                   	ret    

80105ad8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105ad8:	55                   	push   %ebp
80105ad9:	89 e5                	mov    %esp,%ebp
80105adb:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105ade:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae1:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105ae4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ae8:	7f 05                	jg     80105aef <safestrcpy+0x17>
    return os;
80105aea:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105aed:	eb 31                	jmp    80105b20 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105aef:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105af3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105af7:	7e 1e                	jle    80105b17 <safestrcpy+0x3f>
80105af9:	8b 45 08             	mov    0x8(%ebp),%eax
80105afc:	8d 50 01             	lea    0x1(%eax),%edx
80105aff:	89 55 08             	mov    %edx,0x8(%ebp)
80105b02:	8b 55 0c             	mov    0xc(%ebp),%edx
80105b05:	8d 4a 01             	lea    0x1(%edx),%ecx
80105b08:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105b0b:	0f b6 12             	movzbl (%edx),%edx
80105b0e:	88 10                	mov    %dl,(%eax)
80105b10:	0f b6 00             	movzbl (%eax),%eax
80105b13:	84 c0                	test   %al,%al
80105b15:	75 d8                	jne    80105aef <safestrcpy+0x17>
    ;
  *s = 0;
80105b17:	8b 45 08             	mov    0x8(%ebp),%eax
80105b1a:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105b1d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105b20:	c9                   	leave  
80105b21:	c3                   	ret    

80105b22 <strlen>:

int
strlen(const char *s)
{
80105b22:	55                   	push   %ebp
80105b23:	89 e5                	mov    %esp,%ebp
80105b25:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105b28:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105b2f:	eb 04                	jmp    80105b35 <strlen+0x13>
80105b31:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105b35:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b38:	8b 45 08             	mov    0x8(%ebp),%eax
80105b3b:	01 d0                	add    %edx,%eax
80105b3d:	0f b6 00             	movzbl (%eax),%eax
80105b40:	84 c0                	test   %al,%al
80105b42:	75 ed                	jne    80105b31 <strlen+0xf>
    ;
  return n;
80105b44:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105b47:	c9                   	leave  
80105b48:	c3                   	ret    

80105b49 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105b49:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105b4d:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105b51:	55                   	push   %ebp
  pushl %ebx
80105b52:	53                   	push   %ebx
  pushl %esi
80105b53:	56                   	push   %esi
  pushl %edi
80105b54:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105b55:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105b57:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105b59:	5f                   	pop    %edi
  popl %esi
80105b5a:	5e                   	pop    %esi
  popl %ebx
80105b5b:	5b                   	pop    %ebx
  popl %ebp
80105b5c:	5d                   	pop    %ebp
  ret
80105b5d:	c3                   	ret    

80105b5e <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105b5e:	55                   	push   %ebp
80105b5f:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105b61:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b67:	8b 00                	mov    (%eax),%eax
80105b69:	3b 45 08             	cmp    0x8(%ebp),%eax
80105b6c:	76 12                	jbe    80105b80 <fetchint+0x22>
80105b6e:	8b 45 08             	mov    0x8(%ebp),%eax
80105b71:	8d 50 04             	lea    0x4(%eax),%edx
80105b74:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b7a:	8b 00                	mov    (%eax),%eax
80105b7c:	39 c2                	cmp    %eax,%edx
80105b7e:	76 07                	jbe    80105b87 <fetchint+0x29>
    return -1;
80105b80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b85:	eb 0f                	jmp    80105b96 <fetchint+0x38>
  *ip = *(int*)(addr);
80105b87:	8b 45 08             	mov    0x8(%ebp),%eax
80105b8a:	8b 10                	mov    (%eax),%edx
80105b8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b8f:	89 10                	mov    %edx,(%eax)
  return 0;
80105b91:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105b96:	5d                   	pop    %ebp
80105b97:	c3                   	ret    

80105b98 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105b98:	55                   	push   %ebp
80105b99:	89 e5                	mov    %esp,%ebp
80105b9b:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105b9e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ba4:	8b 00                	mov    (%eax),%eax
80105ba6:	3b 45 08             	cmp    0x8(%ebp),%eax
80105ba9:	77 07                	ja     80105bb2 <fetchstr+0x1a>
    return -1;
80105bab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105bb0:	eb 46                	jmp    80105bf8 <fetchstr+0x60>
  *pp = (char*)addr;
80105bb2:	8b 55 08             	mov    0x8(%ebp),%edx
80105bb5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bb8:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105bba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bc0:	8b 00                	mov    (%eax),%eax
80105bc2:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105bc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bc8:	8b 00                	mov    (%eax),%eax
80105bca:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105bcd:	eb 1c                	jmp    80105beb <fetchstr+0x53>
    if(*s == 0)
80105bcf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bd2:	0f b6 00             	movzbl (%eax),%eax
80105bd5:	84 c0                	test   %al,%al
80105bd7:	75 0e                	jne    80105be7 <fetchstr+0x4f>
      return s - *pp;
80105bd9:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105bdc:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bdf:	8b 00                	mov    (%eax),%eax
80105be1:	29 c2                	sub    %eax,%edx
80105be3:	89 d0                	mov    %edx,%eax
80105be5:	eb 11                	jmp    80105bf8 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105be7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105beb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bee:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105bf1:	72 dc                	jb     80105bcf <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105bf3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105bf8:	c9                   	leave  
80105bf9:	c3                   	ret    

80105bfa <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105bfa:	55                   	push   %ebp
80105bfb:	89 e5                	mov    %esp,%ebp
80105bfd:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105c00:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c06:	8b 40 18             	mov    0x18(%eax),%eax
80105c09:	8b 50 44             	mov    0x44(%eax),%edx
80105c0c:	8b 45 08             	mov    0x8(%ebp),%eax
80105c0f:	c1 e0 02             	shl    $0x2,%eax
80105c12:	01 d0                	add    %edx,%eax
80105c14:	8d 50 04             	lea    0x4(%eax),%edx
80105c17:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c1e:	89 14 24             	mov    %edx,(%esp)
80105c21:	e8 38 ff ff ff       	call   80105b5e <fetchint>
}
80105c26:	c9                   	leave  
80105c27:	c3                   	ret    

80105c28 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105c28:	55                   	push   %ebp
80105c29:	89 e5                	mov    %esp,%ebp
80105c2b:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105c2e:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105c31:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c35:	8b 45 08             	mov    0x8(%ebp),%eax
80105c38:	89 04 24             	mov    %eax,(%esp)
80105c3b:	e8 ba ff ff ff       	call   80105bfa <argint>
80105c40:	85 c0                	test   %eax,%eax
80105c42:	79 07                	jns    80105c4b <argptr+0x23>
    return -1;
80105c44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c49:	eb 3d                	jmp    80105c88 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105c4b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c4e:	89 c2                	mov    %eax,%edx
80105c50:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c56:	8b 00                	mov    (%eax),%eax
80105c58:	39 c2                	cmp    %eax,%edx
80105c5a:	73 16                	jae    80105c72 <argptr+0x4a>
80105c5c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c5f:	89 c2                	mov    %eax,%edx
80105c61:	8b 45 10             	mov    0x10(%ebp),%eax
80105c64:	01 c2                	add    %eax,%edx
80105c66:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c6c:	8b 00                	mov    (%eax),%eax
80105c6e:	39 c2                	cmp    %eax,%edx
80105c70:	76 07                	jbe    80105c79 <argptr+0x51>
    return -1;
80105c72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c77:	eb 0f                	jmp    80105c88 <argptr+0x60>
  *pp = (char*)i;
80105c79:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c7c:	89 c2                	mov    %eax,%edx
80105c7e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c81:	89 10                	mov    %edx,(%eax)
  return 0;
80105c83:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105c88:	c9                   	leave  
80105c89:	c3                   	ret    

80105c8a <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105c8a:	55                   	push   %ebp
80105c8b:	89 e5                	mov    %esp,%ebp
80105c8d:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105c90:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105c93:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c97:	8b 45 08             	mov    0x8(%ebp),%eax
80105c9a:	89 04 24             	mov    %eax,(%esp)
80105c9d:	e8 58 ff ff ff       	call   80105bfa <argint>
80105ca2:	85 c0                	test   %eax,%eax
80105ca4:	79 07                	jns    80105cad <argstr+0x23>
    return -1;
80105ca6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cab:	eb 12                	jmp    80105cbf <argstr+0x35>
  return fetchstr(addr, pp);
80105cad:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cb0:	8b 55 0c             	mov    0xc(%ebp),%edx
80105cb3:	89 54 24 04          	mov    %edx,0x4(%esp)
80105cb7:	89 04 24             	mov    %eax,(%esp)
80105cba:	e8 d9 fe ff ff       	call   80105b98 <fetchstr>
}
80105cbf:	c9                   	leave  
80105cc0:	c3                   	ret    

80105cc1 <syscall>:
[SYS_wait2]  sys_wait2,
};

void
syscall(void)
{
80105cc1:	55                   	push   %ebp
80105cc2:	89 e5                	mov    %esp,%ebp
80105cc4:	53                   	push   %ebx
80105cc5:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105cc8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cce:	8b 40 18             	mov    0x18(%eax),%eax
80105cd1:	8b 40 1c             	mov    0x1c(%eax),%eax
80105cd4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80105cd7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105cdb:	7e 30                	jle    80105d0d <syscall+0x4c>
80105cdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ce0:	83 f8 17             	cmp    $0x17,%eax
80105ce3:	77 28                	ja     80105d0d <syscall+0x4c>
80105ce5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ce8:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105cef:	85 c0                	test   %eax,%eax
80105cf1:	74 1a                	je     80105d0d <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105cf3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cf9:	8b 58 18             	mov    0x18(%eax),%ebx
80105cfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cff:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105d06:	ff d0                	call   *%eax
80105d08:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105d0b:	eb 3d                	jmp    80105d4a <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105d0d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d13:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105d16:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105d1c:	8b 40 10             	mov    0x10(%eax),%eax
80105d1f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105d22:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105d26:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105d2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d2e:	c7 04 24 8f 90 10 80 	movl   $0x8010908f,(%esp)
80105d35:	e8 66 a6 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105d3a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d40:	8b 40 18             	mov    0x18(%eax),%eax
80105d43:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105d4a:	83 c4 24             	add    $0x24,%esp
80105d4d:	5b                   	pop    %ebx
80105d4e:	5d                   	pop    %ebp
80105d4f:	c3                   	ret    

80105d50 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105d50:	55                   	push   %ebp
80105d51:	89 e5                	mov    %esp,%ebp
80105d53:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105d56:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d59:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d5d:	8b 45 08             	mov    0x8(%ebp),%eax
80105d60:	89 04 24             	mov    %eax,(%esp)
80105d63:	e8 92 fe ff ff       	call   80105bfa <argint>
80105d68:	85 c0                	test   %eax,%eax
80105d6a:	79 07                	jns    80105d73 <argfd+0x23>
    return -1;
80105d6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d71:	eb 50                	jmp    80105dc3 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105d73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d76:	85 c0                	test   %eax,%eax
80105d78:	78 21                	js     80105d9b <argfd+0x4b>
80105d7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d7d:	83 f8 0f             	cmp    $0xf,%eax
80105d80:	7f 19                	jg     80105d9b <argfd+0x4b>
80105d82:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d88:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105d8b:	83 c2 08             	add    $0x8,%edx
80105d8e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105d92:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d95:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d99:	75 07                	jne    80105da2 <argfd+0x52>
    return -1;
80105d9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105da0:	eb 21                	jmp    80105dc3 <argfd+0x73>
  if(pfd)
80105da2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105da6:	74 08                	je     80105db0 <argfd+0x60>
    *pfd = fd;
80105da8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105dab:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dae:	89 10                	mov    %edx,(%eax)
  if(pf)
80105db0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105db4:	74 08                	je     80105dbe <argfd+0x6e>
    *pf = f;
80105db6:	8b 45 10             	mov    0x10(%ebp),%eax
80105db9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105dbc:	89 10                	mov    %edx,(%eax)
  return 0;
80105dbe:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dc3:	c9                   	leave  
80105dc4:	c3                   	ret    

80105dc5 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105dc5:	55                   	push   %ebp
80105dc6:	89 e5                	mov    %esp,%ebp
80105dc8:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105dcb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105dd2:	eb 30                	jmp    80105e04 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105dd4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dda:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ddd:	83 c2 08             	add    $0x8,%edx
80105de0:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105de4:	85 c0                	test   %eax,%eax
80105de6:	75 18                	jne    80105e00 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105de8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dee:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105df1:	8d 4a 08             	lea    0x8(%edx),%ecx
80105df4:	8b 55 08             	mov    0x8(%ebp),%edx
80105df7:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105dfb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dfe:	eb 0f                	jmp    80105e0f <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105e00:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105e04:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105e08:	7e ca                	jle    80105dd4 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105e0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105e0f:	c9                   	leave  
80105e10:	c3                   	ret    

80105e11 <sys_dup>:

int
sys_dup(void)
{
80105e11:	55                   	push   %ebp
80105e12:	89 e5                	mov    %esp,%ebp
80105e14:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105e17:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e1a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105e25:	00 
80105e26:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e2d:	e8 1e ff ff ff       	call   80105d50 <argfd>
80105e32:	85 c0                	test   %eax,%eax
80105e34:	79 07                	jns    80105e3d <sys_dup+0x2c>
    return -1;
80105e36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e3b:	eb 29                	jmp    80105e66 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105e3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e40:	89 04 24             	mov    %eax,(%esp)
80105e43:	e8 7d ff ff ff       	call   80105dc5 <fdalloc>
80105e48:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e4b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e4f:	79 07                	jns    80105e58 <sys_dup+0x47>
    return -1;
80105e51:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e56:	eb 0e                	jmp    80105e66 <sys_dup+0x55>
  filedup(f);
80105e58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e5b:	89 04 24             	mov    %eax,(%esp)
80105e5e:	e8 21 b7 ff ff       	call   80101584 <filedup>
  return fd;
80105e63:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105e66:	c9                   	leave  
80105e67:	c3                   	ret    

80105e68 <sys_read>:

int
sys_read(void)
{
80105e68:	55                   	push   %ebp
80105e69:	89 e5                	mov    %esp,%ebp
80105e6b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105e6e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105e71:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e75:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105e7c:	00 
80105e7d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e84:	e8 c7 fe ff ff       	call   80105d50 <argfd>
80105e89:	85 c0                	test   %eax,%eax
80105e8b:	78 35                	js     80105ec2 <sys_read+0x5a>
80105e8d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e90:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e94:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105e9b:	e8 5a fd ff ff       	call   80105bfa <argint>
80105ea0:	85 c0                	test   %eax,%eax
80105ea2:	78 1e                	js     80105ec2 <sys_read+0x5a>
80105ea4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ea7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105eab:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105eae:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eb2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105eb9:	e8 6a fd ff ff       	call   80105c28 <argptr>
80105ebe:	85 c0                	test   %eax,%eax
80105ec0:	79 07                	jns    80105ec9 <sys_read+0x61>
    return -1;
80105ec2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ec7:	eb 19                	jmp    80105ee2 <sys_read+0x7a>
  return fileread(f, p, n);
80105ec9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105ecc:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105ecf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ed2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105ed6:	89 54 24 04          	mov    %edx,0x4(%esp)
80105eda:	89 04 24             	mov    %eax,(%esp)
80105edd:	e8 0f b8 ff ff       	call   801016f1 <fileread>
}
80105ee2:	c9                   	leave  
80105ee3:	c3                   	ret    

80105ee4 <sys_write>:

int
sys_write(void)
{
80105ee4:	55                   	push   %ebp
80105ee5:	89 e5                	mov    %esp,%ebp
80105ee7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105eea:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105eed:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ef1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105ef8:	00 
80105ef9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f00:	e8 4b fe ff ff       	call   80105d50 <argfd>
80105f05:	85 c0                	test   %eax,%eax
80105f07:	78 35                	js     80105f3e <sys_write+0x5a>
80105f09:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f0c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f10:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105f17:	e8 de fc ff ff       	call   80105bfa <argint>
80105f1c:	85 c0                	test   %eax,%eax
80105f1e:	78 1e                	js     80105f3e <sys_write+0x5a>
80105f20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f23:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f27:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105f2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f2e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f35:	e8 ee fc ff ff       	call   80105c28 <argptr>
80105f3a:	85 c0                	test   %eax,%eax
80105f3c:	79 07                	jns    80105f45 <sys_write+0x61>
    return -1;
80105f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f43:	eb 19                	jmp    80105f5e <sys_write+0x7a>
  return filewrite(f, p, n);
80105f45:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105f48:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105f4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f4e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105f52:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f56:	89 04 24             	mov    %eax,(%esp)
80105f59:	e8 4f b8 ff ff       	call   801017ad <filewrite>
}
80105f5e:	c9                   	leave  
80105f5f:	c3                   	ret    

80105f60 <sys_close>:

int
sys_close(void)
{
80105f60:	55                   	push   %ebp
80105f61:	89 e5                	mov    %esp,%ebp
80105f63:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105f66:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f69:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f6d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105f70:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f74:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f7b:	e8 d0 fd ff ff       	call   80105d50 <argfd>
80105f80:	85 c0                	test   %eax,%eax
80105f82:	79 07                	jns    80105f8b <sys_close+0x2b>
    return -1;
80105f84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f89:	eb 24                	jmp    80105faf <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105f8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f91:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f94:	83 c2 08             	add    $0x8,%edx
80105f97:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105f9e:	00 
  fileclose(f);
80105f9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fa2:	89 04 24             	mov    %eax,(%esp)
80105fa5:	e8 22 b6 ff ff       	call   801015cc <fileclose>
  return 0;
80105faa:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105faf:	c9                   	leave  
80105fb0:	c3                   	ret    

80105fb1 <sys_fstat>:

int
sys_fstat(void)
{
80105fb1:	55                   	push   %ebp
80105fb2:	89 e5                	mov    %esp,%ebp
80105fb4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105fb7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fba:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fbe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fc5:	00 
80105fc6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fcd:	e8 7e fd ff ff       	call   80105d50 <argfd>
80105fd2:	85 c0                	test   %eax,%eax
80105fd4:	78 1f                	js     80105ff5 <sys_fstat+0x44>
80105fd6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105fdd:	00 
80105fde:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fe1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fe5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105fec:	e8 37 fc ff ff       	call   80105c28 <argptr>
80105ff1:	85 c0                	test   %eax,%eax
80105ff3:	79 07                	jns    80105ffc <sys_fstat+0x4b>
    return -1;
80105ff5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ffa:	eb 12                	jmp    8010600e <sys_fstat+0x5d>
  return filestat(f, st);
80105ffc:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105fff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106002:	89 54 24 04          	mov    %edx,0x4(%esp)
80106006:	89 04 24             	mov    %eax,(%esp)
80106009:	e8 94 b6 ff ff       	call   801016a2 <filestat>
}
8010600e:	c9                   	leave  
8010600f:	c3                   	ret    

80106010 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106010:	55                   	push   %ebp
80106011:	89 e5                	mov    %esp,%ebp
80106013:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106016:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106019:	89 44 24 04          	mov    %eax,0x4(%esp)
8010601d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106024:	e8 61 fc ff ff       	call   80105c8a <argstr>
80106029:	85 c0                	test   %eax,%eax
8010602b:	78 17                	js     80106044 <sys_link+0x34>
8010602d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106030:	89 44 24 04          	mov    %eax,0x4(%esp)
80106034:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010603b:	e8 4a fc ff ff       	call   80105c8a <argstr>
80106040:	85 c0                	test   %eax,%eax
80106042:	79 0a                	jns    8010604e <sys_link+0x3e>
    return -1;
80106044:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106049:	e9 42 01 00 00       	jmp    80106190 <sys_link+0x180>

  begin_op();
8010604e:	e8 4c da ff ff       	call   80103a9f <begin_op>
  if((ip = namei(old)) == 0){
80106053:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106056:	89 04 24             	mov    %eax,(%esp)
80106059:	e8 0a ca ff ff       	call   80102a68 <namei>
8010605e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106061:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106065:	75 0f                	jne    80106076 <sys_link+0x66>
    end_op();
80106067:	e8 b7 da ff ff       	call   80103b23 <end_op>
    return -1;
8010606c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106071:	e9 1a 01 00 00       	jmp    80106190 <sys_link+0x180>
  }

  ilock(ip);
80106076:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106079:	89 04 24             	mov    %eax,(%esp)
8010607c:	e8 36 be ff ff       	call   80101eb7 <ilock>
  if(ip->type == T_DIR){
80106081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106084:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106088:	66 83 f8 01          	cmp    $0x1,%ax
8010608c:	75 1a                	jne    801060a8 <sys_link+0x98>
    iunlockput(ip);
8010608e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106091:	89 04 24             	mov    %eax,(%esp)
80106094:	e8 a8 c0 ff ff       	call   80102141 <iunlockput>
    end_op();
80106099:	e8 85 da ff ff       	call   80103b23 <end_op>
    return -1;
8010609e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060a3:	e9 e8 00 00 00       	jmp    80106190 <sys_link+0x180>
  }

  ip->nlink++;
801060a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060ab:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801060af:	8d 50 01             	lea    0x1(%eax),%edx
801060b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060b5:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801060b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060bc:	89 04 24             	mov    %eax,(%esp)
801060bf:	e8 31 bc ff ff       	call   80101cf5 <iupdate>
  iunlock(ip);
801060c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060c7:	89 04 24             	mov    %eax,(%esp)
801060ca:	e8 3c bf ff ff       	call   8010200b <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801060cf:	8b 45 dc             	mov    -0x24(%ebp),%eax
801060d2:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801060d5:	89 54 24 04          	mov    %edx,0x4(%esp)
801060d9:	89 04 24             	mov    %eax,(%esp)
801060dc:	e8 a9 c9 ff ff       	call   80102a8a <nameiparent>
801060e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060e4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801060e8:	75 02                	jne    801060ec <sys_link+0xdc>
    goto bad;
801060ea:	eb 68                	jmp    80106154 <sys_link+0x144>
  ilock(dp);
801060ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ef:	89 04 24             	mov    %eax,(%esp)
801060f2:	e8 c0 bd ff ff       	call   80101eb7 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801060f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060fa:	8b 10                	mov    (%eax),%edx
801060fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060ff:	8b 00                	mov    (%eax),%eax
80106101:	39 c2                	cmp    %eax,%edx
80106103:	75 20                	jne    80106125 <sys_link+0x115>
80106105:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106108:	8b 40 04             	mov    0x4(%eax),%eax
8010610b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010610f:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106112:	89 44 24 04          	mov    %eax,0x4(%esp)
80106116:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106119:	89 04 24             	mov    %eax,(%esp)
8010611c:	e8 87 c6 ff ff       	call   801027a8 <dirlink>
80106121:	85 c0                	test   %eax,%eax
80106123:	79 0d                	jns    80106132 <sys_link+0x122>
    iunlockput(dp);
80106125:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106128:	89 04 24             	mov    %eax,(%esp)
8010612b:	e8 11 c0 ff ff       	call   80102141 <iunlockput>
    goto bad;
80106130:	eb 22                	jmp    80106154 <sys_link+0x144>
  }
  iunlockput(dp);
80106132:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106135:	89 04 24             	mov    %eax,(%esp)
80106138:	e8 04 c0 ff ff       	call   80102141 <iunlockput>
  iput(ip);
8010613d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106140:	89 04 24             	mov    %eax,(%esp)
80106143:	e8 28 bf ff ff       	call   80102070 <iput>

  end_op();
80106148:	e8 d6 d9 ff ff       	call   80103b23 <end_op>

  return 0;
8010614d:	b8 00 00 00 00       	mov    $0x0,%eax
80106152:	eb 3c                	jmp    80106190 <sys_link+0x180>

bad:
  ilock(ip);
80106154:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106157:	89 04 24             	mov    %eax,(%esp)
8010615a:	e8 58 bd ff ff       	call   80101eb7 <ilock>
  ip->nlink--;
8010615f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106162:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106166:	8d 50 ff             	lea    -0x1(%eax),%edx
80106169:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010616c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106170:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106173:	89 04 24             	mov    %eax,(%esp)
80106176:	e8 7a bb ff ff       	call   80101cf5 <iupdate>
  iunlockput(ip);
8010617b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010617e:	89 04 24             	mov    %eax,(%esp)
80106181:	e8 bb bf ff ff       	call   80102141 <iunlockput>
  end_op();
80106186:	e8 98 d9 ff ff       	call   80103b23 <end_op>
  return -1;
8010618b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106190:	c9                   	leave  
80106191:	c3                   	ret    

80106192 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106192:	55                   	push   %ebp
80106193:	89 e5                	mov    %esp,%ebp
80106195:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106198:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
8010619f:	eb 4b                	jmp    801061ec <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801061a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061a4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801061ab:	00 
801061ac:	89 44 24 08          	mov    %eax,0x8(%esp)
801061b0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801061b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801061b7:	8b 45 08             	mov    0x8(%ebp),%eax
801061ba:	89 04 24             	mov    %eax,(%esp)
801061bd:	e8 08 c2 ff ff       	call   801023ca <readi>
801061c2:	83 f8 10             	cmp    $0x10,%eax
801061c5:	74 0c                	je     801061d3 <isdirempty+0x41>
      panic("isdirempty: readi");
801061c7:	c7 04 24 ab 90 10 80 	movl   $0x801090ab,(%esp)
801061ce:	e8 67 a3 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
801061d3:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801061d7:	66 85 c0             	test   %ax,%ax
801061da:	74 07                	je     801061e3 <isdirempty+0x51>
      return 0;
801061dc:	b8 00 00 00 00       	mov    $0x0,%eax
801061e1:	eb 1b                	jmp    801061fe <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801061e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061e6:	83 c0 10             	add    $0x10,%eax
801061e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
801061ef:	8b 45 08             	mov    0x8(%ebp),%eax
801061f2:	8b 40 18             	mov    0x18(%eax),%eax
801061f5:	39 c2                	cmp    %eax,%edx
801061f7:	72 a8                	jb     801061a1 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801061f9:	b8 01 00 00 00       	mov    $0x1,%eax
}
801061fe:	c9                   	leave  
801061ff:	c3                   	ret    

80106200 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106200:	55                   	push   %ebp
80106201:	89 e5                	mov    %esp,%ebp
80106203:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106206:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106209:	89 44 24 04          	mov    %eax,0x4(%esp)
8010620d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106214:	e8 71 fa ff ff       	call   80105c8a <argstr>
80106219:	85 c0                	test   %eax,%eax
8010621b:	79 0a                	jns    80106227 <sys_unlink+0x27>
    return -1;
8010621d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106222:	e9 af 01 00 00       	jmp    801063d6 <sys_unlink+0x1d6>

  begin_op();
80106227:	e8 73 d8 ff ff       	call   80103a9f <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010622c:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010622f:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106232:	89 54 24 04          	mov    %edx,0x4(%esp)
80106236:	89 04 24             	mov    %eax,(%esp)
80106239:	e8 4c c8 ff ff       	call   80102a8a <nameiparent>
8010623e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106241:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106245:	75 0f                	jne    80106256 <sys_unlink+0x56>
    end_op();
80106247:	e8 d7 d8 ff ff       	call   80103b23 <end_op>
    return -1;
8010624c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106251:	e9 80 01 00 00       	jmp    801063d6 <sys_unlink+0x1d6>
  }

  ilock(dp);
80106256:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106259:	89 04 24             	mov    %eax,(%esp)
8010625c:	e8 56 bc ff ff       	call   80101eb7 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106261:	c7 44 24 04 bd 90 10 	movl   $0x801090bd,0x4(%esp)
80106268:	80 
80106269:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010626c:	89 04 24             	mov    %eax,(%esp)
8010626f:	e8 49 c4 ff ff       	call   801026bd <namecmp>
80106274:	85 c0                	test   %eax,%eax
80106276:	0f 84 45 01 00 00    	je     801063c1 <sys_unlink+0x1c1>
8010627c:	c7 44 24 04 bf 90 10 	movl   $0x801090bf,0x4(%esp)
80106283:	80 
80106284:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106287:	89 04 24             	mov    %eax,(%esp)
8010628a:	e8 2e c4 ff ff       	call   801026bd <namecmp>
8010628f:	85 c0                	test   %eax,%eax
80106291:	0f 84 2a 01 00 00    	je     801063c1 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106297:	8d 45 c8             	lea    -0x38(%ebp),%eax
8010629a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010629e:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801062a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801062a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062a8:	89 04 24             	mov    %eax,(%esp)
801062ab:	e8 2f c4 ff ff       	call   801026df <dirlookup>
801062b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801062b3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801062b7:	75 05                	jne    801062be <sys_unlink+0xbe>
    goto bad;
801062b9:	e9 03 01 00 00       	jmp    801063c1 <sys_unlink+0x1c1>
  ilock(ip);
801062be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062c1:	89 04 24             	mov    %eax,(%esp)
801062c4:	e8 ee bb ff ff       	call   80101eb7 <ilock>

  if(ip->nlink < 1)
801062c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062cc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801062d0:	66 85 c0             	test   %ax,%ax
801062d3:	7f 0c                	jg     801062e1 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
801062d5:	c7 04 24 c2 90 10 80 	movl   $0x801090c2,(%esp)
801062dc:	e8 59 a2 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801062e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062e4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801062e8:	66 83 f8 01          	cmp    $0x1,%ax
801062ec:	75 1f                	jne    8010630d <sys_unlink+0x10d>
801062ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062f1:	89 04 24             	mov    %eax,(%esp)
801062f4:	e8 99 fe ff ff       	call   80106192 <isdirempty>
801062f9:	85 c0                	test   %eax,%eax
801062fb:	75 10                	jne    8010630d <sys_unlink+0x10d>
    iunlockput(ip);
801062fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106300:	89 04 24             	mov    %eax,(%esp)
80106303:	e8 39 be ff ff       	call   80102141 <iunlockput>
    goto bad;
80106308:	e9 b4 00 00 00       	jmp    801063c1 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
8010630d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106314:	00 
80106315:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010631c:	00 
8010631d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106320:	89 04 24             	mov    %eax,(%esp)
80106323:	e8 90 f5 ff ff       	call   801058b8 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106328:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010632b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106332:	00 
80106333:	89 44 24 08          	mov    %eax,0x8(%esp)
80106337:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010633a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010633e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106341:	89 04 24             	mov    %eax,(%esp)
80106344:	e8 e5 c1 ff ff       	call   8010252e <writei>
80106349:	83 f8 10             	cmp    $0x10,%eax
8010634c:	74 0c                	je     8010635a <sys_unlink+0x15a>
    panic("unlink: writei");
8010634e:	c7 04 24 d4 90 10 80 	movl   $0x801090d4,(%esp)
80106355:	e8 e0 a1 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
8010635a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010635d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106361:	66 83 f8 01          	cmp    $0x1,%ax
80106365:	75 1c                	jne    80106383 <sys_unlink+0x183>
    dp->nlink--;
80106367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010636a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010636e:	8d 50 ff             	lea    -0x1(%eax),%edx
80106371:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106374:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106378:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010637b:	89 04 24             	mov    %eax,(%esp)
8010637e:	e8 72 b9 ff ff       	call   80101cf5 <iupdate>
  }
  iunlockput(dp);
80106383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106386:	89 04 24             	mov    %eax,(%esp)
80106389:	e8 b3 bd ff ff       	call   80102141 <iunlockput>

  ip->nlink--;
8010638e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106391:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106395:	8d 50 ff             	lea    -0x1(%eax),%edx
80106398:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010639b:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010639f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063a2:	89 04 24             	mov    %eax,(%esp)
801063a5:	e8 4b b9 ff ff       	call   80101cf5 <iupdate>
  iunlockput(ip);
801063aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063ad:	89 04 24             	mov    %eax,(%esp)
801063b0:	e8 8c bd ff ff       	call   80102141 <iunlockput>

  end_op();
801063b5:	e8 69 d7 ff ff       	call   80103b23 <end_op>

  return 0;
801063ba:	b8 00 00 00 00       	mov    $0x0,%eax
801063bf:	eb 15                	jmp    801063d6 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
801063c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063c4:	89 04 24             	mov    %eax,(%esp)
801063c7:	e8 75 bd ff ff       	call   80102141 <iunlockput>
  end_op();
801063cc:	e8 52 d7 ff ff       	call   80103b23 <end_op>
  return -1;
801063d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801063d6:	c9                   	leave  
801063d7:	c3                   	ret    

801063d8 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801063d8:	55                   	push   %ebp
801063d9:	89 e5                	mov    %esp,%ebp
801063db:	83 ec 48             	sub    $0x48,%esp
801063de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801063e1:	8b 55 10             	mov    0x10(%ebp),%edx
801063e4:	8b 45 14             	mov    0x14(%ebp),%eax
801063e7:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801063eb:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801063ef:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801063f3:	8d 45 de             	lea    -0x22(%ebp),%eax
801063f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801063fa:	8b 45 08             	mov    0x8(%ebp),%eax
801063fd:	89 04 24             	mov    %eax,(%esp)
80106400:	e8 85 c6 ff ff       	call   80102a8a <nameiparent>
80106405:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106408:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010640c:	75 0a                	jne    80106418 <create+0x40>
    return 0;
8010640e:	b8 00 00 00 00       	mov    $0x0,%eax
80106413:	e9 7e 01 00 00       	jmp    80106596 <create+0x1be>
  ilock(dp);
80106418:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010641b:	89 04 24             	mov    %eax,(%esp)
8010641e:	e8 94 ba ff ff       	call   80101eb7 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106423:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106426:	89 44 24 08          	mov    %eax,0x8(%esp)
8010642a:	8d 45 de             	lea    -0x22(%ebp),%eax
8010642d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106431:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106434:	89 04 24             	mov    %eax,(%esp)
80106437:	e8 a3 c2 ff ff       	call   801026df <dirlookup>
8010643c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010643f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106443:	74 47                	je     8010648c <create+0xb4>
    iunlockput(dp);
80106445:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106448:	89 04 24             	mov    %eax,(%esp)
8010644b:	e8 f1 bc ff ff       	call   80102141 <iunlockput>
    ilock(ip);
80106450:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106453:	89 04 24             	mov    %eax,(%esp)
80106456:	e8 5c ba ff ff       	call   80101eb7 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010645b:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106460:	75 15                	jne    80106477 <create+0x9f>
80106462:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106465:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106469:	66 83 f8 02          	cmp    $0x2,%ax
8010646d:	75 08                	jne    80106477 <create+0x9f>
      return ip;
8010646f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106472:	e9 1f 01 00 00       	jmp    80106596 <create+0x1be>
    iunlockput(ip);
80106477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010647a:	89 04 24             	mov    %eax,(%esp)
8010647d:	e8 bf bc ff ff       	call   80102141 <iunlockput>
    return 0;
80106482:	b8 00 00 00 00       	mov    $0x0,%eax
80106487:	e9 0a 01 00 00       	jmp    80106596 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
8010648c:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106490:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106493:	8b 00                	mov    (%eax),%eax
80106495:	89 54 24 04          	mov    %edx,0x4(%esp)
80106499:	89 04 24             	mov    %eax,(%esp)
8010649c:	e8 7f b7 ff ff       	call   80101c20 <ialloc>
801064a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801064a4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064a8:	75 0c                	jne    801064b6 <create+0xde>
    panic("create: ialloc");
801064aa:	c7 04 24 e3 90 10 80 	movl   $0x801090e3,(%esp)
801064b1:	e8 84 a0 ff ff       	call   8010053a <panic>

  ilock(ip);
801064b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064b9:	89 04 24             	mov    %eax,(%esp)
801064bc:	e8 f6 b9 ff ff       	call   80101eb7 <ilock>
  ip->major = major;
801064c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064c4:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801064c8:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801064cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064cf:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801064d3:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801064d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064da:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801064e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064e3:	89 04 24             	mov    %eax,(%esp)
801064e6:	e8 0a b8 ff ff       	call   80101cf5 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
801064eb:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
801064f0:	75 6a                	jne    8010655c <create+0x184>
    dp->nlink++;  // for ".."
801064f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f5:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064f9:	8d 50 01             	lea    0x1(%eax),%edx
801064fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ff:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106506:	89 04 24             	mov    %eax,(%esp)
80106509:	e8 e7 b7 ff ff       	call   80101cf5 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010650e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106511:	8b 40 04             	mov    0x4(%eax),%eax
80106514:	89 44 24 08          	mov    %eax,0x8(%esp)
80106518:	c7 44 24 04 bd 90 10 	movl   $0x801090bd,0x4(%esp)
8010651f:	80 
80106520:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106523:	89 04 24             	mov    %eax,(%esp)
80106526:	e8 7d c2 ff ff       	call   801027a8 <dirlink>
8010652b:	85 c0                	test   %eax,%eax
8010652d:	78 21                	js     80106550 <create+0x178>
8010652f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106532:	8b 40 04             	mov    0x4(%eax),%eax
80106535:	89 44 24 08          	mov    %eax,0x8(%esp)
80106539:	c7 44 24 04 bf 90 10 	movl   $0x801090bf,0x4(%esp)
80106540:	80 
80106541:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106544:	89 04 24             	mov    %eax,(%esp)
80106547:	e8 5c c2 ff ff       	call   801027a8 <dirlink>
8010654c:	85 c0                	test   %eax,%eax
8010654e:	79 0c                	jns    8010655c <create+0x184>
      panic("create dots");
80106550:	c7 04 24 f2 90 10 80 	movl   $0x801090f2,(%esp)
80106557:	e8 de 9f ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
8010655c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010655f:	8b 40 04             	mov    0x4(%eax),%eax
80106562:	89 44 24 08          	mov    %eax,0x8(%esp)
80106566:	8d 45 de             	lea    -0x22(%ebp),%eax
80106569:	89 44 24 04          	mov    %eax,0x4(%esp)
8010656d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106570:	89 04 24             	mov    %eax,(%esp)
80106573:	e8 30 c2 ff ff       	call   801027a8 <dirlink>
80106578:	85 c0                	test   %eax,%eax
8010657a:	79 0c                	jns    80106588 <create+0x1b0>
    panic("create: dirlink");
8010657c:	c7 04 24 fe 90 10 80 	movl   $0x801090fe,(%esp)
80106583:	e8 b2 9f ff ff       	call   8010053a <panic>

  iunlockput(dp);
80106588:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010658b:	89 04 24             	mov    %eax,(%esp)
8010658e:	e8 ae bb ff ff       	call   80102141 <iunlockput>

  return ip;
80106593:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106596:	c9                   	leave  
80106597:	c3                   	ret    

80106598 <sys_open>:

int
sys_open(void)
{
80106598:	55                   	push   %ebp
80106599:	89 e5                	mov    %esp,%ebp
8010659b:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
8010659e:	8d 45 e8             	lea    -0x18(%ebp),%eax
801065a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801065a5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065ac:	e8 d9 f6 ff ff       	call   80105c8a <argstr>
801065b1:	85 c0                	test   %eax,%eax
801065b3:	78 17                	js     801065cc <sys_open+0x34>
801065b5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801065b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801065bc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065c3:	e8 32 f6 ff ff       	call   80105bfa <argint>
801065c8:	85 c0                	test   %eax,%eax
801065ca:	79 0a                	jns    801065d6 <sys_open+0x3e>
    return -1;
801065cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065d1:	e9 5c 01 00 00       	jmp    80106732 <sys_open+0x19a>

  begin_op();
801065d6:	e8 c4 d4 ff ff       	call   80103a9f <begin_op>

  if(omode & O_CREATE){
801065db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801065de:	25 00 02 00 00       	and    $0x200,%eax
801065e3:	85 c0                	test   %eax,%eax
801065e5:	74 3b                	je     80106622 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
801065e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801065ea:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801065f1:	00 
801065f2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801065f9:	00 
801065fa:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106601:	00 
80106602:	89 04 24             	mov    %eax,(%esp)
80106605:	e8 ce fd ff ff       	call   801063d8 <create>
8010660a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
8010660d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106611:	75 6b                	jne    8010667e <sys_open+0xe6>
      end_op();
80106613:	e8 0b d5 ff ff       	call   80103b23 <end_op>
      return -1;
80106618:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010661d:	e9 10 01 00 00       	jmp    80106732 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80106622:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106625:	89 04 24             	mov    %eax,(%esp)
80106628:	e8 3b c4 ff ff       	call   80102a68 <namei>
8010662d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106630:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106634:	75 0f                	jne    80106645 <sys_open+0xad>
      end_op();
80106636:	e8 e8 d4 ff ff       	call   80103b23 <end_op>
      return -1;
8010663b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106640:	e9 ed 00 00 00       	jmp    80106732 <sys_open+0x19a>
    }
    ilock(ip);
80106645:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106648:	89 04 24             	mov    %eax,(%esp)
8010664b:	e8 67 b8 ff ff       	call   80101eb7 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106650:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106653:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106657:	66 83 f8 01          	cmp    $0x1,%ax
8010665b:	75 21                	jne    8010667e <sys_open+0xe6>
8010665d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106660:	85 c0                	test   %eax,%eax
80106662:	74 1a                	je     8010667e <sys_open+0xe6>
      iunlockput(ip);
80106664:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106667:	89 04 24             	mov    %eax,(%esp)
8010666a:	e8 d2 ba ff ff       	call   80102141 <iunlockput>
      end_op();
8010666f:	e8 af d4 ff ff       	call   80103b23 <end_op>
      return -1;
80106674:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106679:	e9 b4 00 00 00       	jmp    80106732 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010667e:	e8 a1 ae ff ff       	call   80101524 <filealloc>
80106683:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106686:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010668a:	74 14                	je     801066a0 <sys_open+0x108>
8010668c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010668f:	89 04 24             	mov    %eax,(%esp)
80106692:	e8 2e f7 ff ff       	call   80105dc5 <fdalloc>
80106697:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010669a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010669e:	79 28                	jns    801066c8 <sys_open+0x130>
    if(f)
801066a0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801066a4:	74 0b                	je     801066b1 <sys_open+0x119>
      fileclose(f);
801066a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066a9:	89 04 24             	mov    %eax,(%esp)
801066ac:	e8 1b af ff ff       	call   801015cc <fileclose>
    iunlockput(ip);
801066b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066b4:	89 04 24             	mov    %eax,(%esp)
801066b7:	e8 85 ba ff ff       	call   80102141 <iunlockput>
    end_op();
801066bc:	e8 62 d4 ff ff       	call   80103b23 <end_op>
    return -1;
801066c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066c6:	eb 6a                	jmp    80106732 <sys_open+0x19a>
  }
  iunlock(ip);
801066c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066cb:	89 04 24             	mov    %eax,(%esp)
801066ce:	e8 38 b9 ff ff       	call   8010200b <iunlock>
  end_op();
801066d3:	e8 4b d4 ff ff       	call   80103b23 <end_op>

  f->type = FD_INODE;
801066d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066db:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801066e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066e4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801066e7:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801066ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066ed:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801066f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801066f7:	83 e0 01             	and    $0x1,%eax
801066fa:	85 c0                	test   %eax,%eax
801066fc:	0f 94 c0             	sete   %al
801066ff:	89 c2                	mov    %eax,%edx
80106701:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106704:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106707:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010670a:	83 e0 01             	and    $0x1,%eax
8010670d:	85 c0                	test   %eax,%eax
8010670f:	75 0a                	jne    8010671b <sys_open+0x183>
80106711:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106714:	83 e0 02             	and    $0x2,%eax
80106717:	85 c0                	test   %eax,%eax
80106719:	74 07                	je     80106722 <sys_open+0x18a>
8010671b:	b8 01 00 00 00       	mov    $0x1,%eax
80106720:	eb 05                	jmp    80106727 <sys_open+0x18f>
80106722:	b8 00 00 00 00       	mov    $0x0,%eax
80106727:	89 c2                	mov    %eax,%edx
80106729:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010672c:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010672f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106732:	c9                   	leave  
80106733:	c3                   	ret    

80106734 <sys_mkdir>:

int
sys_mkdir(void)
{
80106734:	55                   	push   %ebp
80106735:	89 e5                	mov    %esp,%ebp
80106737:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010673a:	e8 60 d3 ff ff       	call   80103a9f <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010673f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106742:	89 44 24 04          	mov    %eax,0x4(%esp)
80106746:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010674d:	e8 38 f5 ff ff       	call   80105c8a <argstr>
80106752:	85 c0                	test   %eax,%eax
80106754:	78 2c                	js     80106782 <sys_mkdir+0x4e>
80106756:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106759:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106760:	00 
80106761:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106768:	00 
80106769:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106770:	00 
80106771:	89 04 24             	mov    %eax,(%esp)
80106774:	e8 5f fc ff ff       	call   801063d8 <create>
80106779:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010677c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106780:	75 0c                	jne    8010678e <sys_mkdir+0x5a>
    end_op();
80106782:	e8 9c d3 ff ff       	call   80103b23 <end_op>
    return -1;
80106787:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010678c:	eb 15                	jmp    801067a3 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
8010678e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106791:	89 04 24             	mov    %eax,(%esp)
80106794:	e8 a8 b9 ff ff       	call   80102141 <iunlockput>
  end_op();
80106799:	e8 85 d3 ff ff       	call   80103b23 <end_op>
  return 0;
8010679e:	b8 00 00 00 00       	mov    $0x0,%eax
}
801067a3:	c9                   	leave  
801067a4:	c3                   	ret    

801067a5 <sys_mknod>:

int
sys_mknod(void)
{
801067a5:	55                   	push   %ebp
801067a6:	89 e5                	mov    %esp,%ebp
801067a8:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
801067ab:	e8 ef d2 ff ff       	call   80103a9f <begin_op>
  if((len=argstr(0, &path)) < 0 ||
801067b0:	8d 45 ec             	lea    -0x14(%ebp),%eax
801067b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801067b7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067be:	e8 c7 f4 ff ff       	call   80105c8a <argstr>
801067c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067c6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801067ca:	78 5e                	js     8010682a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801067cc:	8d 45 e8             	lea    -0x18(%ebp),%eax
801067cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801067d3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801067da:	e8 1b f4 ff ff       	call   80105bfa <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
801067df:	85 c0                	test   %eax,%eax
801067e1:	78 47                	js     8010682a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801067e3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801067e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801067ea:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801067f1:	e8 04 f4 ff ff       	call   80105bfa <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801067f6:	85 c0                	test   %eax,%eax
801067f8:	78 30                	js     8010682a <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801067fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801067fd:	0f bf c8             	movswl %ax,%ecx
80106800:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106803:	0f bf d0             	movswl %ax,%edx
80106806:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106809:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010680d:	89 54 24 08          	mov    %edx,0x8(%esp)
80106811:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106818:	00 
80106819:	89 04 24             	mov    %eax,(%esp)
8010681c:	e8 b7 fb ff ff       	call   801063d8 <create>
80106821:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106824:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106828:	75 0c                	jne    80106836 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
8010682a:	e8 f4 d2 ff ff       	call   80103b23 <end_op>
    return -1;
8010682f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106834:	eb 15                	jmp    8010684b <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106836:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106839:	89 04 24             	mov    %eax,(%esp)
8010683c:	e8 00 b9 ff ff       	call   80102141 <iunlockput>
  end_op();
80106841:	e8 dd d2 ff ff       	call   80103b23 <end_op>
  return 0;
80106846:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010684b:	c9                   	leave  
8010684c:	c3                   	ret    

8010684d <sys_chdir>:

int
sys_chdir(void)
{
8010684d:	55                   	push   %ebp
8010684e:	89 e5                	mov    %esp,%ebp
80106850:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106853:	e8 47 d2 ff ff       	call   80103a9f <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106858:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010685b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010685f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106866:	e8 1f f4 ff ff       	call   80105c8a <argstr>
8010686b:	85 c0                	test   %eax,%eax
8010686d:	78 14                	js     80106883 <sys_chdir+0x36>
8010686f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106872:	89 04 24             	mov    %eax,(%esp)
80106875:	e8 ee c1 ff ff       	call   80102a68 <namei>
8010687a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010687d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106881:	75 0c                	jne    8010688f <sys_chdir+0x42>
    end_op();
80106883:	e8 9b d2 ff ff       	call   80103b23 <end_op>
    return -1;
80106888:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010688d:	eb 61                	jmp    801068f0 <sys_chdir+0xa3>
  }
  ilock(ip);
8010688f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106892:	89 04 24             	mov    %eax,(%esp)
80106895:	e8 1d b6 ff ff       	call   80101eb7 <ilock>
  if(ip->type != T_DIR){
8010689a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010689d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801068a1:	66 83 f8 01          	cmp    $0x1,%ax
801068a5:	74 17                	je     801068be <sys_chdir+0x71>
    iunlockput(ip);
801068a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068aa:	89 04 24             	mov    %eax,(%esp)
801068ad:	e8 8f b8 ff ff       	call   80102141 <iunlockput>
    end_op();
801068b2:	e8 6c d2 ff ff       	call   80103b23 <end_op>
    return -1;
801068b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068bc:	eb 32                	jmp    801068f0 <sys_chdir+0xa3>
  }
  iunlock(ip);
801068be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068c1:	89 04 24             	mov    %eax,(%esp)
801068c4:	e8 42 b7 ff ff       	call   8010200b <iunlock>
  iput(proc->cwd);
801068c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068cf:	8b 40 68             	mov    0x68(%eax),%eax
801068d2:	89 04 24             	mov    %eax,(%esp)
801068d5:	e8 96 b7 ff ff       	call   80102070 <iput>
  end_op();
801068da:	e8 44 d2 ff ff       	call   80103b23 <end_op>
  proc->cwd = ip;
801068df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068e5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801068e8:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801068eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068f0:	c9                   	leave  
801068f1:	c3                   	ret    

801068f2 <sys_exec>:

int
sys_exec(void)
{
801068f2:	55                   	push   %ebp
801068f3:	89 e5                	mov    %esp,%ebp
801068f5:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801068fb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801068fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80106902:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106909:	e8 7c f3 ff ff       	call   80105c8a <argstr>
8010690e:	85 c0                	test   %eax,%eax
80106910:	78 1a                	js     8010692c <sys_exec+0x3a>
80106912:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106918:	89 44 24 04          	mov    %eax,0x4(%esp)
8010691c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106923:	e8 d2 f2 ff ff       	call   80105bfa <argint>
80106928:	85 c0                	test   %eax,%eax
8010692a:	79 0a                	jns    80106936 <sys_exec+0x44>
    return -1;
8010692c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106931:	e9 c8 00 00 00       	jmp    801069fe <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106936:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010693d:	00 
8010693e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106945:	00 
80106946:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010694c:	89 04 24             	mov    %eax,(%esp)
8010694f:	e8 64 ef ff ff       	call   801058b8 <memset>
  for(i=0;; i++){
80106954:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
8010695b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010695e:	83 f8 1f             	cmp    $0x1f,%eax
80106961:	76 0a                	jbe    8010696d <sys_exec+0x7b>
      return -1;
80106963:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106968:	e9 91 00 00 00       	jmp    801069fe <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
8010696d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106970:	c1 e0 02             	shl    $0x2,%eax
80106973:	89 c2                	mov    %eax,%edx
80106975:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
8010697b:	01 c2                	add    %eax,%edx
8010697d:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106983:	89 44 24 04          	mov    %eax,0x4(%esp)
80106987:	89 14 24             	mov    %edx,(%esp)
8010698a:	e8 cf f1 ff ff       	call   80105b5e <fetchint>
8010698f:	85 c0                	test   %eax,%eax
80106991:	79 07                	jns    8010699a <sys_exec+0xa8>
      return -1;
80106993:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106998:	eb 64                	jmp    801069fe <sys_exec+0x10c>
    if(uarg == 0){
8010699a:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801069a0:	85 c0                	test   %eax,%eax
801069a2:	75 26                	jne    801069ca <sys_exec+0xd8>
      argv[i] = 0;
801069a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a7:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801069ae:	00 00 00 00 
      break;
801069b2:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801069b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069b6:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801069bc:	89 54 24 04          	mov    %edx,0x4(%esp)
801069c0:	89 04 24             	mov    %eax,(%esp)
801069c3:	e8 25 a7 ff ff       	call   801010ed <exec>
801069c8:	eb 34                	jmp    801069fe <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
801069ca:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801069d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801069d3:	c1 e2 02             	shl    $0x2,%edx
801069d6:	01 c2                	add    %eax,%edx
801069d8:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801069de:	89 54 24 04          	mov    %edx,0x4(%esp)
801069e2:	89 04 24             	mov    %eax,(%esp)
801069e5:	e8 ae f1 ff ff       	call   80105b98 <fetchstr>
801069ea:	85 c0                	test   %eax,%eax
801069ec:	79 07                	jns    801069f5 <sys_exec+0x103>
      return -1;
801069ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069f3:	eb 09                	jmp    801069fe <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801069f5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
801069f9:	e9 5d ff ff ff       	jmp    8010695b <sys_exec+0x69>
  return exec(path, argv);
}
801069fe:	c9                   	leave  
801069ff:	c3                   	ret    

80106a00 <sys_pipe>:

int
sys_pipe(void)
{
80106a00:	55                   	push   %ebp
80106a01:	89 e5                	mov    %esp,%ebp
80106a03:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106a06:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106a0d:	00 
80106a0e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106a11:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a15:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a1c:	e8 07 f2 ff ff       	call   80105c28 <argptr>
80106a21:	85 c0                	test   %eax,%eax
80106a23:	79 0a                	jns    80106a2f <sys_pipe+0x2f>
    return -1;
80106a25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a2a:	e9 9b 00 00 00       	jmp    80106aca <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106a2f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106a32:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a36:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106a39:	89 04 24             	mov    %eax,(%esp)
80106a3c:	e8 6a db ff ff       	call   801045ab <pipealloc>
80106a41:	85 c0                	test   %eax,%eax
80106a43:	79 07                	jns    80106a4c <sys_pipe+0x4c>
    return -1;
80106a45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a4a:	eb 7e                	jmp    80106aca <sys_pipe+0xca>
  fd0 = -1;
80106a4c:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106a53:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106a56:	89 04 24             	mov    %eax,(%esp)
80106a59:	e8 67 f3 ff ff       	call   80105dc5 <fdalloc>
80106a5e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a61:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a65:	78 14                	js     80106a7b <sys_pipe+0x7b>
80106a67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106a6a:	89 04 24             	mov    %eax,(%esp)
80106a6d:	e8 53 f3 ff ff       	call   80105dc5 <fdalloc>
80106a72:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a75:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a79:	79 37                	jns    80106ab2 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106a7b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a7f:	78 14                	js     80106a95 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106a81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a87:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a8a:	83 c2 08             	add    $0x8,%edx
80106a8d:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106a94:	00 
    fileclose(rf);
80106a95:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106a98:	89 04 24             	mov    %eax,(%esp)
80106a9b:	e8 2c ab ff ff       	call   801015cc <fileclose>
    fileclose(wf);
80106aa0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106aa3:	89 04 24             	mov    %eax,(%esp)
80106aa6:	e8 21 ab ff ff       	call   801015cc <fileclose>
    return -1;
80106aab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ab0:	eb 18                	jmp    80106aca <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106ab2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106ab5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ab8:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106aba:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106abd:	8d 50 04             	lea    0x4(%eax),%edx
80106ac0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ac3:	89 02                	mov    %eax,(%edx)
  return 0;
80106ac5:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106aca:	c9                   	leave  
80106acb:	c3                   	ret    

80106acc <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106acc:	55                   	push   %ebp
80106acd:	89 e5                	mov    %esp,%ebp
80106acf:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106ad2:	e8 82 e1 ff ff       	call   80104c59 <fork>
}
80106ad7:	c9                   	leave  
80106ad8:	c3                   	ret    

80106ad9 <sys_exit>:

int
sys_exit(void)
{
80106ad9:	55                   	push   %ebp
80106ada:	89 e5                	mov    %esp,%ebp
80106adc:	83 ec 08             	sub    $0x8,%esp
  exit();
80106adf:	e8 24 e3 ff ff       	call   80104e08 <exit>
  return 0;  // not reached
80106ae4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106ae9:	c9                   	leave  
80106aea:	c3                   	ret    

80106aeb <sys_wait>:

int
sys_wait(void)
{
80106aeb:	55                   	push   %ebp
80106aec:	89 e5                	mov    %esp,%ebp
80106aee:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106af1:	e8 37 e4 ff ff       	call   80104f2d <wait>
}
80106af6:	c9                   	leave  
80106af7:	c3                   	ret    

80106af8 <sys_wait2>:

int
sys_wait2(void)
{
80106af8:	55                   	push   %ebp
80106af9:	89 e5                	mov    %esp,%ebp
80106afb:	83 ec 08             	sub    $0x8,%esp
  return wait2();
80106afe:	e8 3c e5 ff ff       	call   8010503f <wait2>
}
80106b03:	c9                   	leave  
80106b04:	c3                   	ret    

80106b05 <sys_kill>:

int
sys_kill(void)
{
80106b05:	55                   	push   %ebp
80106b06:	89 e5                	mov    %esp,%ebp
80106b08:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106b0b:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106b0e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b12:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b19:	e8 dc f0 ff ff       	call   80105bfa <argint>
80106b1e:	85 c0                	test   %eax,%eax
80106b20:	79 07                	jns    80106b29 <sys_kill+0x24>
    return -1;
80106b22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b27:	eb 0b                	jmp    80106b34 <sys_kill+0x2f>
  return kill(pid);
80106b29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b2c:	89 04 24             	mov    %eax,(%esp)
80106b2f:	e8 64 e9 ff ff       	call   80105498 <kill>
}
80106b34:	c9                   	leave  
80106b35:	c3                   	ret    

80106b36 <sys_getpid>:

int
sys_getpid(void)
{
80106b36:	55                   	push   %ebp
80106b37:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106b39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b3f:	8b 40 10             	mov    0x10(%eax),%eax
}
80106b42:	5d                   	pop    %ebp
80106b43:	c3                   	ret    

80106b44 <sys_sbrk>:

int
sys_sbrk(void)
{
80106b44:	55                   	push   %ebp
80106b45:	89 e5                	mov    %esp,%ebp
80106b47:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106b4a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106b4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b51:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b58:	e8 9d f0 ff ff       	call   80105bfa <argint>
80106b5d:	85 c0                	test   %eax,%eax
80106b5f:	79 07                	jns    80106b68 <sys_sbrk+0x24>
    return -1;
80106b61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b66:	eb 24                	jmp    80106b8c <sys_sbrk+0x48>
  addr = proc->sz;
80106b68:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b6e:	8b 00                	mov    (%eax),%eax
80106b70:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106b73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b76:	89 04 24             	mov    %eax,(%esp)
80106b79:	e8 36 e0 ff ff       	call   80104bb4 <growproc>
80106b7e:	85 c0                	test   %eax,%eax
80106b80:	79 07                	jns    80106b89 <sys_sbrk+0x45>
    return -1;
80106b82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b87:	eb 03                	jmp    80106b8c <sys_sbrk+0x48>
  return addr;
80106b89:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106b8c:	c9                   	leave  
80106b8d:	c3                   	ret    

80106b8e <sys_sleep>:

int
sys_sleep(void)
{
80106b8e:	55                   	push   %ebp
80106b8f:	89 e5                	mov    %esp,%ebp
80106b91:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106b94:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106b97:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b9b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ba2:	e8 53 f0 ff ff       	call   80105bfa <argint>
80106ba7:	85 c0                	test   %eax,%eax
80106ba9:	79 07                	jns    80106bb2 <sys_sleep+0x24>
    return -1;
80106bab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bb0:	eb 6c                	jmp    80106c1e <sys_sleep+0x90>
  acquire(&tickslock);
80106bb2:	c7 04 24 00 65 11 80 	movl   $0x80116500,(%esp)
80106bb9:	e8 a6 ea ff ff       	call   80105664 <acquire>
  ticks0 = ticks;
80106bbe:	a1 40 6d 11 80       	mov    0x80116d40,%eax
80106bc3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106bc6:	eb 34                	jmp    80106bfc <sys_sleep+0x6e>
    if(proc->killed){
80106bc8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bce:	8b 40 24             	mov    0x24(%eax),%eax
80106bd1:	85 c0                	test   %eax,%eax
80106bd3:	74 13                	je     80106be8 <sys_sleep+0x5a>
      release(&tickslock);
80106bd5:	c7 04 24 00 65 11 80 	movl   $0x80116500,(%esp)
80106bdc:	e8 e5 ea ff ff       	call   801056c6 <release>
      return -1;
80106be1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106be6:	eb 36                	jmp    80106c1e <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106be8:	c7 44 24 04 00 65 11 	movl   $0x80116500,0x4(%esp)
80106bef:	80 
80106bf0:	c7 04 24 40 6d 11 80 	movl   $0x80116d40,(%esp)
80106bf7:	e8 95 e7 ff ff       	call   80105391 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106bfc:	a1 40 6d 11 80       	mov    0x80116d40,%eax
80106c01:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106c04:	89 c2                	mov    %eax,%edx
80106c06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c09:	39 c2                	cmp    %eax,%edx
80106c0b:	72 bb                	jb     80106bc8 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106c0d:	c7 04 24 00 65 11 80 	movl   $0x80116500,(%esp)
80106c14:	e8 ad ea ff ff       	call   801056c6 <release>
  return 0;
80106c19:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c1e:	c9                   	leave  
80106c1f:	c3                   	ret    

80106c20 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106c20:	55                   	push   %ebp
80106c21:	89 e5                	mov    %esp,%ebp
80106c23:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106c26:	c7 04 24 00 65 11 80 	movl   $0x80116500,(%esp)
80106c2d:	e8 32 ea ff ff       	call   80105664 <acquire>
  xticks = ticks;
80106c32:	a1 40 6d 11 80       	mov    0x80116d40,%eax
80106c37:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106c3a:	c7 04 24 00 65 11 80 	movl   $0x80116500,(%esp)
80106c41:	e8 80 ea ff ff       	call   801056c6 <release>
  return xticks;
80106c46:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106c49:	c9                   	leave  
80106c4a:	c3                   	ret    

80106c4b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106c4b:	55                   	push   %ebp
80106c4c:	89 e5                	mov    %esp,%ebp
80106c4e:	83 ec 08             	sub    $0x8,%esp
80106c51:	8b 55 08             	mov    0x8(%ebp),%edx
80106c54:	8b 45 0c             	mov    0xc(%ebp),%eax
80106c57:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106c5b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106c5e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106c62:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106c66:	ee                   	out    %al,(%dx)
}
80106c67:	c9                   	leave  
80106c68:	c3                   	ret    

80106c69 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106c69:	55                   	push   %ebp
80106c6a:	89 e5                	mov    %esp,%ebp
80106c6c:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106c6f:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106c76:	00 
80106c77:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106c7e:	e8 c8 ff ff ff       	call   80106c4b <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106c83:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106c8a:	00 
80106c8b:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106c92:	e8 b4 ff ff ff       	call   80106c4b <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106c97:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106c9e:	00 
80106c9f:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106ca6:	e8 a0 ff ff ff       	call   80106c4b <outb>
  picenable(IRQ_TIMER);
80106cab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106cb2:	e8 87 d7 ff ff       	call   8010443e <picenable>
}
80106cb7:	c9                   	leave  
80106cb8:	c3                   	ret    

80106cb9 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106cb9:	1e                   	push   %ds
  pushl %es
80106cba:	06                   	push   %es
  pushl %fs
80106cbb:	0f a0                	push   %fs
  pushl %gs
80106cbd:	0f a8                	push   %gs
  pushal
80106cbf:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106cc0:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106cc4:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106cc6:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106cc8:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106ccc:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106cce:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106cd0:	54                   	push   %esp
  call trap
80106cd1:	e8 d8 01 00 00       	call   80106eae <trap>
  addl $4, %esp
80106cd6:	83 c4 04             	add    $0x4,%esp

80106cd9 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106cd9:	61                   	popa   
  popl %gs
80106cda:	0f a9                	pop    %gs
  popl %fs
80106cdc:	0f a1                	pop    %fs
  popl %es
80106cde:	07                   	pop    %es
  popl %ds
80106cdf:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106ce0:	83 c4 08             	add    $0x8,%esp
  iret
80106ce3:	cf                   	iret   

80106ce4 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106ce4:	55                   	push   %ebp
80106ce5:	89 e5                	mov    %esp,%ebp
80106ce7:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106cea:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ced:	83 e8 01             	sub    $0x1,%eax
80106cf0:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106cf4:	8b 45 08             	mov    0x8(%ebp),%eax
80106cf7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106cfb:	8b 45 08             	mov    0x8(%ebp),%eax
80106cfe:	c1 e8 10             	shr    $0x10,%eax
80106d01:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106d05:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106d08:	0f 01 18             	lidtl  (%eax)
}
80106d0b:	c9                   	leave  
80106d0c:	c3                   	ret    

80106d0d <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106d0d:	55                   	push   %ebp
80106d0e:	89 e5                	mov    %esp,%ebp
80106d10:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106d13:	0f 20 d0             	mov    %cr2,%eax
80106d16:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106d19:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106d1c:	c9                   	leave  
80106d1d:	c3                   	ret    

80106d1e <tvinit>:
uint ticks;
void increment_process_times(void);

void
tvinit(void)
{
80106d1e:	55                   	push   %ebp
80106d1f:	89 e5                	mov    %esp,%ebp
80106d21:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106d24:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106d2b:	e9 c3 00 00 00       	jmp    80106df3 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106d30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d33:	8b 04 85 a0 c0 10 80 	mov    -0x7fef3f60(,%eax,4),%eax
80106d3a:	89 c2                	mov    %eax,%edx
80106d3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d3f:	66 89 14 c5 40 65 11 	mov    %dx,-0x7fee9ac0(,%eax,8)
80106d46:	80 
80106d47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d4a:	66 c7 04 c5 42 65 11 	movw   $0x8,-0x7fee9abe(,%eax,8)
80106d51:	80 08 00 
80106d54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d57:	0f b6 14 c5 44 65 11 	movzbl -0x7fee9abc(,%eax,8),%edx
80106d5e:	80 
80106d5f:	83 e2 e0             	and    $0xffffffe0,%edx
80106d62:	88 14 c5 44 65 11 80 	mov    %dl,-0x7fee9abc(,%eax,8)
80106d69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d6c:	0f b6 14 c5 44 65 11 	movzbl -0x7fee9abc(,%eax,8),%edx
80106d73:	80 
80106d74:	83 e2 1f             	and    $0x1f,%edx
80106d77:	88 14 c5 44 65 11 80 	mov    %dl,-0x7fee9abc(,%eax,8)
80106d7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d81:	0f b6 14 c5 45 65 11 	movzbl -0x7fee9abb(,%eax,8),%edx
80106d88:	80 
80106d89:	83 e2 f0             	and    $0xfffffff0,%edx
80106d8c:	83 ca 0e             	or     $0xe,%edx
80106d8f:	88 14 c5 45 65 11 80 	mov    %dl,-0x7fee9abb(,%eax,8)
80106d96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d99:	0f b6 14 c5 45 65 11 	movzbl -0x7fee9abb(,%eax,8),%edx
80106da0:	80 
80106da1:	83 e2 ef             	and    $0xffffffef,%edx
80106da4:	88 14 c5 45 65 11 80 	mov    %dl,-0x7fee9abb(,%eax,8)
80106dab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dae:	0f b6 14 c5 45 65 11 	movzbl -0x7fee9abb(,%eax,8),%edx
80106db5:	80 
80106db6:	83 e2 9f             	and    $0xffffff9f,%edx
80106db9:	88 14 c5 45 65 11 80 	mov    %dl,-0x7fee9abb(,%eax,8)
80106dc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dc3:	0f b6 14 c5 45 65 11 	movzbl -0x7fee9abb(,%eax,8),%edx
80106dca:	80 
80106dcb:	83 ca 80             	or     $0xffffff80,%edx
80106dce:	88 14 c5 45 65 11 80 	mov    %dl,-0x7fee9abb(,%eax,8)
80106dd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dd8:	8b 04 85 a0 c0 10 80 	mov    -0x7fef3f60(,%eax,4),%eax
80106ddf:	c1 e8 10             	shr    $0x10,%eax
80106de2:	89 c2                	mov    %eax,%edx
80106de4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106de7:	66 89 14 c5 46 65 11 	mov    %dx,-0x7fee9aba(,%eax,8)
80106dee:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106def:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106df3:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106dfa:	0f 8e 30 ff ff ff    	jle    80106d30 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106e00:	a1 a0 c1 10 80       	mov    0x8010c1a0,%eax
80106e05:	66 a3 40 67 11 80    	mov    %ax,0x80116740
80106e0b:	66 c7 05 42 67 11 80 	movw   $0x8,0x80116742
80106e12:	08 00 
80106e14:	0f b6 05 44 67 11 80 	movzbl 0x80116744,%eax
80106e1b:	83 e0 e0             	and    $0xffffffe0,%eax
80106e1e:	a2 44 67 11 80       	mov    %al,0x80116744
80106e23:	0f b6 05 44 67 11 80 	movzbl 0x80116744,%eax
80106e2a:	83 e0 1f             	and    $0x1f,%eax
80106e2d:	a2 44 67 11 80       	mov    %al,0x80116744
80106e32:	0f b6 05 45 67 11 80 	movzbl 0x80116745,%eax
80106e39:	83 c8 0f             	or     $0xf,%eax
80106e3c:	a2 45 67 11 80       	mov    %al,0x80116745
80106e41:	0f b6 05 45 67 11 80 	movzbl 0x80116745,%eax
80106e48:	83 e0 ef             	and    $0xffffffef,%eax
80106e4b:	a2 45 67 11 80       	mov    %al,0x80116745
80106e50:	0f b6 05 45 67 11 80 	movzbl 0x80116745,%eax
80106e57:	83 c8 60             	or     $0x60,%eax
80106e5a:	a2 45 67 11 80       	mov    %al,0x80116745
80106e5f:	0f b6 05 45 67 11 80 	movzbl 0x80116745,%eax
80106e66:	83 c8 80             	or     $0xffffff80,%eax
80106e69:	a2 45 67 11 80       	mov    %al,0x80116745
80106e6e:	a1 a0 c1 10 80       	mov    0x8010c1a0,%eax
80106e73:	c1 e8 10             	shr    $0x10,%eax
80106e76:	66 a3 46 67 11 80    	mov    %ax,0x80116746
  
  initlock(&tickslock, "time");
80106e7c:	c7 44 24 04 10 91 10 	movl   $0x80109110,0x4(%esp)
80106e83:	80 
80106e84:	c7 04 24 00 65 11 80 	movl   $0x80116500,(%esp)
80106e8b:	e8 b3 e7 ff ff       	call   80105643 <initlock>
}
80106e90:	c9                   	leave  
80106e91:	c3                   	ret    

80106e92 <idtinit>:

void
idtinit(void)
{
80106e92:	55                   	push   %ebp
80106e93:	89 e5                	mov    %esp,%ebp
80106e95:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106e98:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106e9f:	00 
80106ea0:	c7 04 24 40 65 11 80 	movl   $0x80116540,(%esp)
80106ea7:	e8 38 fe ff ff       	call   80106ce4 <lidt>
}
80106eac:	c9                   	leave  
80106ead:	c3                   	ret    

80106eae <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106eae:	55                   	push   %ebp
80106eaf:	89 e5                	mov    %esp,%ebp
80106eb1:	57                   	push   %edi
80106eb2:	56                   	push   %esi
80106eb3:	53                   	push   %ebx
80106eb4:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106eb7:	8b 45 08             	mov    0x8(%ebp),%eax
80106eba:	8b 40 30             	mov    0x30(%eax),%eax
80106ebd:	83 f8 40             	cmp    $0x40,%eax
80106ec0:	75 3f                	jne    80106f01 <trap+0x53>
    if(proc->killed)
80106ec2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ec8:	8b 40 24             	mov    0x24(%eax),%eax
80106ecb:	85 c0                	test   %eax,%eax
80106ecd:	74 05                	je     80106ed4 <trap+0x26>
      exit();
80106ecf:	e8 34 df ff ff       	call   80104e08 <exit>
    proc->tf = tf;
80106ed4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106eda:	8b 55 08             	mov    0x8(%ebp),%edx
80106edd:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106ee0:	e8 dc ed ff ff       	call   80105cc1 <syscall>
    if(proc->killed)
80106ee5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106eeb:	8b 40 24             	mov    0x24(%eax),%eax
80106eee:	85 c0                	test   %eax,%eax
80106ef0:	74 0a                	je     80106efc <trap+0x4e>
      exit();
80106ef2:	e8 11 df ff ff       	call   80104e08 <exit>
    return;
80106ef7:	e9 32 02 00 00       	jmp    8010712e <trap+0x280>
80106efc:	e9 2d 02 00 00       	jmp    8010712e <trap+0x280>
  }

  switch(tf->trapno){
80106f01:	8b 45 08             	mov    0x8(%ebp),%eax
80106f04:	8b 40 30             	mov    0x30(%eax),%eax
80106f07:	83 e8 20             	sub    $0x20,%eax
80106f0a:	83 f8 1f             	cmp    $0x1f,%eax
80106f0d:	0f 87 c1 00 00 00    	ja     80106fd4 <trap+0x126>
80106f13:	8b 04 85 b8 91 10 80 	mov    -0x7fef6e48(,%eax,4),%eax
80106f1a:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106f1c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106f22:	0f b6 00             	movzbl (%eax),%eax
80106f25:	84 c0                	test   %al,%al
80106f27:	75 36                	jne    80106f5f <trap+0xb1>
      acquire(&tickslock);
80106f29:	c7 04 24 00 65 11 80 	movl   $0x80116500,(%esp)
80106f30:	e8 2f e7 ff ff       	call   80105664 <acquire>
      ticks++;
80106f35:	a1 40 6d 11 80       	mov    0x80116d40,%eax
80106f3a:	83 c0 01             	add    $0x1,%eax
80106f3d:	a3 40 6d 11 80       	mov    %eax,0x80116d40
      increment_process_times(); 
80106f42:	e8 f8 e1 ff ff       	call   8010513f <increment_process_times>
      wakeup(&ticks);
80106f47:	c7 04 24 40 6d 11 80 	movl   $0x80116d40,(%esp)
80106f4e:	e8 1a e5 ff ff       	call   8010546d <wakeup>
      release(&tickslock);
80106f53:	c7 04 24 00 65 11 80 	movl   $0x80116500,(%esp)
80106f5a:	e8 67 e7 ff ff       	call   801056c6 <release>
    }
    lapiceoi();
80106f5f:	e8 05 c6 ff ff       	call   80103569 <lapiceoi>
    break;
80106f64:	e9 41 01 00 00       	jmp    801070aa <trap+0x1fc>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106f69:	e8 09 be ff ff       	call   80102d77 <ideintr>
    lapiceoi();
80106f6e:	e8 f6 c5 ff ff       	call   80103569 <lapiceoi>
    break;
80106f73:	e9 32 01 00 00       	jmp    801070aa <trap+0x1fc>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106f78:	e8 bb c3 ff ff       	call   80103338 <kbdintr>
    lapiceoi();
80106f7d:	e8 e7 c5 ff ff       	call   80103569 <lapiceoi>
    break;
80106f82:	e9 23 01 00 00       	jmp    801070aa <trap+0x1fc>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106f87:	e8 97 03 00 00       	call   80107323 <uartintr>
    lapiceoi();
80106f8c:	e8 d8 c5 ff ff       	call   80103569 <lapiceoi>
    break;
80106f91:	e9 14 01 00 00       	jmp    801070aa <trap+0x1fc>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106f96:	8b 45 08             	mov    0x8(%ebp),%eax
80106f99:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106f9c:	8b 45 08             	mov    0x8(%ebp),%eax
80106f9f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106fa3:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106fa6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106fac:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106faf:	0f b6 c0             	movzbl %al,%eax
80106fb2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106fb6:	89 54 24 08          	mov    %edx,0x8(%esp)
80106fba:	89 44 24 04          	mov    %eax,0x4(%esp)
80106fbe:	c7 04 24 18 91 10 80 	movl   $0x80109118,(%esp)
80106fc5:	e8 d6 93 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106fca:	e8 9a c5 ff ff       	call   80103569 <lapiceoi>
    break;
80106fcf:	e9 d6 00 00 00       	jmp    801070aa <trap+0x1fc>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106fd4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106fda:	85 c0                	test   %eax,%eax
80106fdc:	74 11                	je     80106fef <trap+0x141>
80106fde:	8b 45 08             	mov    0x8(%ebp),%eax
80106fe1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106fe5:	0f b7 c0             	movzwl %ax,%eax
80106fe8:	83 e0 03             	and    $0x3,%eax
80106feb:	85 c0                	test   %eax,%eax
80106fed:	75 46                	jne    80107035 <trap+0x187>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106fef:	e8 19 fd ff ff       	call   80106d0d <rcr2>
80106ff4:	8b 55 08             	mov    0x8(%ebp),%edx
80106ff7:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106ffa:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107001:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107004:	0f b6 ca             	movzbl %dl,%ecx
80107007:	8b 55 08             	mov    0x8(%ebp),%edx
8010700a:	8b 52 30             	mov    0x30(%edx),%edx
8010700d:	89 44 24 10          	mov    %eax,0x10(%esp)
80107011:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107015:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107019:	89 54 24 04          	mov    %edx,0x4(%esp)
8010701d:	c7 04 24 3c 91 10 80 	movl   $0x8010913c,(%esp)
80107024:	e8 77 93 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107029:	c7 04 24 6e 91 10 80 	movl   $0x8010916e,(%esp)
80107030:	e8 05 95 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107035:	e8 d3 fc ff ff       	call   80106d0d <rcr2>
8010703a:	89 c2                	mov    %eax,%edx
8010703c:	8b 45 08             	mov    0x8(%ebp),%eax
8010703f:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107042:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107048:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010704b:	0f b6 f0             	movzbl %al,%esi
8010704e:	8b 45 08             	mov    0x8(%ebp),%eax
80107051:	8b 58 34             	mov    0x34(%eax),%ebx
80107054:	8b 45 08             	mov    0x8(%ebp),%eax
80107057:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010705a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107060:	83 c0 6c             	add    $0x6c,%eax
80107063:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107066:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010706c:	8b 40 10             	mov    0x10(%eax),%eax
8010706f:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107073:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107077:	89 74 24 14          	mov    %esi,0x14(%esp)
8010707b:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010707f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107083:	8b 75 e4             	mov    -0x1c(%ebp),%esi
80107086:	89 74 24 08          	mov    %esi,0x8(%esp)
8010708a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010708e:	c7 04 24 74 91 10 80 	movl   $0x80109174,(%esp)
80107095:	e8 06 93 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010709a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070a0:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801070a7:	eb 01                	jmp    801070aa <trap+0x1fc>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801070a9:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801070aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070b0:	85 c0                	test   %eax,%eax
801070b2:	74 24                	je     801070d8 <trap+0x22a>
801070b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070ba:	8b 40 24             	mov    0x24(%eax),%eax
801070bd:	85 c0                	test   %eax,%eax
801070bf:	74 17                	je     801070d8 <trap+0x22a>
801070c1:	8b 45 08             	mov    0x8(%ebp),%eax
801070c4:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801070c8:	0f b7 c0             	movzwl %ax,%eax
801070cb:	83 e0 03             	and    $0x3,%eax
801070ce:	83 f8 03             	cmp    $0x3,%eax
801070d1:	75 05                	jne    801070d8 <trap+0x22a>
    exit();
801070d3:	e8 30 dd ff ff       	call   80104e08 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
801070d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070de:	85 c0                	test   %eax,%eax
801070e0:	74 1e                	je     80107100 <trap+0x252>
801070e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070e8:	8b 40 0c             	mov    0xc(%eax),%eax
801070eb:	83 f8 04             	cmp    $0x4,%eax
801070ee:	75 10                	jne    80107100 <trap+0x252>
801070f0:	8b 45 08             	mov    0x8(%ebp),%eax
801070f3:	8b 40 30             	mov    0x30(%eax),%eax
801070f6:	83 f8 20             	cmp    $0x20,%eax
801070f9:	75 05                	jne    80107100 <trap+0x252>
    yield();
801070fb:	e8 20 e2 ff ff       	call   80105320 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107100:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107106:	85 c0                	test   %eax,%eax
80107108:	74 24                	je     8010712e <trap+0x280>
8010710a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107110:	8b 40 24             	mov    0x24(%eax),%eax
80107113:	85 c0                	test   %eax,%eax
80107115:	74 17                	je     8010712e <trap+0x280>
80107117:	8b 45 08             	mov    0x8(%ebp),%eax
8010711a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010711e:	0f b7 c0             	movzwl %ax,%eax
80107121:	83 e0 03             	and    $0x3,%eax
80107124:	83 f8 03             	cmp    $0x3,%eax
80107127:	75 05                	jne    8010712e <trap+0x280>
    exit();
80107129:	e8 da dc ff ff       	call   80104e08 <exit>
}
8010712e:	83 c4 3c             	add    $0x3c,%esp
80107131:	5b                   	pop    %ebx
80107132:	5e                   	pop    %esi
80107133:	5f                   	pop    %edi
80107134:	5d                   	pop    %ebp
80107135:	c3                   	ret    

80107136 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107136:	55                   	push   %ebp
80107137:	89 e5                	mov    %esp,%ebp
80107139:	83 ec 14             	sub    $0x14,%esp
8010713c:	8b 45 08             	mov    0x8(%ebp),%eax
8010713f:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107143:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80107147:	89 c2                	mov    %eax,%edx
80107149:	ec                   	in     (%dx),%al
8010714a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010714d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80107151:	c9                   	leave  
80107152:	c3                   	ret    

80107153 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107153:	55                   	push   %ebp
80107154:	89 e5                	mov    %esp,%ebp
80107156:	83 ec 08             	sub    $0x8,%esp
80107159:	8b 55 08             	mov    0x8(%ebp),%edx
8010715c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010715f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107163:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107166:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010716a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010716e:	ee                   	out    %al,(%dx)
}
8010716f:	c9                   	leave  
80107170:	c3                   	ret    

80107171 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107171:	55                   	push   %ebp
80107172:	89 e5                	mov    %esp,%ebp
80107174:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107177:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010717e:	00 
8010717f:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107186:	e8 c8 ff ff ff       	call   80107153 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010718b:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107192:	00 
80107193:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010719a:	e8 b4 ff ff ff       	call   80107153 <outb>
  outb(COM1+0, 115200/9600);
8010719f:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
801071a6:	00 
801071a7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801071ae:	e8 a0 ff ff ff       	call   80107153 <outb>
  outb(COM1+1, 0);
801071b3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801071ba:	00 
801071bb:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801071c2:	e8 8c ff ff ff       	call   80107153 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
801071c7:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801071ce:	00 
801071cf:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801071d6:	e8 78 ff ff ff       	call   80107153 <outb>
  outb(COM1+4, 0);
801071db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801071e2:	00 
801071e3:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801071ea:	e8 64 ff ff ff       	call   80107153 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801071ef:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801071f6:	00 
801071f7:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801071fe:	e8 50 ff ff ff       	call   80107153 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107203:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010720a:	e8 27 ff ff ff       	call   80107136 <inb>
8010720f:	3c ff                	cmp    $0xff,%al
80107211:	75 02                	jne    80107215 <uartinit+0xa4>
    return;
80107213:	eb 6a                	jmp    8010727f <uartinit+0x10e>
  uart = 1;
80107215:	c7 05 4c c6 10 80 01 	movl   $0x1,0x8010c64c
8010721c:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
8010721f:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107226:	e8 0b ff ff ff       	call   80107136 <inb>
  inb(COM1+0);
8010722b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107232:	e8 ff fe ff ff       	call   80107136 <inb>
  picenable(IRQ_COM1);
80107237:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010723e:	e8 fb d1 ff ff       	call   8010443e <picenable>
  ioapicenable(IRQ_COM1, 0);
80107243:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010724a:	00 
8010724b:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107252:	e8 9f bd ff ff       	call   80102ff6 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107257:	c7 45 f4 38 92 10 80 	movl   $0x80109238,-0xc(%ebp)
8010725e:	eb 15                	jmp    80107275 <uartinit+0x104>
    uartputc(*p);
80107260:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107263:	0f b6 00             	movzbl (%eax),%eax
80107266:	0f be c0             	movsbl %al,%eax
80107269:	89 04 24             	mov    %eax,(%esp)
8010726c:	e8 10 00 00 00       	call   80107281 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107271:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107275:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107278:	0f b6 00             	movzbl (%eax),%eax
8010727b:	84 c0                	test   %al,%al
8010727d:	75 e1                	jne    80107260 <uartinit+0xef>
    uartputc(*p);
}
8010727f:	c9                   	leave  
80107280:	c3                   	ret    

80107281 <uartputc>:

void
uartputc(int c)
{
80107281:	55                   	push   %ebp
80107282:	89 e5                	mov    %esp,%ebp
80107284:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107287:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
8010728c:	85 c0                	test   %eax,%eax
8010728e:	75 02                	jne    80107292 <uartputc+0x11>
    return;
80107290:	eb 4b                	jmp    801072dd <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107292:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107299:	eb 10                	jmp    801072ab <uartputc+0x2a>
    microdelay(10);
8010729b:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801072a2:	e8 e7 c2 ff ff       	call   8010358e <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801072a7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801072ab:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801072af:	7f 16                	jg     801072c7 <uartputc+0x46>
801072b1:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801072b8:	e8 79 fe ff ff       	call   80107136 <inb>
801072bd:	0f b6 c0             	movzbl %al,%eax
801072c0:	83 e0 20             	and    $0x20,%eax
801072c3:	85 c0                	test   %eax,%eax
801072c5:	74 d4                	je     8010729b <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
801072c7:	8b 45 08             	mov    0x8(%ebp),%eax
801072ca:	0f b6 c0             	movzbl %al,%eax
801072cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801072d1:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801072d8:	e8 76 fe ff ff       	call   80107153 <outb>
}
801072dd:	c9                   	leave  
801072de:	c3                   	ret    

801072df <uartgetc>:

static int
uartgetc(void)
{
801072df:	55                   	push   %ebp
801072e0:	89 e5                	mov    %esp,%ebp
801072e2:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801072e5:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
801072ea:	85 c0                	test   %eax,%eax
801072ec:	75 07                	jne    801072f5 <uartgetc+0x16>
    return -1;
801072ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072f3:	eb 2c                	jmp    80107321 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801072f5:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801072fc:	e8 35 fe ff ff       	call   80107136 <inb>
80107301:	0f b6 c0             	movzbl %al,%eax
80107304:	83 e0 01             	and    $0x1,%eax
80107307:	85 c0                	test   %eax,%eax
80107309:	75 07                	jne    80107312 <uartgetc+0x33>
    return -1;
8010730b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107310:	eb 0f                	jmp    80107321 <uartgetc+0x42>
  return inb(COM1+0);
80107312:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107319:	e8 18 fe ff ff       	call   80107136 <inb>
8010731e:	0f b6 c0             	movzbl %al,%eax
}
80107321:	c9                   	leave  
80107322:	c3                   	ret    

80107323 <uartintr>:

void
uartintr(void)
{
80107323:	55                   	push   %ebp
80107324:	89 e5                	mov    %esp,%ebp
80107326:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107329:	c7 04 24 df 72 10 80 	movl   $0x801072df,(%esp)
80107330:	e8 c1 97 ff ff       	call   80100af6 <consoleintr>
}
80107335:	c9                   	leave  
80107336:	c3                   	ret    

80107337 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107337:	6a 00                	push   $0x0
  pushl $0
80107339:	6a 00                	push   $0x0
  jmp alltraps
8010733b:	e9 79 f9 ff ff       	jmp    80106cb9 <alltraps>

80107340 <vector1>:
.globl vector1
vector1:
  pushl $0
80107340:	6a 00                	push   $0x0
  pushl $1
80107342:	6a 01                	push   $0x1
  jmp alltraps
80107344:	e9 70 f9 ff ff       	jmp    80106cb9 <alltraps>

80107349 <vector2>:
.globl vector2
vector2:
  pushl $0
80107349:	6a 00                	push   $0x0
  pushl $2
8010734b:	6a 02                	push   $0x2
  jmp alltraps
8010734d:	e9 67 f9 ff ff       	jmp    80106cb9 <alltraps>

80107352 <vector3>:
.globl vector3
vector3:
  pushl $0
80107352:	6a 00                	push   $0x0
  pushl $3
80107354:	6a 03                	push   $0x3
  jmp alltraps
80107356:	e9 5e f9 ff ff       	jmp    80106cb9 <alltraps>

8010735b <vector4>:
.globl vector4
vector4:
  pushl $0
8010735b:	6a 00                	push   $0x0
  pushl $4
8010735d:	6a 04                	push   $0x4
  jmp alltraps
8010735f:	e9 55 f9 ff ff       	jmp    80106cb9 <alltraps>

80107364 <vector5>:
.globl vector5
vector5:
  pushl $0
80107364:	6a 00                	push   $0x0
  pushl $5
80107366:	6a 05                	push   $0x5
  jmp alltraps
80107368:	e9 4c f9 ff ff       	jmp    80106cb9 <alltraps>

8010736d <vector6>:
.globl vector6
vector6:
  pushl $0
8010736d:	6a 00                	push   $0x0
  pushl $6
8010736f:	6a 06                	push   $0x6
  jmp alltraps
80107371:	e9 43 f9 ff ff       	jmp    80106cb9 <alltraps>

80107376 <vector7>:
.globl vector7
vector7:
  pushl $0
80107376:	6a 00                	push   $0x0
  pushl $7
80107378:	6a 07                	push   $0x7
  jmp alltraps
8010737a:	e9 3a f9 ff ff       	jmp    80106cb9 <alltraps>

8010737f <vector8>:
.globl vector8
vector8:
  pushl $8
8010737f:	6a 08                	push   $0x8
  jmp alltraps
80107381:	e9 33 f9 ff ff       	jmp    80106cb9 <alltraps>

80107386 <vector9>:
.globl vector9
vector9:
  pushl $0
80107386:	6a 00                	push   $0x0
  pushl $9
80107388:	6a 09                	push   $0x9
  jmp alltraps
8010738a:	e9 2a f9 ff ff       	jmp    80106cb9 <alltraps>

8010738f <vector10>:
.globl vector10
vector10:
  pushl $10
8010738f:	6a 0a                	push   $0xa
  jmp alltraps
80107391:	e9 23 f9 ff ff       	jmp    80106cb9 <alltraps>

80107396 <vector11>:
.globl vector11
vector11:
  pushl $11
80107396:	6a 0b                	push   $0xb
  jmp alltraps
80107398:	e9 1c f9 ff ff       	jmp    80106cb9 <alltraps>

8010739d <vector12>:
.globl vector12
vector12:
  pushl $12
8010739d:	6a 0c                	push   $0xc
  jmp alltraps
8010739f:	e9 15 f9 ff ff       	jmp    80106cb9 <alltraps>

801073a4 <vector13>:
.globl vector13
vector13:
  pushl $13
801073a4:	6a 0d                	push   $0xd
  jmp alltraps
801073a6:	e9 0e f9 ff ff       	jmp    80106cb9 <alltraps>

801073ab <vector14>:
.globl vector14
vector14:
  pushl $14
801073ab:	6a 0e                	push   $0xe
  jmp alltraps
801073ad:	e9 07 f9 ff ff       	jmp    80106cb9 <alltraps>

801073b2 <vector15>:
.globl vector15
vector15:
  pushl $0
801073b2:	6a 00                	push   $0x0
  pushl $15
801073b4:	6a 0f                	push   $0xf
  jmp alltraps
801073b6:	e9 fe f8 ff ff       	jmp    80106cb9 <alltraps>

801073bb <vector16>:
.globl vector16
vector16:
  pushl $0
801073bb:	6a 00                	push   $0x0
  pushl $16
801073bd:	6a 10                	push   $0x10
  jmp alltraps
801073bf:	e9 f5 f8 ff ff       	jmp    80106cb9 <alltraps>

801073c4 <vector17>:
.globl vector17
vector17:
  pushl $17
801073c4:	6a 11                	push   $0x11
  jmp alltraps
801073c6:	e9 ee f8 ff ff       	jmp    80106cb9 <alltraps>

801073cb <vector18>:
.globl vector18
vector18:
  pushl $0
801073cb:	6a 00                	push   $0x0
  pushl $18
801073cd:	6a 12                	push   $0x12
  jmp alltraps
801073cf:	e9 e5 f8 ff ff       	jmp    80106cb9 <alltraps>

801073d4 <vector19>:
.globl vector19
vector19:
  pushl $0
801073d4:	6a 00                	push   $0x0
  pushl $19
801073d6:	6a 13                	push   $0x13
  jmp alltraps
801073d8:	e9 dc f8 ff ff       	jmp    80106cb9 <alltraps>

801073dd <vector20>:
.globl vector20
vector20:
  pushl $0
801073dd:	6a 00                	push   $0x0
  pushl $20
801073df:	6a 14                	push   $0x14
  jmp alltraps
801073e1:	e9 d3 f8 ff ff       	jmp    80106cb9 <alltraps>

801073e6 <vector21>:
.globl vector21
vector21:
  pushl $0
801073e6:	6a 00                	push   $0x0
  pushl $21
801073e8:	6a 15                	push   $0x15
  jmp alltraps
801073ea:	e9 ca f8 ff ff       	jmp    80106cb9 <alltraps>

801073ef <vector22>:
.globl vector22
vector22:
  pushl $0
801073ef:	6a 00                	push   $0x0
  pushl $22
801073f1:	6a 16                	push   $0x16
  jmp alltraps
801073f3:	e9 c1 f8 ff ff       	jmp    80106cb9 <alltraps>

801073f8 <vector23>:
.globl vector23
vector23:
  pushl $0
801073f8:	6a 00                	push   $0x0
  pushl $23
801073fa:	6a 17                	push   $0x17
  jmp alltraps
801073fc:	e9 b8 f8 ff ff       	jmp    80106cb9 <alltraps>

80107401 <vector24>:
.globl vector24
vector24:
  pushl $0
80107401:	6a 00                	push   $0x0
  pushl $24
80107403:	6a 18                	push   $0x18
  jmp alltraps
80107405:	e9 af f8 ff ff       	jmp    80106cb9 <alltraps>

8010740a <vector25>:
.globl vector25
vector25:
  pushl $0
8010740a:	6a 00                	push   $0x0
  pushl $25
8010740c:	6a 19                	push   $0x19
  jmp alltraps
8010740e:	e9 a6 f8 ff ff       	jmp    80106cb9 <alltraps>

80107413 <vector26>:
.globl vector26
vector26:
  pushl $0
80107413:	6a 00                	push   $0x0
  pushl $26
80107415:	6a 1a                	push   $0x1a
  jmp alltraps
80107417:	e9 9d f8 ff ff       	jmp    80106cb9 <alltraps>

8010741c <vector27>:
.globl vector27
vector27:
  pushl $0
8010741c:	6a 00                	push   $0x0
  pushl $27
8010741e:	6a 1b                	push   $0x1b
  jmp alltraps
80107420:	e9 94 f8 ff ff       	jmp    80106cb9 <alltraps>

80107425 <vector28>:
.globl vector28
vector28:
  pushl $0
80107425:	6a 00                	push   $0x0
  pushl $28
80107427:	6a 1c                	push   $0x1c
  jmp alltraps
80107429:	e9 8b f8 ff ff       	jmp    80106cb9 <alltraps>

8010742e <vector29>:
.globl vector29
vector29:
  pushl $0
8010742e:	6a 00                	push   $0x0
  pushl $29
80107430:	6a 1d                	push   $0x1d
  jmp alltraps
80107432:	e9 82 f8 ff ff       	jmp    80106cb9 <alltraps>

80107437 <vector30>:
.globl vector30
vector30:
  pushl $0
80107437:	6a 00                	push   $0x0
  pushl $30
80107439:	6a 1e                	push   $0x1e
  jmp alltraps
8010743b:	e9 79 f8 ff ff       	jmp    80106cb9 <alltraps>

80107440 <vector31>:
.globl vector31
vector31:
  pushl $0
80107440:	6a 00                	push   $0x0
  pushl $31
80107442:	6a 1f                	push   $0x1f
  jmp alltraps
80107444:	e9 70 f8 ff ff       	jmp    80106cb9 <alltraps>

80107449 <vector32>:
.globl vector32
vector32:
  pushl $0
80107449:	6a 00                	push   $0x0
  pushl $32
8010744b:	6a 20                	push   $0x20
  jmp alltraps
8010744d:	e9 67 f8 ff ff       	jmp    80106cb9 <alltraps>

80107452 <vector33>:
.globl vector33
vector33:
  pushl $0
80107452:	6a 00                	push   $0x0
  pushl $33
80107454:	6a 21                	push   $0x21
  jmp alltraps
80107456:	e9 5e f8 ff ff       	jmp    80106cb9 <alltraps>

8010745b <vector34>:
.globl vector34
vector34:
  pushl $0
8010745b:	6a 00                	push   $0x0
  pushl $34
8010745d:	6a 22                	push   $0x22
  jmp alltraps
8010745f:	e9 55 f8 ff ff       	jmp    80106cb9 <alltraps>

80107464 <vector35>:
.globl vector35
vector35:
  pushl $0
80107464:	6a 00                	push   $0x0
  pushl $35
80107466:	6a 23                	push   $0x23
  jmp alltraps
80107468:	e9 4c f8 ff ff       	jmp    80106cb9 <alltraps>

8010746d <vector36>:
.globl vector36
vector36:
  pushl $0
8010746d:	6a 00                	push   $0x0
  pushl $36
8010746f:	6a 24                	push   $0x24
  jmp alltraps
80107471:	e9 43 f8 ff ff       	jmp    80106cb9 <alltraps>

80107476 <vector37>:
.globl vector37
vector37:
  pushl $0
80107476:	6a 00                	push   $0x0
  pushl $37
80107478:	6a 25                	push   $0x25
  jmp alltraps
8010747a:	e9 3a f8 ff ff       	jmp    80106cb9 <alltraps>

8010747f <vector38>:
.globl vector38
vector38:
  pushl $0
8010747f:	6a 00                	push   $0x0
  pushl $38
80107481:	6a 26                	push   $0x26
  jmp alltraps
80107483:	e9 31 f8 ff ff       	jmp    80106cb9 <alltraps>

80107488 <vector39>:
.globl vector39
vector39:
  pushl $0
80107488:	6a 00                	push   $0x0
  pushl $39
8010748a:	6a 27                	push   $0x27
  jmp alltraps
8010748c:	e9 28 f8 ff ff       	jmp    80106cb9 <alltraps>

80107491 <vector40>:
.globl vector40
vector40:
  pushl $0
80107491:	6a 00                	push   $0x0
  pushl $40
80107493:	6a 28                	push   $0x28
  jmp alltraps
80107495:	e9 1f f8 ff ff       	jmp    80106cb9 <alltraps>

8010749a <vector41>:
.globl vector41
vector41:
  pushl $0
8010749a:	6a 00                	push   $0x0
  pushl $41
8010749c:	6a 29                	push   $0x29
  jmp alltraps
8010749e:	e9 16 f8 ff ff       	jmp    80106cb9 <alltraps>

801074a3 <vector42>:
.globl vector42
vector42:
  pushl $0
801074a3:	6a 00                	push   $0x0
  pushl $42
801074a5:	6a 2a                	push   $0x2a
  jmp alltraps
801074a7:	e9 0d f8 ff ff       	jmp    80106cb9 <alltraps>

801074ac <vector43>:
.globl vector43
vector43:
  pushl $0
801074ac:	6a 00                	push   $0x0
  pushl $43
801074ae:	6a 2b                	push   $0x2b
  jmp alltraps
801074b0:	e9 04 f8 ff ff       	jmp    80106cb9 <alltraps>

801074b5 <vector44>:
.globl vector44
vector44:
  pushl $0
801074b5:	6a 00                	push   $0x0
  pushl $44
801074b7:	6a 2c                	push   $0x2c
  jmp alltraps
801074b9:	e9 fb f7 ff ff       	jmp    80106cb9 <alltraps>

801074be <vector45>:
.globl vector45
vector45:
  pushl $0
801074be:	6a 00                	push   $0x0
  pushl $45
801074c0:	6a 2d                	push   $0x2d
  jmp alltraps
801074c2:	e9 f2 f7 ff ff       	jmp    80106cb9 <alltraps>

801074c7 <vector46>:
.globl vector46
vector46:
  pushl $0
801074c7:	6a 00                	push   $0x0
  pushl $46
801074c9:	6a 2e                	push   $0x2e
  jmp alltraps
801074cb:	e9 e9 f7 ff ff       	jmp    80106cb9 <alltraps>

801074d0 <vector47>:
.globl vector47
vector47:
  pushl $0
801074d0:	6a 00                	push   $0x0
  pushl $47
801074d2:	6a 2f                	push   $0x2f
  jmp alltraps
801074d4:	e9 e0 f7 ff ff       	jmp    80106cb9 <alltraps>

801074d9 <vector48>:
.globl vector48
vector48:
  pushl $0
801074d9:	6a 00                	push   $0x0
  pushl $48
801074db:	6a 30                	push   $0x30
  jmp alltraps
801074dd:	e9 d7 f7 ff ff       	jmp    80106cb9 <alltraps>

801074e2 <vector49>:
.globl vector49
vector49:
  pushl $0
801074e2:	6a 00                	push   $0x0
  pushl $49
801074e4:	6a 31                	push   $0x31
  jmp alltraps
801074e6:	e9 ce f7 ff ff       	jmp    80106cb9 <alltraps>

801074eb <vector50>:
.globl vector50
vector50:
  pushl $0
801074eb:	6a 00                	push   $0x0
  pushl $50
801074ed:	6a 32                	push   $0x32
  jmp alltraps
801074ef:	e9 c5 f7 ff ff       	jmp    80106cb9 <alltraps>

801074f4 <vector51>:
.globl vector51
vector51:
  pushl $0
801074f4:	6a 00                	push   $0x0
  pushl $51
801074f6:	6a 33                	push   $0x33
  jmp alltraps
801074f8:	e9 bc f7 ff ff       	jmp    80106cb9 <alltraps>

801074fd <vector52>:
.globl vector52
vector52:
  pushl $0
801074fd:	6a 00                	push   $0x0
  pushl $52
801074ff:	6a 34                	push   $0x34
  jmp alltraps
80107501:	e9 b3 f7 ff ff       	jmp    80106cb9 <alltraps>

80107506 <vector53>:
.globl vector53
vector53:
  pushl $0
80107506:	6a 00                	push   $0x0
  pushl $53
80107508:	6a 35                	push   $0x35
  jmp alltraps
8010750a:	e9 aa f7 ff ff       	jmp    80106cb9 <alltraps>

8010750f <vector54>:
.globl vector54
vector54:
  pushl $0
8010750f:	6a 00                	push   $0x0
  pushl $54
80107511:	6a 36                	push   $0x36
  jmp alltraps
80107513:	e9 a1 f7 ff ff       	jmp    80106cb9 <alltraps>

80107518 <vector55>:
.globl vector55
vector55:
  pushl $0
80107518:	6a 00                	push   $0x0
  pushl $55
8010751a:	6a 37                	push   $0x37
  jmp alltraps
8010751c:	e9 98 f7 ff ff       	jmp    80106cb9 <alltraps>

80107521 <vector56>:
.globl vector56
vector56:
  pushl $0
80107521:	6a 00                	push   $0x0
  pushl $56
80107523:	6a 38                	push   $0x38
  jmp alltraps
80107525:	e9 8f f7 ff ff       	jmp    80106cb9 <alltraps>

8010752a <vector57>:
.globl vector57
vector57:
  pushl $0
8010752a:	6a 00                	push   $0x0
  pushl $57
8010752c:	6a 39                	push   $0x39
  jmp alltraps
8010752e:	e9 86 f7 ff ff       	jmp    80106cb9 <alltraps>

80107533 <vector58>:
.globl vector58
vector58:
  pushl $0
80107533:	6a 00                	push   $0x0
  pushl $58
80107535:	6a 3a                	push   $0x3a
  jmp alltraps
80107537:	e9 7d f7 ff ff       	jmp    80106cb9 <alltraps>

8010753c <vector59>:
.globl vector59
vector59:
  pushl $0
8010753c:	6a 00                	push   $0x0
  pushl $59
8010753e:	6a 3b                	push   $0x3b
  jmp alltraps
80107540:	e9 74 f7 ff ff       	jmp    80106cb9 <alltraps>

80107545 <vector60>:
.globl vector60
vector60:
  pushl $0
80107545:	6a 00                	push   $0x0
  pushl $60
80107547:	6a 3c                	push   $0x3c
  jmp alltraps
80107549:	e9 6b f7 ff ff       	jmp    80106cb9 <alltraps>

8010754e <vector61>:
.globl vector61
vector61:
  pushl $0
8010754e:	6a 00                	push   $0x0
  pushl $61
80107550:	6a 3d                	push   $0x3d
  jmp alltraps
80107552:	e9 62 f7 ff ff       	jmp    80106cb9 <alltraps>

80107557 <vector62>:
.globl vector62
vector62:
  pushl $0
80107557:	6a 00                	push   $0x0
  pushl $62
80107559:	6a 3e                	push   $0x3e
  jmp alltraps
8010755b:	e9 59 f7 ff ff       	jmp    80106cb9 <alltraps>

80107560 <vector63>:
.globl vector63
vector63:
  pushl $0
80107560:	6a 00                	push   $0x0
  pushl $63
80107562:	6a 3f                	push   $0x3f
  jmp alltraps
80107564:	e9 50 f7 ff ff       	jmp    80106cb9 <alltraps>

80107569 <vector64>:
.globl vector64
vector64:
  pushl $0
80107569:	6a 00                	push   $0x0
  pushl $64
8010756b:	6a 40                	push   $0x40
  jmp alltraps
8010756d:	e9 47 f7 ff ff       	jmp    80106cb9 <alltraps>

80107572 <vector65>:
.globl vector65
vector65:
  pushl $0
80107572:	6a 00                	push   $0x0
  pushl $65
80107574:	6a 41                	push   $0x41
  jmp alltraps
80107576:	e9 3e f7 ff ff       	jmp    80106cb9 <alltraps>

8010757b <vector66>:
.globl vector66
vector66:
  pushl $0
8010757b:	6a 00                	push   $0x0
  pushl $66
8010757d:	6a 42                	push   $0x42
  jmp alltraps
8010757f:	e9 35 f7 ff ff       	jmp    80106cb9 <alltraps>

80107584 <vector67>:
.globl vector67
vector67:
  pushl $0
80107584:	6a 00                	push   $0x0
  pushl $67
80107586:	6a 43                	push   $0x43
  jmp alltraps
80107588:	e9 2c f7 ff ff       	jmp    80106cb9 <alltraps>

8010758d <vector68>:
.globl vector68
vector68:
  pushl $0
8010758d:	6a 00                	push   $0x0
  pushl $68
8010758f:	6a 44                	push   $0x44
  jmp alltraps
80107591:	e9 23 f7 ff ff       	jmp    80106cb9 <alltraps>

80107596 <vector69>:
.globl vector69
vector69:
  pushl $0
80107596:	6a 00                	push   $0x0
  pushl $69
80107598:	6a 45                	push   $0x45
  jmp alltraps
8010759a:	e9 1a f7 ff ff       	jmp    80106cb9 <alltraps>

8010759f <vector70>:
.globl vector70
vector70:
  pushl $0
8010759f:	6a 00                	push   $0x0
  pushl $70
801075a1:	6a 46                	push   $0x46
  jmp alltraps
801075a3:	e9 11 f7 ff ff       	jmp    80106cb9 <alltraps>

801075a8 <vector71>:
.globl vector71
vector71:
  pushl $0
801075a8:	6a 00                	push   $0x0
  pushl $71
801075aa:	6a 47                	push   $0x47
  jmp alltraps
801075ac:	e9 08 f7 ff ff       	jmp    80106cb9 <alltraps>

801075b1 <vector72>:
.globl vector72
vector72:
  pushl $0
801075b1:	6a 00                	push   $0x0
  pushl $72
801075b3:	6a 48                	push   $0x48
  jmp alltraps
801075b5:	e9 ff f6 ff ff       	jmp    80106cb9 <alltraps>

801075ba <vector73>:
.globl vector73
vector73:
  pushl $0
801075ba:	6a 00                	push   $0x0
  pushl $73
801075bc:	6a 49                	push   $0x49
  jmp alltraps
801075be:	e9 f6 f6 ff ff       	jmp    80106cb9 <alltraps>

801075c3 <vector74>:
.globl vector74
vector74:
  pushl $0
801075c3:	6a 00                	push   $0x0
  pushl $74
801075c5:	6a 4a                	push   $0x4a
  jmp alltraps
801075c7:	e9 ed f6 ff ff       	jmp    80106cb9 <alltraps>

801075cc <vector75>:
.globl vector75
vector75:
  pushl $0
801075cc:	6a 00                	push   $0x0
  pushl $75
801075ce:	6a 4b                	push   $0x4b
  jmp alltraps
801075d0:	e9 e4 f6 ff ff       	jmp    80106cb9 <alltraps>

801075d5 <vector76>:
.globl vector76
vector76:
  pushl $0
801075d5:	6a 00                	push   $0x0
  pushl $76
801075d7:	6a 4c                	push   $0x4c
  jmp alltraps
801075d9:	e9 db f6 ff ff       	jmp    80106cb9 <alltraps>

801075de <vector77>:
.globl vector77
vector77:
  pushl $0
801075de:	6a 00                	push   $0x0
  pushl $77
801075e0:	6a 4d                	push   $0x4d
  jmp alltraps
801075e2:	e9 d2 f6 ff ff       	jmp    80106cb9 <alltraps>

801075e7 <vector78>:
.globl vector78
vector78:
  pushl $0
801075e7:	6a 00                	push   $0x0
  pushl $78
801075e9:	6a 4e                	push   $0x4e
  jmp alltraps
801075eb:	e9 c9 f6 ff ff       	jmp    80106cb9 <alltraps>

801075f0 <vector79>:
.globl vector79
vector79:
  pushl $0
801075f0:	6a 00                	push   $0x0
  pushl $79
801075f2:	6a 4f                	push   $0x4f
  jmp alltraps
801075f4:	e9 c0 f6 ff ff       	jmp    80106cb9 <alltraps>

801075f9 <vector80>:
.globl vector80
vector80:
  pushl $0
801075f9:	6a 00                	push   $0x0
  pushl $80
801075fb:	6a 50                	push   $0x50
  jmp alltraps
801075fd:	e9 b7 f6 ff ff       	jmp    80106cb9 <alltraps>

80107602 <vector81>:
.globl vector81
vector81:
  pushl $0
80107602:	6a 00                	push   $0x0
  pushl $81
80107604:	6a 51                	push   $0x51
  jmp alltraps
80107606:	e9 ae f6 ff ff       	jmp    80106cb9 <alltraps>

8010760b <vector82>:
.globl vector82
vector82:
  pushl $0
8010760b:	6a 00                	push   $0x0
  pushl $82
8010760d:	6a 52                	push   $0x52
  jmp alltraps
8010760f:	e9 a5 f6 ff ff       	jmp    80106cb9 <alltraps>

80107614 <vector83>:
.globl vector83
vector83:
  pushl $0
80107614:	6a 00                	push   $0x0
  pushl $83
80107616:	6a 53                	push   $0x53
  jmp alltraps
80107618:	e9 9c f6 ff ff       	jmp    80106cb9 <alltraps>

8010761d <vector84>:
.globl vector84
vector84:
  pushl $0
8010761d:	6a 00                	push   $0x0
  pushl $84
8010761f:	6a 54                	push   $0x54
  jmp alltraps
80107621:	e9 93 f6 ff ff       	jmp    80106cb9 <alltraps>

80107626 <vector85>:
.globl vector85
vector85:
  pushl $0
80107626:	6a 00                	push   $0x0
  pushl $85
80107628:	6a 55                	push   $0x55
  jmp alltraps
8010762a:	e9 8a f6 ff ff       	jmp    80106cb9 <alltraps>

8010762f <vector86>:
.globl vector86
vector86:
  pushl $0
8010762f:	6a 00                	push   $0x0
  pushl $86
80107631:	6a 56                	push   $0x56
  jmp alltraps
80107633:	e9 81 f6 ff ff       	jmp    80106cb9 <alltraps>

80107638 <vector87>:
.globl vector87
vector87:
  pushl $0
80107638:	6a 00                	push   $0x0
  pushl $87
8010763a:	6a 57                	push   $0x57
  jmp alltraps
8010763c:	e9 78 f6 ff ff       	jmp    80106cb9 <alltraps>

80107641 <vector88>:
.globl vector88
vector88:
  pushl $0
80107641:	6a 00                	push   $0x0
  pushl $88
80107643:	6a 58                	push   $0x58
  jmp alltraps
80107645:	e9 6f f6 ff ff       	jmp    80106cb9 <alltraps>

8010764a <vector89>:
.globl vector89
vector89:
  pushl $0
8010764a:	6a 00                	push   $0x0
  pushl $89
8010764c:	6a 59                	push   $0x59
  jmp alltraps
8010764e:	e9 66 f6 ff ff       	jmp    80106cb9 <alltraps>

80107653 <vector90>:
.globl vector90
vector90:
  pushl $0
80107653:	6a 00                	push   $0x0
  pushl $90
80107655:	6a 5a                	push   $0x5a
  jmp alltraps
80107657:	e9 5d f6 ff ff       	jmp    80106cb9 <alltraps>

8010765c <vector91>:
.globl vector91
vector91:
  pushl $0
8010765c:	6a 00                	push   $0x0
  pushl $91
8010765e:	6a 5b                	push   $0x5b
  jmp alltraps
80107660:	e9 54 f6 ff ff       	jmp    80106cb9 <alltraps>

80107665 <vector92>:
.globl vector92
vector92:
  pushl $0
80107665:	6a 00                	push   $0x0
  pushl $92
80107667:	6a 5c                	push   $0x5c
  jmp alltraps
80107669:	e9 4b f6 ff ff       	jmp    80106cb9 <alltraps>

8010766e <vector93>:
.globl vector93
vector93:
  pushl $0
8010766e:	6a 00                	push   $0x0
  pushl $93
80107670:	6a 5d                	push   $0x5d
  jmp alltraps
80107672:	e9 42 f6 ff ff       	jmp    80106cb9 <alltraps>

80107677 <vector94>:
.globl vector94
vector94:
  pushl $0
80107677:	6a 00                	push   $0x0
  pushl $94
80107679:	6a 5e                	push   $0x5e
  jmp alltraps
8010767b:	e9 39 f6 ff ff       	jmp    80106cb9 <alltraps>

80107680 <vector95>:
.globl vector95
vector95:
  pushl $0
80107680:	6a 00                	push   $0x0
  pushl $95
80107682:	6a 5f                	push   $0x5f
  jmp alltraps
80107684:	e9 30 f6 ff ff       	jmp    80106cb9 <alltraps>

80107689 <vector96>:
.globl vector96
vector96:
  pushl $0
80107689:	6a 00                	push   $0x0
  pushl $96
8010768b:	6a 60                	push   $0x60
  jmp alltraps
8010768d:	e9 27 f6 ff ff       	jmp    80106cb9 <alltraps>

80107692 <vector97>:
.globl vector97
vector97:
  pushl $0
80107692:	6a 00                	push   $0x0
  pushl $97
80107694:	6a 61                	push   $0x61
  jmp alltraps
80107696:	e9 1e f6 ff ff       	jmp    80106cb9 <alltraps>

8010769b <vector98>:
.globl vector98
vector98:
  pushl $0
8010769b:	6a 00                	push   $0x0
  pushl $98
8010769d:	6a 62                	push   $0x62
  jmp alltraps
8010769f:	e9 15 f6 ff ff       	jmp    80106cb9 <alltraps>

801076a4 <vector99>:
.globl vector99
vector99:
  pushl $0
801076a4:	6a 00                	push   $0x0
  pushl $99
801076a6:	6a 63                	push   $0x63
  jmp alltraps
801076a8:	e9 0c f6 ff ff       	jmp    80106cb9 <alltraps>

801076ad <vector100>:
.globl vector100
vector100:
  pushl $0
801076ad:	6a 00                	push   $0x0
  pushl $100
801076af:	6a 64                	push   $0x64
  jmp alltraps
801076b1:	e9 03 f6 ff ff       	jmp    80106cb9 <alltraps>

801076b6 <vector101>:
.globl vector101
vector101:
  pushl $0
801076b6:	6a 00                	push   $0x0
  pushl $101
801076b8:	6a 65                	push   $0x65
  jmp alltraps
801076ba:	e9 fa f5 ff ff       	jmp    80106cb9 <alltraps>

801076bf <vector102>:
.globl vector102
vector102:
  pushl $0
801076bf:	6a 00                	push   $0x0
  pushl $102
801076c1:	6a 66                	push   $0x66
  jmp alltraps
801076c3:	e9 f1 f5 ff ff       	jmp    80106cb9 <alltraps>

801076c8 <vector103>:
.globl vector103
vector103:
  pushl $0
801076c8:	6a 00                	push   $0x0
  pushl $103
801076ca:	6a 67                	push   $0x67
  jmp alltraps
801076cc:	e9 e8 f5 ff ff       	jmp    80106cb9 <alltraps>

801076d1 <vector104>:
.globl vector104
vector104:
  pushl $0
801076d1:	6a 00                	push   $0x0
  pushl $104
801076d3:	6a 68                	push   $0x68
  jmp alltraps
801076d5:	e9 df f5 ff ff       	jmp    80106cb9 <alltraps>

801076da <vector105>:
.globl vector105
vector105:
  pushl $0
801076da:	6a 00                	push   $0x0
  pushl $105
801076dc:	6a 69                	push   $0x69
  jmp alltraps
801076de:	e9 d6 f5 ff ff       	jmp    80106cb9 <alltraps>

801076e3 <vector106>:
.globl vector106
vector106:
  pushl $0
801076e3:	6a 00                	push   $0x0
  pushl $106
801076e5:	6a 6a                	push   $0x6a
  jmp alltraps
801076e7:	e9 cd f5 ff ff       	jmp    80106cb9 <alltraps>

801076ec <vector107>:
.globl vector107
vector107:
  pushl $0
801076ec:	6a 00                	push   $0x0
  pushl $107
801076ee:	6a 6b                	push   $0x6b
  jmp alltraps
801076f0:	e9 c4 f5 ff ff       	jmp    80106cb9 <alltraps>

801076f5 <vector108>:
.globl vector108
vector108:
  pushl $0
801076f5:	6a 00                	push   $0x0
  pushl $108
801076f7:	6a 6c                	push   $0x6c
  jmp alltraps
801076f9:	e9 bb f5 ff ff       	jmp    80106cb9 <alltraps>

801076fe <vector109>:
.globl vector109
vector109:
  pushl $0
801076fe:	6a 00                	push   $0x0
  pushl $109
80107700:	6a 6d                	push   $0x6d
  jmp alltraps
80107702:	e9 b2 f5 ff ff       	jmp    80106cb9 <alltraps>

80107707 <vector110>:
.globl vector110
vector110:
  pushl $0
80107707:	6a 00                	push   $0x0
  pushl $110
80107709:	6a 6e                	push   $0x6e
  jmp alltraps
8010770b:	e9 a9 f5 ff ff       	jmp    80106cb9 <alltraps>

80107710 <vector111>:
.globl vector111
vector111:
  pushl $0
80107710:	6a 00                	push   $0x0
  pushl $111
80107712:	6a 6f                	push   $0x6f
  jmp alltraps
80107714:	e9 a0 f5 ff ff       	jmp    80106cb9 <alltraps>

80107719 <vector112>:
.globl vector112
vector112:
  pushl $0
80107719:	6a 00                	push   $0x0
  pushl $112
8010771b:	6a 70                	push   $0x70
  jmp alltraps
8010771d:	e9 97 f5 ff ff       	jmp    80106cb9 <alltraps>

80107722 <vector113>:
.globl vector113
vector113:
  pushl $0
80107722:	6a 00                	push   $0x0
  pushl $113
80107724:	6a 71                	push   $0x71
  jmp alltraps
80107726:	e9 8e f5 ff ff       	jmp    80106cb9 <alltraps>

8010772b <vector114>:
.globl vector114
vector114:
  pushl $0
8010772b:	6a 00                	push   $0x0
  pushl $114
8010772d:	6a 72                	push   $0x72
  jmp alltraps
8010772f:	e9 85 f5 ff ff       	jmp    80106cb9 <alltraps>

80107734 <vector115>:
.globl vector115
vector115:
  pushl $0
80107734:	6a 00                	push   $0x0
  pushl $115
80107736:	6a 73                	push   $0x73
  jmp alltraps
80107738:	e9 7c f5 ff ff       	jmp    80106cb9 <alltraps>

8010773d <vector116>:
.globl vector116
vector116:
  pushl $0
8010773d:	6a 00                	push   $0x0
  pushl $116
8010773f:	6a 74                	push   $0x74
  jmp alltraps
80107741:	e9 73 f5 ff ff       	jmp    80106cb9 <alltraps>

80107746 <vector117>:
.globl vector117
vector117:
  pushl $0
80107746:	6a 00                	push   $0x0
  pushl $117
80107748:	6a 75                	push   $0x75
  jmp alltraps
8010774a:	e9 6a f5 ff ff       	jmp    80106cb9 <alltraps>

8010774f <vector118>:
.globl vector118
vector118:
  pushl $0
8010774f:	6a 00                	push   $0x0
  pushl $118
80107751:	6a 76                	push   $0x76
  jmp alltraps
80107753:	e9 61 f5 ff ff       	jmp    80106cb9 <alltraps>

80107758 <vector119>:
.globl vector119
vector119:
  pushl $0
80107758:	6a 00                	push   $0x0
  pushl $119
8010775a:	6a 77                	push   $0x77
  jmp alltraps
8010775c:	e9 58 f5 ff ff       	jmp    80106cb9 <alltraps>

80107761 <vector120>:
.globl vector120
vector120:
  pushl $0
80107761:	6a 00                	push   $0x0
  pushl $120
80107763:	6a 78                	push   $0x78
  jmp alltraps
80107765:	e9 4f f5 ff ff       	jmp    80106cb9 <alltraps>

8010776a <vector121>:
.globl vector121
vector121:
  pushl $0
8010776a:	6a 00                	push   $0x0
  pushl $121
8010776c:	6a 79                	push   $0x79
  jmp alltraps
8010776e:	e9 46 f5 ff ff       	jmp    80106cb9 <alltraps>

80107773 <vector122>:
.globl vector122
vector122:
  pushl $0
80107773:	6a 00                	push   $0x0
  pushl $122
80107775:	6a 7a                	push   $0x7a
  jmp alltraps
80107777:	e9 3d f5 ff ff       	jmp    80106cb9 <alltraps>

8010777c <vector123>:
.globl vector123
vector123:
  pushl $0
8010777c:	6a 00                	push   $0x0
  pushl $123
8010777e:	6a 7b                	push   $0x7b
  jmp alltraps
80107780:	e9 34 f5 ff ff       	jmp    80106cb9 <alltraps>

80107785 <vector124>:
.globl vector124
vector124:
  pushl $0
80107785:	6a 00                	push   $0x0
  pushl $124
80107787:	6a 7c                	push   $0x7c
  jmp alltraps
80107789:	e9 2b f5 ff ff       	jmp    80106cb9 <alltraps>

8010778e <vector125>:
.globl vector125
vector125:
  pushl $0
8010778e:	6a 00                	push   $0x0
  pushl $125
80107790:	6a 7d                	push   $0x7d
  jmp alltraps
80107792:	e9 22 f5 ff ff       	jmp    80106cb9 <alltraps>

80107797 <vector126>:
.globl vector126
vector126:
  pushl $0
80107797:	6a 00                	push   $0x0
  pushl $126
80107799:	6a 7e                	push   $0x7e
  jmp alltraps
8010779b:	e9 19 f5 ff ff       	jmp    80106cb9 <alltraps>

801077a0 <vector127>:
.globl vector127
vector127:
  pushl $0
801077a0:	6a 00                	push   $0x0
  pushl $127
801077a2:	6a 7f                	push   $0x7f
  jmp alltraps
801077a4:	e9 10 f5 ff ff       	jmp    80106cb9 <alltraps>

801077a9 <vector128>:
.globl vector128
vector128:
  pushl $0
801077a9:	6a 00                	push   $0x0
  pushl $128
801077ab:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801077b0:	e9 04 f5 ff ff       	jmp    80106cb9 <alltraps>

801077b5 <vector129>:
.globl vector129
vector129:
  pushl $0
801077b5:	6a 00                	push   $0x0
  pushl $129
801077b7:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801077bc:	e9 f8 f4 ff ff       	jmp    80106cb9 <alltraps>

801077c1 <vector130>:
.globl vector130
vector130:
  pushl $0
801077c1:	6a 00                	push   $0x0
  pushl $130
801077c3:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801077c8:	e9 ec f4 ff ff       	jmp    80106cb9 <alltraps>

801077cd <vector131>:
.globl vector131
vector131:
  pushl $0
801077cd:	6a 00                	push   $0x0
  pushl $131
801077cf:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801077d4:	e9 e0 f4 ff ff       	jmp    80106cb9 <alltraps>

801077d9 <vector132>:
.globl vector132
vector132:
  pushl $0
801077d9:	6a 00                	push   $0x0
  pushl $132
801077db:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801077e0:	e9 d4 f4 ff ff       	jmp    80106cb9 <alltraps>

801077e5 <vector133>:
.globl vector133
vector133:
  pushl $0
801077e5:	6a 00                	push   $0x0
  pushl $133
801077e7:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801077ec:	e9 c8 f4 ff ff       	jmp    80106cb9 <alltraps>

801077f1 <vector134>:
.globl vector134
vector134:
  pushl $0
801077f1:	6a 00                	push   $0x0
  pushl $134
801077f3:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801077f8:	e9 bc f4 ff ff       	jmp    80106cb9 <alltraps>

801077fd <vector135>:
.globl vector135
vector135:
  pushl $0
801077fd:	6a 00                	push   $0x0
  pushl $135
801077ff:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107804:	e9 b0 f4 ff ff       	jmp    80106cb9 <alltraps>

80107809 <vector136>:
.globl vector136
vector136:
  pushl $0
80107809:	6a 00                	push   $0x0
  pushl $136
8010780b:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107810:	e9 a4 f4 ff ff       	jmp    80106cb9 <alltraps>

80107815 <vector137>:
.globl vector137
vector137:
  pushl $0
80107815:	6a 00                	push   $0x0
  pushl $137
80107817:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010781c:	e9 98 f4 ff ff       	jmp    80106cb9 <alltraps>

80107821 <vector138>:
.globl vector138
vector138:
  pushl $0
80107821:	6a 00                	push   $0x0
  pushl $138
80107823:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107828:	e9 8c f4 ff ff       	jmp    80106cb9 <alltraps>

8010782d <vector139>:
.globl vector139
vector139:
  pushl $0
8010782d:	6a 00                	push   $0x0
  pushl $139
8010782f:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107834:	e9 80 f4 ff ff       	jmp    80106cb9 <alltraps>

80107839 <vector140>:
.globl vector140
vector140:
  pushl $0
80107839:	6a 00                	push   $0x0
  pushl $140
8010783b:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107840:	e9 74 f4 ff ff       	jmp    80106cb9 <alltraps>

80107845 <vector141>:
.globl vector141
vector141:
  pushl $0
80107845:	6a 00                	push   $0x0
  pushl $141
80107847:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010784c:	e9 68 f4 ff ff       	jmp    80106cb9 <alltraps>

80107851 <vector142>:
.globl vector142
vector142:
  pushl $0
80107851:	6a 00                	push   $0x0
  pushl $142
80107853:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107858:	e9 5c f4 ff ff       	jmp    80106cb9 <alltraps>

8010785d <vector143>:
.globl vector143
vector143:
  pushl $0
8010785d:	6a 00                	push   $0x0
  pushl $143
8010785f:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107864:	e9 50 f4 ff ff       	jmp    80106cb9 <alltraps>

80107869 <vector144>:
.globl vector144
vector144:
  pushl $0
80107869:	6a 00                	push   $0x0
  pushl $144
8010786b:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107870:	e9 44 f4 ff ff       	jmp    80106cb9 <alltraps>

80107875 <vector145>:
.globl vector145
vector145:
  pushl $0
80107875:	6a 00                	push   $0x0
  pushl $145
80107877:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010787c:	e9 38 f4 ff ff       	jmp    80106cb9 <alltraps>

80107881 <vector146>:
.globl vector146
vector146:
  pushl $0
80107881:	6a 00                	push   $0x0
  pushl $146
80107883:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107888:	e9 2c f4 ff ff       	jmp    80106cb9 <alltraps>

8010788d <vector147>:
.globl vector147
vector147:
  pushl $0
8010788d:	6a 00                	push   $0x0
  pushl $147
8010788f:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107894:	e9 20 f4 ff ff       	jmp    80106cb9 <alltraps>

80107899 <vector148>:
.globl vector148
vector148:
  pushl $0
80107899:	6a 00                	push   $0x0
  pushl $148
8010789b:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801078a0:	e9 14 f4 ff ff       	jmp    80106cb9 <alltraps>

801078a5 <vector149>:
.globl vector149
vector149:
  pushl $0
801078a5:	6a 00                	push   $0x0
  pushl $149
801078a7:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801078ac:	e9 08 f4 ff ff       	jmp    80106cb9 <alltraps>

801078b1 <vector150>:
.globl vector150
vector150:
  pushl $0
801078b1:	6a 00                	push   $0x0
  pushl $150
801078b3:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801078b8:	e9 fc f3 ff ff       	jmp    80106cb9 <alltraps>

801078bd <vector151>:
.globl vector151
vector151:
  pushl $0
801078bd:	6a 00                	push   $0x0
  pushl $151
801078bf:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801078c4:	e9 f0 f3 ff ff       	jmp    80106cb9 <alltraps>

801078c9 <vector152>:
.globl vector152
vector152:
  pushl $0
801078c9:	6a 00                	push   $0x0
  pushl $152
801078cb:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801078d0:	e9 e4 f3 ff ff       	jmp    80106cb9 <alltraps>

801078d5 <vector153>:
.globl vector153
vector153:
  pushl $0
801078d5:	6a 00                	push   $0x0
  pushl $153
801078d7:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801078dc:	e9 d8 f3 ff ff       	jmp    80106cb9 <alltraps>

801078e1 <vector154>:
.globl vector154
vector154:
  pushl $0
801078e1:	6a 00                	push   $0x0
  pushl $154
801078e3:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801078e8:	e9 cc f3 ff ff       	jmp    80106cb9 <alltraps>

801078ed <vector155>:
.globl vector155
vector155:
  pushl $0
801078ed:	6a 00                	push   $0x0
  pushl $155
801078ef:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801078f4:	e9 c0 f3 ff ff       	jmp    80106cb9 <alltraps>

801078f9 <vector156>:
.globl vector156
vector156:
  pushl $0
801078f9:	6a 00                	push   $0x0
  pushl $156
801078fb:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107900:	e9 b4 f3 ff ff       	jmp    80106cb9 <alltraps>

80107905 <vector157>:
.globl vector157
vector157:
  pushl $0
80107905:	6a 00                	push   $0x0
  pushl $157
80107907:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010790c:	e9 a8 f3 ff ff       	jmp    80106cb9 <alltraps>

80107911 <vector158>:
.globl vector158
vector158:
  pushl $0
80107911:	6a 00                	push   $0x0
  pushl $158
80107913:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107918:	e9 9c f3 ff ff       	jmp    80106cb9 <alltraps>

8010791d <vector159>:
.globl vector159
vector159:
  pushl $0
8010791d:	6a 00                	push   $0x0
  pushl $159
8010791f:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107924:	e9 90 f3 ff ff       	jmp    80106cb9 <alltraps>

80107929 <vector160>:
.globl vector160
vector160:
  pushl $0
80107929:	6a 00                	push   $0x0
  pushl $160
8010792b:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107930:	e9 84 f3 ff ff       	jmp    80106cb9 <alltraps>

80107935 <vector161>:
.globl vector161
vector161:
  pushl $0
80107935:	6a 00                	push   $0x0
  pushl $161
80107937:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010793c:	e9 78 f3 ff ff       	jmp    80106cb9 <alltraps>

80107941 <vector162>:
.globl vector162
vector162:
  pushl $0
80107941:	6a 00                	push   $0x0
  pushl $162
80107943:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107948:	e9 6c f3 ff ff       	jmp    80106cb9 <alltraps>

8010794d <vector163>:
.globl vector163
vector163:
  pushl $0
8010794d:	6a 00                	push   $0x0
  pushl $163
8010794f:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107954:	e9 60 f3 ff ff       	jmp    80106cb9 <alltraps>

80107959 <vector164>:
.globl vector164
vector164:
  pushl $0
80107959:	6a 00                	push   $0x0
  pushl $164
8010795b:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107960:	e9 54 f3 ff ff       	jmp    80106cb9 <alltraps>

80107965 <vector165>:
.globl vector165
vector165:
  pushl $0
80107965:	6a 00                	push   $0x0
  pushl $165
80107967:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010796c:	e9 48 f3 ff ff       	jmp    80106cb9 <alltraps>

80107971 <vector166>:
.globl vector166
vector166:
  pushl $0
80107971:	6a 00                	push   $0x0
  pushl $166
80107973:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107978:	e9 3c f3 ff ff       	jmp    80106cb9 <alltraps>

8010797d <vector167>:
.globl vector167
vector167:
  pushl $0
8010797d:	6a 00                	push   $0x0
  pushl $167
8010797f:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107984:	e9 30 f3 ff ff       	jmp    80106cb9 <alltraps>

80107989 <vector168>:
.globl vector168
vector168:
  pushl $0
80107989:	6a 00                	push   $0x0
  pushl $168
8010798b:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107990:	e9 24 f3 ff ff       	jmp    80106cb9 <alltraps>

80107995 <vector169>:
.globl vector169
vector169:
  pushl $0
80107995:	6a 00                	push   $0x0
  pushl $169
80107997:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010799c:	e9 18 f3 ff ff       	jmp    80106cb9 <alltraps>

801079a1 <vector170>:
.globl vector170
vector170:
  pushl $0
801079a1:	6a 00                	push   $0x0
  pushl $170
801079a3:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801079a8:	e9 0c f3 ff ff       	jmp    80106cb9 <alltraps>

801079ad <vector171>:
.globl vector171
vector171:
  pushl $0
801079ad:	6a 00                	push   $0x0
  pushl $171
801079af:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801079b4:	e9 00 f3 ff ff       	jmp    80106cb9 <alltraps>

801079b9 <vector172>:
.globl vector172
vector172:
  pushl $0
801079b9:	6a 00                	push   $0x0
  pushl $172
801079bb:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801079c0:	e9 f4 f2 ff ff       	jmp    80106cb9 <alltraps>

801079c5 <vector173>:
.globl vector173
vector173:
  pushl $0
801079c5:	6a 00                	push   $0x0
  pushl $173
801079c7:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801079cc:	e9 e8 f2 ff ff       	jmp    80106cb9 <alltraps>

801079d1 <vector174>:
.globl vector174
vector174:
  pushl $0
801079d1:	6a 00                	push   $0x0
  pushl $174
801079d3:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801079d8:	e9 dc f2 ff ff       	jmp    80106cb9 <alltraps>

801079dd <vector175>:
.globl vector175
vector175:
  pushl $0
801079dd:	6a 00                	push   $0x0
  pushl $175
801079df:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801079e4:	e9 d0 f2 ff ff       	jmp    80106cb9 <alltraps>

801079e9 <vector176>:
.globl vector176
vector176:
  pushl $0
801079e9:	6a 00                	push   $0x0
  pushl $176
801079eb:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801079f0:	e9 c4 f2 ff ff       	jmp    80106cb9 <alltraps>

801079f5 <vector177>:
.globl vector177
vector177:
  pushl $0
801079f5:	6a 00                	push   $0x0
  pushl $177
801079f7:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801079fc:	e9 b8 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a01 <vector178>:
.globl vector178
vector178:
  pushl $0
80107a01:	6a 00                	push   $0x0
  pushl $178
80107a03:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107a08:	e9 ac f2 ff ff       	jmp    80106cb9 <alltraps>

80107a0d <vector179>:
.globl vector179
vector179:
  pushl $0
80107a0d:	6a 00                	push   $0x0
  pushl $179
80107a0f:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107a14:	e9 a0 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a19 <vector180>:
.globl vector180
vector180:
  pushl $0
80107a19:	6a 00                	push   $0x0
  pushl $180
80107a1b:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107a20:	e9 94 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a25 <vector181>:
.globl vector181
vector181:
  pushl $0
80107a25:	6a 00                	push   $0x0
  pushl $181
80107a27:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107a2c:	e9 88 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a31 <vector182>:
.globl vector182
vector182:
  pushl $0
80107a31:	6a 00                	push   $0x0
  pushl $182
80107a33:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107a38:	e9 7c f2 ff ff       	jmp    80106cb9 <alltraps>

80107a3d <vector183>:
.globl vector183
vector183:
  pushl $0
80107a3d:	6a 00                	push   $0x0
  pushl $183
80107a3f:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107a44:	e9 70 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a49 <vector184>:
.globl vector184
vector184:
  pushl $0
80107a49:	6a 00                	push   $0x0
  pushl $184
80107a4b:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107a50:	e9 64 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a55 <vector185>:
.globl vector185
vector185:
  pushl $0
80107a55:	6a 00                	push   $0x0
  pushl $185
80107a57:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107a5c:	e9 58 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a61 <vector186>:
.globl vector186
vector186:
  pushl $0
80107a61:	6a 00                	push   $0x0
  pushl $186
80107a63:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107a68:	e9 4c f2 ff ff       	jmp    80106cb9 <alltraps>

80107a6d <vector187>:
.globl vector187
vector187:
  pushl $0
80107a6d:	6a 00                	push   $0x0
  pushl $187
80107a6f:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107a74:	e9 40 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a79 <vector188>:
.globl vector188
vector188:
  pushl $0
80107a79:	6a 00                	push   $0x0
  pushl $188
80107a7b:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107a80:	e9 34 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a85 <vector189>:
.globl vector189
vector189:
  pushl $0
80107a85:	6a 00                	push   $0x0
  pushl $189
80107a87:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107a8c:	e9 28 f2 ff ff       	jmp    80106cb9 <alltraps>

80107a91 <vector190>:
.globl vector190
vector190:
  pushl $0
80107a91:	6a 00                	push   $0x0
  pushl $190
80107a93:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107a98:	e9 1c f2 ff ff       	jmp    80106cb9 <alltraps>

80107a9d <vector191>:
.globl vector191
vector191:
  pushl $0
80107a9d:	6a 00                	push   $0x0
  pushl $191
80107a9f:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107aa4:	e9 10 f2 ff ff       	jmp    80106cb9 <alltraps>

80107aa9 <vector192>:
.globl vector192
vector192:
  pushl $0
80107aa9:	6a 00                	push   $0x0
  pushl $192
80107aab:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107ab0:	e9 04 f2 ff ff       	jmp    80106cb9 <alltraps>

80107ab5 <vector193>:
.globl vector193
vector193:
  pushl $0
80107ab5:	6a 00                	push   $0x0
  pushl $193
80107ab7:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107abc:	e9 f8 f1 ff ff       	jmp    80106cb9 <alltraps>

80107ac1 <vector194>:
.globl vector194
vector194:
  pushl $0
80107ac1:	6a 00                	push   $0x0
  pushl $194
80107ac3:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107ac8:	e9 ec f1 ff ff       	jmp    80106cb9 <alltraps>

80107acd <vector195>:
.globl vector195
vector195:
  pushl $0
80107acd:	6a 00                	push   $0x0
  pushl $195
80107acf:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107ad4:	e9 e0 f1 ff ff       	jmp    80106cb9 <alltraps>

80107ad9 <vector196>:
.globl vector196
vector196:
  pushl $0
80107ad9:	6a 00                	push   $0x0
  pushl $196
80107adb:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107ae0:	e9 d4 f1 ff ff       	jmp    80106cb9 <alltraps>

80107ae5 <vector197>:
.globl vector197
vector197:
  pushl $0
80107ae5:	6a 00                	push   $0x0
  pushl $197
80107ae7:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107aec:	e9 c8 f1 ff ff       	jmp    80106cb9 <alltraps>

80107af1 <vector198>:
.globl vector198
vector198:
  pushl $0
80107af1:	6a 00                	push   $0x0
  pushl $198
80107af3:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107af8:	e9 bc f1 ff ff       	jmp    80106cb9 <alltraps>

80107afd <vector199>:
.globl vector199
vector199:
  pushl $0
80107afd:	6a 00                	push   $0x0
  pushl $199
80107aff:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107b04:	e9 b0 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b09 <vector200>:
.globl vector200
vector200:
  pushl $0
80107b09:	6a 00                	push   $0x0
  pushl $200
80107b0b:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107b10:	e9 a4 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b15 <vector201>:
.globl vector201
vector201:
  pushl $0
80107b15:	6a 00                	push   $0x0
  pushl $201
80107b17:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107b1c:	e9 98 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b21 <vector202>:
.globl vector202
vector202:
  pushl $0
80107b21:	6a 00                	push   $0x0
  pushl $202
80107b23:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107b28:	e9 8c f1 ff ff       	jmp    80106cb9 <alltraps>

80107b2d <vector203>:
.globl vector203
vector203:
  pushl $0
80107b2d:	6a 00                	push   $0x0
  pushl $203
80107b2f:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107b34:	e9 80 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b39 <vector204>:
.globl vector204
vector204:
  pushl $0
80107b39:	6a 00                	push   $0x0
  pushl $204
80107b3b:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107b40:	e9 74 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b45 <vector205>:
.globl vector205
vector205:
  pushl $0
80107b45:	6a 00                	push   $0x0
  pushl $205
80107b47:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107b4c:	e9 68 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b51 <vector206>:
.globl vector206
vector206:
  pushl $0
80107b51:	6a 00                	push   $0x0
  pushl $206
80107b53:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107b58:	e9 5c f1 ff ff       	jmp    80106cb9 <alltraps>

80107b5d <vector207>:
.globl vector207
vector207:
  pushl $0
80107b5d:	6a 00                	push   $0x0
  pushl $207
80107b5f:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107b64:	e9 50 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b69 <vector208>:
.globl vector208
vector208:
  pushl $0
80107b69:	6a 00                	push   $0x0
  pushl $208
80107b6b:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107b70:	e9 44 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b75 <vector209>:
.globl vector209
vector209:
  pushl $0
80107b75:	6a 00                	push   $0x0
  pushl $209
80107b77:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107b7c:	e9 38 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b81 <vector210>:
.globl vector210
vector210:
  pushl $0
80107b81:	6a 00                	push   $0x0
  pushl $210
80107b83:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107b88:	e9 2c f1 ff ff       	jmp    80106cb9 <alltraps>

80107b8d <vector211>:
.globl vector211
vector211:
  pushl $0
80107b8d:	6a 00                	push   $0x0
  pushl $211
80107b8f:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107b94:	e9 20 f1 ff ff       	jmp    80106cb9 <alltraps>

80107b99 <vector212>:
.globl vector212
vector212:
  pushl $0
80107b99:	6a 00                	push   $0x0
  pushl $212
80107b9b:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107ba0:	e9 14 f1 ff ff       	jmp    80106cb9 <alltraps>

80107ba5 <vector213>:
.globl vector213
vector213:
  pushl $0
80107ba5:	6a 00                	push   $0x0
  pushl $213
80107ba7:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107bac:	e9 08 f1 ff ff       	jmp    80106cb9 <alltraps>

80107bb1 <vector214>:
.globl vector214
vector214:
  pushl $0
80107bb1:	6a 00                	push   $0x0
  pushl $214
80107bb3:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107bb8:	e9 fc f0 ff ff       	jmp    80106cb9 <alltraps>

80107bbd <vector215>:
.globl vector215
vector215:
  pushl $0
80107bbd:	6a 00                	push   $0x0
  pushl $215
80107bbf:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107bc4:	e9 f0 f0 ff ff       	jmp    80106cb9 <alltraps>

80107bc9 <vector216>:
.globl vector216
vector216:
  pushl $0
80107bc9:	6a 00                	push   $0x0
  pushl $216
80107bcb:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107bd0:	e9 e4 f0 ff ff       	jmp    80106cb9 <alltraps>

80107bd5 <vector217>:
.globl vector217
vector217:
  pushl $0
80107bd5:	6a 00                	push   $0x0
  pushl $217
80107bd7:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107bdc:	e9 d8 f0 ff ff       	jmp    80106cb9 <alltraps>

80107be1 <vector218>:
.globl vector218
vector218:
  pushl $0
80107be1:	6a 00                	push   $0x0
  pushl $218
80107be3:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107be8:	e9 cc f0 ff ff       	jmp    80106cb9 <alltraps>

80107bed <vector219>:
.globl vector219
vector219:
  pushl $0
80107bed:	6a 00                	push   $0x0
  pushl $219
80107bef:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107bf4:	e9 c0 f0 ff ff       	jmp    80106cb9 <alltraps>

80107bf9 <vector220>:
.globl vector220
vector220:
  pushl $0
80107bf9:	6a 00                	push   $0x0
  pushl $220
80107bfb:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107c00:	e9 b4 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c05 <vector221>:
.globl vector221
vector221:
  pushl $0
80107c05:	6a 00                	push   $0x0
  pushl $221
80107c07:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107c0c:	e9 a8 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c11 <vector222>:
.globl vector222
vector222:
  pushl $0
80107c11:	6a 00                	push   $0x0
  pushl $222
80107c13:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107c18:	e9 9c f0 ff ff       	jmp    80106cb9 <alltraps>

80107c1d <vector223>:
.globl vector223
vector223:
  pushl $0
80107c1d:	6a 00                	push   $0x0
  pushl $223
80107c1f:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107c24:	e9 90 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c29 <vector224>:
.globl vector224
vector224:
  pushl $0
80107c29:	6a 00                	push   $0x0
  pushl $224
80107c2b:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107c30:	e9 84 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c35 <vector225>:
.globl vector225
vector225:
  pushl $0
80107c35:	6a 00                	push   $0x0
  pushl $225
80107c37:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107c3c:	e9 78 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c41 <vector226>:
.globl vector226
vector226:
  pushl $0
80107c41:	6a 00                	push   $0x0
  pushl $226
80107c43:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107c48:	e9 6c f0 ff ff       	jmp    80106cb9 <alltraps>

80107c4d <vector227>:
.globl vector227
vector227:
  pushl $0
80107c4d:	6a 00                	push   $0x0
  pushl $227
80107c4f:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107c54:	e9 60 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c59 <vector228>:
.globl vector228
vector228:
  pushl $0
80107c59:	6a 00                	push   $0x0
  pushl $228
80107c5b:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107c60:	e9 54 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c65 <vector229>:
.globl vector229
vector229:
  pushl $0
80107c65:	6a 00                	push   $0x0
  pushl $229
80107c67:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107c6c:	e9 48 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c71 <vector230>:
.globl vector230
vector230:
  pushl $0
80107c71:	6a 00                	push   $0x0
  pushl $230
80107c73:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107c78:	e9 3c f0 ff ff       	jmp    80106cb9 <alltraps>

80107c7d <vector231>:
.globl vector231
vector231:
  pushl $0
80107c7d:	6a 00                	push   $0x0
  pushl $231
80107c7f:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107c84:	e9 30 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c89 <vector232>:
.globl vector232
vector232:
  pushl $0
80107c89:	6a 00                	push   $0x0
  pushl $232
80107c8b:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107c90:	e9 24 f0 ff ff       	jmp    80106cb9 <alltraps>

80107c95 <vector233>:
.globl vector233
vector233:
  pushl $0
80107c95:	6a 00                	push   $0x0
  pushl $233
80107c97:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107c9c:	e9 18 f0 ff ff       	jmp    80106cb9 <alltraps>

80107ca1 <vector234>:
.globl vector234
vector234:
  pushl $0
80107ca1:	6a 00                	push   $0x0
  pushl $234
80107ca3:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107ca8:	e9 0c f0 ff ff       	jmp    80106cb9 <alltraps>

80107cad <vector235>:
.globl vector235
vector235:
  pushl $0
80107cad:	6a 00                	push   $0x0
  pushl $235
80107caf:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107cb4:	e9 00 f0 ff ff       	jmp    80106cb9 <alltraps>

80107cb9 <vector236>:
.globl vector236
vector236:
  pushl $0
80107cb9:	6a 00                	push   $0x0
  pushl $236
80107cbb:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107cc0:	e9 f4 ef ff ff       	jmp    80106cb9 <alltraps>

80107cc5 <vector237>:
.globl vector237
vector237:
  pushl $0
80107cc5:	6a 00                	push   $0x0
  pushl $237
80107cc7:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107ccc:	e9 e8 ef ff ff       	jmp    80106cb9 <alltraps>

80107cd1 <vector238>:
.globl vector238
vector238:
  pushl $0
80107cd1:	6a 00                	push   $0x0
  pushl $238
80107cd3:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107cd8:	e9 dc ef ff ff       	jmp    80106cb9 <alltraps>

80107cdd <vector239>:
.globl vector239
vector239:
  pushl $0
80107cdd:	6a 00                	push   $0x0
  pushl $239
80107cdf:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107ce4:	e9 d0 ef ff ff       	jmp    80106cb9 <alltraps>

80107ce9 <vector240>:
.globl vector240
vector240:
  pushl $0
80107ce9:	6a 00                	push   $0x0
  pushl $240
80107ceb:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107cf0:	e9 c4 ef ff ff       	jmp    80106cb9 <alltraps>

80107cf5 <vector241>:
.globl vector241
vector241:
  pushl $0
80107cf5:	6a 00                	push   $0x0
  pushl $241
80107cf7:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107cfc:	e9 b8 ef ff ff       	jmp    80106cb9 <alltraps>

80107d01 <vector242>:
.globl vector242
vector242:
  pushl $0
80107d01:	6a 00                	push   $0x0
  pushl $242
80107d03:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107d08:	e9 ac ef ff ff       	jmp    80106cb9 <alltraps>

80107d0d <vector243>:
.globl vector243
vector243:
  pushl $0
80107d0d:	6a 00                	push   $0x0
  pushl $243
80107d0f:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107d14:	e9 a0 ef ff ff       	jmp    80106cb9 <alltraps>

80107d19 <vector244>:
.globl vector244
vector244:
  pushl $0
80107d19:	6a 00                	push   $0x0
  pushl $244
80107d1b:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107d20:	e9 94 ef ff ff       	jmp    80106cb9 <alltraps>

80107d25 <vector245>:
.globl vector245
vector245:
  pushl $0
80107d25:	6a 00                	push   $0x0
  pushl $245
80107d27:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107d2c:	e9 88 ef ff ff       	jmp    80106cb9 <alltraps>

80107d31 <vector246>:
.globl vector246
vector246:
  pushl $0
80107d31:	6a 00                	push   $0x0
  pushl $246
80107d33:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107d38:	e9 7c ef ff ff       	jmp    80106cb9 <alltraps>

80107d3d <vector247>:
.globl vector247
vector247:
  pushl $0
80107d3d:	6a 00                	push   $0x0
  pushl $247
80107d3f:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107d44:	e9 70 ef ff ff       	jmp    80106cb9 <alltraps>

80107d49 <vector248>:
.globl vector248
vector248:
  pushl $0
80107d49:	6a 00                	push   $0x0
  pushl $248
80107d4b:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107d50:	e9 64 ef ff ff       	jmp    80106cb9 <alltraps>

80107d55 <vector249>:
.globl vector249
vector249:
  pushl $0
80107d55:	6a 00                	push   $0x0
  pushl $249
80107d57:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107d5c:	e9 58 ef ff ff       	jmp    80106cb9 <alltraps>

80107d61 <vector250>:
.globl vector250
vector250:
  pushl $0
80107d61:	6a 00                	push   $0x0
  pushl $250
80107d63:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107d68:	e9 4c ef ff ff       	jmp    80106cb9 <alltraps>

80107d6d <vector251>:
.globl vector251
vector251:
  pushl $0
80107d6d:	6a 00                	push   $0x0
  pushl $251
80107d6f:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107d74:	e9 40 ef ff ff       	jmp    80106cb9 <alltraps>

80107d79 <vector252>:
.globl vector252
vector252:
  pushl $0
80107d79:	6a 00                	push   $0x0
  pushl $252
80107d7b:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107d80:	e9 34 ef ff ff       	jmp    80106cb9 <alltraps>

80107d85 <vector253>:
.globl vector253
vector253:
  pushl $0
80107d85:	6a 00                	push   $0x0
  pushl $253
80107d87:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107d8c:	e9 28 ef ff ff       	jmp    80106cb9 <alltraps>

80107d91 <vector254>:
.globl vector254
vector254:
  pushl $0
80107d91:	6a 00                	push   $0x0
  pushl $254
80107d93:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107d98:	e9 1c ef ff ff       	jmp    80106cb9 <alltraps>

80107d9d <vector255>:
.globl vector255
vector255:
  pushl $0
80107d9d:	6a 00                	push   $0x0
  pushl $255
80107d9f:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107da4:	e9 10 ef ff ff       	jmp    80106cb9 <alltraps>

80107da9 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107da9:	55                   	push   %ebp
80107daa:	89 e5                	mov    %esp,%ebp
80107dac:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107daf:	8b 45 0c             	mov    0xc(%ebp),%eax
80107db2:	83 e8 01             	sub    $0x1,%eax
80107db5:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107db9:	8b 45 08             	mov    0x8(%ebp),%eax
80107dbc:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107dc0:	8b 45 08             	mov    0x8(%ebp),%eax
80107dc3:	c1 e8 10             	shr    $0x10,%eax
80107dc6:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107dca:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107dcd:	0f 01 10             	lgdtl  (%eax)
}
80107dd0:	c9                   	leave  
80107dd1:	c3                   	ret    

80107dd2 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107dd2:	55                   	push   %ebp
80107dd3:	89 e5                	mov    %esp,%ebp
80107dd5:	83 ec 04             	sub    $0x4,%esp
80107dd8:	8b 45 08             	mov    0x8(%ebp),%eax
80107ddb:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107ddf:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107de3:	0f 00 d8             	ltr    %ax
}
80107de6:	c9                   	leave  
80107de7:	c3                   	ret    

80107de8 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107de8:	55                   	push   %ebp
80107de9:	89 e5                	mov    %esp,%ebp
80107deb:	83 ec 04             	sub    $0x4,%esp
80107dee:	8b 45 08             	mov    0x8(%ebp),%eax
80107df1:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107df5:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107df9:	8e e8                	mov    %eax,%gs
}
80107dfb:	c9                   	leave  
80107dfc:	c3                   	ret    

80107dfd <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107dfd:	55                   	push   %ebp
80107dfe:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107e00:	8b 45 08             	mov    0x8(%ebp),%eax
80107e03:	0f 22 d8             	mov    %eax,%cr3
}
80107e06:	5d                   	pop    %ebp
80107e07:	c3                   	ret    

80107e08 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107e08:	55                   	push   %ebp
80107e09:	89 e5                	mov    %esp,%ebp
80107e0b:	8b 45 08             	mov    0x8(%ebp),%eax
80107e0e:	05 00 00 00 80       	add    $0x80000000,%eax
80107e13:	5d                   	pop    %ebp
80107e14:	c3                   	ret    

80107e15 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107e15:	55                   	push   %ebp
80107e16:	89 e5                	mov    %esp,%ebp
80107e18:	8b 45 08             	mov    0x8(%ebp),%eax
80107e1b:	05 00 00 00 80       	add    $0x80000000,%eax
80107e20:	5d                   	pop    %ebp
80107e21:	c3                   	ret    

80107e22 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107e22:	55                   	push   %ebp
80107e23:	89 e5                	mov    %esp,%ebp
80107e25:	53                   	push   %ebx
80107e26:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107e29:	e8 e3 b6 ff ff       	call   80103511 <cpunum>
80107e2e:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107e34:	05 c0 3b 11 80       	add    $0x80113bc0,%eax
80107e39:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107e3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e3f:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e48:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107e4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e51:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107e55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e58:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107e5c:	83 e2 f0             	and    $0xfffffff0,%edx
80107e5f:	83 ca 0a             	or     $0xa,%edx
80107e62:	88 50 7d             	mov    %dl,0x7d(%eax)
80107e65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e68:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107e6c:	83 ca 10             	or     $0x10,%edx
80107e6f:	88 50 7d             	mov    %dl,0x7d(%eax)
80107e72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e75:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107e79:	83 e2 9f             	and    $0xffffff9f,%edx
80107e7c:	88 50 7d             	mov    %dl,0x7d(%eax)
80107e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e82:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107e86:	83 ca 80             	or     $0xffffff80,%edx
80107e89:	88 50 7d             	mov    %dl,0x7d(%eax)
80107e8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e8f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107e93:	83 ca 0f             	or     $0xf,%edx
80107e96:	88 50 7e             	mov    %dl,0x7e(%eax)
80107e99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e9c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ea0:	83 e2 ef             	and    $0xffffffef,%edx
80107ea3:	88 50 7e             	mov    %dl,0x7e(%eax)
80107ea6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ea9:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ead:	83 e2 df             	and    $0xffffffdf,%edx
80107eb0:	88 50 7e             	mov    %dl,0x7e(%eax)
80107eb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107eb6:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107eba:	83 ca 40             	or     $0x40,%edx
80107ebd:	88 50 7e             	mov    %dl,0x7e(%eax)
80107ec0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ec3:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ec7:	83 ca 80             	or     $0xffffff80,%edx
80107eca:	88 50 7e             	mov    %dl,0x7e(%eax)
80107ecd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ed0:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ed7:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107ede:	ff ff 
80107ee0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ee3:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107eea:	00 00 
80107eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107eef:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ef9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107f00:	83 e2 f0             	and    $0xfffffff0,%edx
80107f03:	83 ca 02             	or     $0x2,%edx
80107f06:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107f0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f0f:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107f16:	83 ca 10             	or     $0x10,%edx
80107f19:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107f1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f22:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107f29:	83 e2 9f             	and    $0xffffff9f,%edx
80107f2c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107f32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f35:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107f3c:	83 ca 80             	or     $0xffffff80,%edx
80107f3f:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107f45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f48:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107f4f:	83 ca 0f             	or     $0xf,%edx
80107f52:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107f58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f5b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107f62:	83 e2 ef             	and    $0xffffffef,%edx
80107f65:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107f6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f6e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107f75:	83 e2 df             	and    $0xffffffdf,%edx
80107f78:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107f7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f81:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107f88:	83 ca 40             	or     $0x40,%edx
80107f8b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107f91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f94:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107f9b:	83 ca 80             	or     $0xffffff80,%edx
80107f9e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107fa4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fa7:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107fae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fb1:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107fb8:	ff ff 
80107fba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fbd:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107fc4:	00 00 
80107fc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fc9:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107fd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fd3:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107fda:	83 e2 f0             	and    $0xfffffff0,%edx
80107fdd:	83 ca 0a             	or     $0xa,%edx
80107fe0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107fe6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fe9:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107ff0:	83 ca 10             	or     $0x10,%edx
80107ff3:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107ff9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ffc:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108003:	83 ca 60             	or     $0x60,%edx
80108006:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010800c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010800f:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108016:	83 ca 80             	or     $0xffffff80,%edx
80108019:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010801f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108022:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108029:	83 ca 0f             	or     $0xf,%edx
8010802c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108032:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108035:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010803c:	83 e2 ef             	and    $0xffffffef,%edx
8010803f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108045:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108048:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010804f:	83 e2 df             	and    $0xffffffdf,%edx
80108052:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108058:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010805b:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108062:	83 ca 40             	or     $0x40,%edx
80108065:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010806b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108075:	83 ca 80             	or     $0xffffff80,%edx
80108078:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010807e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108081:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108088:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010808b:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108092:	ff ff 
80108094:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108097:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
8010809e:	00 00 
801080a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080a3:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801080aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ad:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801080b4:	83 e2 f0             	and    $0xfffffff0,%edx
801080b7:	83 ca 02             	or     $0x2,%edx
801080ba:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801080c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c3:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801080ca:	83 ca 10             	or     $0x10,%edx
801080cd:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801080d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080d6:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801080dd:	83 ca 60             	or     $0x60,%edx
801080e0:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801080e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801080f0:	83 ca 80             	or     $0xffffff80,%edx
801080f3:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801080f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080fc:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108103:	83 ca 0f             	or     $0xf,%edx
80108106:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010810c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010810f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108116:	83 e2 ef             	and    $0xffffffef,%edx
80108119:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010811f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108122:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108129:	83 e2 df             	and    $0xffffffdf,%edx
8010812c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108132:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108135:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010813c:	83 ca 40             	or     $0x40,%edx
8010813f:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108145:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108148:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010814f:	83 ca 80             	or     $0xffffff80,%edx
80108152:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108158:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010815b:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108162:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108165:	05 b4 00 00 00       	add    $0xb4,%eax
8010816a:	89 c3                	mov    %eax,%ebx
8010816c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010816f:	05 b4 00 00 00       	add    $0xb4,%eax
80108174:	c1 e8 10             	shr    $0x10,%eax
80108177:	89 c1                	mov    %eax,%ecx
80108179:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817c:	05 b4 00 00 00       	add    $0xb4,%eax
80108181:	c1 e8 18             	shr    $0x18,%eax
80108184:	89 c2                	mov    %eax,%edx
80108186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108189:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108190:	00 00 
80108192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108195:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010819c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819f:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
801081a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a8:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801081af:	83 e1 f0             	and    $0xfffffff0,%ecx
801081b2:	83 c9 02             	or     $0x2,%ecx
801081b5:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801081bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081be:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801081c5:	83 c9 10             	or     $0x10,%ecx
801081c8:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801081ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d1:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801081d8:	83 e1 9f             	and    $0xffffff9f,%ecx
801081db:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801081e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e4:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801081eb:	83 c9 80             	or     $0xffffff80,%ecx
801081ee:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801081f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801081fe:	83 e1 f0             	and    $0xfffffff0,%ecx
80108201:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108207:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010820a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108211:	83 e1 ef             	and    $0xffffffef,%ecx
80108214:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010821a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010821d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108224:	83 e1 df             	and    $0xffffffdf,%ecx
80108227:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010822d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108230:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108237:	83 c9 40             	or     $0x40,%ecx
8010823a:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108240:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108243:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010824a:	83 c9 80             	or     $0xffffff80,%ecx
8010824d:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108253:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108256:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010825c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010825f:	83 c0 70             	add    $0x70,%eax
80108262:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108269:	00 
8010826a:	89 04 24             	mov    %eax,(%esp)
8010826d:	e8 37 fb ff ff       	call   80107da9 <lgdt>
  loadgs(SEG_KCPU << 3);
80108272:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108279:	e8 6a fb ff ff       	call   80107de8 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
8010827e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108281:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108287:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010828e:	00 00 00 00 
}
80108292:	83 c4 24             	add    $0x24,%esp
80108295:	5b                   	pop    %ebx
80108296:	5d                   	pop    %ebp
80108297:	c3                   	ret    

80108298 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108298:	55                   	push   %ebp
80108299:	89 e5                	mov    %esp,%ebp
8010829b:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
8010829e:	8b 45 0c             	mov    0xc(%ebp),%eax
801082a1:	c1 e8 16             	shr    $0x16,%eax
801082a4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801082ab:	8b 45 08             	mov    0x8(%ebp),%eax
801082ae:	01 d0                	add    %edx,%eax
801082b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801082b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082b6:	8b 00                	mov    (%eax),%eax
801082b8:	83 e0 01             	and    $0x1,%eax
801082bb:	85 c0                	test   %eax,%eax
801082bd:	74 17                	je     801082d6 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801082bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082c2:	8b 00                	mov    (%eax),%eax
801082c4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801082c9:	89 04 24             	mov    %eax,(%esp)
801082cc:	e8 44 fb ff ff       	call   80107e15 <p2v>
801082d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801082d4:	eb 4b                	jmp    80108321 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801082d6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801082da:	74 0e                	je     801082ea <walkpgdir+0x52>
801082dc:	e8 9a ae ff ff       	call   8010317b <kalloc>
801082e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801082e4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801082e8:	75 07                	jne    801082f1 <walkpgdir+0x59>
      return 0;
801082ea:	b8 00 00 00 00       	mov    $0x0,%eax
801082ef:	eb 47                	jmp    80108338 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801082f1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801082f8:	00 
801082f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108300:	00 
80108301:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108304:	89 04 24             	mov    %eax,(%esp)
80108307:	e8 ac d5 ff ff       	call   801058b8 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
8010830c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830f:	89 04 24             	mov    %eax,(%esp)
80108312:	e8 f1 fa ff ff       	call   80107e08 <v2p>
80108317:	83 c8 07             	or     $0x7,%eax
8010831a:	89 c2                	mov    %eax,%edx
8010831c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010831f:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108321:	8b 45 0c             	mov    0xc(%ebp),%eax
80108324:	c1 e8 0c             	shr    $0xc,%eax
80108327:	25 ff 03 00 00       	and    $0x3ff,%eax
8010832c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108333:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108336:	01 d0                	add    %edx,%eax
}
80108338:	c9                   	leave  
80108339:	c3                   	ret    

8010833a <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010833a:	55                   	push   %ebp
8010833b:	89 e5                	mov    %esp,%ebp
8010833d:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108340:	8b 45 0c             	mov    0xc(%ebp),%eax
80108343:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108348:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010834b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010834e:	8b 45 10             	mov    0x10(%ebp),%eax
80108351:	01 d0                	add    %edx,%eax
80108353:	83 e8 01             	sub    $0x1,%eax
80108356:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010835b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010835e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108365:	00 
80108366:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108369:	89 44 24 04          	mov    %eax,0x4(%esp)
8010836d:	8b 45 08             	mov    0x8(%ebp),%eax
80108370:	89 04 24             	mov    %eax,(%esp)
80108373:	e8 20 ff ff ff       	call   80108298 <walkpgdir>
80108378:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010837b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010837f:	75 07                	jne    80108388 <mappages+0x4e>
      return -1;
80108381:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108386:	eb 48                	jmp    801083d0 <mappages+0x96>
    if(*pte & PTE_P)
80108388:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010838b:	8b 00                	mov    (%eax),%eax
8010838d:	83 e0 01             	and    $0x1,%eax
80108390:	85 c0                	test   %eax,%eax
80108392:	74 0c                	je     801083a0 <mappages+0x66>
      panic("remap");
80108394:	c7 04 24 40 92 10 80 	movl   $0x80109240,(%esp)
8010839b:	e8 9a 81 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
801083a0:	8b 45 18             	mov    0x18(%ebp),%eax
801083a3:	0b 45 14             	or     0x14(%ebp),%eax
801083a6:	83 c8 01             	or     $0x1,%eax
801083a9:	89 c2                	mov    %eax,%edx
801083ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083ae:	89 10                	mov    %edx,(%eax)
    if(a == last)
801083b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801083b6:	75 08                	jne    801083c0 <mappages+0x86>
      break;
801083b8:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
801083b9:	b8 00 00 00 00       	mov    $0x0,%eax
801083be:	eb 10                	jmp    801083d0 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
801083c0:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
801083c7:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801083ce:	eb 8e                	jmp    8010835e <mappages+0x24>
  return 0;
}
801083d0:	c9                   	leave  
801083d1:	c3                   	ret    

801083d2 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
801083d2:	55                   	push   %ebp
801083d3:	89 e5                	mov    %esp,%ebp
801083d5:	53                   	push   %ebx
801083d6:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801083d9:	e8 9d ad ff ff       	call   8010317b <kalloc>
801083de:	89 45 f0             	mov    %eax,-0x10(%ebp)
801083e1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801083e5:	75 0a                	jne    801083f1 <setupkvm+0x1f>
    return 0;
801083e7:	b8 00 00 00 00       	mov    $0x0,%eax
801083ec:	e9 98 00 00 00       	jmp    80108489 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801083f1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801083f8:	00 
801083f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108400:	00 
80108401:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108404:	89 04 24             	mov    %eax,(%esp)
80108407:	e8 ac d4 ff ff       	call   801058b8 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
8010840c:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108413:	e8 fd f9 ff ff       	call   80107e15 <p2v>
80108418:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
8010841d:	76 0c                	jbe    8010842b <setupkvm+0x59>
    panic("PHYSTOP too high");
8010841f:	c7 04 24 46 92 10 80 	movl   $0x80109246,(%esp)
80108426:	e8 0f 81 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010842b:	c7 45 f4 a0 c4 10 80 	movl   $0x8010c4a0,-0xc(%ebp)
80108432:	eb 49                	jmp    8010847d <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108434:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108437:	8b 48 0c             	mov    0xc(%eax),%ecx
8010843a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010843d:	8b 50 04             	mov    0x4(%eax),%edx
80108440:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108443:	8b 58 08             	mov    0x8(%eax),%ebx
80108446:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108449:	8b 40 04             	mov    0x4(%eax),%eax
8010844c:	29 c3                	sub    %eax,%ebx
8010844e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108451:	8b 00                	mov    (%eax),%eax
80108453:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108457:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010845b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010845f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108463:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108466:	89 04 24             	mov    %eax,(%esp)
80108469:	e8 cc fe ff ff       	call   8010833a <mappages>
8010846e:	85 c0                	test   %eax,%eax
80108470:	79 07                	jns    80108479 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108472:	b8 00 00 00 00       	mov    $0x0,%eax
80108477:	eb 10                	jmp    80108489 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108479:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010847d:	81 7d f4 e0 c4 10 80 	cmpl   $0x8010c4e0,-0xc(%ebp)
80108484:	72 ae                	jb     80108434 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108486:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108489:	83 c4 34             	add    $0x34,%esp
8010848c:	5b                   	pop    %ebx
8010848d:	5d                   	pop    %ebp
8010848e:	c3                   	ret    

8010848f <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
8010848f:	55                   	push   %ebp
80108490:	89 e5                	mov    %esp,%ebp
80108492:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108495:	e8 38 ff ff ff       	call   801083d2 <setupkvm>
8010849a:	a3 98 6d 11 80       	mov    %eax,0x80116d98
  switchkvm();
8010849f:	e8 02 00 00 00       	call   801084a6 <switchkvm>
}
801084a4:	c9                   	leave  
801084a5:	c3                   	ret    

801084a6 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801084a6:	55                   	push   %ebp
801084a7:	89 e5                	mov    %esp,%ebp
801084a9:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801084ac:	a1 98 6d 11 80       	mov    0x80116d98,%eax
801084b1:	89 04 24             	mov    %eax,(%esp)
801084b4:	e8 4f f9 ff ff       	call   80107e08 <v2p>
801084b9:	89 04 24             	mov    %eax,(%esp)
801084bc:	e8 3c f9 ff ff       	call   80107dfd <lcr3>
}
801084c1:	c9                   	leave  
801084c2:	c3                   	ret    

801084c3 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801084c3:	55                   	push   %ebp
801084c4:	89 e5                	mov    %esp,%ebp
801084c6:	53                   	push   %ebx
801084c7:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801084ca:	e8 e9 d2 ff ff       	call   801057b8 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801084cf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801084d5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801084dc:	83 c2 08             	add    $0x8,%edx
801084df:	89 d3                	mov    %edx,%ebx
801084e1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801084e8:	83 c2 08             	add    $0x8,%edx
801084eb:	c1 ea 10             	shr    $0x10,%edx
801084ee:	89 d1                	mov    %edx,%ecx
801084f0:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801084f7:	83 c2 08             	add    $0x8,%edx
801084fa:	c1 ea 18             	shr    $0x18,%edx
801084fd:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108504:	67 00 
80108506:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
8010850d:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108513:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010851a:	83 e1 f0             	and    $0xfffffff0,%ecx
8010851d:	83 c9 09             	or     $0x9,%ecx
80108520:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108526:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010852d:	83 c9 10             	or     $0x10,%ecx
80108530:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108536:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010853d:	83 e1 9f             	and    $0xffffff9f,%ecx
80108540:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108546:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010854d:	83 c9 80             	or     $0xffffff80,%ecx
80108550:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108556:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010855d:	83 e1 f0             	and    $0xfffffff0,%ecx
80108560:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108566:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010856d:	83 e1 ef             	and    $0xffffffef,%ecx
80108570:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108576:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010857d:	83 e1 df             	and    $0xffffffdf,%ecx
80108580:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108586:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010858d:	83 c9 40             	or     $0x40,%ecx
80108590:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108596:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010859d:	83 e1 7f             	and    $0x7f,%ecx
801085a0:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801085a6:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801085ac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801085b2:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801085b9:	83 e2 ef             	and    $0xffffffef,%edx
801085bc:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801085c2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801085c8:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801085ce:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801085d4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801085db:	8b 52 08             	mov    0x8(%edx),%edx
801085de:	81 c2 00 10 00 00    	add    $0x1000,%edx
801085e4:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801085e7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801085ee:	e8 df f7 ff ff       	call   80107dd2 <ltr>
  if(p->pgdir == 0)
801085f3:	8b 45 08             	mov    0x8(%ebp),%eax
801085f6:	8b 40 04             	mov    0x4(%eax),%eax
801085f9:	85 c0                	test   %eax,%eax
801085fb:	75 0c                	jne    80108609 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801085fd:	c7 04 24 57 92 10 80 	movl   $0x80109257,(%esp)
80108604:	e8 31 7f ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108609:	8b 45 08             	mov    0x8(%ebp),%eax
8010860c:	8b 40 04             	mov    0x4(%eax),%eax
8010860f:	89 04 24             	mov    %eax,(%esp)
80108612:	e8 f1 f7 ff ff       	call   80107e08 <v2p>
80108617:	89 04 24             	mov    %eax,(%esp)
8010861a:	e8 de f7 ff ff       	call   80107dfd <lcr3>
  popcli();
8010861f:	e8 d8 d1 ff ff       	call   801057fc <popcli>
}
80108624:	83 c4 14             	add    $0x14,%esp
80108627:	5b                   	pop    %ebx
80108628:	5d                   	pop    %ebp
80108629:	c3                   	ret    

8010862a <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010862a:	55                   	push   %ebp
8010862b:	89 e5                	mov    %esp,%ebp
8010862d:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108630:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108637:	76 0c                	jbe    80108645 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108639:	c7 04 24 6b 92 10 80 	movl   $0x8010926b,(%esp)
80108640:	e8 f5 7e ff ff       	call   8010053a <panic>
  mem = kalloc();
80108645:	e8 31 ab ff ff       	call   8010317b <kalloc>
8010864a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
8010864d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108654:	00 
80108655:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010865c:	00 
8010865d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108660:	89 04 24             	mov    %eax,(%esp)
80108663:	e8 50 d2 ff ff       	call   801058b8 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108668:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010866b:	89 04 24             	mov    %eax,(%esp)
8010866e:	e8 95 f7 ff ff       	call   80107e08 <v2p>
80108673:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010867a:	00 
8010867b:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010867f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108686:	00 
80108687:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010868e:	00 
8010868f:	8b 45 08             	mov    0x8(%ebp),%eax
80108692:	89 04 24             	mov    %eax,(%esp)
80108695:	e8 a0 fc ff ff       	call   8010833a <mappages>
  memmove(mem, init, sz);
8010869a:	8b 45 10             	mov    0x10(%ebp),%eax
8010869d:	89 44 24 08          	mov    %eax,0x8(%esp)
801086a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801086a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801086a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ab:	89 04 24             	mov    %eax,(%esp)
801086ae:	e8 d4 d2 ff ff       	call   80105987 <memmove>
}
801086b3:	c9                   	leave  
801086b4:	c3                   	ret    

801086b5 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801086b5:	55                   	push   %ebp
801086b6:	89 e5                	mov    %esp,%ebp
801086b8:	53                   	push   %ebx
801086b9:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801086bc:	8b 45 0c             	mov    0xc(%ebp),%eax
801086bf:	25 ff 0f 00 00       	and    $0xfff,%eax
801086c4:	85 c0                	test   %eax,%eax
801086c6:	74 0c                	je     801086d4 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801086c8:	c7 04 24 88 92 10 80 	movl   $0x80109288,(%esp)
801086cf:	e8 66 7e ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
801086d4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801086db:	e9 a9 00 00 00       	jmp    80108789 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801086e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086e3:	8b 55 0c             	mov    0xc(%ebp),%edx
801086e6:	01 d0                	add    %edx,%eax
801086e8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801086ef:	00 
801086f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801086f4:	8b 45 08             	mov    0x8(%ebp),%eax
801086f7:	89 04 24             	mov    %eax,(%esp)
801086fa:	e8 99 fb ff ff       	call   80108298 <walkpgdir>
801086ff:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108702:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108706:	75 0c                	jne    80108714 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108708:	c7 04 24 ab 92 10 80 	movl   $0x801092ab,(%esp)
8010870f:	e8 26 7e ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108714:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108717:	8b 00                	mov    (%eax),%eax
80108719:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010871e:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108721:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108724:	8b 55 18             	mov    0x18(%ebp),%edx
80108727:	29 c2                	sub    %eax,%edx
80108729:	89 d0                	mov    %edx,%eax
8010872b:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108730:	77 0f                	ja     80108741 <loaduvm+0x8c>
      n = sz - i;
80108732:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108735:	8b 55 18             	mov    0x18(%ebp),%edx
80108738:	29 c2                	sub    %eax,%edx
8010873a:	89 d0                	mov    %edx,%eax
8010873c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010873f:	eb 07                	jmp    80108748 <loaduvm+0x93>
    else
      n = PGSIZE;
80108741:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108748:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010874b:	8b 55 14             	mov    0x14(%ebp),%edx
8010874e:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108751:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108754:	89 04 24             	mov    %eax,(%esp)
80108757:	e8 b9 f6 ff ff       	call   80107e15 <p2v>
8010875c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010875f:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108763:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108767:	89 44 24 04          	mov    %eax,0x4(%esp)
8010876b:	8b 45 10             	mov    0x10(%ebp),%eax
8010876e:	89 04 24             	mov    %eax,(%esp)
80108771:	e8 54 9c ff ff       	call   801023ca <readi>
80108776:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108779:	74 07                	je     80108782 <loaduvm+0xcd>
      return -1;
8010877b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108780:	eb 18                	jmp    8010879a <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108782:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108789:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010878c:	3b 45 18             	cmp    0x18(%ebp),%eax
8010878f:	0f 82 4b ff ff ff    	jb     801086e0 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108795:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010879a:	83 c4 24             	add    $0x24,%esp
8010879d:	5b                   	pop    %ebx
8010879e:	5d                   	pop    %ebp
8010879f:	c3                   	ret    

801087a0 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801087a0:	55                   	push   %ebp
801087a1:	89 e5                	mov    %esp,%ebp
801087a3:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
801087a6:	8b 45 10             	mov    0x10(%ebp),%eax
801087a9:	85 c0                	test   %eax,%eax
801087ab:	79 0a                	jns    801087b7 <allocuvm+0x17>
    return 0;
801087ad:	b8 00 00 00 00       	mov    $0x0,%eax
801087b2:	e9 c1 00 00 00       	jmp    80108878 <allocuvm+0xd8>
  if(newsz < oldsz)
801087b7:	8b 45 10             	mov    0x10(%ebp),%eax
801087ba:	3b 45 0c             	cmp    0xc(%ebp),%eax
801087bd:	73 08                	jae    801087c7 <allocuvm+0x27>
    return oldsz;
801087bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801087c2:	e9 b1 00 00 00       	jmp    80108878 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
801087c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801087ca:	05 ff 0f 00 00       	add    $0xfff,%eax
801087cf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801087d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801087d7:	e9 8d 00 00 00       	jmp    80108869 <allocuvm+0xc9>
    mem = kalloc();
801087dc:	e8 9a a9 ff ff       	call   8010317b <kalloc>
801087e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
801087e4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801087e8:	75 2c                	jne    80108816 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
801087ea:	c7 04 24 c9 92 10 80 	movl   $0x801092c9,(%esp)
801087f1:	e8 aa 7b ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801087f6:	8b 45 0c             	mov    0xc(%ebp),%eax
801087f9:	89 44 24 08          	mov    %eax,0x8(%esp)
801087fd:	8b 45 10             	mov    0x10(%ebp),%eax
80108800:	89 44 24 04          	mov    %eax,0x4(%esp)
80108804:	8b 45 08             	mov    0x8(%ebp),%eax
80108807:	89 04 24             	mov    %eax,(%esp)
8010880a:	e8 6b 00 00 00       	call   8010887a <deallocuvm>
      return 0;
8010880f:	b8 00 00 00 00       	mov    $0x0,%eax
80108814:	eb 62                	jmp    80108878 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108816:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010881d:	00 
8010881e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108825:	00 
80108826:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108829:	89 04 24             	mov    %eax,(%esp)
8010882c:	e8 87 d0 ff ff       	call   801058b8 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108831:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108834:	89 04 24             	mov    %eax,(%esp)
80108837:	e8 cc f5 ff ff       	call   80107e08 <v2p>
8010883c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010883f:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108846:	00 
80108847:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010884b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108852:	00 
80108853:	89 54 24 04          	mov    %edx,0x4(%esp)
80108857:	8b 45 08             	mov    0x8(%ebp),%eax
8010885a:	89 04 24             	mov    %eax,(%esp)
8010885d:	e8 d8 fa ff ff       	call   8010833a <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108862:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108869:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010886c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010886f:	0f 82 67 ff ff ff    	jb     801087dc <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108875:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108878:	c9                   	leave  
80108879:	c3                   	ret    

8010887a <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010887a:	55                   	push   %ebp
8010887b:	89 e5                	mov    %esp,%ebp
8010887d:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108880:	8b 45 10             	mov    0x10(%ebp),%eax
80108883:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108886:	72 08                	jb     80108890 <deallocuvm+0x16>
    return oldsz;
80108888:	8b 45 0c             	mov    0xc(%ebp),%eax
8010888b:	e9 a4 00 00 00       	jmp    80108934 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108890:	8b 45 10             	mov    0x10(%ebp),%eax
80108893:	05 ff 0f 00 00       	add    $0xfff,%eax
80108898:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010889d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801088a0:	e9 80 00 00 00       	jmp    80108925 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801088a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088a8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801088af:	00 
801088b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801088b4:	8b 45 08             	mov    0x8(%ebp),%eax
801088b7:	89 04 24             	mov    %eax,(%esp)
801088ba:	e8 d9 f9 ff ff       	call   80108298 <walkpgdir>
801088bf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801088c2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801088c6:	75 09                	jne    801088d1 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801088c8:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801088cf:	eb 4d                	jmp    8010891e <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801088d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088d4:	8b 00                	mov    (%eax),%eax
801088d6:	83 e0 01             	and    $0x1,%eax
801088d9:	85 c0                	test   %eax,%eax
801088db:	74 41                	je     8010891e <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
801088dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088e0:	8b 00                	mov    (%eax),%eax
801088e2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088e7:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801088ea:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801088ee:	75 0c                	jne    801088fc <deallocuvm+0x82>
        panic("kfree");
801088f0:	c7 04 24 e1 92 10 80 	movl   $0x801092e1,(%esp)
801088f7:	e8 3e 7c ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
801088fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088ff:	89 04 24             	mov    %eax,(%esp)
80108902:	e8 0e f5 ff ff       	call   80107e15 <p2v>
80108907:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
8010890a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010890d:	89 04 24             	mov    %eax,(%esp)
80108910:	e8 cd a7 ff ff       	call   801030e2 <kfree>
      *pte = 0;
80108915:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108918:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
8010891e:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108925:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108928:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010892b:	0f 82 74 ff ff ff    	jb     801088a5 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108931:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108934:	c9                   	leave  
80108935:	c3                   	ret    

80108936 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108936:	55                   	push   %ebp
80108937:	89 e5                	mov    %esp,%ebp
80108939:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
8010893c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108940:	75 0c                	jne    8010894e <freevm+0x18>
    panic("freevm: no pgdir");
80108942:	c7 04 24 e7 92 10 80 	movl   $0x801092e7,(%esp)
80108949:	e8 ec 7b ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010894e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108955:	00 
80108956:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
8010895d:	80 
8010895e:	8b 45 08             	mov    0x8(%ebp),%eax
80108961:	89 04 24             	mov    %eax,(%esp)
80108964:	e8 11 ff ff ff       	call   8010887a <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108969:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108970:	eb 48                	jmp    801089ba <freevm+0x84>
    if(pgdir[i] & PTE_P){
80108972:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108975:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010897c:	8b 45 08             	mov    0x8(%ebp),%eax
8010897f:	01 d0                	add    %edx,%eax
80108981:	8b 00                	mov    (%eax),%eax
80108983:	83 e0 01             	and    $0x1,%eax
80108986:	85 c0                	test   %eax,%eax
80108988:	74 2c                	je     801089b6 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010898a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010898d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108994:	8b 45 08             	mov    0x8(%ebp),%eax
80108997:	01 d0                	add    %edx,%eax
80108999:	8b 00                	mov    (%eax),%eax
8010899b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089a0:	89 04 24             	mov    %eax,(%esp)
801089a3:	e8 6d f4 ff ff       	call   80107e15 <p2v>
801089a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801089ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801089ae:	89 04 24             	mov    %eax,(%esp)
801089b1:	e8 2c a7 ff ff       	call   801030e2 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801089b6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801089ba:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801089c1:	76 af                	jbe    80108972 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801089c3:	8b 45 08             	mov    0x8(%ebp),%eax
801089c6:	89 04 24             	mov    %eax,(%esp)
801089c9:	e8 14 a7 ff ff       	call   801030e2 <kfree>
}
801089ce:	c9                   	leave  
801089cf:	c3                   	ret    

801089d0 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801089d0:	55                   	push   %ebp
801089d1:	89 e5                	mov    %esp,%ebp
801089d3:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801089d6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801089dd:	00 
801089de:	8b 45 0c             	mov    0xc(%ebp),%eax
801089e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801089e5:	8b 45 08             	mov    0x8(%ebp),%eax
801089e8:	89 04 24             	mov    %eax,(%esp)
801089eb:	e8 a8 f8 ff ff       	call   80108298 <walkpgdir>
801089f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801089f3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801089f7:	75 0c                	jne    80108a05 <clearpteu+0x35>
    panic("clearpteu");
801089f9:	c7 04 24 f8 92 10 80 	movl   $0x801092f8,(%esp)
80108a00:	e8 35 7b ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a08:	8b 00                	mov    (%eax),%eax
80108a0a:	83 e0 fb             	and    $0xfffffffb,%eax
80108a0d:	89 c2                	mov    %eax,%edx
80108a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a12:	89 10                	mov    %edx,(%eax)
}
80108a14:	c9                   	leave  
80108a15:	c3                   	ret    

80108a16 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108a16:	55                   	push   %ebp
80108a17:	89 e5                	mov    %esp,%ebp
80108a19:	53                   	push   %ebx
80108a1a:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108a1d:	e8 b0 f9 ff ff       	call   801083d2 <setupkvm>
80108a22:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108a25:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108a29:	75 0a                	jne    80108a35 <copyuvm+0x1f>
    return 0;
80108a2b:	b8 00 00 00 00       	mov    $0x0,%eax
80108a30:	e9 fd 00 00 00       	jmp    80108b32 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
80108a35:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108a3c:	e9 d0 00 00 00       	jmp    80108b11 <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a44:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108a4b:	00 
80108a4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a50:	8b 45 08             	mov    0x8(%ebp),%eax
80108a53:	89 04 24             	mov    %eax,(%esp)
80108a56:	e8 3d f8 ff ff       	call   80108298 <walkpgdir>
80108a5b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108a5e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108a62:	75 0c                	jne    80108a70 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80108a64:	c7 04 24 02 93 10 80 	movl   $0x80109302,(%esp)
80108a6b:	e8 ca 7a ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108a70:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a73:	8b 00                	mov    (%eax),%eax
80108a75:	83 e0 01             	and    $0x1,%eax
80108a78:	85 c0                	test   %eax,%eax
80108a7a:	75 0c                	jne    80108a88 <copyuvm+0x72>
      panic("copyuvm: page not present");
80108a7c:	c7 04 24 1c 93 10 80 	movl   $0x8010931c,(%esp)
80108a83:	e8 b2 7a ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108a88:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a8b:	8b 00                	mov    (%eax),%eax
80108a8d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108a92:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108a95:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a98:	8b 00                	mov    (%eax),%eax
80108a9a:	25 ff 0f 00 00       	and    $0xfff,%eax
80108a9f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80108aa2:	e8 d4 a6 ff ff       	call   8010317b <kalloc>
80108aa7:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108aaa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108aae:	75 02                	jne    80108ab2 <copyuvm+0x9c>
      goto bad;
80108ab0:	eb 70                	jmp    80108b22 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108ab2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ab5:	89 04 24             	mov    %eax,(%esp)
80108ab8:	e8 58 f3 ff ff       	call   80107e15 <p2v>
80108abd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ac4:	00 
80108ac5:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ac9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108acc:	89 04 24             	mov    %eax,(%esp)
80108acf:	e8 b3 ce ff ff       	call   80105987 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108ad4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80108ad7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108ada:	89 04 24             	mov    %eax,(%esp)
80108add:	e8 26 f3 ff ff       	call   80107e08 <v2p>
80108ae2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108ae5:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108ae9:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108aed:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108af4:	00 
80108af5:	89 54 24 04          	mov    %edx,0x4(%esp)
80108af9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108afc:	89 04 24             	mov    %eax,(%esp)
80108aff:	e8 36 f8 ff ff       	call   8010833a <mappages>
80108b04:	85 c0                	test   %eax,%eax
80108b06:	79 02                	jns    80108b0a <copyuvm+0xf4>
      goto bad;
80108b08:	eb 18                	jmp    80108b22 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108b0a:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108b11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b14:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108b17:	0f 82 24 ff ff ff    	jb     80108a41 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108b1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b20:	eb 10                	jmp    80108b32 <copyuvm+0x11c>

bad:
  freevm(d);
80108b22:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b25:	89 04 24             	mov    %eax,(%esp)
80108b28:	e8 09 fe ff ff       	call   80108936 <freevm>
  return 0;
80108b2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108b32:	83 c4 44             	add    $0x44,%esp
80108b35:	5b                   	pop    %ebx
80108b36:	5d                   	pop    %ebp
80108b37:	c3                   	ret    

80108b38 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108b38:	55                   	push   %ebp
80108b39:	89 e5                	mov    %esp,%ebp
80108b3b:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108b3e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108b45:	00 
80108b46:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b49:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b4d:	8b 45 08             	mov    0x8(%ebp),%eax
80108b50:	89 04 24             	mov    %eax,(%esp)
80108b53:	e8 40 f7 ff ff       	call   80108298 <walkpgdir>
80108b58:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b5e:	8b 00                	mov    (%eax),%eax
80108b60:	83 e0 01             	and    $0x1,%eax
80108b63:	85 c0                	test   %eax,%eax
80108b65:	75 07                	jne    80108b6e <uva2ka+0x36>
    return 0;
80108b67:	b8 00 00 00 00       	mov    $0x0,%eax
80108b6c:	eb 25                	jmp    80108b93 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108b6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b71:	8b 00                	mov    (%eax),%eax
80108b73:	83 e0 04             	and    $0x4,%eax
80108b76:	85 c0                	test   %eax,%eax
80108b78:	75 07                	jne    80108b81 <uva2ka+0x49>
    return 0;
80108b7a:	b8 00 00 00 00       	mov    $0x0,%eax
80108b7f:	eb 12                	jmp    80108b93 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108b81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b84:	8b 00                	mov    (%eax),%eax
80108b86:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b8b:	89 04 24             	mov    %eax,(%esp)
80108b8e:	e8 82 f2 ff ff       	call   80107e15 <p2v>
}
80108b93:	c9                   	leave  
80108b94:	c3                   	ret    

80108b95 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108b95:	55                   	push   %ebp
80108b96:	89 e5                	mov    %esp,%ebp
80108b98:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108b9b:	8b 45 10             	mov    0x10(%ebp),%eax
80108b9e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108ba1:	e9 87 00 00 00       	jmp    80108c2d <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
80108ba6:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ba9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108bae:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108bb1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108bb4:	89 44 24 04          	mov    %eax,0x4(%esp)
80108bb8:	8b 45 08             	mov    0x8(%ebp),%eax
80108bbb:	89 04 24             	mov    %eax,(%esp)
80108bbe:	e8 75 ff ff ff       	call   80108b38 <uva2ka>
80108bc3:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108bc6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108bca:	75 07                	jne    80108bd3 <copyout+0x3e>
      return -1;
80108bcc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108bd1:	eb 69                	jmp    80108c3c <copyout+0xa7>
    n = PGSIZE - (va - va0);
80108bd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80108bd6:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108bd9:	29 c2                	sub    %eax,%edx
80108bdb:	89 d0                	mov    %edx,%eax
80108bdd:	05 00 10 00 00       	add    $0x1000,%eax
80108be2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108be5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108be8:	3b 45 14             	cmp    0x14(%ebp),%eax
80108beb:	76 06                	jbe    80108bf3 <copyout+0x5e>
      n = len;
80108bed:	8b 45 14             	mov    0x14(%ebp),%eax
80108bf0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108bf3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108bf6:	8b 55 0c             	mov    0xc(%ebp),%edx
80108bf9:	29 c2                	sub    %eax,%edx
80108bfb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108bfe:	01 c2                	add    %eax,%edx
80108c00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c03:	89 44 24 08          	mov    %eax,0x8(%esp)
80108c07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c0e:	89 14 24             	mov    %edx,(%esp)
80108c11:	e8 71 cd ff ff       	call   80105987 <memmove>
    len -= n;
80108c16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c19:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108c1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c1f:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108c22:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108c25:	05 00 10 00 00       	add    $0x1000,%eax
80108c2a:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108c2d:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108c31:	0f 85 6f ff ff ff    	jne    80108ba6 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108c37:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108c3c:	c9                   	leave  
80108c3d:	c3                   	ret    
