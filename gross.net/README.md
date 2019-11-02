## Solution
* If using vbox it needs to be told not to reset the time `VBoxManage setextradata "vmname" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1`
* Change system time to 11:00 AM on the 30th of November 2019
* add service (sc.exe create gross binPath=C:\gross.net.exe)
* run service (sc.exe start gross)
* attach with dnspy
* Set breakpoint at the end of generatePassword. Dnspy does not seem to get the contents of `text` on the return or statements not using it. Break on `text += array2(num And 15)` (vb) and continue 7 times. Copy the string in `text` and then add the last 2 bytes manually (and the value in `num` with 15 and look it up in `array2`).
* wrap in WACTF3{}

