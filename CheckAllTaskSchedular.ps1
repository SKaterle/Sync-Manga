function getChapterMangaReader([String] $url, [String] $folder)
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

function checkChapterMangaReader([String] $manga,[String] $url, [String] $mangaDir)
{
    if ($url.Trim().Length -gt 0)
    {
        [Int] $chapter = 1
        [Int] $statusCode = 0
        do
        {
            [String] $folder = "000" + $chapter.ToString()
            $folder = $mangaFolder + "\" + $mangaDir + "\" + "c" + $folder.Substring($folder.Length -3)
            try
            {
                #check main folder
                if ((Test-Path -Path $folder -PathType Container) -eq $false)
                {
                    $response = Invoke-WebRequest -Uri ($url + "/" + $chapter.ToString())
                    $response.ParsedHtml.body.getElementsByTagName('div') | Where {$_.getAttributeNode('id').Value -eq 'recom_info'} | Foreach { $statusCode = -1 } 
                    if ($statusCode -ne 0) { break }
                    #check sync folder
                    if ($syncFolder.Length -ne 0)
                    {
                        New-Item -ItemType Directory -Force -Path ($folder.Replace($mangaFolder, $syncFolder)) | Out-Null
                    }            
                    New-Item -ItemType Directory -Force -Path $folder | Out-Null
                    getChapterMangaReader ($url + "/" + $chapter.ToString()) ($folder + "\")
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

function getMangaReader([String] $manga, [String] $mangaDir)
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
    #Write-Host "Checking $manga " -NoNewline
    try
    {
        $response = Invoke-WebRequest -Uri ($next)
        checkChapterMangaReader $manga $next $mangaDir
        #Write-Host " Good" -BackgroundColor Green
    }
    catch [System.Net.WebException] 
    {
        $statusCode = [int]$_.Exception.Response.StatusCode
        "#skip" > $mangaFolder\$mangaDir\mangareader.txt
        #Write-Host "Error: $statusCode" -BackgroundColor Red
    }
}

function getChapterMangaHere([String] $url, [String] $folder)
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
            #Write-Host "Error: $statusCode" -BackgroundColor Red -NoNewline
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

function checkChapterMangaHere([String] $manga,[String] $url, [String] $mangaDir)
{
    if ($url.Trim())
    {
        $folder = $url -replace ".$"
        $folder = $mangaFolder + "\" + $mangaDir + "\" + $folder.Substring($folder.LastIndexOf("/")+1)
        #check main folder
        if ((Test-Path -Path $folder -PathType Container) -eq $false)
        {
            #check sync folder
            if ($syncFolder.Length -ne 0)
            {
                New-Item -ItemType Directory -Force -Path ($folder.Replace($mangaFolder, $syncFolder)) | Out-Null
            }            
            New-Item -ItemType Directory -Force -Path $folder | Out-Null
            getChapterMangaHere $url ($folder + "\")
        }
    }
}

function getMangaHere([String] $manga, [String] $mangaDir)
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
    #Write-Host "Checking $manga " -NoNewline
    try
    {
        $response = Invoke-WebRequest -Uri ($next)
        $response.Links | Where-Object {$_.innerText -clike ($manga+ "*") } | Foreach {checkChapterMangaHere $manga $_.href $mangaDir}
        #Write-Host " Good" -BackgroundColor Green
    }
    catch [System.Net.WebException] 
    {
        $statusCode = [int]$_.Exception.Response.StatusCode
        "#skip" > $mangaFolder\$mangaDir\amngahere.txt
        #Write-Host "Error: $statusCode" -BackgroundColor Red
    }
    
}

function getChapterMangaFox([String] $url, [String] $folder)
{
    $url_tmp = $url.Substring(0,$url.LastIndexOf("/")+1)
    do
    {
        $statusCode = 0
        try
        {
            $response = Invoke-WebRequest -Uri ($url)
            $response.Images -cmatch "id=image" | Foreach {$image = $_.src}
            $response.Links -cmatch "next page" | foreach {$url = $url_tmp + $_.href}
            if ($url.EndsWith(".html") -ne $true)
            {
                $statusCode = -1
                break
            }
            if ($image)
            {
                $fname = $image.Substring($image.LastIndexOf("/")+1)
                Invoke-WebRequest -Uri $image -OutFile ($folder + $fname)
                if ($syncFolder.Length -ne 0)
                {
                    Copy-Item -Path ($folder + $fname) -Destination ($folder.Replace($mangaFolder, $syncFolder))
                } 
            }     
        }
        catch [System.Net.WebException] 
        {
            $statusCode = [int]$_.Exception.Response.StatusCode
            #Write-Host "Error Image: $statusCode" -BackgroundColor Red -NoNewline
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

function checkChapterMangaFox([String] $manga,[String] $url,[String] $mangaDir)
{
    if ($url.Trim() -and $url.EndsWith(".html"))
    {
        $folder = $url.Substring(0,$url.LastIndexOf("/"))
        $folder = $mangaFolder + "\" + $mangaDir + "\" + $folder.Substring($folder.LastIndexOf("/")+1)
        #check main folder
        if ((Test-Path -Path $folder -PathType Container) -eq $false)
        {
            #check sync folder
            if ($syncFolder.Length -ne 0)
            {
                New-Item -ItemType Directory -Force -Path ($folder.Replace($mangaFolder, $syncFolder)) | Out-Null
            }           
            New-Item -ItemType Directory -Force -Path $folder | Out-Null
            getChapterMangaFox $url ($folder + "\")
        }
    }
}

function getMangaFox([String] $manga, [String] $mangaDir)
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
    #Write-Host "Checking $manga " -NoNewline
    try
    {
        $response = Invoke-WebRequest -Uri ($next)
        $response.Links | Where-Object {$_.innerText -clike ($manga+ "*") } | Foreach {checkChapterMangaFox $manga $_.href $mangaDir}
        #Write-Host " Good" -BackgroundColor Green
    }
    catch [System.Net.WebException] 
    {
        $statusCode = [int]$_.Exception.Response.StatusCode
        "#skip" > $mangaFolder\$mangaDir\mangafox.txt
        #Write-Host "Error: $statusCode" -BackgroundColor Red
    }   
}

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
        if ($syncFolder.Length -ne 0)
        {
            Copy-Item -Path ($mangaDir + "\" + $page.Substring($page.LastIndexOf("/")+1)) -Destination ($folder.Replace($mangaFolder, $syncFolder))
        } 
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
            if ($syncFolder.Length -ne 0)
            {
                Copy-Item -Path ($mangaDir + "\" + $page.Substring($page.LastIndexOf("/")+1)) -Destination ($folder.Replace($mangaFolder, $syncFolder))
            } 
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
                $dir = $syncFolder + $mangaDir.Substring($mangaDir.LastIndexOf("\"))
                ## check folder
                if ((Test-Path -Path $dir -PathType Container) -eq $false)
                {
                    New-Item -ItemType Directory -Force -Path $dir | Out-Null 
                }
                $dir = $dir + $folder.Substring($folder.LastIndexOf("\"))
                New-Item -ItemType Directory -Force -Path $dir | Out-Null
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
        #Write-Host " Good" -BackgroundColor Green
    }
    catch [System.Net.WebException] 
    {
        $statusCode = [int]$_.Exception.Response.StatusCode
        #Write-Host "Error: $statusCode" -BackgroundColor Red
    } 
}

function checkNameMangaHere([String] $fullPath, [String] $manga)
{
    $mangaDir = $manga
    if ((Test-Path -Path $fullPath\mangahere.txt) -eq $true)
    {        
        $manga = Get-Content -Path $fullPath\mangahere.txt
    }
    if ($manga.Equals("#skip") -eq $false)
    {
        getMangaHere $manga $mangaDir
    }
}

function checkNameMangaFox([String] $fullPath, [String] $manga)
{
    $mangaDir = $manga
    if ((Test-Path -Path $fullPath\mangafox.txt) -eq $true)
    {
        $manga = Get-Content -Path $fullPath\mangafox.txt
    }
    if ($manga.Equals("#skip") -eq $false)
    {
        getMangaFox $manga $mangaDir
    }
}

function checkNameMangaReader([String] $fullPath, [String] $manga)
{
    $mangaDir = $manga
    if ((Test-Path -Path $fullPath\mangareader.txt) -eq $true)
    {
        $manga = Get-Content -Path $fullPath\mangareader.txt
    }
    if ($manga.Equals("#skip") -eq $false)
    {
        getMangaReader $manga $mangaDir
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
       #Write-Host "Checking $manga " -NoNewline
       getBatoto $mangaBato $fullPath
    }
}

clear
# main folder where the manga will be stored - amend the path to your local repository
[String] $mangaFolder = "F:\Manga\Ongoing"

# all updates will be stored in this folder
[String] $syncFolder = "F:\Manga\Sync"

# language selector for Bato.to
[String] $langBato = "English"

# MangaHere to be checked
#Write-Host "Start Checking MangaHere" -BackgroundColor Gray
[String] $source = "http://www.mangahere.co/manga/"
Get-ChildItem -Directory -Path $mangaFolder | Foreach { checkNameMangaHere $_.FullName $_.Name }
#Write-Host "Done" -BackgroundColor Gray
#Write-Host ""

# MangaFox to be checked
#Write-Host "Start Checking MangaFox" -BackgroundColor Gray
$source = "http://mangafox.me/manga/"
Get-ChildItem -Directory -Path $mangaFolder | Foreach { checkNameMangaFox $_.FullName $_.Name }
#Write-Host "Done" -BackgroundColor Gray
#Write-Host ""

# MangaReader to be checked
#Write-Host "Start Checking MangaReader" -BackgroundColor Gray
$source = "http://www.mangareader.net"
Get-ChildItem -Directory -Path $mangaFolder | Foreach { checkNameMangaReader $_.FullName $_.Name }
#Write-Host "Done" -BackgroundColor Gray
#Write-Host ""

# Bato.to to be checked
#Write-Host "Start Checking Bato [$langBato] " -BackgroundColor Gray
$source = "http://bato.to"
Get-ChildItem -Directory -Path $mangaFolder | Foreach { checkNameBato $_.FullName $_.Name }
#Write-Host "Done" -BackgroundColor Gray
#Write-Host ""

# Remove folders from sync folder with no updates
if ($syncFolder)
{
    Get-ChildItem -Directory -Path $syncFolder\* | Foreach { if ( (Get-ChildItem -Directory -Path $_.FullName).Count -eq 0) { Remove-Item -Path $_.FullName} }
}
#Write-Host "All Done!"
# remove the two lines below if this script runs as scheduled task!
#Write-Host "Press any key to close the window"
#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")