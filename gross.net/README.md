## Solution
* Change system time to X
* add service (sc.exe create gross binPath=C:\gross.net.exe)
* run service (sc.exe start gross)
* attach with dnspy
* Set breakpoint at the end of generatePassword
* Read password
* Submit as WACTF3{password}

