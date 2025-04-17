Advanced Boot Disk version 4.0
======================================================================

A floppy disk with tools that helps
you install Windows 9x on QEMU-3dfx.

======================================================================
Changelog:
- Change Kernel to FreeDOS
======================================================================
Problems:
1. Reading disk is unavailable while your using Windows on VMware unless modifying bios.
   VirtualBox may not work.
2. msbatch.inf is included on win98.zip. If you dont want it, delete the file.
3. Windows NT drivers and batch not included.
4. unzip -d c:\$windir batch\win98.zip btw
5. disk have errors reading when changing disks using qemu monitor
