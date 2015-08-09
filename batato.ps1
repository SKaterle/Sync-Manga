function getChapterBatot([String] $url,[String] $mangaDir)
{
    [String] $response = Invoke-WebRequest -Uri ($url) -UseBasicParsing
    [String] $page = $response.Substring($response.IndexOf('id="comic_page"'))
    [String] $select = $response.Substring($response.IndexOf('id="page_select"'))
    #get the current image as page 1
    $page = $page.Substring($page.IndexOf('src="')+5)
    $page = $page.Substring(0,$page.IndexOf('"'))
    if ($page)
    {
        Invoke-WebRequest -Uri $page -OutFile ($mangaDir + "\" + $page.Substring($page.LastIndexOf("/")+1))
        #if ($syncFolder.Length -ne 0)
        #{
        #    Copy-Item -Path ($folder + $fname) -Destination ($folder.Replace($mangaFolder, $syncFolder))
        #} 
    }   
    #crawl the page select
    $select = $select.Substring($select.IndexOf(">")+1)
    $select = $select.Substring($select.IndexOf("</option>")+9)
    $select = $select.Substring(0,$select.IndexOf("</select>"))
    do
    {
        $select = $select.Substring($select.IndexOf('value="')+7)
        $page = $select.Substring(0,$select.IndexOf('"'))
        $response = Invoke-WebRequest -Uri ($page) -UseBasicParsing
        $page = $response.Substring($response.IndexOf('id="comic_page"'))
        $page = $page.Substring($page.IndexOf('src="')+5)
        $page = $page.Substring(0,$page.IndexOf('"'))
        if ($page)
        {
            Invoke-WebRequest -Uri $page -OutFile ($mangaDir + "\" + $page.Substring($page.LastIndexOf("/")+1))
            #if ($syncFolder.Length -ne 0)
            #{
            #    Copy-Item -Path ($folder + $fname) -Destination ($folder.Replace($mangaFolder, $syncFolder))
            #} 
        }  
        if (($select.IndexOf('value="')) -eq -1) { break }
        $select = $select.Substring($select.IndexOf("</option>")+9) 
    } while ($select.Length -gt 0)
}

function checkChapterBatoto([String] $url,[String] $mangaDir)
{
    [String] $chapter = $url.Substring($url.LastIndexOf("/")+1)
    $chapter = $chapter.Substring(0,$chapter.LastIndexOf("_by_"))
    $chapter = "0000" + ($chapter.Substring($chapter.LastIndexOf("_")+1)).Replace("ch", "")
    [String] $folder = $mangaDir + "\" + "c" + $chapter.Substring($chapter.Length -3)
        #check main folder
        if ((Test-Path -Path $folder -PathType Container) -eq $false)
        {
            #check sync folder
            if ($syncFolder.Length -ne 0)
            {
                New-Item -ItemType Directory -Force -Path ($folder.Replace($mangaFolder, $syncFolder)) | Out-Null
            }           
            New-Item -ItemType Directory -Force -Path $folder | Out-Null
            getChapterBatot $url $folder
        }           
}

function getBatoto([String] $manga, [String] $mangaDir)
{
    try
    {
        [String] $response = Invoke-WebRequest -Uri ($manga) -UseBasicParsing 
        [Int] $pos1 = $response.IndexOf('h3 class="maintitle"')
        [Int] $pos2 = $response.IndexOf("<div id='commentsStart'",$pos1)
        [String] $chapters = $response.Substring($pos1, $pos2-$pos1)
        do
        {
            # need to crawl the table to get the right link based on language provided
            $pos1 = $chapters.IndexOf("lang_" + $langBato)
            if ($pos1 -eq -1) {break} 
            $chapters = $chapters.Substring($pos1)
            $pos1 = $chapters.IndexOf("href=") + 6
            $pos2 = $chapters.IndexOf('"', $pos1)
            checkChapterBatoto ($chapters.Substring($pos1, $pos2 - $pos1)) $mangaDir
            $chapters = $chapters.Substring($pos2)
        } while ($chapters.Length -gt 0)
        Write-host " Good" -BackgroundColor Green
    }
    catch [System.Net.WebException] 
    {
        $statusCode = [int]$_.Exception.Response.StatusCode
        Write-Host "Error: $statusCode" -BackgroundColor Red
    } 
}

function checkNameBato([String] $fullPath, [String] $manga)
{
    if ((Test-Path -Path $fullPath\bato.txt) -eq $false)
    {
        #bato.to uses DB-ID - first time check, search for name and respective ID
        # this will always take some time, as only basic parsing is possible, thanks to bato cookie policy
        [String] $link
        $response = Invoke-WebRequest -Uri ("http://www.bato.to/search?name=" + $manga.Replace(" ", "+")) -UseBasicParsing 
        $response.Links -cmatch "comic" | Foreach { $link = $_.href }
        if ($link.Length -ne 0)
        {
            $link > ($fullPath + "\bato.txt")   
        } else {
            "#skip" > ($fullPath + "\bato.txt")   
        }
    }
    $mangaBato = Get-Content -Path $fullPath\bato.txt
    if ($mangaBato.Equals("#skip") -eq $false)
    {
       Write-Host "Checking $manga " -NoNewline
       getBatoto $mangaBato $fullPath
    }
}

clear
# main folder where the manga will be stored - amend the path to your local repository
[String] $mangaFolder = "f:\Manga\test"

# all updates will be stored in this folder
[String] $syncFolder = "f:\Manga\Sync"

# language selector for Bato.to
[String] $langBato = "English"

# Bato.to to be checked
Write-Host "Start Checking Bato [$langBato] " -BackgroundColor Gray
$source = "http://bato.to"
Get-ChildItem -Directory -Path $mangaFolder | Foreach { checkNameBato $_.FullName $_.Name }
Write-Host "Done" -BackgroundColor Gray
Write-Host ""

# Remove folders from sync folder with no updates
if ($syncFolder)
{
    Get-ChildItem -Directory -Path $syncFolder\* | Foreach { if ( (Get-ChildItem -Directory -Path $_.FullName).Count -eq 0) { Remove-Item -Path $_.FullName} }
}
Write-Host "All Done!"
# remove the two lines below if this script runs as scheduled task!
Write-Host "Press any key to close the window"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")