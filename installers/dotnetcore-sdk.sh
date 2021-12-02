#!/bin/bash -e
################################################################################
##  File:  dotnetcore-sdk.sh
##  Desc:  Installs .NET Core SDK
################################################################################

source $HELPER_SCRIPTS/etc-environment.sh
source $HELPER_SCRIPTS/install.sh
source $HELPER_SCRIPTS/os.sh

# Ubuntu 20 doesn't support EOL versions
LATEST_DOTNET_PACKAGES=$(get_toolset_value '.dotnet.aptPackages[]')
DOTNET_VERSIONS=$(get_toolset_value '.dotnet.versions[]')

# Disable telemetry
export DOTNET_CLI_TELEMETRY_OPTOUT=1

for latest_package in ${LATEST_DOTNET_PACKAGES[@]}; do
    echo "Determing if .NET Core ($latest_package) is installed"
    if ! IsPackageInstalled $latest_package; then
        echo "Could not find .NET Core ($latest_package), installing..."
        apt-get install $latest_package -y
    else
        echo ".NET Core ($latest_package) is already installed"
    fi
done

## Get list of all released SDKs from channels which are not end-of-life or preview
#release_urls=("https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/2.1/releases.json" "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/2.2/releases.json" "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/3.0/releases.json" "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/3.1/releases.json")
#sdks=()
#for release_url in ${release_urls[@]}; do
#    echo "${release_url}"
#    releases=$(curl "${release_url}")
#    sdks=("${sdks[@]}" $(echo "${releases}" | jq '.releases[]' | jq '.sdk.version'))
#    sdks=("${sdks[@]}" $(echo "${releases}" | jq '.releases[]' | jq '.sdks[]?' | jq '.version'))
#done

##temporary avoid 3.1.102 installation due to https://github.com/dotnet/aspnetcore/issues/19133
#sortedSdks=$(echo ${sdks[@]} | tr ' ' '\n' | grep -v 3.1.102 | grep -v preview | grep -v rc | grep -v display | cut -d\" -f2 | sort -u -r)
#
#for sdk in $sortedSdks; do
#    url="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$sdk/dotnet-sdk-$sdk-linux-x64.tar.gz"
#    echo "$url" >> urls
#    echo "Adding $url to list to download later"
#done
#
## Download additional SDKs
#echo "Downloading release tarballs..."
#cat urls | xargs -n 1 -P 16 wget -q
#for tarball in *.tar.gz; do
#    dest="./tmp-$(basename -s .tar.gz $tarball)"
#    echo "Extracting $tarball to $dest"
#    mkdir "$dest" && tar -C "$dest" -xzf "$tarball"
#    rsync -qav "$dest/shared/" /usr/share/dotnet/shared/
#    rsync -qav "$dest/host/" /usr/share/dotnet/host/
#    rsync -qav "$dest/sdk/" /usr/share/dotnet/sdk/
#    rm -rf "$dest"
#    rm "$tarball"
#done
#rm urls
#
#DocumentInstalledItem ".NET Core SDK:"
## Smoke test each SDK
#for sdk in $sortedSdks; do
##    mksamples "$sdk" "console"
##    mksamples "$sdk" "mstest"
##    mksamples "$sdk" "xunit"
##    mksamples "$sdk" "web"
##    mksamples "$sdk" "mvc"
##    mksamples "$sdk" "webapi"
#    DocumentInstalledItemIndent "$sdk"
#done
#
## NuGetFallbackFolder at /usr/share/dotnet/sdk/NuGetFallbackFolder is warmed up by smoke test
## Additional FTE will just copy to ~/.dotnet/NuGet which provides no benefit on a fungible machine
#setEtcEnvironmentVariable DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1
#prependEtcEnvironmentPath /home/runner/.dotnet/tools
#echo 'export PATH="$PATH:$HOME/.dotnet/tools"' | tee -a /etc/skel/.bashrc
