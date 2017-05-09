/*
 *Inputs:
 *  Both inputs are 1D SORTED arrays with no DUPLICATES. 
 *Outputs:
 *  iou: intersection/union
 *  count of combined (union) elements.
 *  count of common (intersection) elements.
*/
#include "mex.h"
#include "tmwtypes.h"
// #include<stdio.h>

int printUnion(int arr1[], int arr2[], int m, int n)
{
    int i = 0, j = 0;
    int count = 0;
//   for (int i=0;i<m; i++)
//   {
//     printf(" %4d:%5.1f\n ", i, arr1[i]);
//   }
//   printf(" %4d:%4d\n ", m, n);
    while (i < m && j < n)
    {
        if (arr1[i] < arr2[j])
        {
            count++;
            i++;
//       printf(" a:%5.1f ", arr1[i++]);
        }
        else if (arr2[j] < arr1[i])
        {
            count++;
            j++;
//       printf(" b:%5.1f ", arr2[j++]);
        }
        else
        {
            count++;
//       printf(" c:%5.1f ", arr2[j++]);
//       i++;
            i++;
            j++;
        }
    }
    
    /* Print remaining elements of the larger array */
    if (i < m)
    {
        count = count + m-i;
//    printf(" d:%5.1f \n", arr1[i++]);
    }
    if (j < n)
    {
        count = count + n-j;
//       printf(" e:%5.1f \n", arr2[j++]);
    }
//   printf(" Union: %d\n ", count);
    return count;
}

template <class myType>
int printIntersect(myType arr1[], myType arr2[], int m, int n)
{
    int i = 0, j = 0;
    int count = 0;
    while (i < m && j < n)
    {
        if (arr1[i] < arr2[j])
            i++;
        else if (arr2[j] < arr1[i])
            j++;
        else
        {
            count++;
            i++;
            j++;
        }
    }
    return count;
}


/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[])
{
    size_t num1, num2;                   /* size of matrix */
    int count_union, count_intersect;              /* output matrix */
    
//     /* check for proper number of arguments */
//     if(nrhs!=2) {
//         mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs","Two inputs required.");
//     }
//     /* make sure the first input argument is scalar */
//     if( !mxIsDouble(prhs[0]) ) {
//         mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notScalar","Input ar1 must be a scalar.");
//     }
//
//     /* make sure the second input argument is type double */
//     if( !mxIsDouble(prhs[1]) ) {
//         mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notDouble","Input matrix must be type double.");
//     }
    
    /* get the value of the scalar input  */
    mxClassID category;
    category = mxGetClassID(prhs[0]);
//     printf("%d: int32:%d, double: %d, single: %d\n", category, mxINT32_CLASS, mxDOUBLE_CLASS, mxSINGLE_CLASS);
    if (category == mxDOUBLE_CLASS)
    {
        double *ar1, *ar2;              /* 1st PixelIdxList */
        ar1 = (double *) mxGetPr(prhs[0]);
        ar2 = (double *) mxGetPr(prhs[1]);
        num1 = mxGetNumberOfElements(prhs[0]);
        num2 = mxGetNumberOfElements(prhs[1]);
        count_intersect = printIntersect(ar1, ar2, num1, num2);
        // mexPrintf("%d: %d: %d\n", num1, num2, count_intersect);
    }
    else if (category == mxINT32_CLASS)
    {
        int *ar1, *ar2;              /* 1st PixelIdxList */
        mexPrintf("int32\n");
        ar1 = (int *) mxGetData(prhs[0]);
        ar2 = (int *) mxGetData(prhs[1]);
        num1 = mxGetNumberOfElements(prhs[0]);
        num2 = mxGetNumberOfElements(prhs[1]);
        //count_intersect = printIntersect<int>(ar1, ar2, num1, num2);
    }
    else if (category == mxSINGLE_CLASS)
    {   
        count_intersect = -1;
    }

    count_union = num1+num2-count_intersect;
    double iou;
    iou = (double)count_intersect/(double)count_union;
    
//     printf("%d::: Union: %d, Inter: %d, iou: %1.3f\n ", nlhs, count_union, count_intersect, iou);
    /* get a pointer to the real data in the output matrix */
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(plhs[0])=iou;
    if (nlhs > 1)
    {
        plhs[1]=mxCreateDoubleMatrix(1,1,mxREAL);
        *mxGetPr(plhs[1])=(double)count_union;
    }
    if (nlhs > 2)
    {
        plhs[2]=mxCreateDoubleMatrix(1,1,mxREAL);
        *mxGetPr(plhs[2])=(double)count_intersect;
    }
}
