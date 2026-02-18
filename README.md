<h1>The name of this open source project: Osen Loigc OSD10</h1>

<h2>(EN)Osen Loigc OSD10: Hardware implementation of video compressing algorithm in H.264 standard.  </h2>
External logic receive h.264 NAL stream from FIFO, which is external memory, and decodes it as YUV4:2:0,then store it into the external memory
OsenLogic OSD10 includes stream parser(extensions and CAVLC),IDCT/Iquant(residual),internal predictor and deblocking filters
parser can work without CPU, which means PL-end can do all the work

<h2>(ZH)Osen Loigc OSD10：H.264标准的视频压缩算法的硬件实现  </h2>
外部逻辑OSD10从外部内存接收来自FIFO的h.264 NAL流，并将其解码为YUV 4：2：0，然后存储到外部内存。
OsenLogic OSD10包括位流解析器（扩展和CAVLC）、IDCT/Iquant（残差）、内部预测器和去块过滤器。 
解码器可以在没有CPU时工作( PL端可以完成所有工作）  

<h2>FILE STRUCTURE:</h2>
in forlder "Hardware", the sub-folder 'decoder' includes complete simulation project using Modelsim; the sub-folder 'video_decoder' includes complete RTL files of Osen Loigc OSD10.
in folder "Software": it contains files that can implement the simulation of H264 decoding using software in C++, which used to compare the performance with the result of simlulation in hardware.  
<img src="https://github.com/ICscholar/H264_decoder-verilog-Cpp/blob/main/img/simulation.png" width="600px">  
Files in software simulation folder

<h2>HOW TO SIMULATE THE PROJECT:  </h2>
<h3>Hardware</h3> in modelsim console window, type "vsim -vopt -pli pli_fputc64.dll work.bitstream_tb".pli_fputc64.dll is a pli library I write for dump binary out.yuv file, it runs in windows 64bit, if you are using windows 32 bit, instead it with fputc32.dll. the source of pli_fputc is in software/pli_fputc_src directory.  
<h3>Software</h3>  1.cd to this directory.  
2.type "make" to build bitstream.exe, gcc is required to build it.  
3.run bitstream.exe to decode the "in.264" file in the same directory.  
To use the open source project, the first step is to replace the input file in projcet with own .264 video. In hardware part, a direct change is enough, while in software part, if you want to change the file name in the code, then you should use commands to 'makefile' in both 3 sub-folders.  
The specific command for 'makefile' depends on a .exe file in the path 'D:\VSCode\MinGW\mingw\bin\mingw32-make.exe'.  
After downloading .mp4 file from video website, you can use ffmpeg to transfer it into .264 file. Default command to achieve this may be not enough, through numerous trials, the most appropriate command is 'ffmpeg -i 2_dance.mp4 -c:v libx264 -profile:v baseline -level 3.1 -refs 1 -bf 0 -r 25 -s 1280x720 -pix_fmt yuv420p -an 2_dance.264'. Besides, you should make sure that the resolution of video can be divided by 16, otherwise when you open the simuliation output file using some softwares, YUV viewer for example, may be in low quality with gray or blue ribbon at the bottom and left of the video, from automatic completion from bilinear interpolation method.  
simulation results:  
<img src="https://github.com/ICscholar/H264_decoder-verilog-Cpp/blob/main/img/simulation_out.png" width="480px">  

<h3>Explanation of DECODER in Hardware:</h3>
<h4>read_nalu_inst</h4>  
a package of NALU= a set of head information of NALU + a series of RBSP(raw byte sequence payload)  
The function of this module includes starting bits of NALU, extracting vedio stream information, reading vedio stream data, and converting bit stream of encoding vedio into RBSP.  

⼀个NALU = ⼀组对应于视频编码的NALU头部信息 + ⼀个原始字节序列负荷(RBSP,Raw Byte Sequence Payload).  
模块的功能包括检测NALU起始字节、提取NALU头信息、读取视频流数据，并将编码视频比特流（EBSP）转换为原始字节序列负载（RBSP）

<h4>rbsp_buffer  </h4>
NALU is the basic unit in encoding video data, and RBSP is one kind of format used in NALU load, used to transfer encoding video stream data.  
The function of this module is extracting RBSP from NALU and perform certain processing and conversion, preparing for further video decoding process.  

NALU是编码视频数据的基本单位，而RBSP是NALU负载的一种格式，用于传输编码视频数据。  
这个模块的功能是从输入的NALU数据中提取RBSP数据，并进行一定的处理和转换，以便进一步的视频解码处理  

<h4>read_exp_golomb_inst </h4> 
指数哥伦布编码（Exp-Golomb coding）,一种无损数据压缩方法  
Exp-Golomb Coding, a kind of condensing method without damage on data

<h4>pps_inst 图像参数集（Picture Parameter Set)</h4>
The parameters parsed in this module including (important parts):  
图像参数集ID（pic_parameter_set_id）  
序列参数集ID（seq_parameter_set_id）  
熵编码模式标志（entropy_coding_mode_flag）  
图片顺序存在标志（pic_order_present_flag）  
参考帧索引（num_ref_idx_l0_active_minus1 和 num_ref_idx_l1_active_minus1）  
加权预测标志（weighted_pred_flag）和加权双向预测标识（weighted_bipred_idc）  
初始量化参数（pic_init_qp_minus26, pic_init_qs_minus26, chroma_qp_index_offset）  
去块滤波控制标志（deblocking_filter_control_present_flag）、限制帧内预测标志（constrained_intra_pred_flag）和冗余图片计数存在标志（redundant)  

<h4> sps_inst 视频序列参数集(Sequence Parameter Set, SPS)</h4>
可用性信息(VUI)部分。VUI提供了关于视频流的额外信息，如纵横比、视频格式、色彩描述  
useful information in video, providing aspect ratio, format code of video and color description.  

<h4> slice_header_inst</h4>
切片类型分成0-9，其中0-4表示B帧或P帧，5-9表示I帧,从代码中可以看出本开源项目并未区分B和P帧  
The kinds of slice types are divided into 0 to 9, where 0-4 represent B frames or P frames, 5-9 represent I frames, from which we can find that this project did not discriminate the B frames and P frames.  

<h3> intra_pred_top </h3>
<h4>intra_pred_calc_inst</h4>
根据不同预测模式,从周边像素获取参考样本值  
计算预测平面,采样周边像素实现预测  
计算方向预测,实现边缘延伸估计预计值  
计算预测模样Sum值,支持DC预测  
根据4x4块循环实现整个MB预测  
输出16个预计值送往IDCT重建 residual  
getting reference values of around pixel values according to different prediction modes  
calculating prediction plane, sample around pixel values to accomplish predictions  
calculate direction predictions, accomplishing extending edges to esitimate prediction values.  
finishing the whole micro-blocks through recycling 4x4 blocks.  

<h4>intra_pred_regs_inst</h4>
平面预测模式的计算：模块根据帧内预测的模式执行不同的计算，如DC预测模式下的累加和舍入操作，以及平面预测模式下的H和V值的计算，这些值反映了像素值沿水平和垂直方向的变化趋势  
种子值的计算：用于平面预测模式中，根据预先计算的a、b、c值生成种子值，这些种子值后续用于生成预测像素值  

calculations on plane prediction mode: the module conducts different kinds of algorithm according to intra predictions, which represnets the trend of change along vertical and horizontal directions.  
seeds calculation: seeds used in plane prediction mode, which would be generated by pre-calculated parameters, a, b and c.

<h3>intra_pred_top</h3>
<h4>inter_pred_load</h4>
luma filter + chroma filter  
luma filter: eliminating spatial redundancy of video data  
chroma filter: besides information of luma, the information of chroma is essential as well. However, the chroma information used to be stored in low resolution, since human eyes' sensitivity is lower than the detailed information of luma.


## 去块滤波器：
去块滤波作用：由于视频编码过程涉及量化操作，较为粗糙，在解码过程中反量化时会导致最终解码出的视频存在边缘模糊的问题，因此需要去块滤波模块提高解码视频的清晰度。  
去块滤波流程可以参考博客：http://t.csdnimg.cn/eFaJX
本项目中硬件实现去块滤波涉及多个变量和工程文件，软件部分可以通过是否注释“deblocking_filter(slice_header, pps);”来决定是否在解码过程中启用去块滤波器。  
硬件部分：exp_golomb_decoding_output_in 控制 disable_deblocking_filter_idc 信号的，若在仿真过程中观察得到‘disable_deblocking_filter_idc’值为0，则deblocking_filter启动







