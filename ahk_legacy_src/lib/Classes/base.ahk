class qc_base
{
  __Call( aTarget, aParams* ) {
    if ObjHasKey( qc_base, aTarget )
      return qc_base[ aTarget ].( this, aParams* )
    throw Exception( "Unknown function '" aTarget "' requested from object '" this.__Class "'`n" CallStack() )
  }
  
  Err( msg ) {
    throw Exception( this.__Class " : " msg ( A_LastError != 0 ? "`n" this.ErrorFormat( A_LastError ) : "" ), -2 )
  }
  
  ErrorFormat( error_id ) {
    VarSetCapacity(msg,1000,0)
    if !len := DllCall("FormatMessageW"
          ,"UInt",FORMAT_MESSAGE_FROM_SYSTEM := 0x00001000 | FORMAT_MESSAGE_IGNORE_INSERTS := 0x00000200		;dwflags
          ,"Ptr",0		;lpSource
          ,"UInt",error_id	;dwMessageId
          ,"UInt",0			;dwLanguageId
          ,"Ptr",&msg			;lpBuffer
          ,"UInt",500)			;nSize
      return
    return 	strget(&msg,len)
  }
}