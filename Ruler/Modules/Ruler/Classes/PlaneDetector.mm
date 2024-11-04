//
//  PlaneDetector.m
//  Ruler
//
//  Created by Tbxark on 18/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <opencv2/opencv.hpp>

@implementation PlaneDetector : NSObject 

+ (SCNVector4)detectPlaneWithPoints:(NSArray <NSValue* >*)points {
    cv::Mat points_mat((int)points.count, 3, CV_32FC1);
    
    for (int i = 0; i < points.count; i++) {
        NSValue *warp = points[i];
        SCNVector3 point = warp.SCNVector3Value;
        points_mat.at<float>(i, 0) = point.x;
        points_mat.at<float>(i, 1) = point.y;
        points_mat.at<float>(i, 2) = point.z;
    }
    
    float plane[4] = {0};
    detectPlane(points_mat, plane);
    return SCNVector4Make(plane[0], plane[1], plane[2], plane[3]);
}

void detectPlane(const cv::Mat& points, float* plane) {
    int nrows = points.rows;
    int ncols = points.cols;
    
    // Estimate geometric centroid
    cv::Mat centroid = cv::Mat::zeros(1, ncols, CV_32F);
    for (int c = 0; c < ncols; c++) {
        for (int r = 0; r < nrows; r++) {
            centroid.at<float>(0, c) += points.at<float>(r, c);
        }
        centroid.at<float>(0, c) /= nrows;
    }

    // Subtract centroid from points
    cv::Mat points2 = points - cv::repeat(centroid, nrows, 1);

    // Perform SVD on the covariance matrix
    cv::Mat A = points2.t() * points2;
    cv::Mat W, U, Vt;
    cv::SVD::compute(A, W, U, Vt);

    // Assign plane coefficients by the smallest singular value
    for (int c = 0; c < ncols; c++) {
        plane[c] = Vt.at<float>(2, c);
        plane[3] += plane[c] * centroid.at<float>(0, c);
    }
}

+ (float)area3DOfPolygon:(NSArray<NSValue *> *)points {
    SCNVector3 *v = (SCNVector3 *)malloc(sizeof(SCNVector3) * points.count);
    for (int i = 0; i < points.count; i++) {
        v[i] = points[i].SCNVector3Value;
    }
    // Implement the area calculation here
    return 0;
}

@end
