if (Get-Module 'posh-cargo') { return }



function Get-AliasPattern($exe) {
   $aliases = @($exe) + @(Get-Alias | Where-Object { $_.Definition -eq $exe } | Select-Object -Exp Name)
   "($($aliases -join '|'))"
}

function get_manifest() {
    $manifest = (cargo metadata --format-version 1 --no-deps --quiet 2> $null)
    if (!$manifest -and $Global:Error.Count -ne 0) {
        $Global:Error.RemoveAt(0)
    }
    return $manifest
}

function get_manifest_path() {
    $proj = (cargo locate-project 2> $null) |
        Select-Object -First 1 | ForEach-Object {
        $_.SubString(9, $_.Length - 11) -replace '\\\\', '\'
    }
    if ($proj) {
        return $proj
    }
    elseif ($Global:Error.Count -ne 0) {
        $Global:Error.RemoveAt(0)
    }
    return $null
}

function get_project_directory() {
    $manifest_path = get_manifest_path
    if ($manifest_path) {
        Split-Path -Path $manifest_path
    }
}

function get_target_from_manifest_by_kind() {
    param($kind)
    return get_manifest | ConvertFrom-Json |
        Select-Object -ExpandProperty 'packages' |
        Select-Object -ExpandProperty 'targets' |
        Where-Object { $_.kind -eq $kind } |
        Select-Object -ExpandProperty 'name'
}

function get_package_from_manifest() {
    $packages = get_manifest | ConvertFrom-Json | Select-Object -ExpandProperty 'packages'
    $packages | Select-Object -ExpandProperty 'name'
    $packages | Select-Object -ExpandProperty 'dependencies' | Select-Object -ExpandProperty 'name'
}

function get_feature_from_manifest() {
    $manifest = get_manifest | ConvertFrom-Json
    $packages = ($manifest | Select-Object -ExpandProperty packages)

    $packages | Select-Object -ExpandProperty features | ForEach-Object {
        $_.PSObject.Properties.Name
        $_.PSObject.Properties.Value
    }

    $packages | Select-Object -ExpandProperty 'dependencies' | Select-Object -ExpandProperty 'name'
}

function get_cargo_commands() {
    return (cargo --list 2> $null) | Select-Object -Skip 1 | ForEach-Object {
        $_.Trim() -match '^\S+' > $null
        $Matches[0]
    }
}

function get_available_target_triples($toolchain) {
    $pattern = '(\s\(default\)|\s\(installed\))$'
    $targets = @()
    if ($toolchain) {
        $targets = $(rustup target list --toolchain $toolchain)
    }
    else {
        $targets = $(rustup target list)
    }

    return $targets | Where-Object { $_ -match $pattern } | ForEach-Object { $_ -replace $pattern, '' }
}

function get_toolchain_path($toolchain) {
    $rustc_path = ''
    if ($toolchain) {
        $rustc_path = $(rustup run $toolchain rustup which rustc)
    }
    else {
        $rustc_path = $(rustup which rustc)
    }
    return Resolve-Path ((Split-Path $rustc_path) + '\..')
}

function get_rustc_errorcode_list($toolchain) {
    $toolchain_path = (get_toolchain_path $toolchain)
    $doc_path = Join-Path $toolchain_path 'share\doc\rust\html\error-index.html'
    Get-Content $doc_path | Where-Object {
        $_ -match 'error-described error-used\"><h2 id=\"(\S+)\"'
    } | ForEach-Object { $Matches[1] }
}

function get_available_toolchains() {
    $toolchain_list = (rustup toolchain list | ForEach-Object{
        $i = $_.IndexOf(' ')
        if ($i -ge 0) {
            $_.SubString(0, $i)
        } else {
            $_
        }
    })

    $toolchain_list
    $toolchain_list | ForEach-Object {
        $t = $_ -split '-'
        $t[0]
        $t[0] + '-' + $t[4]
    }
}

function get_installed_packages() {
    return (
        cargo install --list | Where-Object {
            $_ -match '^(\S+)\s+\S+:$'
        } | ForEach-Object{ $Matches[1] }
    )
}



$vcs = @('git', 'hg', 'pijul', 'none')
$color = @('auto', 'always', 'never')
$msg_format = @('human', 'json')

$opt_help = @('-h', '--help')
$opt_verbose = @('-v', '--verbose')
$opt_very_verbose = @($opt_verbose + @('-vv'))
$opt_quiet = @('-q', '--quiet')
$opt_color = @('--color')
$opt_common = @($opt_help + $opt_very_verbose + $opt_quiet + $opt_color)
$opt_pkg = @('-p', '--package')
$opt_feat = @('--features', '--all-features', '--no-default-features')
$opt_mani = @('--manifest-path')
$opt_jobs = @('-j', '--jobs')
$opt_force = @('-f', '--force')
$opt_lock = @('--frozen', '--locked')
$opt_bin = @('--bin', '--bins')
$opt_example = @('--example', '--examples')
$opt_test = @('--test', '--tests', '--bench', '--benches')
$opt_bin_types = @($opt_bin + $opt_example + $opt_test)
$opt_exclude = @('--all', '--exclude')
$opt_version = @('-V', '--version')
$opt__fetch = @($opt_common + $opt_mani + $opt_lock)

$opt___nocmd = $opt_common + $opt_version + @('--list', '--explain')
$opt___commands = @(
    @('bench', @($opt_common + $opt_pkg + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + $opt_bin_types + $opt_exclude + @('--message-format', '--target', '--lib', '--no-run', '--no-fail-fast'))),
    @('benchcmp', @($opt_help + $opt_color + @('--version', '--include-missing', '--threshold', '--varience', '--improvements', '--regressions'))),
    @('build', @($opt_common + $opt_pkg + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + $opt_bin_types + $opt_exclude + @('--message-format', '--target', '--lib', '--release'))),
    @('check', @($opt_common + $opt_pkg + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + $opt_bin_types + $opt_exclude + @('--message-format', '--target', '--lib', '--release'))),
    @('clean', @($opt_common + $opt_pkg + $opt_mani + $opt_lock + @('--target', '--release'))),
    @('doc', @($opt_common + $opt_pkg + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + $opt_bin + @('--all', '--message-format', '--lib', '--target', '--open', '--no-deps', '--release'))),
    @('expand', @($opt_common + $opt_pkg + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + $opt_bin_types + @('--message-format', '--profile', '--target', '--lib', '--release'))),
    @('fetch', $opt__fetch),
    @('fmt', @($opt_help + $opt_verbose + $opt_quiet + $opt_pkg + @('--all'))),
    @('generate-lockfile', $opt__fetch),
    @('git-checkout', @($opt_common + $opt_lock + @('--reference', '--url'))),
    @('graph', @($opt_help + $opt_version + @('-I', '--include-versions', '--build-color', '--build-deps', '--build-line-color', '--build-line-style', '--build-shape', '--dev-color', '--dev-deps', '--dev-line-color', '--dev-line-style', '--dev-shape', '--dot-file', '--lock-file', '--manifest-file', '--optional-color', '--optional-deps', '--optional-line-color', '--optional-line-style', '--optional-shape'))),
    @('help', $opt_help),
    @('init', @($opt_common + $opt_lock + @('--bin', '--lib', '--name', '--vcs'))),
    @('install', @($opt_common + $opt_feat + $opt_jobs + $opt_lock + $opt_force + $opt_bin + $opt_example + @('--branch', '--debug', '--git', '--list', '--path', '--rev', '--root', '--tag', '--vers'))),
    @('install-update', @($opt_help + $opt_force + $opt_version + @('-a', '--all', '-i', '--allow-no-update', '-l', '--list', '-c', '--cargo-dir'))),
    @('install-update-config', @($opt_help + $opt_version + @('-c', '--cargo-dir', '-d', '--default-features', '-f', '--feature', '-n', '--no-feature', '-t', '--toolchain'))),
    @('locate-project', @($opt_mani + $opt_help)),
    @('login', @($opt_common + $opt_lock + @('--host'))),
    @('metadata', @($opt_common + $opt_feat + $opt_mani + $opt_lock + @('--format-version', '--no-deps'))),
    @('modules', @($opt_help + $opt_version + @('-b', '--bin', '-l', '--lib', '-o', '--orphans', '-p', '--plain'))),
    @('new', @($opt_common + $opt_lock + @('--vcs', '--bin', '--lib', '--name'))),
    @('outdated', @($opt_help + $opt_verbose + $opt_mani + $opt_pkg + $opt_version + @('-d', '--depth', '--exit-code', '-l', '--lockfile-path', '-m', '-R', '--root-deps-only'))),
    @('owner', @($opt_common + $opt_lock + @('-a', '--add', '-r', '--remove', '-l', '--list', '--index', '--token'))),
    @('package', @($opt_common + $opt_mani + $opt_lock + $opt_jobs + @('--allow-dirty', '-l', '--list', '--no-verify', '--no-metadata'))),
    @('pkgid', @($opt__fetch + $opt_pkg)),
    @('publish', @($opt_common + $opt_mani + $opt_lock + $opt_jobs + @('--allow-dirty', '--dry-run', '--host', '--token', '--no-verify'))),
    @('read-manifest', @($opt_help + $opt_very_verbose + $opt_mani + $opt_color + @('--no-deps'))),
    @('run', @($opt_common + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + @('--bin', '--example', '--message-format', '--target', '--release'))),
    @('rustc', @($opt_common + $opt_pkg + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + $opt_bin_types + @('--message-format', '--profile', '--target', '--lib', '--release'))),
    @('rustdoc', @($opt_common + $opt_pkg + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + $opt_bin_types + @('--message-format', '--target', '--lib', '--release', '--open'))),
    @('search', @($opt_common + $opt_lock + @('--host', '--limit'))),
    @('test', @($opt_common + $opt_pkg + $opt_feat + $opt_mani + $opt_lock + $opt_jobs + $opt_bin_types + $opt_exclude + @('--message-format', '--doc', '--target', '--lib', '--no-run', '--release', '--no-fail-fast'))),
    @('tree', @($opt_help + $opt_verbose + $opt_quiet + $opt_color + $opt_pkg + $opt_feat + $opt_lock + $opt_mani + $opt_version + @('-a', '--all', '--charset', '-d', '--duplicates', '-f', '--format', '-i', '--invert', '-k', '--kind', '--no-indent', '--target'))),
    @('uninstall', @($opt_common + $opt_lock + @('--bin', '--root'))),
    @('update', @($opt_common + $opt_pkg + $opt_mani + $opt_lock + @('--aggressive', '--precise'))),
    @('verify-project', @($opt__fetch)),
    @('version', @($opt_help + $opt_very_verbose + $opt_color)),
    @('yank', @($opt_common + $opt_lock + @('--vers', '--undo', '--index', '--token')))
)

function parse_commands ($parameters) {
    if ($parameters -match "^(?<firstToken>\S+)\s+(\S+\s+)*(?<lastToken>\S*)\s*$") {
        $opt___commands | Where-Object {
            $_[0].Equals($Matches['firstToken'])
        } | Select-Object -First 1 | ForEach-Object {
            $command = $_[0]
            $completionList = $_[1]
            $wordToComplete = $Matches['lastToken']
            return @($command, $completionList, $wordToComplete)
        }
    }
}

function CargoTabExpansion($lastBlock) {
    $toolchain = ''
    $parameters = ($lastBlock -replace "^$(Get-AliasPattern cargo)(\.exe)?\s+","")
    if ($parameters -and $parameters[0] -eq '+') {
        $i = $parameters.IndexOf(' ')
        if ($i -gt 0) {
            $toolchain = $parameters.SubString(1, $i - 1)
            $parameters = $parameters.SubString($i).TrimStart()
        }
    }

    $parsed = (parse_commands $parameters)
    if ($parsed.Length -eq 3) {
        $command = $parsed[0]
        $completionList = $parsed[1]
        $wordToComplete = $parsed[2]
    }

    if ($command) {
        $other_command_specific = $false
        if ($command -eq 'help') {
            $completionList = $completionList + (get_cargo_commands)
        }
        elseif ($parameters -match '\s+(?<lastOption>\-\S+)\s+(?<lastToken>\S*)$') {
            $lastOption = $Matches['lastOption']
            $lastToken = $Matches['lastToken']
            switch -regex ($lastOption) {
                '^\-\-color$' {
                    $completionList = $color
                }
                '^\-\-message-format$' {
                    $completionList = $msg_format
                }
                '^\-\-vcs$' {
                    $completionList = $vcs
                }
                '^\-\-target$' {
                    $completionList = (get_available_target_triples $toolchain)
                }
                '^(\-\-bin|\-\-test|\-\-example|\-\-bench)$' {
                    $kind = $lastOption.SubString(2)
                    if (!(($kind -eq 'bin') -and
                        ($command -eq 'init' -or $command -eq 'new'))) {

                        $possibleList = get_target_from_manifest_by_kind $kind
                        if (!$possibleList) {
                            $possibleList = @('<NAME>')
                        }

                        $wordToComplete = $lastToken
                        $completionList = $possibleList
                    }
                }
                '^(\-p|\-\-package|\-\-exclude)$' {
                    $possibleList = (get_package_from_manifest)

                    if (!$possibleList) {
                        $possibleList = @('<SPEC>')
                    }

                    $wordToComplete = $lastToken
                    $completionList = $possibleList
                }
                '^\-\-features$' {
                    $possibleList = (get_feature_from_manifest)

                    if (!$possibleList) {
                        $possibleList = @('<FEATURE>')
                    }

                    $wordToComplete = $lastToken
                    $completionList = $possibleList
                }
                '^(\-t|\-\-toolchain)$' {
                    $completionList = (get_available_toolchains)
                }
                '^(\-t|\-\-manifest-path)$' {
                    $completionList = @()
                }
                default {
                    $other_command_specific = $true
                }
            }
        }
        else {
            $other_command_specific = $true
        }

        if ($other_command_specific) {
            if ($command -eq 'pkgid') {
                $completionList = $completionList + (get_package_from_manifest)
            }
            elseif ($command -eq 'uninstall' -or
                $command -eq 'install-update' -or
                $command -eq 'install-update-config') {
                $installed_packages = (get_installed_packages)
                $completionList = $completionList + $installed_packages
            }
            elseif ($command -eq 'graph') {
                if ($parameters -match '\s+(?<lastOption>\-\S+)\s+(?<lastToken>\S*)$') {
                    $lastOption = $Matches['lastOption']
                    switch -regex ($lastOption) {
                        '^\-\-\S+\-color$' {
                            $completionList = @('blue', 'black', 'yellow', 'purple', 'green', 'red', 'white', 'orange')
                        }
                        '^\-\-\S+\-style$' {
                            $completionList = @('solid', 'dotted', 'dashed')
                        }
                        '^\-\-\S+\-shape$' {
                            $completionList = @('box', 'round', 'diamond', 'triangle')
                        }
                        '^\-\-\S+\-deps$' {
                            $completionList = @('true', 'false')
                        }
                        '^\-\-\S+\-file$' {
                            $completionList = @()
                        }
                    }
                }
            }
            elseif ($command -eq 'modules') {
                if ($parameters -match '\s+(?<lastOption>\-\S+)\s+(?<lastToken>\S*)$') {
                    $lastOption = $Matches['lastOption']
                    switch -regex ($lastOption) {
                        '^\-b$' {
                            $possibleList = get_target_from_manifest_by_kind 'bin'
                            if (!$possibleList) {
                                $possibleList = @('<NAME>')
                            }

                            $wordToComplete = $lastToken
                            $completionList = $possibleList
                        }
                    }
                }
            }
            elseif ($command -eq 'outdated') {
                if ($parameters -match '\s+(?<lastOption>\-\S+)\s+(?<lastToken>\S*)$') {
                    $lastOption = $Matches['lastOption']
                    switch -regex ($lastOption) {
                        '^\-(d|\-\depth|\-exit-code)$' {
                            $completionList = @(0.. 9) + @('<NUM>')
                        }
                        '^\-\-\S+\-path$' {
                            $completionList = @()
                        }
                    }
                }
            }
            elseif ($command -eq 'tree') {
                if ($parameters -match '\s+(?<lastOption>\-\S+)\s+(?<lastToken>\S*)$') {
                    $lastOption = $Matches['lastOption']
                    switch -regex ($lastOption) {
                        '^(\-k|\-\-kind)$' {
                            $completionList = @('normal', 'dev', 'build')
                        }
                        '^\-\-charset$' {
                            $completionList = @('utf8', 'ascii')
                        }
                        '^(\-f|\-\-format)$' {
                            $completionList = @('<FORMAT>', '""')
                        }
                    }
                }
            }
        }
    }
    else {
        $wordToComplete = $parameters
        $completionList = $opt___nocmd + (get_cargo_commands)
        
        if (!$toolchain) {
            $completionList += get_available_toolchains | ForEach-Object { '+' + $_ }
        }

        if ($parameters -match '(^|\s+)(?<lastOption>\-\S+)\s+(?<lastToken>\S*)$') {
            $lastToken = $Matches['lastToken']
            $lastOption = $Matches['lastOption']
            switch -regex ($lastOption) {
                '^\-\-color$' {
                    $wordToComplete = $lastToken
                    $completionList = $color
                }
                '^\-\-explain$' {
                    $wordToComplete = $lastToken
                    $completionList = (get_rustc_errorcode_list $toolchain)
                    if (!$completionList) {
                        $completionList = @('<CODE>')
                    }
                }
            }
        }
    }

    $finalCandidates = $completionList | Where-Object { $_ -like "${wordToComplete}*" } | Sort-Object -CaseSensitive -Unique

    $finalCandidates | Where-Object { $_[0] -ne '-' -and $_[0] -ne '+' }
    $finalCandidates | Where-Object { $_[0] -eq '-' -and $_.Length -gt 1 -and $_[1] -ne '-' }
    $finalCandidates | Where-Object { $_[0] -eq '-' -and $_.Length -gt 1 -and $_[1] -eq '-' }
    $finalCandidates | Where-Object { $_[0] -eq '+' }
}



$PowerTab_RegisterTabExpansion = if (Get-Module -Name powertab) { Get-Command Register-TabExpansion -Module powertab -ErrorAction SilentlyContinue }
if ($PowerTab_RegisterTabExpansion)
{
  & $PowerTab_RegisterTabExpansion "cargo" -Type Command {
    param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)  # 1:

    $line = $Context.Line
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()
    $TabExpansionHasOutput.Value = $true
    CargoTabExpansion $lastBlock
  }

  return
}

if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion TabExpansionBackup
}

function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    switch -regex ($lastBlock) {
        # Execute cargo tab completion for all cargo-related commands
        "^$(Get-AliasPattern cargo)(\.exe)? (.*)" {
            CargoTabExpansion $lastBlock
        }

        # Fall back on existing tab expansion
        default { if (Test-Path Function:\TabExpansionBackup) { TabExpansionBackup $line $lastWord } }
    }
}



Export-ModuleMember -Function 'TabExpansion'
