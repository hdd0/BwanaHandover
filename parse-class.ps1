param([string]$JarPath,[string]$EntryName)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z=[System.IO.Compression.ZipFile]::OpenRead($JarPath)
$e=$z.Entries | Where-Object { $_.FullName -eq $EntryName }
if(-not $e){ "ENTRY NOT FOUND: $EntryName"; $z.Dispose(); exit 1 }
$s=$e.Open(); $ms=New-Object System.IO.MemoryStream; [void]$s.CopyTo($ms); $s.Close(); $z.Dispose()
$b=$ms.ToArray()
"file size = $($b.Length)"

$stream=New-Object System.IO.MemoryStream(,$b)
$br=New-Object System.IO.BinaryReader($stream)
# class files are big-endian; BinaryReader is little-endian, so reverse each read
function RU32($br){ $x=$br.ReadBytes(4); [Array]::Reverse($x); [BitConverter]::ToUInt32($x,0) }
function RU16($br){ $x=$br.ReadBytes(2); [Array]::Reverse($x); [BitConverter]::ToUInt16($x,0) }
function RI32($br){ $x=$br.ReadBytes(4); [Array]::Reverse($x); [BitConverter]::ToInt32($x,0) }
$magic=RU32 $br; $minor=RU16 $br; $major=RU16 $br
"magic=0x{0:X8} minor={1} major={2}" -f $magic,$minor,$major
$cpCount=RU16 $br; "cpCount=$cpCount"
$cp=New-Object object[] $cpCount
$i=1
while($i -lt $cpCount){
  $tag=$br.ReadByte()
  switch($tag){
    1 { $len=RU16 $br; $cp[$i]=[System.Text.Encoding]::UTF8.GetString($br.ReadBytes($len)) }
    3 { $cp[$i]=@('int',(RI32 $br)) }
    4 { [void]$br.ReadBytes(4); $cp[$i]='float' }
    5 { [void]$br.ReadBytes(8); $cp[$i]='long'; $i++ }
    6 { [void]$br.ReadBytes(8); $cp[$i]='double'; $i++ }
    7 { $cp[$i]=@('class',(RU16 $br)) }
    8 { $cp[$i]=@('string',(RU16 $br)) }
    9 { [void]$br.ReadBytes(4); $cp[$i]='fieldref' }
    10 { [void]$br.ReadBytes(4); $cp[$i]='methodref' }
    11 { [void]$br.ReadBytes(4); $cp[$i]='ifaceMethodref' }
    12 { $cp[$i]=@('nameandtype',(RU16 $br),(RU16 $br)) }
    15 { [void]$br.ReadBytes(3); $cp[$i]='methodhandle' }
    16 { [void]$br.ReadBytes(2); $cp[$i]='methodtype' }
    18 { $cp[$i]=@('invokedynamic',(RU16 $br),(RU16 $br)) }
    default { throw "unknown cp tag $tag at index $i (stream pos $($stream.Position))" }
  }
  $i++
}
[void](RU16 $br); [void](RU16 $br); [void](RU16 $br)
$ifcCount=RU16 $br; [void]$br.ReadBytes(2*$ifcCount)

"===== STATIC FINAL INT CONSTANTS ====="
$fieldCount=RU16 $br
for($f=0;$f -lt $fieldCount;$f++){
  [void](RU16 $br)
  $ni=RU16 $br; [void](RU16 $br)
  $name=$cp[$ni]
  $an=RU16 $br
  for($k=0;$k -lt $an;$k++){
    $ani=RU16 $br; $len=[BitConverter]::ToUInt32(@($br.ReadBytes(4)[3..0]),0); $data=$br.ReadBytes($len)
    if($cp[$ani] -eq 'ConstantValue'){
      $idx=[BitConverter]::ToUInt16(@($data[1],$data[0]),0)
      $entry=$cp[$idx]
      $val = if($entry -is [array] -and $entry[0] -eq 'int'){ $entry[1] } else { $entry -join '/' }
      "{0,-42} = {1}" -f $name,$val
    }
  }
}
