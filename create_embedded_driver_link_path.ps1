# This script creates a symlink between the drivers directory in PowerBI and the SDK location. It
# is required for embedded driver development, as this connector piggybacks off the Microsoft OEM
# Simba driver. Without this symlink tests will not run. Make sure that the below version number
# in the SDK path matches the installed version.

# Parameters for version numbers
param (
    [string]$SDKVersion = "0.4.0-win32-arm64",
    [string]$SDKToolsVersion = "2.127.3"
)

# Define paths for source and target directories with parameterised version numbers
$targetPath = "$Env:UserProfile\.vscode\extensions\powerquery.vscode-powerquery-sdk-$SDKVersion\.nuget\Microsoft.PowerQuery.SdkTools.$SDKToolsVersion\tools\ODBC Drivers"
$sourcePath = "$Env:ProgramFiles\Microsoft Power BI Desktop\bin\ODBC Drivers"

# Check if source path exists
if (!(Test-Path -Path $sourcePath)) {
    Write-Output "Source path does not exist: $sourcePath"
    exit
}

# Check if target path already exists
if (Test-Path -Path $targetPath) {
    Write-Output "Target path already exists: $targetPath"
} else {
    # Create the symbolic link
    New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force
    Write-Output "Symbolic link created from '$targetPath' to '$sourcePath'"
}
