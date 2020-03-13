#!/usr/bin/env ruby
# Licensed under the Apache License, Version 2.0 (the "License")

require "rbbcc"
include RbBCC

# load BPF program
b = BCC.new(text: <<BPF)
#include <uapi/linux/ptrace.h>

BPF_HASH(last);

int do_trace(struct pt_regs *ctx) {
    u64 ts, *tsp, delta, key = 0, counter_key = 1, zero = 0;

    // initialize counter key
    if (last.lookup_or_try_init(&counter_key, &zero))
        last.increment(counter_key);

    // attempt to read stored timestamp
    tsp = last.lookup(&key);
    if (tsp != 0) {
        delta = bpf_ktime_get_ns() - *tsp;
        if (delta < 1000000000) {
            // output if time is less than 1 second
            bpf_trace_printk("%d\\n", delta / 1000000);
        }
        last.delete(&key);
    }

    // update stored timestamp
    ts = bpf_ktime_get_ns();
    last.update(&key, &ts);
    return 0;
}
BPF

COUNTER_KEY = 1

b.attach_kprobe(event: b.get_syscall_fnname("sync"), fn_name: "do_trace")
puts("Tracing for quick sync's... Ctrl-C to end")

# format output
start = 0
begin
  b.trace_fields do |task, pid, cpu, flags, ts, ms|
    start = ts.to_f if start.zero?
    ts = ts.to_f - start
    puts("At time %.2f s: multiple syncs detected, last %s ms ago" % [ts, ms.chomp])
  end
rescue Interrupt
  table = b["last"]
  puts "Count of sys_sync: %d" % table[COUNTER_KEY].to_bcc_value
end
