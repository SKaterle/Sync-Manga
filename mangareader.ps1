# main folder where the manga will be stored - amend the path to your local repository
[String] $mangaFolder = "F:\Manga\mangareader\Ongoing"

# all updates will be stored in this folder
[String] $syncFolder = "F:\Manga\Sync"

# manga site to be checked
[String] $source = "http://www.mangareader.net"

function getChapter([String] $url, [String] $folder)
{
    [Int] $page = 1
    [Int] $statusCode = 0    
    do
    {   
        try
        {
            $fname = "000" + $page.ToString()
            $fname = $fname.Substring($fname.Length - 3)
            $response = Invoke-WebRequest -Uri ($url + "/" + $page.ToString())
            #$response.ParsedHtml.body.getElementsByTagName('div') | Where {$_.getAttributeNode('id').Value -eq 'recom_info'} | Foreach { $statusCode = -1 } 
            $response.Images | Foreach { $image = $_.src }
            
            if ($image.Length -ne 0)
            {
                $fname = $fname + $image.Substring($image.LastIndexOf("."))               
                Invoke-WebRequest -Uri $image -OutFile ($folder + $fname)
                if ($syncFolder.Length -ne 0)
                {
                    Copy-Item -Path ($folder + $fname) -Destination (($folder.Replace($mangaFolder, $syncFolder)) + $fname)
                } 
            }                 
        }
        catch [System.Net.WebException] 
        {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        $page++
    } while ($statusCode -eq 0)

    if ((Get-ChildItem $folder).Count -eq 0)
    {
        Remove-Item -Path $folder -Force
        if ($syncFolder.Length -ne 0)
        {
            Remove-Item -Path ($folder.Replace($mangaFolder, $syncFolder)) -Force
        }
    } 
}

function checkChapter([String] $manga,[String] $url)
{
    if ($url.Trim().Length -gt 0)
    {
        [Int] $chapter = 1
        [Int] $statusCode = 0
        do
        {
            [String] $folder = "000" + $chapter.ToString()
            $folder = $mangaFolder + "\" + $manga + "\" + "c" + $folder.Substring($folder.Length -3)
            try
            {
                $response = Invoke-WebRequest -Uri ($url + "/" + $chapter.ToString())
                $response.ParsedHtml.body.getElementsByTagName('div') | Where {$_.getAttributeNode('id').Value -eq 'recom_info'} | Foreach { $statusCode = -1 } 
                if ($statusCode -ne 0) { break }
                #check main folder
                if ((Test-Path -Path $folder -PathType Container) -eq $false)
                {
                    #check sync folder
                    if ($syncFolder.Length -ne 0)
                    {
                        New-Item -ItemType Directory -Force -Path ($folder.Replace($mangaFolder, $syncFolder)) | Out-Null
                    }            
                    New-Item -ItemType Directory -Force -Path $folder | Out-Null
                    getChapter ($url + "/" + $chapter.ToString()) ($folder + "\")
                }
            }
            catch [System.Net.WebException] 
            {
                #no more chapters
                $statusCode = [int]$_.Exception.Response.StatusCode
            }            
            $chapter++
        } while ($statusCode -eq 0)
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
        checkChapter $manga $next
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