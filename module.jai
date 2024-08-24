//  ------------------------
// | MATH_DXM (DIRECTXMATH) |
//  ------------------------

// A hand-rolled extension for the Math module in congruence with DirectXMath.

// TODO: make use of Matrix4x3?
XMMATRIX :: Matrix4;

XMVECTOR :: struct {
    #as using base: Vector4;
    // DXM specific:
#place x;
    u: [4] u32 = ---;
}

// XMVECTORU32 etc. redundant thanks to #place :)

XMVECTOR_ZERO :: XMVECTOR.{x=0, y=0, z=0, w=0};

XM_SELECT_0 :: 0x00000000;
XM_SELECT_1 :: 0xFFFFFFFF;

g_XMSelect1110 : XMVECTOR : .{u[0]=XM_SELECT_1, u[1]=XM_SELECT_1, u[2]=XM_SELECT_1, u[3]=XM_SELECT_0};

g_XMIdentityR3 :: XMVECTOR.{x=0, y=0, z=0, w=1};

operator - :: (a: Vector4) -> Vector4 {
    return .{-a.x, -a.y, -a.z, -a.w};
}

print_xmmatrix :: (m: XMMATRIX) {
    print("%\n", row(m, 0));
    print("%\n", row(m, 1));
    print("%\n", row(m, 2));
    print("%\n", row(m, 3));
}

XMConvertToRadians :: (fDegrees: float) -> float {
    return fDegrees * (PI / 180);
}

// TODO
// XMScalarSinCos :: (pSin: *float, pCos: *float, Value: float) {
//     assert(pSin);
//     assert(pCos);

//     // ...
// }

XMVectorSelect :: (V1: XMVECTOR, V2: XMVECTOR, Control: XMVECTOR) -> XMVECTOR {
    Result: XMVECTOR;
    for 0..3 {
	Result.u[it] = (V1.u[it] & ~Control.u[it]) | (V2.u[it] & Control.u[it]);
    }
    return Result;
}

XMVector3Dot :: (V1: Vector3, V2: Vector3) -> XMVECTOR {
    dp := dot(V1, V2);
    return xx make_vector4(dp);
} 

XMMatrixLookAtLH :: (
    EyePosition: XMVECTOR,
    FocusPosition: XMVECTOR,
    UpDirection: XMVECTOR
) -> XMMATRIX {
    
    EyeDirection : XMVECTOR = xx (FocusPosition - EyePosition);
    return XMMatrixLookToLH(EyePosition, EyeDirection, UpDirection);
}

XMMatrixLookToLH :: (
    EyePosition: XMVECTOR,
    EyeDirection: XMVECTOR,
    UpDirection: XMVECTOR
) -> XMMATRIX {
    
    // TODO: check for infinite?
    assert(EyeDirection != XMVECTOR_ZERO);
    assert(UpDirection != XMVECTOR_ZERO);

    // Operations are on Vector3 component of XMVECTOR
    R2 := normalize(EyeDirection.xyz);  
    R0 := cross(UpDirection.xyz, R2);
    R0 = normalize(R0);

    R1 := cross(R2, R0);
    NegEyePosition := -EyePosition;

    D0 := XMVector3Dot(R0, NegEyePosition.xyz);
    D1 := XMVector3Dot(R1, NegEyePosition.xyz);
    D2 := XMVector3Dot(R2, NegEyePosition.xyz);

    M: XMMATRIX;

    M.v[0] = XMVectorSelect(D0, xx R0, g_XMSelect1110);
    M.v[1] = XMVectorSelect(D1, xx R1, g_XMSelect1110);
    M.v[2] = XMVectorSelect(D2, xx R2, g_XMSelect1110);
    M.v[3] = g_XMIdentityR3;

    M = transpose(M);
    return M;
}

XMMatrixPerspectiveFovLH :: (
    FovAngleY: float,
    AspectRatio: float,
    NearZ: float,
    FarZ: float
) -> XMMATRIX {

    // TODO
    cpu_info := get_cpu_info();
    if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.AVX2) {
        #asm AVX2 {}
    }
    if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.AVX) {
        #asm AVX {}
    }
    if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.SSE2) {
	#asm SSE2 {}
    }
    // If your CPU doesn't support SSE2, that's a you problem.
    else {}

    // SCALAR
    // XMScalarSinCos is probably more efficient
    SinFov := sin(0.5 * FovAngleY);
    CosFov := cos(0.5 * FovAngleY);

    Height := CosFov / SinFov;
    Width := Height / AspectRatio;
    fRange := FarZ / (FarZ - NearZ);

    M := XMMATRIX.{
	Width, 0, 0, 0,
	0, Height, 0, 0,
	0, 0, fRange, 1,
	0, 0, -fRange * NearZ, 1
    };
    
    return M;
}

#import "Basic";
#import "Math";
#import "Machine_X64";
