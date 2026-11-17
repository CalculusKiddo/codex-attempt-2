#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#define vtbl2q_u8 vqtbl2_u8
#define MINIH264_IMPLEMENTATION
#define H264E_SVC_API 0
#define H264E_MAX_THREADS 0
#include "minih264e.h"
#define bs_t mp4_bs_t
#define nal_put_esc mp4_nal_put_esc
#define MINIMP4_IMPLEMENTATION
#include "minimp4.h"
static H264E_persist_t *enc;
static H264E_scratch_t *scratch;
static H264E_io_yuv_t yuv;
static H264E_run_param_t run;
static MP4E_mux_t *mux;
static mp4_h26x_writer_t track;
static FILE *output;
static int w,h,rate;
static int write_mp4(int64_t off,const void *p,size_t n,void *token){FILE *f=token;return fseek(f,off,SEEK_SET)||fwrite(p,1,n,f)!=n;}
int video_open(const char *path,int width,int height,int fps){
 w=width;h=height;rate=fps;
 H264E_create_param_t p={0};p.width=w;p.height=h;p.gop=fps*5;p.enableNEON=1;p.const_input_flag=1;
 int a,b;if(H264E_sizeof(&p,&a,&b))return 1;
 enc=aligned_alloc(64,(a+63)&~63);scratch=aligned_alloc(64,(b+63)&~63);
 if(H264E_init(enc,&p))return 2;
 unsigned char *mem=aligned_alloc(64,((w*h*3/2)+63)&~63);
 yuv.yuv[0]=mem;yuv.yuv[1]=mem+w*h;yuv.yuv[2]=mem+w*h*5/4;
 yuv.stride[0]=w;yuv.stride[1]=yuv.stride[2]=w/2;
 run.encode_speed=8;run.desired_frame_bytes=400000/8/fps;run.qp_min=20;run.qp_max=35;
 output=fopen(path,"wb");if(!output)return 3;
 mux=MP4E_open(0,0,output,write_mp4);if(!mux)return 4;
 return mp4_h26x_write_init(&track,mux,w,h,0);
}
static unsigned char clamp(int n){return n<0?0:n>255?255:n;}
int video_frame(const unsigned char *argb){
 for(int y=0;y<h;y++)for(int x=0;x<w;x++){
   const unsigned char *p=argb+(y*w+x)*4;
   int r=p[1],g=p[2],b=p[3];
   yuv.yuv[0][y*w+x]=clamp(((66*r+129*g+25*b+128)>>8)+16);
   if(!(y&1)&&!(x&1)){
     int idx=y/2*(w/2)+x/2;
     yuv.yuv[1][idx]=clamp(((-38*r-74*g+112*b+128)>>8)+128);
     yuv.yuv[2][idx]=clamp(((112*r-94*g-18*b+128)>>8)+128);
   }
 }
 unsigned char *data;int n;int err=H264E_encode(enc,scratch,&run,&yuv,&data,&n);if(err)return err;
 return mp4_h26x_write_nal(&track,data,n,90000/rate);
}
int video_close(void){mp4_h26x_write_close(&track);int e=MP4E_close(mux);fclose(output);free(enc);free(scratch);free(yuv.yuv[0]);return e;}
