
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
80100028:	bc 70 d6 10 80       	mov    $0x8010d670,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 e4 3d 10 80       	mov    $0x80103de4,%eax
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
8010003a:	c7 44 24 04 8c 90 10 	movl   $0x8010908c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 b9 59 00 00       	call   80105a07 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 15 11 80 84 	movl   $0x80111584,0x80111590
80100055:	15 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 15 11 80 84 	movl   $0x80111584,0x80111594
8010005f:	15 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 b4 d6 10 80 	movl   $0x8010d6b4,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 15 11 80    	mov    0x80111594,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 15 11 80 	movl   $0x80111584,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 15 11 80       	mov    0x80111594,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 15 11 80       	mov    %eax,0x80111594

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 15 11 80 	cmpl   $0x80111584,-0xc(%ebp)
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
801000b6:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801000bd:	e8 66 59 00 00       	call   80105a28 <acquire>

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 15 11 80       	mov    0x80111594,%eax
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
801000fd:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100104:	e8 81 59 00 00       	call   80105a8a <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 0e 56 00 00       	call   80105732 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 15 11 80 	cmpl   $0x80111584,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 15 11 80       	mov    0x80111590,%eax
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
80100175:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010017c:	e8 09 59 00 00       	call   80105a8a <release>
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
8010018f:	81 7d f4 84 15 11 80 	cmpl   $0x80111584,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 93 90 10 80 	movl   $0x80109093,(%esp)
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
801001d3:	e8 a0 2c 00 00       	call   80102e78 <iderw>
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
801001ef:	c7 04 24 a4 90 10 80 	movl   $0x801090a4,(%esp)
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
80100210:	e8 63 2c 00 00       	call   80102e78 <iderw>
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
80100229:	c7 04 24 ab 90 10 80 	movl   $0x801090ab,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 e7 57 00 00       	call   80105a28 <acquire>

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
8010025f:	8b 15 94 15 11 80    	mov    0x80111594,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 15 11 80 	movl   $0x80111584,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 15 11 80       	mov    0x80111594,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 15 11 80       	mov    %eax,0x80111594

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
8010029d:	e8 84 55 00 00       	call   80105826 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 dc 57 00 00       	call   80105a8a <release>
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
801003a6:	a1 14 c6 10 80       	mov    0x8010c614,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
801003bb:	e8 68 56 00 00       	call   80105a28 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 b2 90 10 80 	movl   $0x801090b2,(%esp)
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
801004b0:	c7 45 ec bb 90 10 80 	movl   $0x801090bb,-0x14(%ebp)
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
8010052c:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100533:	e8 52 55 00 00       	call   80105a8a <release>
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
80100545:	c7 05 14 c6 10 80 00 	movl   $0x0,0x8010c614
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 c2 90 10 80 	movl   $0x801090c2,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 d1 90 10 80 	movl   $0x801090d1,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 45 55 00 00       	call   80105ad9 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 d3 90 10 80 	movl   $0x801090d3,(%esp)
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
801005be:	c7 05 c0 c5 10 80 01 	movl   $0x1,0x8010c5c0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <shift_buffer_right>:
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
801006d7:	a1 18 c6 10 80       	mov    0x8010c618,%eax
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
80100711:	8b 15 18 c6 10 80    	mov    0x8010c618,%edx
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
8010074a:	a1 18 c6 10 80       	mov    0x8010c618,%eax
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
801007bb:	c7 04 24 d7 90 10 80 	movl   $0x801090d7,(%esp)
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
801007ef:	e8 57 55 00 00       	call   80105d4b <memmove>
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
8010081e:	e8 59 54 00 00       	call   80105c7c <memset>
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
80100883:	a1 18 c6 10 80       	mov    0x8010c618,%eax
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
801008cd:	a1 c0 c5 10 80       	mov    0x8010c5c0,%eax
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
801008ed:	e8 dd 6d 00 00       	call   801076cf <uartputc>
801008f2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801008f9:	e8 d1 6d 00 00       	call   801076cf <uartputc>
801008fe:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100905:	e8 c5 6d 00 00       	call   801076cf <uartputc>
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
80100924:	e8 a6 6d 00 00       	call   801076cf <uartputc>
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
8010093c:	a1 80 20 11 80       	mov    0x80112080,%eax
80100941:	83 f8 10             	cmp    $0x10,%eax
80100944:	75 5d                	jne    801009a3 <add_to_history+0x6d>
  for(i = 0; i < MAX_HISTORY - 1; ++i)
80100946:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010094d:	eb 41                	jmp    80100990 <add_to_history+0x5a>
    memmove(history.commands[i],history.commands[i + 1],
	    history.command_sizes[i + 1]);
8010094f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100952:	83 c0 01             	add    $0x1,%eax
80100955:	05 00 02 00 00       	add    $0x200,%eax
8010095a:	8b 04 85 40 18 11 80 	mov    -0x7feee7c0(,%eax,4),%eax
void
add_to_history(char * start, char * end){
 int i;
 if (history.lastcommand == MAX_HISTORY){
  for(i = 0; i < MAX_HISTORY - 1; ++i)
    memmove(history.commands[i],history.commands[i + 1],
80100961:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100964:	83 c2 01             	add    $0x1,%edx
80100967:	c1 e2 07             	shl    $0x7,%edx
8010096a:	8d 8a 40 18 11 80    	lea    -0x7feee7c0(%edx),%ecx
80100970:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100973:	c1 e2 07             	shl    $0x7,%edx
80100976:	81 c2 40 18 11 80    	add    $0x80111840,%edx
8010097c:	89 44 24 08          	mov    %eax,0x8(%esp)
80100980:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80100984:	89 14 24             	mov    %edx,(%esp)
80100987:	e8 bf 53 00 00       	call   80105d4b <memmove>
//adds a string from start to end to history
void
add_to_history(char * start, char * end){
 int i;
 if (history.lastcommand == MAX_HISTORY){
  for(i = 0; i < MAX_HISTORY - 1; ++i)
8010098c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100990:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80100994:	7e b9                	jle    8010094f <add_to_history+0x19>
    memmove(history.commands[i],history.commands[i + 1],
	    history.command_sizes[i + 1]);
  --history.lastcommand;
80100996:	a1 80 20 11 80       	mov    0x80112080,%eax
8010099b:	83 e8 01             	sub    $0x1,%eax
8010099e:	a3 80 20 11 80       	mov    %eax,0x80112080
 }
 history.command_sizes[history.lastcommand] = end - start;
801009a3:	a1 80 20 11 80       	mov    0x80112080,%eax
801009a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801009ab:	8b 55 08             	mov    0x8(%ebp),%edx
801009ae:	29 d1                	sub    %edx,%ecx
801009b0:	89 ca                	mov    %ecx,%edx
801009b2:	05 00 02 00 00       	add    $0x200,%eax
801009b7:	89 14 85 40 18 11 80 	mov    %edx,-0x7feee7c0(,%eax,4)
 memmove(history.commands[history.lastcommand++], start,end-start);
801009be:	8b 55 0c             	mov    0xc(%ebp),%edx
801009c1:	8b 45 08             	mov    0x8(%ebp),%eax
801009c4:	29 c2                	sub    %eax,%edx
801009c6:	89 d0                	mov    %edx,%eax
801009c8:	89 c2                	mov    %eax,%edx
801009ca:	a1 80 20 11 80       	mov    0x80112080,%eax
801009cf:	8d 48 01             	lea    0x1(%eax),%ecx
801009d2:	89 0d 80 20 11 80    	mov    %ecx,0x80112080
801009d8:	c1 e0 07             	shl    $0x7,%eax
801009db:	8d 88 40 18 11 80    	lea    -0x7feee7c0(%eax),%ecx
801009e1:	89 54 24 08          	mov    %edx,0x8(%esp)
801009e5:	8b 45 08             	mov    0x8(%ebp),%eax
801009e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801009ec:	89 0c 24             	mov    %ecx,(%esp)
801009ef:	e8 57 53 00 00       	call   80105d4b <memmove>
 history.display_command = history.lastcommand - 1;
801009f4:	a1 80 20 11 80       	mov    0x80112080,%eax
801009f9:	83 e8 01             	sub    $0x1,%eax
801009fc:	a3 84 20 11 80       	mov    %eax,0x80112084
}
80100a01:	c9                   	leave  
80100a02:	c3                   	ret    

80100a03 <kill_line>:

void 
kill_line(){
80100a03:	55                   	push   %ebp
80100a04:	89 e5                	mov    %esp,%ebp
80100a06:	83 ec 18             	sub    $0x18,%esp
  input.e = (input.e + left_strides) % INPUT_BUF;
80100a09:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100a0f:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100a14:	01 d0                	add    %edx,%eax
80100a16:	83 e0 7f             	and    $0x7f,%eax
80100a19:	a3 28 18 11 80       	mov    %eax,0x80111828
  while(left_strides){
80100a1e:	eb 19                	jmp    80100a39 <kill_line+0x36>
    cgaputc(RIGHTARROW);
80100a20:	c7 04 24 e5 00 00 00 	movl   $0xe5,(%esp)
80100a27:	e8 02 fc ff ff       	call   8010062e <cgaputc>
    left_strides--;
80100a2c:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100a31:	83 e8 01             	sub    $0x1,%eax
80100a34:	a3 18 c6 10 80       	mov    %eax,0x8010c618
}

void 
kill_line(){
  input.e = (input.e + left_strides) % INPUT_BUF;
  while(left_strides){
80100a39:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100a3e:	85 c0                	test   %eax,%eax
80100a40:	75 de                	jne    80100a20 <kill_line+0x1d>
    cgaputc(RIGHTARROW);
    left_strides--;
  }
  while(input.e != input.w &&
80100a42:	eb 19                	jmp    80100a5d <kill_line+0x5a>
	input.buf[(input.e - 1) % INPUT_BUF] != '\n'){
    input.e--;
80100a44:	a1 28 18 11 80       	mov    0x80111828,%eax
80100a49:	83 e8 01             	sub    $0x1,%eax
80100a4c:	a3 28 18 11 80       	mov    %eax,0x80111828
    consputc(BACKSPACE);
80100a51:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100a58:	e8 6a fe ff ff       	call   801008c7 <consputc>
  input.e = (input.e + left_strides) % INPUT_BUF;
  while(left_strides){
    cgaputc(RIGHTARROW);
    left_strides--;
  }
  while(input.e != input.w &&
80100a5d:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100a63:	a1 24 18 11 80       	mov    0x80111824,%eax
80100a68:	39 c2                	cmp    %eax,%edx
80100a6a:	74 16                	je     80100a82 <kill_line+0x7f>
	input.buf[(input.e - 1) % INPUT_BUF] != '\n'){
80100a6c:	a1 28 18 11 80       	mov    0x80111828,%eax
80100a71:	83 e8 01             	sub    $0x1,%eax
80100a74:	83 e0 7f             	and    $0x7f,%eax
80100a77:	0f b6 80 a0 17 11 80 	movzbl -0x7feee860(%eax),%eax
  input.e = (input.e + left_strides) % INPUT_BUF;
  while(left_strides){
    cgaputc(RIGHTARROW);
    left_strides--;
  }
  while(input.e != input.w &&
80100a7e:	3c 0a                	cmp    $0xa,%al
80100a80:	75 c2                	jne    80100a44 <kill_line+0x41>
	input.buf[(input.e - 1) % INPUT_BUF] != '\n'){
    input.e--;
    consputc(BACKSPACE);
  }
}
80100a82:	c9                   	leave  
80100a83:	c3                   	ret    

80100a84 <display_history>:

void 
display_history(){
80100a84:	55                   	push   %ebp
80100a85:	89 e5                	mov    %esp,%ebp
80100a87:	83 ec 28             	sub    $0x28,%esp
 int i = 0;
80100a8a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 int size = history.command_sizes[history.display_command];
80100a91:	a1 84 20 11 80       	mov    0x80112084,%eax
80100a96:	05 00 02 00 00       	add    $0x200,%eax
80100a9b:	8b 04 85 40 18 11 80 	mov    -0x7feee7c0(,%eax,4),%eax
80100aa2:	89 45 ec             	mov    %eax,-0x14(%ebp)
 char * cmd = history.commands[history.display_command];
80100aa5:	a1 84 20 11 80       	mov    0x80112084,%eax
80100aaa:	c1 e0 07             	shl    $0x7,%eax
80100aad:	05 40 18 11 80       	add    $0x80111840,%eax
80100ab2:	89 45 f0             	mov    %eax,-0x10(%ebp)
 kill_line();
80100ab5:	e8 49 ff ff ff       	call   80100a03 <kill_line>
 input.e = input.w;
80100aba:	a1 24 18 11 80       	mov    0x80111824,%eax
80100abf:	a3 28 18 11 80       	mov    %eax,0x80111828
 memmove(input.buf + input.w, cmd, size);
80100ac4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ac7:	8b 15 24 18 11 80    	mov    0x80111824,%edx
80100acd:	81 c2 a0 17 11 80    	add    $0x801117a0,%edx
80100ad3:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ad7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100ada:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ade:	89 14 24             	mov    %edx,(%esp)
80100ae1:	e8 65 52 00 00       	call   80105d4b <memmove>
 for (i = 0; i < size; ++i){
80100ae6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100aed:	eb 1b                	jmp    80100b0a <display_history+0x86>
   consputc(*cmd++);
80100aef:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100af2:	8d 50 01             	lea    0x1(%eax),%edx
80100af5:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100af8:	0f b6 00             	movzbl (%eax),%eax
80100afb:	0f be c0             	movsbl %al,%eax
80100afe:	89 04 24             	mov    %eax,(%esp)
80100b01:	e8 c1 fd ff ff       	call   801008c7 <consputc>
 int size = history.command_sizes[history.display_command];
 char * cmd = history.commands[history.display_command];
 kill_line();
 input.e = input.w;
 memmove(input.buf + input.w, cmd, size);
 for (i = 0; i < size; ++i){
80100b06:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100b0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100b0d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100b10:	7c dd                	jl     80100aef <display_history+0x6b>
   consputc(*cmd++);
 }
 input.e+=size % INPUT_BUF;
80100b12:	8b 0d 28 18 11 80    	mov    0x80111828,%ecx
80100b18:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100b1b:	99                   	cltd   
80100b1c:	c1 ea 19             	shr    $0x19,%edx
80100b1f:	01 d0                	add    %edx,%eax
80100b21:	83 e0 7f             	and    $0x7f,%eax
80100b24:	29 d0                	sub    %edx,%eax
80100b26:	01 c8                	add    %ecx,%eax
80100b28:	a3 28 18 11 80       	mov    %eax,0x80111828
}
80100b2d:	c9                   	leave  
80100b2e:	c3                   	ret    

80100b2f <consoleintr>:
 
void
consoleintr(int (*getc)(void))
{
80100b2f:	55                   	push   %ebp
80100b30:	89 e5                	mov    %esp,%ebp
80100b32:	83 ec 28             	sub    $0x28,%esp
  int c, doprocdump = 0;
80100b35:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
80100b3c:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100b43:	e8 e0 4e 00 00       	call   80105a28 <acquire>
  while((c = getc()) >= 0){
80100b48:	e9 3a 03 00 00       	jmp    80100e87 <consoleintr+0x358>
    switch(c){
80100b4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100b50:	83 f8 7f             	cmp    $0x7f,%eax
80100b53:	0f 84 ac 00 00 00    	je     80100c05 <consoleintr+0xd6>
80100b59:	83 f8 7f             	cmp    $0x7f,%eax
80100b5c:	7f 18                	jg     80100b76 <consoleintr+0x47>
80100b5e:	83 f8 10             	cmp    $0x10,%eax
80100b61:	74 50                	je     80100bb3 <consoleintr+0x84>
80100b63:	83 f8 15             	cmp    $0x15,%eax
80100b66:	74 72                	je     80100bda <consoleintr+0xab>
80100b68:	83 f8 08             	cmp    $0x8,%eax
80100b6b:	0f 84 94 00 00 00    	je     80100c05 <consoleintr+0xd6>
80100b71:	e9 ed 01 00 00       	jmp    80100d63 <consoleintr+0x234>
80100b76:	3d e3 00 00 00       	cmp    $0xe3,%eax
80100b7b:	0f 84 97 01 00 00    	je     80100d18 <consoleintr+0x1e9>
80100b81:	3d e3 00 00 00       	cmp    $0xe3,%eax
80100b86:	7f 10                	jg     80100b98 <consoleintr+0x69>
80100b88:	3d e2 00 00 00       	cmp    $0xe2,%eax
80100b8d:	0f 84 51 01 00 00    	je     80100ce4 <consoleintr+0x1b5>
80100b93:	e9 cb 01 00 00       	jmp    80100d63 <consoleintr+0x234>
80100b98:	3d e4 00 00 00       	cmp    $0xe4,%eax
80100b9d:	0f 84 c9 00 00 00    	je     80100c6c <consoleintr+0x13d>
80100ba3:	3d e5 00 00 00       	cmp    $0xe5,%eax
80100ba8:	0f 84 fd 00 00 00    	je     80100cab <consoleintr+0x17c>
80100bae:	e9 b0 01 00 00       	jmp    80100d63 <consoleintr+0x234>
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
80100bb3:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
80100bba:	e9 c8 02 00 00       	jmp    80100e87 <consoleintr+0x358>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100bbf:	a1 28 18 11 80       	mov    0x80111828,%eax
80100bc4:	83 e8 01             	sub    $0x1,%eax
80100bc7:	a3 28 18 11 80       	mov    %eax,0x80111828
        consputc(BACKSPACE);
80100bcc:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100bd3:	e8 ef fc ff ff       	call   801008c7 <consputc>
80100bd8:	eb 01                	jmp    80100bdb <consoleintr+0xac>
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100bda:	90                   	nop
80100bdb:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100be1:	a1 24 18 11 80       	mov    0x80111824,%eax
80100be6:	39 c2                	cmp    %eax,%edx
80100be8:	74 16                	je     80100c00 <consoleintr+0xd1>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100bea:	a1 28 18 11 80       	mov    0x80111828,%eax
80100bef:	83 e8 01             	sub    $0x1,%eax
80100bf2:	83 e0 7f             	and    $0x7f,%eax
80100bf5:	0f b6 80 a0 17 11 80 	movzbl -0x7feee860(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100bfc:	3c 0a                	cmp    $0xa,%al
80100bfe:	75 bf                	jne    80100bbf <consoleintr+0x90>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100c00:	e9 82 02 00 00       	jmp    80100e87 <consoleintr+0x358>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
80100c05:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100c0b:	a1 24 18 11 80       	mov    0x80111824,%eax
80100c10:	39 c2                	cmp    %eax,%edx
80100c12:	74 53                	je     80100c67 <consoleintr+0x138>
        input.e--;
80100c14:	a1 28 18 11 80       	mov    0x80111828,%eax
80100c19:	83 e8 01             	sub    $0x1,%eax
80100c1c:	a3 28 18 11 80       	mov    %eax,0x80111828
        if(left_strides > 0){
80100c21:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100c26:	85 c0                	test   %eax,%eax
80100c28:	7e 2c                	jle    80100c56 <consoleintr+0x127>
         shift_buffer_left(input.buf + input.e,
               input.buf + input.e + left_strides +1);
80100c2a:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100c30:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100c35:	01 d0                	add    %edx,%eax
80100c37:	83 c0 01             	add    $0x1,%eax
      break;
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        if(left_strides > 0){
         shift_buffer_left(input.buf + input.e,
80100c3a:	8d 90 a0 17 11 80    	lea    -0x7feee860(%eax),%edx
80100c40:	a1 28 18 11 80       	mov    0x80111828,%eax
80100c45:	05 a0 17 11 80       	add    $0x801117a0,%eax
80100c4a:	89 54 24 04          	mov    %edx,0x4(%esp)
80100c4e:	89 04 24             	mov    %eax,(%esp)
80100c51:	e8 a6 f9 ff ff       	call   801005fc <shift_buffer_left>
               input.buf + input.e + left_strides +1);
              
        }
            consputc(BACKSPACE);
80100c56:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100c5d:	e8 65 fc ff ff       	call   801008c7 <consputc>
      }
      break;
80100c62:	e9 20 02 00 00       	jmp    80100e87 <consoleintr+0x358>
80100c67:	e9 1b 02 00 00       	jmp    80100e87 <consoleintr+0x358>
     case LEFTARROW: //makeshift left arrow
      if(input.e != input.w) { //we want to shift the buffer to the right
80100c6c:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100c72:	a1 24 18 11 80       	mov    0x80111824,%eax
80100c77:	39 c2                	cmp    %eax,%edx
80100c79:	74 2b                	je     80100ca6 <consoleintr+0x177>
       cgaputc(LEFTARROW);
80100c7b:	c7 04 24 e4 00 00 00 	movl   $0xe4,(%esp)
80100c82:	e8 a7 f9 ff ff       	call   8010062e <cgaputc>
       ++left_strides;
80100c87:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100c8c:	83 c0 01             	add    $0x1,%eax
80100c8f:	a3 18 c6 10 80       	mov    %eax,0x8010c618
       --input.e;
80100c94:	a1 28 18 11 80       	mov    0x80111828,%eax
80100c99:	83 e8 01             	sub    $0x1,%eax
80100c9c:	a3 28 18 11 80       	mov    %eax,0x80111828
      }
      break;
80100ca1:	e9 e1 01 00 00       	jmp    80100e87 <consoleintr+0x358>
80100ca6:	e9 dc 01 00 00       	jmp    80100e87 <consoleintr+0x358>
     case RIGHTARROW:
      if(left_strides > 0) {
80100cab:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100cb0:	85 c0                	test   %eax,%eax
80100cb2:	7e 2b                	jle    80100cdf <consoleintr+0x1b0>
        cgaputc(RIGHTARROW);
80100cb4:	c7 04 24 e5 00 00 00 	movl   $0xe5,(%esp)
80100cbb:	e8 6e f9 ff ff       	call   8010062e <cgaputc>
        --left_strides;
80100cc0:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100cc5:	83 e8 01             	sub    $0x1,%eax
80100cc8:	a3 18 c6 10 80       	mov    %eax,0x8010c618
        ++input.e;
80100ccd:	a1 28 18 11 80       	mov    0x80111828,%eax
80100cd2:	83 c0 01             	add    $0x1,%eax
80100cd5:	a3 28 18 11 80       	mov    %eax,0x80111828
      }
      break;
80100cda:	e9 a8 01 00 00       	jmp    80100e87 <consoleintr+0x358>
80100cdf:	e9 a3 01 00 00       	jmp    80100e87 <consoleintr+0x358>
     case KEY_UP: 
       if(history.lastcommand > 0) {
80100ce4:	a1 80 20 11 80       	mov    0x80112080,%eax
80100ce9:	85 c0                	test   %eax,%eax
80100ceb:	7e 26                	jle    80100d13 <consoleintr+0x1e4>
           display_history();
80100ced:	e8 92 fd ff ff       	call   80100a84 <display_history>
	   history.display_command -= (history.display_command) ? 1 :0;
80100cf2:	8b 15 84 20 11 80    	mov    0x80112084,%edx
80100cf8:	a1 84 20 11 80       	mov    0x80112084,%eax
80100cfd:	85 c0                	test   %eax,%eax
80100cff:	0f 95 c0             	setne  %al
80100d02:	0f b6 c0             	movzbl %al,%eax
80100d05:	29 c2                	sub    %eax,%edx
80100d07:	89 d0                	mov    %edx,%eax
80100d09:	a3 84 20 11 80       	mov    %eax,0x80112084
       }
     break;
80100d0e:	e9 74 01 00 00       	jmp    80100e87 <consoleintr+0x358>
80100d13:	e9 6f 01 00 00       	jmp    80100e87 <consoleintr+0x358>
     case KEY_DN: 
	if((history.lastcommand - history.display_command) > 1) {
80100d18:	8b 15 80 20 11 80    	mov    0x80112080,%edx
80100d1e:	a1 84 20 11 80       	mov    0x80112084,%eax
80100d23:	29 c2                	sub    %eax,%edx
80100d25:	89 d0                	mov    %edx,%eax
80100d27:	83 f8 01             	cmp    $0x1,%eax
80100d2a:	7e 14                	jle    80100d40 <consoleintr+0x211>
	 ++history.display_command;
80100d2c:	a1 84 20 11 80       	mov    0x80112084,%eax
80100d31:	83 c0 01             	add    $0x1,%eax
80100d34:	a3 84 20 11 80       	mov    %eax,0x80112084
	 display_history();
80100d39:	e8 46 fd ff ff       	call   80100a84 <display_history>
80100d3e:	eb 1e                	jmp    80100d5e <consoleintr+0x22f>
	}
	else if (history.lastcommand - history.display_command == 1)
80100d40:	8b 15 80 20 11 80    	mov    0x80112080,%edx
80100d46:	a1 84 20 11 80       	mov    0x80112084,%eax
80100d4b:	29 c2                	sub    %eax,%edx
80100d4d:	89 d0                	mov    %edx,%eax
80100d4f:	83 f8 01             	cmp    $0x1,%eax
80100d52:	75 0a                	jne    80100d5e <consoleintr+0x22f>
	  kill_line();
80100d54:	e8 aa fc ff ff       	call   80100a03 <kill_line>
     break;
80100d59:	e9 29 01 00 00       	jmp    80100e87 <consoleintr+0x358>
80100d5e:	e9 24 01 00 00       	jmp    80100e87 <consoleintr+0x358>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100d63:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100d67:	0f 84 19 01 00 00    	je     80100e86 <consoleintr+0x357>
80100d6d:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100d73:	a1 20 18 11 80       	mov    0x80111820,%eax
80100d78:	29 c2                	sub    %eax,%edx
80100d7a:	89 d0                	mov    %edx,%eax
80100d7c:	83 f8 7f             	cmp    $0x7f,%eax
80100d7f:	0f 87 01 01 00 00    	ja     80100e86 <consoleintr+0x357>
        c = (c == '\r') ? '\n' : c;
80100d85:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80100d89:	74 05                	je     80100d90 <consoleintr+0x261>
80100d8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100d8e:	eb 05                	jmp    80100d95 <consoleintr+0x266>
80100d90:	b8 0a 00 00 00       	mov    $0xa,%eax
80100d95:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if('\n' == c){  // if we press enter we want the whole buffer to be
80100d98:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100d9c:	75 4f                	jne    80100ded <consoleintr+0x2be>
          input.e = (input.e + left_strides) % INPUT_BUF;
80100d9e:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100da4:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100da9:	01 d0                	add    %edx,%eax
80100dab:	83 e0 7f             	and    $0x7f,%eax
80100dae:	a3 28 18 11 80       	mov    %eax,0x80111828
           if(input.e != input.w) 
80100db3:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100db9:	a1 24 18 11 80       	mov    0x80111824,%eax
80100dbe:	39 c2                	cmp    %eax,%edx
80100dc0:	74 21                	je     80100de3 <consoleintr+0x2b4>
	     add_to_history(input.buf + input.w,
               input.buf + input.e);
80100dc2:	a1 28 18 11 80       	mov    0x80111828,%eax
      if(c != 0 && input.e-input.r < INPUT_BUF){
        c = (c == '\r') ? '\n' : c;
        if('\n' == c){  // if we press enter we want the whole buffer to be
          input.e = (input.e + left_strides) % INPUT_BUF;
           if(input.e != input.w) 
	     add_to_history(input.buf + input.w,
80100dc7:	8d 90 a0 17 11 80    	lea    -0x7feee860(%eax),%edx
80100dcd:	a1 24 18 11 80       	mov    0x80111824,%eax
80100dd2:	05 a0 17 11 80       	add    $0x801117a0,%eax
80100dd7:	89 54 24 04          	mov    %edx,0x4(%esp)
80100ddb:	89 04 24             	mov    %eax,(%esp)
80100dde:	e8 53 fb ff ff       	call   80100936 <add_to_history>
               input.buf + input.e);
            left_strides  = 0;
80100de3:	c7 05 18 c6 10 80 00 	movl   $0x0,0x8010c618
80100dea:	00 00 00 
        }
       
        if (left_strides > 0) { //if we've taken a left and then we write.
80100ded:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100df2:	85 c0                	test   %eax,%eax
80100df4:	7e 29                	jle    80100e1f <consoleintr+0x2f0>
          shift_buffer_right(input.buf + input.e,
               input.buf + input.e + left_strides);
80100df6:	8b 15 28 18 11 80    	mov    0x80111828,%edx
80100dfc:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80100e01:	01 d0                	add    %edx,%eax
               input.buf + input.e);
            left_strides  = 0;
        }
       
        if (left_strides > 0) { //if we've taken a left and then we write.
          shift_buffer_right(input.buf + input.e,
80100e03:	8d 90 a0 17 11 80    	lea    -0x7feee860(%eax),%edx
80100e09:	a1 28 18 11 80       	mov    0x80111828,%eax
80100e0e:	05 a0 17 11 80       	add    $0x801117a0,%eax
80100e13:	89 54 24 04          	mov    %edx,0x4(%esp)
80100e17:	89 04 24             	mov    %eax,(%esp)
80100e1a:	e8 ab f7 ff ff       	call   801005ca <shift_buffer_right>
               input.buf + input.e + left_strides);
        }
        input.buf[input.e++ % INPUT_BUF] = c;
80100e1f:	a1 28 18 11 80       	mov    0x80111828,%eax
80100e24:	8d 50 01             	lea    0x1(%eax),%edx
80100e27:	89 15 28 18 11 80    	mov    %edx,0x80111828
80100e2d:	83 e0 7f             	and    $0x7f,%eax
80100e30:	89 c2                	mov    %eax,%edx
80100e32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e35:	88 82 a0 17 11 80    	mov    %al,-0x7feee860(%edx)
        consputc(c);
80100e3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e3e:	89 04 24             	mov    %eax,(%esp)
80100e41:	e8 81 fa ff ff       	call   801008c7 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
80100e46:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100e4a:	74 18                	je     80100e64 <consoleintr+0x335>
80100e4c:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100e50:	74 12                	je     80100e64 <consoleintr+0x335>
80100e52:	a1 28 18 11 80       	mov    0x80111828,%eax
80100e57:	8b 15 20 18 11 80    	mov    0x80111820,%edx
80100e5d:	83 ea 80             	sub    $0xffffff80,%edx
80100e60:	39 d0                	cmp    %edx,%eax
80100e62:	75 22                	jne    80100e86 <consoleintr+0x357>
          left_strides = 0;
80100e64:	c7 05 18 c6 10 80 00 	movl   $0x0,0x8010c618
80100e6b:	00 00 00 
          input.w = input.e;
80100e6e:	a1 28 18 11 80       	mov    0x80111828,%eax
80100e73:	a3 24 18 11 80       	mov    %eax,0x80111824
          wakeup(&input.r);
80100e78:	c7 04 24 20 18 11 80 	movl   $0x80111820,(%esp)
80100e7f:	e8 a2 49 00 00       	call   80105826 <wakeup>
        }
      }
        break;
80100e84:	eb 00                	jmp    80100e86 <consoleintr+0x357>
80100e86:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c, doprocdump = 0;

  acquire(&cons.lock);
  while((c = getc()) >= 0){
80100e87:	8b 45 08             	mov    0x8(%ebp),%eax
80100e8a:	ff d0                	call   *%eax
80100e8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e8f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100e93:	0f 89 b4 fc ff ff    	jns    80100b4d <consoleintr+0x1e>
        }
      }
        break;
      }
  }
  release(&cons.lock);
80100e99:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100ea0:	e8 e5 4b 00 00       	call   80105a8a <release>
  if(doprocdump) {
80100ea5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100ea9:	74 05                	je     80100eb0 <consoleintr+0x381>
        procdump();  // now call procdump() wo. cons.lock held
80100eab:	e8 27 4a 00 00       	call   801058d7 <procdump>
      }
}
80100eb0:	c9                   	leave  
80100eb1:	c3                   	ret    

80100eb2 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100eb2:	55                   	push   %ebp
80100eb3:	89 e5                	mov    %esp,%ebp
80100eb5:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;
  iunlock(ip);
80100eb8:	8b 45 08             	mov    0x8(%ebp),%eax
80100ebb:	89 04 24             	mov    %eax,(%esp)
80100ebe:	e8 86 11 00 00       	call   80102049 <iunlock>
  target = n;
80100ec3:	8b 45 10             	mov    0x10(%ebp),%eax
80100ec6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
80100ec9:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100ed0:	e8 53 4b 00 00       	call   80105a28 <acquire>
  while(n > 0){
80100ed5:	e9 aa 00 00 00       	jmp    80100f84 <consoleread+0xd2>
    while(input.r == input.w){
80100eda:	eb 42                	jmp    80100f1e <consoleread+0x6c>
      if(proc->killed){
80100edc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ee2:	8b 40 24             	mov    0x24(%eax),%eax
80100ee5:	85 c0                	test   %eax,%eax
80100ee7:	74 21                	je     80100f0a <consoleread+0x58>
        release(&cons.lock);
80100ee9:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100ef0:	e8 95 4b 00 00       	call   80105a8a <release>
        ilock(ip);
80100ef5:	8b 45 08             	mov    0x8(%ebp),%eax
80100ef8:	89 04 24             	mov    %eax,(%esp)
80100efb:	e8 f5 0f 00 00       	call   80101ef5 <ilock>
        return -1;
80100f00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f05:	e9 a5 00 00 00       	jmp    80100faf <consoleread+0xfd>
      }
      sleep(&input.r, &cons.lock);
80100f0a:	c7 44 24 04 e0 c5 10 	movl   $0x8010c5e0,0x4(%esp)
80100f11:	80 
80100f12:	c7 04 24 20 18 11 80 	movl   $0x80111820,(%esp)
80100f19:	e8 14 48 00 00       	call   80105732 <sleep>
  int c;
  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
    while(input.r == input.w){
80100f1e:	8b 15 20 18 11 80    	mov    0x80111820,%edx
80100f24:	a1 24 18 11 80       	mov    0x80111824,%eax
80100f29:	39 c2                	cmp    %eax,%edx
80100f2b:	74 af                	je     80100edc <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100f2d:	a1 20 18 11 80       	mov    0x80111820,%eax
80100f32:	8d 50 01             	lea    0x1(%eax),%edx
80100f35:	89 15 20 18 11 80    	mov    %edx,0x80111820
80100f3b:	83 e0 7f             	and    $0x7f,%eax
80100f3e:	0f b6 80 a0 17 11 80 	movzbl -0x7feee860(%eax),%eax
80100f45:	0f be c0             	movsbl %al,%eax
80100f48:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
80100f4b:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100f4f:	75 19                	jne    80100f6a <consoleread+0xb8>
      if(n < target){
80100f51:	8b 45 10             	mov    0x10(%ebp),%eax
80100f54:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80100f57:	73 0f                	jae    80100f68 <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
80100f59:	a1 20 18 11 80       	mov    0x80111820,%eax
80100f5e:	83 e8 01             	sub    $0x1,%eax
80100f61:	a3 20 18 11 80       	mov    %eax,0x80111820
      }
      break;
80100f66:	eb 26                	jmp    80100f8e <consoleread+0xdc>
80100f68:	eb 24                	jmp    80100f8e <consoleread+0xdc>
    }
    *dst++ = c;
80100f6a:	8b 45 0c             	mov    0xc(%ebp),%eax
80100f6d:	8d 50 01             	lea    0x1(%eax),%edx
80100f70:	89 55 0c             	mov    %edx,0xc(%ebp)
80100f73:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100f76:	88 10                	mov    %dl,(%eax)
    --n;
80100f78:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100f7c:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100f80:	75 02                	jne    80100f84 <consoleread+0xd2>
      break;
80100f82:	eb 0a                	jmp    80100f8e <consoleread+0xdc>
  uint target;
  int c;
  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
80100f84:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100f88:	0f 8f 4c ff ff ff    	jg     80100eda <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&cons.lock);
80100f8e:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100f95:	e8 f0 4a 00 00       	call   80105a8a <release>
  ilock(ip);
80100f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80100f9d:	89 04 24             	mov    %eax,(%esp)
80100fa0:	e8 50 0f 00 00       	call   80101ef5 <ilock>

  return target - n;
80100fa5:	8b 45 10             	mov    0x10(%ebp),%eax
80100fa8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100fab:	29 c2                	sub    %eax,%edx
80100fad:	89 d0                	mov    %edx,%eax
}
80100faf:	c9                   	leave  
80100fb0:	c3                   	ret    

80100fb1 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100fb1:	55                   	push   %ebp
80100fb2:	89 e5                	mov    %esp,%ebp
80100fb4:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80100fba:	89 04 24             	mov    %eax,(%esp)
80100fbd:	e8 87 10 00 00       	call   80102049 <iunlock>
  acquire(&cons.lock);
80100fc2:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100fc9:	e8 5a 4a 00 00       	call   80105a28 <acquire>
  for(i = 0; i < n; i++)
80100fce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100fd5:	eb 1d                	jmp    80100ff4 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100fd7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100fda:	8b 45 0c             	mov    0xc(%ebp),%eax
80100fdd:	01 d0                	add    %edx,%eax
80100fdf:	0f b6 00             	movzbl (%eax),%eax
80100fe2:	0f be c0             	movsbl %al,%eax
80100fe5:	0f b6 c0             	movzbl %al,%eax
80100fe8:	89 04 24             	mov    %eax,(%esp)
80100feb:	e8 d7 f8 ff ff       	call   801008c7 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100ff0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100ff4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ff7:	3b 45 10             	cmp    0x10(%ebp),%eax
80100ffa:	7c db                	jl     80100fd7 <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100ffc:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80101003:	e8 82 4a 00 00       	call   80105a8a <release>
  ilock(ip);
80101008:	8b 45 08             	mov    0x8(%ebp),%eax
8010100b:	89 04 24             	mov    %eax,(%esp)
8010100e:	e8 e2 0e 00 00       	call   80101ef5 <ilock>

  return n;
80101013:	8b 45 10             	mov    0x10(%ebp),%eax
}
80101016:	c9                   	leave  
80101017:	c3                   	ret    

80101018 <consoleinit>:

void
consoleinit(void)
{
80101018:	55                   	push   %ebp
80101019:	89 e5                	mov    %esp,%ebp
8010101b:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
8010101e:	c7 44 24 04 ea 90 10 	movl   $0x801090ea,0x4(%esp)
80101025:	80 
80101026:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
8010102d:	e8 d5 49 00 00       	call   80105a07 <initlock>

  devsw[CONSOLE].write = consolewrite;
80101032:	c7 05 4c 2a 11 80 b1 	movl   $0x80100fb1,0x80112a4c
80101039:	0f 10 80 
  devsw[CONSOLE].read = consoleread;
8010103c:	c7 05 48 2a 11 80 b2 	movl   $0x80100eb2,0x80112a48
80101043:	0e 10 80 
  cons.locking = 1;
80101046:	c7 05 14 c6 10 80 01 	movl   $0x1,0x8010c614
8010104d:	00 00 00 

  picenable(IRQ_KBD);
80101050:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101057:	e8 20 34 00 00       	call   8010447c <picenable>
  ioapicenable(IRQ_KBD, 0);
8010105c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101063:	00 
80101064:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010106b:	e8 c4 1f 00 00       	call   80103034 <ioapicenable>
}
80101070:	c9                   	leave  
80101071:	c3                   	ret    

80101072 <sys_history>:

// This is the implementation of sys_history huzzah
int 
sys_history(void) {
80101072:	55                   	push   %ebp
80101073:	89 e5                	mov    %esp,%ebp
80101075:	83 ec 28             	sub    $0x28,%esp
  char * buffer; 
  int index;

  if(argstr(0, &buffer) < 0 || argint(1, &index)) 
80101078:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010107b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010107f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80101086:	e8 c3 4f 00 00       	call   8010604e <argstr>
8010108b:	85 c0                	test   %eax,%eax
8010108d:	78 17                	js     801010a6 <sys_history+0x34>
8010108f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80101092:	89 44 24 04          	mov    %eax,0x4(%esp)
80101096:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010109d:	e8 1c 4f 00 00       	call   80105fbe <argint>
801010a2:	85 c0                	test   %eax,%eax
801010a4:	74 07                	je     801010ad <sys_history+0x3b>
    return -1;
801010a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801010ab:	eb 7c                	jmp    80101129 <sys_history+0xb7>
  if(index >= history.lastcommand && index < INPUT_BUF)
801010ad:	8b 15 80 20 11 80    	mov    0x80112080,%edx
801010b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010b6:	39 c2                	cmp    %eax,%edx
801010b8:	7f 0f                	jg     801010c9 <sys_history+0x57>
801010ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010bd:	83 f8 7f             	cmp    $0x7f,%eax
801010c0:	7f 07                	jg     801010c9 <sys_history+0x57>
    return -2;
801010c2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
801010c7:	eb 60                	jmp    80101129 <sys_history+0xb7>
  else if (index > history.lastcommand) 
801010c9:	8b 15 80 20 11 80    	mov    0x80112080,%edx
801010cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010d2:	39 c2                	cmp    %eax,%edx
801010d4:	7d 07                	jge    801010dd <sys_history+0x6b>
    return -1;
801010d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801010db:	eb 4c                	jmp    80101129 <sys_history+0xb7>
  memmove(buffer, history.commands[index], history.command_sizes[index]);
801010dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010e0:	05 00 02 00 00       	add    $0x200,%eax
801010e5:	8b 04 85 40 18 11 80 	mov    -0x7feee7c0(,%eax,4),%eax
801010ec:	89 c2                	mov    %eax,%edx
801010ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010f1:	c1 e0 07             	shl    $0x7,%eax
801010f4:	8d 88 40 18 11 80    	lea    -0x7feee7c0(%eax),%ecx
801010fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801010fd:	89 54 24 08          	mov    %edx,0x8(%esp)
80101101:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80101105:	89 04 24             	mov    %eax,(%esp)
80101108:	e8 3e 4c 00 00       	call   80105d4b <memmove>
  buffer[history.command_sizes[index]] = 0;
8010110d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101110:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101113:	05 00 02 00 00       	add    $0x200,%eax
80101118:	8b 04 85 40 18 11 80 	mov    -0x7feee7c0(,%eax,4),%eax
8010111f:	01 d0                	add    %edx,%eax
80101121:	c6 00 00             	movb   $0x0,(%eax)
  return 0;
80101124:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101129:	c9                   	leave  
8010112a:	c3                   	ret    

8010112b <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
8010112b:	55                   	push   %ebp
8010112c:	89 e5                	mov    %esp,%ebp
8010112e:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80101134:	e8 a4 29 00 00       	call   80103add <begin_op>
  if((ip = namei(path)) == 0){
80101139:	8b 45 08             	mov    0x8(%ebp),%eax
8010113c:	89 04 24             	mov    %eax,(%esp)
8010113f:	e8 62 19 00 00       	call   80102aa6 <namei>
80101144:	89 45 d8             	mov    %eax,-0x28(%ebp)
80101147:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
8010114b:	75 0f                	jne    8010115c <exec+0x31>
    end_op();
8010114d:	e8 0f 2a 00 00       	call   80103b61 <end_op>
    return -1;
80101152:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101157:	e9 e8 03 00 00       	jmp    80101544 <exec+0x419>
  }
  ilock(ip);
8010115c:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010115f:	89 04 24             	mov    %eax,(%esp)
80101162:	e8 8e 0d 00 00       	call   80101ef5 <ilock>
  pgdir = 0;
80101167:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
8010116e:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80101175:	00 
80101176:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010117d:	00 
8010117e:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80101184:	89 44 24 04          	mov    %eax,0x4(%esp)
80101188:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010118b:	89 04 24             	mov    %eax,(%esp)
8010118e:	e8 75 12 00 00       	call   80102408 <readi>
80101193:	83 f8 33             	cmp    $0x33,%eax
80101196:	77 05                	ja     8010119d <exec+0x72>
    goto bad;
80101198:	e9 7b 03 00 00       	jmp    80101518 <exec+0x3ed>
  if(elf.magic != ELF_MAGIC)
8010119d:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
801011a3:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
801011a8:	74 05                	je     801011af <exec+0x84>
    goto bad;
801011aa:	e9 69 03 00 00       	jmp    80101518 <exec+0x3ed>

  if((pgdir = setupkvm()) == 0)
801011af:	e8 6c 76 00 00       	call   80108820 <setupkvm>
801011b4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
801011b7:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
801011bb:	75 05                	jne    801011c2 <exec+0x97>
    goto bad;
801011bd:	e9 56 03 00 00       	jmp    80101518 <exec+0x3ed>

  // Load program into memory.
  sz = 0;
801011c2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
801011c9:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
801011d0:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
801011d6:	89 45 e8             	mov    %eax,-0x18(%ebp)
801011d9:	e9 cb 00 00 00       	jmp    801012a9 <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801011de:	8b 45 e8             	mov    -0x18(%ebp),%eax
801011e1:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
801011e8:	00 
801011e9:	89 44 24 08          	mov    %eax,0x8(%esp)
801011ed:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
801011f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801011f7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801011fa:	89 04 24             	mov    %eax,(%esp)
801011fd:	e8 06 12 00 00       	call   80102408 <readi>
80101202:	83 f8 20             	cmp    $0x20,%eax
80101205:	74 05                	je     8010120c <exec+0xe1>
      goto bad;
80101207:	e9 0c 03 00 00       	jmp    80101518 <exec+0x3ed>
    if(ph.type != ELF_PROG_LOAD)
8010120c:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80101212:	83 f8 01             	cmp    $0x1,%eax
80101215:	74 05                	je     8010121c <exec+0xf1>
      continue;
80101217:	e9 80 00 00 00       	jmp    8010129c <exec+0x171>
    if(ph.memsz < ph.filesz)
8010121c:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80101222:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80101228:	39 c2                	cmp    %eax,%edx
8010122a:	73 05                	jae    80101231 <exec+0x106>
      goto bad;
8010122c:	e9 e7 02 00 00       	jmp    80101518 <exec+0x3ed>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80101231:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80101237:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
8010123d:	01 d0                	add    %edx,%eax
8010123f:	89 44 24 08          	mov    %eax,0x8(%esp)
80101243:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101246:	89 44 24 04          	mov    %eax,0x4(%esp)
8010124a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010124d:	89 04 24             	mov    %eax,(%esp)
80101250:	e8 99 79 00 00       	call   80108bee <allocuvm>
80101255:	89 45 e0             	mov    %eax,-0x20(%ebp)
80101258:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010125c:	75 05                	jne    80101263 <exec+0x138>
      goto bad;
8010125e:	e9 b5 02 00 00       	jmp    80101518 <exec+0x3ed>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80101263:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80101269:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
8010126f:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80101275:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80101279:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010127d:	8b 55 d8             	mov    -0x28(%ebp),%edx
80101280:	89 54 24 08          	mov    %edx,0x8(%esp)
80101284:	89 44 24 04          	mov    %eax,0x4(%esp)
80101288:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010128b:	89 04 24             	mov    %eax,(%esp)
8010128e:	e8 70 78 00 00       	call   80108b03 <loaduvm>
80101293:	85 c0                	test   %eax,%eax
80101295:	79 05                	jns    8010129c <exec+0x171>
      goto bad;
80101297:	e9 7c 02 00 00       	jmp    80101518 <exec+0x3ed>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
8010129c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801012a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012a3:	83 c0 20             	add    $0x20,%eax
801012a6:	89 45 e8             	mov    %eax,-0x18(%ebp)
801012a9:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
801012b0:	0f b7 c0             	movzwl %ax,%eax
801012b3:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801012b6:	0f 8f 22 ff ff ff    	jg     801011de <exec+0xb3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
801012bc:	8b 45 d8             	mov    -0x28(%ebp),%eax
801012bf:	89 04 24             	mov    %eax,(%esp)
801012c2:	e8 b8 0e 00 00       	call   8010217f <iunlockput>
  end_op();
801012c7:	e8 95 28 00 00       	call   80103b61 <end_op>
  ip = 0;
801012cc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
801012d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801012d6:	05 ff 0f 00 00       	add    $0xfff,%eax
801012db:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801012e0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
801012e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801012e6:	05 00 20 00 00       	add    $0x2000,%eax
801012eb:	89 44 24 08          	mov    %eax,0x8(%esp)
801012ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
801012f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801012f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801012f9:	89 04 24             	mov    %eax,(%esp)
801012fc:	e8 ed 78 00 00       	call   80108bee <allocuvm>
80101301:	89 45 e0             	mov    %eax,-0x20(%ebp)
80101304:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101308:	75 05                	jne    8010130f <exec+0x1e4>
    goto bad;
8010130a:	e9 09 02 00 00       	jmp    80101518 <exec+0x3ed>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
8010130f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101312:	2d 00 20 00 00       	sub    $0x2000,%eax
80101317:	89 44 24 04          	mov    %eax,0x4(%esp)
8010131b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010131e:	89 04 24             	mov    %eax,(%esp)
80101321:	e8 f8 7a 00 00       	call   80108e1e <clearpteu>
  sp = sz;
80101326:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101329:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
8010132c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80101333:	e9 9a 00 00 00       	jmp    801013d2 <exec+0x2a7>
    if(argc >= MAXARG)
80101338:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
8010133c:	76 05                	jbe    80101343 <exec+0x218>
      goto bad;
8010133e:	e9 d5 01 00 00       	jmp    80101518 <exec+0x3ed>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80101343:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101346:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010134d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101350:	01 d0                	add    %edx,%eax
80101352:	8b 00                	mov    (%eax),%eax
80101354:	89 04 24             	mov    %eax,(%esp)
80101357:	e8 8a 4b 00 00       	call   80105ee6 <strlen>
8010135c:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010135f:	29 c2                	sub    %eax,%edx
80101361:	89 d0                	mov    %edx,%eax
80101363:	83 e8 01             	sub    $0x1,%eax
80101366:	83 e0 fc             	and    $0xfffffffc,%eax
80101369:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
8010136c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010136f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101376:	8b 45 0c             	mov    0xc(%ebp),%eax
80101379:	01 d0                	add    %edx,%eax
8010137b:	8b 00                	mov    (%eax),%eax
8010137d:	89 04 24             	mov    %eax,(%esp)
80101380:	e8 61 4b 00 00       	call   80105ee6 <strlen>
80101385:	83 c0 01             	add    $0x1,%eax
80101388:	89 c2                	mov    %eax,%edx
8010138a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010138d:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80101394:	8b 45 0c             	mov    0xc(%ebp),%eax
80101397:	01 c8                	add    %ecx,%eax
80101399:	8b 00                	mov    (%eax),%eax
8010139b:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010139f:	89 44 24 08          	mov    %eax,0x8(%esp)
801013a3:	8b 45 dc             	mov    -0x24(%ebp),%eax
801013a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801013aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801013ad:	89 04 24             	mov    %eax,(%esp)
801013b0:	e8 2e 7c 00 00       	call   80108fe3 <copyout>
801013b5:	85 c0                	test   %eax,%eax
801013b7:	79 05                	jns    801013be <exec+0x293>
      goto bad;
801013b9:	e9 5a 01 00 00       	jmp    80101518 <exec+0x3ed>
    ustack[3+argc] = sp;
801013be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013c1:	8d 50 03             	lea    0x3(%eax),%edx
801013c4:	8b 45 dc             	mov    -0x24(%ebp),%eax
801013c7:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
801013ce:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801013d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013d5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801013dc:	8b 45 0c             	mov    0xc(%ebp),%eax
801013df:	01 d0                	add    %edx,%eax
801013e1:	8b 00                	mov    (%eax),%eax
801013e3:	85 c0                	test   %eax,%eax
801013e5:	0f 85 4d ff ff ff    	jne    80101338 <exec+0x20d>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
801013eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013ee:	83 c0 03             	add    $0x3,%eax
801013f1:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
801013f8:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
801013fc:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80101403:	ff ff ff 
  ustack[1] = argc;
80101406:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101409:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
8010140f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101412:	83 c0 01             	add    $0x1,%eax
80101415:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010141c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010141f:	29 d0                	sub    %edx,%eax
80101421:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80101427:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010142a:	83 c0 04             	add    $0x4,%eax
8010142d:	c1 e0 02             	shl    $0x2,%eax
80101430:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80101433:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101436:	83 c0 04             	add    $0x4,%eax
80101439:	c1 e0 02             	shl    $0x2,%eax
8010143c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101440:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80101446:	89 44 24 08          	mov    %eax,0x8(%esp)
8010144a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010144d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101451:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101454:	89 04 24             	mov    %eax,(%esp)
80101457:	e8 87 7b 00 00       	call   80108fe3 <copyout>
8010145c:	85 c0                	test   %eax,%eax
8010145e:	79 05                	jns    80101465 <exec+0x33a>
    goto bad;
80101460:	e9 b3 00 00 00       	jmp    80101518 <exec+0x3ed>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80101465:	8b 45 08             	mov    0x8(%ebp),%eax
80101468:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010146b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010146e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101471:	eb 17                	jmp    8010148a <exec+0x35f>
    if(*s == '/')
80101473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101476:	0f b6 00             	movzbl (%eax),%eax
80101479:	3c 2f                	cmp    $0x2f,%al
8010147b:	75 09                	jne    80101486 <exec+0x35b>
      last = s+1;
8010147d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101480:	83 c0 01             	add    $0x1,%eax
80101483:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80101486:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010148a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010148d:	0f b6 00             	movzbl (%eax),%eax
80101490:	84 c0                	test   %al,%al
80101492:	75 df                	jne    80101473 <exec+0x348>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80101494:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010149a:	8d 50 6c             	lea    0x6c(%eax),%edx
8010149d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801014a4:	00 
801014a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801014ac:	89 14 24             	mov    %edx,(%esp)
801014af:	e8 e8 49 00 00       	call   80105e9c <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
801014b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014ba:	8b 40 04             	mov    0x4(%eax),%eax
801014bd:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
801014c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014c6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801014c9:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
801014cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014d2:	8b 55 e0             	mov    -0x20(%ebp),%edx
801014d5:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
801014d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014dd:	8b 40 18             	mov    0x18(%eax),%eax
801014e0:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
801014e6:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
801014e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014ef:	8b 40 18             	mov    0x18(%eax),%eax
801014f2:	8b 55 dc             	mov    -0x24(%ebp),%edx
801014f5:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
801014f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014fe:	89 04 24             	mov    %eax,(%esp)
80101501:	e8 0b 74 00 00       	call   80108911 <switchuvm>
  freevm(oldpgdir);
80101506:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101509:	89 04 24             	mov    %eax,(%esp)
8010150c:	e8 73 78 00 00       	call   80108d84 <freevm>
  return 0;
80101511:	b8 00 00 00 00       	mov    $0x0,%eax
80101516:	eb 2c                	jmp    80101544 <exec+0x419>

 bad:
  if(pgdir)
80101518:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
8010151c:	74 0b                	je     80101529 <exec+0x3fe>
    freevm(pgdir);
8010151e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101521:	89 04 24             	mov    %eax,(%esp)
80101524:	e8 5b 78 00 00       	call   80108d84 <freevm>
  if(ip){
80101529:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
8010152d:	74 10                	je     8010153f <exec+0x414>
    iunlockput(ip);
8010152f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101532:	89 04 24             	mov    %eax,(%esp)
80101535:	e8 45 0c 00 00       	call   8010217f <iunlockput>
    end_op();
8010153a:	e8 22 26 00 00       	call   80103b61 <end_op>
  }
  return -1;
8010153f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101544:	c9                   	leave  
80101545:	c3                   	ret    

80101546 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80101546:	55                   	push   %ebp
80101547:	89 e5                	mov    %esp,%ebp
80101549:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
8010154c:	c7 44 24 04 f2 90 10 	movl   $0x801090f2,0x4(%esp)
80101553:	80 
80101554:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
8010155b:	e8 a7 44 00 00       	call   80105a07 <initlock>
}
80101560:	c9                   	leave  
80101561:	c3                   	ret    

80101562 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101562:	55                   	push   %ebp
80101563:	89 e5                	mov    %esp,%ebp
80101565:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80101568:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
8010156f:	e8 b4 44 00 00       	call   80105a28 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101574:	c7 45 f4 d4 20 11 80 	movl   $0x801120d4,-0xc(%ebp)
8010157b:	eb 29                	jmp    801015a6 <filealloc+0x44>
    if(f->ref == 0){
8010157d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101580:	8b 40 04             	mov    0x4(%eax),%eax
80101583:	85 c0                	test   %eax,%eax
80101585:	75 1b                	jne    801015a2 <filealloc+0x40>
      f->ref = 1;
80101587:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010158a:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80101591:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
80101598:	e8 ed 44 00 00       	call   80105a8a <release>
      return f;
8010159d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015a0:	eb 1e                	jmp    801015c0 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
801015a2:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
801015a6:	81 7d f4 34 2a 11 80 	cmpl   $0x80112a34,-0xc(%ebp)
801015ad:	72 ce                	jb     8010157d <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
801015af:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
801015b6:	e8 cf 44 00 00       	call   80105a8a <release>
  return 0;
801015bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801015c0:	c9                   	leave  
801015c1:	c3                   	ret    

801015c2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
801015c2:	55                   	push   %ebp
801015c3:	89 e5                	mov    %esp,%ebp
801015c5:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
801015c8:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
801015cf:	e8 54 44 00 00       	call   80105a28 <acquire>
  if(f->ref < 1)
801015d4:	8b 45 08             	mov    0x8(%ebp),%eax
801015d7:	8b 40 04             	mov    0x4(%eax),%eax
801015da:	85 c0                	test   %eax,%eax
801015dc:	7f 0c                	jg     801015ea <filedup+0x28>
    panic("filedup");
801015de:	c7 04 24 f9 90 10 80 	movl   $0x801090f9,(%esp)
801015e5:	e8 50 ef ff ff       	call   8010053a <panic>
  f->ref++;
801015ea:	8b 45 08             	mov    0x8(%ebp),%eax
801015ed:	8b 40 04             	mov    0x4(%eax),%eax
801015f0:	8d 50 01             	lea    0x1(%eax),%edx
801015f3:	8b 45 08             	mov    0x8(%ebp),%eax
801015f6:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
801015f9:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
80101600:	e8 85 44 00 00       	call   80105a8a <release>
  return f;
80101605:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101608:	c9                   	leave  
80101609:	c3                   	ret    

8010160a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
8010160a:	55                   	push   %ebp
8010160b:	89 e5                	mov    %esp,%ebp
8010160d:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80101610:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
80101617:	e8 0c 44 00 00       	call   80105a28 <acquire>
  if(f->ref < 1)
8010161c:	8b 45 08             	mov    0x8(%ebp),%eax
8010161f:	8b 40 04             	mov    0x4(%eax),%eax
80101622:	85 c0                	test   %eax,%eax
80101624:	7f 0c                	jg     80101632 <fileclose+0x28>
    panic("fileclose");
80101626:	c7 04 24 01 91 10 80 	movl   $0x80109101,(%esp)
8010162d:	e8 08 ef ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80101632:	8b 45 08             	mov    0x8(%ebp),%eax
80101635:	8b 40 04             	mov    0x4(%eax),%eax
80101638:	8d 50 ff             	lea    -0x1(%eax),%edx
8010163b:	8b 45 08             	mov    0x8(%ebp),%eax
8010163e:	89 50 04             	mov    %edx,0x4(%eax)
80101641:	8b 45 08             	mov    0x8(%ebp),%eax
80101644:	8b 40 04             	mov    0x4(%eax),%eax
80101647:	85 c0                	test   %eax,%eax
80101649:	7e 11                	jle    8010165c <fileclose+0x52>
    release(&ftable.lock);
8010164b:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
80101652:	e8 33 44 00 00       	call   80105a8a <release>
80101657:	e9 82 00 00 00       	jmp    801016de <fileclose+0xd4>
    return;
  }
  ff = *f;
8010165c:	8b 45 08             	mov    0x8(%ebp),%eax
8010165f:	8b 10                	mov    (%eax),%edx
80101661:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101664:	8b 50 04             	mov    0x4(%eax),%edx
80101667:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010166a:	8b 50 08             	mov    0x8(%eax),%edx
8010166d:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101670:	8b 50 0c             	mov    0xc(%eax),%edx
80101673:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101676:	8b 50 10             	mov    0x10(%eax),%edx
80101679:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010167c:	8b 40 14             	mov    0x14(%eax),%eax
8010167f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101682:	8b 45 08             	mov    0x8(%ebp),%eax
80101685:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010168c:	8b 45 08             	mov    0x8(%ebp),%eax
8010168f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101695:	c7 04 24 a0 20 11 80 	movl   $0x801120a0,(%esp)
8010169c:	e8 e9 43 00 00       	call   80105a8a <release>
  
  if(ff.type == FD_PIPE)
801016a1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801016a4:	83 f8 01             	cmp    $0x1,%eax
801016a7:	75 18                	jne    801016c1 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
801016a9:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
801016ad:	0f be d0             	movsbl %al,%edx
801016b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016b3:	89 54 24 04          	mov    %edx,0x4(%esp)
801016b7:	89 04 24             	mov    %eax,(%esp)
801016ba:	e8 6d 30 00 00       	call   8010472c <pipeclose>
801016bf:	eb 1d                	jmp    801016de <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801016c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801016c4:	83 f8 02             	cmp    $0x2,%eax
801016c7:	75 15                	jne    801016de <fileclose+0xd4>
    begin_op();
801016c9:	e8 0f 24 00 00       	call   80103add <begin_op>
    iput(ff.ip);
801016ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016d1:	89 04 24             	mov    %eax,(%esp)
801016d4:	e8 d5 09 00 00       	call   801020ae <iput>
    end_op();
801016d9:	e8 83 24 00 00       	call   80103b61 <end_op>
  }
}
801016de:	c9                   	leave  
801016df:	c3                   	ret    

801016e0 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801016e0:	55                   	push   %ebp
801016e1:	89 e5                	mov    %esp,%ebp
801016e3:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801016e6:	8b 45 08             	mov    0x8(%ebp),%eax
801016e9:	8b 00                	mov    (%eax),%eax
801016eb:	83 f8 02             	cmp    $0x2,%eax
801016ee:	75 38                	jne    80101728 <filestat+0x48>
    ilock(f->ip);
801016f0:	8b 45 08             	mov    0x8(%ebp),%eax
801016f3:	8b 40 10             	mov    0x10(%eax),%eax
801016f6:	89 04 24             	mov    %eax,(%esp)
801016f9:	e8 f7 07 00 00       	call   80101ef5 <ilock>
    stati(f->ip, st);
801016fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101701:	8b 40 10             	mov    0x10(%eax),%eax
80101704:	8b 55 0c             	mov    0xc(%ebp),%edx
80101707:	89 54 24 04          	mov    %edx,0x4(%esp)
8010170b:	89 04 24             	mov    %eax,(%esp)
8010170e:	e8 b0 0c 00 00       	call   801023c3 <stati>
    iunlock(f->ip);
80101713:	8b 45 08             	mov    0x8(%ebp),%eax
80101716:	8b 40 10             	mov    0x10(%eax),%eax
80101719:	89 04 24             	mov    %eax,(%esp)
8010171c:	e8 28 09 00 00       	call   80102049 <iunlock>
    return 0;
80101721:	b8 00 00 00 00       	mov    $0x0,%eax
80101726:	eb 05                	jmp    8010172d <filestat+0x4d>
  }
  return -1;
80101728:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010172d:	c9                   	leave  
8010172e:	c3                   	ret    

8010172f <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
8010172f:	55                   	push   %ebp
80101730:	89 e5                	mov    %esp,%ebp
80101732:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101735:	8b 45 08             	mov    0x8(%ebp),%eax
80101738:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010173c:	84 c0                	test   %al,%al
8010173e:	75 0a                	jne    8010174a <fileread+0x1b>
    return -1;
80101740:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101745:	e9 9f 00 00 00       	jmp    801017e9 <fileread+0xba>
  if(f->type == FD_PIPE)
8010174a:	8b 45 08             	mov    0x8(%ebp),%eax
8010174d:	8b 00                	mov    (%eax),%eax
8010174f:	83 f8 01             	cmp    $0x1,%eax
80101752:	75 1e                	jne    80101772 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101754:	8b 45 08             	mov    0x8(%ebp),%eax
80101757:	8b 40 0c             	mov    0xc(%eax),%eax
8010175a:	8b 55 10             	mov    0x10(%ebp),%edx
8010175d:	89 54 24 08          	mov    %edx,0x8(%esp)
80101761:	8b 55 0c             	mov    0xc(%ebp),%edx
80101764:	89 54 24 04          	mov    %edx,0x4(%esp)
80101768:	89 04 24             	mov    %eax,(%esp)
8010176b:	e8 3d 31 00 00       	call   801048ad <piperead>
80101770:	eb 77                	jmp    801017e9 <fileread+0xba>
  if(f->type == FD_INODE){
80101772:	8b 45 08             	mov    0x8(%ebp),%eax
80101775:	8b 00                	mov    (%eax),%eax
80101777:	83 f8 02             	cmp    $0x2,%eax
8010177a:	75 61                	jne    801017dd <fileread+0xae>
    ilock(f->ip);
8010177c:	8b 45 08             	mov    0x8(%ebp),%eax
8010177f:	8b 40 10             	mov    0x10(%eax),%eax
80101782:	89 04 24             	mov    %eax,(%esp)
80101785:	e8 6b 07 00 00       	call   80101ef5 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010178a:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010178d:	8b 45 08             	mov    0x8(%ebp),%eax
80101790:	8b 50 14             	mov    0x14(%eax),%edx
80101793:	8b 45 08             	mov    0x8(%ebp),%eax
80101796:	8b 40 10             	mov    0x10(%eax),%eax
80101799:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010179d:	89 54 24 08          	mov    %edx,0x8(%esp)
801017a1:	8b 55 0c             	mov    0xc(%ebp),%edx
801017a4:	89 54 24 04          	mov    %edx,0x4(%esp)
801017a8:	89 04 24             	mov    %eax,(%esp)
801017ab:	e8 58 0c 00 00       	call   80102408 <readi>
801017b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801017b3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801017b7:	7e 11                	jle    801017ca <fileread+0x9b>
      f->off += r;
801017b9:	8b 45 08             	mov    0x8(%ebp),%eax
801017bc:	8b 50 14             	mov    0x14(%eax),%edx
801017bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c2:	01 c2                	add    %eax,%edx
801017c4:	8b 45 08             	mov    0x8(%ebp),%eax
801017c7:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801017ca:	8b 45 08             	mov    0x8(%ebp),%eax
801017cd:	8b 40 10             	mov    0x10(%eax),%eax
801017d0:	89 04 24             	mov    %eax,(%esp)
801017d3:	e8 71 08 00 00       	call   80102049 <iunlock>
    return r;
801017d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017db:	eb 0c                	jmp    801017e9 <fileread+0xba>
  }
  panic("fileread");
801017dd:	c7 04 24 0b 91 10 80 	movl   $0x8010910b,(%esp)
801017e4:	e8 51 ed ff ff       	call   8010053a <panic>
}
801017e9:	c9                   	leave  
801017ea:	c3                   	ret    

801017eb <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801017eb:	55                   	push   %ebp
801017ec:	89 e5                	mov    %esp,%ebp
801017ee:	53                   	push   %ebx
801017ef:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801017f2:	8b 45 08             	mov    0x8(%ebp),%eax
801017f5:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801017f9:	84 c0                	test   %al,%al
801017fb:	75 0a                	jne    80101807 <filewrite+0x1c>
    return -1;
801017fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101802:	e9 20 01 00 00       	jmp    80101927 <filewrite+0x13c>
  if(f->type == FD_PIPE)
80101807:	8b 45 08             	mov    0x8(%ebp),%eax
8010180a:	8b 00                	mov    (%eax),%eax
8010180c:	83 f8 01             	cmp    $0x1,%eax
8010180f:	75 21                	jne    80101832 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
80101811:	8b 45 08             	mov    0x8(%ebp),%eax
80101814:	8b 40 0c             	mov    0xc(%eax),%eax
80101817:	8b 55 10             	mov    0x10(%ebp),%edx
8010181a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010181e:	8b 55 0c             	mov    0xc(%ebp),%edx
80101821:	89 54 24 04          	mov    %edx,0x4(%esp)
80101825:	89 04 24             	mov    %eax,(%esp)
80101828:	e8 91 2f 00 00       	call   801047be <pipewrite>
8010182d:	e9 f5 00 00 00       	jmp    80101927 <filewrite+0x13c>
  if(f->type == FD_INODE){
80101832:	8b 45 08             	mov    0x8(%ebp),%eax
80101835:	8b 00                	mov    (%eax),%eax
80101837:	83 f8 02             	cmp    $0x2,%eax
8010183a:	0f 85 db 00 00 00    	jne    8010191b <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101840:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
80101847:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
8010184e:	e9 a8 00 00 00       	jmp    801018fb <filewrite+0x110>
      int n1 = n - i;
80101853:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101856:	8b 55 10             	mov    0x10(%ebp),%edx
80101859:	29 c2                	sub    %eax,%edx
8010185b:	89 d0                	mov    %edx,%eax
8010185d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101860:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101863:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101866:	7e 06                	jle    8010186e <filewrite+0x83>
        n1 = max;
80101868:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010186b:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
8010186e:	e8 6a 22 00 00       	call   80103add <begin_op>
      ilock(f->ip);
80101873:	8b 45 08             	mov    0x8(%ebp),%eax
80101876:	8b 40 10             	mov    0x10(%eax),%eax
80101879:	89 04 24             	mov    %eax,(%esp)
8010187c:	e8 74 06 00 00       	call   80101ef5 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101881:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101884:	8b 45 08             	mov    0x8(%ebp),%eax
80101887:	8b 50 14             	mov    0x14(%eax),%edx
8010188a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
8010188d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101890:	01 c3                	add    %eax,%ebx
80101892:	8b 45 08             	mov    0x8(%ebp),%eax
80101895:	8b 40 10             	mov    0x10(%eax),%eax
80101898:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010189c:	89 54 24 08          	mov    %edx,0x8(%esp)
801018a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
801018a4:	89 04 24             	mov    %eax,(%esp)
801018a7:	e8 c0 0c 00 00       	call   8010256c <writei>
801018ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
801018af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801018b3:	7e 11                	jle    801018c6 <filewrite+0xdb>
        f->off += r;
801018b5:	8b 45 08             	mov    0x8(%ebp),%eax
801018b8:	8b 50 14             	mov    0x14(%eax),%edx
801018bb:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018be:	01 c2                	add    %eax,%edx
801018c0:	8b 45 08             	mov    0x8(%ebp),%eax
801018c3:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801018c6:	8b 45 08             	mov    0x8(%ebp),%eax
801018c9:	8b 40 10             	mov    0x10(%eax),%eax
801018cc:	89 04 24             	mov    %eax,(%esp)
801018cf:	e8 75 07 00 00       	call   80102049 <iunlock>
      end_op();
801018d4:	e8 88 22 00 00       	call   80103b61 <end_op>

      if(r < 0)
801018d9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801018dd:	79 02                	jns    801018e1 <filewrite+0xf6>
        break;
801018df:	eb 26                	jmp    80101907 <filewrite+0x11c>
      if(r != n1)
801018e1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018e4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801018e7:	74 0c                	je     801018f5 <filewrite+0x10a>
        panic("short filewrite");
801018e9:	c7 04 24 14 91 10 80 	movl   $0x80109114,(%esp)
801018f0:	e8 45 ec ff ff       	call   8010053a <panic>
      i += r;
801018f5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018f8:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801018fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018fe:	3b 45 10             	cmp    0x10(%ebp),%eax
80101901:	0f 8c 4c ff ff ff    	jl     80101853 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
80101907:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010190a:	3b 45 10             	cmp    0x10(%ebp),%eax
8010190d:	75 05                	jne    80101914 <filewrite+0x129>
8010190f:	8b 45 10             	mov    0x10(%ebp),%eax
80101912:	eb 05                	jmp    80101919 <filewrite+0x12e>
80101914:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101919:	eb 0c                	jmp    80101927 <filewrite+0x13c>
  }
  panic("filewrite");
8010191b:	c7 04 24 24 91 10 80 	movl   $0x80109124,(%esp)
80101922:	e8 13 ec ff ff       	call   8010053a <panic>
}
80101927:	83 c4 24             	add    $0x24,%esp
8010192a:	5b                   	pop    %ebx
8010192b:	5d                   	pop    %ebp
8010192c:	c3                   	ret    

8010192d <readsb>:
struct superblock sb;   // there should be one per dev, but we run with one dev

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
8010192d:	55                   	push   %ebp
8010192e:	89 e5                	mov    %esp,%ebp
80101930:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101933:	8b 45 08             	mov    0x8(%ebp),%eax
80101936:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010193d:	00 
8010193e:	89 04 24             	mov    %eax,(%esp)
80101941:	e8 60 e8 ff ff       	call   801001a6 <bread>
80101946:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101949:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010194c:	83 c0 18             	add    $0x18,%eax
8010194f:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
80101956:	00 
80101957:	89 44 24 04          	mov    %eax,0x4(%esp)
8010195b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010195e:	89 04 24             	mov    %eax,(%esp)
80101961:	e8 e5 43 00 00       	call   80105d4b <memmove>
  brelse(bp);
80101966:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101969:	89 04 24             	mov    %eax,(%esp)
8010196c:	e8 a6 e8 ff ff       	call   80100217 <brelse>
}
80101971:	c9                   	leave  
80101972:	c3                   	ret    

80101973 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101973:	55                   	push   %ebp
80101974:	89 e5                	mov    %esp,%ebp
80101976:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101979:	8b 55 0c             	mov    0xc(%ebp),%edx
8010197c:	8b 45 08             	mov    0x8(%ebp),%eax
8010197f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101983:	89 04 24             	mov    %eax,(%esp)
80101986:	e8 1b e8 ff ff       	call   801001a6 <bread>
8010198b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
8010198e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101991:	83 c0 18             	add    $0x18,%eax
80101994:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010199b:	00 
8010199c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801019a3:	00 
801019a4:	89 04 24             	mov    %eax,(%esp)
801019a7:	e8 d0 42 00 00       	call   80105c7c <memset>
  log_write(bp);
801019ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019af:	89 04 24             	mov    %eax,(%esp)
801019b2:	e8 31 23 00 00       	call   80103ce8 <log_write>
  brelse(bp);
801019b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019ba:	89 04 24             	mov    %eax,(%esp)
801019bd:	e8 55 e8 ff ff       	call   80100217 <brelse>
}
801019c2:	c9                   	leave  
801019c3:	c3                   	ret    

801019c4 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801019c4:	55                   	push   %ebp
801019c5:	89 e5                	mov    %esp,%ebp
801019c7:	83 ec 28             	sub    $0x28,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
801019ca:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
801019d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801019d8:	e9 07 01 00 00       	jmp    80101ae4 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
801019dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019e0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801019e6:	85 c0                	test   %eax,%eax
801019e8:	0f 48 c2             	cmovs  %edx,%eax
801019eb:	c1 f8 0c             	sar    $0xc,%eax
801019ee:	89 c2                	mov    %eax,%edx
801019f0:	a1 b8 2a 11 80       	mov    0x80112ab8,%eax
801019f5:	01 d0                	add    %edx,%eax
801019f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801019fb:	8b 45 08             	mov    0x8(%ebp),%eax
801019fe:	89 04 24             	mov    %eax,(%esp)
80101a01:	e8 a0 e7 ff ff       	call   801001a6 <bread>
80101a06:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101a09:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101a10:	e9 9d 00 00 00       	jmp    80101ab2 <balloc+0xee>
      m = 1 << (bi % 8);
80101a15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a18:	99                   	cltd   
80101a19:	c1 ea 1d             	shr    $0x1d,%edx
80101a1c:	01 d0                	add    %edx,%eax
80101a1e:	83 e0 07             	and    $0x7,%eax
80101a21:	29 d0                	sub    %edx,%eax
80101a23:	ba 01 00 00 00       	mov    $0x1,%edx
80101a28:	89 c1                	mov    %eax,%ecx
80101a2a:	d3 e2                	shl    %cl,%edx
80101a2c:	89 d0                	mov    %edx,%eax
80101a2e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101a31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a34:	8d 50 07             	lea    0x7(%eax),%edx
80101a37:	85 c0                	test   %eax,%eax
80101a39:	0f 48 c2             	cmovs  %edx,%eax
80101a3c:	c1 f8 03             	sar    $0x3,%eax
80101a3f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101a42:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101a47:	0f b6 c0             	movzbl %al,%eax
80101a4a:	23 45 e8             	and    -0x18(%ebp),%eax
80101a4d:	85 c0                	test   %eax,%eax
80101a4f:	75 5d                	jne    80101aae <balloc+0xea>
        bp->data[bi/8] |= m;  // Mark block in use.
80101a51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a54:	8d 50 07             	lea    0x7(%eax),%edx
80101a57:	85 c0                	test   %eax,%eax
80101a59:	0f 48 c2             	cmovs  %edx,%eax
80101a5c:	c1 f8 03             	sar    $0x3,%eax
80101a5f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101a62:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101a67:	89 d1                	mov    %edx,%ecx
80101a69:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101a6c:	09 ca                	or     %ecx,%edx
80101a6e:	89 d1                	mov    %edx,%ecx
80101a70:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101a73:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101a77:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101a7a:	89 04 24             	mov    %eax,(%esp)
80101a7d:	e8 66 22 00 00       	call   80103ce8 <log_write>
        brelse(bp);
80101a82:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101a85:	89 04 24             	mov    %eax,(%esp)
80101a88:	e8 8a e7 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a90:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101a93:	01 c2                	add    %eax,%edx
80101a95:	8b 45 08             	mov    0x8(%ebp),%eax
80101a98:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a9c:	89 04 24             	mov    %eax,(%esp)
80101a9f:	e8 cf fe ff ff       	call   80101973 <bzero>
        return b + bi;
80101aa4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aa7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101aaa:	01 d0                	add    %edx,%eax
80101aac:	eb 52                	jmp    80101b00 <balloc+0x13c>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101aae:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101ab2:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101ab9:	7f 17                	jg     80101ad2 <balloc+0x10e>
80101abb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101abe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ac1:	01 d0                	add    %edx,%eax
80101ac3:	89 c2                	mov    %eax,%edx
80101ac5:	a1 a0 2a 11 80       	mov    0x80112aa0,%eax
80101aca:	39 c2                	cmp    %eax,%edx
80101acc:	0f 82 43 ff ff ff    	jb     80101a15 <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101ad2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ad5:	89 04 24             	mov    %eax,(%esp)
80101ad8:	e8 3a e7 ff ff       	call   80100217 <brelse>
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
80101add:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101ae4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ae7:	a1 a0 2a 11 80       	mov    0x80112aa0,%eax
80101aec:	39 c2                	cmp    %eax,%edx
80101aee:	0f 82 e9 fe ff ff    	jb     801019dd <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101af4:	c7 04 24 30 91 10 80 	movl   $0x80109130,(%esp)
80101afb:	e8 3a ea ff ff       	call   8010053a <panic>
}
80101b00:	c9                   	leave  
80101b01:	c3                   	ret    

80101b02 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101b02:	55                   	push   %ebp
80101b03:	89 e5                	mov    %esp,%ebp
80101b05:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
80101b08:	c7 44 24 04 a0 2a 11 	movl   $0x80112aa0,0x4(%esp)
80101b0f:	80 
80101b10:	8b 45 08             	mov    0x8(%ebp),%eax
80101b13:	89 04 24             	mov    %eax,(%esp)
80101b16:	e8 12 fe ff ff       	call   8010192d <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101b1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101b1e:	c1 e8 0c             	shr    $0xc,%eax
80101b21:	89 c2                	mov    %eax,%edx
80101b23:	a1 b8 2a 11 80       	mov    0x80112ab8,%eax
80101b28:	01 c2                	add    %eax,%edx
80101b2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b31:	89 04 24             	mov    %eax,(%esp)
80101b34:	e8 6d e6 ff ff       	call   801001a6 <bread>
80101b39:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101b3c:	8b 45 0c             	mov    0xc(%ebp),%eax
80101b3f:	25 ff 0f 00 00       	and    $0xfff,%eax
80101b44:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101b47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b4a:	99                   	cltd   
80101b4b:	c1 ea 1d             	shr    $0x1d,%edx
80101b4e:	01 d0                	add    %edx,%eax
80101b50:	83 e0 07             	and    $0x7,%eax
80101b53:	29 d0                	sub    %edx,%eax
80101b55:	ba 01 00 00 00       	mov    $0x1,%edx
80101b5a:	89 c1                	mov    %eax,%ecx
80101b5c:	d3 e2                	shl    %cl,%edx
80101b5e:	89 d0                	mov    %edx,%eax
80101b60:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101b63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b66:	8d 50 07             	lea    0x7(%eax),%edx
80101b69:	85 c0                	test   %eax,%eax
80101b6b:	0f 48 c2             	cmovs  %edx,%eax
80101b6e:	c1 f8 03             	sar    $0x3,%eax
80101b71:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b74:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101b79:	0f b6 c0             	movzbl %al,%eax
80101b7c:	23 45 ec             	and    -0x14(%ebp),%eax
80101b7f:	85 c0                	test   %eax,%eax
80101b81:	75 0c                	jne    80101b8f <bfree+0x8d>
    panic("freeing free block");
80101b83:	c7 04 24 46 91 10 80 	movl   $0x80109146,(%esp)
80101b8a:	e8 ab e9 ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101b8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b92:	8d 50 07             	lea    0x7(%eax),%edx
80101b95:	85 c0                	test   %eax,%eax
80101b97:	0f 48 c2             	cmovs  %edx,%eax
80101b9a:	c1 f8 03             	sar    $0x3,%eax
80101b9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ba0:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101ba5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101ba8:	f7 d1                	not    %ecx
80101baa:	21 ca                	and    %ecx,%edx
80101bac:	89 d1                	mov    %edx,%ecx
80101bae:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bb1:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101bb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bb8:	89 04 24             	mov    %eax,(%esp)
80101bbb:	e8 28 21 00 00       	call   80103ce8 <log_write>
  brelse(bp);
80101bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bc3:	89 04 24             	mov    %eax,(%esp)
80101bc6:	e8 4c e6 ff ff       	call   80100217 <brelse>
}
80101bcb:	c9                   	leave  
80101bcc:	c3                   	ret    

80101bcd <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
80101bcd:	55                   	push   %ebp
80101bce:	89 e5                	mov    %esp,%ebp
80101bd0:	57                   	push   %edi
80101bd1:	56                   	push   %esi
80101bd2:	53                   	push   %ebx
80101bd3:	83 ec 3c             	sub    $0x3c,%esp
  initlock(&icache.lock, "icache");
80101bd6:	c7 44 24 04 59 91 10 	movl   $0x80109159,0x4(%esp)
80101bdd:	80 
80101bde:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80101be5:	e8 1d 3e 00 00       	call   80105a07 <initlock>
  readsb(dev, &sb);
80101bea:	c7 44 24 04 a0 2a 11 	movl   $0x80112aa0,0x4(%esp)
80101bf1:	80 
80101bf2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf5:	89 04 24             	mov    %eax,(%esp)
80101bf8:	e8 30 fd ff ff       	call   8010192d <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d inodestart %d bmap start %d\n", sb.size,
80101bfd:	a1 b8 2a 11 80       	mov    0x80112ab8,%eax
80101c02:	8b 3d b4 2a 11 80    	mov    0x80112ab4,%edi
80101c08:	8b 35 b0 2a 11 80    	mov    0x80112ab0,%esi
80101c0e:	8b 1d ac 2a 11 80    	mov    0x80112aac,%ebx
80101c14:	8b 0d a8 2a 11 80    	mov    0x80112aa8,%ecx
80101c1a:	8b 15 a4 2a 11 80    	mov    0x80112aa4,%edx
80101c20:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101c23:	8b 15 a0 2a 11 80    	mov    0x80112aa0,%edx
80101c29:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101c2d:	89 7c 24 18          	mov    %edi,0x18(%esp)
80101c31:	89 74 24 14          	mov    %esi,0x14(%esp)
80101c35:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80101c39:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101c3d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101c40:	89 44 24 08          	mov    %eax,0x8(%esp)
80101c44:	89 d0                	mov    %edx,%eax
80101c46:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c4a:	c7 04 24 60 91 10 80 	movl   $0x80109160,(%esp)
80101c51:	e8 4a e7 ff ff       	call   801003a0 <cprintf>
          sb.nblocks, sb.ninodes, sb.nlog, sb.logstart, sb.inodestart, sb.bmapstart);
}
80101c56:	83 c4 3c             	add    $0x3c,%esp
80101c59:	5b                   	pop    %ebx
80101c5a:	5e                   	pop    %esi
80101c5b:	5f                   	pop    %edi
80101c5c:	5d                   	pop    %ebp
80101c5d:	c3                   	ret    

80101c5e <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101c5e:	55                   	push   %ebp
80101c5f:	89 e5                	mov    %esp,%ebp
80101c61:	83 ec 28             	sub    $0x28,%esp
80101c64:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c67:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101c6b:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101c72:	e9 9e 00 00 00       	jmp    80101d15 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
80101c77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c7a:	c1 e8 03             	shr    $0x3,%eax
80101c7d:	89 c2                	mov    %eax,%edx
80101c7f:	a1 b4 2a 11 80       	mov    0x80112ab4,%eax
80101c84:	01 d0                	add    %edx,%eax
80101c86:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8d:	89 04 24             	mov    %eax,(%esp)
80101c90:	e8 11 e5 ff ff       	call   801001a6 <bread>
80101c95:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101c98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c9b:	8d 50 18             	lea    0x18(%eax),%edx
80101c9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ca1:	83 e0 07             	and    $0x7,%eax
80101ca4:	c1 e0 06             	shl    $0x6,%eax
80101ca7:	01 d0                	add    %edx,%eax
80101ca9:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101cac:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101caf:	0f b7 00             	movzwl (%eax),%eax
80101cb2:	66 85 c0             	test   %ax,%ax
80101cb5:	75 4f                	jne    80101d06 <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
80101cb7:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101cbe:	00 
80101cbf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101cc6:	00 
80101cc7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cca:	89 04 24             	mov    %eax,(%esp)
80101ccd:	e8 aa 3f 00 00       	call   80105c7c <memset>
      dip->type = type;
80101cd2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cd5:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
80101cd9:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101cdc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cdf:	89 04 24             	mov    %eax,(%esp)
80101ce2:	e8 01 20 00 00       	call   80103ce8 <log_write>
      brelse(bp);
80101ce7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cea:	89 04 24             	mov    %eax,(%esp)
80101ced:	e8 25 e5 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cf5:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cf9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cfc:	89 04 24             	mov    %eax,(%esp)
80101cff:	e8 ed 00 00 00       	call   80101df1 <iget>
80101d04:	eb 2b                	jmp    80101d31 <ialloc+0xd3>
    }
    brelse(bp);
80101d06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d09:	89 04 24             	mov    %eax,(%esp)
80101d0c:	e8 06 e5 ff ff       	call   80100217 <brelse>
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101d11:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d15:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d18:	a1 a8 2a 11 80       	mov    0x80112aa8,%eax
80101d1d:	39 c2                	cmp    %eax,%edx
80101d1f:	0f 82 52 ff ff ff    	jb     80101c77 <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101d25:	c7 04 24 b3 91 10 80 	movl   $0x801091b3,(%esp)
80101d2c:	e8 09 e8 ff ff       	call   8010053a <panic>
}
80101d31:	c9                   	leave  
80101d32:	c3                   	ret    

80101d33 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101d33:	55                   	push   %ebp
80101d34:	89 e5                	mov    %esp,%ebp
80101d36:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101d39:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3c:	8b 40 04             	mov    0x4(%eax),%eax
80101d3f:	c1 e8 03             	shr    $0x3,%eax
80101d42:	89 c2                	mov    %eax,%edx
80101d44:	a1 b4 2a 11 80       	mov    0x80112ab4,%eax
80101d49:	01 c2                	add    %eax,%edx
80101d4b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4e:	8b 00                	mov    (%eax),%eax
80101d50:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d54:	89 04 24             	mov    %eax,(%esp)
80101d57:	e8 4a e4 ff ff       	call   801001a6 <bread>
80101d5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101d5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d62:	8d 50 18             	lea    0x18(%eax),%edx
80101d65:	8b 45 08             	mov    0x8(%ebp),%eax
80101d68:	8b 40 04             	mov    0x4(%eax),%eax
80101d6b:	83 e0 07             	and    $0x7,%eax
80101d6e:	c1 e0 06             	shl    $0x6,%eax
80101d71:	01 d0                	add    %edx,%eax
80101d73:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101d76:	8b 45 08             	mov    0x8(%ebp),%eax
80101d79:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d80:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101d83:	8b 45 08             	mov    0x8(%ebp),%eax
80101d86:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101d8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d8d:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101d91:	8b 45 08             	mov    0x8(%ebp),%eax
80101d94:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101d98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d9b:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101d9f:	8b 45 08             	mov    0x8(%ebp),%eax
80101da2:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101da6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101da9:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101dad:	8b 45 08             	mov    0x8(%ebp),%eax
80101db0:	8b 50 18             	mov    0x18(%eax),%edx
80101db3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101db6:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101db9:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbc:	8d 50 1c             	lea    0x1c(%eax),%edx
80101dbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101dc2:	83 c0 0c             	add    $0xc,%eax
80101dc5:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101dcc:	00 
80101dcd:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dd1:	89 04 24             	mov    %eax,(%esp)
80101dd4:	e8 72 3f 00 00       	call   80105d4b <memmove>
  log_write(bp);
80101dd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ddc:	89 04 24             	mov    %eax,(%esp)
80101ddf:	e8 04 1f 00 00       	call   80103ce8 <log_write>
  brelse(bp);
80101de4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101de7:	89 04 24             	mov    %eax,(%esp)
80101dea:	e8 28 e4 ff ff       	call   80100217 <brelse>
}
80101def:	c9                   	leave  
80101df0:	c3                   	ret    

80101df1 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101df1:	55                   	push   %ebp
80101df2:	89 e5                	mov    %esp,%ebp
80101df4:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101df7:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80101dfe:	e8 25 3c 00 00       	call   80105a28 <acquire>

  // Is the inode already cached?
  empty = 0;
80101e03:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101e0a:	c7 45 f4 f4 2a 11 80 	movl   $0x80112af4,-0xc(%ebp)
80101e11:	eb 59                	jmp    80101e6c <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101e13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e16:	8b 40 08             	mov    0x8(%eax),%eax
80101e19:	85 c0                	test   %eax,%eax
80101e1b:	7e 35                	jle    80101e52 <iget+0x61>
80101e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e20:	8b 00                	mov    (%eax),%eax
80101e22:	3b 45 08             	cmp    0x8(%ebp),%eax
80101e25:	75 2b                	jne    80101e52 <iget+0x61>
80101e27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e2a:	8b 40 04             	mov    0x4(%eax),%eax
80101e2d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101e30:	75 20                	jne    80101e52 <iget+0x61>
      ip->ref++;
80101e32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e35:	8b 40 08             	mov    0x8(%eax),%eax
80101e38:	8d 50 01             	lea    0x1(%eax),%edx
80101e3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e3e:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101e41:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80101e48:	e8 3d 3c 00 00       	call   80105a8a <release>
      return ip;
80101e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e50:	eb 6f                	jmp    80101ec1 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101e52:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101e56:	75 10                	jne    80101e68 <iget+0x77>
80101e58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e5b:	8b 40 08             	mov    0x8(%eax),%eax
80101e5e:	85 c0                	test   %eax,%eax
80101e60:	75 06                	jne    80101e68 <iget+0x77>
      empty = ip;
80101e62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e65:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101e68:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101e6c:	81 7d f4 94 3a 11 80 	cmpl   $0x80113a94,-0xc(%ebp)
80101e73:	72 9e                	jb     80101e13 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101e75:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101e79:	75 0c                	jne    80101e87 <iget+0x96>
    panic("iget: no inodes");
80101e7b:	c7 04 24 c5 91 10 80 	movl   $0x801091c5,(%esp)
80101e82:	e8 b3 e6 ff ff       	call   8010053a <panic>

  ip = empty;
80101e87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101e8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e90:	8b 55 08             	mov    0x8(%ebp),%edx
80101e93:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101e95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e98:	8b 55 0c             	mov    0xc(%ebp),%edx
80101e9b:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101e9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ea1:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101ea8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101eab:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101eb2:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80101eb9:	e8 cc 3b 00 00       	call   80105a8a <release>

  return ip;
80101ebe:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101ec1:	c9                   	leave  
80101ec2:	c3                   	ret    

80101ec3 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101ec3:	55                   	push   %ebp
80101ec4:	89 e5                	mov    %esp,%ebp
80101ec6:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101ec9:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80101ed0:	e8 53 3b 00 00       	call   80105a28 <acquire>
  ip->ref++;
80101ed5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed8:	8b 40 08             	mov    0x8(%eax),%eax
80101edb:	8d 50 01             	lea    0x1(%eax),%edx
80101ede:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee1:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ee4:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80101eeb:	e8 9a 3b 00 00       	call   80105a8a <release>
  return ip;
80101ef0:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101ef3:	c9                   	leave  
80101ef4:	c3                   	ret    

80101ef5 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101ef5:	55                   	push   %ebp
80101ef6:	89 e5                	mov    %esp,%ebp
80101ef8:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101efb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101eff:	74 0a                	je     80101f0b <ilock+0x16>
80101f01:	8b 45 08             	mov    0x8(%ebp),%eax
80101f04:	8b 40 08             	mov    0x8(%eax),%eax
80101f07:	85 c0                	test   %eax,%eax
80101f09:	7f 0c                	jg     80101f17 <ilock+0x22>
    panic("ilock");
80101f0b:	c7 04 24 d5 91 10 80 	movl   $0x801091d5,(%esp)
80101f12:	e8 23 e6 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101f17:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80101f1e:	e8 05 3b 00 00       	call   80105a28 <acquire>
  while(ip->flags & I_BUSY)
80101f23:	eb 13                	jmp    80101f38 <ilock+0x43>
    sleep(ip, &icache.lock);
80101f25:	c7 44 24 04 c0 2a 11 	movl   $0x80112ac0,0x4(%esp)
80101f2c:	80 
80101f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f30:	89 04 24             	mov    %eax,(%esp)
80101f33:	e8 fa 37 00 00       	call   80105732 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101f38:	8b 45 08             	mov    0x8(%ebp),%eax
80101f3b:	8b 40 0c             	mov    0xc(%eax),%eax
80101f3e:	83 e0 01             	and    $0x1,%eax
80101f41:	85 c0                	test   %eax,%eax
80101f43:	75 e0                	jne    80101f25 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101f45:	8b 45 08             	mov    0x8(%ebp),%eax
80101f48:	8b 40 0c             	mov    0xc(%eax),%eax
80101f4b:	83 c8 01             	or     $0x1,%eax
80101f4e:	89 c2                	mov    %eax,%edx
80101f50:	8b 45 08             	mov    0x8(%ebp),%eax
80101f53:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101f56:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80101f5d:	e8 28 3b 00 00       	call   80105a8a <release>

  if(!(ip->flags & I_VALID)){
80101f62:	8b 45 08             	mov    0x8(%ebp),%eax
80101f65:	8b 40 0c             	mov    0xc(%eax),%eax
80101f68:	83 e0 02             	and    $0x2,%eax
80101f6b:	85 c0                	test   %eax,%eax
80101f6d:	0f 85 d4 00 00 00    	jne    80102047 <ilock+0x152>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101f73:	8b 45 08             	mov    0x8(%ebp),%eax
80101f76:	8b 40 04             	mov    0x4(%eax),%eax
80101f79:	c1 e8 03             	shr    $0x3,%eax
80101f7c:	89 c2                	mov    %eax,%edx
80101f7e:	a1 b4 2a 11 80       	mov    0x80112ab4,%eax
80101f83:	01 c2                	add    %eax,%edx
80101f85:	8b 45 08             	mov    0x8(%ebp),%eax
80101f88:	8b 00                	mov    (%eax),%eax
80101f8a:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f8e:	89 04 24             	mov    %eax,(%esp)
80101f91:	e8 10 e2 ff ff       	call   801001a6 <bread>
80101f96:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101f99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f9c:	8d 50 18             	lea    0x18(%eax),%edx
80101f9f:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa2:	8b 40 04             	mov    0x4(%eax),%eax
80101fa5:	83 e0 07             	and    $0x7,%eax
80101fa8:	c1 e0 06             	shl    $0x6,%eax
80101fab:	01 d0                	add    %edx,%eax
80101fad:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101fb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fb3:	0f b7 10             	movzwl (%eax),%edx
80101fb6:	8b 45 08             	mov    0x8(%ebp),%eax
80101fb9:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101fbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fc0:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101fc4:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc7:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101fcb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fce:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101fd2:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd5:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101fd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fdc:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe3:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101fe7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fea:	8b 50 08             	mov    0x8(%eax),%edx
80101fed:	8b 45 08             	mov    0x8(%ebp),%eax
80101ff0:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101ff3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ff6:	8d 50 0c             	lea    0xc(%eax),%edx
80101ff9:	8b 45 08             	mov    0x8(%ebp),%eax
80101ffc:	83 c0 1c             	add    $0x1c,%eax
80101fff:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80102006:	00 
80102007:	89 54 24 04          	mov    %edx,0x4(%esp)
8010200b:	89 04 24             	mov    %eax,(%esp)
8010200e:	e8 38 3d 00 00       	call   80105d4b <memmove>
    brelse(bp);
80102013:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102016:	89 04 24             	mov    %eax,(%esp)
80102019:	e8 f9 e1 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010201e:	8b 45 08             	mov    0x8(%ebp),%eax
80102021:	8b 40 0c             	mov    0xc(%eax),%eax
80102024:	83 c8 02             	or     $0x2,%eax
80102027:	89 c2                	mov    %eax,%edx
80102029:	8b 45 08             	mov    0x8(%ebp),%eax
8010202c:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
8010202f:	8b 45 08             	mov    0x8(%ebp),%eax
80102032:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102036:	66 85 c0             	test   %ax,%ax
80102039:	75 0c                	jne    80102047 <ilock+0x152>
      panic("ilock: no type");
8010203b:	c7 04 24 db 91 10 80 	movl   $0x801091db,(%esp)
80102042:	e8 f3 e4 ff ff       	call   8010053a <panic>
  }
}
80102047:	c9                   	leave  
80102048:	c3                   	ret    

80102049 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80102049:	55                   	push   %ebp
8010204a:	89 e5                	mov    %esp,%ebp
8010204c:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
8010204f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102053:	74 17                	je     8010206c <iunlock+0x23>
80102055:	8b 45 08             	mov    0x8(%ebp),%eax
80102058:	8b 40 0c             	mov    0xc(%eax),%eax
8010205b:	83 e0 01             	and    $0x1,%eax
8010205e:	85 c0                	test   %eax,%eax
80102060:	74 0a                	je     8010206c <iunlock+0x23>
80102062:	8b 45 08             	mov    0x8(%ebp),%eax
80102065:	8b 40 08             	mov    0x8(%eax),%eax
80102068:	85 c0                	test   %eax,%eax
8010206a:	7f 0c                	jg     80102078 <iunlock+0x2f>
    panic("iunlock");
8010206c:	c7 04 24 ea 91 10 80 	movl   $0x801091ea,(%esp)
80102073:	e8 c2 e4 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80102078:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
8010207f:	e8 a4 39 00 00       	call   80105a28 <acquire>
  ip->flags &= ~I_BUSY;
80102084:	8b 45 08             	mov    0x8(%ebp),%eax
80102087:	8b 40 0c             	mov    0xc(%eax),%eax
8010208a:	83 e0 fe             	and    $0xfffffffe,%eax
8010208d:	89 c2                	mov    %eax,%edx
8010208f:	8b 45 08             	mov    0x8(%ebp),%eax
80102092:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80102095:	8b 45 08             	mov    0x8(%ebp),%eax
80102098:	89 04 24             	mov    %eax,(%esp)
8010209b:	e8 86 37 00 00       	call   80105826 <wakeup>
  release(&icache.lock);
801020a0:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
801020a7:	e8 de 39 00 00       	call   80105a8a <release>
}
801020ac:	c9                   	leave  
801020ad:	c3                   	ret    

801020ae <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
801020ae:	55                   	push   %ebp
801020af:	89 e5                	mov    %esp,%ebp
801020b1:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801020b4:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
801020bb:	e8 68 39 00 00       	call   80105a28 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
801020c0:	8b 45 08             	mov    0x8(%ebp),%eax
801020c3:	8b 40 08             	mov    0x8(%eax),%eax
801020c6:	83 f8 01             	cmp    $0x1,%eax
801020c9:	0f 85 93 00 00 00    	jne    80102162 <iput+0xb4>
801020cf:	8b 45 08             	mov    0x8(%ebp),%eax
801020d2:	8b 40 0c             	mov    0xc(%eax),%eax
801020d5:	83 e0 02             	and    $0x2,%eax
801020d8:	85 c0                	test   %eax,%eax
801020da:	0f 84 82 00 00 00    	je     80102162 <iput+0xb4>
801020e0:	8b 45 08             	mov    0x8(%ebp),%eax
801020e3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801020e7:	66 85 c0             	test   %ax,%ax
801020ea:	75 76                	jne    80102162 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
801020ec:	8b 45 08             	mov    0x8(%ebp),%eax
801020ef:	8b 40 0c             	mov    0xc(%eax),%eax
801020f2:	83 e0 01             	and    $0x1,%eax
801020f5:	85 c0                	test   %eax,%eax
801020f7:	74 0c                	je     80102105 <iput+0x57>
      panic("iput busy");
801020f9:	c7 04 24 f2 91 10 80 	movl   $0x801091f2,(%esp)
80102100:	e8 35 e4 ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80102105:	8b 45 08             	mov    0x8(%ebp),%eax
80102108:	8b 40 0c             	mov    0xc(%eax),%eax
8010210b:	83 c8 01             	or     $0x1,%eax
8010210e:	89 c2                	mov    %eax,%edx
80102110:	8b 45 08             	mov    0x8(%ebp),%eax
80102113:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80102116:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
8010211d:	e8 68 39 00 00       	call   80105a8a <release>
    itrunc(ip);
80102122:	8b 45 08             	mov    0x8(%ebp),%eax
80102125:	89 04 24             	mov    %eax,(%esp)
80102128:	e8 7d 01 00 00       	call   801022aa <itrunc>
    ip->type = 0;
8010212d:	8b 45 08             	mov    0x8(%ebp),%eax
80102130:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80102136:	8b 45 08             	mov    0x8(%ebp),%eax
80102139:	89 04 24             	mov    %eax,(%esp)
8010213c:	e8 f2 fb ff ff       	call   80101d33 <iupdate>
    acquire(&icache.lock);
80102141:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80102148:	e8 db 38 00 00       	call   80105a28 <acquire>
    ip->flags = 0;
8010214d:	8b 45 08             	mov    0x8(%ebp),%eax
80102150:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102157:	8b 45 08             	mov    0x8(%ebp),%eax
8010215a:	89 04 24             	mov    %eax,(%esp)
8010215d:	e8 c4 36 00 00       	call   80105826 <wakeup>
  }
  ip->ref--;
80102162:	8b 45 08             	mov    0x8(%ebp),%eax
80102165:	8b 40 08             	mov    0x8(%eax),%eax
80102168:	8d 50 ff             	lea    -0x1(%eax),%edx
8010216b:	8b 45 08             	mov    0x8(%ebp),%eax
8010216e:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80102171:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80102178:	e8 0d 39 00 00       	call   80105a8a <release>
}
8010217d:	c9                   	leave  
8010217e:	c3                   	ret    

8010217f <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
8010217f:	55                   	push   %ebp
80102180:	89 e5                	mov    %esp,%ebp
80102182:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80102185:	8b 45 08             	mov    0x8(%ebp),%eax
80102188:	89 04 24             	mov    %eax,(%esp)
8010218b:	e8 b9 fe ff ff       	call   80102049 <iunlock>
  iput(ip);
80102190:	8b 45 08             	mov    0x8(%ebp),%eax
80102193:	89 04 24             	mov    %eax,(%esp)
80102196:	e8 13 ff ff ff       	call   801020ae <iput>
}
8010219b:	c9                   	leave  
8010219c:	c3                   	ret    

8010219d <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
8010219d:	55                   	push   %ebp
8010219e:	89 e5                	mov    %esp,%ebp
801021a0:	53                   	push   %ebx
801021a1:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
801021a4:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
801021a8:	77 3e                	ja     801021e8 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
801021aa:	8b 45 08             	mov    0x8(%ebp),%eax
801021ad:	8b 55 0c             	mov    0xc(%ebp),%edx
801021b0:	83 c2 04             	add    $0x4,%edx
801021b3:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801021b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801021be:	75 20                	jne    801021e0 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
801021c0:	8b 45 08             	mov    0x8(%ebp),%eax
801021c3:	8b 00                	mov    (%eax),%eax
801021c5:	89 04 24             	mov    %eax,(%esp)
801021c8:	e8 f7 f7 ff ff       	call   801019c4 <balloc>
801021cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021d0:	8b 45 08             	mov    0x8(%ebp),%eax
801021d3:	8b 55 0c             	mov    0xc(%ebp),%edx
801021d6:	8d 4a 04             	lea    0x4(%edx),%ecx
801021d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021dc:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801021e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021e3:	e9 bc 00 00 00       	jmp    801022a4 <bmap+0x107>
  }
  bn -= NDIRECT;
801021e8:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801021ec:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801021f0:	0f 87 a2 00 00 00    	ja     80102298 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
801021f6:	8b 45 08             	mov    0x8(%ebp),%eax
801021f9:	8b 40 4c             	mov    0x4c(%eax),%eax
801021fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021ff:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102203:	75 19                	jne    8010221e <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80102205:	8b 45 08             	mov    0x8(%ebp),%eax
80102208:	8b 00                	mov    (%eax),%eax
8010220a:	89 04 24             	mov    %eax,(%esp)
8010220d:	e8 b2 f7 ff ff       	call   801019c4 <balloc>
80102212:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102215:	8b 45 08             	mov    0x8(%ebp),%eax
80102218:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010221b:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
8010221e:	8b 45 08             	mov    0x8(%ebp),%eax
80102221:	8b 00                	mov    (%eax),%eax
80102223:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102226:	89 54 24 04          	mov    %edx,0x4(%esp)
8010222a:	89 04 24             	mov    %eax,(%esp)
8010222d:	e8 74 df ff ff       	call   801001a6 <bread>
80102232:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80102235:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102238:	83 c0 18             	add    $0x18,%eax
8010223b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
8010223e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102241:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102248:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010224b:	01 d0                	add    %edx,%eax
8010224d:	8b 00                	mov    (%eax),%eax
8010224f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102252:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102256:	75 30                	jne    80102288 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80102258:	8b 45 0c             	mov    0xc(%ebp),%eax
8010225b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102262:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102265:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80102268:	8b 45 08             	mov    0x8(%ebp),%eax
8010226b:	8b 00                	mov    (%eax),%eax
8010226d:	89 04 24             	mov    %eax,(%esp)
80102270:	e8 4f f7 ff ff       	call   801019c4 <balloc>
80102275:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102278:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010227b:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
8010227d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102280:	89 04 24             	mov    %eax,(%esp)
80102283:	e8 60 1a 00 00       	call   80103ce8 <log_write>
    }
    brelse(bp);
80102288:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010228b:	89 04 24             	mov    %eax,(%esp)
8010228e:	e8 84 df ff ff       	call   80100217 <brelse>
    return addr;
80102293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102296:	eb 0c                	jmp    801022a4 <bmap+0x107>
  }

  panic("bmap: out of range");
80102298:	c7 04 24 fc 91 10 80 	movl   $0x801091fc,(%esp)
8010229f:	e8 96 e2 ff ff       	call   8010053a <panic>
}
801022a4:	83 c4 24             	add    $0x24,%esp
801022a7:	5b                   	pop    %ebx
801022a8:	5d                   	pop    %ebp
801022a9:	c3                   	ret    

801022aa <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
801022aa:	55                   	push   %ebp
801022ab:	89 e5                	mov    %esp,%ebp
801022ad:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801022b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801022b7:	eb 44                	jmp    801022fd <itrunc+0x53>
    if(ip->addrs[i]){
801022b9:	8b 45 08             	mov    0x8(%ebp),%eax
801022bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022bf:	83 c2 04             	add    $0x4,%edx
801022c2:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801022c6:	85 c0                	test   %eax,%eax
801022c8:	74 2f                	je     801022f9 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
801022ca:	8b 45 08             	mov    0x8(%ebp),%eax
801022cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022d0:	83 c2 04             	add    $0x4,%edx
801022d3:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801022d7:	8b 45 08             	mov    0x8(%ebp),%eax
801022da:	8b 00                	mov    (%eax),%eax
801022dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801022e0:	89 04 24             	mov    %eax,(%esp)
801022e3:	e8 1a f8 ff ff       	call   80101b02 <bfree>
      ip->addrs[i] = 0;
801022e8:	8b 45 08             	mov    0x8(%ebp),%eax
801022eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022ee:	83 c2 04             	add    $0x4,%edx
801022f1:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801022f8:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801022f9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801022fd:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80102301:	7e b6                	jle    801022b9 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80102303:	8b 45 08             	mov    0x8(%ebp),%eax
80102306:	8b 40 4c             	mov    0x4c(%eax),%eax
80102309:	85 c0                	test   %eax,%eax
8010230b:	0f 84 9b 00 00 00    	je     801023ac <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80102311:	8b 45 08             	mov    0x8(%ebp),%eax
80102314:	8b 50 4c             	mov    0x4c(%eax),%edx
80102317:	8b 45 08             	mov    0x8(%ebp),%eax
8010231a:	8b 00                	mov    (%eax),%eax
8010231c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102320:	89 04 24             	mov    %eax,(%esp)
80102323:	e8 7e de ff ff       	call   801001a6 <bread>
80102328:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
8010232b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010232e:	83 c0 18             	add    $0x18,%eax
80102331:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102334:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010233b:	eb 3b                	jmp    80102378 <itrunc+0xce>
      if(a[j])
8010233d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102340:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102347:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010234a:	01 d0                	add    %edx,%eax
8010234c:	8b 00                	mov    (%eax),%eax
8010234e:	85 c0                	test   %eax,%eax
80102350:	74 22                	je     80102374 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80102352:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102355:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010235c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010235f:	01 d0                	add    %edx,%eax
80102361:	8b 10                	mov    (%eax),%edx
80102363:	8b 45 08             	mov    0x8(%ebp),%eax
80102366:	8b 00                	mov    (%eax),%eax
80102368:	89 54 24 04          	mov    %edx,0x4(%esp)
8010236c:	89 04 24             	mov    %eax,(%esp)
8010236f:	e8 8e f7 ff ff       	call   80101b02 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102374:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102378:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010237b:	83 f8 7f             	cmp    $0x7f,%eax
8010237e:	76 bd                	jbe    8010233d <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80102380:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102383:	89 04 24             	mov    %eax,(%esp)
80102386:	e8 8c de ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
8010238b:	8b 45 08             	mov    0x8(%ebp),%eax
8010238e:	8b 50 4c             	mov    0x4c(%eax),%edx
80102391:	8b 45 08             	mov    0x8(%ebp),%eax
80102394:	8b 00                	mov    (%eax),%eax
80102396:	89 54 24 04          	mov    %edx,0x4(%esp)
8010239a:	89 04 24             	mov    %eax,(%esp)
8010239d:	e8 60 f7 ff ff       	call   80101b02 <bfree>
    ip->addrs[NDIRECT] = 0;
801023a2:	8b 45 08             	mov    0x8(%ebp),%eax
801023a5:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
801023ac:	8b 45 08             	mov    0x8(%ebp),%eax
801023af:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
801023b6:	8b 45 08             	mov    0x8(%ebp),%eax
801023b9:	89 04 24             	mov    %eax,(%esp)
801023bc:	e8 72 f9 ff ff       	call   80101d33 <iupdate>
}
801023c1:	c9                   	leave  
801023c2:	c3                   	ret    

801023c3 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
801023c3:	55                   	push   %ebp
801023c4:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
801023c6:	8b 45 08             	mov    0x8(%ebp),%eax
801023c9:	8b 00                	mov    (%eax),%eax
801023cb:	89 c2                	mov    %eax,%edx
801023cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801023d0:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
801023d3:	8b 45 08             	mov    0x8(%ebp),%eax
801023d6:	8b 50 04             	mov    0x4(%eax),%edx
801023d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801023dc:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
801023df:	8b 45 08             	mov    0x8(%ebp),%eax
801023e2:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801023e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801023e9:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
801023ec:	8b 45 08             	mov    0x8(%ebp),%eax
801023ef:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801023f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801023f6:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
801023fa:	8b 45 08             	mov    0x8(%ebp),%eax
801023fd:	8b 50 18             	mov    0x18(%eax),%edx
80102400:	8b 45 0c             	mov    0xc(%ebp),%eax
80102403:	89 50 10             	mov    %edx,0x10(%eax)
}
80102406:	5d                   	pop    %ebp
80102407:	c3                   	ret    

80102408 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80102408:	55                   	push   %ebp
80102409:	89 e5                	mov    %esp,%ebp
8010240b:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
8010240e:	8b 45 08             	mov    0x8(%ebp),%eax
80102411:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102415:	66 83 f8 03          	cmp    $0x3,%ax
80102419:	75 60                	jne    8010247b <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
8010241b:	8b 45 08             	mov    0x8(%ebp),%eax
8010241e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102422:	66 85 c0             	test   %ax,%ax
80102425:	78 20                	js     80102447 <readi+0x3f>
80102427:	8b 45 08             	mov    0x8(%ebp),%eax
8010242a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010242e:	66 83 f8 09          	cmp    $0x9,%ax
80102432:	7f 13                	jg     80102447 <readi+0x3f>
80102434:	8b 45 08             	mov    0x8(%ebp),%eax
80102437:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010243b:	98                   	cwtl   
8010243c:	8b 04 c5 40 2a 11 80 	mov    -0x7feed5c0(,%eax,8),%eax
80102443:	85 c0                	test   %eax,%eax
80102445:	75 0a                	jne    80102451 <readi+0x49>
      return -1;
80102447:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010244c:	e9 19 01 00 00       	jmp    8010256a <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80102451:	8b 45 08             	mov    0x8(%ebp),%eax
80102454:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102458:	98                   	cwtl   
80102459:	8b 04 c5 40 2a 11 80 	mov    -0x7feed5c0(,%eax,8),%eax
80102460:	8b 55 14             	mov    0x14(%ebp),%edx
80102463:	89 54 24 08          	mov    %edx,0x8(%esp)
80102467:	8b 55 0c             	mov    0xc(%ebp),%edx
8010246a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010246e:	8b 55 08             	mov    0x8(%ebp),%edx
80102471:	89 14 24             	mov    %edx,(%esp)
80102474:	ff d0                	call   *%eax
80102476:	e9 ef 00 00 00       	jmp    8010256a <readi+0x162>
  }

  if(off > ip->size || off + n < off)
8010247b:	8b 45 08             	mov    0x8(%ebp),%eax
8010247e:	8b 40 18             	mov    0x18(%eax),%eax
80102481:	3b 45 10             	cmp    0x10(%ebp),%eax
80102484:	72 0d                	jb     80102493 <readi+0x8b>
80102486:	8b 45 14             	mov    0x14(%ebp),%eax
80102489:	8b 55 10             	mov    0x10(%ebp),%edx
8010248c:	01 d0                	add    %edx,%eax
8010248e:	3b 45 10             	cmp    0x10(%ebp),%eax
80102491:	73 0a                	jae    8010249d <readi+0x95>
    return -1;
80102493:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102498:	e9 cd 00 00 00       	jmp    8010256a <readi+0x162>
  if(off + n > ip->size)
8010249d:	8b 45 14             	mov    0x14(%ebp),%eax
801024a0:	8b 55 10             	mov    0x10(%ebp),%edx
801024a3:	01 c2                	add    %eax,%edx
801024a5:	8b 45 08             	mov    0x8(%ebp),%eax
801024a8:	8b 40 18             	mov    0x18(%eax),%eax
801024ab:	39 c2                	cmp    %eax,%edx
801024ad:	76 0c                	jbe    801024bb <readi+0xb3>
    n = ip->size - off;
801024af:	8b 45 08             	mov    0x8(%ebp),%eax
801024b2:	8b 40 18             	mov    0x18(%eax),%eax
801024b5:	2b 45 10             	sub    0x10(%ebp),%eax
801024b8:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801024bb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801024c2:	e9 94 00 00 00       	jmp    8010255b <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801024c7:	8b 45 10             	mov    0x10(%ebp),%eax
801024ca:	c1 e8 09             	shr    $0x9,%eax
801024cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801024d1:	8b 45 08             	mov    0x8(%ebp),%eax
801024d4:	89 04 24             	mov    %eax,(%esp)
801024d7:	e8 c1 fc ff ff       	call   8010219d <bmap>
801024dc:	8b 55 08             	mov    0x8(%ebp),%edx
801024df:	8b 12                	mov    (%edx),%edx
801024e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801024e5:	89 14 24             	mov    %edx,(%esp)
801024e8:	e8 b9 dc ff ff       	call   801001a6 <bread>
801024ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801024f0:	8b 45 10             	mov    0x10(%ebp),%eax
801024f3:	25 ff 01 00 00       	and    $0x1ff,%eax
801024f8:	89 c2                	mov    %eax,%edx
801024fa:	b8 00 02 00 00       	mov    $0x200,%eax
801024ff:	29 d0                	sub    %edx,%eax
80102501:	89 c2                	mov    %eax,%edx
80102503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102506:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102509:	29 c1                	sub    %eax,%ecx
8010250b:	89 c8                	mov    %ecx,%eax
8010250d:	39 c2                	cmp    %eax,%edx
8010250f:	0f 46 c2             	cmovbe %edx,%eax
80102512:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80102515:	8b 45 10             	mov    0x10(%ebp),%eax
80102518:	25 ff 01 00 00       	and    $0x1ff,%eax
8010251d:	8d 50 10             	lea    0x10(%eax),%edx
80102520:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102523:	01 d0                	add    %edx,%eax
80102525:	8d 50 08             	lea    0x8(%eax),%edx
80102528:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010252b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010252f:	89 54 24 04          	mov    %edx,0x4(%esp)
80102533:	8b 45 0c             	mov    0xc(%ebp),%eax
80102536:	89 04 24             	mov    %eax,(%esp)
80102539:	e8 0d 38 00 00       	call   80105d4b <memmove>
    brelse(bp);
8010253e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102541:	89 04 24             	mov    %eax,(%esp)
80102544:	e8 ce dc ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102549:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010254c:	01 45 f4             	add    %eax,-0xc(%ebp)
8010254f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102552:	01 45 10             	add    %eax,0x10(%ebp)
80102555:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102558:	01 45 0c             	add    %eax,0xc(%ebp)
8010255b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010255e:	3b 45 14             	cmp    0x14(%ebp),%eax
80102561:	0f 82 60 ff ff ff    	jb     801024c7 <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102567:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010256a:	c9                   	leave  
8010256b:	c3                   	ret    

8010256c <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
8010256c:	55                   	push   %ebp
8010256d:	89 e5                	mov    %esp,%ebp
8010256f:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102572:	8b 45 08             	mov    0x8(%ebp),%eax
80102575:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102579:	66 83 f8 03          	cmp    $0x3,%ax
8010257d:	75 60                	jne    801025df <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
8010257f:	8b 45 08             	mov    0x8(%ebp),%eax
80102582:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102586:	66 85 c0             	test   %ax,%ax
80102589:	78 20                	js     801025ab <writei+0x3f>
8010258b:	8b 45 08             	mov    0x8(%ebp),%eax
8010258e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102592:	66 83 f8 09          	cmp    $0x9,%ax
80102596:	7f 13                	jg     801025ab <writei+0x3f>
80102598:	8b 45 08             	mov    0x8(%ebp),%eax
8010259b:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010259f:	98                   	cwtl   
801025a0:	8b 04 c5 44 2a 11 80 	mov    -0x7feed5bc(,%eax,8),%eax
801025a7:	85 c0                	test   %eax,%eax
801025a9:	75 0a                	jne    801025b5 <writei+0x49>
      return -1;
801025ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025b0:	e9 44 01 00 00       	jmp    801026f9 <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
801025b5:	8b 45 08             	mov    0x8(%ebp),%eax
801025b8:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801025bc:	98                   	cwtl   
801025bd:	8b 04 c5 44 2a 11 80 	mov    -0x7feed5bc(,%eax,8),%eax
801025c4:	8b 55 14             	mov    0x14(%ebp),%edx
801025c7:	89 54 24 08          	mov    %edx,0x8(%esp)
801025cb:	8b 55 0c             	mov    0xc(%ebp),%edx
801025ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801025d2:	8b 55 08             	mov    0x8(%ebp),%edx
801025d5:	89 14 24             	mov    %edx,(%esp)
801025d8:	ff d0                	call   *%eax
801025da:	e9 1a 01 00 00       	jmp    801026f9 <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
801025df:	8b 45 08             	mov    0x8(%ebp),%eax
801025e2:	8b 40 18             	mov    0x18(%eax),%eax
801025e5:	3b 45 10             	cmp    0x10(%ebp),%eax
801025e8:	72 0d                	jb     801025f7 <writei+0x8b>
801025ea:	8b 45 14             	mov    0x14(%ebp),%eax
801025ed:	8b 55 10             	mov    0x10(%ebp),%edx
801025f0:	01 d0                	add    %edx,%eax
801025f2:	3b 45 10             	cmp    0x10(%ebp),%eax
801025f5:	73 0a                	jae    80102601 <writei+0x95>
    return -1;
801025f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025fc:	e9 f8 00 00 00       	jmp    801026f9 <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
80102601:	8b 45 14             	mov    0x14(%ebp),%eax
80102604:	8b 55 10             	mov    0x10(%ebp),%edx
80102607:	01 d0                	add    %edx,%eax
80102609:	3d 00 18 01 00       	cmp    $0x11800,%eax
8010260e:	76 0a                	jbe    8010261a <writei+0xae>
    return -1;
80102610:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102615:	e9 df 00 00 00       	jmp    801026f9 <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010261a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102621:	e9 9f 00 00 00       	jmp    801026c5 <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102626:	8b 45 10             	mov    0x10(%ebp),%eax
80102629:	c1 e8 09             	shr    $0x9,%eax
8010262c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102630:	8b 45 08             	mov    0x8(%ebp),%eax
80102633:	89 04 24             	mov    %eax,(%esp)
80102636:	e8 62 fb ff ff       	call   8010219d <bmap>
8010263b:	8b 55 08             	mov    0x8(%ebp),%edx
8010263e:	8b 12                	mov    (%edx),%edx
80102640:	89 44 24 04          	mov    %eax,0x4(%esp)
80102644:	89 14 24             	mov    %edx,(%esp)
80102647:	e8 5a db ff ff       	call   801001a6 <bread>
8010264c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
8010264f:	8b 45 10             	mov    0x10(%ebp),%eax
80102652:	25 ff 01 00 00       	and    $0x1ff,%eax
80102657:	89 c2                	mov    %eax,%edx
80102659:	b8 00 02 00 00       	mov    $0x200,%eax
8010265e:	29 d0                	sub    %edx,%eax
80102660:	89 c2                	mov    %eax,%edx
80102662:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102665:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102668:	29 c1                	sub    %eax,%ecx
8010266a:	89 c8                	mov    %ecx,%eax
8010266c:	39 c2                	cmp    %eax,%edx
8010266e:	0f 46 c2             	cmovbe %edx,%eax
80102671:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102674:	8b 45 10             	mov    0x10(%ebp),%eax
80102677:	25 ff 01 00 00       	and    $0x1ff,%eax
8010267c:	8d 50 10             	lea    0x10(%eax),%edx
8010267f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102682:	01 d0                	add    %edx,%eax
80102684:	8d 50 08             	lea    0x8(%eax),%edx
80102687:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010268a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010268e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102691:	89 44 24 04          	mov    %eax,0x4(%esp)
80102695:	89 14 24             	mov    %edx,(%esp)
80102698:	e8 ae 36 00 00       	call   80105d4b <memmove>
    log_write(bp);
8010269d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026a0:	89 04 24             	mov    %eax,(%esp)
801026a3:	e8 40 16 00 00       	call   80103ce8 <log_write>
    brelse(bp);
801026a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026ab:	89 04 24             	mov    %eax,(%esp)
801026ae:	e8 64 db ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801026b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801026b6:	01 45 f4             	add    %eax,-0xc(%ebp)
801026b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801026bc:	01 45 10             	add    %eax,0x10(%ebp)
801026bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801026c2:	01 45 0c             	add    %eax,0xc(%ebp)
801026c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026c8:	3b 45 14             	cmp    0x14(%ebp),%eax
801026cb:	0f 82 55 ff ff ff    	jb     80102626 <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801026d1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801026d5:	74 1f                	je     801026f6 <writei+0x18a>
801026d7:	8b 45 08             	mov    0x8(%ebp),%eax
801026da:	8b 40 18             	mov    0x18(%eax),%eax
801026dd:	3b 45 10             	cmp    0x10(%ebp),%eax
801026e0:	73 14                	jae    801026f6 <writei+0x18a>
    ip->size = off;
801026e2:	8b 45 08             	mov    0x8(%ebp),%eax
801026e5:	8b 55 10             	mov    0x10(%ebp),%edx
801026e8:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
801026eb:	8b 45 08             	mov    0x8(%ebp),%eax
801026ee:	89 04 24             	mov    %eax,(%esp)
801026f1:	e8 3d f6 ff ff       	call   80101d33 <iupdate>
  }
  return n;
801026f6:	8b 45 14             	mov    0x14(%ebp),%eax
}
801026f9:	c9                   	leave  
801026fa:	c3                   	ret    

801026fb <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801026fb:	55                   	push   %ebp
801026fc:	89 e5                	mov    %esp,%ebp
801026fe:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102701:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102708:	00 
80102709:	8b 45 0c             	mov    0xc(%ebp),%eax
8010270c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102710:	8b 45 08             	mov    0x8(%ebp),%eax
80102713:	89 04 24             	mov    %eax,(%esp)
80102716:	e8 d3 36 00 00       	call   80105dee <strncmp>
}
8010271b:	c9                   	leave  
8010271c:	c3                   	ret    

8010271d <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
8010271d:	55                   	push   %ebp
8010271e:	89 e5                	mov    %esp,%ebp
80102720:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102723:	8b 45 08             	mov    0x8(%ebp),%eax
80102726:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010272a:	66 83 f8 01          	cmp    $0x1,%ax
8010272e:	74 0c                	je     8010273c <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102730:	c7 04 24 0f 92 10 80 	movl   $0x8010920f,(%esp)
80102737:	e8 fe dd ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010273c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102743:	e9 88 00 00 00       	jmp    801027d0 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102748:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010274f:	00 
80102750:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102753:	89 44 24 08          	mov    %eax,0x8(%esp)
80102757:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010275a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010275e:	8b 45 08             	mov    0x8(%ebp),%eax
80102761:	89 04 24             	mov    %eax,(%esp)
80102764:	e8 9f fc ff ff       	call   80102408 <readi>
80102769:	83 f8 10             	cmp    $0x10,%eax
8010276c:	74 0c                	je     8010277a <dirlookup+0x5d>
      panic("dirlink read");
8010276e:	c7 04 24 21 92 10 80 	movl   $0x80109221,(%esp)
80102775:	e8 c0 dd ff ff       	call   8010053a <panic>
    if(de.inum == 0)
8010277a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010277e:	66 85 c0             	test   %ax,%ax
80102781:	75 02                	jne    80102785 <dirlookup+0x68>
      continue;
80102783:	eb 47                	jmp    801027cc <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
80102785:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102788:	83 c0 02             	add    $0x2,%eax
8010278b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010278f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102792:	89 04 24             	mov    %eax,(%esp)
80102795:	e8 61 ff ff ff       	call   801026fb <namecmp>
8010279a:	85 c0                	test   %eax,%eax
8010279c:	75 2e                	jne    801027cc <dirlookup+0xaf>
      // entry matches path element
      if(poff)
8010279e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801027a2:	74 08                	je     801027ac <dirlookup+0x8f>
        *poff = off;
801027a4:	8b 45 10             	mov    0x10(%ebp),%eax
801027a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801027aa:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
801027ac:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801027b0:	0f b7 c0             	movzwl %ax,%eax
801027b3:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801027b6:	8b 45 08             	mov    0x8(%ebp),%eax
801027b9:	8b 00                	mov    (%eax),%eax
801027bb:	8b 55 f0             	mov    -0x10(%ebp),%edx
801027be:	89 54 24 04          	mov    %edx,0x4(%esp)
801027c2:	89 04 24             	mov    %eax,(%esp)
801027c5:	e8 27 f6 ff ff       	call   80101df1 <iget>
801027ca:	eb 18                	jmp    801027e4 <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801027cc:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801027d0:	8b 45 08             	mov    0x8(%ebp),%eax
801027d3:	8b 40 18             	mov    0x18(%eax),%eax
801027d6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801027d9:	0f 87 69 ff ff ff    	ja     80102748 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801027df:	b8 00 00 00 00       	mov    $0x0,%eax
}
801027e4:	c9                   	leave  
801027e5:	c3                   	ret    

801027e6 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801027e6:	55                   	push   %ebp
801027e7:	89 e5                	mov    %esp,%ebp
801027e9:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801027ec:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801027f3:	00 
801027f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801027f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801027fb:	8b 45 08             	mov    0x8(%ebp),%eax
801027fe:	89 04 24             	mov    %eax,(%esp)
80102801:	e8 17 ff ff ff       	call   8010271d <dirlookup>
80102806:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102809:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010280d:	74 15                	je     80102824 <dirlink+0x3e>
    iput(ip);
8010280f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102812:	89 04 24             	mov    %eax,(%esp)
80102815:	e8 94 f8 ff ff       	call   801020ae <iput>
    return -1;
8010281a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010281f:	e9 b7 00 00 00       	jmp    801028db <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102824:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010282b:	eb 46                	jmp    80102873 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010282d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102830:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102837:	00 
80102838:	89 44 24 08          	mov    %eax,0x8(%esp)
8010283c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010283f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102843:	8b 45 08             	mov    0x8(%ebp),%eax
80102846:	89 04 24             	mov    %eax,(%esp)
80102849:	e8 ba fb ff ff       	call   80102408 <readi>
8010284e:	83 f8 10             	cmp    $0x10,%eax
80102851:	74 0c                	je     8010285f <dirlink+0x79>
      panic("dirlink read");
80102853:	c7 04 24 21 92 10 80 	movl   $0x80109221,(%esp)
8010285a:	e8 db dc ff ff       	call   8010053a <panic>
    if(de.inum == 0)
8010285f:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102863:	66 85 c0             	test   %ax,%ax
80102866:	75 02                	jne    8010286a <dirlink+0x84>
      break;
80102868:	eb 16                	jmp    80102880 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010286a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010286d:	83 c0 10             	add    $0x10,%eax
80102870:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102873:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102876:	8b 45 08             	mov    0x8(%ebp),%eax
80102879:	8b 40 18             	mov    0x18(%eax),%eax
8010287c:	39 c2                	cmp    %eax,%edx
8010287e:	72 ad                	jb     8010282d <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
80102880:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102887:	00 
80102888:	8b 45 0c             	mov    0xc(%ebp),%eax
8010288b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010288f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102892:	83 c0 02             	add    $0x2,%eax
80102895:	89 04 24             	mov    %eax,(%esp)
80102898:	e8 a7 35 00 00       	call   80105e44 <strncpy>
  de.inum = inum;
8010289d:	8b 45 10             	mov    0x10(%ebp),%eax
801028a0:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801028a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028a7:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801028ae:	00 
801028af:	89 44 24 08          	mov    %eax,0x8(%esp)
801028b3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801028b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801028ba:	8b 45 08             	mov    0x8(%ebp),%eax
801028bd:	89 04 24             	mov    %eax,(%esp)
801028c0:	e8 a7 fc ff ff       	call   8010256c <writei>
801028c5:	83 f8 10             	cmp    $0x10,%eax
801028c8:	74 0c                	je     801028d6 <dirlink+0xf0>
    panic("dirlink");
801028ca:	c7 04 24 2e 92 10 80 	movl   $0x8010922e,(%esp)
801028d1:	e8 64 dc ff ff       	call   8010053a <panic>
  
  return 0;
801028d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801028db:	c9                   	leave  
801028dc:	c3                   	ret    

801028dd <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801028dd:	55                   	push   %ebp
801028de:	89 e5                	mov    %esp,%ebp
801028e0:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801028e3:	eb 04                	jmp    801028e9 <skipelem+0xc>
    path++;
801028e5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801028e9:	8b 45 08             	mov    0x8(%ebp),%eax
801028ec:	0f b6 00             	movzbl (%eax),%eax
801028ef:	3c 2f                	cmp    $0x2f,%al
801028f1:	74 f2                	je     801028e5 <skipelem+0x8>
    path++;
  if(*path == 0)
801028f3:	8b 45 08             	mov    0x8(%ebp),%eax
801028f6:	0f b6 00             	movzbl (%eax),%eax
801028f9:	84 c0                	test   %al,%al
801028fb:	75 0a                	jne    80102907 <skipelem+0x2a>
    return 0;
801028fd:	b8 00 00 00 00       	mov    $0x0,%eax
80102902:	e9 86 00 00 00       	jmp    8010298d <skipelem+0xb0>
  s = path;
80102907:	8b 45 08             	mov    0x8(%ebp),%eax
8010290a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
8010290d:	eb 04                	jmp    80102913 <skipelem+0x36>
    path++;
8010290f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102913:	8b 45 08             	mov    0x8(%ebp),%eax
80102916:	0f b6 00             	movzbl (%eax),%eax
80102919:	3c 2f                	cmp    $0x2f,%al
8010291b:	74 0a                	je     80102927 <skipelem+0x4a>
8010291d:	8b 45 08             	mov    0x8(%ebp),%eax
80102920:	0f b6 00             	movzbl (%eax),%eax
80102923:	84 c0                	test   %al,%al
80102925:	75 e8                	jne    8010290f <skipelem+0x32>
    path++;
  len = path - s;
80102927:	8b 55 08             	mov    0x8(%ebp),%edx
8010292a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010292d:	29 c2                	sub    %eax,%edx
8010292f:	89 d0                	mov    %edx,%eax
80102931:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102934:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102938:	7e 1c                	jle    80102956 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
8010293a:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102941:	00 
80102942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102945:	89 44 24 04          	mov    %eax,0x4(%esp)
80102949:	8b 45 0c             	mov    0xc(%ebp),%eax
8010294c:	89 04 24             	mov    %eax,(%esp)
8010294f:	e8 f7 33 00 00       	call   80105d4b <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102954:	eb 2a                	jmp    80102980 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102956:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102959:	89 44 24 08          	mov    %eax,0x8(%esp)
8010295d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102960:	89 44 24 04          	mov    %eax,0x4(%esp)
80102964:	8b 45 0c             	mov    0xc(%ebp),%eax
80102967:	89 04 24             	mov    %eax,(%esp)
8010296a:	e8 dc 33 00 00       	call   80105d4b <memmove>
    name[len] = 0;
8010296f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102972:	8b 45 0c             	mov    0xc(%ebp),%eax
80102975:	01 d0                	add    %edx,%eax
80102977:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010297a:	eb 04                	jmp    80102980 <skipelem+0xa3>
    path++;
8010297c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102980:	8b 45 08             	mov    0x8(%ebp),%eax
80102983:	0f b6 00             	movzbl (%eax),%eax
80102986:	3c 2f                	cmp    $0x2f,%al
80102988:	74 f2                	je     8010297c <skipelem+0x9f>
    path++;
  return path;
8010298a:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010298d:	c9                   	leave  
8010298e:	c3                   	ret    

8010298f <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010298f:	55                   	push   %ebp
80102990:	89 e5                	mov    %esp,%ebp
80102992:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102995:	8b 45 08             	mov    0x8(%ebp),%eax
80102998:	0f b6 00             	movzbl (%eax),%eax
8010299b:	3c 2f                	cmp    $0x2f,%al
8010299d:	75 1c                	jne    801029bb <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010299f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801029a6:	00 
801029a7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801029ae:	e8 3e f4 ff ff       	call   80101df1 <iget>
801029b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801029b6:	e9 af 00 00 00       	jmp    80102a6a <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801029bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801029c1:	8b 40 68             	mov    0x68(%eax),%eax
801029c4:	89 04 24             	mov    %eax,(%esp)
801029c7:	e8 f7 f4 ff ff       	call   80101ec3 <idup>
801029cc:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801029cf:	e9 96 00 00 00       	jmp    80102a6a <namex+0xdb>
    ilock(ip);
801029d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029d7:	89 04 24             	mov    %eax,(%esp)
801029da:	e8 16 f5 ff ff       	call   80101ef5 <ilock>
    if(ip->type != T_DIR){
801029df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801029e6:	66 83 f8 01          	cmp    $0x1,%ax
801029ea:	74 15                	je     80102a01 <namex+0x72>
      iunlockput(ip);
801029ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029ef:	89 04 24             	mov    %eax,(%esp)
801029f2:	e8 88 f7 ff ff       	call   8010217f <iunlockput>
      return 0;
801029f7:	b8 00 00 00 00       	mov    $0x0,%eax
801029fc:	e9 a3 00 00 00       	jmp    80102aa4 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102a01:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102a05:	74 1d                	je     80102a24 <namex+0x95>
80102a07:	8b 45 08             	mov    0x8(%ebp),%eax
80102a0a:	0f b6 00             	movzbl (%eax),%eax
80102a0d:	84 c0                	test   %al,%al
80102a0f:	75 13                	jne    80102a24 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102a11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a14:	89 04 24             	mov    %eax,(%esp)
80102a17:	e8 2d f6 ff ff       	call   80102049 <iunlock>
      return ip;
80102a1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a1f:	e9 80 00 00 00       	jmp    80102aa4 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102a24:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102a2b:	00 
80102a2c:	8b 45 10             	mov    0x10(%ebp),%eax
80102a2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a36:	89 04 24             	mov    %eax,(%esp)
80102a39:	e8 df fc ff ff       	call   8010271d <dirlookup>
80102a3e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102a41:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102a45:	75 12                	jne    80102a59 <namex+0xca>
      iunlockput(ip);
80102a47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a4a:	89 04 24             	mov    %eax,(%esp)
80102a4d:	e8 2d f7 ff ff       	call   8010217f <iunlockput>
      return 0;
80102a52:	b8 00 00 00 00       	mov    $0x0,%eax
80102a57:	eb 4b                	jmp    80102aa4 <namex+0x115>
    }
    iunlockput(ip);
80102a59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a5c:	89 04 24             	mov    %eax,(%esp)
80102a5f:	e8 1b f7 ff ff       	call   8010217f <iunlockput>
    ip = next;
80102a64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a67:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102a6a:	8b 45 10             	mov    0x10(%ebp),%eax
80102a6d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a71:	8b 45 08             	mov    0x8(%ebp),%eax
80102a74:	89 04 24             	mov    %eax,(%esp)
80102a77:	e8 61 fe ff ff       	call   801028dd <skipelem>
80102a7c:	89 45 08             	mov    %eax,0x8(%ebp)
80102a7f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102a83:	0f 85 4b ff ff ff    	jne    801029d4 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102a89:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102a8d:	74 12                	je     80102aa1 <namex+0x112>
    iput(ip);
80102a8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a92:	89 04 24             	mov    %eax,(%esp)
80102a95:	e8 14 f6 ff ff       	call   801020ae <iput>
    return 0;
80102a9a:	b8 00 00 00 00       	mov    $0x0,%eax
80102a9f:	eb 03                	jmp    80102aa4 <namex+0x115>
  }
  return ip;
80102aa1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102aa4:	c9                   	leave  
80102aa5:	c3                   	ret    

80102aa6 <namei>:

struct inode*
namei(char *path)
{
80102aa6:	55                   	push   %ebp
80102aa7:	89 e5                	mov    %esp,%ebp
80102aa9:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102aac:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102aaf:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ab3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102aba:	00 
80102abb:	8b 45 08             	mov    0x8(%ebp),%eax
80102abe:	89 04 24             	mov    %eax,(%esp)
80102ac1:	e8 c9 fe ff ff       	call   8010298f <namex>
}
80102ac6:	c9                   	leave  
80102ac7:	c3                   	ret    

80102ac8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102ac8:	55                   	push   %ebp
80102ac9:	89 e5                	mov    %esp,%ebp
80102acb:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102ace:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ad1:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ad5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102adc:	00 
80102add:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae0:	89 04 24             	mov    %eax,(%esp)
80102ae3:	e8 a7 fe ff ff       	call   8010298f <namex>
}
80102ae8:	c9                   	leave  
80102ae9:	c3                   	ret    

80102aea <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102aea:	55                   	push   %ebp
80102aeb:	89 e5                	mov    %esp,%ebp
80102aed:	83 ec 14             	sub    $0x14,%esp
80102af0:	8b 45 08             	mov    0x8(%ebp),%eax
80102af3:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102af7:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102afb:	89 c2                	mov    %eax,%edx
80102afd:	ec                   	in     (%dx),%al
80102afe:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102b01:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102b05:	c9                   	leave  
80102b06:	c3                   	ret    

80102b07 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102b07:	55                   	push   %ebp
80102b08:	89 e5                	mov    %esp,%ebp
80102b0a:	57                   	push   %edi
80102b0b:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102b0c:	8b 55 08             	mov    0x8(%ebp),%edx
80102b0f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b12:	8b 45 10             	mov    0x10(%ebp),%eax
80102b15:	89 cb                	mov    %ecx,%ebx
80102b17:	89 df                	mov    %ebx,%edi
80102b19:	89 c1                	mov    %eax,%ecx
80102b1b:	fc                   	cld    
80102b1c:	f3 6d                	rep insl (%dx),%es:(%edi)
80102b1e:	89 c8                	mov    %ecx,%eax
80102b20:	89 fb                	mov    %edi,%ebx
80102b22:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b25:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102b28:	5b                   	pop    %ebx
80102b29:	5f                   	pop    %edi
80102b2a:	5d                   	pop    %ebp
80102b2b:	c3                   	ret    

80102b2c <outb>:

static inline void
outb(ushort port, uchar data)
{
80102b2c:	55                   	push   %ebp
80102b2d:	89 e5                	mov    %esp,%ebp
80102b2f:	83 ec 08             	sub    $0x8,%esp
80102b32:	8b 55 08             	mov    0x8(%ebp),%edx
80102b35:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b38:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102b3c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102b3f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102b43:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102b47:	ee                   	out    %al,(%dx)
}
80102b48:	c9                   	leave  
80102b49:	c3                   	ret    

80102b4a <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102b4a:	55                   	push   %ebp
80102b4b:	89 e5                	mov    %esp,%ebp
80102b4d:	56                   	push   %esi
80102b4e:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102b4f:	8b 55 08             	mov    0x8(%ebp),%edx
80102b52:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b55:	8b 45 10             	mov    0x10(%ebp),%eax
80102b58:	89 cb                	mov    %ecx,%ebx
80102b5a:	89 de                	mov    %ebx,%esi
80102b5c:	89 c1                	mov    %eax,%ecx
80102b5e:	fc                   	cld    
80102b5f:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102b61:	89 c8                	mov    %ecx,%eax
80102b63:	89 f3                	mov    %esi,%ebx
80102b65:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b68:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102b6b:	5b                   	pop    %ebx
80102b6c:	5e                   	pop    %esi
80102b6d:	5d                   	pop    %ebp
80102b6e:	c3                   	ret    

80102b6f <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102b6f:	55                   	push   %ebp
80102b70:	89 e5                	mov    %esp,%ebp
80102b72:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102b75:	90                   	nop
80102b76:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102b7d:	e8 68 ff ff ff       	call   80102aea <inb>
80102b82:	0f b6 c0             	movzbl %al,%eax
80102b85:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102b88:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102b8b:	25 c0 00 00 00       	and    $0xc0,%eax
80102b90:	83 f8 40             	cmp    $0x40,%eax
80102b93:	75 e1                	jne    80102b76 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102b95:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102b99:	74 11                	je     80102bac <idewait+0x3d>
80102b9b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102b9e:	83 e0 21             	and    $0x21,%eax
80102ba1:	85 c0                	test   %eax,%eax
80102ba3:	74 07                	je     80102bac <idewait+0x3d>
    return -1;
80102ba5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102baa:	eb 05                	jmp    80102bb1 <idewait+0x42>
  return 0;
80102bac:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102bb1:	c9                   	leave  
80102bb2:	c3                   	ret    

80102bb3 <ideinit>:

void
ideinit(void)
{
80102bb3:	55                   	push   %ebp
80102bb4:	89 e5                	mov    %esp,%ebp
80102bb6:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102bb9:	c7 44 24 04 36 92 10 	movl   $0x80109236,0x4(%esp)
80102bc0:	80 
80102bc1:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102bc8:	e8 3a 2e 00 00       	call   80105a07 <initlock>
  picenable(IRQ_IDE);
80102bcd:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102bd4:	e8 a3 18 00 00       	call   8010447c <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102bd9:	a1 c0 41 11 80       	mov    0x801141c0,%eax
80102bde:	83 e8 01             	sub    $0x1,%eax
80102be1:	89 44 24 04          	mov    %eax,0x4(%esp)
80102be5:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102bec:	e8 43 04 00 00       	call   80103034 <ioapicenable>
  idewait(0);
80102bf1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102bf8:	e8 72 ff ff ff       	call   80102b6f <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102bfd:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102c04:	00 
80102c05:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c0c:	e8 1b ff ff ff       	call   80102b2c <outb>
  for(i=0; i<1000; i++){
80102c11:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c18:	eb 20                	jmp    80102c3a <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102c1a:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102c21:	e8 c4 fe ff ff       	call   80102aea <inb>
80102c26:	84 c0                	test   %al,%al
80102c28:	74 0c                	je     80102c36 <ideinit+0x83>
      havedisk1 = 1;
80102c2a:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
80102c31:	00 00 00 
      break;
80102c34:	eb 0d                	jmp    80102c43 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102c36:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c3a:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102c41:	7e d7                	jle    80102c1a <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102c43:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102c4a:	00 
80102c4b:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c52:	e8 d5 fe ff ff       	call   80102b2c <outb>
}
80102c57:	c9                   	leave  
80102c58:	c3                   	ret    

80102c59 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102c59:	55                   	push   %ebp
80102c5a:	89 e5                	mov    %esp,%ebp
80102c5c:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102c5f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102c63:	75 0c                	jne    80102c71 <idestart+0x18>
    panic("idestart");
80102c65:	c7 04 24 3a 92 10 80 	movl   $0x8010923a,(%esp)
80102c6c:	e8 c9 d8 ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102c71:	8b 45 08             	mov    0x8(%ebp),%eax
80102c74:	8b 40 08             	mov    0x8(%eax),%eax
80102c77:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102c7c:	76 0c                	jbe    80102c8a <idestart+0x31>
    panic("incorrect blockno");
80102c7e:	c7 04 24 43 92 10 80 	movl   $0x80109243,(%esp)
80102c85:	e8 b0 d8 ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102c8a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102c91:	8b 45 08             	mov    0x8(%ebp),%eax
80102c94:	8b 50 08             	mov    0x8(%eax),%edx
80102c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c9a:	0f af c2             	imul   %edx,%eax
80102c9d:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102ca0:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102ca4:	7e 0c                	jle    80102cb2 <idestart+0x59>
80102ca6:	c7 04 24 3a 92 10 80 	movl   $0x8010923a,(%esp)
80102cad:	e8 88 d8 ff ff       	call   8010053a <panic>
  
  idewait(0);
80102cb2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102cb9:	e8 b1 fe ff ff       	call   80102b6f <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102cbe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102cc5:	00 
80102cc6:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102ccd:	e8 5a fe ff ff       	call   80102b2c <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102cd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cd5:	0f b6 c0             	movzbl %al,%eax
80102cd8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cdc:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102ce3:	e8 44 fe ff ff       	call   80102b2c <outb>
  outb(0x1f3, sector & 0xff);
80102ce8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ceb:	0f b6 c0             	movzbl %al,%eax
80102cee:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cf2:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102cf9:	e8 2e fe ff ff       	call   80102b2c <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102cfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d01:	c1 f8 08             	sar    $0x8,%eax
80102d04:	0f b6 c0             	movzbl %al,%eax
80102d07:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d0b:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102d12:	e8 15 fe ff ff       	call   80102b2c <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102d17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d1a:	c1 f8 10             	sar    $0x10,%eax
80102d1d:	0f b6 c0             	movzbl %al,%eax
80102d20:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d24:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102d2b:	e8 fc fd ff ff       	call   80102b2c <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102d30:	8b 45 08             	mov    0x8(%ebp),%eax
80102d33:	8b 40 04             	mov    0x4(%eax),%eax
80102d36:	83 e0 01             	and    $0x1,%eax
80102d39:	c1 e0 04             	shl    $0x4,%eax
80102d3c:	89 c2                	mov    %eax,%edx
80102d3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d41:	c1 f8 18             	sar    $0x18,%eax
80102d44:	83 e0 0f             	and    $0xf,%eax
80102d47:	09 d0                	or     %edx,%eax
80102d49:	83 c8 e0             	or     $0xffffffe0,%eax
80102d4c:	0f b6 c0             	movzbl %al,%eax
80102d4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d53:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102d5a:	e8 cd fd ff ff       	call   80102b2c <outb>
  if(b->flags & B_DIRTY){
80102d5f:	8b 45 08             	mov    0x8(%ebp),%eax
80102d62:	8b 00                	mov    (%eax),%eax
80102d64:	83 e0 04             	and    $0x4,%eax
80102d67:	85 c0                	test   %eax,%eax
80102d69:	74 34                	je     80102d9f <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102d6b:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102d72:	00 
80102d73:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102d7a:	e8 ad fd ff ff       	call   80102b2c <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102d7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102d82:	83 c0 18             	add    $0x18,%eax
80102d85:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102d8c:	00 
80102d8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d91:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102d98:	e8 ad fd ff ff       	call   80102b4a <outsl>
80102d9d:	eb 14                	jmp    80102db3 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102d9f:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102da6:	00 
80102da7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102dae:	e8 79 fd ff ff       	call   80102b2c <outb>
  }
}
80102db3:	c9                   	leave  
80102db4:	c3                   	ret    

80102db5 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102db5:	55                   	push   %ebp
80102db6:	89 e5                	mov    %esp,%ebp
80102db8:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102dbb:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102dc2:	e8 61 2c 00 00       	call   80105a28 <acquire>
  if((b = idequeue) == 0){
80102dc7:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102dcc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102dcf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102dd3:	75 11                	jne    80102de6 <ideintr+0x31>
    release(&idelock);
80102dd5:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102ddc:	e8 a9 2c 00 00       	call   80105a8a <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102de1:	e9 90 00 00 00       	jmp    80102e76 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102de6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102de9:	8b 40 14             	mov    0x14(%eax),%eax
80102dec:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102df1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102df4:	8b 00                	mov    (%eax),%eax
80102df6:	83 e0 04             	and    $0x4,%eax
80102df9:	85 c0                	test   %eax,%eax
80102dfb:	75 2e                	jne    80102e2b <ideintr+0x76>
80102dfd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102e04:	e8 66 fd ff ff       	call   80102b6f <idewait>
80102e09:	85 c0                	test   %eax,%eax
80102e0b:	78 1e                	js     80102e2b <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102e0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e10:	83 c0 18             	add    $0x18,%eax
80102e13:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102e1a:	00 
80102e1b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e1f:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102e26:	e8 dc fc ff ff       	call   80102b07 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102e2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e2e:	8b 00                	mov    (%eax),%eax
80102e30:	83 c8 02             	or     $0x2,%eax
80102e33:	89 c2                	mov    %eax,%edx
80102e35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e38:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102e3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e3d:	8b 00                	mov    (%eax),%eax
80102e3f:	83 e0 fb             	and    $0xfffffffb,%eax
80102e42:	89 c2                	mov    %eax,%edx
80102e44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e47:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102e49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e4c:	89 04 24             	mov    %eax,(%esp)
80102e4f:	e8 d2 29 00 00       	call   80105826 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102e54:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102e59:	85 c0                	test   %eax,%eax
80102e5b:	74 0d                	je     80102e6a <ideintr+0xb5>
    idestart(idequeue);
80102e5d:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102e62:	89 04 24             	mov    %eax,(%esp)
80102e65:	e8 ef fd ff ff       	call   80102c59 <idestart>

  release(&idelock);
80102e6a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102e71:	e8 14 2c 00 00       	call   80105a8a <release>
}
80102e76:	c9                   	leave  
80102e77:	c3                   	ret    

80102e78 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102e78:	55                   	push   %ebp
80102e79:	89 e5                	mov    %esp,%ebp
80102e7b:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102e7e:	8b 45 08             	mov    0x8(%ebp),%eax
80102e81:	8b 00                	mov    (%eax),%eax
80102e83:	83 e0 01             	and    $0x1,%eax
80102e86:	85 c0                	test   %eax,%eax
80102e88:	75 0c                	jne    80102e96 <iderw+0x1e>
    panic("iderw: buf not busy");
80102e8a:	c7 04 24 55 92 10 80 	movl   $0x80109255,(%esp)
80102e91:	e8 a4 d6 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102e96:	8b 45 08             	mov    0x8(%ebp),%eax
80102e99:	8b 00                	mov    (%eax),%eax
80102e9b:	83 e0 06             	and    $0x6,%eax
80102e9e:	83 f8 02             	cmp    $0x2,%eax
80102ea1:	75 0c                	jne    80102eaf <iderw+0x37>
    panic("iderw: nothing to do");
80102ea3:	c7 04 24 69 92 10 80 	movl   $0x80109269,(%esp)
80102eaa:	e8 8b d6 ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102eaf:	8b 45 08             	mov    0x8(%ebp),%eax
80102eb2:	8b 40 04             	mov    0x4(%eax),%eax
80102eb5:	85 c0                	test   %eax,%eax
80102eb7:	74 15                	je     80102ece <iderw+0x56>
80102eb9:	a1 58 c6 10 80       	mov    0x8010c658,%eax
80102ebe:	85 c0                	test   %eax,%eax
80102ec0:	75 0c                	jne    80102ece <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102ec2:	c7 04 24 7e 92 10 80 	movl   $0x8010927e,(%esp)
80102ec9:	e8 6c d6 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102ece:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102ed5:	e8 4e 2b 00 00       	call   80105a28 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102eda:	8b 45 08             	mov    0x8(%ebp),%eax
80102edd:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102ee4:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
80102eeb:	eb 0b                	jmp    80102ef8 <iderw+0x80>
80102eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ef0:	8b 00                	mov    (%eax),%eax
80102ef2:	83 c0 14             	add    $0x14,%eax
80102ef5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102ef8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102efb:	8b 00                	mov    (%eax),%eax
80102efd:	85 c0                	test   %eax,%eax
80102eff:	75 ec                	jne    80102eed <iderw+0x75>
    ;
  *pp = b;
80102f01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f04:	8b 55 08             	mov    0x8(%ebp),%edx
80102f07:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102f09:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102f0e:	3b 45 08             	cmp    0x8(%ebp),%eax
80102f11:	75 0d                	jne    80102f20 <iderw+0xa8>
    idestart(b);
80102f13:	8b 45 08             	mov    0x8(%ebp),%eax
80102f16:	89 04 24             	mov    %eax,(%esp)
80102f19:	e8 3b fd ff ff       	call   80102c59 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f1e:	eb 15                	jmp    80102f35 <iderw+0xbd>
80102f20:	eb 13                	jmp    80102f35 <iderw+0xbd>
    sleep(b, &idelock);
80102f22:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80102f29:	80 
80102f2a:	8b 45 08             	mov    0x8(%ebp),%eax
80102f2d:	89 04 24             	mov    %eax,(%esp)
80102f30:	e8 fd 27 00 00       	call   80105732 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102f35:	8b 45 08             	mov    0x8(%ebp),%eax
80102f38:	8b 00                	mov    (%eax),%eax
80102f3a:	83 e0 06             	and    $0x6,%eax
80102f3d:	83 f8 02             	cmp    $0x2,%eax
80102f40:	75 e0                	jne    80102f22 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102f42:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102f49:	e8 3c 2b 00 00       	call   80105a8a <release>
}
80102f4e:	c9                   	leave  
80102f4f:	c3                   	ret    

80102f50 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102f50:	55                   	push   %ebp
80102f51:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102f53:	a1 94 3a 11 80       	mov    0x80113a94,%eax
80102f58:	8b 55 08             	mov    0x8(%ebp),%edx
80102f5b:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102f5d:	a1 94 3a 11 80       	mov    0x80113a94,%eax
80102f62:	8b 40 10             	mov    0x10(%eax),%eax
}
80102f65:	5d                   	pop    %ebp
80102f66:	c3                   	ret    

80102f67 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102f67:	55                   	push   %ebp
80102f68:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102f6a:	a1 94 3a 11 80       	mov    0x80113a94,%eax
80102f6f:	8b 55 08             	mov    0x8(%ebp),%edx
80102f72:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102f74:	a1 94 3a 11 80       	mov    0x80113a94,%eax
80102f79:	8b 55 0c             	mov    0xc(%ebp),%edx
80102f7c:	89 50 10             	mov    %edx,0x10(%eax)
}
80102f7f:	5d                   	pop    %ebp
80102f80:	c3                   	ret    

80102f81 <ioapicinit>:

void
ioapicinit(void)
{
80102f81:	55                   	push   %ebp
80102f82:	89 e5                	mov    %esp,%ebp
80102f84:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102f87:	a1 c4 3b 11 80       	mov    0x80113bc4,%eax
80102f8c:	85 c0                	test   %eax,%eax
80102f8e:	75 05                	jne    80102f95 <ioapicinit+0x14>
    return;
80102f90:	e9 9d 00 00 00       	jmp    80103032 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102f95:	c7 05 94 3a 11 80 00 	movl   $0xfec00000,0x80113a94
80102f9c:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102f9f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102fa6:	e8 a5 ff ff ff       	call   80102f50 <ioapicread>
80102fab:	c1 e8 10             	shr    $0x10,%eax
80102fae:	25 ff 00 00 00       	and    $0xff,%eax
80102fb3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102fb6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102fbd:	e8 8e ff ff ff       	call   80102f50 <ioapicread>
80102fc2:	c1 e8 18             	shr    $0x18,%eax
80102fc5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102fc8:	0f b6 05 c0 3b 11 80 	movzbl 0x80113bc0,%eax
80102fcf:	0f b6 c0             	movzbl %al,%eax
80102fd2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102fd5:	74 0c                	je     80102fe3 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102fd7:	c7 04 24 9c 92 10 80 	movl   $0x8010929c,(%esp)
80102fde:	e8 bd d3 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102fe3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102fea:	eb 3e                	jmp    8010302a <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102fec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fef:	83 c0 20             	add    $0x20,%eax
80102ff2:	0d 00 00 01 00       	or     $0x10000,%eax
80102ff7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102ffa:	83 c2 08             	add    $0x8,%edx
80102ffd:	01 d2                	add    %edx,%edx
80102fff:	89 44 24 04          	mov    %eax,0x4(%esp)
80103003:	89 14 24             	mov    %edx,(%esp)
80103006:	e8 5c ff ff ff       	call   80102f67 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
8010300b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010300e:	83 c0 08             	add    $0x8,%eax
80103011:	01 c0                	add    %eax,%eax
80103013:	83 c0 01             	add    $0x1,%eax
80103016:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010301d:	00 
8010301e:	89 04 24             	mov    %eax,(%esp)
80103021:	e8 41 ff ff ff       	call   80102f67 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103026:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010302a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010302d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103030:	7e ba                	jle    80102fec <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103032:	c9                   	leave  
80103033:	c3                   	ret    

80103034 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103034:	55                   	push   %ebp
80103035:	89 e5                	mov    %esp,%ebp
80103037:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
8010303a:	a1 c4 3b 11 80       	mov    0x80113bc4,%eax
8010303f:	85 c0                	test   %eax,%eax
80103041:	75 02                	jne    80103045 <ioapicenable+0x11>
    return;
80103043:	eb 37                	jmp    8010307c <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103045:	8b 45 08             	mov    0x8(%ebp),%eax
80103048:	83 c0 20             	add    $0x20,%eax
8010304b:	8b 55 08             	mov    0x8(%ebp),%edx
8010304e:	83 c2 08             	add    $0x8,%edx
80103051:	01 d2                	add    %edx,%edx
80103053:	89 44 24 04          	mov    %eax,0x4(%esp)
80103057:	89 14 24             	mov    %edx,(%esp)
8010305a:	e8 08 ff ff ff       	call   80102f67 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
8010305f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103062:	c1 e0 18             	shl    $0x18,%eax
80103065:	8b 55 08             	mov    0x8(%ebp),%edx
80103068:	83 c2 08             	add    $0x8,%edx
8010306b:	01 d2                	add    %edx,%edx
8010306d:	83 c2 01             	add    $0x1,%edx
80103070:	89 44 24 04          	mov    %eax,0x4(%esp)
80103074:	89 14 24             	mov    %edx,(%esp)
80103077:	e8 eb fe ff ff       	call   80102f67 <ioapicwrite>
}
8010307c:	c9                   	leave  
8010307d:	c3                   	ret    

8010307e <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010307e:	55                   	push   %ebp
8010307f:	89 e5                	mov    %esp,%ebp
80103081:	8b 45 08             	mov    0x8(%ebp),%eax
80103084:	05 00 00 00 80       	add    $0x80000000,%eax
80103089:	5d                   	pop    %ebp
8010308a:	c3                   	ret    

8010308b <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
8010308b:	55                   	push   %ebp
8010308c:	89 e5                	mov    %esp,%ebp
8010308e:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103091:	c7 44 24 04 ce 92 10 	movl   $0x801092ce,0x4(%esp)
80103098:	80 
80103099:	c7 04 24 a0 3a 11 80 	movl   $0x80113aa0,(%esp)
801030a0:	e8 62 29 00 00       	call   80105a07 <initlock>
  kmem.use_lock = 0;
801030a5:	c7 05 d4 3a 11 80 00 	movl   $0x0,0x80113ad4
801030ac:	00 00 00 
  freerange(vstart, vend);
801030af:	8b 45 0c             	mov    0xc(%ebp),%eax
801030b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801030b6:	8b 45 08             	mov    0x8(%ebp),%eax
801030b9:	89 04 24             	mov    %eax,(%esp)
801030bc:	e8 26 00 00 00       	call   801030e7 <freerange>
}
801030c1:	c9                   	leave  
801030c2:	c3                   	ret    

801030c3 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
801030c3:	55                   	push   %ebp
801030c4:	89 e5                	mov    %esp,%ebp
801030c6:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
801030c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801030cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801030d0:	8b 45 08             	mov    0x8(%ebp),%eax
801030d3:	89 04 24             	mov    %eax,(%esp)
801030d6:	e8 0c 00 00 00       	call   801030e7 <freerange>
  kmem.use_lock = 1;
801030db:	c7 05 d4 3a 11 80 01 	movl   $0x1,0x80113ad4
801030e2:	00 00 00 
}
801030e5:	c9                   	leave  
801030e6:	c3                   	ret    

801030e7 <freerange>:

void
freerange(void *vstart, void *vend)
{
801030e7:	55                   	push   %ebp
801030e8:	89 e5                	mov    %esp,%ebp
801030ea:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
801030ed:	8b 45 08             	mov    0x8(%ebp),%eax
801030f0:	05 ff 0f 00 00       	add    $0xfff,%eax
801030f5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801030fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801030fd:	eb 12                	jmp    80103111 <freerange+0x2a>
    kfree(p);
801030ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103102:	89 04 24             	mov    %eax,(%esp)
80103105:	e8 16 00 00 00       	call   80103120 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
8010310a:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103111:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103114:	05 00 10 00 00       	add    $0x1000,%eax
80103119:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010311c:	76 e1                	jbe    801030ff <freerange+0x18>
    kfree(p);
}
8010311e:	c9                   	leave  
8010311f:	c3                   	ret    

80103120 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80103120:	55                   	push   %ebp
80103121:	89 e5                	mov    %esp,%ebp
80103123:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80103126:	8b 45 08             	mov    0x8(%ebp),%eax
80103129:	25 ff 0f 00 00       	and    $0xfff,%eax
8010312e:	85 c0                	test   %eax,%eax
80103130:	75 1b                	jne    8010314d <kfree+0x2d>
80103132:	81 7d 08 fc 72 11 80 	cmpl   $0x801172fc,0x8(%ebp)
80103139:	72 12                	jb     8010314d <kfree+0x2d>
8010313b:	8b 45 08             	mov    0x8(%ebp),%eax
8010313e:	89 04 24             	mov    %eax,(%esp)
80103141:	e8 38 ff ff ff       	call   8010307e <v2p>
80103146:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
8010314b:	76 0c                	jbe    80103159 <kfree+0x39>
    panic("kfree");
8010314d:	c7 04 24 d3 92 10 80 	movl   $0x801092d3,(%esp)
80103154:	e8 e1 d3 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103159:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103160:	00 
80103161:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103168:	00 
80103169:	8b 45 08             	mov    0x8(%ebp),%eax
8010316c:	89 04 24             	mov    %eax,(%esp)
8010316f:	e8 08 2b 00 00       	call   80105c7c <memset>

  if(kmem.use_lock)
80103174:	a1 d4 3a 11 80       	mov    0x80113ad4,%eax
80103179:	85 c0                	test   %eax,%eax
8010317b:	74 0c                	je     80103189 <kfree+0x69>
    acquire(&kmem.lock);
8010317d:	c7 04 24 a0 3a 11 80 	movl   $0x80113aa0,(%esp)
80103184:	e8 9f 28 00 00       	call   80105a28 <acquire>
  r = (struct run*)v;
80103189:	8b 45 08             	mov    0x8(%ebp),%eax
8010318c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
8010318f:	8b 15 d8 3a 11 80    	mov    0x80113ad8,%edx
80103195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103198:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
8010319a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010319d:	a3 d8 3a 11 80       	mov    %eax,0x80113ad8
  if(kmem.use_lock)
801031a2:	a1 d4 3a 11 80       	mov    0x80113ad4,%eax
801031a7:	85 c0                	test   %eax,%eax
801031a9:	74 0c                	je     801031b7 <kfree+0x97>
    release(&kmem.lock);
801031ab:	c7 04 24 a0 3a 11 80 	movl   $0x80113aa0,(%esp)
801031b2:	e8 d3 28 00 00       	call   80105a8a <release>
}
801031b7:	c9                   	leave  
801031b8:	c3                   	ret    

801031b9 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801031b9:	55                   	push   %ebp
801031ba:	89 e5                	mov    %esp,%ebp
801031bc:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
801031bf:	a1 d4 3a 11 80       	mov    0x80113ad4,%eax
801031c4:	85 c0                	test   %eax,%eax
801031c6:	74 0c                	je     801031d4 <kalloc+0x1b>
    acquire(&kmem.lock);
801031c8:	c7 04 24 a0 3a 11 80 	movl   $0x80113aa0,(%esp)
801031cf:	e8 54 28 00 00       	call   80105a28 <acquire>
  r = kmem.freelist;
801031d4:	a1 d8 3a 11 80       	mov    0x80113ad8,%eax
801031d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
801031dc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801031e0:	74 0a                	je     801031ec <kalloc+0x33>
    kmem.freelist = r->next;
801031e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031e5:	8b 00                	mov    (%eax),%eax
801031e7:	a3 d8 3a 11 80       	mov    %eax,0x80113ad8
  if(kmem.use_lock)
801031ec:	a1 d4 3a 11 80       	mov    0x80113ad4,%eax
801031f1:	85 c0                	test   %eax,%eax
801031f3:	74 0c                	je     80103201 <kalloc+0x48>
    release(&kmem.lock);
801031f5:	c7 04 24 a0 3a 11 80 	movl   $0x80113aa0,(%esp)
801031fc:	e8 89 28 00 00       	call   80105a8a <release>
  return (char*)r;
80103201:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103204:	c9                   	leave  
80103205:	c3                   	ret    

80103206 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103206:	55                   	push   %ebp
80103207:	89 e5                	mov    %esp,%ebp
80103209:	83 ec 14             	sub    $0x14,%esp
8010320c:	8b 45 08             	mov    0x8(%ebp),%eax
8010320f:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103213:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103217:	89 c2                	mov    %eax,%edx
80103219:	ec                   	in     (%dx),%al
8010321a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010321d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103221:	c9                   	leave  
80103222:	c3                   	ret    

80103223 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103223:	55                   	push   %ebp
80103224:	89 e5                	mov    %esp,%ebp
80103226:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103229:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103230:	e8 d1 ff ff ff       	call   80103206 <inb>
80103235:	0f b6 c0             	movzbl %al,%eax
80103238:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
8010323b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010323e:	83 e0 01             	and    $0x1,%eax
80103241:	85 c0                	test   %eax,%eax
80103243:	75 0a                	jne    8010324f <kbdgetc+0x2c>
    return -1;
80103245:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010324a:	e9 25 01 00 00       	jmp    80103374 <kbdgetc+0x151>
  data = inb(KBDATAP);
8010324f:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103256:	e8 ab ff ff ff       	call   80103206 <inb>
8010325b:	0f b6 c0             	movzbl %al,%eax
8010325e:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103261:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103268:	75 17                	jne    80103281 <kbdgetc+0x5e>
    shift |= E0ESC;
8010326a:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010326f:	83 c8 40             	or     $0x40,%eax
80103272:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103277:	b8 00 00 00 00       	mov    $0x0,%eax
8010327c:	e9 f3 00 00 00       	jmp    80103374 <kbdgetc+0x151>
  } else if(data & 0x80){
80103281:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103284:	25 80 00 00 00       	and    $0x80,%eax
80103289:	85 c0                	test   %eax,%eax
8010328b:	74 45                	je     801032d2 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
8010328d:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103292:	83 e0 40             	and    $0x40,%eax
80103295:	85 c0                	test   %eax,%eax
80103297:	75 08                	jne    801032a1 <kbdgetc+0x7e>
80103299:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010329c:	83 e0 7f             	and    $0x7f,%eax
8010329f:	eb 03                	jmp    801032a4 <kbdgetc+0x81>
801032a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801032a4:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
801032a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801032aa:	05 20 a0 10 80       	add    $0x8010a020,%eax
801032af:	0f b6 00             	movzbl (%eax),%eax
801032b2:	83 c8 40             	or     $0x40,%eax
801032b5:	0f b6 c0             	movzbl %al,%eax
801032b8:	f7 d0                	not    %eax
801032ba:	89 c2                	mov    %eax,%edx
801032bc:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801032c1:	21 d0                	and    %edx,%eax
801032c3:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
801032c8:	b8 00 00 00 00       	mov    $0x0,%eax
801032cd:	e9 a2 00 00 00       	jmp    80103374 <kbdgetc+0x151>
  } else if(shift & E0ESC){
801032d2:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801032d7:	83 e0 40             	and    $0x40,%eax
801032da:	85 c0                	test   %eax,%eax
801032dc:	74 14                	je     801032f2 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801032de:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801032e5:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801032ea:	83 e0 bf             	and    $0xffffffbf,%eax
801032ed:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
801032f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801032f5:	05 20 a0 10 80       	add    $0x8010a020,%eax
801032fa:	0f b6 00             	movzbl (%eax),%eax
801032fd:	0f b6 d0             	movzbl %al,%edx
80103300:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103305:	09 d0                	or     %edx,%eax
80103307:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
8010330c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010330f:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103314:	0f b6 00             	movzbl (%eax),%eax
80103317:	0f b6 d0             	movzbl %al,%edx
8010331a:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010331f:	31 d0                	xor    %edx,%eax
80103321:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103326:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010332b:	83 e0 03             	and    $0x3,%eax
8010332e:	8b 14 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%edx
80103335:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103338:	01 d0                	add    %edx,%eax
8010333a:	0f b6 00             	movzbl (%eax),%eax
8010333d:	0f b6 c0             	movzbl %al,%eax
80103340:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103343:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103348:	83 e0 08             	and    $0x8,%eax
8010334b:	85 c0                	test   %eax,%eax
8010334d:	74 22                	je     80103371 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
8010334f:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103353:	76 0c                	jbe    80103361 <kbdgetc+0x13e>
80103355:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103359:	77 06                	ja     80103361 <kbdgetc+0x13e>
      c += 'A' - 'a';
8010335b:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
8010335f:	eb 10                	jmp    80103371 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80103361:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103365:	76 0a                	jbe    80103371 <kbdgetc+0x14e>
80103367:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
8010336b:	77 04                	ja     80103371 <kbdgetc+0x14e>
      c += 'a' - 'A';
8010336d:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103371:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103374:	c9                   	leave  
80103375:	c3                   	ret    

80103376 <kbdintr>:

void
kbdintr(void)
{
80103376:	55                   	push   %ebp
80103377:	89 e5                	mov    %esp,%ebp
80103379:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
8010337c:	c7 04 24 23 32 10 80 	movl   $0x80103223,(%esp)
80103383:	e8 a7 d7 ff ff       	call   80100b2f <consoleintr>
}
80103388:	c9                   	leave  
80103389:	c3                   	ret    

8010338a <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010338a:	55                   	push   %ebp
8010338b:	89 e5                	mov    %esp,%ebp
8010338d:	83 ec 14             	sub    $0x14,%esp
80103390:	8b 45 08             	mov    0x8(%ebp),%eax
80103393:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103397:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010339b:	89 c2                	mov    %eax,%edx
8010339d:	ec                   	in     (%dx),%al
8010339e:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801033a1:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801033a5:	c9                   	leave  
801033a6:	c3                   	ret    

801033a7 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801033a7:	55                   	push   %ebp
801033a8:	89 e5                	mov    %esp,%ebp
801033aa:	83 ec 08             	sub    $0x8,%esp
801033ad:	8b 55 08             	mov    0x8(%ebp),%edx
801033b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801033b3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801033b7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801033ba:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801033be:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801033c2:	ee                   	out    %al,(%dx)
}
801033c3:	c9                   	leave  
801033c4:	c3                   	ret    

801033c5 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801033c5:	55                   	push   %ebp
801033c6:	89 e5                	mov    %esp,%ebp
801033c8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801033cb:	9c                   	pushf  
801033cc:	58                   	pop    %eax
801033cd:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801033d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801033d3:	c9                   	leave  
801033d4:	c3                   	ret    

801033d5 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801033d5:	55                   	push   %ebp
801033d6:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801033d8:	a1 dc 3a 11 80       	mov    0x80113adc,%eax
801033dd:	8b 55 08             	mov    0x8(%ebp),%edx
801033e0:	c1 e2 02             	shl    $0x2,%edx
801033e3:	01 c2                	add    %eax,%edx
801033e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801033e8:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801033ea:	a1 dc 3a 11 80       	mov    0x80113adc,%eax
801033ef:	83 c0 20             	add    $0x20,%eax
801033f2:	8b 00                	mov    (%eax),%eax
}
801033f4:	5d                   	pop    %ebp
801033f5:	c3                   	ret    

801033f6 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
801033f6:	55                   	push   %ebp
801033f7:	89 e5                	mov    %esp,%ebp
801033f9:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801033fc:	a1 dc 3a 11 80       	mov    0x80113adc,%eax
80103401:	85 c0                	test   %eax,%eax
80103403:	75 05                	jne    8010340a <lapicinit+0x14>
    return;
80103405:	e9 43 01 00 00       	jmp    8010354d <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010340a:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103411:	00 
80103412:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103419:	e8 b7 ff ff ff       	call   801033d5 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
8010341e:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103425:	00 
80103426:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
8010342d:	e8 a3 ff ff ff       	call   801033d5 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103432:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103439:	00 
8010343a:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103441:	e8 8f ff ff ff       	call   801033d5 <lapicw>
  lapicw(TICR, 10000000); 
80103446:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
8010344d:	00 
8010344e:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103455:	e8 7b ff ff ff       	call   801033d5 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010345a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103461:	00 
80103462:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103469:	e8 67 ff ff ff       	call   801033d5 <lapicw>
  lapicw(LINT1, MASKED);
8010346e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103475:	00 
80103476:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010347d:	e8 53 ff ff ff       	call   801033d5 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103482:	a1 dc 3a 11 80       	mov    0x80113adc,%eax
80103487:	83 c0 30             	add    $0x30,%eax
8010348a:	8b 00                	mov    (%eax),%eax
8010348c:	c1 e8 10             	shr    $0x10,%eax
8010348f:	0f b6 c0             	movzbl %al,%eax
80103492:	83 f8 03             	cmp    $0x3,%eax
80103495:	76 14                	jbe    801034ab <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80103497:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010349e:	00 
8010349f:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
801034a6:	e8 2a ff ff ff       	call   801033d5 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801034ab:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
801034b2:	00 
801034b3:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
801034ba:	e8 16 ff ff ff       	call   801033d5 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
801034bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034c6:	00 
801034c7:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801034ce:	e8 02 ff ff ff       	call   801033d5 <lapicw>
  lapicw(ESR, 0);
801034d3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034da:	00 
801034db:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801034e2:	e8 ee fe ff ff       	call   801033d5 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801034e7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034ee:	00 
801034ef:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801034f6:	e8 da fe ff ff       	call   801033d5 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801034fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103502:	00 
80103503:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010350a:	e8 c6 fe ff ff       	call   801033d5 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010350f:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80103516:	00 
80103517:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010351e:	e8 b2 fe ff ff       	call   801033d5 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80103523:	90                   	nop
80103524:	a1 dc 3a 11 80       	mov    0x80113adc,%eax
80103529:	05 00 03 00 00       	add    $0x300,%eax
8010352e:	8b 00                	mov    (%eax),%eax
80103530:	25 00 10 00 00       	and    $0x1000,%eax
80103535:	85 c0                	test   %eax,%eax
80103537:	75 eb                	jne    80103524 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103539:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103540:	00 
80103541:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103548:	e8 88 fe ff ff       	call   801033d5 <lapicw>
}
8010354d:	c9                   	leave  
8010354e:	c3                   	ret    

8010354f <cpunum>:

int
cpunum(void)
{
8010354f:	55                   	push   %ebp
80103550:	89 e5                	mov    %esp,%ebp
80103552:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103555:	e8 6b fe ff ff       	call   801033c5 <readeflags>
8010355a:	25 00 02 00 00       	and    $0x200,%eax
8010355f:	85 c0                	test   %eax,%eax
80103561:	74 25                	je     80103588 <cpunum+0x39>
    static int n;
    if(n++ == 0)
80103563:	a1 60 c6 10 80       	mov    0x8010c660,%eax
80103568:	8d 50 01             	lea    0x1(%eax),%edx
8010356b:	89 15 60 c6 10 80    	mov    %edx,0x8010c660
80103571:	85 c0                	test   %eax,%eax
80103573:	75 13                	jne    80103588 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80103575:	8b 45 04             	mov    0x4(%ebp),%eax
80103578:	89 44 24 04          	mov    %eax,0x4(%esp)
8010357c:	c7 04 24 dc 92 10 80 	movl   $0x801092dc,(%esp)
80103583:	e8 18 ce ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103588:	a1 dc 3a 11 80       	mov    0x80113adc,%eax
8010358d:	85 c0                	test   %eax,%eax
8010358f:	74 0f                	je     801035a0 <cpunum+0x51>
    return lapic[ID]>>24;
80103591:	a1 dc 3a 11 80       	mov    0x80113adc,%eax
80103596:	83 c0 20             	add    $0x20,%eax
80103599:	8b 00                	mov    (%eax),%eax
8010359b:	c1 e8 18             	shr    $0x18,%eax
8010359e:	eb 05                	jmp    801035a5 <cpunum+0x56>
  return 0;
801035a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801035a5:	c9                   	leave  
801035a6:	c3                   	ret    

801035a7 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801035a7:	55                   	push   %ebp
801035a8:	89 e5                	mov    %esp,%ebp
801035aa:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801035ad:	a1 dc 3a 11 80       	mov    0x80113adc,%eax
801035b2:	85 c0                	test   %eax,%eax
801035b4:	74 14                	je     801035ca <lapiceoi+0x23>
    lapicw(EOI, 0);
801035b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035bd:	00 
801035be:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801035c5:	e8 0b fe ff ff       	call   801033d5 <lapicw>
}
801035ca:	c9                   	leave  
801035cb:	c3                   	ret    

801035cc <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
801035cc:	55                   	push   %ebp
801035cd:	89 e5                	mov    %esp,%ebp
}
801035cf:	5d                   	pop    %ebp
801035d0:	c3                   	ret    

801035d1 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
801035d1:	55                   	push   %ebp
801035d2:	89 e5                	mov    %esp,%ebp
801035d4:	83 ec 1c             	sub    $0x1c,%esp
801035d7:	8b 45 08             	mov    0x8(%ebp),%eax
801035da:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
801035dd:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801035e4:	00 
801035e5:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801035ec:	e8 b6 fd ff ff       	call   801033a7 <outb>
  outb(CMOS_PORT+1, 0x0A);
801035f1:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801035f8:	00 
801035f9:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103600:	e8 a2 fd ff ff       	call   801033a7 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103605:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
8010360c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010360f:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103614:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103617:	8d 50 02             	lea    0x2(%eax),%edx
8010361a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010361d:	c1 e8 04             	shr    $0x4,%eax
80103620:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103623:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103627:	c1 e0 18             	shl    $0x18,%eax
8010362a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010362e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103635:	e8 9b fd ff ff       	call   801033d5 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010363a:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103641:	00 
80103642:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103649:	e8 87 fd ff ff       	call   801033d5 <lapicw>
  microdelay(200);
8010364e:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103655:	e8 72 ff ff ff       	call   801035cc <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
8010365a:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103661:	00 
80103662:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103669:	e8 67 fd ff ff       	call   801033d5 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
8010366e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103675:	e8 52 ff ff ff       	call   801035cc <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010367a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103681:	eb 40                	jmp    801036c3 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103683:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103687:	c1 e0 18             	shl    $0x18,%eax
8010368a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010368e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103695:	e8 3b fd ff ff       	call   801033d5 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010369a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010369d:	c1 e8 0c             	shr    $0xc,%eax
801036a0:	80 cc 06             	or     $0x6,%ah
801036a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801036a7:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801036ae:	e8 22 fd ff ff       	call   801033d5 <lapicw>
    microdelay(200);
801036b3:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801036ba:	e8 0d ff ff ff       	call   801035cc <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801036bf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801036c3:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801036c7:	7e ba                	jle    80103683 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801036c9:	c9                   	leave  
801036ca:	c3                   	ret    

801036cb <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
801036cb:	55                   	push   %ebp
801036cc:	89 e5                	mov    %esp,%ebp
801036ce:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
801036d1:	8b 45 08             	mov    0x8(%ebp),%eax
801036d4:	0f b6 c0             	movzbl %al,%eax
801036d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801036db:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801036e2:	e8 c0 fc ff ff       	call   801033a7 <outb>
  microdelay(200);
801036e7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801036ee:	e8 d9 fe ff ff       	call   801035cc <microdelay>

  return inb(CMOS_RETURN);
801036f3:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801036fa:	e8 8b fc ff ff       	call   8010338a <inb>
801036ff:	0f b6 c0             	movzbl %al,%eax
}
80103702:	c9                   	leave  
80103703:	c3                   	ret    

80103704 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103704:	55                   	push   %ebp
80103705:	89 e5                	mov    %esp,%ebp
80103707:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
8010370a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103711:	e8 b5 ff ff ff       	call   801036cb <cmos_read>
80103716:	8b 55 08             	mov    0x8(%ebp),%edx
80103719:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
8010371b:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103722:	e8 a4 ff ff ff       	call   801036cb <cmos_read>
80103727:	8b 55 08             	mov    0x8(%ebp),%edx
8010372a:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
8010372d:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80103734:	e8 92 ff ff ff       	call   801036cb <cmos_read>
80103739:	8b 55 08             	mov    0x8(%ebp),%edx
8010373c:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
8010373f:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
80103746:	e8 80 ff ff ff       	call   801036cb <cmos_read>
8010374b:	8b 55 08             	mov    0x8(%ebp),%edx
8010374e:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
80103751:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103758:	e8 6e ff ff ff       	call   801036cb <cmos_read>
8010375d:	8b 55 08             	mov    0x8(%ebp),%edx
80103760:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
80103763:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
8010376a:	e8 5c ff ff ff       	call   801036cb <cmos_read>
8010376f:	8b 55 08             	mov    0x8(%ebp),%edx
80103772:	89 42 14             	mov    %eax,0x14(%edx)
}
80103775:	c9                   	leave  
80103776:	c3                   	ret    

80103777 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80103777:	55                   	push   %ebp
80103778:	89 e5                	mov    %esp,%ebp
8010377a:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010377d:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
80103784:	e8 42 ff ff ff       	call   801036cb <cmos_read>
80103789:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
8010378c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010378f:	83 e0 04             	and    $0x4,%eax
80103792:	85 c0                	test   %eax,%eax
80103794:	0f 94 c0             	sete   %al
80103797:	0f b6 c0             	movzbl %al,%eax
8010379a:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
8010379d:	8d 45 d8             	lea    -0x28(%ebp),%eax
801037a0:	89 04 24             	mov    %eax,(%esp)
801037a3:	e8 5c ff ff ff       	call   80103704 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801037a8:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801037af:	e8 17 ff ff ff       	call   801036cb <cmos_read>
801037b4:	25 80 00 00 00       	and    $0x80,%eax
801037b9:	85 c0                	test   %eax,%eax
801037bb:	74 02                	je     801037bf <cmostime+0x48>
        continue;
801037bd:	eb 36                	jmp    801037f5 <cmostime+0x7e>
    fill_rtcdate(&t2);
801037bf:	8d 45 c0             	lea    -0x40(%ebp),%eax
801037c2:	89 04 24             	mov    %eax,(%esp)
801037c5:	e8 3a ff ff ff       	call   80103704 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
801037ca:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
801037d1:	00 
801037d2:	8d 45 c0             	lea    -0x40(%ebp),%eax
801037d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801037d9:	8d 45 d8             	lea    -0x28(%ebp),%eax
801037dc:	89 04 24             	mov    %eax,(%esp)
801037df:	e8 0f 25 00 00       	call   80105cf3 <memcmp>
801037e4:	85 c0                	test   %eax,%eax
801037e6:	75 0d                	jne    801037f5 <cmostime+0x7e>
      break;
801037e8:	90                   	nop
  }

  // convert
  if (bcd) {
801037e9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801037ed:	0f 84 ac 00 00 00    	je     8010389f <cmostime+0x128>
801037f3:	eb 02                	jmp    801037f7 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801037f5:	eb a6                	jmp    8010379d <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801037f7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801037fa:	c1 e8 04             	shr    $0x4,%eax
801037fd:	89 c2                	mov    %eax,%edx
801037ff:	89 d0                	mov    %edx,%eax
80103801:	c1 e0 02             	shl    $0x2,%eax
80103804:	01 d0                	add    %edx,%eax
80103806:	01 c0                	add    %eax,%eax
80103808:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010380b:	83 e2 0f             	and    $0xf,%edx
8010380e:	01 d0                	add    %edx,%eax
80103810:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103813:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103816:	c1 e8 04             	shr    $0x4,%eax
80103819:	89 c2                	mov    %eax,%edx
8010381b:	89 d0                	mov    %edx,%eax
8010381d:	c1 e0 02             	shl    $0x2,%eax
80103820:	01 d0                	add    %edx,%eax
80103822:	01 c0                	add    %eax,%eax
80103824:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103827:	83 e2 0f             	and    $0xf,%edx
8010382a:	01 d0                	add    %edx,%eax
8010382c:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
8010382f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103832:	c1 e8 04             	shr    $0x4,%eax
80103835:	89 c2                	mov    %eax,%edx
80103837:	89 d0                	mov    %edx,%eax
80103839:	c1 e0 02             	shl    $0x2,%eax
8010383c:	01 d0                	add    %edx,%eax
8010383e:	01 c0                	add    %eax,%eax
80103840:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103843:	83 e2 0f             	and    $0xf,%edx
80103846:	01 d0                	add    %edx,%eax
80103848:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
8010384b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010384e:	c1 e8 04             	shr    $0x4,%eax
80103851:	89 c2                	mov    %eax,%edx
80103853:	89 d0                	mov    %edx,%eax
80103855:	c1 e0 02             	shl    $0x2,%eax
80103858:	01 d0                	add    %edx,%eax
8010385a:	01 c0                	add    %eax,%eax
8010385c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010385f:	83 e2 0f             	and    $0xf,%edx
80103862:	01 d0                	add    %edx,%eax
80103864:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103867:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010386a:	c1 e8 04             	shr    $0x4,%eax
8010386d:	89 c2                	mov    %eax,%edx
8010386f:	89 d0                	mov    %edx,%eax
80103871:	c1 e0 02             	shl    $0x2,%eax
80103874:	01 d0                	add    %edx,%eax
80103876:	01 c0                	add    %eax,%eax
80103878:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010387b:	83 e2 0f             	and    $0xf,%edx
8010387e:	01 d0                	add    %edx,%eax
80103880:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
80103883:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103886:	c1 e8 04             	shr    $0x4,%eax
80103889:	89 c2                	mov    %eax,%edx
8010388b:	89 d0                	mov    %edx,%eax
8010388d:	c1 e0 02             	shl    $0x2,%eax
80103890:	01 d0                	add    %edx,%eax
80103892:	01 c0                	add    %eax,%eax
80103894:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103897:	83 e2 0f             	and    $0xf,%edx
8010389a:	01 d0                	add    %edx,%eax
8010389c:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
8010389f:	8b 45 08             	mov    0x8(%ebp),%eax
801038a2:	8b 55 d8             	mov    -0x28(%ebp),%edx
801038a5:	89 10                	mov    %edx,(%eax)
801038a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
801038aa:	89 50 04             	mov    %edx,0x4(%eax)
801038ad:	8b 55 e0             	mov    -0x20(%ebp),%edx
801038b0:	89 50 08             	mov    %edx,0x8(%eax)
801038b3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801038b6:	89 50 0c             	mov    %edx,0xc(%eax)
801038b9:	8b 55 e8             	mov    -0x18(%ebp),%edx
801038bc:	89 50 10             	mov    %edx,0x10(%eax)
801038bf:	8b 55 ec             	mov    -0x14(%ebp),%edx
801038c2:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
801038c5:	8b 45 08             	mov    0x8(%ebp),%eax
801038c8:	8b 40 14             	mov    0x14(%eax),%eax
801038cb:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
801038d1:	8b 45 08             	mov    0x8(%ebp),%eax
801038d4:	89 50 14             	mov    %edx,0x14(%eax)
}
801038d7:	c9                   	leave  
801038d8:	c3                   	ret    

801038d9 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
801038d9:	55                   	push   %ebp
801038da:	89 e5                	mov    %esp,%ebp
801038dc:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801038df:	c7 44 24 04 08 93 10 	movl   $0x80109308,0x4(%esp)
801038e6:	80 
801038e7:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
801038ee:	e8 14 21 00 00       	call   80105a07 <initlock>
  readsb(dev, &sb);
801038f3:	8d 45 dc             	lea    -0x24(%ebp),%eax
801038f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801038fa:	8b 45 08             	mov    0x8(%ebp),%eax
801038fd:	89 04 24             	mov    %eax,(%esp)
80103900:	e8 28 e0 ff ff       	call   8010192d <readsb>
  log.start = sb.logstart;
80103905:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103908:	a3 14 3b 11 80       	mov    %eax,0x80113b14
  log.size = sb.nlog;
8010390d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103910:	a3 18 3b 11 80       	mov    %eax,0x80113b18
  log.dev = dev;
80103915:	8b 45 08             	mov    0x8(%ebp),%eax
80103918:	a3 24 3b 11 80       	mov    %eax,0x80113b24
  recover_from_log();
8010391d:	e8 9a 01 00 00       	call   80103abc <recover_from_log>
}
80103922:	c9                   	leave  
80103923:	c3                   	ret    

80103924 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103924:	55                   	push   %ebp
80103925:	89 e5                	mov    %esp,%ebp
80103927:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010392a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103931:	e9 8c 00 00 00       	jmp    801039c2 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103936:	8b 15 14 3b 11 80    	mov    0x80113b14,%edx
8010393c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010393f:	01 d0                	add    %edx,%eax
80103941:	83 c0 01             	add    $0x1,%eax
80103944:	89 c2                	mov    %eax,%edx
80103946:	a1 24 3b 11 80       	mov    0x80113b24,%eax
8010394b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010394f:	89 04 24             	mov    %eax,(%esp)
80103952:	e8 4f c8 ff ff       	call   801001a6 <bread>
80103957:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010395a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010395d:	83 c0 10             	add    $0x10,%eax
80103960:	8b 04 85 ec 3a 11 80 	mov    -0x7feec514(,%eax,4),%eax
80103967:	89 c2                	mov    %eax,%edx
80103969:	a1 24 3b 11 80       	mov    0x80113b24,%eax
8010396e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103972:	89 04 24             	mov    %eax,(%esp)
80103975:	e8 2c c8 ff ff       	call   801001a6 <bread>
8010397a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
8010397d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103980:	8d 50 18             	lea    0x18(%eax),%edx
80103983:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103986:	83 c0 18             	add    $0x18,%eax
80103989:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103990:	00 
80103991:	89 54 24 04          	mov    %edx,0x4(%esp)
80103995:	89 04 24             	mov    %eax,(%esp)
80103998:	e8 ae 23 00 00       	call   80105d4b <memmove>
    bwrite(dbuf);  // write dst to disk
8010399d:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039a0:	89 04 24             	mov    %eax,(%esp)
801039a3:	e8 35 c8 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801039a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039ab:	89 04 24             	mov    %eax,(%esp)
801039ae:	e8 64 c8 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801039b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039b6:	89 04 24             	mov    %eax,(%esp)
801039b9:	e8 59 c8 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801039be:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801039c2:	a1 28 3b 11 80       	mov    0x80113b28,%eax
801039c7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801039ca:	0f 8f 66 ff ff ff    	jg     80103936 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
801039d0:	c9                   	leave  
801039d1:	c3                   	ret    

801039d2 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801039d2:	55                   	push   %ebp
801039d3:	89 e5                	mov    %esp,%ebp
801039d5:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801039d8:	a1 14 3b 11 80       	mov    0x80113b14,%eax
801039dd:	89 c2                	mov    %eax,%edx
801039df:	a1 24 3b 11 80       	mov    0x80113b24,%eax
801039e4:	89 54 24 04          	mov    %edx,0x4(%esp)
801039e8:	89 04 24             	mov    %eax,(%esp)
801039eb:	e8 b6 c7 ff ff       	call   801001a6 <bread>
801039f0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801039f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039f6:	83 c0 18             	add    $0x18,%eax
801039f9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801039fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039ff:	8b 00                	mov    (%eax),%eax
80103a01:	a3 28 3b 11 80       	mov    %eax,0x80113b28
  for (i = 0; i < log.lh.n; i++) {
80103a06:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a0d:	eb 1b                	jmp    80103a2a <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103a0f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a12:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103a15:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103a19:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103a1c:	83 c2 10             	add    $0x10,%edx
80103a1f:	89 04 95 ec 3a 11 80 	mov    %eax,-0x7feec514(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103a26:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a2a:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103a2f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a32:	7f db                	jg     80103a0f <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
80103a34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a37:	89 04 24             	mov    %eax,(%esp)
80103a3a:	e8 d8 c7 ff ff       	call   80100217 <brelse>
}
80103a3f:	c9                   	leave  
80103a40:	c3                   	ret    

80103a41 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103a41:	55                   	push   %ebp
80103a42:	89 e5                	mov    %esp,%ebp
80103a44:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103a47:	a1 14 3b 11 80       	mov    0x80113b14,%eax
80103a4c:	89 c2                	mov    %eax,%edx
80103a4e:	a1 24 3b 11 80       	mov    0x80113b24,%eax
80103a53:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a57:	89 04 24             	mov    %eax,(%esp)
80103a5a:	e8 47 c7 ff ff       	call   801001a6 <bread>
80103a5f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103a62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a65:	83 c0 18             	add    $0x18,%eax
80103a68:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103a6b:	8b 15 28 3b 11 80    	mov    0x80113b28,%edx
80103a71:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a74:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103a76:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a7d:	eb 1b                	jmp    80103a9a <write_head+0x59>
    hb->block[i] = log.lh.block[i];
80103a7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a82:	83 c0 10             	add    $0x10,%eax
80103a85:	8b 0c 85 ec 3a 11 80 	mov    -0x7feec514(,%eax,4),%ecx
80103a8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a8f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103a92:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103a96:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a9a:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103a9f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103aa2:	7f db                	jg     80103a7f <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103aa4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aa7:	89 04 24             	mov    %eax,(%esp)
80103aaa:	e8 2e c7 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103aaf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ab2:	89 04 24             	mov    %eax,(%esp)
80103ab5:	e8 5d c7 ff ff       	call   80100217 <brelse>
}
80103aba:	c9                   	leave  
80103abb:	c3                   	ret    

80103abc <recover_from_log>:

static void
recover_from_log(void)
{
80103abc:	55                   	push   %ebp
80103abd:	89 e5                	mov    %esp,%ebp
80103abf:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103ac2:	e8 0b ff ff ff       	call   801039d2 <read_head>
  install_trans(); // if committed, copy from log to disk
80103ac7:	e8 58 fe ff ff       	call   80103924 <install_trans>
  log.lh.n = 0;
80103acc:	c7 05 28 3b 11 80 00 	movl   $0x0,0x80113b28
80103ad3:	00 00 00 
  write_head(); // clear the log
80103ad6:	e8 66 ff ff ff       	call   80103a41 <write_head>
}
80103adb:	c9                   	leave  
80103adc:	c3                   	ret    

80103add <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103add:	55                   	push   %ebp
80103ade:	89 e5                	mov    %esp,%ebp
80103ae0:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103ae3:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103aea:	e8 39 1f 00 00       	call   80105a28 <acquire>
  while(1){
    if(log.committing){
80103aef:	a1 20 3b 11 80       	mov    0x80113b20,%eax
80103af4:	85 c0                	test   %eax,%eax
80103af6:	74 16                	je     80103b0e <begin_op+0x31>
      sleep(&log, &log.lock);
80103af8:	c7 44 24 04 e0 3a 11 	movl   $0x80113ae0,0x4(%esp)
80103aff:	80 
80103b00:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103b07:	e8 26 1c 00 00       	call   80105732 <sleep>
80103b0c:	eb 4f                	jmp    80103b5d <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103b0e:	8b 0d 28 3b 11 80    	mov    0x80113b28,%ecx
80103b14:	a1 1c 3b 11 80       	mov    0x80113b1c,%eax
80103b19:	8d 50 01             	lea    0x1(%eax),%edx
80103b1c:	89 d0                	mov    %edx,%eax
80103b1e:	c1 e0 02             	shl    $0x2,%eax
80103b21:	01 d0                	add    %edx,%eax
80103b23:	01 c0                	add    %eax,%eax
80103b25:	01 c8                	add    %ecx,%eax
80103b27:	83 f8 1e             	cmp    $0x1e,%eax
80103b2a:	7e 16                	jle    80103b42 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103b2c:	c7 44 24 04 e0 3a 11 	movl   $0x80113ae0,0x4(%esp)
80103b33:	80 
80103b34:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103b3b:	e8 f2 1b 00 00       	call   80105732 <sleep>
80103b40:	eb 1b                	jmp    80103b5d <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103b42:	a1 1c 3b 11 80       	mov    0x80113b1c,%eax
80103b47:	83 c0 01             	add    $0x1,%eax
80103b4a:	a3 1c 3b 11 80       	mov    %eax,0x80113b1c
      release(&log.lock);
80103b4f:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103b56:	e8 2f 1f 00 00       	call   80105a8a <release>
      break;
80103b5b:	eb 02                	jmp    80103b5f <begin_op+0x82>
    }
  }
80103b5d:	eb 90                	jmp    80103aef <begin_op+0x12>
}
80103b5f:	c9                   	leave  
80103b60:	c3                   	ret    

80103b61 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103b61:	55                   	push   %ebp
80103b62:	89 e5                	mov    %esp,%ebp
80103b64:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
80103b67:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103b6e:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103b75:	e8 ae 1e 00 00       	call   80105a28 <acquire>
  log.outstanding -= 1;
80103b7a:	a1 1c 3b 11 80       	mov    0x80113b1c,%eax
80103b7f:	83 e8 01             	sub    $0x1,%eax
80103b82:	a3 1c 3b 11 80       	mov    %eax,0x80113b1c
  if(log.committing)
80103b87:	a1 20 3b 11 80       	mov    0x80113b20,%eax
80103b8c:	85 c0                	test   %eax,%eax
80103b8e:	74 0c                	je     80103b9c <end_op+0x3b>
    panic("log.committing");
80103b90:	c7 04 24 0c 93 10 80 	movl   $0x8010930c,(%esp)
80103b97:	e8 9e c9 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103b9c:	a1 1c 3b 11 80       	mov    0x80113b1c,%eax
80103ba1:	85 c0                	test   %eax,%eax
80103ba3:	75 13                	jne    80103bb8 <end_op+0x57>
    do_commit = 1;
80103ba5:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103bac:	c7 05 20 3b 11 80 01 	movl   $0x1,0x80113b20
80103bb3:	00 00 00 
80103bb6:	eb 0c                	jmp    80103bc4 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103bb8:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103bbf:	e8 62 1c 00 00       	call   80105826 <wakeup>
  }
  release(&log.lock);
80103bc4:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103bcb:	e8 ba 1e 00 00       	call   80105a8a <release>

  if(do_commit){
80103bd0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103bd4:	74 33                	je     80103c09 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103bd6:	e8 de 00 00 00       	call   80103cb9 <commit>
    acquire(&log.lock);
80103bdb:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103be2:	e8 41 1e 00 00       	call   80105a28 <acquire>
    log.committing = 0;
80103be7:	c7 05 20 3b 11 80 00 	movl   $0x0,0x80113b20
80103bee:	00 00 00 
    wakeup(&log);
80103bf1:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103bf8:	e8 29 1c 00 00       	call   80105826 <wakeup>
    release(&log.lock);
80103bfd:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103c04:	e8 81 1e 00 00       	call   80105a8a <release>
  }
}
80103c09:	c9                   	leave  
80103c0a:	c3                   	ret    

80103c0b <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103c0b:	55                   	push   %ebp
80103c0c:	89 e5                	mov    %esp,%ebp
80103c0e:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103c11:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103c18:	e9 8c 00 00 00       	jmp    80103ca9 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103c1d:	8b 15 14 3b 11 80    	mov    0x80113b14,%edx
80103c23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c26:	01 d0                	add    %edx,%eax
80103c28:	83 c0 01             	add    $0x1,%eax
80103c2b:	89 c2                	mov    %eax,%edx
80103c2d:	a1 24 3b 11 80       	mov    0x80113b24,%eax
80103c32:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c36:	89 04 24             	mov    %eax,(%esp)
80103c39:	e8 68 c5 ff ff       	call   801001a6 <bread>
80103c3e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103c41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c44:	83 c0 10             	add    $0x10,%eax
80103c47:	8b 04 85 ec 3a 11 80 	mov    -0x7feec514(,%eax,4),%eax
80103c4e:	89 c2                	mov    %eax,%edx
80103c50:	a1 24 3b 11 80       	mov    0x80113b24,%eax
80103c55:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c59:	89 04 24             	mov    %eax,(%esp)
80103c5c:	e8 45 c5 ff ff       	call   801001a6 <bread>
80103c61:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103c64:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c67:	8d 50 18             	lea    0x18(%eax),%edx
80103c6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c6d:	83 c0 18             	add    $0x18,%eax
80103c70:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103c77:	00 
80103c78:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c7c:	89 04 24             	mov    %eax,(%esp)
80103c7f:	e8 c7 20 00 00       	call   80105d4b <memmove>
    bwrite(to);  // write the log
80103c84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c87:	89 04 24             	mov    %eax,(%esp)
80103c8a:	e8 4e c5 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103c8f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c92:	89 04 24             	mov    %eax,(%esp)
80103c95:	e8 7d c5 ff ff       	call   80100217 <brelse>
    brelse(to);
80103c9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c9d:	89 04 24             	mov    %eax,(%esp)
80103ca0:	e8 72 c5 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103ca5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103ca9:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103cae:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103cb1:	0f 8f 66 ff ff ff    	jg     80103c1d <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103cb7:	c9                   	leave  
80103cb8:	c3                   	ret    

80103cb9 <commit>:

static void
commit()
{
80103cb9:	55                   	push   %ebp
80103cba:	89 e5                	mov    %esp,%ebp
80103cbc:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103cbf:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103cc4:	85 c0                	test   %eax,%eax
80103cc6:	7e 1e                	jle    80103ce6 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103cc8:	e8 3e ff ff ff       	call   80103c0b <write_log>
    write_head();    // Write header to disk -- the real commit
80103ccd:	e8 6f fd ff ff       	call   80103a41 <write_head>
    install_trans(); // Now install writes to home locations
80103cd2:	e8 4d fc ff ff       	call   80103924 <install_trans>
    log.lh.n = 0; 
80103cd7:	c7 05 28 3b 11 80 00 	movl   $0x0,0x80113b28
80103cde:	00 00 00 
    write_head();    // Erase the transaction from the log
80103ce1:	e8 5b fd ff ff       	call   80103a41 <write_head>
  }
}
80103ce6:	c9                   	leave  
80103ce7:	c3                   	ret    

80103ce8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103ce8:	55                   	push   %ebp
80103ce9:	89 e5                	mov    %esp,%ebp
80103ceb:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103cee:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103cf3:	83 f8 1d             	cmp    $0x1d,%eax
80103cf6:	7f 12                	jg     80103d0a <log_write+0x22>
80103cf8:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103cfd:	8b 15 18 3b 11 80    	mov    0x80113b18,%edx
80103d03:	83 ea 01             	sub    $0x1,%edx
80103d06:	39 d0                	cmp    %edx,%eax
80103d08:	7c 0c                	jl     80103d16 <log_write+0x2e>
    panic("too big a transaction");
80103d0a:	c7 04 24 1b 93 10 80 	movl   $0x8010931b,(%esp)
80103d11:	e8 24 c8 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103d16:	a1 1c 3b 11 80       	mov    0x80113b1c,%eax
80103d1b:	85 c0                	test   %eax,%eax
80103d1d:	7f 0c                	jg     80103d2b <log_write+0x43>
    panic("log_write outside of trans");
80103d1f:	c7 04 24 31 93 10 80 	movl   $0x80109331,(%esp)
80103d26:	e8 0f c8 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103d2b:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103d32:	e8 f1 1c 00 00       	call   80105a28 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103d37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103d3e:	eb 1f                	jmp    80103d5f <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103d40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d43:	83 c0 10             	add    $0x10,%eax
80103d46:	8b 04 85 ec 3a 11 80 	mov    -0x7feec514(,%eax,4),%eax
80103d4d:	89 c2                	mov    %eax,%edx
80103d4f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d52:	8b 40 08             	mov    0x8(%eax),%eax
80103d55:	39 c2                	cmp    %eax,%edx
80103d57:	75 02                	jne    80103d5b <log_write+0x73>
      break;
80103d59:	eb 0e                	jmp    80103d69 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103d5b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d5f:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103d64:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d67:	7f d7                	jg     80103d40 <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103d69:	8b 45 08             	mov    0x8(%ebp),%eax
80103d6c:	8b 40 08             	mov    0x8(%eax),%eax
80103d6f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d72:	83 c2 10             	add    $0x10,%edx
80103d75:	89 04 95 ec 3a 11 80 	mov    %eax,-0x7feec514(,%edx,4)
  if (i == log.lh.n)
80103d7c:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103d81:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d84:	75 0d                	jne    80103d93 <log_write+0xab>
    log.lh.n++;
80103d86:	a1 28 3b 11 80       	mov    0x80113b28,%eax
80103d8b:	83 c0 01             	add    $0x1,%eax
80103d8e:	a3 28 3b 11 80       	mov    %eax,0x80113b28
  b->flags |= B_DIRTY; // prevent eviction
80103d93:	8b 45 08             	mov    0x8(%ebp),%eax
80103d96:	8b 00                	mov    (%eax),%eax
80103d98:	83 c8 04             	or     $0x4,%eax
80103d9b:	89 c2                	mov    %eax,%edx
80103d9d:	8b 45 08             	mov    0x8(%ebp),%eax
80103da0:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103da2:	c7 04 24 e0 3a 11 80 	movl   $0x80113ae0,(%esp)
80103da9:	e8 dc 1c 00 00       	call   80105a8a <release>
}
80103dae:	c9                   	leave  
80103daf:	c3                   	ret    

80103db0 <v2p>:
80103db0:	55                   	push   %ebp
80103db1:	89 e5                	mov    %esp,%ebp
80103db3:	8b 45 08             	mov    0x8(%ebp),%eax
80103db6:	05 00 00 00 80       	add    $0x80000000,%eax
80103dbb:	5d                   	pop    %ebp
80103dbc:	c3                   	ret    

80103dbd <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103dbd:	55                   	push   %ebp
80103dbe:	89 e5                	mov    %esp,%ebp
80103dc0:	8b 45 08             	mov    0x8(%ebp),%eax
80103dc3:	05 00 00 00 80       	add    $0x80000000,%eax
80103dc8:	5d                   	pop    %ebp
80103dc9:	c3                   	ret    

80103dca <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103dca:	55                   	push   %ebp
80103dcb:	89 e5                	mov    %esp,%ebp
80103dcd:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103dd0:	8b 55 08             	mov    0x8(%ebp),%edx
80103dd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dd6:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103dd9:	f0 87 02             	lock xchg %eax,(%edx)
80103ddc:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103ddf:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103de2:	c9                   	leave  
80103de3:	c3                   	ret    

80103de4 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103de4:	55                   	push   %ebp
80103de5:	89 e5                	mov    %esp,%ebp
80103de7:	83 e4 f0             	and    $0xfffffff0,%esp
80103dea:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103ded:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103df4:	80 
80103df5:	c7 04 24 fc 72 11 80 	movl   $0x801172fc,(%esp)
80103dfc:	e8 8a f2 ff ff       	call   8010308b <kinit1>
  kvmalloc();      // kernel page table
80103e01:	e8 d7 4a 00 00       	call   801088dd <kvmalloc>
  mpinit();        // collect info about this machine
80103e06:	e8 41 04 00 00       	call   8010424c <mpinit>
  lapicinit();
80103e0b:	e8 e6 f5 ff ff       	call   801033f6 <lapicinit>
  seginit();       // set up segments
80103e10:	e8 5b 44 00 00       	call   80108270 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103e15:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103e1b:	0f b6 00             	movzbl (%eax),%eax
80103e1e:	0f b6 c0             	movzbl %al,%eax
80103e21:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e25:	c7 04 24 4c 93 10 80 	movl   $0x8010934c,(%esp)
80103e2c:	e8 6f c5 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103e31:	e8 74 06 00 00       	call   801044aa <picinit>
  ioapicinit();    // another interrupt controller
80103e36:	e8 46 f1 ff ff       	call   80102f81 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103e3b:	e8 d8 d1 ff ff       	call   80101018 <consoleinit>
  uartinit();      // serial port
80103e40:	e8 7a 37 00 00       	call   801075bf <uartinit>
  pinit();         // process table
80103e45:	e8 b4 0d 00 00       	call   80104bfe <pinit>
  tvinit();        // trap vectors
80103e4a:	e8 ec 32 00 00       	call   8010713b <tvinit>
  binit();         // buffer cache
80103e4f:	e8 e0 c1 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103e54:	e8 ed d6 ff ff       	call   80101546 <fileinit>
  ideinit();       // disk
80103e59:	e8 55 ed ff ff       	call   80102bb3 <ideinit>
  if(!ismp)
80103e5e:	a1 c4 3b 11 80       	mov    0x80113bc4,%eax
80103e63:	85 c0                	test   %eax,%eax
80103e65:	75 05                	jne    80103e6c <main+0x88>
    timerinit();   // uniprocessor timer
80103e67:	e8 1a 32 00 00       	call   80107086 <timerinit>
  startothers();   // start other processors
80103e6c:	e8 7f 00 00 00       	call   80103ef0 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103e71:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103e78:	8e 
80103e79:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103e80:	e8 3e f2 ff ff       	call   801030c3 <kinit2>
  userinit();      // first user process
80103e85:	e8 97 0e 00 00       	call   80104d21 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103e8a:	e8 1a 00 00 00       	call   80103ea9 <mpmain>

80103e8f <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103e8f:	55                   	push   %ebp
80103e90:	89 e5                	mov    %esp,%ebp
80103e92:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103e95:	e8 5a 4a 00 00       	call   801088f4 <switchkvm>
  seginit();
80103e9a:	e8 d1 43 00 00       	call   80108270 <seginit>
  lapicinit();
80103e9f:	e8 52 f5 ff ff       	call   801033f6 <lapicinit>
  mpmain();
80103ea4:	e8 00 00 00 00       	call   80103ea9 <mpmain>

80103ea9 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103ea9:	55                   	push   %ebp
80103eaa:	89 e5                	mov    %esp,%ebp
80103eac:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103eaf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103eb5:	0f b6 00             	movzbl (%eax),%eax
80103eb8:	0f b6 c0             	movzbl %al,%eax
80103ebb:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ebf:	c7 04 24 63 93 10 80 	movl   $0x80109363,(%esp)
80103ec6:	e8 d5 c4 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103ecb:	e8 df 33 00 00       	call   801072af <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103ed0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ed6:	05 a8 00 00 00       	add    $0xa8,%eax
80103edb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103ee2:	00 
80103ee3:	89 04 24             	mov    %eax,(%esp)
80103ee6:	e8 df fe ff ff       	call   80103dca <xchg>
  scheduler();     // start running processes
80103eeb:	e8 68 16 00 00       	call   80105558 <scheduler>

80103ef0 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103ef0:	55                   	push   %ebp
80103ef1:	89 e5                	mov    %esp,%ebp
80103ef3:	53                   	push   %ebx
80103ef4:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103ef7:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103efe:	e8 ba fe ff ff       	call   80103dbd <p2v>
80103f03:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103f06:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103f0b:	89 44 24 08          	mov    %eax,0x8(%esp)
80103f0f:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80103f16:	80 
80103f17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f1a:	89 04 24             	mov    %eax,(%esp)
80103f1d:	e8 29 1e 00 00       	call   80105d4b <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103f22:	c7 45 f4 e0 3b 11 80 	movl   $0x80113be0,-0xc(%ebp)
80103f29:	e9 85 00 00 00       	jmp    80103fb3 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103f2e:	e8 1c f6 ff ff       	call   8010354f <cpunum>
80103f33:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103f39:	05 e0 3b 11 80       	add    $0x80113be0,%eax
80103f3e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103f41:	75 02                	jne    80103f45 <startothers+0x55>
      continue;
80103f43:	eb 67                	jmp    80103fac <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103f45:	e8 6f f2 ff ff       	call   801031b9 <kalloc>
80103f4a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103f4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f50:	83 e8 04             	sub    $0x4,%eax
80103f53:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103f56:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103f5c:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103f5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f61:	83 e8 08             	sub    $0x8,%eax
80103f64:	c7 00 8f 3e 10 80    	movl   $0x80103e8f,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103f6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f6d:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103f70:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80103f77:	e8 34 fe ff ff       	call   80103db0 <v2p>
80103f7c:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103f7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f81:	89 04 24             	mov    %eax,(%esp)
80103f84:	e8 27 fe ff ff       	call   80103db0 <v2p>
80103f89:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f8c:	0f b6 12             	movzbl (%edx),%edx
80103f8f:	0f b6 d2             	movzbl %dl,%edx
80103f92:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f96:	89 14 24             	mov    %edx,(%esp)
80103f99:	e8 33 f6 ff ff       	call   801035d1 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103f9e:	90                   	nop
80103f9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fa2:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103fa8:	85 c0                	test   %eax,%eax
80103faa:	74 f3                	je     80103f9f <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103fac:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103fb3:	a1 c0 41 11 80       	mov    0x801141c0,%eax
80103fb8:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103fbe:	05 e0 3b 11 80       	add    $0x80113be0,%eax
80103fc3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103fc6:	0f 87 62 ff ff ff    	ja     80103f2e <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103fcc:	83 c4 24             	add    $0x24,%esp
80103fcf:	5b                   	pop    %ebx
80103fd0:	5d                   	pop    %ebp
80103fd1:	c3                   	ret    

80103fd2 <p2v>:
80103fd2:	55                   	push   %ebp
80103fd3:	89 e5                	mov    %esp,%ebp
80103fd5:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd8:	05 00 00 00 80       	add    $0x80000000,%eax
80103fdd:	5d                   	pop    %ebp
80103fde:	c3                   	ret    

80103fdf <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103fdf:	55                   	push   %ebp
80103fe0:	89 e5                	mov    %esp,%ebp
80103fe2:	83 ec 14             	sub    $0x14,%esp
80103fe5:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe8:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103fec:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103ff0:	89 c2                	mov    %eax,%edx
80103ff2:	ec                   	in     (%dx),%al
80103ff3:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103ff6:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103ffa:	c9                   	leave  
80103ffb:	c3                   	ret    

80103ffc <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103ffc:	55                   	push   %ebp
80103ffd:	89 e5                	mov    %esp,%ebp
80103fff:	83 ec 08             	sub    $0x8,%esp
80104002:	8b 55 08             	mov    0x8(%ebp),%edx
80104005:	8b 45 0c             	mov    0xc(%ebp),%eax
80104008:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010400c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010400f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104013:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104017:	ee                   	out    %al,(%dx)
}
80104018:	c9                   	leave  
80104019:	c3                   	ret    

8010401a <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
8010401a:	55                   	push   %ebp
8010401b:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
8010401d:	a1 64 c6 10 80       	mov    0x8010c664,%eax
80104022:	89 c2                	mov    %eax,%edx
80104024:	b8 e0 3b 11 80       	mov    $0x80113be0,%eax
80104029:	29 c2                	sub    %eax,%edx
8010402b:	89 d0                	mov    %edx,%eax
8010402d:	c1 f8 02             	sar    $0x2,%eax
80104030:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80104036:	5d                   	pop    %ebp
80104037:	c3                   	ret    

80104038 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104038:	55                   	push   %ebp
80104039:	89 e5                	mov    %esp,%ebp
8010403b:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010403e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104045:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010404c:	eb 15                	jmp    80104063 <sum+0x2b>
    sum += addr[i];
8010404e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104051:	8b 45 08             	mov    0x8(%ebp),%eax
80104054:	01 d0                	add    %edx,%eax
80104056:	0f b6 00             	movzbl (%eax),%eax
80104059:	0f b6 c0             	movzbl %al,%eax
8010405c:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010405f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104063:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104066:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104069:	7c e3                	jl     8010404e <sum+0x16>
    sum += addr[i];
  return sum;
8010406b:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010406e:	c9                   	leave  
8010406f:	c3                   	ret    

80104070 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80104070:	55                   	push   %ebp
80104071:	89 e5                	mov    %esp,%ebp
80104073:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104076:	8b 45 08             	mov    0x8(%ebp),%eax
80104079:	89 04 24             	mov    %eax,(%esp)
8010407c:	e8 51 ff ff ff       	call   80103fd2 <p2v>
80104081:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104084:	8b 55 0c             	mov    0xc(%ebp),%edx
80104087:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010408a:	01 d0                	add    %edx,%eax
8010408c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010408f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104092:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104095:	eb 3f                	jmp    801040d6 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104097:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010409e:	00 
8010409f:	c7 44 24 04 74 93 10 	movl   $0x80109374,0x4(%esp)
801040a6:	80 
801040a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040aa:	89 04 24             	mov    %eax,(%esp)
801040ad:	e8 41 1c 00 00       	call   80105cf3 <memcmp>
801040b2:	85 c0                	test   %eax,%eax
801040b4:	75 1c                	jne    801040d2 <mpsearch1+0x62>
801040b6:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801040bd:	00 
801040be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040c1:	89 04 24             	mov    %eax,(%esp)
801040c4:	e8 6f ff ff ff       	call   80104038 <sum>
801040c9:	84 c0                	test   %al,%al
801040cb:	75 05                	jne    801040d2 <mpsearch1+0x62>
      return (struct mp*)p;
801040cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040d0:	eb 11                	jmp    801040e3 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801040d2:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801040d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040d9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801040dc:	72 b9                	jb     80104097 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801040de:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040e3:	c9                   	leave  
801040e4:	c3                   	ret    

801040e5 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801040e5:	55                   	push   %ebp
801040e6:	89 e5                	mov    %esp,%ebp
801040e8:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801040eb:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801040f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040f5:	83 c0 0f             	add    $0xf,%eax
801040f8:	0f b6 00             	movzbl (%eax),%eax
801040fb:	0f b6 c0             	movzbl %al,%eax
801040fe:	c1 e0 08             	shl    $0x8,%eax
80104101:	89 c2                	mov    %eax,%edx
80104103:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104106:	83 c0 0e             	add    $0xe,%eax
80104109:	0f b6 00             	movzbl (%eax),%eax
8010410c:	0f b6 c0             	movzbl %al,%eax
8010410f:	09 d0                	or     %edx,%eax
80104111:	c1 e0 04             	shl    $0x4,%eax
80104114:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104117:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010411b:	74 21                	je     8010413e <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
8010411d:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104124:	00 
80104125:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104128:	89 04 24             	mov    %eax,(%esp)
8010412b:	e8 40 ff ff ff       	call   80104070 <mpsearch1>
80104130:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104133:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104137:	74 50                	je     80104189 <mpsearch+0xa4>
      return mp;
80104139:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010413c:	eb 5f                	jmp    8010419d <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010413e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104141:	83 c0 14             	add    $0x14,%eax
80104144:	0f b6 00             	movzbl (%eax),%eax
80104147:	0f b6 c0             	movzbl %al,%eax
8010414a:	c1 e0 08             	shl    $0x8,%eax
8010414d:	89 c2                	mov    %eax,%edx
8010414f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104152:	83 c0 13             	add    $0x13,%eax
80104155:	0f b6 00             	movzbl (%eax),%eax
80104158:	0f b6 c0             	movzbl %al,%eax
8010415b:	09 d0                	or     %edx,%eax
8010415d:	c1 e0 0a             	shl    $0xa,%eax
80104160:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104163:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104166:	2d 00 04 00 00       	sub    $0x400,%eax
8010416b:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104172:	00 
80104173:	89 04 24             	mov    %eax,(%esp)
80104176:	e8 f5 fe ff ff       	call   80104070 <mpsearch1>
8010417b:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010417e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104182:	74 05                	je     80104189 <mpsearch+0xa4>
      return mp;
80104184:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104187:	eb 14                	jmp    8010419d <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104189:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104190:	00 
80104191:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104198:	e8 d3 fe ff ff       	call   80104070 <mpsearch1>
}
8010419d:	c9                   	leave  
8010419e:	c3                   	ret    

8010419f <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
8010419f:	55                   	push   %ebp
801041a0:	89 e5                	mov    %esp,%ebp
801041a2:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
801041a5:	e8 3b ff ff ff       	call   801040e5 <mpsearch>
801041aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801041ad:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801041b1:	74 0a                	je     801041bd <mpconfig+0x1e>
801041b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b6:	8b 40 04             	mov    0x4(%eax),%eax
801041b9:	85 c0                	test   %eax,%eax
801041bb:	75 0a                	jne    801041c7 <mpconfig+0x28>
    return 0;
801041bd:	b8 00 00 00 00       	mov    $0x0,%eax
801041c2:	e9 83 00 00 00       	jmp    8010424a <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801041c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ca:	8b 40 04             	mov    0x4(%eax),%eax
801041cd:	89 04 24             	mov    %eax,(%esp)
801041d0:	e8 fd fd ff ff       	call   80103fd2 <p2v>
801041d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801041d8:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801041df:	00 
801041e0:	c7 44 24 04 79 93 10 	movl   $0x80109379,0x4(%esp)
801041e7:	80 
801041e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041eb:	89 04 24             	mov    %eax,(%esp)
801041ee:	e8 00 1b 00 00       	call   80105cf3 <memcmp>
801041f3:	85 c0                	test   %eax,%eax
801041f5:	74 07                	je     801041fe <mpconfig+0x5f>
    return 0;
801041f7:	b8 00 00 00 00       	mov    $0x0,%eax
801041fc:	eb 4c                	jmp    8010424a <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801041fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104201:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104205:	3c 01                	cmp    $0x1,%al
80104207:	74 12                	je     8010421b <mpconfig+0x7c>
80104209:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010420c:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104210:	3c 04                	cmp    $0x4,%al
80104212:	74 07                	je     8010421b <mpconfig+0x7c>
    return 0;
80104214:	b8 00 00 00 00       	mov    $0x0,%eax
80104219:	eb 2f                	jmp    8010424a <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
8010421b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010421e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104222:	0f b7 c0             	movzwl %ax,%eax
80104225:	89 44 24 04          	mov    %eax,0x4(%esp)
80104229:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010422c:	89 04 24             	mov    %eax,(%esp)
8010422f:	e8 04 fe ff ff       	call   80104038 <sum>
80104234:	84 c0                	test   %al,%al
80104236:	74 07                	je     8010423f <mpconfig+0xa0>
    return 0;
80104238:	b8 00 00 00 00       	mov    $0x0,%eax
8010423d:	eb 0b                	jmp    8010424a <mpconfig+0xab>
  *pmp = mp;
8010423f:	8b 45 08             	mov    0x8(%ebp),%eax
80104242:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104245:	89 10                	mov    %edx,(%eax)
  return conf;
80104247:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010424a:	c9                   	leave  
8010424b:	c3                   	ret    

8010424c <mpinit>:

void
mpinit(void)
{
8010424c:	55                   	push   %ebp
8010424d:	89 e5                	mov    %esp,%ebp
8010424f:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104252:	c7 05 64 c6 10 80 e0 	movl   $0x80113be0,0x8010c664
80104259:	3b 11 80 
  if((conf = mpconfig(&mp)) == 0)
8010425c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010425f:	89 04 24             	mov    %eax,(%esp)
80104262:	e8 38 ff ff ff       	call   8010419f <mpconfig>
80104267:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010426a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010426e:	75 05                	jne    80104275 <mpinit+0x29>
    return;
80104270:	e9 9c 01 00 00       	jmp    80104411 <mpinit+0x1c5>
  ismp = 1;
80104275:	c7 05 c4 3b 11 80 01 	movl   $0x1,0x80113bc4
8010427c:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
8010427f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104282:	8b 40 24             	mov    0x24(%eax),%eax
80104285:	a3 dc 3a 11 80       	mov    %eax,0x80113adc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010428a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010428d:	83 c0 2c             	add    $0x2c,%eax
80104290:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104293:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104296:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010429a:	0f b7 d0             	movzwl %ax,%edx
8010429d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042a0:	01 d0                	add    %edx,%eax
801042a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
801042a5:	e9 f4 00 00 00       	jmp    8010439e <mpinit+0x152>
    switch(*p){
801042aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042ad:	0f b6 00             	movzbl (%eax),%eax
801042b0:	0f b6 c0             	movzbl %al,%eax
801042b3:	83 f8 04             	cmp    $0x4,%eax
801042b6:	0f 87 bf 00 00 00    	ja     8010437b <mpinit+0x12f>
801042bc:	8b 04 85 bc 93 10 80 	mov    -0x7fef6c44(,%eax,4),%eax
801042c3:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
801042c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042c8:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801042cb:	8b 45 e8             	mov    -0x18(%ebp),%eax
801042ce:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801042d2:	0f b6 d0             	movzbl %al,%edx
801042d5:	a1 c0 41 11 80       	mov    0x801141c0,%eax
801042da:	39 c2                	cmp    %eax,%edx
801042dc:	74 2d                	je     8010430b <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801042de:	8b 45 e8             	mov    -0x18(%ebp),%eax
801042e1:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801042e5:	0f b6 d0             	movzbl %al,%edx
801042e8:	a1 c0 41 11 80       	mov    0x801141c0,%eax
801042ed:	89 54 24 08          	mov    %edx,0x8(%esp)
801042f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801042f5:	c7 04 24 7e 93 10 80 	movl   $0x8010937e,(%esp)
801042fc:	e8 9f c0 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80104301:	c7 05 c4 3b 11 80 00 	movl   $0x0,0x80113bc4
80104308:	00 00 00 
      }
      if(proc->flags & MPBOOT)
8010430b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010430e:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104312:	0f b6 c0             	movzbl %al,%eax
80104315:	83 e0 02             	and    $0x2,%eax
80104318:	85 c0                	test   %eax,%eax
8010431a:	74 15                	je     80104331 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
8010431c:	a1 c0 41 11 80       	mov    0x801141c0,%eax
80104321:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104327:	05 e0 3b 11 80       	add    $0x80113be0,%eax
8010432c:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104331:	8b 15 c0 41 11 80    	mov    0x801141c0,%edx
80104337:	a1 c0 41 11 80       	mov    0x801141c0,%eax
8010433c:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104342:	81 c2 e0 3b 11 80    	add    $0x80113be0,%edx
80104348:	88 02                	mov    %al,(%edx)
      ncpu++;
8010434a:	a1 c0 41 11 80       	mov    0x801141c0,%eax
8010434f:	83 c0 01             	add    $0x1,%eax
80104352:	a3 c0 41 11 80       	mov    %eax,0x801141c0
      p += sizeof(struct mpproc);
80104357:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
8010435b:	eb 41                	jmp    8010439e <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
8010435d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104360:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104363:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104366:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010436a:	a2 c0 3b 11 80       	mov    %al,0x80113bc0
      p += sizeof(struct mpioapic);
8010436f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104373:	eb 29                	jmp    8010439e <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104375:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104379:	eb 23                	jmp    8010439e <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
8010437b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010437e:	0f b6 00             	movzbl (%eax),%eax
80104381:	0f b6 c0             	movzbl %al,%eax
80104384:	89 44 24 04          	mov    %eax,0x4(%esp)
80104388:	c7 04 24 9c 93 10 80 	movl   $0x8010939c,(%esp)
8010438f:	e8 0c c0 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80104394:	c7 05 c4 3b 11 80 00 	movl   $0x0,0x80113bc4
8010439b:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010439e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043a1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801043a4:	0f 82 00 ff ff ff    	jb     801042aa <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
801043aa:	a1 c4 3b 11 80       	mov    0x80113bc4,%eax
801043af:	85 c0                	test   %eax,%eax
801043b1:	75 1d                	jne    801043d0 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
801043b3:	c7 05 c0 41 11 80 01 	movl   $0x1,0x801141c0
801043ba:	00 00 00 
    lapic = 0;
801043bd:	c7 05 dc 3a 11 80 00 	movl   $0x0,0x80113adc
801043c4:	00 00 00 
    ioapicid = 0;
801043c7:	c6 05 c0 3b 11 80 00 	movb   $0x0,0x80113bc0
    return;
801043ce:	eb 41                	jmp    80104411 <mpinit+0x1c5>
  }

  if(mp->imcrp){
801043d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043d3:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
801043d7:	84 c0                	test   %al,%al
801043d9:	74 36                	je     80104411 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
801043db:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801043e2:	00 
801043e3:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801043ea:	e8 0d fc ff ff       	call   80103ffc <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801043ef:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801043f6:	e8 e4 fb ff ff       	call   80103fdf <inb>
801043fb:	83 c8 01             	or     $0x1,%eax
801043fe:	0f b6 c0             	movzbl %al,%eax
80104401:	89 44 24 04          	mov    %eax,0x4(%esp)
80104405:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
8010440c:	e8 eb fb ff ff       	call   80103ffc <outb>
  }
}
80104411:	c9                   	leave  
80104412:	c3                   	ret    

80104413 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104413:	55                   	push   %ebp
80104414:	89 e5                	mov    %esp,%ebp
80104416:	83 ec 08             	sub    $0x8,%esp
80104419:	8b 55 08             	mov    0x8(%ebp),%edx
8010441c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010441f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104423:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104426:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010442a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010442e:	ee                   	out    %al,(%dx)
}
8010442f:	c9                   	leave  
80104430:	c3                   	ret    

80104431 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104431:	55                   	push   %ebp
80104432:	89 e5                	mov    %esp,%ebp
80104434:	83 ec 0c             	sub    $0xc,%esp
80104437:	8b 45 08             	mov    0x8(%ebp),%eax
8010443a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
8010443e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104442:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104448:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010444c:	0f b6 c0             	movzbl %al,%eax
8010444f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104453:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010445a:	e8 b4 ff ff ff       	call   80104413 <outb>
  outb(IO_PIC2+1, mask >> 8);
8010445f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104463:	66 c1 e8 08          	shr    $0x8,%ax
80104467:	0f b6 c0             	movzbl %al,%eax
8010446a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010446e:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104475:	e8 99 ff ff ff       	call   80104413 <outb>
}
8010447a:	c9                   	leave  
8010447b:	c3                   	ret    

8010447c <picenable>:

void
picenable(int irq)
{
8010447c:	55                   	push   %ebp
8010447d:	89 e5                	mov    %esp,%ebp
8010447f:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104482:	8b 45 08             	mov    0x8(%ebp),%eax
80104485:	ba 01 00 00 00       	mov    $0x1,%edx
8010448a:	89 c1                	mov    %eax,%ecx
8010448c:	d3 e2                	shl    %cl,%edx
8010448e:	89 d0                	mov    %edx,%eax
80104490:	f7 d0                	not    %eax
80104492:	89 c2                	mov    %eax,%edx
80104494:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010449b:	21 d0                	and    %edx,%eax
8010449d:	0f b7 c0             	movzwl %ax,%eax
801044a0:	89 04 24             	mov    %eax,(%esp)
801044a3:	e8 89 ff ff ff       	call   80104431 <picsetmask>
}
801044a8:	c9                   	leave  
801044a9:	c3                   	ret    

801044aa <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
801044aa:	55                   	push   %ebp
801044ab:	89 e5                	mov    %esp,%ebp
801044ad:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
801044b0:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801044b7:	00 
801044b8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801044bf:	e8 4f ff ff ff       	call   80104413 <outb>
  outb(IO_PIC2+1, 0xFF);
801044c4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801044cb:	00 
801044cc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801044d3:	e8 3b ff ff ff       	call   80104413 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801044d8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801044df:	00 
801044e0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801044e7:	e8 27 ff ff ff       	call   80104413 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801044ec:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801044f3:	00 
801044f4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801044fb:	e8 13 ff ff ff       	call   80104413 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104500:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104507:	00 
80104508:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010450f:	e8 ff fe ff ff       	call   80104413 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104514:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010451b:	00 
8010451c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104523:	e8 eb fe ff ff       	call   80104413 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104528:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010452f:	00 
80104530:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104537:	e8 d7 fe ff ff       	call   80104413 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
8010453c:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104543:	00 
80104544:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010454b:	e8 c3 fe ff ff       	call   80104413 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104550:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104557:	00 
80104558:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010455f:	e8 af fe ff ff       	call   80104413 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104564:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010456b:	00 
8010456c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104573:	e8 9b fe ff ff       	call   80104413 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104578:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010457f:	00 
80104580:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104587:	e8 87 fe ff ff       	call   80104413 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
8010458c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104593:	00 
80104594:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010459b:	e8 73 fe ff ff       	call   80104413 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
801045a0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801045a7:	00 
801045a8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801045af:	e8 5f fe ff ff       	call   80104413 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
801045b4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801045bb:	00 
801045bc:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801045c3:	e8 4b fe ff ff       	call   80104413 <outb>

  if(irqmask != 0xFFFF)
801045c8:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801045cf:	66 83 f8 ff          	cmp    $0xffff,%ax
801045d3:	74 12                	je     801045e7 <picinit+0x13d>
    picsetmask(irqmask);
801045d5:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801045dc:	0f b7 c0             	movzwl %ax,%eax
801045df:	89 04 24             	mov    %eax,(%esp)
801045e2:	e8 4a fe ff ff       	call   80104431 <picsetmask>
}
801045e7:	c9                   	leave  
801045e8:	c3                   	ret    

801045e9 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801045e9:	55                   	push   %ebp
801045ea:	89 e5                	mov    %esp,%ebp
801045ec:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801045ef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801045f6:	8b 45 0c             	mov    0xc(%ebp),%eax
801045f9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801045ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80104602:	8b 10                	mov    (%eax),%edx
80104604:	8b 45 08             	mov    0x8(%ebp),%eax
80104607:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104609:	e8 54 cf ff ff       	call   80101562 <filealloc>
8010460e:	8b 55 08             	mov    0x8(%ebp),%edx
80104611:	89 02                	mov    %eax,(%edx)
80104613:	8b 45 08             	mov    0x8(%ebp),%eax
80104616:	8b 00                	mov    (%eax),%eax
80104618:	85 c0                	test   %eax,%eax
8010461a:	0f 84 c8 00 00 00    	je     801046e8 <pipealloc+0xff>
80104620:	e8 3d cf ff ff       	call   80101562 <filealloc>
80104625:	8b 55 0c             	mov    0xc(%ebp),%edx
80104628:	89 02                	mov    %eax,(%edx)
8010462a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010462d:	8b 00                	mov    (%eax),%eax
8010462f:	85 c0                	test   %eax,%eax
80104631:	0f 84 b1 00 00 00    	je     801046e8 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104637:	e8 7d eb ff ff       	call   801031b9 <kalloc>
8010463c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010463f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104643:	75 05                	jne    8010464a <pipealloc+0x61>
    goto bad;
80104645:	e9 9e 00 00 00       	jmp    801046e8 <pipealloc+0xff>
  p->readopen = 1;
8010464a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010464d:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104654:	00 00 00 
  p->writeopen = 1;
80104657:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010465a:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104661:	00 00 00 
  p->nwrite = 0;
80104664:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104667:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
8010466e:	00 00 00 
  p->nread = 0;
80104671:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104674:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
8010467b:	00 00 00 
  initlock(&p->lock, "pipe");
8010467e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104681:	c7 44 24 04 d0 93 10 	movl   $0x801093d0,0x4(%esp)
80104688:	80 
80104689:	89 04 24             	mov    %eax,(%esp)
8010468c:	e8 76 13 00 00       	call   80105a07 <initlock>
  (*f0)->type = FD_PIPE;
80104691:	8b 45 08             	mov    0x8(%ebp),%eax
80104694:	8b 00                	mov    (%eax),%eax
80104696:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
8010469c:	8b 45 08             	mov    0x8(%ebp),%eax
8010469f:	8b 00                	mov    (%eax),%eax
801046a1:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801046a5:	8b 45 08             	mov    0x8(%ebp),%eax
801046a8:	8b 00                	mov    (%eax),%eax
801046aa:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801046ae:	8b 45 08             	mov    0x8(%ebp),%eax
801046b1:	8b 00                	mov    (%eax),%eax
801046b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046b6:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
801046b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801046bc:	8b 00                	mov    (%eax),%eax
801046be:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801046c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801046c7:	8b 00                	mov    (%eax),%eax
801046c9:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801046cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801046d0:	8b 00                	mov    (%eax),%eax
801046d2:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801046d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801046d9:	8b 00                	mov    (%eax),%eax
801046db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046de:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801046e1:	b8 00 00 00 00       	mov    $0x0,%eax
801046e6:	eb 42                	jmp    8010472a <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
801046e8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046ec:	74 0b                	je     801046f9 <pipealloc+0x110>
    kfree((char*)p);
801046ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046f1:	89 04 24             	mov    %eax,(%esp)
801046f4:	e8 27 ea ff ff       	call   80103120 <kfree>
  if(*f0)
801046f9:	8b 45 08             	mov    0x8(%ebp),%eax
801046fc:	8b 00                	mov    (%eax),%eax
801046fe:	85 c0                	test   %eax,%eax
80104700:	74 0d                	je     8010470f <pipealloc+0x126>
    fileclose(*f0);
80104702:	8b 45 08             	mov    0x8(%ebp),%eax
80104705:	8b 00                	mov    (%eax),%eax
80104707:	89 04 24             	mov    %eax,(%esp)
8010470a:	e8 fb ce ff ff       	call   8010160a <fileclose>
  if(*f1)
8010470f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104712:	8b 00                	mov    (%eax),%eax
80104714:	85 c0                	test   %eax,%eax
80104716:	74 0d                	je     80104725 <pipealloc+0x13c>
    fileclose(*f1);
80104718:	8b 45 0c             	mov    0xc(%ebp),%eax
8010471b:	8b 00                	mov    (%eax),%eax
8010471d:	89 04 24             	mov    %eax,(%esp)
80104720:	e8 e5 ce ff ff       	call   8010160a <fileclose>
  return -1;
80104725:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010472a:	c9                   	leave  
8010472b:	c3                   	ret    

8010472c <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010472c:	55                   	push   %ebp
8010472d:	89 e5                	mov    %esp,%ebp
8010472f:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104732:	8b 45 08             	mov    0x8(%ebp),%eax
80104735:	89 04 24             	mov    %eax,(%esp)
80104738:	e8 eb 12 00 00       	call   80105a28 <acquire>
  if(writable){
8010473d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104741:	74 1f                	je     80104762 <pipeclose+0x36>
    p->writeopen = 0;
80104743:	8b 45 08             	mov    0x8(%ebp),%eax
80104746:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
8010474d:	00 00 00 
    wakeup(&p->nread);
80104750:	8b 45 08             	mov    0x8(%ebp),%eax
80104753:	05 34 02 00 00       	add    $0x234,%eax
80104758:	89 04 24             	mov    %eax,(%esp)
8010475b:	e8 c6 10 00 00       	call   80105826 <wakeup>
80104760:	eb 1d                	jmp    8010477f <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104762:	8b 45 08             	mov    0x8(%ebp),%eax
80104765:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
8010476c:	00 00 00 
    wakeup(&p->nwrite);
8010476f:	8b 45 08             	mov    0x8(%ebp),%eax
80104772:	05 38 02 00 00       	add    $0x238,%eax
80104777:	89 04 24             	mov    %eax,(%esp)
8010477a:	e8 a7 10 00 00       	call   80105826 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010477f:	8b 45 08             	mov    0x8(%ebp),%eax
80104782:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104788:	85 c0                	test   %eax,%eax
8010478a:	75 25                	jne    801047b1 <pipeclose+0x85>
8010478c:	8b 45 08             	mov    0x8(%ebp),%eax
8010478f:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104795:	85 c0                	test   %eax,%eax
80104797:	75 18                	jne    801047b1 <pipeclose+0x85>
    release(&p->lock);
80104799:	8b 45 08             	mov    0x8(%ebp),%eax
8010479c:	89 04 24             	mov    %eax,(%esp)
8010479f:	e8 e6 12 00 00       	call   80105a8a <release>
    kfree((char*)p);
801047a4:	8b 45 08             	mov    0x8(%ebp),%eax
801047a7:	89 04 24             	mov    %eax,(%esp)
801047aa:	e8 71 e9 ff ff       	call   80103120 <kfree>
801047af:	eb 0b                	jmp    801047bc <pipeclose+0x90>
  } else
    release(&p->lock);
801047b1:	8b 45 08             	mov    0x8(%ebp),%eax
801047b4:	89 04 24             	mov    %eax,(%esp)
801047b7:	e8 ce 12 00 00       	call   80105a8a <release>
}
801047bc:	c9                   	leave  
801047bd:	c3                   	ret    

801047be <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
801047be:	55                   	push   %ebp
801047bf:	89 e5                	mov    %esp,%ebp
801047c1:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
801047c4:	8b 45 08             	mov    0x8(%ebp),%eax
801047c7:	89 04 24             	mov    %eax,(%esp)
801047ca:	e8 59 12 00 00       	call   80105a28 <acquire>
  for(i = 0; i < n; i++){
801047cf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801047d6:	e9 a6 00 00 00       	jmp    80104881 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801047db:	eb 57                	jmp    80104834 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
801047dd:	8b 45 08             	mov    0x8(%ebp),%eax
801047e0:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801047e6:	85 c0                	test   %eax,%eax
801047e8:	74 0d                	je     801047f7 <pipewrite+0x39>
801047ea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047f0:	8b 40 24             	mov    0x24(%eax),%eax
801047f3:	85 c0                	test   %eax,%eax
801047f5:	74 15                	je     8010480c <pipewrite+0x4e>
        release(&p->lock);
801047f7:	8b 45 08             	mov    0x8(%ebp),%eax
801047fa:	89 04 24             	mov    %eax,(%esp)
801047fd:	e8 88 12 00 00       	call   80105a8a <release>
        return -1;
80104802:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104807:	e9 9f 00 00 00       	jmp    801048ab <pipewrite+0xed>
      }
      wakeup(&p->nread);
8010480c:	8b 45 08             	mov    0x8(%ebp),%eax
8010480f:	05 34 02 00 00       	add    $0x234,%eax
80104814:	89 04 24             	mov    %eax,(%esp)
80104817:	e8 0a 10 00 00       	call   80105826 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010481c:	8b 45 08             	mov    0x8(%ebp),%eax
8010481f:	8b 55 08             	mov    0x8(%ebp),%edx
80104822:	81 c2 38 02 00 00    	add    $0x238,%edx
80104828:	89 44 24 04          	mov    %eax,0x4(%esp)
8010482c:	89 14 24             	mov    %edx,(%esp)
8010482f:	e8 fe 0e 00 00       	call   80105732 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104834:	8b 45 08             	mov    0x8(%ebp),%eax
80104837:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
8010483d:	8b 45 08             	mov    0x8(%ebp),%eax
80104840:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104846:	05 00 02 00 00       	add    $0x200,%eax
8010484b:	39 c2                	cmp    %eax,%edx
8010484d:	74 8e                	je     801047dd <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010484f:	8b 45 08             	mov    0x8(%ebp),%eax
80104852:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104858:	8d 48 01             	lea    0x1(%eax),%ecx
8010485b:	8b 55 08             	mov    0x8(%ebp),%edx
8010485e:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104864:	25 ff 01 00 00       	and    $0x1ff,%eax
80104869:	89 c1                	mov    %eax,%ecx
8010486b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010486e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104871:	01 d0                	add    %edx,%eax
80104873:	0f b6 10             	movzbl (%eax),%edx
80104876:	8b 45 08             	mov    0x8(%ebp),%eax
80104879:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
8010487d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104881:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104884:	3b 45 10             	cmp    0x10(%ebp),%eax
80104887:	0f 8c 4e ff ff ff    	jl     801047db <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010488d:	8b 45 08             	mov    0x8(%ebp),%eax
80104890:	05 34 02 00 00       	add    $0x234,%eax
80104895:	89 04 24             	mov    %eax,(%esp)
80104898:	e8 89 0f 00 00       	call   80105826 <wakeup>
  release(&p->lock);
8010489d:	8b 45 08             	mov    0x8(%ebp),%eax
801048a0:	89 04 24             	mov    %eax,(%esp)
801048a3:	e8 e2 11 00 00       	call   80105a8a <release>
  return n;
801048a8:	8b 45 10             	mov    0x10(%ebp),%eax
}
801048ab:	c9                   	leave  
801048ac:	c3                   	ret    

801048ad <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801048ad:	55                   	push   %ebp
801048ae:	89 e5                	mov    %esp,%ebp
801048b0:	53                   	push   %ebx
801048b1:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801048b4:	8b 45 08             	mov    0x8(%ebp),%eax
801048b7:	89 04 24             	mov    %eax,(%esp)
801048ba:	e8 69 11 00 00       	call   80105a28 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801048bf:	eb 3a                	jmp    801048fb <piperead+0x4e>
    if(proc->killed){
801048c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048c7:	8b 40 24             	mov    0x24(%eax),%eax
801048ca:	85 c0                	test   %eax,%eax
801048cc:	74 15                	je     801048e3 <piperead+0x36>
      release(&p->lock);
801048ce:	8b 45 08             	mov    0x8(%ebp),%eax
801048d1:	89 04 24             	mov    %eax,(%esp)
801048d4:	e8 b1 11 00 00       	call   80105a8a <release>
      return -1;
801048d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048de:	e9 b5 00 00 00       	jmp    80104998 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801048e3:	8b 45 08             	mov    0x8(%ebp),%eax
801048e6:	8b 55 08             	mov    0x8(%ebp),%edx
801048e9:	81 c2 34 02 00 00    	add    $0x234,%edx
801048ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801048f3:	89 14 24             	mov    %edx,(%esp)
801048f6:	e8 37 0e 00 00       	call   80105732 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801048fb:	8b 45 08             	mov    0x8(%ebp),%eax
801048fe:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104904:	8b 45 08             	mov    0x8(%ebp),%eax
80104907:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010490d:	39 c2                	cmp    %eax,%edx
8010490f:	75 0d                	jne    8010491e <piperead+0x71>
80104911:	8b 45 08             	mov    0x8(%ebp),%eax
80104914:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010491a:	85 c0                	test   %eax,%eax
8010491c:	75 a3                	jne    801048c1 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010491e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104925:	eb 4b                	jmp    80104972 <piperead+0xc5>
    if(p->nread == p->nwrite)
80104927:	8b 45 08             	mov    0x8(%ebp),%eax
8010492a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104930:	8b 45 08             	mov    0x8(%ebp),%eax
80104933:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104939:	39 c2                	cmp    %eax,%edx
8010493b:	75 02                	jne    8010493f <piperead+0x92>
      break;
8010493d:	eb 3b                	jmp    8010497a <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010493f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104942:	8b 45 0c             	mov    0xc(%ebp),%eax
80104945:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104948:	8b 45 08             	mov    0x8(%ebp),%eax
8010494b:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104951:	8d 48 01             	lea    0x1(%eax),%ecx
80104954:	8b 55 08             	mov    0x8(%ebp),%edx
80104957:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
8010495d:	25 ff 01 00 00       	and    $0x1ff,%eax
80104962:	89 c2                	mov    %eax,%edx
80104964:	8b 45 08             	mov    0x8(%ebp),%eax
80104967:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
8010496c:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010496e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104972:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104975:	3b 45 10             	cmp    0x10(%ebp),%eax
80104978:	7c ad                	jl     80104927 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010497a:	8b 45 08             	mov    0x8(%ebp),%eax
8010497d:	05 38 02 00 00       	add    $0x238,%eax
80104982:	89 04 24             	mov    %eax,(%esp)
80104985:	e8 9c 0e 00 00       	call   80105826 <wakeup>
  release(&p->lock);
8010498a:	8b 45 08             	mov    0x8(%ebp),%eax
8010498d:	89 04 24             	mov    %eax,(%esp)
80104990:	e8 f5 10 00 00       	call   80105a8a <release>
  return i;
80104995:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104998:	83 c4 24             	add    $0x24,%esp
8010499b:	5b                   	pop    %ebx
8010499c:	5d                   	pop    %ebp
8010499d:	c3                   	ret    

8010499e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010499e:	55                   	push   %ebp
8010499f:	89 e5                	mov    %esp,%ebp
801049a1:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801049a4:	9c                   	pushf  
801049a5:	58                   	pop    %eax
801049a6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801049a9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801049ac:	c9                   	leave  
801049ad:	c3                   	ret    

801049ae <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801049ae:	55                   	push   %ebp
801049af:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801049b1:	fb                   	sti    
}
801049b2:	5d                   	pop    %ebp
801049b3:	c3                   	ret    

801049b4 <queue_init>:
  int tail;
  int head;
  struct proc* proc[QUEUE_SIZE];
} queue; 

void queue_init(queue* q) {
801049b4:	55                   	push   %ebp
801049b5:	89 e5                	mov    %esp,%ebp
  q->tail = 0;
801049b7:	8b 45 08             	mov    0x8(%ebp),%eax
801049ba:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  q->count = 0;
801049c1:	8b 45 08             	mov    0x8(%ebp),%eax
801049c4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  q->head = 0;
801049ca:	8b 45 08             	mov    0x8(%ebp),%eax
801049cd:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
801049d4:	5d                   	pop    %ebp
801049d5:	c3                   	ret    

801049d6 <enqueue>:

void enqueue(queue* q, struct proc* p){
801049d6:	55                   	push   %ebp
801049d7:	89 e5                	mov    %esp,%ebp
  q->proc[q->tail] = p;
801049d9:	8b 45 08             	mov    0x8(%ebp),%eax
801049dc:	8b 50 04             	mov    0x4(%eax),%edx
801049df:	8b 45 08             	mov    0x8(%ebp),%eax
801049e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801049e5:	89 4c 90 0c          	mov    %ecx,0xc(%eax,%edx,4)
  q->tail = (q->tail + 1) % QUEUE_SIZE;
801049e9:	8b 45 08             	mov    0x8(%ebp),%eax
801049ec:	8b 40 04             	mov    0x4(%eax),%eax
801049ef:	8d 50 01             	lea    0x1(%eax),%edx
801049f2:	89 d0                	mov    %edx,%eax
801049f4:	c1 f8 1f             	sar    $0x1f,%eax
801049f7:	c1 e8 1a             	shr    $0x1a,%eax
801049fa:	01 c2                	add    %eax,%edx
801049fc:	83 e2 3f             	and    $0x3f,%edx
801049ff:	29 c2                	sub    %eax,%edx
80104a01:	89 d0                	mov    %edx,%eax
80104a03:	89 c2                	mov    %eax,%edx
80104a05:	8b 45 08             	mov    0x8(%ebp),%eax
80104a08:	89 50 04             	mov    %edx,0x4(%eax)
  ++q->count;
80104a0b:	8b 45 08             	mov    0x8(%ebp),%eax
80104a0e:	8b 00                	mov    (%eax),%eax
80104a10:	8d 50 01             	lea    0x1(%eax),%edx
80104a13:	8b 45 08             	mov    0x8(%ebp),%eax
80104a16:	89 10                	mov    %edx,(%eax)
}
80104a18:	5d                   	pop    %ebp
80104a19:	c3                   	ret    

80104a1a <dequeue>:

struct proc * dequeue(queue* q) {
80104a1a:	55                   	push   %ebp
80104a1b:	89 e5                	mov    %esp,%ebp
80104a1d:	83 ec 10             	sub    $0x10,%esp
 struct proc* tmp = q->proc[q->head]; 
80104a20:	8b 45 08             	mov    0x8(%ebp),%eax
80104a23:	8b 50 08             	mov    0x8(%eax),%edx
80104a26:	8b 45 08             	mov    0x8(%ebp),%eax
80104a29:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80104a2d:	89 45 fc             	mov    %eax,-0x4(%ebp)
 --q->count;
80104a30:	8b 45 08             	mov    0x8(%ebp),%eax
80104a33:	8b 00                	mov    (%eax),%eax
80104a35:	8d 50 ff             	lea    -0x1(%eax),%edx
80104a38:	8b 45 08             	mov    0x8(%ebp),%eax
80104a3b:	89 10                	mov    %edx,(%eax)
 q->head = (q->head + 1) % QUEUE_SIZE;
80104a3d:	8b 45 08             	mov    0x8(%ebp),%eax
80104a40:	8b 40 08             	mov    0x8(%eax),%eax
80104a43:	8d 50 01             	lea    0x1(%eax),%edx
80104a46:	89 d0                	mov    %edx,%eax
80104a48:	c1 f8 1f             	sar    $0x1f,%eax
80104a4b:	c1 e8 1a             	shr    $0x1a,%eax
80104a4e:	01 c2                	add    %eax,%edx
80104a50:	83 e2 3f             	and    $0x3f,%edx
80104a53:	29 c2                	sub    %eax,%edx
80104a55:	89 d0                	mov    %edx,%eax
80104a57:	89 c2                	mov    %eax,%edx
80104a59:	8b 45 08             	mov    0x8(%ebp),%eax
80104a5c:	89 50 08             	mov    %edx,0x8(%eax)
 return tmp;
80104a5f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104a62:	c9                   	leave  
80104a63:	c3                   	ret    

80104a64 <multi_level_enq>:
  queue pr1;
  queue pr2;
  queue pr3;
} multi_level_queue;

void multi_level_enq(multi_level_queue* q, struct proc * p) {
80104a64:	55                   	push   %ebp
80104a65:	89 e5                	mov    %esp,%ebp
80104a67:	83 ec 08             	sub    $0x8,%esp
 switch (p->priority) {
80104a6a:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a6d:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80104a73:	83 f8 01             	cmp    $0x1,%eax
80104a76:	74 07                	je     80104a7f <multi_level_enq+0x1b>
80104a78:	83 f8 02             	cmp    $0x2,%eax
80104a7b:	74 16                	je     80104a93 <multi_level_enq+0x2f>
80104a7d:	eb 2e                	jmp    80104aad <multi_level_enq+0x49>
    case LOW_PRIO:
      enqueue(&q->pr1, p);
80104a7f:	8b 45 08             	mov    0x8(%ebp),%eax
80104a82:	8b 55 0c             	mov    0xc(%ebp),%edx
80104a85:	89 54 24 04          	mov    %edx,0x4(%esp)
80104a89:	89 04 24             	mov    %eax,(%esp)
80104a8c:	e8 45 ff ff ff       	call   801049d6 <enqueue>
    break;
80104a91:	eb 32                	jmp    80104ac5 <multi_level_enq+0x61>
    
    case MED_PRIO:
      enqueue(&q->pr2, p);
80104a93:	8b 45 08             	mov    0x8(%ebp),%eax
80104a96:	8d 90 0c 01 00 00    	lea    0x10c(%eax),%edx
80104a9c:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a9f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104aa3:	89 14 24             	mov    %edx,(%esp)
80104aa6:	e8 2b ff ff ff       	call   801049d6 <enqueue>
    break;
80104aab:	eb 18                	jmp    80104ac5 <multi_level_enq+0x61>
    case HIGH_PRIO:
    default: 
      enqueue(&q->pr3, p);
80104aad:	8b 45 08             	mov    0x8(%ebp),%eax
80104ab0:	8d 90 18 02 00 00    	lea    0x218(%eax),%edx
80104ab6:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ab9:	89 44 24 04          	mov    %eax,0x4(%esp)
80104abd:	89 14 24             	mov    %edx,(%esp)
80104ac0:	e8 11 ff ff ff       	call   801049d6 <enqueue>
 }
} 
80104ac5:	c9                   	leave  
80104ac6:	c3                   	ret    

80104ac7 <multi_level_dequeue>:

struct proc* multi_level_dequeue(multi_level_queue* q) {
80104ac7:	55                   	push   %ebp
80104ac8:	89 e5                	mov    %esp,%ebp
80104aca:	83 ec 04             	sub    $0x4,%esp
  return (q->pr1.count > 0) ? dequeue(&q->pr1) :
80104acd:	8b 45 08             	mov    0x8(%ebp),%eax
80104ad0:	8b 00                	mov    (%eax),%eax
80104ad2:	85 c0                	test   %eax,%eax
80104ad4:	7e 0d                	jle    80104ae3 <multi_level_dequeue+0x1c>
80104ad6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ad9:	89 04 24             	mov    %eax,(%esp)
80104adc:	e8 39 ff ff ff       	call   80104a1a <dequeue>
80104ae1:	eb 43                	jmp    80104b26 <multi_level_dequeue+0x5f>
         (q->pr2.count > 0) ? dequeue(&q->pr2) :
80104ae3:	8b 45 08             	mov    0x8(%ebp),%eax
80104ae6:	8b 80 0c 01 00 00    	mov    0x10c(%eax),%eax
80104aec:	85 c0                	test   %eax,%eax
80104aee:	7e 12                	jle    80104b02 <multi_level_dequeue+0x3b>
80104af0:	8b 45 08             	mov    0x8(%ebp),%eax
80104af3:	05 0c 01 00 00       	add    $0x10c,%eax
80104af8:	89 04 24             	mov    %eax,(%esp)
80104afb:	e8 1a ff ff ff       	call   80104a1a <dequeue>
80104b00:	eb 24                	jmp    80104b26 <multi_level_dequeue+0x5f>
         (q->pr3.count > 0) ? dequeue(&q->pr3) : 0;
80104b02:	8b 45 08             	mov    0x8(%ebp),%eax
80104b05:	8b 80 18 02 00 00    	mov    0x218(%eax),%eax
80104b0b:	85 c0                	test   %eax,%eax
80104b0d:	7e 12                	jle    80104b21 <multi_level_dequeue+0x5a>
80104b0f:	8b 45 08             	mov    0x8(%ebp),%eax
80104b12:	05 18 02 00 00       	add    $0x218,%eax
80104b17:	89 04 24             	mov    %eax,(%esp)
80104b1a:	e8 fb fe ff ff       	call   80104a1a <dequeue>
80104b1f:	eb 05                	jmp    80104b26 <multi_level_dequeue+0x5f>
80104b21:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b26:	c9                   	leave  
80104b27:	c3                   	ret    

80104b28 <fcfs_dequeue>:

struct proc* fcfs_dequeue(queue* q) {
80104b28:	55                   	push   %ebp
80104b29:	89 e5                	mov    %esp,%ebp
80104b2b:	83 ec 10             	sub    $0x10,%esp
  struct proc * min = q->proc[q->head];  
80104b2e:	8b 45 08             	mov    0x8(%ebp),%eax
80104b31:	8b 50 08             	mov    0x8(%eax),%edx
80104b34:	8b 45 08             	mov    0x8(%ebp),%eax
80104b37:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80104b3b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  int i = (q->head+1) % QUEUE_SIZE;
80104b3e:	8b 45 08             	mov    0x8(%ebp),%eax
80104b41:	8b 40 08             	mov    0x8(%eax),%eax
80104b44:	8d 50 01             	lea    0x1(%eax),%edx
80104b47:	89 d0                	mov    %edx,%eax
80104b49:	c1 f8 1f             	sar    $0x1f,%eax
80104b4c:	c1 e8 1a             	shr    $0x1a,%eax
80104b4f:	01 c2                	add    %eax,%edx
80104b51:	83 e2 3f             	and    $0x3f,%edx
80104b54:	29 c2                	sub    %eax,%edx
80104b56:	89 d0                	mov    %edx,%eax
80104b58:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if (q->count == 0) return 0;
80104b5b:	8b 45 08             	mov    0x8(%ebp),%eax
80104b5e:	8b 00                	mov    (%eax),%eax
80104b60:	85 c0                	test   %eax,%eax
80104b62:	75 07                	jne    80104b6b <fcfs_dequeue+0x43>
80104b64:	b8 00 00 00 00       	mov    $0x0,%eax
80104b69:	eb 65                	jmp    80104bd0 <fcfs_dequeue+0xa8>
  while (i != q->tail) {
80104b6b:	eb 43                	jmp    80104bb0 <fcfs_dequeue+0x88>
      min = (min->ctime > q->proc[i]->ctime) ? q->proc[i] : min;
80104b6d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104b70:	8b 48 7c             	mov    0x7c(%eax),%ecx
80104b73:	8b 45 08             	mov    0x8(%ebp),%eax
80104b76:	8b 55 f8             	mov    -0x8(%ebp),%edx
80104b79:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80104b7d:	8b 40 7c             	mov    0x7c(%eax),%eax
80104b80:	39 c1                	cmp    %eax,%ecx
80104b82:	7e 0c                	jle    80104b90 <fcfs_dequeue+0x68>
80104b84:	8b 45 08             	mov    0x8(%ebp),%eax
80104b87:	8b 55 f8             	mov    -0x8(%ebp),%edx
80104b8a:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80104b8e:	eb 03                	jmp    80104b93 <fcfs_dequeue+0x6b>
80104b90:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104b93:	89 45 fc             	mov    %eax,-0x4(%ebp)
      i = (i+1) % QUEUE_SIZE;
80104b96:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104b99:	8d 50 01             	lea    0x1(%eax),%edx
80104b9c:	89 d0                	mov    %edx,%eax
80104b9e:	c1 f8 1f             	sar    $0x1f,%eax
80104ba1:	c1 e8 1a             	shr    $0x1a,%eax
80104ba4:	01 c2                	add    %eax,%edx
80104ba6:	83 e2 3f             	and    $0x3f,%edx
80104ba9:	29 c2                	sub    %eax,%edx
80104bab:	89 d0                	mov    %edx,%eax
80104bad:	89 45 f8             	mov    %eax,-0x8(%ebp)

struct proc* fcfs_dequeue(queue* q) {
  struct proc * min = q->proc[q->head];  
  int i = (q->head+1) % QUEUE_SIZE;
  if (q->count == 0) return 0;
  while (i != q->tail) {
80104bb0:	8b 45 08             	mov    0x8(%ebp),%eax
80104bb3:	8b 40 04             	mov    0x4(%eax),%eax
80104bb6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104bb9:	75 b2                	jne    80104b6d <fcfs_dequeue+0x45>
      min = (min->ctime > q->proc[i]->ctime) ? q->proc[i] : min;
      i = (i+1) % QUEUE_SIZE;
  }
  if(min->state != RUNNABLE) 
80104bbb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104bbe:	8b 40 0c             	mov    0xc(%eax),%eax
80104bc1:	83 f8 03             	cmp    $0x3,%eax
80104bc4:	74 07                	je     80104bcd <fcfs_dequeue+0xa5>
    return 0;
80104bc6:	b8 00 00 00 00       	mov    $0x0,%eax
80104bcb:	eb 03                	jmp    80104bd0 <fcfs_dequeue+0xa8>
  return min;
80104bcd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104bd0:	c9                   	leave  
80104bd1:	c3                   	ret    

80104bd2 <init_queue>:
#if defined(SML) || defined(DML)
  multi_level_queue sch_queue;
  void init_queue() {
80104bd2:	55                   	push   %ebp
80104bd3:	89 e5                	mov    %esp,%ebp
80104bd5:	83 ec 04             	sub    $0x4,%esp
    queue_init(&sch_queue.pr1);
80104bd8:	c7 04 24 e0 41 11 80 	movl   $0x801141e0,(%esp)
80104bdf:	e8 d0 fd ff ff       	call   801049b4 <queue_init>
    queue_init(&sch_queue.pr2);
80104be4:	c7 04 24 ec 42 11 80 	movl   $0x801142ec,(%esp)
80104beb:	e8 c4 fd ff ff       	call   801049b4 <queue_init>
    queue_init(&sch_queue.pr3);
80104bf0:	c7 04 24 f8 43 11 80 	movl   $0x801143f8,(%esp)
80104bf7:	e8 b8 fd ff ff       	call   801049b4 <queue_init>
  } 
80104bfc:	c9                   	leave  
80104bfd:	c3                   	ret    

80104bfe <pinit>:
#endif


void
pinit(void)
{
80104bfe:	55                   	push   %ebp
80104bff:	89 e5                	mov    %esp,%ebp
80104c01:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104c04:	c7 44 24 04 d5 93 10 	movl   $0x801093d5,0x4(%esp)
80104c0b:	80 
80104c0c:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80104c13:	e8 ef 0d 00 00       	call   80105a07 <initlock>
#ifndef DEFAULT
  init_queue();
80104c18:	e8 b5 ff ff ff       	call   80104bd2 <init_queue>
#endif
}
80104c1d:	c9                   	leave  
80104c1e:	c3                   	ret    

80104c1f <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{ // here we can choose to which queue we want him to be sent..
80104c1f:	55                   	push   %ebp
80104c20:	89 e5                	mov    %esp,%ebp
80104c22:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104c25:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80104c2c:	e8 f7 0d 00 00       	call   80105a28 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c31:	c7 45 f4 54 45 11 80 	movl   $0x80114554,-0xc(%ebp)
80104c38:	eb 53                	jmp    80104c8d <allocproc+0x6e>
    if(p->state == UNUSED)
80104c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c3d:	8b 40 0c             	mov    0xc(%eax),%eax
80104c40:	85 c0                	test   %eax,%eax
80104c42:	75 42                	jne    80104c86 <allocproc+0x67>
      goto found;
80104c44:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104c45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c48:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104c4f:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80104c54:	8d 50 01             	lea    0x1(%eax),%edx
80104c57:	89 15 04 c0 10 80    	mov    %edx,0x8010c004
80104c5d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c60:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
80104c63:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80104c6a:	e8 1b 0e 00 00       	call   80105a8a <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104c6f:	e8 45 e5 ff ff       	call   801031b9 <kalloc>
80104c74:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c77:	89 42 08             	mov    %eax,0x8(%edx)
80104c7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c7d:	8b 40 08             	mov    0x8(%eax),%eax
80104c80:	85 c0                	test   %eax,%eax
80104c82:	75 36                	jne    80104cba <allocproc+0x9b>
80104c84:	eb 23                	jmp    80104ca9 <allocproc+0x8a>
{ // here we can choose to which queue we want him to be sent..
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c86:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
80104c8d:	81 7d f4 54 6a 11 80 	cmpl   $0x80116a54,-0xc(%ebp)
80104c94:	72 a4                	jb     80104c3a <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104c96:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80104c9d:	e8 e8 0d 00 00       	call   80105a8a <release>
  return 0;
80104ca2:	b8 00 00 00 00       	mov    $0x0,%eax
80104ca7:	eb 76                	jmp    80104d1f <allocproc+0x100>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
80104ca9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cac:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104cb3:	b8 00 00 00 00       	mov    $0x0,%eax
80104cb8:	eb 65                	jmp    80104d1f <allocproc+0x100>
  }
  sp = p->kstack + KSTACKSIZE;
80104cba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cbd:	8b 40 08             	mov    0x8(%eax),%eax
80104cc0:	05 00 10 00 00       	add    $0x1000,%eax
80104cc5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104cc8:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104ccc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ccf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cd2:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104cd5:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104cd9:	ba f6 70 10 80       	mov    $0x801070f6,%edx
80104cde:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ce1:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104ce3:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cea:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ced:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104cf0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cf3:	8b 40 1c             	mov    0x1c(%eax),%eax
80104cf6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104cfd:	00 
80104cfe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104d05:	00 
80104d06:	89 04 24             	mov    %eax,(%esp)
80104d09:	e8 6e 0f 00 00       	call   80105c7c <memset>
  p->context->eip = (uint)forkret;
80104d0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d11:	8b 40 1c             	mov    0x1c(%eax),%eax
80104d14:	ba f3 56 10 80       	mov    $0x801056f3,%edx
80104d19:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104d1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104d1f:	c9                   	leave  
80104d20:	c3                   	ret    

80104d21 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104d21:	55                   	push   %ebp
80104d22:	89 e5                	mov    %esp,%ebp
80104d24:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104d27:	e8 f3 fe ff ff       	call   80104c1f <allocproc>
80104d2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104d2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d32:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm()) == 0)
80104d37:	e8 e4 3a 00 00       	call   80108820 <setupkvm>
80104d3c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d3f:	89 42 04             	mov    %eax,0x4(%edx)
80104d42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d45:	8b 40 04             	mov    0x4(%eax),%eax
80104d48:	85 c0                	test   %eax,%eax
80104d4a:	75 0c                	jne    80104d58 <userinit+0x37>
    panic("userinit: out of memory?");
80104d4c:	c7 04 24 dc 93 10 80 	movl   $0x801093dc,(%esp)
80104d53:	e8 e2 b7 ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104d58:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104d5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d60:	8b 40 04             	mov    0x4(%eax),%eax
80104d63:	89 54 24 08          	mov    %edx,0x8(%esp)
80104d67:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80104d6e:	80 
80104d6f:	89 04 24             	mov    %eax,(%esp)
80104d72:	e8 01 3d 00 00       	call   80108a78 <inituvm>
  p->sz = PGSIZE;
80104d77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d7a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104d80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d83:	8b 40 18             	mov    0x18(%eax),%eax
80104d86:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104d8d:	00 
80104d8e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104d95:	00 
80104d96:	89 04 24             	mov    %eax,(%esp)
80104d99:	e8 de 0e 00 00       	call   80105c7c <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104d9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104da1:	8b 40 18             	mov    0x18(%eax),%eax
80104da4:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104daa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dad:	8b 40 18             	mov    0x18(%eax),%eax
80104db0:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104db6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104db9:	8b 40 18             	mov    0x18(%eax),%eax
80104dbc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104dbf:	8b 52 18             	mov    0x18(%edx),%edx
80104dc2:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104dc6:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104dca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dcd:	8b 40 18             	mov    0x18(%eax),%eax
80104dd0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104dd3:	8b 52 18             	mov    0x18(%edx),%edx
80104dd6:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104dda:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104dde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104de1:	8b 40 18             	mov    0x18(%eax),%eax
80104de4:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104deb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dee:	8b 40 18             	mov    0x18(%eax),%eax
80104df1:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104df8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dfb:	8b 40 18             	mov    0x18(%eax),%eax
80104dfe:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)


  safestrcpy(p->name, "initcode", sizeof(p->name));
80104e05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e08:	83 c0 6c             	add    $0x6c,%eax
80104e0b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104e12:	00 
80104e13:	c7 44 24 04 f5 93 10 	movl   $0x801093f5,0x4(%esp)
80104e1a:	80 
80104e1b:	89 04 24             	mov    %eax,(%esp)
80104e1e:	e8 79 10 00 00       	call   80105e9c <safestrcpy>
  p->cwd = namei("/");
80104e23:	c7 04 24 fe 93 10 80 	movl   $0x801093fe,(%esp)
80104e2a:	e8 77 dc ff ff       	call   80102aa6 <namei>
80104e2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e32:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104e35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e38:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  p->ctime = 1231231;
80104e3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e42:	c7 40 7c 7f c9 12 00 	movl   $0x12c97f,0x7c(%eax)
  p->priority = MED_PRIO;
80104e49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e4c:	c7 80 8c 00 00 00 02 	movl   $0x2,0x8c(%eax)
80104e53:	00 00 00 
  p->dml_opts = DEFAULT_OPT;
80104e56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e59:	c7 80 90 00 00 00 02 	movl   $0x2,0x90(%eax)
80104e60:	00 00 00 
  enq_to_scheduler(p);
80104e63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e66:	89 04 24             	mov    %eax,(%esp)
80104e69:	e8 a7 00 00 00       	call   80104f15 <enq_to_scheduler>
}
80104e6e:	c9                   	leave  
80104e6f:	c3                   	ret    

80104e70 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104e70:	55                   	push   %ebp
80104e71:	89 e5                	mov    %esp,%ebp
80104e73:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104e76:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e7c:	8b 00                	mov    (%eax),%eax
80104e7e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104e81:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e85:	7e 34                	jle    80104ebb <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104e87:	8b 55 08             	mov    0x8(%ebp),%edx
80104e8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e8d:	01 c2                	add    %eax,%edx
80104e8f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e95:	8b 40 04             	mov    0x4(%eax),%eax
80104e98:	89 54 24 08          	mov    %edx,0x8(%esp)
80104e9c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e9f:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ea3:	89 04 24             	mov    %eax,(%esp)
80104ea6:	e8 43 3d 00 00       	call   80108bee <allocuvm>
80104eab:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104eae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104eb2:	75 41                	jne    80104ef5 <growproc+0x85>
      return -1;
80104eb4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eb9:	eb 58                	jmp    80104f13 <growproc+0xa3>
  } else if(n < 0){
80104ebb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104ebf:	79 34                	jns    80104ef5 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104ec1:	8b 55 08             	mov    0x8(%ebp),%edx
80104ec4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ec7:	01 c2                	add    %eax,%edx
80104ec9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ecf:	8b 40 04             	mov    0x4(%eax),%eax
80104ed2:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ed6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ed9:	89 54 24 04          	mov    %edx,0x4(%esp)
80104edd:	89 04 24             	mov    %eax,(%esp)
80104ee0:	e8 e3 3d 00 00       	call   80108cc8 <deallocuvm>
80104ee5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104ee8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104eec:	75 07                	jne    80104ef5 <growproc+0x85>
      return -1;
80104eee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ef3:	eb 1e                	jmp    80104f13 <growproc+0xa3>
  }
  proc->sz = sz;
80104ef5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104efb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104efe:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104f00:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f06:	89 04 24             	mov    %eax,(%esp)
80104f09:	e8 03 3a 00 00       	call   80108911 <switchuvm>
  return 0;
80104f0e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f13:	c9                   	leave  
80104f14:	c3                   	ret    

80104f15 <enq_to_scheduler>:
// Adds the newly created process to the appropriate queue.
void enq_to_scheduler (struct proc * p) {
80104f15:	55                   	push   %ebp
80104f16:	89 e5                	mov    %esp,%ebp
80104f18:	83 ec 08             	sub    $0x8,%esp
#endif
#ifdef SML 
  multi_level_enq(&sch_queue,p);
#endif
#ifdef DML
  switch (p->dml_opts) {
80104f1b:	8b 45 08             	mov    0x8(%ebp),%eax
80104f1e:	8b 80 90 00 00 00    	mov    0x90(%eax),%eax
80104f24:	85 c0                	test   %eax,%eax
80104f26:	74 07                	je     80104f2f <enq_to_scheduler+0x1a>
80104f28:	83 f8 01             	cmp    $0x1,%eax
80104f2b:	74 11                	je     80104f3e <enq_to_scheduler+0x29>
80104f2d:	eb 36                	jmp    80104f65 <enq_to_scheduler+0x50>
    case RETURNING_FROM_SLEEP: 
      p->priority = HIGH_PRIO;
80104f2f:	8b 45 08             	mov    0x8(%ebp),%eax
80104f32:	c7 80 8c 00 00 00 03 	movl   $0x3,0x8c(%eax)
80104f39:	00 00 00 
    break;
80104f3c:	eb 27                	jmp    80104f65 <enq_to_scheduler+0x50>
    case FULL_QUANTA:
      p->priority -= (p->priority > LOW_PRIO) ? 1 : 0;
80104f3e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f41:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80104f47:	8b 45 08             	mov    0x8(%ebp),%eax
80104f4a:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80104f50:	83 f8 01             	cmp    $0x1,%eax
80104f53:	0f 9f c0             	setg   %al
80104f56:	0f b6 c0             	movzbl %al,%eax
80104f59:	29 c2                	sub    %eax,%edx
80104f5b:	8b 45 08             	mov    0x8(%ebp),%eax
80104f5e:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
    break;
80104f64:	90                   	nop
    default: ;
  }
  multi_level_enq(&sch_queue, p);
80104f65:	8b 45 08             	mov    0x8(%ebp),%eax
80104f68:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f6c:	c7 04 24 e0 41 11 80 	movl   $0x801141e0,(%esp)
80104f73:	e8 ec fa ff ff       	call   80104a64 <multi_level_enq>
#endif
}
80104f78:	c9                   	leave  
80104f79:	c3                   	ret    

80104f7a <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104f7a:	55                   	push   %ebp
80104f7b:	89 e5                	mov    %esp,%ebp
80104f7d:	57                   	push   %edi
80104f7e:	56                   	push   %esi
80104f7f:	53                   	push   %ebx
80104f80:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104f83:	e8 97 fc ff ff       	call   80104c1f <allocproc>
80104f88:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104f8b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104f8f:	75 0a                	jne    80104f9b <fork+0x21>
    return -1;
80104f91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f96:	e9 b3 01 00 00       	jmp    8010514e <fork+0x1d4>
  np->ctime = ticks;
80104f9b:	a1 a0 72 11 80       	mov    0x801172a0,%eax
80104fa0:	89 c2                	mov    %eax,%edx
80104fa2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fa5:	89 50 7c             	mov    %edx,0x7c(%eax)
  np->stime = 0;
80104fa8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fab:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104fb2:	00 00 00 
  np->retime = 0;
80104fb5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fb8:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%eax)
80104fbf:	00 00 00 
  np->rutime = 0;
80104fc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fc5:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104fcc:	00 00 00 
  np->priority = proc->priority;
80104fcf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fd5:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80104fdb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fde:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
  np->dml_opts = DEFAULT_OPT;
80104fe4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fe7:	c7 80 90 00 00 00 02 	movl   $0x2,0x90(%eax)
80104fee:	00 00 00 
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104ff1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ff7:	8b 10                	mov    (%eax),%edx
80104ff9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fff:	8b 40 04             	mov    0x4(%eax),%eax
80105002:	89 54 24 04          	mov    %edx,0x4(%esp)
80105006:	89 04 24             	mov    %eax,(%esp)
80105009:	e8 56 3e 00 00       	call   80108e64 <copyuvm>
8010500e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105011:	89 42 04             	mov    %eax,0x4(%edx)
80105014:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105017:	8b 40 04             	mov    0x4(%eax),%eax
8010501a:	85 c0                	test   %eax,%eax
8010501c:	75 2c                	jne    8010504a <fork+0xd0>
    kfree(np->kstack);
8010501e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105021:	8b 40 08             	mov    0x8(%eax),%eax
80105024:	89 04 24             	mov    %eax,(%esp)
80105027:	e8 f4 e0 ff ff       	call   80103120 <kfree>
    np->kstack = 0;
8010502c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010502f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80105036:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105039:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80105040:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105045:	e9 04 01 00 00       	jmp    8010514e <fork+0x1d4>
  }
  np->sz = proc->sz;
8010504a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105050:	8b 10                	mov    (%eax),%edx
80105052:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105055:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80105057:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010505e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105061:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80105064:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105067:	8b 50 18             	mov    0x18(%eax),%edx
8010506a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105070:	8b 40 18             	mov    0x18(%eax),%eax
80105073:	89 c3                	mov    %eax,%ebx
80105075:	b8 13 00 00 00       	mov    $0x13,%eax
8010507a:	89 d7                	mov    %edx,%edi
8010507c:	89 de                	mov    %ebx,%esi
8010507e:	89 c1                	mov    %eax,%ecx
80105080:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80105082:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105085:	8b 40 18             	mov    0x18(%eax),%eax
80105088:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
8010508f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80105096:	eb 3d                	jmp    801050d5 <fork+0x15b>
    if(proc->ofile[i])
80105098:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010509e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801050a1:	83 c2 08             	add    $0x8,%edx
801050a4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801050a8:	85 c0                	test   %eax,%eax
801050aa:	74 25                	je     801050d1 <fork+0x157>
      np->ofile[i] = filedup(proc->ofile[i]);
801050ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050b2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801050b5:	83 c2 08             	add    $0x8,%edx
801050b8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801050bc:	89 04 24             	mov    %eax,(%esp)
801050bf:	e8 fe c4 ff ff       	call   801015c2 <filedup>
801050c4:	8b 55 e0             	mov    -0x20(%ebp),%edx
801050c7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801050ca:	83 c1 08             	add    $0x8,%ecx
801050cd:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801050d1:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801050d5:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801050d9:	7e bd                	jle    80105098 <fork+0x11e>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801050db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050e1:	8b 40 68             	mov    0x68(%eax),%eax
801050e4:	89 04 24             	mov    %eax,(%esp)
801050e7:	e8 d7 cd ff ff       	call   80101ec3 <idup>
801050ec:	8b 55 e0             	mov    -0x20(%ebp),%edx
801050ef:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
801050f2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050f8:	8d 50 6c             	lea    0x6c(%eax),%edx
801050fb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801050fe:	83 c0 6c             	add    $0x6c,%eax
80105101:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105108:	00 
80105109:	89 54 24 04          	mov    %edx,0x4(%esp)
8010510d:	89 04 24             	mov    %eax,(%esp)
80105110:	e8 87 0d 00 00       	call   80105e9c <safestrcpy>
 
  pid = np->pid;
80105115:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105118:	8b 40 10             	mov    0x10(%eax),%eax
8010511b:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
8010511e:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105125:	e8 fe 08 00 00       	call   80105a28 <acquire>
  np->state = RUNNABLE;
8010512a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010512d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  enq_to_scheduler(np);
80105134:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105137:	89 04 24             	mov    %eax,(%esp)
8010513a:	e8 d6 fd ff ff       	call   80104f15 <enq_to_scheduler>
  release(&ptable.lock);
8010513f:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105146:	e8 3f 09 00 00       	call   80105a8a <release>
  
  return pid;
8010514b:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010514e:	83 c4 2c             	add    $0x2c,%esp
80105151:	5b                   	pop    %ebx
80105152:	5e                   	pop    %esi
80105153:	5f                   	pop    %edi
80105154:	5d                   	pop    %ebp
80105155:	c3                   	ret    

80105156 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80105156:	55                   	push   %ebp
80105157:	89 e5                	mov    %esp,%ebp
80105159:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010515c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105163:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80105168:	39 c2                	cmp    %eax,%edx
8010516a:	75 0c                	jne    80105178 <exit+0x22>
    panic("init exiting");
8010516c:	c7 04 24 00 94 10 80 	movl   $0x80109400,(%esp)
80105173:	e8 c2 b3 ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105178:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010517f:	eb 44                	jmp    801051c5 <exit+0x6f>
    if(proc->ofile[fd]){
80105181:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105187:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010518a:	83 c2 08             	add    $0x8,%edx
8010518d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105191:	85 c0                	test   %eax,%eax
80105193:	74 2c                	je     801051c1 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80105195:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010519b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010519e:	83 c2 08             	add    $0x8,%edx
801051a1:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801051a5:	89 04 24             	mov    %eax,(%esp)
801051a8:	e8 5d c4 ff ff       	call   8010160a <fileclose>
      proc->ofile[fd] = 0;
801051ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051b3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801051b6:	83 c2 08             	add    $0x8,%edx
801051b9:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801051c0:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801051c1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801051c5:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801051c9:	7e b6                	jle    80105181 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
801051cb:	e8 0d e9 ff ff       	call   80103add <begin_op>
  iput(proc->cwd);
801051d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051d6:	8b 40 68             	mov    0x68(%eax),%eax
801051d9:	89 04 24             	mov    %eax,(%esp)
801051dc:	e8 cd ce ff ff       	call   801020ae <iput>
  end_op();
801051e1:	e8 7b e9 ff ff       	call   80103b61 <end_op>
  proc->cwd = 0;
801051e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051ec:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801051f3:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
801051fa:	e8 29 08 00 00       	call   80105a28 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801051ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105205:	8b 40 14             	mov    0x14(%eax),%eax
80105208:	89 04 24             	mov    %eax,(%esp)
8010520b:	e8 bd 05 00 00       	call   801057cd <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105210:	c7 45 f4 54 45 11 80 	movl   $0x80114554,-0xc(%ebp)
80105217:	eb 3b                	jmp    80105254 <exit+0xfe>
    if(p->parent == proc){
80105219:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010521c:	8b 50 14             	mov    0x14(%eax),%edx
8010521f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105225:	39 c2                	cmp    %eax,%edx
80105227:	75 24                	jne    8010524d <exit+0xf7>
      p->parent = initproc;
80105229:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
8010522f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105232:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80105235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105238:	8b 40 0c             	mov    0xc(%eax),%eax
8010523b:	83 f8 05             	cmp    $0x5,%eax
8010523e:	75 0d                	jne    8010524d <exit+0xf7>
        wakeup1(initproc);
80105240:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80105245:	89 04 24             	mov    %eax,(%esp)
80105248:	e8 80 05 00 00       	call   801057cd <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010524d:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
80105254:	81 7d f4 54 6a 11 80 	cmpl   $0x80116a54,-0xc(%ebp)
8010525b:	72 bc                	jb     80105219 <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
8010525d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105263:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010526a:	e8 92 03 00 00       	call   80105601 <sched>
  panic("zombie exit");
8010526f:	c7 04 24 0d 94 10 80 	movl   $0x8010940d,(%esp)
80105276:	e8 bf b2 ff ff       	call   8010053a <panic>

8010527b <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
8010527b:	55                   	push   %ebp
8010527c:	89 e5                	mov    %esp,%ebp
8010527e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80105281:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105288:	e8 9b 07 00 00       	call   80105a28 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
8010528d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105294:	c7 45 f4 54 45 11 80 	movl   $0x80114554,-0xc(%ebp)
8010529b:	e9 9d 00 00 00       	jmp    8010533d <wait+0xc2>
      if(p->parent != proc)
801052a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052a3:	8b 50 14             	mov    0x14(%eax),%edx
801052a6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052ac:	39 c2                	cmp    %eax,%edx
801052ae:	74 05                	je     801052b5 <wait+0x3a>
        continue;
801052b0:	e9 81 00 00 00       	jmp    80105336 <wait+0xbb>
      havekids = 1;
801052b5:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801052bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052bf:	8b 40 0c             	mov    0xc(%eax),%eax
801052c2:	83 f8 05             	cmp    $0x5,%eax
801052c5:	75 6f                	jne    80105336 <wait+0xbb>
        // Found one.
        pid = p->pid;
801052c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ca:	8b 40 10             	mov    0x10(%eax),%eax
801052cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801052d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052d3:	8b 40 08             	mov    0x8(%eax),%eax
801052d6:	89 04 24             	mov    %eax,(%esp)
801052d9:	e8 42 de ff ff       	call   80103120 <kfree>
        p->kstack = 0;
801052de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052e1:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
801052e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052eb:	8b 40 04             	mov    0x4(%eax),%eax
801052ee:	89 04 24             	mov    %eax,(%esp)
801052f1:	e8 8e 3a 00 00       	call   80108d84 <freevm>
        p->state = UNUSED;
801052f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052f9:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80105300:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105303:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
8010530a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010530d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80105314:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105317:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
8010531b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010531e:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80105325:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
8010532c:	e8 59 07 00 00       	call   80105a8a <release>
        return pid;
80105331:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105334:	eb 55                	jmp    8010538b <wait+0x110>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105336:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
8010533d:	81 7d f4 54 6a 11 80 	cmpl   $0x80116a54,-0xc(%ebp)
80105344:	0f 82 56 ff ff ff    	jb     801052a0 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
8010534a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010534e:	74 0d                	je     8010535d <wait+0xe2>
80105350:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105356:	8b 40 24             	mov    0x24(%eax),%eax
80105359:	85 c0                	test   %eax,%eax
8010535b:	74 13                	je     80105370 <wait+0xf5>
      release(&ptable.lock);
8010535d:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105364:	e8 21 07 00 00       	call   80105a8a <release>
      return -1;
80105369:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010536e:	eb 1b                	jmp    8010538b <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105370:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105376:	c7 44 24 04 20 45 11 	movl   $0x80114520,0x4(%esp)
8010537d:	80 
8010537e:	89 04 24             	mov    %eax,(%esp)
80105381:	e8 ac 03 00 00       	call   80105732 <sleep>
  }
80105386:	e9 02 ff ff ff       	jmp    8010528d <wait+0x12>
}
8010538b:	c9                   	leave  
8010538c:	c3                   	ret    

8010538d <wait2>:

int wait2(void) {
8010538d:	55                   	push   %ebp
8010538e:	89 e5                	mov    %esp,%ebp
80105390:	83 ec 38             	sub    $0x38,%esp
  char *retime, *rutime, *stime;
  int pid = 0;
80105393:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  struct proc * p;
  if(argptr(0,&retime,sizeof(int)) < 0
8010539a:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801053a1:	00 
801053a2:	8d 45 ec             	lea    -0x14(%ebp),%eax
801053a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801053a9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801053b0:	e8 37 0c 00 00       	call   80105fec <argptr>
801053b5:	85 c0                	test   %eax,%eax
801053b7:	78 3e                	js     801053f7 <wait2+0x6a>
      || argptr(1,&rutime,sizeof(int)) < 0
801053b9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801053c0:	00 
801053c1:	8d 45 e8             	lea    -0x18(%ebp),%eax
801053c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801053c8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801053cf:	e8 18 0c 00 00       	call   80105fec <argptr>
801053d4:	85 c0                	test   %eax,%eax
801053d6:	78 1f                	js     801053f7 <wait2+0x6a>
      || argptr(2,&stime,sizeof(int)) < 0) 
801053d8:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801053df:	00 
801053e0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801053e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801053e7:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801053ee:	e8 f9 0b 00 00       	call   80105fec <argptr>
801053f3:	85 c0                	test   %eax,%eax
801053f5:	79 0a                	jns    80105401 <wait2+0x74>
    return -1;
801053f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053fc:	e9 8a 00 00 00       	jmp    8010548b <wait2+0xfe>
  pid = wait(); 
80105401:	e8 75 fe ff ff       	call   8010527b <wait>
80105406:	89 45 f0             	mov    %eax,-0x10(%ebp)
  // now we have athe pid of a child  process - now we can 
  // find it in the ptable and foo foo 
  acquire(&ptable.lock);
80105409:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105410:	e8 13 06 00 00       	call   80105a28 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC] && pid > 0; ++p) 
80105415:	c7 45 f4 54 45 11 80 	movl   $0x80114554,-0xc(%ebp)
8010541c:	eb 4d                	jmp    8010546b <wait2+0xde>
    if(p->pid == pid){ //found the child 
8010541e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105421:	8b 40 10             	mov    0x10(%eax),%eax
80105424:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80105427:	75 3b                	jne    80105464 <wait2+0xd7>
      *retime = p->retime;
80105429:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010542c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010542f:	8b 92 84 00 00 00    	mov    0x84(%edx),%edx
80105435:	88 10                	mov    %dl,(%eax)
      *rutime = p->rutime;
80105437:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010543a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010543d:	8b 92 88 00 00 00    	mov    0x88(%edx),%edx
80105443:	88 10                	mov    %dl,(%eax)
      *stime = p->stime;
80105445:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105448:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010544b:	8b 92 80 00 00 00    	mov    0x80(%edx),%edx
80105451:	88 10                	mov    %dl,(%eax)
      release(&ptable.lock);
80105453:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
8010545a:	e8 2b 06 00 00       	call   80105a8a <release>
      return pid;
8010545f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105462:	eb 27                	jmp    8010548b <wait2+0xfe>
    return -1;
  pid = wait(); 
  // now we have athe pid of a child  process - now we can 
  // find it in the ptable and foo foo 
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC] && pid > 0; ++p) 
80105464:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
8010546b:	81 7d f4 54 6a 11 80 	cmpl   $0x80116a54,-0xc(%ebp)
80105472:	73 06                	jae    8010547a <wait2+0xed>
80105474:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105478:	7f a4                	jg     8010541e <wait2+0x91>
      *rutime = p->rutime;
      *stime = p->stime;
      release(&ptable.lock);
      return pid;
    }
  release(&ptable.lock);
8010547a:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105481:	e8 04 06 00 00       	call   80105a8a <release>
  return -1;
80105486:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010548b:	c9                   	leave  
8010548c:	c3                   	ret    

8010548d <increment_process_times>:
// This method is icrements the time fields for all the processes
// each tick, it is called in trap.c when we increment the total amount of 
// ticks we lock the ptable here!
//
void increment_process_times(void) {
8010548d:	55                   	push   %ebp
8010548e:	89 e5                	mov    %esp,%ebp
80105490:	83 ec 28             	sub    $0x28,%esp
  struct proc * p;
  acquire(&ptable.lock);
80105493:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
8010549a:	e8 89 05 00 00       	call   80105a28 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; ++p)
8010549f:	c7 45 f4 54 45 11 80 	movl   $0x80114554,-0xc(%ebp)
801054a6:	eb 62                	jmp    8010550a <increment_process_times+0x7d>
    switch (p->state) {
801054a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054ab:	8b 40 0c             	mov    0xc(%eax),%eax
801054ae:	83 f8 03             	cmp    $0x3,%eax
801054b1:	74 3a                	je     801054ed <increment_process_times+0x60>
801054b3:	83 f8 04             	cmp    $0x4,%eax
801054b6:	74 1e                	je     801054d6 <increment_process_times+0x49>
801054b8:	83 f8 02             	cmp    $0x2,%eax
801054bb:	74 02                	je     801054bf <increment_process_times+0x32>
      break;
      case RUNNABLE:
        ++p->retime;
      break;
      default:
      break;
801054bd:	eb 44                	jmp    80105503 <increment_process_times+0x76>
  struct proc * p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; ++p)
    switch (p->state) {
      case SLEEPING:
        ++p->stime;
801054bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054c2:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
801054c8:	8d 50 01             	lea    0x1(%eax),%edx
801054cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054ce:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
      break;
801054d4:	eb 2d                	jmp    80105503 <increment_process_times+0x76>
      case RUNNING:
        ++p->rutime;
801054d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054d9:	8b 80 88 00 00 00    	mov    0x88(%eax),%eax
801054df:	8d 50 01             	lea    0x1(%eax),%edx
801054e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054e5:	89 90 88 00 00 00    	mov    %edx,0x88(%eax)
      break;
801054eb:	eb 16                	jmp    80105503 <increment_process_times+0x76>
      case RUNNABLE:
        ++p->retime;
801054ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054f0:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
801054f6:	8d 50 01             	lea    0x1(%eax),%edx
801054f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054fc:	89 90 84 00 00 00    	mov    %edx,0x84(%eax)
      break;
80105502:	90                   	nop
// ticks we lock the ptable here!
//
void increment_process_times(void) {
  struct proc * p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; ++p)
80105503:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
8010550a:	81 7d f4 54 6a 11 80 	cmpl   $0x80116a54,-0xc(%ebp)
80105511:	72 95                	jb     801054a8 <increment_process_times+0x1b>
        ++p->retime;
      break;
      default:
      break;
    }
   release(&ptable.lock);  
80105513:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
8010551a:	e8 6b 05 00 00       	call   80105a8a <release>
}
8010551f:	c9                   	leave  
80105520:	c3                   	ret    

80105521 <end_of_round>:
  }
#endif

#if defined(SML) || defined(DML)
  // Multi level queue that includes 3 priority levels.
  int end_of_round(struct proc* p) {
80105521:	55                   	push   %ebp
80105522:	89 e5                	mov    %esp,%ebp
    return p == 0;
80105524:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105528:	0f 94 c0             	sete   %al
8010552b:	0f b6 c0             	movzbl %al,%eax
  }
8010552e:	5d                   	pop    %ebp
8010552f:	c3                   	ret    

80105530 <next_proc>:
  struct proc* next_proc(struct proc* p) {
80105530:	55                   	push   %ebp
80105531:	89 e5                	mov    %esp,%ebp
80105533:	83 ec 04             	sub    $0x4,%esp
    return multi_level_dequeue(&sch_queue);
80105536:	c7 04 24 e0 41 11 80 	movl   $0x801141e0,(%esp)
8010553d:	e8 85 f5 ff ff       	call   80104ac7 <multi_level_dequeue>
  }
80105542:	c9                   	leave  
80105543:	c3                   	ret    

80105544 <first_process>:
  struct proc* first_process() {
80105544:	55                   	push   %ebp
80105545:	89 e5                	mov    %esp,%ebp
80105547:	83 ec 04             	sub    $0x4,%esp
    return next_proc(0);
8010554a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105551:	e8 da ff ff ff       	call   80105530 <next_proc>
  }
80105556:	c9                   	leave  
80105557:	c3                   	ret    

80105558 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105558:	55                   	push   %ebp
80105559:	89 e5                	mov    %esp,%ebp
8010555b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
8010555e:	e8 4b f4 ff ff       	call   801049ae <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80105563:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
8010556a:	e8 b9 04 00 00       	call   80105a28 <acquire>
    for(p = first_process(); !end_of_round(p); p = next_proc(p)){
8010556f:	e8 d0 ff ff ff       	call   80105544 <first_process>
80105574:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105577:	eb 68                	jmp    801055e1 <scheduler+0x89>
      if(p->state != RUNNABLE)
80105579:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010557c:	8b 40 0c             	mov    0xc(%eax),%eax
8010557f:	83 f8 03             	cmp    $0x3,%eax
80105582:	74 02                	je     80105586 <scheduler+0x2e>
        continue;
80105584:	eb 4d                	jmp    801055d3 <scheduler+0x7b>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80105586:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105589:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
8010558f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105592:	89 04 24             	mov    %eax,(%esp)
80105595:	e8 77 33 00 00       	call   80108911 <switchuvm>
      p->state = RUNNING;
8010559a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010559d:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801055a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055aa:	8b 40 1c             	mov    0x1c(%eax),%eax
801055ad:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801055b4:	83 c2 04             	add    $0x4,%edx
801055b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801055bb:	89 14 24             	mov    %edx,(%esp)
801055be:	e8 4a 09 00 00       	call   80105f0d <swtch>
      switchkvm();
801055c3:	e8 2c 33 00 00       	call   801088f4 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801055c8:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801055cf:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = first_process(); !end_of_round(p); p = next_proc(p)){
801055d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d6:	89 04 24             	mov    %eax,(%esp)
801055d9:	e8 52 ff ff ff       	call   80105530 <next_proc>
801055de:	89 45 f4             	mov    %eax,-0xc(%ebp)
801055e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055e4:	89 04 24             	mov    %eax,(%esp)
801055e7:	e8 35 ff ff ff       	call   80105521 <end_of_round>
801055ec:	85 c0                	test   %eax,%eax
801055ee:	74 89                	je     80105579 <scheduler+0x21>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
801055f0:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
801055f7:	e8 8e 04 00 00       	call   80105a8a <release>

  }
801055fc:	e9 5d ff ff ff       	jmp    8010555e <scheduler+0x6>

80105601 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105601:	55                   	push   %ebp
80105602:	89 e5                	mov    %esp,%ebp
80105604:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105607:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
8010560e:	e8 3f 05 00 00       	call   80105b52 <holding>
80105613:	85 c0                	test   %eax,%eax
80105615:	75 0c                	jne    80105623 <sched+0x22>
    panic("sched ptable.lock");
80105617:	c7 04 24 19 94 10 80 	movl   $0x80109419,(%esp)
8010561e:	e8 17 af ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80105623:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105629:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010562f:	83 f8 01             	cmp    $0x1,%eax
80105632:	74 0c                	je     80105640 <sched+0x3f>
    panic("sched locks");
80105634:	c7 04 24 2b 94 10 80 	movl   $0x8010942b,(%esp)
8010563b:	e8 fa ae ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80105640:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105646:	8b 40 0c             	mov    0xc(%eax),%eax
80105649:	83 f8 04             	cmp    $0x4,%eax
8010564c:	75 0c                	jne    8010565a <sched+0x59>
    panic("sched running");
8010564e:	c7 04 24 37 94 10 80 	movl   $0x80109437,(%esp)
80105655:	e8 e0 ae ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
8010565a:	e8 3f f3 ff ff       	call   8010499e <readeflags>
8010565f:	25 00 02 00 00       	and    $0x200,%eax
80105664:	85 c0                	test   %eax,%eax
80105666:	74 0c                	je     80105674 <sched+0x73>
    panic("sched interruptible");
80105668:	c7 04 24 45 94 10 80 	movl   $0x80109445,(%esp)
8010566f:	e8 c6 ae ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80105674:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010567a:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105680:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105683:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105689:	8b 40 04             	mov    0x4(%eax),%eax
8010568c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105693:	83 c2 1c             	add    $0x1c,%edx
80105696:	89 44 24 04          	mov    %eax,0x4(%esp)
8010569a:	89 14 24             	mov    %edx,(%esp)
8010569d:	e8 6b 08 00 00       	call   80105f0d <swtch>
  cpu->intena = intena;
801056a2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056ab:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801056b1:	c9                   	leave  
801056b2:	c3                   	ret    

801056b3 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801056b3:	55                   	push   %ebp
801056b4:	89 e5                	mov    %esp,%ebp
801056b6:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801056b9:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
801056c0:	e8 63 03 00 00       	call   80105a28 <acquire>
  proc->state = RUNNABLE;
801056c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056cb:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  enq_to_scheduler(proc);
801056d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056d8:	89 04 24             	mov    %eax,(%esp)
801056db:	e8 35 f8 ff ff       	call   80104f15 <enq_to_scheduler>
  sched();
801056e0:	e8 1c ff ff ff       	call   80105601 <sched>
  release(&ptable.lock);
801056e5:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
801056ec:	e8 99 03 00 00       	call   80105a8a <release>
}
801056f1:	c9                   	leave  
801056f2:	c3                   	ret    

801056f3 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801056f3:	55                   	push   %ebp
801056f4:	89 e5                	mov    %esp,%ebp
801056f6:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801056f9:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105700:	e8 85 03 00 00       	call   80105a8a <release>

  if (first) {
80105705:	a1 08 c0 10 80       	mov    0x8010c008,%eax
8010570a:	85 c0                	test   %eax,%eax
8010570c:	74 22                	je     80105730 <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010570e:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
80105715:	00 00 00 
    iinit(ROOTDEV);
80105718:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010571f:	e8 a9 c4 ff ff       	call   80101bcd <iinit>
    initlog(ROOTDEV);
80105724:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010572b:	e8 a9 e1 ff ff       	call   801038d9 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105730:	c9                   	leave  
80105731:	c3                   	ret    

80105732 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105732:	55                   	push   %ebp
80105733:	89 e5                	mov    %esp,%ebp
80105735:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105738:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010573e:	85 c0                	test   %eax,%eax
80105740:	75 0c                	jne    8010574e <sleep+0x1c>
    panic("sleep");
80105742:	c7 04 24 59 94 10 80 	movl   $0x80109459,(%esp)
80105749:	e8 ec ad ff ff       	call   8010053a <panic>

  if(lk == 0)
8010574e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105752:	75 0c                	jne    80105760 <sleep+0x2e>
    panic("sleep without lk");
80105754:	c7 04 24 5f 94 10 80 	movl   $0x8010945f,(%esp)
8010575b:	e8 da ad ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105760:	81 7d 0c 20 45 11 80 	cmpl   $0x80114520,0xc(%ebp)
80105767:	74 17                	je     80105780 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105769:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105770:	e8 b3 02 00 00       	call   80105a28 <acquire>
    release(lk);
80105775:	8b 45 0c             	mov    0xc(%ebp),%eax
80105778:	89 04 24             	mov    %eax,(%esp)
8010577b:	e8 0a 03 00 00       	call   80105a8a <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105780:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105786:	8b 55 08             	mov    0x8(%ebp),%edx
80105789:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
8010578c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105792:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80105799:	e8 63 fe ff ff       	call   80105601 <sched>

  // Tidy up.
  proc->chan = 0;
8010579e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057a4:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801057ab:	81 7d 0c 20 45 11 80 	cmpl   $0x80114520,0xc(%ebp)
801057b2:	74 17                	je     801057cb <sleep+0x99>
    release(&ptable.lock);
801057b4:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
801057bb:	e8 ca 02 00 00       	call   80105a8a <release>
    acquire(lk);
801057c0:	8b 45 0c             	mov    0xc(%ebp),%eax
801057c3:	89 04 24             	mov    %eax,(%esp)
801057c6:	e8 5d 02 00 00       	call   80105a28 <acquire>
  }
}
801057cb:	c9                   	leave  
801057cc:	c3                   	ret    

801057cd <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801057cd:	55                   	push   %ebp
801057ce:	89 e5                	mov    %esp,%ebp
801057d0:	83 ec 14             	sub    $0x14,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801057d3:	c7 45 fc 54 45 11 80 	movl   $0x80114554,-0x4(%ebp)
801057da:	eb 3f                	jmp    8010581b <wakeup1+0x4e>
    if(p->state == SLEEPING && p->chan == chan) {
801057dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
801057df:	8b 40 0c             	mov    0xc(%eax),%eax
801057e2:	83 f8 02             	cmp    $0x2,%eax
801057e5:	75 2d                	jne    80105814 <wakeup1+0x47>
801057e7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801057ea:	8b 40 20             	mov    0x20(%eax),%eax
801057ed:	3b 45 08             	cmp    0x8(%ebp),%eax
801057f0:	75 22                	jne    80105814 <wakeup1+0x47>
      p->state = RUNNABLE;
801057f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801057f5:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      p->dml_opts = RETURNING_FROM_SLEEP;
801057fc:	8b 45 fc             	mov    -0x4(%ebp),%eax
801057ff:	c7 80 90 00 00 00 00 	movl   $0x0,0x90(%eax)
80105806:	00 00 00 
      enq_to_scheduler(p);
80105809:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010580c:	89 04 24             	mov    %eax,(%esp)
8010580f:	e8 01 f7 ff ff       	call   80104f15 <enq_to_scheduler>
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105814:	81 45 fc 94 00 00 00 	addl   $0x94,-0x4(%ebp)
8010581b:	81 7d fc 54 6a 11 80 	cmpl   $0x80116a54,-0x4(%ebp)
80105822:	72 b8                	jb     801057dc <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan) {
      p->state = RUNNABLE;
      p->dml_opts = RETURNING_FROM_SLEEP;
      enq_to_scheduler(p);
    }
}
80105824:	c9                   	leave  
80105825:	c3                   	ret    

80105826 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105826:	55                   	push   %ebp
80105827:	89 e5                	mov    %esp,%ebp
80105829:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
8010582c:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
80105833:	e8 f0 01 00 00       	call   80105a28 <acquire>
  wakeup1(chan);
80105838:	8b 45 08             	mov    0x8(%ebp),%eax
8010583b:	89 04 24             	mov    %eax,(%esp)
8010583e:	e8 8a ff ff ff       	call   801057cd <wakeup1>
  release(&ptable.lock);
80105843:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
8010584a:	e8 3b 02 00 00       	call   80105a8a <release>
}
8010584f:	c9                   	leave  
80105850:	c3                   	ret    

80105851 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105851:	55                   	push   %ebp
80105852:	89 e5                	mov    %esp,%ebp
80105854:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105857:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
8010585e:	e8 c5 01 00 00       	call   80105a28 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105863:	c7 45 f4 54 45 11 80 	movl   $0x80114554,-0xc(%ebp)
8010586a:	eb 4f                	jmp    801058bb <kill+0x6a>
    if(p->pid == pid){
8010586c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010586f:	8b 40 10             	mov    0x10(%eax),%eax
80105872:	3b 45 08             	cmp    0x8(%ebp),%eax
80105875:	75 3d                	jne    801058b4 <kill+0x63>
      p->killed = 1;
80105877:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010587a:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING) {
80105881:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105884:	8b 40 0c             	mov    0xc(%eax),%eax
80105887:	83 f8 02             	cmp    $0x2,%eax
8010588a:	75 15                	jne    801058a1 <kill+0x50>
        p->state = RUNNABLE;
8010588c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010588f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
        enq_to_scheduler(p);
80105896:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105899:	89 04 24             	mov    %eax,(%esp)
8010589c:	e8 74 f6 ff ff       	call   80104f15 <enq_to_scheduler>
      }
      release(&ptable.lock);
801058a1:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
801058a8:	e8 dd 01 00 00       	call   80105a8a <release>
      return 0;
801058ad:	b8 00 00 00 00       	mov    $0x0,%eax
801058b2:	eb 21                	jmp    801058d5 <kill+0x84>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058b4:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
801058bb:	81 7d f4 54 6a 11 80 	cmpl   $0x80116a54,-0xc(%ebp)
801058c2:	72 a8                	jb     8010586c <kill+0x1b>
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801058c4:	c7 04 24 20 45 11 80 	movl   $0x80114520,(%esp)
801058cb:	e8 ba 01 00 00       	call   80105a8a <release>
  return -1;
801058d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801058d5:	c9                   	leave  
801058d6:	c3                   	ret    

801058d7 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801058d7:	55                   	push   %ebp
801058d8:	89 e5                	mov    %esp,%ebp
801058da:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058dd:	c7 45 f0 54 45 11 80 	movl   $0x80114554,-0x10(%ebp)
801058e4:	e9 d9 00 00 00       	jmp    801059c2 <procdump+0xeb>
    if(p->state == UNUSED)
801058e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058ec:	8b 40 0c             	mov    0xc(%eax),%eax
801058ef:	85 c0                	test   %eax,%eax
801058f1:	75 05                	jne    801058f8 <procdump+0x21>
      continue;
801058f3:	e9 c3 00 00 00       	jmp    801059bb <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801058f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058fb:	8b 40 0c             	mov    0xc(%eax),%eax
801058fe:	83 f8 05             	cmp    $0x5,%eax
80105901:	77 23                	ja     80105926 <procdump+0x4f>
80105903:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105906:	8b 40 0c             	mov    0xc(%eax),%eax
80105909:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80105910:	85 c0                	test   %eax,%eax
80105912:	74 12                	je     80105926 <procdump+0x4f>
      state = states[p->state];
80105914:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105917:	8b 40 0c             	mov    0xc(%eax),%eax
8010591a:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80105921:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105924:	eb 07                	jmp    8010592d <procdump+0x56>
    else
      state = "???";
80105926:	c7 45 ec 70 94 10 80 	movl   $0x80109470,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
8010592d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105930:	8d 50 6c             	lea    0x6c(%eax),%edx
80105933:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105936:	8b 40 10             	mov    0x10(%eax),%eax
80105939:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010593d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105940:	89 54 24 08          	mov    %edx,0x8(%esp)
80105944:	89 44 24 04          	mov    %eax,0x4(%esp)
80105948:	c7 04 24 74 94 10 80 	movl   $0x80109474,(%esp)
8010594f:	e8 4c aa ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80105954:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105957:	8b 40 0c             	mov    0xc(%eax),%eax
8010595a:	83 f8 02             	cmp    $0x2,%eax
8010595d:	75 50                	jne    801059af <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
8010595f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105962:	8b 40 1c             	mov    0x1c(%eax),%eax
80105965:	8b 40 0c             	mov    0xc(%eax),%eax
80105968:	83 c0 08             	add    $0x8,%eax
8010596b:	8d 55 c4             	lea    -0x3c(%ebp),%edx
8010596e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105972:	89 04 24             	mov    %eax,(%esp)
80105975:	e8 5f 01 00 00       	call   80105ad9 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
8010597a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105981:	eb 1b                	jmp    8010599e <procdump+0xc7>
        cprintf(" %p", pc[i]);
80105983:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105986:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
8010598a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010598e:	c7 04 24 7d 94 10 80 	movl   $0x8010947d,(%esp)
80105995:	e8 06 aa ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
8010599a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010599e:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801059a2:	7f 0b                	jg     801059af <procdump+0xd8>
801059a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059a7:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801059ab:	85 c0                	test   %eax,%eax
801059ad:	75 d4                	jne    80105983 <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801059af:	c7 04 24 81 94 10 80 	movl   $0x80109481,(%esp)
801059b6:	e8 e5 a9 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801059bb:	81 45 f0 94 00 00 00 	addl   $0x94,-0x10(%ebp)
801059c2:	81 7d f0 54 6a 11 80 	cmpl   $0x80116a54,-0x10(%ebp)
801059c9:	0f 82 1a ff ff ff    	jb     801058e9 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801059cf:	c9                   	leave  
801059d0:	c3                   	ret    

801059d1 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801059d1:	55                   	push   %ebp
801059d2:	89 e5                	mov    %esp,%ebp
801059d4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801059d7:	9c                   	pushf  
801059d8:	58                   	pop    %eax
801059d9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801059dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801059df:	c9                   	leave  
801059e0:	c3                   	ret    

801059e1 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801059e1:	55                   	push   %ebp
801059e2:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801059e4:	fa                   	cli    
}
801059e5:	5d                   	pop    %ebp
801059e6:	c3                   	ret    

801059e7 <sti>:

static inline void
sti(void)
{
801059e7:	55                   	push   %ebp
801059e8:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801059ea:	fb                   	sti    
}
801059eb:	5d                   	pop    %ebp
801059ec:	c3                   	ret    

801059ed <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
801059ed:	55                   	push   %ebp
801059ee:	89 e5                	mov    %esp,%ebp
801059f0:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801059f3:	8b 55 08             	mov    0x8(%ebp),%edx
801059f6:	8b 45 0c             	mov    0xc(%ebp),%eax
801059f9:	8b 4d 08             	mov    0x8(%ebp),%ecx
801059fc:	f0 87 02             	lock xchg %eax,(%edx)
801059ff:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105a02:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105a05:	c9                   	leave  
80105a06:	c3                   	ret    

80105a07 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105a07:	55                   	push   %ebp
80105a08:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105a0a:	8b 45 08             	mov    0x8(%ebp),%eax
80105a0d:	8b 55 0c             	mov    0xc(%ebp),%edx
80105a10:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105a13:	8b 45 08             	mov    0x8(%ebp),%eax
80105a16:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105a1c:	8b 45 08             	mov    0x8(%ebp),%eax
80105a1f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105a26:	5d                   	pop    %ebp
80105a27:	c3                   	ret    

80105a28 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105a28:	55                   	push   %ebp
80105a29:	89 e5                	mov    %esp,%ebp
80105a2b:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105a2e:	e8 49 01 00 00       	call   80105b7c <pushcli>
  if(holding(lk))
80105a33:	8b 45 08             	mov    0x8(%ebp),%eax
80105a36:	89 04 24             	mov    %eax,(%esp)
80105a39:	e8 14 01 00 00       	call   80105b52 <holding>
80105a3e:	85 c0                	test   %eax,%eax
80105a40:	74 0c                	je     80105a4e <acquire+0x26>
    panic("acquire");
80105a42:	c7 04 24 ad 94 10 80 	movl   $0x801094ad,(%esp)
80105a49:	e8 ec aa ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105a4e:	90                   	nop
80105a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a52:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105a59:	00 
80105a5a:	89 04 24             	mov    %eax,(%esp)
80105a5d:	e8 8b ff ff ff       	call   801059ed <xchg>
80105a62:	85 c0                	test   %eax,%eax
80105a64:	75 e9                	jne    80105a4f <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105a66:	8b 45 08             	mov    0x8(%ebp),%eax
80105a69:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105a70:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105a73:	8b 45 08             	mov    0x8(%ebp),%eax
80105a76:	83 c0 0c             	add    $0xc,%eax
80105a79:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a7d:	8d 45 08             	lea    0x8(%ebp),%eax
80105a80:	89 04 24             	mov    %eax,(%esp)
80105a83:	e8 51 00 00 00       	call   80105ad9 <getcallerpcs>
}
80105a88:	c9                   	leave  
80105a89:	c3                   	ret    

80105a8a <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105a8a:	55                   	push   %ebp
80105a8b:	89 e5                	mov    %esp,%ebp
80105a8d:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105a90:	8b 45 08             	mov    0x8(%ebp),%eax
80105a93:	89 04 24             	mov    %eax,(%esp)
80105a96:	e8 b7 00 00 00       	call   80105b52 <holding>
80105a9b:	85 c0                	test   %eax,%eax
80105a9d:	75 0c                	jne    80105aab <release+0x21>
    panic("release");
80105a9f:	c7 04 24 b5 94 10 80 	movl   $0x801094b5,(%esp)
80105aa6:	e8 8f aa ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105aab:	8b 45 08             	mov    0x8(%ebp),%eax
80105aae:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105ab5:	8b 45 08             	mov    0x8(%ebp),%eax
80105ab8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105abf:	8b 45 08             	mov    0x8(%ebp),%eax
80105ac2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105ac9:	00 
80105aca:	89 04 24             	mov    %eax,(%esp)
80105acd:	e8 1b ff ff ff       	call   801059ed <xchg>

  popcli();
80105ad2:	e8 e9 00 00 00       	call   80105bc0 <popcli>
}
80105ad7:	c9                   	leave  
80105ad8:	c3                   	ret    

80105ad9 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105ad9:	55                   	push   %ebp
80105ada:	89 e5                	mov    %esp,%ebp
80105adc:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105adf:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae2:	83 e8 08             	sub    $0x8,%eax
80105ae5:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105ae8:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105aef:	eb 38                	jmp    80105b29 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105af1:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105af5:	74 38                	je     80105b2f <getcallerpcs+0x56>
80105af7:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105afe:	76 2f                	jbe    80105b2f <getcallerpcs+0x56>
80105b00:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105b04:	74 29                	je     80105b2f <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105b06:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b09:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105b10:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b13:	01 c2                	add    %eax,%edx
80105b15:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b18:	8b 40 04             	mov    0x4(%eax),%eax
80105b1b:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105b1d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b20:	8b 00                	mov    (%eax),%eax
80105b22:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105b25:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105b29:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105b2d:	7e c2                	jle    80105af1 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105b2f:	eb 19                	jmp    80105b4a <getcallerpcs+0x71>
    pcs[i] = 0;
80105b31:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b34:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105b3b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b3e:	01 d0                	add    %edx,%eax
80105b40:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105b46:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105b4a:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105b4e:	7e e1                	jle    80105b31 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105b50:	c9                   	leave  
80105b51:	c3                   	ret    

80105b52 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105b52:	55                   	push   %ebp
80105b53:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105b55:	8b 45 08             	mov    0x8(%ebp),%eax
80105b58:	8b 00                	mov    (%eax),%eax
80105b5a:	85 c0                	test   %eax,%eax
80105b5c:	74 17                	je     80105b75 <holding+0x23>
80105b5e:	8b 45 08             	mov    0x8(%ebp),%eax
80105b61:	8b 50 08             	mov    0x8(%eax),%edx
80105b64:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b6a:	39 c2                	cmp    %eax,%edx
80105b6c:	75 07                	jne    80105b75 <holding+0x23>
80105b6e:	b8 01 00 00 00       	mov    $0x1,%eax
80105b73:	eb 05                	jmp    80105b7a <holding+0x28>
80105b75:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105b7a:	5d                   	pop    %ebp
80105b7b:	c3                   	ret    

80105b7c <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105b7c:	55                   	push   %ebp
80105b7d:	89 e5                	mov    %esp,%ebp
80105b7f:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105b82:	e8 4a fe ff ff       	call   801059d1 <readeflags>
80105b87:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105b8a:	e8 52 fe ff ff       	call   801059e1 <cli>
  if(cpu->ncli++ == 0)
80105b8f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105b96:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105b9c:	8d 48 01             	lea    0x1(%eax),%ecx
80105b9f:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105ba5:	85 c0                	test   %eax,%eax
80105ba7:	75 15                	jne    80105bbe <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105ba9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105baf:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105bb2:	81 e2 00 02 00 00    	and    $0x200,%edx
80105bb8:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105bbe:	c9                   	leave  
80105bbf:	c3                   	ret    

80105bc0 <popcli>:

void
popcli(void)
{
80105bc0:	55                   	push   %ebp
80105bc1:	89 e5                	mov    %esp,%ebp
80105bc3:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105bc6:	e8 06 fe ff ff       	call   801059d1 <readeflags>
80105bcb:	25 00 02 00 00       	and    $0x200,%eax
80105bd0:	85 c0                	test   %eax,%eax
80105bd2:	74 0c                	je     80105be0 <popcli+0x20>
    panic("popcli - interruptible");
80105bd4:	c7 04 24 bd 94 10 80 	movl   $0x801094bd,(%esp)
80105bdb:	e8 5a a9 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105be0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105be6:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105bec:	83 ea 01             	sub    $0x1,%edx
80105bef:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105bf5:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105bfb:	85 c0                	test   %eax,%eax
80105bfd:	79 0c                	jns    80105c0b <popcli+0x4b>
    panic("popcli");
80105bff:	c7 04 24 d4 94 10 80 	movl   $0x801094d4,(%esp)
80105c06:	e8 2f a9 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105c0b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c11:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105c17:	85 c0                	test   %eax,%eax
80105c19:	75 15                	jne    80105c30 <popcli+0x70>
80105c1b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c21:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105c27:	85 c0                	test   %eax,%eax
80105c29:	74 05                	je     80105c30 <popcli+0x70>
    sti();
80105c2b:	e8 b7 fd ff ff       	call   801059e7 <sti>
}
80105c30:	c9                   	leave  
80105c31:	c3                   	ret    

80105c32 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105c32:	55                   	push   %ebp
80105c33:	89 e5                	mov    %esp,%ebp
80105c35:	57                   	push   %edi
80105c36:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105c37:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105c3a:	8b 55 10             	mov    0x10(%ebp),%edx
80105c3d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c40:	89 cb                	mov    %ecx,%ebx
80105c42:	89 df                	mov    %ebx,%edi
80105c44:	89 d1                	mov    %edx,%ecx
80105c46:	fc                   	cld    
80105c47:	f3 aa                	rep stos %al,%es:(%edi)
80105c49:	89 ca                	mov    %ecx,%edx
80105c4b:	89 fb                	mov    %edi,%ebx
80105c4d:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105c50:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105c53:	5b                   	pop    %ebx
80105c54:	5f                   	pop    %edi
80105c55:	5d                   	pop    %ebp
80105c56:	c3                   	ret    

80105c57 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105c57:	55                   	push   %ebp
80105c58:	89 e5                	mov    %esp,%ebp
80105c5a:	57                   	push   %edi
80105c5b:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105c5c:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105c5f:	8b 55 10             	mov    0x10(%ebp),%edx
80105c62:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c65:	89 cb                	mov    %ecx,%ebx
80105c67:	89 df                	mov    %ebx,%edi
80105c69:	89 d1                	mov    %edx,%ecx
80105c6b:	fc                   	cld    
80105c6c:	f3 ab                	rep stos %eax,%es:(%edi)
80105c6e:	89 ca                	mov    %ecx,%edx
80105c70:	89 fb                	mov    %edi,%ebx
80105c72:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105c75:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105c78:	5b                   	pop    %ebx
80105c79:	5f                   	pop    %edi
80105c7a:	5d                   	pop    %ebp
80105c7b:	c3                   	ret    

80105c7c <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105c7c:	55                   	push   %ebp
80105c7d:	89 e5                	mov    %esp,%ebp
80105c7f:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105c82:	8b 45 08             	mov    0x8(%ebp),%eax
80105c85:	83 e0 03             	and    $0x3,%eax
80105c88:	85 c0                	test   %eax,%eax
80105c8a:	75 49                	jne    80105cd5 <memset+0x59>
80105c8c:	8b 45 10             	mov    0x10(%ebp),%eax
80105c8f:	83 e0 03             	and    $0x3,%eax
80105c92:	85 c0                	test   %eax,%eax
80105c94:	75 3f                	jne    80105cd5 <memset+0x59>
    c &= 0xFF;
80105c96:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105c9d:	8b 45 10             	mov    0x10(%ebp),%eax
80105ca0:	c1 e8 02             	shr    $0x2,%eax
80105ca3:	89 c2                	mov    %eax,%edx
80105ca5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ca8:	c1 e0 18             	shl    $0x18,%eax
80105cab:	89 c1                	mov    %eax,%ecx
80105cad:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cb0:	c1 e0 10             	shl    $0x10,%eax
80105cb3:	09 c1                	or     %eax,%ecx
80105cb5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cb8:	c1 e0 08             	shl    $0x8,%eax
80105cbb:	09 c8                	or     %ecx,%eax
80105cbd:	0b 45 0c             	or     0xc(%ebp),%eax
80105cc0:	89 54 24 08          	mov    %edx,0x8(%esp)
80105cc4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cc8:	8b 45 08             	mov    0x8(%ebp),%eax
80105ccb:	89 04 24             	mov    %eax,(%esp)
80105cce:	e8 84 ff ff ff       	call   80105c57 <stosl>
80105cd3:	eb 19                	jmp    80105cee <memset+0x72>
  } else
    stosb(dst, c, n);
80105cd5:	8b 45 10             	mov    0x10(%ebp),%eax
80105cd8:	89 44 24 08          	mov    %eax,0x8(%esp)
80105cdc:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cdf:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ce3:	8b 45 08             	mov    0x8(%ebp),%eax
80105ce6:	89 04 24             	mov    %eax,(%esp)
80105ce9:	e8 44 ff ff ff       	call   80105c32 <stosb>
  return dst;
80105cee:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105cf1:	c9                   	leave  
80105cf2:	c3                   	ret    

80105cf3 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105cf3:	55                   	push   %ebp
80105cf4:	89 e5                	mov    %esp,%ebp
80105cf6:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105cf9:	8b 45 08             	mov    0x8(%ebp),%eax
80105cfc:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105cff:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d02:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105d05:	eb 30                	jmp    80105d37 <memcmp+0x44>
    if(*s1 != *s2)
80105d07:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d0a:	0f b6 10             	movzbl (%eax),%edx
80105d0d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d10:	0f b6 00             	movzbl (%eax),%eax
80105d13:	38 c2                	cmp    %al,%dl
80105d15:	74 18                	je     80105d2f <memcmp+0x3c>
      return *s1 - *s2;
80105d17:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d1a:	0f b6 00             	movzbl (%eax),%eax
80105d1d:	0f b6 d0             	movzbl %al,%edx
80105d20:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d23:	0f b6 00             	movzbl (%eax),%eax
80105d26:	0f b6 c0             	movzbl %al,%eax
80105d29:	29 c2                	sub    %eax,%edx
80105d2b:	89 d0                	mov    %edx,%eax
80105d2d:	eb 1a                	jmp    80105d49 <memcmp+0x56>
    s1++, s2++;
80105d2f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d33:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105d37:	8b 45 10             	mov    0x10(%ebp),%eax
80105d3a:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d3d:	89 55 10             	mov    %edx,0x10(%ebp)
80105d40:	85 c0                	test   %eax,%eax
80105d42:	75 c3                	jne    80105d07 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105d44:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d49:	c9                   	leave  
80105d4a:	c3                   	ret    

80105d4b <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105d4b:	55                   	push   %ebp
80105d4c:	89 e5                	mov    %esp,%ebp
80105d4e:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105d51:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d54:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105d57:	8b 45 08             	mov    0x8(%ebp),%eax
80105d5a:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105d5d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d60:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d63:	73 3d                	jae    80105da2 <memmove+0x57>
80105d65:	8b 45 10             	mov    0x10(%ebp),%eax
80105d68:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d6b:	01 d0                	add    %edx,%eax
80105d6d:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d70:	76 30                	jbe    80105da2 <memmove+0x57>
    s += n;
80105d72:	8b 45 10             	mov    0x10(%ebp),%eax
80105d75:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105d78:	8b 45 10             	mov    0x10(%ebp),%eax
80105d7b:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105d7e:	eb 13                	jmp    80105d93 <memmove+0x48>
      *--d = *--s;
80105d80:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105d84:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105d88:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d8b:	0f b6 10             	movzbl (%eax),%edx
80105d8e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d91:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105d93:	8b 45 10             	mov    0x10(%ebp),%eax
80105d96:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d99:	89 55 10             	mov    %edx,0x10(%ebp)
80105d9c:	85 c0                	test   %eax,%eax
80105d9e:	75 e0                	jne    80105d80 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105da0:	eb 26                	jmp    80105dc8 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105da2:	eb 17                	jmp    80105dbb <memmove+0x70>
      *d++ = *s++;
80105da4:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105da7:	8d 50 01             	lea    0x1(%eax),%edx
80105daa:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105dad:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105db0:	8d 4a 01             	lea    0x1(%edx),%ecx
80105db3:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105db6:	0f b6 12             	movzbl (%edx),%edx
80105db9:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105dbb:	8b 45 10             	mov    0x10(%ebp),%eax
80105dbe:	8d 50 ff             	lea    -0x1(%eax),%edx
80105dc1:	89 55 10             	mov    %edx,0x10(%ebp)
80105dc4:	85 c0                	test   %eax,%eax
80105dc6:	75 dc                	jne    80105da4 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105dc8:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105dcb:	c9                   	leave  
80105dcc:	c3                   	ret    

80105dcd <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105dcd:	55                   	push   %ebp
80105dce:	89 e5                	mov    %esp,%ebp
80105dd0:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105dd3:	8b 45 10             	mov    0x10(%ebp),%eax
80105dd6:	89 44 24 08          	mov    %eax,0x8(%esp)
80105dda:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ddd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de1:	8b 45 08             	mov    0x8(%ebp),%eax
80105de4:	89 04 24             	mov    %eax,(%esp)
80105de7:	e8 5f ff ff ff       	call   80105d4b <memmove>
}
80105dec:	c9                   	leave  
80105ded:	c3                   	ret    

80105dee <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105dee:	55                   	push   %ebp
80105def:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105df1:	eb 0c                	jmp    80105dff <strncmp+0x11>
    n--, p++, q++;
80105df3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105df7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105dfb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105dff:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e03:	74 1a                	je     80105e1f <strncmp+0x31>
80105e05:	8b 45 08             	mov    0x8(%ebp),%eax
80105e08:	0f b6 00             	movzbl (%eax),%eax
80105e0b:	84 c0                	test   %al,%al
80105e0d:	74 10                	je     80105e1f <strncmp+0x31>
80105e0f:	8b 45 08             	mov    0x8(%ebp),%eax
80105e12:	0f b6 10             	movzbl (%eax),%edx
80105e15:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e18:	0f b6 00             	movzbl (%eax),%eax
80105e1b:	38 c2                	cmp    %al,%dl
80105e1d:	74 d4                	je     80105df3 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105e1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e23:	75 07                	jne    80105e2c <strncmp+0x3e>
    return 0;
80105e25:	b8 00 00 00 00       	mov    $0x0,%eax
80105e2a:	eb 16                	jmp    80105e42 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105e2c:	8b 45 08             	mov    0x8(%ebp),%eax
80105e2f:	0f b6 00             	movzbl (%eax),%eax
80105e32:	0f b6 d0             	movzbl %al,%edx
80105e35:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e38:	0f b6 00             	movzbl (%eax),%eax
80105e3b:	0f b6 c0             	movzbl %al,%eax
80105e3e:	29 c2                	sub    %eax,%edx
80105e40:	89 d0                	mov    %edx,%eax
}
80105e42:	5d                   	pop    %ebp
80105e43:	c3                   	ret    

80105e44 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105e44:	55                   	push   %ebp
80105e45:	89 e5                	mov    %esp,%ebp
80105e47:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105e4a:	8b 45 08             	mov    0x8(%ebp),%eax
80105e4d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105e50:	90                   	nop
80105e51:	8b 45 10             	mov    0x10(%ebp),%eax
80105e54:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e57:	89 55 10             	mov    %edx,0x10(%ebp)
80105e5a:	85 c0                	test   %eax,%eax
80105e5c:	7e 1e                	jle    80105e7c <strncpy+0x38>
80105e5e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e61:	8d 50 01             	lea    0x1(%eax),%edx
80105e64:	89 55 08             	mov    %edx,0x8(%ebp)
80105e67:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e6a:	8d 4a 01             	lea    0x1(%edx),%ecx
80105e6d:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105e70:	0f b6 12             	movzbl (%edx),%edx
80105e73:	88 10                	mov    %dl,(%eax)
80105e75:	0f b6 00             	movzbl (%eax),%eax
80105e78:	84 c0                	test   %al,%al
80105e7a:	75 d5                	jne    80105e51 <strncpy+0xd>
    ;
  while(n-- > 0)
80105e7c:	eb 0c                	jmp    80105e8a <strncpy+0x46>
    *s++ = 0;
80105e7e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e81:	8d 50 01             	lea    0x1(%eax),%edx
80105e84:	89 55 08             	mov    %edx,0x8(%ebp)
80105e87:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105e8a:	8b 45 10             	mov    0x10(%ebp),%eax
80105e8d:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e90:	89 55 10             	mov    %edx,0x10(%ebp)
80105e93:	85 c0                	test   %eax,%eax
80105e95:	7f e7                	jg     80105e7e <strncpy+0x3a>
    *s++ = 0;
  return os;
80105e97:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105e9a:	c9                   	leave  
80105e9b:	c3                   	ret    

80105e9c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105e9c:	55                   	push   %ebp
80105e9d:	89 e5                	mov    %esp,%ebp
80105e9f:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105ea2:	8b 45 08             	mov    0x8(%ebp),%eax
80105ea5:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105ea8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105eac:	7f 05                	jg     80105eb3 <safestrcpy+0x17>
    return os;
80105eae:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105eb1:	eb 31                	jmp    80105ee4 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105eb3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105eb7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ebb:	7e 1e                	jle    80105edb <safestrcpy+0x3f>
80105ebd:	8b 45 08             	mov    0x8(%ebp),%eax
80105ec0:	8d 50 01             	lea    0x1(%eax),%edx
80105ec3:	89 55 08             	mov    %edx,0x8(%ebp)
80105ec6:	8b 55 0c             	mov    0xc(%ebp),%edx
80105ec9:	8d 4a 01             	lea    0x1(%edx),%ecx
80105ecc:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105ecf:	0f b6 12             	movzbl (%edx),%edx
80105ed2:	88 10                	mov    %dl,(%eax)
80105ed4:	0f b6 00             	movzbl (%eax),%eax
80105ed7:	84 c0                	test   %al,%al
80105ed9:	75 d8                	jne    80105eb3 <safestrcpy+0x17>
    ;
  *s = 0;
80105edb:	8b 45 08             	mov    0x8(%ebp),%eax
80105ede:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105ee1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105ee4:	c9                   	leave  
80105ee5:	c3                   	ret    

80105ee6 <strlen>:

int
strlen(const char *s)
{
80105ee6:	55                   	push   %ebp
80105ee7:	89 e5                	mov    %esp,%ebp
80105ee9:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105eec:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105ef3:	eb 04                	jmp    80105ef9 <strlen+0x13>
80105ef5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ef9:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105efc:	8b 45 08             	mov    0x8(%ebp),%eax
80105eff:	01 d0                	add    %edx,%eax
80105f01:	0f b6 00             	movzbl (%eax),%eax
80105f04:	84 c0                	test   %al,%al
80105f06:	75 ed                	jne    80105ef5 <strlen+0xf>
    ;
  return n;
80105f08:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f0b:	c9                   	leave  
80105f0c:	c3                   	ret    

80105f0d <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105f0d:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105f11:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105f15:	55                   	push   %ebp
  pushl %ebx
80105f16:	53                   	push   %ebx
  pushl %esi
80105f17:	56                   	push   %esi
  pushl %edi
80105f18:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105f19:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105f1b:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105f1d:	5f                   	pop    %edi
  popl %esi
80105f1e:	5e                   	pop    %esi
  popl %ebx
80105f1f:	5b                   	pop    %ebx
  popl %ebp
80105f20:	5d                   	pop    %ebp
  ret
80105f21:	c3                   	ret    

80105f22 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105f22:	55                   	push   %ebp
80105f23:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80105f25:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f2b:	8b 00                	mov    (%eax),%eax
80105f2d:	3b 45 08             	cmp    0x8(%ebp),%eax
80105f30:	76 12                	jbe    80105f44 <fetchint+0x22>
80105f32:	8b 45 08             	mov    0x8(%ebp),%eax
80105f35:	8d 50 04             	lea    0x4(%eax),%edx
80105f38:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f3e:	8b 00                	mov    (%eax),%eax
80105f40:	39 c2                	cmp    %eax,%edx
80105f42:	76 07                	jbe    80105f4b <fetchint+0x29>
    return -1;
80105f44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f49:	eb 0f                	jmp    80105f5a <fetchint+0x38>
  *ip = *(int*)(addr);
80105f4b:	8b 45 08             	mov    0x8(%ebp),%eax
80105f4e:	8b 10                	mov    (%eax),%edx
80105f50:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f53:	89 10                	mov    %edx,(%eax)
  return 0;
80105f55:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f5a:	5d                   	pop    %ebp
80105f5b:	c3                   	ret    

80105f5c <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105f5c:	55                   	push   %ebp
80105f5d:	89 e5                	mov    %esp,%ebp
80105f5f:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105f62:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f68:	8b 00                	mov    (%eax),%eax
80105f6a:	3b 45 08             	cmp    0x8(%ebp),%eax
80105f6d:	77 07                	ja     80105f76 <fetchstr+0x1a>
    return -1;
80105f6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f74:	eb 46                	jmp    80105fbc <fetchstr+0x60>
  *pp = (char*)addr;
80105f76:	8b 55 08             	mov    0x8(%ebp),%edx
80105f79:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f7c:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105f7e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f84:	8b 00                	mov    (%eax),%eax
80105f86:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105f89:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f8c:	8b 00                	mov    (%eax),%eax
80105f8e:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105f91:	eb 1c                	jmp    80105faf <fetchstr+0x53>
    if(*s == 0)
80105f93:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f96:	0f b6 00             	movzbl (%eax),%eax
80105f99:	84 c0                	test   %al,%al
80105f9b:	75 0e                	jne    80105fab <fetchstr+0x4f>
      return s - *pp;
80105f9d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fa0:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fa3:	8b 00                	mov    (%eax),%eax
80105fa5:	29 c2                	sub    %eax,%edx
80105fa7:	89 d0                	mov    %edx,%eax
80105fa9:	eb 11                	jmp    80105fbc <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
80105fab:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105faf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fb2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105fb5:	72 dc                	jb     80105f93 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105fb7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105fbc:	c9                   	leave  
80105fbd:	c3                   	ret    

80105fbe <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105fbe:	55                   	push   %ebp
80105fbf:	89 e5                	mov    %esp,%ebp
80105fc1:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105fc4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fca:	8b 40 18             	mov    0x18(%eax),%eax
80105fcd:	8b 50 44             	mov    0x44(%eax),%edx
80105fd0:	8b 45 08             	mov    0x8(%ebp),%eax
80105fd3:	c1 e0 02             	shl    $0x2,%eax
80105fd6:	01 d0                	add    %edx,%eax
80105fd8:	8d 50 04             	lea    0x4(%eax),%edx
80105fdb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fde:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fe2:	89 14 24             	mov    %edx,(%esp)
80105fe5:	e8 38 ff ff ff       	call   80105f22 <fetchint>
}
80105fea:	c9                   	leave  
80105feb:	c3                   	ret    

80105fec <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105fec:	55                   	push   %ebp
80105fed:	89 e5                	mov    %esp,%ebp
80105fef:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105ff2:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105ff5:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ff9:	8b 45 08             	mov    0x8(%ebp),%eax
80105ffc:	89 04 24             	mov    %eax,(%esp)
80105fff:	e8 ba ff ff ff       	call   80105fbe <argint>
80106004:	85 c0                	test   %eax,%eax
80106006:	79 07                	jns    8010600f <argptr+0x23>
    return -1;
80106008:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010600d:	eb 3d                	jmp    8010604c <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
8010600f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106012:	89 c2                	mov    %eax,%edx
80106014:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010601a:	8b 00                	mov    (%eax),%eax
8010601c:	39 c2                	cmp    %eax,%edx
8010601e:	73 16                	jae    80106036 <argptr+0x4a>
80106020:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106023:	89 c2                	mov    %eax,%edx
80106025:	8b 45 10             	mov    0x10(%ebp),%eax
80106028:	01 c2                	add    %eax,%edx
8010602a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106030:	8b 00                	mov    (%eax),%eax
80106032:	39 c2                	cmp    %eax,%edx
80106034:	76 07                	jbe    8010603d <argptr+0x51>
    return -1;
80106036:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010603b:	eb 0f                	jmp    8010604c <argptr+0x60>
  *pp = (char*)i;
8010603d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106040:	89 c2                	mov    %eax,%edx
80106042:	8b 45 0c             	mov    0xc(%ebp),%eax
80106045:	89 10                	mov    %edx,(%eax)
  return 0;
80106047:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010604c:	c9                   	leave  
8010604d:	c3                   	ret    

8010604e <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010604e:	55                   	push   %ebp
8010604f:	89 e5                	mov    %esp,%ebp
80106051:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80106054:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106057:	89 44 24 04          	mov    %eax,0x4(%esp)
8010605b:	8b 45 08             	mov    0x8(%ebp),%eax
8010605e:	89 04 24             	mov    %eax,(%esp)
80106061:	e8 58 ff ff ff       	call   80105fbe <argint>
80106066:	85 c0                	test   %eax,%eax
80106068:	79 07                	jns    80106071 <argstr+0x23>
    return -1;
8010606a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010606f:	eb 12                	jmp    80106083 <argstr+0x35>
  return fetchstr(addr, pp);
80106071:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106074:	8b 55 0c             	mov    0xc(%ebp),%edx
80106077:	89 54 24 04          	mov    %edx,0x4(%esp)
8010607b:	89 04 24             	mov    %eax,(%esp)
8010607e:	e8 d9 fe ff ff       	call   80105f5c <fetchstr>
}
80106083:	c9                   	leave  
80106084:	c3                   	ret    

80106085 <syscall>:
[SYS_set_prio] sys_set_prio,
};

void
syscall(void)
{
80106085:	55                   	push   %ebp
80106086:	89 e5                	mov    %esp,%ebp
80106088:	53                   	push   %ebx
80106089:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010608c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106092:	8b 40 18             	mov    0x18(%eax),%eax
80106095:	8b 40 1c             	mov    0x1c(%eax),%eax
80106098:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010609b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010609f:	7e 30                	jle    801060d1 <syscall+0x4c>
801060a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060a4:	83 f8 18             	cmp    $0x18,%eax
801060a7:	77 28                	ja     801060d1 <syscall+0x4c>
801060a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060ac:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801060b3:	85 c0                	test   %eax,%eax
801060b5:	74 1a                	je     801060d1 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
801060b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060bd:	8b 58 18             	mov    0x18(%eax),%ebx
801060c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060c3:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801060ca:	ff d0                	call   *%eax
801060cc:	89 43 1c             	mov    %eax,0x1c(%ebx)
801060cf:	eb 3d                	jmp    8010610e <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801060d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060d7:	8d 48 6c             	lea    0x6c(%eax),%ecx
801060da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801060e0:	8b 40 10             	mov    0x10(%eax),%eax
801060e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060e6:	89 54 24 0c          	mov    %edx,0xc(%esp)
801060ea:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801060ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801060f2:	c7 04 24 db 94 10 80 	movl   $0x801094db,(%esp)
801060f9:	e8 a2 a2 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801060fe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106104:	8b 40 18             	mov    0x18(%eax),%eax
80106107:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
8010610e:	83 c4 24             	add    $0x24,%esp
80106111:	5b                   	pop    %ebx
80106112:	5d                   	pop    %ebp
80106113:	c3                   	ret    

80106114 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80106114:	55                   	push   %ebp
80106115:	89 e5                	mov    %esp,%ebp
80106117:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010611a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010611d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106121:	8b 45 08             	mov    0x8(%ebp),%eax
80106124:	89 04 24             	mov    %eax,(%esp)
80106127:	e8 92 fe ff ff       	call   80105fbe <argint>
8010612c:	85 c0                	test   %eax,%eax
8010612e:	79 07                	jns    80106137 <argfd+0x23>
    return -1;
80106130:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106135:	eb 50                	jmp    80106187 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80106137:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010613a:	85 c0                	test   %eax,%eax
8010613c:	78 21                	js     8010615f <argfd+0x4b>
8010613e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106141:	83 f8 0f             	cmp    $0xf,%eax
80106144:	7f 19                	jg     8010615f <argfd+0x4b>
80106146:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010614c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010614f:	83 c2 08             	add    $0x8,%edx
80106152:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106156:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106159:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010615d:	75 07                	jne    80106166 <argfd+0x52>
    return -1;
8010615f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106164:	eb 21                	jmp    80106187 <argfd+0x73>
  if(pfd)
80106166:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010616a:	74 08                	je     80106174 <argfd+0x60>
    *pfd = fd;
8010616c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010616f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106172:	89 10                	mov    %edx,(%eax)
  if(pf)
80106174:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106178:	74 08                	je     80106182 <argfd+0x6e>
    *pf = f;
8010617a:	8b 45 10             	mov    0x10(%ebp),%eax
8010617d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106180:	89 10                	mov    %edx,(%eax)
  return 0;
80106182:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106187:	c9                   	leave  
80106188:	c3                   	ret    

80106189 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106189:	55                   	push   %ebp
8010618a:	89 e5                	mov    %esp,%ebp
8010618c:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010618f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80106196:	eb 30                	jmp    801061c8 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106198:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010619e:	8b 55 fc             	mov    -0x4(%ebp),%edx
801061a1:	83 c2 08             	add    $0x8,%edx
801061a4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801061a8:	85 c0                	test   %eax,%eax
801061aa:	75 18                	jne    801061c4 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801061ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061b2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801061b5:	8d 4a 08             	lea    0x8(%edx),%ecx
801061b8:	8b 55 08             	mov    0x8(%ebp),%edx
801061bb:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801061bf:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061c2:	eb 0f                	jmp    801061d3 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801061c4:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801061c8:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801061cc:	7e ca                	jle    80106198 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801061ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801061d3:	c9                   	leave  
801061d4:	c3                   	ret    

801061d5 <sys_dup>:

int
sys_dup(void)
{
801061d5:	55                   	push   %ebp
801061d6:	89 e5                	mov    %esp,%ebp
801061d8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801061db:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061de:	89 44 24 08          	mov    %eax,0x8(%esp)
801061e2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801061e9:	00 
801061ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061f1:	e8 1e ff ff ff       	call   80106114 <argfd>
801061f6:	85 c0                	test   %eax,%eax
801061f8:	79 07                	jns    80106201 <sys_dup+0x2c>
    return -1;
801061fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ff:	eb 29                	jmp    8010622a <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106201:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106204:	89 04 24             	mov    %eax,(%esp)
80106207:	e8 7d ff ff ff       	call   80106189 <fdalloc>
8010620c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010620f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106213:	79 07                	jns    8010621c <sys_dup+0x47>
    return -1;
80106215:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010621a:	eb 0e                	jmp    8010622a <sys_dup+0x55>
  filedup(f);
8010621c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010621f:	89 04 24             	mov    %eax,(%esp)
80106222:	e8 9b b3 ff ff       	call   801015c2 <filedup>
  return fd;
80106227:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010622a:	c9                   	leave  
8010622b:	c3                   	ret    

8010622c <sys_read>:

int
sys_read(void)
{
8010622c:	55                   	push   %ebp
8010622d:	89 e5                	mov    %esp,%ebp
8010622f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106232:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106235:	89 44 24 08          	mov    %eax,0x8(%esp)
80106239:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106240:	00 
80106241:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106248:	e8 c7 fe ff ff       	call   80106114 <argfd>
8010624d:	85 c0                	test   %eax,%eax
8010624f:	78 35                	js     80106286 <sys_read+0x5a>
80106251:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106254:	89 44 24 04          	mov    %eax,0x4(%esp)
80106258:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010625f:	e8 5a fd ff ff       	call   80105fbe <argint>
80106264:	85 c0                	test   %eax,%eax
80106266:	78 1e                	js     80106286 <sys_read+0x5a>
80106268:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010626b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010626f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106272:	89 44 24 04          	mov    %eax,0x4(%esp)
80106276:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010627d:	e8 6a fd ff ff       	call   80105fec <argptr>
80106282:	85 c0                	test   %eax,%eax
80106284:	79 07                	jns    8010628d <sys_read+0x61>
    return -1;
80106286:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010628b:	eb 19                	jmp    801062a6 <sys_read+0x7a>
  return fileread(f, p, n);
8010628d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106290:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106296:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010629a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010629e:	89 04 24             	mov    %eax,(%esp)
801062a1:	e8 89 b4 ff ff       	call   8010172f <fileread>
}
801062a6:	c9                   	leave  
801062a7:	c3                   	ret    

801062a8 <sys_write>:

int
sys_write(void)
{
801062a8:	55                   	push   %ebp
801062a9:	89 e5                	mov    %esp,%ebp
801062ab:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801062ae:	8d 45 f4             	lea    -0xc(%ebp),%eax
801062b1:	89 44 24 08          	mov    %eax,0x8(%esp)
801062b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801062bc:	00 
801062bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062c4:	e8 4b fe ff ff       	call   80106114 <argfd>
801062c9:	85 c0                	test   %eax,%eax
801062cb:	78 35                	js     80106302 <sys_write+0x5a>
801062cd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801062d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801062d4:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801062db:	e8 de fc ff ff       	call   80105fbe <argint>
801062e0:	85 c0                	test   %eax,%eax
801062e2:	78 1e                	js     80106302 <sys_write+0x5a>
801062e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062e7:	89 44 24 08          	mov    %eax,0x8(%esp)
801062eb:	8d 45 ec             	lea    -0x14(%ebp),%eax
801062ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801062f2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801062f9:	e8 ee fc ff ff       	call   80105fec <argptr>
801062fe:	85 c0                	test   %eax,%eax
80106300:	79 07                	jns    80106309 <sys_write+0x61>
    return -1;
80106302:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106307:	eb 19                	jmp    80106322 <sys_write+0x7a>
  return filewrite(f, p, n);
80106309:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010630c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010630f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106312:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106316:	89 54 24 04          	mov    %edx,0x4(%esp)
8010631a:	89 04 24             	mov    %eax,(%esp)
8010631d:	e8 c9 b4 ff ff       	call   801017eb <filewrite>
}
80106322:	c9                   	leave  
80106323:	c3                   	ret    

80106324 <sys_close>:

int
sys_close(void)
{
80106324:	55                   	push   %ebp
80106325:	89 e5                	mov    %esp,%ebp
80106327:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010632a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010632d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106331:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106334:	89 44 24 04          	mov    %eax,0x4(%esp)
80106338:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010633f:	e8 d0 fd ff ff       	call   80106114 <argfd>
80106344:	85 c0                	test   %eax,%eax
80106346:	79 07                	jns    8010634f <sys_close+0x2b>
    return -1;
80106348:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010634d:	eb 24                	jmp    80106373 <sys_close+0x4f>
  proc->ofile[fd] = 0;
8010634f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106355:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106358:	83 c2 08             	add    $0x8,%edx
8010635b:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106362:	00 
  fileclose(f);
80106363:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106366:	89 04 24             	mov    %eax,(%esp)
80106369:	e8 9c b2 ff ff       	call   8010160a <fileclose>
  return 0;
8010636e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106373:	c9                   	leave  
80106374:	c3                   	ret    

80106375 <sys_fstat>:

int
sys_fstat(void)
{
80106375:	55                   	push   %ebp
80106376:	89 e5                	mov    %esp,%ebp
80106378:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010637b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010637e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106382:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106389:	00 
8010638a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106391:	e8 7e fd ff ff       	call   80106114 <argfd>
80106396:	85 c0                	test   %eax,%eax
80106398:	78 1f                	js     801063b9 <sys_fstat+0x44>
8010639a:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801063a1:	00 
801063a2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801063a9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801063b0:	e8 37 fc ff ff       	call   80105fec <argptr>
801063b5:	85 c0                	test   %eax,%eax
801063b7:	79 07                	jns    801063c0 <sys_fstat+0x4b>
    return -1;
801063b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063be:	eb 12                	jmp    801063d2 <sys_fstat+0x5d>
  return filestat(f, st);
801063c0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801063c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801063ca:	89 04 24             	mov    %eax,(%esp)
801063cd:	e8 0e b3 ff ff       	call   801016e0 <filestat>
}
801063d2:	c9                   	leave  
801063d3:	c3                   	ret    

801063d4 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801063d4:	55                   	push   %ebp
801063d5:	89 e5                	mov    %esp,%ebp
801063d7:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801063da:	8d 45 d8             	lea    -0x28(%ebp),%eax
801063dd:	89 44 24 04          	mov    %eax,0x4(%esp)
801063e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063e8:	e8 61 fc ff ff       	call   8010604e <argstr>
801063ed:	85 c0                	test   %eax,%eax
801063ef:	78 17                	js     80106408 <sys_link+0x34>
801063f1:	8d 45 dc             	lea    -0x24(%ebp),%eax
801063f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801063f8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801063ff:	e8 4a fc ff ff       	call   8010604e <argstr>
80106404:	85 c0                	test   %eax,%eax
80106406:	79 0a                	jns    80106412 <sys_link+0x3e>
    return -1;
80106408:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010640d:	e9 42 01 00 00       	jmp    80106554 <sys_link+0x180>

  begin_op();
80106412:	e8 c6 d6 ff ff       	call   80103add <begin_op>
  if((ip = namei(old)) == 0){
80106417:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010641a:	89 04 24             	mov    %eax,(%esp)
8010641d:	e8 84 c6 ff ff       	call   80102aa6 <namei>
80106422:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106425:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106429:	75 0f                	jne    8010643a <sys_link+0x66>
    end_op();
8010642b:	e8 31 d7 ff ff       	call   80103b61 <end_op>
    return -1;
80106430:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106435:	e9 1a 01 00 00       	jmp    80106554 <sys_link+0x180>
  }

  ilock(ip);
8010643a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010643d:	89 04 24             	mov    %eax,(%esp)
80106440:	e8 b0 ba ff ff       	call   80101ef5 <ilock>
  if(ip->type == T_DIR){
80106445:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106448:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010644c:	66 83 f8 01          	cmp    $0x1,%ax
80106450:	75 1a                	jne    8010646c <sys_link+0x98>
    iunlockput(ip);
80106452:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106455:	89 04 24             	mov    %eax,(%esp)
80106458:	e8 22 bd ff ff       	call   8010217f <iunlockput>
    end_op();
8010645d:	e8 ff d6 ff ff       	call   80103b61 <end_op>
    return -1;
80106462:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106467:	e9 e8 00 00 00       	jmp    80106554 <sys_link+0x180>
  }

  ip->nlink++;
8010646c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010646f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106473:	8d 50 01             	lea    0x1(%eax),%edx
80106476:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106479:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010647d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106480:	89 04 24             	mov    %eax,(%esp)
80106483:	e8 ab b8 ff ff       	call   80101d33 <iupdate>
  iunlock(ip);
80106488:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010648b:	89 04 24             	mov    %eax,(%esp)
8010648e:	e8 b6 bb ff ff       	call   80102049 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106493:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106496:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106499:	89 54 24 04          	mov    %edx,0x4(%esp)
8010649d:	89 04 24             	mov    %eax,(%esp)
801064a0:	e8 23 c6 ff ff       	call   80102ac8 <nameiparent>
801064a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801064a8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064ac:	75 02                	jne    801064b0 <sys_link+0xdc>
    goto bad;
801064ae:	eb 68                	jmp    80106518 <sys_link+0x144>
  ilock(dp);
801064b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064b3:	89 04 24             	mov    %eax,(%esp)
801064b6:	e8 3a ba ff ff       	call   80101ef5 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801064bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064be:	8b 10                	mov    (%eax),%edx
801064c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c3:	8b 00                	mov    (%eax),%eax
801064c5:	39 c2                	cmp    %eax,%edx
801064c7:	75 20                	jne    801064e9 <sys_link+0x115>
801064c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064cc:	8b 40 04             	mov    0x4(%eax),%eax
801064cf:	89 44 24 08          	mov    %eax,0x8(%esp)
801064d3:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801064d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801064da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064dd:	89 04 24             	mov    %eax,(%esp)
801064e0:	e8 01 c3 ff ff       	call   801027e6 <dirlink>
801064e5:	85 c0                	test   %eax,%eax
801064e7:	79 0d                	jns    801064f6 <sys_link+0x122>
    iunlockput(dp);
801064e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ec:	89 04 24             	mov    %eax,(%esp)
801064ef:	e8 8b bc ff ff       	call   8010217f <iunlockput>
    goto bad;
801064f4:	eb 22                	jmp    80106518 <sys_link+0x144>
  }
  iunlockput(dp);
801064f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064f9:	89 04 24             	mov    %eax,(%esp)
801064fc:	e8 7e bc ff ff       	call   8010217f <iunlockput>
  iput(ip);
80106501:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106504:	89 04 24             	mov    %eax,(%esp)
80106507:	e8 a2 bb ff ff       	call   801020ae <iput>

  end_op();
8010650c:	e8 50 d6 ff ff       	call   80103b61 <end_op>

  return 0;
80106511:	b8 00 00 00 00       	mov    $0x0,%eax
80106516:	eb 3c                	jmp    80106554 <sys_link+0x180>

bad:
  ilock(ip);
80106518:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010651b:	89 04 24             	mov    %eax,(%esp)
8010651e:	e8 d2 b9 ff ff       	call   80101ef5 <ilock>
  ip->nlink--;
80106523:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106526:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010652a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010652d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106530:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106534:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106537:	89 04 24             	mov    %eax,(%esp)
8010653a:	e8 f4 b7 ff ff       	call   80101d33 <iupdate>
  iunlockput(ip);
8010653f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106542:	89 04 24             	mov    %eax,(%esp)
80106545:	e8 35 bc ff ff       	call   8010217f <iunlockput>
  end_op();
8010654a:	e8 12 d6 ff ff       	call   80103b61 <end_op>
  return -1;
8010654f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106554:	c9                   	leave  
80106555:	c3                   	ret    

80106556 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106556:	55                   	push   %ebp
80106557:	89 e5                	mov    %esp,%ebp
80106559:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010655c:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106563:	eb 4b                	jmp    801065b0 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106565:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106568:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010656f:	00 
80106570:	89 44 24 08          	mov    %eax,0x8(%esp)
80106574:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106577:	89 44 24 04          	mov    %eax,0x4(%esp)
8010657b:	8b 45 08             	mov    0x8(%ebp),%eax
8010657e:	89 04 24             	mov    %eax,(%esp)
80106581:	e8 82 be ff ff       	call   80102408 <readi>
80106586:	83 f8 10             	cmp    $0x10,%eax
80106589:	74 0c                	je     80106597 <isdirempty+0x41>
      panic("isdirempty: readi");
8010658b:	c7 04 24 f7 94 10 80 	movl   $0x801094f7,(%esp)
80106592:	e8 a3 9f ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80106597:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010659b:	66 85 c0             	test   %ax,%ax
8010659e:	74 07                	je     801065a7 <isdirempty+0x51>
      return 0;
801065a0:	b8 00 00 00 00       	mov    $0x0,%eax
801065a5:	eb 1b                	jmp    801065c2 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801065a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065aa:	83 c0 10             	add    $0x10,%eax
801065ad:	89 45 f4             	mov    %eax,-0xc(%ebp)
801065b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065b3:	8b 45 08             	mov    0x8(%ebp),%eax
801065b6:	8b 40 18             	mov    0x18(%eax),%eax
801065b9:	39 c2                	cmp    %eax,%edx
801065bb:	72 a8                	jb     80106565 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801065bd:	b8 01 00 00 00       	mov    $0x1,%eax
}
801065c2:	c9                   	leave  
801065c3:	c3                   	ret    

801065c4 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801065c4:	55                   	push   %ebp
801065c5:	89 e5                	mov    %esp,%ebp
801065c7:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
801065ca:	8d 45 cc             	lea    -0x34(%ebp),%eax
801065cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801065d1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065d8:	e8 71 fa ff ff       	call   8010604e <argstr>
801065dd:	85 c0                	test   %eax,%eax
801065df:	79 0a                	jns    801065eb <sys_unlink+0x27>
    return -1;
801065e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065e6:	e9 af 01 00 00       	jmp    8010679a <sys_unlink+0x1d6>

  begin_op();
801065eb:	e8 ed d4 ff ff       	call   80103add <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801065f0:	8b 45 cc             	mov    -0x34(%ebp),%eax
801065f3:	8d 55 d2             	lea    -0x2e(%ebp),%edx
801065f6:	89 54 24 04          	mov    %edx,0x4(%esp)
801065fa:	89 04 24             	mov    %eax,(%esp)
801065fd:	e8 c6 c4 ff ff       	call   80102ac8 <nameiparent>
80106602:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106605:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106609:	75 0f                	jne    8010661a <sys_unlink+0x56>
    end_op();
8010660b:	e8 51 d5 ff ff       	call   80103b61 <end_op>
    return -1;
80106610:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106615:	e9 80 01 00 00       	jmp    8010679a <sys_unlink+0x1d6>
  }

  ilock(dp);
8010661a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010661d:	89 04 24             	mov    %eax,(%esp)
80106620:	e8 d0 b8 ff ff       	call   80101ef5 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106625:	c7 44 24 04 09 95 10 	movl   $0x80109509,0x4(%esp)
8010662c:	80 
8010662d:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106630:	89 04 24             	mov    %eax,(%esp)
80106633:	e8 c3 c0 ff ff       	call   801026fb <namecmp>
80106638:	85 c0                	test   %eax,%eax
8010663a:	0f 84 45 01 00 00    	je     80106785 <sys_unlink+0x1c1>
80106640:	c7 44 24 04 0b 95 10 	movl   $0x8010950b,0x4(%esp)
80106647:	80 
80106648:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010664b:	89 04 24             	mov    %eax,(%esp)
8010664e:	e8 a8 c0 ff ff       	call   801026fb <namecmp>
80106653:	85 c0                	test   %eax,%eax
80106655:	0f 84 2a 01 00 00    	je     80106785 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
8010665b:	8d 45 c8             	lea    -0x38(%ebp),%eax
8010665e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106662:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106665:	89 44 24 04          	mov    %eax,0x4(%esp)
80106669:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010666c:	89 04 24             	mov    %eax,(%esp)
8010666f:	e8 a9 c0 ff ff       	call   8010271d <dirlookup>
80106674:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106677:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010667b:	75 05                	jne    80106682 <sys_unlink+0xbe>
    goto bad;
8010667d:	e9 03 01 00 00       	jmp    80106785 <sys_unlink+0x1c1>
  ilock(ip);
80106682:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106685:	89 04 24             	mov    %eax,(%esp)
80106688:	e8 68 b8 ff ff       	call   80101ef5 <ilock>

  if(ip->nlink < 1)
8010668d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106690:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106694:	66 85 c0             	test   %ax,%ax
80106697:	7f 0c                	jg     801066a5 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80106699:	c7 04 24 0e 95 10 80 	movl   $0x8010950e,(%esp)
801066a0:	e8 95 9e ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801066a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066a8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801066ac:	66 83 f8 01          	cmp    $0x1,%ax
801066b0:	75 1f                	jne    801066d1 <sys_unlink+0x10d>
801066b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066b5:	89 04 24             	mov    %eax,(%esp)
801066b8:	e8 99 fe ff ff       	call   80106556 <isdirempty>
801066bd:	85 c0                	test   %eax,%eax
801066bf:	75 10                	jne    801066d1 <sys_unlink+0x10d>
    iunlockput(ip);
801066c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066c4:	89 04 24             	mov    %eax,(%esp)
801066c7:	e8 b3 ba ff ff       	call   8010217f <iunlockput>
    goto bad;
801066cc:	e9 b4 00 00 00       	jmp    80106785 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
801066d1:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801066d8:	00 
801066d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801066e0:	00 
801066e1:	8d 45 e0             	lea    -0x20(%ebp),%eax
801066e4:	89 04 24             	mov    %eax,(%esp)
801066e7:	e8 90 f5 ff ff       	call   80105c7c <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801066ec:	8b 45 c8             	mov    -0x38(%ebp),%eax
801066ef:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801066f6:	00 
801066f7:	89 44 24 08          	mov    %eax,0x8(%esp)
801066fb:	8d 45 e0             	lea    -0x20(%ebp),%eax
801066fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80106702:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106705:	89 04 24             	mov    %eax,(%esp)
80106708:	e8 5f be ff ff       	call   8010256c <writei>
8010670d:	83 f8 10             	cmp    $0x10,%eax
80106710:	74 0c                	je     8010671e <sys_unlink+0x15a>
    panic("unlink: writei");
80106712:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
80106719:	e8 1c 9e ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
8010671e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106721:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106725:	66 83 f8 01          	cmp    $0x1,%ax
80106729:	75 1c                	jne    80106747 <sys_unlink+0x183>
    dp->nlink--;
8010672b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010672e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106732:	8d 50 ff             	lea    -0x1(%eax),%edx
80106735:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106738:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010673c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010673f:	89 04 24             	mov    %eax,(%esp)
80106742:	e8 ec b5 ff ff       	call   80101d33 <iupdate>
  }
  iunlockput(dp);
80106747:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010674a:	89 04 24             	mov    %eax,(%esp)
8010674d:	e8 2d ba ff ff       	call   8010217f <iunlockput>

  ip->nlink--;
80106752:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106755:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106759:	8d 50 ff             	lea    -0x1(%eax),%edx
8010675c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010675f:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106763:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106766:	89 04 24             	mov    %eax,(%esp)
80106769:	e8 c5 b5 ff ff       	call   80101d33 <iupdate>
  iunlockput(ip);
8010676e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106771:	89 04 24             	mov    %eax,(%esp)
80106774:	e8 06 ba ff ff       	call   8010217f <iunlockput>

  end_op();
80106779:	e8 e3 d3 ff ff       	call   80103b61 <end_op>

  return 0;
8010677e:	b8 00 00 00 00       	mov    $0x0,%eax
80106783:	eb 15                	jmp    8010679a <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80106785:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106788:	89 04 24             	mov    %eax,(%esp)
8010678b:	e8 ef b9 ff ff       	call   8010217f <iunlockput>
  end_op();
80106790:	e8 cc d3 ff ff       	call   80103b61 <end_op>
  return -1;
80106795:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010679a:	c9                   	leave  
8010679b:	c3                   	ret    

8010679c <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
8010679c:	55                   	push   %ebp
8010679d:	89 e5                	mov    %esp,%ebp
8010679f:	83 ec 48             	sub    $0x48,%esp
801067a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801067a5:	8b 55 10             	mov    0x10(%ebp),%edx
801067a8:	8b 45 14             	mov    0x14(%ebp),%eax
801067ab:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801067af:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801067b3:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801067b7:	8d 45 de             	lea    -0x22(%ebp),%eax
801067ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801067be:	8b 45 08             	mov    0x8(%ebp),%eax
801067c1:	89 04 24             	mov    %eax,(%esp)
801067c4:	e8 ff c2 ff ff       	call   80102ac8 <nameiparent>
801067c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067cc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801067d0:	75 0a                	jne    801067dc <create+0x40>
    return 0;
801067d2:	b8 00 00 00 00       	mov    $0x0,%eax
801067d7:	e9 7e 01 00 00       	jmp    8010695a <create+0x1be>
  ilock(dp);
801067dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067df:	89 04 24             	mov    %eax,(%esp)
801067e2:	e8 0e b7 ff ff       	call   80101ef5 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801067e7:	8d 45 ec             	lea    -0x14(%ebp),%eax
801067ea:	89 44 24 08          	mov    %eax,0x8(%esp)
801067ee:	8d 45 de             	lea    -0x22(%ebp),%eax
801067f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801067f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067f8:	89 04 24             	mov    %eax,(%esp)
801067fb:	e8 1d bf ff ff       	call   8010271d <dirlookup>
80106800:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106803:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106807:	74 47                	je     80106850 <create+0xb4>
    iunlockput(dp);
80106809:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010680c:	89 04 24             	mov    %eax,(%esp)
8010680f:	e8 6b b9 ff ff       	call   8010217f <iunlockput>
    ilock(ip);
80106814:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106817:	89 04 24             	mov    %eax,(%esp)
8010681a:	e8 d6 b6 ff ff       	call   80101ef5 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010681f:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106824:	75 15                	jne    8010683b <create+0x9f>
80106826:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106829:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010682d:	66 83 f8 02          	cmp    $0x2,%ax
80106831:	75 08                	jne    8010683b <create+0x9f>
      return ip;
80106833:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106836:	e9 1f 01 00 00       	jmp    8010695a <create+0x1be>
    iunlockput(ip);
8010683b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010683e:	89 04 24             	mov    %eax,(%esp)
80106841:	e8 39 b9 ff ff       	call   8010217f <iunlockput>
    return 0;
80106846:	b8 00 00 00 00       	mov    $0x0,%eax
8010684b:	e9 0a 01 00 00       	jmp    8010695a <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106850:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106857:	8b 00                	mov    (%eax),%eax
80106859:	89 54 24 04          	mov    %edx,0x4(%esp)
8010685d:	89 04 24             	mov    %eax,(%esp)
80106860:	e8 f9 b3 ff ff       	call   80101c5e <ialloc>
80106865:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106868:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010686c:	75 0c                	jne    8010687a <create+0xde>
    panic("create: ialloc");
8010686e:	c7 04 24 2f 95 10 80 	movl   $0x8010952f,(%esp)
80106875:	e8 c0 9c ff ff       	call   8010053a <panic>

  ilock(ip);
8010687a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010687d:	89 04 24             	mov    %eax,(%esp)
80106880:	e8 70 b6 ff ff       	call   80101ef5 <ilock>
  ip->major = major;
80106885:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106888:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
8010688c:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106890:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106893:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106897:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
8010689b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010689e:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801068a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068a7:	89 04 24             	mov    %eax,(%esp)
801068aa:	e8 84 b4 ff ff       	call   80101d33 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
801068af:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
801068b4:	75 6a                	jne    80106920 <create+0x184>
    dp->nlink++;  // for ".."
801068b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068b9:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801068bd:	8d 50 01             	lea    0x1(%eax),%edx
801068c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068c3:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801068c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ca:	89 04 24             	mov    %eax,(%esp)
801068cd:	e8 61 b4 ff ff       	call   80101d33 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801068d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068d5:	8b 40 04             	mov    0x4(%eax),%eax
801068d8:	89 44 24 08          	mov    %eax,0x8(%esp)
801068dc:	c7 44 24 04 09 95 10 	movl   $0x80109509,0x4(%esp)
801068e3:	80 
801068e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068e7:	89 04 24             	mov    %eax,(%esp)
801068ea:	e8 f7 be ff ff       	call   801027e6 <dirlink>
801068ef:	85 c0                	test   %eax,%eax
801068f1:	78 21                	js     80106914 <create+0x178>
801068f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f6:	8b 40 04             	mov    0x4(%eax),%eax
801068f9:	89 44 24 08          	mov    %eax,0x8(%esp)
801068fd:	c7 44 24 04 0b 95 10 	movl   $0x8010950b,0x4(%esp)
80106904:	80 
80106905:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106908:	89 04 24             	mov    %eax,(%esp)
8010690b:	e8 d6 be ff ff       	call   801027e6 <dirlink>
80106910:	85 c0                	test   %eax,%eax
80106912:	79 0c                	jns    80106920 <create+0x184>
      panic("create dots");
80106914:	c7 04 24 3e 95 10 80 	movl   $0x8010953e,(%esp)
8010691b:	e8 1a 9c ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106920:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106923:	8b 40 04             	mov    0x4(%eax),%eax
80106926:	89 44 24 08          	mov    %eax,0x8(%esp)
8010692a:	8d 45 de             	lea    -0x22(%ebp),%eax
8010692d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106931:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106934:	89 04 24             	mov    %eax,(%esp)
80106937:	e8 aa be ff ff       	call   801027e6 <dirlink>
8010693c:	85 c0                	test   %eax,%eax
8010693e:	79 0c                	jns    8010694c <create+0x1b0>
    panic("create: dirlink");
80106940:	c7 04 24 4a 95 10 80 	movl   $0x8010954a,(%esp)
80106947:	e8 ee 9b ff ff       	call   8010053a <panic>

  iunlockput(dp);
8010694c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010694f:	89 04 24             	mov    %eax,(%esp)
80106952:	e8 28 b8 ff ff       	call   8010217f <iunlockput>

  return ip;
80106957:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010695a:	c9                   	leave  
8010695b:	c3                   	ret    

8010695c <sys_open>:

int
sys_open(void)
{
8010695c:	55                   	push   %ebp
8010695d:	89 e5                	mov    %esp,%ebp
8010695f:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106962:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106965:	89 44 24 04          	mov    %eax,0x4(%esp)
80106969:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106970:	e8 d9 f6 ff ff       	call   8010604e <argstr>
80106975:	85 c0                	test   %eax,%eax
80106977:	78 17                	js     80106990 <sys_open+0x34>
80106979:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010697c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106980:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106987:	e8 32 f6 ff ff       	call   80105fbe <argint>
8010698c:	85 c0                	test   %eax,%eax
8010698e:	79 0a                	jns    8010699a <sys_open+0x3e>
    return -1;
80106990:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106995:	e9 5c 01 00 00       	jmp    80106af6 <sys_open+0x19a>

  begin_op();
8010699a:	e8 3e d1 ff ff       	call   80103add <begin_op>

  if(omode & O_CREATE){
8010699f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801069a2:	25 00 02 00 00       	and    $0x200,%eax
801069a7:	85 c0                	test   %eax,%eax
801069a9:	74 3b                	je     801069e6 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
801069ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
801069ae:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801069b5:	00 
801069b6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801069bd:	00 
801069be:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801069c5:	00 
801069c6:	89 04 24             	mov    %eax,(%esp)
801069c9:	e8 ce fd ff ff       	call   8010679c <create>
801069ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
801069d1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069d5:	75 6b                	jne    80106a42 <sys_open+0xe6>
      end_op();
801069d7:	e8 85 d1 ff ff       	call   80103b61 <end_op>
      return -1;
801069dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069e1:	e9 10 01 00 00       	jmp    80106af6 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
801069e6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801069e9:	89 04 24             	mov    %eax,(%esp)
801069ec:	e8 b5 c0 ff ff       	call   80102aa6 <namei>
801069f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069f8:	75 0f                	jne    80106a09 <sys_open+0xad>
      end_op();
801069fa:	e8 62 d1 ff ff       	call   80103b61 <end_op>
      return -1;
801069ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a04:	e9 ed 00 00 00       	jmp    80106af6 <sys_open+0x19a>
    }
    ilock(ip);
80106a09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a0c:	89 04 24             	mov    %eax,(%esp)
80106a0f:	e8 e1 b4 ff ff       	call   80101ef5 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106a14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a17:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a1b:	66 83 f8 01          	cmp    $0x1,%ax
80106a1f:	75 21                	jne    80106a42 <sys_open+0xe6>
80106a21:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106a24:	85 c0                	test   %eax,%eax
80106a26:	74 1a                	je     80106a42 <sys_open+0xe6>
      iunlockput(ip);
80106a28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a2b:	89 04 24             	mov    %eax,(%esp)
80106a2e:	e8 4c b7 ff ff       	call   8010217f <iunlockput>
      end_op();
80106a33:	e8 29 d1 ff ff       	call   80103b61 <end_op>
      return -1;
80106a38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a3d:	e9 b4 00 00 00       	jmp    80106af6 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106a42:	e8 1b ab ff ff       	call   80101562 <filealloc>
80106a47:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a4a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a4e:	74 14                	je     80106a64 <sys_open+0x108>
80106a50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a53:	89 04 24             	mov    %eax,(%esp)
80106a56:	e8 2e f7 ff ff       	call   80106189 <fdalloc>
80106a5b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106a5e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106a62:	79 28                	jns    80106a8c <sys_open+0x130>
    if(f)
80106a64:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a68:	74 0b                	je     80106a75 <sys_open+0x119>
      fileclose(f);
80106a6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a6d:	89 04 24             	mov    %eax,(%esp)
80106a70:	e8 95 ab ff ff       	call   8010160a <fileclose>
    iunlockput(ip);
80106a75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a78:	89 04 24             	mov    %eax,(%esp)
80106a7b:	e8 ff b6 ff ff       	call   8010217f <iunlockput>
    end_op();
80106a80:	e8 dc d0 ff ff       	call   80103b61 <end_op>
    return -1;
80106a85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a8a:	eb 6a                	jmp    80106af6 <sys_open+0x19a>
  }
  iunlock(ip);
80106a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a8f:	89 04 24             	mov    %eax,(%esp)
80106a92:	e8 b2 b5 ff ff       	call   80102049 <iunlock>
  end_op();
80106a97:	e8 c5 d0 ff ff       	call   80103b61 <end_op>

  f->type = FD_INODE;
80106a9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a9f:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106aa5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aa8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106aab:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106aae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ab1:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106ab8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106abb:	83 e0 01             	and    $0x1,%eax
80106abe:	85 c0                	test   %eax,%eax
80106ac0:	0f 94 c0             	sete   %al
80106ac3:	89 c2                	mov    %eax,%edx
80106ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ac8:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106acb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ace:	83 e0 01             	and    $0x1,%eax
80106ad1:	85 c0                	test   %eax,%eax
80106ad3:	75 0a                	jne    80106adf <sys_open+0x183>
80106ad5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ad8:	83 e0 02             	and    $0x2,%eax
80106adb:	85 c0                	test   %eax,%eax
80106add:	74 07                	je     80106ae6 <sys_open+0x18a>
80106adf:	b8 01 00 00 00       	mov    $0x1,%eax
80106ae4:	eb 05                	jmp    80106aeb <sys_open+0x18f>
80106ae6:	b8 00 00 00 00       	mov    $0x0,%eax
80106aeb:	89 c2                	mov    %eax,%edx
80106aed:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106af0:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106af3:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106af6:	c9                   	leave  
80106af7:	c3                   	ret    

80106af8 <sys_mkdir>:

int
sys_mkdir(void)
{
80106af8:	55                   	push   %ebp
80106af9:	89 e5                	mov    %esp,%ebp
80106afb:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106afe:	e8 da cf ff ff       	call   80103add <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106b03:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106b06:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b0a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b11:	e8 38 f5 ff ff       	call   8010604e <argstr>
80106b16:	85 c0                	test   %eax,%eax
80106b18:	78 2c                	js     80106b46 <sys_mkdir+0x4e>
80106b1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b1d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106b24:	00 
80106b25:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106b2c:	00 
80106b2d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106b34:	00 
80106b35:	89 04 24             	mov    %eax,(%esp)
80106b38:	e8 5f fc ff ff       	call   8010679c <create>
80106b3d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b40:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b44:	75 0c                	jne    80106b52 <sys_mkdir+0x5a>
    end_op();
80106b46:	e8 16 d0 ff ff       	call   80103b61 <end_op>
    return -1;
80106b4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b50:	eb 15                	jmp    80106b67 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106b52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b55:	89 04 24             	mov    %eax,(%esp)
80106b58:	e8 22 b6 ff ff       	call   8010217f <iunlockput>
  end_op();
80106b5d:	e8 ff cf ff ff       	call   80103b61 <end_op>
  return 0;
80106b62:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106b67:	c9                   	leave  
80106b68:	c3                   	ret    

80106b69 <sys_mknod>:

int
sys_mknod(void)
{
80106b69:	55                   	push   %ebp
80106b6a:	89 e5                	mov    %esp,%ebp
80106b6c:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106b6f:	e8 69 cf ff ff       	call   80103add <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80106b74:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b77:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b7b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b82:	e8 c7 f4 ff ff       	call   8010604e <argstr>
80106b87:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b8a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b8e:	78 5e                	js     80106bee <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106b90:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b93:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b97:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106b9e:	e8 1b f4 ff ff       	call   80105fbe <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106ba3:	85 c0                	test   %eax,%eax
80106ba5:	78 47                	js     80106bee <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106ba7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106baa:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bae:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106bb5:	e8 04 f4 ff ff       	call   80105fbe <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106bba:	85 c0                	test   %eax,%eax
80106bbc:	78 30                	js     80106bee <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106bbe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bc1:	0f bf c8             	movswl %ax,%ecx
80106bc4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106bc7:	0f bf d0             	movswl %ax,%edx
80106bca:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106bcd:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106bd1:	89 54 24 08          	mov    %edx,0x8(%esp)
80106bd5:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106bdc:	00 
80106bdd:	89 04 24             	mov    %eax,(%esp)
80106be0:	e8 b7 fb ff ff       	call   8010679c <create>
80106be5:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106be8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bec:	75 0c                	jne    80106bfa <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106bee:	e8 6e cf ff ff       	call   80103b61 <end_op>
    return -1;
80106bf3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bf8:	eb 15                	jmp    80106c0f <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106bfa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bfd:	89 04 24             	mov    %eax,(%esp)
80106c00:	e8 7a b5 ff ff       	call   8010217f <iunlockput>
  end_op();
80106c05:	e8 57 cf ff ff       	call   80103b61 <end_op>
  return 0;
80106c0a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c0f:	c9                   	leave  
80106c10:	c3                   	ret    

80106c11 <sys_chdir>:

int
sys_chdir(void)
{
80106c11:	55                   	push   %ebp
80106c12:	89 e5                	mov    %esp,%ebp
80106c14:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106c17:	e8 c1 ce ff ff       	call   80103add <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106c1c:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c1f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c23:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c2a:	e8 1f f4 ff ff       	call   8010604e <argstr>
80106c2f:	85 c0                	test   %eax,%eax
80106c31:	78 14                	js     80106c47 <sys_chdir+0x36>
80106c33:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c36:	89 04 24             	mov    %eax,(%esp)
80106c39:	e8 68 be ff ff       	call   80102aa6 <namei>
80106c3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106c41:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c45:	75 0c                	jne    80106c53 <sys_chdir+0x42>
    end_op();
80106c47:	e8 15 cf ff ff       	call   80103b61 <end_op>
    return -1;
80106c4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c51:	eb 61                	jmp    80106cb4 <sys_chdir+0xa3>
  }
  ilock(ip);
80106c53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c56:	89 04 24             	mov    %eax,(%esp)
80106c59:	e8 97 b2 ff ff       	call   80101ef5 <ilock>
  if(ip->type != T_DIR){
80106c5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c61:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106c65:	66 83 f8 01          	cmp    $0x1,%ax
80106c69:	74 17                	je     80106c82 <sys_chdir+0x71>
    iunlockput(ip);
80106c6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c6e:	89 04 24             	mov    %eax,(%esp)
80106c71:	e8 09 b5 ff ff       	call   8010217f <iunlockput>
    end_op();
80106c76:	e8 e6 ce ff ff       	call   80103b61 <end_op>
    return -1;
80106c7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c80:	eb 32                	jmp    80106cb4 <sys_chdir+0xa3>
  }
  iunlock(ip);
80106c82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c85:	89 04 24             	mov    %eax,(%esp)
80106c88:	e8 bc b3 ff ff       	call   80102049 <iunlock>
  iput(proc->cwd);
80106c8d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c93:	8b 40 68             	mov    0x68(%eax),%eax
80106c96:	89 04 24             	mov    %eax,(%esp)
80106c99:	e8 10 b4 ff ff       	call   801020ae <iput>
  end_op();
80106c9e:	e8 be ce ff ff       	call   80103b61 <end_op>
  proc->cwd = ip;
80106ca3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ca9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106cac:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106caf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106cb4:	c9                   	leave  
80106cb5:	c3                   	ret    

80106cb6 <sys_exec>:

int
sys_exec(void)
{
80106cb6:	55                   	push   %ebp
80106cb7:	89 e5                	mov    %esp,%ebp
80106cb9:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106cbf:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106cc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cc6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ccd:	e8 7c f3 ff ff       	call   8010604e <argstr>
80106cd2:	85 c0                	test   %eax,%eax
80106cd4:	78 1a                	js     80106cf0 <sys_exec+0x3a>
80106cd6:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106cdc:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ce0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106ce7:	e8 d2 f2 ff ff       	call   80105fbe <argint>
80106cec:	85 c0                	test   %eax,%eax
80106cee:	79 0a                	jns    80106cfa <sys_exec+0x44>
    return -1;
80106cf0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cf5:	e9 d8 00 00 00       	jmp    80106dd2 <sys_exec+0x11c>
  }
  memset(argv, 0, sizeof(argv));
80106cfa:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106d01:	00 
80106d02:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106d09:	00 
80106d0a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106d10:	89 04 24             	mov    %eax,(%esp)
80106d13:	e8 64 ef ff ff       	call   80105c7c <memset>
  for(i=0;; i++){
80106d18:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d22:	83 f8 1f             	cmp    $0x1f,%eax
80106d25:	76 0a                	jbe    80106d31 <sys_exec+0x7b>
      return -1;
80106d27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d2c:	e9 a1 00 00 00       	jmp    80106dd2 <sys_exec+0x11c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106d31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d34:	c1 e0 02             	shl    $0x2,%eax
80106d37:	89 c2                	mov    %eax,%edx
80106d39:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106d3f:	01 c2                	add    %eax,%edx
80106d41:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106d47:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d4b:	89 14 24             	mov    %edx,(%esp)
80106d4e:	e8 cf f1 ff ff       	call   80105f22 <fetchint>
80106d53:	85 c0                	test   %eax,%eax
80106d55:	79 07                	jns    80106d5e <sys_exec+0xa8>
      return -1;
80106d57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d5c:	eb 74                	jmp    80106dd2 <sys_exec+0x11c>
    if(uarg == 0){
80106d5e:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106d64:	85 c0                	test   %eax,%eax
80106d66:	75 36                	jne    80106d9e <sys_exec+0xe8>
      argv[i] = 0;
80106d68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d6b:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106d72:	00 00 00 00 
      break;
80106d76:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
#ifdef DML
proc->priority = MED_PRIO;
80106d77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d7d:	c7 80 8c 00 00 00 02 	movl   $0x2,0x8c(%eax)
80106d84:	00 00 00 
#endif
  return exec(path, argv);
80106d87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d8a:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106d90:	89 54 24 04          	mov    %edx,0x4(%esp)
80106d94:	89 04 24             	mov    %eax,(%esp)
80106d97:	e8 8f a3 ff ff       	call   8010112b <exec>
80106d9c:	eb 34                	jmp    80106dd2 <sys_exec+0x11c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106d9e:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106da4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106da7:	c1 e2 02             	shl    $0x2,%edx
80106daa:	01 c2                	add    %eax,%edx
80106dac:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106db2:	89 54 24 04          	mov    %edx,0x4(%esp)
80106db6:	89 04 24             	mov    %eax,(%esp)
80106db9:	e8 9e f1 ff ff       	call   80105f5c <fetchstr>
80106dbe:	85 c0                	test   %eax,%eax
80106dc0:	79 07                	jns    80106dc9 <sys_exec+0x113>
      return -1;
80106dc2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106dc7:	eb 09                	jmp    80106dd2 <sys_exec+0x11c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106dc9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106dcd:	e9 4d ff ff ff       	jmp    80106d1f <sys_exec+0x69>
#ifdef DML
proc->priority = MED_PRIO;
#endif
  return exec(path, argv);
}
80106dd2:	c9                   	leave  
80106dd3:	c3                   	ret    

80106dd4 <sys_pipe>:

int
sys_pipe(void)
{
80106dd4:	55                   	push   %ebp
80106dd5:	89 e5                	mov    %esp,%ebp
80106dd7:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106dda:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106de1:	00 
80106de2:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106de5:	89 44 24 04          	mov    %eax,0x4(%esp)
80106de9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106df0:	e8 f7 f1 ff ff       	call   80105fec <argptr>
80106df5:	85 c0                	test   %eax,%eax
80106df7:	79 0a                	jns    80106e03 <sys_pipe+0x2f>
    return -1;
80106df9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106dfe:	e9 9b 00 00 00       	jmp    80106e9e <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106e03:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106e06:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e0a:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106e0d:	89 04 24             	mov    %eax,(%esp)
80106e10:	e8 d4 d7 ff ff       	call   801045e9 <pipealloc>
80106e15:	85 c0                	test   %eax,%eax
80106e17:	79 07                	jns    80106e20 <sys_pipe+0x4c>
    return -1;
80106e19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e1e:	eb 7e                	jmp    80106e9e <sys_pipe+0xca>
  fd0 = -1;
80106e20:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106e27:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106e2a:	89 04 24             	mov    %eax,(%esp)
80106e2d:	e8 57 f3 ff ff       	call   80106189 <fdalloc>
80106e32:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106e35:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e39:	78 14                	js     80106e4f <sys_pipe+0x7b>
80106e3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106e3e:	89 04 24             	mov    %eax,(%esp)
80106e41:	e8 43 f3 ff ff       	call   80106189 <fdalloc>
80106e46:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106e49:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106e4d:	79 37                	jns    80106e86 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106e4f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e53:	78 14                	js     80106e69 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106e55:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e5b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e5e:	83 c2 08             	add    $0x8,%edx
80106e61:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106e68:	00 
    fileclose(rf);
80106e69:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106e6c:	89 04 24             	mov    %eax,(%esp)
80106e6f:	e8 96 a7 ff ff       	call   8010160a <fileclose>
    fileclose(wf);
80106e74:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106e77:	89 04 24             	mov    %eax,(%esp)
80106e7a:	e8 8b a7 ff ff       	call   8010160a <fileclose>
    return -1;
80106e7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e84:	eb 18                	jmp    80106e9e <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106e86:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106e89:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e8c:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106e8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106e91:	8d 50 04             	lea    0x4(%eax),%edx
80106e94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e97:	89 02                	mov    %eax,(%edx)
  return 0;
80106e99:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106e9e:	c9                   	leave  
80106e9f:	c3                   	ret    

80106ea0 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106ea0:	55                   	push   %ebp
80106ea1:	89 e5                	mov    %esp,%ebp
80106ea3:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106ea6:	e8 cf e0 ff ff       	call   80104f7a <fork>
}
80106eab:	c9                   	leave  
80106eac:	c3                   	ret    

80106ead <sys_exit>:

int
sys_exit(void)
{
80106ead:	55                   	push   %ebp
80106eae:	89 e5                	mov    %esp,%ebp
80106eb0:	83 ec 08             	sub    $0x8,%esp
  exit();
80106eb3:	e8 9e e2 ff ff       	call   80105156 <exit>
  return 0;  // not reached
80106eb8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106ebd:	c9                   	leave  
80106ebe:	c3                   	ret    

80106ebf <sys_wait>:

int
sys_wait(void)
{
80106ebf:	55                   	push   %ebp
80106ec0:	89 e5                	mov    %esp,%ebp
80106ec2:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106ec5:	e8 b1 e3 ff ff       	call   8010527b <wait>
}
80106eca:	c9                   	leave  
80106ecb:	c3                   	ret    

80106ecc <sys_wait2>:

int
sys_wait2(void)
{
80106ecc:	55                   	push   %ebp
80106ecd:	89 e5                	mov    %esp,%ebp
80106ecf:	83 ec 08             	sub    $0x8,%esp
  return wait2();
80106ed2:	e8 b6 e4 ff ff       	call   8010538d <wait2>
}
80106ed7:	c9                   	leave  
80106ed8:	c3                   	ret    

80106ed9 <sys_kill>:

int
sys_kill(void)
{
80106ed9:	55                   	push   %ebp
80106eda:	89 e5                	mov    %esp,%ebp
80106edc:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106edf:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106ee2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ee6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106eed:	e8 cc f0 ff ff       	call   80105fbe <argint>
80106ef2:	85 c0                	test   %eax,%eax
80106ef4:	79 07                	jns    80106efd <sys_kill+0x24>
    return -1;
80106ef6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106efb:	eb 0b                	jmp    80106f08 <sys_kill+0x2f>
  return kill(pid);
80106efd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f00:	89 04 24             	mov    %eax,(%esp)
80106f03:	e8 49 e9 ff ff       	call   80105851 <kill>
}
80106f08:	c9                   	leave  
80106f09:	c3                   	ret    

80106f0a <sys_getpid>:

int
sys_getpid(void)
{
80106f0a:	55                   	push   %ebp
80106f0b:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106f0d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106f13:	8b 40 10             	mov    0x10(%eax),%eax
}
80106f16:	5d                   	pop    %ebp
80106f17:	c3                   	ret    

80106f18 <sys_sbrk>:

int
sys_sbrk(void)
{
80106f18:	55                   	push   %ebp
80106f19:	89 e5                	mov    %esp,%ebp
80106f1b:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106f1e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106f21:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f25:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f2c:	e8 8d f0 ff ff       	call   80105fbe <argint>
80106f31:	85 c0                	test   %eax,%eax
80106f33:	79 07                	jns    80106f3c <sys_sbrk+0x24>
    return -1;
80106f35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f3a:	eb 24                	jmp    80106f60 <sys_sbrk+0x48>
  addr = proc->sz;
80106f3c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106f42:	8b 00                	mov    (%eax),%eax
80106f44:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106f47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f4a:	89 04 24             	mov    %eax,(%esp)
80106f4d:	e8 1e df ff ff       	call   80104e70 <growproc>
80106f52:	85 c0                	test   %eax,%eax
80106f54:	79 07                	jns    80106f5d <sys_sbrk+0x45>
    return -1;
80106f56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f5b:	eb 03                	jmp    80106f60 <sys_sbrk+0x48>
  return addr;
80106f5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106f60:	c9                   	leave  
80106f61:	c3                   	ret    

80106f62 <sys_sleep>:

int
sys_sleep(void)
{
80106f62:	55                   	push   %ebp
80106f63:	89 e5                	mov    %esp,%ebp
80106f65:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106f68:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106f6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f6f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f76:	e8 43 f0 ff ff       	call   80105fbe <argint>
80106f7b:	85 c0                	test   %eax,%eax
80106f7d:	79 07                	jns    80106f86 <sys_sleep+0x24>
    return -1;
80106f7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f84:	eb 6c                	jmp    80106ff2 <sys_sleep+0x90>
  acquire(&tickslock);
80106f86:	c7 04 24 60 6a 11 80 	movl   $0x80116a60,(%esp)
80106f8d:	e8 96 ea ff ff       	call   80105a28 <acquire>
  ticks0 = ticks;
80106f92:	a1 a0 72 11 80       	mov    0x801172a0,%eax
80106f97:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106f9a:	eb 34                	jmp    80106fd0 <sys_sleep+0x6e>
    if(proc->killed){
80106f9c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106fa2:	8b 40 24             	mov    0x24(%eax),%eax
80106fa5:	85 c0                	test   %eax,%eax
80106fa7:	74 13                	je     80106fbc <sys_sleep+0x5a>
      release(&tickslock);
80106fa9:	c7 04 24 60 6a 11 80 	movl   $0x80116a60,(%esp)
80106fb0:	e8 d5 ea ff ff       	call   80105a8a <release>
      return -1;
80106fb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fba:	eb 36                	jmp    80106ff2 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106fbc:	c7 44 24 04 60 6a 11 	movl   $0x80116a60,0x4(%esp)
80106fc3:	80 
80106fc4:	c7 04 24 a0 72 11 80 	movl   $0x801172a0,(%esp)
80106fcb:	e8 62 e7 ff ff       	call   80105732 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106fd0:	a1 a0 72 11 80       	mov    0x801172a0,%eax
80106fd5:	2b 45 f4             	sub    -0xc(%ebp),%eax
80106fd8:	89 c2                	mov    %eax,%edx
80106fda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fdd:	39 c2                	cmp    %eax,%edx
80106fdf:	72 bb                	jb     80106f9c <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106fe1:	c7 04 24 60 6a 11 80 	movl   $0x80116a60,(%esp)
80106fe8:	e8 9d ea ff ff       	call   80105a8a <release>
  return 0;
80106fed:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106ff2:	c9                   	leave  
80106ff3:	c3                   	ret    

80106ff4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106ff4:	55                   	push   %ebp
80106ff5:	89 e5                	mov    %esp,%ebp
80106ff7:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106ffa:	c7 04 24 60 6a 11 80 	movl   $0x80116a60,(%esp)
80107001:	e8 22 ea ff ff       	call   80105a28 <acquire>
  xticks = ticks;
80107006:	a1 a0 72 11 80       	mov    0x801172a0,%eax
8010700b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
8010700e:	c7 04 24 60 6a 11 80 	movl   $0x80116a60,(%esp)
80107015:	e8 70 ea ff ff       	call   80105a8a <release>
  return xticks;
8010701a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010701d:	c9                   	leave  
8010701e:	c3                   	ret    

8010701f <sys_set_prio>:

// Sets the priority of the process to the given priority
int
sys_set_prio(void)
{
8010701f:	55                   	push   %ebp
80107020:	89 e5                	mov    %esp,%ebp
80107022:	83 ec 28             	sub    $0x28,%esp
  int prio;
  if(argint(0,&prio) < 0 || prio > 3 || prio < 1)
80107025:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107028:	89 44 24 04          	mov    %eax,0x4(%esp)
8010702c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107033:	e8 86 ef ff ff       	call   80105fbe <argint>
80107038:	85 c0                	test   %eax,%eax
8010703a:	78 0f                	js     8010704b <sys_set_prio+0x2c>
8010703c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010703f:	83 f8 03             	cmp    $0x3,%eax
80107042:	7f 07                	jg     8010704b <sys_set_prio+0x2c>
80107044:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107047:	85 c0                	test   %eax,%eax
80107049:	7f 07                	jg     80107052 <sys_set_prio+0x33>
    return -1;
8010704b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107050:	eb 14                	jmp    80107066 <sys_set_prio+0x47>
  proc->priority = prio;
80107052:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107058:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010705b:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
  return 0;
80107061:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107066:	c9                   	leave  
80107067:	c3                   	ret    

80107068 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107068:	55                   	push   %ebp
80107069:	89 e5                	mov    %esp,%ebp
8010706b:	83 ec 08             	sub    $0x8,%esp
8010706e:	8b 55 08             	mov    0x8(%ebp),%edx
80107071:	8b 45 0c             	mov    0xc(%ebp),%eax
80107074:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107078:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010707b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010707f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107083:	ee                   	out    %al,(%dx)
}
80107084:	c9                   	leave  
80107085:	c3                   	ret    

80107086 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80107086:	55                   	push   %ebp
80107087:	89 e5                	mov    %esp,%ebp
80107089:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
8010708c:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80107093:	00 
80107094:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010709b:	e8 c8 ff ff ff       	call   80107068 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801070a0:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801070a7:	00 
801070a8:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801070af:	e8 b4 ff ff ff       	call   80107068 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801070b4:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801070bb:	00 
801070bc:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801070c3:	e8 a0 ff ff ff       	call   80107068 <outb>
  picenable(IRQ_TIMER);
801070c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070cf:	e8 a8 d3 ff ff       	call   8010447c <picenable>
}
801070d4:	c9                   	leave  
801070d5:	c3                   	ret    

801070d6 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801070d6:	1e                   	push   %ds
  pushl %es
801070d7:	06                   	push   %es
  pushl %fs
801070d8:	0f a0                	push   %fs
  pushl %gs
801070da:	0f a8                	push   %gs
  pushal
801070dc:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801070dd:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801070e1:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801070e3:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801070e5:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801070e9:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801070eb:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801070ed:	54                   	push   %esp
  call trap
801070ee:	e8 d8 01 00 00       	call   801072cb <trap>
  addl $4, %esp
801070f3:	83 c4 04             	add    $0x4,%esp

801070f6 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801070f6:	61                   	popa   
  popl %gs
801070f7:	0f a9                	pop    %gs
  popl %fs
801070f9:	0f a1                	pop    %fs
  popl %es
801070fb:	07                   	pop    %es
  popl %ds
801070fc:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801070fd:	83 c4 08             	add    $0x8,%esp
  iret
80107100:	cf                   	iret   

80107101 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80107101:	55                   	push   %ebp
80107102:	89 e5                	mov    %esp,%ebp
80107104:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107107:	8b 45 0c             	mov    0xc(%ebp),%eax
8010710a:	83 e8 01             	sub    $0x1,%eax
8010710d:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107111:	8b 45 08             	mov    0x8(%ebp),%eax
80107114:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107118:	8b 45 08             	mov    0x8(%ebp),%eax
8010711b:	c1 e8 10             	shr    $0x10,%eax
8010711e:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80107122:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107125:	0f 01 18             	lidtl  (%eax)
}
80107128:	c9                   	leave  
80107129:	c3                   	ret    

8010712a <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
8010712a:	55                   	push   %ebp
8010712b:	89 e5                	mov    %esp,%ebp
8010712d:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80107130:	0f 20 d0             	mov    %cr2,%eax
80107133:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80107136:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80107139:	c9                   	leave  
8010713a:	c3                   	ret    

8010713b <tvinit>:
uint ticks;
void increment_process_times(void);

void
tvinit(void)
{
8010713b:	55                   	push   %ebp
8010713c:	89 e5                	mov    %esp,%ebp
8010713e:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80107141:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107148:	e9 c3 00 00 00       	jmp    80107210 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010714d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107150:	8b 04 85 a4 c0 10 80 	mov    -0x7fef3f5c(,%eax,4),%eax
80107157:	89 c2                	mov    %eax,%edx
80107159:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010715c:	66 89 14 c5 a0 6a 11 	mov    %dx,-0x7fee9560(,%eax,8)
80107163:	80 
80107164:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107167:	66 c7 04 c5 a2 6a 11 	movw   $0x8,-0x7fee955e(,%eax,8)
8010716e:	80 08 00 
80107171:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107174:	0f b6 14 c5 a4 6a 11 	movzbl -0x7fee955c(,%eax,8),%edx
8010717b:	80 
8010717c:	83 e2 e0             	and    $0xffffffe0,%edx
8010717f:	88 14 c5 a4 6a 11 80 	mov    %dl,-0x7fee955c(,%eax,8)
80107186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107189:	0f b6 14 c5 a4 6a 11 	movzbl -0x7fee955c(,%eax,8),%edx
80107190:	80 
80107191:	83 e2 1f             	and    $0x1f,%edx
80107194:	88 14 c5 a4 6a 11 80 	mov    %dl,-0x7fee955c(,%eax,8)
8010719b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010719e:	0f b6 14 c5 a5 6a 11 	movzbl -0x7fee955b(,%eax,8),%edx
801071a5:	80 
801071a6:	83 e2 f0             	and    $0xfffffff0,%edx
801071a9:	83 ca 0e             	or     $0xe,%edx
801071ac:	88 14 c5 a5 6a 11 80 	mov    %dl,-0x7fee955b(,%eax,8)
801071b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071b6:	0f b6 14 c5 a5 6a 11 	movzbl -0x7fee955b(,%eax,8),%edx
801071bd:	80 
801071be:	83 e2 ef             	and    $0xffffffef,%edx
801071c1:	88 14 c5 a5 6a 11 80 	mov    %dl,-0x7fee955b(,%eax,8)
801071c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071cb:	0f b6 14 c5 a5 6a 11 	movzbl -0x7fee955b(,%eax,8),%edx
801071d2:	80 
801071d3:	83 e2 9f             	and    $0xffffff9f,%edx
801071d6:	88 14 c5 a5 6a 11 80 	mov    %dl,-0x7fee955b(,%eax,8)
801071dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071e0:	0f b6 14 c5 a5 6a 11 	movzbl -0x7fee955b(,%eax,8),%edx
801071e7:	80 
801071e8:	83 ca 80             	or     $0xffffff80,%edx
801071eb:	88 14 c5 a5 6a 11 80 	mov    %dl,-0x7fee955b(,%eax,8)
801071f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071f5:	8b 04 85 a4 c0 10 80 	mov    -0x7fef3f5c(,%eax,4),%eax
801071fc:	c1 e8 10             	shr    $0x10,%eax
801071ff:	89 c2                	mov    %eax,%edx
80107201:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107204:	66 89 14 c5 a6 6a 11 	mov    %dx,-0x7fee955a(,%eax,8)
8010720b:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
8010720c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107210:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80107217:	0f 8e 30 ff ff ff    	jle    8010714d <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010721d:	a1 a4 c1 10 80       	mov    0x8010c1a4,%eax
80107222:	66 a3 a0 6c 11 80    	mov    %ax,0x80116ca0
80107228:	66 c7 05 a2 6c 11 80 	movw   $0x8,0x80116ca2
8010722f:	08 00 
80107231:	0f b6 05 a4 6c 11 80 	movzbl 0x80116ca4,%eax
80107238:	83 e0 e0             	and    $0xffffffe0,%eax
8010723b:	a2 a4 6c 11 80       	mov    %al,0x80116ca4
80107240:	0f b6 05 a4 6c 11 80 	movzbl 0x80116ca4,%eax
80107247:	83 e0 1f             	and    $0x1f,%eax
8010724a:	a2 a4 6c 11 80       	mov    %al,0x80116ca4
8010724f:	0f b6 05 a5 6c 11 80 	movzbl 0x80116ca5,%eax
80107256:	83 c8 0f             	or     $0xf,%eax
80107259:	a2 a5 6c 11 80       	mov    %al,0x80116ca5
8010725e:	0f b6 05 a5 6c 11 80 	movzbl 0x80116ca5,%eax
80107265:	83 e0 ef             	and    $0xffffffef,%eax
80107268:	a2 a5 6c 11 80       	mov    %al,0x80116ca5
8010726d:	0f b6 05 a5 6c 11 80 	movzbl 0x80116ca5,%eax
80107274:	83 c8 60             	or     $0x60,%eax
80107277:	a2 a5 6c 11 80       	mov    %al,0x80116ca5
8010727c:	0f b6 05 a5 6c 11 80 	movzbl 0x80116ca5,%eax
80107283:	83 c8 80             	or     $0xffffff80,%eax
80107286:	a2 a5 6c 11 80       	mov    %al,0x80116ca5
8010728b:	a1 a4 c1 10 80       	mov    0x8010c1a4,%eax
80107290:	c1 e8 10             	shr    $0x10,%eax
80107293:	66 a3 a6 6c 11 80    	mov    %ax,0x80116ca6
  
  initlock(&tickslock, "time");
80107299:	c7 44 24 04 5c 95 10 	movl   $0x8010955c,0x4(%esp)
801072a0:	80 
801072a1:	c7 04 24 60 6a 11 80 	movl   $0x80116a60,(%esp)
801072a8:	e8 5a e7 ff ff       	call   80105a07 <initlock>
}
801072ad:	c9                   	leave  
801072ae:	c3                   	ret    

801072af <idtinit>:

void
idtinit(void)
{
801072af:	55                   	push   %ebp
801072b0:	89 e5                	mov    %esp,%ebp
801072b2:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801072b5:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801072bc:	00 
801072bd:	c7 04 24 a0 6a 11 80 	movl   $0x80116aa0,(%esp)
801072c4:	e8 38 fe ff ff       	call   80107101 <lidt>
}
801072c9:	c9                   	leave  
801072ca:	c3                   	ret    

801072cb <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801072cb:	55                   	push   %ebp
801072cc:	89 e5                	mov    %esp,%ebp
801072ce:	57                   	push   %edi
801072cf:	56                   	push   %esi
801072d0:	53                   	push   %ebx
801072d1:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
801072d4:	8b 45 08             	mov    0x8(%ebp),%eax
801072d7:	8b 40 30             	mov    0x30(%eax),%eax
801072da:	83 f8 40             	cmp    $0x40,%eax
801072dd:	75 3f                	jne    8010731e <trap+0x53>
    if(proc->killed)
801072df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072e5:	8b 40 24             	mov    0x24(%eax),%eax
801072e8:	85 c0                	test   %eax,%eax
801072ea:	74 05                	je     801072f1 <trap+0x26>
      exit();
801072ec:	e8 65 de ff ff       	call   80105156 <exit>
    proc->tf = tf;
801072f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072f7:	8b 55 08             	mov    0x8(%ebp),%edx
801072fa:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801072fd:	e8 83 ed ff ff       	call   80106085 <syscall>
    if(proc->killed)
80107302:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107308:	8b 40 24             	mov    0x24(%eax),%eax
8010730b:	85 c0                	test   %eax,%eax
8010730d:	74 0a                	je     80107319 <trap+0x4e>
      exit();
8010730f:	e8 42 de ff ff       	call   80105156 <exit>
    return;
80107314:	e9 63 02 00 00       	jmp    8010757c <trap+0x2b1>
80107319:	e9 5e 02 00 00       	jmp    8010757c <trap+0x2b1>
  }

  switch(tf->trapno){
8010731e:	8b 45 08             	mov    0x8(%ebp),%eax
80107321:	8b 40 30             	mov    0x30(%eax),%eax
80107324:	83 e8 20             	sub    $0x20,%eax
80107327:	83 f8 1f             	cmp    $0x1f,%eax
8010732a:	0f 87 c1 00 00 00    	ja     801073f1 <trap+0x126>
80107330:	8b 04 85 04 96 10 80 	mov    -0x7fef69fc(,%eax,4),%eax
80107337:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107339:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010733f:	0f b6 00             	movzbl (%eax),%eax
80107342:	84 c0                	test   %al,%al
80107344:	75 36                	jne    8010737c <trap+0xb1>
      acquire(&tickslock);
80107346:	c7 04 24 60 6a 11 80 	movl   $0x80116a60,(%esp)
8010734d:	e8 d6 e6 ff ff       	call   80105a28 <acquire>
      ticks++;
80107352:	a1 a0 72 11 80       	mov    0x801172a0,%eax
80107357:	83 c0 01             	add    $0x1,%eax
8010735a:	a3 a0 72 11 80       	mov    %eax,0x801172a0
      increment_process_times(); 
8010735f:	e8 29 e1 ff ff       	call   8010548d <increment_process_times>
      wakeup(&ticks);
80107364:	c7 04 24 a0 72 11 80 	movl   $0x801172a0,(%esp)
8010736b:	e8 b6 e4 ff ff       	call   80105826 <wakeup>
      release(&tickslock);
80107370:	c7 04 24 60 6a 11 80 	movl   $0x80116a60,(%esp)
80107377:	e8 0e e7 ff ff       	call   80105a8a <release>
    }
    lapiceoi();
8010737c:	e8 26 c2 ff ff       	call   801035a7 <lapiceoi>
    break;
80107381:	e9 41 01 00 00       	jmp    801074c7 <trap+0x1fc>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107386:	e8 2a ba ff ff       	call   80102db5 <ideintr>
    lapiceoi();
8010738b:	e8 17 c2 ff ff       	call   801035a7 <lapiceoi>
    break;
80107390:	e9 32 01 00 00       	jmp    801074c7 <trap+0x1fc>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107395:	e8 dc bf ff ff       	call   80103376 <kbdintr>
    lapiceoi();
8010739a:	e8 08 c2 ff ff       	call   801035a7 <lapiceoi>
    break;
8010739f:	e9 23 01 00 00       	jmp    801074c7 <trap+0x1fc>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801073a4:	e8 c8 03 00 00       	call   80107771 <uartintr>
    lapiceoi();
801073a9:	e8 f9 c1 ff ff       	call   801035a7 <lapiceoi>
    break;
801073ae:	e9 14 01 00 00       	jmp    801074c7 <trap+0x1fc>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801073b3:	8b 45 08             	mov    0x8(%ebp),%eax
801073b6:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801073b9:	8b 45 08             	mov    0x8(%ebp),%eax
801073bc:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801073c0:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801073c3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801073c9:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801073cc:	0f b6 c0             	movzbl %al,%eax
801073cf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801073d3:	89 54 24 08          	mov    %edx,0x8(%esp)
801073d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801073db:	c7 04 24 64 95 10 80 	movl   $0x80109564,(%esp)
801073e2:	e8 b9 8f ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801073e7:	e8 bb c1 ff ff       	call   801035a7 <lapiceoi>
    break;
801073ec:	e9 d6 00 00 00       	jmp    801074c7 <trap+0x1fc>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801073f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073f7:	85 c0                	test   %eax,%eax
801073f9:	74 11                	je     8010740c <trap+0x141>
801073fb:	8b 45 08             	mov    0x8(%ebp),%eax
801073fe:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107402:	0f b7 c0             	movzwl %ax,%eax
80107405:	83 e0 03             	and    $0x3,%eax
80107408:	85 c0                	test   %eax,%eax
8010740a:	75 46                	jne    80107452 <trap+0x187>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010740c:	e8 19 fd ff ff       	call   8010712a <rcr2>
80107411:	8b 55 08             	mov    0x8(%ebp),%edx
80107414:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107417:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010741e:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107421:	0f b6 ca             	movzbl %dl,%ecx
80107424:	8b 55 08             	mov    0x8(%ebp),%edx
80107427:	8b 52 30             	mov    0x30(%edx),%edx
8010742a:	89 44 24 10          	mov    %eax,0x10(%esp)
8010742e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107432:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107436:	89 54 24 04          	mov    %edx,0x4(%esp)
8010743a:	c7 04 24 88 95 10 80 	movl   $0x80109588,(%esp)
80107441:	e8 5a 8f ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107446:	c7 04 24 ba 95 10 80 	movl   $0x801095ba,(%esp)
8010744d:	e8 e8 90 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107452:	e8 d3 fc ff ff       	call   8010712a <rcr2>
80107457:	89 c2                	mov    %eax,%edx
80107459:	8b 45 08             	mov    0x8(%ebp),%eax
8010745c:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010745f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107465:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107468:	0f b6 f0             	movzbl %al,%esi
8010746b:	8b 45 08             	mov    0x8(%ebp),%eax
8010746e:	8b 58 34             	mov    0x34(%eax),%ebx
80107471:	8b 45 08             	mov    0x8(%ebp),%eax
80107474:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107477:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010747d:	83 c0 6c             	add    $0x6c,%eax
80107480:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107483:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107489:	8b 40 10             	mov    0x10(%eax),%eax
8010748c:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107490:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107494:	89 74 24 14          	mov    %esi,0x14(%esp)
80107498:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010749c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801074a0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
801074a3:	89 74 24 08          	mov    %esi,0x8(%esp)
801074a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801074ab:	c7 04 24 c0 95 10 80 	movl   $0x801095c0,(%esp)
801074b2:	e8 e9 8e ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801074b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074bd:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801074c4:	eb 01                	jmp    801074c7 <trap+0x1fc>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801074c6:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801074c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074cd:	85 c0                	test   %eax,%eax
801074cf:	74 24                	je     801074f5 <trap+0x22a>
801074d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074d7:	8b 40 24             	mov    0x24(%eax),%eax
801074da:	85 c0                	test   %eax,%eax
801074dc:	74 17                	je     801074f5 <trap+0x22a>
801074de:	8b 45 08             	mov    0x8(%ebp),%eax
801074e1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801074e5:	0f b7 c0             	movzwl %ax,%eax
801074e8:	83 e0 03             	and    $0x3,%eax
801074eb:	83 f8 03             	cmp    $0x3,%eax
801074ee:	75 05                	jne    801074f5 <trap+0x22a>
    exit();
801074f0:	e8 61 dc ff ff       	call   80105156 <exit>
 #ifndef FCFS 
  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  // We added the QUANTA condition for yielding over!
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER
801074f5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074fb:	85 c0                	test   %eax,%eax
801074fd:	74 4f                	je     8010754e <trap+0x283>
801074ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107505:	8b 40 0c             	mov    0xc(%eax),%eax
80107508:	83 f8 04             	cmp    $0x4,%eax
8010750b:	75 41                	jne    8010754e <trap+0x283>
8010750d:	8b 45 08             	mov    0x8(%ebp),%eax
80107510:	8b 40 30             	mov    0x30(%eax),%eax
80107513:	83 f8 20             	cmp    $0x20,%eax
80107516:	75 36                	jne    8010754e <trap+0x283>
      && (ticks % QUANTA) == 0) {
80107518:	8b 0d a0 72 11 80    	mov    0x801172a0,%ecx
8010751e:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
80107523:	89 c8                	mov    %ecx,%eax
80107525:	f7 e2                	mul    %edx
80107527:	c1 ea 02             	shr    $0x2,%edx
8010752a:	89 d0                	mov    %edx,%eax
8010752c:	c1 e0 02             	shl    $0x2,%eax
8010752f:	01 d0                	add    %edx,%eax
80107531:	29 c1                	sub    %eax,%ecx
80107533:	89 ca                	mov    %ecx,%edx
80107535:	85 d2                	test   %edx,%edx
80107537:	75 15                	jne    8010754e <trap+0x283>
    proc->dml_opts = FULL_QUANTA;
80107539:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010753f:	c7 80 90 00 00 00 01 	movl   $0x1,0x90(%eax)
80107546:	00 00 00 
    yield();
80107549:	e8 65 e1 ff ff       	call   801056b3 <yield>
  }
 #endif
  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010754e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107554:	85 c0                	test   %eax,%eax
80107556:	74 24                	je     8010757c <trap+0x2b1>
80107558:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010755e:	8b 40 24             	mov    0x24(%eax),%eax
80107561:	85 c0                	test   %eax,%eax
80107563:	74 17                	je     8010757c <trap+0x2b1>
80107565:	8b 45 08             	mov    0x8(%ebp),%eax
80107568:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010756c:	0f b7 c0             	movzwl %ax,%eax
8010756f:	83 e0 03             	and    $0x3,%eax
80107572:	83 f8 03             	cmp    $0x3,%eax
80107575:	75 05                	jne    8010757c <trap+0x2b1>
    exit();
80107577:	e8 da db ff ff       	call   80105156 <exit>
}
8010757c:	83 c4 3c             	add    $0x3c,%esp
8010757f:	5b                   	pop    %ebx
80107580:	5e                   	pop    %esi
80107581:	5f                   	pop    %edi
80107582:	5d                   	pop    %ebp
80107583:	c3                   	ret    

80107584 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107584:	55                   	push   %ebp
80107585:	89 e5                	mov    %esp,%ebp
80107587:	83 ec 14             	sub    $0x14,%esp
8010758a:	8b 45 08             	mov    0x8(%ebp),%eax
8010758d:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107591:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80107595:	89 c2                	mov    %eax,%edx
80107597:	ec                   	in     (%dx),%al
80107598:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010759b:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010759f:	c9                   	leave  
801075a0:	c3                   	ret    

801075a1 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801075a1:	55                   	push   %ebp
801075a2:	89 e5                	mov    %esp,%ebp
801075a4:	83 ec 08             	sub    $0x8,%esp
801075a7:	8b 55 08             	mov    0x8(%ebp),%edx
801075aa:	8b 45 0c             	mov    0xc(%ebp),%eax
801075ad:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801075b1:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801075b4:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801075b8:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801075bc:	ee                   	out    %al,(%dx)
}
801075bd:	c9                   	leave  
801075be:	c3                   	ret    

801075bf <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801075bf:	55                   	push   %ebp
801075c0:	89 e5                	mov    %esp,%ebp
801075c2:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801075c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801075cc:	00 
801075cd:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801075d4:	e8 c8 ff ff ff       	call   801075a1 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801075d9:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
801075e0:	00 
801075e1:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801075e8:	e8 b4 ff ff ff       	call   801075a1 <outb>
  outb(COM1+0, 115200/9600);
801075ed:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
801075f4:	00 
801075f5:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801075fc:	e8 a0 ff ff ff       	call   801075a1 <outb>
  outb(COM1+1, 0);
80107601:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107608:	00 
80107609:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107610:	e8 8c ff ff ff       	call   801075a1 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107615:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010761c:	00 
8010761d:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107624:	e8 78 ff ff ff       	call   801075a1 <outb>
  outb(COM1+4, 0);
80107629:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107630:	00 
80107631:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107638:	e8 64 ff ff ff       	call   801075a1 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
8010763d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107644:	00 
80107645:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010764c:	e8 50 ff ff ff       	call   801075a1 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107651:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107658:	e8 27 ff ff ff       	call   80107584 <inb>
8010765d:	3c ff                	cmp    $0xff,%al
8010765f:	75 02                	jne    80107663 <uartinit+0xa4>
    return;
80107661:	eb 6a                	jmp    801076cd <uartinit+0x10e>
  uart = 1;
80107663:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
8010766a:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
8010766d:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107674:	e8 0b ff ff ff       	call   80107584 <inb>
  inb(COM1+0);
80107679:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107680:	e8 ff fe ff ff       	call   80107584 <inb>
  picenable(IRQ_COM1);
80107685:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010768c:	e8 eb cd ff ff       	call   8010447c <picenable>
  ioapicenable(IRQ_COM1, 0);
80107691:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107698:	00 
80107699:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801076a0:	e8 8f b9 ff ff       	call   80103034 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801076a5:	c7 45 f4 84 96 10 80 	movl   $0x80109684,-0xc(%ebp)
801076ac:	eb 15                	jmp    801076c3 <uartinit+0x104>
    uartputc(*p);
801076ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076b1:	0f b6 00             	movzbl (%eax),%eax
801076b4:	0f be c0             	movsbl %al,%eax
801076b7:	89 04 24             	mov    %eax,(%esp)
801076ba:	e8 10 00 00 00       	call   801076cf <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801076bf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801076c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c6:	0f b6 00             	movzbl (%eax),%eax
801076c9:	84 c0                	test   %al,%al
801076cb:	75 e1                	jne    801076ae <uartinit+0xef>
    uartputc(*p);
}
801076cd:	c9                   	leave  
801076ce:	c3                   	ret    

801076cf <uartputc>:

void
uartputc(int c)
{
801076cf:	55                   	push   %ebp
801076d0:	89 e5                	mov    %esp,%ebp
801076d2:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
801076d5:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
801076da:	85 c0                	test   %eax,%eax
801076dc:	75 02                	jne    801076e0 <uartputc+0x11>
    return;
801076de:	eb 4b                	jmp    8010772b <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801076e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801076e7:	eb 10                	jmp    801076f9 <uartputc+0x2a>
    microdelay(10);
801076e9:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801076f0:	e8 d7 be ff ff       	call   801035cc <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801076f5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801076f9:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801076fd:	7f 16                	jg     80107715 <uartputc+0x46>
801076ff:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107706:	e8 79 fe ff ff       	call   80107584 <inb>
8010770b:	0f b6 c0             	movzbl %al,%eax
8010770e:	83 e0 20             	and    $0x20,%eax
80107711:	85 c0                	test   %eax,%eax
80107713:	74 d4                	je     801076e9 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80107715:	8b 45 08             	mov    0x8(%ebp),%eax
80107718:	0f b6 c0             	movzbl %al,%eax
8010771b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010771f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107726:	e8 76 fe ff ff       	call   801075a1 <outb>
}
8010772b:	c9                   	leave  
8010772c:	c3                   	ret    

8010772d <uartgetc>:

static int
uartgetc(void)
{
8010772d:	55                   	push   %ebp
8010772e:	89 e5                	mov    %esp,%ebp
80107730:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107733:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107738:	85 c0                	test   %eax,%eax
8010773a:	75 07                	jne    80107743 <uartgetc+0x16>
    return -1;
8010773c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107741:	eb 2c                	jmp    8010776f <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107743:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010774a:	e8 35 fe ff ff       	call   80107584 <inb>
8010774f:	0f b6 c0             	movzbl %al,%eax
80107752:	83 e0 01             	and    $0x1,%eax
80107755:	85 c0                	test   %eax,%eax
80107757:	75 07                	jne    80107760 <uartgetc+0x33>
    return -1;
80107759:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010775e:	eb 0f                	jmp    8010776f <uartgetc+0x42>
  return inb(COM1+0);
80107760:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107767:	e8 18 fe ff ff       	call   80107584 <inb>
8010776c:	0f b6 c0             	movzbl %al,%eax
}
8010776f:	c9                   	leave  
80107770:	c3                   	ret    

80107771 <uartintr>:

void
uartintr(void)
{
80107771:	55                   	push   %ebp
80107772:	89 e5                	mov    %esp,%ebp
80107774:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107777:	c7 04 24 2d 77 10 80 	movl   $0x8010772d,(%esp)
8010777e:	e8 ac 93 ff ff       	call   80100b2f <consoleintr>
}
80107783:	c9                   	leave  
80107784:	c3                   	ret    

80107785 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107785:	6a 00                	push   $0x0
  pushl $0
80107787:	6a 00                	push   $0x0
  jmp alltraps
80107789:	e9 48 f9 ff ff       	jmp    801070d6 <alltraps>

8010778e <vector1>:
.globl vector1
vector1:
  pushl $0
8010778e:	6a 00                	push   $0x0
  pushl $1
80107790:	6a 01                	push   $0x1
  jmp alltraps
80107792:	e9 3f f9 ff ff       	jmp    801070d6 <alltraps>

80107797 <vector2>:
.globl vector2
vector2:
  pushl $0
80107797:	6a 00                	push   $0x0
  pushl $2
80107799:	6a 02                	push   $0x2
  jmp alltraps
8010779b:	e9 36 f9 ff ff       	jmp    801070d6 <alltraps>

801077a0 <vector3>:
.globl vector3
vector3:
  pushl $0
801077a0:	6a 00                	push   $0x0
  pushl $3
801077a2:	6a 03                	push   $0x3
  jmp alltraps
801077a4:	e9 2d f9 ff ff       	jmp    801070d6 <alltraps>

801077a9 <vector4>:
.globl vector4
vector4:
  pushl $0
801077a9:	6a 00                	push   $0x0
  pushl $4
801077ab:	6a 04                	push   $0x4
  jmp alltraps
801077ad:	e9 24 f9 ff ff       	jmp    801070d6 <alltraps>

801077b2 <vector5>:
.globl vector5
vector5:
  pushl $0
801077b2:	6a 00                	push   $0x0
  pushl $5
801077b4:	6a 05                	push   $0x5
  jmp alltraps
801077b6:	e9 1b f9 ff ff       	jmp    801070d6 <alltraps>

801077bb <vector6>:
.globl vector6
vector6:
  pushl $0
801077bb:	6a 00                	push   $0x0
  pushl $6
801077bd:	6a 06                	push   $0x6
  jmp alltraps
801077bf:	e9 12 f9 ff ff       	jmp    801070d6 <alltraps>

801077c4 <vector7>:
.globl vector7
vector7:
  pushl $0
801077c4:	6a 00                	push   $0x0
  pushl $7
801077c6:	6a 07                	push   $0x7
  jmp alltraps
801077c8:	e9 09 f9 ff ff       	jmp    801070d6 <alltraps>

801077cd <vector8>:
.globl vector8
vector8:
  pushl $8
801077cd:	6a 08                	push   $0x8
  jmp alltraps
801077cf:	e9 02 f9 ff ff       	jmp    801070d6 <alltraps>

801077d4 <vector9>:
.globl vector9
vector9:
  pushl $0
801077d4:	6a 00                	push   $0x0
  pushl $9
801077d6:	6a 09                	push   $0x9
  jmp alltraps
801077d8:	e9 f9 f8 ff ff       	jmp    801070d6 <alltraps>

801077dd <vector10>:
.globl vector10
vector10:
  pushl $10
801077dd:	6a 0a                	push   $0xa
  jmp alltraps
801077df:	e9 f2 f8 ff ff       	jmp    801070d6 <alltraps>

801077e4 <vector11>:
.globl vector11
vector11:
  pushl $11
801077e4:	6a 0b                	push   $0xb
  jmp alltraps
801077e6:	e9 eb f8 ff ff       	jmp    801070d6 <alltraps>

801077eb <vector12>:
.globl vector12
vector12:
  pushl $12
801077eb:	6a 0c                	push   $0xc
  jmp alltraps
801077ed:	e9 e4 f8 ff ff       	jmp    801070d6 <alltraps>

801077f2 <vector13>:
.globl vector13
vector13:
  pushl $13
801077f2:	6a 0d                	push   $0xd
  jmp alltraps
801077f4:	e9 dd f8 ff ff       	jmp    801070d6 <alltraps>

801077f9 <vector14>:
.globl vector14
vector14:
  pushl $14
801077f9:	6a 0e                	push   $0xe
  jmp alltraps
801077fb:	e9 d6 f8 ff ff       	jmp    801070d6 <alltraps>

80107800 <vector15>:
.globl vector15
vector15:
  pushl $0
80107800:	6a 00                	push   $0x0
  pushl $15
80107802:	6a 0f                	push   $0xf
  jmp alltraps
80107804:	e9 cd f8 ff ff       	jmp    801070d6 <alltraps>

80107809 <vector16>:
.globl vector16
vector16:
  pushl $0
80107809:	6a 00                	push   $0x0
  pushl $16
8010780b:	6a 10                	push   $0x10
  jmp alltraps
8010780d:	e9 c4 f8 ff ff       	jmp    801070d6 <alltraps>

80107812 <vector17>:
.globl vector17
vector17:
  pushl $17
80107812:	6a 11                	push   $0x11
  jmp alltraps
80107814:	e9 bd f8 ff ff       	jmp    801070d6 <alltraps>

80107819 <vector18>:
.globl vector18
vector18:
  pushl $0
80107819:	6a 00                	push   $0x0
  pushl $18
8010781b:	6a 12                	push   $0x12
  jmp alltraps
8010781d:	e9 b4 f8 ff ff       	jmp    801070d6 <alltraps>

80107822 <vector19>:
.globl vector19
vector19:
  pushl $0
80107822:	6a 00                	push   $0x0
  pushl $19
80107824:	6a 13                	push   $0x13
  jmp alltraps
80107826:	e9 ab f8 ff ff       	jmp    801070d6 <alltraps>

8010782b <vector20>:
.globl vector20
vector20:
  pushl $0
8010782b:	6a 00                	push   $0x0
  pushl $20
8010782d:	6a 14                	push   $0x14
  jmp alltraps
8010782f:	e9 a2 f8 ff ff       	jmp    801070d6 <alltraps>

80107834 <vector21>:
.globl vector21
vector21:
  pushl $0
80107834:	6a 00                	push   $0x0
  pushl $21
80107836:	6a 15                	push   $0x15
  jmp alltraps
80107838:	e9 99 f8 ff ff       	jmp    801070d6 <alltraps>

8010783d <vector22>:
.globl vector22
vector22:
  pushl $0
8010783d:	6a 00                	push   $0x0
  pushl $22
8010783f:	6a 16                	push   $0x16
  jmp alltraps
80107841:	e9 90 f8 ff ff       	jmp    801070d6 <alltraps>

80107846 <vector23>:
.globl vector23
vector23:
  pushl $0
80107846:	6a 00                	push   $0x0
  pushl $23
80107848:	6a 17                	push   $0x17
  jmp alltraps
8010784a:	e9 87 f8 ff ff       	jmp    801070d6 <alltraps>

8010784f <vector24>:
.globl vector24
vector24:
  pushl $0
8010784f:	6a 00                	push   $0x0
  pushl $24
80107851:	6a 18                	push   $0x18
  jmp alltraps
80107853:	e9 7e f8 ff ff       	jmp    801070d6 <alltraps>

80107858 <vector25>:
.globl vector25
vector25:
  pushl $0
80107858:	6a 00                	push   $0x0
  pushl $25
8010785a:	6a 19                	push   $0x19
  jmp alltraps
8010785c:	e9 75 f8 ff ff       	jmp    801070d6 <alltraps>

80107861 <vector26>:
.globl vector26
vector26:
  pushl $0
80107861:	6a 00                	push   $0x0
  pushl $26
80107863:	6a 1a                	push   $0x1a
  jmp alltraps
80107865:	e9 6c f8 ff ff       	jmp    801070d6 <alltraps>

8010786a <vector27>:
.globl vector27
vector27:
  pushl $0
8010786a:	6a 00                	push   $0x0
  pushl $27
8010786c:	6a 1b                	push   $0x1b
  jmp alltraps
8010786e:	e9 63 f8 ff ff       	jmp    801070d6 <alltraps>

80107873 <vector28>:
.globl vector28
vector28:
  pushl $0
80107873:	6a 00                	push   $0x0
  pushl $28
80107875:	6a 1c                	push   $0x1c
  jmp alltraps
80107877:	e9 5a f8 ff ff       	jmp    801070d6 <alltraps>

8010787c <vector29>:
.globl vector29
vector29:
  pushl $0
8010787c:	6a 00                	push   $0x0
  pushl $29
8010787e:	6a 1d                	push   $0x1d
  jmp alltraps
80107880:	e9 51 f8 ff ff       	jmp    801070d6 <alltraps>

80107885 <vector30>:
.globl vector30
vector30:
  pushl $0
80107885:	6a 00                	push   $0x0
  pushl $30
80107887:	6a 1e                	push   $0x1e
  jmp alltraps
80107889:	e9 48 f8 ff ff       	jmp    801070d6 <alltraps>

8010788e <vector31>:
.globl vector31
vector31:
  pushl $0
8010788e:	6a 00                	push   $0x0
  pushl $31
80107890:	6a 1f                	push   $0x1f
  jmp alltraps
80107892:	e9 3f f8 ff ff       	jmp    801070d6 <alltraps>

80107897 <vector32>:
.globl vector32
vector32:
  pushl $0
80107897:	6a 00                	push   $0x0
  pushl $32
80107899:	6a 20                	push   $0x20
  jmp alltraps
8010789b:	e9 36 f8 ff ff       	jmp    801070d6 <alltraps>

801078a0 <vector33>:
.globl vector33
vector33:
  pushl $0
801078a0:	6a 00                	push   $0x0
  pushl $33
801078a2:	6a 21                	push   $0x21
  jmp alltraps
801078a4:	e9 2d f8 ff ff       	jmp    801070d6 <alltraps>

801078a9 <vector34>:
.globl vector34
vector34:
  pushl $0
801078a9:	6a 00                	push   $0x0
  pushl $34
801078ab:	6a 22                	push   $0x22
  jmp alltraps
801078ad:	e9 24 f8 ff ff       	jmp    801070d6 <alltraps>

801078b2 <vector35>:
.globl vector35
vector35:
  pushl $0
801078b2:	6a 00                	push   $0x0
  pushl $35
801078b4:	6a 23                	push   $0x23
  jmp alltraps
801078b6:	e9 1b f8 ff ff       	jmp    801070d6 <alltraps>

801078bb <vector36>:
.globl vector36
vector36:
  pushl $0
801078bb:	6a 00                	push   $0x0
  pushl $36
801078bd:	6a 24                	push   $0x24
  jmp alltraps
801078bf:	e9 12 f8 ff ff       	jmp    801070d6 <alltraps>

801078c4 <vector37>:
.globl vector37
vector37:
  pushl $0
801078c4:	6a 00                	push   $0x0
  pushl $37
801078c6:	6a 25                	push   $0x25
  jmp alltraps
801078c8:	e9 09 f8 ff ff       	jmp    801070d6 <alltraps>

801078cd <vector38>:
.globl vector38
vector38:
  pushl $0
801078cd:	6a 00                	push   $0x0
  pushl $38
801078cf:	6a 26                	push   $0x26
  jmp alltraps
801078d1:	e9 00 f8 ff ff       	jmp    801070d6 <alltraps>

801078d6 <vector39>:
.globl vector39
vector39:
  pushl $0
801078d6:	6a 00                	push   $0x0
  pushl $39
801078d8:	6a 27                	push   $0x27
  jmp alltraps
801078da:	e9 f7 f7 ff ff       	jmp    801070d6 <alltraps>

801078df <vector40>:
.globl vector40
vector40:
  pushl $0
801078df:	6a 00                	push   $0x0
  pushl $40
801078e1:	6a 28                	push   $0x28
  jmp alltraps
801078e3:	e9 ee f7 ff ff       	jmp    801070d6 <alltraps>

801078e8 <vector41>:
.globl vector41
vector41:
  pushl $0
801078e8:	6a 00                	push   $0x0
  pushl $41
801078ea:	6a 29                	push   $0x29
  jmp alltraps
801078ec:	e9 e5 f7 ff ff       	jmp    801070d6 <alltraps>

801078f1 <vector42>:
.globl vector42
vector42:
  pushl $0
801078f1:	6a 00                	push   $0x0
  pushl $42
801078f3:	6a 2a                	push   $0x2a
  jmp alltraps
801078f5:	e9 dc f7 ff ff       	jmp    801070d6 <alltraps>

801078fa <vector43>:
.globl vector43
vector43:
  pushl $0
801078fa:	6a 00                	push   $0x0
  pushl $43
801078fc:	6a 2b                	push   $0x2b
  jmp alltraps
801078fe:	e9 d3 f7 ff ff       	jmp    801070d6 <alltraps>

80107903 <vector44>:
.globl vector44
vector44:
  pushl $0
80107903:	6a 00                	push   $0x0
  pushl $44
80107905:	6a 2c                	push   $0x2c
  jmp alltraps
80107907:	e9 ca f7 ff ff       	jmp    801070d6 <alltraps>

8010790c <vector45>:
.globl vector45
vector45:
  pushl $0
8010790c:	6a 00                	push   $0x0
  pushl $45
8010790e:	6a 2d                	push   $0x2d
  jmp alltraps
80107910:	e9 c1 f7 ff ff       	jmp    801070d6 <alltraps>

80107915 <vector46>:
.globl vector46
vector46:
  pushl $0
80107915:	6a 00                	push   $0x0
  pushl $46
80107917:	6a 2e                	push   $0x2e
  jmp alltraps
80107919:	e9 b8 f7 ff ff       	jmp    801070d6 <alltraps>

8010791e <vector47>:
.globl vector47
vector47:
  pushl $0
8010791e:	6a 00                	push   $0x0
  pushl $47
80107920:	6a 2f                	push   $0x2f
  jmp alltraps
80107922:	e9 af f7 ff ff       	jmp    801070d6 <alltraps>

80107927 <vector48>:
.globl vector48
vector48:
  pushl $0
80107927:	6a 00                	push   $0x0
  pushl $48
80107929:	6a 30                	push   $0x30
  jmp alltraps
8010792b:	e9 a6 f7 ff ff       	jmp    801070d6 <alltraps>

80107930 <vector49>:
.globl vector49
vector49:
  pushl $0
80107930:	6a 00                	push   $0x0
  pushl $49
80107932:	6a 31                	push   $0x31
  jmp alltraps
80107934:	e9 9d f7 ff ff       	jmp    801070d6 <alltraps>

80107939 <vector50>:
.globl vector50
vector50:
  pushl $0
80107939:	6a 00                	push   $0x0
  pushl $50
8010793b:	6a 32                	push   $0x32
  jmp alltraps
8010793d:	e9 94 f7 ff ff       	jmp    801070d6 <alltraps>

80107942 <vector51>:
.globl vector51
vector51:
  pushl $0
80107942:	6a 00                	push   $0x0
  pushl $51
80107944:	6a 33                	push   $0x33
  jmp alltraps
80107946:	e9 8b f7 ff ff       	jmp    801070d6 <alltraps>

8010794b <vector52>:
.globl vector52
vector52:
  pushl $0
8010794b:	6a 00                	push   $0x0
  pushl $52
8010794d:	6a 34                	push   $0x34
  jmp alltraps
8010794f:	e9 82 f7 ff ff       	jmp    801070d6 <alltraps>

80107954 <vector53>:
.globl vector53
vector53:
  pushl $0
80107954:	6a 00                	push   $0x0
  pushl $53
80107956:	6a 35                	push   $0x35
  jmp alltraps
80107958:	e9 79 f7 ff ff       	jmp    801070d6 <alltraps>

8010795d <vector54>:
.globl vector54
vector54:
  pushl $0
8010795d:	6a 00                	push   $0x0
  pushl $54
8010795f:	6a 36                	push   $0x36
  jmp alltraps
80107961:	e9 70 f7 ff ff       	jmp    801070d6 <alltraps>

80107966 <vector55>:
.globl vector55
vector55:
  pushl $0
80107966:	6a 00                	push   $0x0
  pushl $55
80107968:	6a 37                	push   $0x37
  jmp alltraps
8010796a:	e9 67 f7 ff ff       	jmp    801070d6 <alltraps>

8010796f <vector56>:
.globl vector56
vector56:
  pushl $0
8010796f:	6a 00                	push   $0x0
  pushl $56
80107971:	6a 38                	push   $0x38
  jmp alltraps
80107973:	e9 5e f7 ff ff       	jmp    801070d6 <alltraps>

80107978 <vector57>:
.globl vector57
vector57:
  pushl $0
80107978:	6a 00                	push   $0x0
  pushl $57
8010797a:	6a 39                	push   $0x39
  jmp alltraps
8010797c:	e9 55 f7 ff ff       	jmp    801070d6 <alltraps>

80107981 <vector58>:
.globl vector58
vector58:
  pushl $0
80107981:	6a 00                	push   $0x0
  pushl $58
80107983:	6a 3a                	push   $0x3a
  jmp alltraps
80107985:	e9 4c f7 ff ff       	jmp    801070d6 <alltraps>

8010798a <vector59>:
.globl vector59
vector59:
  pushl $0
8010798a:	6a 00                	push   $0x0
  pushl $59
8010798c:	6a 3b                	push   $0x3b
  jmp alltraps
8010798e:	e9 43 f7 ff ff       	jmp    801070d6 <alltraps>

80107993 <vector60>:
.globl vector60
vector60:
  pushl $0
80107993:	6a 00                	push   $0x0
  pushl $60
80107995:	6a 3c                	push   $0x3c
  jmp alltraps
80107997:	e9 3a f7 ff ff       	jmp    801070d6 <alltraps>

8010799c <vector61>:
.globl vector61
vector61:
  pushl $0
8010799c:	6a 00                	push   $0x0
  pushl $61
8010799e:	6a 3d                	push   $0x3d
  jmp alltraps
801079a0:	e9 31 f7 ff ff       	jmp    801070d6 <alltraps>

801079a5 <vector62>:
.globl vector62
vector62:
  pushl $0
801079a5:	6a 00                	push   $0x0
  pushl $62
801079a7:	6a 3e                	push   $0x3e
  jmp alltraps
801079a9:	e9 28 f7 ff ff       	jmp    801070d6 <alltraps>

801079ae <vector63>:
.globl vector63
vector63:
  pushl $0
801079ae:	6a 00                	push   $0x0
  pushl $63
801079b0:	6a 3f                	push   $0x3f
  jmp alltraps
801079b2:	e9 1f f7 ff ff       	jmp    801070d6 <alltraps>

801079b7 <vector64>:
.globl vector64
vector64:
  pushl $0
801079b7:	6a 00                	push   $0x0
  pushl $64
801079b9:	6a 40                	push   $0x40
  jmp alltraps
801079bb:	e9 16 f7 ff ff       	jmp    801070d6 <alltraps>

801079c0 <vector65>:
.globl vector65
vector65:
  pushl $0
801079c0:	6a 00                	push   $0x0
  pushl $65
801079c2:	6a 41                	push   $0x41
  jmp alltraps
801079c4:	e9 0d f7 ff ff       	jmp    801070d6 <alltraps>

801079c9 <vector66>:
.globl vector66
vector66:
  pushl $0
801079c9:	6a 00                	push   $0x0
  pushl $66
801079cb:	6a 42                	push   $0x42
  jmp alltraps
801079cd:	e9 04 f7 ff ff       	jmp    801070d6 <alltraps>

801079d2 <vector67>:
.globl vector67
vector67:
  pushl $0
801079d2:	6a 00                	push   $0x0
  pushl $67
801079d4:	6a 43                	push   $0x43
  jmp alltraps
801079d6:	e9 fb f6 ff ff       	jmp    801070d6 <alltraps>

801079db <vector68>:
.globl vector68
vector68:
  pushl $0
801079db:	6a 00                	push   $0x0
  pushl $68
801079dd:	6a 44                	push   $0x44
  jmp alltraps
801079df:	e9 f2 f6 ff ff       	jmp    801070d6 <alltraps>

801079e4 <vector69>:
.globl vector69
vector69:
  pushl $0
801079e4:	6a 00                	push   $0x0
  pushl $69
801079e6:	6a 45                	push   $0x45
  jmp alltraps
801079e8:	e9 e9 f6 ff ff       	jmp    801070d6 <alltraps>

801079ed <vector70>:
.globl vector70
vector70:
  pushl $0
801079ed:	6a 00                	push   $0x0
  pushl $70
801079ef:	6a 46                	push   $0x46
  jmp alltraps
801079f1:	e9 e0 f6 ff ff       	jmp    801070d6 <alltraps>

801079f6 <vector71>:
.globl vector71
vector71:
  pushl $0
801079f6:	6a 00                	push   $0x0
  pushl $71
801079f8:	6a 47                	push   $0x47
  jmp alltraps
801079fa:	e9 d7 f6 ff ff       	jmp    801070d6 <alltraps>

801079ff <vector72>:
.globl vector72
vector72:
  pushl $0
801079ff:	6a 00                	push   $0x0
  pushl $72
80107a01:	6a 48                	push   $0x48
  jmp alltraps
80107a03:	e9 ce f6 ff ff       	jmp    801070d6 <alltraps>

80107a08 <vector73>:
.globl vector73
vector73:
  pushl $0
80107a08:	6a 00                	push   $0x0
  pushl $73
80107a0a:	6a 49                	push   $0x49
  jmp alltraps
80107a0c:	e9 c5 f6 ff ff       	jmp    801070d6 <alltraps>

80107a11 <vector74>:
.globl vector74
vector74:
  pushl $0
80107a11:	6a 00                	push   $0x0
  pushl $74
80107a13:	6a 4a                	push   $0x4a
  jmp alltraps
80107a15:	e9 bc f6 ff ff       	jmp    801070d6 <alltraps>

80107a1a <vector75>:
.globl vector75
vector75:
  pushl $0
80107a1a:	6a 00                	push   $0x0
  pushl $75
80107a1c:	6a 4b                	push   $0x4b
  jmp alltraps
80107a1e:	e9 b3 f6 ff ff       	jmp    801070d6 <alltraps>

80107a23 <vector76>:
.globl vector76
vector76:
  pushl $0
80107a23:	6a 00                	push   $0x0
  pushl $76
80107a25:	6a 4c                	push   $0x4c
  jmp alltraps
80107a27:	e9 aa f6 ff ff       	jmp    801070d6 <alltraps>

80107a2c <vector77>:
.globl vector77
vector77:
  pushl $0
80107a2c:	6a 00                	push   $0x0
  pushl $77
80107a2e:	6a 4d                	push   $0x4d
  jmp alltraps
80107a30:	e9 a1 f6 ff ff       	jmp    801070d6 <alltraps>

80107a35 <vector78>:
.globl vector78
vector78:
  pushl $0
80107a35:	6a 00                	push   $0x0
  pushl $78
80107a37:	6a 4e                	push   $0x4e
  jmp alltraps
80107a39:	e9 98 f6 ff ff       	jmp    801070d6 <alltraps>

80107a3e <vector79>:
.globl vector79
vector79:
  pushl $0
80107a3e:	6a 00                	push   $0x0
  pushl $79
80107a40:	6a 4f                	push   $0x4f
  jmp alltraps
80107a42:	e9 8f f6 ff ff       	jmp    801070d6 <alltraps>

80107a47 <vector80>:
.globl vector80
vector80:
  pushl $0
80107a47:	6a 00                	push   $0x0
  pushl $80
80107a49:	6a 50                	push   $0x50
  jmp alltraps
80107a4b:	e9 86 f6 ff ff       	jmp    801070d6 <alltraps>

80107a50 <vector81>:
.globl vector81
vector81:
  pushl $0
80107a50:	6a 00                	push   $0x0
  pushl $81
80107a52:	6a 51                	push   $0x51
  jmp alltraps
80107a54:	e9 7d f6 ff ff       	jmp    801070d6 <alltraps>

80107a59 <vector82>:
.globl vector82
vector82:
  pushl $0
80107a59:	6a 00                	push   $0x0
  pushl $82
80107a5b:	6a 52                	push   $0x52
  jmp alltraps
80107a5d:	e9 74 f6 ff ff       	jmp    801070d6 <alltraps>

80107a62 <vector83>:
.globl vector83
vector83:
  pushl $0
80107a62:	6a 00                	push   $0x0
  pushl $83
80107a64:	6a 53                	push   $0x53
  jmp alltraps
80107a66:	e9 6b f6 ff ff       	jmp    801070d6 <alltraps>

80107a6b <vector84>:
.globl vector84
vector84:
  pushl $0
80107a6b:	6a 00                	push   $0x0
  pushl $84
80107a6d:	6a 54                	push   $0x54
  jmp alltraps
80107a6f:	e9 62 f6 ff ff       	jmp    801070d6 <alltraps>

80107a74 <vector85>:
.globl vector85
vector85:
  pushl $0
80107a74:	6a 00                	push   $0x0
  pushl $85
80107a76:	6a 55                	push   $0x55
  jmp alltraps
80107a78:	e9 59 f6 ff ff       	jmp    801070d6 <alltraps>

80107a7d <vector86>:
.globl vector86
vector86:
  pushl $0
80107a7d:	6a 00                	push   $0x0
  pushl $86
80107a7f:	6a 56                	push   $0x56
  jmp alltraps
80107a81:	e9 50 f6 ff ff       	jmp    801070d6 <alltraps>

80107a86 <vector87>:
.globl vector87
vector87:
  pushl $0
80107a86:	6a 00                	push   $0x0
  pushl $87
80107a88:	6a 57                	push   $0x57
  jmp alltraps
80107a8a:	e9 47 f6 ff ff       	jmp    801070d6 <alltraps>

80107a8f <vector88>:
.globl vector88
vector88:
  pushl $0
80107a8f:	6a 00                	push   $0x0
  pushl $88
80107a91:	6a 58                	push   $0x58
  jmp alltraps
80107a93:	e9 3e f6 ff ff       	jmp    801070d6 <alltraps>

80107a98 <vector89>:
.globl vector89
vector89:
  pushl $0
80107a98:	6a 00                	push   $0x0
  pushl $89
80107a9a:	6a 59                	push   $0x59
  jmp alltraps
80107a9c:	e9 35 f6 ff ff       	jmp    801070d6 <alltraps>

80107aa1 <vector90>:
.globl vector90
vector90:
  pushl $0
80107aa1:	6a 00                	push   $0x0
  pushl $90
80107aa3:	6a 5a                	push   $0x5a
  jmp alltraps
80107aa5:	e9 2c f6 ff ff       	jmp    801070d6 <alltraps>

80107aaa <vector91>:
.globl vector91
vector91:
  pushl $0
80107aaa:	6a 00                	push   $0x0
  pushl $91
80107aac:	6a 5b                	push   $0x5b
  jmp alltraps
80107aae:	e9 23 f6 ff ff       	jmp    801070d6 <alltraps>

80107ab3 <vector92>:
.globl vector92
vector92:
  pushl $0
80107ab3:	6a 00                	push   $0x0
  pushl $92
80107ab5:	6a 5c                	push   $0x5c
  jmp alltraps
80107ab7:	e9 1a f6 ff ff       	jmp    801070d6 <alltraps>

80107abc <vector93>:
.globl vector93
vector93:
  pushl $0
80107abc:	6a 00                	push   $0x0
  pushl $93
80107abe:	6a 5d                	push   $0x5d
  jmp alltraps
80107ac0:	e9 11 f6 ff ff       	jmp    801070d6 <alltraps>

80107ac5 <vector94>:
.globl vector94
vector94:
  pushl $0
80107ac5:	6a 00                	push   $0x0
  pushl $94
80107ac7:	6a 5e                	push   $0x5e
  jmp alltraps
80107ac9:	e9 08 f6 ff ff       	jmp    801070d6 <alltraps>

80107ace <vector95>:
.globl vector95
vector95:
  pushl $0
80107ace:	6a 00                	push   $0x0
  pushl $95
80107ad0:	6a 5f                	push   $0x5f
  jmp alltraps
80107ad2:	e9 ff f5 ff ff       	jmp    801070d6 <alltraps>

80107ad7 <vector96>:
.globl vector96
vector96:
  pushl $0
80107ad7:	6a 00                	push   $0x0
  pushl $96
80107ad9:	6a 60                	push   $0x60
  jmp alltraps
80107adb:	e9 f6 f5 ff ff       	jmp    801070d6 <alltraps>

80107ae0 <vector97>:
.globl vector97
vector97:
  pushl $0
80107ae0:	6a 00                	push   $0x0
  pushl $97
80107ae2:	6a 61                	push   $0x61
  jmp alltraps
80107ae4:	e9 ed f5 ff ff       	jmp    801070d6 <alltraps>

80107ae9 <vector98>:
.globl vector98
vector98:
  pushl $0
80107ae9:	6a 00                	push   $0x0
  pushl $98
80107aeb:	6a 62                	push   $0x62
  jmp alltraps
80107aed:	e9 e4 f5 ff ff       	jmp    801070d6 <alltraps>

80107af2 <vector99>:
.globl vector99
vector99:
  pushl $0
80107af2:	6a 00                	push   $0x0
  pushl $99
80107af4:	6a 63                	push   $0x63
  jmp alltraps
80107af6:	e9 db f5 ff ff       	jmp    801070d6 <alltraps>

80107afb <vector100>:
.globl vector100
vector100:
  pushl $0
80107afb:	6a 00                	push   $0x0
  pushl $100
80107afd:	6a 64                	push   $0x64
  jmp alltraps
80107aff:	e9 d2 f5 ff ff       	jmp    801070d6 <alltraps>

80107b04 <vector101>:
.globl vector101
vector101:
  pushl $0
80107b04:	6a 00                	push   $0x0
  pushl $101
80107b06:	6a 65                	push   $0x65
  jmp alltraps
80107b08:	e9 c9 f5 ff ff       	jmp    801070d6 <alltraps>

80107b0d <vector102>:
.globl vector102
vector102:
  pushl $0
80107b0d:	6a 00                	push   $0x0
  pushl $102
80107b0f:	6a 66                	push   $0x66
  jmp alltraps
80107b11:	e9 c0 f5 ff ff       	jmp    801070d6 <alltraps>

80107b16 <vector103>:
.globl vector103
vector103:
  pushl $0
80107b16:	6a 00                	push   $0x0
  pushl $103
80107b18:	6a 67                	push   $0x67
  jmp alltraps
80107b1a:	e9 b7 f5 ff ff       	jmp    801070d6 <alltraps>

80107b1f <vector104>:
.globl vector104
vector104:
  pushl $0
80107b1f:	6a 00                	push   $0x0
  pushl $104
80107b21:	6a 68                	push   $0x68
  jmp alltraps
80107b23:	e9 ae f5 ff ff       	jmp    801070d6 <alltraps>

80107b28 <vector105>:
.globl vector105
vector105:
  pushl $0
80107b28:	6a 00                	push   $0x0
  pushl $105
80107b2a:	6a 69                	push   $0x69
  jmp alltraps
80107b2c:	e9 a5 f5 ff ff       	jmp    801070d6 <alltraps>

80107b31 <vector106>:
.globl vector106
vector106:
  pushl $0
80107b31:	6a 00                	push   $0x0
  pushl $106
80107b33:	6a 6a                	push   $0x6a
  jmp alltraps
80107b35:	e9 9c f5 ff ff       	jmp    801070d6 <alltraps>

80107b3a <vector107>:
.globl vector107
vector107:
  pushl $0
80107b3a:	6a 00                	push   $0x0
  pushl $107
80107b3c:	6a 6b                	push   $0x6b
  jmp alltraps
80107b3e:	e9 93 f5 ff ff       	jmp    801070d6 <alltraps>

80107b43 <vector108>:
.globl vector108
vector108:
  pushl $0
80107b43:	6a 00                	push   $0x0
  pushl $108
80107b45:	6a 6c                	push   $0x6c
  jmp alltraps
80107b47:	e9 8a f5 ff ff       	jmp    801070d6 <alltraps>

80107b4c <vector109>:
.globl vector109
vector109:
  pushl $0
80107b4c:	6a 00                	push   $0x0
  pushl $109
80107b4e:	6a 6d                	push   $0x6d
  jmp alltraps
80107b50:	e9 81 f5 ff ff       	jmp    801070d6 <alltraps>

80107b55 <vector110>:
.globl vector110
vector110:
  pushl $0
80107b55:	6a 00                	push   $0x0
  pushl $110
80107b57:	6a 6e                	push   $0x6e
  jmp alltraps
80107b59:	e9 78 f5 ff ff       	jmp    801070d6 <alltraps>

80107b5e <vector111>:
.globl vector111
vector111:
  pushl $0
80107b5e:	6a 00                	push   $0x0
  pushl $111
80107b60:	6a 6f                	push   $0x6f
  jmp alltraps
80107b62:	e9 6f f5 ff ff       	jmp    801070d6 <alltraps>

80107b67 <vector112>:
.globl vector112
vector112:
  pushl $0
80107b67:	6a 00                	push   $0x0
  pushl $112
80107b69:	6a 70                	push   $0x70
  jmp alltraps
80107b6b:	e9 66 f5 ff ff       	jmp    801070d6 <alltraps>

80107b70 <vector113>:
.globl vector113
vector113:
  pushl $0
80107b70:	6a 00                	push   $0x0
  pushl $113
80107b72:	6a 71                	push   $0x71
  jmp alltraps
80107b74:	e9 5d f5 ff ff       	jmp    801070d6 <alltraps>

80107b79 <vector114>:
.globl vector114
vector114:
  pushl $0
80107b79:	6a 00                	push   $0x0
  pushl $114
80107b7b:	6a 72                	push   $0x72
  jmp alltraps
80107b7d:	e9 54 f5 ff ff       	jmp    801070d6 <alltraps>

80107b82 <vector115>:
.globl vector115
vector115:
  pushl $0
80107b82:	6a 00                	push   $0x0
  pushl $115
80107b84:	6a 73                	push   $0x73
  jmp alltraps
80107b86:	e9 4b f5 ff ff       	jmp    801070d6 <alltraps>

80107b8b <vector116>:
.globl vector116
vector116:
  pushl $0
80107b8b:	6a 00                	push   $0x0
  pushl $116
80107b8d:	6a 74                	push   $0x74
  jmp alltraps
80107b8f:	e9 42 f5 ff ff       	jmp    801070d6 <alltraps>

80107b94 <vector117>:
.globl vector117
vector117:
  pushl $0
80107b94:	6a 00                	push   $0x0
  pushl $117
80107b96:	6a 75                	push   $0x75
  jmp alltraps
80107b98:	e9 39 f5 ff ff       	jmp    801070d6 <alltraps>

80107b9d <vector118>:
.globl vector118
vector118:
  pushl $0
80107b9d:	6a 00                	push   $0x0
  pushl $118
80107b9f:	6a 76                	push   $0x76
  jmp alltraps
80107ba1:	e9 30 f5 ff ff       	jmp    801070d6 <alltraps>

80107ba6 <vector119>:
.globl vector119
vector119:
  pushl $0
80107ba6:	6a 00                	push   $0x0
  pushl $119
80107ba8:	6a 77                	push   $0x77
  jmp alltraps
80107baa:	e9 27 f5 ff ff       	jmp    801070d6 <alltraps>

80107baf <vector120>:
.globl vector120
vector120:
  pushl $0
80107baf:	6a 00                	push   $0x0
  pushl $120
80107bb1:	6a 78                	push   $0x78
  jmp alltraps
80107bb3:	e9 1e f5 ff ff       	jmp    801070d6 <alltraps>

80107bb8 <vector121>:
.globl vector121
vector121:
  pushl $0
80107bb8:	6a 00                	push   $0x0
  pushl $121
80107bba:	6a 79                	push   $0x79
  jmp alltraps
80107bbc:	e9 15 f5 ff ff       	jmp    801070d6 <alltraps>

80107bc1 <vector122>:
.globl vector122
vector122:
  pushl $0
80107bc1:	6a 00                	push   $0x0
  pushl $122
80107bc3:	6a 7a                	push   $0x7a
  jmp alltraps
80107bc5:	e9 0c f5 ff ff       	jmp    801070d6 <alltraps>

80107bca <vector123>:
.globl vector123
vector123:
  pushl $0
80107bca:	6a 00                	push   $0x0
  pushl $123
80107bcc:	6a 7b                	push   $0x7b
  jmp alltraps
80107bce:	e9 03 f5 ff ff       	jmp    801070d6 <alltraps>

80107bd3 <vector124>:
.globl vector124
vector124:
  pushl $0
80107bd3:	6a 00                	push   $0x0
  pushl $124
80107bd5:	6a 7c                	push   $0x7c
  jmp alltraps
80107bd7:	e9 fa f4 ff ff       	jmp    801070d6 <alltraps>

80107bdc <vector125>:
.globl vector125
vector125:
  pushl $0
80107bdc:	6a 00                	push   $0x0
  pushl $125
80107bde:	6a 7d                	push   $0x7d
  jmp alltraps
80107be0:	e9 f1 f4 ff ff       	jmp    801070d6 <alltraps>

80107be5 <vector126>:
.globl vector126
vector126:
  pushl $0
80107be5:	6a 00                	push   $0x0
  pushl $126
80107be7:	6a 7e                	push   $0x7e
  jmp alltraps
80107be9:	e9 e8 f4 ff ff       	jmp    801070d6 <alltraps>

80107bee <vector127>:
.globl vector127
vector127:
  pushl $0
80107bee:	6a 00                	push   $0x0
  pushl $127
80107bf0:	6a 7f                	push   $0x7f
  jmp alltraps
80107bf2:	e9 df f4 ff ff       	jmp    801070d6 <alltraps>

80107bf7 <vector128>:
.globl vector128
vector128:
  pushl $0
80107bf7:	6a 00                	push   $0x0
  pushl $128
80107bf9:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107bfe:	e9 d3 f4 ff ff       	jmp    801070d6 <alltraps>

80107c03 <vector129>:
.globl vector129
vector129:
  pushl $0
80107c03:	6a 00                	push   $0x0
  pushl $129
80107c05:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107c0a:	e9 c7 f4 ff ff       	jmp    801070d6 <alltraps>

80107c0f <vector130>:
.globl vector130
vector130:
  pushl $0
80107c0f:	6a 00                	push   $0x0
  pushl $130
80107c11:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107c16:	e9 bb f4 ff ff       	jmp    801070d6 <alltraps>

80107c1b <vector131>:
.globl vector131
vector131:
  pushl $0
80107c1b:	6a 00                	push   $0x0
  pushl $131
80107c1d:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107c22:	e9 af f4 ff ff       	jmp    801070d6 <alltraps>

80107c27 <vector132>:
.globl vector132
vector132:
  pushl $0
80107c27:	6a 00                	push   $0x0
  pushl $132
80107c29:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107c2e:	e9 a3 f4 ff ff       	jmp    801070d6 <alltraps>

80107c33 <vector133>:
.globl vector133
vector133:
  pushl $0
80107c33:	6a 00                	push   $0x0
  pushl $133
80107c35:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107c3a:	e9 97 f4 ff ff       	jmp    801070d6 <alltraps>

80107c3f <vector134>:
.globl vector134
vector134:
  pushl $0
80107c3f:	6a 00                	push   $0x0
  pushl $134
80107c41:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107c46:	e9 8b f4 ff ff       	jmp    801070d6 <alltraps>

80107c4b <vector135>:
.globl vector135
vector135:
  pushl $0
80107c4b:	6a 00                	push   $0x0
  pushl $135
80107c4d:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107c52:	e9 7f f4 ff ff       	jmp    801070d6 <alltraps>

80107c57 <vector136>:
.globl vector136
vector136:
  pushl $0
80107c57:	6a 00                	push   $0x0
  pushl $136
80107c59:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107c5e:	e9 73 f4 ff ff       	jmp    801070d6 <alltraps>

80107c63 <vector137>:
.globl vector137
vector137:
  pushl $0
80107c63:	6a 00                	push   $0x0
  pushl $137
80107c65:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107c6a:	e9 67 f4 ff ff       	jmp    801070d6 <alltraps>

80107c6f <vector138>:
.globl vector138
vector138:
  pushl $0
80107c6f:	6a 00                	push   $0x0
  pushl $138
80107c71:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107c76:	e9 5b f4 ff ff       	jmp    801070d6 <alltraps>

80107c7b <vector139>:
.globl vector139
vector139:
  pushl $0
80107c7b:	6a 00                	push   $0x0
  pushl $139
80107c7d:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107c82:	e9 4f f4 ff ff       	jmp    801070d6 <alltraps>

80107c87 <vector140>:
.globl vector140
vector140:
  pushl $0
80107c87:	6a 00                	push   $0x0
  pushl $140
80107c89:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107c8e:	e9 43 f4 ff ff       	jmp    801070d6 <alltraps>

80107c93 <vector141>:
.globl vector141
vector141:
  pushl $0
80107c93:	6a 00                	push   $0x0
  pushl $141
80107c95:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107c9a:	e9 37 f4 ff ff       	jmp    801070d6 <alltraps>

80107c9f <vector142>:
.globl vector142
vector142:
  pushl $0
80107c9f:	6a 00                	push   $0x0
  pushl $142
80107ca1:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107ca6:	e9 2b f4 ff ff       	jmp    801070d6 <alltraps>

80107cab <vector143>:
.globl vector143
vector143:
  pushl $0
80107cab:	6a 00                	push   $0x0
  pushl $143
80107cad:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107cb2:	e9 1f f4 ff ff       	jmp    801070d6 <alltraps>

80107cb7 <vector144>:
.globl vector144
vector144:
  pushl $0
80107cb7:	6a 00                	push   $0x0
  pushl $144
80107cb9:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107cbe:	e9 13 f4 ff ff       	jmp    801070d6 <alltraps>

80107cc3 <vector145>:
.globl vector145
vector145:
  pushl $0
80107cc3:	6a 00                	push   $0x0
  pushl $145
80107cc5:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107cca:	e9 07 f4 ff ff       	jmp    801070d6 <alltraps>

80107ccf <vector146>:
.globl vector146
vector146:
  pushl $0
80107ccf:	6a 00                	push   $0x0
  pushl $146
80107cd1:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107cd6:	e9 fb f3 ff ff       	jmp    801070d6 <alltraps>

80107cdb <vector147>:
.globl vector147
vector147:
  pushl $0
80107cdb:	6a 00                	push   $0x0
  pushl $147
80107cdd:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107ce2:	e9 ef f3 ff ff       	jmp    801070d6 <alltraps>

80107ce7 <vector148>:
.globl vector148
vector148:
  pushl $0
80107ce7:	6a 00                	push   $0x0
  pushl $148
80107ce9:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107cee:	e9 e3 f3 ff ff       	jmp    801070d6 <alltraps>

80107cf3 <vector149>:
.globl vector149
vector149:
  pushl $0
80107cf3:	6a 00                	push   $0x0
  pushl $149
80107cf5:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107cfa:	e9 d7 f3 ff ff       	jmp    801070d6 <alltraps>

80107cff <vector150>:
.globl vector150
vector150:
  pushl $0
80107cff:	6a 00                	push   $0x0
  pushl $150
80107d01:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107d06:	e9 cb f3 ff ff       	jmp    801070d6 <alltraps>

80107d0b <vector151>:
.globl vector151
vector151:
  pushl $0
80107d0b:	6a 00                	push   $0x0
  pushl $151
80107d0d:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107d12:	e9 bf f3 ff ff       	jmp    801070d6 <alltraps>

80107d17 <vector152>:
.globl vector152
vector152:
  pushl $0
80107d17:	6a 00                	push   $0x0
  pushl $152
80107d19:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107d1e:	e9 b3 f3 ff ff       	jmp    801070d6 <alltraps>

80107d23 <vector153>:
.globl vector153
vector153:
  pushl $0
80107d23:	6a 00                	push   $0x0
  pushl $153
80107d25:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107d2a:	e9 a7 f3 ff ff       	jmp    801070d6 <alltraps>

80107d2f <vector154>:
.globl vector154
vector154:
  pushl $0
80107d2f:	6a 00                	push   $0x0
  pushl $154
80107d31:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107d36:	e9 9b f3 ff ff       	jmp    801070d6 <alltraps>

80107d3b <vector155>:
.globl vector155
vector155:
  pushl $0
80107d3b:	6a 00                	push   $0x0
  pushl $155
80107d3d:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107d42:	e9 8f f3 ff ff       	jmp    801070d6 <alltraps>

80107d47 <vector156>:
.globl vector156
vector156:
  pushl $0
80107d47:	6a 00                	push   $0x0
  pushl $156
80107d49:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107d4e:	e9 83 f3 ff ff       	jmp    801070d6 <alltraps>

80107d53 <vector157>:
.globl vector157
vector157:
  pushl $0
80107d53:	6a 00                	push   $0x0
  pushl $157
80107d55:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107d5a:	e9 77 f3 ff ff       	jmp    801070d6 <alltraps>

80107d5f <vector158>:
.globl vector158
vector158:
  pushl $0
80107d5f:	6a 00                	push   $0x0
  pushl $158
80107d61:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107d66:	e9 6b f3 ff ff       	jmp    801070d6 <alltraps>

80107d6b <vector159>:
.globl vector159
vector159:
  pushl $0
80107d6b:	6a 00                	push   $0x0
  pushl $159
80107d6d:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107d72:	e9 5f f3 ff ff       	jmp    801070d6 <alltraps>

80107d77 <vector160>:
.globl vector160
vector160:
  pushl $0
80107d77:	6a 00                	push   $0x0
  pushl $160
80107d79:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107d7e:	e9 53 f3 ff ff       	jmp    801070d6 <alltraps>

80107d83 <vector161>:
.globl vector161
vector161:
  pushl $0
80107d83:	6a 00                	push   $0x0
  pushl $161
80107d85:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107d8a:	e9 47 f3 ff ff       	jmp    801070d6 <alltraps>

80107d8f <vector162>:
.globl vector162
vector162:
  pushl $0
80107d8f:	6a 00                	push   $0x0
  pushl $162
80107d91:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107d96:	e9 3b f3 ff ff       	jmp    801070d6 <alltraps>

80107d9b <vector163>:
.globl vector163
vector163:
  pushl $0
80107d9b:	6a 00                	push   $0x0
  pushl $163
80107d9d:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107da2:	e9 2f f3 ff ff       	jmp    801070d6 <alltraps>

80107da7 <vector164>:
.globl vector164
vector164:
  pushl $0
80107da7:	6a 00                	push   $0x0
  pushl $164
80107da9:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107dae:	e9 23 f3 ff ff       	jmp    801070d6 <alltraps>

80107db3 <vector165>:
.globl vector165
vector165:
  pushl $0
80107db3:	6a 00                	push   $0x0
  pushl $165
80107db5:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107dba:	e9 17 f3 ff ff       	jmp    801070d6 <alltraps>

80107dbf <vector166>:
.globl vector166
vector166:
  pushl $0
80107dbf:	6a 00                	push   $0x0
  pushl $166
80107dc1:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107dc6:	e9 0b f3 ff ff       	jmp    801070d6 <alltraps>

80107dcb <vector167>:
.globl vector167
vector167:
  pushl $0
80107dcb:	6a 00                	push   $0x0
  pushl $167
80107dcd:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107dd2:	e9 ff f2 ff ff       	jmp    801070d6 <alltraps>

80107dd7 <vector168>:
.globl vector168
vector168:
  pushl $0
80107dd7:	6a 00                	push   $0x0
  pushl $168
80107dd9:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107dde:	e9 f3 f2 ff ff       	jmp    801070d6 <alltraps>

80107de3 <vector169>:
.globl vector169
vector169:
  pushl $0
80107de3:	6a 00                	push   $0x0
  pushl $169
80107de5:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107dea:	e9 e7 f2 ff ff       	jmp    801070d6 <alltraps>

80107def <vector170>:
.globl vector170
vector170:
  pushl $0
80107def:	6a 00                	push   $0x0
  pushl $170
80107df1:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107df6:	e9 db f2 ff ff       	jmp    801070d6 <alltraps>

80107dfb <vector171>:
.globl vector171
vector171:
  pushl $0
80107dfb:	6a 00                	push   $0x0
  pushl $171
80107dfd:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107e02:	e9 cf f2 ff ff       	jmp    801070d6 <alltraps>

80107e07 <vector172>:
.globl vector172
vector172:
  pushl $0
80107e07:	6a 00                	push   $0x0
  pushl $172
80107e09:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107e0e:	e9 c3 f2 ff ff       	jmp    801070d6 <alltraps>

80107e13 <vector173>:
.globl vector173
vector173:
  pushl $0
80107e13:	6a 00                	push   $0x0
  pushl $173
80107e15:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107e1a:	e9 b7 f2 ff ff       	jmp    801070d6 <alltraps>

80107e1f <vector174>:
.globl vector174
vector174:
  pushl $0
80107e1f:	6a 00                	push   $0x0
  pushl $174
80107e21:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107e26:	e9 ab f2 ff ff       	jmp    801070d6 <alltraps>

80107e2b <vector175>:
.globl vector175
vector175:
  pushl $0
80107e2b:	6a 00                	push   $0x0
  pushl $175
80107e2d:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107e32:	e9 9f f2 ff ff       	jmp    801070d6 <alltraps>

80107e37 <vector176>:
.globl vector176
vector176:
  pushl $0
80107e37:	6a 00                	push   $0x0
  pushl $176
80107e39:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107e3e:	e9 93 f2 ff ff       	jmp    801070d6 <alltraps>

80107e43 <vector177>:
.globl vector177
vector177:
  pushl $0
80107e43:	6a 00                	push   $0x0
  pushl $177
80107e45:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107e4a:	e9 87 f2 ff ff       	jmp    801070d6 <alltraps>

80107e4f <vector178>:
.globl vector178
vector178:
  pushl $0
80107e4f:	6a 00                	push   $0x0
  pushl $178
80107e51:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107e56:	e9 7b f2 ff ff       	jmp    801070d6 <alltraps>

80107e5b <vector179>:
.globl vector179
vector179:
  pushl $0
80107e5b:	6a 00                	push   $0x0
  pushl $179
80107e5d:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107e62:	e9 6f f2 ff ff       	jmp    801070d6 <alltraps>

80107e67 <vector180>:
.globl vector180
vector180:
  pushl $0
80107e67:	6a 00                	push   $0x0
  pushl $180
80107e69:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107e6e:	e9 63 f2 ff ff       	jmp    801070d6 <alltraps>

80107e73 <vector181>:
.globl vector181
vector181:
  pushl $0
80107e73:	6a 00                	push   $0x0
  pushl $181
80107e75:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107e7a:	e9 57 f2 ff ff       	jmp    801070d6 <alltraps>

80107e7f <vector182>:
.globl vector182
vector182:
  pushl $0
80107e7f:	6a 00                	push   $0x0
  pushl $182
80107e81:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107e86:	e9 4b f2 ff ff       	jmp    801070d6 <alltraps>

80107e8b <vector183>:
.globl vector183
vector183:
  pushl $0
80107e8b:	6a 00                	push   $0x0
  pushl $183
80107e8d:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107e92:	e9 3f f2 ff ff       	jmp    801070d6 <alltraps>

80107e97 <vector184>:
.globl vector184
vector184:
  pushl $0
80107e97:	6a 00                	push   $0x0
  pushl $184
80107e99:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107e9e:	e9 33 f2 ff ff       	jmp    801070d6 <alltraps>

80107ea3 <vector185>:
.globl vector185
vector185:
  pushl $0
80107ea3:	6a 00                	push   $0x0
  pushl $185
80107ea5:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107eaa:	e9 27 f2 ff ff       	jmp    801070d6 <alltraps>

80107eaf <vector186>:
.globl vector186
vector186:
  pushl $0
80107eaf:	6a 00                	push   $0x0
  pushl $186
80107eb1:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107eb6:	e9 1b f2 ff ff       	jmp    801070d6 <alltraps>

80107ebb <vector187>:
.globl vector187
vector187:
  pushl $0
80107ebb:	6a 00                	push   $0x0
  pushl $187
80107ebd:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107ec2:	e9 0f f2 ff ff       	jmp    801070d6 <alltraps>

80107ec7 <vector188>:
.globl vector188
vector188:
  pushl $0
80107ec7:	6a 00                	push   $0x0
  pushl $188
80107ec9:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107ece:	e9 03 f2 ff ff       	jmp    801070d6 <alltraps>

80107ed3 <vector189>:
.globl vector189
vector189:
  pushl $0
80107ed3:	6a 00                	push   $0x0
  pushl $189
80107ed5:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107eda:	e9 f7 f1 ff ff       	jmp    801070d6 <alltraps>

80107edf <vector190>:
.globl vector190
vector190:
  pushl $0
80107edf:	6a 00                	push   $0x0
  pushl $190
80107ee1:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107ee6:	e9 eb f1 ff ff       	jmp    801070d6 <alltraps>

80107eeb <vector191>:
.globl vector191
vector191:
  pushl $0
80107eeb:	6a 00                	push   $0x0
  pushl $191
80107eed:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107ef2:	e9 df f1 ff ff       	jmp    801070d6 <alltraps>

80107ef7 <vector192>:
.globl vector192
vector192:
  pushl $0
80107ef7:	6a 00                	push   $0x0
  pushl $192
80107ef9:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107efe:	e9 d3 f1 ff ff       	jmp    801070d6 <alltraps>

80107f03 <vector193>:
.globl vector193
vector193:
  pushl $0
80107f03:	6a 00                	push   $0x0
  pushl $193
80107f05:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107f0a:	e9 c7 f1 ff ff       	jmp    801070d6 <alltraps>

80107f0f <vector194>:
.globl vector194
vector194:
  pushl $0
80107f0f:	6a 00                	push   $0x0
  pushl $194
80107f11:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107f16:	e9 bb f1 ff ff       	jmp    801070d6 <alltraps>

80107f1b <vector195>:
.globl vector195
vector195:
  pushl $0
80107f1b:	6a 00                	push   $0x0
  pushl $195
80107f1d:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107f22:	e9 af f1 ff ff       	jmp    801070d6 <alltraps>

80107f27 <vector196>:
.globl vector196
vector196:
  pushl $0
80107f27:	6a 00                	push   $0x0
  pushl $196
80107f29:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107f2e:	e9 a3 f1 ff ff       	jmp    801070d6 <alltraps>

80107f33 <vector197>:
.globl vector197
vector197:
  pushl $0
80107f33:	6a 00                	push   $0x0
  pushl $197
80107f35:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107f3a:	e9 97 f1 ff ff       	jmp    801070d6 <alltraps>

80107f3f <vector198>:
.globl vector198
vector198:
  pushl $0
80107f3f:	6a 00                	push   $0x0
  pushl $198
80107f41:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107f46:	e9 8b f1 ff ff       	jmp    801070d6 <alltraps>

80107f4b <vector199>:
.globl vector199
vector199:
  pushl $0
80107f4b:	6a 00                	push   $0x0
  pushl $199
80107f4d:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107f52:	e9 7f f1 ff ff       	jmp    801070d6 <alltraps>

80107f57 <vector200>:
.globl vector200
vector200:
  pushl $0
80107f57:	6a 00                	push   $0x0
  pushl $200
80107f59:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107f5e:	e9 73 f1 ff ff       	jmp    801070d6 <alltraps>

80107f63 <vector201>:
.globl vector201
vector201:
  pushl $0
80107f63:	6a 00                	push   $0x0
  pushl $201
80107f65:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107f6a:	e9 67 f1 ff ff       	jmp    801070d6 <alltraps>

80107f6f <vector202>:
.globl vector202
vector202:
  pushl $0
80107f6f:	6a 00                	push   $0x0
  pushl $202
80107f71:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107f76:	e9 5b f1 ff ff       	jmp    801070d6 <alltraps>

80107f7b <vector203>:
.globl vector203
vector203:
  pushl $0
80107f7b:	6a 00                	push   $0x0
  pushl $203
80107f7d:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107f82:	e9 4f f1 ff ff       	jmp    801070d6 <alltraps>

80107f87 <vector204>:
.globl vector204
vector204:
  pushl $0
80107f87:	6a 00                	push   $0x0
  pushl $204
80107f89:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107f8e:	e9 43 f1 ff ff       	jmp    801070d6 <alltraps>

80107f93 <vector205>:
.globl vector205
vector205:
  pushl $0
80107f93:	6a 00                	push   $0x0
  pushl $205
80107f95:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107f9a:	e9 37 f1 ff ff       	jmp    801070d6 <alltraps>

80107f9f <vector206>:
.globl vector206
vector206:
  pushl $0
80107f9f:	6a 00                	push   $0x0
  pushl $206
80107fa1:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107fa6:	e9 2b f1 ff ff       	jmp    801070d6 <alltraps>

80107fab <vector207>:
.globl vector207
vector207:
  pushl $0
80107fab:	6a 00                	push   $0x0
  pushl $207
80107fad:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107fb2:	e9 1f f1 ff ff       	jmp    801070d6 <alltraps>

80107fb7 <vector208>:
.globl vector208
vector208:
  pushl $0
80107fb7:	6a 00                	push   $0x0
  pushl $208
80107fb9:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107fbe:	e9 13 f1 ff ff       	jmp    801070d6 <alltraps>

80107fc3 <vector209>:
.globl vector209
vector209:
  pushl $0
80107fc3:	6a 00                	push   $0x0
  pushl $209
80107fc5:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107fca:	e9 07 f1 ff ff       	jmp    801070d6 <alltraps>

80107fcf <vector210>:
.globl vector210
vector210:
  pushl $0
80107fcf:	6a 00                	push   $0x0
  pushl $210
80107fd1:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107fd6:	e9 fb f0 ff ff       	jmp    801070d6 <alltraps>

80107fdb <vector211>:
.globl vector211
vector211:
  pushl $0
80107fdb:	6a 00                	push   $0x0
  pushl $211
80107fdd:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107fe2:	e9 ef f0 ff ff       	jmp    801070d6 <alltraps>

80107fe7 <vector212>:
.globl vector212
vector212:
  pushl $0
80107fe7:	6a 00                	push   $0x0
  pushl $212
80107fe9:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107fee:	e9 e3 f0 ff ff       	jmp    801070d6 <alltraps>

80107ff3 <vector213>:
.globl vector213
vector213:
  pushl $0
80107ff3:	6a 00                	push   $0x0
  pushl $213
80107ff5:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107ffa:	e9 d7 f0 ff ff       	jmp    801070d6 <alltraps>

80107fff <vector214>:
.globl vector214
vector214:
  pushl $0
80107fff:	6a 00                	push   $0x0
  pushl $214
80108001:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108006:	e9 cb f0 ff ff       	jmp    801070d6 <alltraps>

8010800b <vector215>:
.globl vector215
vector215:
  pushl $0
8010800b:	6a 00                	push   $0x0
  pushl $215
8010800d:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80108012:	e9 bf f0 ff ff       	jmp    801070d6 <alltraps>

80108017 <vector216>:
.globl vector216
vector216:
  pushl $0
80108017:	6a 00                	push   $0x0
  pushl $216
80108019:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
8010801e:	e9 b3 f0 ff ff       	jmp    801070d6 <alltraps>

80108023 <vector217>:
.globl vector217
vector217:
  pushl $0
80108023:	6a 00                	push   $0x0
  pushl $217
80108025:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010802a:	e9 a7 f0 ff ff       	jmp    801070d6 <alltraps>

8010802f <vector218>:
.globl vector218
vector218:
  pushl $0
8010802f:	6a 00                	push   $0x0
  pushl $218
80108031:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80108036:	e9 9b f0 ff ff       	jmp    801070d6 <alltraps>

8010803b <vector219>:
.globl vector219
vector219:
  pushl $0
8010803b:	6a 00                	push   $0x0
  pushl $219
8010803d:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80108042:	e9 8f f0 ff ff       	jmp    801070d6 <alltraps>

80108047 <vector220>:
.globl vector220
vector220:
  pushl $0
80108047:	6a 00                	push   $0x0
  pushl $220
80108049:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
8010804e:	e9 83 f0 ff ff       	jmp    801070d6 <alltraps>

80108053 <vector221>:
.globl vector221
vector221:
  pushl $0
80108053:	6a 00                	push   $0x0
  pushl $221
80108055:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
8010805a:	e9 77 f0 ff ff       	jmp    801070d6 <alltraps>

8010805f <vector222>:
.globl vector222
vector222:
  pushl $0
8010805f:	6a 00                	push   $0x0
  pushl $222
80108061:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80108066:	e9 6b f0 ff ff       	jmp    801070d6 <alltraps>

8010806b <vector223>:
.globl vector223
vector223:
  pushl $0
8010806b:	6a 00                	push   $0x0
  pushl $223
8010806d:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80108072:	e9 5f f0 ff ff       	jmp    801070d6 <alltraps>

80108077 <vector224>:
.globl vector224
vector224:
  pushl $0
80108077:	6a 00                	push   $0x0
  pushl $224
80108079:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010807e:	e9 53 f0 ff ff       	jmp    801070d6 <alltraps>

80108083 <vector225>:
.globl vector225
vector225:
  pushl $0
80108083:	6a 00                	push   $0x0
  pushl $225
80108085:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
8010808a:	e9 47 f0 ff ff       	jmp    801070d6 <alltraps>

8010808f <vector226>:
.globl vector226
vector226:
  pushl $0
8010808f:	6a 00                	push   $0x0
  pushl $226
80108091:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108096:	e9 3b f0 ff ff       	jmp    801070d6 <alltraps>

8010809b <vector227>:
.globl vector227
vector227:
  pushl $0
8010809b:	6a 00                	push   $0x0
  pushl $227
8010809d:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801080a2:	e9 2f f0 ff ff       	jmp    801070d6 <alltraps>

801080a7 <vector228>:
.globl vector228
vector228:
  pushl $0
801080a7:	6a 00                	push   $0x0
  pushl $228
801080a9:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801080ae:	e9 23 f0 ff ff       	jmp    801070d6 <alltraps>

801080b3 <vector229>:
.globl vector229
vector229:
  pushl $0
801080b3:	6a 00                	push   $0x0
  pushl $229
801080b5:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801080ba:	e9 17 f0 ff ff       	jmp    801070d6 <alltraps>

801080bf <vector230>:
.globl vector230
vector230:
  pushl $0
801080bf:	6a 00                	push   $0x0
  pushl $230
801080c1:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801080c6:	e9 0b f0 ff ff       	jmp    801070d6 <alltraps>

801080cb <vector231>:
.globl vector231
vector231:
  pushl $0
801080cb:	6a 00                	push   $0x0
  pushl $231
801080cd:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801080d2:	e9 ff ef ff ff       	jmp    801070d6 <alltraps>

801080d7 <vector232>:
.globl vector232
vector232:
  pushl $0
801080d7:	6a 00                	push   $0x0
  pushl $232
801080d9:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801080de:	e9 f3 ef ff ff       	jmp    801070d6 <alltraps>

801080e3 <vector233>:
.globl vector233
vector233:
  pushl $0
801080e3:	6a 00                	push   $0x0
  pushl $233
801080e5:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801080ea:	e9 e7 ef ff ff       	jmp    801070d6 <alltraps>

801080ef <vector234>:
.globl vector234
vector234:
  pushl $0
801080ef:	6a 00                	push   $0x0
  pushl $234
801080f1:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801080f6:	e9 db ef ff ff       	jmp    801070d6 <alltraps>

801080fb <vector235>:
.globl vector235
vector235:
  pushl $0
801080fb:	6a 00                	push   $0x0
  pushl $235
801080fd:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80108102:	e9 cf ef ff ff       	jmp    801070d6 <alltraps>

80108107 <vector236>:
.globl vector236
vector236:
  pushl $0
80108107:	6a 00                	push   $0x0
  pushl $236
80108109:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010810e:	e9 c3 ef ff ff       	jmp    801070d6 <alltraps>

80108113 <vector237>:
.globl vector237
vector237:
  pushl $0
80108113:	6a 00                	push   $0x0
  pushl $237
80108115:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010811a:	e9 b7 ef ff ff       	jmp    801070d6 <alltraps>

8010811f <vector238>:
.globl vector238
vector238:
  pushl $0
8010811f:	6a 00                	push   $0x0
  pushl $238
80108121:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80108126:	e9 ab ef ff ff       	jmp    801070d6 <alltraps>

8010812b <vector239>:
.globl vector239
vector239:
  pushl $0
8010812b:	6a 00                	push   $0x0
  pushl $239
8010812d:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80108132:	e9 9f ef ff ff       	jmp    801070d6 <alltraps>

80108137 <vector240>:
.globl vector240
vector240:
  pushl $0
80108137:	6a 00                	push   $0x0
  pushl $240
80108139:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010813e:	e9 93 ef ff ff       	jmp    801070d6 <alltraps>

80108143 <vector241>:
.globl vector241
vector241:
  pushl $0
80108143:	6a 00                	push   $0x0
  pushl $241
80108145:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010814a:	e9 87 ef ff ff       	jmp    801070d6 <alltraps>

8010814f <vector242>:
.globl vector242
vector242:
  pushl $0
8010814f:	6a 00                	push   $0x0
  pushl $242
80108151:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80108156:	e9 7b ef ff ff       	jmp    801070d6 <alltraps>

8010815b <vector243>:
.globl vector243
vector243:
  pushl $0
8010815b:	6a 00                	push   $0x0
  pushl $243
8010815d:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80108162:	e9 6f ef ff ff       	jmp    801070d6 <alltraps>

80108167 <vector244>:
.globl vector244
vector244:
  pushl $0
80108167:	6a 00                	push   $0x0
  pushl $244
80108169:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010816e:	e9 63 ef ff ff       	jmp    801070d6 <alltraps>

80108173 <vector245>:
.globl vector245
vector245:
  pushl $0
80108173:	6a 00                	push   $0x0
  pushl $245
80108175:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010817a:	e9 57 ef ff ff       	jmp    801070d6 <alltraps>

8010817f <vector246>:
.globl vector246
vector246:
  pushl $0
8010817f:	6a 00                	push   $0x0
  pushl $246
80108181:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80108186:	e9 4b ef ff ff       	jmp    801070d6 <alltraps>

8010818b <vector247>:
.globl vector247
vector247:
  pushl $0
8010818b:	6a 00                	push   $0x0
  pushl $247
8010818d:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80108192:	e9 3f ef ff ff       	jmp    801070d6 <alltraps>

80108197 <vector248>:
.globl vector248
vector248:
  pushl $0
80108197:	6a 00                	push   $0x0
  pushl $248
80108199:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010819e:	e9 33 ef ff ff       	jmp    801070d6 <alltraps>

801081a3 <vector249>:
.globl vector249
vector249:
  pushl $0
801081a3:	6a 00                	push   $0x0
  pushl $249
801081a5:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801081aa:	e9 27 ef ff ff       	jmp    801070d6 <alltraps>

801081af <vector250>:
.globl vector250
vector250:
  pushl $0
801081af:	6a 00                	push   $0x0
  pushl $250
801081b1:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801081b6:	e9 1b ef ff ff       	jmp    801070d6 <alltraps>

801081bb <vector251>:
.globl vector251
vector251:
  pushl $0
801081bb:	6a 00                	push   $0x0
  pushl $251
801081bd:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801081c2:	e9 0f ef ff ff       	jmp    801070d6 <alltraps>

801081c7 <vector252>:
.globl vector252
vector252:
  pushl $0
801081c7:	6a 00                	push   $0x0
  pushl $252
801081c9:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801081ce:	e9 03 ef ff ff       	jmp    801070d6 <alltraps>

801081d3 <vector253>:
.globl vector253
vector253:
  pushl $0
801081d3:	6a 00                	push   $0x0
  pushl $253
801081d5:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801081da:	e9 f7 ee ff ff       	jmp    801070d6 <alltraps>

801081df <vector254>:
.globl vector254
vector254:
  pushl $0
801081df:	6a 00                	push   $0x0
  pushl $254
801081e1:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801081e6:	e9 eb ee ff ff       	jmp    801070d6 <alltraps>

801081eb <vector255>:
.globl vector255
vector255:
  pushl $0
801081eb:	6a 00                	push   $0x0
  pushl $255
801081ed:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801081f2:	e9 df ee ff ff       	jmp    801070d6 <alltraps>

801081f7 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801081f7:	55                   	push   %ebp
801081f8:	89 e5                	mov    %esp,%ebp
801081fa:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801081fd:	8b 45 0c             	mov    0xc(%ebp),%eax
80108200:	83 e8 01             	sub    $0x1,%eax
80108203:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108207:	8b 45 08             	mov    0x8(%ebp),%eax
8010820a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010820e:	8b 45 08             	mov    0x8(%ebp),%eax
80108211:	c1 e8 10             	shr    $0x10,%eax
80108214:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108218:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010821b:	0f 01 10             	lgdtl  (%eax)
}
8010821e:	c9                   	leave  
8010821f:	c3                   	ret    

80108220 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80108220:	55                   	push   %ebp
80108221:	89 e5                	mov    %esp,%ebp
80108223:	83 ec 04             	sub    $0x4,%esp
80108226:	8b 45 08             	mov    0x8(%ebp),%eax
80108229:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010822d:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108231:	0f 00 d8             	ltr    %ax
}
80108234:	c9                   	leave  
80108235:	c3                   	ret    

80108236 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80108236:	55                   	push   %ebp
80108237:	89 e5                	mov    %esp,%ebp
80108239:	83 ec 04             	sub    $0x4,%esp
8010823c:	8b 45 08             	mov    0x8(%ebp),%eax
8010823f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108243:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108247:	8e e8                	mov    %eax,%gs
}
80108249:	c9                   	leave  
8010824a:	c3                   	ret    

8010824b <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
8010824b:	55                   	push   %ebp
8010824c:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010824e:	8b 45 08             	mov    0x8(%ebp),%eax
80108251:	0f 22 d8             	mov    %eax,%cr3
}
80108254:	5d                   	pop    %ebp
80108255:	c3                   	ret    

80108256 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80108256:	55                   	push   %ebp
80108257:	89 e5                	mov    %esp,%ebp
80108259:	8b 45 08             	mov    0x8(%ebp),%eax
8010825c:	05 00 00 00 80       	add    $0x80000000,%eax
80108261:	5d                   	pop    %ebp
80108262:	c3                   	ret    

80108263 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80108263:	55                   	push   %ebp
80108264:	89 e5                	mov    %esp,%ebp
80108266:	8b 45 08             	mov    0x8(%ebp),%eax
80108269:	05 00 00 00 80       	add    $0x80000000,%eax
8010826e:	5d                   	pop    %ebp
8010826f:	c3                   	ret    

80108270 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80108270:	55                   	push   %ebp
80108271:	89 e5                	mov    %esp,%ebp
80108273:	53                   	push   %ebx
80108274:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80108277:	e8 d3 b2 ff ff       	call   8010354f <cpunum>
8010827c:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108282:	05 e0 3b 11 80       	add    $0x80113be0,%eax
80108287:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010828a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828d:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108296:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010829c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010829f:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801082a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a6:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801082aa:	83 e2 f0             	and    $0xfffffff0,%edx
801082ad:	83 ca 0a             	or     $0xa,%edx
801082b0:	88 50 7d             	mov    %dl,0x7d(%eax)
801082b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b6:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801082ba:	83 ca 10             	or     $0x10,%edx
801082bd:	88 50 7d             	mov    %dl,0x7d(%eax)
801082c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082c3:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801082c7:	83 e2 9f             	and    $0xffffff9f,%edx
801082ca:	88 50 7d             	mov    %dl,0x7d(%eax)
801082cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082d0:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801082d4:	83 ca 80             	or     $0xffffff80,%edx
801082d7:	88 50 7d             	mov    %dl,0x7d(%eax)
801082da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082dd:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801082e1:	83 ca 0f             	or     $0xf,%edx
801082e4:	88 50 7e             	mov    %dl,0x7e(%eax)
801082e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ea:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801082ee:	83 e2 ef             	and    $0xffffffef,%edx
801082f1:	88 50 7e             	mov    %dl,0x7e(%eax)
801082f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082f7:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801082fb:	83 e2 df             	and    $0xffffffdf,%edx
801082fe:	88 50 7e             	mov    %dl,0x7e(%eax)
80108301:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108304:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108308:	83 ca 40             	or     $0x40,%edx
8010830b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010830e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108311:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108315:	83 ca 80             	or     $0xffffff80,%edx
80108318:	88 50 7e             	mov    %dl,0x7e(%eax)
8010831b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010831e:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108322:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108325:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010832c:	ff ff 
8010832e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108331:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108338:	00 00 
8010833a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833d:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108344:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108347:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010834e:	83 e2 f0             	and    $0xfffffff0,%edx
80108351:	83 ca 02             	or     $0x2,%edx
80108354:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010835a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835d:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108364:	83 ca 10             	or     $0x10,%edx
80108367:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010836d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108370:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108377:	83 e2 9f             	and    $0xffffff9f,%edx
8010837a:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108380:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108383:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010838a:	83 ca 80             	or     $0xffffff80,%edx
8010838d:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108396:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010839d:	83 ca 0f             	or     $0xf,%edx
801083a0:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a9:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801083b0:	83 e2 ef             	and    $0xffffffef,%edx
801083b3:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083bc:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801083c3:	83 e2 df             	and    $0xffffffdf,%edx
801083c6:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083cf:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801083d6:	83 ca 40             	or     $0x40,%edx
801083d9:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e2:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801083e9:	83 ca 80             	or     $0xffffff80,%edx
801083ec:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801083f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083f5:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801083fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ff:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108406:	ff ff 
80108408:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010840b:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108412:	00 00 
80108414:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108417:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010841e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108421:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108428:	83 e2 f0             	and    $0xfffffff0,%edx
8010842b:	83 ca 0a             	or     $0xa,%edx
8010842e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108434:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108437:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010843e:	83 ca 10             	or     $0x10,%edx
80108441:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108447:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010844a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108451:	83 ca 60             	or     $0x60,%edx
80108454:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010845a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010845d:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108464:	83 ca 80             	or     $0xffffff80,%edx
80108467:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010846d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108470:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108477:	83 ca 0f             	or     $0xf,%edx
8010847a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108480:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108483:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010848a:	83 e2 ef             	and    $0xffffffef,%edx
8010848d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108493:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108496:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010849d:	83 e2 df             	and    $0xffffffdf,%edx
801084a0:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801084a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801084b0:	83 ca 40             	or     $0x40,%edx
801084b3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801084b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084bc:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801084c3:	83 ca 80             	or     $0xffffff80,%edx
801084c6:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801084cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084cf:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801084d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d9:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801084e0:	ff ff 
801084e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e5:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
801084ec:	00 00 
801084ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f1:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801084f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084fb:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108502:	83 e2 f0             	and    $0xfffffff0,%edx
80108505:	83 ca 02             	or     $0x2,%edx
80108508:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010850e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108511:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108518:	83 ca 10             	or     $0x10,%edx
8010851b:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108521:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108524:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010852b:	83 ca 60             	or     $0x60,%edx
8010852e:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108534:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108537:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010853e:	83 ca 80             	or     $0xffffff80,%edx
80108541:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108547:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010854a:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108551:	83 ca 0f             	or     $0xf,%edx
80108554:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010855a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010855d:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108564:	83 e2 ef             	and    $0xffffffef,%edx
80108567:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010856d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108570:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108577:	83 e2 df             	and    $0xffffffdf,%edx
8010857a:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108580:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108583:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010858a:	83 ca 40             	or     $0x40,%edx
8010858d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108593:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108596:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010859d:	83 ca 80             	or     $0xffffff80,%edx
801085a0:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801085a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085a9:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801085b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085b3:	05 b4 00 00 00       	add    $0xb4,%eax
801085b8:	89 c3                	mov    %eax,%ebx
801085ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085bd:	05 b4 00 00 00       	add    $0xb4,%eax
801085c2:	c1 e8 10             	shr    $0x10,%eax
801085c5:	89 c1                	mov    %eax,%ecx
801085c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085ca:	05 b4 00 00 00       	add    $0xb4,%eax
801085cf:	c1 e8 18             	shr    $0x18,%eax
801085d2:	89 c2                	mov    %eax,%edx
801085d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085d7:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
801085de:	00 00 
801085e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e3:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
801085ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085ed:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
801085f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085f6:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801085fd:	83 e1 f0             	and    $0xfffffff0,%ecx
80108600:	83 c9 02             	or     $0x2,%ecx
80108603:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108609:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010860c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108613:	83 c9 10             	or     $0x10,%ecx
80108616:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010861c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108626:	83 e1 9f             	and    $0xffffff9f,%ecx
80108629:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010862f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108632:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108639:	83 c9 80             	or     $0xffffff80,%ecx
8010863c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108642:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108645:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010864c:	83 e1 f0             	and    $0xfffffff0,%ecx
8010864f:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108655:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108658:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010865f:	83 e1 ef             	and    $0xffffffef,%ecx
80108662:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108668:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010866b:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108672:	83 e1 df             	and    $0xffffffdf,%ecx
80108675:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010867b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010867e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108685:	83 c9 40             	or     $0x40,%ecx
80108688:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010868e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108691:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108698:	83 c9 80             	or     $0xffffff80,%ecx
8010869b:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801086a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086a4:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801086aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ad:	83 c0 70             	add    $0x70,%eax
801086b0:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
801086b7:	00 
801086b8:	89 04 24             	mov    %eax,(%esp)
801086bb:	e8 37 fb ff ff       	call   801081f7 <lgdt>
  loadgs(SEG_KCPU << 3);
801086c0:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
801086c7:	e8 6a fb ff ff       	call   80108236 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
801086cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086cf:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
801086d5:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801086dc:	00 00 00 00 
}
801086e0:	83 c4 24             	add    $0x24,%esp
801086e3:	5b                   	pop    %ebx
801086e4:	5d                   	pop    %ebp
801086e5:	c3                   	ret    

801086e6 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801086e6:	55                   	push   %ebp
801086e7:	89 e5                	mov    %esp,%ebp
801086e9:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801086ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801086ef:	c1 e8 16             	shr    $0x16,%eax
801086f2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801086f9:	8b 45 08             	mov    0x8(%ebp),%eax
801086fc:	01 d0                	add    %edx,%eax
801086fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108701:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108704:	8b 00                	mov    (%eax),%eax
80108706:	83 e0 01             	and    $0x1,%eax
80108709:	85 c0                	test   %eax,%eax
8010870b:	74 17                	je     80108724 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
8010870d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108710:	8b 00                	mov    (%eax),%eax
80108712:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108717:	89 04 24             	mov    %eax,(%esp)
8010871a:	e8 44 fb ff ff       	call   80108263 <p2v>
8010871f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108722:	eb 4b                	jmp    8010876f <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108724:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108728:	74 0e                	je     80108738 <walkpgdir+0x52>
8010872a:	e8 8a aa ff ff       	call   801031b9 <kalloc>
8010872f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108732:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108736:	75 07                	jne    8010873f <walkpgdir+0x59>
      return 0;
80108738:	b8 00 00 00 00       	mov    $0x0,%eax
8010873d:	eb 47                	jmp    80108786 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
8010873f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108746:	00 
80108747:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010874e:	00 
8010874f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108752:	89 04 24             	mov    %eax,(%esp)
80108755:	e8 22 d5 ff ff       	call   80105c7c <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
8010875a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010875d:	89 04 24             	mov    %eax,(%esp)
80108760:	e8 f1 fa ff ff       	call   80108256 <v2p>
80108765:	83 c8 07             	or     $0x7,%eax
80108768:	89 c2                	mov    %eax,%edx
8010876a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010876d:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
8010876f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108772:	c1 e8 0c             	shr    $0xc,%eax
80108775:	25 ff 03 00 00       	and    $0x3ff,%eax
8010877a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108781:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108784:	01 d0                	add    %edx,%eax
}
80108786:	c9                   	leave  
80108787:	c3                   	ret    

80108788 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108788:	55                   	push   %ebp
80108789:	89 e5                	mov    %esp,%ebp
8010878b:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
8010878e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108791:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108796:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108799:	8b 55 0c             	mov    0xc(%ebp),%edx
8010879c:	8b 45 10             	mov    0x10(%ebp),%eax
8010879f:	01 d0                	add    %edx,%eax
801087a1:	83 e8 01             	sub    $0x1,%eax
801087a4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801087a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801087ac:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801087b3:	00 
801087b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801087bb:	8b 45 08             	mov    0x8(%ebp),%eax
801087be:	89 04 24             	mov    %eax,(%esp)
801087c1:	e8 20 ff ff ff       	call   801086e6 <walkpgdir>
801087c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
801087c9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801087cd:	75 07                	jne    801087d6 <mappages+0x4e>
      return -1;
801087cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801087d4:	eb 48                	jmp    8010881e <mappages+0x96>
    if(*pte & PTE_P)
801087d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801087d9:	8b 00                	mov    (%eax),%eax
801087db:	83 e0 01             	and    $0x1,%eax
801087de:	85 c0                	test   %eax,%eax
801087e0:	74 0c                	je     801087ee <mappages+0x66>
      panic("remap");
801087e2:	c7 04 24 8c 96 10 80 	movl   $0x8010968c,(%esp)
801087e9:	e8 4c 7d ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
801087ee:	8b 45 18             	mov    0x18(%ebp),%eax
801087f1:	0b 45 14             	or     0x14(%ebp),%eax
801087f4:	83 c8 01             	or     $0x1,%eax
801087f7:	89 c2                	mov    %eax,%edx
801087f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801087fc:	89 10                	mov    %edx,(%eax)
    if(a == last)
801087fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108801:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108804:	75 08                	jne    8010880e <mappages+0x86>
      break;
80108806:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108807:	b8 00 00 00 00       	mov    $0x0,%eax
8010880c:	eb 10                	jmp    8010881e <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
8010880e:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108815:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
8010881c:	eb 8e                	jmp    801087ac <mappages+0x24>
  return 0;
}
8010881e:	c9                   	leave  
8010881f:	c3                   	ret    

80108820 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80108820:	55                   	push   %ebp
80108821:	89 e5                	mov    %esp,%ebp
80108823:	53                   	push   %ebx
80108824:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108827:	e8 8d a9 ff ff       	call   801031b9 <kalloc>
8010882c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010882f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108833:	75 0a                	jne    8010883f <setupkvm+0x1f>
    return 0;
80108835:	b8 00 00 00 00       	mov    $0x0,%eax
8010883a:	e9 98 00 00 00       	jmp    801088d7 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
8010883f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108846:	00 
80108847:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010884e:	00 
8010884f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108852:	89 04 24             	mov    %eax,(%esp)
80108855:	e8 22 d4 ff ff       	call   80105c7c <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
8010885a:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108861:	e8 fd f9 ff ff       	call   80108263 <p2v>
80108866:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
8010886b:	76 0c                	jbe    80108879 <setupkvm+0x59>
    panic("PHYSTOP too high");
8010886d:	c7 04 24 92 96 10 80 	movl   $0x80109692,(%esp)
80108874:	e8 c1 7c ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108879:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108880:	eb 49                	jmp    801088cb <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108882:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108885:	8b 48 0c             	mov    0xc(%eax),%ecx
80108888:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010888b:	8b 50 04             	mov    0x4(%eax),%edx
8010888e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108891:	8b 58 08             	mov    0x8(%eax),%ebx
80108894:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108897:	8b 40 04             	mov    0x4(%eax),%eax
8010889a:	29 c3                	sub    %eax,%ebx
8010889c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010889f:	8b 00                	mov    (%eax),%eax
801088a1:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801088a5:	89 54 24 0c          	mov    %edx,0xc(%esp)
801088a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801088ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801088b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088b4:	89 04 24             	mov    %eax,(%esp)
801088b7:	e8 cc fe ff ff       	call   80108788 <mappages>
801088bc:	85 c0                	test   %eax,%eax
801088be:	79 07                	jns    801088c7 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
801088c0:	b8 00 00 00 00       	mov    $0x0,%eax
801088c5:	eb 10                	jmp    801088d7 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801088c7:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801088cb:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
801088d2:	72 ae                	jb     80108882 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
801088d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801088d7:	83 c4 34             	add    $0x34,%esp
801088da:	5b                   	pop    %ebx
801088db:	5d                   	pop    %ebp
801088dc:	c3                   	ret    

801088dd <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
801088dd:	55                   	push   %ebp
801088de:	89 e5                	mov    %esp,%ebp
801088e0:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801088e3:	e8 38 ff ff ff       	call   80108820 <setupkvm>
801088e8:	a3 f8 72 11 80       	mov    %eax,0x801172f8
  switchkvm();
801088ed:	e8 02 00 00 00       	call   801088f4 <switchkvm>
}
801088f2:	c9                   	leave  
801088f3:	c3                   	ret    

801088f4 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801088f4:	55                   	push   %ebp
801088f5:	89 e5                	mov    %esp,%ebp
801088f7:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801088fa:	a1 f8 72 11 80       	mov    0x801172f8,%eax
801088ff:	89 04 24             	mov    %eax,(%esp)
80108902:	e8 4f f9 ff ff       	call   80108256 <v2p>
80108907:	89 04 24             	mov    %eax,(%esp)
8010890a:	e8 3c f9 ff ff       	call   8010824b <lcr3>
}
8010890f:	c9                   	leave  
80108910:	c3                   	ret    

80108911 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108911:	55                   	push   %ebp
80108912:	89 e5                	mov    %esp,%ebp
80108914:	53                   	push   %ebx
80108915:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108918:	e8 5f d2 ff ff       	call   80105b7c <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
8010891d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108923:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010892a:	83 c2 08             	add    $0x8,%edx
8010892d:	89 d3                	mov    %edx,%ebx
8010892f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108936:	83 c2 08             	add    $0x8,%edx
80108939:	c1 ea 10             	shr    $0x10,%edx
8010893c:	89 d1                	mov    %edx,%ecx
8010893e:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108945:	83 c2 08             	add    $0x8,%edx
80108948:	c1 ea 18             	shr    $0x18,%edx
8010894b:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108952:	67 00 
80108954:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
8010895b:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108961:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108968:	83 e1 f0             	and    $0xfffffff0,%ecx
8010896b:	83 c9 09             	or     $0x9,%ecx
8010896e:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108974:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010897b:	83 c9 10             	or     $0x10,%ecx
8010897e:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108984:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010898b:	83 e1 9f             	and    $0xffffff9f,%ecx
8010898e:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108994:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010899b:	83 c9 80             	or     $0xffffff80,%ecx
8010899e:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801089a4:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089ab:	83 e1 f0             	and    $0xfffffff0,%ecx
801089ae:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089b4:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089bb:	83 e1 ef             	and    $0xffffffef,%ecx
801089be:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089c4:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089cb:	83 e1 df             	and    $0xffffffdf,%ecx
801089ce:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089d4:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089db:	83 c9 40             	or     $0x40,%ecx
801089de:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089e4:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801089eb:	83 e1 7f             	and    $0x7f,%ecx
801089ee:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801089f4:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801089fa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108a00:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108a07:	83 e2 ef             	and    $0xffffffef,%edx
80108a0a:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108a10:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108a16:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108a1c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108a22:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108a29:	8b 52 08             	mov    0x8(%edx),%edx
80108a2c:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108a32:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108a35:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108a3c:	e8 df f7 ff ff       	call   80108220 <ltr>
  if(p->pgdir == 0)
80108a41:	8b 45 08             	mov    0x8(%ebp),%eax
80108a44:	8b 40 04             	mov    0x4(%eax),%eax
80108a47:	85 c0                	test   %eax,%eax
80108a49:	75 0c                	jne    80108a57 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108a4b:	c7 04 24 a3 96 10 80 	movl   $0x801096a3,(%esp)
80108a52:	e8 e3 7a ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108a57:	8b 45 08             	mov    0x8(%ebp),%eax
80108a5a:	8b 40 04             	mov    0x4(%eax),%eax
80108a5d:	89 04 24             	mov    %eax,(%esp)
80108a60:	e8 f1 f7 ff ff       	call   80108256 <v2p>
80108a65:	89 04 24             	mov    %eax,(%esp)
80108a68:	e8 de f7 ff ff       	call   8010824b <lcr3>
  popcli();
80108a6d:	e8 4e d1 ff ff       	call   80105bc0 <popcli>
}
80108a72:	83 c4 14             	add    $0x14,%esp
80108a75:	5b                   	pop    %ebx
80108a76:	5d                   	pop    %ebp
80108a77:	c3                   	ret    

80108a78 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108a78:	55                   	push   %ebp
80108a79:	89 e5                	mov    %esp,%ebp
80108a7b:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108a7e:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108a85:	76 0c                	jbe    80108a93 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108a87:	c7 04 24 b7 96 10 80 	movl   $0x801096b7,(%esp)
80108a8e:	e8 a7 7a ff ff       	call   8010053a <panic>
  mem = kalloc();
80108a93:	e8 21 a7 ff ff       	call   801031b9 <kalloc>
80108a98:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108a9b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108aa2:	00 
80108aa3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108aaa:	00 
80108aab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aae:	89 04 24             	mov    %eax,(%esp)
80108ab1:	e8 c6 d1 ff ff       	call   80105c7c <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ab9:	89 04 24             	mov    %eax,(%esp)
80108abc:	e8 95 f7 ff ff       	call   80108256 <v2p>
80108ac1:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108ac8:	00 
80108ac9:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108acd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ad4:	00 
80108ad5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108adc:	00 
80108add:	8b 45 08             	mov    0x8(%ebp),%eax
80108ae0:	89 04 24             	mov    %eax,(%esp)
80108ae3:	e8 a0 fc ff ff       	call   80108788 <mappages>
  memmove(mem, init, sz);
80108ae8:	8b 45 10             	mov    0x10(%ebp),%eax
80108aeb:	89 44 24 08          	mov    %eax,0x8(%esp)
80108aef:	8b 45 0c             	mov    0xc(%ebp),%eax
80108af2:	89 44 24 04          	mov    %eax,0x4(%esp)
80108af6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108af9:	89 04 24             	mov    %eax,(%esp)
80108afc:	e8 4a d2 ff ff       	call   80105d4b <memmove>
}
80108b01:	c9                   	leave  
80108b02:	c3                   	ret    

80108b03 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108b03:	55                   	push   %ebp
80108b04:	89 e5                	mov    %esp,%ebp
80108b06:	53                   	push   %ebx
80108b07:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108b0a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b0d:	25 ff 0f 00 00       	and    $0xfff,%eax
80108b12:	85 c0                	test   %eax,%eax
80108b14:	74 0c                	je     80108b22 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108b16:	c7 04 24 d4 96 10 80 	movl   $0x801096d4,(%esp)
80108b1d:	e8 18 7a ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108b22:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108b29:	e9 a9 00 00 00       	jmp    80108bd7 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108b2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b31:	8b 55 0c             	mov    0xc(%ebp),%edx
80108b34:	01 d0                	add    %edx,%eax
80108b36:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108b3d:	00 
80108b3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b42:	8b 45 08             	mov    0x8(%ebp),%eax
80108b45:	89 04 24             	mov    %eax,(%esp)
80108b48:	e8 99 fb ff ff       	call   801086e6 <walkpgdir>
80108b4d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108b50:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108b54:	75 0c                	jne    80108b62 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108b56:	c7 04 24 f7 96 10 80 	movl   $0x801096f7,(%esp)
80108b5d:	e8 d8 79 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108b62:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108b65:	8b 00                	mov    (%eax),%eax
80108b67:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b6c:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108b6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b72:	8b 55 18             	mov    0x18(%ebp),%edx
80108b75:	29 c2                	sub    %eax,%edx
80108b77:	89 d0                	mov    %edx,%eax
80108b79:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108b7e:	77 0f                	ja     80108b8f <loaduvm+0x8c>
      n = sz - i;
80108b80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b83:	8b 55 18             	mov    0x18(%ebp),%edx
80108b86:	29 c2                	sub    %eax,%edx
80108b88:	89 d0                	mov    %edx,%eax
80108b8a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108b8d:	eb 07                	jmp    80108b96 <loaduvm+0x93>
    else
      n = PGSIZE;
80108b8f:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108b96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b99:	8b 55 14             	mov    0x14(%ebp),%edx
80108b9c:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108b9f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ba2:	89 04 24             	mov    %eax,(%esp)
80108ba5:	e8 b9 f6 ff ff       	call   80108263 <p2v>
80108baa:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108bad:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108bb1:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108bb5:	89 44 24 04          	mov    %eax,0x4(%esp)
80108bb9:	8b 45 10             	mov    0x10(%ebp),%eax
80108bbc:	89 04 24             	mov    %eax,(%esp)
80108bbf:	e8 44 98 ff ff       	call   80102408 <readi>
80108bc4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108bc7:	74 07                	je     80108bd0 <loaduvm+0xcd>
      return -1;
80108bc9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108bce:	eb 18                	jmp    80108be8 <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108bd0:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bda:	3b 45 18             	cmp    0x18(%ebp),%eax
80108bdd:	0f 82 4b ff ff ff    	jb     80108b2e <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108be3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108be8:	83 c4 24             	add    $0x24,%esp
80108beb:	5b                   	pop    %ebx
80108bec:	5d                   	pop    %ebp
80108bed:	c3                   	ret    

80108bee <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108bee:	55                   	push   %ebp
80108bef:	89 e5                	mov    %esp,%ebp
80108bf1:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108bf4:	8b 45 10             	mov    0x10(%ebp),%eax
80108bf7:	85 c0                	test   %eax,%eax
80108bf9:	79 0a                	jns    80108c05 <allocuvm+0x17>
    return 0;
80108bfb:	b8 00 00 00 00       	mov    $0x0,%eax
80108c00:	e9 c1 00 00 00       	jmp    80108cc6 <allocuvm+0xd8>
  if(newsz < oldsz)
80108c05:	8b 45 10             	mov    0x10(%ebp),%eax
80108c08:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108c0b:	73 08                	jae    80108c15 <allocuvm+0x27>
    return oldsz;
80108c0d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c10:	e9 b1 00 00 00       	jmp    80108cc6 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108c15:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c18:	05 ff 0f 00 00       	add    $0xfff,%eax
80108c1d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c22:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108c25:	e9 8d 00 00 00       	jmp    80108cb7 <allocuvm+0xc9>
    mem = kalloc();
80108c2a:	e8 8a a5 ff ff       	call   801031b9 <kalloc>
80108c2f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108c32:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108c36:	75 2c                	jne    80108c64 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108c38:	c7 04 24 15 97 10 80 	movl   $0x80109715,(%esp)
80108c3f:	e8 5c 77 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108c44:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c47:	89 44 24 08          	mov    %eax,0x8(%esp)
80108c4b:	8b 45 10             	mov    0x10(%ebp),%eax
80108c4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c52:	8b 45 08             	mov    0x8(%ebp),%eax
80108c55:	89 04 24             	mov    %eax,(%esp)
80108c58:	e8 6b 00 00 00       	call   80108cc8 <deallocuvm>
      return 0;
80108c5d:	b8 00 00 00 00       	mov    $0x0,%eax
80108c62:	eb 62                	jmp    80108cc6 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108c64:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c6b:	00 
80108c6c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c73:	00 
80108c74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c77:	89 04 24             	mov    %eax,(%esp)
80108c7a:	e8 fd cf ff ff       	call   80105c7c <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108c7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c82:	89 04 24             	mov    %eax,(%esp)
80108c85:	e8 cc f5 ff ff       	call   80108256 <v2p>
80108c8a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108c8d:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108c94:	00 
80108c95:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108c99:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ca0:	00 
80108ca1:	89 54 24 04          	mov    %edx,0x4(%esp)
80108ca5:	8b 45 08             	mov    0x8(%ebp),%eax
80108ca8:	89 04 24             	mov    %eax,(%esp)
80108cab:	e8 d8 fa ff ff       	call   80108788 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108cb0:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108cb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cba:	3b 45 10             	cmp    0x10(%ebp),%eax
80108cbd:	0f 82 67 ff ff ff    	jb     80108c2a <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108cc3:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108cc6:	c9                   	leave  
80108cc7:	c3                   	ret    

80108cc8 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108cc8:	55                   	push   %ebp
80108cc9:	89 e5                	mov    %esp,%ebp
80108ccb:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108cce:	8b 45 10             	mov    0x10(%ebp),%eax
80108cd1:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108cd4:	72 08                	jb     80108cde <deallocuvm+0x16>
    return oldsz;
80108cd6:	8b 45 0c             	mov    0xc(%ebp),%eax
80108cd9:	e9 a4 00 00 00       	jmp    80108d82 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108cde:	8b 45 10             	mov    0x10(%ebp),%eax
80108ce1:	05 ff 0f 00 00       	add    $0xfff,%eax
80108ce6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ceb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108cee:	e9 80 00 00 00       	jmp    80108d73 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108cf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cf6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108cfd:	00 
80108cfe:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d02:	8b 45 08             	mov    0x8(%ebp),%eax
80108d05:	89 04 24             	mov    %eax,(%esp)
80108d08:	e8 d9 f9 ff ff       	call   801086e6 <walkpgdir>
80108d0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108d10:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108d14:	75 09                	jne    80108d1f <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108d16:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108d1d:	eb 4d                	jmp    80108d6c <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108d1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d22:	8b 00                	mov    (%eax),%eax
80108d24:	83 e0 01             	and    $0x1,%eax
80108d27:	85 c0                	test   %eax,%eax
80108d29:	74 41                	je     80108d6c <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108d2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d2e:	8b 00                	mov    (%eax),%eax
80108d30:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d35:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108d38:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d3c:	75 0c                	jne    80108d4a <deallocuvm+0x82>
        panic("kfree");
80108d3e:	c7 04 24 2d 97 10 80 	movl   $0x8010972d,(%esp)
80108d45:	e8 f0 77 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
80108d4a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d4d:	89 04 24             	mov    %eax,(%esp)
80108d50:	e8 0e f5 ff ff       	call   80108263 <p2v>
80108d55:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108d58:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d5b:	89 04 24             	mov    %eax,(%esp)
80108d5e:	e8 bd a3 ff ff       	call   80103120 <kfree>
      *pte = 0;
80108d63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d66:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108d6c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108d73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d76:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108d79:	0f 82 74 ff ff ff    	jb     80108cf3 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108d7f:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108d82:	c9                   	leave  
80108d83:	c3                   	ret    

80108d84 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108d84:	55                   	push   %ebp
80108d85:	89 e5                	mov    %esp,%ebp
80108d87:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108d8a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108d8e:	75 0c                	jne    80108d9c <freevm+0x18>
    panic("freevm: no pgdir");
80108d90:	c7 04 24 33 97 10 80 	movl   $0x80109733,(%esp)
80108d97:	e8 9e 77 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108d9c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108da3:	00 
80108da4:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108dab:	80 
80108dac:	8b 45 08             	mov    0x8(%ebp),%eax
80108daf:	89 04 24             	mov    %eax,(%esp)
80108db2:	e8 11 ff ff ff       	call   80108cc8 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108db7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108dbe:	eb 48                	jmp    80108e08 <freevm+0x84>
    if(pgdir[i] & PTE_P){
80108dc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dc3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108dca:	8b 45 08             	mov    0x8(%ebp),%eax
80108dcd:	01 d0                	add    %edx,%eax
80108dcf:	8b 00                	mov    (%eax),%eax
80108dd1:	83 e0 01             	and    $0x1,%eax
80108dd4:	85 c0                	test   %eax,%eax
80108dd6:	74 2c                	je     80108e04 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108dd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ddb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108de2:	8b 45 08             	mov    0x8(%ebp),%eax
80108de5:	01 d0                	add    %edx,%eax
80108de7:	8b 00                	mov    (%eax),%eax
80108de9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108dee:	89 04 24             	mov    %eax,(%esp)
80108df1:	e8 6d f4 ff ff       	call   80108263 <p2v>
80108df6:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108df9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108dfc:	89 04 24             	mov    %eax,(%esp)
80108dff:	e8 1c a3 ff ff       	call   80103120 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108e04:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108e08:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108e0f:	76 af                	jbe    80108dc0 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108e11:	8b 45 08             	mov    0x8(%ebp),%eax
80108e14:	89 04 24             	mov    %eax,(%esp)
80108e17:	e8 04 a3 ff ff       	call   80103120 <kfree>
}
80108e1c:	c9                   	leave  
80108e1d:	c3                   	ret    

80108e1e <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108e1e:	55                   	push   %ebp
80108e1f:	89 e5                	mov    %esp,%ebp
80108e21:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108e24:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e2b:	00 
80108e2c:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e33:	8b 45 08             	mov    0x8(%ebp),%eax
80108e36:	89 04 24             	mov    %eax,(%esp)
80108e39:	e8 a8 f8 ff ff       	call   801086e6 <walkpgdir>
80108e3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108e41:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108e45:	75 0c                	jne    80108e53 <clearpteu+0x35>
    panic("clearpteu");
80108e47:	c7 04 24 44 97 10 80 	movl   $0x80109744,(%esp)
80108e4e:	e8 e7 76 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108e53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e56:	8b 00                	mov    (%eax),%eax
80108e58:	83 e0 fb             	and    $0xfffffffb,%eax
80108e5b:	89 c2                	mov    %eax,%edx
80108e5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e60:	89 10                	mov    %edx,(%eax)
}
80108e62:	c9                   	leave  
80108e63:	c3                   	ret    

80108e64 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108e64:	55                   	push   %ebp
80108e65:	89 e5                	mov    %esp,%ebp
80108e67:	53                   	push   %ebx
80108e68:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108e6b:	e8 b0 f9 ff ff       	call   80108820 <setupkvm>
80108e70:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108e73:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108e77:	75 0a                	jne    80108e83 <copyuvm+0x1f>
    return 0;
80108e79:	b8 00 00 00 00       	mov    $0x0,%eax
80108e7e:	e9 fd 00 00 00       	jmp    80108f80 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
80108e83:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e8a:	e9 d0 00 00 00       	jmp    80108f5f <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108e8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e92:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e99:	00 
80108e9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e9e:	8b 45 08             	mov    0x8(%ebp),%eax
80108ea1:	89 04 24             	mov    %eax,(%esp)
80108ea4:	e8 3d f8 ff ff       	call   801086e6 <walkpgdir>
80108ea9:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108eac:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108eb0:	75 0c                	jne    80108ebe <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80108eb2:	c7 04 24 4e 97 10 80 	movl   $0x8010974e,(%esp)
80108eb9:	e8 7c 76 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80108ebe:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ec1:	8b 00                	mov    (%eax),%eax
80108ec3:	83 e0 01             	and    $0x1,%eax
80108ec6:	85 c0                	test   %eax,%eax
80108ec8:	75 0c                	jne    80108ed6 <copyuvm+0x72>
      panic("copyuvm: page not present");
80108eca:	c7 04 24 68 97 10 80 	movl   $0x80109768,(%esp)
80108ed1:	e8 64 76 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108ed6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ed9:	8b 00                	mov    (%eax),%eax
80108edb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ee0:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108ee3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ee6:	8b 00                	mov    (%eax),%eax
80108ee8:	25 ff 0f 00 00       	and    $0xfff,%eax
80108eed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80108ef0:	e8 c4 a2 ff ff       	call   801031b9 <kalloc>
80108ef5:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108ef8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108efc:	75 02                	jne    80108f00 <copyuvm+0x9c>
      goto bad;
80108efe:	eb 70                	jmp    80108f70 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108f00:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f03:	89 04 24             	mov    %eax,(%esp)
80108f06:	e8 58 f3 ff ff       	call   80108263 <p2v>
80108f0b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f12:	00 
80108f13:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f17:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108f1a:	89 04 24             	mov    %eax,(%esp)
80108f1d:	e8 29 ce ff ff       	call   80105d4b <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80108f22:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80108f25:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108f28:	89 04 24             	mov    %eax,(%esp)
80108f2b:	e8 26 f3 ff ff       	call   80108256 <v2p>
80108f30:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108f33:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80108f37:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108f3b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f42:	00 
80108f43:	89 54 24 04          	mov    %edx,0x4(%esp)
80108f47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f4a:	89 04 24             	mov    %eax,(%esp)
80108f4d:	e8 36 f8 ff ff       	call   80108788 <mappages>
80108f52:	85 c0                	test   %eax,%eax
80108f54:	79 02                	jns    80108f58 <copyuvm+0xf4>
      goto bad;
80108f56:	eb 18                	jmp    80108f70 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108f58:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108f5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f62:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108f65:	0f 82 24 ff ff ff    	jb     80108e8f <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80108f6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f6e:	eb 10                	jmp    80108f80 <copyuvm+0x11c>

bad:
  freevm(d);
80108f70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f73:	89 04 24             	mov    %eax,(%esp)
80108f76:	e8 09 fe ff ff       	call   80108d84 <freevm>
  return 0;
80108f7b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108f80:	83 c4 44             	add    $0x44,%esp
80108f83:	5b                   	pop    %ebx
80108f84:	5d                   	pop    %ebp
80108f85:	c3                   	ret    

80108f86 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108f86:	55                   	push   %ebp
80108f87:	89 e5                	mov    %esp,%ebp
80108f89:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108f8c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f93:	00 
80108f94:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f97:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f9b:	8b 45 08             	mov    0x8(%ebp),%eax
80108f9e:	89 04 24             	mov    %eax,(%esp)
80108fa1:	e8 40 f7 ff ff       	call   801086e6 <walkpgdir>
80108fa6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108fa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fac:	8b 00                	mov    (%eax),%eax
80108fae:	83 e0 01             	and    $0x1,%eax
80108fb1:	85 c0                	test   %eax,%eax
80108fb3:	75 07                	jne    80108fbc <uva2ka+0x36>
    return 0;
80108fb5:	b8 00 00 00 00       	mov    $0x0,%eax
80108fba:	eb 25                	jmp    80108fe1 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108fbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fbf:	8b 00                	mov    (%eax),%eax
80108fc1:	83 e0 04             	and    $0x4,%eax
80108fc4:	85 c0                	test   %eax,%eax
80108fc6:	75 07                	jne    80108fcf <uva2ka+0x49>
    return 0;
80108fc8:	b8 00 00 00 00       	mov    $0x0,%eax
80108fcd:	eb 12                	jmp    80108fe1 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108fcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fd2:	8b 00                	mov    (%eax),%eax
80108fd4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108fd9:	89 04 24             	mov    %eax,(%esp)
80108fdc:	e8 82 f2 ff ff       	call   80108263 <p2v>
}
80108fe1:	c9                   	leave  
80108fe2:	c3                   	ret    

80108fe3 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108fe3:	55                   	push   %ebp
80108fe4:	89 e5                	mov    %esp,%ebp
80108fe6:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108fe9:	8b 45 10             	mov    0x10(%ebp),%eax
80108fec:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108fef:	e9 87 00 00 00       	jmp    8010907b <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
80108ff4:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ff7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ffc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108fff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109002:	89 44 24 04          	mov    %eax,0x4(%esp)
80109006:	8b 45 08             	mov    0x8(%ebp),%eax
80109009:	89 04 24             	mov    %eax,(%esp)
8010900c:	e8 75 ff ff ff       	call   80108f86 <uva2ka>
80109011:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109014:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109018:	75 07                	jne    80109021 <copyout+0x3e>
      return -1;
8010901a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010901f:	eb 69                	jmp    8010908a <copyout+0xa7>
    n = PGSIZE - (va - va0);
80109021:	8b 45 0c             	mov    0xc(%ebp),%eax
80109024:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109027:	29 c2                	sub    %eax,%edx
80109029:	89 d0                	mov    %edx,%eax
8010902b:	05 00 10 00 00       	add    $0x1000,%eax
80109030:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109033:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109036:	3b 45 14             	cmp    0x14(%ebp),%eax
80109039:	76 06                	jbe    80109041 <copyout+0x5e>
      n = len;
8010903b:	8b 45 14             	mov    0x14(%ebp),%eax
8010903e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109041:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109044:	8b 55 0c             	mov    0xc(%ebp),%edx
80109047:	29 c2                	sub    %eax,%edx
80109049:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010904c:	01 c2                	add    %eax,%edx
8010904e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109051:	89 44 24 08          	mov    %eax,0x8(%esp)
80109055:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109058:	89 44 24 04          	mov    %eax,0x4(%esp)
8010905c:	89 14 24             	mov    %edx,(%esp)
8010905f:	e8 e7 cc ff ff       	call   80105d4b <memmove>
    len -= n;
80109064:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109067:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010906a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010906d:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80109070:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109073:	05 00 10 00 00       	add    $0x1000,%eax
80109078:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010907b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010907f:	0f 85 6f ff ff ff    	jne    80108ff4 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80109085:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010908a:	c9                   	leave  
8010908b:	c3                   	ret    
