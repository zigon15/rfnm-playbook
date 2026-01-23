  #!/bin/bash                                                                                                           
  DEVICE="/dev/sdb"                                                                                                     
                                                                                                                        
  echo "=== Partition Layout ==="                                                                                       
  fdisk -l "$DEVICE"                                                                                               
                                                                                                                        
  echo -e "\n=== U-Boot Check ==="                                                                                      
  dd if="$DEVICE" bs=1K skip=32 count=512 2>/dev/null | strings | grep -i "u-boot" | head -3                       
                                                                                                                        
  echo -e "\n=== Boot Partition ==="                                                                                    
  mkdir -p /tmp/check_boot                                                                                         
  mount "${DEVICE}1" /tmp/check_boot                                                                               
  ls -lh /tmp/check_boot/                                                                                               
  umount /tmp/check_boot                                                                                           
  rmdir /tmp/check_boot                                                                                                 
                                                                                                                        
  echo -e "\n=== Root Partition ==="                                                                                    
  mkdir -p /tmp/check_root                                                                                         
  mount "${DEVICE}2" /tmp/check_root                                                                               
  df -h /tmp/check_root                                                                                                 
  ls -l /tmp/check_root/ | head -10                                                                                     
  umount /tmp/check_root                                                                                           
  rmdir /tmp/check_root                                                                                                 
                                                                                                                        
  echo -e "\n=== Filesystem Integrity ==="                                                                              
  fsck.vfat -n "${DEVICE}1"                                                                                        
  fsck.ext4 -n "${DEVICE}2" 