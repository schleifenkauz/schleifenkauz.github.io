#!/usr/bin/env bash
set -euo pipefail

if ! command -v unzip >/dev/null 2>&1; then
    echo "Error: unzip is required but not installed. To install execute 'sudo apt install unzip' and rerun this script"
    exit 1
fi

# --- Helper functions ---

download_file() {
    local url="$1"
    local output="$2"
    local name="$3"
    echo "Downloading $name ..."
    if curl -L -o "$output" "$url"; then
        echo "Downloaded to $output"
    else
        echo "Failed to download $name" >&2
        exit 1
    fi
}

extract_zip() {
    local zip="$1"
    local dest="$2"
    echo "Extracting $zip ..."
    if unzip -o "$zip" -d "$dest" > /dev/null; then
        echo "Extracted to $dest"
    else
        echo "Failed to extract $zip" >&2
        exit 1
    fi
}

# --- Ponticello version ---
defaultPonticelloVersion="0.2.2"
read -rp "Enter Ponticello version (default=$defaultPonticelloVersion): " ponticelloVersion
ponticelloVersion="${ponticelloVersion:-$defaultPonticelloVersion}"

# --- Ponticello home directory ---
defaultHomeDir="$HOME/ponticello"
read -rp "Enter the Ponticello home directory (default=$defaultHomeDir): " homeDir
homeDir="${homeDir:-$defaultHomeDir}"
export PONTICELLO_HOME="$homeDir"

mkdir -p "$homeDir/lib"

# --- Detect Java version ---
javaVersion=null
if command -v java >/dev/null 2>&1; then
    versionStr=$(java -version 2>&1 | head -n1)
    if [[ $versionStr =~ \"([0-9]+)\. ]]; then
        javaVersion="${BASH_REMATCH[1]}"
    elif [[ $versionStr =~ \"([0-9]+)\" ]]; then
        javaVersion="${BASH_REMATCH[1]}"
    fi
    echo "Detected Java version $javaVersion."
    if (( javaVersion <= 19 )); then
        echo "Java version is incompatible."
        javaVersion=null
    fi
else
    echo "Java is not installed or not on the PATH."
fi

# --- Prompt user for JRE option ---
echo "Options:"
if [[ $javaVersion == null ]]; then
    echo "1) Specify path to JRE"
    echo "2) Install Java locally"
    echo "3) Abort installation"
else
    echo "1) Use Java from PATH"
    echo "2) Install Java automatically"
fi
read -rp "Choose option (default=1): " option
option="${option:-1}"

jdkDir="$homeDir/lib/jdk"
mkdir -p "$(dirname "$jdkDir")"

if [[ "$option" == "1" ]]; then
    if [[ $javaVersion == null ]]; then
        read -rp "Path to Java Runtime Environment: " jrePath
        if [[ ! -d "$jrePath" ]]; then
            echo "Invalid path" >&2
            exit 1
        fi
    else
        jrePath=$(dirname "$(dirname "$(command -v java)")")
    fi
    ln -sfn "$jrePath" "$jdkDir"
    echo "Link created: $jdkDir -> $jrePath"
elif [[ "$option" == "2" ]]; then
    os=$(uname -s)
    arch=$(uname -m) 

    if [[ "$os" == "Darwin" ]]; then
        os="macos"
    elif [[ "$os" == *nux* ]]; then
        os="linux"
    else 
        echo "Unsupported OS: $os"
        exit 1
    fi

    if [[ $arch == "x86_64" ]]; then
        arch="x64"
    fi

    jreUrl="https://download.oracle.com/java/24/latest/jdk-24_$os-${arch}_bin.tar.gz"
    jreTar="$homeDir/jre.tar.gz"
    download_file "$jreUrl" "$jreTar" "Java Runtime Environment"
    tar -xzf "$jreTar" -C "$homeDir/lib"
    extractedDir=$(find "$homeDir/lib" -maxdepth 1 -type d -name "jdk-*" | head -n1)
    mv "$extractedDir" "$jdkDir"
    rm -f "$jreTar"
elif [[ "$option" == "3" ]]; then
    echo "Installation aborted."
    exit 0
fi

# --- Download and extract JavaFX SDK ---
javafxUrl="https://download2.gluonhq.com/openjfx/21.0.8/openjfx-21.0.8_$os-x64_bin-sdk.zip"
javafxZip="$homeDir/javafx-sdk.zip"
download_file "$javafxUrl" "$javafxZip" "JavaFX SDK"
extract_zip "$javafxZip" "$homeDir/lib"
mv "$homeDir/lib/javafx-sdk-21.0.8" "$homeDir/lib/javafx"
rm -f "$javafxZip"

# --- Download and extract Ponticello ---
ponticelloUrl="https://schleifenkauz.de/software/ponticello-v$ponticelloVersion.zip"
ponticelloZip="$homeDir/ponticello.zip"
download_file "$ponticelloUrl" "$ponticelloZip" "Ponticello"
extract_zip "$ponticelloZip" "$homeDir"
rm -f "$ponticelloZip"

# --- Add scripts to PATH ---
scriptsDir="$homeDir/scripts"
if ! grep -q "$scriptsDir" <<< "$PATH"; then
    echo "export PATH=\"\$PATH:$scriptsDir\"" >> ~/.bashrc
    export PATH="$PATH:$scriptsDir"
    echo "Ponticello scripts added to PATH."
else
    echo "Ponticello scripts already in PATH."
fi

# --- Projects directory ---
defaultProjectsDir="$HOME/compositions"
read -rp "Enter the directory where your Ponticello projects will be located: " projectsDir
projectsDir="${projectsDir:-$defaultProjectsDir}"
mkdir -p "$projectsDir"
export PONTICELLO_PROJECTS="$projectsDir"
echo "export PONTICELLO_PROJECTS='$projectsDir'" >> ~/.bashrc

echo "Ponticello was setup successfully."
echo "You can now run it using 'ponticello <project-name>'"
