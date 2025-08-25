# Prompt the user for a target directory
$homeDir = Read-Host "Enter the Ponticello home directory"
[System.Environment]::SetEnvironmentVariable("PONTICELLO_HOME", $homeDir, "User")

# Create the directory if it doesn't exist
if (-Not (Test-Path -Path $homeDir)) {
    Write-Host "Directory does not exist. Creating it..."
    New-Item -ItemType Directory -Path $homeDir | Out-Null
}

# Function to download a file
function Download-File($url, $output, $name) {
    Write-Host "Downloading $name ..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
        Write-Host "Downloaded to $output"
    } catch {
        Write-Error "Failed to download $name"
        exit
    }
}
# Function to extract a zip file
function Extract-Zip($zipPath, $destination) {
    Write-Host "Extracting $zipPath ..."
    try {
        Expand-Archive -Path $zipPath -DestinationPath $destination -Force
        Write-Host "Extracted to $destination"
    } catch {
        Write-Error "Failed to extract $zipPath"
        exit
    }
}

New-Item -ItemType Directory -Path (Join-Path $homeDir "lib") | Out-Null

# Download and extract JavaFX SDK
$javafxUrl = "https://download2.gluonhq.com/openjfx/21.0.8/openjfx-21.0.8_windows-x64_bin-sdk.zip"
$javafxZip = Join-Path $homeDir "javafx-sdk.zip"
Download-File $javafxUrl $javafxZip "JavaFX SDK"
Extract-Zip $javafxZip (Join-Path $homeDir "lib")
Rename-Item -Path "$homeDir\lib\javafx-sdk-21.0.8" -NewName "javafx"
Remove-Item $javafxZip -Force

try {
    $versionOutput = & java -version 2>&1 | Select-String 'version' | ForEach-Object { $_.ToString() }
    
    # Extract the version number
    if ($versionOutput -match '\"(\d+)\.(\d+).*\"') {
        $javaVersion = [int]$matches[1]
    } elseif ($versionOutput -match '\"(\d+)\"') {
        $javaVersion = [int]$matches[1]
    } else {
        $javaVersion = $null
        Write-Error "Could not parse Java version"
    }
    Write-Host "Detected Java version $javaVersion."

    if (-not $javaVersion -gt 19) {
        Write-Host "Java version is incompatible."
        $javaVersion = $null
    }
} catch {
    Write-Error "Java is not installed or not on the PATH"
    $javaVersion = $null
}

if ($null -eq $javaVersion) {
    Write-Host "1) Specify path to JRE"
    Write-Host "2) Install Java locally"
    Write-Host "3) Abort installation"
} else {
    Write-Host "1) Use Java from the PATH"
    Write-Host "2) Install Java automatically"
}
$option = Read-Host "Choose option: "

$jdkDir = (Join-Path $homeDir "lib\jdk")
if ("1" -eq $option) {
    if ($null -eq $javaVersion) {
        $jdkPath = Read-Host "Path to Java Runtime Environment: "
    } else {
        $jdkPath = (Get-Command java).Source
    }
    New-Item -ItemType Junction -Path $jdkDir -Target $jdkPath
    Write-Host "Linked created: $jdkPath -> $jdkDir"
} elseif ("2" -eq $option) {
    $jreUrl = "https://download.oracle.com/java/24/latest/jdk-24_windows-x64_bin.zip"
    $jreZip = Join-Path $homeDir "jre.zip"
    Download-File $jreUrl $jreZip "Java Runtime Environment"
    Extract-Zip $jreZip (Join-Path $homeDir "lib")
    Rename-Item -Path "$homeDir\lib\jdk-24.0.2" -NewName "jdk"
    Remove-Item $jreZip -Force
}

#Download and extract Ponticello
$ponticelloUrl = "https://schleifenkauz.de/software/ponticello.zip"
$ponticelloZip = Join-Path $homeDir "ponticello.zip"
Download-File $ponticelloUrl $ponticelloZip "Ponticello"
Extract-Zip $ponticelloZip $homeDir
Remove-Item $ponticelloZip -Force

# Add scripts directory to the PATH variable
$dirToAdd = Join-Path $homeDir "scripts"

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath.Split(";") -notcontains $dirToAdd) {
    $newPath = $currentPath + ";" + $dirToAdd
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Ponticello scripts added to user PATH."
} else {
    Write-Host "Ponticello scripts are already in PATH."
}


$projectsDir = Read-Host "Enter the directory where your Ponticello projects will be located: "
[System.Environment]::SetEnvironmentVariable("PONTICELLO_PROJECTS", $projectsDir, "User")

Write-Host "Ponticello was setup succesfully."
Write-Host "You can now run it using 'ponticello.bat <project-name>'"