# this script is a development helper for copying files over from adrian's laptop

Set-Location $PSScriptRoot


$source = "C:\Users\adrian\My Code\commit-hooktest"
$target = "\\ott-proto1\c$\AppDir2"

try {

    if ($env:computername -ne 'XPS8700') {
        Throw "This script is not usable on this computer"
    }

    if (-not (Test-Path -Path $Target -PathType Container)) {
        Throw "Target Path '$target' NOT accessible!"
    }

    $source0 = Get-ChildItem -Recurse -Path $source -File
    $target0 = Get-ChildItem -Recurse -Path $target -File

    # find files that differ by creation times
    $manifest = Compare-Object -ReferenceObject $source0 -DifferenceObject $target0 -Property "LastWriteTime" -PassThru |

        # ignore files peculiar to workspace
        Where-Object {$_.Name -notin @(".gitignore", "Update-Target.ps1", "Update-ExcludedFiles.txt")} |

        # add relativepath details
        ForEach-Object {

            $relativePath = if ($_.SideIndicator -eq '<=') {
                $_.DirectoryName.Replace($source, '')
            } else {
                $_.DirectoryName.Replace($target, '')
            }

            $_ | Add-Member -NotePropertyName relativePath -NotePropertyValue $relativePath -PassThru

        } |

        # group by relativepath and file name
        Group-Object -Property relativePath, Name |
        ForEach-Object {

            $source1 = $_.Group | Where-Object { $_.SideIndicator -eq '<='}
            $target1 = $_.Group | Where-Object { $_.SideIndicator -eq '=>'}
    
            [PSCustomObject]@{
                Source = $source1
                Target = $target1
                TargetIsNewer = ($source1.LastWriteTime -lt $target1.LastWriteTime)
                TargetIsForeign = ($source1 -eq $Null)
            }
            
        }

    if ($foreign = $manifest | Where-Object {$_.TargetIsNewer -or $_.TargetIsForeign}) {
      
        # show a table
        Write-Host "Found Foreign target changes or files" -ForegroundColor Yellow
        $foreign | Select-Object `
            @{
                Name='SourceFullName'
                Expression = {$_.Source.FullName}
            },
            @{
                Name='SourceCreated'
                Expression = {$_.Source.LastWriteTime}
            },
            @{
                Name='TargetFullName'
                Expression = {$_.Target.FullName}
            },
            @{
                Name='TargetCreated'
                Expression = {$_.Target.LastWriteTime}
            },
            TargetIsNewer, TargetIsForeign | Format-Table

         # copy files from target to source
        if ((Read-Host "Copy these foreign files here to Source? (y/N)").toUpper() -eq 'Y') {
            $foreign | ForEach-Object {
                Copy-Item -Path $_.Target.FullName -Destination "$source$($_.Target.relativePath)" -Force -Verbose
            }
        }

    }
    
    if ($manifest | Where-Object { !$_.TargetIsNewer -and !$_.TargetIsForeign}) {   

        # copy files from source to target
        Write-Host "Copying Source changes or files" -ForegroundColor Cyan
        $manifest | ForEach-Object {

            Copy-Item -Path $_.Source.FullName -Destination "$target$($_.Source.relativePath)" -Force -Verbose
        }
    } else {

        Write-Host "No changes made" -ForegroundColor Cyan
    }
}

catch {
    Write-Host $PSItem.toString() -ForegroundColor Red
}