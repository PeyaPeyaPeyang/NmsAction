#!/bin/sh

download_build_tools() {
    # Download BuildTools.jar
    wget -O BuildTools.jar "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download BuildTools.jar for version $version"
        return 1
    fi
}

 get_arch() {
     jvm_dir="/usr/lib/jvm/"

     # パターンに一致するファイルが存在するかチェック
     files=$(ls -d "$jvm_dir"java-[0-9]*-openjdk-* 2>/dev/null)
     if [ -z "$files" ]; then
         echo "No OpenJDK installation found in $jvm_dir" >&2
         return 1
     fi

     # パターンに一致するファイル名を取得し、パターンに一致する部分を抽出して出力
     for file in $files; do
         if echo "$file" | grep -qE "java-[0-9]+-openjdk-[^-]+$"; then
             arch=$(basename "$file" | sed -E "s/.*java-[0-9]+-openjdk-([^-]+)$/\1/")
             echo "$arch"
             return 0
         fi
     done

     return 1
 }


# Function to install dependencies
build_one_nms() {
    cpu_arch_type=$(get_arch)
    version=$1
    # Determine Java version based on provided Minecraft version
    case $version in
        1.17 | 1.16* | 1.15* | 1.14* | 1.13* | 1.12* | 1.11* | 1.10* | 1.9* | 1.8*)
            echo "Using java8"
            export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-$cpu_arch_type
            ;;
        *)
            echo "Using java17"
            export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-$cpu_arch_type
            ;;
    esac

    # Set the JAVA_EXE variable
    JAVA_EXE="$JAVA_HOME/bin/java"

    echo "Using java: $JAVA_HOME"
    echo "Using Java executable: $JAVA_EXE"

    # Run BuildTools.jar with the specified version
    "$JAVA_EXE" -jar BuildTools.jar --rev "$version"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build version $version"
        return 1
    fi
}

# Check if versions are provided as arguments
if [ "$#" -eq 0 ]; then
    echo "No versions provided. Please provide versions as comma-separated list."
    exit 1
fi

# Join the comma-separated list into a space-separated list
version_list=$(echo "$*" | tr ',' ' ')

# Create directory for build
mkdir -p "nms-build"
cd "nms-build" || exit 1

# Download BuildTools.jar
download_build_tools || exit 1

# Iterate through provided versions
for version in $version_list; do
    build_one_nms "$version" || exit 1
done

# Install to github .m2
mkdir -p .m2/repository
if [ $? -ne 0 ]; then
    echo "Error: Failed to create .m2/repository directory"
    exit 1
fi

# Deploy to local
cp -r /root/.m2/repository .m2/repository || exit 1
