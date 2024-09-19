param (
    [string]$filePath,
    [string]$mode
)

# Read the entire file into a byte array
$fileBytes = [System.IO.File]::ReadAllBytes($filePath)

# Read the data from specific offsets
$height = [BitConverter]::ToInt16($fileBytes, 0xc)
$width = [BitConverter]::ToInt16($fileBytes, 0x10)
$mipLevels = $fileBytes[0x1c]
$fourByteString = [System.Text.Encoding]::ASCII.GetString($fileBytes, 0x54, 4)

# Print the data to the CMD window
Write-Output "Height: $height"
Write-Output "Width: $width"
Write-Output "Mip Levels: $mipLevels"
Write-Output "4-byte String: $fourByteString"

# Convert the 4-byte string into an int8 value
switch ($fourByteString) {
    "ATI2" { $int8Value = 83 }
    "DXT1" { $int8Value = 71 }
    "DXT5" { $int8Value = 77 }
    default { throw "Unknown 4-byte string: $fourByteString" }
}

# Initialize a 128-byte array for the new header
$newHeader = New-Object byte[] 128

# Fill in the provided template values
$template = [byte[]](0x41, 0x56, 0x54, 0x58, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                     0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA2, 0x42, 0x00, 0x00, 0xA8, 0x41,
                     0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
$template.CopyTo($newHeader, 0)

# Insert the extracted values into the new header
$newHeader[0x08] = [byte]$int8Value
[BitConverter]::GetBytes($width).CopyTo($newHeader, 0x0c)
[BitConverter]::GetBytes($height).CopyTo($newHeader, 0x0e)
$newHeader[0x14] = [byte]$mipLevels
$newHeader[0x15] = [byte]$mipLevels

# If mode is srgb, insert 09 at 0x12
if ($mode -eq 'srgb') {
    $newHeader[0x12] = 0x09
}

# Calculate the offset 128 bytes from the end of the file
$fileLength = $fileBytes.Length
$offsetValue = $fileLength - 128
$offsetBytes = [BitConverter]::GetBytes($offsetValue)

# Insert the offset bytes into the new header at 0x24
$offsetBytes[0..3].CopyTo($newHeader, 0x24)

# Write the new header and the rest of the file content to a new file with .ddsc extension
$newFilePath = [System.IO.Path]::ChangeExtension($filePath, ".ddsc")
[System.IO.File]::WriteAllBytes($newFilePath, $newHeader + $fileBytes[128..($fileBytes.Length - 1)])

Write-Output "New file created: $newFilePath"
