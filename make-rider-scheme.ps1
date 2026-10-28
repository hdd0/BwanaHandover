$ErrorActionPreference = 'Stop'

$src      = 'C:\Users\howar\AppData\Local\Temp\opencode\VisualStudioDark.xml'
$cfg      = Join-Path $env:APPDATA 'JetBrains\Rider2026.2'
$colorDir = Join-Path $cfg 'colors'
$out      = Join-Path $colorDir 'BWANA Green.xml'
$pointer  = Join-Path $cfg 'options\colors.scheme.xml'

New-Item -ItemType Directory -Force -Path $colorDir | Out-Null

$t = Get-Content -LiteralPath $src -Raw

# --- palette -------------------------------------------------------------
$BG      = '000000'   # shell + editor background: black
$GREEN   = '00E676'   # base code text: green
$PINK    = 'FF79C6'   # keywords
$YELLOW  = 'F1FA8C'   # strings
$PURPLE  = 'BD93F9'   # numbers
$INDIGO  = '6272A4'   # comments
$CYAN    = '8BE9FD'   # types
$ORANGE  = 'FFB86C'   # methods
$BLUE    = '9CDCFE'   # variables
$RED     = 'FF5555'   # invalid escapes

$ci = $t.IndexOf('<colors>')
$ai = $t.IndexOf('<attributes>')
if ($ci -lt 0 -or $ai -lt 0) { throw 'scheme sections not found' }
$head  = $t.Substring(0, $ci)
$colors = $t.Substring($ci, $ai - $ci)
$attrs  = $t.Substring($ai)

# rename the scheme
$head = $head -replace '<scheme name="[^"]*"', '<scheme name="BWANA Green"'

function Set-ColorKey([string]$text, [string]$key, [string]$value) {
    $pat = '(<option name="' + [regex]::Escape($key) + '" value=")[0-9a-fA-F]+(")'
    $rx  = [regex]::new($pat)
    $n   = $rx.Matches($text).Count
    if ($n -ne 1) { throw "colors: expected 1 match for $key, got $n" }
    return $rx.Replace($text, ('${1}' + $value + '${2}'), 1)
}

# --- <colors>: editor + console/shell ------------------------------------
$colorEdits = [ordered]@{
    'CONSOLE_BACKGROUND_KEY'        = $BG
    'GUTTER_BACKGROUND'             = $BG
    'CARET_COLOR'                   = '00FF66'
    'CARET_ROW_COLOR'               = '0d1f0d'
    'SELECTION_BACKGROUND'          = '003D1F'
    'LINE_NUMBERS_COLOR'            = '4C9A5A'
    'LINE_NUMBER_ON_CARET_ROW_COLOR'= $GREEN
    'WHITESPACES'                   = '2E7D32'
    'INDENT_GUIDE'                  = '1F3D26'
    'SELECTED_INDENT_GUIDE'         = '2E7D32'
}
foreach ($k in $colorEdits.Keys) { $colors = Set-ColorKey $colors $k $colorEdits[$k] }

# --- <attributes>: text attributes ---------------------------------------
function Set-Attr([string]$text, [string]$key, [string]$fg, [string]$bg) {
    $esc = [regex]::Escape($key)
    $body = @()
    if ($fg) { $body += '<option name="FOREGROUND" value="' + $fg + '" />' }
    if ($bg) { $body += '<option name="BACKGROUND" value="' + $bg + '" />' }

    if ($body.Count -eq 0) { return $text }

    $newBlock = '<option name="' + $key + '">' + "`n      <value>`n        " +
                ($body -join "`n        ") + "`n      </value>`n    </option>"

    # form 1: fully self-closing element  <option name="K" />
    $rxOpt = [regex]::new('(?s)<option name="' + $esc + '"\s*/>')
    if ($rxOpt.IsMatch($text)) {
        return $rxOpt.Replace($text, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newBlock }, 1)
    }

    # form 2: empty nested value  <option name="K">\s*<value\s*/>
    #         (the trailing </option> survives, so do not emit another one)
    $rxSelf = [regex]::new('(?s)<option name="' + $esc + '">\s*<value\s*/>')
    if ($rxSelf.IsMatch($text)) {
        $newPartial = '<option name="' + $key + '">' + "`n      <value>`n        " +
                      ($body -join "`n        ") + "`n      </value>"
        return $rxSelf.Replace($text, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newPartial }, 1)
    }

    # form 3: existing populated value
    $rx = [regex]::new('(?s)(<option name="' + $esc + '">\s*<value>)(.*?)(</value>)')
    $found = $rx.Matches($text)
    if ($found.Count -ne 1) { return $text }   # key absent in this scheme: skip
    $inner = $found[0].Groups[2].Value

    if ($fg) {
        $rfx = [regex]::new('(?s)<option name="FOREGROUND" value="[^"]*"\s*/>')
        if ($rfx.IsMatch($inner)) { $inner = $rfx.Replace($inner, '<option name="FOREGROUND" value="' + $fg + '" />', 1) }
        else { $inner = "`n        <option name=`"FOREGROUND`" value=`"$fg`" />" + $inner }
    }
    if ($bg) {
        $rbg = [regex]::new('(?s)<option name="BACKGROUND" value="[^"]*"\s*/>')
        if ($rbg.IsMatch($inner)) { $inner = $rbg.Replace($inner, '<option name="BACKGROUND" value="' + $bg + '" />', 1) }
        else { $inner = $inner + "`n        <option name=`"BACKGROUND`" value=`"$bg`" />" }
    }

    $repl = '<option name="' + $key + '">' + "`n      <value>" + $inner + '</value>'
    return $rx.Replace($text, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $repl }, 1)
}

# default editor text = black background, green text
$attrs = Set-Attr $attrs 'TEXT' $GREEN $BG
$attrs = Set-Attr $attrs 'DEFAULT_IDENTIFIER' $GREEN $null

$attrEdits = [ordered]@{
    'DEFAULT_ATTRIBUTE'            = $GREEN
    'DEFAULT_KEYWORD'             = $PINK
    'DEFAULT_STRING'              = $YELLOW
    'DEFAULT_NUMBER'              = $PURPLE
    'DEFAULT_LINE_COMMENT'        = $INDIGO
    'DEFAULT_BLOCK_COMMENT'       = $INDIGO
    'DEFAULT_DOC_COMMENT'         = $INDIGO
    'DEFAULT_DOC_MARKUP'          = $INDIGO
    'DEFAULT_DOC_COMMENT_TAG'     = $PINK
    'DEFAULT_CLASS_NAME'          = $CYAN
    'DEFAULT_INTERFACE_NAME'      = $CYAN
    'DEFAULT_CLASS_REFERENCE'     = $CYAN
    'DEFAULT_STATIC_METHOD'       = $ORANGE
    'DEFAULT_INSTANCE_METHOD'     = $ORANGE
    'DEFAULT_FUNCTION_CALL'       = $ORANGE
    'DEFAULT_PARAMETER'           = $BLUE
    'DEFAULT_LOCAL_VARIABLE'      = $BLUE
    'DEFAULT_INSTANCE_FIELD'      = $BLUE
    'DEFAULT_STATIC_FIELD'        = $BLUE
    'DEFAULT_CONSTANT'            = $BLUE
    'DEFAULT_METADATA'            = $PINK
    'DEFAULT_PREDEFINED_SYMBOL'   = $YELLOW
    'DEFAULT_TAG'                 = $PINK
    'DEFAULT_ENTITY'              = $PINK
    'DEFAULT_VALID_STRING_ESCAPE' = '50FA7B'
    'DEFAULT_INVALID_STRING_ESCAPE' = $RED
    'CUSTOM_KEYWORD1_ATTRIBUTES'  = $PINK
    'CUSTOM_KEYWORD2_ATTRIBUTES'  = $CYAN
    'CUSTOM_KEYWORD3_ATTRIBUTES'  = $PURPLE
    'CUSTOM_KEYWORD4_ATTRIBUTES'  = $ORANGE
    'CUSTOM_STRING_ATTRIBUTES'    = $YELLOW
    'CUSTOM_NUMBER_ATTRIBUTES'    = $PURPLE
    'CUSTOM_LINE_COMMENT_ATTRIBUTES'   = $INDIGO
    'CUSTOM_MULTI_LINE_COMMENT_ATTRIBUTES' = $INDIGO
}
foreach ($k in $attrEdits.Keys) { $attrs = Set-Attr $attrs $k $attrEdits[$k] $null }

# --- console / shell output ---------------------------------------------
$consoleEdits = [ordered]@{
    'CONSOLE_NORMAL_OUTPUT' = $GREEN
    'CONSOLE_SYSTEM_OUTPUT' = '4EC9B2'
    'CONSOLE_USER_INPUT'    = $GREEN
    'CONSOLE_PARAMETER'     = $GREEN
}
foreach ($k in $consoleEdits.Keys) {
    if ($colors -match ('<option name="' + [regex]::Escape($k) + '"')) {
        $colors = Set-ColorKey $colors $k $consoleEdits[$k]
    } else {
        $attrs = Set-Attr $attrs $k $consoleEdits[$k] $null
    }
}

$xml = $head + $colors + $attrs
[System.IO.File]::WriteAllText($out, $xml, (New-Object System.Text.UTF8Encoding($false)))

# validate
[xml]$check = Get-Content -LiteralPath $out -Raw
if ($check.scheme.name -ne 'BWANA Green') { throw 'scheme name mismatch' }
Write-Output "WROTE: $out"
Write-Output "scheme name: $($check.scheme.name)  parent: $($check.scheme.parent_scheme)"
Write-Output "colors options: $($check.scheme.colors.option.Count)  attributes: $($check.scheme.attributes.option.Count)"

# --- point the IDE at it --------------------------------------------------
if (-not (Test-Path -LiteralPath ($pointer + '.bak'))) {
    Copy-Item -LiteralPath $pointer -Destination ($pointer + '.bak')
}
$ptr = @"
<application>
  <component name="EditorColorsManagerImpl">
    <global_color_scheme name="BWANA Green" />
  </component>
</application>
"@
[System.IO.File]::WriteAllText($pointer, $ptr, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "POINTER: $pointer"
Get-Content -LiteralPath $pointer
