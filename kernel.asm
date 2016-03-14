
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
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
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
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 50 3c 10 80       	mov    $0x80103c50,%eax
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
8010003a:	c7 44 24 04 fc 88 10 	movl   $0x801088fc,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 c2 52 00 00       	call   80105310 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 05 11 80 64 	movl   $0x80110564,0x80110570
80100055:	05 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 05 11 80 64 	movl   $0x80110564,0x80110574
8010005f:	05 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 05 11 80       	mov    0x80110574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 05 11 80       	mov    %eax,0x80110574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
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
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 6f 52 00 00       	call   80105331 <acquire>

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 05 11 80       	mov    0x80110574,%eax
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
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 8a 52 00 00       	call   80105393 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 43 4f 00 00       	call   80105067 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 05 11 80       	mov    0x80110570,%eax
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
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 12 52 00 00       	call   80105393 <release>
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
8010018f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 03 89 10 80 	movl   $0x80108903,(%esp)
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
801001d3:	e8 0c 2b 00 00       	call   80102ce4 <iderw>
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
801001ef:	c7 04 24 14 89 10 80 	movl   $0x80108914,(%esp)
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
80100210:	e8 cf 2a 00 00       	call   80102ce4 <iderw>
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
80100229:	c7 04 24 1b 89 10 80 	movl   $0x8010891b,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 f0 50 00 00       	call   80105331 <acquire>

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
8010025f:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 05 11 80       	mov    0x80110574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 05 11 80       	mov    %eax,0x80110574

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
8010029d:	e8 9e 4e 00 00       	call   80105140 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 e5 50 00 00       	call   80105393 <release>
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
80100340:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
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
801003a6:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bb:	e8 71 4f 00 00       	call   80105331 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 22 89 10 80 	movl   $0x80108922,(%esp)
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
801004b0:	c7 45 ec 2b 89 10 80 	movl   $0x8010892b,-0x14(%ebp)
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
8010052c:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100533:	e8 5b 4e 00 00       	call   80105393 <release>
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
80100545:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 32 89 10 80 	movl   $0x80108932,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 41 89 10 80 	movl   $0x80108941,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 4e 4e 00 00       	call   801053e2 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 43 89 10 80 	movl   $0x80108943,(%esp)
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
801005be:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
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
801006d7:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
801006dc:	85 c0                	test   %eax,%eax
801006de:	0f 8e c8 00 00 00    	jle    801007ac <cgaputc+0x17e>
	for ( i = pos; i<=left_strides+pos; ++i)
801006e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801006ea:	eb 25                	jmp    80100711 <cgaputc+0xe3>
	  crt[i]=crt[i+1];
801006ec:	a1 00 90 10 80       	mov    0x80109000,%eax
801006f1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801006f4:	01 d2                	add    %edx,%edx
801006f6:	01 c2                	add    %eax,%edx
801006f8:	a1 00 90 10 80       	mov    0x80109000,%eax
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
80100711:	8b 15 f8 b5 10 80    	mov    0x8010b5f8,%edx
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
8010074a:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
8010074f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      while(i-->0){
80100752:	eb 2b                	jmp    8010077f <cgaputc+0x151>
	crt[pos + i + 1]=crt[pos + i];
80100754:	a1 00 90 10 80       	mov    0x80109000,%eax
80100759:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010075c:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010075f:	01 ca                	add    %ecx,%edx
80100761:	83 c2 01             	add    $0x1,%edx
80100764:	01 d2                	add    %edx,%edx
80100766:	01 c2                	add    %eax,%edx
80100768:	a1 00 90 10 80       	mov    0x80109000,%eax
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
8010078c:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
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
801007bb:	c7 04 24 47 89 10 80 	movl   $0x80108947,(%esp)
801007c2:	e8 73 fd ff ff       	call   8010053a <panic>
  
  if((pos/80) >= 24){  // Scroll up.
801007c7:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
801007ce:	7e 53                	jle    80100823 <cgaputc+0x1f5>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801007d0:	a1 00 90 10 80       	mov    0x80109000,%eax
801007d5:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
801007db:	a1 00 90 10 80       	mov    0x80109000,%eax
801007e0:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801007e7:	00 
801007e8:	89 54 24 04          	mov    %edx,0x4(%esp)
801007ec:	89 04 24             	mov    %eax,(%esp)
801007ef:	e8 60 4e 00 00       	call   80105654 <memmove>
    pos -= 80;
801007f4:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801007f8:	b8 80 07 00 00       	mov    $0x780,%eax
801007fd:	2b 45 f4             	sub    -0xc(%ebp),%eax
80100800:	8d 14 00             	lea    (%eax,%eax,1),%edx
80100803:	a1 00 90 10 80       	mov    0x80109000,%eax
80100808:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010080b:	01 c9                	add    %ecx,%ecx
8010080d:	01 c8                	add    %ecx,%eax
8010080f:	89 54 24 08          	mov    %edx,0x8(%esp)
80100813:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010081a:	00 
8010081b:	89 04 24             	mov    %eax,(%esp)
8010081e:	e8 62 4d 00 00       	call   80105585 <memset>
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
80100883:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100888:	85 c0                	test   %eax,%eax
8010088a:	7e 24                	jle    801008b0 <cgaputc+0x282>
    crt[pos]= crt[pos] | 0x0700;
8010088c:	a1 00 90 10 80       	mov    0x80109000,%eax
80100891:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100894:	01 d2                	add    %edx,%edx
80100896:	01 d0                	add    %edx,%eax
80100898:	8b 15 00 90 10 80    	mov    0x80109000,%edx
8010089e:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801008a1:	01 c9                	add    %ecx,%ecx
801008a3:	01 ca                	add    %ecx,%edx
801008a5:	0f b7 12             	movzwl (%edx),%edx
801008a8:	80 ce 07             	or     $0x7,%dh
801008ab:	66 89 10             	mov    %dx,(%eax)
801008ae:	eb 11                	jmp    801008c1 <cgaputc+0x293>
  else
    crt[pos] = ' ' | 0x0700;
801008b0:	a1 00 90 10 80       	mov    0x80109000,%eax
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
801008cd:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
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
801008ed:	e8 4a 66 00 00       	call   80106f3c <uartputc>
801008f2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801008f9:	e8 3e 66 00 00       	call   80106f3c <uartputc>
801008fe:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100905:	e8 32 66 00 00       	call   80106f3c <uartputc>
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
80100924:	e8 13 66 00 00       	call   80106f3c <uartputc>
  cgaputc(c);
80100929:	8b 45 08             	mov    0x8(%ebp),%eax
8010092c:	89 04 24             	mov    %eax,(%esp)
8010092f:	e8 fa fc ff ff       	call   8010062e <cgaputc>
}
80100934:	c9                   	leave  
80100935:	c3                   	ret    

80100936 <add_to_history>:
  int lastcommand;
} history;

//adds a string from start to end to history
void
add_to_history(char * start, char * end){
80100936:	55                   	push   %ebp
80100937:	89 e5                	mov    %esp,%ebp
80100939:	83 ec 28             	sub    $0x28,%esp
 int i;
 if (history.lastcommand == MAX_HISTORY){
8010093c:	a1 60 10 11 80       	mov    0x80111060,%eax
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
8010095a:	8b 04 85 20 08 11 80 	mov    -0x7feef7e0(,%eax,4),%eax
void
add_to_history(char * start, char * end){
 int i;
 if (history.lastcommand == MAX_HISTORY){
  for(i=0; i<MAX_HISTORY-1; ++i)
    memmove(history.commands[i],history.commands[i+1],
80100961:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100964:	83 c2 01             	add    $0x1,%edx
80100967:	c1 e2 07             	shl    $0x7,%edx
8010096a:	8d 8a 20 08 11 80    	lea    -0x7feef7e0(%edx),%ecx
80100970:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100973:	c1 e2 07             	shl    $0x7,%edx
80100976:	81 c2 20 08 11 80    	add    $0x80110820,%edx
8010097c:	89 44 24 08          	mov    %eax,0x8(%esp)
80100980:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80100984:	89 14 24             	mov    %edx,(%esp)
80100987:	e8 c8 4c 00 00       	call   80105654 <memmove>
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
80100996:	a1 60 10 11 80       	mov    0x80111060,%eax
8010099b:	83 e8 01             	sub    $0x1,%eax
8010099e:	a3 60 10 11 80       	mov    %eax,0x80111060
 }
 history.command_sizes[history.lastcommand] = end - start;
801009a3:	a1 60 10 11 80       	mov    0x80111060,%eax
801009a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801009ab:	8b 55 08             	mov    0x8(%ebp),%edx
801009ae:	29 d1                	sub    %edx,%ecx
801009b0:	89 ca                	mov    %ecx,%edx
801009b2:	05 00 02 00 00       	add    $0x200,%eax
801009b7:	89 14 85 20 08 11 80 	mov    %edx,-0x7feef7e0(,%eax,4)
 memmove(history.commands[history.lastcommand++],start,end-start);
801009be:	8b 55 0c             	mov    0xc(%ebp),%edx
801009c1:	8b 45 08             	mov    0x8(%ebp),%eax
801009c4:	29 c2                	sub    %eax,%edx
801009c6:	89 d0                	mov    %edx,%eax
801009c8:	89 c2                	mov    %eax,%edx
801009ca:	a1 60 10 11 80       	mov    0x80111060,%eax
801009cf:	8d 48 01             	lea    0x1(%eax),%ecx
801009d2:	89 0d 60 10 11 80    	mov    %ecx,0x80111060
801009d8:	c1 e0 07             	shl    $0x7,%eax
801009db:	8d 88 20 08 11 80    	lea    -0x7feef7e0(%eax),%ecx
801009e1:	89 54 24 08          	mov    %edx,0x8(%esp)
801009e5:	8b 45 08             	mov    0x8(%ebp),%eax
801009e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801009ec:	89 0c 24             	mov    %ecx,(%esp)
801009ef:	e8 60 4c 00 00       	call   80105654 <memmove>
}
801009f4:	c9                   	leave  
801009f5:	c3                   	ret    

801009f6 <kill_line>:
void 
kill_line(){
801009f6:	55                   	push   %ebp
801009f7:	89 e5                	mov    %esp,%ebp
801009f9:	83 ec 18             	sub    $0x18,%esp
  while(input.e != input.w &&
801009fc:	eb 19                	jmp    80100a17 <kill_line+0x21>
	input.buf[(input.e-1) % INPUT_BUF] != '\n'){
    input.e--;
801009fe:	a1 08 08 11 80       	mov    0x80110808,%eax
80100a03:	83 e8 01             	sub    $0x1,%eax
80100a06:	a3 08 08 11 80       	mov    %eax,0x80110808
    consputc(BACKSPACE);
80100a0b:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100a12:	e8 b0 fe ff ff       	call   801008c7 <consputc>
 history.command_sizes[history.lastcommand] = end - start;
 memmove(history.commands[history.lastcommand++],start,end-start);
}
void 
kill_line(){
  while(input.e != input.w &&
80100a17:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100a1d:	a1 04 08 11 80       	mov    0x80110804,%eax
80100a22:	39 c2                	cmp    %eax,%edx
80100a24:	74 16                	je     80100a3c <kill_line+0x46>
	input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100a26:	a1 08 08 11 80       	mov    0x80110808,%eax
80100a2b:	83 e8 01             	sub    $0x1,%eax
80100a2e:	83 e0 7f             	and    $0x7f,%eax
80100a31:	0f b6 80 80 07 11 80 	movzbl -0x7feef880(%eax),%eax
 history.command_sizes[history.lastcommand] = end - start;
 memmove(history.commands[history.lastcommand++],start,end-start);
}
void 
kill_line(){
  while(input.e != input.w &&
80100a38:	3c 0a                	cmp    $0xa,%al
80100a3a:	75 c2                	jne    801009fe <kill_line+0x8>
	input.buf[(input.e-1) % INPUT_BUF] != '\n'){
    input.e--;
    consputc(BACKSPACE);
  }

}
80100a3c:	c9                   	leave  
80100a3d:	c3                   	ret    

80100a3e <display_history>:
void 
display_history(){
80100a3e:	55                   	push   %ebp
80100a3f:	89 e5                	mov    %esp,%ebp
80100a41:	83 ec 28             	sub    $0x28,%esp
 int i =0;
80100a44:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 int size = history.command_sizes[history.lastcommand-1];
80100a4b:	a1 60 10 11 80       	mov    0x80111060,%eax
80100a50:	83 e8 01             	sub    $0x1,%eax
80100a53:	05 00 02 00 00       	add    $0x200,%eax
80100a58:	8b 04 85 20 08 11 80 	mov    -0x7feef7e0(,%eax,4),%eax
80100a5f:	89 45 ec             	mov    %eax,-0x14(%ebp)
 char * cmd = history.commands[history.lastcommand-1];
80100a62:	a1 60 10 11 80       	mov    0x80111060,%eax
80100a67:	83 e8 01             	sub    $0x1,%eax
80100a6a:	c1 e0 07             	shl    $0x7,%eax
80100a6d:	05 20 08 11 80       	add    $0x80110820,%eax
80100a72:	89 45 f0             	mov    %eax,-0x10(%ebp)
 kill_line();
80100a75:	e8 7c ff ff ff       	call   801009f6 <kill_line>
 for (i = 0; i< size; ++i)
80100a7a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a81:	eb 1b                	jmp    80100a9e <display_history+0x60>
   cgaputc(*cmd++);
80100a83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100a86:	8d 50 01             	lea    0x1(%eax),%edx
80100a89:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100a8c:	0f b6 00             	movzbl (%eax),%eax
80100a8f:	0f be c0             	movsbl %al,%eax
80100a92:	89 04 24             	mov    %eax,(%esp)
80100a95:	e8 94 fb ff ff       	call   8010062e <cgaputc>
display_history(){
 int i =0;
 int size = history.command_sizes[history.lastcommand-1];
 char * cmd = history.commands[history.lastcommand-1];
 kill_line();
 for (i = 0; i< size; ++i)
80100a9a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100aa1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100aa4:	7c dd                	jl     80100a83 <display_history+0x45>
   cgaputc(*cmd++);
 memmove(input.buf+input.w,cmd,size);
80100aa6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100aa9:	8b 15 04 08 11 80    	mov    0x80110804,%edx
80100aaf:	81 c2 80 07 11 80    	add    $0x80110780,%edx
80100ab5:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ab9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100abc:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ac0:	89 14 24             	mov    %edx,(%esp)
80100ac3:	e8 8c 4b 00 00       	call   80105654 <memmove>
 input.e+=size % INPUT_BUF;
80100ac8:	8b 0d 08 08 11 80    	mov    0x80110808,%ecx
80100ace:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ad1:	99                   	cltd   
80100ad2:	c1 ea 19             	shr    $0x19,%edx
80100ad5:	01 d0                	add    %edx,%eax
80100ad7:	83 e0 7f             	and    $0x7f,%eax
80100ada:	29 d0                	sub    %edx,%eax
80100adc:	01 c8                	add    %ecx,%eax
80100ade:	a3 08 08 11 80       	mov    %eax,0x80110808
 
}
80100ae3:	c9                   	leave  
80100ae4:	c3                   	ret    

80100ae5 <consoleintr>:
void
consoleintr(int (*getc)(void))
{
80100ae5:	55                   	push   %ebp
80100ae6:	89 e5                	mov    %esp,%ebp
80100ae8:	83 ec 28             	sub    $0x28,%esp
  int c, doprocdump = 0;
80100aeb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
80100af2:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100af9:	e8 33 48 00 00       	call   80105331 <acquire>
  while((c = getc()) >= 0){
80100afe:	e9 a9 02 00 00       	jmp    80100dac <consoleintr+0x2c7>
    switch(c){
80100b03:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100b06:	83 f8 7f             	cmp    $0x7f,%eax
80100b09:	0f 84 91 00 00 00    	je     80100ba0 <consoleintr+0xbb>
80100b0f:	83 f8 7f             	cmp    $0x7f,%eax
80100b12:	7f 14                	jg     80100b28 <consoleintr+0x43>
80100b14:	83 f8 10             	cmp    $0x10,%eax
80100b17:	74 35                	je     80100b4e <consoleintr+0x69>
80100b19:	83 f8 15             	cmp    $0x15,%eax
80100b1c:	74 57                	je     80100b75 <consoleintr+0x90>
80100b1e:	83 f8 08             	cmp    $0x8,%eax
80100b21:	74 7d                	je     80100ba0 <consoleintr+0xbb>
80100b23:	e9 6f 01 00 00       	jmp    80100c97 <consoleintr+0x1b2>
80100b28:	3d e4 00 00 00       	cmp    $0xe4,%eax
80100b2d:	0f 84 d4 00 00 00    	je     80100c07 <consoleintr+0x122>
80100b33:	3d e5 00 00 00       	cmp    $0xe5,%eax
80100b38:	0f 84 08 01 00 00    	je     80100c46 <consoleintr+0x161>
80100b3e:	3d e2 00 00 00       	cmp    $0xe2,%eax
80100b43:	0f 84 36 01 00 00    	je     80100c7f <consoleintr+0x19a>
80100b49:	e9 49 01 00 00       	jmp    80100c97 <consoleintr+0x1b2>
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
80100b4e:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
80100b55:	e9 52 02 00 00       	jmp    80100dac <consoleintr+0x2c7>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100b5a:	a1 08 08 11 80       	mov    0x80110808,%eax
80100b5f:	83 e8 01             	sub    $0x1,%eax
80100b62:	a3 08 08 11 80       	mov    %eax,0x80110808
        consputc(BACKSPACE);
80100b67:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100b6e:	e8 54 fd ff ff       	call   801008c7 <consputc>
80100b73:	eb 01                	jmp    80100b76 <consoleintr+0x91>
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100b75:	90                   	nop
80100b76:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100b7c:	a1 04 08 11 80       	mov    0x80110804,%eax
80100b81:	39 c2                	cmp    %eax,%edx
80100b83:	74 16                	je     80100b9b <consoleintr+0xb6>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100b85:	a1 08 08 11 80       	mov    0x80110808,%eax
80100b8a:	83 e8 01             	sub    $0x1,%eax
80100b8d:	83 e0 7f             	and    $0x7f,%eax
80100b90:	0f b6 80 80 07 11 80 	movzbl -0x7feef880(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      doprocdump = 1;   // procdump() locks cons.lock indirectly; invoke later
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100b97:	3c 0a                	cmp    $0xa,%al
80100b99:	75 bf                	jne    80100b5a <consoleintr+0x75>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100b9b:	e9 0c 02 00 00       	jmp    80100dac <consoleintr+0x2c7>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
80100ba0:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100ba6:	a1 04 08 11 80       	mov    0x80110804,%eax
80100bab:	39 c2                	cmp    %eax,%edx
80100bad:	74 53                	je     80100c02 <consoleintr+0x11d>
        input.e--;
80100baf:	a1 08 08 11 80       	mov    0x80110808,%eax
80100bb4:	83 e8 01             	sub    $0x1,%eax
80100bb7:	a3 08 08 11 80       	mov    %eax,0x80110808
	if(left_strides > 0){
80100bbc:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100bc1:	85 c0                	test   %eax,%eax
80100bc3:	7e 2c                	jle    80100bf1 <consoleintr+0x10c>
	 shift_buffer_left(input.buf + input.e,
			   input.buf + input.e + left_strides +1);
80100bc5:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100bcb:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100bd0:	01 d0                	add    %edx,%eax
80100bd2:	83 c0 01             	add    $0x1,%eax
      break;
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
	if(left_strides > 0){
	 shift_buffer_left(input.buf + input.e,
80100bd5:	8d 90 80 07 11 80    	lea    -0x7feef880(%eax),%edx
80100bdb:	a1 08 08 11 80       	mov    0x80110808,%eax
80100be0:	05 80 07 11 80       	add    $0x80110780,%eax
80100be5:	89 54 24 04          	mov    %edx,0x4(%esp)
80100be9:	89 04 24             	mov    %eax,(%esp)
80100bec:	e8 0b fa ff ff       	call   801005fc <shift_buffer_left>
			   input.buf + input.e + left_strides +1);
			  
	}
        consputc(BACKSPACE);
80100bf1:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100bf8:	e8 ca fc ff ff       	call   801008c7 <consputc>
      }
      break;
80100bfd:	e9 aa 01 00 00       	jmp    80100dac <consoleintr+0x2c7>
80100c02:	e9 a5 01 00 00       	jmp    80100dac <consoleintr+0x2c7>
     case LEFTARROW: //makeshift left arrow
      if(input.e != input.w) { //we want to shift the buffer to the right
80100c07:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100c0d:	a1 04 08 11 80       	mov    0x80110804,%eax
80100c12:	39 c2                	cmp    %eax,%edx
80100c14:	74 2b                	je     80100c41 <consoleintr+0x15c>
       // shift_buffer_right(input.buf + input.e, input.buf + INPUT_BUF);
       
       cgaputc(LEFTARROW);
80100c16:	c7 04 24 e4 00 00 00 	movl   $0xe4,(%esp)
80100c1d:	e8 0c fa ff ff       	call   8010062e <cgaputc>
       ++left_strides;
80100c22:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100c27:	83 c0 01             	add    $0x1,%eax
80100c2a:	a3 f8 b5 10 80       	mov    %eax,0x8010b5f8
       --input.e;
80100c2f:	a1 08 08 11 80       	mov    0x80110808,%eax
80100c34:	83 e8 01             	sub    $0x1,%eax
80100c37:	a3 08 08 11 80       	mov    %eax,0x80110808
      }
      break;
80100c3c:	e9 6b 01 00 00       	jmp    80100dac <consoleintr+0x2c7>
80100c41:	e9 66 01 00 00       	jmp    80100dac <consoleintr+0x2c7>
     case RIGHTARROW:
      if(left_strides > 0) {
80100c46:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100c4b:	85 c0                	test   %eax,%eax
80100c4d:	7e 2b                	jle    80100c7a <consoleintr+0x195>
        cgaputc(RIGHTARROW);
80100c4f:	c7 04 24 e5 00 00 00 	movl   $0xe5,(%esp)
80100c56:	e8 d3 f9 ff ff       	call   8010062e <cgaputc>
        --left_strides;
80100c5b:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100c60:	83 e8 01             	sub    $0x1,%eax
80100c63:	a3 f8 b5 10 80       	mov    %eax,0x8010b5f8
        ++input.e;
80100c68:	a1 08 08 11 80       	mov    0x80110808,%eax
80100c6d:	83 c0 01             	add    $0x1,%eax
80100c70:	a3 08 08 11 80       	mov    %eax,0x80110808
      }
      break;
80100c75:	e9 32 01 00 00       	jmp    80100dac <consoleintr+0x2c7>
80100c7a:	e9 2d 01 00 00       	jmp    80100dac <consoleintr+0x2c7>
     case KEY_UP: 
       if(history.lastcommand > 0){
80100c7f:	a1 60 10 11 80       	mov    0x80111060,%eax
80100c84:	85 c0                	test   %eax,%eax
80100c86:	7e 0a                	jle    80100c92 <consoleintr+0x1ad>
	 display_history();
80100c88:	e8 b1 fd ff ff       	call   80100a3e <display_history>
       }
     break;
80100c8d:	e9 1a 01 00 00       	jmp    80100dac <consoleintr+0x2c7>
80100c92:	e9 15 01 00 00       	jmp    80100dac <consoleintr+0x2c7>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100c97:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100c9b:	0f 84 0a 01 00 00    	je     80100dab <consoleintr+0x2c6>
80100ca1:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100ca7:	a1 00 08 11 80       	mov    0x80110800,%eax
80100cac:	29 c2                	sub    %eax,%edx
80100cae:	89 d0                	mov    %edx,%eax
80100cb0:	83 f8 7f             	cmp    $0x7f,%eax
80100cb3:	0f 87 f2 00 00 00    	ja     80100dab <consoleintr+0x2c6>
        c = (c == '\r') ? '\n' : c;
80100cb9:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80100cbd:	74 05                	je     80100cc4 <consoleintr+0x1df>
80100cbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100cc2:	eb 05                	jmp    80100cc9 <consoleintr+0x1e4>
80100cc4:	b8 0a 00 00 00       	mov    $0xa,%eax
80100cc9:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if('\n' == c){  // if we press enter we want the whole buffer to be
80100ccc:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100cd0:	75 40                	jne    80100d12 <consoleintr+0x22d>
          input.e = (input.e + left_strides) % INPUT_BUF;
80100cd2:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100cd8:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100cdd:	01 d0                	add    %edx,%eax
80100cdf:	83 e0 7f             	and    $0x7f,%eax
80100ce2:	a3 08 08 11 80       	mov    %eax,0x80110808
	  add_to_history(input.buf + input.w,
			 input.buf + input.e);
80100ce7:	a1 08 08 11 80       	mov    0x80110808,%eax
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
        c = (c == '\r') ? '\n' : c;
        if('\n' == c){  // if we press enter we want the whole buffer to be
          input.e = (input.e + left_strides) % INPUT_BUF;
	  add_to_history(input.buf + input.w,
80100cec:	8d 90 80 07 11 80    	lea    -0x7feef880(%eax),%edx
80100cf2:	a1 04 08 11 80       	mov    0x80110804,%eax
80100cf7:	05 80 07 11 80       	add    $0x80110780,%eax
80100cfc:	89 54 24 04          	mov    %edx,0x4(%esp)
80100d00:	89 04 24             	mov    %eax,(%esp)
80100d03:	e8 2e fc ff ff       	call   80100936 <add_to_history>
			 input.buf + input.e);
	  left_strides  = 0;
80100d08:	c7 05 f8 b5 10 80 00 	movl   $0x0,0x8010b5f8
80100d0f:	00 00 00 
        }
 
	if (left_strides > 0) { //if we've taken a left and then we write.
80100d12:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100d17:	85 c0                	test   %eax,%eax
80100d19:	7e 29                	jle    80100d44 <consoleintr+0x25f>
	  shift_buffer_right(input.buf + input.e,
			   input.buf + input.e + left_strides);
80100d1b:	8b 15 08 08 11 80    	mov    0x80110808,%edx
80100d21:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100d26:	01 d0                	add    %edx,%eax
			 input.buf + input.e);
	  left_strides  = 0;
        }
 
	if (left_strides > 0) { //if we've taken a left and then we write.
	  shift_buffer_right(input.buf + input.e,
80100d28:	8d 90 80 07 11 80    	lea    -0x7feef880(%eax),%edx
80100d2e:	a1 08 08 11 80       	mov    0x80110808,%eax
80100d33:	05 80 07 11 80       	add    $0x80110780,%eax
80100d38:	89 54 24 04          	mov    %edx,0x4(%esp)
80100d3c:	89 04 24             	mov    %eax,(%esp)
80100d3f:	e8 86 f8 ff ff       	call   801005ca <shift_buffer_right>
			   input.buf + input.e + left_strides);
	}
	input.buf[input.e++ % INPUT_BUF] = c;
80100d44:	a1 08 08 11 80       	mov    0x80110808,%eax
80100d49:	8d 50 01             	lea    0x1(%eax),%edx
80100d4c:	89 15 08 08 11 80    	mov    %edx,0x80110808
80100d52:	83 e0 7f             	and    $0x7f,%eax
80100d55:	89 c2                	mov    %eax,%edx
80100d57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100d5a:	88 82 80 07 11 80    	mov    %al,-0x7feef880(%edx)
	consputc(c);
80100d60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100d63:	89 04 24             	mov    %eax,(%esp)
80100d66:	e8 5c fb ff ff       	call   801008c7 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
80100d6b:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100d6f:	74 18                	je     80100d89 <consoleintr+0x2a4>
80100d71:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100d75:	74 12                	je     80100d89 <consoleintr+0x2a4>
80100d77:	a1 08 08 11 80       	mov    0x80110808,%eax
80100d7c:	8b 15 00 08 11 80    	mov    0x80110800,%edx
80100d82:	83 ea 80             	sub    $0xffffff80,%edx
80100d85:	39 d0                	cmp    %edx,%eax
80100d87:	75 22                	jne    80100dab <consoleintr+0x2c6>
          left_strides = 0;
80100d89:	c7 05 f8 b5 10 80 00 	movl   $0x0,0x8010b5f8
80100d90:	00 00 00 
          input.w = input.e;
80100d93:	a1 08 08 11 80       	mov    0x80110808,%eax
80100d98:	a3 04 08 11 80       	mov    %eax,0x80110804
          wakeup(&input.r);
80100d9d:	c7 04 24 00 08 11 80 	movl   $0x80110800,(%esp)
80100da4:	e8 97 43 00 00       	call   80105140 <wakeup>
        }
      }
      break;
80100da9:	eb 00                	jmp    80100dab <consoleintr+0x2c6>
80100dab:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c, doprocdump = 0;

  acquire(&cons.lock);
  while((c = getc()) >= 0){
80100dac:	8b 45 08             	mov    0x8(%ebp),%eax
80100daf:	ff d0                	call   *%eax
80100db1:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100db4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100db8:	0f 89 45 fd ff ff    	jns    80100b03 <consoleintr+0x1e>
        }
      }
      break;
    }
  }
  release(&cons.lock);
80100dbe:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100dc5:	e8 c9 45 00 00       	call   80105393 <release>
  if(doprocdump) {
80100dca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100dce:	74 05                	je     80100dd5 <consoleintr+0x2f0>
    procdump();  // now call procdump() wo. cons.lock held
80100dd0:	e8 0e 44 00 00       	call   801051e3 <procdump>
  }
}
80100dd5:	c9                   	leave  
80100dd6:	c3                   	ret    

80100dd7 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100dd7:	55                   	push   %ebp
80100dd8:	89 e5                	mov    %esp,%ebp
80100dda:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;
  iunlock(ip);
80100ddd:	8b 45 08             	mov    0x8(%ebp),%eax
80100de0:	89 04 24             	mov    %eax,(%esp)
80100de3:	e8 cd 10 00 00       	call   80101eb5 <iunlock>
  target = n;
80100de8:	8b 45 10             	mov    0x10(%ebp),%eax
80100deb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
80100dee:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100df5:	e8 37 45 00 00       	call   80105331 <acquire>
  while(n > 0){
80100dfa:	e9 aa 00 00 00       	jmp    80100ea9 <consoleread+0xd2>
    while(input.r == input.w){
80100dff:	eb 42                	jmp    80100e43 <consoleread+0x6c>
      if(proc->killed){
80100e01:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e07:	8b 40 24             	mov    0x24(%eax),%eax
80100e0a:	85 c0                	test   %eax,%eax
80100e0c:	74 21                	je     80100e2f <consoleread+0x58>
        release(&cons.lock);
80100e0e:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100e15:	e8 79 45 00 00       	call   80105393 <release>
        ilock(ip);
80100e1a:	8b 45 08             	mov    0x8(%ebp),%eax
80100e1d:	89 04 24             	mov    %eax,(%esp)
80100e20:	e8 3c 0f 00 00       	call   80101d61 <ilock>
        return -1;
80100e25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100e2a:	e9 a5 00 00 00       	jmp    80100ed4 <consoleread+0xfd>
      }
      sleep(&input.r, &cons.lock);
80100e2f:	c7 44 24 04 c0 b5 10 	movl   $0x8010b5c0,0x4(%esp)
80100e36:	80 
80100e37:	c7 04 24 00 08 11 80 	movl   $0x80110800,(%esp)
80100e3e:	e8 24 42 00 00       	call   80105067 <sleep>
  int c;
  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
    while(input.r == input.w){
80100e43:	8b 15 00 08 11 80    	mov    0x80110800,%edx
80100e49:	a1 04 08 11 80       	mov    0x80110804,%eax
80100e4e:	39 c2                	cmp    %eax,%edx
80100e50:	74 af                	je     80100e01 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100e52:	a1 00 08 11 80       	mov    0x80110800,%eax
80100e57:	8d 50 01             	lea    0x1(%eax),%edx
80100e5a:	89 15 00 08 11 80    	mov    %edx,0x80110800
80100e60:	83 e0 7f             	and    $0x7f,%eax
80100e63:	0f b6 80 80 07 11 80 	movzbl -0x7feef880(%eax),%eax
80100e6a:	0f be c0             	movsbl %al,%eax
80100e6d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
80100e70:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100e74:	75 19                	jne    80100e8f <consoleread+0xb8>
      if(n < target){
80100e76:	8b 45 10             	mov    0x10(%ebp),%eax
80100e79:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80100e7c:	73 0f                	jae    80100e8d <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
80100e7e:	a1 00 08 11 80       	mov    0x80110800,%eax
80100e83:	83 e8 01             	sub    $0x1,%eax
80100e86:	a3 00 08 11 80       	mov    %eax,0x80110800
      }
      break;
80100e8b:	eb 26                	jmp    80100eb3 <consoleread+0xdc>
80100e8d:	eb 24                	jmp    80100eb3 <consoleread+0xdc>
    }
    *dst++ = c;
80100e8f:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e92:	8d 50 01             	lea    0x1(%eax),%edx
80100e95:	89 55 0c             	mov    %edx,0xc(%ebp)
80100e98:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100e9b:	88 10                	mov    %dl,(%eax)
    --n;
80100e9d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100ea1:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100ea5:	75 02                	jne    80100ea9 <consoleread+0xd2>
      break;
80100ea7:	eb 0a                	jmp    80100eb3 <consoleread+0xdc>
  uint target;
  int c;
  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
80100ea9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100ead:	0f 8f 4c ff ff ff    	jg     80100dff <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&cons.lock);
80100eb3:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100eba:	e8 d4 44 00 00       	call   80105393 <release>
  ilock(ip);
80100ebf:	8b 45 08             	mov    0x8(%ebp),%eax
80100ec2:	89 04 24             	mov    %eax,(%esp)
80100ec5:	e8 97 0e 00 00       	call   80101d61 <ilock>

  return target - n;
80100eca:	8b 45 10             	mov    0x10(%ebp),%eax
80100ecd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100ed0:	29 c2                	sub    %eax,%edx
80100ed2:	89 d0                	mov    %edx,%eax
}
80100ed4:	c9                   	leave  
80100ed5:	c3                   	ret    

80100ed6 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100ed6:	55                   	push   %ebp
80100ed7:	89 e5                	mov    %esp,%ebp
80100ed9:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100edc:	8b 45 08             	mov    0x8(%ebp),%eax
80100edf:	89 04 24             	mov    %eax,(%esp)
80100ee2:	e8 ce 0f 00 00       	call   80101eb5 <iunlock>
  acquire(&cons.lock);
80100ee7:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100eee:	e8 3e 44 00 00       	call   80105331 <acquire>
  for(i = 0; i < n; i++)
80100ef3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100efa:	eb 1d                	jmp    80100f19 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100efc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100eff:	8b 45 0c             	mov    0xc(%ebp),%eax
80100f02:	01 d0                	add    %edx,%eax
80100f04:	0f b6 00             	movzbl (%eax),%eax
80100f07:	0f be c0             	movsbl %al,%eax
80100f0a:	0f b6 c0             	movzbl %al,%eax
80100f0d:	89 04 24             	mov    %eax,(%esp)
80100f10:	e8 b2 f9 ff ff       	call   801008c7 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100f15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100f19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f1c:	3b 45 10             	cmp    0x10(%ebp),%eax
80100f1f:	7c db                	jl     80100efc <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100f21:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100f28:	e8 66 44 00 00       	call   80105393 <release>
  ilock(ip);
80100f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80100f30:	89 04 24             	mov    %eax,(%esp)
80100f33:	e8 29 0e 00 00       	call   80101d61 <ilock>

  return n;
80100f38:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100f3b:	c9                   	leave  
80100f3c:	c3                   	ret    

80100f3d <consoleinit>:

void
consoleinit(void)
{
80100f3d:	55                   	push   %ebp
80100f3e:	89 e5                	mov    %esp,%ebp
80100f40:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100f43:	c7 44 24 04 5a 89 10 	movl   $0x8010895a,0x4(%esp)
80100f4a:	80 
80100f4b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100f52:	e8 b9 43 00 00       	call   80105310 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100f57:	c7 05 2c 1a 11 80 d6 	movl   $0x80100ed6,0x80111a2c
80100f5e:	0e 10 80 
  devsw[CONSOLE].read = consoleread;
80100f61:	c7 05 28 1a 11 80 d7 	movl   $0x80100dd7,0x80111a28
80100f68:	0d 10 80 
  cons.locking = 1;
80100f6b:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100f72:	00 00 00 

  picenable(IRQ_KBD);
80100f75:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100f7c:	e8 67 33 00 00       	call   801042e8 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100f81:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100f88:	00 
80100f89:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100f90:	e8 0b 1f 00 00       	call   80102ea0 <ioapicenable>
}
80100f95:	c9                   	leave  
80100f96:	c3                   	ret    

80100f97 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100f97:	55                   	push   %ebp
80100f98:	89 e5                	mov    %esp,%ebp
80100f9a:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100fa0:	e8 a4 29 00 00       	call   80103949 <begin_op>
  if((ip = namei(path)) == 0){
80100fa5:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa8:	89 04 24             	mov    %eax,(%esp)
80100fab:	e8 62 19 00 00       	call   80102912 <namei>
80100fb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100fb3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100fb7:	75 0f                	jne    80100fc8 <exec+0x31>
    end_op();
80100fb9:	e8 0f 2a 00 00       	call   801039cd <end_op>
    return -1;
80100fbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100fc3:	e9 e8 03 00 00       	jmp    801013b0 <exec+0x419>
  }
  ilock(ip);
80100fc8:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100fcb:	89 04 24             	mov    %eax,(%esp)
80100fce:	e8 8e 0d 00 00       	call   80101d61 <ilock>
  pgdir = 0;
80100fd3:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100fda:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100fe1:	00 
80100fe2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100fe9:	00 
80100fea:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100ff0:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ff4:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ff7:	89 04 24             	mov    %eax,(%esp)
80100ffa:	e8 75 12 00 00       	call   80102274 <readi>
80100fff:	83 f8 33             	cmp    $0x33,%eax
80101002:	77 05                	ja     80101009 <exec+0x72>
    goto bad;
80101004:	e9 7b 03 00 00       	jmp    80101384 <exec+0x3ed>
  if(elf.magic != ELF_MAGIC)
80101009:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
8010100f:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80101014:	74 05                	je     8010101b <exec+0x84>
    goto bad;
80101016:	e9 69 03 00 00       	jmp    80101384 <exec+0x3ed>

  if((pgdir = setupkvm()) == 0)
8010101b:	e8 6d 70 00 00       	call   8010808d <setupkvm>
80101020:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80101023:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80101027:	75 05                	jne    8010102e <exec+0x97>
    goto bad;
80101029:	e9 56 03 00 00       	jmp    80101384 <exec+0x3ed>

  // Load program into memory.
  sz = 0;
8010102e:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80101035:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
8010103c:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80101042:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101045:	e9 cb 00 00 00       	jmp    80101115 <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
8010104a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010104d:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80101054:	00 
80101055:	89 44 24 08          	mov    %eax,0x8(%esp)
80101059:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
8010105f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101063:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101066:	89 04 24             	mov    %eax,(%esp)
80101069:	e8 06 12 00 00       	call   80102274 <readi>
8010106e:	83 f8 20             	cmp    $0x20,%eax
80101071:	74 05                	je     80101078 <exec+0xe1>
      goto bad;
80101073:	e9 0c 03 00 00       	jmp    80101384 <exec+0x3ed>
    if(ph.type != ELF_PROG_LOAD)
80101078:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
8010107e:	83 f8 01             	cmp    $0x1,%eax
80101081:	74 05                	je     80101088 <exec+0xf1>
      continue;
80101083:	e9 80 00 00 00       	jmp    80101108 <exec+0x171>
    if(ph.memsz < ph.filesz)
80101088:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
8010108e:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80101094:	39 c2                	cmp    %eax,%edx
80101096:	73 05                	jae    8010109d <exec+0x106>
      goto bad;
80101098:	e9 e7 02 00 00       	jmp    80101384 <exec+0x3ed>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
8010109d:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
801010a3:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
801010a9:	01 d0                	add    %edx,%eax
801010ab:	89 44 24 08          	mov    %eax,0x8(%esp)
801010af:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801010b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801010b9:	89 04 24             	mov    %eax,(%esp)
801010bc:	e8 9a 73 00 00       	call   8010845b <allocuvm>
801010c1:	89 45 e0             	mov    %eax,-0x20(%ebp)
801010c4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801010c8:	75 05                	jne    801010cf <exec+0x138>
      goto bad;
801010ca:	e9 b5 02 00 00       	jmp    80101384 <exec+0x3ed>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
801010cf:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
801010d5:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
801010db:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
801010e1:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801010e5:	89 54 24 0c          	mov    %edx,0xc(%esp)
801010e9:	8b 55 d8             	mov    -0x28(%ebp),%edx
801010ec:	89 54 24 08          	mov    %edx,0x8(%esp)
801010f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801010f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801010f7:	89 04 24             	mov    %eax,(%esp)
801010fa:	e8 71 72 00 00       	call   80108370 <loaduvm>
801010ff:	85 c0                	test   %eax,%eax
80101101:	79 05                	jns    80101108 <exec+0x171>
      goto bad;
80101103:	e9 7c 02 00 00       	jmp    80101384 <exec+0x3ed>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80101108:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
8010110c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010110f:	83 c0 20             	add    $0x20,%eax
80101112:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101115:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
8010111c:	0f b7 c0             	movzwl %ax,%eax
8010111f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101122:	0f 8f 22 ff ff ff    	jg     8010104a <exec+0xb3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80101128:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010112b:	89 04 24             	mov    %eax,(%esp)
8010112e:	e8 b8 0e 00 00       	call   80101feb <iunlockput>
  end_op();
80101133:	e8 95 28 00 00       	call   801039cd <end_op>
  ip = 0;
80101138:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
8010113f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101142:	05 ff 0f 00 00       	add    $0xfff,%eax
80101147:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010114c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
8010114f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101152:	05 00 20 00 00       	add    $0x2000,%eax
80101157:	89 44 24 08          	mov    %eax,0x8(%esp)
8010115b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010115e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101162:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101165:	89 04 24             	mov    %eax,(%esp)
80101168:	e8 ee 72 00 00       	call   8010845b <allocuvm>
8010116d:	89 45 e0             	mov    %eax,-0x20(%ebp)
80101170:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101174:	75 05                	jne    8010117b <exec+0x1e4>
    goto bad;
80101176:	e9 09 02 00 00       	jmp    80101384 <exec+0x3ed>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
8010117b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010117e:	2d 00 20 00 00       	sub    $0x2000,%eax
80101183:	89 44 24 04          	mov    %eax,0x4(%esp)
80101187:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010118a:	89 04 24             	mov    %eax,(%esp)
8010118d:	e8 f9 74 00 00       	call   8010868b <clearpteu>
  sp = sz;
80101192:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101195:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80101198:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010119f:	e9 9a 00 00 00       	jmp    8010123e <exec+0x2a7>
    if(argc >= MAXARG)
801011a4:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
801011a8:	76 05                	jbe    801011af <exec+0x218>
      goto bad;
801011aa:	e9 d5 01 00 00       	jmp    80101384 <exec+0x3ed>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
801011af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011b2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801011b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801011bc:	01 d0                	add    %edx,%eax
801011be:	8b 00                	mov    (%eax),%eax
801011c0:	89 04 24             	mov    %eax,(%esp)
801011c3:	e8 27 46 00 00       	call   801057ef <strlen>
801011c8:	8b 55 dc             	mov    -0x24(%ebp),%edx
801011cb:	29 c2                	sub    %eax,%edx
801011cd:	89 d0                	mov    %edx,%eax
801011cf:	83 e8 01             	sub    $0x1,%eax
801011d2:	83 e0 fc             	and    $0xfffffffc,%eax
801011d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
801011d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011db:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801011e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801011e5:	01 d0                	add    %edx,%eax
801011e7:	8b 00                	mov    (%eax),%eax
801011e9:	89 04 24             	mov    %eax,(%esp)
801011ec:	e8 fe 45 00 00       	call   801057ef <strlen>
801011f1:	83 c0 01             	add    $0x1,%eax
801011f4:	89 c2                	mov    %eax,%edx
801011f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011f9:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80101200:	8b 45 0c             	mov    0xc(%ebp),%eax
80101203:	01 c8                	add    %ecx,%eax
80101205:	8b 00                	mov    (%eax),%eax
80101207:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010120b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010120f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101212:	89 44 24 04          	mov    %eax,0x4(%esp)
80101216:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101219:	89 04 24             	mov    %eax,(%esp)
8010121c:	e8 2f 76 00 00       	call   80108850 <copyout>
80101221:	85 c0                	test   %eax,%eax
80101223:	79 05                	jns    8010122a <exec+0x293>
      goto bad;
80101225:	e9 5a 01 00 00       	jmp    80101384 <exec+0x3ed>
    ustack[3+argc] = sp;
8010122a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010122d:	8d 50 03             	lea    0x3(%eax),%edx
80101230:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101233:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
8010123a:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010123e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101241:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101248:	8b 45 0c             	mov    0xc(%ebp),%eax
8010124b:	01 d0                	add    %edx,%eax
8010124d:	8b 00                	mov    (%eax),%eax
8010124f:	85 c0                	test   %eax,%eax
80101251:	0f 85 4d ff ff ff    	jne    801011a4 <exec+0x20d>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80101257:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010125a:	83 c0 03             	add    $0x3,%eax
8010125d:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80101264:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80101268:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
8010126f:	ff ff ff 
  ustack[1] = argc;
80101272:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101275:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
8010127b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010127e:	83 c0 01             	add    $0x1,%eax
80101281:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101288:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010128b:	29 d0                	sub    %edx,%eax
8010128d:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80101293:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101296:	83 c0 04             	add    $0x4,%eax
80101299:	c1 e0 02             	shl    $0x2,%eax
8010129c:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
8010129f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801012a2:	83 c0 04             	add    $0x4,%eax
801012a5:	c1 e0 02             	shl    $0x2,%eax
801012a8:	89 44 24 0c          	mov    %eax,0xc(%esp)
801012ac:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
801012b2:	89 44 24 08          	mov    %eax,0x8(%esp)
801012b6:	8b 45 dc             	mov    -0x24(%ebp),%eax
801012b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801012bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801012c0:	89 04 24             	mov    %eax,(%esp)
801012c3:	e8 88 75 00 00       	call   80108850 <copyout>
801012c8:	85 c0                	test   %eax,%eax
801012ca:	79 05                	jns    801012d1 <exec+0x33a>
    goto bad;
801012cc:	e9 b3 00 00 00       	jmp    80101384 <exec+0x3ed>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
801012d1:	8b 45 08             	mov    0x8(%ebp),%eax
801012d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801012d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012da:	89 45 f0             	mov    %eax,-0x10(%ebp)
801012dd:	eb 17                	jmp    801012f6 <exec+0x35f>
    if(*s == '/')
801012df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012e2:	0f b6 00             	movzbl (%eax),%eax
801012e5:	3c 2f                	cmp    $0x2f,%al
801012e7:	75 09                	jne    801012f2 <exec+0x35b>
      last = s+1;
801012e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ec:	83 c0 01             	add    $0x1,%eax
801012ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
801012f2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801012f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012f9:	0f b6 00             	movzbl (%eax),%eax
801012fc:	84 c0                	test   %al,%al
801012fe:	75 df                	jne    801012df <exec+0x348>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80101300:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101306:	8d 50 6c             	lea    0x6c(%eax),%edx
80101309:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101310:	00 
80101311:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101314:	89 44 24 04          	mov    %eax,0x4(%esp)
80101318:	89 14 24             	mov    %edx,(%esp)
8010131b:	e8 85 44 00 00       	call   801057a5 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80101320:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101326:	8b 40 04             	mov    0x4(%eax),%eax
80101329:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
8010132c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101332:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80101335:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80101338:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010133e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101341:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80101343:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101349:	8b 40 18             	mov    0x18(%eax),%eax
8010134c:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80101352:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80101355:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010135b:	8b 40 18             	mov    0x18(%eax),%eax
8010135e:	8b 55 dc             	mov    -0x24(%ebp),%edx
80101361:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80101364:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010136a:	89 04 24             	mov    %eax,(%esp)
8010136d:	e8 0c 6e 00 00       	call   8010817e <switchuvm>
  freevm(oldpgdir);
80101372:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101375:	89 04 24             	mov    %eax,(%esp)
80101378:	e8 74 72 00 00       	call   801085f1 <freevm>
  return 0;
8010137d:	b8 00 00 00 00       	mov    $0x0,%eax
80101382:	eb 2c                	jmp    801013b0 <exec+0x419>

 bad:
  if(pgdir)
80101384:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80101388:	74 0b                	je     80101395 <exec+0x3fe>
    freevm(pgdir);
8010138a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010138d:	89 04 24             	mov    %eax,(%esp)
80101390:	e8 5c 72 00 00       	call   801085f1 <freevm>
  if(ip){
80101395:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80101399:	74 10                	je     801013ab <exec+0x414>
    iunlockput(ip);
8010139b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010139e:	89 04 24             	mov    %eax,(%esp)
801013a1:	e8 45 0c 00 00       	call   80101feb <iunlockput>
    end_op();
801013a6:	e8 22 26 00 00       	call   801039cd <end_op>
  }
  return -1;
801013ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801013b0:	c9                   	leave  
801013b1:	c3                   	ret    

801013b2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
801013b2:	55                   	push   %ebp
801013b3:	89 e5                	mov    %esp,%ebp
801013b5:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
801013b8:	c7 44 24 04 62 89 10 	movl   $0x80108962,0x4(%esp)
801013bf:	80 
801013c0:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
801013c7:	e8 44 3f 00 00       	call   80105310 <initlock>
}
801013cc:	c9                   	leave  
801013cd:	c3                   	ret    

801013ce <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
801013ce:	55                   	push   %ebp
801013cf:	89 e5                	mov    %esp,%ebp
801013d1:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
801013d4:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
801013db:	e8 51 3f 00 00       	call   80105331 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
801013e0:	c7 45 f4 b4 10 11 80 	movl   $0x801110b4,-0xc(%ebp)
801013e7:	eb 29                	jmp    80101412 <filealloc+0x44>
    if(f->ref == 0){
801013e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013ec:	8b 40 04             	mov    0x4(%eax),%eax
801013ef:	85 c0                	test   %eax,%eax
801013f1:	75 1b                	jne    8010140e <filealloc+0x40>
      f->ref = 1;
801013f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013f6:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
801013fd:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
80101404:	e8 8a 3f 00 00       	call   80105393 <release>
      return f;
80101409:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010140c:	eb 1e                	jmp    8010142c <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
8010140e:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80101412:	81 7d f4 14 1a 11 80 	cmpl   $0x80111a14,-0xc(%ebp)
80101419:	72 ce                	jb     801013e9 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
8010141b:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
80101422:	e8 6c 3f 00 00       	call   80105393 <release>
  return 0;
80101427:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010142c:	c9                   	leave  
8010142d:	c3                   	ret    

8010142e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
8010142e:	55                   	push   %ebp
8010142f:	89 e5                	mov    %esp,%ebp
80101431:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80101434:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
8010143b:	e8 f1 3e 00 00       	call   80105331 <acquire>
  if(f->ref < 1)
80101440:	8b 45 08             	mov    0x8(%ebp),%eax
80101443:	8b 40 04             	mov    0x4(%eax),%eax
80101446:	85 c0                	test   %eax,%eax
80101448:	7f 0c                	jg     80101456 <filedup+0x28>
    panic("filedup");
8010144a:	c7 04 24 69 89 10 80 	movl   $0x80108969,(%esp)
80101451:	e8 e4 f0 ff ff       	call   8010053a <panic>
  f->ref++;
80101456:	8b 45 08             	mov    0x8(%ebp),%eax
80101459:	8b 40 04             	mov    0x4(%eax),%eax
8010145c:	8d 50 01             	lea    0x1(%eax),%edx
8010145f:	8b 45 08             	mov    0x8(%ebp),%eax
80101462:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80101465:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
8010146c:	e8 22 3f 00 00       	call   80105393 <release>
  return f;
80101471:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101474:	c9                   	leave  
80101475:	c3                   	ret    

80101476 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80101476:	55                   	push   %ebp
80101477:	89 e5                	mov    %esp,%ebp
80101479:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
8010147c:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
80101483:	e8 a9 3e 00 00       	call   80105331 <acquire>
  if(f->ref < 1)
80101488:	8b 45 08             	mov    0x8(%ebp),%eax
8010148b:	8b 40 04             	mov    0x4(%eax),%eax
8010148e:	85 c0                	test   %eax,%eax
80101490:	7f 0c                	jg     8010149e <fileclose+0x28>
    panic("fileclose");
80101492:	c7 04 24 71 89 10 80 	movl   $0x80108971,(%esp)
80101499:	e8 9c f0 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
8010149e:	8b 45 08             	mov    0x8(%ebp),%eax
801014a1:	8b 40 04             	mov    0x4(%eax),%eax
801014a4:	8d 50 ff             	lea    -0x1(%eax),%edx
801014a7:	8b 45 08             	mov    0x8(%ebp),%eax
801014aa:	89 50 04             	mov    %edx,0x4(%eax)
801014ad:	8b 45 08             	mov    0x8(%ebp),%eax
801014b0:	8b 40 04             	mov    0x4(%eax),%eax
801014b3:	85 c0                	test   %eax,%eax
801014b5:	7e 11                	jle    801014c8 <fileclose+0x52>
    release(&ftable.lock);
801014b7:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
801014be:	e8 d0 3e 00 00       	call   80105393 <release>
801014c3:	e9 82 00 00 00       	jmp    8010154a <fileclose+0xd4>
    return;
  }
  ff = *f;
801014c8:	8b 45 08             	mov    0x8(%ebp),%eax
801014cb:	8b 10                	mov    (%eax),%edx
801014cd:	89 55 e0             	mov    %edx,-0x20(%ebp)
801014d0:	8b 50 04             	mov    0x4(%eax),%edx
801014d3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
801014d6:	8b 50 08             	mov    0x8(%eax),%edx
801014d9:	89 55 e8             	mov    %edx,-0x18(%ebp)
801014dc:	8b 50 0c             	mov    0xc(%eax),%edx
801014df:	89 55 ec             	mov    %edx,-0x14(%ebp)
801014e2:	8b 50 10             	mov    0x10(%eax),%edx
801014e5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801014e8:	8b 40 14             	mov    0x14(%eax),%eax
801014eb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
801014ee:	8b 45 08             	mov    0x8(%ebp),%eax
801014f1:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
801014f8:	8b 45 08             	mov    0x8(%ebp),%eax
801014fb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101501:	c7 04 24 80 10 11 80 	movl   $0x80111080,(%esp)
80101508:	e8 86 3e 00 00       	call   80105393 <release>
  
  if(ff.type == FD_PIPE)
8010150d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101510:	83 f8 01             	cmp    $0x1,%eax
80101513:	75 18                	jne    8010152d <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
80101515:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101519:	0f be d0             	movsbl %al,%edx
8010151c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010151f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101523:	89 04 24             	mov    %eax,(%esp)
80101526:	e8 6d 30 00 00       	call   80104598 <pipeclose>
8010152b:	eb 1d                	jmp    8010154a <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010152d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101530:	83 f8 02             	cmp    $0x2,%eax
80101533:	75 15                	jne    8010154a <fileclose+0xd4>
    begin_op();
80101535:	e8 0f 24 00 00       	call   80103949 <begin_op>
    iput(ff.ip);
8010153a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010153d:	89 04 24             	mov    %eax,(%esp)
80101540:	e8 d5 09 00 00       	call   80101f1a <iput>
    end_op();
80101545:	e8 83 24 00 00       	call   801039cd <end_op>
  }
}
8010154a:	c9                   	leave  
8010154b:	c3                   	ret    

8010154c <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
8010154c:	55                   	push   %ebp
8010154d:	89 e5                	mov    %esp,%ebp
8010154f:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
80101552:	8b 45 08             	mov    0x8(%ebp),%eax
80101555:	8b 00                	mov    (%eax),%eax
80101557:	83 f8 02             	cmp    $0x2,%eax
8010155a:	75 38                	jne    80101594 <filestat+0x48>
    ilock(f->ip);
8010155c:	8b 45 08             	mov    0x8(%ebp),%eax
8010155f:	8b 40 10             	mov    0x10(%eax),%eax
80101562:	89 04 24             	mov    %eax,(%esp)
80101565:	e8 f7 07 00 00       	call   80101d61 <ilock>
    stati(f->ip, st);
8010156a:	8b 45 08             	mov    0x8(%ebp),%eax
8010156d:	8b 40 10             	mov    0x10(%eax),%eax
80101570:	8b 55 0c             	mov    0xc(%ebp),%edx
80101573:	89 54 24 04          	mov    %edx,0x4(%esp)
80101577:	89 04 24             	mov    %eax,(%esp)
8010157a:	e8 b0 0c 00 00       	call   8010222f <stati>
    iunlock(f->ip);
8010157f:	8b 45 08             	mov    0x8(%ebp),%eax
80101582:	8b 40 10             	mov    0x10(%eax),%eax
80101585:	89 04 24             	mov    %eax,(%esp)
80101588:	e8 28 09 00 00       	call   80101eb5 <iunlock>
    return 0;
8010158d:	b8 00 00 00 00       	mov    $0x0,%eax
80101592:	eb 05                	jmp    80101599 <filestat+0x4d>
  }
  return -1;
80101594:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101599:	c9                   	leave  
8010159a:	c3                   	ret    

8010159b <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
8010159b:	55                   	push   %ebp
8010159c:	89 e5                	mov    %esp,%ebp
8010159e:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801015a1:	8b 45 08             	mov    0x8(%ebp),%eax
801015a4:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801015a8:	84 c0                	test   %al,%al
801015aa:	75 0a                	jne    801015b6 <fileread+0x1b>
    return -1;
801015ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801015b1:	e9 9f 00 00 00       	jmp    80101655 <fileread+0xba>
  if(f->type == FD_PIPE)
801015b6:	8b 45 08             	mov    0x8(%ebp),%eax
801015b9:	8b 00                	mov    (%eax),%eax
801015bb:	83 f8 01             	cmp    $0x1,%eax
801015be:	75 1e                	jne    801015de <fileread+0x43>
    return piperead(f->pipe, addr, n);
801015c0:	8b 45 08             	mov    0x8(%ebp),%eax
801015c3:	8b 40 0c             	mov    0xc(%eax),%eax
801015c6:	8b 55 10             	mov    0x10(%ebp),%edx
801015c9:	89 54 24 08          	mov    %edx,0x8(%esp)
801015cd:	8b 55 0c             	mov    0xc(%ebp),%edx
801015d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801015d4:	89 04 24             	mov    %eax,(%esp)
801015d7:	e8 3d 31 00 00       	call   80104719 <piperead>
801015dc:	eb 77                	jmp    80101655 <fileread+0xba>
  if(f->type == FD_INODE){
801015de:	8b 45 08             	mov    0x8(%ebp),%eax
801015e1:	8b 00                	mov    (%eax),%eax
801015e3:	83 f8 02             	cmp    $0x2,%eax
801015e6:	75 61                	jne    80101649 <fileread+0xae>
    ilock(f->ip);
801015e8:	8b 45 08             	mov    0x8(%ebp),%eax
801015eb:	8b 40 10             	mov    0x10(%eax),%eax
801015ee:	89 04 24             	mov    %eax,(%esp)
801015f1:	e8 6b 07 00 00       	call   80101d61 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
801015f6:	8b 4d 10             	mov    0x10(%ebp),%ecx
801015f9:	8b 45 08             	mov    0x8(%ebp),%eax
801015fc:	8b 50 14             	mov    0x14(%eax),%edx
801015ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101602:	8b 40 10             	mov    0x10(%eax),%eax
80101605:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101609:	89 54 24 08          	mov    %edx,0x8(%esp)
8010160d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101610:	89 54 24 04          	mov    %edx,0x4(%esp)
80101614:	89 04 24             	mov    %eax,(%esp)
80101617:	e8 58 0c 00 00       	call   80102274 <readi>
8010161c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010161f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101623:	7e 11                	jle    80101636 <fileread+0x9b>
      f->off += r;
80101625:	8b 45 08             	mov    0x8(%ebp),%eax
80101628:	8b 50 14             	mov    0x14(%eax),%edx
8010162b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010162e:	01 c2                	add    %eax,%edx
80101630:	8b 45 08             	mov    0x8(%ebp),%eax
80101633:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
80101636:	8b 45 08             	mov    0x8(%ebp),%eax
80101639:	8b 40 10             	mov    0x10(%eax),%eax
8010163c:	89 04 24             	mov    %eax,(%esp)
8010163f:	e8 71 08 00 00       	call   80101eb5 <iunlock>
    return r;
80101644:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101647:	eb 0c                	jmp    80101655 <fileread+0xba>
  }
  panic("fileread");
80101649:	c7 04 24 7b 89 10 80 	movl   $0x8010897b,(%esp)
80101650:	e8 e5 ee ff ff       	call   8010053a <panic>
}
80101655:	c9                   	leave  
80101656:	c3                   	ret    

80101657 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80101657:	55                   	push   %ebp
80101658:	89 e5                	mov    %esp,%ebp
8010165a:	53                   	push   %ebx
8010165b:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
8010165e:	8b 45 08             	mov    0x8(%ebp),%eax
80101661:	0f b6 40 09          	movzbl 0x9(%eax),%eax
80101665:	84 c0                	test   %al,%al
80101667:	75 0a                	jne    80101673 <filewrite+0x1c>
    return -1;
80101669:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010166e:	e9 20 01 00 00       	jmp    80101793 <filewrite+0x13c>
  if(f->type == FD_PIPE)
80101673:	8b 45 08             	mov    0x8(%ebp),%eax
80101676:	8b 00                	mov    (%eax),%eax
80101678:	83 f8 01             	cmp    $0x1,%eax
8010167b:	75 21                	jne    8010169e <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
8010167d:	8b 45 08             	mov    0x8(%ebp),%eax
80101680:	8b 40 0c             	mov    0xc(%eax),%eax
80101683:	8b 55 10             	mov    0x10(%ebp),%edx
80101686:	89 54 24 08          	mov    %edx,0x8(%esp)
8010168a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010168d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101691:	89 04 24             	mov    %eax,(%esp)
80101694:	e8 91 2f 00 00       	call   8010462a <pipewrite>
80101699:	e9 f5 00 00 00       	jmp    80101793 <filewrite+0x13c>
  if(f->type == FD_INODE){
8010169e:	8b 45 08             	mov    0x8(%ebp),%eax
801016a1:	8b 00                	mov    (%eax),%eax
801016a3:	83 f8 02             	cmp    $0x2,%eax
801016a6:	0f 85 db 00 00 00    	jne    80101787 <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801016ac:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
801016b3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
801016ba:	e9 a8 00 00 00       	jmp    80101767 <filewrite+0x110>
      int n1 = n - i;
801016bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016c2:	8b 55 10             	mov    0x10(%ebp),%edx
801016c5:	29 c2                	sub    %eax,%edx
801016c7:	89 d0                	mov    %edx,%eax
801016c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
801016cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016cf:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801016d2:	7e 06                	jle    801016da <filewrite+0x83>
        n1 = max;
801016d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016d7:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
801016da:	e8 6a 22 00 00       	call   80103949 <begin_op>
      ilock(f->ip);
801016df:	8b 45 08             	mov    0x8(%ebp),%eax
801016e2:	8b 40 10             	mov    0x10(%eax),%eax
801016e5:	89 04 24             	mov    %eax,(%esp)
801016e8:	e8 74 06 00 00       	call   80101d61 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
801016ed:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801016f0:	8b 45 08             	mov    0x8(%ebp),%eax
801016f3:	8b 50 14             	mov    0x14(%eax),%edx
801016f6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
801016f9:	8b 45 0c             	mov    0xc(%ebp),%eax
801016fc:	01 c3                	add    %eax,%ebx
801016fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101701:	8b 40 10             	mov    0x10(%eax),%eax
80101704:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101708:	89 54 24 08          	mov    %edx,0x8(%esp)
8010170c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101710:	89 04 24             	mov    %eax,(%esp)
80101713:	e8 c0 0c 00 00       	call   801023d8 <writei>
80101718:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010171b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010171f:	7e 11                	jle    80101732 <filewrite+0xdb>
        f->off += r;
80101721:	8b 45 08             	mov    0x8(%ebp),%eax
80101724:	8b 50 14             	mov    0x14(%eax),%edx
80101727:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010172a:	01 c2                	add    %eax,%edx
8010172c:	8b 45 08             	mov    0x8(%ebp),%eax
8010172f:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101732:	8b 45 08             	mov    0x8(%ebp),%eax
80101735:	8b 40 10             	mov    0x10(%eax),%eax
80101738:	89 04 24             	mov    %eax,(%esp)
8010173b:	e8 75 07 00 00       	call   80101eb5 <iunlock>
      end_op();
80101740:	e8 88 22 00 00       	call   801039cd <end_op>

      if(r < 0)
80101745:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101749:	79 02                	jns    8010174d <filewrite+0xf6>
        break;
8010174b:	eb 26                	jmp    80101773 <filewrite+0x11c>
      if(r != n1)
8010174d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101750:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80101753:	74 0c                	je     80101761 <filewrite+0x10a>
        panic("short filewrite");
80101755:	c7 04 24 84 89 10 80 	movl   $0x80108984,(%esp)
8010175c:	e8 d9 ed ff ff       	call   8010053a <panic>
      i += r;
80101761:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101764:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
80101767:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010176a:	3b 45 10             	cmp    0x10(%ebp),%eax
8010176d:	0f 8c 4c ff ff ff    	jl     801016bf <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
80101773:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101776:	3b 45 10             	cmp    0x10(%ebp),%eax
80101779:	75 05                	jne    80101780 <filewrite+0x129>
8010177b:	8b 45 10             	mov    0x10(%ebp),%eax
8010177e:	eb 05                	jmp    80101785 <filewrite+0x12e>
80101780:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101785:	eb 0c                	jmp    80101793 <filewrite+0x13c>
  }
  panic("filewrite");
80101787:	c7 04 24 94 89 10 80 	movl   $0x80108994,(%esp)
8010178e:	e8 a7 ed ff ff       	call   8010053a <panic>
}
80101793:	83 c4 24             	add    $0x24,%esp
80101796:	5b                   	pop    %ebx
80101797:	5d                   	pop    %ebp
80101798:	c3                   	ret    

80101799 <readsb>:
struct superblock sb;   // there should be one per dev, but we run with one dev

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101799:	55                   	push   %ebp
8010179a:	89 e5                	mov    %esp,%ebp
8010179c:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
8010179f:	8b 45 08             	mov    0x8(%ebp),%eax
801017a2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801017a9:	00 
801017aa:	89 04 24             	mov    %eax,(%esp)
801017ad:	e8 f4 e9 ff ff       	call   801001a6 <bread>
801017b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
801017b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b8:	83 c0 18             	add    $0x18,%eax
801017bb:	c7 44 24 08 1c 00 00 	movl   $0x1c,0x8(%esp)
801017c2:	00 
801017c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801017c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801017ca:	89 04 24             	mov    %eax,(%esp)
801017cd:	e8 82 3e 00 00       	call   80105654 <memmove>
  brelse(bp);
801017d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d5:	89 04 24             	mov    %eax,(%esp)
801017d8:	e8 3a ea ff ff       	call   80100217 <brelse>
}
801017dd:	c9                   	leave  
801017de:	c3                   	ret    

801017df <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
801017df:	55                   	push   %ebp
801017e0:	89 e5                	mov    %esp,%ebp
801017e2:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
801017e5:	8b 55 0c             	mov    0xc(%ebp),%edx
801017e8:	8b 45 08             	mov    0x8(%ebp),%eax
801017eb:	89 54 24 04          	mov    %edx,0x4(%esp)
801017ef:	89 04 24             	mov    %eax,(%esp)
801017f2:	e8 af e9 ff ff       	call   801001a6 <bread>
801017f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801017fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fd:	83 c0 18             	add    $0x18,%eax
80101800:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101807:	00 
80101808:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010180f:	00 
80101810:	89 04 24             	mov    %eax,(%esp)
80101813:	e8 6d 3d 00 00       	call   80105585 <memset>
  log_write(bp);
80101818:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010181b:	89 04 24             	mov    %eax,(%esp)
8010181e:	e8 31 23 00 00       	call   80103b54 <log_write>
  brelse(bp);
80101823:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101826:	89 04 24             	mov    %eax,(%esp)
80101829:	e8 e9 e9 ff ff       	call   80100217 <brelse>
}
8010182e:	c9                   	leave  
8010182f:	c3                   	ret    

80101830 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101830:	55                   	push   %ebp
80101831:	89 e5                	mov    %esp,%ebp
80101833:	83 ec 28             	sub    $0x28,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
80101836:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
8010183d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101844:	e9 07 01 00 00       	jmp    80101950 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
80101849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101852:	85 c0                	test   %eax,%eax
80101854:	0f 48 c2             	cmovs  %edx,%eax
80101857:	c1 f8 0c             	sar    $0xc,%eax
8010185a:	89 c2                	mov    %eax,%edx
8010185c:	a1 98 1a 11 80       	mov    0x80111a98,%eax
80101861:	01 d0                	add    %edx,%eax
80101863:	89 44 24 04          	mov    %eax,0x4(%esp)
80101867:	8b 45 08             	mov    0x8(%ebp),%eax
8010186a:	89 04 24             	mov    %eax,(%esp)
8010186d:	e8 34 e9 ff ff       	call   801001a6 <bread>
80101872:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101875:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010187c:	e9 9d 00 00 00       	jmp    8010191e <balloc+0xee>
      m = 1 << (bi % 8);
80101881:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101884:	99                   	cltd   
80101885:	c1 ea 1d             	shr    $0x1d,%edx
80101888:	01 d0                	add    %edx,%eax
8010188a:	83 e0 07             	and    $0x7,%eax
8010188d:	29 d0                	sub    %edx,%eax
8010188f:	ba 01 00 00 00       	mov    $0x1,%edx
80101894:	89 c1                	mov    %eax,%ecx
80101896:	d3 e2                	shl    %cl,%edx
80101898:	89 d0                	mov    %edx,%eax
8010189a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010189d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018a0:	8d 50 07             	lea    0x7(%eax),%edx
801018a3:	85 c0                	test   %eax,%eax
801018a5:	0f 48 c2             	cmovs  %edx,%eax
801018a8:	c1 f8 03             	sar    $0x3,%eax
801018ab:	8b 55 ec             	mov    -0x14(%ebp),%edx
801018ae:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801018b3:	0f b6 c0             	movzbl %al,%eax
801018b6:	23 45 e8             	and    -0x18(%ebp),%eax
801018b9:	85 c0                	test   %eax,%eax
801018bb:	75 5d                	jne    8010191a <balloc+0xea>
        bp->data[bi/8] |= m;  // Mark block in use.
801018bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018c0:	8d 50 07             	lea    0x7(%eax),%edx
801018c3:	85 c0                	test   %eax,%eax
801018c5:	0f 48 c2             	cmovs  %edx,%eax
801018c8:	c1 f8 03             	sar    $0x3,%eax
801018cb:	8b 55 ec             	mov    -0x14(%ebp),%edx
801018ce:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801018d3:	89 d1                	mov    %edx,%ecx
801018d5:	8b 55 e8             	mov    -0x18(%ebp),%edx
801018d8:	09 ca                	or     %ecx,%edx
801018da:	89 d1                	mov    %edx,%ecx
801018dc:	8b 55 ec             	mov    -0x14(%ebp),%edx
801018df:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
801018e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801018e6:	89 04 24             	mov    %eax,(%esp)
801018e9:	e8 66 22 00 00       	call   80103b54 <log_write>
        brelse(bp);
801018ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
801018f1:	89 04 24             	mov    %eax,(%esp)
801018f4:	e8 1e e9 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
801018f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018fc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801018ff:	01 c2                	add    %eax,%edx
80101901:	8b 45 08             	mov    0x8(%ebp),%eax
80101904:	89 54 24 04          	mov    %edx,0x4(%esp)
80101908:	89 04 24             	mov    %eax,(%esp)
8010190b:	e8 cf fe ff ff       	call   801017df <bzero>
        return b + bi;
80101910:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101913:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101916:	01 d0                	add    %edx,%eax
80101918:	eb 52                	jmp    8010196c <balloc+0x13c>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010191a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010191e:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101925:	7f 17                	jg     8010193e <balloc+0x10e>
80101927:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010192a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010192d:	01 d0                	add    %edx,%eax
8010192f:	89 c2                	mov    %eax,%edx
80101931:	a1 80 1a 11 80       	mov    0x80111a80,%eax
80101936:	39 c2                	cmp    %eax,%edx
80101938:	0f 82 43 ff ff ff    	jb     80101881 <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
8010193e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101941:	89 04 24             	mov    %eax,(%esp)
80101944:	e8 ce e8 ff ff       	call   80100217 <brelse>
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
80101949:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101950:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101953:	a1 80 1a 11 80       	mov    0x80111a80,%eax
80101958:	39 c2                	cmp    %eax,%edx
8010195a:	0f 82 e9 fe ff ff    	jb     80101849 <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101960:	c7 04 24 a0 89 10 80 	movl   $0x801089a0,(%esp)
80101967:	e8 ce eb ff ff       	call   8010053a <panic>
}
8010196c:	c9                   	leave  
8010196d:	c3                   	ret    

8010196e <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
8010196e:	55                   	push   %ebp
8010196f:	89 e5                	mov    %esp,%ebp
80101971:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
80101974:	c7 44 24 04 80 1a 11 	movl   $0x80111a80,0x4(%esp)
8010197b:	80 
8010197c:	8b 45 08             	mov    0x8(%ebp),%eax
8010197f:	89 04 24             	mov    %eax,(%esp)
80101982:	e8 12 fe ff ff       	call   80101799 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101987:	8b 45 0c             	mov    0xc(%ebp),%eax
8010198a:	c1 e8 0c             	shr    $0xc,%eax
8010198d:	89 c2                	mov    %eax,%edx
8010198f:	a1 98 1a 11 80       	mov    0x80111a98,%eax
80101994:	01 c2                	add    %eax,%edx
80101996:	8b 45 08             	mov    0x8(%ebp),%eax
80101999:	89 54 24 04          	mov    %edx,0x4(%esp)
8010199d:	89 04 24             	mov    %eax,(%esp)
801019a0:	e8 01 e8 ff ff       	call   801001a6 <bread>
801019a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
801019a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801019ab:	25 ff 0f 00 00       	and    $0xfff,%eax
801019b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
801019b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019b6:	99                   	cltd   
801019b7:	c1 ea 1d             	shr    $0x1d,%edx
801019ba:	01 d0                	add    %edx,%eax
801019bc:	83 e0 07             	and    $0x7,%eax
801019bf:	29 d0                	sub    %edx,%eax
801019c1:	ba 01 00 00 00       	mov    $0x1,%edx
801019c6:	89 c1                	mov    %eax,%ecx
801019c8:	d3 e2                	shl    %cl,%edx
801019ca:	89 d0                	mov    %edx,%eax
801019cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
801019cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019d2:	8d 50 07             	lea    0x7(%eax),%edx
801019d5:	85 c0                	test   %eax,%eax
801019d7:	0f 48 c2             	cmovs  %edx,%eax
801019da:	c1 f8 03             	sar    $0x3,%eax
801019dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801019e0:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801019e5:	0f b6 c0             	movzbl %al,%eax
801019e8:	23 45 ec             	and    -0x14(%ebp),%eax
801019eb:	85 c0                	test   %eax,%eax
801019ed:	75 0c                	jne    801019fb <bfree+0x8d>
    panic("freeing free block");
801019ef:	c7 04 24 b6 89 10 80 	movl   $0x801089b6,(%esp)
801019f6:	e8 3f eb ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
801019fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019fe:	8d 50 07             	lea    0x7(%eax),%edx
80101a01:	85 c0                	test   %eax,%eax
80101a03:	0f 48 c2             	cmovs  %edx,%eax
80101a06:	c1 f8 03             	sar    $0x3,%eax
80101a09:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101a0c:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101a11:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101a14:	f7 d1                	not    %ecx
80101a16:	21 ca                	and    %ecx,%edx
80101a18:	89 d1                	mov    %edx,%ecx
80101a1a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101a1d:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101a21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a24:	89 04 24             	mov    %eax,(%esp)
80101a27:	e8 28 21 00 00       	call   80103b54 <log_write>
  brelse(bp);
80101a2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a2f:	89 04 24             	mov    %eax,(%esp)
80101a32:	e8 e0 e7 ff ff       	call   80100217 <brelse>
}
80101a37:	c9                   	leave  
80101a38:	c3                   	ret    

80101a39 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
80101a39:	55                   	push   %ebp
80101a3a:	89 e5                	mov    %esp,%ebp
80101a3c:	57                   	push   %edi
80101a3d:	56                   	push   %esi
80101a3e:	53                   	push   %ebx
80101a3f:	83 ec 3c             	sub    $0x3c,%esp
  initlock(&icache.lock, "icache");
80101a42:	c7 44 24 04 c9 89 10 	movl   $0x801089c9,0x4(%esp)
80101a49:	80 
80101a4a:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101a51:	e8 ba 38 00 00       	call   80105310 <initlock>
  readsb(dev, &sb);
80101a56:	c7 44 24 04 80 1a 11 	movl   $0x80111a80,0x4(%esp)
80101a5d:	80 
80101a5e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a61:	89 04 24             	mov    %eax,(%esp)
80101a64:	e8 30 fd ff ff       	call   80101799 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d inodestart %d bmap start %d\n", sb.size,
80101a69:	a1 98 1a 11 80       	mov    0x80111a98,%eax
80101a6e:	8b 3d 94 1a 11 80    	mov    0x80111a94,%edi
80101a74:	8b 35 90 1a 11 80    	mov    0x80111a90,%esi
80101a7a:	8b 1d 8c 1a 11 80    	mov    0x80111a8c,%ebx
80101a80:	8b 0d 88 1a 11 80    	mov    0x80111a88,%ecx
80101a86:	8b 15 84 1a 11 80    	mov    0x80111a84,%edx
80101a8c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101a8f:	8b 15 80 1a 11 80    	mov    0x80111a80,%edx
80101a95:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101a99:	89 7c 24 18          	mov    %edi,0x18(%esp)
80101a9d:	89 74 24 14          	mov    %esi,0x14(%esp)
80101aa1:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80101aa5:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101aa9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101aac:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ab0:	89 d0                	mov    %edx,%eax
80101ab2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ab6:	c7 04 24 d0 89 10 80 	movl   $0x801089d0,(%esp)
80101abd:	e8 de e8 ff ff       	call   801003a0 <cprintf>
          sb.nblocks, sb.ninodes, sb.nlog, sb.logstart, sb.inodestart, sb.bmapstart);
}
80101ac2:	83 c4 3c             	add    $0x3c,%esp
80101ac5:	5b                   	pop    %ebx
80101ac6:	5e                   	pop    %esi
80101ac7:	5f                   	pop    %edi
80101ac8:	5d                   	pop    %ebp
80101ac9:	c3                   	ret    

80101aca <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101aca:	55                   	push   %ebp
80101acb:	89 e5                	mov    %esp,%ebp
80101acd:	83 ec 28             	sub    $0x28,%esp
80101ad0:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ad3:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101ad7:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101ade:	e9 9e 00 00 00       	jmp    80101b81 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
80101ae3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ae6:	c1 e8 03             	shr    $0x3,%eax
80101ae9:	89 c2                	mov    %eax,%edx
80101aeb:	a1 94 1a 11 80       	mov    0x80111a94,%eax
80101af0:	01 d0                	add    %edx,%eax
80101af2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101af6:	8b 45 08             	mov    0x8(%ebp),%eax
80101af9:	89 04 24             	mov    %eax,(%esp)
80101afc:	e8 a5 e6 ff ff       	call   801001a6 <bread>
80101b01:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101b04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b07:	8d 50 18             	lea    0x18(%eax),%edx
80101b0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b0d:	83 e0 07             	and    $0x7,%eax
80101b10:	c1 e0 06             	shl    $0x6,%eax
80101b13:	01 d0                	add    %edx,%eax
80101b15:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101b18:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101b1b:	0f b7 00             	movzwl (%eax),%eax
80101b1e:	66 85 c0             	test   %ax,%ax
80101b21:	75 4f                	jne    80101b72 <ialloc+0xa8>
      memset(dip, 0, sizeof(*dip));
80101b23:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101b2a:	00 
80101b2b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101b32:	00 
80101b33:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101b36:	89 04 24             	mov    %eax,(%esp)
80101b39:	e8 47 3a 00 00       	call   80105585 <memset>
      dip->type = type;
80101b3e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101b41:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
80101b45:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101b48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b4b:	89 04 24             	mov    %eax,(%esp)
80101b4e:	e8 01 20 00 00       	call   80103b54 <log_write>
      brelse(bp);
80101b53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b56:	89 04 24             	mov    %eax,(%esp)
80101b59:	e8 b9 e6 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101b5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b61:	89 44 24 04          	mov    %eax,0x4(%esp)
80101b65:	8b 45 08             	mov    0x8(%ebp),%eax
80101b68:	89 04 24             	mov    %eax,(%esp)
80101b6b:	e8 ed 00 00 00       	call   80101c5d <iget>
80101b70:	eb 2b                	jmp    80101b9d <ialloc+0xd3>
    }
    brelse(bp);
80101b72:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b75:	89 04 24             	mov    %eax,(%esp)
80101b78:	e8 9a e6 ff ff       	call   80100217 <brelse>
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101b7d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101b81:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b84:	a1 88 1a 11 80       	mov    0x80111a88,%eax
80101b89:	39 c2                	cmp    %eax,%edx
80101b8b:	0f 82 52 ff ff ff    	jb     80101ae3 <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101b91:	c7 04 24 23 8a 10 80 	movl   $0x80108a23,(%esp)
80101b98:	e8 9d e9 ff ff       	call   8010053a <panic>
}
80101b9d:	c9                   	leave  
80101b9e:	c3                   	ret    

80101b9f <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101b9f:	55                   	push   %ebp
80101ba0:	89 e5                	mov    %esp,%ebp
80101ba2:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101ba5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba8:	8b 40 04             	mov    0x4(%eax),%eax
80101bab:	c1 e8 03             	shr    $0x3,%eax
80101bae:	89 c2                	mov    %eax,%edx
80101bb0:	a1 94 1a 11 80       	mov    0x80111a94,%eax
80101bb5:	01 c2                	add    %eax,%edx
80101bb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bba:	8b 00                	mov    (%eax),%eax
80101bbc:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bc0:	89 04 24             	mov    %eax,(%esp)
80101bc3:	e8 de e5 ff ff       	call   801001a6 <bread>
80101bc8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101bcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bce:	8d 50 18             	lea    0x18(%eax),%edx
80101bd1:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd4:	8b 40 04             	mov    0x4(%eax),%eax
80101bd7:	83 e0 07             	and    $0x7,%eax
80101bda:	c1 e0 06             	shl    $0x6,%eax
80101bdd:	01 d0                	add    %edx,%eax
80101bdf:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101be2:	8b 45 08             	mov    0x8(%ebp),%eax
80101be5:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101be9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bec:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101bef:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf2:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101bf6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bf9:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101bfd:	8b 45 08             	mov    0x8(%ebp),%eax
80101c00:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101c04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c07:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101c0b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0e:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101c12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c15:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101c19:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1c:	8b 50 18             	mov    0x18(%eax),%edx
80101c1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c22:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101c25:	8b 45 08             	mov    0x8(%ebp),%eax
80101c28:	8d 50 1c             	lea    0x1c(%eax),%edx
80101c2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c2e:	83 c0 0c             	add    $0xc,%eax
80101c31:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101c38:	00 
80101c39:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c3d:	89 04 24             	mov    %eax,(%esp)
80101c40:	e8 0f 3a 00 00       	call   80105654 <memmove>
  log_write(bp);
80101c45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c48:	89 04 24             	mov    %eax,(%esp)
80101c4b:	e8 04 1f 00 00       	call   80103b54 <log_write>
  brelse(bp);
80101c50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c53:	89 04 24             	mov    %eax,(%esp)
80101c56:	e8 bc e5 ff ff       	call   80100217 <brelse>
}
80101c5b:	c9                   	leave  
80101c5c:	c3                   	ret    

80101c5d <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101c5d:	55                   	push   %ebp
80101c5e:	89 e5                	mov    %esp,%ebp
80101c60:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101c63:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101c6a:	e8 c2 36 00 00       	call   80105331 <acquire>

  // Is the inode already cached?
  empty = 0;
80101c6f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101c76:	c7 45 f4 d4 1a 11 80 	movl   $0x80111ad4,-0xc(%ebp)
80101c7d:	eb 59                	jmp    80101cd8 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101c7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c82:	8b 40 08             	mov    0x8(%eax),%eax
80101c85:	85 c0                	test   %eax,%eax
80101c87:	7e 35                	jle    80101cbe <iget+0x61>
80101c89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c8c:	8b 00                	mov    (%eax),%eax
80101c8e:	3b 45 08             	cmp    0x8(%ebp),%eax
80101c91:	75 2b                	jne    80101cbe <iget+0x61>
80101c93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c96:	8b 40 04             	mov    0x4(%eax),%eax
80101c99:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101c9c:	75 20                	jne    80101cbe <iget+0x61>
      ip->ref++;
80101c9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ca1:	8b 40 08             	mov    0x8(%eax),%eax
80101ca4:	8d 50 01             	lea    0x1(%eax),%edx
80101ca7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101caa:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101cad:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101cb4:	e8 da 36 00 00       	call   80105393 <release>
      return ip;
80101cb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cbc:	eb 6f                	jmp    80101d2d <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101cbe:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101cc2:	75 10                	jne    80101cd4 <iget+0x77>
80101cc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cc7:	8b 40 08             	mov    0x8(%eax),%eax
80101cca:	85 c0                	test   %eax,%eax
80101ccc:	75 06                	jne    80101cd4 <iget+0x77>
      empty = ip;
80101cce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cd1:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101cd4:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101cd8:	81 7d f4 74 2a 11 80 	cmpl   $0x80112a74,-0xc(%ebp)
80101cdf:	72 9e                	jb     80101c7f <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101ce1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101ce5:	75 0c                	jne    80101cf3 <iget+0x96>
    panic("iget: no inodes");
80101ce7:	c7 04 24 35 8a 10 80 	movl   $0x80108a35,(%esp)
80101cee:	e8 47 e8 ff ff       	call   8010053a <panic>

  ip = empty;
80101cf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cf6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101cf9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cfc:	8b 55 08             	mov    0x8(%ebp),%edx
80101cff:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101d01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d04:	8b 55 0c             	mov    0xc(%ebp),%edx
80101d07:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101d0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d0d:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101d14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d17:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101d1e:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101d25:	e8 69 36 00 00       	call   80105393 <release>

  return ip;
80101d2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101d2d:	c9                   	leave  
80101d2e:	c3                   	ret    

80101d2f <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101d2f:	55                   	push   %ebp
80101d30:	89 e5                	mov    %esp,%ebp
80101d32:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101d35:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101d3c:	e8 f0 35 00 00       	call   80105331 <acquire>
  ip->ref++;
80101d41:	8b 45 08             	mov    0x8(%ebp),%eax
80101d44:	8b 40 08             	mov    0x8(%eax),%eax
80101d47:	8d 50 01             	lea    0x1(%eax),%edx
80101d4a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4d:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101d50:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101d57:	e8 37 36 00 00       	call   80105393 <release>
  return ip;
80101d5c:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101d5f:	c9                   	leave  
80101d60:	c3                   	ret    

80101d61 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101d61:	55                   	push   %ebp
80101d62:	89 e5                	mov    %esp,%ebp
80101d64:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101d67:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101d6b:	74 0a                	je     80101d77 <ilock+0x16>
80101d6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d70:	8b 40 08             	mov    0x8(%eax),%eax
80101d73:	85 c0                	test   %eax,%eax
80101d75:	7f 0c                	jg     80101d83 <ilock+0x22>
    panic("ilock");
80101d77:	c7 04 24 45 8a 10 80 	movl   $0x80108a45,(%esp)
80101d7e:	e8 b7 e7 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101d83:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101d8a:	e8 a2 35 00 00       	call   80105331 <acquire>
  while(ip->flags & I_BUSY)
80101d8f:	eb 13                	jmp    80101da4 <ilock+0x43>
    sleep(ip, &icache.lock);
80101d91:	c7 44 24 04 a0 1a 11 	movl   $0x80111aa0,0x4(%esp)
80101d98:	80 
80101d99:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9c:	89 04 24             	mov    %eax,(%esp)
80101d9f:	e8 c3 32 00 00       	call   80105067 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101da4:	8b 45 08             	mov    0x8(%ebp),%eax
80101da7:	8b 40 0c             	mov    0xc(%eax),%eax
80101daa:	83 e0 01             	and    $0x1,%eax
80101dad:	85 c0                	test   %eax,%eax
80101daf:	75 e0                	jne    80101d91 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101db1:	8b 45 08             	mov    0x8(%ebp),%eax
80101db4:	8b 40 0c             	mov    0xc(%eax),%eax
80101db7:	83 c8 01             	or     $0x1,%eax
80101dba:	89 c2                	mov    %eax,%edx
80101dbc:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbf:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101dc2:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101dc9:	e8 c5 35 00 00       	call   80105393 <release>

  if(!(ip->flags & I_VALID)){
80101dce:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd1:	8b 40 0c             	mov    0xc(%eax),%eax
80101dd4:	83 e0 02             	and    $0x2,%eax
80101dd7:	85 c0                	test   %eax,%eax
80101dd9:	0f 85 d4 00 00 00    	jne    80101eb3 <ilock+0x152>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101ddf:	8b 45 08             	mov    0x8(%ebp),%eax
80101de2:	8b 40 04             	mov    0x4(%eax),%eax
80101de5:	c1 e8 03             	shr    $0x3,%eax
80101de8:	89 c2                	mov    %eax,%edx
80101dea:	a1 94 1a 11 80       	mov    0x80111a94,%eax
80101def:	01 c2                	add    %eax,%edx
80101df1:	8b 45 08             	mov    0x8(%ebp),%eax
80101df4:	8b 00                	mov    (%eax),%eax
80101df6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dfa:	89 04 24             	mov    %eax,(%esp)
80101dfd:	e8 a4 e3 ff ff       	call   801001a6 <bread>
80101e02:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101e05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e08:	8d 50 18             	lea    0x18(%eax),%edx
80101e0b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e0e:	8b 40 04             	mov    0x4(%eax),%eax
80101e11:	83 e0 07             	and    $0x7,%eax
80101e14:	c1 e0 06             	shl    $0x6,%eax
80101e17:	01 d0                	add    %edx,%eax
80101e19:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101e1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e1f:	0f b7 10             	movzwl (%eax),%edx
80101e22:	8b 45 08             	mov    0x8(%ebp),%eax
80101e25:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101e29:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e2c:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101e30:	8b 45 08             	mov    0x8(%ebp),%eax
80101e33:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101e37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e3a:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101e3e:	8b 45 08             	mov    0x8(%ebp),%eax
80101e41:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101e45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e48:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101e4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e4f:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101e53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e56:	8b 50 08             	mov    0x8(%eax),%edx
80101e59:	8b 45 08             	mov    0x8(%ebp),%eax
80101e5c:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101e5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e62:	8d 50 0c             	lea    0xc(%eax),%edx
80101e65:	8b 45 08             	mov    0x8(%ebp),%eax
80101e68:	83 c0 1c             	add    $0x1c,%eax
80101e6b:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101e72:	00 
80101e73:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e77:	89 04 24             	mov    %eax,(%esp)
80101e7a:	e8 d5 37 00 00       	call   80105654 <memmove>
    brelse(bp);
80101e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e82:	89 04 24             	mov    %eax,(%esp)
80101e85:	e8 8d e3 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101e8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8d:	8b 40 0c             	mov    0xc(%eax),%eax
80101e90:	83 c8 02             	or     $0x2,%eax
80101e93:	89 c2                	mov    %eax,%edx
80101e95:	8b 45 08             	mov    0x8(%ebp),%eax
80101e98:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101e9b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e9e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101ea2:	66 85 c0             	test   %ax,%ax
80101ea5:	75 0c                	jne    80101eb3 <ilock+0x152>
      panic("ilock: no type");
80101ea7:	c7 04 24 4b 8a 10 80 	movl   $0x80108a4b,(%esp)
80101eae:	e8 87 e6 ff ff       	call   8010053a <panic>
  }
}
80101eb3:	c9                   	leave  
80101eb4:	c3                   	ret    

80101eb5 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101eb5:	55                   	push   %ebp
80101eb6:	89 e5                	mov    %esp,%ebp
80101eb8:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101ebb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101ebf:	74 17                	je     80101ed8 <iunlock+0x23>
80101ec1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec4:	8b 40 0c             	mov    0xc(%eax),%eax
80101ec7:	83 e0 01             	and    $0x1,%eax
80101eca:	85 c0                	test   %eax,%eax
80101ecc:	74 0a                	je     80101ed8 <iunlock+0x23>
80101ece:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed1:	8b 40 08             	mov    0x8(%eax),%eax
80101ed4:	85 c0                	test   %eax,%eax
80101ed6:	7f 0c                	jg     80101ee4 <iunlock+0x2f>
    panic("iunlock");
80101ed8:	c7 04 24 5a 8a 10 80 	movl   $0x80108a5a,(%esp)
80101edf:	e8 56 e6 ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101ee4:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101eeb:	e8 41 34 00 00       	call   80105331 <acquire>
  ip->flags &= ~I_BUSY;
80101ef0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef3:	8b 40 0c             	mov    0xc(%eax),%eax
80101ef6:	83 e0 fe             	and    $0xfffffffe,%eax
80101ef9:	89 c2                	mov    %eax,%edx
80101efb:	8b 45 08             	mov    0x8(%ebp),%eax
80101efe:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101f01:	8b 45 08             	mov    0x8(%ebp),%eax
80101f04:	89 04 24             	mov    %eax,(%esp)
80101f07:	e8 34 32 00 00       	call   80105140 <wakeup>
  release(&icache.lock);
80101f0c:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101f13:	e8 7b 34 00 00       	call   80105393 <release>
}
80101f18:	c9                   	leave  
80101f19:	c3                   	ret    

80101f1a <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101f1a:	55                   	push   %ebp
80101f1b:	89 e5                	mov    %esp,%ebp
80101f1d:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101f20:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101f27:	e8 05 34 00 00       	call   80105331 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101f2c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f2f:	8b 40 08             	mov    0x8(%eax),%eax
80101f32:	83 f8 01             	cmp    $0x1,%eax
80101f35:	0f 85 93 00 00 00    	jne    80101fce <iput+0xb4>
80101f3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101f3e:	8b 40 0c             	mov    0xc(%eax),%eax
80101f41:	83 e0 02             	and    $0x2,%eax
80101f44:	85 c0                	test   %eax,%eax
80101f46:	0f 84 82 00 00 00    	je     80101fce <iput+0xb4>
80101f4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101f53:	66 85 c0             	test   %ax,%ax
80101f56:	75 76                	jne    80101fce <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101f58:	8b 45 08             	mov    0x8(%ebp),%eax
80101f5b:	8b 40 0c             	mov    0xc(%eax),%eax
80101f5e:	83 e0 01             	and    $0x1,%eax
80101f61:	85 c0                	test   %eax,%eax
80101f63:	74 0c                	je     80101f71 <iput+0x57>
      panic("iput busy");
80101f65:	c7 04 24 62 8a 10 80 	movl   $0x80108a62,(%esp)
80101f6c:	e8 c9 e5 ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101f71:	8b 45 08             	mov    0x8(%ebp),%eax
80101f74:	8b 40 0c             	mov    0xc(%eax),%eax
80101f77:	83 c8 01             	or     $0x1,%eax
80101f7a:	89 c2                	mov    %eax,%edx
80101f7c:	8b 45 08             	mov    0x8(%ebp),%eax
80101f7f:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101f82:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101f89:	e8 05 34 00 00       	call   80105393 <release>
    itrunc(ip);
80101f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80101f91:	89 04 24             	mov    %eax,(%esp)
80101f94:	e8 7d 01 00 00       	call   80102116 <itrunc>
    ip->type = 0;
80101f99:	8b 45 08             	mov    0x8(%ebp),%eax
80101f9c:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101fa2:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa5:	89 04 24             	mov    %eax,(%esp)
80101fa8:	e8 f2 fb ff ff       	call   80101b9f <iupdate>
    acquire(&icache.lock);
80101fad:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101fb4:	e8 78 33 00 00       	call   80105331 <acquire>
    ip->flags = 0;
80101fb9:	8b 45 08             	mov    0x8(%ebp),%eax
80101fbc:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101fc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc6:	89 04 24             	mov    %eax,(%esp)
80101fc9:	e8 72 31 00 00       	call   80105140 <wakeup>
  }
  ip->ref--;
80101fce:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd1:	8b 40 08             	mov    0x8(%eax),%eax
80101fd4:	8d 50 ff             	lea    -0x1(%eax),%edx
80101fd7:	8b 45 08             	mov    0x8(%ebp),%eax
80101fda:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101fdd:	c7 04 24 a0 1a 11 80 	movl   $0x80111aa0,(%esp)
80101fe4:	e8 aa 33 00 00       	call   80105393 <release>
}
80101fe9:	c9                   	leave  
80101fea:	c3                   	ret    

80101feb <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101feb:	55                   	push   %ebp
80101fec:	89 e5                	mov    %esp,%ebp
80101fee:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101ff1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ff4:	89 04 24             	mov    %eax,(%esp)
80101ff7:	e8 b9 fe ff ff       	call   80101eb5 <iunlock>
  iput(ip);
80101ffc:	8b 45 08             	mov    0x8(%ebp),%eax
80101fff:	89 04 24             	mov    %eax,(%esp)
80102002:	e8 13 ff ff ff       	call   80101f1a <iput>
}
80102007:	c9                   	leave  
80102008:	c3                   	ret    

80102009 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80102009:	55                   	push   %ebp
8010200a:	89 e5                	mov    %esp,%ebp
8010200c:	53                   	push   %ebx
8010200d:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80102010:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80102014:	77 3e                	ja     80102054 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80102016:	8b 45 08             	mov    0x8(%ebp),%eax
80102019:	8b 55 0c             	mov    0xc(%ebp),%edx
8010201c:	83 c2 04             	add    $0x4,%edx
8010201f:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102023:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102026:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010202a:	75 20                	jne    8010204c <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
8010202c:	8b 45 08             	mov    0x8(%ebp),%eax
8010202f:	8b 00                	mov    (%eax),%eax
80102031:	89 04 24             	mov    %eax,(%esp)
80102034:	e8 f7 f7 ff ff       	call   80101830 <balloc>
80102039:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010203c:	8b 45 08             	mov    0x8(%ebp),%eax
8010203f:	8b 55 0c             	mov    0xc(%ebp),%edx
80102042:	8d 4a 04             	lea    0x4(%edx),%ecx
80102045:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102048:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
8010204c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010204f:	e9 bc 00 00 00       	jmp    80102110 <bmap+0x107>
  }
  bn -= NDIRECT;
80102054:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80102058:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
8010205c:	0f 87 a2 00 00 00    	ja     80102104 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80102062:	8b 45 08             	mov    0x8(%ebp),%eax
80102065:	8b 40 4c             	mov    0x4c(%eax),%eax
80102068:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010206b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010206f:	75 19                	jne    8010208a <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80102071:	8b 45 08             	mov    0x8(%ebp),%eax
80102074:	8b 00                	mov    (%eax),%eax
80102076:	89 04 24             	mov    %eax,(%esp)
80102079:	e8 b2 f7 ff ff       	call   80101830 <balloc>
8010207e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102081:	8b 45 08             	mov    0x8(%ebp),%eax
80102084:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102087:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
8010208a:	8b 45 08             	mov    0x8(%ebp),%eax
8010208d:	8b 00                	mov    (%eax),%eax
8010208f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102092:	89 54 24 04          	mov    %edx,0x4(%esp)
80102096:	89 04 24             	mov    %eax,(%esp)
80102099:	e8 08 e1 ff ff       	call   801001a6 <bread>
8010209e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
801020a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020a4:	83 c0 18             	add    $0x18,%eax
801020a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
801020aa:	8b 45 0c             	mov    0xc(%ebp),%eax
801020ad:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801020b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020b7:	01 d0                	add    %edx,%eax
801020b9:	8b 00                	mov    (%eax),%eax
801020bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801020be:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801020c2:	75 30                	jne    801020f4 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
801020c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801020c7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801020ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020d1:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801020d4:	8b 45 08             	mov    0x8(%ebp),%eax
801020d7:	8b 00                	mov    (%eax),%eax
801020d9:	89 04 24             	mov    %eax,(%esp)
801020dc:	e8 4f f7 ff ff       	call   80101830 <balloc>
801020e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801020e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020e7:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
801020e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020ec:	89 04 24             	mov    %eax,(%esp)
801020ef:	e8 60 1a 00 00       	call   80103b54 <log_write>
    }
    brelse(bp);
801020f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020f7:	89 04 24             	mov    %eax,(%esp)
801020fa:	e8 18 e1 ff ff       	call   80100217 <brelse>
    return addr;
801020ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102102:	eb 0c                	jmp    80102110 <bmap+0x107>
  }

  panic("bmap: out of range");
80102104:	c7 04 24 6c 8a 10 80 	movl   $0x80108a6c,(%esp)
8010210b:	e8 2a e4 ff ff       	call   8010053a <panic>
}
80102110:	83 c4 24             	add    $0x24,%esp
80102113:	5b                   	pop    %ebx
80102114:	5d                   	pop    %ebp
80102115:	c3                   	ret    

80102116 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80102116:	55                   	push   %ebp
80102117:	89 e5                	mov    %esp,%ebp
80102119:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
8010211c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102123:	eb 44                	jmp    80102169 <itrunc+0x53>
    if(ip->addrs[i]){
80102125:	8b 45 08             	mov    0x8(%ebp),%eax
80102128:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010212b:	83 c2 04             	add    $0x4,%edx
8010212e:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102132:	85 c0                	test   %eax,%eax
80102134:	74 2f                	je     80102165 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80102136:	8b 45 08             	mov    0x8(%ebp),%eax
80102139:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010213c:	83 c2 04             	add    $0x4,%edx
8010213f:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80102143:	8b 45 08             	mov    0x8(%ebp),%eax
80102146:	8b 00                	mov    (%eax),%eax
80102148:	89 54 24 04          	mov    %edx,0x4(%esp)
8010214c:	89 04 24             	mov    %eax,(%esp)
8010214f:	e8 1a f8 ff ff       	call   8010196e <bfree>
      ip->addrs[i] = 0;
80102154:	8b 45 08             	mov    0x8(%ebp),%eax
80102157:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010215a:	83 c2 04             	add    $0x4,%edx
8010215d:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80102164:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102165:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102169:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
8010216d:	7e b6                	jle    80102125 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
8010216f:	8b 45 08             	mov    0x8(%ebp),%eax
80102172:	8b 40 4c             	mov    0x4c(%eax),%eax
80102175:	85 c0                	test   %eax,%eax
80102177:	0f 84 9b 00 00 00    	je     80102218 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
8010217d:	8b 45 08             	mov    0x8(%ebp),%eax
80102180:	8b 50 4c             	mov    0x4c(%eax),%edx
80102183:	8b 45 08             	mov    0x8(%ebp),%eax
80102186:	8b 00                	mov    (%eax),%eax
80102188:	89 54 24 04          	mov    %edx,0x4(%esp)
8010218c:	89 04 24             	mov    %eax,(%esp)
8010218f:	e8 12 e0 ff ff       	call   801001a6 <bread>
80102194:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102197:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010219a:	83 c0 18             	add    $0x18,%eax
8010219d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
801021a0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801021a7:	eb 3b                	jmp    801021e4 <itrunc+0xce>
      if(a[j])
801021a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021ac:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801021b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801021b6:	01 d0                	add    %edx,%eax
801021b8:	8b 00                	mov    (%eax),%eax
801021ba:	85 c0                	test   %eax,%eax
801021bc:	74 22                	je     801021e0 <itrunc+0xca>
        bfree(ip->dev, a[j]);
801021be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021c1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801021c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801021cb:	01 d0                	add    %edx,%eax
801021cd:	8b 10                	mov    (%eax),%edx
801021cf:	8b 45 08             	mov    0x8(%ebp),%eax
801021d2:	8b 00                	mov    (%eax),%eax
801021d4:	89 54 24 04          	mov    %edx,0x4(%esp)
801021d8:	89 04 24             	mov    %eax,(%esp)
801021db:	e8 8e f7 ff ff       	call   8010196e <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
801021e0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801021e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021e7:	83 f8 7f             	cmp    $0x7f,%eax
801021ea:	76 bd                	jbe    801021a9 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
801021ec:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021ef:	89 04 24             	mov    %eax,(%esp)
801021f2:	e8 20 e0 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
801021f7:	8b 45 08             	mov    0x8(%ebp),%eax
801021fa:	8b 50 4c             	mov    0x4c(%eax),%edx
801021fd:	8b 45 08             	mov    0x8(%ebp),%eax
80102200:	8b 00                	mov    (%eax),%eax
80102202:	89 54 24 04          	mov    %edx,0x4(%esp)
80102206:	89 04 24             	mov    %eax,(%esp)
80102209:	e8 60 f7 ff ff       	call   8010196e <bfree>
    ip->addrs[NDIRECT] = 0;
8010220e:	8b 45 08             	mov    0x8(%ebp),%eax
80102211:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80102218:	8b 45 08             	mov    0x8(%ebp),%eax
8010221b:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102222:	8b 45 08             	mov    0x8(%ebp),%eax
80102225:	89 04 24             	mov    %eax,(%esp)
80102228:	e8 72 f9 ff ff       	call   80101b9f <iupdate>
}
8010222d:	c9                   	leave  
8010222e:	c3                   	ret    

8010222f <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
8010222f:	55                   	push   %ebp
80102230:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80102232:	8b 45 08             	mov    0x8(%ebp),%eax
80102235:	8b 00                	mov    (%eax),%eax
80102237:	89 c2                	mov    %eax,%edx
80102239:	8b 45 0c             	mov    0xc(%ebp),%eax
8010223c:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
8010223f:	8b 45 08             	mov    0x8(%ebp),%eax
80102242:	8b 50 04             	mov    0x4(%eax),%edx
80102245:	8b 45 0c             	mov    0xc(%ebp),%eax
80102248:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
8010224b:	8b 45 08             	mov    0x8(%ebp),%eax
8010224e:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102252:	8b 45 0c             	mov    0xc(%ebp),%eax
80102255:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80102258:	8b 45 08             	mov    0x8(%ebp),%eax
8010225b:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010225f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102262:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80102266:	8b 45 08             	mov    0x8(%ebp),%eax
80102269:	8b 50 18             	mov    0x18(%eax),%edx
8010226c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010226f:	89 50 10             	mov    %edx,0x10(%eax)
}
80102272:	5d                   	pop    %ebp
80102273:	c3                   	ret    

80102274 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80102274:	55                   	push   %ebp
80102275:	89 e5                	mov    %esp,%ebp
80102277:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
8010227a:	8b 45 08             	mov    0x8(%ebp),%eax
8010227d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102281:	66 83 f8 03          	cmp    $0x3,%ax
80102285:	75 60                	jne    801022e7 <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80102287:	8b 45 08             	mov    0x8(%ebp),%eax
8010228a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010228e:	66 85 c0             	test   %ax,%ax
80102291:	78 20                	js     801022b3 <readi+0x3f>
80102293:	8b 45 08             	mov    0x8(%ebp),%eax
80102296:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010229a:	66 83 f8 09          	cmp    $0x9,%ax
8010229e:	7f 13                	jg     801022b3 <readi+0x3f>
801022a0:	8b 45 08             	mov    0x8(%ebp),%eax
801022a3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801022a7:	98                   	cwtl   
801022a8:	8b 04 c5 20 1a 11 80 	mov    -0x7feee5e0(,%eax,8),%eax
801022af:	85 c0                	test   %eax,%eax
801022b1:	75 0a                	jne    801022bd <readi+0x49>
      return -1;
801022b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022b8:	e9 19 01 00 00       	jmp    801023d6 <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
801022bd:	8b 45 08             	mov    0x8(%ebp),%eax
801022c0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801022c4:	98                   	cwtl   
801022c5:	8b 04 c5 20 1a 11 80 	mov    -0x7feee5e0(,%eax,8),%eax
801022cc:	8b 55 14             	mov    0x14(%ebp),%edx
801022cf:	89 54 24 08          	mov    %edx,0x8(%esp)
801022d3:	8b 55 0c             	mov    0xc(%ebp),%edx
801022d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801022da:	8b 55 08             	mov    0x8(%ebp),%edx
801022dd:	89 14 24             	mov    %edx,(%esp)
801022e0:	ff d0                	call   *%eax
801022e2:	e9 ef 00 00 00       	jmp    801023d6 <readi+0x162>
  }

  if(off > ip->size || off + n < off)
801022e7:	8b 45 08             	mov    0x8(%ebp),%eax
801022ea:	8b 40 18             	mov    0x18(%eax),%eax
801022ed:	3b 45 10             	cmp    0x10(%ebp),%eax
801022f0:	72 0d                	jb     801022ff <readi+0x8b>
801022f2:	8b 45 14             	mov    0x14(%ebp),%eax
801022f5:	8b 55 10             	mov    0x10(%ebp),%edx
801022f8:	01 d0                	add    %edx,%eax
801022fa:	3b 45 10             	cmp    0x10(%ebp),%eax
801022fd:	73 0a                	jae    80102309 <readi+0x95>
    return -1;
801022ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102304:	e9 cd 00 00 00       	jmp    801023d6 <readi+0x162>
  if(off + n > ip->size)
80102309:	8b 45 14             	mov    0x14(%ebp),%eax
8010230c:	8b 55 10             	mov    0x10(%ebp),%edx
8010230f:	01 c2                	add    %eax,%edx
80102311:	8b 45 08             	mov    0x8(%ebp),%eax
80102314:	8b 40 18             	mov    0x18(%eax),%eax
80102317:	39 c2                	cmp    %eax,%edx
80102319:	76 0c                	jbe    80102327 <readi+0xb3>
    n = ip->size - off;
8010231b:	8b 45 08             	mov    0x8(%ebp),%eax
8010231e:	8b 40 18             	mov    0x18(%eax),%eax
80102321:	2b 45 10             	sub    0x10(%ebp),%eax
80102324:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102327:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010232e:	e9 94 00 00 00       	jmp    801023c7 <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102333:	8b 45 10             	mov    0x10(%ebp),%eax
80102336:	c1 e8 09             	shr    $0x9,%eax
80102339:	89 44 24 04          	mov    %eax,0x4(%esp)
8010233d:	8b 45 08             	mov    0x8(%ebp),%eax
80102340:	89 04 24             	mov    %eax,(%esp)
80102343:	e8 c1 fc ff ff       	call   80102009 <bmap>
80102348:	8b 55 08             	mov    0x8(%ebp),%edx
8010234b:	8b 12                	mov    (%edx),%edx
8010234d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102351:	89 14 24             	mov    %edx,(%esp)
80102354:	e8 4d de ff ff       	call   801001a6 <bread>
80102359:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
8010235c:	8b 45 10             	mov    0x10(%ebp),%eax
8010235f:	25 ff 01 00 00       	and    $0x1ff,%eax
80102364:	89 c2                	mov    %eax,%edx
80102366:	b8 00 02 00 00       	mov    $0x200,%eax
8010236b:	29 d0                	sub    %edx,%eax
8010236d:	89 c2                	mov    %eax,%edx
8010236f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102372:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102375:	29 c1                	sub    %eax,%ecx
80102377:	89 c8                	mov    %ecx,%eax
80102379:	39 c2                	cmp    %eax,%edx
8010237b:	0f 46 c2             	cmovbe %edx,%eax
8010237e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80102381:	8b 45 10             	mov    0x10(%ebp),%eax
80102384:	25 ff 01 00 00       	and    $0x1ff,%eax
80102389:	8d 50 10             	lea    0x10(%eax),%edx
8010238c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010238f:	01 d0                	add    %edx,%eax
80102391:	8d 50 08             	lea    0x8(%eax),%edx
80102394:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102397:	89 44 24 08          	mov    %eax,0x8(%esp)
8010239b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010239f:	8b 45 0c             	mov    0xc(%ebp),%eax
801023a2:	89 04 24             	mov    %eax,(%esp)
801023a5:	e8 aa 32 00 00       	call   80105654 <memmove>
    brelse(bp);
801023aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023ad:	89 04 24             	mov    %eax,(%esp)
801023b0:	e8 62 de ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801023b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801023b8:	01 45 f4             	add    %eax,-0xc(%ebp)
801023bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801023be:	01 45 10             	add    %eax,0x10(%ebp)
801023c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801023c4:	01 45 0c             	add    %eax,0xc(%ebp)
801023c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ca:	3b 45 14             	cmp    0x14(%ebp),%eax
801023cd:	0f 82 60 ff ff ff    	jb     80102333 <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
801023d3:	8b 45 14             	mov    0x14(%ebp),%eax
}
801023d6:	c9                   	leave  
801023d7:	c3                   	ret    

801023d8 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
801023d8:	55                   	push   %ebp
801023d9:	89 e5                	mov    %esp,%ebp
801023db:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
801023de:	8b 45 08             	mov    0x8(%ebp),%eax
801023e1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801023e5:	66 83 f8 03          	cmp    $0x3,%ax
801023e9:	75 60                	jne    8010244b <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801023eb:	8b 45 08             	mov    0x8(%ebp),%eax
801023ee:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801023f2:	66 85 c0             	test   %ax,%ax
801023f5:	78 20                	js     80102417 <writei+0x3f>
801023f7:	8b 45 08             	mov    0x8(%ebp),%eax
801023fa:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801023fe:	66 83 f8 09          	cmp    $0x9,%ax
80102402:	7f 13                	jg     80102417 <writei+0x3f>
80102404:	8b 45 08             	mov    0x8(%ebp),%eax
80102407:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010240b:	98                   	cwtl   
8010240c:	8b 04 c5 24 1a 11 80 	mov    -0x7feee5dc(,%eax,8),%eax
80102413:	85 c0                	test   %eax,%eax
80102415:	75 0a                	jne    80102421 <writei+0x49>
      return -1;
80102417:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010241c:	e9 44 01 00 00       	jmp    80102565 <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
80102421:	8b 45 08             	mov    0x8(%ebp),%eax
80102424:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102428:	98                   	cwtl   
80102429:	8b 04 c5 24 1a 11 80 	mov    -0x7feee5dc(,%eax,8),%eax
80102430:	8b 55 14             	mov    0x14(%ebp),%edx
80102433:	89 54 24 08          	mov    %edx,0x8(%esp)
80102437:	8b 55 0c             	mov    0xc(%ebp),%edx
8010243a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010243e:	8b 55 08             	mov    0x8(%ebp),%edx
80102441:	89 14 24             	mov    %edx,(%esp)
80102444:	ff d0                	call   *%eax
80102446:	e9 1a 01 00 00       	jmp    80102565 <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
8010244b:	8b 45 08             	mov    0x8(%ebp),%eax
8010244e:	8b 40 18             	mov    0x18(%eax),%eax
80102451:	3b 45 10             	cmp    0x10(%ebp),%eax
80102454:	72 0d                	jb     80102463 <writei+0x8b>
80102456:	8b 45 14             	mov    0x14(%ebp),%eax
80102459:	8b 55 10             	mov    0x10(%ebp),%edx
8010245c:	01 d0                	add    %edx,%eax
8010245e:	3b 45 10             	cmp    0x10(%ebp),%eax
80102461:	73 0a                	jae    8010246d <writei+0x95>
    return -1;
80102463:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102468:	e9 f8 00 00 00       	jmp    80102565 <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
8010246d:	8b 45 14             	mov    0x14(%ebp),%eax
80102470:	8b 55 10             	mov    0x10(%ebp),%edx
80102473:	01 d0                	add    %edx,%eax
80102475:	3d 00 18 01 00       	cmp    $0x11800,%eax
8010247a:	76 0a                	jbe    80102486 <writei+0xae>
    return -1;
8010247c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102481:	e9 df 00 00 00       	jmp    80102565 <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102486:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010248d:	e9 9f 00 00 00       	jmp    80102531 <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102492:	8b 45 10             	mov    0x10(%ebp),%eax
80102495:	c1 e8 09             	shr    $0x9,%eax
80102498:	89 44 24 04          	mov    %eax,0x4(%esp)
8010249c:	8b 45 08             	mov    0x8(%ebp),%eax
8010249f:	89 04 24             	mov    %eax,(%esp)
801024a2:	e8 62 fb ff ff       	call   80102009 <bmap>
801024a7:	8b 55 08             	mov    0x8(%ebp),%edx
801024aa:	8b 12                	mov    (%edx),%edx
801024ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801024b0:	89 14 24             	mov    %edx,(%esp)
801024b3:	e8 ee dc ff ff       	call   801001a6 <bread>
801024b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801024bb:	8b 45 10             	mov    0x10(%ebp),%eax
801024be:	25 ff 01 00 00       	and    $0x1ff,%eax
801024c3:	89 c2                	mov    %eax,%edx
801024c5:	b8 00 02 00 00       	mov    $0x200,%eax
801024ca:	29 d0                	sub    %edx,%eax
801024cc:	89 c2                	mov    %eax,%edx
801024ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024d1:	8b 4d 14             	mov    0x14(%ebp),%ecx
801024d4:	29 c1                	sub    %eax,%ecx
801024d6:	89 c8                	mov    %ecx,%eax
801024d8:	39 c2                	cmp    %eax,%edx
801024da:	0f 46 c2             	cmovbe %edx,%eax
801024dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
801024e0:	8b 45 10             	mov    0x10(%ebp),%eax
801024e3:	25 ff 01 00 00       	and    $0x1ff,%eax
801024e8:	8d 50 10             	lea    0x10(%eax),%edx
801024eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024ee:	01 d0                	add    %edx,%eax
801024f0:	8d 50 08             	lea    0x8(%eax),%edx
801024f3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801024f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801024fa:	8b 45 0c             	mov    0xc(%ebp),%eax
801024fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80102501:	89 14 24             	mov    %edx,(%esp)
80102504:	e8 4b 31 00 00       	call   80105654 <memmove>
    log_write(bp);
80102509:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010250c:	89 04 24             	mov    %eax,(%esp)
8010250f:	e8 40 16 00 00       	call   80103b54 <log_write>
    brelse(bp);
80102514:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102517:	89 04 24             	mov    %eax,(%esp)
8010251a:	e8 f8 dc ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010251f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102522:	01 45 f4             	add    %eax,-0xc(%ebp)
80102525:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102528:	01 45 10             	add    %eax,0x10(%ebp)
8010252b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010252e:	01 45 0c             	add    %eax,0xc(%ebp)
80102531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102534:	3b 45 14             	cmp    0x14(%ebp),%eax
80102537:	0f 82 55 ff ff ff    	jb     80102492 <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
8010253d:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102541:	74 1f                	je     80102562 <writei+0x18a>
80102543:	8b 45 08             	mov    0x8(%ebp),%eax
80102546:	8b 40 18             	mov    0x18(%eax),%eax
80102549:	3b 45 10             	cmp    0x10(%ebp),%eax
8010254c:	73 14                	jae    80102562 <writei+0x18a>
    ip->size = off;
8010254e:	8b 45 08             	mov    0x8(%ebp),%eax
80102551:	8b 55 10             	mov    0x10(%ebp),%edx
80102554:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102557:	8b 45 08             	mov    0x8(%ebp),%eax
8010255a:	89 04 24             	mov    %eax,(%esp)
8010255d:	e8 3d f6 ff ff       	call   80101b9f <iupdate>
  }
  return n;
80102562:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102565:	c9                   	leave  
80102566:	c3                   	ret    

80102567 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102567:	55                   	push   %ebp
80102568:	89 e5                	mov    %esp,%ebp
8010256a:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
8010256d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102574:	00 
80102575:	8b 45 0c             	mov    0xc(%ebp),%eax
80102578:	89 44 24 04          	mov    %eax,0x4(%esp)
8010257c:	8b 45 08             	mov    0x8(%ebp),%eax
8010257f:	89 04 24             	mov    %eax,(%esp)
80102582:	e8 70 31 00 00       	call   801056f7 <strncmp>
}
80102587:	c9                   	leave  
80102588:	c3                   	ret    

80102589 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102589:	55                   	push   %ebp
8010258a:	89 e5                	mov    %esp,%ebp
8010258c:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
8010258f:	8b 45 08             	mov    0x8(%ebp),%eax
80102592:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102596:	66 83 f8 01          	cmp    $0x1,%ax
8010259a:	74 0c                	je     801025a8 <dirlookup+0x1f>
    panic("dirlookup not DIR");
8010259c:	c7 04 24 7f 8a 10 80 	movl   $0x80108a7f,(%esp)
801025a3:	e8 92 df ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801025a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801025af:	e9 88 00 00 00       	jmp    8010263c <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801025b4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801025bb:	00 
801025bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801025c3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801025c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801025ca:	8b 45 08             	mov    0x8(%ebp),%eax
801025cd:	89 04 24             	mov    %eax,(%esp)
801025d0:	e8 9f fc ff ff       	call   80102274 <readi>
801025d5:	83 f8 10             	cmp    $0x10,%eax
801025d8:	74 0c                	je     801025e6 <dirlookup+0x5d>
      panic("dirlink read");
801025da:	c7 04 24 91 8a 10 80 	movl   $0x80108a91,(%esp)
801025e1:	e8 54 df ff ff       	call   8010053a <panic>
    if(de.inum == 0)
801025e6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801025ea:	66 85 c0             	test   %ax,%ax
801025ed:	75 02                	jne    801025f1 <dirlookup+0x68>
      continue;
801025ef:	eb 47                	jmp    80102638 <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
801025f1:	8d 45 e0             	lea    -0x20(%ebp),%eax
801025f4:	83 c0 02             	add    $0x2,%eax
801025f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801025fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801025fe:	89 04 24             	mov    %eax,(%esp)
80102601:	e8 61 ff ff ff       	call   80102567 <namecmp>
80102606:	85 c0                	test   %eax,%eax
80102608:	75 2e                	jne    80102638 <dirlookup+0xaf>
      // entry matches path element
      if(poff)
8010260a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010260e:	74 08                	je     80102618 <dirlookup+0x8f>
        *poff = off;
80102610:	8b 45 10             	mov    0x10(%ebp),%eax
80102613:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102616:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102618:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010261c:	0f b7 c0             	movzwl %ax,%eax
8010261f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102622:	8b 45 08             	mov    0x8(%ebp),%eax
80102625:	8b 00                	mov    (%eax),%eax
80102627:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010262a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010262e:	89 04 24             	mov    %eax,(%esp)
80102631:	e8 27 f6 ff ff       	call   80101c5d <iget>
80102636:	eb 18                	jmp    80102650 <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102638:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010263c:	8b 45 08             	mov    0x8(%ebp),%eax
8010263f:	8b 40 18             	mov    0x18(%eax),%eax
80102642:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102645:	0f 87 69 ff ff ff    	ja     801025b4 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
8010264b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102650:	c9                   	leave  
80102651:	c3                   	ret    

80102652 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102652:	55                   	push   %ebp
80102653:	89 e5                	mov    %esp,%ebp
80102655:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102658:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010265f:	00 
80102660:	8b 45 0c             	mov    0xc(%ebp),%eax
80102663:	89 44 24 04          	mov    %eax,0x4(%esp)
80102667:	8b 45 08             	mov    0x8(%ebp),%eax
8010266a:	89 04 24             	mov    %eax,(%esp)
8010266d:	e8 17 ff ff ff       	call   80102589 <dirlookup>
80102672:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102675:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102679:	74 15                	je     80102690 <dirlink+0x3e>
    iput(ip);
8010267b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010267e:	89 04 24             	mov    %eax,(%esp)
80102681:	e8 94 f8 ff ff       	call   80101f1a <iput>
    return -1;
80102686:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010268b:	e9 b7 00 00 00       	jmp    80102747 <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102690:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102697:	eb 46                	jmp    801026df <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102699:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010269c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801026a3:	00 
801026a4:	89 44 24 08          	mov    %eax,0x8(%esp)
801026a8:	8d 45 e0             	lea    -0x20(%ebp),%eax
801026ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801026af:	8b 45 08             	mov    0x8(%ebp),%eax
801026b2:	89 04 24             	mov    %eax,(%esp)
801026b5:	e8 ba fb ff ff       	call   80102274 <readi>
801026ba:	83 f8 10             	cmp    $0x10,%eax
801026bd:	74 0c                	je     801026cb <dirlink+0x79>
      panic("dirlink read");
801026bf:	c7 04 24 91 8a 10 80 	movl   $0x80108a91,(%esp)
801026c6:	e8 6f de ff ff       	call   8010053a <panic>
    if(de.inum == 0)
801026cb:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801026cf:	66 85 c0             	test   %ax,%ax
801026d2:	75 02                	jne    801026d6 <dirlink+0x84>
      break;
801026d4:	eb 16                	jmp    801026ec <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801026d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026d9:	83 c0 10             	add    $0x10,%eax
801026dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026df:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026e2:	8b 45 08             	mov    0x8(%ebp),%eax
801026e5:	8b 40 18             	mov    0x18(%eax),%eax
801026e8:	39 c2                	cmp    %eax,%edx
801026ea:	72 ad                	jb     80102699 <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
801026ec:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801026f3:	00 
801026f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801026f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801026fb:	8d 45 e0             	lea    -0x20(%ebp),%eax
801026fe:	83 c0 02             	add    $0x2,%eax
80102701:	89 04 24             	mov    %eax,(%esp)
80102704:	e8 44 30 00 00       	call   8010574d <strncpy>
  de.inum = inum;
80102709:	8b 45 10             	mov    0x10(%ebp),%eax
8010270c:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102710:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102713:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010271a:	00 
8010271b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010271f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102722:	89 44 24 04          	mov    %eax,0x4(%esp)
80102726:	8b 45 08             	mov    0x8(%ebp),%eax
80102729:	89 04 24             	mov    %eax,(%esp)
8010272c:	e8 a7 fc ff ff       	call   801023d8 <writei>
80102731:	83 f8 10             	cmp    $0x10,%eax
80102734:	74 0c                	je     80102742 <dirlink+0xf0>
    panic("dirlink");
80102736:	c7 04 24 9e 8a 10 80 	movl   $0x80108a9e,(%esp)
8010273d:	e8 f8 dd ff ff       	call   8010053a <panic>
  
  return 0;
80102742:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102747:	c9                   	leave  
80102748:	c3                   	ret    

80102749 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102749:	55                   	push   %ebp
8010274a:	89 e5                	mov    %esp,%ebp
8010274c:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010274f:	eb 04                	jmp    80102755 <skipelem+0xc>
    path++;
80102751:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102755:	8b 45 08             	mov    0x8(%ebp),%eax
80102758:	0f b6 00             	movzbl (%eax),%eax
8010275b:	3c 2f                	cmp    $0x2f,%al
8010275d:	74 f2                	je     80102751 <skipelem+0x8>
    path++;
  if(*path == 0)
8010275f:	8b 45 08             	mov    0x8(%ebp),%eax
80102762:	0f b6 00             	movzbl (%eax),%eax
80102765:	84 c0                	test   %al,%al
80102767:	75 0a                	jne    80102773 <skipelem+0x2a>
    return 0;
80102769:	b8 00 00 00 00       	mov    $0x0,%eax
8010276e:	e9 86 00 00 00       	jmp    801027f9 <skipelem+0xb0>
  s = path;
80102773:	8b 45 08             	mov    0x8(%ebp),%eax
80102776:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102779:	eb 04                	jmp    8010277f <skipelem+0x36>
    path++;
8010277b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
8010277f:	8b 45 08             	mov    0x8(%ebp),%eax
80102782:	0f b6 00             	movzbl (%eax),%eax
80102785:	3c 2f                	cmp    $0x2f,%al
80102787:	74 0a                	je     80102793 <skipelem+0x4a>
80102789:	8b 45 08             	mov    0x8(%ebp),%eax
8010278c:	0f b6 00             	movzbl (%eax),%eax
8010278f:	84 c0                	test   %al,%al
80102791:	75 e8                	jne    8010277b <skipelem+0x32>
    path++;
  len = path - s;
80102793:	8b 55 08             	mov    0x8(%ebp),%edx
80102796:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102799:	29 c2                	sub    %eax,%edx
8010279b:	89 d0                	mov    %edx,%eax
8010279d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801027a0:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801027a4:	7e 1c                	jle    801027c2 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
801027a6:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801027ad:	00 
801027ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801027b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801027b8:	89 04 24             	mov    %eax,(%esp)
801027bb:	e8 94 2e 00 00       	call   80105654 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801027c0:	eb 2a                	jmp    801027ec <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801027c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027c5:	89 44 24 08          	mov    %eax,0x8(%esp)
801027c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801027d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801027d3:	89 04 24             	mov    %eax,(%esp)
801027d6:	e8 79 2e 00 00       	call   80105654 <memmove>
    name[len] = 0;
801027db:	8b 55 f0             	mov    -0x10(%ebp),%edx
801027de:	8b 45 0c             	mov    0xc(%ebp),%eax
801027e1:	01 d0                	add    %edx,%eax
801027e3:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801027e6:	eb 04                	jmp    801027ec <skipelem+0xa3>
    path++;
801027e8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801027ec:	8b 45 08             	mov    0x8(%ebp),%eax
801027ef:	0f b6 00             	movzbl (%eax),%eax
801027f2:	3c 2f                	cmp    $0x2f,%al
801027f4:	74 f2                	je     801027e8 <skipelem+0x9f>
    path++;
  return path;
801027f6:	8b 45 08             	mov    0x8(%ebp),%eax
}
801027f9:	c9                   	leave  
801027fa:	c3                   	ret    

801027fb <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801027fb:	55                   	push   %ebp
801027fc:	89 e5                	mov    %esp,%ebp
801027fe:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102801:	8b 45 08             	mov    0x8(%ebp),%eax
80102804:	0f b6 00             	movzbl (%eax),%eax
80102807:	3c 2f                	cmp    $0x2f,%al
80102809:	75 1c                	jne    80102827 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010280b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102812:	00 
80102813:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010281a:	e8 3e f4 ff ff       	call   80101c5d <iget>
8010281f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102822:	e9 af 00 00 00       	jmp    801028d6 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102827:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010282d:	8b 40 68             	mov    0x68(%eax),%eax
80102830:	89 04 24             	mov    %eax,(%esp)
80102833:	e8 f7 f4 ff ff       	call   80101d2f <idup>
80102838:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010283b:	e9 96 00 00 00       	jmp    801028d6 <namex+0xdb>
    ilock(ip);
80102840:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102843:	89 04 24             	mov    %eax,(%esp)
80102846:	e8 16 f5 ff ff       	call   80101d61 <ilock>
    if(ip->type != T_DIR){
8010284b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010284e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102852:	66 83 f8 01          	cmp    $0x1,%ax
80102856:	74 15                	je     8010286d <namex+0x72>
      iunlockput(ip);
80102858:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010285b:	89 04 24             	mov    %eax,(%esp)
8010285e:	e8 88 f7 ff ff       	call   80101feb <iunlockput>
      return 0;
80102863:	b8 00 00 00 00       	mov    $0x0,%eax
80102868:	e9 a3 00 00 00       	jmp    80102910 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
8010286d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102871:	74 1d                	je     80102890 <namex+0x95>
80102873:	8b 45 08             	mov    0x8(%ebp),%eax
80102876:	0f b6 00             	movzbl (%eax),%eax
80102879:	84 c0                	test   %al,%al
8010287b:	75 13                	jne    80102890 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
8010287d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102880:	89 04 24             	mov    %eax,(%esp)
80102883:	e8 2d f6 ff ff       	call   80101eb5 <iunlock>
      return ip;
80102888:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010288b:	e9 80 00 00 00       	jmp    80102910 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102890:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102897:	00 
80102898:	8b 45 10             	mov    0x10(%ebp),%eax
8010289b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010289f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028a2:	89 04 24             	mov    %eax,(%esp)
801028a5:	e8 df fc ff ff       	call   80102589 <dirlookup>
801028aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
801028ad:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801028b1:	75 12                	jne    801028c5 <namex+0xca>
      iunlockput(ip);
801028b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028b6:	89 04 24             	mov    %eax,(%esp)
801028b9:	e8 2d f7 ff ff       	call   80101feb <iunlockput>
      return 0;
801028be:	b8 00 00 00 00       	mov    $0x0,%eax
801028c3:	eb 4b                	jmp    80102910 <namex+0x115>
    }
    iunlockput(ip);
801028c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028c8:	89 04 24             	mov    %eax,(%esp)
801028cb:	e8 1b f7 ff ff       	call   80101feb <iunlockput>
    ip = next;
801028d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801028d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801028d6:	8b 45 10             	mov    0x10(%ebp),%eax
801028d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801028dd:	8b 45 08             	mov    0x8(%ebp),%eax
801028e0:	89 04 24             	mov    %eax,(%esp)
801028e3:	e8 61 fe ff ff       	call   80102749 <skipelem>
801028e8:	89 45 08             	mov    %eax,0x8(%ebp)
801028eb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801028ef:	0f 85 4b ff ff ff    	jne    80102840 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801028f5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801028f9:	74 12                	je     8010290d <namex+0x112>
    iput(ip);
801028fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028fe:	89 04 24             	mov    %eax,(%esp)
80102901:	e8 14 f6 ff ff       	call   80101f1a <iput>
    return 0;
80102906:	b8 00 00 00 00       	mov    $0x0,%eax
8010290b:	eb 03                	jmp    80102910 <namex+0x115>
  }
  return ip;
8010290d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102910:	c9                   	leave  
80102911:	c3                   	ret    

80102912 <namei>:

struct inode*
namei(char *path)
{
80102912:	55                   	push   %ebp
80102913:	89 e5                	mov    %esp,%ebp
80102915:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102918:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010291b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010291f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102926:	00 
80102927:	8b 45 08             	mov    0x8(%ebp),%eax
8010292a:	89 04 24             	mov    %eax,(%esp)
8010292d:	e8 c9 fe ff ff       	call   801027fb <namex>
}
80102932:	c9                   	leave  
80102933:	c3                   	ret    

80102934 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102934:	55                   	push   %ebp
80102935:	89 e5                	mov    %esp,%ebp
80102937:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
8010293a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010293d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102941:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102948:	00 
80102949:	8b 45 08             	mov    0x8(%ebp),%eax
8010294c:	89 04 24             	mov    %eax,(%esp)
8010294f:	e8 a7 fe ff ff       	call   801027fb <namex>
}
80102954:	c9                   	leave  
80102955:	c3                   	ret    

80102956 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102956:	55                   	push   %ebp
80102957:	89 e5                	mov    %esp,%ebp
80102959:	83 ec 14             	sub    $0x14,%esp
8010295c:	8b 45 08             	mov    0x8(%ebp),%eax
8010295f:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102963:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102967:	89 c2                	mov    %eax,%edx
80102969:	ec                   	in     (%dx),%al
8010296a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010296d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102971:	c9                   	leave  
80102972:	c3                   	ret    

80102973 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102973:	55                   	push   %ebp
80102974:	89 e5                	mov    %esp,%ebp
80102976:	57                   	push   %edi
80102977:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102978:	8b 55 08             	mov    0x8(%ebp),%edx
8010297b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010297e:	8b 45 10             	mov    0x10(%ebp),%eax
80102981:	89 cb                	mov    %ecx,%ebx
80102983:	89 df                	mov    %ebx,%edi
80102985:	89 c1                	mov    %eax,%ecx
80102987:	fc                   	cld    
80102988:	f3 6d                	rep insl (%dx),%es:(%edi)
8010298a:	89 c8                	mov    %ecx,%eax
8010298c:	89 fb                	mov    %edi,%ebx
8010298e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102991:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102994:	5b                   	pop    %ebx
80102995:	5f                   	pop    %edi
80102996:	5d                   	pop    %ebp
80102997:	c3                   	ret    

80102998 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102998:	55                   	push   %ebp
80102999:	89 e5                	mov    %esp,%ebp
8010299b:	83 ec 08             	sub    $0x8,%esp
8010299e:	8b 55 08             	mov    0x8(%ebp),%edx
801029a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801029a4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801029a8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801029ab:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801029af:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801029b3:	ee                   	out    %al,(%dx)
}
801029b4:	c9                   	leave  
801029b5:	c3                   	ret    

801029b6 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801029b6:	55                   	push   %ebp
801029b7:	89 e5                	mov    %esp,%ebp
801029b9:	56                   	push   %esi
801029ba:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801029bb:	8b 55 08             	mov    0x8(%ebp),%edx
801029be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801029c1:	8b 45 10             	mov    0x10(%ebp),%eax
801029c4:	89 cb                	mov    %ecx,%ebx
801029c6:	89 de                	mov    %ebx,%esi
801029c8:	89 c1                	mov    %eax,%ecx
801029ca:	fc                   	cld    
801029cb:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801029cd:	89 c8                	mov    %ecx,%eax
801029cf:	89 f3                	mov    %esi,%ebx
801029d1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801029d4:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801029d7:	5b                   	pop    %ebx
801029d8:	5e                   	pop    %esi
801029d9:	5d                   	pop    %ebp
801029da:	c3                   	ret    

801029db <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801029db:	55                   	push   %ebp
801029dc:	89 e5                	mov    %esp,%ebp
801029de:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801029e1:	90                   	nop
801029e2:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801029e9:	e8 68 ff ff ff       	call   80102956 <inb>
801029ee:	0f b6 c0             	movzbl %al,%eax
801029f1:	89 45 fc             	mov    %eax,-0x4(%ebp)
801029f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801029f7:	25 c0 00 00 00       	and    $0xc0,%eax
801029fc:	83 f8 40             	cmp    $0x40,%eax
801029ff:	75 e1                	jne    801029e2 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102a01:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102a05:	74 11                	je     80102a18 <idewait+0x3d>
80102a07:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102a0a:	83 e0 21             	and    $0x21,%eax
80102a0d:	85 c0                	test   %eax,%eax
80102a0f:	74 07                	je     80102a18 <idewait+0x3d>
    return -1;
80102a11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102a16:	eb 05                	jmp    80102a1d <idewait+0x42>
  return 0;
80102a18:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102a1d:	c9                   	leave  
80102a1e:	c3                   	ret    

80102a1f <ideinit>:

void
ideinit(void)
{
80102a1f:	55                   	push   %ebp
80102a20:	89 e5                	mov    %esp,%ebp
80102a22:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102a25:	c7 44 24 04 a6 8a 10 	movl   $0x80108aa6,0x4(%esp)
80102a2c:	80 
80102a2d:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102a34:	e8 d7 28 00 00       	call   80105310 <initlock>
  picenable(IRQ_IDE);
80102a39:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102a40:	e8 a3 18 00 00       	call   801042e8 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102a45:	a1 a0 31 11 80       	mov    0x801131a0,%eax
80102a4a:	83 e8 01             	sub    $0x1,%eax
80102a4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a51:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102a58:	e8 43 04 00 00       	call   80102ea0 <ioapicenable>
  idewait(0);
80102a5d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102a64:	e8 72 ff ff ff       	call   801029db <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102a69:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102a70:	00 
80102a71:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102a78:	e8 1b ff ff ff       	call   80102998 <outb>
  for(i=0; i<1000; i++){
80102a7d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a84:	eb 20                	jmp    80102aa6 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102a86:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102a8d:	e8 c4 fe ff ff       	call   80102956 <inb>
80102a92:	84 c0                	test   %al,%al
80102a94:	74 0c                	je     80102aa2 <ideinit+0x83>
      havedisk1 = 1;
80102a96:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
80102a9d:	00 00 00 
      break;
80102aa0:	eb 0d                	jmp    80102aaf <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102aa2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102aa6:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102aad:	7e d7                	jle    80102a86 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102aaf:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102ab6:	00 
80102ab7:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102abe:	e8 d5 fe ff ff       	call   80102998 <outb>
}
80102ac3:	c9                   	leave  
80102ac4:	c3                   	ret    

80102ac5 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102ac5:	55                   	push   %ebp
80102ac6:	89 e5                	mov    %esp,%ebp
80102ac8:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
80102acb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102acf:	75 0c                	jne    80102add <idestart+0x18>
    panic("idestart");
80102ad1:	c7 04 24 aa 8a 10 80 	movl   $0x80108aaa,(%esp)
80102ad8:	e8 5d da ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
80102add:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae0:	8b 40 08             	mov    0x8(%eax),%eax
80102ae3:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102ae8:	76 0c                	jbe    80102af6 <idestart+0x31>
    panic("incorrect blockno");
80102aea:	c7 04 24 b3 8a 10 80 	movl   $0x80108ab3,(%esp)
80102af1:	e8 44 da ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102af6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
80102afd:	8b 45 08             	mov    0x8(%ebp),%eax
80102b00:	8b 50 08             	mov    0x8(%eax),%edx
80102b03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b06:	0f af c2             	imul   %edx,%eax
80102b09:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102b0c:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102b10:	7e 0c                	jle    80102b1e <idestart+0x59>
80102b12:	c7 04 24 aa 8a 10 80 	movl   $0x80108aaa,(%esp)
80102b19:	e8 1c da ff ff       	call   8010053a <panic>
  
  idewait(0);
80102b1e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102b25:	e8 b1 fe ff ff       	call   801029db <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102b2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102b31:	00 
80102b32:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102b39:	e8 5a fe ff ff       	call   80102998 <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102b3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b41:	0f b6 c0             	movzbl %al,%eax
80102b44:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b48:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102b4f:	e8 44 fe ff ff       	call   80102998 <outb>
  outb(0x1f3, sector & 0xff);
80102b54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b57:	0f b6 c0             	movzbl %al,%eax
80102b5a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b5e:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102b65:	e8 2e fe ff ff       	call   80102998 <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
80102b6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b6d:	c1 f8 08             	sar    $0x8,%eax
80102b70:	0f b6 c0             	movzbl %al,%eax
80102b73:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b77:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102b7e:	e8 15 fe ff ff       	call   80102998 <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102b83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b86:	c1 f8 10             	sar    $0x10,%eax
80102b89:	0f b6 c0             	movzbl %al,%eax
80102b8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b90:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102b97:	e8 fc fd ff ff       	call   80102998 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102b9c:	8b 45 08             	mov    0x8(%ebp),%eax
80102b9f:	8b 40 04             	mov    0x4(%eax),%eax
80102ba2:	83 e0 01             	and    $0x1,%eax
80102ba5:	c1 e0 04             	shl    $0x4,%eax
80102ba8:	89 c2                	mov    %eax,%edx
80102baa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102bad:	c1 f8 18             	sar    $0x18,%eax
80102bb0:	83 e0 0f             	and    $0xf,%eax
80102bb3:	09 d0                	or     %edx,%eax
80102bb5:	83 c8 e0             	or     $0xffffffe0,%eax
80102bb8:	0f b6 c0             	movzbl %al,%eax
80102bbb:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bbf:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102bc6:	e8 cd fd ff ff       	call   80102998 <outb>
  if(b->flags & B_DIRTY){
80102bcb:	8b 45 08             	mov    0x8(%ebp),%eax
80102bce:	8b 00                	mov    (%eax),%eax
80102bd0:	83 e0 04             	and    $0x4,%eax
80102bd3:	85 c0                	test   %eax,%eax
80102bd5:	74 34                	je     80102c0b <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
80102bd7:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102bde:	00 
80102bdf:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102be6:	e8 ad fd ff ff       	call   80102998 <outb>
    outsl(0x1f0, b->data, BSIZE/4);
80102beb:	8b 45 08             	mov    0x8(%ebp),%eax
80102bee:	83 c0 18             	add    $0x18,%eax
80102bf1:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102bf8:	00 
80102bf9:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bfd:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102c04:	e8 ad fd ff ff       	call   801029b6 <outsl>
80102c09:	eb 14                	jmp    80102c1f <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102c0b:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102c12:	00 
80102c13:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102c1a:	e8 79 fd ff ff       	call   80102998 <outb>
  }
}
80102c1f:	c9                   	leave  
80102c20:	c3                   	ret    

80102c21 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102c21:	55                   	push   %ebp
80102c22:	89 e5                	mov    %esp,%ebp
80102c24:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102c27:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102c2e:	e8 fe 26 00 00       	call   80105331 <acquire>
  if((b = idequeue) == 0){
80102c33:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102c38:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102c3b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102c3f:	75 11                	jne    80102c52 <ideintr+0x31>
    release(&idelock);
80102c41:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102c48:	e8 46 27 00 00       	call   80105393 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102c4d:	e9 90 00 00 00       	jmp    80102ce2 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102c52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c55:	8b 40 14             	mov    0x14(%eax),%eax
80102c58:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102c5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c60:	8b 00                	mov    (%eax),%eax
80102c62:	83 e0 04             	and    $0x4,%eax
80102c65:	85 c0                	test   %eax,%eax
80102c67:	75 2e                	jne    80102c97 <ideintr+0x76>
80102c69:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102c70:	e8 66 fd ff ff       	call   801029db <idewait>
80102c75:	85 c0                	test   %eax,%eax
80102c77:	78 1e                	js     80102c97 <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
80102c79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c7c:	83 c0 18             	add    $0x18,%eax
80102c7f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102c86:	00 
80102c87:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c8b:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102c92:	e8 dc fc ff ff       	call   80102973 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c9a:	8b 00                	mov    (%eax),%eax
80102c9c:	83 c8 02             	or     $0x2,%eax
80102c9f:	89 c2                	mov    %eax,%edx
80102ca1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ca4:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102ca6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ca9:	8b 00                	mov    (%eax),%eax
80102cab:	83 e0 fb             	and    $0xfffffffb,%eax
80102cae:	89 c2                	mov    %eax,%edx
80102cb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cb3:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102cb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cb8:	89 04 24             	mov    %eax,(%esp)
80102cbb:	e8 80 24 00 00       	call   80105140 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102cc0:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102cc5:	85 c0                	test   %eax,%eax
80102cc7:	74 0d                	je     80102cd6 <ideintr+0xb5>
    idestart(idequeue);
80102cc9:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102cce:	89 04 24             	mov    %eax,(%esp)
80102cd1:	e8 ef fd ff ff       	call   80102ac5 <idestart>

  release(&idelock);
80102cd6:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102cdd:	e8 b1 26 00 00       	call   80105393 <release>
}
80102ce2:	c9                   	leave  
80102ce3:	c3                   	ret    

80102ce4 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102ce4:	55                   	push   %ebp
80102ce5:	89 e5                	mov    %esp,%ebp
80102ce7:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102cea:	8b 45 08             	mov    0x8(%ebp),%eax
80102ced:	8b 00                	mov    (%eax),%eax
80102cef:	83 e0 01             	and    $0x1,%eax
80102cf2:	85 c0                	test   %eax,%eax
80102cf4:	75 0c                	jne    80102d02 <iderw+0x1e>
    panic("iderw: buf not busy");
80102cf6:	c7 04 24 c5 8a 10 80 	movl   $0x80108ac5,(%esp)
80102cfd:	e8 38 d8 ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102d02:	8b 45 08             	mov    0x8(%ebp),%eax
80102d05:	8b 00                	mov    (%eax),%eax
80102d07:	83 e0 06             	and    $0x6,%eax
80102d0a:	83 f8 02             	cmp    $0x2,%eax
80102d0d:	75 0c                	jne    80102d1b <iderw+0x37>
    panic("iderw: nothing to do");
80102d0f:	c7 04 24 d9 8a 10 80 	movl   $0x80108ad9,(%esp)
80102d16:	e8 1f d8 ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
80102d1b:	8b 45 08             	mov    0x8(%ebp),%eax
80102d1e:	8b 40 04             	mov    0x4(%eax),%eax
80102d21:	85 c0                	test   %eax,%eax
80102d23:	74 15                	je     80102d3a <iderw+0x56>
80102d25:	a1 38 b6 10 80       	mov    0x8010b638,%eax
80102d2a:	85 c0                	test   %eax,%eax
80102d2c:	75 0c                	jne    80102d3a <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102d2e:	c7 04 24 ee 8a 10 80 	movl   $0x80108aee,(%esp)
80102d35:	e8 00 d8 ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102d3a:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102d41:	e8 eb 25 00 00       	call   80105331 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102d46:	8b 45 08             	mov    0x8(%ebp),%eax
80102d49:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102d50:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
80102d57:	eb 0b                	jmp    80102d64 <iderw+0x80>
80102d59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d5c:	8b 00                	mov    (%eax),%eax
80102d5e:	83 c0 14             	add    $0x14,%eax
80102d61:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102d64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d67:	8b 00                	mov    (%eax),%eax
80102d69:	85 c0                	test   %eax,%eax
80102d6b:	75 ec                	jne    80102d59 <iderw+0x75>
    ;
  *pp = b;
80102d6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d70:	8b 55 08             	mov    0x8(%ebp),%edx
80102d73:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102d75:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102d7a:	3b 45 08             	cmp    0x8(%ebp),%eax
80102d7d:	75 0d                	jne    80102d8c <iderw+0xa8>
    idestart(b);
80102d7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102d82:	89 04 24             	mov    %eax,(%esp)
80102d85:	e8 3b fd ff ff       	call   80102ac5 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102d8a:	eb 15                	jmp    80102da1 <iderw+0xbd>
80102d8c:	eb 13                	jmp    80102da1 <iderw+0xbd>
    sleep(b, &idelock);
80102d8e:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
80102d95:	80 
80102d96:	8b 45 08             	mov    0x8(%ebp),%eax
80102d99:	89 04 24             	mov    %eax,(%esp)
80102d9c:	e8 c6 22 00 00       	call   80105067 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102da1:	8b 45 08             	mov    0x8(%ebp),%eax
80102da4:	8b 00                	mov    (%eax),%eax
80102da6:	83 e0 06             	and    $0x6,%eax
80102da9:	83 f8 02             	cmp    $0x2,%eax
80102dac:	75 e0                	jne    80102d8e <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102dae:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102db5:	e8 d9 25 00 00       	call   80105393 <release>
}
80102dba:	c9                   	leave  
80102dbb:	c3                   	ret    

80102dbc <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102dbc:	55                   	push   %ebp
80102dbd:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102dbf:	a1 74 2a 11 80       	mov    0x80112a74,%eax
80102dc4:	8b 55 08             	mov    0x8(%ebp),%edx
80102dc7:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102dc9:	a1 74 2a 11 80       	mov    0x80112a74,%eax
80102dce:	8b 40 10             	mov    0x10(%eax),%eax
}
80102dd1:	5d                   	pop    %ebp
80102dd2:	c3                   	ret    

80102dd3 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102dd3:	55                   	push   %ebp
80102dd4:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102dd6:	a1 74 2a 11 80       	mov    0x80112a74,%eax
80102ddb:	8b 55 08             	mov    0x8(%ebp),%edx
80102dde:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102de0:	a1 74 2a 11 80       	mov    0x80112a74,%eax
80102de5:	8b 55 0c             	mov    0xc(%ebp),%edx
80102de8:	89 50 10             	mov    %edx,0x10(%eax)
}
80102deb:	5d                   	pop    %ebp
80102dec:	c3                   	ret    

80102ded <ioapicinit>:

void
ioapicinit(void)
{
80102ded:	55                   	push   %ebp
80102dee:	89 e5                	mov    %esp,%ebp
80102df0:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102df3:	a1 a4 2b 11 80       	mov    0x80112ba4,%eax
80102df8:	85 c0                	test   %eax,%eax
80102dfa:	75 05                	jne    80102e01 <ioapicinit+0x14>
    return;
80102dfc:	e9 9d 00 00 00       	jmp    80102e9e <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102e01:	c7 05 74 2a 11 80 00 	movl   $0xfec00000,0x80112a74
80102e08:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102e0b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102e12:	e8 a5 ff ff ff       	call   80102dbc <ioapicread>
80102e17:	c1 e8 10             	shr    $0x10,%eax
80102e1a:	25 ff 00 00 00       	and    $0xff,%eax
80102e1f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102e22:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102e29:	e8 8e ff ff ff       	call   80102dbc <ioapicread>
80102e2e:	c1 e8 18             	shr    $0x18,%eax
80102e31:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102e34:	0f b6 05 a0 2b 11 80 	movzbl 0x80112ba0,%eax
80102e3b:	0f b6 c0             	movzbl %al,%eax
80102e3e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102e41:	74 0c                	je     80102e4f <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102e43:	c7 04 24 0c 8b 10 80 	movl   $0x80108b0c,(%esp)
80102e4a:	e8 51 d5 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102e4f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102e56:	eb 3e                	jmp    80102e96 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102e58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e5b:	83 c0 20             	add    $0x20,%eax
80102e5e:	0d 00 00 01 00       	or     $0x10000,%eax
80102e63:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102e66:	83 c2 08             	add    $0x8,%edx
80102e69:	01 d2                	add    %edx,%edx
80102e6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e6f:	89 14 24             	mov    %edx,(%esp)
80102e72:	e8 5c ff ff ff       	call   80102dd3 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102e77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e7a:	83 c0 08             	add    $0x8,%eax
80102e7d:	01 c0                	add    %eax,%eax
80102e7f:	83 c0 01             	add    $0x1,%eax
80102e82:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e89:	00 
80102e8a:	89 04 24             	mov    %eax,(%esp)
80102e8d:	e8 41 ff ff ff       	call   80102dd3 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102e92:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102e96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e99:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102e9c:	7e ba                	jle    80102e58 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102e9e:	c9                   	leave  
80102e9f:	c3                   	ret    

80102ea0 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102ea0:	55                   	push   %ebp
80102ea1:	89 e5                	mov    %esp,%ebp
80102ea3:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102ea6:	a1 a4 2b 11 80       	mov    0x80112ba4,%eax
80102eab:	85 c0                	test   %eax,%eax
80102ead:	75 02                	jne    80102eb1 <ioapicenable+0x11>
    return;
80102eaf:	eb 37                	jmp    80102ee8 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102eb1:	8b 45 08             	mov    0x8(%ebp),%eax
80102eb4:	83 c0 20             	add    $0x20,%eax
80102eb7:	8b 55 08             	mov    0x8(%ebp),%edx
80102eba:	83 c2 08             	add    $0x8,%edx
80102ebd:	01 d2                	add    %edx,%edx
80102ebf:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ec3:	89 14 24             	mov    %edx,(%esp)
80102ec6:	e8 08 ff ff ff       	call   80102dd3 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102ecb:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ece:	c1 e0 18             	shl    $0x18,%eax
80102ed1:	8b 55 08             	mov    0x8(%ebp),%edx
80102ed4:	83 c2 08             	add    $0x8,%edx
80102ed7:	01 d2                	add    %edx,%edx
80102ed9:	83 c2 01             	add    $0x1,%edx
80102edc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ee0:	89 14 24             	mov    %edx,(%esp)
80102ee3:	e8 eb fe ff ff       	call   80102dd3 <ioapicwrite>
}
80102ee8:	c9                   	leave  
80102ee9:	c3                   	ret    

80102eea <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102eea:	55                   	push   %ebp
80102eeb:	89 e5                	mov    %esp,%ebp
80102eed:	8b 45 08             	mov    0x8(%ebp),%eax
80102ef0:	05 00 00 00 80       	add    $0x80000000,%eax
80102ef5:	5d                   	pop    %ebp
80102ef6:	c3                   	ret    

80102ef7 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102ef7:	55                   	push   %ebp
80102ef8:	89 e5                	mov    %esp,%ebp
80102efa:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102efd:	c7 44 24 04 3e 8b 10 	movl   $0x80108b3e,0x4(%esp)
80102f04:	80 
80102f05:	c7 04 24 80 2a 11 80 	movl   $0x80112a80,(%esp)
80102f0c:	e8 ff 23 00 00       	call   80105310 <initlock>
  kmem.use_lock = 0;
80102f11:	c7 05 b4 2a 11 80 00 	movl   $0x0,0x80112ab4
80102f18:	00 00 00 
  freerange(vstart, vend);
80102f1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f22:	8b 45 08             	mov    0x8(%ebp),%eax
80102f25:	89 04 24             	mov    %eax,(%esp)
80102f28:	e8 26 00 00 00       	call   80102f53 <freerange>
}
80102f2d:	c9                   	leave  
80102f2e:	c3                   	ret    

80102f2f <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102f2f:	55                   	push   %ebp
80102f30:	89 e5                	mov    %esp,%ebp
80102f32:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102f35:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f38:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f3c:	8b 45 08             	mov    0x8(%ebp),%eax
80102f3f:	89 04 24             	mov    %eax,(%esp)
80102f42:	e8 0c 00 00 00       	call   80102f53 <freerange>
  kmem.use_lock = 1;
80102f47:	c7 05 b4 2a 11 80 01 	movl   $0x1,0x80112ab4
80102f4e:	00 00 00 
}
80102f51:	c9                   	leave  
80102f52:	c3                   	ret    

80102f53 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102f53:	55                   	push   %ebp
80102f54:	89 e5                	mov    %esp,%ebp
80102f56:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102f59:	8b 45 08             	mov    0x8(%ebp),%eax
80102f5c:	05 ff 0f 00 00       	add    $0xfff,%eax
80102f61:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102f66:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102f69:	eb 12                	jmp    80102f7d <freerange+0x2a>
    kfree(p);
80102f6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f6e:	89 04 24             	mov    %eax,(%esp)
80102f71:	e8 16 00 00 00       	call   80102f8c <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102f76:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102f7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f80:	05 00 10 00 00       	add    $0x1000,%eax
80102f85:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102f88:	76 e1                	jbe    80102f6b <freerange+0x18>
    kfree(p);
}
80102f8a:	c9                   	leave  
80102f8b:	c3                   	ret    

80102f8c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102f8c:	55                   	push   %ebp
80102f8d:	89 e5                	mov    %esp,%ebp
80102f8f:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102f92:	8b 45 08             	mov    0x8(%ebp),%eax
80102f95:	25 ff 0f 00 00       	and    $0xfff,%eax
80102f9a:	85 c0                	test   %eax,%eax
80102f9c:	75 1b                	jne    80102fb9 <kfree+0x2d>
80102f9e:	81 7d 08 9c 59 11 80 	cmpl   $0x8011599c,0x8(%ebp)
80102fa5:	72 12                	jb     80102fb9 <kfree+0x2d>
80102fa7:	8b 45 08             	mov    0x8(%ebp),%eax
80102faa:	89 04 24             	mov    %eax,(%esp)
80102fad:	e8 38 ff ff ff       	call   80102eea <v2p>
80102fb2:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102fb7:	76 0c                	jbe    80102fc5 <kfree+0x39>
    panic("kfree");
80102fb9:	c7 04 24 43 8b 10 80 	movl   $0x80108b43,(%esp)
80102fc0:	e8 75 d5 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102fc5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102fcc:	00 
80102fcd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102fd4:	00 
80102fd5:	8b 45 08             	mov    0x8(%ebp),%eax
80102fd8:	89 04 24             	mov    %eax,(%esp)
80102fdb:	e8 a5 25 00 00       	call   80105585 <memset>

  if(kmem.use_lock)
80102fe0:	a1 b4 2a 11 80       	mov    0x80112ab4,%eax
80102fe5:	85 c0                	test   %eax,%eax
80102fe7:	74 0c                	je     80102ff5 <kfree+0x69>
    acquire(&kmem.lock);
80102fe9:	c7 04 24 80 2a 11 80 	movl   $0x80112a80,(%esp)
80102ff0:	e8 3c 23 00 00       	call   80105331 <acquire>
  r = (struct run*)v;
80102ff5:	8b 45 08             	mov    0x8(%ebp),%eax
80102ff8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ffb:	8b 15 b8 2a 11 80    	mov    0x80112ab8,%edx
80103001:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103004:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103006:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103009:	a3 b8 2a 11 80       	mov    %eax,0x80112ab8
  if(kmem.use_lock)
8010300e:	a1 b4 2a 11 80       	mov    0x80112ab4,%eax
80103013:	85 c0                	test   %eax,%eax
80103015:	74 0c                	je     80103023 <kfree+0x97>
    release(&kmem.lock);
80103017:	c7 04 24 80 2a 11 80 	movl   $0x80112a80,(%esp)
8010301e:	e8 70 23 00 00       	call   80105393 <release>
}
80103023:	c9                   	leave  
80103024:	c3                   	ret    

80103025 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103025:	55                   	push   %ebp
80103026:	89 e5                	mov    %esp,%ebp
80103028:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
8010302b:	a1 b4 2a 11 80       	mov    0x80112ab4,%eax
80103030:	85 c0                	test   %eax,%eax
80103032:	74 0c                	je     80103040 <kalloc+0x1b>
    acquire(&kmem.lock);
80103034:	c7 04 24 80 2a 11 80 	movl   $0x80112a80,(%esp)
8010303b:	e8 f1 22 00 00       	call   80105331 <acquire>
  r = kmem.freelist;
80103040:	a1 b8 2a 11 80       	mov    0x80112ab8,%eax
80103045:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103048:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010304c:	74 0a                	je     80103058 <kalloc+0x33>
    kmem.freelist = r->next;
8010304e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103051:	8b 00                	mov    (%eax),%eax
80103053:	a3 b8 2a 11 80       	mov    %eax,0x80112ab8
  if(kmem.use_lock)
80103058:	a1 b4 2a 11 80       	mov    0x80112ab4,%eax
8010305d:	85 c0                	test   %eax,%eax
8010305f:	74 0c                	je     8010306d <kalloc+0x48>
    release(&kmem.lock);
80103061:	c7 04 24 80 2a 11 80 	movl   $0x80112a80,(%esp)
80103068:	e8 26 23 00 00       	call   80105393 <release>
  return (char*)r;
8010306d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103070:	c9                   	leave  
80103071:	c3                   	ret    

80103072 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103072:	55                   	push   %ebp
80103073:	89 e5                	mov    %esp,%ebp
80103075:	83 ec 14             	sub    $0x14,%esp
80103078:	8b 45 08             	mov    0x8(%ebp),%eax
8010307b:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010307f:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103083:	89 c2                	mov    %eax,%edx
80103085:	ec                   	in     (%dx),%al
80103086:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103089:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
8010308d:	c9                   	leave  
8010308e:	c3                   	ret    

8010308f <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010308f:	55                   	push   %ebp
80103090:	89 e5                	mov    %esp,%ebp
80103092:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103095:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010309c:	e8 d1 ff ff ff       	call   80103072 <inb>
801030a1:	0f b6 c0             	movzbl %al,%eax
801030a4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
801030a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030aa:	83 e0 01             	and    $0x1,%eax
801030ad:	85 c0                	test   %eax,%eax
801030af:	75 0a                	jne    801030bb <kbdgetc+0x2c>
    return -1;
801030b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801030b6:	e9 25 01 00 00       	jmp    801031e0 <kbdgetc+0x151>
  data = inb(KBDATAP);
801030bb:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
801030c2:	e8 ab ff ff ff       	call   80103072 <inb>
801030c7:	0f b6 c0             	movzbl %al,%eax
801030ca:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
801030cd:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
801030d4:	75 17                	jne    801030ed <kbdgetc+0x5e>
    shift |= E0ESC;
801030d6:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
801030db:	83 c8 40             	or     $0x40,%eax
801030de:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
801030e3:	b8 00 00 00 00       	mov    $0x0,%eax
801030e8:	e9 f3 00 00 00       	jmp    801031e0 <kbdgetc+0x151>
  } else if(data & 0x80){
801030ed:	8b 45 fc             	mov    -0x4(%ebp),%eax
801030f0:	25 80 00 00 00       	and    $0x80,%eax
801030f5:	85 c0                	test   %eax,%eax
801030f7:	74 45                	je     8010313e <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
801030f9:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
801030fe:	83 e0 40             	and    $0x40,%eax
80103101:	85 c0                	test   %eax,%eax
80103103:	75 08                	jne    8010310d <kbdgetc+0x7e>
80103105:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103108:	83 e0 7f             	and    $0x7f,%eax
8010310b:	eb 03                	jmp    80103110 <kbdgetc+0x81>
8010310d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103110:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103113:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103116:	05 20 90 10 80       	add    $0x80109020,%eax
8010311b:	0f b6 00             	movzbl (%eax),%eax
8010311e:	83 c8 40             	or     $0x40,%eax
80103121:	0f b6 c0             	movzbl %al,%eax
80103124:	f7 d0                	not    %eax
80103126:	89 c2                	mov    %eax,%edx
80103128:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
8010312d:	21 d0                	and    %edx,%eax
8010312f:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80103134:	b8 00 00 00 00       	mov    $0x0,%eax
80103139:	e9 a2 00 00 00       	jmp    801031e0 <kbdgetc+0x151>
  } else if(shift & E0ESC){
8010313e:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80103143:	83 e0 40             	and    $0x40,%eax
80103146:	85 c0                	test   %eax,%eax
80103148:	74 14                	je     8010315e <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010314a:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103151:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80103156:	83 e0 bf             	and    $0xffffffbf,%eax
80103159:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
8010315e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103161:	05 20 90 10 80       	add    $0x80109020,%eax
80103166:	0f b6 00             	movzbl (%eax),%eax
80103169:	0f b6 d0             	movzbl %al,%edx
8010316c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80103171:	09 d0                	or     %edx,%eax
80103173:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80103178:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010317b:	05 20 91 10 80       	add    $0x80109120,%eax
80103180:	0f b6 00             	movzbl (%eax),%eax
80103183:	0f b6 d0             	movzbl %al,%edx
80103186:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
8010318b:	31 d0                	xor    %edx,%eax
8010318d:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80103192:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80103197:	83 e0 03             	and    $0x3,%eax
8010319a:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
801031a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801031a4:	01 d0                	add    %edx,%eax
801031a6:	0f b6 00             	movzbl (%eax),%eax
801031a9:	0f b6 c0             	movzbl %al,%eax
801031ac:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
801031af:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
801031b4:	83 e0 08             	and    $0x8,%eax
801031b7:	85 c0                	test   %eax,%eax
801031b9:	74 22                	je     801031dd <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
801031bb:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
801031bf:	76 0c                	jbe    801031cd <kbdgetc+0x13e>
801031c1:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
801031c5:	77 06                	ja     801031cd <kbdgetc+0x13e>
      c += 'A' - 'a';
801031c7:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
801031cb:	eb 10                	jmp    801031dd <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
801031cd:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
801031d1:	76 0a                	jbe    801031dd <kbdgetc+0x14e>
801031d3:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
801031d7:	77 04                	ja     801031dd <kbdgetc+0x14e>
      c += 'a' - 'A';
801031d9:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
801031dd:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801031e0:	c9                   	leave  
801031e1:	c3                   	ret    

801031e2 <kbdintr>:

void
kbdintr(void)
{
801031e2:	55                   	push   %ebp
801031e3:	89 e5                	mov    %esp,%ebp
801031e5:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
801031e8:	c7 04 24 8f 30 10 80 	movl   $0x8010308f,(%esp)
801031ef:	e8 f1 d8 ff ff       	call   80100ae5 <consoleintr>
}
801031f4:	c9                   	leave  
801031f5:	c3                   	ret    

801031f6 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801031f6:	55                   	push   %ebp
801031f7:	89 e5                	mov    %esp,%ebp
801031f9:	83 ec 14             	sub    $0x14,%esp
801031fc:	8b 45 08             	mov    0x8(%ebp),%eax
801031ff:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103203:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103207:	89 c2                	mov    %eax,%edx
80103209:	ec                   	in     (%dx),%al
8010320a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010320d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103211:	c9                   	leave  
80103212:	c3                   	ret    

80103213 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103213:	55                   	push   %ebp
80103214:	89 e5                	mov    %esp,%ebp
80103216:	83 ec 08             	sub    $0x8,%esp
80103219:	8b 55 08             	mov    0x8(%ebp),%edx
8010321c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010321f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103223:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103226:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010322a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010322e:	ee                   	out    %al,(%dx)
}
8010322f:	c9                   	leave  
80103230:	c3                   	ret    

80103231 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103231:	55                   	push   %ebp
80103232:	89 e5                	mov    %esp,%ebp
80103234:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103237:	9c                   	pushf  
80103238:	58                   	pop    %eax
80103239:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
8010323c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010323f:	c9                   	leave  
80103240:	c3                   	ret    

80103241 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103241:	55                   	push   %ebp
80103242:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103244:	a1 bc 2a 11 80       	mov    0x80112abc,%eax
80103249:	8b 55 08             	mov    0x8(%ebp),%edx
8010324c:	c1 e2 02             	shl    $0x2,%edx
8010324f:	01 c2                	add    %eax,%edx
80103251:	8b 45 0c             	mov    0xc(%ebp),%eax
80103254:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103256:	a1 bc 2a 11 80       	mov    0x80112abc,%eax
8010325b:	83 c0 20             	add    $0x20,%eax
8010325e:	8b 00                	mov    (%eax),%eax
}
80103260:	5d                   	pop    %ebp
80103261:	c3                   	ret    

80103262 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80103262:	55                   	push   %ebp
80103263:	89 e5                	mov    %esp,%ebp
80103265:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103268:	a1 bc 2a 11 80       	mov    0x80112abc,%eax
8010326d:	85 c0                	test   %eax,%eax
8010326f:	75 05                	jne    80103276 <lapicinit+0x14>
    return;
80103271:	e9 43 01 00 00       	jmp    801033b9 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80103276:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
8010327d:	00 
8010327e:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103285:	e8 b7 ff ff ff       	call   80103241 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
8010328a:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103291:	00 
80103292:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103299:	e8 a3 ff ff ff       	call   80103241 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010329e:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801032a5:	00 
801032a6:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801032ad:	e8 8f ff ff ff       	call   80103241 <lapicw>
  lapicw(TICR, 10000000); 
801032b2:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
801032b9:	00 
801032ba:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
801032c1:	e8 7b ff ff ff       	call   80103241 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
801032c6:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801032cd:	00 
801032ce:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
801032d5:	e8 67 ff ff ff       	call   80103241 <lapicw>
  lapicw(LINT1, MASKED);
801032da:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801032e1:	00 
801032e2:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
801032e9:	e8 53 ff ff ff       	call   80103241 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801032ee:	a1 bc 2a 11 80       	mov    0x80112abc,%eax
801032f3:	83 c0 30             	add    $0x30,%eax
801032f6:	8b 00                	mov    (%eax),%eax
801032f8:	c1 e8 10             	shr    $0x10,%eax
801032fb:	0f b6 c0             	movzbl %al,%eax
801032fe:	83 f8 03             	cmp    $0x3,%eax
80103301:	76 14                	jbe    80103317 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80103303:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010330a:	00 
8010330b:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103312:	e8 2a ff ff ff       	call   80103241 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103317:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
8010331e:	00 
8010331f:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103326:	e8 16 ff ff ff       	call   80103241 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
8010332b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103332:	00 
80103333:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010333a:	e8 02 ff ff ff       	call   80103241 <lapicw>
  lapicw(ESR, 0);
8010333f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103346:	00 
80103347:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010334e:	e8 ee fe ff ff       	call   80103241 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80103353:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010335a:	00 
8010335b:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103362:	e8 da fe ff ff       	call   80103241 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103367:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010336e:	00 
8010336f:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103376:	e8 c6 fe ff ff       	call   80103241 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010337b:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80103382:	00 
80103383:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010338a:	e8 b2 fe ff ff       	call   80103241 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010338f:	90                   	nop
80103390:	a1 bc 2a 11 80       	mov    0x80112abc,%eax
80103395:	05 00 03 00 00       	add    $0x300,%eax
8010339a:	8b 00                	mov    (%eax),%eax
8010339c:	25 00 10 00 00       	and    $0x1000,%eax
801033a1:	85 c0                	test   %eax,%eax
801033a3:	75 eb                	jne    80103390 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801033a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801033ac:	00 
801033ad:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801033b4:	e8 88 fe ff ff       	call   80103241 <lapicw>
}
801033b9:	c9                   	leave  
801033ba:	c3                   	ret    

801033bb <cpunum>:

int
cpunum(void)
{
801033bb:	55                   	push   %ebp
801033bc:	89 e5                	mov    %esp,%ebp
801033be:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
801033c1:	e8 6b fe ff ff       	call   80103231 <readeflags>
801033c6:	25 00 02 00 00       	and    $0x200,%eax
801033cb:	85 c0                	test   %eax,%eax
801033cd:	74 25                	je     801033f4 <cpunum+0x39>
    static int n;
    if(n++ == 0)
801033cf:	a1 40 b6 10 80       	mov    0x8010b640,%eax
801033d4:	8d 50 01             	lea    0x1(%eax),%edx
801033d7:	89 15 40 b6 10 80    	mov    %edx,0x8010b640
801033dd:	85 c0                	test   %eax,%eax
801033df:	75 13                	jne    801033f4 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
801033e1:	8b 45 04             	mov    0x4(%ebp),%eax
801033e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801033e8:	c7 04 24 4c 8b 10 80 	movl   $0x80108b4c,(%esp)
801033ef:	e8 ac cf ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
801033f4:	a1 bc 2a 11 80       	mov    0x80112abc,%eax
801033f9:	85 c0                	test   %eax,%eax
801033fb:	74 0f                	je     8010340c <cpunum+0x51>
    return lapic[ID]>>24;
801033fd:	a1 bc 2a 11 80       	mov    0x80112abc,%eax
80103402:	83 c0 20             	add    $0x20,%eax
80103405:	8b 00                	mov    (%eax),%eax
80103407:	c1 e8 18             	shr    $0x18,%eax
8010340a:	eb 05                	jmp    80103411 <cpunum+0x56>
  return 0;
8010340c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103411:	c9                   	leave  
80103412:	c3                   	ret    

80103413 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103413:	55                   	push   %ebp
80103414:	89 e5                	mov    %esp,%ebp
80103416:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103419:	a1 bc 2a 11 80       	mov    0x80112abc,%eax
8010341e:	85 c0                	test   %eax,%eax
80103420:	74 14                	je     80103436 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103422:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103429:	00 
8010342a:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103431:	e8 0b fe ff ff       	call   80103241 <lapicw>
}
80103436:	c9                   	leave  
80103437:	c3                   	ret    

80103438 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103438:	55                   	push   %ebp
80103439:	89 e5                	mov    %esp,%ebp
}
8010343b:	5d                   	pop    %ebp
8010343c:	c3                   	ret    

8010343d <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010343d:	55                   	push   %ebp
8010343e:	89 e5                	mov    %esp,%ebp
80103440:	83 ec 1c             	sub    $0x1c,%esp
80103443:	8b 45 08             	mov    0x8(%ebp),%eax
80103446:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80103449:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103450:	00 
80103451:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103458:	e8 b6 fd ff ff       	call   80103213 <outb>
  outb(CMOS_PORT+1, 0x0A);
8010345d:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103464:	00 
80103465:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010346c:	e8 a2 fd ff ff       	call   80103213 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103471:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103478:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010347b:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103480:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103483:	8d 50 02             	lea    0x2(%eax),%edx
80103486:	8b 45 0c             	mov    0xc(%ebp),%eax
80103489:	c1 e8 04             	shr    $0x4,%eax
8010348c:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010348f:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103493:	c1 e0 18             	shl    $0x18,%eax
80103496:	89 44 24 04          	mov    %eax,0x4(%esp)
8010349a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801034a1:	e8 9b fd ff ff       	call   80103241 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801034a6:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801034ad:	00 
801034ae:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801034b5:	e8 87 fd ff ff       	call   80103241 <lapicw>
  microdelay(200);
801034ba:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801034c1:	e8 72 ff ff ff       	call   80103438 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801034c6:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801034cd:	00 
801034ce:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801034d5:	e8 67 fd ff ff       	call   80103241 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801034da:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801034e1:	e8 52 ff ff ff       	call   80103438 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801034e6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801034ed:	eb 40                	jmp    8010352f <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801034ef:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801034f3:	c1 e0 18             	shl    $0x18,%eax
801034f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801034fa:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103501:	e8 3b fd ff ff       	call   80103241 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103506:	8b 45 0c             	mov    0xc(%ebp),%eax
80103509:	c1 e8 0c             	shr    $0xc,%eax
8010350c:	80 cc 06             	or     $0x6,%ah
8010350f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103513:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010351a:	e8 22 fd ff ff       	call   80103241 <lapicw>
    microdelay(200);
8010351f:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103526:	e8 0d ff ff ff       	call   80103438 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010352b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010352f:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103533:	7e ba                	jle    801034ef <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103535:	c9                   	leave  
80103536:	c3                   	ret    

80103537 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
80103537:	55                   	push   %ebp
80103538:	89 e5                	mov    %esp,%ebp
8010353a:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
8010353d:	8b 45 08             	mov    0x8(%ebp),%eax
80103540:	0f b6 c0             	movzbl %al,%eax
80103543:	89 44 24 04          	mov    %eax,0x4(%esp)
80103547:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010354e:	e8 c0 fc ff ff       	call   80103213 <outb>
  microdelay(200);
80103553:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010355a:	e8 d9 fe ff ff       	call   80103438 <microdelay>

  return inb(CMOS_RETURN);
8010355f:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103566:	e8 8b fc ff ff       	call   801031f6 <inb>
8010356b:	0f b6 c0             	movzbl %al,%eax
}
8010356e:	c9                   	leave  
8010356f:	c3                   	ret    

80103570 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103570:	55                   	push   %ebp
80103571:	89 e5                	mov    %esp,%ebp
80103573:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
80103576:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010357d:	e8 b5 ff ff ff       	call   80103537 <cmos_read>
80103582:	8b 55 08             	mov    0x8(%ebp),%edx
80103585:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
80103587:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010358e:	e8 a4 ff ff ff       	call   80103537 <cmos_read>
80103593:	8b 55 08             	mov    0x8(%ebp),%edx
80103596:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103599:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801035a0:	e8 92 ff ff ff       	call   80103537 <cmos_read>
801035a5:	8b 55 08             	mov    0x8(%ebp),%edx
801035a8:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
801035ab:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
801035b2:	e8 80 ff ff ff       	call   80103537 <cmos_read>
801035b7:	8b 55 08             	mov    0x8(%ebp),%edx
801035ba:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
801035bd:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801035c4:	e8 6e ff ff ff       	call   80103537 <cmos_read>
801035c9:	8b 55 08             	mov    0x8(%ebp),%edx
801035cc:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
801035cf:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
801035d6:	e8 5c ff ff ff       	call   80103537 <cmos_read>
801035db:	8b 55 08             	mov    0x8(%ebp),%edx
801035de:	89 42 14             	mov    %eax,0x14(%edx)
}
801035e1:	c9                   	leave  
801035e2:	c3                   	ret    

801035e3 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801035e3:	55                   	push   %ebp
801035e4:	89 e5                	mov    %esp,%ebp
801035e6:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801035e9:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801035f0:	e8 42 ff ff ff       	call   80103537 <cmos_read>
801035f5:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801035f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035fb:	83 e0 04             	and    $0x4,%eax
801035fe:	85 c0                	test   %eax,%eax
80103600:	0f 94 c0             	sete   %al
80103603:	0f b6 c0             	movzbl %al,%eax
80103606:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
80103609:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010360c:	89 04 24             	mov    %eax,(%esp)
8010360f:	e8 5c ff ff ff       	call   80103570 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
80103614:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010361b:	e8 17 ff ff ff       	call   80103537 <cmos_read>
80103620:	25 80 00 00 00       	and    $0x80,%eax
80103625:	85 c0                	test   %eax,%eax
80103627:	74 02                	je     8010362b <cmostime+0x48>
        continue;
80103629:	eb 36                	jmp    80103661 <cmostime+0x7e>
    fill_rtcdate(&t2);
8010362b:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010362e:	89 04 24             	mov    %eax,(%esp)
80103631:	e8 3a ff ff ff       	call   80103570 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
80103636:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
8010363d:	00 
8010363e:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103641:	89 44 24 04          	mov    %eax,0x4(%esp)
80103645:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103648:	89 04 24             	mov    %eax,(%esp)
8010364b:	e8 ac 1f 00 00       	call   801055fc <memcmp>
80103650:	85 c0                	test   %eax,%eax
80103652:	75 0d                	jne    80103661 <cmostime+0x7e>
      break;
80103654:	90                   	nop
  }

  // convert
  if (bcd) {
80103655:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103659:	0f 84 ac 00 00 00    	je     8010370b <cmostime+0x128>
8010365f:	eb 02                	jmp    80103663 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103661:	eb a6                	jmp    80103609 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103663:	8b 45 d8             	mov    -0x28(%ebp),%eax
80103666:	c1 e8 04             	shr    $0x4,%eax
80103669:	89 c2                	mov    %eax,%edx
8010366b:	89 d0                	mov    %edx,%eax
8010366d:	c1 e0 02             	shl    $0x2,%eax
80103670:	01 d0                	add    %edx,%eax
80103672:	01 c0                	add    %eax,%eax
80103674:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103677:	83 e2 0f             	and    $0xf,%edx
8010367a:	01 d0                	add    %edx,%eax
8010367c:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
8010367f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103682:	c1 e8 04             	shr    $0x4,%eax
80103685:	89 c2                	mov    %eax,%edx
80103687:	89 d0                	mov    %edx,%eax
80103689:	c1 e0 02             	shl    $0x2,%eax
8010368c:	01 d0                	add    %edx,%eax
8010368e:	01 c0                	add    %eax,%eax
80103690:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103693:	83 e2 0f             	and    $0xf,%edx
80103696:	01 d0                	add    %edx,%eax
80103698:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
8010369b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010369e:	c1 e8 04             	shr    $0x4,%eax
801036a1:	89 c2                	mov    %eax,%edx
801036a3:	89 d0                	mov    %edx,%eax
801036a5:	c1 e0 02             	shl    $0x2,%eax
801036a8:	01 d0                	add    %edx,%eax
801036aa:	01 c0                	add    %eax,%eax
801036ac:	8b 55 e0             	mov    -0x20(%ebp),%edx
801036af:	83 e2 0f             	and    $0xf,%edx
801036b2:	01 d0                	add    %edx,%eax
801036b4:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
801036b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801036ba:	c1 e8 04             	shr    $0x4,%eax
801036bd:	89 c2                	mov    %eax,%edx
801036bf:	89 d0                	mov    %edx,%eax
801036c1:	c1 e0 02             	shl    $0x2,%eax
801036c4:	01 d0                	add    %edx,%eax
801036c6:	01 c0                	add    %eax,%eax
801036c8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801036cb:	83 e2 0f             	and    $0xf,%edx
801036ce:	01 d0                	add    %edx,%eax
801036d0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801036d3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801036d6:	c1 e8 04             	shr    $0x4,%eax
801036d9:	89 c2                	mov    %eax,%edx
801036db:	89 d0                	mov    %edx,%eax
801036dd:	c1 e0 02             	shl    $0x2,%eax
801036e0:	01 d0                	add    %edx,%eax
801036e2:	01 c0                	add    %eax,%eax
801036e4:	8b 55 e8             	mov    -0x18(%ebp),%edx
801036e7:	83 e2 0f             	and    $0xf,%edx
801036ea:	01 d0                	add    %edx,%eax
801036ec:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801036ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036f2:	c1 e8 04             	shr    $0x4,%eax
801036f5:	89 c2                	mov    %eax,%edx
801036f7:	89 d0                	mov    %edx,%eax
801036f9:	c1 e0 02             	shl    $0x2,%eax
801036fc:	01 d0                	add    %edx,%eax
801036fe:	01 c0                	add    %eax,%eax
80103700:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103703:	83 e2 0f             	and    $0xf,%edx
80103706:	01 d0                	add    %edx,%eax
80103708:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
8010370b:	8b 45 08             	mov    0x8(%ebp),%eax
8010370e:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103711:	89 10                	mov    %edx,(%eax)
80103713:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103716:	89 50 04             	mov    %edx,0x4(%eax)
80103719:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010371c:	89 50 08             	mov    %edx,0x8(%eax)
8010371f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103722:	89 50 0c             	mov    %edx,0xc(%eax)
80103725:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103728:	89 50 10             	mov    %edx,0x10(%eax)
8010372b:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010372e:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103731:	8b 45 08             	mov    0x8(%ebp),%eax
80103734:	8b 40 14             	mov    0x14(%eax),%eax
80103737:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
8010373d:	8b 45 08             	mov    0x8(%ebp),%eax
80103740:	89 50 14             	mov    %edx,0x14(%eax)
}
80103743:	c9                   	leave  
80103744:	c3                   	ret    

80103745 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
80103745:	55                   	push   %ebp
80103746:	89 e5                	mov    %esp,%ebp
80103748:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010374b:	c7 44 24 04 78 8b 10 	movl   $0x80108b78,0x4(%esp)
80103752:	80 
80103753:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
8010375a:	e8 b1 1b 00 00       	call   80105310 <initlock>
  readsb(dev, &sb);
8010375f:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103762:	89 44 24 04          	mov    %eax,0x4(%esp)
80103766:	8b 45 08             	mov    0x8(%ebp),%eax
80103769:	89 04 24             	mov    %eax,(%esp)
8010376c:	e8 28 e0 ff ff       	call   80101799 <readsb>
  log.start = sb.logstart;
80103771:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103774:	a3 f4 2a 11 80       	mov    %eax,0x80112af4
  log.size = sb.nlog;
80103779:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010377c:	a3 f8 2a 11 80       	mov    %eax,0x80112af8
  log.dev = dev;
80103781:	8b 45 08             	mov    0x8(%ebp),%eax
80103784:	a3 04 2b 11 80       	mov    %eax,0x80112b04
  recover_from_log();
80103789:	e8 9a 01 00 00       	call   80103928 <recover_from_log>
}
8010378e:	c9                   	leave  
8010378f:	c3                   	ret    

80103790 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103790:	55                   	push   %ebp
80103791:	89 e5                	mov    %esp,%ebp
80103793:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103796:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010379d:	e9 8c 00 00 00       	jmp    8010382e <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801037a2:	8b 15 f4 2a 11 80    	mov    0x80112af4,%edx
801037a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037ab:	01 d0                	add    %edx,%eax
801037ad:	83 c0 01             	add    $0x1,%eax
801037b0:	89 c2                	mov    %eax,%edx
801037b2:	a1 04 2b 11 80       	mov    0x80112b04,%eax
801037b7:	89 54 24 04          	mov    %edx,0x4(%esp)
801037bb:	89 04 24             	mov    %eax,(%esp)
801037be:	e8 e3 c9 ff ff       	call   801001a6 <bread>
801037c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801037c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037c9:	83 c0 10             	add    $0x10,%eax
801037cc:	8b 04 85 cc 2a 11 80 	mov    -0x7feed534(,%eax,4),%eax
801037d3:	89 c2                	mov    %eax,%edx
801037d5:	a1 04 2b 11 80       	mov    0x80112b04,%eax
801037da:	89 54 24 04          	mov    %edx,0x4(%esp)
801037de:	89 04 24             	mov    %eax,(%esp)
801037e1:	e8 c0 c9 ff ff       	call   801001a6 <bread>
801037e6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801037e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037ec:	8d 50 18             	lea    0x18(%eax),%edx
801037ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037f2:	83 c0 18             	add    $0x18,%eax
801037f5:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801037fc:	00 
801037fd:	89 54 24 04          	mov    %edx,0x4(%esp)
80103801:	89 04 24             	mov    %eax,(%esp)
80103804:	e8 4b 1e 00 00       	call   80105654 <memmove>
    bwrite(dbuf);  // write dst to disk
80103809:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010380c:	89 04 24             	mov    %eax,(%esp)
8010380f:	e8 c9 c9 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103814:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103817:	89 04 24             	mov    %eax,(%esp)
8010381a:	e8 f8 c9 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
8010381f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103822:	89 04 24             	mov    %eax,(%esp)
80103825:	e8 ed c9 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010382a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010382e:	a1 08 2b 11 80       	mov    0x80112b08,%eax
80103833:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103836:	0f 8f 66 ff ff ff    	jg     801037a2 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010383c:	c9                   	leave  
8010383d:	c3                   	ret    

8010383e <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010383e:	55                   	push   %ebp
8010383f:	89 e5                	mov    %esp,%ebp
80103841:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103844:	a1 f4 2a 11 80       	mov    0x80112af4,%eax
80103849:	89 c2                	mov    %eax,%edx
8010384b:	a1 04 2b 11 80       	mov    0x80112b04,%eax
80103850:	89 54 24 04          	mov    %edx,0x4(%esp)
80103854:	89 04 24             	mov    %eax,(%esp)
80103857:	e8 4a c9 ff ff       	call   801001a6 <bread>
8010385c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010385f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103862:	83 c0 18             	add    $0x18,%eax
80103865:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103868:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010386b:	8b 00                	mov    (%eax),%eax
8010386d:	a3 08 2b 11 80       	mov    %eax,0x80112b08
  for (i = 0; i < log.lh.n; i++) {
80103872:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103879:	eb 1b                	jmp    80103896 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
8010387b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010387e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103881:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103885:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103888:	83 c2 10             	add    $0x10,%edx
8010388b:	89 04 95 cc 2a 11 80 	mov    %eax,-0x7feed534(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103892:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103896:	a1 08 2b 11 80       	mov    0x80112b08,%eax
8010389b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010389e:	7f db                	jg     8010387b <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
801038a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038a3:	89 04 24             	mov    %eax,(%esp)
801038a6:	e8 6c c9 ff ff       	call   80100217 <brelse>
}
801038ab:	c9                   	leave  
801038ac:	c3                   	ret    

801038ad <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801038ad:	55                   	push   %ebp
801038ae:	89 e5                	mov    %esp,%ebp
801038b0:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801038b3:	a1 f4 2a 11 80       	mov    0x80112af4,%eax
801038b8:	89 c2                	mov    %eax,%edx
801038ba:	a1 04 2b 11 80       	mov    0x80112b04,%eax
801038bf:	89 54 24 04          	mov    %edx,0x4(%esp)
801038c3:	89 04 24             	mov    %eax,(%esp)
801038c6:	e8 db c8 ff ff       	call   801001a6 <bread>
801038cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801038ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038d1:	83 c0 18             	add    $0x18,%eax
801038d4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801038d7:	8b 15 08 2b 11 80    	mov    0x80112b08,%edx
801038dd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801038e0:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801038e2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801038e9:	eb 1b                	jmp    80103906 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
801038eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038ee:	83 c0 10             	add    $0x10,%eax
801038f1:	8b 0c 85 cc 2a 11 80 	mov    -0x7feed534(,%eax,4),%ecx
801038f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801038fb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038fe:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103902:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103906:	a1 08 2b 11 80       	mov    0x80112b08,%eax
8010390b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010390e:	7f db                	jg     801038eb <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
80103910:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103913:	89 04 24             	mov    %eax,(%esp)
80103916:	e8 c2 c8 ff ff       	call   801001dd <bwrite>
  brelse(buf);
8010391b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010391e:	89 04 24             	mov    %eax,(%esp)
80103921:	e8 f1 c8 ff ff       	call   80100217 <brelse>
}
80103926:	c9                   	leave  
80103927:	c3                   	ret    

80103928 <recover_from_log>:

static void
recover_from_log(void)
{
80103928:	55                   	push   %ebp
80103929:	89 e5                	mov    %esp,%ebp
8010392b:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010392e:	e8 0b ff ff ff       	call   8010383e <read_head>
  install_trans(); // if committed, copy from log to disk
80103933:	e8 58 fe ff ff       	call   80103790 <install_trans>
  log.lh.n = 0;
80103938:	c7 05 08 2b 11 80 00 	movl   $0x0,0x80112b08
8010393f:	00 00 00 
  write_head(); // clear the log
80103942:	e8 66 ff ff ff       	call   801038ad <write_head>
}
80103947:	c9                   	leave  
80103948:	c3                   	ret    

80103949 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103949:	55                   	push   %ebp
8010394a:	89 e5                	mov    %esp,%ebp
8010394c:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010394f:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103956:	e8 d6 19 00 00       	call   80105331 <acquire>
  while(1){
    if(log.committing){
8010395b:	a1 00 2b 11 80       	mov    0x80112b00,%eax
80103960:	85 c0                	test   %eax,%eax
80103962:	74 16                	je     8010397a <begin_op+0x31>
      sleep(&log, &log.lock);
80103964:	c7 44 24 04 c0 2a 11 	movl   $0x80112ac0,0x4(%esp)
8010396b:	80 
8010396c:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103973:	e8 ef 16 00 00       	call   80105067 <sleep>
80103978:	eb 4f                	jmp    801039c9 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010397a:	8b 0d 08 2b 11 80    	mov    0x80112b08,%ecx
80103980:	a1 fc 2a 11 80       	mov    0x80112afc,%eax
80103985:	8d 50 01             	lea    0x1(%eax),%edx
80103988:	89 d0                	mov    %edx,%eax
8010398a:	c1 e0 02             	shl    $0x2,%eax
8010398d:	01 d0                	add    %edx,%eax
8010398f:	01 c0                	add    %eax,%eax
80103991:	01 c8                	add    %ecx,%eax
80103993:	83 f8 1e             	cmp    $0x1e,%eax
80103996:	7e 16                	jle    801039ae <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103998:	c7 44 24 04 c0 2a 11 	movl   $0x80112ac0,0x4(%esp)
8010399f:	80 
801039a0:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
801039a7:	e8 bb 16 00 00       	call   80105067 <sleep>
801039ac:	eb 1b                	jmp    801039c9 <begin_op+0x80>
    } else {
      log.outstanding += 1;
801039ae:	a1 fc 2a 11 80       	mov    0x80112afc,%eax
801039b3:	83 c0 01             	add    $0x1,%eax
801039b6:	a3 fc 2a 11 80       	mov    %eax,0x80112afc
      release(&log.lock);
801039bb:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
801039c2:	e8 cc 19 00 00       	call   80105393 <release>
      break;
801039c7:	eb 02                	jmp    801039cb <begin_op+0x82>
    }
  }
801039c9:	eb 90                	jmp    8010395b <begin_op+0x12>
}
801039cb:	c9                   	leave  
801039cc:	c3                   	ret    

801039cd <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801039cd:	55                   	push   %ebp
801039ce:	89 e5                	mov    %esp,%ebp
801039d0:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
801039d3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801039da:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
801039e1:	e8 4b 19 00 00       	call   80105331 <acquire>
  log.outstanding -= 1;
801039e6:	a1 fc 2a 11 80       	mov    0x80112afc,%eax
801039eb:	83 e8 01             	sub    $0x1,%eax
801039ee:	a3 fc 2a 11 80       	mov    %eax,0x80112afc
  if(log.committing)
801039f3:	a1 00 2b 11 80       	mov    0x80112b00,%eax
801039f8:	85 c0                	test   %eax,%eax
801039fa:	74 0c                	je     80103a08 <end_op+0x3b>
    panic("log.committing");
801039fc:	c7 04 24 7c 8b 10 80 	movl   $0x80108b7c,(%esp)
80103a03:	e8 32 cb ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103a08:	a1 fc 2a 11 80       	mov    0x80112afc,%eax
80103a0d:	85 c0                	test   %eax,%eax
80103a0f:	75 13                	jne    80103a24 <end_op+0x57>
    do_commit = 1;
80103a11:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103a18:	c7 05 00 2b 11 80 01 	movl   $0x1,0x80112b00
80103a1f:	00 00 00 
80103a22:	eb 0c                	jmp    80103a30 <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103a24:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103a2b:	e8 10 17 00 00       	call   80105140 <wakeup>
  }
  release(&log.lock);
80103a30:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103a37:	e8 57 19 00 00       	call   80105393 <release>

  if(do_commit){
80103a3c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103a40:	74 33                	je     80103a75 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103a42:	e8 de 00 00 00       	call   80103b25 <commit>
    acquire(&log.lock);
80103a47:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103a4e:	e8 de 18 00 00       	call   80105331 <acquire>
    log.committing = 0;
80103a53:	c7 05 00 2b 11 80 00 	movl   $0x0,0x80112b00
80103a5a:	00 00 00 
    wakeup(&log);
80103a5d:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103a64:	e8 d7 16 00 00       	call   80105140 <wakeup>
    release(&log.lock);
80103a69:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103a70:	e8 1e 19 00 00       	call   80105393 <release>
  }
}
80103a75:	c9                   	leave  
80103a76:	c3                   	ret    

80103a77 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103a77:	55                   	push   %ebp
80103a78:	89 e5                	mov    %esp,%ebp
80103a7a:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a7d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a84:	e9 8c 00 00 00       	jmp    80103b15 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103a89:	8b 15 f4 2a 11 80    	mov    0x80112af4,%edx
80103a8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a92:	01 d0                	add    %edx,%eax
80103a94:	83 c0 01             	add    $0x1,%eax
80103a97:	89 c2                	mov    %eax,%edx
80103a99:	a1 04 2b 11 80       	mov    0x80112b04,%eax
80103a9e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103aa2:	89 04 24             	mov    %eax,(%esp)
80103aa5:	e8 fc c6 ff ff       	call   801001a6 <bread>
80103aaa:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80103aad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ab0:	83 c0 10             	add    $0x10,%eax
80103ab3:	8b 04 85 cc 2a 11 80 	mov    -0x7feed534(,%eax,4),%eax
80103aba:	89 c2                	mov    %eax,%edx
80103abc:	a1 04 2b 11 80       	mov    0x80112b04,%eax
80103ac1:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ac5:	89 04 24             	mov    %eax,(%esp)
80103ac8:	e8 d9 c6 ff ff       	call   801001a6 <bread>
80103acd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
80103ad0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ad3:	8d 50 18             	lea    0x18(%eax),%edx
80103ad6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ad9:	83 c0 18             	add    $0x18,%eax
80103adc:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103ae3:	00 
80103ae4:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ae8:	89 04 24             	mov    %eax,(%esp)
80103aeb:	e8 64 1b 00 00       	call   80105654 <memmove>
    bwrite(to);  // write the log
80103af0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103af3:	89 04 24             	mov    %eax,(%esp)
80103af6:	e8 e2 c6 ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103afb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103afe:	89 04 24             	mov    %eax,(%esp)
80103b01:	e8 11 c7 ff ff       	call   80100217 <brelse>
    brelse(to);
80103b06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b09:	89 04 24             	mov    %eax,(%esp)
80103b0c:	e8 06 c7 ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103b11:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b15:	a1 08 2b 11 80       	mov    0x80112b08,%eax
80103b1a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b1d:	0f 8f 66 ff ff ff    	jg     80103a89 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103b23:	c9                   	leave  
80103b24:	c3                   	ret    

80103b25 <commit>:

static void
commit()
{
80103b25:	55                   	push   %ebp
80103b26:	89 e5                	mov    %esp,%ebp
80103b28:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103b2b:	a1 08 2b 11 80       	mov    0x80112b08,%eax
80103b30:	85 c0                	test   %eax,%eax
80103b32:	7e 1e                	jle    80103b52 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103b34:	e8 3e ff ff ff       	call   80103a77 <write_log>
    write_head();    // Write header to disk -- the real commit
80103b39:	e8 6f fd ff ff       	call   801038ad <write_head>
    install_trans(); // Now install writes to home locations
80103b3e:	e8 4d fc ff ff       	call   80103790 <install_trans>
    log.lh.n = 0; 
80103b43:	c7 05 08 2b 11 80 00 	movl   $0x0,0x80112b08
80103b4a:	00 00 00 
    write_head();    // Erase the transaction from the log
80103b4d:	e8 5b fd ff ff       	call   801038ad <write_head>
  }
}
80103b52:	c9                   	leave  
80103b53:	c3                   	ret    

80103b54 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103b54:	55                   	push   %ebp
80103b55:	89 e5                	mov    %esp,%ebp
80103b57:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103b5a:	a1 08 2b 11 80       	mov    0x80112b08,%eax
80103b5f:	83 f8 1d             	cmp    $0x1d,%eax
80103b62:	7f 12                	jg     80103b76 <log_write+0x22>
80103b64:	a1 08 2b 11 80       	mov    0x80112b08,%eax
80103b69:	8b 15 f8 2a 11 80    	mov    0x80112af8,%edx
80103b6f:	83 ea 01             	sub    $0x1,%edx
80103b72:	39 d0                	cmp    %edx,%eax
80103b74:	7c 0c                	jl     80103b82 <log_write+0x2e>
    panic("too big a transaction");
80103b76:	c7 04 24 8b 8b 10 80 	movl   $0x80108b8b,(%esp)
80103b7d:	e8 b8 c9 ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103b82:	a1 fc 2a 11 80       	mov    0x80112afc,%eax
80103b87:	85 c0                	test   %eax,%eax
80103b89:	7f 0c                	jg     80103b97 <log_write+0x43>
    panic("log_write outside of trans");
80103b8b:	c7 04 24 a1 8b 10 80 	movl   $0x80108ba1,(%esp)
80103b92:	e8 a3 c9 ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103b97:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103b9e:	e8 8e 17 00 00       	call   80105331 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80103ba3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103baa:	eb 1f                	jmp    80103bcb <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80103bac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103baf:	83 c0 10             	add    $0x10,%eax
80103bb2:	8b 04 85 cc 2a 11 80 	mov    -0x7feed534(,%eax,4),%eax
80103bb9:	89 c2                	mov    %eax,%edx
80103bbb:	8b 45 08             	mov    0x8(%ebp),%eax
80103bbe:	8b 40 08             	mov    0x8(%eax),%eax
80103bc1:	39 c2                	cmp    %eax,%edx
80103bc3:	75 02                	jne    80103bc7 <log_write+0x73>
      break;
80103bc5:	eb 0e                	jmp    80103bd5 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103bc7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103bcb:	a1 08 2b 11 80       	mov    0x80112b08,%eax
80103bd0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103bd3:	7f d7                	jg     80103bac <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
80103bd5:	8b 45 08             	mov    0x8(%ebp),%eax
80103bd8:	8b 40 08             	mov    0x8(%eax),%eax
80103bdb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103bde:	83 c2 10             	add    $0x10,%edx
80103be1:	89 04 95 cc 2a 11 80 	mov    %eax,-0x7feed534(,%edx,4)
  if (i == log.lh.n)
80103be8:	a1 08 2b 11 80       	mov    0x80112b08,%eax
80103bed:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103bf0:	75 0d                	jne    80103bff <log_write+0xab>
    log.lh.n++;
80103bf2:	a1 08 2b 11 80       	mov    0x80112b08,%eax
80103bf7:	83 c0 01             	add    $0x1,%eax
80103bfa:	a3 08 2b 11 80       	mov    %eax,0x80112b08
  b->flags |= B_DIRTY; // prevent eviction
80103bff:	8b 45 08             	mov    0x8(%ebp),%eax
80103c02:	8b 00                	mov    (%eax),%eax
80103c04:	83 c8 04             	or     $0x4,%eax
80103c07:	89 c2                	mov    %eax,%edx
80103c09:	8b 45 08             	mov    0x8(%ebp),%eax
80103c0c:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103c0e:	c7 04 24 c0 2a 11 80 	movl   $0x80112ac0,(%esp)
80103c15:	e8 79 17 00 00       	call   80105393 <release>
}
80103c1a:	c9                   	leave  
80103c1b:	c3                   	ret    

80103c1c <v2p>:
80103c1c:	55                   	push   %ebp
80103c1d:	89 e5                	mov    %esp,%ebp
80103c1f:	8b 45 08             	mov    0x8(%ebp),%eax
80103c22:	05 00 00 00 80       	add    $0x80000000,%eax
80103c27:	5d                   	pop    %ebp
80103c28:	c3                   	ret    

80103c29 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103c29:	55                   	push   %ebp
80103c2a:	89 e5                	mov    %esp,%ebp
80103c2c:	8b 45 08             	mov    0x8(%ebp),%eax
80103c2f:	05 00 00 00 80       	add    $0x80000000,%eax
80103c34:	5d                   	pop    %ebp
80103c35:	c3                   	ret    

80103c36 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103c36:	55                   	push   %ebp
80103c37:	89 e5                	mov    %esp,%ebp
80103c39:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103c3c:	8b 55 08             	mov    0x8(%ebp),%edx
80103c3f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c42:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103c45:	f0 87 02             	lock xchg %eax,(%edx)
80103c48:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103c4b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80103c4e:	c9                   	leave  
80103c4f:	c3                   	ret    

80103c50 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103c50:	55                   	push   %ebp
80103c51:	89 e5                	mov    %esp,%ebp
80103c53:	83 e4 f0             	and    $0xfffffff0,%esp
80103c56:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103c59:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103c60:	80 
80103c61:	c7 04 24 9c 59 11 80 	movl   $0x8011599c,(%esp)
80103c68:	e8 8a f2 ff ff       	call   80102ef7 <kinit1>
  kvmalloc();      // kernel page table
80103c6d:	e8 d8 44 00 00       	call   8010814a <kvmalloc>
  mpinit();        // collect info about this machine
80103c72:	e8 41 04 00 00       	call   801040b8 <mpinit>
  lapicinit();
80103c77:	e8 e6 f5 ff ff       	call   80103262 <lapicinit>
  seginit();       // set up segments
80103c7c:	e8 5c 3e 00 00       	call   80107add <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103c81:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103c87:	0f b6 00             	movzbl (%eax),%eax
80103c8a:	0f b6 c0             	movzbl %al,%eax
80103c8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c91:	c7 04 24 bc 8b 10 80 	movl   $0x80108bbc,(%esp)
80103c98:	e8 03 c7 ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103c9d:	e8 74 06 00 00       	call   80104316 <picinit>
  ioapicinit();    // another interrupt controller
80103ca2:	e8 46 f1 ff ff       	call   80102ded <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103ca7:	e8 91 d2 ff ff       	call   80100f3d <consoleinit>
  uartinit();      // serial port
80103cac:	e8 7b 31 00 00       	call   80106e2c <uartinit>
  pinit();         // process table
80103cb1:	e8 6a 0b 00 00       	call   80104820 <pinit>
  tvinit();        // trap vectors
80103cb6:	e8 23 2d 00 00       	call   801069de <tvinit>
  binit();         // buffer cache
80103cbb:	e8 74 c3 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103cc0:	e8 ed d6 ff ff       	call   801013b2 <fileinit>
  ideinit();       // disk
80103cc5:	e8 55 ed ff ff       	call   80102a1f <ideinit>
  if(!ismp)
80103cca:	a1 a4 2b 11 80       	mov    0x80112ba4,%eax
80103ccf:	85 c0                	test   %eax,%eax
80103cd1:	75 05                	jne    80103cd8 <main+0x88>
    timerinit();   // uniprocessor timer
80103cd3:	e8 51 2c 00 00       	call   80106929 <timerinit>
  startothers();   // start other processors
80103cd8:	e8 7f 00 00 00       	call   80103d5c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103cdd:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103ce4:	8e 
80103ce5:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103cec:	e8 3e f2 ff ff       	call   80102f2f <kinit2>
  userinit();      // first user process
80103cf1:	e8 45 0c 00 00       	call   8010493b <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103cf6:	e8 1a 00 00 00       	call   80103d15 <mpmain>

80103cfb <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103cfb:	55                   	push   %ebp
80103cfc:	89 e5                	mov    %esp,%ebp
80103cfe:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103d01:	e8 5b 44 00 00       	call   80108161 <switchkvm>
  seginit();
80103d06:	e8 d2 3d 00 00       	call   80107add <seginit>
  lapicinit();
80103d0b:	e8 52 f5 ff ff       	call   80103262 <lapicinit>
  mpmain();
80103d10:	e8 00 00 00 00       	call   80103d15 <mpmain>

80103d15 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103d15:	55                   	push   %ebp
80103d16:	89 e5                	mov    %esp,%ebp
80103d18:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103d1b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103d21:	0f b6 00             	movzbl (%eax),%eax
80103d24:	0f b6 c0             	movzbl %al,%eax
80103d27:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d2b:	c7 04 24 d3 8b 10 80 	movl   $0x80108bd3,(%esp)
80103d32:	e8 69 c6 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
80103d37:	e8 16 2e 00 00       	call   80106b52 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103d3c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103d42:	05 a8 00 00 00       	add    $0xa8,%eax
80103d47:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103d4e:	00 
80103d4f:	89 04 24             	mov    %eax,(%esp)
80103d52:	e8 df fe ff ff       	call   80103c36 <xchg>
  scheduler();     // start running processes
80103d57:	e8 50 11 00 00       	call   80104eac <scheduler>

80103d5c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103d5c:	55                   	push   %ebp
80103d5d:	89 e5                	mov    %esp,%ebp
80103d5f:	53                   	push   %ebx
80103d60:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103d63:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103d6a:	e8 ba fe ff ff       	call   80103c29 <p2v>
80103d6f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103d72:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103d77:	89 44 24 08          	mov    %eax,0x8(%esp)
80103d7b:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
80103d82:	80 
80103d83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d86:	89 04 24             	mov    %eax,(%esp)
80103d89:	e8 c6 18 00 00       	call   80105654 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103d8e:	c7 45 f4 c0 2b 11 80 	movl   $0x80112bc0,-0xc(%ebp)
80103d95:	e9 85 00 00 00       	jmp    80103e1f <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103d9a:	e8 1c f6 ff ff       	call   801033bb <cpunum>
80103d9f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103da5:	05 c0 2b 11 80       	add    $0x80112bc0,%eax
80103daa:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103dad:	75 02                	jne    80103db1 <startothers+0x55>
      continue;
80103daf:	eb 67                	jmp    80103e18 <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103db1:	e8 6f f2 ff ff       	call   80103025 <kalloc>
80103db6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103db9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dbc:	83 e8 04             	sub    $0x4,%eax
80103dbf:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103dc2:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103dc8:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103dca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dcd:	83 e8 08             	sub    $0x8,%eax
80103dd0:	c7 00 fb 3c 10 80    	movl   $0x80103cfb,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103dd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dd9:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103ddc:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103de3:	e8 34 fe ff ff       	call   80103c1c <v2p>
80103de8:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103dea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ded:	89 04 24             	mov    %eax,(%esp)
80103df0:	e8 27 fe ff ff       	call   80103c1c <v2p>
80103df5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103df8:	0f b6 12             	movzbl (%edx),%edx
80103dfb:	0f b6 d2             	movzbl %dl,%edx
80103dfe:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e02:	89 14 24             	mov    %edx,(%esp)
80103e05:	e8 33 f6 ff ff       	call   8010343d <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103e0a:	90                   	nop
80103e0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e0e:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103e14:	85 c0                	test   %eax,%eax
80103e16:	74 f3                	je     80103e0b <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103e18:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103e1f:	a1 a0 31 11 80       	mov    0x801131a0,%eax
80103e24:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103e2a:	05 c0 2b 11 80       	add    $0x80112bc0,%eax
80103e2f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e32:	0f 87 62 ff ff ff    	ja     80103d9a <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103e38:	83 c4 24             	add    $0x24,%esp
80103e3b:	5b                   	pop    %ebx
80103e3c:	5d                   	pop    %ebp
80103e3d:	c3                   	ret    

80103e3e <p2v>:
80103e3e:	55                   	push   %ebp
80103e3f:	89 e5                	mov    %esp,%ebp
80103e41:	8b 45 08             	mov    0x8(%ebp),%eax
80103e44:	05 00 00 00 80       	add    $0x80000000,%eax
80103e49:	5d                   	pop    %ebp
80103e4a:	c3                   	ret    

80103e4b <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103e4b:	55                   	push   %ebp
80103e4c:	89 e5                	mov    %esp,%ebp
80103e4e:	83 ec 14             	sub    $0x14,%esp
80103e51:	8b 45 08             	mov    0x8(%ebp),%eax
80103e54:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103e58:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103e5c:	89 c2                	mov    %eax,%edx
80103e5e:	ec                   	in     (%dx),%al
80103e5f:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103e62:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103e66:	c9                   	leave  
80103e67:	c3                   	ret    

80103e68 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103e68:	55                   	push   %ebp
80103e69:	89 e5                	mov    %esp,%ebp
80103e6b:	83 ec 08             	sub    $0x8,%esp
80103e6e:	8b 55 08             	mov    0x8(%ebp),%edx
80103e71:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e74:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103e78:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103e7b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103e7f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103e83:	ee                   	out    %al,(%dx)
}
80103e84:	c9                   	leave  
80103e85:	c3                   	ret    

80103e86 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103e86:	55                   	push   %ebp
80103e87:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103e89:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103e8e:	89 c2                	mov    %eax,%edx
80103e90:	b8 c0 2b 11 80       	mov    $0x80112bc0,%eax
80103e95:	29 c2                	sub    %eax,%edx
80103e97:	89 d0                	mov    %edx,%eax
80103e99:	c1 f8 02             	sar    $0x2,%eax
80103e9c:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103ea2:	5d                   	pop    %ebp
80103ea3:	c3                   	ret    

80103ea4 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103ea4:	55                   	push   %ebp
80103ea5:	89 e5                	mov    %esp,%ebp
80103ea7:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103eaa:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103eb1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103eb8:	eb 15                	jmp    80103ecf <sum+0x2b>
    sum += addr[i];
80103eba:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103ebd:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec0:	01 d0                	add    %edx,%eax
80103ec2:	0f b6 00             	movzbl (%eax),%eax
80103ec5:	0f b6 c0             	movzbl %al,%eax
80103ec8:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103ecb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103ecf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ed2:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103ed5:	7c e3                	jl     80103eba <sum+0x16>
    sum += addr[i];
  return sum;
80103ed7:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103eda:	c9                   	leave  
80103edb:	c3                   	ret    

80103edc <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103edc:	55                   	push   %ebp
80103edd:	89 e5                	mov    %esp,%ebp
80103edf:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103ee2:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee5:	89 04 24             	mov    %eax,(%esp)
80103ee8:	e8 51 ff ff ff       	call   80103e3e <p2v>
80103eed:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103ef0:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ef3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ef6:	01 d0                	add    %edx,%eax
80103ef8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103efb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103efe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103f01:	eb 3f                	jmp    80103f42 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103f03:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103f0a:	00 
80103f0b:	c7 44 24 04 e4 8b 10 	movl   $0x80108be4,0x4(%esp)
80103f12:	80 
80103f13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f16:	89 04 24             	mov    %eax,(%esp)
80103f19:	e8 de 16 00 00       	call   801055fc <memcmp>
80103f1e:	85 c0                	test   %eax,%eax
80103f20:	75 1c                	jne    80103f3e <mpsearch1+0x62>
80103f22:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103f29:	00 
80103f2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f2d:	89 04 24             	mov    %eax,(%esp)
80103f30:	e8 6f ff ff ff       	call   80103ea4 <sum>
80103f35:	84 c0                	test   %al,%al
80103f37:	75 05                	jne    80103f3e <mpsearch1+0x62>
      return (struct mp*)p;
80103f39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f3c:	eb 11                	jmp    80103f4f <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103f3e:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103f42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f45:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103f48:	72 b9                	jb     80103f03 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103f4a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f4f:	c9                   	leave  
80103f50:	c3                   	ret    

80103f51 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103f51:	55                   	push   %ebp
80103f52:	89 e5                	mov    %esp,%ebp
80103f54:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103f57:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103f5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f61:	83 c0 0f             	add    $0xf,%eax
80103f64:	0f b6 00             	movzbl (%eax),%eax
80103f67:	0f b6 c0             	movzbl %al,%eax
80103f6a:	c1 e0 08             	shl    $0x8,%eax
80103f6d:	89 c2                	mov    %eax,%edx
80103f6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f72:	83 c0 0e             	add    $0xe,%eax
80103f75:	0f b6 00             	movzbl (%eax),%eax
80103f78:	0f b6 c0             	movzbl %al,%eax
80103f7b:	09 d0                	or     %edx,%eax
80103f7d:	c1 e0 04             	shl    $0x4,%eax
80103f80:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103f83:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103f87:	74 21                	je     80103faa <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103f89:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103f90:	00 
80103f91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f94:	89 04 24             	mov    %eax,(%esp)
80103f97:	e8 40 ff ff ff       	call   80103edc <mpsearch1>
80103f9c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103f9f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103fa3:	74 50                	je     80103ff5 <mpsearch+0xa4>
      return mp;
80103fa5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103fa8:	eb 5f                	jmp    80104009 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103faa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fad:	83 c0 14             	add    $0x14,%eax
80103fb0:	0f b6 00             	movzbl (%eax),%eax
80103fb3:	0f b6 c0             	movzbl %al,%eax
80103fb6:	c1 e0 08             	shl    $0x8,%eax
80103fb9:	89 c2                	mov    %eax,%edx
80103fbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fbe:	83 c0 13             	add    $0x13,%eax
80103fc1:	0f b6 00             	movzbl (%eax),%eax
80103fc4:	0f b6 c0             	movzbl %al,%eax
80103fc7:	09 d0                	or     %edx,%eax
80103fc9:	c1 e0 0a             	shl    $0xa,%eax
80103fcc:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103fcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fd2:	2d 00 04 00 00       	sub    $0x400,%eax
80103fd7:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103fde:	00 
80103fdf:	89 04 24             	mov    %eax,(%esp)
80103fe2:	e8 f5 fe ff ff       	call   80103edc <mpsearch1>
80103fe7:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103fea:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103fee:	74 05                	je     80103ff5 <mpsearch+0xa4>
      return mp;
80103ff0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ff3:	eb 14                	jmp    80104009 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103ff5:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103ffc:	00 
80103ffd:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104004:	e8 d3 fe ff ff       	call   80103edc <mpsearch1>
}
80104009:	c9                   	leave  
8010400a:	c3                   	ret    

8010400b <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
8010400b:	55                   	push   %ebp
8010400c:	89 e5                	mov    %esp,%ebp
8010400e:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104011:	e8 3b ff ff ff       	call   80103f51 <mpsearch>
80104016:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104019:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010401d:	74 0a                	je     80104029 <mpconfig+0x1e>
8010401f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104022:	8b 40 04             	mov    0x4(%eax),%eax
80104025:	85 c0                	test   %eax,%eax
80104027:	75 0a                	jne    80104033 <mpconfig+0x28>
    return 0;
80104029:	b8 00 00 00 00       	mov    $0x0,%eax
8010402e:	e9 83 00 00 00       	jmp    801040b6 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104033:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104036:	8b 40 04             	mov    0x4(%eax),%eax
80104039:	89 04 24             	mov    %eax,(%esp)
8010403c:	e8 fd fd ff ff       	call   80103e3e <p2v>
80104041:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104044:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010404b:	00 
8010404c:	c7 44 24 04 e9 8b 10 	movl   $0x80108be9,0x4(%esp)
80104053:	80 
80104054:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104057:	89 04 24             	mov    %eax,(%esp)
8010405a:	e8 9d 15 00 00       	call   801055fc <memcmp>
8010405f:	85 c0                	test   %eax,%eax
80104061:	74 07                	je     8010406a <mpconfig+0x5f>
    return 0;
80104063:	b8 00 00 00 00       	mov    $0x0,%eax
80104068:	eb 4c                	jmp    801040b6 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010406a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010406d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104071:	3c 01                	cmp    $0x1,%al
80104073:	74 12                	je     80104087 <mpconfig+0x7c>
80104075:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104078:	0f b6 40 06          	movzbl 0x6(%eax),%eax
8010407c:	3c 04                	cmp    $0x4,%al
8010407e:	74 07                	je     80104087 <mpconfig+0x7c>
    return 0;
80104080:	b8 00 00 00 00       	mov    $0x0,%eax
80104085:	eb 2f                	jmp    801040b6 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104087:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010408a:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010408e:	0f b7 c0             	movzwl %ax,%eax
80104091:	89 44 24 04          	mov    %eax,0x4(%esp)
80104095:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104098:	89 04 24             	mov    %eax,(%esp)
8010409b:	e8 04 fe ff ff       	call   80103ea4 <sum>
801040a0:	84 c0                	test   %al,%al
801040a2:	74 07                	je     801040ab <mpconfig+0xa0>
    return 0;
801040a4:	b8 00 00 00 00       	mov    $0x0,%eax
801040a9:	eb 0b                	jmp    801040b6 <mpconfig+0xab>
  *pmp = mp;
801040ab:	8b 45 08             	mov    0x8(%ebp),%eax
801040ae:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040b1:	89 10                	mov    %edx,(%eax)
  return conf;
801040b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801040b6:	c9                   	leave  
801040b7:	c3                   	ret    

801040b8 <mpinit>:

void
mpinit(void)
{
801040b8:	55                   	push   %ebp
801040b9:	89 e5                	mov    %esp,%ebp
801040bb:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801040be:	c7 05 44 b6 10 80 c0 	movl   $0x80112bc0,0x8010b644
801040c5:	2b 11 80 
  if((conf = mpconfig(&mp)) == 0)
801040c8:	8d 45 e0             	lea    -0x20(%ebp),%eax
801040cb:	89 04 24             	mov    %eax,(%esp)
801040ce:	e8 38 ff ff ff       	call   8010400b <mpconfig>
801040d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801040d6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801040da:	75 05                	jne    801040e1 <mpinit+0x29>
    return;
801040dc:	e9 9c 01 00 00       	jmp    8010427d <mpinit+0x1c5>
  ismp = 1;
801040e1:	c7 05 a4 2b 11 80 01 	movl   $0x1,0x80112ba4
801040e8:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801040eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040ee:	8b 40 24             	mov    0x24(%eax),%eax
801040f1:	a3 bc 2a 11 80       	mov    %eax,0x80112abc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801040f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040f9:	83 c0 2c             	add    $0x2c,%eax
801040fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801040ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104102:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104106:	0f b7 d0             	movzwl %ax,%edx
80104109:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010410c:	01 d0                	add    %edx,%eax
8010410e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104111:	e9 f4 00 00 00       	jmp    8010420a <mpinit+0x152>
    switch(*p){
80104116:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104119:	0f b6 00             	movzbl (%eax),%eax
8010411c:	0f b6 c0             	movzbl %al,%eax
8010411f:	83 f8 04             	cmp    $0x4,%eax
80104122:	0f 87 bf 00 00 00    	ja     801041e7 <mpinit+0x12f>
80104128:	8b 04 85 2c 8c 10 80 	mov    -0x7fef73d4(,%eax,4),%eax
8010412f:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104131:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104134:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104137:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010413a:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010413e:	0f b6 d0             	movzbl %al,%edx
80104141:	a1 a0 31 11 80       	mov    0x801131a0,%eax
80104146:	39 c2                	cmp    %eax,%edx
80104148:	74 2d                	je     80104177 <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010414a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010414d:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104151:	0f b6 d0             	movzbl %al,%edx
80104154:	a1 a0 31 11 80       	mov    0x801131a0,%eax
80104159:	89 54 24 08          	mov    %edx,0x8(%esp)
8010415d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104161:	c7 04 24 ee 8b 10 80 	movl   $0x80108bee,(%esp)
80104168:	e8 33 c2 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
8010416d:	c7 05 a4 2b 11 80 00 	movl   $0x0,0x80112ba4
80104174:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104177:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010417a:	0f b6 40 03          	movzbl 0x3(%eax),%eax
8010417e:	0f b6 c0             	movzbl %al,%eax
80104181:	83 e0 02             	and    $0x2,%eax
80104184:	85 c0                	test   %eax,%eax
80104186:	74 15                	je     8010419d <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80104188:	a1 a0 31 11 80       	mov    0x801131a0,%eax
8010418d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104193:	05 c0 2b 11 80       	add    $0x80112bc0,%eax
80104198:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
8010419d:	8b 15 a0 31 11 80    	mov    0x801131a0,%edx
801041a3:	a1 a0 31 11 80       	mov    0x801131a0,%eax
801041a8:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
801041ae:	81 c2 c0 2b 11 80    	add    $0x80112bc0,%edx
801041b4:	88 02                	mov    %al,(%edx)
      ncpu++;
801041b6:	a1 a0 31 11 80       	mov    0x801131a0,%eax
801041bb:	83 c0 01             	add    $0x1,%eax
801041be:	a3 a0 31 11 80       	mov    %eax,0x801131a0
      p += sizeof(struct mpproc);
801041c3:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
801041c7:	eb 41                	jmp    8010420a <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
801041c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
801041cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801041d2:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801041d6:	a2 a0 2b 11 80       	mov    %al,0x80112ba0
      p += sizeof(struct mpioapic);
801041db:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801041df:	eb 29                	jmp    8010420a <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
801041e1:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801041e5:	eb 23                	jmp    8010420a <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
801041e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ea:	0f b6 00             	movzbl (%eax),%eax
801041ed:	0f b6 c0             	movzbl %al,%eax
801041f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801041f4:	c7 04 24 0c 8c 10 80 	movl   $0x80108c0c,(%esp)
801041fb:	e8 a0 c1 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80104200:	c7 05 a4 2b 11 80 00 	movl   $0x0,0x80112ba4
80104207:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010420a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010420d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104210:	0f 82 00 ff ff ff    	jb     80104116 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104216:	a1 a4 2b 11 80       	mov    0x80112ba4,%eax
8010421b:	85 c0                	test   %eax,%eax
8010421d:	75 1d                	jne    8010423c <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
8010421f:	c7 05 a0 31 11 80 01 	movl   $0x1,0x801131a0
80104226:	00 00 00 
    lapic = 0;
80104229:	c7 05 bc 2a 11 80 00 	movl   $0x0,0x80112abc
80104230:	00 00 00 
    ioapicid = 0;
80104233:	c6 05 a0 2b 11 80 00 	movb   $0x0,0x80112ba0
    return;
8010423a:	eb 41                	jmp    8010427d <mpinit+0x1c5>
  }

  if(mp->imcrp){
8010423c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010423f:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104243:	84 c0                	test   %al,%al
80104245:	74 36                	je     8010427d <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104247:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
8010424e:	00 
8010424f:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104256:	e8 0d fc ff ff       	call   80103e68 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
8010425b:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104262:	e8 e4 fb ff ff       	call   80103e4b <inb>
80104267:	83 c8 01             	or     $0x1,%eax
8010426a:	0f b6 c0             	movzbl %al,%eax
8010426d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104271:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104278:	e8 eb fb ff ff       	call   80103e68 <outb>
  }
}
8010427d:	c9                   	leave  
8010427e:	c3                   	ret    

8010427f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010427f:	55                   	push   %ebp
80104280:	89 e5                	mov    %esp,%ebp
80104282:	83 ec 08             	sub    $0x8,%esp
80104285:	8b 55 08             	mov    0x8(%ebp),%edx
80104288:	8b 45 0c             	mov    0xc(%ebp),%eax
8010428b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010428f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104292:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104296:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010429a:	ee                   	out    %al,(%dx)
}
8010429b:	c9                   	leave  
8010429c:	c3                   	ret    

8010429d <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
8010429d:	55                   	push   %ebp
8010429e:	89 e5                	mov    %esp,%ebp
801042a0:	83 ec 0c             	sub    $0xc,%esp
801042a3:	8b 45 08             	mov    0x8(%ebp),%eax
801042a6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
801042aa:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801042ae:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
801042b4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801042b8:	0f b6 c0             	movzbl %al,%eax
801042bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801042bf:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801042c6:	e8 b4 ff ff ff       	call   8010427f <outb>
  outb(IO_PIC2+1, mask >> 8);
801042cb:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801042cf:	66 c1 e8 08          	shr    $0x8,%ax
801042d3:	0f b6 c0             	movzbl %al,%eax
801042d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801042da:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801042e1:	e8 99 ff ff ff       	call   8010427f <outb>
}
801042e6:	c9                   	leave  
801042e7:	c3                   	ret    

801042e8 <picenable>:

void
picenable(int irq)
{
801042e8:	55                   	push   %ebp
801042e9:	89 e5                	mov    %esp,%ebp
801042eb:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
801042ee:	8b 45 08             	mov    0x8(%ebp),%eax
801042f1:	ba 01 00 00 00       	mov    $0x1,%edx
801042f6:	89 c1                	mov    %eax,%ecx
801042f8:	d3 e2                	shl    %cl,%edx
801042fa:	89 d0                	mov    %edx,%eax
801042fc:	f7 d0                	not    %eax
801042fe:	89 c2                	mov    %eax,%edx
80104300:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80104307:	21 d0                	and    %edx,%eax
80104309:	0f b7 c0             	movzwl %ax,%eax
8010430c:	89 04 24             	mov    %eax,(%esp)
8010430f:	e8 89 ff ff ff       	call   8010429d <picsetmask>
}
80104314:	c9                   	leave  
80104315:	c3                   	ret    

80104316 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104316:	55                   	push   %ebp
80104317:	89 e5                	mov    %esp,%ebp
80104319:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
8010431c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104323:	00 
80104324:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010432b:	e8 4f ff ff ff       	call   8010427f <outb>
  outb(IO_PIC2+1, 0xFF);
80104330:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104337:	00 
80104338:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010433f:	e8 3b ff ff ff       	call   8010427f <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104344:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010434b:	00 
8010434c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104353:	e8 27 ff ff ff       	call   8010427f <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104358:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010435f:	00 
80104360:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104367:	e8 13 ff ff ff       	call   8010427f <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
8010436c:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104373:	00 
80104374:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010437b:	e8 ff fe ff ff       	call   8010427f <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104380:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104387:	00 
80104388:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010438f:	e8 eb fe ff ff       	call   8010427f <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104394:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010439b:	00 
8010439c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801043a3:	e8 d7 fe ff ff       	call   8010427f <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
801043a8:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
801043af:	00 
801043b0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801043b7:	e8 c3 fe ff ff       	call   8010427f <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
801043bc:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801043c3:	00 
801043c4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801043cb:	e8 af fe ff ff       	call   8010427f <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
801043d0:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801043d7:	00 
801043d8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801043df:	e8 9b fe ff ff       	call   8010427f <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
801043e4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801043eb:	00 
801043ec:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801043f3:	e8 87 fe ff ff       	call   8010427f <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
801043f8:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801043ff:	00 
80104400:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104407:	e8 73 fe ff ff       	call   8010427f <outb>

  outb(IO_PIC2, 0x68);             // OCW3
8010440c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104413:	00 
80104414:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010441b:	e8 5f fe ff ff       	call   8010427f <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104420:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104427:	00 
80104428:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010442f:	e8 4b fe ff ff       	call   8010427f <outb>

  if(irqmask != 0xFFFF)
80104434:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
8010443b:	66 83 f8 ff          	cmp    $0xffff,%ax
8010443f:	74 12                	je     80104453 <picinit+0x13d>
    picsetmask(irqmask);
80104441:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80104448:	0f b7 c0             	movzwl %ax,%eax
8010444b:	89 04 24             	mov    %eax,(%esp)
8010444e:	e8 4a fe ff ff       	call   8010429d <picsetmask>
}
80104453:	c9                   	leave  
80104454:	c3                   	ret    

80104455 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104455:	55                   	push   %ebp
80104456:	89 e5                	mov    %esp,%ebp
80104458:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
8010445b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104462:	8b 45 0c             	mov    0xc(%ebp),%eax
80104465:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
8010446b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010446e:	8b 10                	mov    (%eax),%edx
80104470:	8b 45 08             	mov    0x8(%ebp),%eax
80104473:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104475:	e8 54 cf ff ff       	call   801013ce <filealloc>
8010447a:	8b 55 08             	mov    0x8(%ebp),%edx
8010447d:	89 02                	mov    %eax,(%edx)
8010447f:	8b 45 08             	mov    0x8(%ebp),%eax
80104482:	8b 00                	mov    (%eax),%eax
80104484:	85 c0                	test   %eax,%eax
80104486:	0f 84 c8 00 00 00    	je     80104554 <pipealloc+0xff>
8010448c:	e8 3d cf ff ff       	call   801013ce <filealloc>
80104491:	8b 55 0c             	mov    0xc(%ebp),%edx
80104494:	89 02                	mov    %eax,(%edx)
80104496:	8b 45 0c             	mov    0xc(%ebp),%eax
80104499:	8b 00                	mov    (%eax),%eax
8010449b:	85 c0                	test   %eax,%eax
8010449d:	0f 84 b1 00 00 00    	je     80104554 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
801044a3:	e8 7d eb ff ff       	call   80103025 <kalloc>
801044a8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801044ab:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801044af:	75 05                	jne    801044b6 <pipealloc+0x61>
    goto bad;
801044b1:	e9 9e 00 00 00       	jmp    80104554 <pipealloc+0xff>
  p->readopen = 1;
801044b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b9:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801044c0:	00 00 00 
  p->writeopen = 1;
801044c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c6:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801044cd:	00 00 00 
  p->nwrite = 0;
801044d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044d3:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801044da:	00 00 00 
  p->nread = 0;
801044dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044e0:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801044e7:	00 00 00 
  initlock(&p->lock, "pipe");
801044ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ed:	c7 44 24 04 40 8c 10 	movl   $0x80108c40,0x4(%esp)
801044f4:	80 
801044f5:	89 04 24             	mov    %eax,(%esp)
801044f8:	e8 13 0e 00 00       	call   80105310 <initlock>
  (*f0)->type = FD_PIPE;
801044fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104500:	8b 00                	mov    (%eax),%eax
80104502:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104508:	8b 45 08             	mov    0x8(%ebp),%eax
8010450b:	8b 00                	mov    (%eax),%eax
8010450d:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104511:	8b 45 08             	mov    0x8(%ebp),%eax
80104514:	8b 00                	mov    (%eax),%eax
80104516:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
8010451a:	8b 45 08             	mov    0x8(%ebp),%eax
8010451d:	8b 00                	mov    (%eax),%eax
8010451f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104522:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104525:	8b 45 0c             	mov    0xc(%ebp),%eax
80104528:	8b 00                	mov    (%eax),%eax
8010452a:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104530:	8b 45 0c             	mov    0xc(%ebp),%eax
80104533:	8b 00                	mov    (%eax),%eax
80104535:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104539:	8b 45 0c             	mov    0xc(%ebp),%eax
8010453c:	8b 00                	mov    (%eax),%eax
8010453e:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104542:	8b 45 0c             	mov    0xc(%ebp),%eax
80104545:	8b 00                	mov    (%eax),%eax
80104547:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010454a:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
8010454d:	b8 00 00 00 00       	mov    $0x0,%eax
80104552:	eb 42                	jmp    80104596 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80104554:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104558:	74 0b                	je     80104565 <pipealloc+0x110>
    kfree((char*)p);
8010455a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010455d:	89 04 24             	mov    %eax,(%esp)
80104560:	e8 27 ea ff ff       	call   80102f8c <kfree>
  if(*f0)
80104565:	8b 45 08             	mov    0x8(%ebp),%eax
80104568:	8b 00                	mov    (%eax),%eax
8010456a:	85 c0                	test   %eax,%eax
8010456c:	74 0d                	je     8010457b <pipealloc+0x126>
    fileclose(*f0);
8010456e:	8b 45 08             	mov    0x8(%ebp),%eax
80104571:	8b 00                	mov    (%eax),%eax
80104573:	89 04 24             	mov    %eax,(%esp)
80104576:	e8 fb ce ff ff       	call   80101476 <fileclose>
  if(*f1)
8010457b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010457e:	8b 00                	mov    (%eax),%eax
80104580:	85 c0                	test   %eax,%eax
80104582:	74 0d                	je     80104591 <pipealloc+0x13c>
    fileclose(*f1);
80104584:	8b 45 0c             	mov    0xc(%ebp),%eax
80104587:	8b 00                	mov    (%eax),%eax
80104589:	89 04 24             	mov    %eax,(%esp)
8010458c:	e8 e5 ce ff ff       	call   80101476 <fileclose>
  return -1;
80104591:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104596:	c9                   	leave  
80104597:	c3                   	ret    

80104598 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104598:	55                   	push   %ebp
80104599:	89 e5                	mov    %esp,%ebp
8010459b:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
8010459e:	8b 45 08             	mov    0x8(%ebp),%eax
801045a1:	89 04 24             	mov    %eax,(%esp)
801045a4:	e8 88 0d 00 00       	call   80105331 <acquire>
  if(writable){
801045a9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801045ad:	74 1f                	je     801045ce <pipeclose+0x36>
    p->writeopen = 0;
801045af:	8b 45 08             	mov    0x8(%ebp),%eax
801045b2:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801045b9:	00 00 00 
    wakeup(&p->nread);
801045bc:	8b 45 08             	mov    0x8(%ebp),%eax
801045bf:	05 34 02 00 00       	add    $0x234,%eax
801045c4:	89 04 24             	mov    %eax,(%esp)
801045c7:	e8 74 0b 00 00       	call   80105140 <wakeup>
801045cc:	eb 1d                	jmp    801045eb <pipeclose+0x53>
  } else {
    p->readopen = 0;
801045ce:	8b 45 08             	mov    0x8(%ebp),%eax
801045d1:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801045d8:	00 00 00 
    wakeup(&p->nwrite);
801045db:	8b 45 08             	mov    0x8(%ebp),%eax
801045de:	05 38 02 00 00       	add    $0x238,%eax
801045e3:	89 04 24             	mov    %eax,(%esp)
801045e6:	e8 55 0b 00 00       	call   80105140 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801045eb:	8b 45 08             	mov    0x8(%ebp),%eax
801045ee:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801045f4:	85 c0                	test   %eax,%eax
801045f6:	75 25                	jne    8010461d <pipeclose+0x85>
801045f8:	8b 45 08             	mov    0x8(%ebp),%eax
801045fb:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104601:	85 c0                	test   %eax,%eax
80104603:	75 18                	jne    8010461d <pipeclose+0x85>
    release(&p->lock);
80104605:	8b 45 08             	mov    0x8(%ebp),%eax
80104608:	89 04 24             	mov    %eax,(%esp)
8010460b:	e8 83 0d 00 00       	call   80105393 <release>
    kfree((char*)p);
80104610:	8b 45 08             	mov    0x8(%ebp),%eax
80104613:	89 04 24             	mov    %eax,(%esp)
80104616:	e8 71 e9 ff ff       	call   80102f8c <kfree>
8010461b:	eb 0b                	jmp    80104628 <pipeclose+0x90>
  } else
    release(&p->lock);
8010461d:	8b 45 08             	mov    0x8(%ebp),%eax
80104620:	89 04 24             	mov    %eax,(%esp)
80104623:	e8 6b 0d 00 00       	call   80105393 <release>
}
80104628:	c9                   	leave  
80104629:	c3                   	ret    

8010462a <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010462a:	55                   	push   %ebp
8010462b:	89 e5                	mov    %esp,%ebp
8010462d:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104630:	8b 45 08             	mov    0x8(%ebp),%eax
80104633:	89 04 24             	mov    %eax,(%esp)
80104636:	e8 f6 0c 00 00       	call   80105331 <acquire>
  for(i = 0; i < n; i++){
8010463b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104642:	e9 a6 00 00 00       	jmp    801046ed <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104647:	eb 57                	jmp    801046a0 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
80104649:	8b 45 08             	mov    0x8(%ebp),%eax
8010464c:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104652:	85 c0                	test   %eax,%eax
80104654:	74 0d                	je     80104663 <pipewrite+0x39>
80104656:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010465c:	8b 40 24             	mov    0x24(%eax),%eax
8010465f:	85 c0                	test   %eax,%eax
80104661:	74 15                	je     80104678 <pipewrite+0x4e>
        release(&p->lock);
80104663:	8b 45 08             	mov    0x8(%ebp),%eax
80104666:	89 04 24             	mov    %eax,(%esp)
80104669:	e8 25 0d 00 00       	call   80105393 <release>
        return -1;
8010466e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104673:	e9 9f 00 00 00       	jmp    80104717 <pipewrite+0xed>
      }
      wakeup(&p->nread);
80104678:	8b 45 08             	mov    0x8(%ebp),%eax
8010467b:	05 34 02 00 00       	add    $0x234,%eax
80104680:	89 04 24             	mov    %eax,(%esp)
80104683:	e8 b8 0a 00 00       	call   80105140 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104688:	8b 45 08             	mov    0x8(%ebp),%eax
8010468b:	8b 55 08             	mov    0x8(%ebp),%edx
8010468e:	81 c2 38 02 00 00    	add    $0x238,%edx
80104694:	89 44 24 04          	mov    %eax,0x4(%esp)
80104698:	89 14 24             	mov    %edx,(%esp)
8010469b:	e8 c7 09 00 00       	call   80105067 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801046a0:	8b 45 08             	mov    0x8(%ebp),%eax
801046a3:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801046a9:	8b 45 08             	mov    0x8(%ebp),%eax
801046ac:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801046b2:	05 00 02 00 00       	add    $0x200,%eax
801046b7:	39 c2                	cmp    %eax,%edx
801046b9:	74 8e                	je     80104649 <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801046bb:	8b 45 08             	mov    0x8(%ebp),%eax
801046be:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801046c4:	8d 48 01             	lea    0x1(%eax),%ecx
801046c7:	8b 55 08             	mov    0x8(%ebp),%edx
801046ca:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
801046d0:	25 ff 01 00 00       	and    $0x1ff,%eax
801046d5:	89 c1                	mov    %eax,%ecx
801046d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046da:	8b 45 0c             	mov    0xc(%ebp),%eax
801046dd:	01 d0                	add    %edx,%eax
801046df:	0f b6 10             	movzbl (%eax),%edx
801046e2:	8b 45 08             	mov    0x8(%ebp),%eax
801046e5:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801046e9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801046ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046f0:	3b 45 10             	cmp    0x10(%ebp),%eax
801046f3:	0f 8c 4e ff ff ff    	jl     80104647 <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801046f9:	8b 45 08             	mov    0x8(%ebp),%eax
801046fc:	05 34 02 00 00       	add    $0x234,%eax
80104701:	89 04 24             	mov    %eax,(%esp)
80104704:	e8 37 0a 00 00       	call   80105140 <wakeup>
  release(&p->lock);
80104709:	8b 45 08             	mov    0x8(%ebp),%eax
8010470c:	89 04 24             	mov    %eax,(%esp)
8010470f:	e8 7f 0c 00 00       	call   80105393 <release>
  return n;
80104714:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104717:	c9                   	leave  
80104718:	c3                   	ret    

80104719 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104719:	55                   	push   %ebp
8010471a:	89 e5                	mov    %esp,%ebp
8010471c:	53                   	push   %ebx
8010471d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104720:	8b 45 08             	mov    0x8(%ebp),%eax
80104723:	89 04 24             	mov    %eax,(%esp)
80104726:	e8 06 0c 00 00       	call   80105331 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010472b:	eb 3a                	jmp    80104767 <piperead+0x4e>
    if(proc->killed){
8010472d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104733:	8b 40 24             	mov    0x24(%eax),%eax
80104736:	85 c0                	test   %eax,%eax
80104738:	74 15                	je     8010474f <piperead+0x36>
      release(&p->lock);
8010473a:	8b 45 08             	mov    0x8(%ebp),%eax
8010473d:	89 04 24             	mov    %eax,(%esp)
80104740:	e8 4e 0c 00 00       	call   80105393 <release>
      return -1;
80104745:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010474a:	e9 b5 00 00 00       	jmp    80104804 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010474f:	8b 45 08             	mov    0x8(%ebp),%eax
80104752:	8b 55 08             	mov    0x8(%ebp),%edx
80104755:	81 c2 34 02 00 00    	add    $0x234,%edx
8010475b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010475f:	89 14 24             	mov    %edx,(%esp)
80104762:	e8 00 09 00 00       	call   80105067 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104767:	8b 45 08             	mov    0x8(%ebp),%eax
8010476a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104770:	8b 45 08             	mov    0x8(%ebp),%eax
80104773:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104779:	39 c2                	cmp    %eax,%edx
8010477b:	75 0d                	jne    8010478a <piperead+0x71>
8010477d:	8b 45 08             	mov    0x8(%ebp),%eax
80104780:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104786:	85 c0                	test   %eax,%eax
80104788:	75 a3                	jne    8010472d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010478a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104791:	eb 4b                	jmp    801047de <piperead+0xc5>
    if(p->nread == p->nwrite)
80104793:	8b 45 08             	mov    0x8(%ebp),%eax
80104796:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010479c:	8b 45 08             	mov    0x8(%ebp),%eax
8010479f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801047a5:	39 c2                	cmp    %eax,%edx
801047a7:	75 02                	jne    801047ab <piperead+0x92>
      break;
801047a9:	eb 3b                	jmp    801047e6 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
801047ab:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047ae:	8b 45 0c             	mov    0xc(%ebp),%eax
801047b1:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801047b4:	8b 45 08             	mov    0x8(%ebp),%eax
801047b7:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801047bd:	8d 48 01             	lea    0x1(%eax),%ecx
801047c0:	8b 55 08             	mov    0x8(%ebp),%edx
801047c3:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
801047c9:	25 ff 01 00 00       	and    $0x1ff,%eax
801047ce:	89 c2                	mov    %eax,%edx
801047d0:	8b 45 08             	mov    0x8(%ebp),%eax
801047d3:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
801047d8:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801047da:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801047de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047e1:	3b 45 10             	cmp    0x10(%ebp),%eax
801047e4:	7c ad                	jl     80104793 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801047e6:	8b 45 08             	mov    0x8(%ebp),%eax
801047e9:	05 38 02 00 00       	add    $0x238,%eax
801047ee:	89 04 24             	mov    %eax,(%esp)
801047f1:	e8 4a 09 00 00       	call   80105140 <wakeup>
  release(&p->lock);
801047f6:	8b 45 08             	mov    0x8(%ebp),%eax
801047f9:	89 04 24             	mov    %eax,(%esp)
801047fc:	e8 92 0b 00 00       	call   80105393 <release>
  return i;
80104801:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104804:	83 c4 24             	add    $0x24,%esp
80104807:	5b                   	pop    %ebx
80104808:	5d                   	pop    %ebp
80104809:	c3                   	ret    

8010480a <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010480a:	55                   	push   %ebp
8010480b:	89 e5                	mov    %esp,%ebp
8010480d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104810:	9c                   	pushf  
80104811:	58                   	pop    %eax
80104812:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104815:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104818:	c9                   	leave  
80104819:	c3                   	ret    

8010481a <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010481a:	55                   	push   %ebp
8010481b:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010481d:	fb                   	sti    
}
8010481e:	5d                   	pop    %ebp
8010481f:	c3                   	ret    

80104820 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104820:	55                   	push   %ebp
80104821:	89 e5                	mov    %esp,%ebp
80104823:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104826:	c7 44 24 04 45 8c 10 	movl   $0x80108c45,0x4(%esp)
8010482d:	80 
8010482e:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104835:	e8 d6 0a 00 00       	call   80105310 <initlock>
}
8010483a:	c9                   	leave  
8010483b:	c3                   	ret    

8010483c <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010483c:	55                   	push   %ebp
8010483d:	89 e5                	mov    %esp,%ebp
8010483f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104842:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104849:	e8 e3 0a 00 00       	call   80105331 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010484e:	c7 45 f4 f4 31 11 80 	movl   $0x801131f4,-0xc(%ebp)
80104855:	eb 50                	jmp    801048a7 <allocproc+0x6b>
    if(p->state == UNUSED)
80104857:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010485a:	8b 40 0c             	mov    0xc(%eax),%eax
8010485d:	85 c0                	test   %eax,%eax
8010485f:	75 42                	jne    801048a3 <allocproc+0x67>
      goto found;
80104861:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104862:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104865:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010486c:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104871:	8d 50 01             	lea    0x1(%eax),%edx
80104874:	89 15 04 b0 10 80    	mov    %edx,0x8010b004
8010487a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010487d:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
80104880:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104887:	e8 07 0b 00 00       	call   80105393 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
8010488c:	e8 94 e7 ff ff       	call   80103025 <kalloc>
80104891:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104894:	89 42 08             	mov    %eax,0x8(%edx)
80104897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010489a:	8b 40 08             	mov    0x8(%eax),%eax
8010489d:	85 c0                	test   %eax,%eax
8010489f:	75 33                	jne    801048d4 <allocproc+0x98>
801048a1:	eb 20                	jmp    801048c3 <allocproc+0x87>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801048a3:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801048a7:	81 7d f4 f4 50 11 80 	cmpl   $0x801150f4,-0xc(%ebp)
801048ae:	72 a7                	jb     80104857 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801048b0:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
801048b7:	e8 d7 0a 00 00       	call   80105393 <release>
  return 0;
801048bc:	b8 00 00 00 00       	mov    $0x0,%eax
801048c1:	eb 76                	jmp    80104939 <allocproc+0xfd>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801048c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048c6:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801048cd:	b8 00 00 00 00       	mov    $0x0,%eax
801048d2:	eb 65                	jmp    80104939 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
801048d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048d7:	8b 40 08             	mov    0x8(%eax),%eax
801048da:	05 00 10 00 00       	add    $0x1000,%eax
801048df:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801048e2:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801048e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048e9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048ec:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801048ef:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801048f3:	ba 99 69 10 80       	mov    $0x80106999,%edx
801048f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048fb:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801048fd:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104901:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104904:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104907:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010490a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010490d:	8b 40 1c             	mov    0x1c(%eax),%eax
80104910:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104917:	00 
80104918:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010491f:	00 
80104920:	89 04 24             	mov    %eax,(%esp)
80104923:	e8 5d 0c 00 00       	call   80105585 <memset>
  p->context->eip = (uint)forkret;
80104928:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010492b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010492e:	ba 28 50 10 80       	mov    $0x80105028,%edx
80104933:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104936:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104939:	c9                   	leave  
8010493a:	c3                   	ret    

8010493b <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010493b:	55                   	push   %ebp
8010493c:	89 e5                	mov    %esp,%ebp
8010493e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104941:	e8 f6 fe ff ff       	call   8010483c <allocproc>
80104946:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104949:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010494c:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
80104951:	e8 37 37 00 00       	call   8010808d <setupkvm>
80104956:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104959:	89 42 04             	mov    %eax,0x4(%edx)
8010495c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010495f:	8b 40 04             	mov    0x4(%eax),%eax
80104962:	85 c0                	test   %eax,%eax
80104964:	75 0c                	jne    80104972 <userinit+0x37>
    panic("userinit: out of memory?");
80104966:	c7 04 24 4c 8c 10 80 	movl   $0x80108c4c,(%esp)
8010496d:	e8 c8 bb ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104972:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104977:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010497a:	8b 40 04             	mov    0x4(%eax),%eax
8010497d:	89 54 24 08          	mov    %edx,0x8(%esp)
80104981:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
80104988:	80 
80104989:	89 04 24             	mov    %eax,(%esp)
8010498c:	e8 54 39 00 00       	call   801082e5 <inituvm>
  p->sz = PGSIZE;
80104991:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104994:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
8010499a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010499d:	8b 40 18             	mov    0x18(%eax),%eax
801049a0:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801049a7:	00 
801049a8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801049af:	00 
801049b0:	89 04 24             	mov    %eax,(%esp)
801049b3:	e8 cd 0b 00 00       	call   80105585 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801049b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049bb:	8b 40 18             	mov    0x18(%eax),%eax
801049be:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801049c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049c7:	8b 40 18             	mov    0x18(%eax),%eax
801049ca:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801049d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049d3:	8b 40 18             	mov    0x18(%eax),%eax
801049d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049d9:	8b 52 18             	mov    0x18(%edx),%edx
801049dc:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801049e0:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801049e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e7:	8b 40 18             	mov    0x18(%eax),%eax
801049ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049ed:	8b 52 18             	mov    0x18(%edx),%edx
801049f0:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801049f4:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801049f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049fb:	8b 40 18             	mov    0x18(%eax),%eax
801049fe:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a08:	8b 40 18             	mov    0x18(%eax),%eax
80104a0b:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104a12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a15:	8b 40 18             	mov    0x18(%eax),%eax
80104a18:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104a1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a22:	83 c0 6c             	add    $0x6c,%eax
80104a25:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104a2c:	00 
80104a2d:	c7 44 24 04 65 8c 10 	movl   $0x80108c65,0x4(%esp)
80104a34:	80 
80104a35:	89 04 24             	mov    %eax,(%esp)
80104a38:	e8 68 0d 00 00       	call   801057a5 <safestrcpy>
  p->cwd = namei("/");
80104a3d:	c7 04 24 6e 8c 10 80 	movl   $0x80108c6e,(%esp)
80104a44:	e8 c9 de ff ff       	call   80102912 <namei>
80104a49:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a4c:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a52:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104a59:	c9                   	leave  
80104a5a:	c3                   	ret    

80104a5b <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104a5b:	55                   	push   %ebp
80104a5c:	89 e5                	mov    %esp,%ebp
80104a5e:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104a61:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a67:	8b 00                	mov    (%eax),%eax
80104a69:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104a6c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104a70:	7e 34                	jle    80104aa6 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104a72:	8b 55 08             	mov    0x8(%ebp),%edx
80104a75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a78:	01 c2                	add    %eax,%edx
80104a7a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a80:	8b 40 04             	mov    0x4(%eax),%eax
80104a83:	89 54 24 08          	mov    %edx,0x8(%esp)
80104a87:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a8a:	89 54 24 04          	mov    %edx,0x4(%esp)
80104a8e:	89 04 24             	mov    %eax,(%esp)
80104a91:	e8 c5 39 00 00       	call   8010845b <allocuvm>
80104a96:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104a99:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104a9d:	75 41                	jne    80104ae0 <growproc+0x85>
      return -1;
80104a9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104aa4:	eb 58                	jmp    80104afe <growproc+0xa3>
  } else if(n < 0){
80104aa6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104aaa:	79 34                	jns    80104ae0 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104aac:	8b 55 08             	mov    0x8(%ebp),%edx
80104aaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab2:	01 c2                	add    %eax,%edx
80104ab4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104aba:	8b 40 04             	mov    0x4(%eax),%eax
80104abd:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ac1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ac4:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ac8:	89 04 24             	mov    %eax,(%esp)
80104acb:	e8 65 3a 00 00       	call   80108535 <deallocuvm>
80104ad0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104ad3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104ad7:	75 07                	jne    80104ae0 <growproc+0x85>
      return -1;
80104ad9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ade:	eb 1e                	jmp    80104afe <growproc+0xa3>
  }
  proc->sz = sz;
80104ae0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ae6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ae9:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104aeb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104af1:	89 04 24             	mov    %eax,(%esp)
80104af4:	e8 85 36 00 00       	call   8010817e <switchuvm>
  return 0;
80104af9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104afe:	c9                   	leave  
80104aff:	c3                   	ret    

80104b00 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104b00:	55                   	push   %ebp
80104b01:	89 e5                	mov    %esp,%ebp
80104b03:	57                   	push   %edi
80104b04:	56                   	push   %esi
80104b05:	53                   	push   %ebx
80104b06:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104b09:	e8 2e fd ff ff       	call   8010483c <allocproc>
80104b0e:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104b11:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104b15:	75 0a                	jne    80104b21 <fork+0x21>
    return -1;
80104b17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b1c:	e9 52 01 00 00       	jmp    80104c73 <fork+0x173>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104b21:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b27:	8b 10                	mov    (%eax),%edx
80104b29:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b2f:	8b 40 04             	mov    0x4(%eax),%eax
80104b32:	89 54 24 04          	mov    %edx,0x4(%esp)
80104b36:	89 04 24             	mov    %eax,(%esp)
80104b39:	e8 93 3b 00 00       	call   801086d1 <copyuvm>
80104b3e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104b41:	89 42 04             	mov    %eax,0x4(%edx)
80104b44:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b47:	8b 40 04             	mov    0x4(%eax),%eax
80104b4a:	85 c0                	test   %eax,%eax
80104b4c:	75 2c                	jne    80104b7a <fork+0x7a>
    kfree(np->kstack);
80104b4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b51:	8b 40 08             	mov    0x8(%eax),%eax
80104b54:	89 04 24             	mov    %eax,(%esp)
80104b57:	e8 30 e4 ff ff       	call   80102f8c <kfree>
    np->kstack = 0;
80104b5c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b5f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104b66:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b69:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104b70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b75:	e9 f9 00 00 00       	jmp    80104c73 <fork+0x173>
  }
  np->sz = proc->sz;
80104b7a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b80:	8b 10                	mov    (%eax),%edx
80104b82:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b85:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104b87:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b91:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104b94:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b97:	8b 50 18             	mov    0x18(%eax),%edx
80104b9a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ba0:	8b 40 18             	mov    0x18(%eax),%eax
80104ba3:	89 c3                	mov    %eax,%ebx
80104ba5:	b8 13 00 00 00       	mov    $0x13,%eax
80104baa:	89 d7                	mov    %edx,%edi
80104bac:	89 de                	mov    %ebx,%esi
80104bae:	89 c1                	mov    %eax,%ecx
80104bb0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104bb2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104bb5:	8b 40 18             	mov    0x18(%eax),%eax
80104bb8:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104bbf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104bc6:	eb 3d                	jmp    80104c05 <fork+0x105>
    if(proc->ofile[i])
80104bc8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bce:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104bd1:	83 c2 08             	add    $0x8,%edx
80104bd4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104bd8:	85 c0                	test   %eax,%eax
80104bda:	74 25                	je     80104c01 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104bdc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104be2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104be5:	83 c2 08             	add    $0x8,%edx
80104be8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104bec:	89 04 24             	mov    %eax,(%esp)
80104bef:	e8 3a c8 ff ff       	call   8010142e <filedup>
80104bf4:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104bf7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104bfa:	83 c1 08             	add    $0x8,%ecx
80104bfd:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104c01:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104c05:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104c09:	7e bd                	jle    80104bc8 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104c0b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c11:	8b 40 68             	mov    0x68(%eax),%eax
80104c14:	89 04 24             	mov    %eax,(%esp)
80104c17:	e8 13 d1 ff ff       	call   80101d2f <idup>
80104c1c:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104c1f:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104c22:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c28:	8d 50 6c             	lea    0x6c(%eax),%edx
80104c2b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c2e:	83 c0 6c             	add    $0x6c,%eax
80104c31:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104c38:	00 
80104c39:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c3d:	89 04 24             	mov    %eax,(%esp)
80104c40:	e8 60 0b 00 00       	call   801057a5 <safestrcpy>
 
  pid = np->pid;
80104c45:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c48:	8b 40 10             	mov    0x10(%eax),%eax
80104c4b:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
80104c4e:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104c55:	e8 d7 06 00 00       	call   80105331 <acquire>
  np->state = RUNNABLE;
80104c5a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c5d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
80104c64:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104c6b:	e8 23 07 00 00       	call   80105393 <release>
  
  return pid;
80104c70:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104c73:	83 c4 2c             	add    $0x2c,%esp
80104c76:	5b                   	pop    %ebx
80104c77:	5e                   	pop    %esi
80104c78:	5f                   	pop    %edi
80104c79:	5d                   	pop    %ebp
80104c7a:	c3                   	ret    

80104c7b <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104c7b:	55                   	push   %ebp
80104c7c:	89 e5                	mov    %esp,%ebp
80104c7e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104c81:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104c88:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104c8d:	39 c2                	cmp    %eax,%edx
80104c8f:	75 0c                	jne    80104c9d <exit+0x22>
    panic("init exiting");
80104c91:	c7 04 24 70 8c 10 80 	movl   $0x80108c70,(%esp)
80104c98:	e8 9d b8 ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104c9d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104ca4:	eb 44                	jmp    80104cea <exit+0x6f>
    if(proc->ofile[fd]){
80104ca6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cac:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104caf:	83 c2 08             	add    $0x8,%edx
80104cb2:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104cb6:	85 c0                	test   %eax,%eax
80104cb8:	74 2c                	je     80104ce6 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104cba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cc0:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cc3:	83 c2 08             	add    $0x8,%edx
80104cc6:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104cca:	89 04 24             	mov    %eax,(%esp)
80104ccd:	e8 a4 c7 ff ff       	call   80101476 <fileclose>
      proc->ofile[fd] = 0;
80104cd2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cd8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cdb:	83 c2 08             	add    $0x8,%edx
80104cde:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104ce5:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104ce6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104cea:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104cee:	7e b6                	jle    80104ca6 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
80104cf0:	e8 54 ec ff ff       	call   80103949 <begin_op>
  iput(proc->cwd);
80104cf5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cfb:	8b 40 68             	mov    0x68(%eax),%eax
80104cfe:	89 04 24             	mov    %eax,(%esp)
80104d01:	e8 14 d2 ff ff       	call   80101f1a <iput>
  end_op();
80104d06:	e8 c2 ec ff ff       	call   801039cd <end_op>
  proc->cwd = 0;
80104d0b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d11:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104d18:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104d1f:	e8 0d 06 00 00       	call   80105331 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104d24:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d2a:	8b 40 14             	mov    0x14(%eax),%eax
80104d2d:	89 04 24             	mov    %eax,(%esp)
80104d30:	e8 cd 03 00 00       	call   80105102 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d35:	c7 45 f4 f4 31 11 80 	movl   $0x801131f4,-0xc(%ebp)
80104d3c:	eb 38                	jmp    80104d76 <exit+0xfb>
    if(p->parent == proc){
80104d3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d41:	8b 50 14             	mov    0x14(%eax),%edx
80104d44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d4a:	39 c2                	cmp    %eax,%edx
80104d4c:	75 24                	jne    80104d72 <exit+0xf7>
      p->parent = initproc;
80104d4e:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104d54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d57:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104d5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d5d:	8b 40 0c             	mov    0xc(%eax),%eax
80104d60:	83 f8 05             	cmp    $0x5,%eax
80104d63:	75 0d                	jne    80104d72 <exit+0xf7>
        wakeup1(initproc);
80104d65:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104d6a:	89 04 24             	mov    %eax,(%esp)
80104d6d:	e8 90 03 00 00       	call   80105102 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d72:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104d76:	81 7d f4 f4 50 11 80 	cmpl   $0x801150f4,-0xc(%ebp)
80104d7d:	72 bf                	jb     80104d3e <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104d7f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d85:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104d8c:	e8 b3 01 00 00       	call   80104f44 <sched>
  panic("zombie exit");
80104d91:	c7 04 24 7d 8c 10 80 	movl   $0x80108c7d,(%esp)
80104d98:	e8 9d b7 ff ff       	call   8010053a <panic>

80104d9d <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104d9d:	55                   	push   %ebp
80104d9e:	89 e5                	mov    %esp,%ebp
80104da0:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104da3:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104daa:	e8 82 05 00 00       	call   80105331 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104daf:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104db6:	c7 45 f4 f4 31 11 80 	movl   $0x801131f4,-0xc(%ebp)
80104dbd:	e9 9a 00 00 00       	jmp    80104e5c <wait+0xbf>
      if(p->parent != proc)
80104dc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dc5:	8b 50 14             	mov    0x14(%eax),%edx
80104dc8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dce:	39 c2                	cmp    %eax,%edx
80104dd0:	74 05                	je     80104dd7 <wait+0x3a>
        continue;
80104dd2:	e9 81 00 00 00       	jmp    80104e58 <wait+0xbb>
      havekids = 1;
80104dd7:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104dde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104de1:	8b 40 0c             	mov    0xc(%eax),%eax
80104de4:	83 f8 05             	cmp    $0x5,%eax
80104de7:	75 6f                	jne    80104e58 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104de9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dec:	8b 40 10             	mov    0x10(%eax),%eax
80104def:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104df2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104df5:	8b 40 08             	mov    0x8(%eax),%eax
80104df8:	89 04 24             	mov    %eax,(%esp)
80104dfb:	e8 8c e1 ff ff       	call   80102f8c <kfree>
        p->kstack = 0;
80104e00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e03:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104e0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e0d:	8b 40 04             	mov    0x4(%eax),%eax
80104e10:	89 04 24             	mov    %eax,(%esp)
80104e13:	e8 d9 37 00 00       	call   801085f1 <freevm>
        p->state = UNUSED;
80104e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e1b:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104e22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e25:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e2f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104e36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e39:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104e3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e40:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104e47:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104e4e:	e8 40 05 00 00       	call   80105393 <release>
        return pid;
80104e53:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104e56:	eb 52                	jmp    80104eaa <wait+0x10d>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e58:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104e5c:	81 7d f4 f4 50 11 80 	cmpl   $0x801150f4,-0xc(%ebp)
80104e63:	0f 82 59 ff ff ff    	jb     80104dc2 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104e69:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104e6d:	74 0d                	je     80104e7c <wait+0xdf>
80104e6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e75:	8b 40 24             	mov    0x24(%eax),%eax
80104e78:	85 c0                	test   %eax,%eax
80104e7a:	74 13                	je     80104e8f <wait+0xf2>
      release(&ptable.lock);
80104e7c:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104e83:	e8 0b 05 00 00       	call   80105393 <release>
      return -1;
80104e88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e8d:	eb 1b                	jmp    80104eaa <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104e8f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e95:	c7 44 24 04 c0 31 11 	movl   $0x801131c0,0x4(%esp)
80104e9c:	80 
80104e9d:	89 04 24             	mov    %eax,(%esp)
80104ea0:	e8 c2 01 00 00       	call   80105067 <sleep>
  }
80104ea5:	e9 05 ff ff ff       	jmp    80104daf <wait+0x12>
}
80104eaa:	c9                   	leave  
80104eab:	c3                   	ret    

80104eac <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104eac:	55                   	push   %ebp
80104ead:	89 e5                	mov    %esp,%ebp
80104eaf:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104eb2:	e8 63 f9 ff ff       	call   8010481a <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104eb7:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104ebe:	e8 6e 04 00 00       	call   80105331 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ec3:	c7 45 f4 f4 31 11 80 	movl   $0x801131f4,-0xc(%ebp)
80104eca:	eb 5e                	jmp    80104f2a <scheduler+0x7e>
      if(p->state != RUNNABLE)
80104ecc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ecf:	8b 40 0c             	mov    0xc(%eax),%eax
80104ed2:	83 f8 03             	cmp    $0x3,%eax
80104ed5:	74 02                	je     80104ed9 <scheduler+0x2d>
        continue;
80104ed7:	eb 4d                	jmp    80104f26 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104ed9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104edc:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104ee2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ee5:	89 04 24             	mov    %eax,(%esp)
80104ee8:	e8 91 32 00 00       	call   8010817e <switchuvm>
      p->state = RUNNING;
80104eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ef0:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104ef7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104efd:	8b 40 1c             	mov    0x1c(%eax),%eax
80104f00:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104f07:	83 c2 04             	add    $0x4,%edx
80104f0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f0e:	89 14 24             	mov    %edx,(%esp)
80104f11:	e8 00 09 00 00       	call   80105816 <swtch>
      switchkvm();
80104f16:	e8 46 32 00 00       	call   80108161 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104f1b:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104f22:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f26:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104f2a:	81 7d f4 f4 50 11 80 	cmpl   $0x801150f4,-0xc(%ebp)
80104f31:	72 99                	jb     80104ecc <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104f33:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104f3a:	e8 54 04 00 00       	call   80105393 <release>

  }
80104f3f:	e9 6e ff ff ff       	jmp    80104eb2 <scheduler+0x6>

80104f44 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104f44:	55                   	push   %ebp
80104f45:	89 e5                	mov    %esp,%ebp
80104f47:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104f4a:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80104f51:	e8 05 05 00 00       	call   8010545b <holding>
80104f56:	85 c0                	test   %eax,%eax
80104f58:	75 0c                	jne    80104f66 <sched+0x22>
    panic("sched ptable.lock");
80104f5a:	c7 04 24 89 8c 10 80 	movl   $0x80108c89,(%esp)
80104f61:	e8 d4 b5 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104f66:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104f6c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104f72:	83 f8 01             	cmp    $0x1,%eax
80104f75:	74 0c                	je     80104f83 <sched+0x3f>
    panic("sched locks");
80104f77:	c7 04 24 9b 8c 10 80 	movl   $0x80108c9b,(%esp)
80104f7e:	e8 b7 b5 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104f83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f89:	8b 40 0c             	mov    0xc(%eax),%eax
80104f8c:	83 f8 04             	cmp    $0x4,%eax
80104f8f:	75 0c                	jne    80104f9d <sched+0x59>
    panic("sched running");
80104f91:	c7 04 24 a7 8c 10 80 	movl   $0x80108ca7,(%esp)
80104f98:	e8 9d b5 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104f9d:	e8 68 f8 ff ff       	call   8010480a <readeflags>
80104fa2:	25 00 02 00 00       	and    $0x200,%eax
80104fa7:	85 c0                	test   %eax,%eax
80104fa9:	74 0c                	je     80104fb7 <sched+0x73>
    panic("sched interruptible");
80104fab:	c7 04 24 b5 8c 10 80 	movl   $0x80108cb5,(%esp)
80104fb2:	e8 83 b5 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104fb7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104fbd:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104fc3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104fc6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104fcc:	8b 40 04             	mov    0x4(%eax),%eax
80104fcf:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104fd6:	83 c2 1c             	add    $0x1c,%edx
80104fd9:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fdd:	89 14 24             	mov    %edx,(%esp)
80104fe0:	e8 31 08 00 00       	call   80105816 <swtch>
  cpu->intena = intena;
80104fe5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104feb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104fee:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104ff4:	c9                   	leave  
80104ff5:	c3                   	ret    

80104ff6 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104ff6:	55                   	push   %ebp
80104ff7:	89 e5                	mov    %esp,%ebp
80104ff9:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104ffc:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80105003:	e8 29 03 00 00       	call   80105331 <acquire>
  proc->state = RUNNABLE;
80105008:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010500e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105015:	e8 2a ff ff ff       	call   80104f44 <sched>
  release(&ptable.lock);
8010501a:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80105021:	e8 6d 03 00 00       	call   80105393 <release>
}
80105026:	c9                   	leave  
80105027:	c3                   	ret    

80105028 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105028:	55                   	push   %ebp
80105029:	89 e5                	mov    %esp,%ebp
8010502b:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
8010502e:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80105035:	e8 59 03 00 00       	call   80105393 <release>

  if (first) {
8010503a:	a1 08 b0 10 80       	mov    0x8010b008,%eax
8010503f:	85 c0                	test   %eax,%eax
80105041:	74 22                	je     80105065 <forkret+0x3d>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105043:	c7 05 08 b0 10 80 00 	movl   $0x0,0x8010b008
8010504a:	00 00 00 
    iinit(ROOTDEV);
8010504d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105054:	e8 e0 c9 ff ff       	call   80101a39 <iinit>
    initlog(ROOTDEV);
80105059:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105060:	e8 e0 e6 ff ff       	call   80103745 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105065:	c9                   	leave  
80105066:	c3                   	ret    

80105067 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105067:	55                   	push   %ebp
80105068:	89 e5                	mov    %esp,%ebp
8010506a:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010506d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105073:	85 c0                	test   %eax,%eax
80105075:	75 0c                	jne    80105083 <sleep+0x1c>
    panic("sleep");
80105077:	c7 04 24 c9 8c 10 80 	movl   $0x80108cc9,(%esp)
8010507e:	e8 b7 b4 ff ff       	call   8010053a <panic>

  if(lk == 0)
80105083:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105087:	75 0c                	jne    80105095 <sleep+0x2e>
    panic("sleep without lk");
80105089:	c7 04 24 cf 8c 10 80 	movl   $0x80108ccf,(%esp)
80105090:	e8 a5 b4 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105095:	81 7d 0c c0 31 11 80 	cmpl   $0x801131c0,0xc(%ebp)
8010509c:	74 17                	je     801050b5 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010509e:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
801050a5:	e8 87 02 00 00       	call   80105331 <acquire>
    release(lk);
801050aa:	8b 45 0c             	mov    0xc(%ebp),%eax
801050ad:	89 04 24             	mov    %eax,(%esp)
801050b0:	e8 de 02 00 00       	call   80105393 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801050b5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050bb:	8b 55 08             	mov    0x8(%ebp),%edx
801050be:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801050c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050c7:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801050ce:	e8 71 fe ff ff       	call   80104f44 <sched>

  // Tidy up.
  proc->chan = 0;
801050d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050d9:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801050e0:	81 7d 0c c0 31 11 80 	cmpl   $0x801131c0,0xc(%ebp)
801050e7:	74 17                	je     80105100 <sleep+0x99>
    release(&ptable.lock);
801050e9:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
801050f0:	e8 9e 02 00 00       	call   80105393 <release>
    acquire(lk);
801050f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801050f8:	89 04 24             	mov    %eax,(%esp)
801050fb:	e8 31 02 00 00       	call   80105331 <acquire>
  }
}
80105100:	c9                   	leave  
80105101:	c3                   	ret    

80105102 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105102:	55                   	push   %ebp
80105103:	89 e5                	mov    %esp,%ebp
80105105:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105108:	c7 45 fc f4 31 11 80 	movl   $0x801131f4,-0x4(%ebp)
8010510f:	eb 24                	jmp    80105135 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105111:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105114:	8b 40 0c             	mov    0xc(%eax),%eax
80105117:	83 f8 02             	cmp    $0x2,%eax
8010511a:	75 15                	jne    80105131 <wakeup1+0x2f>
8010511c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010511f:	8b 40 20             	mov    0x20(%eax),%eax
80105122:	3b 45 08             	cmp    0x8(%ebp),%eax
80105125:	75 0a                	jne    80105131 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105127:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010512a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105131:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80105135:	81 7d fc f4 50 11 80 	cmpl   $0x801150f4,-0x4(%ebp)
8010513c:	72 d3                	jb     80105111 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
8010513e:	c9                   	leave  
8010513f:	c3                   	ret    

80105140 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105140:	55                   	push   %ebp
80105141:	89 e5                	mov    %esp,%ebp
80105143:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105146:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
8010514d:	e8 df 01 00 00       	call   80105331 <acquire>
  wakeup1(chan);
80105152:	8b 45 08             	mov    0x8(%ebp),%eax
80105155:	89 04 24             	mov    %eax,(%esp)
80105158:	e8 a5 ff ff ff       	call   80105102 <wakeup1>
  release(&ptable.lock);
8010515d:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80105164:	e8 2a 02 00 00       	call   80105393 <release>
}
80105169:	c9                   	leave  
8010516a:	c3                   	ret    

8010516b <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
8010516b:	55                   	push   %ebp
8010516c:	89 e5                	mov    %esp,%ebp
8010516e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105171:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
80105178:	e8 b4 01 00 00       	call   80105331 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010517d:	c7 45 f4 f4 31 11 80 	movl   $0x801131f4,-0xc(%ebp)
80105184:	eb 41                	jmp    801051c7 <kill+0x5c>
    if(p->pid == pid){
80105186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105189:	8b 40 10             	mov    0x10(%eax),%eax
8010518c:	3b 45 08             	cmp    0x8(%ebp),%eax
8010518f:	75 32                	jne    801051c3 <kill+0x58>
      p->killed = 1;
80105191:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105194:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
8010519b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010519e:	8b 40 0c             	mov    0xc(%eax),%eax
801051a1:	83 f8 02             	cmp    $0x2,%eax
801051a4:	75 0a                	jne    801051b0 <kill+0x45>
        p->state = RUNNABLE;
801051a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051a9:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
801051b0:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
801051b7:	e8 d7 01 00 00       	call   80105393 <release>
      return 0;
801051bc:	b8 00 00 00 00       	mov    $0x0,%eax
801051c1:	eb 1e                	jmp    801051e1 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051c3:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801051c7:	81 7d f4 f4 50 11 80 	cmpl   $0x801150f4,-0xc(%ebp)
801051ce:	72 b6                	jb     80105186 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801051d0:	c7 04 24 c0 31 11 80 	movl   $0x801131c0,(%esp)
801051d7:	e8 b7 01 00 00       	call   80105393 <release>
  return -1;
801051dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801051e1:	c9                   	leave  
801051e2:	c3                   	ret    

801051e3 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801051e3:	55                   	push   %ebp
801051e4:	89 e5                	mov    %esp,%ebp
801051e6:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051e9:	c7 45 f0 f4 31 11 80 	movl   $0x801131f4,-0x10(%ebp)
801051f0:	e9 d6 00 00 00       	jmp    801052cb <procdump+0xe8>
    if(p->state == UNUSED)
801051f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801051f8:	8b 40 0c             	mov    0xc(%eax),%eax
801051fb:	85 c0                	test   %eax,%eax
801051fd:	75 05                	jne    80105204 <procdump+0x21>
      continue;
801051ff:	e9 c3 00 00 00       	jmp    801052c7 <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105204:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105207:	8b 40 0c             	mov    0xc(%eax),%eax
8010520a:	83 f8 05             	cmp    $0x5,%eax
8010520d:	77 23                	ja     80105232 <procdump+0x4f>
8010520f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105212:	8b 40 0c             	mov    0xc(%eax),%eax
80105215:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
8010521c:	85 c0                	test   %eax,%eax
8010521e:	74 12                	je     80105232 <procdump+0x4f>
      state = states[p->state];
80105220:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105223:	8b 40 0c             	mov    0xc(%eax),%eax
80105226:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
8010522d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105230:	eb 07                	jmp    80105239 <procdump+0x56>
    else
      state = "???";
80105232:	c7 45 ec e0 8c 10 80 	movl   $0x80108ce0,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105239:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010523c:	8d 50 6c             	lea    0x6c(%eax),%edx
8010523f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105242:	8b 40 10             	mov    0x10(%eax),%eax
80105245:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105249:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010524c:	89 54 24 08          	mov    %edx,0x8(%esp)
80105250:	89 44 24 04          	mov    %eax,0x4(%esp)
80105254:	c7 04 24 e4 8c 10 80 	movl   $0x80108ce4,(%esp)
8010525b:	e8 40 b1 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80105260:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105263:	8b 40 0c             	mov    0xc(%eax),%eax
80105266:	83 f8 02             	cmp    $0x2,%eax
80105269:	75 50                	jne    801052bb <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
8010526b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010526e:	8b 40 1c             	mov    0x1c(%eax),%eax
80105271:	8b 40 0c             	mov    0xc(%eax),%eax
80105274:	83 c0 08             	add    $0x8,%eax
80105277:	8d 55 c4             	lea    -0x3c(%ebp),%edx
8010527a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010527e:	89 04 24             	mov    %eax,(%esp)
80105281:	e8 5c 01 00 00       	call   801053e2 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105286:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010528d:	eb 1b                	jmp    801052aa <procdump+0xc7>
        cprintf(" %p", pc[i]);
8010528f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105292:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105296:	89 44 24 04          	mov    %eax,0x4(%esp)
8010529a:	c7 04 24 ed 8c 10 80 	movl   $0x80108ced,(%esp)
801052a1:	e8 fa b0 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801052a6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801052aa:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801052ae:	7f 0b                	jg     801052bb <procdump+0xd8>
801052b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052b3:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801052b7:	85 c0                	test   %eax,%eax
801052b9:	75 d4                	jne    8010528f <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801052bb:	c7 04 24 f1 8c 10 80 	movl   $0x80108cf1,(%esp)
801052c2:	e8 d9 b0 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052c7:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
801052cb:	81 7d f0 f4 50 11 80 	cmpl   $0x801150f4,-0x10(%ebp)
801052d2:	0f 82 1d ff ff ff    	jb     801051f5 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801052d8:	c9                   	leave  
801052d9:	c3                   	ret    

801052da <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801052da:	55                   	push   %ebp
801052db:	89 e5                	mov    %esp,%ebp
801052dd:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801052e0:	9c                   	pushf  
801052e1:	58                   	pop    %eax
801052e2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801052e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801052e8:	c9                   	leave  
801052e9:	c3                   	ret    

801052ea <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801052ea:	55                   	push   %ebp
801052eb:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801052ed:	fa                   	cli    
}
801052ee:	5d                   	pop    %ebp
801052ef:	c3                   	ret    

801052f0 <sti>:

static inline void
sti(void)
{
801052f0:	55                   	push   %ebp
801052f1:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801052f3:	fb                   	sti    
}
801052f4:	5d                   	pop    %ebp
801052f5:	c3                   	ret    

801052f6 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
801052f6:	55                   	push   %ebp
801052f7:	89 e5                	mov    %esp,%ebp
801052f9:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801052fc:	8b 55 08             	mov    0x8(%ebp),%edx
801052ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80105302:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105305:	f0 87 02             	lock xchg %eax,(%edx)
80105308:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010530b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010530e:	c9                   	leave  
8010530f:	c3                   	ret    

80105310 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105310:	55                   	push   %ebp
80105311:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105313:	8b 45 08             	mov    0x8(%ebp),%eax
80105316:	8b 55 0c             	mov    0xc(%ebp),%edx
80105319:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010531c:	8b 45 08             	mov    0x8(%ebp),%eax
8010531f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105325:	8b 45 08             	mov    0x8(%ebp),%eax
80105328:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
8010532f:	5d                   	pop    %ebp
80105330:	c3                   	ret    

80105331 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105331:	55                   	push   %ebp
80105332:	89 e5                	mov    %esp,%ebp
80105334:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105337:	e8 49 01 00 00       	call   80105485 <pushcli>
  if(holding(lk))
8010533c:	8b 45 08             	mov    0x8(%ebp),%eax
8010533f:	89 04 24             	mov    %eax,(%esp)
80105342:	e8 14 01 00 00       	call   8010545b <holding>
80105347:	85 c0                	test   %eax,%eax
80105349:	74 0c                	je     80105357 <acquire+0x26>
    panic("acquire");
8010534b:	c7 04 24 1d 8d 10 80 	movl   $0x80108d1d,(%esp)
80105352:	e8 e3 b1 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105357:	90                   	nop
80105358:	8b 45 08             	mov    0x8(%ebp),%eax
8010535b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105362:	00 
80105363:	89 04 24             	mov    %eax,(%esp)
80105366:	e8 8b ff ff ff       	call   801052f6 <xchg>
8010536b:	85 c0                	test   %eax,%eax
8010536d:	75 e9                	jne    80105358 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
8010536f:	8b 45 08             	mov    0x8(%ebp),%eax
80105372:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105379:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
8010537c:	8b 45 08             	mov    0x8(%ebp),%eax
8010537f:	83 c0 0c             	add    $0xc,%eax
80105382:	89 44 24 04          	mov    %eax,0x4(%esp)
80105386:	8d 45 08             	lea    0x8(%ebp),%eax
80105389:	89 04 24             	mov    %eax,(%esp)
8010538c:	e8 51 00 00 00       	call   801053e2 <getcallerpcs>
}
80105391:	c9                   	leave  
80105392:	c3                   	ret    

80105393 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105393:	55                   	push   %ebp
80105394:	89 e5                	mov    %esp,%ebp
80105396:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105399:	8b 45 08             	mov    0x8(%ebp),%eax
8010539c:	89 04 24             	mov    %eax,(%esp)
8010539f:	e8 b7 00 00 00       	call   8010545b <holding>
801053a4:	85 c0                	test   %eax,%eax
801053a6:	75 0c                	jne    801053b4 <release+0x21>
    panic("release");
801053a8:	c7 04 24 25 8d 10 80 	movl   $0x80108d25,(%esp)
801053af:	e8 86 b1 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
801053b4:	8b 45 08             	mov    0x8(%ebp),%eax
801053b7:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801053be:	8b 45 08             	mov    0x8(%ebp),%eax
801053c1:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
801053c8:	8b 45 08             	mov    0x8(%ebp),%eax
801053cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801053d2:	00 
801053d3:	89 04 24             	mov    %eax,(%esp)
801053d6:	e8 1b ff ff ff       	call   801052f6 <xchg>

  popcli();
801053db:	e8 e9 00 00 00       	call   801054c9 <popcli>
}
801053e0:	c9                   	leave  
801053e1:	c3                   	ret    

801053e2 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801053e2:	55                   	push   %ebp
801053e3:	89 e5                	mov    %esp,%ebp
801053e5:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801053e8:	8b 45 08             	mov    0x8(%ebp),%eax
801053eb:	83 e8 08             	sub    $0x8,%eax
801053ee:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801053f1:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801053f8:	eb 38                	jmp    80105432 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801053fa:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801053fe:	74 38                	je     80105438 <getcallerpcs+0x56>
80105400:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105407:	76 2f                	jbe    80105438 <getcallerpcs+0x56>
80105409:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
8010540d:	74 29                	je     80105438 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010540f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105412:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105419:	8b 45 0c             	mov    0xc(%ebp),%eax
8010541c:	01 c2                	add    %eax,%edx
8010541e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105421:	8b 40 04             	mov    0x4(%eax),%eax
80105424:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105426:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105429:	8b 00                	mov    (%eax),%eax
8010542b:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
8010542e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105432:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105436:	7e c2                	jle    801053fa <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105438:	eb 19                	jmp    80105453 <getcallerpcs+0x71>
    pcs[i] = 0;
8010543a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010543d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105444:	8b 45 0c             	mov    0xc(%ebp),%eax
80105447:	01 d0                	add    %edx,%eax
80105449:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010544f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105453:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105457:	7e e1                	jle    8010543a <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105459:	c9                   	leave  
8010545a:	c3                   	ret    

8010545b <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
8010545b:	55                   	push   %ebp
8010545c:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
8010545e:	8b 45 08             	mov    0x8(%ebp),%eax
80105461:	8b 00                	mov    (%eax),%eax
80105463:	85 c0                	test   %eax,%eax
80105465:	74 17                	je     8010547e <holding+0x23>
80105467:	8b 45 08             	mov    0x8(%ebp),%eax
8010546a:	8b 50 08             	mov    0x8(%eax),%edx
8010546d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105473:	39 c2                	cmp    %eax,%edx
80105475:	75 07                	jne    8010547e <holding+0x23>
80105477:	b8 01 00 00 00       	mov    $0x1,%eax
8010547c:	eb 05                	jmp    80105483 <holding+0x28>
8010547e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105483:	5d                   	pop    %ebp
80105484:	c3                   	ret    

80105485 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105485:	55                   	push   %ebp
80105486:	89 e5                	mov    %esp,%ebp
80105488:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
8010548b:	e8 4a fe ff ff       	call   801052da <readeflags>
80105490:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105493:	e8 52 fe ff ff       	call   801052ea <cli>
  if(cpu->ncli++ == 0)
80105498:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010549f:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
801054a5:	8d 48 01             	lea    0x1(%eax),%ecx
801054a8:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
801054ae:	85 c0                	test   %eax,%eax
801054b0:	75 15                	jne    801054c7 <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
801054b2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801054b8:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054bb:	81 e2 00 02 00 00    	and    $0x200,%edx
801054c1:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801054c7:	c9                   	leave  
801054c8:	c3                   	ret    

801054c9 <popcli>:

void
popcli(void)
{
801054c9:	55                   	push   %ebp
801054ca:	89 e5                	mov    %esp,%ebp
801054cc:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801054cf:	e8 06 fe ff ff       	call   801052da <readeflags>
801054d4:	25 00 02 00 00       	and    $0x200,%eax
801054d9:	85 c0                	test   %eax,%eax
801054db:	74 0c                	je     801054e9 <popcli+0x20>
    panic("popcli - interruptible");
801054dd:	c7 04 24 2d 8d 10 80 	movl   $0x80108d2d,(%esp)
801054e4:	e8 51 b0 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
801054e9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801054ef:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801054f5:	83 ea 01             	sub    $0x1,%edx
801054f8:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801054fe:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105504:	85 c0                	test   %eax,%eax
80105506:	79 0c                	jns    80105514 <popcli+0x4b>
    panic("popcli");
80105508:	c7 04 24 44 8d 10 80 	movl   $0x80108d44,(%esp)
8010550f:	e8 26 b0 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105514:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010551a:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105520:	85 c0                	test   %eax,%eax
80105522:	75 15                	jne    80105539 <popcli+0x70>
80105524:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010552a:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105530:	85 c0                	test   %eax,%eax
80105532:	74 05                	je     80105539 <popcli+0x70>
    sti();
80105534:	e8 b7 fd ff ff       	call   801052f0 <sti>
}
80105539:	c9                   	leave  
8010553a:	c3                   	ret    

8010553b <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
8010553b:	55                   	push   %ebp
8010553c:	89 e5                	mov    %esp,%ebp
8010553e:	57                   	push   %edi
8010553f:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105540:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105543:	8b 55 10             	mov    0x10(%ebp),%edx
80105546:	8b 45 0c             	mov    0xc(%ebp),%eax
80105549:	89 cb                	mov    %ecx,%ebx
8010554b:	89 df                	mov    %ebx,%edi
8010554d:	89 d1                	mov    %edx,%ecx
8010554f:	fc                   	cld    
80105550:	f3 aa                	rep stos %al,%es:(%edi)
80105552:	89 ca                	mov    %ecx,%edx
80105554:	89 fb                	mov    %edi,%ebx
80105556:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105559:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010555c:	5b                   	pop    %ebx
8010555d:	5f                   	pop    %edi
8010555e:	5d                   	pop    %ebp
8010555f:	c3                   	ret    

80105560 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105560:	55                   	push   %ebp
80105561:	89 e5                	mov    %esp,%ebp
80105563:	57                   	push   %edi
80105564:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105565:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105568:	8b 55 10             	mov    0x10(%ebp),%edx
8010556b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010556e:	89 cb                	mov    %ecx,%ebx
80105570:	89 df                	mov    %ebx,%edi
80105572:	89 d1                	mov    %edx,%ecx
80105574:	fc                   	cld    
80105575:	f3 ab                	rep stos %eax,%es:(%edi)
80105577:	89 ca                	mov    %ecx,%edx
80105579:	89 fb                	mov    %edi,%ebx
8010557b:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010557e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105581:	5b                   	pop    %ebx
80105582:	5f                   	pop    %edi
80105583:	5d                   	pop    %ebp
80105584:	c3                   	ret    

80105585 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105585:	55                   	push   %ebp
80105586:	89 e5                	mov    %esp,%ebp
80105588:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
8010558b:	8b 45 08             	mov    0x8(%ebp),%eax
8010558e:	83 e0 03             	and    $0x3,%eax
80105591:	85 c0                	test   %eax,%eax
80105593:	75 49                	jne    801055de <memset+0x59>
80105595:	8b 45 10             	mov    0x10(%ebp),%eax
80105598:	83 e0 03             	and    $0x3,%eax
8010559b:	85 c0                	test   %eax,%eax
8010559d:	75 3f                	jne    801055de <memset+0x59>
    c &= 0xFF;
8010559f:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801055a6:	8b 45 10             	mov    0x10(%ebp),%eax
801055a9:	c1 e8 02             	shr    $0x2,%eax
801055ac:	89 c2                	mov    %eax,%edx
801055ae:	8b 45 0c             	mov    0xc(%ebp),%eax
801055b1:	c1 e0 18             	shl    $0x18,%eax
801055b4:	89 c1                	mov    %eax,%ecx
801055b6:	8b 45 0c             	mov    0xc(%ebp),%eax
801055b9:	c1 e0 10             	shl    $0x10,%eax
801055bc:	09 c1                	or     %eax,%ecx
801055be:	8b 45 0c             	mov    0xc(%ebp),%eax
801055c1:	c1 e0 08             	shl    $0x8,%eax
801055c4:	09 c8                	or     %ecx,%eax
801055c6:	0b 45 0c             	or     0xc(%ebp),%eax
801055c9:	89 54 24 08          	mov    %edx,0x8(%esp)
801055cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801055d1:	8b 45 08             	mov    0x8(%ebp),%eax
801055d4:	89 04 24             	mov    %eax,(%esp)
801055d7:	e8 84 ff ff ff       	call   80105560 <stosl>
801055dc:	eb 19                	jmp    801055f7 <memset+0x72>
  } else
    stosb(dst, c, n);
801055de:	8b 45 10             	mov    0x10(%ebp),%eax
801055e1:	89 44 24 08          	mov    %eax,0x8(%esp)
801055e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801055e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801055ec:	8b 45 08             	mov    0x8(%ebp),%eax
801055ef:	89 04 24             	mov    %eax,(%esp)
801055f2:	e8 44 ff ff ff       	call   8010553b <stosb>
  return dst;
801055f7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801055fa:	c9                   	leave  
801055fb:	c3                   	ret    

801055fc <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801055fc:	55                   	push   %ebp
801055fd:	89 e5                	mov    %esp,%ebp
801055ff:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105602:	8b 45 08             	mov    0x8(%ebp),%eax
80105605:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105608:	8b 45 0c             	mov    0xc(%ebp),%eax
8010560b:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
8010560e:	eb 30                	jmp    80105640 <memcmp+0x44>
    if(*s1 != *s2)
80105610:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105613:	0f b6 10             	movzbl (%eax),%edx
80105616:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105619:	0f b6 00             	movzbl (%eax),%eax
8010561c:	38 c2                	cmp    %al,%dl
8010561e:	74 18                	je     80105638 <memcmp+0x3c>
      return *s1 - *s2;
80105620:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105623:	0f b6 00             	movzbl (%eax),%eax
80105626:	0f b6 d0             	movzbl %al,%edx
80105629:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010562c:	0f b6 00             	movzbl (%eax),%eax
8010562f:	0f b6 c0             	movzbl %al,%eax
80105632:	29 c2                	sub    %eax,%edx
80105634:	89 d0                	mov    %edx,%eax
80105636:	eb 1a                	jmp    80105652 <memcmp+0x56>
    s1++, s2++;
80105638:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010563c:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105640:	8b 45 10             	mov    0x10(%ebp),%eax
80105643:	8d 50 ff             	lea    -0x1(%eax),%edx
80105646:	89 55 10             	mov    %edx,0x10(%ebp)
80105649:	85 c0                	test   %eax,%eax
8010564b:	75 c3                	jne    80105610 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
8010564d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105652:	c9                   	leave  
80105653:	c3                   	ret    

80105654 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105654:	55                   	push   %ebp
80105655:	89 e5                	mov    %esp,%ebp
80105657:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
8010565a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010565d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105660:	8b 45 08             	mov    0x8(%ebp),%eax
80105663:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105666:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105669:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010566c:	73 3d                	jae    801056ab <memmove+0x57>
8010566e:	8b 45 10             	mov    0x10(%ebp),%eax
80105671:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105674:	01 d0                	add    %edx,%eax
80105676:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105679:	76 30                	jbe    801056ab <memmove+0x57>
    s += n;
8010567b:	8b 45 10             	mov    0x10(%ebp),%eax
8010567e:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105681:	8b 45 10             	mov    0x10(%ebp),%eax
80105684:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105687:	eb 13                	jmp    8010569c <memmove+0x48>
      *--d = *--s;
80105689:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
8010568d:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105691:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105694:	0f b6 10             	movzbl (%eax),%edx
80105697:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010569a:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
8010569c:	8b 45 10             	mov    0x10(%ebp),%eax
8010569f:	8d 50 ff             	lea    -0x1(%eax),%edx
801056a2:	89 55 10             	mov    %edx,0x10(%ebp)
801056a5:	85 c0                	test   %eax,%eax
801056a7:	75 e0                	jne    80105689 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801056a9:	eb 26                	jmp    801056d1 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801056ab:	eb 17                	jmp    801056c4 <memmove+0x70>
      *d++ = *s++;
801056ad:	8b 45 f8             	mov    -0x8(%ebp),%eax
801056b0:	8d 50 01             	lea    0x1(%eax),%edx
801056b3:	89 55 f8             	mov    %edx,-0x8(%ebp)
801056b6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801056b9:	8d 4a 01             	lea    0x1(%edx),%ecx
801056bc:	89 4d fc             	mov    %ecx,-0x4(%ebp)
801056bf:	0f b6 12             	movzbl (%edx),%edx
801056c2:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801056c4:	8b 45 10             	mov    0x10(%ebp),%eax
801056c7:	8d 50 ff             	lea    -0x1(%eax),%edx
801056ca:	89 55 10             	mov    %edx,0x10(%ebp)
801056cd:	85 c0                	test   %eax,%eax
801056cf:	75 dc                	jne    801056ad <memmove+0x59>
      *d++ = *s++;

  return dst;
801056d1:	8b 45 08             	mov    0x8(%ebp),%eax
}
801056d4:	c9                   	leave  
801056d5:	c3                   	ret    

801056d6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801056d6:	55                   	push   %ebp
801056d7:	89 e5                	mov    %esp,%ebp
801056d9:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801056dc:	8b 45 10             	mov    0x10(%ebp),%eax
801056df:	89 44 24 08          	mov    %eax,0x8(%esp)
801056e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801056e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801056ea:	8b 45 08             	mov    0x8(%ebp),%eax
801056ed:	89 04 24             	mov    %eax,(%esp)
801056f0:	e8 5f ff ff ff       	call   80105654 <memmove>
}
801056f5:	c9                   	leave  
801056f6:	c3                   	ret    

801056f7 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801056f7:	55                   	push   %ebp
801056f8:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801056fa:	eb 0c                	jmp    80105708 <strncmp+0x11>
    n--, p++, q++;
801056fc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105700:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105704:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105708:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010570c:	74 1a                	je     80105728 <strncmp+0x31>
8010570e:	8b 45 08             	mov    0x8(%ebp),%eax
80105711:	0f b6 00             	movzbl (%eax),%eax
80105714:	84 c0                	test   %al,%al
80105716:	74 10                	je     80105728 <strncmp+0x31>
80105718:	8b 45 08             	mov    0x8(%ebp),%eax
8010571b:	0f b6 10             	movzbl (%eax),%edx
8010571e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105721:	0f b6 00             	movzbl (%eax),%eax
80105724:	38 c2                	cmp    %al,%dl
80105726:	74 d4                	je     801056fc <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105728:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010572c:	75 07                	jne    80105735 <strncmp+0x3e>
    return 0;
8010572e:	b8 00 00 00 00       	mov    $0x0,%eax
80105733:	eb 16                	jmp    8010574b <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105735:	8b 45 08             	mov    0x8(%ebp),%eax
80105738:	0f b6 00             	movzbl (%eax),%eax
8010573b:	0f b6 d0             	movzbl %al,%edx
8010573e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105741:	0f b6 00             	movzbl (%eax),%eax
80105744:	0f b6 c0             	movzbl %al,%eax
80105747:	29 c2                	sub    %eax,%edx
80105749:	89 d0                	mov    %edx,%eax
}
8010574b:	5d                   	pop    %ebp
8010574c:	c3                   	ret    

8010574d <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010574d:	55                   	push   %ebp
8010574e:	89 e5                	mov    %esp,%ebp
80105750:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105753:	8b 45 08             	mov    0x8(%ebp),%eax
80105756:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105759:	90                   	nop
8010575a:	8b 45 10             	mov    0x10(%ebp),%eax
8010575d:	8d 50 ff             	lea    -0x1(%eax),%edx
80105760:	89 55 10             	mov    %edx,0x10(%ebp)
80105763:	85 c0                	test   %eax,%eax
80105765:	7e 1e                	jle    80105785 <strncpy+0x38>
80105767:	8b 45 08             	mov    0x8(%ebp),%eax
8010576a:	8d 50 01             	lea    0x1(%eax),%edx
8010576d:	89 55 08             	mov    %edx,0x8(%ebp)
80105770:	8b 55 0c             	mov    0xc(%ebp),%edx
80105773:	8d 4a 01             	lea    0x1(%edx),%ecx
80105776:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105779:	0f b6 12             	movzbl (%edx),%edx
8010577c:	88 10                	mov    %dl,(%eax)
8010577e:	0f b6 00             	movzbl (%eax),%eax
80105781:	84 c0                	test   %al,%al
80105783:	75 d5                	jne    8010575a <strncpy+0xd>
    ;
  while(n-- > 0)
80105785:	eb 0c                	jmp    80105793 <strncpy+0x46>
    *s++ = 0;
80105787:	8b 45 08             	mov    0x8(%ebp),%eax
8010578a:	8d 50 01             	lea    0x1(%eax),%edx
8010578d:	89 55 08             	mov    %edx,0x8(%ebp)
80105790:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105793:	8b 45 10             	mov    0x10(%ebp),%eax
80105796:	8d 50 ff             	lea    -0x1(%eax),%edx
80105799:	89 55 10             	mov    %edx,0x10(%ebp)
8010579c:	85 c0                	test   %eax,%eax
8010579e:	7f e7                	jg     80105787 <strncpy+0x3a>
    *s++ = 0;
  return os;
801057a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801057a3:	c9                   	leave  
801057a4:	c3                   	ret    

801057a5 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801057a5:	55                   	push   %ebp
801057a6:	89 e5                	mov    %esp,%ebp
801057a8:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801057ab:	8b 45 08             	mov    0x8(%ebp),%eax
801057ae:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801057b1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801057b5:	7f 05                	jg     801057bc <safestrcpy+0x17>
    return os;
801057b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801057ba:	eb 31                	jmp    801057ed <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
801057bc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801057c0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801057c4:	7e 1e                	jle    801057e4 <safestrcpy+0x3f>
801057c6:	8b 45 08             	mov    0x8(%ebp),%eax
801057c9:	8d 50 01             	lea    0x1(%eax),%edx
801057cc:	89 55 08             	mov    %edx,0x8(%ebp)
801057cf:	8b 55 0c             	mov    0xc(%ebp),%edx
801057d2:	8d 4a 01             	lea    0x1(%edx),%ecx
801057d5:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801057d8:	0f b6 12             	movzbl (%edx),%edx
801057db:	88 10                	mov    %dl,(%eax)
801057dd:	0f b6 00             	movzbl (%eax),%eax
801057e0:	84 c0                	test   %al,%al
801057e2:	75 d8                	jne    801057bc <safestrcpy+0x17>
    ;
  *s = 0;
801057e4:	8b 45 08             	mov    0x8(%ebp),%eax
801057e7:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801057ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801057ed:	c9                   	leave  
801057ee:	c3                   	ret    

801057ef <strlen>:

int
strlen(const char *s)
{
801057ef:	55                   	push   %ebp
801057f0:	89 e5                	mov    %esp,%ebp
801057f2:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801057f5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801057fc:	eb 04                	jmp    80105802 <strlen+0x13>
801057fe:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105802:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105805:	8b 45 08             	mov    0x8(%ebp),%eax
80105808:	01 d0                	add    %edx,%eax
8010580a:	0f b6 00             	movzbl (%eax),%eax
8010580d:	84 c0                	test   %al,%al
8010580f:	75 ed                	jne    801057fe <strlen+0xf>
    ;
  return n;
80105811:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105814:	c9                   	leave  
80105815:	c3                   	ret    

80105816 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105816:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010581a:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
8010581e:	55                   	push   %ebp
  pushl %ebx
8010581f:	53                   	push   %ebx
  pushl %esi
80105820:	56                   	push   %esi
  pushl %edi
80105821:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105822:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105824:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105826:	5f                   	pop    %edi
  popl %esi
80105827:	5e                   	pop    %esi
  popl %ebx
80105828:	5b                   	pop    %ebx
  popl %ebp
80105829:	5d                   	pop    %ebp
  ret
8010582a:	c3                   	ret    

8010582b <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010582b:	55                   	push   %ebp
8010582c:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
8010582e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105834:	8b 00                	mov    (%eax),%eax
80105836:	3b 45 08             	cmp    0x8(%ebp),%eax
80105839:	76 12                	jbe    8010584d <fetchint+0x22>
8010583b:	8b 45 08             	mov    0x8(%ebp),%eax
8010583e:	8d 50 04             	lea    0x4(%eax),%edx
80105841:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105847:	8b 00                	mov    (%eax),%eax
80105849:	39 c2                	cmp    %eax,%edx
8010584b:	76 07                	jbe    80105854 <fetchint+0x29>
    return -1;
8010584d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105852:	eb 0f                	jmp    80105863 <fetchint+0x38>
  *ip = *(int*)(addr);
80105854:	8b 45 08             	mov    0x8(%ebp),%eax
80105857:	8b 10                	mov    (%eax),%edx
80105859:	8b 45 0c             	mov    0xc(%ebp),%eax
8010585c:	89 10                	mov    %edx,(%eax)
  return 0;
8010585e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105863:	5d                   	pop    %ebp
80105864:	c3                   	ret    

80105865 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105865:	55                   	push   %ebp
80105866:	89 e5                	mov    %esp,%ebp
80105868:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
8010586b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105871:	8b 00                	mov    (%eax),%eax
80105873:	3b 45 08             	cmp    0x8(%ebp),%eax
80105876:	77 07                	ja     8010587f <fetchstr+0x1a>
    return -1;
80105878:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010587d:	eb 46                	jmp    801058c5 <fetchstr+0x60>
  *pp = (char*)addr;
8010587f:	8b 55 08             	mov    0x8(%ebp),%edx
80105882:	8b 45 0c             	mov    0xc(%ebp),%eax
80105885:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
80105887:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010588d:	8b 00                	mov    (%eax),%eax
8010588f:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105892:	8b 45 0c             	mov    0xc(%ebp),%eax
80105895:	8b 00                	mov    (%eax),%eax
80105897:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010589a:	eb 1c                	jmp    801058b8 <fetchstr+0x53>
    if(*s == 0)
8010589c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010589f:	0f b6 00             	movzbl (%eax),%eax
801058a2:	84 c0                	test   %al,%al
801058a4:	75 0e                	jne    801058b4 <fetchstr+0x4f>
      return s - *pp;
801058a6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058a9:	8b 45 0c             	mov    0xc(%ebp),%eax
801058ac:	8b 00                	mov    (%eax),%eax
801058ae:	29 c2                	sub    %eax,%edx
801058b0:	89 d0                	mov    %edx,%eax
801058b2:	eb 11                	jmp    801058c5 <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
801058b4:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801058b8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058bb:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801058be:	72 dc                	jb     8010589c <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
801058c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801058c5:	c9                   	leave  
801058c6:	c3                   	ret    

801058c7 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801058c7:	55                   	push   %ebp
801058c8:	89 e5                	mov    %esp,%ebp
801058ca:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
801058cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058d3:	8b 40 18             	mov    0x18(%eax),%eax
801058d6:	8b 50 44             	mov    0x44(%eax),%edx
801058d9:	8b 45 08             	mov    0x8(%ebp),%eax
801058dc:	c1 e0 02             	shl    $0x2,%eax
801058df:	01 d0                	add    %edx,%eax
801058e1:	8d 50 04             	lea    0x4(%eax),%edx
801058e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801058e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801058eb:	89 14 24             	mov    %edx,(%esp)
801058ee:	e8 38 ff ff ff       	call   8010582b <fetchint>
}
801058f3:	c9                   	leave  
801058f4:	c3                   	ret    

801058f5 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801058f5:	55                   	push   %ebp
801058f6:	89 e5                	mov    %esp,%ebp
801058f8:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801058fb:	8d 45 fc             	lea    -0x4(%ebp),%eax
801058fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105902:	8b 45 08             	mov    0x8(%ebp),%eax
80105905:	89 04 24             	mov    %eax,(%esp)
80105908:	e8 ba ff ff ff       	call   801058c7 <argint>
8010590d:	85 c0                	test   %eax,%eax
8010590f:	79 07                	jns    80105918 <argptr+0x23>
    return -1;
80105911:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105916:	eb 3d                	jmp    80105955 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105918:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010591b:	89 c2                	mov    %eax,%edx
8010591d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105923:	8b 00                	mov    (%eax),%eax
80105925:	39 c2                	cmp    %eax,%edx
80105927:	73 16                	jae    8010593f <argptr+0x4a>
80105929:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010592c:	89 c2                	mov    %eax,%edx
8010592e:	8b 45 10             	mov    0x10(%ebp),%eax
80105931:	01 c2                	add    %eax,%edx
80105933:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105939:	8b 00                	mov    (%eax),%eax
8010593b:	39 c2                	cmp    %eax,%edx
8010593d:	76 07                	jbe    80105946 <argptr+0x51>
    return -1;
8010593f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105944:	eb 0f                	jmp    80105955 <argptr+0x60>
  *pp = (char*)i;
80105946:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105949:	89 c2                	mov    %eax,%edx
8010594b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010594e:	89 10                	mov    %edx,(%eax)
  return 0;
80105950:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105955:	c9                   	leave  
80105956:	c3                   	ret    

80105957 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105957:	55                   	push   %ebp
80105958:	89 e5                	mov    %esp,%ebp
8010595a:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010595d:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105960:	89 44 24 04          	mov    %eax,0x4(%esp)
80105964:	8b 45 08             	mov    0x8(%ebp),%eax
80105967:	89 04 24             	mov    %eax,(%esp)
8010596a:	e8 58 ff ff ff       	call   801058c7 <argint>
8010596f:	85 c0                	test   %eax,%eax
80105971:	79 07                	jns    8010597a <argstr+0x23>
    return -1;
80105973:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105978:	eb 12                	jmp    8010598c <argstr+0x35>
  return fetchstr(addr, pp);
8010597a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010597d:	8b 55 0c             	mov    0xc(%ebp),%edx
80105980:	89 54 24 04          	mov    %edx,0x4(%esp)
80105984:	89 04 24             	mov    %eax,(%esp)
80105987:	e8 d9 fe ff ff       	call   80105865 <fetchstr>
}
8010598c:	c9                   	leave  
8010598d:	c3                   	ret    

8010598e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
8010598e:	55                   	push   %ebp
8010598f:	89 e5                	mov    %esp,%ebp
80105991:	53                   	push   %ebx
80105992:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105995:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010599b:	8b 40 18             	mov    0x18(%eax),%eax
8010599e:	8b 40 1c             	mov    0x1c(%eax),%eax
801059a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801059a4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801059a8:	7e 30                	jle    801059da <syscall+0x4c>
801059aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ad:	83 f8 15             	cmp    $0x15,%eax
801059b0:	77 28                	ja     801059da <syscall+0x4c>
801059b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b5:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801059bc:	85 c0                	test   %eax,%eax
801059be:	74 1a                	je     801059da <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
801059c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059c6:	8b 58 18             	mov    0x18(%eax),%ebx
801059c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059cc:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801059d3:	ff d0                	call   *%eax
801059d5:	89 43 1c             	mov    %eax,0x1c(%ebx)
801059d8:	eb 3d                	jmp    80105a17 <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801059da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059e0:	8d 48 6c             	lea    0x6c(%eax),%ecx
801059e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801059e9:	8b 40 10             	mov    0x10(%eax),%eax
801059ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
801059ef:	89 54 24 0c          	mov    %edx,0xc(%esp)
801059f3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801059f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801059fb:	c7 04 24 4b 8d 10 80 	movl   $0x80108d4b,(%esp)
80105a02:	e8 99 a9 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105a07:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a0d:	8b 40 18             	mov    0x18(%eax),%eax
80105a10:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105a17:	83 c4 24             	add    $0x24,%esp
80105a1a:	5b                   	pop    %ebx
80105a1b:	5d                   	pop    %ebp
80105a1c:	c3                   	ret    

80105a1d <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105a1d:	55                   	push   %ebp
80105a1e:	89 e5                	mov    %esp,%ebp
80105a20:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105a23:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105a26:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a2a:	8b 45 08             	mov    0x8(%ebp),%eax
80105a2d:	89 04 24             	mov    %eax,(%esp)
80105a30:	e8 92 fe ff ff       	call   801058c7 <argint>
80105a35:	85 c0                	test   %eax,%eax
80105a37:	79 07                	jns    80105a40 <argfd+0x23>
    return -1;
80105a39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a3e:	eb 50                	jmp    80105a90 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105a40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a43:	85 c0                	test   %eax,%eax
80105a45:	78 21                	js     80105a68 <argfd+0x4b>
80105a47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a4a:	83 f8 0f             	cmp    $0xf,%eax
80105a4d:	7f 19                	jg     80105a68 <argfd+0x4b>
80105a4f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a55:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105a58:	83 c2 08             	add    $0x8,%edx
80105a5b:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105a5f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a62:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a66:	75 07                	jne    80105a6f <argfd+0x52>
    return -1;
80105a68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a6d:	eb 21                	jmp    80105a90 <argfd+0x73>
  if(pfd)
80105a6f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105a73:	74 08                	je     80105a7d <argfd+0x60>
    *pfd = fd;
80105a75:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105a78:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a7b:	89 10                	mov    %edx,(%eax)
  if(pf)
80105a7d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105a81:	74 08                	je     80105a8b <argfd+0x6e>
    *pf = f;
80105a83:	8b 45 10             	mov    0x10(%ebp),%eax
80105a86:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105a89:	89 10                	mov    %edx,(%eax)
  return 0;
80105a8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a90:	c9                   	leave  
80105a91:	c3                   	ret    

80105a92 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105a92:	55                   	push   %ebp
80105a93:	89 e5                	mov    %esp,%ebp
80105a95:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105a98:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105a9f:	eb 30                	jmp    80105ad1 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105aa1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105aa7:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105aaa:	83 c2 08             	add    $0x8,%edx
80105aad:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105ab1:	85 c0                	test   %eax,%eax
80105ab3:	75 18                	jne    80105acd <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105ab5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105abb:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105abe:	8d 4a 08             	lea    0x8(%edx),%ecx
80105ac1:	8b 55 08             	mov    0x8(%ebp),%edx
80105ac4:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105ac8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105acb:	eb 0f                	jmp    80105adc <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105acd:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ad1:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105ad5:	7e ca                	jle    80105aa1 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105ad7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105adc:	c9                   	leave  
80105add:	c3                   	ret    

80105ade <sys_dup>:

int
sys_dup(void)
{
80105ade:	55                   	push   %ebp
80105adf:	89 e5                	mov    %esp,%ebp
80105ae1:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105ae4:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ae7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105aeb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105af2:	00 
80105af3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105afa:	e8 1e ff ff ff       	call   80105a1d <argfd>
80105aff:	85 c0                	test   %eax,%eax
80105b01:	79 07                	jns    80105b0a <sys_dup+0x2c>
    return -1;
80105b03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b08:	eb 29                	jmp    80105b33 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105b0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b0d:	89 04 24             	mov    %eax,(%esp)
80105b10:	e8 7d ff ff ff       	call   80105a92 <fdalloc>
80105b15:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b18:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b1c:	79 07                	jns    80105b25 <sys_dup+0x47>
    return -1;
80105b1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b23:	eb 0e                	jmp    80105b33 <sys_dup+0x55>
  filedup(f);
80105b25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b28:	89 04 24             	mov    %eax,(%esp)
80105b2b:	e8 fe b8 ff ff       	call   8010142e <filedup>
  return fd;
80105b30:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105b33:	c9                   	leave  
80105b34:	c3                   	ret    

80105b35 <sys_read>:

int
sys_read(void)
{
80105b35:	55                   	push   %ebp
80105b36:	89 e5                	mov    %esp,%ebp
80105b38:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105b3b:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105b3e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b42:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105b49:	00 
80105b4a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105b51:	e8 c7 fe ff ff       	call   80105a1d <argfd>
80105b56:	85 c0                	test   %eax,%eax
80105b58:	78 35                	js     80105b8f <sys_read+0x5a>
80105b5a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105b5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b61:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105b68:	e8 5a fd ff ff       	call   801058c7 <argint>
80105b6d:	85 c0                	test   %eax,%eax
80105b6f:	78 1e                	js     80105b8f <sys_read+0x5a>
80105b71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b74:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b78:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105b7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b7f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105b86:	e8 6a fd ff ff       	call   801058f5 <argptr>
80105b8b:	85 c0                	test   %eax,%eax
80105b8d:	79 07                	jns    80105b96 <sys_read+0x61>
    return -1;
80105b8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b94:	eb 19                	jmp    80105baf <sys_read+0x7a>
  return fileread(f, p, n);
80105b96:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105b99:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105b9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b9f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105ba3:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ba7:	89 04 24             	mov    %eax,(%esp)
80105baa:	e8 ec b9 ff ff       	call   8010159b <fileread>
}
80105baf:	c9                   	leave  
80105bb0:	c3                   	ret    

80105bb1 <sys_write>:

int
sys_write(void)
{
80105bb1:	55                   	push   %ebp
80105bb2:	89 e5                	mov    %esp,%ebp
80105bb4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105bb7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105bba:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bbe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105bc5:	00 
80105bc6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105bcd:	e8 4b fe ff ff       	call   80105a1d <argfd>
80105bd2:	85 c0                	test   %eax,%eax
80105bd4:	78 35                	js     80105c0b <sys_write+0x5a>
80105bd6:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105bd9:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bdd:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105be4:	e8 de fc ff ff       	call   801058c7 <argint>
80105be9:	85 c0                	test   %eax,%eax
80105beb:	78 1e                	js     80105c0b <sys_write+0x5a>
80105bed:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bf0:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bf4:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105bf7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bfb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105c02:	e8 ee fc ff ff       	call   801058f5 <argptr>
80105c07:	85 c0                	test   %eax,%eax
80105c09:	79 07                	jns    80105c12 <sys_write+0x61>
    return -1;
80105c0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c10:	eb 19                	jmp    80105c2b <sys_write+0x7a>
  return filewrite(f, p, n);
80105c12:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105c15:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105c18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c1b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105c1f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105c23:	89 04 24             	mov    %eax,(%esp)
80105c26:	e8 2c ba ff ff       	call   80101657 <filewrite>
}
80105c2b:	c9                   	leave  
80105c2c:	c3                   	ret    

80105c2d <sys_close>:

int
sys_close(void)
{
80105c2d:	55                   	push   %ebp
80105c2e:	89 e5                	mov    %esp,%ebp
80105c30:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105c33:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105c36:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c3a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105c3d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c41:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105c48:	e8 d0 fd ff ff       	call   80105a1d <argfd>
80105c4d:	85 c0                	test   %eax,%eax
80105c4f:	79 07                	jns    80105c58 <sys_close+0x2b>
    return -1;
80105c51:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c56:	eb 24                	jmp    80105c7c <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105c58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c5e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105c61:	83 c2 08             	add    $0x8,%edx
80105c64:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105c6b:	00 
  fileclose(f);
80105c6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c6f:	89 04 24             	mov    %eax,(%esp)
80105c72:	e8 ff b7 ff ff       	call   80101476 <fileclose>
  return 0;
80105c77:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105c7c:	c9                   	leave  
80105c7d:	c3                   	ret    

80105c7e <sys_fstat>:

int
sys_fstat(void)
{
80105c7e:	55                   	push   %ebp
80105c7f:	89 e5                	mov    %esp,%ebp
80105c81:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105c84:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105c87:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c8b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105c92:	00 
80105c93:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105c9a:	e8 7e fd ff ff       	call   80105a1d <argfd>
80105c9f:	85 c0                	test   %eax,%eax
80105ca1:	78 1f                	js     80105cc2 <sys_fstat+0x44>
80105ca3:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105caa:	00 
80105cab:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105cae:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cb2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105cb9:	e8 37 fc ff ff       	call   801058f5 <argptr>
80105cbe:	85 c0                	test   %eax,%eax
80105cc0:	79 07                	jns    80105cc9 <sys_fstat+0x4b>
    return -1;
80105cc2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cc7:	eb 12                	jmp    80105cdb <sys_fstat+0x5d>
  return filestat(f, st);
80105cc9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ccc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ccf:	89 54 24 04          	mov    %edx,0x4(%esp)
80105cd3:	89 04 24             	mov    %eax,(%esp)
80105cd6:	e8 71 b8 ff ff       	call   8010154c <filestat>
}
80105cdb:	c9                   	leave  
80105cdc:	c3                   	ret    

80105cdd <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105cdd:	55                   	push   %ebp
80105cde:	89 e5                	mov    %esp,%ebp
80105ce0:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105ce3:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105ce6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105cf1:	e8 61 fc ff ff       	call   80105957 <argstr>
80105cf6:	85 c0                	test   %eax,%eax
80105cf8:	78 17                	js     80105d11 <sys_link+0x34>
80105cfa:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105cfd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d01:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105d08:	e8 4a fc ff ff       	call   80105957 <argstr>
80105d0d:	85 c0                	test   %eax,%eax
80105d0f:	79 0a                	jns    80105d1b <sys_link+0x3e>
    return -1;
80105d11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d16:	e9 42 01 00 00       	jmp    80105e5d <sys_link+0x180>

  begin_op();
80105d1b:	e8 29 dc ff ff       	call   80103949 <begin_op>
  if((ip = namei(old)) == 0){
80105d20:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105d23:	89 04 24             	mov    %eax,(%esp)
80105d26:	e8 e7 cb ff ff       	call   80102912 <namei>
80105d2b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d2e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d32:	75 0f                	jne    80105d43 <sys_link+0x66>
    end_op();
80105d34:	e8 94 dc ff ff       	call   801039cd <end_op>
    return -1;
80105d39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d3e:	e9 1a 01 00 00       	jmp    80105e5d <sys_link+0x180>
  }

  ilock(ip);
80105d43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d46:	89 04 24             	mov    %eax,(%esp)
80105d49:	e8 13 c0 ff ff       	call   80101d61 <ilock>
  if(ip->type == T_DIR){
80105d4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d51:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105d55:	66 83 f8 01          	cmp    $0x1,%ax
80105d59:	75 1a                	jne    80105d75 <sys_link+0x98>
    iunlockput(ip);
80105d5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d5e:	89 04 24             	mov    %eax,(%esp)
80105d61:	e8 85 c2 ff ff       	call   80101feb <iunlockput>
    end_op();
80105d66:	e8 62 dc ff ff       	call   801039cd <end_op>
    return -1;
80105d6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d70:	e9 e8 00 00 00       	jmp    80105e5d <sys_link+0x180>
  }

  ip->nlink++;
80105d75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d78:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105d7c:	8d 50 01             	lea    0x1(%eax),%edx
80105d7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d82:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105d86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d89:	89 04 24             	mov    %eax,(%esp)
80105d8c:	e8 0e be ff ff       	call   80101b9f <iupdate>
  iunlock(ip);
80105d91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d94:	89 04 24             	mov    %eax,(%esp)
80105d97:	e8 19 c1 ff ff       	call   80101eb5 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105d9c:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105d9f:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105da2:	89 54 24 04          	mov    %edx,0x4(%esp)
80105da6:	89 04 24             	mov    %eax,(%esp)
80105da9:	e8 86 cb ff ff       	call   80102934 <nameiparent>
80105dae:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105db1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105db5:	75 02                	jne    80105db9 <sys_link+0xdc>
    goto bad;
80105db7:	eb 68                	jmp    80105e21 <sys_link+0x144>
  ilock(dp);
80105db9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dbc:	89 04 24             	mov    %eax,(%esp)
80105dbf:	e8 9d bf ff ff       	call   80101d61 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105dc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc7:	8b 10                	mov    (%eax),%edx
80105dc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dcc:	8b 00                	mov    (%eax),%eax
80105dce:	39 c2                	cmp    %eax,%edx
80105dd0:	75 20                	jne    80105df2 <sys_link+0x115>
80105dd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dd5:	8b 40 04             	mov    0x4(%eax),%eax
80105dd8:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ddc:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105ddf:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105de6:	89 04 24             	mov    %eax,(%esp)
80105de9:	e8 64 c8 ff ff       	call   80102652 <dirlink>
80105dee:	85 c0                	test   %eax,%eax
80105df0:	79 0d                	jns    80105dff <sys_link+0x122>
    iunlockput(dp);
80105df2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105df5:	89 04 24             	mov    %eax,(%esp)
80105df8:	e8 ee c1 ff ff       	call   80101feb <iunlockput>
    goto bad;
80105dfd:	eb 22                	jmp    80105e21 <sys_link+0x144>
  }
  iunlockput(dp);
80105dff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e02:	89 04 24             	mov    %eax,(%esp)
80105e05:	e8 e1 c1 ff ff       	call   80101feb <iunlockput>
  iput(ip);
80105e0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e0d:	89 04 24             	mov    %eax,(%esp)
80105e10:	e8 05 c1 ff ff       	call   80101f1a <iput>

  end_op();
80105e15:	e8 b3 db ff ff       	call   801039cd <end_op>

  return 0;
80105e1a:	b8 00 00 00 00       	mov    $0x0,%eax
80105e1f:	eb 3c                	jmp    80105e5d <sys_link+0x180>

bad:
  ilock(ip);
80105e21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e24:	89 04 24             	mov    %eax,(%esp)
80105e27:	e8 35 bf ff ff       	call   80101d61 <ilock>
  ip->nlink--;
80105e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e2f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e33:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e39:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105e3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e40:	89 04 24             	mov    %eax,(%esp)
80105e43:	e8 57 bd ff ff       	call   80101b9f <iupdate>
  iunlockput(ip);
80105e48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e4b:	89 04 24             	mov    %eax,(%esp)
80105e4e:	e8 98 c1 ff ff       	call   80101feb <iunlockput>
  end_op();
80105e53:	e8 75 db ff ff       	call   801039cd <end_op>
  return -1;
80105e58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105e5d:	c9                   	leave  
80105e5e:	c3                   	ret    

80105e5f <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105e5f:	55                   	push   %ebp
80105e60:	89 e5                	mov    %esp,%ebp
80105e62:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105e65:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105e6c:	eb 4b                	jmp    80105eb9 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105e6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e71:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105e78:	00 
80105e79:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e7d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105e80:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e84:	8b 45 08             	mov    0x8(%ebp),%eax
80105e87:	89 04 24             	mov    %eax,(%esp)
80105e8a:	e8 e5 c3 ff ff       	call   80102274 <readi>
80105e8f:	83 f8 10             	cmp    $0x10,%eax
80105e92:	74 0c                	je     80105ea0 <isdirempty+0x41>
      panic("isdirempty: readi");
80105e94:	c7 04 24 67 8d 10 80 	movl   $0x80108d67,(%esp)
80105e9b:	e8 9a a6 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80105ea0:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105ea4:	66 85 c0             	test   %ax,%ax
80105ea7:	74 07                	je     80105eb0 <isdirempty+0x51>
      return 0;
80105ea9:	b8 00 00 00 00       	mov    $0x0,%eax
80105eae:	eb 1b                	jmp    80105ecb <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105eb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105eb3:	83 c0 10             	add    $0x10,%eax
80105eb6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105eb9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ebc:	8b 45 08             	mov    0x8(%ebp),%eax
80105ebf:	8b 40 18             	mov    0x18(%eax),%eax
80105ec2:	39 c2                	cmp    %eax,%edx
80105ec4:	72 a8                	jb     80105e6e <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105ec6:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105ecb:	c9                   	leave  
80105ecc:	c3                   	ret    

80105ecd <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105ecd:	55                   	push   %ebp
80105ece:	89 e5                	mov    %esp,%ebp
80105ed0:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105ed3:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105ed6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eda:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ee1:	e8 71 fa ff ff       	call   80105957 <argstr>
80105ee6:	85 c0                	test   %eax,%eax
80105ee8:	79 0a                	jns    80105ef4 <sys_unlink+0x27>
    return -1;
80105eea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eef:	e9 af 01 00 00       	jmp    801060a3 <sys_unlink+0x1d6>

  begin_op();
80105ef4:	e8 50 da ff ff       	call   80103949 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105ef9:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105efc:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105eff:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f03:	89 04 24             	mov    %eax,(%esp)
80105f06:	e8 29 ca ff ff       	call   80102934 <nameiparent>
80105f0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f0e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f12:	75 0f                	jne    80105f23 <sys_unlink+0x56>
    end_op();
80105f14:	e8 b4 da ff ff       	call   801039cd <end_op>
    return -1;
80105f19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f1e:	e9 80 01 00 00       	jmp    801060a3 <sys_unlink+0x1d6>
  }

  ilock(dp);
80105f23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f26:	89 04 24             	mov    %eax,(%esp)
80105f29:	e8 33 be ff ff       	call   80101d61 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105f2e:	c7 44 24 04 79 8d 10 	movl   $0x80108d79,0x4(%esp)
80105f35:	80 
80105f36:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105f39:	89 04 24             	mov    %eax,(%esp)
80105f3c:	e8 26 c6 ff ff       	call   80102567 <namecmp>
80105f41:	85 c0                	test   %eax,%eax
80105f43:	0f 84 45 01 00 00    	je     8010608e <sys_unlink+0x1c1>
80105f49:	c7 44 24 04 7b 8d 10 	movl   $0x80108d7b,0x4(%esp)
80105f50:	80 
80105f51:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105f54:	89 04 24             	mov    %eax,(%esp)
80105f57:	e8 0b c6 ff ff       	call   80102567 <namecmp>
80105f5c:	85 c0                	test   %eax,%eax
80105f5e:	0f 84 2a 01 00 00    	je     8010608e <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105f64:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105f67:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f6b:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105f6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f75:	89 04 24             	mov    %eax,(%esp)
80105f78:	e8 0c c6 ff ff       	call   80102589 <dirlookup>
80105f7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f84:	75 05                	jne    80105f8b <sys_unlink+0xbe>
    goto bad;
80105f86:	e9 03 01 00 00       	jmp    8010608e <sys_unlink+0x1c1>
  ilock(ip);
80105f8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f8e:	89 04 24             	mov    %eax,(%esp)
80105f91:	e8 cb bd ff ff       	call   80101d61 <ilock>

  if(ip->nlink < 1)
80105f96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f99:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105f9d:	66 85 c0             	test   %ax,%ax
80105fa0:	7f 0c                	jg     80105fae <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80105fa2:	c7 04 24 7e 8d 10 80 	movl   $0x80108d7e,(%esp)
80105fa9:	e8 8c a5 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105fae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105fb5:	66 83 f8 01          	cmp    $0x1,%ax
80105fb9:	75 1f                	jne    80105fda <sys_unlink+0x10d>
80105fbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fbe:	89 04 24             	mov    %eax,(%esp)
80105fc1:	e8 99 fe ff ff       	call   80105e5f <isdirempty>
80105fc6:	85 c0                	test   %eax,%eax
80105fc8:	75 10                	jne    80105fda <sys_unlink+0x10d>
    iunlockput(ip);
80105fca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fcd:	89 04 24             	mov    %eax,(%esp)
80105fd0:	e8 16 c0 ff ff       	call   80101feb <iunlockput>
    goto bad;
80105fd5:	e9 b4 00 00 00       	jmp    8010608e <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105fda:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105fe1:	00 
80105fe2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fe9:	00 
80105fea:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105fed:	89 04 24             	mov    %eax,(%esp)
80105ff0:	e8 90 f5 ff ff       	call   80105585 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105ff5:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105ff8:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105fff:	00 
80106000:	89 44 24 08          	mov    %eax,0x8(%esp)
80106004:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106007:	89 44 24 04          	mov    %eax,0x4(%esp)
8010600b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010600e:	89 04 24             	mov    %eax,(%esp)
80106011:	e8 c2 c3 ff ff       	call   801023d8 <writei>
80106016:	83 f8 10             	cmp    $0x10,%eax
80106019:	74 0c                	je     80106027 <sys_unlink+0x15a>
    panic("unlink: writei");
8010601b:	c7 04 24 90 8d 10 80 	movl   $0x80108d90,(%esp)
80106022:	e8 13 a5 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80106027:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010602a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010602e:	66 83 f8 01          	cmp    $0x1,%ax
80106032:	75 1c                	jne    80106050 <sys_unlink+0x183>
    dp->nlink--;
80106034:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106037:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010603b:	8d 50 ff             	lea    -0x1(%eax),%edx
8010603e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106041:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106045:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106048:	89 04 24             	mov    %eax,(%esp)
8010604b:	e8 4f bb ff ff       	call   80101b9f <iupdate>
  }
  iunlockput(dp);
80106050:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106053:	89 04 24             	mov    %eax,(%esp)
80106056:	e8 90 bf ff ff       	call   80101feb <iunlockput>

  ip->nlink--;
8010605b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010605e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106062:	8d 50 ff             	lea    -0x1(%eax),%edx
80106065:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106068:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010606c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010606f:	89 04 24             	mov    %eax,(%esp)
80106072:	e8 28 bb ff ff       	call   80101b9f <iupdate>
  iunlockput(ip);
80106077:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010607a:	89 04 24             	mov    %eax,(%esp)
8010607d:	e8 69 bf ff ff       	call   80101feb <iunlockput>

  end_op();
80106082:	e8 46 d9 ff ff       	call   801039cd <end_op>

  return 0;
80106087:	b8 00 00 00 00       	mov    $0x0,%eax
8010608c:	eb 15                	jmp    801060a3 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
8010608e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106091:	89 04 24             	mov    %eax,(%esp)
80106094:	e8 52 bf ff ff       	call   80101feb <iunlockput>
  end_op();
80106099:	e8 2f d9 ff ff       	call   801039cd <end_op>
  return -1;
8010609e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801060a3:	c9                   	leave  
801060a4:	c3                   	ret    

801060a5 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801060a5:	55                   	push   %ebp
801060a6:	89 e5                	mov    %esp,%ebp
801060a8:	83 ec 48             	sub    $0x48,%esp
801060ab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801060ae:	8b 55 10             	mov    0x10(%ebp),%edx
801060b1:	8b 45 14             	mov    0x14(%ebp),%eax
801060b4:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801060b8:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801060bc:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801060c0:	8d 45 de             	lea    -0x22(%ebp),%eax
801060c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801060c7:	8b 45 08             	mov    0x8(%ebp),%eax
801060ca:	89 04 24             	mov    %eax,(%esp)
801060cd:	e8 62 c8 ff ff       	call   80102934 <nameiparent>
801060d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060d5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060d9:	75 0a                	jne    801060e5 <create+0x40>
    return 0;
801060db:	b8 00 00 00 00       	mov    $0x0,%eax
801060e0:	e9 7e 01 00 00       	jmp    80106263 <create+0x1be>
  ilock(dp);
801060e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060e8:	89 04 24             	mov    %eax,(%esp)
801060eb:	e8 71 bc ff ff       	call   80101d61 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801060f0:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060f3:	89 44 24 08          	mov    %eax,0x8(%esp)
801060f7:	8d 45 de             	lea    -0x22(%ebp),%eax
801060fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801060fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106101:	89 04 24             	mov    %eax,(%esp)
80106104:	e8 80 c4 ff ff       	call   80102589 <dirlookup>
80106109:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010610c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106110:	74 47                	je     80106159 <create+0xb4>
    iunlockput(dp);
80106112:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106115:	89 04 24             	mov    %eax,(%esp)
80106118:	e8 ce be ff ff       	call   80101feb <iunlockput>
    ilock(ip);
8010611d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106120:	89 04 24             	mov    %eax,(%esp)
80106123:	e8 39 bc ff ff       	call   80101d61 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106128:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
8010612d:	75 15                	jne    80106144 <create+0x9f>
8010612f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106132:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106136:	66 83 f8 02          	cmp    $0x2,%ax
8010613a:	75 08                	jne    80106144 <create+0x9f>
      return ip;
8010613c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010613f:	e9 1f 01 00 00       	jmp    80106263 <create+0x1be>
    iunlockput(ip);
80106144:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106147:	89 04 24             	mov    %eax,(%esp)
8010614a:	e8 9c be ff ff       	call   80101feb <iunlockput>
    return 0;
8010614f:	b8 00 00 00 00       	mov    $0x0,%eax
80106154:	e9 0a 01 00 00       	jmp    80106263 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106159:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
8010615d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106160:	8b 00                	mov    (%eax),%eax
80106162:	89 54 24 04          	mov    %edx,0x4(%esp)
80106166:	89 04 24             	mov    %eax,(%esp)
80106169:	e8 5c b9 ff ff       	call   80101aca <ialloc>
8010616e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106171:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106175:	75 0c                	jne    80106183 <create+0xde>
    panic("create: ialloc");
80106177:	c7 04 24 9f 8d 10 80 	movl   $0x80108d9f,(%esp)
8010617e:	e8 b7 a3 ff ff       	call   8010053a <panic>

  ilock(ip);
80106183:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106186:	89 04 24             	mov    %eax,(%esp)
80106189:	e8 d3 bb ff ff       	call   80101d61 <ilock>
  ip->major = major;
8010618e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106191:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106195:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106199:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010619c:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801061a0:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801061a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061a7:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801061ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b0:	89 04 24             	mov    %eax,(%esp)
801061b3:	e8 e7 b9 ff ff       	call   80101b9f <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
801061b8:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
801061bd:	75 6a                	jne    80106229 <create+0x184>
    dp->nlink++;  // for ".."
801061bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061c2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801061c6:	8d 50 01             	lea    0x1(%eax),%edx
801061c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061cc:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801061d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061d3:	89 04 24             	mov    %eax,(%esp)
801061d6:	e8 c4 b9 ff ff       	call   80101b9f <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801061db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061de:	8b 40 04             	mov    0x4(%eax),%eax
801061e1:	89 44 24 08          	mov    %eax,0x8(%esp)
801061e5:	c7 44 24 04 79 8d 10 	movl   $0x80108d79,0x4(%esp)
801061ec:	80 
801061ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061f0:	89 04 24             	mov    %eax,(%esp)
801061f3:	e8 5a c4 ff ff       	call   80102652 <dirlink>
801061f8:	85 c0                	test   %eax,%eax
801061fa:	78 21                	js     8010621d <create+0x178>
801061fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ff:	8b 40 04             	mov    0x4(%eax),%eax
80106202:	89 44 24 08          	mov    %eax,0x8(%esp)
80106206:	c7 44 24 04 7b 8d 10 	movl   $0x80108d7b,0x4(%esp)
8010620d:	80 
8010620e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106211:	89 04 24             	mov    %eax,(%esp)
80106214:	e8 39 c4 ff ff       	call   80102652 <dirlink>
80106219:	85 c0                	test   %eax,%eax
8010621b:	79 0c                	jns    80106229 <create+0x184>
      panic("create dots");
8010621d:	c7 04 24 ae 8d 10 80 	movl   $0x80108dae,(%esp)
80106224:	e8 11 a3 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106229:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010622c:	8b 40 04             	mov    0x4(%eax),%eax
8010622f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106233:	8d 45 de             	lea    -0x22(%ebp),%eax
80106236:	89 44 24 04          	mov    %eax,0x4(%esp)
8010623a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010623d:	89 04 24             	mov    %eax,(%esp)
80106240:	e8 0d c4 ff ff       	call   80102652 <dirlink>
80106245:	85 c0                	test   %eax,%eax
80106247:	79 0c                	jns    80106255 <create+0x1b0>
    panic("create: dirlink");
80106249:	c7 04 24 ba 8d 10 80 	movl   $0x80108dba,(%esp)
80106250:	e8 e5 a2 ff ff       	call   8010053a <panic>

  iunlockput(dp);
80106255:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106258:	89 04 24             	mov    %eax,(%esp)
8010625b:	e8 8b bd ff ff       	call   80101feb <iunlockput>

  return ip;
80106260:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106263:	c9                   	leave  
80106264:	c3                   	ret    

80106265 <sys_open>:

int
sys_open(void)
{
80106265:	55                   	push   %ebp
80106266:	89 e5                	mov    %esp,%ebp
80106268:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
8010626b:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010626e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106272:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106279:	e8 d9 f6 ff ff       	call   80105957 <argstr>
8010627e:	85 c0                	test   %eax,%eax
80106280:	78 17                	js     80106299 <sys_open+0x34>
80106282:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106285:	89 44 24 04          	mov    %eax,0x4(%esp)
80106289:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106290:	e8 32 f6 ff ff       	call   801058c7 <argint>
80106295:	85 c0                	test   %eax,%eax
80106297:	79 0a                	jns    801062a3 <sys_open+0x3e>
    return -1;
80106299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010629e:	e9 5c 01 00 00       	jmp    801063ff <sys_open+0x19a>

  begin_op();
801062a3:	e8 a1 d6 ff ff       	call   80103949 <begin_op>

  if(omode & O_CREATE){
801062a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062ab:	25 00 02 00 00       	and    $0x200,%eax
801062b0:	85 c0                	test   %eax,%eax
801062b2:	74 3b                	je     801062ef <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
801062b4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801062b7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801062be:	00 
801062bf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801062c6:	00 
801062c7:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801062ce:	00 
801062cf:	89 04 24             	mov    %eax,(%esp)
801062d2:	e8 ce fd ff ff       	call   801060a5 <create>
801062d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
801062da:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801062de:	75 6b                	jne    8010634b <sys_open+0xe6>
      end_op();
801062e0:	e8 e8 d6 ff ff       	call   801039cd <end_op>
      return -1;
801062e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062ea:	e9 10 01 00 00       	jmp    801063ff <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
801062ef:	8b 45 e8             	mov    -0x18(%ebp),%eax
801062f2:	89 04 24             	mov    %eax,(%esp)
801062f5:	e8 18 c6 ff ff       	call   80102912 <namei>
801062fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801062fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106301:	75 0f                	jne    80106312 <sys_open+0xad>
      end_op();
80106303:	e8 c5 d6 ff ff       	call   801039cd <end_op>
      return -1;
80106308:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010630d:	e9 ed 00 00 00       	jmp    801063ff <sys_open+0x19a>
    }
    ilock(ip);
80106312:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106315:	89 04 24             	mov    %eax,(%esp)
80106318:	e8 44 ba ff ff       	call   80101d61 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010631d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106320:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106324:	66 83 f8 01          	cmp    $0x1,%ax
80106328:	75 21                	jne    8010634b <sys_open+0xe6>
8010632a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010632d:	85 c0                	test   %eax,%eax
8010632f:	74 1a                	je     8010634b <sys_open+0xe6>
      iunlockput(ip);
80106331:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106334:	89 04 24             	mov    %eax,(%esp)
80106337:	e8 af bc ff ff       	call   80101feb <iunlockput>
      end_op();
8010633c:	e8 8c d6 ff ff       	call   801039cd <end_op>
      return -1;
80106341:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106346:	e9 b4 00 00 00       	jmp    801063ff <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010634b:	e8 7e b0 ff ff       	call   801013ce <filealloc>
80106350:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106353:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106357:	74 14                	je     8010636d <sys_open+0x108>
80106359:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010635c:	89 04 24             	mov    %eax,(%esp)
8010635f:	e8 2e f7 ff ff       	call   80105a92 <fdalloc>
80106364:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106367:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010636b:	79 28                	jns    80106395 <sys_open+0x130>
    if(f)
8010636d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106371:	74 0b                	je     8010637e <sys_open+0x119>
      fileclose(f);
80106373:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106376:	89 04 24             	mov    %eax,(%esp)
80106379:	e8 f8 b0 ff ff       	call   80101476 <fileclose>
    iunlockput(ip);
8010637e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106381:	89 04 24             	mov    %eax,(%esp)
80106384:	e8 62 bc ff ff       	call   80101feb <iunlockput>
    end_op();
80106389:	e8 3f d6 ff ff       	call   801039cd <end_op>
    return -1;
8010638e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106393:	eb 6a                	jmp    801063ff <sys_open+0x19a>
  }
  iunlock(ip);
80106395:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106398:	89 04 24             	mov    %eax,(%esp)
8010639b:	e8 15 bb ff ff       	call   80101eb5 <iunlock>
  end_op();
801063a0:	e8 28 d6 ff ff       	call   801039cd <end_op>

  f->type = FD_INODE;
801063a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063a8:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801063ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063b4:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801063b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063ba:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801063c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063c4:	83 e0 01             	and    $0x1,%eax
801063c7:	85 c0                	test   %eax,%eax
801063c9:	0f 94 c0             	sete   %al
801063cc:	89 c2                	mov    %eax,%edx
801063ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063d1:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801063d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063d7:	83 e0 01             	and    $0x1,%eax
801063da:	85 c0                	test   %eax,%eax
801063dc:	75 0a                	jne    801063e8 <sys_open+0x183>
801063de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063e1:	83 e0 02             	and    $0x2,%eax
801063e4:	85 c0                	test   %eax,%eax
801063e6:	74 07                	je     801063ef <sys_open+0x18a>
801063e8:	b8 01 00 00 00       	mov    $0x1,%eax
801063ed:	eb 05                	jmp    801063f4 <sys_open+0x18f>
801063ef:	b8 00 00 00 00       	mov    $0x0,%eax
801063f4:	89 c2                	mov    %eax,%edx
801063f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063f9:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
801063fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
801063ff:	c9                   	leave  
80106400:	c3                   	ret    

80106401 <sys_mkdir>:

int
sys_mkdir(void)
{
80106401:	55                   	push   %ebp
80106402:	89 e5                	mov    %esp,%ebp
80106404:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106407:	e8 3d d5 ff ff       	call   80103949 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010640c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010640f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106413:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010641a:	e8 38 f5 ff ff       	call   80105957 <argstr>
8010641f:	85 c0                	test   %eax,%eax
80106421:	78 2c                	js     8010644f <sys_mkdir+0x4e>
80106423:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106426:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010642d:	00 
8010642e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106435:	00 
80106436:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010643d:	00 
8010643e:	89 04 24             	mov    %eax,(%esp)
80106441:	e8 5f fc ff ff       	call   801060a5 <create>
80106446:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106449:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010644d:	75 0c                	jne    8010645b <sys_mkdir+0x5a>
    end_op();
8010644f:	e8 79 d5 ff ff       	call   801039cd <end_op>
    return -1;
80106454:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106459:	eb 15                	jmp    80106470 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
8010645b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010645e:	89 04 24             	mov    %eax,(%esp)
80106461:	e8 85 bb ff ff       	call   80101feb <iunlockput>
  end_op();
80106466:	e8 62 d5 ff ff       	call   801039cd <end_op>
  return 0;
8010646b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106470:	c9                   	leave  
80106471:	c3                   	ret    

80106472 <sys_mknod>:

int
sys_mknod(void)
{
80106472:	55                   	push   %ebp
80106473:	89 e5                	mov    %esp,%ebp
80106475:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106478:	e8 cc d4 ff ff       	call   80103949 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
8010647d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106480:	89 44 24 04          	mov    %eax,0x4(%esp)
80106484:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010648b:	e8 c7 f4 ff ff       	call   80105957 <argstr>
80106490:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106493:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106497:	78 5e                	js     801064f7 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106499:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010649c:	89 44 24 04          	mov    %eax,0x4(%esp)
801064a0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801064a7:	e8 1b f4 ff ff       	call   801058c7 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
801064ac:	85 c0                	test   %eax,%eax
801064ae:	78 47                	js     801064f7 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801064b0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801064b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801064b7:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801064be:	e8 04 f4 ff ff       	call   801058c7 <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801064c3:	85 c0                	test   %eax,%eax
801064c5:	78 30                	js     801064f7 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801064c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801064ca:	0f bf c8             	movswl %ax,%ecx
801064cd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801064d0:	0f bf d0             	movswl %ax,%edx
801064d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801064d6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801064da:	89 54 24 08          	mov    %edx,0x8(%esp)
801064de:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801064e5:	00 
801064e6:	89 04 24             	mov    %eax,(%esp)
801064e9:	e8 b7 fb ff ff       	call   801060a5 <create>
801064ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
801064f1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064f5:	75 0c                	jne    80106503 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
801064f7:	e8 d1 d4 ff ff       	call   801039cd <end_op>
    return -1;
801064fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106501:	eb 15                	jmp    80106518 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106503:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106506:	89 04 24             	mov    %eax,(%esp)
80106509:	e8 dd ba ff ff       	call   80101feb <iunlockput>
  end_op();
8010650e:	e8 ba d4 ff ff       	call   801039cd <end_op>
  return 0;
80106513:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106518:	c9                   	leave  
80106519:	c3                   	ret    

8010651a <sys_chdir>:

int
sys_chdir(void)
{
8010651a:	55                   	push   %ebp
8010651b:	89 e5                	mov    %esp,%ebp
8010651d:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106520:	e8 24 d4 ff ff       	call   80103949 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106525:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106528:	89 44 24 04          	mov    %eax,0x4(%esp)
8010652c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106533:	e8 1f f4 ff ff       	call   80105957 <argstr>
80106538:	85 c0                	test   %eax,%eax
8010653a:	78 14                	js     80106550 <sys_chdir+0x36>
8010653c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010653f:	89 04 24             	mov    %eax,(%esp)
80106542:	e8 cb c3 ff ff       	call   80102912 <namei>
80106547:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010654a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010654e:	75 0c                	jne    8010655c <sys_chdir+0x42>
    end_op();
80106550:	e8 78 d4 ff ff       	call   801039cd <end_op>
    return -1;
80106555:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010655a:	eb 61                	jmp    801065bd <sys_chdir+0xa3>
  }
  ilock(ip);
8010655c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010655f:	89 04 24             	mov    %eax,(%esp)
80106562:	e8 fa b7 ff ff       	call   80101d61 <ilock>
  if(ip->type != T_DIR){
80106567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010656a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010656e:	66 83 f8 01          	cmp    $0x1,%ax
80106572:	74 17                	je     8010658b <sys_chdir+0x71>
    iunlockput(ip);
80106574:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106577:	89 04 24             	mov    %eax,(%esp)
8010657a:	e8 6c ba ff ff       	call   80101feb <iunlockput>
    end_op();
8010657f:	e8 49 d4 ff ff       	call   801039cd <end_op>
    return -1;
80106584:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106589:	eb 32                	jmp    801065bd <sys_chdir+0xa3>
  }
  iunlock(ip);
8010658b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010658e:	89 04 24             	mov    %eax,(%esp)
80106591:	e8 1f b9 ff ff       	call   80101eb5 <iunlock>
  iput(proc->cwd);
80106596:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010659c:	8b 40 68             	mov    0x68(%eax),%eax
8010659f:	89 04 24             	mov    %eax,(%esp)
801065a2:	e8 73 b9 ff ff       	call   80101f1a <iput>
  end_op();
801065a7:	e8 21 d4 ff ff       	call   801039cd <end_op>
  proc->cwd = ip;
801065ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065b5:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801065b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065bd:	c9                   	leave  
801065be:	c3                   	ret    

801065bf <sys_exec>:

int
sys_exec(void)
{
801065bf:	55                   	push   %ebp
801065c0:	89 e5                	mov    %esp,%ebp
801065c2:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801065c8:	8d 45 f0             	lea    -0x10(%ebp),%eax
801065cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801065cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065d6:	e8 7c f3 ff ff       	call   80105957 <argstr>
801065db:	85 c0                	test   %eax,%eax
801065dd:	78 1a                	js     801065f9 <sys_exec+0x3a>
801065df:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801065e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801065e9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065f0:	e8 d2 f2 ff ff       	call   801058c7 <argint>
801065f5:	85 c0                	test   %eax,%eax
801065f7:	79 0a                	jns    80106603 <sys_exec+0x44>
    return -1;
801065f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065fe:	e9 c8 00 00 00       	jmp    801066cb <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106603:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010660a:	00 
8010660b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106612:	00 
80106613:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106619:	89 04 24             	mov    %eax,(%esp)
8010661c:	e8 64 ef ff ff       	call   80105585 <memset>
  for(i=0;; i++){
80106621:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106628:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010662b:	83 f8 1f             	cmp    $0x1f,%eax
8010662e:	76 0a                	jbe    8010663a <sys_exec+0x7b>
      return -1;
80106630:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106635:	e9 91 00 00 00       	jmp    801066cb <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
8010663a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010663d:	c1 e0 02             	shl    $0x2,%eax
80106640:	89 c2                	mov    %eax,%edx
80106642:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106648:	01 c2                	add    %eax,%edx
8010664a:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106650:	89 44 24 04          	mov    %eax,0x4(%esp)
80106654:	89 14 24             	mov    %edx,(%esp)
80106657:	e8 cf f1 ff ff       	call   8010582b <fetchint>
8010665c:	85 c0                	test   %eax,%eax
8010665e:	79 07                	jns    80106667 <sys_exec+0xa8>
      return -1;
80106660:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106665:	eb 64                	jmp    801066cb <sys_exec+0x10c>
    if(uarg == 0){
80106667:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
8010666d:	85 c0                	test   %eax,%eax
8010666f:	75 26                	jne    80106697 <sys_exec+0xd8>
      argv[i] = 0;
80106671:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106674:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
8010667b:	00 00 00 00 
      break;
8010667f:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106680:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106683:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106689:	89 54 24 04          	mov    %edx,0x4(%esp)
8010668d:	89 04 24             	mov    %eax,(%esp)
80106690:	e8 02 a9 ff ff       	call   80100f97 <exec>
80106695:	eb 34                	jmp    801066cb <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106697:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010669d:	8b 55 f4             	mov    -0xc(%ebp),%edx
801066a0:	c1 e2 02             	shl    $0x2,%edx
801066a3:	01 c2                	add    %eax,%edx
801066a5:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801066ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801066af:	89 04 24             	mov    %eax,(%esp)
801066b2:	e8 ae f1 ff ff       	call   80105865 <fetchstr>
801066b7:	85 c0                	test   %eax,%eax
801066b9:	79 07                	jns    801066c2 <sys_exec+0x103>
      return -1;
801066bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066c0:	eb 09                	jmp    801066cb <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801066c2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
801066c6:	e9 5d ff ff ff       	jmp    80106628 <sys_exec+0x69>
  return exec(path, argv);
}
801066cb:	c9                   	leave  
801066cc:	c3                   	ret    

801066cd <sys_pipe>:

int
sys_pipe(void)
{
801066cd:	55                   	push   %ebp
801066ce:	89 e5                	mov    %esp,%ebp
801066d0:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801066d3:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801066da:	00 
801066db:	8d 45 ec             	lea    -0x14(%ebp),%eax
801066de:	89 44 24 04          	mov    %eax,0x4(%esp)
801066e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066e9:	e8 07 f2 ff ff       	call   801058f5 <argptr>
801066ee:	85 c0                	test   %eax,%eax
801066f0:	79 0a                	jns    801066fc <sys_pipe+0x2f>
    return -1;
801066f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066f7:	e9 9b 00 00 00       	jmp    80106797 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801066fc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801066ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80106703:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106706:	89 04 24             	mov    %eax,(%esp)
80106709:	e8 47 dd ff ff       	call   80104455 <pipealloc>
8010670e:	85 c0                	test   %eax,%eax
80106710:	79 07                	jns    80106719 <sys_pipe+0x4c>
    return -1;
80106712:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106717:	eb 7e                	jmp    80106797 <sys_pipe+0xca>
  fd0 = -1;
80106719:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106720:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106723:	89 04 24             	mov    %eax,(%esp)
80106726:	e8 67 f3 ff ff       	call   80105a92 <fdalloc>
8010672b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010672e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106732:	78 14                	js     80106748 <sys_pipe+0x7b>
80106734:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106737:	89 04 24             	mov    %eax,(%esp)
8010673a:	e8 53 f3 ff ff       	call   80105a92 <fdalloc>
8010673f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106742:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106746:	79 37                	jns    8010677f <sys_pipe+0xb2>
    if(fd0 >= 0)
80106748:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010674c:	78 14                	js     80106762 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
8010674e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106754:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106757:	83 c2 08             	add    $0x8,%edx
8010675a:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106761:	00 
    fileclose(rf);
80106762:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106765:	89 04 24             	mov    %eax,(%esp)
80106768:	e8 09 ad ff ff       	call   80101476 <fileclose>
    fileclose(wf);
8010676d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106770:	89 04 24             	mov    %eax,(%esp)
80106773:	e8 fe ac ff ff       	call   80101476 <fileclose>
    return -1;
80106778:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010677d:	eb 18                	jmp    80106797 <sys_pipe+0xca>
  }
  fd[0] = fd0;
8010677f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106782:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106785:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106787:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010678a:	8d 50 04             	lea    0x4(%eax),%edx
8010678d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106790:	89 02                	mov    %eax,(%edx)
  return 0;
80106792:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106797:	c9                   	leave  
80106798:	c3                   	ret    

80106799 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106799:	55                   	push   %ebp
8010679a:	89 e5                	mov    %esp,%ebp
8010679c:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010679f:	e8 5c e3 ff ff       	call   80104b00 <fork>
}
801067a4:	c9                   	leave  
801067a5:	c3                   	ret    

801067a6 <sys_exit>:

int
sys_exit(void)
{
801067a6:	55                   	push   %ebp
801067a7:	89 e5                	mov    %esp,%ebp
801067a9:	83 ec 08             	sub    $0x8,%esp
  exit();
801067ac:	e8 ca e4 ff ff       	call   80104c7b <exit>
  return 0;  // not reached
801067b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801067b6:	c9                   	leave  
801067b7:	c3                   	ret    

801067b8 <sys_wait>:

int
sys_wait(void)
{
801067b8:	55                   	push   %ebp
801067b9:	89 e5                	mov    %esp,%ebp
801067bb:	83 ec 08             	sub    $0x8,%esp
  return wait();
801067be:	e8 da e5 ff ff       	call   80104d9d <wait>
}
801067c3:	c9                   	leave  
801067c4:	c3                   	ret    

801067c5 <sys_kill>:

int
sys_kill(void)
{
801067c5:	55                   	push   %ebp
801067c6:	89 e5                	mov    %esp,%ebp
801067c8:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801067cb:	8d 45 f4             	lea    -0xc(%ebp),%eax
801067ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801067d2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067d9:	e8 e9 f0 ff ff       	call   801058c7 <argint>
801067de:	85 c0                	test   %eax,%eax
801067e0:	79 07                	jns    801067e9 <sys_kill+0x24>
    return -1;
801067e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067e7:	eb 0b                	jmp    801067f4 <sys_kill+0x2f>
  return kill(pid);
801067e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ec:	89 04 24             	mov    %eax,(%esp)
801067ef:	e8 77 e9 ff ff       	call   8010516b <kill>
}
801067f4:	c9                   	leave  
801067f5:	c3                   	ret    

801067f6 <sys_getpid>:

int
sys_getpid(void)
{
801067f6:	55                   	push   %ebp
801067f7:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801067f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067ff:	8b 40 10             	mov    0x10(%eax),%eax
}
80106802:	5d                   	pop    %ebp
80106803:	c3                   	ret    

80106804 <sys_sbrk>:

int
sys_sbrk(void)
{
80106804:	55                   	push   %ebp
80106805:	89 e5                	mov    %esp,%ebp
80106807:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
8010680a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010680d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106811:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106818:	e8 aa f0 ff ff       	call   801058c7 <argint>
8010681d:	85 c0                	test   %eax,%eax
8010681f:	79 07                	jns    80106828 <sys_sbrk+0x24>
    return -1;
80106821:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106826:	eb 24                	jmp    8010684c <sys_sbrk+0x48>
  addr = proc->sz;
80106828:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010682e:	8b 00                	mov    (%eax),%eax
80106830:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106833:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106836:	89 04 24             	mov    %eax,(%esp)
80106839:	e8 1d e2 ff ff       	call   80104a5b <growproc>
8010683e:	85 c0                	test   %eax,%eax
80106840:	79 07                	jns    80106849 <sys_sbrk+0x45>
    return -1;
80106842:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106847:	eb 03                	jmp    8010684c <sys_sbrk+0x48>
  return addr;
80106849:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010684c:	c9                   	leave  
8010684d:	c3                   	ret    

8010684e <sys_sleep>:

int
sys_sleep(void)
{
8010684e:	55                   	push   %ebp
8010684f:	89 e5                	mov    %esp,%ebp
80106851:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106854:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106857:	89 44 24 04          	mov    %eax,0x4(%esp)
8010685b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106862:	e8 60 f0 ff ff       	call   801058c7 <argint>
80106867:	85 c0                	test   %eax,%eax
80106869:	79 07                	jns    80106872 <sys_sleep+0x24>
    return -1;
8010686b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106870:	eb 6c                	jmp    801068de <sys_sleep+0x90>
  acquire(&tickslock);
80106872:	c7 04 24 00 51 11 80 	movl   $0x80115100,(%esp)
80106879:	e8 b3 ea ff ff       	call   80105331 <acquire>
  ticks0 = ticks;
8010687e:	a1 40 59 11 80       	mov    0x80115940,%eax
80106883:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106886:	eb 34                	jmp    801068bc <sys_sleep+0x6e>
    if(proc->killed){
80106888:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010688e:	8b 40 24             	mov    0x24(%eax),%eax
80106891:	85 c0                	test   %eax,%eax
80106893:	74 13                	je     801068a8 <sys_sleep+0x5a>
      release(&tickslock);
80106895:	c7 04 24 00 51 11 80 	movl   $0x80115100,(%esp)
8010689c:	e8 f2 ea ff ff       	call   80105393 <release>
      return -1;
801068a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068a6:	eb 36                	jmp    801068de <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801068a8:	c7 44 24 04 00 51 11 	movl   $0x80115100,0x4(%esp)
801068af:	80 
801068b0:	c7 04 24 40 59 11 80 	movl   $0x80115940,(%esp)
801068b7:	e8 ab e7 ff ff       	call   80105067 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801068bc:	a1 40 59 11 80       	mov    0x80115940,%eax
801068c1:	2b 45 f4             	sub    -0xc(%ebp),%eax
801068c4:	89 c2                	mov    %eax,%edx
801068c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068c9:	39 c2                	cmp    %eax,%edx
801068cb:	72 bb                	jb     80106888 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801068cd:	c7 04 24 00 51 11 80 	movl   $0x80115100,(%esp)
801068d4:	e8 ba ea ff ff       	call   80105393 <release>
  return 0;
801068d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068de:	c9                   	leave  
801068df:	c3                   	ret    

801068e0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801068e0:	55                   	push   %ebp
801068e1:	89 e5                	mov    %esp,%ebp
801068e3:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801068e6:	c7 04 24 00 51 11 80 	movl   $0x80115100,(%esp)
801068ed:	e8 3f ea ff ff       	call   80105331 <acquire>
  xticks = ticks;
801068f2:	a1 40 59 11 80       	mov    0x80115940,%eax
801068f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801068fa:	c7 04 24 00 51 11 80 	movl   $0x80115100,(%esp)
80106901:	e8 8d ea ff ff       	call   80105393 <release>
  return xticks;
80106906:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106909:	c9                   	leave  
8010690a:	c3                   	ret    

8010690b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010690b:	55                   	push   %ebp
8010690c:	89 e5                	mov    %esp,%ebp
8010690e:	83 ec 08             	sub    $0x8,%esp
80106911:	8b 55 08             	mov    0x8(%ebp),%edx
80106914:	8b 45 0c             	mov    0xc(%ebp),%eax
80106917:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010691b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010691e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106922:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106926:	ee                   	out    %al,(%dx)
}
80106927:	c9                   	leave  
80106928:	c3                   	ret    

80106929 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106929:	55                   	push   %ebp
8010692a:	89 e5                	mov    %esp,%ebp
8010692c:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
8010692f:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106936:	00 
80106937:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010693e:	e8 c8 ff ff ff       	call   8010690b <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106943:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010694a:	00 
8010694b:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106952:	e8 b4 ff ff ff       	call   8010690b <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106957:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
8010695e:	00 
8010695f:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106966:	e8 a0 ff ff ff       	call   8010690b <outb>
  picenable(IRQ_TIMER);
8010696b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106972:	e8 71 d9 ff ff       	call   801042e8 <picenable>
}
80106977:	c9                   	leave  
80106978:	c3                   	ret    

80106979 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106979:	1e                   	push   %ds
  pushl %es
8010697a:	06                   	push   %es
  pushl %fs
8010697b:	0f a0                	push   %fs
  pushl %gs
8010697d:	0f a8                	push   %gs
  pushal
8010697f:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106980:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106984:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106986:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106988:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010698c:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
8010698e:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106990:	54                   	push   %esp
  call trap
80106991:	e8 d8 01 00 00       	call   80106b6e <trap>
  addl $4, %esp
80106996:	83 c4 04             	add    $0x4,%esp

80106999 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106999:	61                   	popa   
  popl %gs
8010699a:	0f a9                	pop    %gs
  popl %fs
8010699c:	0f a1                	pop    %fs
  popl %es
8010699e:	07                   	pop    %es
  popl %ds
8010699f:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801069a0:	83 c4 08             	add    $0x8,%esp
  iret
801069a3:	cf                   	iret   

801069a4 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801069a4:	55                   	push   %ebp
801069a5:	89 e5                	mov    %esp,%ebp
801069a7:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801069aa:	8b 45 0c             	mov    0xc(%ebp),%eax
801069ad:	83 e8 01             	sub    $0x1,%eax
801069b0:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801069b4:	8b 45 08             	mov    0x8(%ebp),%eax
801069b7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801069bb:	8b 45 08             	mov    0x8(%ebp),%eax
801069be:	c1 e8 10             	shr    $0x10,%eax
801069c1:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801069c5:	8d 45 fa             	lea    -0x6(%ebp),%eax
801069c8:	0f 01 18             	lidtl  (%eax)
}
801069cb:	c9                   	leave  
801069cc:	c3                   	ret    

801069cd <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801069cd:	55                   	push   %ebp
801069ce:	89 e5                	mov    %esp,%ebp
801069d0:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801069d3:	0f 20 d0             	mov    %cr2,%eax
801069d6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
801069d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801069dc:	c9                   	leave  
801069dd:	c3                   	ret    

801069de <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801069de:	55                   	push   %ebp
801069df:	89 e5                	mov    %esp,%ebp
801069e1:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801069e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801069eb:	e9 c3 00 00 00       	jmp    80106ab3 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801069f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069f3:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
801069fa:	89 c2                	mov    %eax,%edx
801069fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ff:	66 89 14 c5 40 51 11 	mov    %dx,-0x7feeaec0(,%eax,8)
80106a06:	80 
80106a07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a0a:	66 c7 04 c5 42 51 11 	movw   $0x8,-0x7feeaebe(,%eax,8)
80106a11:	80 08 00 
80106a14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a17:	0f b6 14 c5 44 51 11 	movzbl -0x7feeaebc(,%eax,8),%edx
80106a1e:	80 
80106a1f:	83 e2 e0             	and    $0xffffffe0,%edx
80106a22:	88 14 c5 44 51 11 80 	mov    %dl,-0x7feeaebc(,%eax,8)
80106a29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a2c:	0f b6 14 c5 44 51 11 	movzbl -0x7feeaebc(,%eax,8),%edx
80106a33:	80 
80106a34:	83 e2 1f             	and    $0x1f,%edx
80106a37:	88 14 c5 44 51 11 80 	mov    %dl,-0x7feeaebc(,%eax,8)
80106a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a41:	0f b6 14 c5 45 51 11 	movzbl -0x7feeaebb(,%eax,8),%edx
80106a48:	80 
80106a49:	83 e2 f0             	and    $0xfffffff0,%edx
80106a4c:	83 ca 0e             	or     $0xe,%edx
80106a4f:	88 14 c5 45 51 11 80 	mov    %dl,-0x7feeaebb(,%eax,8)
80106a56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a59:	0f b6 14 c5 45 51 11 	movzbl -0x7feeaebb(,%eax,8),%edx
80106a60:	80 
80106a61:	83 e2 ef             	and    $0xffffffef,%edx
80106a64:	88 14 c5 45 51 11 80 	mov    %dl,-0x7feeaebb(,%eax,8)
80106a6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a6e:	0f b6 14 c5 45 51 11 	movzbl -0x7feeaebb(,%eax,8),%edx
80106a75:	80 
80106a76:	83 e2 9f             	and    $0xffffff9f,%edx
80106a79:	88 14 c5 45 51 11 80 	mov    %dl,-0x7feeaebb(,%eax,8)
80106a80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a83:	0f b6 14 c5 45 51 11 	movzbl -0x7feeaebb(,%eax,8),%edx
80106a8a:	80 
80106a8b:	83 ca 80             	or     $0xffffff80,%edx
80106a8e:	88 14 c5 45 51 11 80 	mov    %dl,-0x7feeaebb(,%eax,8)
80106a95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a98:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106a9f:	c1 e8 10             	shr    $0x10,%eax
80106aa2:	89 c2                	mov    %eax,%edx
80106aa4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa7:	66 89 14 c5 46 51 11 	mov    %dx,-0x7feeaeba(,%eax,8)
80106aae:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106aaf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106ab3:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106aba:	0f 8e 30 ff ff ff    	jle    801069f0 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106ac0:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106ac5:	66 a3 40 53 11 80    	mov    %ax,0x80115340
80106acb:	66 c7 05 42 53 11 80 	movw   $0x8,0x80115342
80106ad2:	08 00 
80106ad4:	0f b6 05 44 53 11 80 	movzbl 0x80115344,%eax
80106adb:	83 e0 e0             	and    $0xffffffe0,%eax
80106ade:	a2 44 53 11 80       	mov    %al,0x80115344
80106ae3:	0f b6 05 44 53 11 80 	movzbl 0x80115344,%eax
80106aea:	83 e0 1f             	and    $0x1f,%eax
80106aed:	a2 44 53 11 80       	mov    %al,0x80115344
80106af2:	0f b6 05 45 53 11 80 	movzbl 0x80115345,%eax
80106af9:	83 c8 0f             	or     $0xf,%eax
80106afc:	a2 45 53 11 80       	mov    %al,0x80115345
80106b01:	0f b6 05 45 53 11 80 	movzbl 0x80115345,%eax
80106b08:	83 e0 ef             	and    $0xffffffef,%eax
80106b0b:	a2 45 53 11 80       	mov    %al,0x80115345
80106b10:	0f b6 05 45 53 11 80 	movzbl 0x80115345,%eax
80106b17:	83 c8 60             	or     $0x60,%eax
80106b1a:	a2 45 53 11 80       	mov    %al,0x80115345
80106b1f:	0f b6 05 45 53 11 80 	movzbl 0x80115345,%eax
80106b26:	83 c8 80             	or     $0xffffff80,%eax
80106b29:	a2 45 53 11 80       	mov    %al,0x80115345
80106b2e:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106b33:	c1 e8 10             	shr    $0x10,%eax
80106b36:	66 a3 46 53 11 80    	mov    %ax,0x80115346
  
  initlock(&tickslock, "time");
80106b3c:	c7 44 24 04 cc 8d 10 	movl   $0x80108dcc,0x4(%esp)
80106b43:	80 
80106b44:	c7 04 24 00 51 11 80 	movl   $0x80115100,(%esp)
80106b4b:	e8 c0 e7 ff ff       	call   80105310 <initlock>
}
80106b50:	c9                   	leave  
80106b51:	c3                   	ret    

80106b52 <idtinit>:

void
idtinit(void)
{
80106b52:	55                   	push   %ebp
80106b53:	89 e5                	mov    %esp,%ebp
80106b55:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106b58:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106b5f:	00 
80106b60:	c7 04 24 40 51 11 80 	movl   $0x80115140,(%esp)
80106b67:	e8 38 fe ff ff       	call   801069a4 <lidt>
}
80106b6c:	c9                   	leave  
80106b6d:	c3                   	ret    

80106b6e <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106b6e:	55                   	push   %ebp
80106b6f:	89 e5                	mov    %esp,%ebp
80106b71:	57                   	push   %edi
80106b72:	56                   	push   %esi
80106b73:	53                   	push   %ebx
80106b74:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106b77:	8b 45 08             	mov    0x8(%ebp),%eax
80106b7a:	8b 40 30             	mov    0x30(%eax),%eax
80106b7d:	83 f8 40             	cmp    $0x40,%eax
80106b80:	75 3f                	jne    80106bc1 <trap+0x53>
    if(proc->killed)
80106b82:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b88:	8b 40 24             	mov    0x24(%eax),%eax
80106b8b:	85 c0                	test   %eax,%eax
80106b8d:	74 05                	je     80106b94 <trap+0x26>
      exit();
80106b8f:	e8 e7 e0 ff ff       	call   80104c7b <exit>
    proc->tf = tf;
80106b94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b9a:	8b 55 08             	mov    0x8(%ebp),%edx
80106b9d:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106ba0:	e8 e9 ed ff ff       	call   8010598e <syscall>
    if(proc->killed)
80106ba5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bab:	8b 40 24             	mov    0x24(%eax),%eax
80106bae:	85 c0                	test   %eax,%eax
80106bb0:	74 0a                	je     80106bbc <trap+0x4e>
      exit();
80106bb2:	e8 c4 e0 ff ff       	call   80104c7b <exit>
    return;
80106bb7:	e9 2d 02 00 00       	jmp    80106de9 <trap+0x27b>
80106bbc:	e9 28 02 00 00       	jmp    80106de9 <trap+0x27b>
  }

  switch(tf->trapno){
80106bc1:	8b 45 08             	mov    0x8(%ebp),%eax
80106bc4:	8b 40 30             	mov    0x30(%eax),%eax
80106bc7:	83 e8 20             	sub    $0x20,%eax
80106bca:	83 f8 1f             	cmp    $0x1f,%eax
80106bcd:	0f 87 bc 00 00 00    	ja     80106c8f <trap+0x121>
80106bd3:	8b 04 85 74 8e 10 80 	mov    -0x7fef718c(,%eax,4),%eax
80106bda:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106bdc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106be2:	0f b6 00             	movzbl (%eax),%eax
80106be5:	84 c0                	test   %al,%al
80106be7:	75 31                	jne    80106c1a <trap+0xac>
      acquire(&tickslock);
80106be9:	c7 04 24 00 51 11 80 	movl   $0x80115100,(%esp)
80106bf0:	e8 3c e7 ff ff       	call   80105331 <acquire>
      ticks++;
80106bf5:	a1 40 59 11 80       	mov    0x80115940,%eax
80106bfa:	83 c0 01             	add    $0x1,%eax
80106bfd:	a3 40 59 11 80       	mov    %eax,0x80115940
      wakeup(&ticks);
80106c02:	c7 04 24 40 59 11 80 	movl   $0x80115940,(%esp)
80106c09:	e8 32 e5 ff ff       	call   80105140 <wakeup>
      release(&tickslock);
80106c0e:	c7 04 24 00 51 11 80 	movl   $0x80115100,(%esp)
80106c15:	e8 79 e7 ff ff       	call   80105393 <release>
    }
    lapiceoi();
80106c1a:	e8 f4 c7 ff ff       	call   80103413 <lapiceoi>
    break;
80106c1f:	e9 41 01 00 00       	jmp    80106d65 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106c24:	e8 f8 bf ff ff       	call   80102c21 <ideintr>
    lapiceoi();
80106c29:	e8 e5 c7 ff ff       	call   80103413 <lapiceoi>
    break;
80106c2e:	e9 32 01 00 00       	jmp    80106d65 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106c33:	e8 aa c5 ff ff       	call   801031e2 <kbdintr>
    lapiceoi();
80106c38:	e8 d6 c7 ff ff       	call   80103413 <lapiceoi>
    break;
80106c3d:	e9 23 01 00 00       	jmp    80106d65 <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106c42:	e8 97 03 00 00       	call   80106fde <uartintr>
    lapiceoi();
80106c47:	e8 c7 c7 ff ff       	call   80103413 <lapiceoi>
    break;
80106c4c:	e9 14 01 00 00       	jmp    80106d65 <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106c51:	8b 45 08             	mov    0x8(%ebp),%eax
80106c54:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106c57:	8b 45 08             	mov    0x8(%ebp),%eax
80106c5a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106c5e:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106c61:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106c67:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106c6a:	0f b6 c0             	movzbl %al,%eax
80106c6d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106c71:	89 54 24 08          	mov    %edx,0x8(%esp)
80106c75:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c79:	c7 04 24 d4 8d 10 80 	movl   $0x80108dd4,(%esp)
80106c80:	e8 1b 97 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106c85:	e8 89 c7 ff ff       	call   80103413 <lapiceoi>
    break;
80106c8a:	e9 d6 00 00 00       	jmp    80106d65 <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106c8f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c95:	85 c0                	test   %eax,%eax
80106c97:	74 11                	je     80106caa <trap+0x13c>
80106c99:	8b 45 08             	mov    0x8(%ebp),%eax
80106c9c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106ca0:	0f b7 c0             	movzwl %ax,%eax
80106ca3:	83 e0 03             	and    $0x3,%eax
80106ca6:	85 c0                	test   %eax,%eax
80106ca8:	75 46                	jne    80106cf0 <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106caa:	e8 1e fd ff ff       	call   801069cd <rcr2>
80106caf:	8b 55 08             	mov    0x8(%ebp),%edx
80106cb2:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106cb5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106cbc:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106cbf:	0f b6 ca             	movzbl %dl,%ecx
80106cc2:	8b 55 08             	mov    0x8(%ebp),%edx
80106cc5:	8b 52 30             	mov    0x30(%edx),%edx
80106cc8:	89 44 24 10          	mov    %eax,0x10(%esp)
80106ccc:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106cd0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106cd4:	89 54 24 04          	mov    %edx,0x4(%esp)
80106cd8:	c7 04 24 f8 8d 10 80 	movl   $0x80108df8,(%esp)
80106cdf:	e8 bc 96 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106ce4:	c7 04 24 2a 8e 10 80 	movl   $0x80108e2a,(%esp)
80106ceb:	e8 4a 98 ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106cf0:	e8 d8 fc ff ff       	call   801069cd <rcr2>
80106cf5:	89 c2                	mov    %eax,%edx
80106cf7:	8b 45 08             	mov    0x8(%ebp),%eax
80106cfa:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106cfd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106d03:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106d06:	0f b6 f0             	movzbl %al,%esi
80106d09:	8b 45 08             	mov    0x8(%ebp),%eax
80106d0c:	8b 58 34             	mov    0x34(%eax),%ebx
80106d0f:	8b 45 08             	mov    0x8(%ebp),%eax
80106d12:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106d15:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d1b:	83 c0 6c             	add    $0x6c,%eax
80106d1e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106d21:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106d27:	8b 40 10             	mov    0x10(%eax),%eax
80106d2a:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106d2e:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106d32:	89 74 24 14          	mov    %esi,0x14(%esp)
80106d36:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106d3a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106d3e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
80106d41:	89 74 24 08          	mov    %esi,0x8(%esp)
80106d45:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d49:	c7 04 24 30 8e 10 80 	movl   $0x80108e30,(%esp)
80106d50:	e8 4b 96 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106d55:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d5b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106d62:	eb 01                	jmp    80106d65 <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106d64:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106d65:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d6b:	85 c0                	test   %eax,%eax
80106d6d:	74 24                	je     80106d93 <trap+0x225>
80106d6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d75:	8b 40 24             	mov    0x24(%eax),%eax
80106d78:	85 c0                	test   %eax,%eax
80106d7a:	74 17                	je     80106d93 <trap+0x225>
80106d7c:	8b 45 08             	mov    0x8(%ebp),%eax
80106d7f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106d83:	0f b7 c0             	movzwl %ax,%eax
80106d86:	83 e0 03             	and    $0x3,%eax
80106d89:	83 f8 03             	cmp    $0x3,%eax
80106d8c:	75 05                	jne    80106d93 <trap+0x225>
    exit();
80106d8e:	e8 e8 de ff ff       	call   80104c7b <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106d93:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d99:	85 c0                	test   %eax,%eax
80106d9b:	74 1e                	je     80106dbb <trap+0x24d>
80106d9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106da3:	8b 40 0c             	mov    0xc(%eax),%eax
80106da6:	83 f8 04             	cmp    $0x4,%eax
80106da9:	75 10                	jne    80106dbb <trap+0x24d>
80106dab:	8b 45 08             	mov    0x8(%ebp),%eax
80106dae:	8b 40 30             	mov    0x30(%eax),%eax
80106db1:	83 f8 20             	cmp    $0x20,%eax
80106db4:	75 05                	jne    80106dbb <trap+0x24d>
    yield();
80106db6:	e8 3b e2 ff ff       	call   80104ff6 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106dbb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106dc1:	85 c0                	test   %eax,%eax
80106dc3:	74 24                	je     80106de9 <trap+0x27b>
80106dc5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106dcb:	8b 40 24             	mov    0x24(%eax),%eax
80106dce:	85 c0                	test   %eax,%eax
80106dd0:	74 17                	je     80106de9 <trap+0x27b>
80106dd2:	8b 45 08             	mov    0x8(%ebp),%eax
80106dd5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106dd9:	0f b7 c0             	movzwl %ax,%eax
80106ddc:	83 e0 03             	and    $0x3,%eax
80106ddf:	83 f8 03             	cmp    $0x3,%eax
80106de2:	75 05                	jne    80106de9 <trap+0x27b>
    exit();
80106de4:	e8 92 de ff ff       	call   80104c7b <exit>
}
80106de9:	83 c4 3c             	add    $0x3c,%esp
80106dec:	5b                   	pop    %ebx
80106ded:	5e                   	pop    %esi
80106dee:	5f                   	pop    %edi
80106def:	5d                   	pop    %ebp
80106df0:	c3                   	ret    

80106df1 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106df1:	55                   	push   %ebp
80106df2:	89 e5                	mov    %esp,%ebp
80106df4:	83 ec 14             	sub    $0x14,%esp
80106df7:	8b 45 08             	mov    0x8(%ebp),%eax
80106dfa:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106dfe:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80106e02:	89 c2                	mov    %eax,%edx
80106e04:	ec                   	in     (%dx),%al
80106e05:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80106e08:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80106e0c:	c9                   	leave  
80106e0d:	c3                   	ret    

80106e0e <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106e0e:	55                   	push   %ebp
80106e0f:	89 e5                	mov    %esp,%ebp
80106e11:	83 ec 08             	sub    $0x8,%esp
80106e14:	8b 55 08             	mov    0x8(%ebp),%edx
80106e17:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e1a:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106e1e:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106e21:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106e25:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106e29:	ee                   	out    %al,(%dx)
}
80106e2a:	c9                   	leave  
80106e2b:	c3                   	ret    

80106e2c <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106e2c:	55                   	push   %ebp
80106e2d:	89 e5                	mov    %esp,%ebp
80106e2f:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106e32:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e39:	00 
80106e3a:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106e41:	e8 c8 ff ff ff       	call   80106e0e <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106e46:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106e4d:	00 
80106e4e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106e55:	e8 b4 ff ff ff       	call   80106e0e <outb>
  outb(COM1+0, 115200/9600);
80106e5a:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106e61:	00 
80106e62:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106e69:	e8 a0 ff ff ff       	call   80106e0e <outb>
  outb(COM1+1, 0);
80106e6e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e75:	00 
80106e76:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106e7d:	e8 8c ff ff ff       	call   80106e0e <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106e82:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106e89:	00 
80106e8a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106e91:	e8 78 ff ff ff       	call   80106e0e <outb>
  outb(COM1+4, 0);
80106e96:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e9d:	00 
80106e9e:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106ea5:	e8 64 ff ff ff       	call   80106e0e <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106eaa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106eb1:	00 
80106eb2:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106eb9:	e8 50 ff ff ff       	call   80106e0e <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106ebe:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106ec5:	e8 27 ff ff ff       	call   80106df1 <inb>
80106eca:	3c ff                	cmp    $0xff,%al
80106ecc:	75 02                	jne    80106ed0 <uartinit+0xa4>
    return;
80106ece:	eb 6a                	jmp    80106f3a <uartinit+0x10e>
  uart = 1;
80106ed0:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106ed7:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106eda:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106ee1:	e8 0b ff ff ff       	call   80106df1 <inb>
  inb(COM1+0);
80106ee6:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106eed:	e8 ff fe ff ff       	call   80106df1 <inb>
  picenable(IRQ_COM1);
80106ef2:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106ef9:	e8 ea d3 ff ff       	call   801042e8 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106efe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106f05:	00 
80106f06:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106f0d:	e8 8e bf ff ff       	call   80102ea0 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106f12:	c7 45 f4 f4 8e 10 80 	movl   $0x80108ef4,-0xc(%ebp)
80106f19:	eb 15                	jmp    80106f30 <uartinit+0x104>
    uartputc(*p);
80106f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f1e:	0f b6 00             	movzbl (%eax),%eax
80106f21:	0f be c0             	movsbl %al,%eax
80106f24:	89 04 24             	mov    %eax,(%esp)
80106f27:	e8 10 00 00 00       	call   80106f3c <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106f2c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f33:	0f b6 00             	movzbl (%eax),%eax
80106f36:	84 c0                	test   %al,%al
80106f38:	75 e1                	jne    80106f1b <uartinit+0xef>
    uartputc(*p);
}
80106f3a:	c9                   	leave  
80106f3b:	c3                   	ret    

80106f3c <uartputc>:

void
uartputc(int c)
{
80106f3c:	55                   	push   %ebp
80106f3d:	89 e5                	mov    %esp,%ebp
80106f3f:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106f42:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106f47:	85 c0                	test   %eax,%eax
80106f49:	75 02                	jne    80106f4d <uartputc+0x11>
    return;
80106f4b:	eb 4b                	jmp    80106f98 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106f4d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106f54:	eb 10                	jmp    80106f66 <uartputc+0x2a>
    microdelay(10);
80106f56:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106f5d:	e8 d6 c4 ff ff       	call   80103438 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106f62:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f66:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106f6a:	7f 16                	jg     80106f82 <uartputc+0x46>
80106f6c:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106f73:	e8 79 fe ff ff       	call   80106df1 <inb>
80106f78:	0f b6 c0             	movzbl %al,%eax
80106f7b:	83 e0 20             	and    $0x20,%eax
80106f7e:	85 c0                	test   %eax,%eax
80106f80:	74 d4                	je     80106f56 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80106f82:	8b 45 08             	mov    0x8(%ebp),%eax
80106f85:	0f b6 c0             	movzbl %al,%eax
80106f88:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f8c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106f93:	e8 76 fe ff ff       	call   80106e0e <outb>
}
80106f98:	c9                   	leave  
80106f99:	c3                   	ret    

80106f9a <uartgetc>:

static int
uartgetc(void)
{
80106f9a:	55                   	push   %ebp
80106f9b:	89 e5                	mov    %esp,%ebp
80106f9d:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106fa0:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106fa5:	85 c0                	test   %eax,%eax
80106fa7:	75 07                	jne    80106fb0 <uartgetc+0x16>
    return -1;
80106fa9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fae:	eb 2c                	jmp    80106fdc <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106fb0:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106fb7:	e8 35 fe ff ff       	call   80106df1 <inb>
80106fbc:	0f b6 c0             	movzbl %al,%eax
80106fbf:	83 e0 01             	and    $0x1,%eax
80106fc2:	85 c0                	test   %eax,%eax
80106fc4:	75 07                	jne    80106fcd <uartgetc+0x33>
    return -1;
80106fc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fcb:	eb 0f                	jmp    80106fdc <uartgetc+0x42>
  return inb(COM1+0);
80106fcd:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106fd4:	e8 18 fe ff ff       	call   80106df1 <inb>
80106fd9:	0f b6 c0             	movzbl %al,%eax
}
80106fdc:	c9                   	leave  
80106fdd:	c3                   	ret    

80106fde <uartintr>:

void
uartintr(void)
{
80106fde:	55                   	push   %ebp
80106fdf:	89 e5                	mov    %esp,%ebp
80106fe1:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106fe4:	c7 04 24 9a 6f 10 80 	movl   $0x80106f9a,(%esp)
80106feb:	e8 f5 9a ff ff       	call   80100ae5 <consoleintr>
}
80106ff0:	c9                   	leave  
80106ff1:	c3                   	ret    

80106ff2 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106ff2:	6a 00                	push   $0x0
  pushl $0
80106ff4:	6a 00                	push   $0x0
  jmp alltraps
80106ff6:	e9 7e f9 ff ff       	jmp    80106979 <alltraps>

80106ffb <vector1>:
.globl vector1
vector1:
  pushl $0
80106ffb:	6a 00                	push   $0x0
  pushl $1
80106ffd:	6a 01                	push   $0x1
  jmp alltraps
80106fff:	e9 75 f9 ff ff       	jmp    80106979 <alltraps>

80107004 <vector2>:
.globl vector2
vector2:
  pushl $0
80107004:	6a 00                	push   $0x0
  pushl $2
80107006:	6a 02                	push   $0x2
  jmp alltraps
80107008:	e9 6c f9 ff ff       	jmp    80106979 <alltraps>

8010700d <vector3>:
.globl vector3
vector3:
  pushl $0
8010700d:	6a 00                	push   $0x0
  pushl $3
8010700f:	6a 03                	push   $0x3
  jmp alltraps
80107011:	e9 63 f9 ff ff       	jmp    80106979 <alltraps>

80107016 <vector4>:
.globl vector4
vector4:
  pushl $0
80107016:	6a 00                	push   $0x0
  pushl $4
80107018:	6a 04                	push   $0x4
  jmp alltraps
8010701a:	e9 5a f9 ff ff       	jmp    80106979 <alltraps>

8010701f <vector5>:
.globl vector5
vector5:
  pushl $0
8010701f:	6a 00                	push   $0x0
  pushl $5
80107021:	6a 05                	push   $0x5
  jmp alltraps
80107023:	e9 51 f9 ff ff       	jmp    80106979 <alltraps>

80107028 <vector6>:
.globl vector6
vector6:
  pushl $0
80107028:	6a 00                	push   $0x0
  pushl $6
8010702a:	6a 06                	push   $0x6
  jmp alltraps
8010702c:	e9 48 f9 ff ff       	jmp    80106979 <alltraps>

80107031 <vector7>:
.globl vector7
vector7:
  pushl $0
80107031:	6a 00                	push   $0x0
  pushl $7
80107033:	6a 07                	push   $0x7
  jmp alltraps
80107035:	e9 3f f9 ff ff       	jmp    80106979 <alltraps>

8010703a <vector8>:
.globl vector8
vector8:
  pushl $8
8010703a:	6a 08                	push   $0x8
  jmp alltraps
8010703c:	e9 38 f9 ff ff       	jmp    80106979 <alltraps>

80107041 <vector9>:
.globl vector9
vector9:
  pushl $0
80107041:	6a 00                	push   $0x0
  pushl $9
80107043:	6a 09                	push   $0x9
  jmp alltraps
80107045:	e9 2f f9 ff ff       	jmp    80106979 <alltraps>

8010704a <vector10>:
.globl vector10
vector10:
  pushl $10
8010704a:	6a 0a                	push   $0xa
  jmp alltraps
8010704c:	e9 28 f9 ff ff       	jmp    80106979 <alltraps>

80107051 <vector11>:
.globl vector11
vector11:
  pushl $11
80107051:	6a 0b                	push   $0xb
  jmp alltraps
80107053:	e9 21 f9 ff ff       	jmp    80106979 <alltraps>

80107058 <vector12>:
.globl vector12
vector12:
  pushl $12
80107058:	6a 0c                	push   $0xc
  jmp alltraps
8010705a:	e9 1a f9 ff ff       	jmp    80106979 <alltraps>

8010705f <vector13>:
.globl vector13
vector13:
  pushl $13
8010705f:	6a 0d                	push   $0xd
  jmp alltraps
80107061:	e9 13 f9 ff ff       	jmp    80106979 <alltraps>

80107066 <vector14>:
.globl vector14
vector14:
  pushl $14
80107066:	6a 0e                	push   $0xe
  jmp alltraps
80107068:	e9 0c f9 ff ff       	jmp    80106979 <alltraps>

8010706d <vector15>:
.globl vector15
vector15:
  pushl $0
8010706d:	6a 00                	push   $0x0
  pushl $15
8010706f:	6a 0f                	push   $0xf
  jmp alltraps
80107071:	e9 03 f9 ff ff       	jmp    80106979 <alltraps>

80107076 <vector16>:
.globl vector16
vector16:
  pushl $0
80107076:	6a 00                	push   $0x0
  pushl $16
80107078:	6a 10                	push   $0x10
  jmp alltraps
8010707a:	e9 fa f8 ff ff       	jmp    80106979 <alltraps>

8010707f <vector17>:
.globl vector17
vector17:
  pushl $17
8010707f:	6a 11                	push   $0x11
  jmp alltraps
80107081:	e9 f3 f8 ff ff       	jmp    80106979 <alltraps>

80107086 <vector18>:
.globl vector18
vector18:
  pushl $0
80107086:	6a 00                	push   $0x0
  pushl $18
80107088:	6a 12                	push   $0x12
  jmp alltraps
8010708a:	e9 ea f8 ff ff       	jmp    80106979 <alltraps>

8010708f <vector19>:
.globl vector19
vector19:
  pushl $0
8010708f:	6a 00                	push   $0x0
  pushl $19
80107091:	6a 13                	push   $0x13
  jmp alltraps
80107093:	e9 e1 f8 ff ff       	jmp    80106979 <alltraps>

80107098 <vector20>:
.globl vector20
vector20:
  pushl $0
80107098:	6a 00                	push   $0x0
  pushl $20
8010709a:	6a 14                	push   $0x14
  jmp alltraps
8010709c:	e9 d8 f8 ff ff       	jmp    80106979 <alltraps>

801070a1 <vector21>:
.globl vector21
vector21:
  pushl $0
801070a1:	6a 00                	push   $0x0
  pushl $21
801070a3:	6a 15                	push   $0x15
  jmp alltraps
801070a5:	e9 cf f8 ff ff       	jmp    80106979 <alltraps>

801070aa <vector22>:
.globl vector22
vector22:
  pushl $0
801070aa:	6a 00                	push   $0x0
  pushl $22
801070ac:	6a 16                	push   $0x16
  jmp alltraps
801070ae:	e9 c6 f8 ff ff       	jmp    80106979 <alltraps>

801070b3 <vector23>:
.globl vector23
vector23:
  pushl $0
801070b3:	6a 00                	push   $0x0
  pushl $23
801070b5:	6a 17                	push   $0x17
  jmp alltraps
801070b7:	e9 bd f8 ff ff       	jmp    80106979 <alltraps>

801070bc <vector24>:
.globl vector24
vector24:
  pushl $0
801070bc:	6a 00                	push   $0x0
  pushl $24
801070be:	6a 18                	push   $0x18
  jmp alltraps
801070c0:	e9 b4 f8 ff ff       	jmp    80106979 <alltraps>

801070c5 <vector25>:
.globl vector25
vector25:
  pushl $0
801070c5:	6a 00                	push   $0x0
  pushl $25
801070c7:	6a 19                	push   $0x19
  jmp alltraps
801070c9:	e9 ab f8 ff ff       	jmp    80106979 <alltraps>

801070ce <vector26>:
.globl vector26
vector26:
  pushl $0
801070ce:	6a 00                	push   $0x0
  pushl $26
801070d0:	6a 1a                	push   $0x1a
  jmp alltraps
801070d2:	e9 a2 f8 ff ff       	jmp    80106979 <alltraps>

801070d7 <vector27>:
.globl vector27
vector27:
  pushl $0
801070d7:	6a 00                	push   $0x0
  pushl $27
801070d9:	6a 1b                	push   $0x1b
  jmp alltraps
801070db:	e9 99 f8 ff ff       	jmp    80106979 <alltraps>

801070e0 <vector28>:
.globl vector28
vector28:
  pushl $0
801070e0:	6a 00                	push   $0x0
  pushl $28
801070e2:	6a 1c                	push   $0x1c
  jmp alltraps
801070e4:	e9 90 f8 ff ff       	jmp    80106979 <alltraps>

801070e9 <vector29>:
.globl vector29
vector29:
  pushl $0
801070e9:	6a 00                	push   $0x0
  pushl $29
801070eb:	6a 1d                	push   $0x1d
  jmp alltraps
801070ed:	e9 87 f8 ff ff       	jmp    80106979 <alltraps>

801070f2 <vector30>:
.globl vector30
vector30:
  pushl $0
801070f2:	6a 00                	push   $0x0
  pushl $30
801070f4:	6a 1e                	push   $0x1e
  jmp alltraps
801070f6:	e9 7e f8 ff ff       	jmp    80106979 <alltraps>

801070fb <vector31>:
.globl vector31
vector31:
  pushl $0
801070fb:	6a 00                	push   $0x0
  pushl $31
801070fd:	6a 1f                	push   $0x1f
  jmp alltraps
801070ff:	e9 75 f8 ff ff       	jmp    80106979 <alltraps>

80107104 <vector32>:
.globl vector32
vector32:
  pushl $0
80107104:	6a 00                	push   $0x0
  pushl $32
80107106:	6a 20                	push   $0x20
  jmp alltraps
80107108:	e9 6c f8 ff ff       	jmp    80106979 <alltraps>

8010710d <vector33>:
.globl vector33
vector33:
  pushl $0
8010710d:	6a 00                	push   $0x0
  pushl $33
8010710f:	6a 21                	push   $0x21
  jmp alltraps
80107111:	e9 63 f8 ff ff       	jmp    80106979 <alltraps>

80107116 <vector34>:
.globl vector34
vector34:
  pushl $0
80107116:	6a 00                	push   $0x0
  pushl $34
80107118:	6a 22                	push   $0x22
  jmp alltraps
8010711a:	e9 5a f8 ff ff       	jmp    80106979 <alltraps>

8010711f <vector35>:
.globl vector35
vector35:
  pushl $0
8010711f:	6a 00                	push   $0x0
  pushl $35
80107121:	6a 23                	push   $0x23
  jmp alltraps
80107123:	e9 51 f8 ff ff       	jmp    80106979 <alltraps>

80107128 <vector36>:
.globl vector36
vector36:
  pushl $0
80107128:	6a 00                	push   $0x0
  pushl $36
8010712a:	6a 24                	push   $0x24
  jmp alltraps
8010712c:	e9 48 f8 ff ff       	jmp    80106979 <alltraps>

80107131 <vector37>:
.globl vector37
vector37:
  pushl $0
80107131:	6a 00                	push   $0x0
  pushl $37
80107133:	6a 25                	push   $0x25
  jmp alltraps
80107135:	e9 3f f8 ff ff       	jmp    80106979 <alltraps>

8010713a <vector38>:
.globl vector38
vector38:
  pushl $0
8010713a:	6a 00                	push   $0x0
  pushl $38
8010713c:	6a 26                	push   $0x26
  jmp alltraps
8010713e:	e9 36 f8 ff ff       	jmp    80106979 <alltraps>

80107143 <vector39>:
.globl vector39
vector39:
  pushl $0
80107143:	6a 00                	push   $0x0
  pushl $39
80107145:	6a 27                	push   $0x27
  jmp alltraps
80107147:	e9 2d f8 ff ff       	jmp    80106979 <alltraps>

8010714c <vector40>:
.globl vector40
vector40:
  pushl $0
8010714c:	6a 00                	push   $0x0
  pushl $40
8010714e:	6a 28                	push   $0x28
  jmp alltraps
80107150:	e9 24 f8 ff ff       	jmp    80106979 <alltraps>

80107155 <vector41>:
.globl vector41
vector41:
  pushl $0
80107155:	6a 00                	push   $0x0
  pushl $41
80107157:	6a 29                	push   $0x29
  jmp alltraps
80107159:	e9 1b f8 ff ff       	jmp    80106979 <alltraps>

8010715e <vector42>:
.globl vector42
vector42:
  pushl $0
8010715e:	6a 00                	push   $0x0
  pushl $42
80107160:	6a 2a                	push   $0x2a
  jmp alltraps
80107162:	e9 12 f8 ff ff       	jmp    80106979 <alltraps>

80107167 <vector43>:
.globl vector43
vector43:
  pushl $0
80107167:	6a 00                	push   $0x0
  pushl $43
80107169:	6a 2b                	push   $0x2b
  jmp alltraps
8010716b:	e9 09 f8 ff ff       	jmp    80106979 <alltraps>

80107170 <vector44>:
.globl vector44
vector44:
  pushl $0
80107170:	6a 00                	push   $0x0
  pushl $44
80107172:	6a 2c                	push   $0x2c
  jmp alltraps
80107174:	e9 00 f8 ff ff       	jmp    80106979 <alltraps>

80107179 <vector45>:
.globl vector45
vector45:
  pushl $0
80107179:	6a 00                	push   $0x0
  pushl $45
8010717b:	6a 2d                	push   $0x2d
  jmp alltraps
8010717d:	e9 f7 f7 ff ff       	jmp    80106979 <alltraps>

80107182 <vector46>:
.globl vector46
vector46:
  pushl $0
80107182:	6a 00                	push   $0x0
  pushl $46
80107184:	6a 2e                	push   $0x2e
  jmp alltraps
80107186:	e9 ee f7 ff ff       	jmp    80106979 <alltraps>

8010718b <vector47>:
.globl vector47
vector47:
  pushl $0
8010718b:	6a 00                	push   $0x0
  pushl $47
8010718d:	6a 2f                	push   $0x2f
  jmp alltraps
8010718f:	e9 e5 f7 ff ff       	jmp    80106979 <alltraps>

80107194 <vector48>:
.globl vector48
vector48:
  pushl $0
80107194:	6a 00                	push   $0x0
  pushl $48
80107196:	6a 30                	push   $0x30
  jmp alltraps
80107198:	e9 dc f7 ff ff       	jmp    80106979 <alltraps>

8010719d <vector49>:
.globl vector49
vector49:
  pushl $0
8010719d:	6a 00                	push   $0x0
  pushl $49
8010719f:	6a 31                	push   $0x31
  jmp alltraps
801071a1:	e9 d3 f7 ff ff       	jmp    80106979 <alltraps>

801071a6 <vector50>:
.globl vector50
vector50:
  pushl $0
801071a6:	6a 00                	push   $0x0
  pushl $50
801071a8:	6a 32                	push   $0x32
  jmp alltraps
801071aa:	e9 ca f7 ff ff       	jmp    80106979 <alltraps>

801071af <vector51>:
.globl vector51
vector51:
  pushl $0
801071af:	6a 00                	push   $0x0
  pushl $51
801071b1:	6a 33                	push   $0x33
  jmp alltraps
801071b3:	e9 c1 f7 ff ff       	jmp    80106979 <alltraps>

801071b8 <vector52>:
.globl vector52
vector52:
  pushl $0
801071b8:	6a 00                	push   $0x0
  pushl $52
801071ba:	6a 34                	push   $0x34
  jmp alltraps
801071bc:	e9 b8 f7 ff ff       	jmp    80106979 <alltraps>

801071c1 <vector53>:
.globl vector53
vector53:
  pushl $0
801071c1:	6a 00                	push   $0x0
  pushl $53
801071c3:	6a 35                	push   $0x35
  jmp alltraps
801071c5:	e9 af f7 ff ff       	jmp    80106979 <alltraps>

801071ca <vector54>:
.globl vector54
vector54:
  pushl $0
801071ca:	6a 00                	push   $0x0
  pushl $54
801071cc:	6a 36                	push   $0x36
  jmp alltraps
801071ce:	e9 a6 f7 ff ff       	jmp    80106979 <alltraps>

801071d3 <vector55>:
.globl vector55
vector55:
  pushl $0
801071d3:	6a 00                	push   $0x0
  pushl $55
801071d5:	6a 37                	push   $0x37
  jmp alltraps
801071d7:	e9 9d f7 ff ff       	jmp    80106979 <alltraps>

801071dc <vector56>:
.globl vector56
vector56:
  pushl $0
801071dc:	6a 00                	push   $0x0
  pushl $56
801071de:	6a 38                	push   $0x38
  jmp alltraps
801071e0:	e9 94 f7 ff ff       	jmp    80106979 <alltraps>

801071e5 <vector57>:
.globl vector57
vector57:
  pushl $0
801071e5:	6a 00                	push   $0x0
  pushl $57
801071e7:	6a 39                	push   $0x39
  jmp alltraps
801071e9:	e9 8b f7 ff ff       	jmp    80106979 <alltraps>

801071ee <vector58>:
.globl vector58
vector58:
  pushl $0
801071ee:	6a 00                	push   $0x0
  pushl $58
801071f0:	6a 3a                	push   $0x3a
  jmp alltraps
801071f2:	e9 82 f7 ff ff       	jmp    80106979 <alltraps>

801071f7 <vector59>:
.globl vector59
vector59:
  pushl $0
801071f7:	6a 00                	push   $0x0
  pushl $59
801071f9:	6a 3b                	push   $0x3b
  jmp alltraps
801071fb:	e9 79 f7 ff ff       	jmp    80106979 <alltraps>

80107200 <vector60>:
.globl vector60
vector60:
  pushl $0
80107200:	6a 00                	push   $0x0
  pushl $60
80107202:	6a 3c                	push   $0x3c
  jmp alltraps
80107204:	e9 70 f7 ff ff       	jmp    80106979 <alltraps>

80107209 <vector61>:
.globl vector61
vector61:
  pushl $0
80107209:	6a 00                	push   $0x0
  pushl $61
8010720b:	6a 3d                	push   $0x3d
  jmp alltraps
8010720d:	e9 67 f7 ff ff       	jmp    80106979 <alltraps>

80107212 <vector62>:
.globl vector62
vector62:
  pushl $0
80107212:	6a 00                	push   $0x0
  pushl $62
80107214:	6a 3e                	push   $0x3e
  jmp alltraps
80107216:	e9 5e f7 ff ff       	jmp    80106979 <alltraps>

8010721b <vector63>:
.globl vector63
vector63:
  pushl $0
8010721b:	6a 00                	push   $0x0
  pushl $63
8010721d:	6a 3f                	push   $0x3f
  jmp alltraps
8010721f:	e9 55 f7 ff ff       	jmp    80106979 <alltraps>

80107224 <vector64>:
.globl vector64
vector64:
  pushl $0
80107224:	6a 00                	push   $0x0
  pushl $64
80107226:	6a 40                	push   $0x40
  jmp alltraps
80107228:	e9 4c f7 ff ff       	jmp    80106979 <alltraps>

8010722d <vector65>:
.globl vector65
vector65:
  pushl $0
8010722d:	6a 00                	push   $0x0
  pushl $65
8010722f:	6a 41                	push   $0x41
  jmp alltraps
80107231:	e9 43 f7 ff ff       	jmp    80106979 <alltraps>

80107236 <vector66>:
.globl vector66
vector66:
  pushl $0
80107236:	6a 00                	push   $0x0
  pushl $66
80107238:	6a 42                	push   $0x42
  jmp alltraps
8010723a:	e9 3a f7 ff ff       	jmp    80106979 <alltraps>

8010723f <vector67>:
.globl vector67
vector67:
  pushl $0
8010723f:	6a 00                	push   $0x0
  pushl $67
80107241:	6a 43                	push   $0x43
  jmp alltraps
80107243:	e9 31 f7 ff ff       	jmp    80106979 <alltraps>

80107248 <vector68>:
.globl vector68
vector68:
  pushl $0
80107248:	6a 00                	push   $0x0
  pushl $68
8010724a:	6a 44                	push   $0x44
  jmp alltraps
8010724c:	e9 28 f7 ff ff       	jmp    80106979 <alltraps>

80107251 <vector69>:
.globl vector69
vector69:
  pushl $0
80107251:	6a 00                	push   $0x0
  pushl $69
80107253:	6a 45                	push   $0x45
  jmp alltraps
80107255:	e9 1f f7 ff ff       	jmp    80106979 <alltraps>

8010725a <vector70>:
.globl vector70
vector70:
  pushl $0
8010725a:	6a 00                	push   $0x0
  pushl $70
8010725c:	6a 46                	push   $0x46
  jmp alltraps
8010725e:	e9 16 f7 ff ff       	jmp    80106979 <alltraps>

80107263 <vector71>:
.globl vector71
vector71:
  pushl $0
80107263:	6a 00                	push   $0x0
  pushl $71
80107265:	6a 47                	push   $0x47
  jmp alltraps
80107267:	e9 0d f7 ff ff       	jmp    80106979 <alltraps>

8010726c <vector72>:
.globl vector72
vector72:
  pushl $0
8010726c:	6a 00                	push   $0x0
  pushl $72
8010726e:	6a 48                	push   $0x48
  jmp alltraps
80107270:	e9 04 f7 ff ff       	jmp    80106979 <alltraps>

80107275 <vector73>:
.globl vector73
vector73:
  pushl $0
80107275:	6a 00                	push   $0x0
  pushl $73
80107277:	6a 49                	push   $0x49
  jmp alltraps
80107279:	e9 fb f6 ff ff       	jmp    80106979 <alltraps>

8010727e <vector74>:
.globl vector74
vector74:
  pushl $0
8010727e:	6a 00                	push   $0x0
  pushl $74
80107280:	6a 4a                	push   $0x4a
  jmp alltraps
80107282:	e9 f2 f6 ff ff       	jmp    80106979 <alltraps>

80107287 <vector75>:
.globl vector75
vector75:
  pushl $0
80107287:	6a 00                	push   $0x0
  pushl $75
80107289:	6a 4b                	push   $0x4b
  jmp alltraps
8010728b:	e9 e9 f6 ff ff       	jmp    80106979 <alltraps>

80107290 <vector76>:
.globl vector76
vector76:
  pushl $0
80107290:	6a 00                	push   $0x0
  pushl $76
80107292:	6a 4c                	push   $0x4c
  jmp alltraps
80107294:	e9 e0 f6 ff ff       	jmp    80106979 <alltraps>

80107299 <vector77>:
.globl vector77
vector77:
  pushl $0
80107299:	6a 00                	push   $0x0
  pushl $77
8010729b:	6a 4d                	push   $0x4d
  jmp alltraps
8010729d:	e9 d7 f6 ff ff       	jmp    80106979 <alltraps>

801072a2 <vector78>:
.globl vector78
vector78:
  pushl $0
801072a2:	6a 00                	push   $0x0
  pushl $78
801072a4:	6a 4e                	push   $0x4e
  jmp alltraps
801072a6:	e9 ce f6 ff ff       	jmp    80106979 <alltraps>

801072ab <vector79>:
.globl vector79
vector79:
  pushl $0
801072ab:	6a 00                	push   $0x0
  pushl $79
801072ad:	6a 4f                	push   $0x4f
  jmp alltraps
801072af:	e9 c5 f6 ff ff       	jmp    80106979 <alltraps>

801072b4 <vector80>:
.globl vector80
vector80:
  pushl $0
801072b4:	6a 00                	push   $0x0
  pushl $80
801072b6:	6a 50                	push   $0x50
  jmp alltraps
801072b8:	e9 bc f6 ff ff       	jmp    80106979 <alltraps>

801072bd <vector81>:
.globl vector81
vector81:
  pushl $0
801072bd:	6a 00                	push   $0x0
  pushl $81
801072bf:	6a 51                	push   $0x51
  jmp alltraps
801072c1:	e9 b3 f6 ff ff       	jmp    80106979 <alltraps>

801072c6 <vector82>:
.globl vector82
vector82:
  pushl $0
801072c6:	6a 00                	push   $0x0
  pushl $82
801072c8:	6a 52                	push   $0x52
  jmp alltraps
801072ca:	e9 aa f6 ff ff       	jmp    80106979 <alltraps>

801072cf <vector83>:
.globl vector83
vector83:
  pushl $0
801072cf:	6a 00                	push   $0x0
  pushl $83
801072d1:	6a 53                	push   $0x53
  jmp alltraps
801072d3:	e9 a1 f6 ff ff       	jmp    80106979 <alltraps>

801072d8 <vector84>:
.globl vector84
vector84:
  pushl $0
801072d8:	6a 00                	push   $0x0
  pushl $84
801072da:	6a 54                	push   $0x54
  jmp alltraps
801072dc:	e9 98 f6 ff ff       	jmp    80106979 <alltraps>

801072e1 <vector85>:
.globl vector85
vector85:
  pushl $0
801072e1:	6a 00                	push   $0x0
  pushl $85
801072e3:	6a 55                	push   $0x55
  jmp alltraps
801072e5:	e9 8f f6 ff ff       	jmp    80106979 <alltraps>

801072ea <vector86>:
.globl vector86
vector86:
  pushl $0
801072ea:	6a 00                	push   $0x0
  pushl $86
801072ec:	6a 56                	push   $0x56
  jmp alltraps
801072ee:	e9 86 f6 ff ff       	jmp    80106979 <alltraps>

801072f3 <vector87>:
.globl vector87
vector87:
  pushl $0
801072f3:	6a 00                	push   $0x0
  pushl $87
801072f5:	6a 57                	push   $0x57
  jmp alltraps
801072f7:	e9 7d f6 ff ff       	jmp    80106979 <alltraps>

801072fc <vector88>:
.globl vector88
vector88:
  pushl $0
801072fc:	6a 00                	push   $0x0
  pushl $88
801072fe:	6a 58                	push   $0x58
  jmp alltraps
80107300:	e9 74 f6 ff ff       	jmp    80106979 <alltraps>

80107305 <vector89>:
.globl vector89
vector89:
  pushl $0
80107305:	6a 00                	push   $0x0
  pushl $89
80107307:	6a 59                	push   $0x59
  jmp alltraps
80107309:	e9 6b f6 ff ff       	jmp    80106979 <alltraps>

8010730e <vector90>:
.globl vector90
vector90:
  pushl $0
8010730e:	6a 00                	push   $0x0
  pushl $90
80107310:	6a 5a                	push   $0x5a
  jmp alltraps
80107312:	e9 62 f6 ff ff       	jmp    80106979 <alltraps>

80107317 <vector91>:
.globl vector91
vector91:
  pushl $0
80107317:	6a 00                	push   $0x0
  pushl $91
80107319:	6a 5b                	push   $0x5b
  jmp alltraps
8010731b:	e9 59 f6 ff ff       	jmp    80106979 <alltraps>

80107320 <vector92>:
.globl vector92
vector92:
  pushl $0
80107320:	6a 00                	push   $0x0
  pushl $92
80107322:	6a 5c                	push   $0x5c
  jmp alltraps
80107324:	e9 50 f6 ff ff       	jmp    80106979 <alltraps>

80107329 <vector93>:
.globl vector93
vector93:
  pushl $0
80107329:	6a 00                	push   $0x0
  pushl $93
8010732b:	6a 5d                	push   $0x5d
  jmp alltraps
8010732d:	e9 47 f6 ff ff       	jmp    80106979 <alltraps>

80107332 <vector94>:
.globl vector94
vector94:
  pushl $0
80107332:	6a 00                	push   $0x0
  pushl $94
80107334:	6a 5e                	push   $0x5e
  jmp alltraps
80107336:	e9 3e f6 ff ff       	jmp    80106979 <alltraps>

8010733b <vector95>:
.globl vector95
vector95:
  pushl $0
8010733b:	6a 00                	push   $0x0
  pushl $95
8010733d:	6a 5f                	push   $0x5f
  jmp alltraps
8010733f:	e9 35 f6 ff ff       	jmp    80106979 <alltraps>

80107344 <vector96>:
.globl vector96
vector96:
  pushl $0
80107344:	6a 00                	push   $0x0
  pushl $96
80107346:	6a 60                	push   $0x60
  jmp alltraps
80107348:	e9 2c f6 ff ff       	jmp    80106979 <alltraps>

8010734d <vector97>:
.globl vector97
vector97:
  pushl $0
8010734d:	6a 00                	push   $0x0
  pushl $97
8010734f:	6a 61                	push   $0x61
  jmp alltraps
80107351:	e9 23 f6 ff ff       	jmp    80106979 <alltraps>

80107356 <vector98>:
.globl vector98
vector98:
  pushl $0
80107356:	6a 00                	push   $0x0
  pushl $98
80107358:	6a 62                	push   $0x62
  jmp alltraps
8010735a:	e9 1a f6 ff ff       	jmp    80106979 <alltraps>

8010735f <vector99>:
.globl vector99
vector99:
  pushl $0
8010735f:	6a 00                	push   $0x0
  pushl $99
80107361:	6a 63                	push   $0x63
  jmp alltraps
80107363:	e9 11 f6 ff ff       	jmp    80106979 <alltraps>

80107368 <vector100>:
.globl vector100
vector100:
  pushl $0
80107368:	6a 00                	push   $0x0
  pushl $100
8010736a:	6a 64                	push   $0x64
  jmp alltraps
8010736c:	e9 08 f6 ff ff       	jmp    80106979 <alltraps>

80107371 <vector101>:
.globl vector101
vector101:
  pushl $0
80107371:	6a 00                	push   $0x0
  pushl $101
80107373:	6a 65                	push   $0x65
  jmp alltraps
80107375:	e9 ff f5 ff ff       	jmp    80106979 <alltraps>

8010737a <vector102>:
.globl vector102
vector102:
  pushl $0
8010737a:	6a 00                	push   $0x0
  pushl $102
8010737c:	6a 66                	push   $0x66
  jmp alltraps
8010737e:	e9 f6 f5 ff ff       	jmp    80106979 <alltraps>

80107383 <vector103>:
.globl vector103
vector103:
  pushl $0
80107383:	6a 00                	push   $0x0
  pushl $103
80107385:	6a 67                	push   $0x67
  jmp alltraps
80107387:	e9 ed f5 ff ff       	jmp    80106979 <alltraps>

8010738c <vector104>:
.globl vector104
vector104:
  pushl $0
8010738c:	6a 00                	push   $0x0
  pushl $104
8010738e:	6a 68                	push   $0x68
  jmp alltraps
80107390:	e9 e4 f5 ff ff       	jmp    80106979 <alltraps>

80107395 <vector105>:
.globl vector105
vector105:
  pushl $0
80107395:	6a 00                	push   $0x0
  pushl $105
80107397:	6a 69                	push   $0x69
  jmp alltraps
80107399:	e9 db f5 ff ff       	jmp    80106979 <alltraps>

8010739e <vector106>:
.globl vector106
vector106:
  pushl $0
8010739e:	6a 00                	push   $0x0
  pushl $106
801073a0:	6a 6a                	push   $0x6a
  jmp alltraps
801073a2:	e9 d2 f5 ff ff       	jmp    80106979 <alltraps>

801073a7 <vector107>:
.globl vector107
vector107:
  pushl $0
801073a7:	6a 00                	push   $0x0
  pushl $107
801073a9:	6a 6b                	push   $0x6b
  jmp alltraps
801073ab:	e9 c9 f5 ff ff       	jmp    80106979 <alltraps>

801073b0 <vector108>:
.globl vector108
vector108:
  pushl $0
801073b0:	6a 00                	push   $0x0
  pushl $108
801073b2:	6a 6c                	push   $0x6c
  jmp alltraps
801073b4:	e9 c0 f5 ff ff       	jmp    80106979 <alltraps>

801073b9 <vector109>:
.globl vector109
vector109:
  pushl $0
801073b9:	6a 00                	push   $0x0
  pushl $109
801073bb:	6a 6d                	push   $0x6d
  jmp alltraps
801073bd:	e9 b7 f5 ff ff       	jmp    80106979 <alltraps>

801073c2 <vector110>:
.globl vector110
vector110:
  pushl $0
801073c2:	6a 00                	push   $0x0
  pushl $110
801073c4:	6a 6e                	push   $0x6e
  jmp alltraps
801073c6:	e9 ae f5 ff ff       	jmp    80106979 <alltraps>

801073cb <vector111>:
.globl vector111
vector111:
  pushl $0
801073cb:	6a 00                	push   $0x0
  pushl $111
801073cd:	6a 6f                	push   $0x6f
  jmp alltraps
801073cf:	e9 a5 f5 ff ff       	jmp    80106979 <alltraps>

801073d4 <vector112>:
.globl vector112
vector112:
  pushl $0
801073d4:	6a 00                	push   $0x0
  pushl $112
801073d6:	6a 70                	push   $0x70
  jmp alltraps
801073d8:	e9 9c f5 ff ff       	jmp    80106979 <alltraps>

801073dd <vector113>:
.globl vector113
vector113:
  pushl $0
801073dd:	6a 00                	push   $0x0
  pushl $113
801073df:	6a 71                	push   $0x71
  jmp alltraps
801073e1:	e9 93 f5 ff ff       	jmp    80106979 <alltraps>

801073e6 <vector114>:
.globl vector114
vector114:
  pushl $0
801073e6:	6a 00                	push   $0x0
  pushl $114
801073e8:	6a 72                	push   $0x72
  jmp alltraps
801073ea:	e9 8a f5 ff ff       	jmp    80106979 <alltraps>

801073ef <vector115>:
.globl vector115
vector115:
  pushl $0
801073ef:	6a 00                	push   $0x0
  pushl $115
801073f1:	6a 73                	push   $0x73
  jmp alltraps
801073f3:	e9 81 f5 ff ff       	jmp    80106979 <alltraps>

801073f8 <vector116>:
.globl vector116
vector116:
  pushl $0
801073f8:	6a 00                	push   $0x0
  pushl $116
801073fa:	6a 74                	push   $0x74
  jmp alltraps
801073fc:	e9 78 f5 ff ff       	jmp    80106979 <alltraps>

80107401 <vector117>:
.globl vector117
vector117:
  pushl $0
80107401:	6a 00                	push   $0x0
  pushl $117
80107403:	6a 75                	push   $0x75
  jmp alltraps
80107405:	e9 6f f5 ff ff       	jmp    80106979 <alltraps>

8010740a <vector118>:
.globl vector118
vector118:
  pushl $0
8010740a:	6a 00                	push   $0x0
  pushl $118
8010740c:	6a 76                	push   $0x76
  jmp alltraps
8010740e:	e9 66 f5 ff ff       	jmp    80106979 <alltraps>

80107413 <vector119>:
.globl vector119
vector119:
  pushl $0
80107413:	6a 00                	push   $0x0
  pushl $119
80107415:	6a 77                	push   $0x77
  jmp alltraps
80107417:	e9 5d f5 ff ff       	jmp    80106979 <alltraps>

8010741c <vector120>:
.globl vector120
vector120:
  pushl $0
8010741c:	6a 00                	push   $0x0
  pushl $120
8010741e:	6a 78                	push   $0x78
  jmp alltraps
80107420:	e9 54 f5 ff ff       	jmp    80106979 <alltraps>

80107425 <vector121>:
.globl vector121
vector121:
  pushl $0
80107425:	6a 00                	push   $0x0
  pushl $121
80107427:	6a 79                	push   $0x79
  jmp alltraps
80107429:	e9 4b f5 ff ff       	jmp    80106979 <alltraps>

8010742e <vector122>:
.globl vector122
vector122:
  pushl $0
8010742e:	6a 00                	push   $0x0
  pushl $122
80107430:	6a 7a                	push   $0x7a
  jmp alltraps
80107432:	e9 42 f5 ff ff       	jmp    80106979 <alltraps>

80107437 <vector123>:
.globl vector123
vector123:
  pushl $0
80107437:	6a 00                	push   $0x0
  pushl $123
80107439:	6a 7b                	push   $0x7b
  jmp alltraps
8010743b:	e9 39 f5 ff ff       	jmp    80106979 <alltraps>

80107440 <vector124>:
.globl vector124
vector124:
  pushl $0
80107440:	6a 00                	push   $0x0
  pushl $124
80107442:	6a 7c                	push   $0x7c
  jmp alltraps
80107444:	e9 30 f5 ff ff       	jmp    80106979 <alltraps>

80107449 <vector125>:
.globl vector125
vector125:
  pushl $0
80107449:	6a 00                	push   $0x0
  pushl $125
8010744b:	6a 7d                	push   $0x7d
  jmp alltraps
8010744d:	e9 27 f5 ff ff       	jmp    80106979 <alltraps>

80107452 <vector126>:
.globl vector126
vector126:
  pushl $0
80107452:	6a 00                	push   $0x0
  pushl $126
80107454:	6a 7e                	push   $0x7e
  jmp alltraps
80107456:	e9 1e f5 ff ff       	jmp    80106979 <alltraps>

8010745b <vector127>:
.globl vector127
vector127:
  pushl $0
8010745b:	6a 00                	push   $0x0
  pushl $127
8010745d:	6a 7f                	push   $0x7f
  jmp alltraps
8010745f:	e9 15 f5 ff ff       	jmp    80106979 <alltraps>

80107464 <vector128>:
.globl vector128
vector128:
  pushl $0
80107464:	6a 00                	push   $0x0
  pushl $128
80107466:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010746b:	e9 09 f5 ff ff       	jmp    80106979 <alltraps>

80107470 <vector129>:
.globl vector129
vector129:
  pushl $0
80107470:	6a 00                	push   $0x0
  pushl $129
80107472:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107477:	e9 fd f4 ff ff       	jmp    80106979 <alltraps>

8010747c <vector130>:
.globl vector130
vector130:
  pushl $0
8010747c:	6a 00                	push   $0x0
  pushl $130
8010747e:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107483:	e9 f1 f4 ff ff       	jmp    80106979 <alltraps>

80107488 <vector131>:
.globl vector131
vector131:
  pushl $0
80107488:	6a 00                	push   $0x0
  pushl $131
8010748a:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010748f:	e9 e5 f4 ff ff       	jmp    80106979 <alltraps>

80107494 <vector132>:
.globl vector132
vector132:
  pushl $0
80107494:	6a 00                	push   $0x0
  pushl $132
80107496:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010749b:	e9 d9 f4 ff ff       	jmp    80106979 <alltraps>

801074a0 <vector133>:
.globl vector133
vector133:
  pushl $0
801074a0:	6a 00                	push   $0x0
  pushl $133
801074a2:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801074a7:	e9 cd f4 ff ff       	jmp    80106979 <alltraps>

801074ac <vector134>:
.globl vector134
vector134:
  pushl $0
801074ac:	6a 00                	push   $0x0
  pushl $134
801074ae:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801074b3:	e9 c1 f4 ff ff       	jmp    80106979 <alltraps>

801074b8 <vector135>:
.globl vector135
vector135:
  pushl $0
801074b8:	6a 00                	push   $0x0
  pushl $135
801074ba:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801074bf:	e9 b5 f4 ff ff       	jmp    80106979 <alltraps>

801074c4 <vector136>:
.globl vector136
vector136:
  pushl $0
801074c4:	6a 00                	push   $0x0
  pushl $136
801074c6:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801074cb:	e9 a9 f4 ff ff       	jmp    80106979 <alltraps>

801074d0 <vector137>:
.globl vector137
vector137:
  pushl $0
801074d0:	6a 00                	push   $0x0
  pushl $137
801074d2:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801074d7:	e9 9d f4 ff ff       	jmp    80106979 <alltraps>

801074dc <vector138>:
.globl vector138
vector138:
  pushl $0
801074dc:	6a 00                	push   $0x0
  pushl $138
801074de:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801074e3:	e9 91 f4 ff ff       	jmp    80106979 <alltraps>

801074e8 <vector139>:
.globl vector139
vector139:
  pushl $0
801074e8:	6a 00                	push   $0x0
  pushl $139
801074ea:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801074ef:	e9 85 f4 ff ff       	jmp    80106979 <alltraps>

801074f4 <vector140>:
.globl vector140
vector140:
  pushl $0
801074f4:	6a 00                	push   $0x0
  pushl $140
801074f6:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801074fb:	e9 79 f4 ff ff       	jmp    80106979 <alltraps>

80107500 <vector141>:
.globl vector141
vector141:
  pushl $0
80107500:	6a 00                	push   $0x0
  pushl $141
80107502:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107507:	e9 6d f4 ff ff       	jmp    80106979 <alltraps>

8010750c <vector142>:
.globl vector142
vector142:
  pushl $0
8010750c:	6a 00                	push   $0x0
  pushl $142
8010750e:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107513:	e9 61 f4 ff ff       	jmp    80106979 <alltraps>

80107518 <vector143>:
.globl vector143
vector143:
  pushl $0
80107518:	6a 00                	push   $0x0
  pushl $143
8010751a:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010751f:	e9 55 f4 ff ff       	jmp    80106979 <alltraps>

80107524 <vector144>:
.globl vector144
vector144:
  pushl $0
80107524:	6a 00                	push   $0x0
  pushl $144
80107526:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010752b:	e9 49 f4 ff ff       	jmp    80106979 <alltraps>

80107530 <vector145>:
.globl vector145
vector145:
  pushl $0
80107530:	6a 00                	push   $0x0
  pushl $145
80107532:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107537:	e9 3d f4 ff ff       	jmp    80106979 <alltraps>

8010753c <vector146>:
.globl vector146
vector146:
  pushl $0
8010753c:	6a 00                	push   $0x0
  pushl $146
8010753e:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107543:	e9 31 f4 ff ff       	jmp    80106979 <alltraps>

80107548 <vector147>:
.globl vector147
vector147:
  pushl $0
80107548:	6a 00                	push   $0x0
  pushl $147
8010754a:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010754f:	e9 25 f4 ff ff       	jmp    80106979 <alltraps>

80107554 <vector148>:
.globl vector148
vector148:
  pushl $0
80107554:	6a 00                	push   $0x0
  pushl $148
80107556:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010755b:	e9 19 f4 ff ff       	jmp    80106979 <alltraps>

80107560 <vector149>:
.globl vector149
vector149:
  pushl $0
80107560:	6a 00                	push   $0x0
  pushl $149
80107562:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107567:	e9 0d f4 ff ff       	jmp    80106979 <alltraps>

8010756c <vector150>:
.globl vector150
vector150:
  pushl $0
8010756c:	6a 00                	push   $0x0
  pushl $150
8010756e:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107573:	e9 01 f4 ff ff       	jmp    80106979 <alltraps>

80107578 <vector151>:
.globl vector151
vector151:
  pushl $0
80107578:	6a 00                	push   $0x0
  pushl $151
8010757a:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010757f:	e9 f5 f3 ff ff       	jmp    80106979 <alltraps>

80107584 <vector152>:
.globl vector152
vector152:
  pushl $0
80107584:	6a 00                	push   $0x0
  pushl $152
80107586:	68 98 00 00 00       	push   $0x98
  jmp alltraps
8010758b:	e9 e9 f3 ff ff       	jmp    80106979 <alltraps>

80107590 <vector153>:
.globl vector153
vector153:
  pushl $0
80107590:	6a 00                	push   $0x0
  pushl $153
80107592:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107597:	e9 dd f3 ff ff       	jmp    80106979 <alltraps>

8010759c <vector154>:
.globl vector154
vector154:
  pushl $0
8010759c:	6a 00                	push   $0x0
  pushl $154
8010759e:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801075a3:	e9 d1 f3 ff ff       	jmp    80106979 <alltraps>

801075a8 <vector155>:
.globl vector155
vector155:
  pushl $0
801075a8:	6a 00                	push   $0x0
  pushl $155
801075aa:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801075af:	e9 c5 f3 ff ff       	jmp    80106979 <alltraps>

801075b4 <vector156>:
.globl vector156
vector156:
  pushl $0
801075b4:	6a 00                	push   $0x0
  pushl $156
801075b6:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801075bb:	e9 b9 f3 ff ff       	jmp    80106979 <alltraps>

801075c0 <vector157>:
.globl vector157
vector157:
  pushl $0
801075c0:	6a 00                	push   $0x0
  pushl $157
801075c2:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801075c7:	e9 ad f3 ff ff       	jmp    80106979 <alltraps>

801075cc <vector158>:
.globl vector158
vector158:
  pushl $0
801075cc:	6a 00                	push   $0x0
  pushl $158
801075ce:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801075d3:	e9 a1 f3 ff ff       	jmp    80106979 <alltraps>

801075d8 <vector159>:
.globl vector159
vector159:
  pushl $0
801075d8:	6a 00                	push   $0x0
  pushl $159
801075da:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801075df:	e9 95 f3 ff ff       	jmp    80106979 <alltraps>

801075e4 <vector160>:
.globl vector160
vector160:
  pushl $0
801075e4:	6a 00                	push   $0x0
  pushl $160
801075e6:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801075eb:	e9 89 f3 ff ff       	jmp    80106979 <alltraps>

801075f0 <vector161>:
.globl vector161
vector161:
  pushl $0
801075f0:	6a 00                	push   $0x0
  pushl $161
801075f2:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801075f7:	e9 7d f3 ff ff       	jmp    80106979 <alltraps>

801075fc <vector162>:
.globl vector162
vector162:
  pushl $0
801075fc:	6a 00                	push   $0x0
  pushl $162
801075fe:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107603:	e9 71 f3 ff ff       	jmp    80106979 <alltraps>

80107608 <vector163>:
.globl vector163
vector163:
  pushl $0
80107608:	6a 00                	push   $0x0
  pushl $163
8010760a:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010760f:	e9 65 f3 ff ff       	jmp    80106979 <alltraps>

80107614 <vector164>:
.globl vector164
vector164:
  pushl $0
80107614:	6a 00                	push   $0x0
  pushl $164
80107616:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010761b:	e9 59 f3 ff ff       	jmp    80106979 <alltraps>

80107620 <vector165>:
.globl vector165
vector165:
  pushl $0
80107620:	6a 00                	push   $0x0
  pushl $165
80107622:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107627:	e9 4d f3 ff ff       	jmp    80106979 <alltraps>

8010762c <vector166>:
.globl vector166
vector166:
  pushl $0
8010762c:	6a 00                	push   $0x0
  pushl $166
8010762e:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107633:	e9 41 f3 ff ff       	jmp    80106979 <alltraps>

80107638 <vector167>:
.globl vector167
vector167:
  pushl $0
80107638:	6a 00                	push   $0x0
  pushl $167
8010763a:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010763f:	e9 35 f3 ff ff       	jmp    80106979 <alltraps>

80107644 <vector168>:
.globl vector168
vector168:
  pushl $0
80107644:	6a 00                	push   $0x0
  pushl $168
80107646:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010764b:	e9 29 f3 ff ff       	jmp    80106979 <alltraps>

80107650 <vector169>:
.globl vector169
vector169:
  pushl $0
80107650:	6a 00                	push   $0x0
  pushl $169
80107652:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107657:	e9 1d f3 ff ff       	jmp    80106979 <alltraps>

8010765c <vector170>:
.globl vector170
vector170:
  pushl $0
8010765c:	6a 00                	push   $0x0
  pushl $170
8010765e:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107663:	e9 11 f3 ff ff       	jmp    80106979 <alltraps>

80107668 <vector171>:
.globl vector171
vector171:
  pushl $0
80107668:	6a 00                	push   $0x0
  pushl $171
8010766a:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
8010766f:	e9 05 f3 ff ff       	jmp    80106979 <alltraps>

80107674 <vector172>:
.globl vector172
vector172:
  pushl $0
80107674:	6a 00                	push   $0x0
  pushl $172
80107676:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
8010767b:	e9 f9 f2 ff ff       	jmp    80106979 <alltraps>

80107680 <vector173>:
.globl vector173
vector173:
  pushl $0
80107680:	6a 00                	push   $0x0
  pushl $173
80107682:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107687:	e9 ed f2 ff ff       	jmp    80106979 <alltraps>

8010768c <vector174>:
.globl vector174
vector174:
  pushl $0
8010768c:	6a 00                	push   $0x0
  pushl $174
8010768e:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107693:	e9 e1 f2 ff ff       	jmp    80106979 <alltraps>

80107698 <vector175>:
.globl vector175
vector175:
  pushl $0
80107698:	6a 00                	push   $0x0
  pushl $175
8010769a:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
8010769f:	e9 d5 f2 ff ff       	jmp    80106979 <alltraps>

801076a4 <vector176>:
.globl vector176
vector176:
  pushl $0
801076a4:	6a 00                	push   $0x0
  pushl $176
801076a6:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801076ab:	e9 c9 f2 ff ff       	jmp    80106979 <alltraps>

801076b0 <vector177>:
.globl vector177
vector177:
  pushl $0
801076b0:	6a 00                	push   $0x0
  pushl $177
801076b2:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801076b7:	e9 bd f2 ff ff       	jmp    80106979 <alltraps>

801076bc <vector178>:
.globl vector178
vector178:
  pushl $0
801076bc:	6a 00                	push   $0x0
  pushl $178
801076be:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801076c3:	e9 b1 f2 ff ff       	jmp    80106979 <alltraps>

801076c8 <vector179>:
.globl vector179
vector179:
  pushl $0
801076c8:	6a 00                	push   $0x0
  pushl $179
801076ca:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801076cf:	e9 a5 f2 ff ff       	jmp    80106979 <alltraps>

801076d4 <vector180>:
.globl vector180
vector180:
  pushl $0
801076d4:	6a 00                	push   $0x0
  pushl $180
801076d6:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801076db:	e9 99 f2 ff ff       	jmp    80106979 <alltraps>

801076e0 <vector181>:
.globl vector181
vector181:
  pushl $0
801076e0:	6a 00                	push   $0x0
  pushl $181
801076e2:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801076e7:	e9 8d f2 ff ff       	jmp    80106979 <alltraps>

801076ec <vector182>:
.globl vector182
vector182:
  pushl $0
801076ec:	6a 00                	push   $0x0
  pushl $182
801076ee:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801076f3:	e9 81 f2 ff ff       	jmp    80106979 <alltraps>

801076f8 <vector183>:
.globl vector183
vector183:
  pushl $0
801076f8:	6a 00                	push   $0x0
  pushl $183
801076fa:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801076ff:	e9 75 f2 ff ff       	jmp    80106979 <alltraps>

80107704 <vector184>:
.globl vector184
vector184:
  pushl $0
80107704:	6a 00                	push   $0x0
  pushl $184
80107706:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010770b:	e9 69 f2 ff ff       	jmp    80106979 <alltraps>

80107710 <vector185>:
.globl vector185
vector185:
  pushl $0
80107710:	6a 00                	push   $0x0
  pushl $185
80107712:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107717:	e9 5d f2 ff ff       	jmp    80106979 <alltraps>

8010771c <vector186>:
.globl vector186
vector186:
  pushl $0
8010771c:	6a 00                	push   $0x0
  pushl $186
8010771e:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107723:	e9 51 f2 ff ff       	jmp    80106979 <alltraps>

80107728 <vector187>:
.globl vector187
vector187:
  pushl $0
80107728:	6a 00                	push   $0x0
  pushl $187
8010772a:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010772f:	e9 45 f2 ff ff       	jmp    80106979 <alltraps>

80107734 <vector188>:
.globl vector188
vector188:
  pushl $0
80107734:	6a 00                	push   $0x0
  pushl $188
80107736:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
8010773b:	e9 39 f2 ff ff       	jmp    80106979 <alltraps>

80107740 <vector189>:
.globl vector189
vector189:
  pushl $0
80107740:	6a 00                	push   $0x0
  pushl $189
80107742:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107747:	e9 2d f2 ff ff       	jmp    80106979 <alltraps>

8010774c <vector190>:
.globl vector190
vector190:
  pushl $0
8010774c:	6a 00                	push   $0x0
  pushl $190
8010774e:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107753:	e9 21 f2 ff ff       	jmp    80106979 <alltraps>

80107758 <vector191>:
.globl vector191
vector191:
  pushl $0
80107758:	6a 00                	push   $0x0
  pushl $191
8010775a:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010775f:	e9 15 f2 ff ff       	jmp    80106979 <alltraps>

80107764 <vector192>:
.globl vector192
vector192:
  pushl $0
80107764:	6a 00                	push   $0x0
  pushl $192
80107766:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
8010776b:	e9 09 f2 ff ff       	jmp    80106979 <alltraps>

80107770 <vector193>:
.globl vector193
vector193:
  pushl $0
80107770:	6a 00                	push   $0x0
  pushl $193
80107772:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107777:	e9 fd f1 ff ff       	jmp    80106979 <alltraps>

8010777c <vector194>:
.globl vector194
vector194:
  pushl $0
8010777c:	6a 00                	push   $0x0
  pushl $194
8010777e:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107783:	e9 f1 f1 ff ff       	jmp    80106979 <alltraps>

80107788 <vector195>:
.globl vector195
vector195:
  pushl $0
80107788:	6a 00                	push   $0x0
  pushl $195
8010778a:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
8010778f:	e9 e5 f1 ff ff       	jmp    80106979 <alltraps>

80107794 <vector196>:
.globl vector196
vector196:
  pushl $0
80107794:	6a 00                	push   $0x0
  pushl $196
80107796:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
8010779b:	e9 d9 f1 ff ff       	jmp    80106979 <alltraps>

801077a0 <vector197>:
.globl vector197
vector197:
  pushl $0
801077a0:	6a 00                	push   $0x0
  pushl $197
801077a2:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801077a7:	e9 cd f1 ff ff       	jmp    80106979 <alltraps>

801077ac <vector198>:
.globl vector198
vector198:
  pushl $0
801077ac:	6a 00                	push   $0x0
  pushl $198
801077ae:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801077b3:	e9 c1 f1 ff ff       	jmp    80106979 <alltraps>

801077b8 <vector199>:
.globl vector199
vector199:
  pushl $0
801077b8:	6a 00                	push   $0x0
  pushl $199
801077ba:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801077bf:	e9 b5 f1 ff ff       	jmp    80106979 <alltraps>

801077c4 <vector200>:
.globl vector200
vector200:
  pushl $0
801077c4:	6a 00                	push   $0x0
  pushl $200
801077c6:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801077cb:	e9 a9 f1 ff ff       	jmp    80106979 <alltraps>

801077d0 <vector201>:
.globl vector201
vector201:
  pushl $0
801077d0:	6a 00                	push   $0x0
  pushl $201
801077d2:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801077d7:	e9 9d f1 ff ff       	jmp    80106979 <alltraps>

801077dc <vector202>:
.globl vector202
vector202:
  pushl $0
801077dc:	6a 00                	push   $0x0
  pushl $202
801077de:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801077e3:	e9 91 f1 ff ff       	jmp    80106979 <alltraps>

801077e8 <vector203>:
.globl vector203
vector203:
  pushl $0
801077e8:	6a 00                	push   $0x0
  pushl $203
801077ea:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801077ef:	e9 85 f1 ff ff       	jmp    80106979 <alltraps>

801077f4 <vector204>:
.globl vector204
vector204:
  pushl $0
801077f4:	6a 00                	push   $0x0
  pushl $204
801077f6:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801077fb:	e9 79 f1 ff ff       	jmp    80106979 <alltraps>

80107800 <vector205>:
.globl vector205
vector205:
  pushl $0
80107800:	6a 00                	push   $0x0
  pushl $205
80107802:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107807:	e9 6d f1 ff ff       	jmp    80106979 <alltraps>

8010780c <vector206>:
.globl vector206
vector206:
  pushl $0
8010780c:	6a 00                	push   $0x0
  pushl $206
8010780e:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107813:	e9 61 f1 ff ff       	jmp    80106979 <alltraps>

80107818 <vector207>:
.globl vector207
vector207:
  pushl $0
80107818:	6a 00                	push   $0x0
  pushl $207
8010781a:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010781f:	e9 55 f1 ff ff       	jmp    80106979 <alltraps>

80107824 <vector208>:
.globl vector208
vector208:
  pushl $0
80107824:	6a 00                	push   $0x0
  pushl $208
80107826:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
8010782b:	e9 49 f1 ff ff       	jmp    80106979 <alltraps>

80107830 <vector209>:
.globl vector209
vector209:
  pushl $0
80107830:	6a 00                	push   $0x0
  pushl $209
80107832:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107837:	e9 3d f1 ff ff       	jmp    80106979 <alltraps>

8010783c <vector210>:
.globl vector210
vector210:
  pushl $0
8010783c:	6a 00                	push   $0x0
  pushl $210
8010783e:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107843:	e9 31 f1 ff ff       	jmp    80106979 <alltraps>

80107848 <vector211>:
.globl vector211
vector211:
  pushl $0
80107848:	6a 00                	push   $0x0
  pushl $211
8010784a:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010784f:	e9 25 f1 ff ff       	jmp    80106979 <alltraps>

80107854 <vector212>:
.globl vector212
vector212:
  pushl $0
80107854:	6a 00                	push   $0x0
  pushl $212
80107856:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
8010785b:	e9 19 f1 ff ff       	jmp    80106979 <alltraps>

80107860 <vector213>:
.globl vector213
vector213:
  pushl $0
80107860:	6a 00                	push   $0x0
  pushl $213
80107862:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107867:	e9 0d f1 ff ff       	jmp    80106979 <alltraps>

8010786c <vector214>:
.globl vector214
vector214:
  pushl $0
8010786c:	6a 00                	push   $0x0
  pushl $214
8010786e:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107873:	e9 01 f1 ff ff       	jmp    80106979 <alltraps>

80107878 <vector215>:
.globl vector215
vector215:
  pushl $0
80107878:	6a 00                	push   $0x0
  pushl $215
8010787a:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
8010787f:	e9 f5 f0 ff ff       	jmp    80106979 <alltraps>

80107884 <vector216>:
.globl vector216
vector216:
  pushl $0
80107884:	6a 00                	push   $0x0
  pushl $216
80107886:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
8010788b:	e9 e9 f0 ff ff       	jmp    80106979 <alltraps>

80107890 <vector217>:
.globl vector217
vector217:
  pushl $0
80107890:	6a 00                	push   $0x0
  pushl $217
80107892:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107897:	e9 dd f0 ff ff       	jmp    80106979 <alltraps>

8010789c <vector218>:
.globl vector218
vector218:
  pushl $0
8010789c:	6a 00                	push   $0x0
  pushl $218
8010789e:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801078a3:	e9 d1 f0 ff ff       	jmp    80106979 <alltraps>

801078a8 <vector219>:
.globl vector219
vector219:
  pushl $0
801078a8:	6a 00                	push   $0x0
  pushl $219
801078aa:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801078af:	e9 c5 f0 ff ff       	jmp    80106979 <alltraps>

801078b4 <vector220>:
.globl vector220
vector220:
  pushl $0
801078b4:	6a 00                	push   $0x0
  pushl $220
801078b6:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801078bb:	e9 b9 f0 ff ff       	jmp    80106979 <alltraps>

801078c0 <vector221>:
.globl vector221
vector221:
  pushl $0
801078c0:	6a 00                	push   $0x0
  pushl $221
801078c2:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801078c7:	e9 ad f0 ff ff       	jmp    80106979 <alltraps>

801078cc <vector222>:
.globl vector222
vector222:
  pushl $0
801078cc:	6a 00                	push   $0x0
  pushl $222
801078ce:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801078d3:	e9 a1 f0 ff ff       	jmp    80106979 <alltraps>

801078d8 <vector223>:
.globl vector223
vector223:
  pushl $0
801078d8:	6a 00                	push   $0x0
  pushl $223
801078da:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801078df:	e9 95 f0 ff ff       	jmp    80106979 <alltraps>

801078e4 <vector224>:
.globl vector224
vector224:
  pushl $0
801078e4:	6a 00                	push   $0x0
  pushl $224
801078e6:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801078eb:	e9 89 f0 ff ff       	jmp    80106979 <alltraps>

801078f0 <vector225>:
.globl vector225
vector225:
  pushl $0
801078f0:	6a 00                	push   $0x0
  pushl $225
801078f2:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801078f7:	e9 7d f0 ff ff       	jmp    80106979 <alltraps>

801078fc <vector226>:
.globl vector226
vector226:
  pushl $0
801078fc:	6a 00                	push   $0x0
  pushl $226
801078fe:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107903:	e9 71 f0 ff ff       	jmp    80106979 <alltraps>

80107908 <vector227>:
.globl vector227
vector227:
  pushl $0
80107908:	6a 00                	push   $0x0
  pushl $227
8010790a:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010790f:	e9 65 f0 ff ff       	jmp    80106979 <alltraps>

80107914 <vector228>:
.globl vector228
vector228:
  pushl $0
80107914:	6a 00                	push   $0x0
  pushl $228
80107916:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
8010791b:	e9 59 f0 ff ff       	jmp    80106979 <alltraps>

80107920 <vector229>:
.globl vector229
vector229:
  pushl $0
80107920:	6a 00                	push   $0x0
  pushl $229
80107922:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107927:	e9 4d f0 ff ff       	jmp    80106979 <alltraps>

8010792c <vector230>:
.globl vector230
vector230:
  pushl $0
8010792c:	6a 00                	push   $0x0
  pushl $230
8010792e:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107933:	e9 41 f0 ff ff       	jmp    80106979 <alltraps>

80107938 <vector231>:
.globl vector231
vector231:
  pushl $0
80107938:	6a 00                	push   $0x0
  pushl $231
8010793a:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010793f:	e9 35 f0 ff ff       	jmp    80106979 <alltraps>

80107944 <vector232>:
.globl vector232
vector232:
  pushl $0
80107944:	6a 00                	push   $0x0
  pushl $232
80107946:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
8010794b:	e9 29 f0 ff ff       	jmp    80106979 <alltraps>

80107950 <vector233>:
.globl vector233
vector233:
  pushl $0
80107950:	6a 00                	push   $0x0
  pushl $233
80107952:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107957:	e9 1d f0 ff ff       	jmp    80106979 <alltraps>

8010795c <vector234>:
.globl vector234
vector234:
  pushl $0
8010795c:	6a 00                	push   $0x0
  pushl $234
8010795e:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107963:	e9 11 f0 ff ff       	jmp    80106979 <alltraps>

80107968 <vector235>:
.globl vector235
vector235:
  pushl $0
80107968:	6a 00                	push   $0x0
  pushl $235
8010796a:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010796f:	e9 05 f0 ff ff       	jmp    80106979 <alltraps>

80107974 <vector236>:
.globl vector236
vector236:
  pushl $0
80107974:	6a 00                	push   $0x0
  pushl $236
80107976:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010797b:	e9 f9 ef ff ff       	jmp    80106979 <alltraps>

80107980 <vector237>:
.globl vector237
vector237:
  pushl $0
80107980:	6a 00                	push   $0x0
  pushl $237
80107982:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107987:	e9 ed ef ff ff       	jmp    80106979 <alltraps>

8010798c <vector238>:
.globl vector238
vector238:
  pushl $0
8010798c:	6a 00                	push   $0x0
  pushl $238
8010798e:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107993:	e9 e1 ef ff ff       	jmp    80106979 <alltraps>

80107998 <vector239>:
.globl vector239
vector239:
  pushl $0
80107998:	6a 00                	push   $0x0
  pushl $239
8010799a:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
8010799f:	e9 d5 ef ff ff       	jmp    80106979 <alltraps>

801079a4 <vector240>:
.globl vector240
vector240:
  pushl $0
801079a4:	6a 00                	push   $0x0
  pushl $240
801079a6:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801079ab:	e9 c9 ef ff ff       	jmp    80106979 <alltraps>

801079b0 <vector241>:
.globl vector241
vector241:
  pushl $0
801079b0:	6a 00                	push   $0x0
  pushl $241
801079b2:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801079b7:	e9 bd ef ff ff       	jmp    80106979 <alltraps>

801079bc <vector242>:
.globl vector242
vector242:
  pushl $0
801079bc:	6a 00                	push   $0x0
  pushl $242
801079be:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801079c3:	e9 b1 ef ff ff       	jmp    80106979 <alltraps>

801079c8 <vector243>:
.globl vector243
vector243:
  pushl $0
801079c8:	6a 00                	push   $0x0
  pushl $243
801079ca:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801079cf:	e9 a5 ef ff ff       	jmp    80106979 <alltraps>

801079d4 <vector244>:
.globl vector244
vector244:
  pushl $0
801079d4:	6a 00                	push   $0x0
  pushl $244
801079d6:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801079db:	e9 99 ef ff ff       	jmp    80106979 <alltraps>

801079e0 <vector245>:
.globl vector245
vector245:
  pushl $0
801079e0:	6a 00                	push   $0x0
  pushl $245
801079e2:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801079e7:	e9 8d ef ff ff       	jmp    80106979 <alltraps>

801079ec <vector246>:
.globl vector246
vector246:
  pushl $0
801079ec:	6a 00                	push   $0x0
  pushl $246
801079ee:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801079f3:	e9 81 ef ff ff       	jmp    80106979 <alltraps>

801079f8 <vector247>:
.globl vector247
vector247:
  pushl $0
801079f8:	6a 00                	push   $0x0
  pushl $247
801079fa:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801079ff:	e9 75 ef ff ff       	jmp    80106979 <alltraps>

80107a04 <vector248>:
.globl vector248
vector248:
  pushl $0
80107a04:	6a 00                	push   $0x0
  pushl $248
80107a06:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107a0b:	e9 69 ef ff ff       	jmp    80106979 <alltraps>

80107a10 <vector249>:
.globl vector249
vector249:
  pushl $0
80107a10:	6a 00                	push   $0x0
  pushl $249
80107a12:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107a17:	e9 5d ef ff ff       	jmp    80106979 <alltraps>

80107a1c <vector250>:
.globl vector250
vector250:
  pushl $0
80107a1c:	6a 00                	push   $0x0
  pushl $250
80107a1e:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107a23:	e9 51 ef ff ff       	jmp    80106979 <alltraps>

80107a28 <vector251>:
.globl vector251
vector251:
  pushl $0
80107a28:	6a 00                	push   $0x0
  pushl $251
80107a2a:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107a2f:	e9 45 ef ff ff       	jmp    80106979 <alltraps>

80107a34 <vector252>:
.globl vector252
vector252:
  pushl $0
80107a34:	6a 00                	push   $0x0
  pushl $252
80107a36:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107a3b:	e9 39 ef ff ff       	jmp    80106979 <alltraps>

80107a40 <vector253>:
.globl vector253
vector253:
  pushl $0
80107a40:	6a 00                	push   $0x0
  pushl $253
80107a42:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107a47:	e9 2d ef ff ff       	jmp    80106979 <alltraps>

80107a4c <vector254>:
.globl vector254
vector254:
  pushl $0
80107a4c:	6a 00                	push   $0x0
  pushl $254
80107a4e:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107a53:	e9 21 ef ff ff       	jmp    80106979 <alltraps>

80107a58 <vector255>:
.globl vector255
vector255:
  pushl $0
80107a58:	6a 00                	push   $0x0
  pushl $255
80107a5a:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107a5f:	e9 15 ef ff ff       	jmp    80106979 <alltraps>

80107a64 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107a64:	55                   	push   %ebp
80107a65:	89 e5                	mov    %esp,%ebp
80107a67:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107a6a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a6d:	83 e8 01             	sub    $0x1,%eax
80107a70:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107a74:	8b 45 08             	mov    0x8(%ebp),%eax
80107a77:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107a7b:	8b 45 08             	mov    0x8(%ebp),%eax
80107a7e:	c1 e8 10             	shr    $0x10,%eax
80107a81:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107a85:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107a88:	0f 01 10             	lgdtl  (%eax)
}
80107a8b:	c9                   	leave  
80107a8c:	c3                   	ret    

80107a8d <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107a8d:	55                   	push   %ebp
80107a8e:	89 e5                	mov    %esp,%ebp
80107a90:	83 ec 04             	sub    $0x4,%esp
80107a93:	8b 45 08             	mov    0x8(%ebp),%eax
80107a96:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107a9a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107a9e:	0f 00 d8             	ltr    %ax
}
80107aa1:	c9                   	leave  
80107aa2:	c3                   	ret    

80107aa3 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107aa3:	55                   	push   %ebp
80107aa4:	89 e5                	mov    %esp,%ebp
80107aa6:	83 ec 04             	sub    $0x4,%esp
80107aa9:	8b 45 08             	mov    0x8(%ebp),%eax
80107aac:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107ab0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107ab4:	8e e8                	mov    %eax,%gs
}
80107ab6:	c9                   	leave  
80107ab7:	c3                   	ret    

80107ab8 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107ab8:	55                   	push   %ebp
80107ab9:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107abb:	8b 45 08             	mov    0x8(%ebp),%eax
80107abe:	0f 22 d8             	mov    %eax,%cr3
}
80107ac1:	5d                   	pop    %ebp
80107ac2:	c3                   	ret    

80107ac3 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107ac3:	55                   	push   %ebp
80107ac4:	89 e5                	mov    %esp,%ebp
80107ac6:	8b 45 08             	mov    0x8(%ebp),%eax
80107ac9:	05 00 00 00 80       	add    $0x80000000,%eax
80107ace:	5d                   	pop    %ebp
80107acf:	c3                   	ret    

80107ad0 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107ad0:	55                   	push   %ebp
80107ad1:	89 e5                	mov    %esp,%ebp
80107ad3:	8b 45 08             	mov    0x8(%ebp),%eax
80107ad6:	05 00 00 00 80       	add    $0x80000000,%eax
80107adb:	5d                   	pop    %ebp
80107adc:	c3                   	ret    

80107add <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107add:	55                   	push   %ebp
80107ade:	89 e5                	mov    %esp,%ebp
80107ae0:	53                   	push   %ebx
80107ae1:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107ae4:	e8 d2 b8 ff ff       	call   801033bb <cpunum>
80107ae9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107aef:	05 c0 2b 11 80       	add    $0x80112bc0,%eax
80107af4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107afa:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107b00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b03:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107b09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b0c:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107b10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b13:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107b17:	83 e2 f0             	and    $0xfffffff0,%edx
80107b1a:	83 ca 0a             	or     $0xa,%edx
80107b1d:	88 50 7d             	mov    %dl,0x7d(%eax)
80107b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b23:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107b27:	83 ca 10             	or     $0x10,%edx
80107b2a:	88 50 7d             	mov    %dl,0x7d(%eax)
80107b2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b30:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107b34:	83 e2 9f             	and    $0xffffff9f,%edx
80107b37:	88 50 7d             	mov    %dl,0x7d(%eax)
80107b3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b3d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107b41:	83 ca 80             	or     $0xffffff80,%edx
80107b44:	88 50 7d             	mov    %dl,0x7d(%eax)
80107b47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b4a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b4e:	83 ca 0f             	or     $0xf,%edx
80107b51:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b57:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b5b:	83 e2 ef             	and    $0xffffffef,%edx
80107b5e:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b64:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b68:	83 e2 df             	and    $0xffffffdf,%edx
80107b6b:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b71:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b75:	83 ca 40             	or     $0x40,%edx
80107b78:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b7e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b82:	83 ca 80             	or     $0xffffff80,%edx
80107b85:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b8b:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b92:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107b99:	ff ff 
80107b9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b9e:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107ba5:	00 00 
80107ba7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107baa:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107bb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bb4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107bbb:	83 e2 f0             	and    $0xfffffff0,%edx
80107bbe:	83 ca 02             	or     $0x2,%edx
80107bc1:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107bc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bca:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107bd1:	83 ca 10             	or     $0x10,%edx
80107bd4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bdd:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107be4:	83 e2 9f             	and    $0xffffff9f,%edx
80107be7:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107bed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bf0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107bf7:	83 ca 80             	or     $0xffffff80,%edx
80107bfa:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107c00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c03:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c0a:	83 ca 0f             	or     $0xf,%edx
80107c0d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c16:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c1d:	83 e2 ef             	and    $0xffffffef,%edx
80107c20:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c29:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c30:	83 e2 df             	and    $0xffffffdf,%edx
80107c33:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c3c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c43:	83 ca 40             	or     $0x40,%edx
80107c46:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c4f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c56:	83 ca 80             	or     $0xffffff80,%edx
80107c59:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c62:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107c69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c6c:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107c73:	ff ff 
80107c75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c78:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107c7f:	00 00 
80107c81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c84:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107c8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c8e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c95:	83 e2 f0             	and    $0xfffffff0,%edx
80107c98:	83 ca 0a             	or     $0xa,%edx
80107c9b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107ca1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ca4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107cab:	83 ca 10             	or     $0x10,%edx
80107cae:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107cb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cb7:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107cbe:	83 ca 60             	or     $0x60,%edx
80107cc1:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107cc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cca:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107cd1:	83 ca 80             	or     $0xffffff80,%edx
80107cd4:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107cda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cdd:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107ce4:	83 ca 0f             	or     $0xf,%edx
80107ce7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107ced:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cf0:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107cf7:	83 e2 ef             	and    $0xffffffef,%edx
80107cfa:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107d00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d03:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107d0a:	83 e2 df             	and    $0xffffffdf,%edx
80107d0d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107d13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d16:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107d1d:	83 ca 40             	or     $0x40,%edx
80107d20:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107d26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d29:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107d30:	83 ca 80             	or     $0xffffff80,%edx
80107d33:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107d39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d3c:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107d43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d46:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107d4d:	ff ff 
80107d4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d52:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107d59:	00 00 
80107d5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d5e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107d65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d68:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d6f:	83 e2 f0             	and    $0xfffffff0,%edx
80107d72:	83 ca 02             	or     $0x2,%edx
80107d75:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d7e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d85:	83 ca 10             	or     $0x10,%edx
80107d88:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d91:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d98:	83 ca 60             	or     $0x60,%edx
80107d9b:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107da1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da4:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107dab:	83 ca 80             	or     $0xffffff80,%edx
80107dae:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107db4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107dbe:	83 ca 0f             	or     $0xf,%edx
80107dc1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107dc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dca:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107dd1:	83 e2 ef             	and    $0xffffffef,%edx
80107dd4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107dda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ddd:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107de4:	83 e2 df             	and    $0xffffffdf,%edx
80107de7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107ded:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107df0:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107df7:	83 ca 40             	or     $0x40,%edx
80107dfa:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107e00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e03:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107e0a:	83 ca 80             	or     $0xffffff80,%edx
80107e0d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107e13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e16:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e20:	05 b4 00 00 00       	add    $0xb4,%eax
80107e25:	89 c3                	mov    %eax,%ebx
80107e27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e2a:	05 b4 00 00 00       	add    $0xb4,%eax
80107e2f:	c1 e8 10             	shr    $0x10,%eax
80107e32:	89 c1                	mov    %eax,%ecx
80107e34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e37:	05 b4 00 00 00       	add    $0xb4,%eax
80107e3c:	c1 e8 18             	shr    $0x18,%eax
80107e3f:	89 c2                	mov    %eax,%edx
80107e41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e44:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107e4b:	00 00 
80107e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e50:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e5a:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107e60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e63:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e6a:	83 e1 f0             	and    $0xfffffff0,%ecx
80107e6d:	83 c9 02             	or     $0x2,%ecx
80107e70:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e79:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e80:	83 c9 10             	or     $0x10,%ecx
80107e83:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e8c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e93:	83 e1 9f             	and    $0xffffff9f,%ecx
80107e96:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e9f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107ea6:	83 c9 80             	or     $0xffffff80,%ecx
80107ea9:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107eaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107eb2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107eb9:	83 e1 f0             	and    $0xfffffff0,%ecx
80107ebc:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ec2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ec5:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107ecc:	83 e1 ef             	and    $0xffffffef,%ecx
80107ecf:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ed5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ed8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107edf:	83 e1 df             	and    $0xffffffdf,%ecx
80107ee2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ee8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107eeb:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107ef2:	83 c9 40             	or     $0x40,%ecx
80107ef5:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107efb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107efe:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107f05:	83 c9 80             	or     $0xffffff80,%ecx
80107f08:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107f0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f11:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107f17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f1a:	83 c0 70             	add    $0x70,%eax
80107f1d:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107f24:	00 
80107f25:	89 04 24             	mov    %eax,(%esp)
80107f28:	e8 37 fb ff ff       	call   80107a64 <lgdt>
  loadgs(SEG_KCPU << 3);
80107f2d:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107f34:	e8 6a fb ff ff       	call   80107aa3 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107f39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f3c:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107f42:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107f49:	00 00 00 00 
}
80107f4d:	83 c4 24             	add    $0x24,%esp
80107f50:	5b                   	pop    %ebx
80107f51:	5d                   	pop    %ebp
80107f52:	c3                   	ret    

80107f53 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107f53:	55                   	push   %ebp
80107f54:	89 e5                	mov    %esp,%ebp
80107f56:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107f59:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f5c:	c1 e8 16             	shr    $0x16,%eax
80107f5f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107f66:	8b 45 08             	mov    0x8(%ebp),%eax
80107f69:	01 d0                	add    %edx,%eax
80107f6b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107f6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f71:	8b 00                	mov    (%eax),%eax
80107f73:	83 e0 01             	and    $0x1,%eax
80107f76:	85 c0                	test   %eax,%eax
80107f78:	74 17                	je     80107f91 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107f7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f7d:	8b 00                	mov    (%eax),%eax
80107f7f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f84:	89 04 24             	mov    %eax,(%esp)
80107f87:	e8 44 fb ff ff       	call   80107ad0 <p2v>
80107f8c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107f8f:	eb 4b                	jmp    80107fdc <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107f91:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107f95:	74 0e                	je     80107fa5 <walkpgdir+0x52>
80107f97:	e8 89 b0 ff ff       	call   80103025 <kalloc>
80107f9c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107f9f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107fa3:	75 07                	jne    80107fac <walkpgdir+0x59>
      return 0;
80107fa5:	b8 00 00 00 00       	mov    $0x0,%eax
80107faa:	eb 47                	jmp    80107ff3 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107fac:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107fb3:	00 
80107fb4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107fbb:	00 
80107fbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fbf:	89 04 24             	mov    %eax,(%esp)
80107fc2:	e8 be d5 ff ff       	call   80105585 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107fc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fca:	89 04 24             	mov    %eax,(%esp)
80107fcd:	e8 f1 fa ff ff       	call   80107ac3 <v2p>
80107fd2:	83 c8 07             	or     $0x7,%eax
80107fd5:	89 c2                	mov    %eax,%edx
80107fd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107fda:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107fdc:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fdf:	c1 e8 0c             	shr    $0xc,%eax
80107fe2:	25 ff 03 00 00       	and    $0x3ff,%eax
80107fe7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107fee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff1:	01 d0                	add    %edx,%eax
}
80107ff3:	c9                   	leave  
80107ff4:	c3                   	ret    

80107ff5 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107ff5:	55                   	push   %ebp
80107ff6:	89 e5                	mov    %esp,%ebp
80107ff8:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107ffb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ffe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108003:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108006:	8b 55 0c             	mov    0xc(%ebp),%edx
80108009:	8b 45 10             	mov    0x10(%ebp),%eax
8010800c:	01 d0                	add    %edx,%eax
8010800e:	83 e8 01             	sub    $0x1,%eax
80108011:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108016:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108019:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108020:	00 
80108021:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108024:	89 44 24 04          	mov    %eax,0x4(%esp)
80108028:	8b 45 08             	mov    0x8(%ebp),%eax
8010802b:	89 04 24             	mov    %eax,(%esp)
8010802e:	e8 20 ff ff ff       	call   80107f53 <walkpgdir>
80108033:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108036:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010803a:	75 07                	jne    80108043 <mappages+0x4e>
      return -1;
8010803c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108041:	eb 48                	jmp    8010808b <mappages+0x96>
    if(*pte & PTE_P)
80108043:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108046:	8b 00                	mov    (%eax),%eax
80108048:	83 e0 01             	and    $0x1,%eax
8010804b:	85 c0                	test   %eax,%eax
8010804d:	74 0c                	je     8010805b <mappages+0x66>
      panic("remap");
8010804f:	c7 04 24 fc 8e 10 80 	movl   $0x80108efc,(%esp)
80108056:	e8 df 84 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
8010805b:	8b 45 18             	mov    0x18(%ebp),%eax
8010805e:	0b 45 14             	or     0x14(%ebp),%eax
80108061:	83 c8 01             	or     $0x1,%eax
80108064:	89 c2                	mov    %eax,%edx
80108066:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108069:	89 10                	mov    %edx,(%eax)
    if(a == last)
8010806b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108071:	75 08                	jne    8010807b <mappages+0x86>
      break;
80108073:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108074:	b8 00 00 00 00       	mov    $0x0,%eax
80108079:	eb 10                	jmp    8010808b <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
8010807b:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108082:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108089:	eb 8e                	jmp    80108019 <mappages+0x24>
  return 0;
}
8010808b:	c9                   	leave  
8010808c:	c3                   	ret    

8010808d <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
8010808d:	55                   	push   %ebp
8010808e:	89 e5                	mov    %esp,%ebp
80108090:	53                   	push   %ebx
80108091:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108094:	e8 8c af ff ff       	call   80103025 <kalloc>
80108099:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010809c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801080a0:	75 0a                	jne    801080ac <setupkvm+0x1f>
    return 0;
801080a2:	b8 00 00 00 00       	mov    $0x0,%eax
801080a7:	e9 98 00 00 00       	jmp    80108144 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801080ac:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801080b3:	00 
801080b4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801080bb:	00 
801080bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080bf:	89 04 24             	mov    %eax,(%esp)
801080c2:	e8 be d4 ff ff       	call   80105585 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801080c7:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801080ce:	e8 fd f9 ff ff       	call   80107ad0 <p2v>
801080d3:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801080d8:	76 0c                	jbe    801080e6 <setupkvm+0x59>
    panic("PHYSTOP too high");
801080da:	c7 04 24 02 8f 10 80 	movl   $0x80108f02,(%esp)
801080e1:	e8 54 84 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801080e6:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
801080ed:	eb 49                	jmp    80108138 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801080ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f2:	8b 48 0c             	mov    0xc(%eax),%ecx
801080f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f8:	8b 50 04             	mov    0x4(%eax),%edx
801080fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080fe:	8b 58 08             	mov    0x8(%eax),%ebx
80108101:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108104:	8b 40 04             	mov    0x4(%eax),%eax
80108107:	29 c3                	sub    %eax,%ebx
80108109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010810c:	8b 00                	mov    (%eax),%eax
8010810e:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108112:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108116:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010811a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010811e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108121:	89 04 24             	mov    %eax,(%esp)
80108124:	e8 cc fe ff ff       	call   80107ff5 <mappages>
80108129:	85 c0                	test   %eax,%eax
8010812b:	79 07                	jns    80108134 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
8010812d:	b8 00 00 00 00       	mov    $0x0,%eax
80108132:	eb 10                	jmp    80108144 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108134:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108138:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
8010813f:	72 ae                	jb     801080ef <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108141:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108144:	83 c4 34             	add    $0x34,%esp
80108147:	5b                   	pop    %ebx
80108148:	5d                   	pop    %ebp
80108149:	c3                   	ret    

8010814a <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
8010814a:	55                   	push   %ebp
8010814b:	89 e5                	mov    %esp,%ebp
8010814d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108150:	e8 38 ff ff ff       	call   8010808d <setupkvm>
80108155:	a3 98 59 11 80       	mov    %eax,0x80115998
  switchkvm();
8010815a:	e8 02 00 00 00       	call   80108161 <switchkvm>
}
8010815f:	c9                   	leave  
80108160:	c3                   	ret    

80108161 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108161:	55                   	push   %ebp
80108162:	89 e5                	mov    %esp,%ebp
80108164:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108167:	a1 98 59 11 80       	mov    0x80115998,%eax
8010816c:	89 04 24             	mov    %eax,(%esp)
8010816f:	e8 4f f9 ff ff       	call   80107ac3 <v2p>
80108174:	89 04 24             	mov    %eax,(%esp)
80108177:	e8 3c f9 ff ff       	call   80107ab8 <lcr3>
}
8010817c:	c9                   	leave  
8010817d:	c3                   	ret    

8010817e <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
8010817e:	55                   	push   %ebp
8010817f:	89 e5                	mov    %esp,%ebp
80108181:	53                   	push   %ebx
80108182:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108185:	e8 fb d2 ff ff       	call   80105485 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
8010818a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108190:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108197:	83 c2 08             	add    $0x8,%edx
8010819a:	89 d3                	mov    %edx,%ebx
8010819c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801081a3:	83 c2 08             	add    $0x8,%edx
801081a6:	c1 ea 10             	shr    $0x10,%edx
801081a9:	89 d1                	mov    %edx,%ecx
801081ab:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801081b2:	83 c2 08             	add    $0x8,%edx
801081b5:	c1 ea 18             	shr    $0x18,%edx
801081b8:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801081bf:	67 00 
801081c1:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
801081c8:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801081ce:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801081d5:	83 e1 f0             	and    $0xfffffff0,%ecx
801081d8:	83 c9 09             	or     $0x9,%ecx
801081db:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801081e1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801081e8:	83 c9 10             	or     $0x10,%ecx
801081eb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801081f1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801081f8:	83 e1 9f             	and    $0xffffff9f,%ecx
801081fb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108201:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108208:	83 c9 80             	or     $0xffffff80,%ecx
8010820b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108211:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108218:	83 e1 f0             	and    $0xfffffff0,%ecx
8010821b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108221:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108228:	83 e1 ef             	and    $0xffffffef,%ecx
8010822b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108231:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108238:	83 e1 df             	and    $0xffffffdf,%ecx
8010823b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108241:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108248:	83 c9 40             	or     $0x40,%ecx
8010824b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108251:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108258:	83 e1 7f             	and    $0x7f,%ecx
8010825b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108261:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108267:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010826d:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108274:	83 e2 ef             	and    $0xffffffef,%edx
80108277:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
8010827d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108283:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108289:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010828f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108296:	8b 52 08             	mov    0x8(%edx),%edx
80108299:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010829f:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801082a2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801082a9:	e8 df f7 ff ff       	call   80107a8d <ltr>
  if(p->pgdir == 0)
801082ae:	8b 45 08             	mov    0x8(%ebp),%eax
801082b1:	8b 40 04             	mov    0x4(%eax),%eax
801082b4:	85 c0                	test   %eax,%eax
801082b6:	75 0c                	jne    801082c4 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801082b8:	c7 04 24 13 8f 10 80 	movl   $0x80108f13,(%esp)
801082bf:	e8 76 82 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801082c4:	8b 45 08             	mov    0x8(%ebp),%eax
801082c7:	8b 40 04             	mov    0x4(%eax),%eax
801082ca:	89 04 24             	mov    %eax,(%esp)
801082cd:	e8 f1 f7 ff ff       	call   80107ac3 <v2p>
801082d2:	89 04 24             	mov    %eax,(%esp)
801082d5:	e8 de f7 ff ff       	call   80107ab8 <lcr3>
  popcli();
801082da:	e8 ea d1 ff ff       	call   801054c9 <popcli>
}
801082df:	83 c4 14             	add    $0x14,%esp
801082e2:	5b                   	pop    %ebx
801082e3:	5d                   	pop    %ebp
801082e4:	c3                   	ret    

801082e5 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801082e5:	55                   	push   %ebp
801082e6:	89 e5                	mov    %esp,%ebp
801082e8:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801082eb:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801082f2:	76 0c                	jbe    80108300 <inituvm+0x1b>
    panic("inituvm: more than a page");
801082f4:	c7 04 24 27 8f 10 80 	movl   $0x80108f27,(%esp)
801082fb:	e8 3a 82 ff ff       	call   8010053a <panic>
  mem = kalloc();
80108300:	e8 20 ad ff ff       	call   80103025 <kalloc>
80108305:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108308:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010830f:	00 
80108310:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108317:	00 
80108318:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010831b:	89 04 24             	mov    %eax,(%esp)
8010831e:	e8 62 d2 ff ff       	call   80105585 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108326:	89 04 24             	mov    %eax,(%esp)
80108329:	e8 95 f7 ff ff       	call   80107ac3 <v2p>
8010832e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108335:	00 
80108336:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010833a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108341:	00 
80108342:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108349:	00 
8010834a:	8b 45 08             	mov    0x8(%ebp),%eax
8010834d:	89 04 24             	mov    %eax,(%esp)
80108350:	e8 a0 fc ff ff       	call   80107ff5 <mappages>
  memmove(mem, init, sz);
80108355:	8b 45 10             	mov    0x10(%ebp),%eax
80108358:	89 44 24 08          	mov    %eax,0x8(%esp)
8010835c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010835f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108363:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108366:	89 04 24             	mov    %eax,(%esp)
80108369:	e8 e6 d2 ff ff       	call   80105654 <memmove>
}
8010836e:	c9                   	leave  
8010836f:	c3                   	ret    

80108370 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108370:	55                   	push   %ebp
80108371:	89 e5                	mov    %esp,%ebp
80108373:	53                   	push   %ebx
80108374:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108377:	8b 45 0c             	mov    0xc(%ebp),%eax
8010837a:	25 ff 0f 00 00       	and    $0xfff,%eax
8010837f:	85 c0                	test   %eax,%eax
80108381:	74 0c                	je     8010838f <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108383:	c7 04 24 44 8f 10 80 	movl   $0x80108f44,(%esp)
8010838a:	e8 ab 81 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
8010838f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108396:	e9 a9 00 00 00       	jmp    80108444 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010839b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010839e:	8b 55 0c             	mov    0xc(%ebp),%edx
801083a1:	01 d0                	add    %edx,%eax
801083a3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801083aa:	00 
801083ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801083af:	8b 45 08             	mov    0x8(%ebp),%eax
801083b2:	89 04 24             	mov    %eax,(%esp)
801083b5:	e8 99 fb ff ff       	call   80107f53 <walkpgdir>
801083ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
801083bd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801083c1:	75 0c                	jne    801083cf <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801083c3:	c7 04 24 67 8f 10 80 	movl   $0x80108f67,(%esp)
801083ca:	e8 6b 81 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801083cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083d2:	8b 00                	mov    (%eax),%eax
801083d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083d9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801083dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083df:	8b 55 18             	mov    0x18(%ebp),%edx
801083e2:	29 c2                	sub    %eax,%edx
801083e4:	89 d0                	mov    %edx,%eax
801083e6:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801083eb:	77 0f                	ja     801083fc <loaduvm+0x8c>
      n = sz - i;
801083ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083f0:	8b 55 18             	mov    0x18(%ebp),%edx
801083f3:	29 c2                	sub    %eax,%edx
801083f5:	89 d0                	mov    %edx,%eax
801083f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801083fa:	eb 07                	jmp    80108403 <loaduvm+0x93>
    else
      n = PGSIZE;
801083fc:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108406:	8b 55 14             	mov    0x14(%ebp),%edx
80108409:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010840c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010840f:	89 04 24             	mov    %eax,(%esp)
80108412:	e8 b9 f6 ff ff       	call   80107ad0 <p2v>
80108417:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010841a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010841e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108422:	89 44 24 04          	mov    %eax,0x4(%esp)
80108426:	8b 45 10             	mov    0x10(%ebp),%eax
80108429:	89 04 24             	mov    %eax,(%esp)
8010842c:	e8 43 9e ff ff       	call   80102274 <readi>
80108431:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108434:	74 07                	je     8010843d <loaduvm+0xcd>
      return -1;
80108436:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010843b:	eb 18                	jmp    80108455 <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010843d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108444:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108447:	3b 45 18             	cmp    0x18(%ebp),%eax
8010844a:	0f 82 4b ff ff ff    	jb     8010839b <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108450:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108455:	83 c4 24             	add    $0x24,%esp
80108458:	5b                   	pop    %ebx
80108459:	5d                   	pop    %ebp
8010845a:	c3                   	ret    

8010845b <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010845b:	55                   	push   %ebp
8010845c:	89 e5                	mov    %esp,%ebp
8010845e:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108461:	8b 45 10             	mov    0x10(%ebp),%eax
80108464:	85 c0                	test   %eax,%eax
80108466:	79 0a                	jns    80108472 <allocuvm+0x17>
    return 0;
80108468:	b8 00 00 00 00       	mov    $0x0,%eax
8010846d:	e9 c1 00 00 00       	jmp    80108533 <allocuvm+0xd8>
  if(newsz < oldsz)
80108472:	8b 45 10             	mov    0x10(%ebp),%eax
80108475:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108478:	73 08                	jae    80108482 <allocuvm+0x27>
    return oldsz;
8010847a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010847d:	e9 b1 00 00 00       	jmp    80108533 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108482:	8b 45 0c             	mov    0xc(%ebp),%eax
80108485:	05 ff 0f 00 00       	add    $0xfff,%eax
8010848a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010848f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108492:	e9 8d 00 00 00       	jmp    80108524 <allocuvm+0xc9>
    mem = kalloc();
80108497:	e8 89 ab ff ff       	call   80103025 <kalloc>
8010849c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
8010849f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801084a3:	75 2c                	jne    801084d1 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
801084a5:	c7 04 24 85 8f 10 80 	movl   $0x80108f85,(%esp)
801084ac:	e8 ef 7e ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801084b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801084b4:	89 44 24 08          	mov    %eax,0x8(%esp)
801084b8:	8b 45 10             	mov    0x10(%ebp),%eax
801084bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801084bf:	8b 45 08             	mov    0x8(%ebp),%eax
801084c2:	89 04 24             	mov    %eax,(%esp)
801084c5:	e8 6b 00 00 00       	call   80108535 <deallocuvm>
      return 0;
801084ca:	b8 00 00 00 00       	mov    $0x0,%eax
801084cf:	eb 62                	jmp    80108533 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801084d1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084d8:	00 
801084d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801084e0:	00 
801084e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084e4:	89 04 24             	mov    %eax,(%esp)
801084e7:	e8 99 d0 ff ff       	call   80105585 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801084ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084ef:	89 04 24             	mov    %eax,(%esp)
801084f2:	e8 cc f5 ff ff       	call   80107ac3 <v2p>
801084f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801084fa:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108501:	00 
80108502:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108506:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010850d:	00 
8010850e:	89 54 24 04          	mov    %edx,0x4(%esp)
80108512:	8b 45 08             	mov    0x8(%ebp),%eax
80108515:	89 04 24             	mov    %eax,(%esp)
80108518:	e8 d8 fa ff ff       	call   80107ff5 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
8010851d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108524:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108527:	3b 45 10             	cmp    0x10(%ebp),%eax
8010852a:	0f 82 67 ff ff ff    	jb     80108497 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108530:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108533:	c9                   	leave  
80108534:	c3                   	ret    

80108535 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108535:	55                   	push   %ebp
80108536:	89 e5                	mov    %esp,%ebp
80108538:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010853b:	8b 45 10             	mov    0x10(%ebp),%eax
8010853e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108541:	72 08                	jb     8010854b <deallocuvm+0x16>
    return oldsz;
80108543:	8b 45 0c             	mov    0xc(%ebp),%eax
80108546:	e9 a4 00 00 00       	jmp    801085ef <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010854b:	8b 45 10             	mov    0x10(%ebp),%eax
8010854e:	05 ff 0f 00 00       	add    $0xfff,%eax
80108553:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108558:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010855b:	e9 80 00 00 00       	jmp    801085e0 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108560:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108563:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010856a:	00 
8010856b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010856f:	8b 45 08             	mov    0x8(%ebp),%eax
80108572:	89 04 24             	mov    %eax,(%esp)
80108575:	e8 d9 f9 ff ff       	call   80107f53 <walkpgdir>
8010857a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
8010857d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108581:	75 09                	jne    8010858c <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108583:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010858a:	eb 4d                	jmp    801085d9 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
8010858c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010858f:	8b 00                	mov    (%eax),%eax
80108591:	83 e0 01             	and    $0x1,%eax
80108594:	85 c0                	test   %eax,%eax
80108596:	74 41                	je     801085d9 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108598:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010859b:	8b 00                	mov    (%eax),%eax
8010859d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801085a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801085a5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801085a9:	75 0c                	jne    801085b7 <deallocuvm+0x82>
        panic("kfree");
801085ab:	c7 04 24 9d 8f 10 80 	movl   $0x80108f9d,(%esp)
801085b2:	e8 83 7f ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
801085b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801085ba:	89 04 24             	mov    %eax,(%esp)
801085bd:	e8 0e f5 ff ff       	call   80107ad0 <p2v>
801085c2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801085c5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801085c8:	89 04 24             	mov    %eax,(%esp)
801085cb:	e8 bc a9 ff ff       	call   80102f8c <kfree>
      *pte = 0;
801085d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085d3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801085d9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801085e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e3:	3b 45 0c             	cmp    0xc(%ebp),%eax
801085e6:	0f 82 74 ff ff ff    	jb     80108560 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801085ec:	8b 45 10             	mov    0x10(%ebp),%eax
}
801085ef:	c9                   	leave  
801085f0:	c3                   	ret    

801085f1 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801085f1:	55                   	push   %ebp
801085f2:	89 e5                	mov    %esp,%ebp
801085f4:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801085f7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801085fb:	75 0c                	jne    80108609 <freevm+0x18>
    panic("freevm: no pgdir");
801085fd:	c7 04 24 a3 8f 10 80 	movl   $0x80108fa3,(%esp)
80108604:	e8 31 7f ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108609:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108610:	00 
80108611:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108618:	80 
80108619:	8b 45 08             	mov    0x8(%ebp),%eax
8010861c:	89 04 24             	mov    %eax,(%esp)
8010861f:	e8 11 ff ff ff       	call   80108535 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108624:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010862b:	eb 48                	jmp    80108675 <freevm+0x84>
    if(pgdir[i] & PTE_P){
8010862d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108630:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108637:	8b 45 08             	mov    0x8(%ebp),%eax
8010863a:	01 d0                	add    %edx,%eax
8010863c:	8b 00                	mov    (%eax),%eax
8010863e:	83 e0 01             	and    $0x1,%eax
80108641:	85 c0                	test   %eax,%eax
80108643:	74 2c                	je     80108671 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108645:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108648:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010864f:	8b 45 08             	mov    0x8(%ebp),%eax
80108652:	01 d0                	add    %edx,%eax
80108654:	8b 00                	mov    (%eax),%eax
80108656:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010865b:	89 04 24             	mov    %eax,(%esp)
8010865e:	e8 6d f4 ff ff       	call   80107ad0 <p2v>
80108663:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108666:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108669:	89 04 24             	mov    %eax,(%esp)
8010866c:	e8 1b a9 ff ff       	call   80102f8c <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108671:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108675:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
8010867c:	76 af                	jbe    8010862d <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
8010867e:	8b 45 08             	mov    0x8(%ebp),%eax
80108681:	89 04 24             	mov    %eax,(%esp)
80108684:	e8 03 a9 ff ff       	call   80102f8c <kfree>
}
80108689:	c9                   	leave  
8010868a:	c3                   	ret    

8010868b <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010868b:	55                   	push   %ebp
8010868c:	89 e5                	mov    %esp,%ebp
8010868e:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108691:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108698:	00 
80108699:	8b 45 0c             	mov    0xc(%ebp),%eax
8010869c:	89 44 24 04          	mov    %eax,0x4(%esp)
801086a0:	8b 45 08             	mov    0x8(%ebp),%eax
801086a3:	89 04 24             	mov    %eax,(%esp)
801086a6:	e8 a8 f8 ff ff       	call   80107f53 <walkpgdir>
801086ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801086ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801086b2:	75 0c                	jne    801086c0 <clearpteu+0x35>
    panic("clearpteu");
801086b4:	c7 04 24 b4 8f 10 80 	movl   $0x80108fb4,(%esp)
801086bb:	e8 7a 7e ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
801086c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086c3:	8b 00                	mov    (%eax),%eax
801086c5:	83 e0 fb             	and    $0xfffffffb,%eax
801086c8:	89 c2                	mov    %eax,%edx
801086ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086cd:	89 10                	mov    %edx,(%eax)
}
801086cf:	c9                   	leave  
801086d0:	c3                   	ret    

801086d1 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801086d1:	55                   	push   %ebp
801086d2:	89 e5                	mov    %esp,%ebp
801086d4:	53                   	push   %ebx
801086d5:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801086d8:	e8 b0 f9 ff ff       	call   8010808d <setupkvm>
801086dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
801086e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801086e4:	75 0a                	jne    801086f0 <copyuvm+0x1f>
    return 0;
801086e6:	b8 00 00 00 00       	mov    $0x0,%eax
801086eb:	e9 fd 00 00 00       	jmp    801087ed <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
801086f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801086f7:	e9 d0 00 00 00       	jmp    801087cc <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801086fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ff:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108706:	00 
80108707:	89 44 24 04          	mov    %eax,0x4(%esp)
8010870b:	8b 45 08             	mov    0x8(%ebp),%eax
8010870e:	89 04 24             	mov    %eax,(%esp)
80108711:	e8 3d f8 ff ff       	call   80107f53 <walkpgdir>
80108716:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108719:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010871d:	75 0c                	jne    8010872b <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
8010871f:	c7 04 24 be 8f 10 80 	movl   $0x80108fbe,(%esp)
80108726:	e8 0f 7e ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
8010872b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010872e:	8b 00                	mov    (%eax),%eax
80108730:	83 e0 01             	and    $0x1,%eax
80108733:	85 c0                	test   %eax,%eax
80108735:	75 0c                	jne    80108743 <copyuvm+0x72>
      panic("copyuvm: page not present");
80108737:	c7 04 24 d8 8f 10 80 	movl   $0x80108fd8,(%esp)
8010873e:	e8 f7 7d ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108743:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108746:	8b 00                	mov    (%eax),%eax
80108748:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010874d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108750:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108753:	8b 00                	mov    (%eax),%eax
80108755:	25 ff 0f 00 00       	and    $0xfff,%eax
8010875a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
8010875d:	e8 c3 a8 ff ff       	call   80103025 <kalloc>
80108762:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108765:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108769:	75 02                	jne    8010876d <copyuvm+0x9c>
      goto bad;
8010876b:	eb 70                	jmp    801087dd <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
8010876d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108770:	89 04 24             	mov    %eax,(%esp)
80108773:	e8 58 f3 ff ff       	call   80107ad0 <p2v>
80108778:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010877f:	00 
80108780:	89 44 24 04          	mov    %eax,0x4(%esp)
80108784:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108787:	89 04 24             	mov    %eax,(%esp)
8010878a:	e8 c5 ce ff ff       	call   80105654 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
8010878f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80108792:	8b 45 e0             	mov    -0x20(%ebp),%eax
80108795:	89 04 24             	mov    %eax,(%esp)
80108798:	e8 26 f3 ff ff       	call   80107ac3 <v2p>
8010879d:	8b 55 f4             	mov    -0xc(%ebp),%edx
801087a0:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801087a4:	89 44 24 0c          	mov    %eax,0xc(%esp)
801087a8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801087af:	00 
801087b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801087b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801087b7:	89 04 24             	mov    %eax,(%esp)
801087ba:	e8 36 f8 ff ff       	call   80107ff5 <mappages>
801087bf:	85 c0                	test   %eax,%eax
801087c1:	79 02                	jns    801087c5 <copyuvm+0xf4>
      goto bad;
801087c3:	eb 18                	jmp    801087dd <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801087c5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801087cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087cf:	3b 45 0c             	cmp    0xc(%ebp),%eax
801087d2:	0f 82 24 ff ff ff    	jb     801086fc <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
801087d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801087db:	eb 10                	jmp    801087ed <copyuvm+0x11c>

bad:
  freevm(d);
801087dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801087e0:	89 04 24             	mov    %eax,(%esp)
801087e3:	e8 09 fe ff ff       	call   801085f1 <freevm>
  return 0;
801087e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801087ed:	83 c4 44             	add    $0x44,%esp
801087f0:	5b                   	pop    %ebx
801087f1:	5d                   	pop    %ebp
801087f2:	c3                   	ret    

801087f3 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801087f3:	55                   	push   %ebp
801087f4:	89 e5                	mov    %esp,%ebp
801087f6:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801087f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108800:	00 
80108801:	8b 45 0c             	mov    0xc(%ebp),%eax
80108804:	89 44 24 04          	mov    %eax,0x4(%esp)
80108808:	8b 45 08             	mov    0x8(%ebp),%eax
8010880b:	89 04 24             	mov    %eax,(%esp)
8010880e:	e8 40 f7 ff ff       	call   80107f53 <walkpgdir>
80108813:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108816:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108819:	8b 00                	mov    (%eax),%eax
8010881b:	83 e0 01             	and    $0x1,%eax
8010881e:	85 c0                	test   %eax,%eax
80108820:	75 07                	jne    80108829 <uva2ka+0x36>
    return 0;
80108822:	b8 00 00 00 00       	mov    $0x0,%eax
80108827:	eb 25                	jmp    8010884e <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108829:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010882c:	8b 00                	mov    (%eax),%eax
8010882e:	83 e0 04             	and    $0x4,%eax
80108831:	85 c0                	test   %eax,%eax
80108833:	75 07                	jne    8010883c <uva2ka+0x49>
    return 0;
80108835:	b8 00 00 00 00       	mov    $0x0,%eax
8010883a:	eb 12                	jmp    8010884e <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
8010883c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010883f:	8b 00                	mov    (%eax),%eax
80108841:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108846:	89 04 24             	mov    %eax,(%esp)
80108849:	e8 82 f2 ff ff       	call   80107ad0 <p2v>
}
8010884e:	c9                   	leave  
8010884f:	c3                   	ret    

80108850 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108850:	55                   	push   %ebp
80108851:	89 e5                	mov    %esp,%ebp
80108853:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108856:	8b 45 10             	mov    0x10(%ebp),%eax
80108859:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010885c:	e9 87 00 00 00       	jmp    801088e8 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
80108861:	8b 45 0c             	mov    0xc(%ebp),%eax
80108864:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108869:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010886c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010886f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108873:	8b 45 08             	mov    0x8(%ebp),%eax
80108876:	89 04 24             	mov    %eax,(%esp)
80108879:	e8 75 ff ff ff       	call   801087f3 <uva2ka>
8010887e:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108881:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108885:	75 07                	jne    8010888e <copyout+0x3e>
      return -1;
80108887:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010888c:	eb 69                	jmp    801088f7 <copyout+0xa7>
    n = PGSIZE - (va - va0);
8010888e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108891:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108894:	29 c2                	sub    %eax,%edx
80108896:	89 d0                	mov    %edx,%eax
80108898:	05 00 10 00 00       	add    $0x1000,%eax
8010889d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801088a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088a3:	3b 45 14             	cmp    0x14(%ebp),%eax
801088a6:	76 06                	jbe    801088ae <copyout+0x5e>
      n = len;
801088a8:	8b 45 14             	mov    0x14(%ebp),%eax
801088ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801088ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088b1:	8b 55 0c             	mov    0xc(%ebp),%edx
801088b4:	29 c2                	sub    %eax,%edx
801088b6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801088b9:	01 c2                	add    %eax,%edx
801088bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088be:	89 44 24 08          	mov    %eax,0x8(%esp)
801088c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801088c9:	89 14 24             	mov    %edx,(%esp)
801088cc:	e8 83 cd ff ff       	call   80105654 <memmove>
    len -= n;
801088d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088d4:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801088d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088da:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801088dd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088e0:	05 00 10 00 00       	add    $0x1000,%eax
801088e5:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801088e8:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801088ec:	0f 85 6f ff ff ff    	jne    80108861 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801088f2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801088f7:	c9                   	leave  
801088f8:	c3                   	ret    
