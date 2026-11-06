/*
* Logic Quest (LQ): Task 3A Path Planner with Decryption
*
* Computes the shortest path on the Logic Quest arena (nodes N1..N36), with the
* line weights of Figure 1 on the Task 3A page: straight line 5, ring arcs
* 7 / 11 / 15 / 19 (inner ring to outermost ring), wavy line N1-N36 100.
*
* Inputs : current_node, next_node, is_encrypted
*   current_node     : where the bot is, 1..36. The path starts here.
*                      At the first location the bot is in the start box, N35.
*   is_encrypted = 0 : next_node is a node number.
*                      Path: current_node -> next_node.
*   is_encrypted = 1 : next_node is the 8-byte encrypted code, encrypted with
*                      PRESENT-80.
*                      Path: current_node -> the drop node in the block.
*
* Decrypted code (8 bytes, byte 0 first):
*   byte 0     : done flag (1 = last block: no pick-up after this drop)
*   byte 1..5  : message, 5 ASCII characters (0x00 = no character)
*   byte 6     : next pick-up node 1..36 (not used when the done flag is 1)
*   byte 7     : drop node 1..36 for this block
*   e.g. message "HELLO", drop at N26, then pick up at N12
*        -> 00 48 45 4C 4C 4F 0C 1A = 0048454C4C4F0C1A
*
* Outputs:
*   is_encrypted = 0 : the path from current_node to next_node.
*   is_encrypted = 1 : the message (message[]) and the path from current_node
*                      to the drop node. When the done flag is 0, the inputs
*                      for the next run are written too:
*                          IS_ENCRYPTED = 0
*                          CURRENT_NODE = the drop node
*                          NEXT_NODE    = the next pick-up node
*                      When the done flag is 1, the inputs are left as they are.
*
* Output (PC), read by test.sh line by line:
*   is_encrypted = 0     is_encrypted = 1, done = 0     is_encrypted = 1, done = 1
*   35                   Message : HELLO                Message : BYE
*   ...                  7                              7
*   7                    ...                            ...
*                        26                             26
*                        Next current_node : 26         Done
*                        Next next_node : 12
*   The path is one node per line, first node first. The message line shows
*   the non-zero message bytes as characters. The code at the end of main
*   prints all of this from message[], path_planned[], idx and the inputs
*   written for the next run.
*
* Debug prints: start every debug line with "dbg:" (see Functions Usage
*   below). test.sh and the evaluator skip the lines that start with "dbg:".
*   Any other extra line counts as part of your output and makes it wrong.
*
* PRESENT-80 (the cipher used for the encrypted codes):
*   block 64 bits, key 80 bits = A1 B2 C3 D4 E5 F6 07 18 29 3A (PRESENT_KEY_* below),
*   31 rounds. See the Task 3A page for the full description of the encryption;
*   your program has to do the reverse.
*
* Data memory ranges (used on the RISC-V CPU, Task 3B):
*   0x02000000 .. 0x0200000F : inputs
*   0x02000010 .. 0x0200001F : outputs (0x0200001C = CPU_DONE)
*   0x02000020 and up        : working memory, stack at the top
*
* Inputs  : ENCRYPTED_HI (0x02000000)  encrypted block, bytes 0..3 (first 8 hex digits)
*           ENCRYPTED_LO (0x02000004)  encrypted block, bytes 4..7 (last 8 hex digits)
*           IS_ENCRYPTED (0x02000008)  0 or 1                            } written for
*           NEXT_NODE    (0x0200000C)  next node, when IS_ENCRYPTED = 0   } the next run
*           CURRENT_NODE (0x0200000D)  current node (where the bot is)    } when done = 0
* Outputs : MESSAGE_0..4 (0x02000010 .. 0x02000014)  message, block bytes 1..5
*           NODE_POINT   (0x02000018)  every node of the path, written in order
*           CPU_DONE     (0x0200001C)  = 1 when finished
*
* Make sure you don't change anything outside the "Add your code here" sections.
*/

#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <limits.h>

// PRESENT-80 key: A1 B2 C3 D4 E5 F6 07 18 29 3A
#define PRESENT_KEY_HI  0xA1B2C3D4   // key bits 79..48
#define PRESENT_KEY_MID 0xE5F60718   // key bits 47..16
#define PRESENT_KEY_LO  0x293A       // key bits 15..0

#ifdef __linux__ // for host pc

    #include <stdio.h>

    void _put_byte(char c) { putchar(c); }

    void _put_str(char *str) {
        while (*str) {
            _put_byte(*str++);
        }
    }

    void print_output(uint8_t num) {
        if (num == 0) {
            putchar('0'); // if the number is 0, directly print '0'
            _put_byte('\n');
            return;
        }

        // convert the integer to a string
        char buffer[20];
        uint8_t index = 0;

        while (num > 0) {
            buffer[index++] = '0' + num % 10; // convert the last digit to its character representation
            num /= 10;                        // move to the next digit
        }
        // print the characters in reverse order (from right to left)
        while (index > 0) { putchar(buffer[--index]); }
        _put_byte('\n');
    }

    void _put_value(uint8_t val) { print_output(val); }

    // print a 32-bit value as 8 hex digits and a newline (e.g. the decrypted block)
    void _put_hex(uint32_t val) { printf("%08X\n", (unsigned int)val); }

    // read 16 hex digits into two 32-bit words, returns 0 if the text is not 16 hex digits
    int read_block(const char *hex, uint32_t *hi, uint32_t *lo) {
        uint32_t word[2] = { 0, 0 };
        if (hex[0] == '0' && (hex[1] == 'x' || hex[1] == 'X')) hex += 2;
        for (int n = 0; n < 16; n++) {
            char c = hex[n];
            uint32_t d;
            if      (c >= '0' && c <= '9') d = c - '0';
            else if (c >= 'a' && c <= 'f') d = c - 'a' + 10;
            else if (c >= 'A' && c <= 'F') d = c - 'A' + 10;
            else return 0;
            word[n >> 3] = (word[n >> 3] << 4) | d;
        }
        if (hex[16] != '\0') return 0;
        *hi = word[0];
        *lo = word[1];
        return 1;
    }

    /*
     * On the PC there is no data memory at 0x02000000, so MEM32(address) is a
     * normal array (one entry per 32-bit word). On the CPU it is the real
     * data memory. Either way, MEM32(0x02000020) reads the same place.
     */
    static uint32_t pc_data_mem[128];
    #define MEM32(addr)  (pc_data_mem[((addr) - 0x02000000u) >> 2])

#else  // for the test device

    void _put_byte(char c) { }
    void _put_value(uint8_t val) { }
    void _put_hex(uint32_t val) { }
    void _put_str(char *str) { }

    #define MEM32(addr)  (*(volatile uint32_t *)(addr))

#endif

/*
Functions Usage

To print while debugging, use the functions below, not printf().
On the PC they print. On the CPU they are empty, so they cost nothing there
and the same file still builds with generatehex.sh.

for a character: _put_byte('A');                        (putchar() on the PC)
for newline:     _put_byte('\n');
for string:      _put_str("your string here");
for number:      _put_value(your_number_here);           0 to 255, then a newline
for 32 bits:     _put_hex(your_32_bit_value_here);       8 hex digits, then a newline

Start every debug line with "dbg:" and end it with a newline (_put_value
and _put_hex end the line for you). test.sh and the evaluator skip the
lines that start with "dbg:", so these prints can stay in the file you
submit. Any other line you print counts as part of your output (see
"Output (PC)" at the top) and makes it wrong.

Examples:
        _put_str("dbg: start_point = ");     _put_value(start_point);
        _put_str("dbg: end_point = ");       _put_value(end_point);
        _put_str("dbg: ENCRYPTED_HI = ");    _put_hex(ENCRYPTED_HI);    // encrypted block, bytes 0..3
        _put_str("dbg: ENCRYPTED_LO = ");    _put_hex(ENCRYPTED_LO);    // encrypted block, bytes 4..7
        _put_str("dbg: first character = "); _put_byte(message[0]); _put_byte('\n');
        _put_str("dbg: Hello World!\n");

*/

// Custom Functions

// ############# Add your code here #############

// ---- PRESENT-80 helpers (80-bit key register kept as 10 bytes, k[0] = bits 79..72) ----

// rotate the 80-bit register right by one bit
static void rotr1(uint8_t *k) {
    uint8_t carry = k[9] & 1;
    for (uint8_t j = 0; j < 10; j++) {
        uint8_t nc = k[j] & 1;
        k[j] = (k[j] >> 1) | (carry << 7);
        carry = nc;
    }
}

// S-box / inverse S-box on one nibble, tables packed into 32-bit constants
static uint8_t sbox(uint8_t x) {
    uint32_t t = (x & 8) ? 0x21748FE3u : 0xDA09B65Cu;
    return (t >> ((x & 7) << 2)) & 0xF;
}
static uint8_t isbox(uint8_t x) {
    uint32_t t = (x & 8) ? 0xA970364Bu : 0xD21C8FE5u;
    return (t >> ((x & 7) << 2)) & 0xF;
}

// forward key update for round r: rotl 61 (= rotr 19), S-box on top nibble, XOR round counter
static void key_next(uint8_t *k, uint8_t r) {
    for (uint8_t i = 0; i < 19; i++) rotr1(k);
    k[0] = (sbox(k[0] >> 4) << 4) | (k[0] & 0xF);
    k[7] ^= (r >> 1);
    k[8] ^= (r & 1) << 7;
}

// inverse of key_next
static void key_prev(uint8_t *k, uint8_t r) {
    k[8] ^= (r & 1) << 7;
    k[7] ^= (r >> 1);
    k[0] = (isbox(k[0] >> 4) << 4) | (k[0] & 0xF);
    for (uint8_t i = 0; i < 61; i++) rotr1(k);
}

// inverse permutation layer: new bit i = old bit P(i), P(i) = 16*i mod 63, bit 63 fixed
static void inv_perm(uint8_t *s, uint8_t *t) {
    for (uint8_t j = 0; j < 8; j++) t[j] = 0;
    uint8_t p = 0;
    for (uint8_t i = 0; i < 63; i++) {
        if ((s[7 - (p >> 3)] >> (p & 7)) & 1) t[7 - (i >> 3)] |= (1 << (i & 7));
        p += 16;
        if (p >= 63) p -= 63;
    }
    t[0] |= s[0] & 0x80;
    for (uint8_t j = 0; j < 8; j++) s[j] = t[j];
}

// PRESENT-80 decryption of the block (ENC_HI, ENC_LO). Result: s[0..7] = decrypted code
static void present_decrypt(uint32_t hi, uint32_t lo, uint8_t *s, uint8_t *k, uint8_t *t) {
    for (uint8_t i = 0; i < 4; i++) {
        s[i]     = hi >> (24 - (i << 3));
        s[4 + i] = lo >> (24 - (i << 3));
    }
    uint32_t kh = PRESENT_KEY_HI, km = PRESENT_KEY_MID, kl = PRESENT_KEY_LO;
    for (uint8_t i = 0; i < 4; i++) {
        k[i]     = kh >> (24 - (i << 3));
        k[4 + i] = km >> (24 - (i << 3));
    }
    k[8] = kl >> 8;  k[9] = kl;

    for (uint8_t r = 1; r <= 31; r++) key_next(k, r);      // k now holds K32
    for (uint8_t j = 0; j < 8; j++) s[j] ^= k[j];
    for (uint8_t r = 31; r >= 1; r--) {
        key_prev(k, r);                                    // k now holds K_r
        inv_perm(s, t);
        for (uint8_t j = 0; j < 8; j++) {
            s[j] = (isbox(s[j] >> 4) << 4) | isbox(s[j] & 0xF);
            s[j] ^= k[j];
        }
    }
}

// ---- arena graph ----
// edge = (u << 9) | (v << 3) | c ; c = 0: 5, 1: 7, 2: 11, 3: 15, 4: 19, 7: 100 (wavy)
#define E(u, v, c)  ((uint16_t)(((u) << 9) | ((v) << 3) | (c)))

static uint8_t edge_weight(uint16_t e) {
    uint8_t c = e & 7;
    if (c == 7) return 100;
    if (c) return 3 + (c << 2);
    return 5;
}

// fill edge list, returns number of edges
static uint8_t build_graph(uint16_t *e) {
    uint8_t n = 0;
    // ===== EDGES FROM FIGURE 1 GO HERE (one line per line of the arena) =====
    e[n++] = E(1, 36, 7);
    e[n++] = E(1, 4, 3);
    e[n++] = E(1, 6, 3);
    e[n++] = E(1, 5, 0);
    e[n++] = E(2, 4, 0);
    e[n++] = E(3, 6, 0);
    e[n++] = E(4, 14, 3);
    e[n++] = E(13, 14, 0);
    e[n++] = E(14, 15, 0);
    e[n++] = E(13, 30, 4);
    e[n++] = E(30, 35, 4);
    e[n++] = E(35, 31, 4);
    e[n++] = E(30, 33, 0);
    e[n++] = E(31, 28, 0);
    e[n++] = E(31, 34, 0);
    e[n++] = E(28, 32, 3);
    e[n++] = E(29, 32, 0);
    e[n++] = E(5, 7, 2);
    e[n++] = E(5, 8, 2);
    e[n++] = E(7, 15, 2);
    e[n++] = E(7, 10, 0);
    e[n++] = E(8, 20, 2);
    e[n++] = E(8, 11, 0);
    e[n++] = E(20, 27, 2);
    e[n++] = E(20, 21, 0);
    e[n++] = E(27, 29, 2);
    e[n++] = E(27, 24, 0);
    e[n++] = E(29, 26, 2);
    e[n++] = E(9, 11, 1);
    e[n++] = E(11, 19, 1);
    e[n++] = E(9, 12, 0);
    e[n++] = E(18, 19, 0);
    e[n++] = E(16, 17, 0);
    e[n++] = E(16, 23, 1);
    e[n++] = E(23, 25, 1);
    e[n++] = E(23, 26, 0);
    e[n++] = E(22, 25, 0);
    // ========================================================================
    return n;
}

// Bellman-Ford shortest path start -> end. Writes path into path[], returns its length.
static uint8_t plan_path(uint8_t start, uint8_t end, uint16_t *e, uint16_t *dist, uint8_t *prev, uint8_t *path) {
    uint8_t n = build_graph(e);
    for (uint8_t i = 0; i < 40; i++) { dist[i] = 0xFFFF; prev[i] = 0; }
    dist[start] = 0;
    uint8_t changed = 1;
    while (changed) {
        changed = 0;
        for (uint8_t i = 0; i < n; i++) {
            uint8_t u = e[i] >> 9, v = (e[i] >> 3) & 0x3F;
            uint16_t w = edge_weight(e[i]);
            if (dist[u] != 0xFFFF && dist[u] + w < dist[v]) { dist[v] = dist[u] + w; prev[v] = u; changed = 1; }
            if (dist[v] != 0xFFFF && dist[v] + w < dist[u]) { dist[u] = dist[v] + w; prev[u] = v; changed = 1; }
        }
    }
    if (dist[end] == 0xFFFF) { path[0] = start; return 1; }   // unreachable (should not happen)
    uint8_t len = 1, v = end;
    while (v != start) { v = prev[v]; len++; }
    v = end;
    for (uint8_t i = len; i > 0; i--) { path[i - 1] = v; v = prev[v]; }
    return len;
}

// ##############################################

// main function
int main(int argc, char const *argv[]) {

    #ifdef __linux__

        if (argc < 4) {
            _put_str("usage: ./Path_Planner_Dec <current_node> <next_node> <is_encrypted>\n");
            _put_str("       current_node     : where the bot is, e.g. 35 (the start box)\n");
            _put_str("       is_encrypted = 0 : next_node is a node number, e.g. 7\n");
            _put_str("       is_encrypted = 1 : next_node is the encrypted code, 16 hex digits\n");
            return 1;
        }
        uint8_t  CURRENT_NODE        = atoi(argv[1]);
        uint8_t  IS_ENCRYPTED        = atoi(argv[3]);
        uint8_t  NEXT_NODE           = 0;
        uint32_t ENCRYPTED_HI        = 0;
        uint32_t ENCRYPTED_LO        = 0;
        if (IS_ENCRYPTED) {
            if (!read_block(argv[2], &ENCRYPTED_HI, &ENCRYPTED_LO)) {
                _put_str("with is_encrypted = 1, next_node must be exactly 16 hex digits\n");
                return 1;
            }
        }
        else {
            NEXT_NODE = atoi(argv[2]);
        }
        uint8_t MESSAGE_0           = 0;
        uint8_t MESSAGE_1           = 0;
        uint8_t MESSAGE_2           = 0;
        uint8_t MESSAGE_3           = 0;
        uint8_t MESSAGE_4           = 0;
        uint8_t NODE_POINT          = 0;
        uint8_t CPU_DONE            = 0;

    #else
        // Address value of variables are updated for RISC-V Implementation
        // inputs: 0x02000000 .. 0x0200000F
        #define ENCRYPTED_HI        (* (volatile uint32_t * ) 0x02000000)
        #define ENCRYPTED_LO        (* (volatile uint32_t * ) 0x02000004)
        #define IS_ENCRYPTED        (* (volatile uint8_t  * ) 0x02000008)
        #define NEXT_NODE           (* (volatile uint8_t  * ) 0x0200000c)
        #define CURRENT_NODE        (* (volatile uint8_t  * ) 0x0200000d)
        // outputs: 0x02000010 .. 0x0200001F
        #define MESSAGE_0           (* (volatile uint8_t  * ) 0x02000010)
        #define MESSAGE_1           (* (volatile uint8_t  * ) 0x02000011)
        #define MESSAGE_2           (* (volatile uint8_t  * ) 0x02000012)
        #define MESSAGE_3           (* (volatile uint8_t  * ) 0x02000013)
        #define MESSAGE_4           (* (volatile uint8_t  * ) 0x02000014)
        #define NODE_POINT          (* (volatile uint8_t  * ) 0x02000018)
        #define CPU_DONE            (* (volatile uint8_t  * ) 0x0200001c)

    #endif

    // read once here: for the next run, the program may write IS_ENCRYPTED = 0
    uint8_t is_encrypted = IS_ENCRYPTED;

    // the message: bytes 1..5 of the decrypted block (0x00 = no character)
    uint8_t message[5] = { 0, 0, 0, 0, 0 };

    // array to store the planned path
    uint8_t path_planned[40];
    // index to keep track of the path_planned array
    uint8_t idx = 0;

    uint8_t start_point = CURRENT_NODE;   // where the bot is
    uint8_t end_point   = 0;              // where the bot goes

    // ############# Add your code here #############

    // set path_planned[] and idx, message[] when is_encrypted = 1, and the
    // inputs for the next run (see Outputs at the top of this file)

    // prefer declaring variables like this
    #ifdef __linux__
        uint16_t dist[40];
        uint8_t  prev[40];
        uint16_t edges[64];
        uint8_t  dstate[8], dkey[10], dtmp[8];
    #else
        uint16_t *dist   = (uint16_t *) 0x02000020;    // working memory starts at 0x02000020
        uint8_t  *prev   = (uint8_t  *) 0x02000070;
        uint16_t *edges  = (uint16_t *) 0x02000098;
        uint8_t  *dstate = (uint8_t  *) 0x02000118;
        uint8_t  *dkey   = (uint8_t  *) 0x02000120;
        uint8_t  *dtmp   = (uint8_t  *) 0x0200012C;
    #endif

    end_point = NEXT_NODE;
    if (is_encrypted) {
        present_decrypt(ENCRYPTED_HI, ENCRYPTED_LO, dstate, dkey, dtmp);
        for (uint8_t i = 0; i < 5; i++) message[i] = dstate[i + 1];
        end_point = dstate[7];
        if (dstate[0] == 0) {           // not the last block: inputs for the next run
            IS_ENCRYPTED = 0;
            CURRENT_NODE = dstate[7];
            NEXT_NODE    = dstate[6];
        }
    }
    idx = plan_path(start_point, end_point, edges, dist, prev, path_planned);

    // ##############################################

    // the message bytes are written into data memory (encrypted block only).
    if (is_encrypted) {
        MESSAGE_0 = message[0];
        MESSAGE_1 = message[1];
        MESSAGE_2 = message[2];
        MESSAGE_3 = message[3];
        MESSAGE_4 = message[4];
    }
    // the node values are written into data memory sequentially.
    for (int i = 0; i < idx; ++i) {
        NODE_POINT = path_planned[i];
    }
    // Path Planning Computation Done Flag
    CPU_DONE = 1;

    #ifdef __linux__    // for host pc: the output test.sh reads (see "Output (PC)" at the top)

        if (is_encrypted) {
            _put_str("Message : ");
            for (int i = 0; i < 5; ++i) {
                if (message[i]) _put_byte(message[i]);
            }
            _put_byte('\n');
        }
        for (int i = 0; i < idx; ++i) {
            _put_value(path_planned[i]);
        }
        if (is_encrypted) {
            if (IS_ENCRYPTED == 0) {            // the inputs written for the next run
                _put_str("Next current_node : ");
                _put_value(CURRENT_NODE);
                _put_str("Next next_node : ");
                _put_value(NEXT_NODE);
            }
            else {
                _put_str("Done\n");
            }
        }

    #endif

    return 0;
}