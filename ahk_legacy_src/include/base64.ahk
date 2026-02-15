b64Encode( ByRef buf, bufLen )
{
	DllCall( "crypt32\CryptBinaryToStringA", "ptr", &buf, "UInt", bufLen, "Uint", 1 | 0x40000000, "Ptr", 0, "UInt*", outLen )
	VarSetCapacity( outBuf, outLen, 0 )
	DllCall( "crypt32\CryptBinaryToStringA", "ptr", &buf, "UInt", bufLen, "Uint", 1 | 0x40000000, "Ptr", &outBuf, "UInt*", outLen )
	return strget( &outBuf, outLen, "CP0" )
}

b64Decode( b64str, ByRef outBuf )
{
	DllCall( "crypt32\CryptStringToBinaryW", "ptr", &b64str, "UInt", 0, "Uint", 1, "Ptr", 0, "UInt*", outLen, "ptr", 0, "ptr", 0 )
	VarSetCapacity( outBuf, outLen, 0 )
	DllCall( "crypt32\CryptStringToBinaryW", "ptr", &b64str, "UInt", 0, "Uint", 1, "Ptr", &outBuf, "UInt*", outLen, "ptr", 0, "ptr", 0 )
	return outLen
}

b2a_hex( ByRef pbData, dwLen )
{
	if (dwLen < 1)
		return 0
	if pbData is integer
		ptr := pbData
	else
		ptr := &pbData
	SetFormat,integer,Hex
	loop,%dwLen%
	{
		num := numget(ptr+0,A_index-1,"UChar")
		hash .= substr((num >> 4),0) . substr((num & 0xf),0)
	}
	SetFormat,integer,D
	StringLower,hash,hash
	return hash
}

a2b_hex( sHash,ByRef ByteBuf )
{
	if (sHash == "" || RegExMatch(sHash,"[^\dABCDEFabcdef]") || mod(StrLen(sHash),2))
		return 0
	BufLen := StrLen(sHash)/2
	VarSetCapacity(ByteBuf,BufLen,0)
	loop,%BufLen%
	{
		num1 := (p := "0x" . SubStr(sHash,(A_Index-1)*2+1,1)) << 4
		num2 := "0x" . SubStr(sHash,(A_Index-1)*2+2,1)
		num := num1 | num2
		NumPut(num,ByteBuf,A_Index-1,"UChar")
	}
	return BufLen
}

_b64( p, encode = true )
{
	static b64 := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	return encode ? substr( b64, p+1, 1 ) : instr( b64, p, true )-1
}

mb64Encode( ByRef buf, bufLen )
{
	offset := 0
	while ( offset < bufLen )
	{
		b1 := numget( &buf, offset++, "char" )
		b2 := numget( &buf, offset++, "char" )
		b3 := numget( &buf, offset++, "char" )
		r .= _b64( b1 >> 2 )
		r .= _b64( ( b1 & 3 ) << 4 | b2 >> 4 )
		r .= _b64( ( b2 & 0xF ) << 2 | b3 >> 6 )
		r .= _b64( b3 & 63 )
	}
	if ( lenDiff := offset - bufLen )
	{
		StringTrimRight, r,r,% lenDiff
		r .= lenDiff = 2 ? "==" : lenDiff = 1 ? "=" : ""
	}
	return r
}

mb64Decode( b64buf, ByRef outBuf )
{
	b64Len := StrLen( b64buf )
	if ( mod( b64Len, 4 ) || RegExMatch( b64buf, "^[^A-Za-z0-9+/=]*$" ) )	;not a base64 string
		return 0
	b64Offset := 0
	byteOffset := 0
	byteLen := ( b64Len//4 )*3
	;reduce byte buf len by the amount of '=' in string
	if RegExMatch( b64buf, "=+$", outEqs )
		byteLen -= strLen( outEqs )
	VarSetCapacity( outBuf, byteLen+2, 0 )
	while ( b64Offset != b64Len )
	{
		loop,4
			i%A_Index% := _b64( SubStr( b64buf, 1+b64Offset++, 1 ), false )
		NumPut( i1 << 2 | i2 >> 4, outBuf, byteOffset++, "char" )
		NumPut( ( i2 & 0xF ) << 4 | i3 >> 2, outBuf, byteOffset++, "char" )
		NumPut( ( i3 & 3 ) << 6 | i4, outBuf, byteOffset++, "char" )
	}
	return byteLen
}