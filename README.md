The name of this open source project: Osen Loigc OSD10

(ZH)Osen Loigc OSD10：H.264标准的视频压缩算法的硬件实现
外部逻辑OSD10从外部内存接收来自FIFO的h.264 NAL流，并将其解码为YUV 4：2：0，然后存储到外部内存。
OsenLogic OSD10包括位流解析器（扩展和CAVLC）、IDCT/Iquant（残差）、内部预测器和去块过滤器。 
解码器可以在没有CPU时工作( PL端可以完成所有工作）  
(en)Osen Loigc OSD10: Hardware implementation of video compressing algorithm in H.264 standard.
External logic receive h.264 NAL stream from FIFO, which is external memory, and decodes it as YUV4:2:0,then store it into the external memory
OsenLogic OSD10 includes stream parser(extensions and CAVLC),IDCT/Iquant(residual),internal predictor and deblocking filters
parser can work without CPU, which means PL-end can do all the work

FILE STRUCTURE:
in forlder "Hardware", the sub-folder 'decoder' includes complete simulation project using Modelsim; the sub-folder 'video_decoder' includes complete RTL files of Osen Loigc OSD10.
in folder "Software": it contains files that can implement the simulation of H264 decoding using software in C++, which used to compare the performance with the result of simlulation in hardware.

HOW TO SIMULATE THE PROJECT:  
Hardware: in modelsim console window, type "vsim -vopt -pli pli_fputc64.dll work.bitstream_tb".pli_fputc64.dll is a pli library I write for dump binary out.yuv file, it runs in windows 64bit, if you are using windows 32 bit, instead it with fputc32.dll. the source of pli_fputc is in software/pli_fputc_src directory.  
Software: 1.cd to this directory.
		      2.type "make" to build bitstream.exe, gcc is required to build it.
		      3.run bitstream.exe to decode the "in.264" file in the same directory.  






