;options manipulation
OptSet( name, val )
{
  qcconf.SetOpt( name, val )
  return val
}

OptGet( name )
{
  return qcconf.GetOpt( name )
}

OptDel( name )
{
  return qcconf.DelOpt( name )
}

SaveUseTime()
{
  Curtime := A_Now
  EnvSub, Curtime,% glb[ "startTime" ], Seconds
  if ( usetime := qcOpt[ "Settings_CT" ] )
    if usetime is digit
      Curtime += usetime
  qcOpt[ "Settings_CT" ] := Curtime
  return
}

GetUseTime()
{
  Curtime := A_Now
  EnvSub, Curtime,% glb[ "startTime" ], Seconds
  if usetime := qcOpt[ "Settings_CT" ]
    if usetime is digit
      Curtime += usetime
  Curtime := Floor(Curtime/86400) . " Days " . Floor(Mod(Curtime,86400)/3600) . " Hours " . Floor(Mod(Mod(Curtime,86400),3600)/60) . " Minutes "
  Return Curtime
}

QCGetDaysUsing()
{
  Curtime := A_Now
  EnvSub, Curtime,% glb[ "startTime" ], Seconds
  if usetime := qcOpt[ "Settings_CT" ]
    if usetime is digit
      Curtime += usetime
  return Floor(Curtime/86400)
}

class QC_Options
{
  __Get( option )
  {
    global OptDefaults
    nm := "qc386@_" option
    if ObjHasKey( this, nm )
      return this[ nm ]
    else
    {
      oRetOpt := OptGet( option )
      if !oRetOpt.attrExist
        value := OptDefaults[ option ]
      else
        value := oRetOpt.val
      ObjInsert( this, nm, value )
      return value
    }
  }
  __Set( option, value )
  {
    nm := "qc386@_" option
    ObjInsert( this, nm, value )
    OptSet( option, value )
    return value
  }
}

class OptDefaults
{
  static aprns_iconssize := 16	;icons_size
  ,aprns_iconstlp := 1	;noiconstooltips
  ,aprns_lightmenu := 0	;lightmenu
  ,aprns_heightadjust := 0	;items_height
  ,aprns_iconsonly := 0	;menu_iconsonly
  ,aprns_columns := 0	;menu_usecolumns
  ,aprns_col_mode := 1
  ,aprns_colbar := 0	;menu_barbreak
  ,aprns_colnum := 2 ;menu_maxpercol
  ,aprns_numpercol := 10 ;menu_maxpercol
  ,aprns_transp := 255    ;menus_transparency
  ,aprns_tform := 0
  ,aprns_mainfont := ""
  ,aprns_fontqlty := 5
  ,aprns_frameWidth := 1
  ,aprns_frameSelMode := 0
  
  static recent_logqc := 1	;rc_logrecentshortcuts
  ,recent_gesture := "UR"
  ,recent_hotkey := "#Q"
  ,recent_maxitems := 7        ;rc_count
  ,recent_logwinri := 0 ;rc_logwinrecent
  ,recent_logprocs := 0 ;rc_logprocs
  ,recent_logfolders := 0   ;rc_logfolders
  ,recent_on := 1    ;recent_state
  ,recent_sub := 1    ;recent_sub_state
  ,recent_geston := 1    ;recent_gesture_state
  
  static main_props_hidden := 1	;propshidewnd
  ,main_cmd_lvview := 1	;cmdlvviewmode
  ,main_pos := ""	;mg_pos
  ,main_tv_defcolors := 0 ;tv_defcolors
  ,main_gesture := "D"   ;maingesture
  ,main_hotkey := "#Z" ;hotkeystring
  ,main_geston := 1    ;gesture_main_enabled
  ,main_ctrlrbhkey := 0   ;defaulthotkey_ctrl_rb
  ,main_ctrlmbhkey := 0   ;defaulthotkey_ctrl_mb
  ,main_ctrllrbhkey := 0 ;defaulthotkey_lb_rb
  ,main_tv_glFont := 1
  ,main_tv_fontSize := 10

  static fb_username := ""
  ,fb_useremail := ""
  
  static gen_runonstartup := 0
  ,gen_contextqc := 0
  ,gen_notheme := 0
  ,gen_suspendsub := 1
  ,gen_helpsub := 1
  ,gen_cmddelay := 200
  ,gen_autoupd := 1
  ,gen_trayicon := 1
  ,gen_smenuson := 0
  ,gen_editoritem := 1
  ,gen_iconrelpath := 0
  ,gen_cmdrelpath := 0
  ,gen_copy_method := 1
  ,gen_paste_method := 1
  ,gen_mnem_method := "run"
  ,gen_donated := 0
  
  static clips_copyhk := "^"
  ,clips_appendhk := "#^"
  ,clips_pastehk := "!"
  ,clips_gesture := "U"
  ,clips_hotkey := "#X"
  ,clips_saveonexit := 1
  ,clips_on := 1
  ,clips_sub := 1
  ,clips_geston := 1
  
  static gest_curbut := "rbutton"    ;curgesturebutton
  ,gest_tempnotify := 1 ;tgnotify
  ,gest_glbon := 1 ;gesturesglobalstate
  ,gest_time := 10000    ;gesture_disable_time
  ,gest_butmods := ""
  ,gest_win_excl := []
  ,gest_win_excl_on := 0

  static settings_ct := ""    ;
  ,hkey_glbon := 1  ;hotkeysglobalstate

  static memos_gesture := "l"
  ,memos_hotkey := "#A"
  ,memos_on := 1
  ,memos_sub := 1 ;memosshowinmain
  ,memos_geston := 1   ;gesture_memos_enabled
  ,memos_delconf := 0 ;memosdelconfirm
  ,otm_bg_default_color := ""
  ,otm_t_default_color := ""
  ,otm_default_font := ""

  static wins_hotkey := "#c" ;win_hide_show_hotkey
  ,wins_gesture := "r"  ;win_hide_gesture
  ,wins_wndhidehkey := "^space"    ;hide_optionalhotkey
  ,wins_on := 1    ;win_hide_enabled
  ,wins_sub := 1   ;win_hide_show
  ,wins_geston := 1  ;gesture_wh_enabled
  ,wins_viewtransp := 150    ;winviewtransplevel
  ,wins_fade := 1 ;winfade
  
  static fm_refresh_on := 1
  ,fm_refresh_time := 15
  ,fm_show_open_item := 1
  ,fm_extractexe := 0
  ,fm_showicons := 1
  ,fm_show_files_ext := 1
  ,fm_iconssize := "global"
  ,fm_files_first := 0
  ,fm_show_lnk := 0
  ,fm_sort_type := "Name"
  ,fm_sort_mode := "Asc"
}