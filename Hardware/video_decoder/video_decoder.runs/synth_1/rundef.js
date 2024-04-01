//
// Vivado(TM)
// rundef.js: a Vivado-generated Runs Script for WSH 5.1/5.6
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//

var WshShell = new ActiveXObject( "WScript.Shell" );
var ProcEnv = WshShell.Environment( "Process" );
var PathVal = ProcEnv("PATH");
if ( PathVal.length == 0 ) {
  PathVal = "E:/VIVADO/vivado/Vivado/2023.1/ids_lite/ISE/bin/nt64;E:/VIVADO/vivado/Vivado/2023.1/ids_lite/ISE/lib/nt64;E:/VIVADO/vivado/Vivado/2023.1/bin;";
} else {
  PathVal = "E:/VIVADO/vivado/Vivado/2023.1/ids_lite/ISE/bin/nt64;E:/VIVADO/vivado/Vivado/2023.1/ids_lite/ISE/lib/nt64;E:/VIVADO/vivado/Vivado/2023.1/bin;" + PathVal;
}

ProcEnv("PATH") = PathVal;

var RDScrFP = WScript.ScriptFullName;
var RDScrN = WScript.ScriptName;
var RDScrDir = RDScrFP.substr( 0, RDScrFP.length - RDScrN.length - 1 );
var ISEJScriptLib = RDScrDir + "/ISEWrap.js";
eval( EAInclude(ISEJScriptLib) );


ISEStep( "vivado",
         "-log display_mem_reader.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source display_mem_reader.tcl" );



function EAInclude( EAInclFilename ) {
  var EAFso = new ActiveXObject( "Scripting.FileSystemObject" );
  var EAInclFile = EAFso.OpenTextFile( EAInclFilename );
  var EAIFContents = EAInclFile.ReadAll();
  EAInclFile.Close();
  return EAIFContents;
}
