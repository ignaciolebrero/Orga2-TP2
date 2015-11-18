/* ************************************************************************* */
/* Organizacion del Computador II                                            */
/*                                                                           */
/*   Funciones para ejecutar los filtros y sobre las imagenes                */
/*                                                                           */
/* ************************************************************************* */

#include "runtest.h"
#include "rdtsc.h"

int run_blur(int c, char* src, char* dst, int times){
  BMP* bmp = bmp_read(src);
  if(bmp==0) { return -1;}  // open error
  
  uint8_t* data = bmp_get_data(bmp);
  uint32_t h = *(bmp_get_h(bmp));
  uint32_t w = *(bmp_get_w(bmp));
  if(w%4!=0) { return -1;}  // do not support padding
  
  uint8_t* dataC = 0;
  if(*(bmp_get_bitcount(bmp)) == 24) {
    dataC = malloc(sizeof(uint8_t)*4*h*w);
    to32(w,h,data,dataC);
  } else {
    dataC = data;
  }
  
  unsigned long start, end;
  switch(c){
    case 0:
      RDTSC_START(start);
      C_blur(w,h,dataC);
      RDTSC_STOP(end); 
      break;
    case 1:
      RDTSC_START(start);
      ASM_blur1(w,h,dataC);
      RDTSC_STOP(end);
      break;
    case 2:
      RDTSC_START(start);
      ASM_blur2(w,h,dataC);
      RDTSC_STOP(end);
      break;
    default:
      // return -1;
      break;
  }
  unsigned long delta = end - start;
  printf("%lu", delta);

  if(*(bmp_get_bitcount(bmp)) == 24) {
    to24(w,h,dataC,data);
    free(dataC);
  }
  bmp_delete(bmp);
  return 0;
}

int run_merge(int c, char* src1, char* src2, char* dst, float value, int times){
  if(value>1) value=1; else if(value<0) value=0;
  BMP* bmp1 = bmp_read(src1);
  BMP* bmp2 = bmp_read(src2);
  if(bmp1==0 || bmp2==0) { return -1;}  // open error
  
  uint8_t* data1 = bmp_get_data(bmp1);
  uint8_t* data2 = bmp_get_data(bmp2);
  uint32_t h1 = *(bmp_get_h(bmp1));
  uint32_t w1 = *(bmp_get_w(bmp1));
  uint32_t h2 = *(bmp_get_h(bmp2));
  uint32_t w2 = *(bmp_get_w(bmp2));
  if(w1%4!=0 || w2%4!=0) { return -1;}  // do not support padding
  if( w1!=w2 || h1!=h2 ) { return -1;}  // different image size
  
  uint8_t* data1C = 0;
  uint8_t* data2C = 0;
  if(*(bmp_get_bitcount(bmp1)) == 24) {
    data1C = malloc(sizeof(uint8_t)*4*h1*w1);
    data2C = malloc(sizeof(uint8_t)*4*h2*w2);
    to32(w1,h1,data1,data1C);
    to32(w2,h2,data2,data2C);
  } else {
    data1C = data1;
    data2C = data2;
  }

  unsigned long start, end;
  switch(c){
    case 0:
      RDTSC_START(start);
      C_merge(w1,h1,data1C,data2C,value);
      RDTSC_STOP(end); 
      break;
    case 1:
      RDTSC_START(start);
      ASM_merge1(w1,h1,data1C,data2C,value);
      RDTSC_STOP(end);
      break;
    case 2:
      RDTSC_START(start);
      ASM_merge2(w1,h1,data1C,data2C,value);
      RDTSC_STOP(end);
      break;
    default:
      return -1;
      break;
  }
  unsigned long delta = end - start;
  
  printf("%lu", delta);

  if(*(bmp_get_bitcount(bmp1)) == 24) {
    to24(w1,h1,data1C,data1);
    free(data1C);
    free(data2C);
  }
  bmp_delete(bmp1);
  bmp_delete(bmp2);
  return 0;
}

int run_hsl(int c, char* src, char* dst, float hh, float ss, float ll, int times) {
  BMP* bmp = bmp_read(src);
  if(bmp==0) { return -1;}  // open error
  if(ss>1) ss=1; else if(ss<-1) ss=-1;
  if(ll>1) ll=1; else if(ll<-1) ll=-1;
  uint8_t* data = bmp_get_data(bmp);
  uint32_t h = *(bmp_get_h(bmp));
  uint32_t w = *(bmp_get_w(bmp));
  if(w%4!=0) { return -1;}  // do not support padding
  
  uint8_t* dataC = 0;
  if(*(bmp_get_bitcount(bmp)) == 24) {
    dataC = malloc(sizeof(uint8_t)*4*h*w);
    to32(w,h,data,dataC);
  } else {
    dataC = data;
  }
  
  unsigned long start, end;
  switch(c){
    case 0:
      RDTSC_START(start);
      C_hsl(w,h,dataC,hh,ss,ll);
      RDTSC_STOP(end); 
      break;
    case 1:
      RDTSC_START(start);
      ASM_hsl1(w,h,dataC,hh,ss,ll);
      RDTSC_STOP(end);
      break;
    case 2:
      RDTSC_START(start);
      ASM_hsl2(w,h,dataC,hh,ss,ll);
      RDTSC_STOP(end);
      break;
    default:
      return -1;
      break;
  }
  unsigned long delta = end - start;
  
  printf("%lu", delta);

  if(*(bmp_get_bitcount(bmp)) == 24) {
    to24(w,h,dataC,data);
    free(dataC);
  }
  bmp_delete(bmp);
  return 0;
}
