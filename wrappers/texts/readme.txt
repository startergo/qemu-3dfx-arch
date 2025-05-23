QEMU-3dfx Wrappers Disk
=================================================================================================

This disk contains wrappers used to make the VM working.

=================================================================================================
Installation
For Win9x/ME:

Copy FXMEMMAP.VXD to C:\WINDOWS\SYSTEM
Copy GLIDE.DLL, GLIDE2X.DLL and GLIDE3X.DLL to C:\WINDOWS\SYSTEM
Copy GLIDE2X.OVL to C:\WINDOWS
Copy OPENGL32.DLL to Game Installation folders

For Win2k/XP:

Copy FXPTL.SYS to %SystemRoot%\system32\drivers
Copy GLIDE.DLL, GLIDE2X.DLL and GLIDE3X.DLL to %SystemRoot%\system32
Run INSTDRV.EXE, require Administrator Priviledge
Copy OPENGL32.DLL to Game Installation folders

=================================================================================================
Testing

If you have done installing it. Try WGLTEST.EXE or WGLGEARS.EXE on disk. It is expected
to run it and see some gears or triangles rotating and know the fps and passthough specs.

But if you see one of the errors if you did something wrong.

1. (Red) If you got illegal operation error like
"Failure: LoadLibrary(opengl32.dll)=0x454"

- Did you follow the Installation guide properly?
- The Wrapper commit is mismatched. compile both QEMU and wrapper in the same commit.

2. (Yellow) If you got a error like
"A required DLL file, API-MS-WIN-CRT-CONVERT-L1-1-0.DLL, was not found."

This means this binary is improperly compiled. Consider compiling in a different enviroment

3. (Crashes) If QEMU Crashes. This means there is something wrong with the system or config.

- If you use NVIDIA on Linux, use Zink.

=================================================================================================
SoftGPU Support
This Binary also supports SoftGPU and now easier to install! (Win9x Only!)
https://github.com/JHRobotics/SoftGPU

1. Check for PCI bus. If you see nothing on Device Manager. Skip this step
If you see some "Plug and Play BIOS" error. follow instructions.
https://github.com/JHRobotics/SoftGPU#pci-bus-detection-fix

2. Install dependencies, This includes DirectX and more

3. Select preset to "QEMU-3dfx" and install then reboot

4. Open disk directory and go to EXTRAS\QEMU-3DFX then edit SET-SIGN.REG
based from GIT revision hash or commit. You can get it from COMMIT ID.TXT 
on Wrapper Disk or search the repository based where you compile it.
Edit "REV_QEMU3DFX"="commit id" where commit id is the first 7 characters
on a commit id!. If your done, run TESTQMFX.EXE. 
If you see triangles spinning, congrats

5. Copy FXMEMMAP.VXD and QMFXGL32.DLL to C:\WINDOWS\SYSTEM and apply file
ICD-ENABLE.REG and reboot

6. Run GLchecker or other 3D application to verify if its running

=================================================================================================
Notes

- Some texts have some occasional problems due to Text Encoding.
- Some tests are used in my host system
