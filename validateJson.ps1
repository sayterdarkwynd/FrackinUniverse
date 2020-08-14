[object[]]$Script:files = Get-ChildItem -Path ./ -Recurse -File -exclude default,*.lua,_previewimage,*.md,*.ps1,*.bat,*.abc,*.txt,*.3ds,*.7z,*.ai,*.avi,*.bat,*.blend,*.bz2,*.bmp,*.catpart,*.catproduct,*.ddf,*.dds,*.dem,*.dib,*.doc,*.docx,*.dst,*.dvl,*.dvl3,*.dvl4,*.dwg,*.dwf,*.dwg,*.dwt,*.dxf,*.editma,*.editmb,*.exp,*.fla,*.flt,*.fxb,*.g,*.gal,*.gif,*.gz,*.htr,*.iam,*.ico,*.ige,*.iges,*.igs,*.indd,*.ipt,*.jpg,*.jpeg,*.jt,*.ma,*.mb,*.mdl,*.mkv,*.model,*.mng,*.mov,*.mp4,*.mpp,*.neu,*.nif,*.obj,*.odf,*.odg,*.odp,*.ods,*.odt,*.ogg,*.pcx,*.pdf,*.pdn,*.png,*.ppt,*.pptx,*.prc,*.prt,*.psb,*.psd,*.rar,*.rle,*.rtf,*.rvt,*.sai,*.sat,*.session,*.shp,*.skp,*.sldprt,*.sldasm,*.sln,*.step,*.stp,*.stl,*.stw,*.sxc,*.sxd,*.sxi,*.sxw,*.tar,*.trc,*.tiff,*.u3d,*.vsd,*.vsdx,*.vssx,*.wav,*.webp,*.webm,*.wire,*.wpd,*.wrl,*.wrz,*.xcf,*.xfl,*.xls,*.xlsx,*.xmb,*.xpm,*.xz,*.zip;
[int]$Script:counter = 0;
[System.Collections.Generic.List[string]] $Script:errors = New-Object System.Collections.Generic.List[string]
foreach ($file in $Script:files) {
    $Script:counter++;
    try {
        $Local:shutUp = (get-Content -Raw -Path $file -Encoding UTF8) -replace "[`r`n]+","`n" -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/' | ConvertFrom-Json -ErrorAction Stop;
    }
    catch {
        $Script:found = $true;
        $a = (($file | Resolve-Path -Relative) + ": " + ($_.exception.message -split '\n')[0]);
        $Script:errors.Add($a)
    }  
}
if ($Script:errors.Count -le 0) {
    write-host -ForegroundColor Green -Object "NO ERRORS FOUND"
}
else {
    Write-Host -ForegroundColor Red "ERRORS FOUND:"
    foreach($str in $Script:errors) {
     Write-Host -ForegroundColor Red -Object $str
    }
}

pause 