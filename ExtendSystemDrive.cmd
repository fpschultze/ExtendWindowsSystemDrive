@ECHO OFF

:: ExtendSystemDrive.cmd
::
:: Uses the entire unallocated disk space to extend the system drive partition.
:: Requires diskpart.exe
:: Run script as admin.
::
:: Syntax:
::
:: ExtendSystemDrive.cmd GB
::
::   GB     Integer value. Specifies the required amount of unallocated disk space in GB.

SET tmpFolder=%TEMP%\%~n0
SET SystemDriveLetter=%SystemDrive:~,1%
SET PartitionID=
SET DiskID=
SET DiskSize=
SET DiskFree=
(SET /A ShouldBeAvailableGB = %1) 2>NUL
IF NOT DEFINED ShouldBeAvailableGB (
  ECHO Syntax error.
  GOTO :END
)

MKDIR %tmpFolder% 2>NUL

ECHO Get the ID of system partition [%SystemDriveLetter%]...
(ECHO RESCAN)>%tmpFolder%\command.tmp
(ECHO LIST VOLUME)>>%tmpFolder%\command.tmp
diskpart.exe /s %tmpFolder%\command.tmp | findstr.exe /C:" %SystemDriveLetter% " >%tmpFolder%\command.out
FOR /F "tokens=2" %%i IN ('TYPE %tmpFolder%\command.out') DO (SET PartitionID=%%i)
IF NOT DEFINED PartitionID (
  ECHO ERROR: Failed to get the partition ID
  GOTO :End
)
ECHO %PartitionID%

ECHO Get disk ID...
(ECHO RESCAN)>%tmpFolder%\command.tmp
(ECHO SELECT VOLUME %PartitionID%)>>%tmpFolder%\command.tmp
(ECHO LIST DISK)>>%tmpFolder%\command.tmp
diskpart.exe /s %tmpFolder%\command.tmp | findstr.exe /R "^\*.Disk" >%tmpFolder%\command.out
FOR /F "tokens=3" %%i IN ('TYPE %tmpFolder%\command.out') DO (SET DiskID=%%i)
IF NOT DEFINED DiskID GOTO :End
ECHO %DiskID%

ECHO Get disk size...
FOR /F "tokens=5-8" %%i IN ('TYPE %tmpFolder%\command.out') DO (SET DiskSize=%%i %%j&SET DiskFree=%%k %%l)
ECHO %DiskSize%, %DiskFree% free
FOR /F "tokens=2" %%i IN ("%DiskFree%") DO IF "%%i" NEQ "GB" (
  ECHO WARNING: Not enough unallocated disk space available
  GOTO :End
)
FOR /F "tokens=1" %%i IN ("%DiskFree%") DO IF %%i LSS %ShouldBeAvailableGB% (
  ECHO WARNING: Not enough unallocated  disk space available
  GOTO :End
)
IF "%DiskFree%" EQU "0 B" (
  ECHO WARNING: No unallocated disk space available
  GOTO :End
)

ECHO Extend the partition...
(ECHO SELECT VOLUME %PartitionID%)>%tmpFolder%\command.tmp
(ECHO EXTEND)>>%tmpFolder%\command.tmp
(ECHO LIST VOLUME)>>%tmpFolder%\command.tmp
diskpart.exe /s %tmpFolder%\command.tmp >%tmpFolder%\command.out
ECHO Done.
ECHO.
ECHO.  Disk ###  Status         Size     Free     Dyn  Gpt
ECHO.  --------  -------------  -------  -------  ---  ---
TYPE %tmpFolder%\command.out | findstr.exe /R "^\*.Volume"
GOTO :End

:End
RMDIR /S /Q %tmpFolder%
GOTO :EOF

:Notes
DISKPART> LIST VOLUME

  Volume ###  Ltr  Label        Fs     Type        Size     Status     Info
  ----------  ---  -----------  -----  ----------  -------  ---------  --------
  Volume 0     E                       DVD-ROM         0 B  No Media
  Volume 1         System Rese  NTFS   Partition    100 MB  Healthy    System
  Volume 2     C   System       NTFS   Partition     49 GB  Healthy    Boot
  Volume 3     D   SWAP         NTFS   Partition     19 GB  Healthy    Pagefile

DISKPART> SELECT VOLUME 2

Volume 2 is the selected volume.

DISKPART> LIST VOLUME

  Volume ###  Ltr  Label        Fs     Type        Size     Status     Info
  ----------  ---  -----------  -----  ----------  -------  ---------  --------
  Volume 0     E                       DVD-ROM         0 B  No Media
  Volume 1         System Rese  NTFS   Partition    100 MB  Healthy    System
* Volume 2     C   System       NTFS   Partition     49 GB  Healthy    Boot
  Volume 3     D   SWAP         NTFS   Partition     19 GB  Healthy    Pagefile

DISKPART> LIST DISK

  Disk ###  Status         Size     Free     Dyn  Gpt
  --------  -------------  -------  -------  ---  ---
* Disk 0    Online          100 GB    50 GB
  Disk 1    Online           20 GB      0 B
