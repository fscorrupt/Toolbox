################
# CONFIG START #
################

$ExportPath = "C:\Temp\"

# Radarr
$RadarrURL = ""
$RadarrApiKey = ""

# Sonarr
$SonarrURL = ""
$SonarrApiKey = ""

##############
# CONFIG END #
##############

<############################################################
    Do NOT edit lines below unless you know what you are doing!
############################################################>

###############
# RADARR PART #
###############
if ($RadarrURL -and $RadarrApiKey){
    # Get Radarr Data
    $RadarrData = Invoke-RestMethod -Method Get -Uri "$RadarrURL/api/v3/movie/?apikey=$RadarrApiKey"

    $ResultRadarr = @()
    foreach ($Item in $RadarrData ){
        if ($item.hasFile -eq "true"){
            $temp = New-Object psobject
            $temp | Add-Member -MemberType NoteProperty -Name "audioChannels" -Value $Item.movieFile.mediaInfo.audioChannels
            $temp | Add-Member -MemberType NoteProperty -Name "audioCodec" -Value $Item.movieFile.mediaInfo.audioCodec
            $temp | Add-Member -MemberType NoteProperty -Name "audioLanguages" -Value $Item.movieFile.mediaInfo.audioLanguages
            $temp | Add-Member -MemberType NoteProperty -Name "videoCodec" -Value $Item.movieFile.mediaInfo.videoCodec
            $temp | Add-Member -MemberType NoteProperty -Name "resolution" -Value $Item.movieFile.mediaInfo.resolution
            $temp | Add-Member -MemberType NoteProperty -Name "releaseGroup" -Value $(if ($Item.movieFile.releaseGroup){$Item.movieFile.releaseGroup} Else {$Item.statistics.releaseGroups})
            $ResultRadarr += $temp
        }
    }

    # Group and count unique entries in $ResultRadarr
    $RadarrGroupedResults = @{}

    foreach ($Property in @("audioChannels", "audioCodec", "audioLanguages", "videoCodec", "resolution", "releaseGroup")) {
        $RadarrGroupedResults[$Property] = $ResultRadarr | Group-Object -Property $Property | Sort-Object -Property Count -Descending
    }

    # Print results in a tabular format
    foreach ($Property in $RadarrGroupedResults.Keys) {
        Write-Host "`n--- $Property Statistics ---`n" -ForegroundColor Cyan

        $TableData = $RadarrGroupedResults[$Property] | ForEach-Object {
            [PSCustomObject]@{
                Value = $_.Name
                Count = $_.Count
            }
        }
        $PathBuilder = if ($ExportPath.EndsWith("\")){$ExportPath+"Radarr_"+ $Property+".txt"}Else{$ExportPath+"\Radarr_"+ $Property+".txt"}

        $TableData | Format-Table -AutoSize
        $TableData | Out-File $PathBuilder -Force
    }
}

###############
# SONARR PART #
###############
if ($SonarrURL -and $SonarrApiKey){

    # Get All Series
    $SeriesList = Invoke-RestMethod -Uri "$SonarrURL/api/v3/series?apikey=$SonarrApiKey" -Method Get

    # Fetch Episodes and Episode Files
    $ResultSonarr = @()
    foreach ($Series in $SeriesList) {
        $Episodes = Invoke-RestMethod -Uri "$SonarrURL/api/v3/episode?seriesId=$($Series.id)&apikey=$SonarrApiKey" -Method Get

        foreach ($Episode in $Episodes) {
            # Fetch episode file details if an episodeFileId exists
            if ($null -ne $Episode.episodeFileId -and $Episode.hasFile -eq "True") {
                $EpisodeFile = Invoke-RestMethod -Uri "$SonarrURL/api/v3/episodeFile/$($Episode.episodeFileId)?apikey=$SonarrApiKey" -Method Get

                # Extract file details
                $AudioChannels = $EpisodeFile.mediaInfo.audioChannels
                $AudioCodec = $EpisodeFile.mediaInfo.audioCodec
                $AudioLanguages = $EpisodeFile.mediaInfo.audioLanguages
                $VideoCodec = $EpisodeFile.mediaInfo.videoCodec
                $Resolution = $EpisodeFile.mediaInfo.resolution
                $ReleaseGroup = $EpisodeFile.releaseGroup
            }

            # Add episode details
            $ResultSonarr += [PSCustomObject]@{
                AudioChannels   = $AudioChannels
                AudioCodec      = $AudioCodec
                AudioLanguages  = $AudioLanguages
                VideoCodec      = $VideoCodec
                Resolution      = $Resolution
                ReleaseGroup    = $ReleaseGroup
            }
        }
    }


    # Group and count unique entries in $ResultSonarr
    $SonarrGroupedResults = @{}

    foreach ($Property in @("audioChannels", "audioCodec", "audioLanguages", "videoCodec", "resolution", "releaseGroup")) {
        $SonarrGroupedResults[$Property] = $ResultSonarr | Group-Object -Property $Property | Sort-Object -Property Count -Descending
    }

    # Print results in a tabular format
    foreach ($Property in $SonarrGroupedResults.Keys) {
        Write-Host "`n--- $Property Statistics ---`n" -ForegroundColor Cyan

        $TableData = $SonarrGroupedResults[$Property] | ForEach-Object {
            [PSCustomObject]@{
                Value = $_.Name
                Count = $_.Count
            }
        }
        $PathBuilder = if ($ExportPath.EndsWith("\")){$ExportPath+"Sonarr_"+ $Property+".txt"}Else{$ExportPath+"\Sonarr_"+ $Property+".txt"}

        $TableData | Format-Table -AutoSize
        $TableData | Out-File $PathBuilder -Force
    }
}
