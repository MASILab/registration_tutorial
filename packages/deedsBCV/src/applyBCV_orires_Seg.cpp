#include <iostream>
#include <fstream>
#include <math.h>
#include <sys/time.h>
#include <vector>
#include <algorithm>
#include <numeric>
#include <functional>
#include <string.h>
#include <map>
#include <sstream>
#include <x86intrin.h>
#include <pthread.h>
#include <thread>
#include "zlib.h"
#include <sys/stat.h>

using namespace std;

//some global variables
int RAND_SAMPLES; //will all be set later (if needed)
int image_m; int image_n; int image_o; int image_d=1;
int image_m2; int image_n2; int image_o2; int image_d2=1;
float SSD0=0.0; float SSD1=0.0; float SSD2=0.0; float distfx_global; float beta=1;
//float SIGMA=8.0;
int qc=1;

//struct for multi-threading of mind-calculation
struct mind_data{
	float* im1;
    float* d1;
    uint64_t* mindq;
    int qs;
    int ind_d1;
};



struct parameters{
    float alpha; int levels=0; bool segment,affine,rigid;
    vector<int> grid_spacing; vector<int> search_radius;
    vector<int> quantisation;
    string fixed_file,moving_file,output_stem,moving_seg_file,affine_file,deformed_file,jacobian_file;
};

#include "imageIOgzType.h"
#include "transformations.h"
//#include "primsMST.h"
//#include "regularisation.h"
//#include "MINDSSCbox.h"
#include "dataCostD.h"
#include "parseArguments.h"


int main (int argc, char * const argv[]) {
	//Initialise random variable

    
    //PARSE INPUT ARGUMENTS
    
    if(argc<4||argv[1][1]=='h'){
        cout<<"=============================================================\n";
        cout<<"Usage (required input arguments):\n";
        cout<<"./applyBCV_ories -M moving.nii.gz -F fixed.nii.gz -O output -D deformed.nii.gz \n";
        cout<<"optional parameters:\n";
        cout<<" -A <affine_matrix.txt> \n";
        cout<<"=============================================================\n";
        return 1;
    }

    parameters args;
    parseCommandLine(args, argc, argv);
    
    size_t split_def=args.deformed_file.find_last_of("/\\");
    if(split_def==string::npos){
        split_def=-1;
    }
    size_t split_moving=args.moving_file.find_last_of("/\\");
    if(split_moving==string::npos){
        split_moving=-1;
    }
    
    
    if(args.deformed_file.substr(args.deformed_file.length()-2)!="gz"){
        cout<<"images must have nii.gz format\n";
        return -1;
    }
    if(args.moving_file.substr(args.moving_file.length()-2)!="gz"){
        cout<<"images must have nii.gz format\n";
        return -1;
    }
    if(args.fixed_file.substr(args.fixed_file.length()-2)!="gz"){
        cout<<"images must have nii.gz format\n";
        return -1;
    }
    cout<<"Transforming "<<args.moving_file.substr(split_moving+1)<<" into "<<args.deformed_file.substr(split_def+1)<<"\n";
    

    
    
    //READ IMAGES and INITIALISE ARRAYS
    
    timeval time1,time2,time1a,time2a;
    

    float* img2;
    float* img2f;
    int M,N,O,P; //image dimensions
    int M2,N2,O2,P2; //image dimensions
    float vox1, voy1, voz1; //voxel size
    float vox2, voy2, voz2; //voxel size
    
    //==ALWAYS ALLOCATE MEMORY FOR HEADER ===/
    char* header=new char[352];
    char* header2=new char[352];
    
    readNiftiVolSize(args.moving_file,img2,header,M,N,O,P,vox1,voy1,voz1);
    readNiftiVolSize(args.fixed_file,img2f,header2,M2,N2,O2,P2,vox2,voy2,voz2);
    
    image_m=M; image_n=N; image_o=O;    
    int m=image_m; int n=image_n; int o=image_o; int sz=m*n*o;
    image_m2=M2; image_n2=N2; image_o2=O2;    
    int m2=image_m2; int n2=image_n2; int o2=image_o2; int sz2=m2*n2*o2;
    
    
    //READ AFFINE MATRIX from linearBCV if provided (else start from identity)
    
    float* X=new float[16];
    
    if(args.affine){
        size_t split_affine=args.affine_file.find_last_of("/\\");
        if(split_affine==string::npos){
            split_affine=-1;
        }
        
        cout<<"Reading affine matrix file: "<<args.affine_file.substr(split_affine+1)<<"\n";
        ifstream matfile;
        matfile.open(args.affine_file);
        for(int i=0;i<4;i++){
            string line;
            getline(matfile,line);
            sscanf(line.c_str(),"%f  %f  %f  %f",&X[i],&X[i+4],&X[i+8],&X[i+12]);
        }
        matfile.close();
        
        
    }
    else{
        cout<<"Using identity transform.\n";
        fill(X,X+16,0.0f);
        X[0]=1.0f; X[1+4]=1.0f; X[2+8]=1.0f; X[3+12]=1.0f;
    }
    
    for(int i=0;i<4;i++){
        printf("%+4.3f | %+4.3f | %+4.3f | %+4.3f \n",X[i],X[i+4],X[i+8],X[i+12]);//X[i],X[i+4],X[i+8],X[i+12]);
        
    }

    //affine matrix with voxel size for moving image
    float* B1 = new float[16];
    fill(B1,B1+16,0.0f);
    B1[0]=vox1; B1[1+4]=voy1; B1[2+8]=voz1; B1[3+12]=1.0f;
    //affine matrix with voxel size for fix image
    float* B2 = new float[16];
    fill(B2,B2+16,0.0f);
    B2[0]=vox2; B2[1+4]=voy2; B2[2+8]=voz2; B2[3+12]=1.0f;
    
    float scale_1, scale_2, scale_3;
    scale_1 = (float)m/(float)m2;
    scale_2 = (float)n/(float)n2;
    scale_3 = (float)o/(float)o2;

    // //Yuankai add to save affine results
	// float* uax=new float[sz]; float* vax=new float[sz]; float* wax=new float[sz];
	// for(int i=0;i<sz;i++){
	// 	uax[i]=0.0; vax[i]=0.0; wax[i]=0.0;
	// }
    // float* warped00=new float[m*n*o];
    // // warpAffine(warped00,img2,img2,X,uax,vax,wax);
    // warpAffine_debug(warped00,img2,img2,X,uax,vax,wax,scale_1,scale_2,scale_3, B1, B2);
    // string affine_out = args.deformed_file;
    // string nii_gz = ".nii.gz";
    // string affine_nii_gz = "_affine.nii.gz";
    // affine_out.replace(affine_out.find(nii_gz), nii_gz.length(), affine_nii_gz);
    // gzWriteNifti(affine_out,warped00,header,m,n,o,1);
    
    
    string inputflow;
    inputflow.append(args.output_stem);
    inputflow.append("_displacements.dat");
    
    cout<<"Reading displacements from:\n"<<inputflow<<"\n";
    
    
    cout<<"=============================================================\n";
    
    vector<float> flow=readFile<float>(inputflow);
    
    int sz3=flow.size()/6;
    int grid_step=round(pow((float)sz2/(float)sz3,0.3333333));

    cout<<"grid step "<<grid_step<<"\n";
    
    int step1; int hw1; float quant1;
    
    //set initial flow-fields to 0; i indicates backward (inverse) transform
    //u is in x-direction (2nd dimension), v in y-direction (1st dim) and w in z-direction (3rd dim)
    float* ux=new float[sz]; float* vx=new float[sz]; float* wx=new float[sz];
    for(int i=0;i<sz;i++){
        ux[i]=0.0; vx[i]=0.0; wx[i]=0.0;
    }
    
    int m1,n1,o1,sz1;
    m1=m2/grid_step; n1=n2/grid_step; o1=o2/grid_step; sz1=m1*n1*o1;
    float* u1=new float[sz1]; float* v1=new float[sz1]; float* w1=new float[sz1];
   
    for(int i=0;i<sz1;i++){
        u1[i]=flow[i]; v1[i]=flow[i+sz1]; w1[i]=flow[i+sz1*2];
        
    }

    upsampleDeformations_debug(ux,vx,wx,u1,v1,w1,m,n,o,m1,n1,o1);


    
    float* warped=new float[sz];
    
    fill(warped,warped+sz,(short)0);


    // //warpAffine_scale(warped,img2,img2,X,ux,vx,wx,scale_1,scale_2,scale_3);
    // float* X_scale=new float[16];
    // fill(X_scale,X_scale+16,0.0f);
    // X_scale[0] = 1.0f;
    // X_scale[5] = 1.0f;
    // X_scale[10] = 1.0f;
    // X_scale[15] = 1.0f;
    // float* X_final=new float[16];
    // float* a = X;
    // float* b = X_scale;
    // float q[16];
    // q[ 0]=(a[ 0]*b[ 0])+(a[ 1]*b[ 4])+(a[ 2]*b[ 8])+(a[ 3]*b[12]);
    // q[ 1]=(a[ 0]*b[ 1])+(a[ 1]*b[ 5])+(a[ 2]*b[ 9])+(a[ 3]*b[13]);
    // q[ 2]=(a[ 0]*b[ 2])+(a[ 1]*b[ 6])+(a[ 2]*b[10])+(a[ 3]*b[14]);
    // q[ 3]=(a[ 0]*b[ 3])+(a[ 1]*b[ 7])+(a[ 2]*b[11])+(a[ 3]*b[15]);
    // q[ 4]=(a[ 4]*b[ 0])+(a[ 5]*b[ 4])+(a[ 6]*b[ 8])+(a[ 7]*b[12]);
    // q[ 5]=(a[ 4]*b[ 1])+(a[ 5]*b[ 5])+(a[ 6]*b[ 9])+(a[ 7]*b[13]);
    // q[ 6]=(a[ 4]*b[ 2])+(a[ 5]*b[ 6])+(a[ 6]*b[10])+(a[ 7]*b[14]);
    // q[ 7]=(a[ 4]*b[ 3])+(a[ 5]*b[ 7])+(a[ 6]*b[11])+(a[ 7]*b[15]);
    // q[ 8]=(a[ 8]*b[ 0])+(a[ 9]*b[ 4])+(a[10]*b[ 8])+(a[11]*b[12]);
    // q[ 9]=(a[ 8]*b[ 1])+(a[ 9]*b[ 5])+(a[10]*b[ 9])+(a[11]*b[13]);
    // q[10]=(a[ 8]*b[ 2])+(a[ 9]*b[ 6])+(a[10]*b[10])+(a[11]*b[14]);
    // q[11]=(a[ 8]*b[ 3])+(a[ 9]*b[ 7])+(a[10]*b[11])+(a[11]*b[15]);
    // q[12]=(a[12]*b[ 0])+(a[13]*b[ 4])+(a[14]*b[ 8])+(a[15]*b[12]);
    // q[13]=(a[12]*b[ 1])+(a[13]*b[ 5])+(a[14]*b[ 9])+(a[15]*b[13]);
    // q[14]=(a[12]*b[ 2])+(a[13]*b[ 6])+(a[14]*b[10])+(a[15]*b[14]);
    // q[15]=(a[12]*b[ 3])+(a[13]*b[ 7])+(a[14]*b[11])+(a[15]*b[15]);
    // for(int i=0;i<16;i++) X_final[i]=q[i];

    // warpAffine_debug(warped,img2,img2,X,ux,vx,wx,scale_1,scale_2,scale_3);
    //warpAffine(warped,warped00,warped00,X_scale,ux,vx,wx);
    warpAffineOriginS(warped,img2,img2,X,ux,vx,wx,scale_1,scale_2,scale_3, B1, B2);
    
    gzWriteNifti(args.deformed_file,warped,header,m,n,o,1);

    
	
	
	return 0;
}
