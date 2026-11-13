Set-StrictMode -Version 2.0

function Test-BritishLayout {
    param([string]$Value)
    # Standard UK, UK Extended, and aliases such as d0010809.
    return ($Value -match '(?i)(^0809:|:(00000809|00000452)$|^(00000809|00000452|[0-9a-f]{4}0809)$)')
}

function Get-KeyboardLanguagePlan {
    param([Parameter(Mandatory)][object[]]$Languages)
    $result = New-Object 'System.Collections.Generic.List[object]'
    $hasUs = $false
    foreach ($language in $Languages) {
        if ($language.LanguageTag -ieq 'en-US') { $hasUs = $true }
    }
    foreach ($language in $Languages) {
        $tag = [string]$language.LanguageTag
        if ($tag -ieq 'en-GB') {
            if (-not $hasUs) {
                $result.Add([pscustomobject]@{
                    LanguageTag = 'en-US'; InputMethodTips = @('0409:00000409')
                    Handwriting = [bool]$language.Handwriting
                })
                $hasUs = $true
            }
            continue
        }
        $tips = New-Object 'System.Collections.Generic.List[string]'
        if ($tag -ieq 'en-US') {
            $tips.Add('0409:00000409')
        } else {
            foreach ($tip in $language.InputMethodTips) {
                if (-not (Test-BritishLayout ([string]$tip)) -and -not $tips.Contains([string]$tip)) {
                    $tips.Add([string]$tip)
                }
            }
            if ($tips.Count -eq 0 -and @($language.InputMethodTips).Count -gt 0) {
                # A language that only had a UK keyboard keeps a US keyboard.
                $tips.Add('0409:00000409')
            }
        }
        $result.Add([pscustomobject]@{
            LanguageTag = $tag; InputMethodTips = @($tips.ToArray())
            Handwriting = [bool]$language.Handwriting
        })
    }
    if (-not $hasUs) {
        $result.Add([pscustomobject]@{
            LanguageTag = 'en-US'; InputMethodTips = @('0409:00000409'); Handwriting = $false
        })
    }
    return $result.ToArray()
}

function Get-KeyboardRegistryPlan {
    param([object[]]$Preload = @(), [object[]]$Substitutes = @())
    $aliases = @{}
    foreach ($item in $Substitutes) { $aliases[[string]$item.Name] = [string]$item.Value }
    $values = New-Object 'System.Collections.Generic.List[string]'
    $otherValues = New-Object 'System.Collections.Generic.List[object]'
    foreach ($item in @($Preload | Sort-Object { if ($_.Name -match '^\d+$') { [int]$_.Name } else { [int]::MaxValue } })) {
        if ($item.Name -notmatch '^\d+$') { $otherValues.Add($item); continue }
        $value = [string]$item.Value
        $resolved = $value
        $seen = @{}
        while ($aliases.ContainsKey($resolved) -and -not $seen.ContainsKey($resolved)) {
            $seen[$resolved] = $true
            $resolved = $aliases[$resolved]
        }
        if ((Test-BritishLayout $value) -or (Test-BritishLayout $resolved)) { $value = '00000409' }
        if (-not $values.Contains($value)) { $values.Add($value) }
    }
    $cleanPreload = New-Object 'System.Collections.Generic.List[object]'
    for ($index = 0; $index -lt $values.Count; $index++) {
        $cleanPreload.Add([pscustomobject]@{ Name = [string]($index + 1); Value = $values[$index]; Kind = 'String' })
    }
    foreach ($item in $otherValues) { $cleanPreload.Add($item) }
    $cleanSubstitutes = New-Object 'System.Collections.Generic.List[object]'
    foreach ($item in $Substitutes) {
        $resolved = [string]$item.Value
        $seen = @{}
        while ($aliases.ContainsKey($resolved) -and -not $seen.ContainsKey($resolved)) {
            $seen[$resolved] = $true
            $resolved = $aliases[$resolved]
        }
        if (-not (Test-BritishLayout ([string]$item.Name)) -and -not (Test-BritishLayout $resolved)) {
            $cleanSubstitutes.Add($item)
        }
    }
    return [pscustomobject]@{ Preload = @($cleanPreload.ToArray()); Substitutes = @($cleanSubstitutes.ToArray()) }
}

function ConvertTo-KeyboardLanguageSignature {
    param([object[]]$Languages)
    $rows = foreach ($language in $Languages) {
        '{0}|{1}|{2}' -f $language.LanguageTag, (@($language.InputMethodTips) -join ','), [bool]$language.Handwriting
    }
    return ($rows -join ';')
}

Export-ModuleMember -Function Test-BritishLayout, Get-KeyboardLanguagePlan, Get-KeyboardRegistryPlan, ConvertTo-KeyboardLanguageSignature
