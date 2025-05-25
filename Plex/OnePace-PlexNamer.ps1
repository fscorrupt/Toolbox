# Edit Vars
$plexServer = "http://192.168.1.93:32400"
$plexToken = "xxxxxxxxxxxxxx"
$ShowRatingKey = "690881"
$AllSeasonsurl = "$plexServer/library/metadata/$ShowRatingKey/children?X-Plex-Token=$plexToken"
$AllSeasons = (Invoke-RestMethod -Uri $AllSeasonsurl).MediaContainer.Directory.Ratingkey
$updateTitle = 'false'
$updateDescription = 'true'
$updateDate = 'true'
$NFORootPath = "C:\temp\OnePace"
###################################

foreach ($Season in $AllSeasons){
    $seasonId = $Season
    $episodesUrl = "$plexServer/library/metadata/$seasonId/children?X-Plex-Token=$plexToken"   
    $episodes = (Invoke-RestMethod -Uri $episodesUrl).MediaContainer.Video
    
    foreach ($episode in $episodes) {
        $episodeNumber = $episode.index
        $seasonNumber = $episode.parentIndex
        $seasonPadded = "{0:D2}" -f [int]$seasonNumber
        $episodePadded = "{0:D2}" -f [int]$episodeNumber
        $nfoFileName = "*S${seasonPadded}E${episodePadded}*.nfo"
        $nfoPath = Join-Path $NFORootPath $nfoFileName

        # Get the first matching NFO file (if any)
        $nfoFile = Get-ChildItem -Path $NFORootPath -Filter $nfoFileName | Select-Object -First 1
        if ($nfoFile) {
            [xml]$nfo = Get-Content $nfoFile.FullName
            if (Test-Path $nfoPath) {
                $updatedFields = @()
                $params = @()
                if ($updateTitle -eq 'true') {
                    $newTitle = $nfo.episodedetails.title
                    $params += "title=$([System.Web.HttpUtility]::UrlEncode($newTitle))"
                    $updatedFields += "Title"
                }
                if ($updateDescription -eq 'true') {
                    $newSummary = $nfo.episodedetails.plot
                    $params += "summary=$([System.Web.HttpUtility]::UrlEncode($newSummary))"
                    $updatedFields += "Summary"
                }
                if ($updateDate -eq 'true') {
                    $newDate = $nfo.episodedetails.premiered
                    $params += "originallyAvailableAt=$([System.Web.HttpUtility]::UrlEncode($newDate))"
                    $updatedFields += "Date"
                }

                if ($params.Count -gt 0) {
                    $queryString = $params -join '&'
                    $updateUrl = "$plexServer/library/metadata/$($episode.ratingKey)?$queryString&X-Plex-Token=$plexToken"
                    Invoke-RestMethod -Uri $updateUrl -Method Put
                    $fieldsString = $updatedFields -join '/'
                    Write-Host "Updated S${seasonPadded}E${episodePadded}: $fieldsString"
                    Start-Sleep 1
                }
            }
        } else {
            Write-Warning "No matching NFO found for pattern: $nfoFileName"
        }
    }    
}
