function Convert-WindowsPath {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$Path
    )
    process {
        return $Path -replace '\\', '/'
    }
}

# Create alias for easy use
Set-Alias -Name cvpath -Value Convert-WindowsPath
