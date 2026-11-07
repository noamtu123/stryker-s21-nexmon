# Floppy-kernel nexmon-native patch — review + proposed follow-up

Reviewer notes on `pr10.patch` (PR #10, FlopKernel-Series/flop_exynos2100_kernel,
3 commits by Artiom-22000) and a proposed follow-up `0004` hardening the
**injection path only**. The capture, type-flip and channel-bridge paths are
correct and already verified on SM-G991B; this does **not** touch them.

## What the existing patch does (and does well)

- **Type-flip on arm/disarm.** `dhd_ioctl_process` mirrors `WLC_SET_MONITOR`
  (108) and the nexmon custom cmd `0x613` onto `net->type`
  (`ARPHRD_IEEE80211_RADIOTAP`), and correctly refuses to intercept
  `WLC_GET_MONITOR` (this firmware returns a constant `0x80000000`, so driving
  the type from a read would reset it). Good call, and the reason is documented.
- **No separate mon-if for nexmon.** `val >= 2` bypasses the stock
  `dhd_add_monitor_if` machinery and forces `monitor_type = 0` so the 802.11
  rx split can't re-route nexmon frames into a stale mon dev. Correct.
- **Channel bridge** via a module-registered function pointer
  (`nexmon_wext_set/get_channel`), used by both the wext compat layer and
  nl80211 (`SET_WIPHY` / `SET_CHANNEL`). Cleanly NULL for all other wifi HW.
- **Band-change guard** (2.4↔5 GHz while armed wedges the chip) returns
  `-EINVAL` so channel hoppers skip instead of killing the radio. Correct and
  important.
- **iftype truthfulness** (`iw dev`, wext `giwmode`) reports monitor.

This is solid, idiomatic bcmdhd/cfg80211 work. The notes below are
incremental.

## Proposed follow-up `0004` — isolate + bound the injection worker

All three changes are confined to the injection path in `dhd_linux.c` /
`dhd_linux_priv.h`.

### 1. Dedicated ordered workqueue instead of `system_wq`

`dhd_nexmon_inject_work()` calls `dhd_wl_ioctl_cmd(..., NEX_INJECT_FRAME)`,
which **sleeps**, once per frame. Running a sleeping, potentially slow (SDIO/PCIe
round-trip to firmware) item on the shared `system_wq`:

- lets unrelated `system_wq` items delay time-sensitive injection (aireplay-ng
  deauth bursts, EAPOL replays), and vice-versa;
- is exactly the case `alloc_ordered_workqueue()` exists for.

A dedicated single-threaded ordered WQ (`WQ_HIGHPRI`) gives injection its own
FIFO context, guaranteed in-order processing, and predictable latency. If the
alloc fails we fall back to `system_wq`, so it can never regress to "no
injection".

### 2. Bound the backlog (back-pressure)

`dhd_nexmon_mon_tx()` currently enqueues **unconditionally** and returns
`NETDEV_TX_OK`. `dhd_start_xmit` is atomic and cannot block, so there is no
natural back-pressure: if the firmware stalls (chip hang / `e=-121`) while a
tool floods frames, `nexmon_inj_q` grows without bound → OOM. Cap the queue
(`NEXMON_INJECT_MAX_QLEN`, 256) and drop + `tx_dropped++` past it. Injection is
best-effort radiotap tx; dropping under a stall is correct and safe.

(Also switch the atomic-context free to `dev_kfree_skb_any()`.)

### 3. Drop the self-requeue; use `destroy_workqueue()` for teardown

The worker's trailing `if (skb_peek(...)) schedule_work(...)` is redundant — the
`while (skb_dequeue(...))` loop already drains FIFO and every `mon_tx` enqueue
wakes the worker — and it races `cancel_work_sync()` on unload (a work that
requeues itself can slip past cancel). Remove it, and in `dhd_detach` use
`destroy_workqueue()` (flush + cancel + free) instead of `cancel_work_sync()`
on the bare work. `skb_queue_purge()` stays as a belt-and-braces final drain.

## Things to verify at build time (I could not compile here)

1. **`net` scope in `dhd_ioctl_process`.** The patch passes `net` to
   `dhd_nexmon_mon_update(pub, ifidx, net, nval)`. Confirm a
   `struct net_device *net` is in scope there (e.g. `dhd_idx2net(pub, ifidx)`);
   if not, derive it before the call. It compiled for Artiom, so this is just a
   re-check after the refactor.
2. **`net->stats` vs driver stats.** `tx_dropped++` on `net->stats` is standard;
   if this bcmdhd tree keeps tx counters elsewhere (`dhd->pub.tx_dropped`),
   point it there. Cosmetic — does not affect function.
3. **`nexmon_cached_chspec` is a single file-global**, mutated from the channel
   bridge and read by `get_channel`, with no lock. Fine for one wlan0 serialized
   by rtnl/wext; noting it in case of future multi-radio. Not changed in `0004`.

## Firmware side — scoped out, deliberately

Modifying the nexmon firmware (bcm4375b1) means writing/recompiling nexmon C
patches and reflashing firmware — no safe build/verify path offline, high brick
risk, and per Artiom the firmware is the hard part he intentionally left alone.
The kernel already exposes everything userspace needs natively, so the
high-value, low-risk work is on the kernel + app side. Recommend leaving the
firmware binary as-is unless a specific, testable win appears.
