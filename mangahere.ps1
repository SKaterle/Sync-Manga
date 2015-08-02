# main folder where the manga will be stored - amend the path to your local repository
[String] $mangaFolder = "F:\Manga\mangahere\Ongoing"

# all updates will be stored in this folder
[String] $syncFolder = "F:\Manga\Sync"

# manga site to be checked
[String] $source = "http://www.mangahere.co/manga/"

function getChapter([String] $url, [String] $folder)
{
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
                if ($syncFolder.Length -ne 0)
                {
                    Copy-Item -Path ($folder + $fname[0]) -Destination ($folder.Replace($mangaFolder, $syncFolder))
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
            Write-Host "Error: $statusCode" -BackgroundColor Red -NoNewline
        }
    } while ($statusCode -eq 0)
    if ((Get-ChildItem $folder).Count -eq 0)
    {
        Remove-Item -Path $folder -Force
        if ($syncFolder.Length -ne 0)
        {
            Remove-Item -Path ($folder.Replace($mangaFolder, $syncFolder)) -Force
        }
    } else {
        if ((Get-ChildItem -Path $folder\*).Count -eq 1)
        {
            Remove-Item -Path $folder -Force -Recurse
            if ($syncFolder.Length -ne 0)
            {
                Remove-Item -Path ($folder.Replace($mangaFolder, $syncFolder)) -Force -Recurse
            }
        } 
    }
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
            if ($syncFolder.Length -ne 0)
            {
                $sync_folder = $syncFolder + "\" + $manga
                if ((Test-Path -Path $sync_folder -PathType Container) -eq $false)
                {
                    New-Item -ItemType Directory -Force -Path $sync_folder | Out-Null
                }
                $sync_folder = $url -replace ".$"
                $sync_folder = $syncFolder + "\" + $manga + "\" + $sync_folder.Substring($sync_folder.LastIndexOf("/")+1)
                New-Item -ItemType Directory -Force -Path $sync_folder | Out-Null
            }            
            New-Item -ItemType Directory -Force -Path $folder | Out-Null
            getChapter $url ($folder + "\")
        }
    }
}

function getManga([String] $manga)
{
    $url = $manga.Replace(" ", "_")
    $url = $url.Replace("(", "")
    $url = $url.Replace(")", "")
    $url = $url.Replace("-", "_")
    $url = $url.Replace(",", "_")
    $url = $url.Replace("!", "")
    do
    {
        $url = $url.Replace("__", "_") 
    } while ($url.IndexOf("__") -ne -1)
    $url = $url.ToLower()
    $next = $source + $url + "/"
    Write-Host "Checking $manga " -NoNewline
    try
    {
        $response = Invoke-WebRequest -Uri ($next)
        $response.Links | Where-Object {$_.innerText -clike ($manga+ "*") } | Foreach {checkChapter $manga $_.href}
        Write-host " Good" -BackgroundColor Green
    }
    catch [System.Net.WebException] 
    {
        $statusCode = [int]$_.Exception.Response.StatusCode
        Write-Host "Error: $statusCode" -BackgroundColor Red -NoNewline
    }
    
}
clear
Write-Host "Start"
Get-ChildItem -Directory -Path $mangaFolder | Foreach { getManga $_.Name }
Get-ChildItem -Directory -Path $syncFolder\* | Foreach { if ( (Get-ChildItem -Directory -Path $_.FullName).Count -eq 0) { Remove-Item -Path $_.FullName} }
Write-Host "All Done!"
# remove the two lines below if this script runs as scheduled task!
Write-Host "Press any key to close the window"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")