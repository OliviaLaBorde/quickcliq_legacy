#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include Crypt.ahk
#Include CryptConst.ahk
#Include CryptFoos.ahk

;~ Data := RandStr2( 14 ) 
;~ Data := "ыфвфдйб2лу9ш* n╘кЖ€"
Data := "아라써"
pwd := "mypassword"
enc := "UTF-8"
passEnc := "UTF-16"

rs .= "original: ->" Data "<-`n"
loop, 7
{
	cryptAlg := A_Index
	loop, 6
	{
		hashAlg := A_Index
		loop,2
		{
			enc := A_Index = 1 ? "UTF-8" : "UTF-16"
			loop,2
			{
				passEnc := A_Index = 1 ? "UTF-8" : "UTF-16"
				Crypt.Encrypt.StrEncoding := enc
				Crypt.Encrypt.PassEncoding := passEnc
				FileAppend, % Data,tmp.txt,% enc
				Crypt.Encrypt.FileEncrypt( "tmp.txt", "sample.dat", pwd, cryptAlg, hashAlg)
				FileDelete, tmp.txt
				f := fileOpen( "sample.dat", "r", "CP0" )
				bufSize := f.RawRead( buffer, f.Length )
				f.close()
				;-------First Method
				;get hashed string of data since StrDecrypt use it as first parameter
				hashedData := b64Encode(buffer,bufSize)
				rs .= "enc: " enc ";penc: " passEnc "; ca: " cryptAlg "; ha: " hashAlg " -- " Crypt.Encrypt.StrDecrypt( hashedData, pwd, cryptAlg, hashAlg) "`n"
			}
		}
	}
}
gui,add,Edit,w400 h500,% rs
gui,show
;~ exitapp
return

guiclose:
	exitapp
	return

RandStr2( n=8, maxSum = "" ) 
{
   static arrs := [ arrLow := [ 97,98,99,100,101,102,103,104,105,106,107,109,110,111,112,113,114,115,116,117,118,119,120,121,122 ]
               ,arrNum := [ 49,50,51,52,53,54,55,56,57 ]
               ,arrUpper := [ 65, 66, 67, 68, 69, 70, 71, 72, 74, 75, 76, 77, 78, 79, 80, 81,82,83,84,85,86,87,88,89,90 ]
               ,arrSym := [ 33,35,36,37,38,40,41,42,43,45,46,47,58,59,60,61,62,63,64,91,92,93,94,95,123,125,126 ] ]
   step := 1
   symnum_a := 0
   while ( step <= n )
   {
      Random,r,1,% arrs.MaxIndex()
      Random,rn,1,% arrs[ r ].MaxIndex()
      char := chr( arrs[ r ][ rn ] )
      if ( char == pre_char )
         continue
      if ( r = 4 )
      {
         if ( symnum_a = maxSum )
            continue
         symnum_a++
      }
      p .= char
      pre_char := char
      step++
   }
   Return p
}