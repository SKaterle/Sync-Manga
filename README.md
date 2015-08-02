# Sync-Manga
usage:
Create a folder, as example: c:\manga
Download the script and save in this folder
Create a sub-folder, where the respective script-connector should store the manga.
As example: c:\manga\mangahere
Optional: create an update folder, as example: c:\manga\updates
Open the script in a text editor and amend the following lines:
[String] $mangaFolder = "<your manga folder goes here>"
[String] $syncFolder = "<your update folder goes here>"
Open Powershell and execute the script.

The $mangaFolder contains all downloaded chapters
The $syncFolder only contains new chapters

# Adding a new manga
Take a note of the manga name, es examples:
Shokugeki no Soma
Nisekoi (KOMI Naoshi)
- The name should be identitical to the displayed name
Create a sub-folder under the manga folder, using the name.
c:\manga\mangahere\Shokugeki no Soma
c:\manga\mangahere\Nisekoi (KOMI Naoshi)

The next time the script starts, the manga will be downloaded / syncronized

# Removing a managa
Either delete or move the manga out of the folder for the connector

# Something gone wrong or pages are missing
Simple delete the chapter from the manga folder and the next time the script is executed, it will download the single chapter again.
