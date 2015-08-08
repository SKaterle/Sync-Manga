[String] $oldPath = "F:\Manga\old"
[String] $newPath = "F:\Manga\Ongoing"

function copyChapter([String] $old, [String] $new)
{
    $subDir = Get-ChildItem -Directory -Path $old\*    
    Foreach ($oldDir in $subDir)
    {
        $chapter = ($oldDir.Name).Split("-")
        [String] $newChapter = $chapter[1].Trim()
        $newChapter = "c" + $newChapter.Substring($newChapter.Length - 3)
        if ((Test-Path -PathType Container -Path $new\$newChapter) -ne $true)
        {
            [String] $fullPath = $oldDir.FullName + "\*"
            $fullPath = $fullPath.Replace("[", "``[")
            $fullPath = $fullPath.Replace("]", "``]")
            New-Item -ItemType Directory -Force -Path ($new + "\" + $newChapter) | Out-Null
            Copy-Item -Path $fullPath -Destination ($new + "\" + $newChapter)
        }
        
    }
}
function getChapter([String] $manga, [String] $path)
{
    write-host $manga 
    if ((Test-Path -PathType Container -Path $newPath\$manga) -ne $true)
    {
        New-Item -ItemType Directory -Force -Path ($newPath + "\" + $manga) | Out-Null
    }
    copyChapter $path ($newPath + "\" + $manga)
}
Get-ChildItem -Directory -Path $oldPath\* | Foreach { getChapter $_.Name $_.FullName }
