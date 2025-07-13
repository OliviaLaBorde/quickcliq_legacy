class MIL extends qc_base
{
	__New()
	{
		this.hSmall := IL_Create(20,10,0)
		this.hBig := IL_Create(20,10,1)
	}
	
	__Delete()
	{
		IL_Destroy(this.hSmall)
		IL_Destroy(this.hBig)
	}
	
    Small()
    {
      return this.hSmall
    }
    
    Big()
    {
      return this.hBig
    }
    
	Get( ind,size=1 )
	{
      return IL_GetIcon( size ? this.hBig : this.hSmall, ind )
	}
	
	Add( icon )
	{
      icoPath := IconGetPath( icon )
      icoIndex := IconGetIndex( icon ) + 1
      if index := IL_Add( this.hSmall, icoPath, icoIndex )
          IL_Add( this.hBig, icoPath, icoIndex )
      return index
	}
	
	Remove( ind )
	{
		IL_Remove( this.hSmall, ind )
		IL_Remove( this.hBig, ind )
	}
	
	AddH(hIcon,ind=-1)
	{
		ret_ind := IL_AddIcon(this.hSmall,hIcon,ind)
		IL_AddIcon(this.hBig,hIcon,ind)
		return ret_ind
	}
}	