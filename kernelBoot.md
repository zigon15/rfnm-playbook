U-Boot SPL 2022.04-gb59a410a-dirty (Feb 18 2026 - 11:10:06 +0000)
DDRINFO: start DRAM init
DDRINFO: DRAM rate 4000MTS
DDRINFO:ddrphy calibration done
DDRINFO: ddrmix config done
SEC0:  RNG instantiated
Normal Boot
Trying to boot from BOOTROM
Boot Stage: Primary boot
image offset 0x8000, pagesize 0x200, ivt offset 0x0
NOTICE:  Do not release JR0 to NS as it can be used by HAB
NOTICE:  BL31: v2.12.0(release):lf-6.12.49-2.2.0-dirty
NOTICE:  BL31: Built : 11:09:59, Feb 18 2026


U-Boot 2022.04-gb59a410a-dirty (Feb 18 2026 - 11:10:06 +0000)

CPU:   i.MX8MP Lite[4] rev1.1 at 1600MHz
CPU:   Industrial temperature grade (-40C to 105C) at 53C
Reset cause: POR
Model: NXP i.MX8MPlus LPDDR4 EVK board
DRAM:  4 GiB
Done pwr en init
Core:  73 devices, 21 uclasses, devicetree: separate
MMC:   FSL_SDHC: 1, FSL_SDHC: 2
Loading Environment from MMC... *** Warning - bad CRC, using default environment

Fail to setup video link
In:    serial
Out:   serial
Err:   serial
SEC0:  RNG instantiated

 BuildInfo:
  - ATF lf-6.12

flash target is MMC:1
Net:   eth1: ethernet@30bf0000 [PRIME]
Fastboot: Normal
Normal Boot
Hit any key to stop autoboot:  0 
Found Boot Script
269 bytes read in 1 ms (262.7 KiB/s)
## Executing script at 43500000
34142720 bytes read in 360 ms (90.4 MiB/s)
57918 bytes read in 1 ms (55.2 MiB/s)
## Flattened Device Tree blob at 43000000
   Booting using the fdt blob at 0x43000000
ERROR: reserving fdt memory region failed (addr=10000000 size=1000000 flags=4)
ERROR: reserving fdt memory region failed (addr=7e0000 size=20000 flags=4)
ERROR: reserving fdt memory region failed (addr=800000 size=20000 flags=4)
ERROR: reserving fdt memory region failed (addr=55000000 size=8000 flags=4)
ERROR: reserving fdt memory region failed (addr=55008000 size=8000 flags=4)
ERROR: reserving fdt memory region failed (addr=55400000 size=100000 flags=4)
ERROR: reserving fdt memory region failed (addr=550ff000 size=1000 flags=4)
   Using Device Tree in place at 0000000043000000, end 000000004301123d
Modify /vpu_g1@38300000:status disabled
Modify /vpu_g2@38310000:status disabled
Modify /vpu_vc8000e@38320000:status disabled
Modify /vipsi@38500000:status disabled
Modify /soc@0/bus@32c00000/camera/isp@32e10000:status disabled
Modify /soc@0/bus@32c00000/camera/isp@32e20000:status disabled
Modify /dsp@3b6e8000:status disabled

Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0x0000000000 [0x410fd034]
[    0.000000] Linux version 6.6.36-rt35 (root@simon) (aarch64-linux-gnu-gcc (Debian 14.2.0-19) 14.2.0, GNU ld (GNU Binutils for Debian) 2.44) #2 SMP PREEMPT_RT Thu Feb 19 01:11:28 UTC 2026
[    0.000000] KASLR disabled due to lack of seed
[    0.000000] Machine model: RFNM imx8mp
[    0.000000] efi: UEFI not found.
[    0.000000] Reserved memory: created CMA memory pool at 0x00000000c4000000, size 960 MiB
[    0.000000] OF: reserved mem: initialized node linux,cma, compatible id shared-dma-pool
[    0.000000] OF: reserved mem: 0x00000000c4000000..0x00000000ffffffff (983040 KiB) map reusable linux,cma
[    0.000000] OF: reserved mem: 0x00000000007e0000..0x00000000007fffff (128 KiB) nomap non-reusable m4@7E0000
[    0.000000] OF: reserved mem: 0x0000000000800000..0x000000000081ffff (128 KiB) nomap non-reusable m4@800000
[    0.000000] OF: reserved mem: 0x0000000000900000..0x000000000096ffff (448 KiB) nomap non-reusable ocram@900000
[    0.000000] OF: reserved mem: 0x0000000010000000..0x0000000010ffffff (16384 KiB) nomap non-reusable m4@10000000
[    0.000000] OF: reserved mem: 0x0000000055000000..0x0000000055007fff (32 KiB) nomap non-reusable vdev0vring0@55000000
[    0.000000] OF: reserved mem: 0x0000000055008000..0x000000005500ffff (32 KiB) nomap non-reusable vdev0vring1@55008000
[    0.000000] OF: reserved mem: 0x00000000550ff000..0x00000000550fffff (4 KiB) nomap non-reusable rsc_table@550ff000
[    0.000000] Reserved memory: created DMA memory pool at 0x0000000055400000, size 1 MiB
[    0.000000] OF: reserved mem: initialized node vdevbuffer@55400000, compatible id shared-dma-pool
[    0.000000] OF: reserved mem: 0x0000000055400000..0x00000000554fffff (1024 KiB) nomap non-reusable vdevbuffer@55400000
[    0.000000] OF: reserved mem: 0x0000000080000000..0x0000000080ffffff (16384 KiB) nomap non-reusable m4@80000000
[    0.000000] OF: reserved mem: 0x0000000082400000..0x00000000923fffff (262144 KiB) nomap non-reusable iqlocale@82400000
[    0.000000] OF: reserved mem: 0x0000000092400000..0x00000000963fffff (65536 KiB) nomap non-reusable la93@92400000
[    0.000000] OF: reserved mem: 0x0000000096400000..0x000000009d3fffff (114688 KiB) nomap non-reusable iqflood@96400000
[    0.000000] Reserved memory: created CMA memory pool at 0x000000009d400000, size 96 MiB
[    0.000000] OF: reserved mem: initialized node iqusb@9D400000, compatible id shared-dma-pool
[    0.000000] OF: reserved mem: 0x000000009d400000..0x00000000a33fffff (98304 KiB) map reusable iqusb@9D400000
[    0.000000] OF: reserved mem: 0x00000000a3400000..0x00000000a37fffff (4096 KiB) nomap non-reusable bootconfig@A3400000
[    0.000000] OF: reserved mem: 0x0000000100000000..0x000000010fffffff (262144 KiB) nomap non-reusable gpu_reserved@100000000
[    0.000000] earlycon: ec_imx6q0 at MMIO 0x0000000030890000 (options '')
[    0.000000] printk: legacy bootconsole [ec_imx6q0] enabled
[    0.000000] NUMA: No NUMA configuration found
[    0.000000] NUMA: Faking a node at [mem 0x0000000040000000-0x000000013fffffff]
[    0.000000] NUMA: NODE_DATA [mem 0x13f9105c0-0x13f912fff]
[    0.000000] Zone ranges:
[    0.000000]   DMA      [mem 0x0000000040000000-0x00000000ffffffff]
[    0.000000]   DMA32    empty
[    0.000000]   Normal   [mem 0x0000000100000000-0x000000013fffffff]
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000040000000-0x0000000054ffffff]
[    0.000000]   node   0: [mem 0x0000000055000000-0x000000005500ffff]
[    0.000000]   node   0: [mem 0x0000000055010000-0x00000000550fefff]
[    0.000000]   node   0: [mem 0x00000000550ff000-0x00000000550fffff]
[    0.000000]   node   0: [mem 0x0000000055100000-0x00000000553fffff]
[    0.000000]   node   0: [mem 0x0000000055400000-0x00000000554fffff]
[    0.000000]   node   0: [mem 0x0000000055500000-0x000000007fffffff]
[    0.000000]   node   0: [mem 0x0000000080000000-0x0000000080ffffff]
[    0.000000]   node   0: [mem 0x0000000081000000-0x00000000823fffff]
[    0.000000]   node   0: [mem 0x0000000082400000-0x000000009d3fffff]
[    0.000000]   node   0: [mem 0x000000009d400000-0x00000000a33fffff]
[    0.000000]   node   0: [mem 0x00000000a3400000-0x00000000a37fffff]
[    0.000000]   node   0: [mem 0x00000000a3800000-0x00000000ffffffff]
[    0.000000]   node   0: [mem 0x0000000100000000-0x000000010fffffff]
[    0.000000]   node   0: [mem 0x0000000110000000-0x000000013fffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000040000000-0x000000013fffffff]
[    0.000000] psci: probing for conduit method from DT.
[    0.000000] psci: PSCIv1.1 detected in firmware.
[    0.000000] psci: Using standard PSCI v0.2 function IDs
[    0.000000] psci: MIGRATE_INFO_TYPE not supported.
[    0.000000] psci: SMC Calling Convention v1.5
[    0.000000] percpu: Embedded 21 pages/cpu s46272 r8192 d31552 u86016
[    0.000000] Detected VIPT I-cache on CPU0
[    0.000000] CPU features: detected: GIC system register CPU interface
[    0.000000] CPU features: detected: ARM erratum 845719
[    0.000000] alternatives: applying boot alternatives
[    0.000000] Kernel command line: console=tty0 console=ttymxc1,115200 earlycon root=/dev/mmcblk1p2 rootwait rw
[    0.000000] Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes, linear)
[    0.000000] Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Fallback order for Node 0: 0 
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 1032192
[    0.000000] Policy zone: Normal
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] software IO TLB: area num 4.
[    0.000000] software IO TLB: mapped [mem 0x00000000c0000000-0x00000000c4000000] (64MB)
[    0.000000] Memory: 2207348K/4194304K available (20736K kernel code, 2110K rwdata, 8376K rodata, 1984K init, 663K bss, 905612K reserved, 1081344K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
[    0.000000] rcu: Preemptible hierarchical RCU implementation.
[    0.000000] rcu:     RCU event tracing is enabled.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=256 to nr_cpu_ids=4.
[    0.000000] rcu:     RCU priority boosting: priority 1 delay 500 ms.
[    0.000000] rcu:     RCU_SOFTIRQ processing moved to rcuc kthreads.
[    0.000000]  No expedited grace period (rcu_normal_after_boot).
[    0.000000]  Trampoline variant of Tasks RCU enabled.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] GICv3: GIC: Using split EOI/Deactivate mode
[    0.000000] GICv3: 160 SPIs implemented
[    0.000000] GICv3: 0 Extended SPIs implemented
[    0.000000] Root IRQ handler: gic_handle_irq
[    0.000000] GICv3: GICv3 features: 16 PPIs
[    0.000000] GICv3: CPU0: found redistributor 0 region 0:0x0000000038880000
[    0.000000] ITS: No ITS available, not enabling LPIs
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] arch_timer: cp15 timer(s) running at 8.00MHz (phys).
[    0.000000] clocksource: arch_sys_counter: mask: 0xffffffffffffff max_cycles: 0x1d854df40, max_idle_ns: 440795202120 ns
[    0.000000] sched_clock: 56 bits at 8MHz, resolution 125ns, wraps every 2199023255500ns
[    0.000367] Console: colour dummy device 80x25
[    0.000375] printk: legacy console [tty0] enabled
[    0.000424] Calibrating delay loop (skipped), value calculated using timer frequency.. 16.00 BogoMIPS (lpj=32000)
[    0.000432] pid_max: default: 32768 minimum: 301
[    0.000486] LSM: initializing lsm=capability,integrity
[    0.000553] Mount-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.000567] Mountpoint-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.001824] RCU Tasks: Setting shift to 2 and lim to 1 rcu_task_cb_adjust=1.
[    0.001883] RCU Tasks Trace: Setting shift to 2 and lim to 1 rcu_task_cb_adjust=1.
[    0.002156] rcu: Hierarchical SRCU implementation.
[    0.002159] rcu:     Max phase no-delay instances is 1000.
[    0.061115] EFI services will not be available.
[    0.227074] smp: Bringing up secondary CPUs ...
[    0.296197] Detected VIPT I-cache on CPU1
[    0.296253] GICv3: CPU1: found redistributor 1 region 0:0x00000000388a0000
[    0.296285] CPU1: Booted secondary processor 0x0000000001 [0x410fd034]
[    0.629607] Detected VIPT I-cache on CPU2
[    0.629652] GICv3: CPU2: found redistributor 2 region 0:0x00000000388c0000
[    0.629673] CPU2: Booted secondary processor 0x0000000002 [0x410fd034]
[    0.780291] Detected VIPT I-cache on CPU3
[    0.780329] GICv3: CPU3: found redistributor 3 region 0:0x00000000388e0000
[    0.780346] CPU3: Booted secondary processor 0x0000000003 [0x410fd034]
[    0.783839] smp: Brought up 1 node, 4 CPUs
[    0.783844] SMP: Total of 4 processors activated.
[    0.783847] CPU features: detected: 32-bit EL0 Support
[    0.783850] CPU features: detected: CRC32 instructions
[    0.790770] CPU: All CPU(s) started at EL2
[    0.790772] alternatives: applying system-wide alternatives
[    0.796541] devtmpfs: initialized
[    0.807911] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.807929] futex hash table entries: 1024 (order: 4, 65536 bytes, linear)
[    0.834228] pinctrl core: initialized pinctrl subsystem
[    0.836377] DMI not present or invalid.
[    0.836930] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.837936] DMA: preallocated 512 KiB GFP_KERNEL pool for atomic allocations
[    0.838038] DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA pool for atomic allocations
[    0.838192] DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    0.838239] audit: initializing netlink subsys (disabled)
[    0.838366] audit: type=2000 audit(0.836:1): state=initialized audit_enabled=0 res=1
[    0.838986] thermal_sys: Registered thermal governor 'step_wise'
[    0.838990] thermal_sys: Registered thermal governor 'power_allocator'
[    0.839019] cpuidle: using governor menu
[    0.839241] hw-breakpoint: found 6 breakpoint and 4 watchpoint registers.
[    0.839302] ASID allocator initialised with 65536 entries
[    0.840205] Serial: AMBA PL011 UART driver
[    0.840276] imx mu driver is registered.
[    0.840299] imx rpmsg driver is registered.
[    0.845192] platform soc@0: Fixed dependency cycle(s) with /soc@0/bus@30000000/efuse@30350000/unique-id@8
[    0.847256] platform 30330000.pinctrl: Fixed dependency cycle(s) with /soc@0/bus@30000000/pinctrl@30330000/imx8mp-custom-board/eqosgrp
[    0.847664] imx8mp-pinctrl 30330000.pinctrl: initialized IMX pinctrl driver
[    0.848138] platform 30350000.efuse: Fixed dependency cycle(s) with /soc@0/bus@30000000/clock-controller@30380000
[    0.849361] platform 30350000.efuse: Fixed dependency cycle(s) with /soc@0/bus@30000000/clock-controller@30380000
[    0.859550] platform 32fc6000.lcd-controller: Fixed dependency cycle(s) with /soc@0/bus@30c00000/hdmi@32fd8000
[    0.859900] platform 32fc6000.lcd-controller: Fixed dependency cycle(s) with /soc@0/bus@30c00000/hdmi@32fd8000
[    0.860049] platform 32fd8000.hdmi: Fixed dependency cycle(s) with /soc@0/bus@30c00000/lcd-controller@32fc6000
[    0.864817] platform fusb340-sw: Fixed dependency cycle(s) with /soc@0/bus@30800000/i2c@30a20000/tcpc@22/connector
[    0.865682] Modules: 24256 pages in range for non-PLT usage
[    0.865686] Modules: 515776 pages in range for PLT usage
[    0.866284] HugeTLB: registered 1.00 GiB page size, pre-allocated 0 pages
[    0.866289] HugeTLB: 0 KiB vmemmap can be freed for a 1.00 GiB page
[    0.866292] HugeTLB: registered 32.0 MiB page size, pre-allocated 0 pages
[    0.866295] HugeTLB: 0 KiB vmemmap can be freed for a 32.0 MiB page
[    0.866298] HugeTLB: registered 2.00 MiB page size, pre-allocated 0 pages
[    0.866302] HugeTLB: 0 KiB vmemmap can be freed for a 2.00 MiB page
[    0.866305] HugeTLB: registered 64.0 KiB page size, pre-allocated 0 pages
[    0.866308] HugeTLB: 0 KiB vmemmap can be freed for a 64.0 KiB page
[    1.091894] ACPI: Interpreter disabled.
[    1.092563] iommu: Default domain type: Translated
[    1.092569] iommu: DMA domain TLB invalidation policy: strict mode
[    1.092896] SCSI subsystem initialized
[    1.093263] usbcore: registered new interface driver usbfs
[    1.093297] usbcore: registered new interface driver hub
[    1.093329] usbcore: registered new device driver usb
[    1.094372] mc: Linux media interface: v0.10
[    1.094414] videodev: Linux video capture interface: v2.00
[    1.094483] pps_core: LinuxPPS API ver. 1 registered
[    1.094486] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    1.094502] PTP clock support registered
[    1.094677] EDAC MC: Ver: 3.0.0
[    1.095155] scmi_core: SCMI protocol bus registered
[    1.095573] FPGA manager framework
[    1.095667] Advanced Linux Sound Architecture Driver Initialized.
[    1.096336] Bluetooth: Core ver 2.22
[    1.096370] NET: Registered PF_BLUETOOTH protocol family
[    1.096373] Bluetooth: HCI device and connection manager initialized
[    1.096379] Bluetooth: HCI socket layer initialized
[    1.096384] Bluetooth: L2CAP socket layer initialized
[    1.096395] Bluetooth: SCO socket layer initialized
[    1.096704] vgaarb: loaded
[    1.097194] clocksource: Switched to clocksource arch_sys_counter
[    1.097396] VFS: Disk quotas dquot_6.6.0
[    1.097419] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
[    1.097591] pnp: PnP ACPI: disabled
[    1.104239] NET: Registered PF_INET protocol family
[    1.104400] IP idents hash table entries: 65536 (order: 7, 524288 bytes, linear)
[    1.106594] tcp_listen_portaddr_hash hash table entries: 2048 (order: 4, 81920 bytes, linear)
[    1.106696] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    1.106714] TCP established hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    1.107022] TCP bind hash table entries: 32768 (order: 9, 2621440 bytes, linear)
[    1.109351] TCP: Hash tables configured (established 32768 bind 32768)
[    1.109483] UDP hash table entries: 2048 (order: 5, 196608 bytes, linear)
[    1.109719] UDP-Lite hash table entries: 2048 (order: 5, 196608 bytes, linear)
[    1.110051] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    1.110423] RPC: Registered named UNIX socket transport module.
[    1.110427] RPC: Registered udp transport module.
[    1.110429] RPC: Registered tcp transport module.
[    1.110431] RPC: Registered tcp-with-tls transport module.
[    1.110433] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    1.111244] NET: Registered PF_XDP protocol family
[    1.111255] PCI: CLS 0 bytes, default 64
[    1.114236] Initialise system trusted keyrings
[    1.114389] workingset: timestamp_bits=42 max_order=20 bucket_order=0
[    1.114674] squashfs: version 4.0 (2009/01/31) Phillip Lougher
[    1.114864] NFS: Registering the id_resolver key type
[    1.114890] Key type id_resolver registered
[    1.114893] Key type id_legacy registered
[    1.114910] nfs4filelayout_init: NFSv4 File Layout Driver Registering...
[    1.114914] nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
[    1.114929] jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
[    1.115116] 9p: Installing v9fs 9p2000 file system support
[    1.136198] jitterentropy: Initialization failed with host not compliant with requirements: 9
[    1.136205] Key type asymmetric registered
[    1.136208] Asymmetric key parser 'x509' registered
[    1.136252] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 243)
[    1.136257] io scheduler mq-deadline registered
[    1.136260] io scheduler kyber registered
[    1.136285] io scheduler bfq registered
[    1.147673] EINJ: ACPI disabled.
[    1.158991] imx-sdma 30bd0000.dma-controller: Direct firmware load for imx/sdma/sdma-imx7d.bin failed with error -2
[    1.159005] imx-sdma 30bd0000.dma-controller: Falling back to sysfs fallback for: imx/sdma/sdma-imx7d.bin
[    1.160635] mxs-dma 33000000.dma-apbh: initialized
[    1.161984] SoC: i.MX8MP revision 1.1
[    1.162391] Bus freq driver module loaded
[    1.181000] Serial: 8250/16550 driver, 4 ports, IRQ sharing enabled
[    1.184401] 30890000.serial: ttymxc1 at MMIO 0x30890000 (irq = 24, base_baud = 1500000) is a IMX
[    1.476262] printk: legacy console [ttymxc1] enabled
[    1.476268] printk: legacy bootconsole [ec_imx6q0] disabled
[    1.490084] etnaviv etnaviv: bound 38000000.gpu3d (ops gpu_ops)
[    1.490209] etnaviv etnaviv: bound 38008000.gpu2d (ops gpu_ops)
[    1.490289] etnaviv-gpu 38000000.gpu3d: model: GC7000, revision: 6204
[    1.490426] etnaviv-gpu 38008000.gpu2d: model: GC520, revision: 5341
[    1.490831] [drm] Initialized etnaviv 1.4.0 20151214 for etnaviv on minor 0
[    1.497803] loop: module loaded
[    1.499297] of_reserved_mem_lookup() returned NULL
[    1.499482] megasas: 07.725.01.00-rc1
[    1.507103] tun: Universal TUN/TAP device driver, 1.6
[    1.507991] thunder_xcv, ver 1.0
[    1.508025] thunder_bgx, ver 1.0
[    1.508056] nicpf, ver 1.0
[    1.510658] hns3: Hisilicon Ethernet Network Driver for Hip08 Family - version
[    1.510662] hns3: Copyright (c) 2017 Huawei Corporation.
[    1.510699] hclge is initializing
[    1.510736] e1000: Intel(R) PRO/1000 Network Driver
[    1.510738] e1000: Copyright (c) 1999-2006 Intel Corporation.
[    1.510766] e1000e: Intel(R) PRO/1000 Network Driver
[    1.510768] e1000e: Copyright(c) 1999 - 2015 Intel Corporation.
[    1.510794] igb: Intel(R) Gigabit Ethernet Network Driver
[    1.510797] igb: Copyright (c) 2007-2014 Intel Corporation.
[    1.510829] igbvf: Intel(R) Gigabit Virtual Function Network Driver
[    1.510832] igbvf: Copyright (c) 2009 - 2012 Intel Corporation.
[    1.510997] sky2: driver version 1.30
[    1.511601] usbcore: registered new device driver r8152-cfgselector
[    1.511633] usbcore: registered new interface driver r8152
[    1.512053] VFIO - User Level meta-driver version: 0.3
[    1.513577] platform 38100000.usb: Fixed dependency cycle(s) with /soc@0/bus@30800000/i2c@30a20000/tcpc@22
[    1.518820] usbcore: registered new interface driver uas
[    1.518857] usbcore: registered new interface driver usb-storage
[    1.518935] usbcore: registered new interface driver usbserial_generic
[    1.518960] usbserial: USB Serial support registered for generic
[    1.518988] usbcore: registered new interface driver ftdi_sio
[    1.519012] usbserial: USB Serial support registered for FTDI USB Serial Device
[    1.519036] usbcore: registered new interface driver usb_serial_simple
[    1.519057] usbserial: USB Serial support registered for carelink
[    1.519078] usbserial: USB Serial support registered for flashloader
[    1.519098] usbserial: USB Serial support registered for funsoft
[    1.519123] usbserial: USB Serial support registered for google
[    1.519146] usbserial: USB Serial support registered for hp4x
[    1.519168] usbserial: USB Serial support registered for kaufmann
[    1.519192] usbserial: USB Serial support registered for libtransistor
[    1.519211] usbserial: USB Serial support registered for moto_modem
[    1.519236] usbserial: USB Serial support registered for motorola_tetra
[    1.519257] usbserial: USB Serial support registered for nokia
[    1.519281] usbserial: USB Serial support registered for novatel_gps
[    1.519303] usbserial: USB Serial support registered for siemens_mpi
[    1.519326] usbserial: USB Serial support registered for suunto
[    1.519366] usbserial: USB Serial support registered for vivopay
[    1.519385] usbserial: USB Serial support registered for zio
[    1.519414] usbcore: registered new interface driver usb_ehset_test
[    1.521375] gadgetfs: USB Gadget filesystem, version 24 Aug 2004
[    1.522519] input: 30370000.snvs:snvs-powerkey as /devices/platform/soc@0/30000000.bus/30370000.snvs/30370000.snvs:snvs-powerkey/input/input0
[    1.524725] snvs_rtc 30370000.snvs:snvs-rtc-lp: registered as rtc0
[    1.524746] snvs_rtc 30370000.snvs:snvs-rtc-lp: setting system clock to 1970-01-01T00:00:00 UTC (0)
[    1.524903] i2c_dev: i2c /dev entries driver
[    1.530948] Bluetooth: HCI UART driver ver 2.3
[    1.530959] Bluetooth: HCI UART protocol H4 registered
[    1.530962] Bluetooth: HCI UART protocol BCSP registered
[    1.530989] Bluetooth: HCI UART protocol LL registered
[    1.530992] Bluetooth: HCI UART protocol ATH3K registered
[    1.531014] Bluetooth: HCI UART protocol Three-wire (H5) registered
[    1.531115] Bluetooth: HCI UART protocol Broadcom registered
[    1.531136] Bluetooth: HCI UART protocol QCA registered
[    1.531349] EDAC MC: ECC not enabled
[    1.532855] sdhci: Secure Digital Host Controller Interface driver
[    1.532859] sdhci: Copyright(c) Pierre Ossman
[    1.533500] Synopsys Designware Multimedia Card Interface Driver
[    1.534192] sdhci-pltfm: SDHCI platform and OF driver helper
[    1.538297] SMCCC: SOC_ID: ARCH_SOC_ID not implemented, skipping ....
[    1.538429] usbcore: registered new interface driver usbhid
[    1.538433] usbhid: USB HID core driver
[    1.545460] hw perfevents: enabled with armv8_cortex_a53 PMU driver, 7 counters available
[    1.548264]  cs_system_cfg: CoreSight Configuration manager initialised
[    1.549177] platform soc@0: Fixed dependency cycle(s) with /soc@0/bus@30000000/efuse@30350000
[    1.550261] optee: probing for conduit method.
[    1.550270] optee: api uid mismatch
[    1.550272] optee: probe of firmware:optee failed with error -22
[    1.553827] pktgen: Packet Generator for packet performance testing. Version: 2.75
[    1.557425] NET: Registered PF_LLC protocol family
[    1.557445] Mirror/redirect action on
[    1.557509] u32 classifier
[    1.557512]     input device check on
[    1.557513]     Actions configured
[    1.557828] NET: Registered PF_INET6 protocol family
[    1.558350] Segment Routing with IPv6
[    1.558379] In-situ OAM (IOAM) with IPv6
[    1.558422] NET: Registered PF_PACKET protocol family
[    1.558442] bridge: filtering via arp/ip/ip6tables is no longer available by default. Update your scripts to load br_netfilter if you need this.
[    1.558505] Bluetooth: RFCOMM TTY layer initialized
[    1.558515] Bluetooth: RFCOMM socket layer initialized
[    1.558544] Bluetooth: RFCOMM ver 1.11
[    1.558552] Bluetooth: BNEP (Ethernet Emulation) ver 1.3
[    1.558555] Bluetooth: BNEP filters: protocol multicast
[    1.558561] Bluetooth: BNEP socket layer initialized
[    1.558564] Bluetooth: HIDP (Human Interface Emulation) ver 1.2
[    1.558571] Bluetooth: HIDP socket layer initialized
[    1.558678] 8021q: 802.1Q VLAN Support v1.8
[    1.558694] lib80211: common routines for IEEE802.11 drivers
[    1.558727] 9pnet: Installing 9P2000 support
[    1.558856] Key type dns_resolver registered
[    1.559016] NET: Registered PF_VSOCK protocol family
[    1.569798] mmc2: SDHCI controller on 30b60000.mmc [30b60000.mmc] using ADMA
[    1.575111] registered taskstats version 1
[    1.575254] Loading compiled-in X.509 certificates
[    1.603735] gpio gpiochip0: Static allocation of GPIO base is deprecated, use dynamic allocation.
[    1.605335] gpio gpiochip1: Static allocation of GPIO base is deprecated, use dynamic allocation.
[    1.607140] gpio gpiochip2: Static allocation of GPIO base is deprecated, use dynamic allocation.
[    1.608884] gpio gpiochip3: Static allocation of GPIO base is deprecated, use dynamic allocation.
[    1.610695] gpio gpiochip4: Static allocation of GPIO base is deprecated, use dynamic allocation.
[    1.615439] platform 38100000.usb: Fixed dependency cycle(s) with /soc@0/bus@30800000/i2c@30a20000/tcpc@22
[    1.615608] i2c 0-0022: Fixed dependency cycle(s) with /soc@0/usb@32f10100/usb@38100000
[    1.618926] hwmon hwmon0: temp1_input not attached to any thermal zone
[    1.618942] tmp102 0-0048: initialized
[    1.619650] RFNM: Deferring Si5510 probe...
[    1.639760] RFNM: Motherboard id 4 revision 1 serial U3D6CP3J mac-addr 00:04:9f:08:be:8e
[    1.647148] mmc2: new HS400 Enhanced strobe MMC card at address 0001
[    1.647806] mmcblk2: mmc2:0001 TY2964 58.3 GiB
[    1.648951] i2c i2c-0: IMX I2C adapter registered
[    1.651446]  mmcblk2: p1 p2 p3
[    1.652550] mmcblk2boot0: mmc2:0001 TY2964 4.00 MiB
[    1.654355] mmcblk2boot1: mmc2:0001 TY2964 4.00 MiB
[    1.656057] mmcblk2rpmb: mmc2:0001 TY2964 4.00 MiB, chardev (234:0)
[    1.661095] nxp-pca9450 0-0025: pca9450bc probed.
[    1.669853] RFNM: Daughterboard detected on slot 1, board id 3 revision 1 serial 24JC9ANS
[    1.671032] hwmon hwmon1: temp1_input not attached to any thermal zone
[    1.671039] tmp102 1-0048: initialized
[    1.671091] i2c i2c-1: IMX I2C adapter registered
[    1.694428] RFNM: Daughterboard detected on slot 2, board id 1 revision 1 serial YTLPXRJM
[    1.695033] tmp102 2-0048: error reading config register
[    1.695156] i2c i2c-2: IMX I2C adapter registered
[    1.696340] imx8mq-usb-phy 382f0040.usb-phy: supply vbus not found, using dummy regulator
[    1.696704] RFNM: Deferring PCIe probe...
[    1.712316] dwhdmi-imx 32fd8000.hdmi: Detected HDMI TX controller v2.13a with HDCP (samsung_dw_hdmi_phy2)
[    1.714210] dwhdmi-imx 32fd8000.hdmi: registered DesignWare HDMI I2C bus driver
[    1.717139] imx-drm display-subsystem: bound imx-lcdifv3-crtc.0 (ops lcdifv3_crtc_ops)
[    1.717254] imx-drm display-subsystem: bound 32fd8000.hdmi (ops dw_hdmi_imx_ops)
[    1.717643] [drm] Initialized imx-drm 1.0.0 20120507 for display-subsystem on minor 1
[    2.391068] EDID block 2 (tag 0x00) checksum is invalid, remainder is 191
[    2.454632] Console: switching to colour frame buffer device 240x67
[    2.470760] imx-drm display-subsystem: [drm] fb0: imx-drmdrmfb frame buffer device
[    2.471797] Delaying spi clock from CS by 1 clocks
[    2.473422] Delaying spi clock from CS by 1 clocks
[    2.475366] imx-dwmac 30bf0000.ethernet: IRQ eth_lpi not found
[    2.475630] imx-dwmac 30bf0000.ethernet: User ID: 0x10, Synopsys ID: 0x51
[    2.475639] imx-dwmac 30bf0000.ethernet:     DWMAC4/5
[    2.475644] imx-dwmac 30bf0000.ethernet: DMA HW capability register supported
[    2.475648] imx-dwmac 30bf0000.ethernet: RX Checksum Offload Engine supported
[    2.475651] imx-dwmac 30bf0000.ethernet: TX Checksum insertion supported
[    2.475654] imx-dwmac 30bf0000.ethernet: Wake-Up On Lan supported
[    2.475704] imx-dwmac 30bf0000.ethernet: Enable RX Mitigation via HW Watchdog Timer
[    2.475709] imx-dwmac 30bf0000.ethernet: Enabled L3L4 Flow TC (entries=8)
[    2.475714] imx-dwmac 30bf0000.ethernet: Enabled RFS Flow TC (entries=10)
[    2.475723] imx-dwmac 30bf0000.ethernet: Enabling HW TC (entries=256, max_off=256)
[    2.475728] imx-dwmac 30bf0000.ethernet: Using 34/40 bits DMA host/device width
[    2.735050] xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
[    2.735076] xhci-hcd xhci-hcd.1.auto: new USB bus registered, assigned bus number 1
[    2.735409] xhci-hcd xhci-hcd.1.auto: hcc params 0x0220fe6d hci version 0x110 quirks 0x000000a001000010
[    2.735588] xhci-hcd xhci-hcd.1.auto: irq 218, io mem 0x38200000
[    2.735742] xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
[    2.735754] xhci-hcd xhci-hcd.1.auto: new USB bus registered, assigned bus number 2
[    2.735765] xhci-hcd xhci-hcd.1.auto: Host supports USB 3.0 SuperSpeed
[    2.736018] imx-cpufreq-dt imx-cpufreq-dt: cpu speed grade 7 mkt segment 2 supported-hw 0x80 0x4
[    2.736717] hub 1-0:1.0: USB hub found
[    2.736741] hub 1-0:1.0: 1 port detected
[    2.737160] usb usb2: We don't know the algorithms for LPM for this host, disabling LPM.
[    2.737797] hub 2-0:1.0: USB hub found
[    2.737821] hub 2-0:1.0: 1 port detected
[    2.739036] RFNM: WSLED driver
[    2.741529] sdhci-esdhc-imx 30b50000.mmc: Got CD GPIO
[    2.742033] remoteproc remoteproc0: imx8mp-cm7 is available
[    2.752148] RFNM: Starting up Si5510...
[    2.770930] mmc1: SDHCI controller on 30b50000.mmc [30b50000.mmc] using ADMA
[    2.951446] EDID block 2 (tag 0x00) checksum is invalid, remainder is 191
[    3.032220] mmc1: host does not support reading read-only switch, assuming write-enable
[    3.052467] mmc1: new ultra high speed SDR104 SDHC card at address aaaa
[    3.053148] mmcblk1: mmc1:aaaa SP32G 29.7 GiB
[    3.055264]  mmcblk1: p1 p2
[    3.465237] random: crng init done
[    4.057501] RFNM: DCS clock not set in eeprom, defaulting to 122...
[    4.057508] RFNM: DCS clock is 11673.6 MHz / 95
[    4.080968] RFNM: Selected plan 2 RFNM_DAUGHTERBOARD_LIME, RFNM_DAUGHTERBOARD_LIME
[    4.080973] RFNM: Enabling clock output 15
[    4.107884] RFNM: Enabling clocks for RBA
[    4.107889] RFNM: Enabling clock output 6
[    4.132880] RFNM: Enabling clock output 8
[    4.155666] RFNM: Waiting for reference clock to lock...
[    4.305486] RFNM: Si5510 is ready and providing a PCIe clock!
[    4.345795] RFNM: Performed LA9310 reset
[    4.346474] RFNM: PCIe started
[    4.348038] imx6q-pcie 33800000.pcie: host bridge /soc@0/pcie@33800000 ranges:
[    4.348079] imx6q-pcie 33800000.pcie:       IO 0x001ff80000..0x001ff8ffff -> 0x0000000000
[    4.348099] imx6q-pcie 33800000.pcie:      MEM 0x0018000000..0x001fefffff -> 0x0018000000
[    4.350585] imx6q-pcie 33800000.pcie: iATU: unroll T, 4 ob, 4 ib, align 64K, limit 16G
[    4.350818] cfg80211: Loading compiled-in X.509 certificates for regulatory database
[    4.352243] Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
[    4.352934] Loaded X.509 cert 'wens: 61c038651aabdcf94bd0ac7ff06c7248db18c600'
[    4.352997] clk: Disabling unused clocks
[    4.353332] platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
[    4.353342] platform regulatory.0: Falling back to sysfs fallback for: regulatory.db
[    4.357976] ALSA device list:
[    4.357983]   No soundcards found.
[    4.450969] imx6q-pcie 33800000.pcie: PCIe Gen.1 x1 link up
[    4.551613] imx6q-pcie 33800000.pcie: PCIe Gen.3 x1 link up
[    4.551625] imx6q-pcie 33800000.pcie: Link up, Gen3
[    4.551632] imx6q-pcie 33800000.pcie: PCIe Gen.3 x1 link up
[    4.552005] imx6q-pcie 33800000.pcie: PCI host bridge to bus 0000:00
[    4.552016] pci_bus 0000:00: root bus resource [bus 00-ff]
[    4.552025] pci_bus 0000:00: root bus resource [io  0x0000-0xffff]
[    4.552032] pci_bus 0000:00: root bus resource [mem 0x18000000-0x1fefffff]
[    4.552061] pci 0000:00:00.0: [16c3:abcd] type 01 class 0x060400
[    4.552075] pci 0000:00:00.0: reg 0x10: [mem 0x00000000-0x000fffff]
[    4.552086] pci 0000:00:00.0: reg 0x38: [mem 0x00000000-0x0000ffff pref]
[    4.552128] pci 0000:00:00.0: supports D1
[    4.552133] pci 0000:00:00.0: PME# supported from D0 D1 D3hot D3cold
[    4.554877] pci 0000:01:00.0: Setting PCI class for LA9310 PCIe device!
[    4.554884] pci 0000:01:00.0: [1957:1c12] type 00 class 0x000280
[    4.554918] pci 0000:01:00.0: reg 0x10: forcing BAR0 readback 0xf0000000 to 0xfc000000 (i.e.64MB)
[    4.554924] pci 0000:01:00.0: reg 0x10: [mem 0x00000000-0x03ffffff]
[    4.554943] pci 0000:01:00.0: reg 0x14: [mem 0x00000000-0x0001ffff]
[    4.554970] pci 0000:01:00.0: reg 0x18: [mem 0x00000000-0x007fffff 64bit pref]
[    4.555013] pci 0000:01:00.0: reg 0x30: [mem 0x00000000-0x00ffffff pref]
[    4.555146] pci 0000:01:00.0: PME# supported from D0 D3hot
[    4.565888] pci 0000:00:00.0: BAR 14: assigned [mem 0x18000000-0x1dffffff] (96MB 98304KB)
[    4.565903] pci 0000:00:00.0: BAR 15: assigned [mem 0x1e000000-0x1f7fffff pref] (24MB 24576KB)
[    4.565913] pci 0000:00:00.0: BAR 0: assigned [mem 0x1f800000-0x1f8fffff] (1MB 1024KB)
[    4.565922] pci 0000:00:00.0: ######BAR 0: update new 0x1f800000 current 0xffff8000)
[    4.565931] pci 0000:00:00.0: BAR 6: assigned [mem 0x1f900000-0x1f90ffff pref] (0MB 64KB)
[    4.565945] pci 0000:01:00.0: BAR 0: assigned [mem 0x18000000-0x1bffffff] (64MB 65536KB)
[    4.565953] pci 0000:01:00.0: ######BAR 0: update new 0x18000000 current 0xffff8000)
[    4.565964] pci 0000:01:00.0: BAR 0: error updating (0x18000000 != 0x10000000)
[    4.565972] pci 0000:01:00.0: BAR 6: assigned [mem 0x1e000000-0x1effffff pref] (16MB 16384KB)
[    4.565982] pci 0000:01:00.0: BAR 2: assigned [mem 0x1f000000-0x1f7fffff 64bit pref] (8MB 8192KB)
[    4.565991] pci 0000:01:00.0: ######BAR 2: update new 0x1f00000c current 0xffff8000)
[    4.566015] pci 0000:01:00.0: BAR 1: assigned [mem 0x1c000000-0x1c01ffff] (0MB 128KB)
[    4.566023] pci 0000:01:00.0: ######BAR 1: update new 0x1c000000 current 0xffff8000)
[    4.566036] pci 0000:00:00.0: PCI bridge to [bus 01-ff]
[    4.566043] pci 0000:00:00.0:   bridge window [mem 0x18000000-0x1dffffff]
[    4.566050] pci 0000:00:00.0:   bridge window [mem 0x1e000000-0x1f7fffff pref]
[    4.567536] pcieport 0000:00:00.0: PME: Signaling with IRQ 223
[    4.800061] EXT4-fs (mmcblk1p2): recovery complete
[    4.800889] EXT4-fs (mmcblk1p2): mounted filesystem 19d689c2-bf62-47bf-b6b2-1683622e1f24 r/w with ordered data mode. Quota mode: none.
[    4.800950] VFS: Mounted root (ext4 filesystem) on device 179:98.
[    4.801869] devtmpfs: mounted
[    4.802396] Freeing unused kernel memory: 1984K
[    4.802467] Run /sbin/init as init process
[    5.107934] systemd[1]: System time advanced to timestamp on /var/lib/systemd/timesync/clock: Thu 2026-02-19 01:45:44 UTC
[    5.229312] systemd[1]: systemd 257.9-1~deb13u1 running in system mode (+PAM +AUDIT +SELINUX +APPARMOR +IMA +IPE +SMACK +SECCOMP +GCRYPT -GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN +IPTC +KMOD +LIBCRYPTSETUP +LIBCRYPTSETUP_PLUGINS +LIBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +BTF -XKBCOMMON -UTMP +SYSVINIT +LIBARCHIVE)
[    5.229342] systemd[1]: Detected architecture arm64.

Welcome to Debian GNU/Linux 13 (trixie)!

[    5.302165] systemd[1]: Hostname set to <rfnm>.
[    5.377132] systemd[1]: memfd_create() called without MFD_EXEC or MFD_NOEXEC_SEAL set
[    5.578928] systemd[1]: bpf-restrict-fs: BPF LSM hook not enabled in the kernel, BPF LSM not supported.
[    6.101285] systemd[1]: Queued start job for default target graphical.target.
[  OK  ] Created slice[    6.151363] systemd[1]: Created slice system-getty.slice - Slice /system/getty.
 system-getty.slice - Slice /system/getty.
[  OK  ] Created slice[    6.175293] systemd[1]: Created slice system-modprobe.slice - Slice /system/modprobe.
 system-modprobe.slice - Slice /system/modprobe.
[  OK  ] Created slice[    6.199885] systemd[1]: Created slice system-serial\x2dgetty.slice - Slice /system/serial-getty.
 system-serial\x2dget…slice - Slice /system/serial-getty.
[  OK  ] Created slice[    6.231093] systemd[1]: Created slice user.slice - User and Session Slice.
 user.slice - User and Session Slice.
[  OK  ] Started     6.254641] systemd[1]: Started systemd-ask-password-wall.path - Forward Password Requests to Wall Directory Watch.
;39msystemd-ask-password-wall.…d Requests to Wall Directory Watch.
         Expecting device dev-ttymxc1.device - /dev[    6.286188] systemd[1]: proc-sys-fs-binfmt_misc.automount - Arbitrary Executable File Formats File System Automount Point was skipped because of an unmet condition check (ConditionPathExists=/proc/sys/fs/binfmt_misc).
/ttymxc1...
[    6.286311] systemd[1]: Expecting device dev-ttymxc1.device - /dev/ttymxc1...
[  OK  ] Reached target nss-user-lookup.targ[    6.334082] systemd[1]: Reached target nss-user-lookup.target - User and Group Name Lookups.
et - User and Group Name Lookups.
[  OK  ] Reached target remote-fs.target -[    6.361719] systemd[1]: Reached target remote-fs.target - Remote File Systems.
 Remote File Systems.
[  OK  ] Reached target slices.target - Sl[    6.389675] systemd[1]: Reached target slices.target - Slice Units.
ice Units.
[  OK  ] Reached target swap.target - Sw[    6.414048] systemd[1]: Reached target swap.target - Swaps.
aps.
[  OK  ] Listening on [    6.454495] systemd[1]: Listening on systemd-coredump.socket - Process Core Dump Socket.
systemd-coredump.socket - Process Core Dump Socket.
[  OK  ] Listening on [    6.487888] systemd[1]: Listening on systemd-creds.socket - Credential Encryption/Decryption.
systemd-creds.socket - Credential Encryption/Decryption.
[  OK  ] Listening on systemd-initctl.socke�[    6.514211] systemd[1]: Listening on systemd-initctl.socket - initctl Compatibility Named Pipe.
��- initctl Compatibility Named Pipe.
[  OK  ] Listening on systemd-journald-dev-�[    6.542116] systemd[1]: Listening on systemd-journald-dev-log.socket - Journal Socket (/dev/log).
��socket - Journal Socket (/dev/log).
[  OK  ] Listening on systemd-journald.socke[    6.570585] systemd[1]: Listening on systemd-journald.socket - Journal Sockets.
t - Journal Sockets.
[  OK  ] Listening on [    6.594361] systemd[1]: Listening on systemd-networkd.socket - Network Service Netlink Socket.
systemd-networkd.socket - Network Service Netlink Socket.
[  OK  ] Listening on [    6.622040] systemd[1]: systemd-pcrextend.socket - TPM PCR Measurements was skipped because of an unmet condition check (ConditionSecurity=measured-uki).
systemd-udevd-control.socket - udev Control Socket.[    6.622135] systemd[1]: systemd-pcrlock.socket - Make TPM PCR Policy was skipped because of an unmet condition check (ConditionSecurity=measured-uki).

[    6.622661] systemd[1]: Listening on systemd-udevd-control.socket - udev Control Socket.
[  OK  ] Listening on systemd-udevd-kernel.s[    6.682274] systemd[1]: Listening on systemd-udevd-kernel.socket - udev Kernel Socket.
ocket - udev Kernel Socket.
         Mounting dev-hu[    6.706753] systemd[1]: Mounting dev-hugepages.mount - Huge Pages File System...
gepages.mount - Huge Pages File System...
         Mounting dev-mq[    6.732764] systemd[1]: Mounting dev-mqueue.mount - POSIX Message Queue File System...
ueue.mount - POSIX Message Queue File System...
         Mounting run-lo[    6.779755] systemd[1]: Mounting run-lock.mount - Legacy Locks Directory /run/lock...
ck.mount - Legacy Locks Directory /run/lock...
         Mounting sys-ke[    6.808560] systemd[1]: Mounting sys-kernel-debug.mount - Kernel Debug File System...
rnel-debug.mount - Kernel Debug File System...
[    6.833632] systemd[1]: sys-kernel-tracing.mount - Kernel Trace File System was skipped because of an unmet condition check (ConditionPathExists=/sys/kernel/tracing).
[    6.840296] systemd[1]: Mounting tmp.mount - Temporary Directory /tmp...
         Mounting tmp.mount - Temporary Directory /tmp...
[    6.870850] systemd[1]: Starting kmod-static-nodes.service - Create List of Static Device Nodes...
         Starting kmod-static-nodes.service…eate List of Static Device Nodes...
         Starting modpro[    6.910732] systemd[1]: Starting modprobe@configfs.service - Load Kernel Module configfs...
be@configfs.service - Load Kernel Module configfs...
         Starting modprobe@drm.service - Load Kerne[    6.937376] systemd[1]: Starting modprobe@drm.service - Load Kernel Module drm...
l Module drm...
         Starting modprobe@efi_pstore.servi… - Lo[    6.969458] systemd[1]: Starting modprobe@efi_pstore.service - Load Kernel Module efi_pstore...
ad Kernel Module efi_pstore...
         Starting modprobe@fuse.service - Load Kern[    7.001930] systemd[1]: Starting modprobe@fuse.service - Load Kernel Module fuse...
el Module fuse...
[    7.030292] systemd[1]: systemd-hibernate-clear.service - Clear Stale Hibernate Storage Info was skipped because of an unmet condition check (ConditionPathExists=/sys/firmware/efi/efivars/HibernateLocation-8cf2644b-4b0b-428f-9387-6d876050dc67).
[    7.037479] systemd[1]: Starting systemd-journald.service - Journal Service...
[    7.063082] fuse: init (API version 7.39)
         Starting systemd-journald.service - Journal Service...
[    7.088568] systemd[1]: Starting systemd-modules-load.service - Load Kernel Modules...
         Starting systemd-modules-load.service - Load Kernel Modules...
         Starting system[    7.153008] systemd[1]: Starting systemd-network-generator.service - Generate network units from Kernel command line...
d-network-generator…k units from Kernel command line...
         Starting system[    7.181763] systemd[1]: systemd-pcrmachine.service - TPM PCR Machine ID Measurement was skipped because of an unmet condition check (ConditionSecurity=measured-uki).
d-remount-fs.servic…unt Root and Kernel File Systems...
[    7.185068] systemd[1]: Starting systemd-remount-fs.service - Remount Root and Kernel File Systems...
[    7.233861] systemd[1]: systemd-tpm2-setup-early.service - Early TPM SRK Setup was skipped because of an unmet condition check (ConditionSecurity=measured-uki).
         Starting system[    7.262519] systemd[1]: Starting systemd-udev-load-credentials.service - Load udev Rules from Credentials...
d-udev-load-credent…Load udev Rules from Credentials...
         Starting systemd-udev-trigger.service - Co[    7.293552] systemd[1]: Starting systemd-udev-trigger.service - Coldplug All udev Devices...
ldplug All udev Devices...
[    7.318217] systemd-journald[190]: Collecting audit messages is disabled.
[  OK  ] Mounted     7.360242] systemd[1]: Mounted dev-hugepages.mount - Huge Pages File System.
;39mdev-hugepages.mount - Huge Pages File System.
[  OK  ] Mounted     7.388726] systemd[1]: Mounted dev-mqueue.mount - POSIX Message Queue File System.
;39mdev-mqueue.mount - POSIX Message Queue File System.
[  OK  ] Mounted run-lock.mount - Legacy[    7.414063] systemd[1]: Mounted run-lock.mount - Legacy Locks Directory /run/lock.
 Locks Directory /run/lock.
[  OK  ] Mounted sys-kernel-debug.mount [    7.437966] systemd[1]: Mounted sys-kernel-debug.mount - Kernel Debug File System.
- Kernel Debug File System.
[  OK  ] Started systemd-journald.service    7.462527] systemd[1]: Started systemd-journald.service - Journal Service.
m - Journal Service.
[  OK  ] Mounted tmp.mount - Temporary Directory /tmp.
[  OK  ] Finished kmod-static-nodes.service…Create List of Static Device Nodes.
[  OK  ] Finished modprobe@configfs.service - Load Kernel Module configfs.
[  OK  ] Finished modprobe@drm.service - Load Kernel Module drm.
[  OK  ] Finished modprobe@efi_pstore.service - Load Kernel Module efi_pstore.
[  OK  ] Finished modprobe@fuse.service - Load Kernel Module fuse.
[  OK  ] Finished systemd-modules-load.service - Load Kernel Modules.
[  OK  ] Finished systemd-network-generator…ork units from Kernel command line.
[  OK  ] Finished systemd-remount-fs.servic…mount Root and Kernel File Systems.
[  OK  ] Finished systemd-udev-load-credent…- Load udev Rules from Credentials.
[  OK  ] Reached target network-pre.target - Preparation for Network.
         Mounting sys-fs-fuse-connections.mount - FUSE Control File System...
         Mounting sys-kernel-config.mount - Kernel Configuration File System...
         Starting systemd-journal-flush.ser…sh Journal to Persistent Storage...
         Starting systemd-random-seed.service - Load/Save OS Random Seed...
         Starting systemd-sysctl.service - Apply Kernel Variables...
[    7.938663] systemd-journald[190]: Received client request to flush runtime journal.
[    7.942803] systemd-journald[190]: File /var/log/journal/f3a47a0bb14f4ea9a00de9a2ce6c8cc4/system.journal corrupted or uncleanly shut down, renaming and replacing.
         Starting systemd-tmpfiles-setup-de… Device Nodes in /dev gracefully...
[  OK  ] Mounted sys-fs-fuse-connections.mount - FUSE Control File System.
[  OK  ] Mounted sys-kernel-config.mount - Kernel Configuration File System.
[  OK  ] Finished systemd-journal-flush.ser…lush Journal to Persistent Storage.
[  OK  ] Finished systemd-random-seed.service - Load/Save OS Random Seed.
[  OK  ] Finished systemd-sysctl.service - Apply Kernel Variables.
[  OK  ] Finished systemd-tmpfiles-setup-de…ic Device Nodes in /dev gracefully.
         Starting systemd-resolved.service - Network Name Resolution...
         Starting systemd-timesyncd.service - Network Time Synchronization...
         Starting systemd-tmpfiles-setup-de…eate Static Device Nodes in /dev...
[  OK  ] Finished systemd-udev-trigger.service - Coldplug All udev Devices.
         Starting ifupdown-pre.service - He…synchronize boot up for ifupdown...
[  OK  ] Finished systemd-tmpfiles-setup-de…Create Static Device Nodes in /dev.
[  OK  ] Finished ifupdown-pre.service - He…o synchronize boot up for ifupdown.
[  OK  ] Reached target local-fs-pre.target…Preparation for Local File Systems.
[  OK  ] Reached target local-fs.target - Local File Systems.
[  OK  ] Listening on systemd-sysext.socket… System Extension Image Management.
         Starting networking.service - Raise network interfaces...
         Starting plymouth-read-write.servi…ymouth To Write Out Runtime Data...
         Starting systemd-tmpfiles-setup.se…ate System Files and Directories...
         Starting systemd-udevd.service - R…ager for Device Events and Files...
[  OK  ] Started systemd-timesyncd.service - Network Time Synchronization.
[  OK  ] Finished plymouth-read-write.servi…Plymouth To Write Out Runtime Data.
[  OK  ] Reached target time-set.target - System Time Set.
[  OK  ] Finished systemd-tmpfiles-setup.se…reate System Files and Directories.
[  OK  ] Started systemd-resolved.service - Network Name Resolution.
[  OK  ] Finished networking.service - Raise network interfaces.
[  OK  ] Reached target nss-lookup.target - Host and Network Name Lookups.
[  OK  ] Started systemd-udevd.service - Ru…anager for Device Events and Files.
[  OK  ] Reached target sysinit.target - System Initialization.
[  OK  ] Started cups.path - CUPS Scheduler.
[  OK  ] Started anacron.timer - Trigger anacron every hour.
[  OK  ] Started apt-daily.timer - Daily apt download activities.
[  OK  ] Started apt-daily-upgrade.timer - …y apt upgrade and clean activities.
[  OK  ] Started dpkg-db-backup.timer - Daily dpkg database backup timer.
[  OK  ] Started e2scrub_all.timer - Period…Metadata Check for All Filesystems.
[  OK  ] Started fstrim.timer - Discard unused filesystem blocks once a week.
[  OK  ] Started fwupd-refresh.timer - Refresh fwupd metadata regularly.
[  OK  ] Started logrotate.timer - Daily rotation of log files.
[  OK  ] Started man-db.timer - Daily man-db regeneration.
[  OK  ] Started systemd-tmpfiles-clean.tim…y Cleanup of Temporary Directories.
[  OK  ] Reached target timers.target - Timer Units.
[  OK  ] Listening on avahi-daemon.socket -…DNS/DNS-SD Stack Activation Socket.
[    9.360101] imx-dwmac 30bf0000.ethernet end1: renamed from eth0
[  OK  ] Listening on cups.socket - CUPS Scheduler.
[  OK  ] Listening on dbus.socket - D-Bus System Message Bus Socket.
[  OK  ] Listening on sshd-unix-local.socke…temd-ssh-generator, AF_UNIX Local).
[  OK  ] Listening on systemd-hostnamed.socket - Hostname Service Socket.
[  OK  ] Reached target sockets.target - Socket Units.
         Starting plymouth-start.service - Show Plymouth Boot Screen...
         Starting systemd-networkd.service - Network Configuration...
Booting Linux on physical CPU 0x0000000000 [0x410fd034]
[  OK  ] Found device dev-ttymxc1.device - /dev/ttymxc1.
Linux version 6.6.36-rt35 (root@simon) (aarch64-linux-gnu-gcc (Debian 14.2.0-19) 14.2.0, GNU ld (GNU Binutils for Debian) 2.44) #2 SMP PREEMPT_RT Thu Feb 19 01:11:28 UTC 2026
KASLR disabled due to lack of seed
Machine model: RFNM imx8mp
efi: UEFI not found.
Reserved memory: created CMA memory pool at 0x00000000c4000000, size 960 MiB
OF: reserved mem: initialized node linux,cma, compatible id shared-dma-pool
OF: reserved mem: 0x00000000c4000000..0x00000000ffffffff (983040 KiB) map reusable linux,cma
OF: reserved mem: 0x00000000007e0000..0x00000000007fffff (128 KiB) nomap non-reusable m4@7E0000
OF: reserved mem: 0x0000000000800000..0x000000000081ffff (128 KiB) nomap non-reusable m4@800000
OF: reserved mem: 0x0000000000900000..0x000000000096ffff (448 KiB) nomap non-reusable ocram@900000
OF: reserved mem: 0x0000000010000000..0x0000000010ffffff (16384 KiB) nomap non-reusable m4@10000000
OF: reserved mem: 0x0000000055000000..0x0000000055007fff (32 KiB) nomap non-reusable vdev0vring0@55000000
OF: reserved mem: 0x0000000055008000..0x000000005500ffff (32 KiB) nomap non-reusable vdev0vring1@55008000
OF: reserved mem: 0x00000000550ff000..0x00000000550fffff (4 KiB) nomap non-reusable rsc_table@550ff000
Reserved memory: created DMA memory pool at 0x0000000055400000, size 1 MiB
OF: reserved mem: initialized node vdevbuffer@55400000, compatible id shared-dma-pool
OF: reserved mem: 0x0000000055400000..0x00000000554fffff (1024 KiB) nomap non-reusable vdevbuffer@55400000
OF: reserved mem: 0x0000000080000000..0x0000000080ffffff (16384 KiB) nomap non-reusable m4@80000000
OF: reserved mem: 0x0000000082400000..0x00000000923fffff (262144 KiB) nomap non-reusable iqlocale@82400000
OF: reserved mem: 0x0000000092400000..0x00000000963fffff (65536 KiB) nomap non-reusable la93@92400000
OF: reserved mem: 0x0000000096400000..0x000000009d3fffff (114688 KiB) nomap non-reusable iqflood@96400000
Reserved memory: created CMA memory pool at 0x000000009d400000, size 96 MiB
OF: reserved mem: initialized node iqusb@9D400000, compatible id shared-dma-pool
OF: reserved mem: 0x000000009d400000..0x00000000a33fffff (98304 KiB) map reusable iqusb@9D400000
OF: reserved mem: 0x00000000a3400000..0x00000000a37fffff (4096 KiB) nomap non-reusable bootconfig@A3400000
OF: reserved mem: 0x0000000100000000..0x000000010fffffff (262144 KiB) nomap non-reusable gpu_reserved@100000000
earlycon: ec_imx6q0 at MMIO 0x0000000030890000 (options '')
printk: legacy bootconsole [ec_imx6q0] enabled
NUMA: No NUMA configuration found
NUMA: Faking a node at [mem 0x0000000040000000-0x000000013fffffff]
NUMA: NODE_DATA [mem 0x13f9105c0-0x13f912fff]
Zone ranges:
  DMA      [mem 0x0000000040000000-0x00000000ffffffff]
  DMA32    empty
  Normal   [mem 0x0000000100000000-0x000000013fffffff]
Movable zone start for each node
Early memory node ranges
  node   0: [mem 0x0000000040000000-0x0000000054ffffff]
  node   0: [mem 0x0000000055000000-0x000000005500ffff]
  node   0: [mem 0x0000000055010000-0x00000000550fefff]
  node   0: [mem 0x00000000550ff000-0x00000000550fffff]
  node   0: [mem 0x0000000055100000-0x00000000553fffff]
  node   0: [mem 0x0000000055400000-0x00000000554fffff]
  node   0: [mem 0x0000000055500000-0x000000007fffffff]
  node   0: [mem 0x0000000080000000-0x0000000080ffffff]
  node   0: [mem 0x0000000081000000-0x00000000823fffff]
  node   0: [mem 0x0000000082400000-0x000000009d3fffff]
  node   0: [mem 0x000000009d400000-0x00000000a33fffff]
[  OK  ] Started plymouth-start.service - Show Plymouth Boot Screen.
  node   0: [mem 0x00000000a3400000-0x00000000a37fffff]
  node   0: [mem 0x00000000a3800000-0x00000000ffffffff]
  node   0: [mem 0x0000000100000000-0x000000010fffffff]
  node   0: [mem 0x0000000110000000-0x000000013fffffff]
Initmem setup node 0 [mem 0x0000000040000000-0x000000013fffffff]
psci: probing for conduit method from DT.
psci: PSCIv1.1 detected in firmware.
psci: Using standard PSCI v0.2 function IDs
psci: MIGRATE_INFO_TYPE not supported.
psci: SMC Calling Convention v1.5
percpu: Embedded 21 pages/cpu s46272 r8192 d31552 u86016
pcpu-alloc: s46272 r8192 d31552 u86016 alloc=21*4096
pcpu-alloc: [0] 0 [0] 1 [0] 2 [0] 3 
Detected VIPT I-cache on CPU0
CPU features: detected: GIC system register CPU interface
CPU features: detected: ARM erratum 845719
alternatives: applying boot alternatives
Kernel command line: console=tty0 console=ttymxc1,115200 earlycon root=/dev/mmcblk1p2 rootwait rw
Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes, linear)
Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[   10.321002] cfg80211: failed to load regulatory.db

Built 1 zonelists, mobility grouping on.  Total pages: 1032192
Policy zone: Normal
mem auto-init: stack:off, heap alloc:off, heap free:off
software IO TLB: area num 4.
software IO TLB: mapped [mem 0x00000000c0000000-0x00000000c4000000] (64MB)
Memory: 2207348K/4194304K available (20736K kernel code, 2110K rwdata, 8376K rodata, 1984K init, 663K bss, 905612K reserved, 1081344K cma-reserved)
SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
rcu: Preemptible hierarchical RCU implementation.
rcu:    RCU event tracing is enabled.
rcu:    RCU restricting CPUs from NR_CPUS=256 to nr_cpu_ids=4.
rcu:    RCU priority boosting: priority 1 delay 500 ms.
rcu:    RCU_SOFTIRQ processing moved to rcuc kthreads.
        No expedited grace period (rcu_normal_after_boot).
        Trampoline variant of Tasks RCU enabled.
        Tracing variant of Tasks RCU enabled.
rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
GICv3: [   10.438899] caam-snvs 30370000.caam-snvs: ipid matched - 0x3e
GIC: Using split EOI/Deactivate mode
GICv3: 160 S[   10.444250] caam-snvs 30370000.caam-snvs: violation handlers armed - non-secure state
PIs implemented
GICv3: 0 Extended SPIs implemented
Root IRQ handler: gic_handle_irq
GICv3: GICv3 features: 16 PPIs
GICv3: CPU0: found redistributor 0 region 0:0x0000000038880000
ITS: No ITS available, not enabling LPIs
rcu: srcu_init: Setting srcu_struct sizes based on contention.   10.492225] caam 30900000.crypto: device ID = 0x0a16040100000100 (Era 9)
m
arch_timer: cp15 timer(s) running at 8.00MHz (phys)[   10.492240] caam 30900000.crypto: job rings = 2, qi = 0
.
clocksource: arch_sys_counter: mask: 0xffffffffffffff max_cycles: 0x1d854df40, max_idle_ns: 440795202120 ns
sched_clock: 56 bits at 8MHz, resolution 125ns, wraps every 2199023255500ns
Console: colour dummy device 80x25
printk: legacy console [tty0] enabled
Calibrating delay loop (skipped), value calculated using timer frequency.. 16.00 BogoMIPS (lpj=32000)
pid_max: default: 32768 minimum: 301
LSM: initializing lsm=capability,integrity
Mount-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
Mountpoint-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
RCU Tasks: Setting shift to 2 and lim to 1 rcu_task_cb_adjust=1.
RCU Tasks Trace: Setting shift to 2 and lim to 1 rcu_task_cb_adjust=1.
rcu: Hierarchical SRCU implementation.
rcu:    Max phase no-delay instances is 1000.
EFI services will not be available.
smp: Bringing up secondary CPUs ...
Detected VIPT I-cache on CPU1
GICv3: CPU1: found redistributor 1 region 0:0x00000000388a0000
CPU1: Booted secondary processor 0x0000000001 [0x410fd034]
Detected VIPT I-cache on CPU2
GICv3: CPU2: found redistributor 2 region 0:0x00000000388c0000
CPU2: Booted secondary processor 0x0000000002 [0x410fd034]
Detected VIPT I-cache on CPU3
GICv3: CPU3: found redistributor 3 region 0:0x00000000388e0000
CPU3: Booted secondary processor 0x0000000003 [0x410fd034]
smp: Brought up 1 node, 4 CPUs
SMP: Total of 4 processors activated.
CPU features: detected: 32-bit EL0 Support
CPU features: detected: CRC32 instructions
CPU: All CPU(s) started at EL2
alternatives: applying system-wide alternatives
devtmpfs: initialized
clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
futex hash table entries: 1024 (order: 4, 65536 bytes, linear)
pinctrl core: initialized pinctrl subsystem
DMI not present or invalid.
NET: Registered PF_NETLINK/PF_ROUTE protocol family
DMA: preallocated 512 KiB GFP_KERNEL pool for atomic allocations
DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA pool for atomic allocations
DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
audit: initializing netlink subsys (disabled)
audit: type=2000 audit(0.836:1): state=initialized audit_enabled=0 res=1
thermal_sys: Registered thermal governor 'step_wise'
[  OK  ] Started systemd-ask-password-plymo…quests to Plymouth Directory Watch.
[  OK  ] Reached target paths.target - Path Units.
[  OK  ] Reached target basic.target - Basic System.
thermal_sys: Registered thermal governor 'power_allocator'
cpuidle: using governor menu
hw-breakpoint: found 6 breakpoint and 4 watchpoint registers.
         Starting accounts-daemon.service - Accounts Service...
[  OK  ] Started anacron.service - Run anacron jobs.
         Starting avahi-daemon.service - Avahi mDNS/DNS-SD Stack...
[  OK  ] Started cron.service - Regular background program processing daemon.
         Starting dbus.service - D-Bus System Message Bus...
         Starting e2scrub_reap.service - Re…ne ext4 Metadata Check Snapshots...
         Starting polkit.service - Authorization Manager...
         Starting smartmontools.service - S…orting Technology (SMART) Daemon...
         Starting systemd-logind.service - User Login Management...
         Starting udisks2.service - Disk Manager...
[  OK  ] Started systemd-networkd.service - Network Configuration.
         Starting systemd-networkd-persiste…tent Storage in systemd-networkd...
         Starting systemd-networkd-wait-onl…ait for Network to be Configured...
[  OK  ] Finished systemd-networkd-persiste…istent Storage in systemd-networkd.
ASID allocator initialised with 65536 entries
[  OK  ] Started dbus.service - D-Bus System Message Bus.
Serial: AMBA PL011 UART driver
imx mu driver is registered.
imx rpmsg driver is registered.
platform soc@0: Fixed dependency cycle(s) with /soc@0/bus@30000000/efuse@30350000/unique-id@8
platform 30330000.pin[   10.942836] imx-sdma 30e10000.dma-controller: firmware found.
ctrl: Fixed dependency cycle(s) with /soc@0/bus@30000000/pinctrl[   10.942881] imx-sdma 30bd0000.dma-controller: firmware found.
@30330000/imx8mp-custom-board/eqosgrp
imx8mp-pinc[   10.943053] imx-sdma 30bd0000.dma-controller: loaded firmware 4.6
trl 30330000.pinctrl: initialized IMX pinctrl driver
         Starting NetworkManager.service - Network Manager...
platform 30350000.efuse: Fixed dependency cycle(s) with /soc@0/bus@30000000/clock-controller@30380000
platform 30350000.efuse: Fixed dependency cycle(s) with /soc@0/bus@30000000/clock-controller@30380000
platform 32fc6000.lcd-controller: Fixed dependency cycle(s) with /soc@0/bus@30c00000/hdmi@32fd8000
platform 32fc6000.lcd-controller: Fixed dependency cycle(s) with /soc@0/bus@30c00000/hdmi@32fd8000
         Starting wpa_supplicant.service - WPA supplicant...
platform 32fd8000.hdmi: Fixed dependency cycle(s) with /soc@0/bus@30c00000/lcd-controller@32fc6000
platform fusb340-sw: Fixed dependency cycle(s) with /soc@0/bus@30800000/i2c@30a20000/tcpc@22/connector
Modules: 24256 pages in range for non-PLT usage
[FAILED] Failed to start smartmontools.serv…eporting Technology (SMART) Daemon.
See 'systemctl status smartmontools.service' for details.
[  OK  ] Started avahi-daemon.service - Avahi mDNS/DNS-SD Stack.
Modules: 515776 pages in range for PLT usage
HugeTLB: registered 1.00 GiB page size, pre-allocated 0 pages
HugeTLB: 0 KiB vmemmap can be freed for a 1.00 GiB page
HugeTLB: registered 32.0 MiB page size, pre-allocated 0 pages
HugeTLB: 0 KiB vmemmap can be freed for a 32.0 MiB page
HugeTLB: registered 2.00 MiB page size, pre-allocated 0 pages
HugeTLB: 0 KiB vmemmap can be freed for a 2.00 MiB page
HugeTLB: registered 64.0 KiB page size, pre-allocated 0 pages
HugeTL[   11.130281] imx-hdmi sound-hdmi: failed to find SAI platform device
B: 0 KiB vmemmap can be freed for a 64.0 KiB page
   11.130298] imx-hdmi: probe of sound-hdmi failed with error -22
mACPI: Interpreter disabled.
iommu: Default domain type: Translated
iommu: DMA domain TLB invalidation policy: strict mode
SCSI subsystem initialized
libata version 3.00 loaded.
usbcore: registered new interface driver usbfs
usbcore: registered new interface driver hub
usbcore: registered new device driver usb
mc: Linux media interface: v0.10
videodev: Linux video capture interface: v2.00
pps_core: LinuxPPS API ver. 1 registered
pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
PTP clock support registered
EDAC MC: Ver: 3.0.0
scmi_core: SCMI protocol bus registered
FPGA manager framework
Advanced Linux Sound Architecture Driver Initialized.
Bluetooth: Core ver 2.22
NET: Registered PF_BLUETOOTH protocol family
Bluetooth: HCI device and connection manager initialized
Bluetooth: HCI socket layer initialized
Bluetooth: L2CAP socket layer initialized
Bluetooth: SCO socket layer initialized
vgaarb: loaded
clocksource: Switched to clocksource arch_sys_counter
VFS: Disk quotas dquot_6.6.0
[  OK  ] Started wpa_supplicant.service - WPA supplicant.
VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
pnp: PnP ACPI: disabled
NET: Registered PF_INET protocol family
[  OK  ] Started systemd-logind.service - User Login Management.
IP idents hash table entries: 65536 (order: 7, 524288 bytes, linear)
[  OK  ] Reached target usb-gadget.target - Hardware activated USB gadget.
tcp_listen_portaddr_hash hash table entries: 2048 (order: 4, 81920 bytes, linear)
Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
TCP established hash table entries: 32768 (order: 6, 262144 bytes, linear)
TCP bind hash table entries: 32768 (order: 9, 2621440 bytes, linear)
TCP: Hash tables configured (established 32768 bind 32768)
UDP hash table entries: 2048 (order: 5, 196608 bytes, linear)
UDP-Lite hash table entries: 2048 (order: 5, 196608 bytes, linear)
NET: Registered PF_UNIX/PF_LOCAL protocol family
RPC: Registered named UNIX socket transport module.
RPC: Registered udp transport module.
RPC: Registered tcp transport module.
RPC: Registered tcp-with-tls transport module.
RPC: Registered tcp NFSv4.1 backchannel transport module.
NET: Registered PF_XDP protocol family
PCI: CLS 0 bytes, default 64
Initialise system trusted keyrings
workingset: timestamp_bits=42 max_order=20 bucket_order=0
squashfs: version 4.0 (2009/01/31) Phillip Lougher
NFS: Registering the id_resolver key type
Key type id_resolver registered
Key type id_legacy registered
nfs4filelayout_init: NFSv4 File Layout Driver Registering...
nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
9p: Installing v9fs 9p2000 file system support
jitterentropy: Initialization failed with host not compliant with requirements: 9
Key type asymmetric registered
Asymmetric key parser 'x509' registered
Block layer SCSI generic (bsg) driver version 0.4 loaded (major 243)
io scheduler mq-deadline registered
io scheduler kyber registered
io scheduler bfq registered
EINJ: ACPI disabled.
imx-sdma 30bd0000.dma-controller: Direct firmware load for imx/sdma/sdma-imx7d.bin failed with error -2
imx-sdma 30bd0000.dma-controller: Falling back to sysfs fallback for: imx/sdma/sdma-imx7d.bin
mxs-dma 33000000.dma-apbh: initialized
SoC: i.MX8MP revision 1.1
Bus freq driver module loaded
Serial: 8250/16550 driver, 4 ports, IRQ sharing enabled
30890000.serial: ttymxc1 at MMIO 0x30890000 (irq = 24, base_baud = 1500000) is a IMX
printk: legacy console [ttymxc1] enabled
printk: legacy bootconsole [ec_imx6q0] disabled
etnaviv etnaviv: bound 38000000.gpu3d (ops gpu_ops)
etnaviv etnaviv: bound 38008000.gpu2d (ops gpu_ops)
etnaviv-gpu 38000000.gpu3d: model: GC7000, revision: 6204
etnaviv-gpu 38008000.gpu2d: model: GC520, revision: 5341
[drm] Initialized etnaviv 1.4.0 20151214 [   11.589757] caam algorithms registered in /proc/crypto
for etnaviv on minor 0
   11.589896] caam 30900000.crypto: caam pkc algorithms registered in /proc/crypto
1;39mloop: module loaded
   11.589928] caam 30900000.crypto: rng crypto API alg registered prng-caam
;21;31mof_reserved_mem_lookup() r[   11.589937] caam 30900000.crypto: registering rng-caam
eturned NULL
megas[   11.591900] Device caam-keygen registered
as: 07.725.01.00-rc1
   11.609540] imx-dwmac 30bf0000.ethernet end1: Register MEM_TYPE_PAGE_POOL RxQ-0
39mtun: Universal TUN/TAP device driver, 1.6
thunder_xcv, ver 1.0
thunder_bgx, ver 1.0
nicpf, ver 1.0
hns3: Hisilicon Ethernet Network Driver for Hip08 Family - version
hns3: Copyright (c) 2017 Huawei Corporation.
hclge is initializing
e1000: Intel(R) PRO/1000 Network Driver
e1000: Copyright (c) 1999-2006 Intel Corporation.
e1000e: Intel(R) PRO/1000 Network Driver
e1000e: Copyright(c) 1999 - 2015 Intel Corporation.
igb: Intel(R) Gigabit Ethernet Network Driver
igb: Copyright (c) 2007-2014 Intel Corporation.
igbvf: Intel(R) Gigabit Virtual Function Network Driver
igbvf: Copyright (c) 2009 - 2012 Intel Corporation.
sky2: driver version 1.30
usbcore: registered new device driver r8152-cfgselector
usbcore: registered new interface driver r8152
VFIO - User Level meta-driver version: 0.3
platform 38100000.usb: Fixed dependency cycle(s) with /soc@0/bus@30800000/i2c@30a20000/tcpc@22
usbcore: registered new interface driver uas
usbcore: registered new interface driver usb-storage
usbcore: registered new interface driver usbserial_generic
usbserial: USB Serial support registered for generic
usbcore: registered new interface driver ftdi_sio
usbserial: USB Serial support registered for FTDI USB Serial Device
usbcore: registered new interface driver usb_serial_simple
usbserial: USB Serial support registered for carelink
[  OK  ] Finished e2scrub_reap.service - Re…line ext4 Metadata Check Snapshots.
         Start[   11.801242] imx-dwmac 30bf0000.ethernet end1: PHY [stmmac-1:01] driver [RTL8211F Gigabit Ethernet] (irq=POLL)
ing systemd-hostnamed.se[   11.809864] imx-dwmac 30bf0000.ethernet end1: No Safety Features support found
rvice - Hostname Service...
[  OK  ] Started  imx-dwmac 30bf0000.ethernet end1: IEEE 1588-2008 Advanced Timestamp supported
[0;1;39mpolkit.service - Authorization Manager.
         [   11.810213] imx-dwmac 30bf0000.ethernet end1: registered PTP clock
Starting ModemManager.se[   11.837523] imx-dwmac 30bf0000.ethernet end1: FPE workqueue start
rvice - Modem Manager...
[[   11.837538] imx-dwmac 30bf0000.ethernet end1: configuring for phy/rgmii-id link mode
  OK  ] Started    11.866274] 8021q: adding VLAN 0 to HW filter on device end1
39maccounts-daemon.service - Accounts Service.
usbserial: USB Serial support registered for flashloader
usbserial: USB Serial support registered for funsoft
usbserial: USB Serial support registered for google
usbserial: USB Serial support registered for hp4x
[  OK  ] Started udisks2.service - Disk Manager.
usbserial: USB Serial support registered for kaufmann
usbserial: USB Serial support registered for libtransistor
usbserial: USB Serial support registered for moto_modem
usbserial: USB Serial support registered for motorola_tetra
usbserial: USB Serial support registered for nokia
usbserial: USB Serial support registered for novatel_gps
usbserial: USB Serial support registered for siemens_mpi
usbserial: USB Serial support registered for suunto
usbserial: USB Serial support registered for vivopay
usbserial: USB Serial support registered for zio
usbcore: registered new interface driver usb_ehset_test
gadgetfs: USB Gadget filesystem, version 24 Aug 2004
input: 30370000.snvs:snvs-powerkey as /devices/platform/soc@0/30000000.bus/30370000.snvs/30370000.snvs:snvs-powerkey/input/input0
snvs_rtc 30370000.snvs:snvs-rtc-lp: registered as rtc0
snvs_rtc 30370000.snvs:snvs-rtc-lp: setting system clock to 1970-01-01T00:00:00 UTC (0)
i2c_dev: i2c /dev entries driver
Bluetooth: HCI UART driver ver 2.3
Bluetooth: HCI UART protocol H4 registered
Bluetooth: HCI UART protocol BCSP registered
Bluetooth: HCI UART protocol LL registered
Bluetooth: HCI UART protocol ATH3K registered
Bluetooth: HCI UART protocol Three-wire (H5) registered
Bluetooth: HCI UART protocol Broadcom registered
Bluetooth: HCI UART protocol QCA registered
EDAC MC: ECC not enabled
sdhci: Secure Digital Host Controller Interface driver
sdhci: Copyright(c) Pierre Ossman
Synopsys Designware Multimedia Card Interface Driver
sdhci-pltfm: SDHCI platform and OF driver helper
SMCCC: SOC_ID: ARCH_SOC_ID not implemented, skipping ....
usbcore: registered new interface driver usbhid
usbhid: USB HID core driver
hw perfevents: enabled with armv8_cortex_a53 PMU driver, 7 counters available
 cs_system_cfg: CoreSight Configuration manager initialised
platform soc@0: Fixed dependency cycle(s) with /soc@0/bus@30000000/efuse@30350000
optee: probing for conduit method.
   12.127480] NET: Registered PF_QIPCRTR protocol family
21;33moptee: api uid mismatch
optee: probe of firmware:optee failed with error -22
pktgen: Packet Generator for packet performance testing. Version: 2.75
NET: Registered PF_LLC protocol family
Mirror/redirect action on
u32 classifier
    input device check on
    Actions configured
NET: Registered PF_INET6 protocol family
Segment Routing with IPv6
In-situ OAM (IOAM) with IPv6
NET: Registered PF_PACKET protocol family
bridge: filtering via arp/ip/ip6tables is no longer available by default. Update your scripts to load br_netfilter if you need this.
Bluetooth: RFCOMM TTY layer initialized
Bluetooth: RFCOMM socket layer initialized
Bluetooth: RFCOMM ver 1.11
Bluetooth: BNEP (Ethernet Emulation) ver 1.3
Bluetooth: BNEP filters: protocol multicast
Bluetooth: BNEP socket layer initialized
Bluetooth: HIDP (Human Interface Emulation) ver 1.2
Bluetooth: HIDP socket layer initialized
8021q: 802.1Q VLAN Support v1.8
lib80211: common routines for IEEE802.11 drivers
lib80211_crypt: registered algorithm 'NULL'
lib80211_crypt: registered algorithm 'WEP'
lib80211_crypt: registered algorithm 'CCMP'
lib80211_crypt: registered algorithm 'TKIP'
9pnet: Installing 9P2000 support
Key type dns_resolver registered
NET: Registered PF_VSOCK protocol family
mmc2: SDHCI controller on 30b60000.mmc [30b60000.mmc] using ADMA
registered taskstats version 1
Loading compiled-in X.509 certificates
gpio gpiochip0: Static allocation of GPIO base is deprecated, use dynamic allocation.
gpio gpiochip1: Static allocation of GPIO base is deprecated, use dynamic allocation.
gpio gpiochip2: Static allocation of GPIO base is deprecated, use dynamic allocation.
gpio gpiochip3: Static allocation of GPIO base is deprecated, use dynamic allocation.
gpio gpiochip4: Static allocation of GPIO base is deprecated, use dynamic allocation.
platform 38100000.usb: Fixed dependency cycle(s) with /soc@0/bus@30800000/i2c@30a20000/tcpc@22
i2c 0-0022: Fixed dependency cycle(s) with /soc@0/usb@32f10100/usb@38100000
hwmon hwmon0: temp1_input not attached to any thermal zone
tmp102 0-0048: initialized
RFNM: Deferring Si5510 probe...
RFNM: Motherboard id 4 revision 1 serial U3D6CP3J mac-addr 00:04:9f:08:be:8e
mmc2: new HS400 Enhanced strobe MMC card at address 0001
mmcblk2: mmc2:0001 TY2964 58.3 GiB
i2c i2c-0: IMX I2C adapter registered
 mmcblk2: p1 p2 p3
mmcblk2boot0: mmc2:0001 TY2964 4.00 MiB
mmcblk2boot1: mmc2:0001 TY2964 4.00 MiB
mmcblk2rpmb: mmc2:0001 TY2964 4.00 MiB, chardev (234:0)
nxp-pca9450 0-0025: pca9450bc probed.
RFNM: Daughterboard detected on slot 1, board id 3 revision 1 serial 24JC9ANS
hwmon hwmon1: temp1_input not attached to any thermal zone
tmp102 1-0048: initialized
i2c i2c-1: IMX I2C adapter registered
RFNM: Daughterboard detected on slot 2, board id 1 revision 1 serial YTLPXRJM
tmp102 2-0048: error reading config register
i2c i2c-2: IMX I2C adapter registered
imx8mq-usb-phy 382f0040.usb-phy: supply vbus not found, using dummy regulator
RFNM: Deferring PCIe probe...
dwhdmi-imx 32fd8000.hdmi: Detected HDMI TX controller v2.13a with HDCP (samsung_dw_hdmi_phy2)
[  OK  ] Started ModemManager.service - Modem Manager.
dwhdmi-imx 32fd8000.hdmi: registered DesignWare HDMI I2C bus driver
imx-drm display-subsystem: bound imx-lcdifv3-crtc.0 (ops lcdifv3_crtc_ops)
imx-drm display-subsystem: bound 32fd8000.hdmi (ops dw_hdmi_imx_ops)
[drm] Initialized imx-drm 1.0.0 20120507 for display-subsystem on minor 1
[  OK  ] Started systemd-hostnamed.service - Hostname Service.
         Starting NetworkManager-dispatcher…anager Script Dispatcher Service...
[  OK  ] Started NetworkManager.service - Network Manager.
[  OK  ] Reached target network.target - Network.
         Starting NetworkManager-wait-onlin…ce - Network Manager Wait Online...
         Starting cups.service - CUPS Scheduler...
         Starting ssh.service - OpenBSD Secure Shell server...
         Starting systemd-user-sessions.service - Permit User Sessions...
[  OK  ] Started NetworkManager-dispatcher.… Manager Script Dispatcher Service.
[  OK  ] Finished systemd-user-sessions.service - Permit User Sessions.
[  OK  ] Started sddm.service - Simple Desktop Display Manager.
EDID block 2 (tag 0x00) checksum is invalid, remainder is 191
[  OK  ] Started cups.service - CUPS Scheduler.
        [00] GOOD 00 ff ff ff ff ff ff 00 06 b3 fe 27 01 01 01 01
        [00] GOOD 1c 21 01 03 80 3c 22 78 2a f1 80 ad 50 46 a5 24
        [00] GOOD 0c 50 54 bf cf 00 d1 c0 71 4f 81 c0 81 40 81 80
        [00] GOOD 95 00 b3 00 01 01 56 5e 00 a0 a0 a0 29 50 30 20
        [00] GOOD 35 00 55 50 21 00 00 1a 00 00 00 fd 00 30 90 1e
        [00] GOOD e1 49 00 0a 20 20 20 20 20 20 00 00 00 fc 00 58
        [00] GOOD 47 32 37 41 43 53 0a 20 20 20 20 20 00 00 00 ff
        [00] GOOD 00 54 32 4c 4d 54 46 30 35 35 38 32 36 0a 02 46
[  OK  ] Started ssh.service - OpenBSD Secure Shell server.
        [01] GOOD 02 03 50 f1 51 01 03 02 12 11 13 04 1f 90 3f 20
        [01] GOOD 21 22 40 61 60 5c 23 09 17 07 83 01 00 00 e2 00
        [01] GOOD ea 68 03 0c 00 10 00 38 44 08 6d d8 5d c4 01 78
        [01] GOOD 80 03 02 30 90 00 00 00 68 1a 00 00 01 01 30 90
        [01] GOOD f0 e3 05 c0 00 e3 0f 00 c0 e6 06 05 01 66 66 25
        [01] GOOD e7 9c 00 a0 a0 a0 24 50 30 20 68 04 55 50 21 00
        [01] GOOD 00 1a 6f c2 00 a0 a0 a0 55 50 30 20 35 00 55 50
        [01] GOOD 21 00 00 1a 00 00 00 00 00 00 00 00 00 00 00 b3
        [02] BAD  00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f
        [02] BAD  10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
        [02] BAD  20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f
        [02] BAD  30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f
        [02] BAD  40 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f
        [02] BAD  50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f
        [02] BAD  60 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f
        [02] BAD  70 71 72 73 74 75 76 77 78 79 7a 7b 7c 7d 7e 7f
Console: switching to colour frame buffer device 240x67
imx-drm display-subsystem: [drm] fb0: imx-drmdrmfb frame buffer device
Delaying spi clock from CS by 1 clocks
Delaying spi clock from CS by 1 clocks
imx-dwmac 30bf0000.ethernet: IRQ eth_lpi not found
imx-dwmac 30bf0000.ethernet: User ID: 0x10, Synopsys ID: 0x51
imx-dwmac 30bf0000.ethernet:    DWMAC4/5
imx-dwmac 30bf0000.ethernet: DMA HW capability register supported
imx-dwmac 30bf0000.ethernet: RX Checksum Offload Engine supported
imx-dwmac 30bf0000.ethernet: TX Checksum insertion supported
imx-dwmac 30bf0000.ethernet: Wake-Up On Lan supported
imx-dwmac 30bf0000.ethernet: Enable RX Mitigation via HW Watchdog Timer
imx-dwmac 30bf0000.ethernet: Enabled L3L4 Flow TC (entries=8)
imx-dwmac 30bf0000.ethernet: Enabled RFS Flow TC (entries=10)
imx-dwmac 30bf0000.ethernet: Enabling HW TC (entries=256, max_off=256)
imx-dwmac 30bf0000.ethernet: Using 34/40 bits DMA host/device width
xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
xhci-hcd xhci-hcd.1.auto: new USB bus registered, assigned bus number 1
xhci-hcd xhci-hcd.1.auto: hcc params 0x0220fe6d hci version 0x110 quirks 0x000000a001000010
xhci-hcd xhci-hcd.1.auto: irq 218, io mem 0x38200000
xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
xhci-hcd xhci-hcd.1.auto: new USB bus registered, assigned bus number 2
xhci-hcd xhci-hcd.1.auto: Host supports USB 3.0 SuperSpeed
imx-cpufreq-dt imx-cpufreq-dt: cpu speed grade 7 mkt segment 2 supported-hw 0x80 0x4
hub 1-0:1.0: USB hub found
hub 1-0:1.0: 1 port detected
usb usb2: We don't know the algorithms for LPM for this host, disabling LPM.
hub 2-0:1.0: USB hub found
hub 2-0:1.0: 1 port detected
RFNM: WSLED driver
sdhci-esdhc-imx 30b50000.mmc: Got CD GPIO
remoteproc remoteproc0: imx8mp-cm7 is available
RFNM: Starting up Si5510...
mmc1: SDHCI controller on 30b50000.mmc [30b50000.mmc] using ADMA
EDID block 2 (tag 0x00) checksum is invalid, remainder is 191
mmc1: host does not support reading read-only switch, assuming write-enable
mmc1: new ultra high speed SDR104 SDHC card at address aaaa
mmcblk1: mmc1:aaaa SP32G 29.7 GiB
 mmcblk1: p1 p2
random: crng init done
RFNM: DCS clock not set in eeprom, defaulting to 122...
RFNM: DCS clock is 11673.6 MHz / 95
RFNM: Selected plan 2 RFNM_DAUGHTERBOARD_LIME, RFNM_DAUGHTERBOARD_LIME
RFNM: Enabling clock output 15
RFNM: Enabling clocks for RBA
RFNM: Enabling clock output 6
RFNM: Enabling clock output 8
RFNM: Waiting for reference clock to lock...
RFNM: Si5510 is ready and providing a PCIe clock!
RFNM: Performed LA9310 reset
RFNM: PCIe started
imx6q-pcie 33800000.pcie: host bridge /soc@0/pcie@33800000 ranges:
imx6q-pcie 33800000.pcie:       IO 0x001ff80000..0x001ff8ffff -> 0x0000000000
imx6q-pcie 33800000.pcie:      MEM 0x0018000000..0x001fefffff -> 0x0018000000
imx6q-pcie 33800000.pcie: iATU: unroll T, 4 ob, 4 ib, align 64K, limit 16G
cfg80211: Loading compiled-in X.509 certificates for regulatory database
Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
Loaded X.509 cert 'wens: 61c038651aabdcf94bd0ac7ff06c7248db18c600'
clk: Disabling unused clocks
platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
platform regulatory.0: Falling back to sysfs fallback for: regulatory.db
ALSA device list:
  No soundcards found.
imx6q-pcie 33800000.pcie: PCIe Gen.1 x1 link up
imx6q-pcie 33800000.pcie: PCIe Gen.3 x1 link up
imx6q-pcie 33800000.pcie: Link up, Gen3
imx6q-pcie 33800000.pcie: PCIe Gen.3 x1 link up
imx6q-pcie 33800000.pcie: PCI host bridge to bus 0000:00
pci_bus 0000:00: root bus resource [bus 00-ff]
pci_bus 0000:00: root bus resource [io  0x0000-0xffff]
[  OK  ] Created slice user-106.slice - User Slice of UID 106.
pci_bus 0000:00: root bus resource [mem 0x18000000-0x1fefffff]
         Starting user-runtime-dir@106.serv… Runtime Directory /run/user/106...
pci 0000:00:00.0: [16c3:abcd] type 01 class 0x060400
pci 0000:00:00.0: reg 0x10: [mem 0x00000000-0x000fffff]
pci 0000:00:00.0: reg 0x38: [mem 0x00000000-0x0000ffff pref]
pci 0000:00:00.0: supports D1
pci 0000:00:00.0: PME# supported from D0 D1 D3hot D3cold
pci 0000:01:00.0: Setting PCI class for LA9310 PCIe device!
pci 0000:01:00.0: [1957:1c12] type 00 class 0x000280
pci 0000:01:00.0: reg 0x10: forcing BAR0 readback 0xf0000000 to 0xfc000000 (i.e.64MB)
pci 0000:01:00.0: reg 0x10: [mem 0x00000000-0x03ffffff]
pci 0000:01:00.0: reg 0x14: [mem 0x00000000-0x0001ffff]
pci 0000:01:00.0: reg 0x18: [mem 0x00000000-0x007fffff 64bit pref]
pci 0000:01:00.0: reg 0x30: [mem 0x00000000-0x00ffffff pref]
pci 0000:01:00.0: PME# supported from D0 D3hot
pci 0000:00:00.0: BAR 14: assigned [mem 0x18000000-0x1dffffff] (96MB 98304KB)
pci 0000:00:00.0: BAR 15: assigned [mem 0x1e000000-0x1f7fffff pref] (24MB 24576KB)
pci 0000:00:00.0: BAR 0: assigned [mem 0x1f800000-0x1f8fffff] (1MB 1024KB)
pci 0000:00:00.0: ######BAR 0: update new 0x1f800000 current 0xffff8000)
pci 0000:00:00.0: BAR 6: assigned [mem 0x1f900000-0x1f90ffff pref] (0MB 64KB)
pci 0000:01:00.0: BAR 0: assigned [mem 0x18000000-0x1bffffff] (64MB 65536KB)
pci 0000:01:00.0: ######BAR 0: update new 0x18000000 current 0xffff8000)
pci 0000:01:00.0: BAR 0: error updating (0x18000000 != 0x10000000)
pci 0000:01:00.0: BAR 6: assigned [mem 0x1e000000-0x1effffff pref] (16MB 16384KB)
[  OK  ] Finished user-runtime-dir@106.serv…er Runtime Directory /run/user/106.
pci 0000:01:00.0: BAR 2: assigned [mem 0x1f000000-0x1f7fffff 64bit pref] (8MB 8192KB)
         Starting user@106.service - User Manager for UID 106...
pci 0000:01:00.0: ######BAR 2: update new 0x1f00000c current 0xffff8000)
pci 0000:01:00.0: BAR 1: assigned [mem 0x1c000000-0x1c01ffff] (0MB 128KB)
pci 0000:01:00.0: ######BAR 1: update new 0x1c000000 current 0xffff8000)
pci 0000:00:00.0: PCI bridge to [bus 01-ff]
pci 0000:00:00.0:   bridge window [mem 0x18000000-0x1dffffff]
pci 0000:00:00.0:   bridge window [mem 0x1e000000-0x1f7fffff pref]
pcieport 0000:00:00.0: PME: Signaling with IRQ 223
EXT4-fs (mmcblk1p2): recovery complete
EXT4-fs (mmcblk1p2): mounted filesystem 19d689c2-bf62-47bf-b6b2-1683622e1f24 r/w with ordered data mode. Quota mode: none.
VFS: Mounted root (ext4 filesystem) on device 179:98.
devtmpfs: mounted
Freeing unused kernel memory: 1984K
Run /sbin/init as init process
  with arguments:
    /sbin/init
  with environment:
    HOME=/
    TERM=linux
systemd[1]: System time advanced to timestamp on /var/lib/systemd/timesync/clock: Thu 2026-02-19 01:45:44 UTC
systemd[1]: systemd 257.9-1~deb13u1 running in system mode (+PAM +AUDIT +SELINUX +APPARMOR +IMA +IPE +SMACK +SECCOMP +GCRYPT -GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN +IPTC +KMOD +LIBCRYPTSETUP +LIBCRYPTSETUP_PLUGINS +LIBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +BTF -XKBCOMMON -UTMP +SYSVINIT +LIBARCHIVE)
systemd[1]: Detected architecture arm64.
systemd[1]: Hostname set to <rfnm>.
systemd[1]: memfd_create() called without MFD_EXEC or MFD_NOEXEC_SEAL set
systemd[1]: bpf-restrict-fs: BPF LSM hook not enabled in the kernel, BPF LSM not supported.
systemd[1]: Queued start job for default target graphical.target.
systemd[1]: Created slice system-getty.slice - Slice /system/getty.
systemd[1]: Created slice system-modprobe.slice - Slice /system/modprobe.
systemd[1]: Created slice system-serial\x2dgetty.slice - Slice /system/serial-getty.
systemd[1]: Created slice user.slice - User and Session Slice.
systemd[1]: Started systemd-ask-password-wall.path - Forward Password Requests to Wall Directory Watch.
systemd[1]: proc-sys-fs-binfmt_misc.automount - Arbitrary Executable File Formats File System Automount Point was skipped because of an unmet condition check (ConditionPathExists=/proc/sys/fs/binfmt_misc).
systemd[1]: Expecting device dev-ttymxc1.device - /dev/ttymxc1...
systemd[1]: Reached target nss-user-lookup.target - User and Group Name Lookups.
systemd[1]: Reached target remote-fs.target - Remote File Systems.
systemd[1]: Reached target slices.target - Slice Units.
systemd[1]: Reached target swap.target - Swaps.
systemd[1]: Listening on systemd-coredump.socket - Process Core Dump Socket.
systemd[1]: Listening on systemd-creds.socket - Credential Encryption/Decryption.
systemd[1]: Listening on systemd-initctl.socket - initctl Compatibility Named Pipe.
systemd[1]: Listening on systemd-journald-dev-log.socket - Journal Socket (/dev/log).
systemd[1]: Listening on systemd-journald.socket - Journal Sockets.
systemd[1]: Listening on systemd-networkd.socket - Network Service Netlink Socket.
systemd[1]: systemd-pcrextend.socket - TPM PCR Measurements was skipped because of an unmet condition check (ConditionSecurity=measured-uki).
systemd[1]: systemd-pcrlock.socket - Make TPM PCR Policy was skipped because of an unmet condition check (ConditionSecurity=measured-uki).
systemd[1]: Listening on systemd-udevd-control.socket - udev Control Socket.
systemd[1]: Listening on systemd-udevd-kernel.socket - udev Kernel Socket.
systemd[1]: Mounting dev-hugepages.mount - Huge Pages File System...
systemd[1]: Mounting dev-mqueue.mount - POSIX Message Queue File System...
systemd[1]: Mounting run-lock.mount - Legacy Locks Directory /run/lock...
systemd[1]: Mounting sys-kernel-debug.mount - Kernel Debug File System...
systemd[1]: sys-kernel-tracing.mount - Kernel Trace File System was skipped because of an unmet condition check (ConditionPathExists=/sys/kernel/tracing).
systemd[1]: Mounting tmp.mount - Temporary Directory /tmp...
systemd[1]: Starting kmod-static-nodes.service - Create List of Static Device Nodes...
systemd[1]: Starting modprobe@configfs.service - Load Kernel Module configfs...
systemd[1]: Starting modprobe@drm.service - Load Kernel Module drm...
systemd[1]: Starting modprobe@efi_pstore.service - Load Kernel Module efi_pstore...
systemd[1]: Starting modprobe@fuse.service - Load Kernel Module fuse...
systemd[1]: systemd-hibernate-clear.service - Clear Stale Hibernate Storage Info was skipped because of an unmet condition check (ConditionPathExists=/sys/firmware/efi/efivars/HibernateLocation-8cf2644b-4b0b-428f-9387-6d876050dc67).
systemd[1]: Starting systemd-journald.service - Journal Service...
fuse: init (API version 7.39)
systemd[1]: Starting systemd-modules-load.service - Load Kernel Modules...
systemd[1]: Starting systemd-network-generator.service - Generate network units from Kernel command line...
systemd[1]: systemd-pcrmachine.service - TPM PCR Machine ID Measurement was skipped because of an unmet condition check (ConditionSecurity=measured-uki).
systemd[1]: Starting systemd-remount-fs.service - Remount Root and Kernel File Systems...
systemd[1]: systemd-tpm2-setup-early.service - Early TPM SRK Setup was skipped because of an unmet condition check (ConditionSecurity=measured-uki).
systemd[1]: Starting systemd-udev-load-credentials.service - Load udev Rules from Credentials...
systemd[1]: Starting systemd-udev-trigger.service - Coldplug All udev Devices...
systemd-journald[190]: Collecting audit messages is disabled.
systemd[1]: Mounted dev-hugepages.mount - Huge Pages File System.
systemd[1]: Mounted dev-mqueue.mount - POSIX Message Queue File System.
systemd[1]: Mounted run-lock.mount - Legacy Locks Directory /run/lock.
systemd[1]: Mounted sys-kernel-debug.mount - Kernel Debug File System.
systemd[1]: Started systemd-journald.service - Journal Service.
systemd-journald[190]: Received client request to flush runtime journal.
systemd-journald[190]: File /var/log/journal/f3a47a0bb14f4ea9a00de9a2ce6c8cc4/system.journal corrupted or uncleanly shut down, renaming and replacing.
imx-dwmac 30bf0000.ethernet end1: renamed from eth0
cfg80211: failed to load regulatory.db
caam-snvs 30370000.caam-snvs: ipid matched - 0x3e
caam-snvs 30370000.caam-snvs: violation handlers armed - non-secure state
caam 30900000.crypto: device ID = 0x0a16040100000100 (Era 9)
caam 30900000.crypto: job rings = 2, qi = 0
imx-sdma 30e10000.dma-controller: firmware found.
imx-sdma 30bd0000.dma-controller: firmware found.
imx-sdma 30bd0000.dma-controller: loaded firmware 4.6
imx-hdmi sound-hdmi: failed to find SAI platform device
imx-hdmi: probe of sound-hdmi failed with error -22
caam algorithms registered in /proc/crypto
caam 30900000.crypto: caam pkc algorithms registered in /proc/crypto
caam 30900000.crypto: rng crypto API alg registered prng-caam
caam 30900000.crypto: registering rng-caam
Device caam-keygen registered
imx-dwmac 30bf0000.ethernet end1: Register MEM_TYPE_PAGE_POOL RxQ-0
imx-dwmac 30bf0000.ethernet end1: PHY [stmmac-1:01] driver [RTL8211F Gigabit Ethernet] (irq=POLL)
imx-dwmac 30bf0000.ethernet end1: No Safety Features support found
imx-dwmac 30bf0000.ethernet end1: IEEE 1588-2008 Advanced Timestamp supported
imx-dwmac 30bf0000.ethernet end1: registered PTP clock
imx-dwmac 30bf0000.ethernet end1: FPE workqueue start
imx-dwmac 30bf0000.ethernet end1: configuring for phy/rgmii-id link mode
8021q: adding VLAN 0 to HW filter on device end1
NET: Registered PF_QIPCRTR protocol family
[  OK  ] Started user@106.service - User Manager for UID 106.
[  OK  ] Started session-1.scope - Session 1 of User sddm.
         Starting rtkit-daemon.service - Re…imeKit Scheduling Policy Service...
[  OK  ] Started session-3.scope - Session 3 of User sddm.
[  OK  ] Started rtkit-daemon.service - RealtimeKit Scheduling Policy Service.
imx-dwmac 30bf0000.ethe[   15.424866] imx-dwmac 30bf0000.ethernet end1: Link is Up - 1Gbps/Full - flow control off
rnet end1: Link is Up - 1Gbps/Full - flow control off
EDID block 2 (tag 0x00)[   16.827348] EDID block 2 (tag 0x00) checksum is invalid, remainder is 191
 checksum is invalid, remainder is 191
[*     ] (1 of 2) Job systemd-networkd-wait-…ice/start running (11s / no limit)
[   17.388405] EDID block 2 (tag 0x00) checksum is invalid, remainder is 191
[  OK  ] Finished NetworkManager-wait-onlin…vice - Network Manager Wait Online.
[  OK  ] Finished systemd-networkd-wait-onl… Wait for Network to be Configured.
[  OK  ] Reached target network-online.target - Network is Online.
[  OK  ] Started cups-browsed.service - Mak…te CUPS printers available locally.
         Starting rc-local.service - /etc/rc.local Compatibility...
[  OK  ] Started rc-local.service - /etc/rc.local Compatibility.
         Starting plymouth-quit-wait.servic…d until boot process finishes up...
         Starting plymouth-quit.service - Terminate Plymouth Boot Screen...

Debian GNU/Linux 13 rfnm ttymxc1

rfnm login: root (automatic login)

Linux rfnm 6.6.36-rt35 #2 SMP PREEMPT_RT Thu Feb 19 01:11:28 UTC 2026 aarch64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
root@rfnm:~# ls
root@rfnm:~# /rfnm/scripts/enable_
enable_la9310_uart_ext_port  enable_usb-a                 
root@rfnm:~# /rfnm/scripts/enable_usb-a 
root@rfnm:~# [   51.997239] usb 1-1: new high-speed USB device number 2 using xhci-hcd
[   52.208166] hub 1-1:1.0: USB hub found
[   52.208256] hub 1-1:1.0: 4 ports detected
[   52.493537] usb 1-1.2: new high-speed USB device number 3 using xhci-hcd
[   52.724422] input: Logitech USB Receiver as /devices/platform/soc@0/32f10108.usb/38200000.usb/xhci-hcd.1.auto/usb1/1-1/1-1.2/1-1.2:1.0/0003:046D:C54D.0001/input/input1
[   52.724950] hid-generic 0003:046D:C54D.0001: input: USB HID v1.11 Mouse [Logitech USB Receiver] on usb-xhci-hcd.1.auto-1.2/input0
[   52.727869] input: Logitech USB Receiver Keyboard as /devices/platform/soc@0/32f10108.usb/38200000.usb/xhci-hcd.1.auto/usb1/1-1/1-1.2/1-1.2:1.1/0003:046D:C54D.0002/input/input2
[   52.786994] hid-generic 0003:046D:C54D.0002: input: USB HID v1.11 Keyboard [Logitech USB Receiver] on usb-xhci-hcd.1.auto-1.2/input1
[   52.788196] hid-generic 0003:046D:C54D.0003: device has no listeners, quitting
[   52.865232] usb 1-1.3: new full-speed USB device number 4 using xhci-hcd
[   53.108911] input: Logitech G915 WIRELESS RGB MECHANICAL GAMING KEYBOARD as /devices/platform/soc@0/32f10108.usb/38200000.usb/xhci-hcd.1.auto/usb1/1-1/1-1.3/1-1.3:1.0/0003:046D:C33E.0004/input/input3
[   53.166999] hid-generic 0003:046D:C33E.0004: input: USB HID v1.11 Keyboard [Logitech G915 WIRELESS RGB MECHANICAL GAMING KEYBOARD] on usb-xhci-hcd.1.auto-1.3/input0
[   53.169183] input: Logitech G915 WIRELESS RGB MECHANICAL GAMING KEYBOARD Mouse as /devices/platform/soc@0/32f10108.usb/38200000.usb/xhci-hcd.1.auto/usb1/1-1/1-1.3/1-1.3:1.1/0003:046D:C33E.0005/input/input4
[   53.169767] input: Logitech G915 WIRELESS RGB MECHANICAL GAMING KEYBOARD Consumer Control as /devices/platform/soc@0/32f10108.usb/38200000.usb/xhci-hcd.1.auto/usb1/1-1/1-1.3/1-1.3:1.1/0003:046D:C33E.0005/input/input5
[   53.229861] input: Logitech G915 WIRELESS RGB MECHANICAL GAMING KEYBOARD System Control as /devices/platform/soc@0/32f10108.usb/38200000.usb/xhci-hcd.1.auto/usb1/1-1/1-1.3/1-1.3:1.1/0003:046D:C33E.0005/input/input6
[   53.229984] hid-generic 0003:046D:C33E.0005: input: USB HID v1.11 Mouse [Logitech G915 WIRELESS RGB MECHANICAL GAMING KEYBOARD] on usb-xhci-hcd.1.auto-1.3/input1
[   53.232002] hid-generic 0003:046D:C33E.0006: device has no listeners, quitting
[   57.407380] systemd-journald[190]: File /var/log/journal/f3a47a0bb14f4ea9a00de9a2ce6c8cc4/user-1000.journal corrupted or uncleanly shut down, renaming and replacing.
[   62.736327] EDID block 2 (tag 0x00) checksum is invalid, remainder is 191