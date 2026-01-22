Find RFNM on network
- ```sudo arp-scan --localnet | grep -iE "nxp|freescale|00:04:9f"```

SSH into RFNM
- ```ssh root@10.27.41.31```

Enabling USB-A Power
- ```/rfnm/scripts/eanble_usb-a```


Can likely host packages on local PC to update from
1. Compile kernel driver on laptop
1. Host apt server
1. Run apt get on RFNM which pulls new software from laptop

