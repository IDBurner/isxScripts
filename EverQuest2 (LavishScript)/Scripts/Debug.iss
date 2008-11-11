;; Debug.iss
;;
;; Includeable debug object.
;; -------------------------
;; Provides the following:
;;	Debug script scope variable, debug type.
;; 
;;	MEMBERS:
;;		Enabled (bool type)
;;		TimestampEcho (bool type)
;;		TimestampLog (bool type)
;;	
;;	METHODS:
;;		Enable
;;		Disable
;;		Echo[Arguments]                 Echos a debug line with timestamp to the console.
;;		Log[Arguments]                  Logs a line in a log file matching the script name in the script dir.
;;		SetFilename[string Filename]    Sets output filename used by Log method. Default: Scriptdir/Script.txt
;;		SetPrefix[string]               Sets string to prefix all echo and log output with. Default "DEBUG: "
;;		TimestampEcho[bool]             Enables or disables timestamps in echos. Default TRUE
;;		TimestampLog[bool]              Enables or disables timestamps in logs. Default TRUE
;;
;;	Example Script:
;;	
;;	#include Debug.iss
;;	
;;	function main()
;;	{
;;		Debug:Enable
;;		Debug:Echo["My script is started"]
;;		Debug:Log["I Ran my script"]
;;	}
	
#ifndef _DEBUG_
#define _DEBUG_

objectdef debug
{
	member:bool Enabled()
	{
		return ${This.IsEnabled}
	}
	
	member:bool TimestampEcho()
	{
		return ${This.Timestamp_Echo}
	}

	member:bool TimestampLog()
	{
		return ${This.Timestamp_Log}
	}
	
	method Enable()
	{
		This.IsEnabled:Set[TRUE]
	}
	
	method Disable()
	{
		This:IsEnabled:Set[FALSE]
	}
	
	method SetFilename(string Filename)
	{
		This.File:Set[${Filename}]
	}
	
	method TimestampEcho(bool Value)
	{
		This.Timestamp_Echo:Set[${Value}]
	}
	
	method TimestampLog(bool Value)
	{
		This.Timestamp_Log:Set[${Value}]
	}
	
	method SetPrefix(string Prefix)
	{
		This.Prefix:Set[${Prefix}]
	}
	
	method Echo(... Args)
	{
		if ${This.Enabled}
		{
			echo ${If[${This.Timestamp_Echo},${Time.Time24}]} ${This.Prefix}${Args.Expand}
		}
	}
	
	method Log(... Args)
	{
		if ${This.Enabled}
		{
			redirect -append "${This.File}" "echo ${If[${This.Timestamp_Log},${Time.Year}${Time.Month.LeadingZeroes[2]}${Time.Day.LeadingZeroes[2]} ${Time.Time24}]} ${This.Prefix}${Args.Expand}"
		}
	}
	
	method Initialize()
	{
		This.IsEnabled:Set[FALSE]
		This.TimestampEcho:Set[TRUE]
		This.TimestampLog:Set[TRUE]
		This.Prefix:Set["DEBUG: "]
		This.File:Set["${Script.CurrentDirectory}/${Script.Filename}.txt"]
	}
	
	variable bool IsEnabled
	variable bool Timestamp_Echo
	variable bool Timestamp_Log
	variable string Prefix
	variable string File
}

variable debug Debug

#endif /* _DEBUG_ */
