// internal_bus_defines.svh
// Internal bus signal struct definitions.
// Included directly by modules (avoids Vivado compile-order issues with packages).
//
// === Handshake timing ===
//
// Master drives valid=1, along with addr/wdata/byte_en/read_en/write_en.
// Slave asserts ready=1 when it has (for reads) or accepted (for writes)
// the transaction.
//
// Single-cycle slave:  ready = 1 always (combinational or registered
//   same-cycle).  Transaction completes in one clock.
//
// Multi-cycle slave:   ready is asserted some cycles after valid.
//   Master must hold valid stable until ready is sampled high.
//
// The transaction is complete on the rising edge where both valid=1
// and ready=1.  For reads, rdata is valid in that same cycle.

// Bus request (master -> slave)
typedef struct packed {
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [3:0]  byte_en;
    logic        read_en;
    logic        write_en;
    logic        valid;
} bus_req_t;

// Bus response (slave -> master)
typedef struct packed {
    logic [31:0] rdata;
    logic        ready;
} bus_resp_t;
