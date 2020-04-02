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


void warpAffineSinv(short* warped,short* input,float* X,float* u1,float* v1,float* w1){
    int m=image_m;
    int n=image_n;
    int o=image_o;
    int sz=m*n*o;
    for(int k=0;k<o;k++){
        for(int j=0;j<n;j++){
            for(int i=0;i<m;i++){


                float x2=(float)i*X[0]+(float)j*X[1]+(float)k*X[2]+(float)X[3];
                float y2=(float)i*X[4]+(float)j*X[5]+(float)k*X[6]+(float)X[7];
                float z2=(float)i*X[8]+(float)j*X[9]+(float)k*X[10]+(float)X[11];
                int x=round(x2); int y=round(y2);  int z=round(z2);

                float x1=x2+v1[min(max(x,0),m-1)+min(max(y,0),n-1)*m+min(max(z,0),o-1)*m*n];
                float y1=y2+u1[min(max(x,0),m-1)+min(max(y,0),n-1)*m+min(max(z,0),o-1)*m*n];
                float z1=z2+w1[min(max(x,0),m-1)+min(max(y,0),n-1)*m+min(max(z,0),o-1)*m*n];

                x=round(x1); y=round(y1); z=round(z1);

                //if(y>=0&x>=0&z>=0&y<m&x<n&z<o){
                    warped[i+j*m+k*m*n]=input[min(max(x,0),m-1)+min(max(y,0),n-1)*m+min(max(z,0),o-1)*m*n];
                //}
                //else{
                //    warped[i+j*m+k*m*n]=0;
                //}
            }
        }
    }


}
int main (int argc, char * const argv[]) {
	//Initialise random variable


    //PARSE INPUT ARGUMENTS

    if(argc<4||argv[1][1]=='h'){
        cout<<"=============================================================\n";
        cout<<"Usage (required input arguments):\n";
        cout<<"./applyBCV -M moving.nii.gz -O output -D deformed.nii.gz \n";
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

    cout<<"Transforming "<<args.moving_file.substr(split_moving+1)<<" into "<<args.deformed_file.substr(split_def+1)<<"\n";




    //READ IMAGES and INITIALISE ARRAYS

    timeval time1,time2,time1a,time2a;


    short* seg2;
    int M,N,O,P; //image dimensions

    //==ALWAYS ALLOCATE MEMORY FOR HEADER ===/
    char* header=new char[352];

    readNifti(args.moving_file,seg2,header,M,N,O,P);
    image_m=M; image_n=N; image_o=O;

    int m=image_m; int n=image_n; int o=image_o; int sz=m*n*o;
    cout<<"seg2 m"<<m<<" n"<<n<<" o"<<o<<endl;



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




    string inputflow;
    inputflow.append(args.output_stem);
    inputflow.append("_displacements.dat");

    cout<<"Reading displacements from:\n"<<inputflow<<"\n";


    cout<<"=============================================================\n";

    vector<float> flow=readFile<float>(inputflow);

    int sz3=flow.size()/6;
    int grid_step=round(pow((float)sz/(float)sz3,0.3333333));

    cout<<"grid step "<<grid_step<<"\n";

    int step1; int hw1; float quant1;

    //set initial flow-fields to 0; i indicates backward (inverse) transform
    //u is in x-direction (2nd dimension), v in y-direction (1st dim) and w in z-direction (3rd dim)
    float* ux=new float[sz]; float* vx=new float[sz]; float* wx=new float[sz];
    for(int i=0;i<sz;i++){
        ux[i]=0.0; vx[i]=0.0; wx[i]=0.0;
    }

    int m1,n1,o1,sz1;
    m1=m/grid_step; n1=n/grid_step; o1=o/grid_step; sz1=m1*n1*o1;
    float* u1=new float[sz1]; float* v1=new float[sz1]; float* w1=new float[sz1];
    cout << "using inverse transformation" <<"\n";
    for(int i=0;i<sz1;i++){
        u1[i]=flow[i+sz1*3]; v1[i]=flow[i+sz1*4]; w1[i]=flow[i+sz1*5];

    }
    //cout<<"read flow successfully"<<endl;
    upsampleDeformationsCL(ux,vx,wx,u1,v1,w1,m,n,o,m1,n1,o1);


    //cout<<"upsampled flow successfully"<<endl;

    short* segw=new short[sz];

    fill(segw,segw+sz,(short)0);

    warpAffineSinv(segw,seg2,X,ux,vx,wx);

    //cout<<"applied warp successfully"<<endl;


    gzWriteSegment(args.deformed_file,segw,header,m,n,o,1);




	return 0;
}
