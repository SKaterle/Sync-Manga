# main folder where the manga will be stored - amend the path to your local repository
[String] $mangaFolder = "F:\Manga\mangareader\Ongoing"

# all updates will be stored in this folder
[String] $syncFolder = "F:\Manga\Sync"

# manga site to be checked
[String] $source = "http://www.mangareader.net"

function getChapter([String] $url, [String] $folder)
{
    do
    {       
        $statusCode = 0
        try
        {
            # http://www.mangareader.net/aku-no-kyouten/3/19
            $fname = "000" + $url.Substring($url.LastIndexOf("/")+1)
            $fname = $fname.Substring($fname.Length - 3)
            $response = Invoke-WebRequest -Uri ($url)
            $response.Images | Where-Object {$_.alt -clike ($manga+ "*") } | Foreach {$image = $_.src}
            $response.Links | Where-Object {$_.innerText -clike "Next" } | foreach {$url = $source + $_.href}
            if ($image)
            {
                $fname = $fname + $image.Substring($image.LastIndexOf("."))               
                Invoke-WebRequest -Uri $image -OutFile ($folder + $fname)
                #if ($syncFolder.Length -ne 0)
                #{
                #    Copy-Item -Path ($folder + $fname) -Destination (($folder.Replace($mangaFolder, $syncFolder)) + $fname)
                #} 
            }
            $response.ParsedHtml.body.getElementsByTagName('div') | Where {$_.getAttributeNode('id').Value -eq 'recom_info'} | Foreach { $statusCode = -1 }      
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
    if ($url.Trim().Length -gt 0)
    {
        $folder = "000" + $url.Substring($url.LastIndexOf("/")+1)
        $folder = $folder.Substring($folder.Length -3)         
        $folder = $mangaFolder + "\" + $manga + "\" + $folder
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
            getChapter ($source + $url + "/1") ($folder + "\")
        }
    }
}

function getManga([String] $manga)
{
    $url = $manga.Replace(" ", "-")
    $url = $url.Replace("(", "-")
    $url = $url.Replace(")", "-")
    $url = $url.Replace("-", "-")
    $url = $url.Replace(",", "-")
    do
    {
        $url = $url.Replace("--", "-") 
    } while ($url.IndexOf("--") -ne -1)
    $url = $url.ToLower()
    $next = $source + "/" + $url
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