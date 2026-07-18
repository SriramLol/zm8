# zm8 gum picker - dropdown UI for the shared GobbleGum pack.
# Reads the per-map gum list the mod writes (available_gums.txt) and saves
# the selection to gum_pack.txt, which the mod reads when players join.
# Boxes are type-to-filter: typing narrows the dropdown to matching gums.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptData = Join-Path $PSScriptRoot "boiii\scriptdata\zm8"
$gumsFile = Join-Path $scriptData "available_gums.txt"
$packFile = Join-Path $scriptData "gum_pack.txt"

# gum list: prefer the per-map list written by the mod, fall back to classics
$gums = @()
if (Test-Path $gumsFile) {
    $gums = @(Get-Content $gumsFile | Where-Object { $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") } | ForEach-Object { $_.Trim() })
}
if ($gums.Count -eq 0) {
    $gums = @(
        "always done swiftly", "arms grace", "arsenal accelerator", "coagulant",
        "in plain sight", "stock option", "sword flay", "anywhere but here",
        "danger closest", "armamental accomplishment", "firing on all cylinders"
    )
}
$global:zm8Gums = @($gums | Sort-Object -Unique)

# current selection, if a pack was saved before
$current = @()
if (Test-Path $packFile) {
    $current = @(Get-Content $packFile | Where-Object { $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") } | ForEach-Object { $_.Trim() })
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "zm8 - Shared GobbleGum Pack (players 5-8)"
$form.Size = New-Object System.Drawing.Size(440, 340)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.StartPosition = "CenterScreen"

$info = New-Object System.Windows.Forms.Label
$info.Text = "Pick up to 5 gums - type to filter the list. (mega) gums are experimental. Given to players the game gives no pack (slots 5-8). Run a map once to refresh the list for that map."
$info.Location = New-Object System.Drawing.Point(15, 10)
$info.Size = New-Object System.Drawing.Size(400, 58)
$form.Controls.Add($info)

# type-to-filter: rebuild the item list to substring matches as the user types
$filterHandler = {
    $box = $this
    if ($box.Tag -eq "filtering") { return }
    $box.Tag = "filtering"
    try {
        $text = $box.Text
        $caret = $box.SelectionStart
        $matches = @($global:zm8Gums | Where-Object { $_ -like "*$text*" })
        if ($matches.Count -eq 0) { $matches = $global:zm8Gums }
        $box.BeginUpdate()
        $box.Items.Clear()
        foreach ($m in $matches) { [void]$box.Items.Add($m) }
        $box.EndUpdate()
        if ($text -ne "" -and -not $box.DroppedDown) {
            $box.DroppedDown = $true
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
        }
        $box.Text = $text
        $box.SelectionStart = $caret
        $box.SelectionLength = 0
    } finally {
        $box.Tag = $null
    }
}

$combos = @()
for ($i = 0; $i -lt 5; $i++) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Gum $($i + 1):"
    $label.Location = New-Object System.Drawing.Point(15, (78 + $i * 32))
    $label.Size = New-Object System.Drawing.Size(60, 22)
    $form.Controls.Add($label)

    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.DropDownStyle = "DropDown"
    $combo.Location = New-Object System.Drawing.Point(80, (75 + $i * 32))
    $combo.Size = New-Object System.Drawing.Size(330, 24)
    foreach ($g in $global:zm8Gums) { [void]$combo.Items.Add($g) }
    if ($i -lt $current.Count) { $combo.Text = $current[$i] }
    $combo.Add_TextUpdate($filterHandler)
    $form.Controls.Add($combo)
    $combos += $combo
}

$save = New-Object System.Windows.Forms.Button
$save.Text = "Save Pack"
$save.Location = New-Object System.Drawing.Point(80, 250)
$save.Size = New-Object System.Drawing.Size(160, 30)
$save.Add_Click({
    $picked = @()
    $unknown = @()
    foreach ($c in $combos) {
        $t = $c.Text.Trim()
        if ($t -eq "") { continue }
        $match = $global:zm8Gums | Where-Object { $_ -ieq $t } | Select-Object -First 1
        if ($match) {
            $picked += $match
        } else {
            $picked += $t
            $unknown += $t
        }
    }
    if ($picked.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Pick at least one gum (or just close to keep the default pack).", "zm8") | Out-Null
        return
    }
    if ($unknown.Count -gt 0) {
        $answer = [System.Windows.Forms.MessageBox]::Show(
            "Not in the list for this map:`n`n$($unknown -join "`n")`n`nSave anyway? (The mod skips names it can't resolve and prints a warning in the console.)",
            "zm8", [System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    }
    if (-not (Test-Path $scriptData)) { New-Item -ItemType Directory -Force $scriptData | Out-Null }
    $out = @("# zm8 shared gum pack - written by zm8-gum-picker") + $picked
    $out | Out-File $packFile -Encoding ascii
    [System.Windows.Forms.MessageBox]::Show("Saved. Applies from the next match (or next player join).", "zm8") | Out-Null
    $form.Close()
})
$form.Controls.Add($save)

$cancel = New-Object System.Windows.Forms.Button
$cancel.Text = "Cancel"
$cancel.Location = New-Object System.Drawing.Point(250, 250)
$cancel.Size = New-Object System.Drawing.Size(160, 30)
$cancel.Add_Click({ $form.Close() })
$form.Controls.Add($cancel)

[void]$form.ShowDialog()

