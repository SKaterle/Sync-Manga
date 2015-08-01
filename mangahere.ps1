$mangaFolder = "F:\Manga\mangahere\Ongoing"
$syncFolder = "F:\Manga\mangahere\Sync"
$source = "http://www.mangahere.co/manga/"

function getChapter([String] $url, [String] $folder)
{
    write-host "$url to $folder"
    do
    {
        $statusCode = 0
        try
        {
            $response = Invoke-WebRequest -Uri ($url)
            $response.Images -cmatch "id=image" | Foreach {$image = $_.src}
            $response.Links -cmatch "next" | foreach {$url = $_.href}
            if ($image)
            {
                $fname = ($image.Substring($image.LastIndexOf("/")+1)).Split("?")
                Invoke-WebRequest -Uri $image -OutFile ($folder + $fname[0])
                write-host "." -noNewLine
                if ($syncFolder)
                {
                    $target = $folder.Replace($mangaFolder, $syncFolder)
                    Copy-Item -Path ($folder + $fname[0]) -Destination $target 
                } 
            }
            if ($url.EndsWith(".html") -eq $false)
            {
                $statusCode = -1
            }      
        }
        catch [System.Net.WebException] 
        {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
    } while ($statusCode -eq 0)
}

function checkChapter([String] $manga,[String] $url)
{
    if ($url.Trim())
    {
        $folder = $url -replace ".$"
        $folder = $mangaFolder + "\" + $manga + "\" + $folder.Substring($folder.LastIndexOf("/")+1)
        #check main folder
        if ((Test-Path -Path $folder -PathType Container) -eq $false)
        {
            #check sync folder
            $sync_folder = $syncFolder + "\" + $manga
            if ((Test-Path -Path $sync_folder -PathType Container) -eq $false)
            {
                New-Item -ItemType Directory -Force -Path $sync_folder
            }
            $sync_folder = $url -replace ".$"
            $sync_folder = $syncFolder + "\" + $manga + "\" + $sync_folder.Substring($sync_folder.LastIndexOf("/")+1)
            New-Item -ItemType Directory -Force -Path $sync_folder
            New-Item -ItemType Directory -Force -Path $folder
            getChapter $url ($folder + "\")
        }
    }
}

function getManga([String] $manga)
{
    $url = $manga.Replace(" ", "_")
    $url = $url.ToLower()
    $next = $source + $url + "/"
    $response = Invoke-WebRequest -Uri ($next)
    $response.AllElements | Where-Object {$_.innerText -match $manga} | Foreach {checkChapter $manga $_.href}
}
clear
Get-ChildItem -Directory -Path $mangaFolder | foreach { getManga $_.Name }