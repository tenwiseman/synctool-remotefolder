# synctool-remotefolder

Update-Target.ps1 is a Powershell command script that can be simply placed
on a local machine, and manually invoked to recursively copy items from a
local source folder to a target folder on a remote machine.

Using this script is a developers alternative when not having access
to a remote machine shell inside the local machine environment, such as is
sometimes the case when the user is working remotely.

## What it does

Primarily, the script copies source files that do not exist in the target folder or
overwrites target files that have an older LastWriteTime than the source.

However, if the target contains "foreign" files that do not exist in the source folder or
target files exist with a newer LastWriteTime than the source, then the user
is asked if they would like these files copied back to the source folder.

This assists the workflow where the user may be directly debugging and fixing
the contents of files on the remote machine, and they would like their sucessful
changes written back to the source folder.
