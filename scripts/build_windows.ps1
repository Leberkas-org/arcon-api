param(
    [switch]$Build
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$imageExists = docker images -q arcon-api-build 2>$null
if ($Build -or -not $imageExists) {
    Write-Host "Building Docker image..."
    docker build -t arcon-api-build $root
}

docker run --rm -v "${root}/src:/api/src" -v "${root}/build:/api/build" arcon-api-build
