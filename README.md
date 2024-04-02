<font face="Arial" size=64>The name of this open source project: Osen Loigc OSD10</font>

(en)Osen Loigc OSD10: Hardware implementation of video compressing algorithm in H.264 standard.
External logic receive h.264 NAL stream from FIFO, which is external memory, and decodes it as YUV4:2:0,then store it into the external memory
OsenLogic OSD10 includes stream parser(extensions and CAVLC),IDCT/Iquant(residual),internal predictor and deblocking filters
parser can work without CPU, which means PL-end can do all the work

(ZH)Osen Loigc OSD10：H.264标准的视频压缩算法的硬件实现
外部逻辑OSD10从外部内存接收来自FIFO的h.264 NAL流，并将其解码为YUV 4：2：0，然后存储到外部内存。
OsenLogic OSD10包括位流解析器（扩展和CAVLC）、IDCT/Iquant（残差）、内部预测器和去块过滤器。 
解码器可以在没有CPU时工作( PL端可以完成所有工作）  

FILE STRUCTURE:
in forlder "Hardware", the sub-folder 'decoder' includes complete simulation project using Modelsim; the sub-folder 'video_decoder' includes complete RTL files of Osen Loigc OSD10.
in folder "Software": it contains files that can implement the simulation of H264 decoding using software in C++, which used to compare the performance with the result of simlulation in hardware.  
<img src="https://github.com/ICscholar/H264_decoder-verilog-Cpp/blob/main/img/simulation.png" width="600px">  
Files in software simulation folder

HOW TO SIMULATE THE PROJECT:  
Hardware: in modelsim console window, type "vsim -vopt -pli pli_fputc64.dll work.bitstream_tb".pli_fputc64.dll is a pli library I write for dump binary out.yuv file, it runs in windows 64bit, if you are using windows 32 bit, instead it with fputc32.dll. the source of pli_fputc is in software/pli_fputc_src directory.  
Software: 1.cd to this directory.
		      2.type "make" to build bitstream.exe, gcc is required to build it.
		      3.run bitstream.exe to decode the "in.264" file in the same directory.  
To use the open source project, the first step is to replace the input file in projcet with own .264 video. In hardware part, a direct change is enough, while in software part, if you want to change the file name in the code, then you should use commands to 'makefile' in both 3 sub-folders.  
The specific command for 'makefile' depends on a .exe file in the path 'D:\VSCode\MinGW\mingw\bin\mingw32-make.exe'.  
After downloading .mp4 file from video website, you can use ffmpeg to transfer it into .264 file. Default command to achieve this may be not enough, through numerous trials, the most appropriate command is 'ffmpeg -i 2_dance.mp4 -c:v libx264 -profile:v baseline -level 3.1 -refs 1 -bf 0 -r 25 -s 1280x720 -pix_fmt yuv420p -an 2_dance.264'. Besides, you should make sure that the resolution of video can be divided by 16, otherwise when you open the simuliation output file using some softwares, YUV viewer for example, may be in low quality with gray or blue ribbon at the bottom and left of the video, from automatic completion from bilinear interpolation method.  
simulation results:  
<img src="https://github.com/ICscholar/H264_decoder-verilog-Cpp/blob/main/img/simulation_out.png" width="480px">  










