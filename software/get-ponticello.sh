#!/usr/bin/env bash
set -euo pipefail

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

# --- Prompt for Ponticello home directory ---
read -rp "Enter the Ponticello home directory: " homeDir
export PONTICELLO_HOME="$homeDir"

mkdir -p "$homeDir/lib"

# --- Download and extract JavaFX SDK ---
javafxUrl="https://download2.gluonhq.com/openjfx/21.0.8/openjfx-21.0.8_linux-x64_bin-sdk.zip"
javafxZip="$homeDir/javafx-sdk.zip"
download_file "$javafxUrl" "$javafxZip" "JavaFX SDK"
extract_zip "$javafxZip" "$homeDir/lib"
mv "$homeDir/lib/javafx-sdk-21.0.8" "$homeDir/lib/javafx"
rm -f "$javafxZip"

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
  echo "Java is not installed or not on PATH."
fi

# --- Ask user what to do for JDK/JRE ---
echo "Options:"
if [[ $javaVersion == null ]]; then
  echo "1) Specify path to JRE"
  echo "2) Install Java locally"
  echo "3) Abort installation"
else
  echo "1) Use Java from PATH"
  echo "2) Install Java automatically"
fi
read -rp "Choose option: " option

jdkDir="$homeDir/lib/jdk"
mkdir -p "$(dirname "$jdkDir")"

if [[ "$option" == "1" ]]; then
  if [[ $javaVersion == null ]]; then
    read -rp "Path to existing JRE: " jrePath
    if [[ ! -d "$jrePath" ]]; then
      echo "Invalid path" >&2
      exit 1
    fi
  else
    jrePath=$(dirname "$(command -v java)")
  fi
  # Create a symlink to JRE
  ln -sfn "$jrePath" "$jdkDir"
  echo "Link created: $jdkDir -> $jrePath"
elif [[ "$option" == "2" ]]; then
  jreUrl="https://download.oracle.com/java/24/latest/jdk-24_linux-x64_bin.tar.gz"
  jreTar="$homeDir/jre.tar.gz"
  download_file "$jreUrl" "$jreTar" "Java Runtime Environment"
  mkdir -p "$jdkDir"
  tar -xzf "$jreTar" -C "$homeDir/lib"
  # Assume the extracted folder is named like jdk-24.0.x
  extractedDir=$(find "$homeDir/lib" -maxdepth 1 -type d -name "jdk-*" | head -n1)
  mv "$extractedDir" "$jdkDir"
  rm -f "$jreTar"
fi

# --- Download and extract Ponticello ---
ponticelloUrl="https://schleifenkauz.de/software/ponticello.zip"
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
read -rp "Enter the directory where your Ponticello projects will be located: " projectsDir
export PONTICELLO_PROJECTS="$projectsDir"
echo "export PONTICELLO_PROJECTS=\"$projectsDir\"" >> ~/.bashrc

echo "Ponticello was setup successfully."
echo "You can now run it using 'ponticello <project-name>'"
