# Path to the FFmpeg executable
$ffmpegPath = "C:\ffmpeg\ffmpeg-master-latest-win64-gpl\bin\ffmpeg.exe"

# Directory containing the MP4 files
$directory = "N:\VideoFiles"


if (!(test-path $ffmpegPath -ErrorAction SilentlyContinue)){
    # Download ffmpeg
    $DownloadUrl = "https://objects.githubusercontent.com/github-production-release-asset-2e65be/292087234/734beec5-c46f-4ee0-9db2-0d8c3eb8c812?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20230510%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20230510T124639Z&X-Amz-Expires=300&X-Amz-Signature=d23b250963371ef51ac86a2aeaab97d8c113e25044209a6d04fdf3a3fc32b514&X-Amz-SignedHeaders=host&actor_id=45659314&key_id=0&repo_id=292087234&response-content-disposition=attachment%3B%20filename%3Dffmpeg-master-latest-win64-gpl.zip&response-content-type=application%2Foctet-stream"
    $ZipPath = "C:\ffmpeg\ffmpeg.zip"

    # Create the output directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path "C:\ffmpeg" | Out-Null

    # Create a WebClient object
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($DownloadUrl, $ZipPath)

    Expand-Archive $ZipPath "C:\ffmpeg"
}

# Get all MP4 files in the directory
$mp4Files = Get-ChildItem -Path $directory -Filter "*.mp4" -File

# Iterate through each MP4 file
foreach ($file in $mp4Files) {
    # Create a temporary file name for the modified MP4
    $outputFile = Join-Path -Path $directory -ChildPath ("temp_" + $file.Name)

    # Execute FFmpeg to change the audio language
    $arguments = "-i `"$($file.FullName)`" -c copy -metadata:s:a:0 language=ger `"$outputFile`""
    Start-Process -FilePath $ffmpegPath -ArgumentList $arguments -Wait -NoNewWindow

    # Replace the original MP4 file with the modified version
    Remove-Item -Path $file.FullName
    Move-Item -Path $outputFile -Destination $file.FullName
}
