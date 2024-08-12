//  ------------------------
// | MATH_DXM (DIRECTXMATH) |
//  ------------------------

// A hand-rolled extension for the Math module in congruence with DirectXMath.

operator - :: (a: Vector4) -> Vector4 {
    return .{-a.x, -a.y, -a.z, -a.w};
}

// TYPES ------------------------------------------------------

// TODO: make use of Matrix4x3?
XMMATRIX :: Matrix4;

XMVECTOR :: struct {
    #as using base: Vector4;
    // DXM specific:
#place x;
    u: [4] u32 = ---;
}

// XMVECTORU32 etc. redundant thanks to #place :)

// CONSTANTS --------------------------------------------------

XMVECTOR_ZERO :: XMVECTOR.{x=0, y=0, z=0, w=0};

g_XMIdentityR3 :: XMVECTOR.{x=0, y=0, z=0, w=1};

XM_SELECT_0 :: 0x00000000;
XM_SELECT_1 :: 0xFFFFFFFF;

g_XMSelect1110 : XMVECTOR : .{u[0]=XM_SELECT_1, u[1]=XM_SELECT_1, u[2]=XM_SELECT_1, u[3]=XM_SELECT_0};
g_XMMaskY : XMVECTOR : .{u[0]=XM_SELECT_0, u[1]=XM_SELECT_1, u[2]=XM_SELECT_0, u[3]=XM_SELECT_0};

XM_PI :: PI64;
XM_2PI :: 6.283185307;
XM_1DIVPI :: 0.318309886;
XM_1DIV2PI :: 0.159154943;
XM_PIDIV2 :: 1.570796327;
XM_PIDIV4 :: 0.785398163;

// PROCEDURES -------------------------------------------------

print_xmmatrix :: (m: XMMATRIX) {
    print("%\n", row(m, 0));
    print("%\n", row(m, 1));
    print("%\n", row(m, 2));
    print("%\n", row(m, 3));
}

XMConvertToRadians :: (fDegrees: float) -> float {
    return fDegrees * (PI / 180);
}

XMScalarSinCos :: (pSin: *float, pCos: *float, Value: float) {
    assert(pSin != null);
    assert(pCos != null);

    quotient := XM_1DIV2PI * Value;

    if Value >= 0.0 quotient = cast(float)(cast(s32)(quotient + 0.5));
    else quotient = cast(float)(cast(s32)(quotient - 0.5));

    y := Value - XM_2PI * quotient;

    sign: float;
    if y > XM_PIDIV2 { y = XM_PI -y; sign = -1; }
    else if y < -XM_PIDIV2 { y = XM_PI -y; sign = -1; }
    else sign = +1;

    y2 := square(y);

    pSin.* = cast(float)((((((-2.3889859e-08 * y2 + 2.7525562e-06) * y2 - 0.00019840874) * y2 + 0.0083333310) * y2 - 0.16666667) * y2 + 1.0) * y);

    p := ((((-2.6051615e-07 * y2 + 2.4760495e-05) * y2 - 0.0013888378) * y2 + 0.041666638) * y2 - 0.5) * y2 + 1.0;

    pCos.* = cast(float)(sign * p);
}

XMVector3Dot :: (V1: Vector3, V2: Vector3) -> XMVECTOR {
    dp := dot(V1, V2);
    return xx make_vector4(dp);
}

XMVectorSelect :: (
    V1: XMVECTOR,
    V2: XMVECTOR,
    Control: XMVECTOR
) -> XMVECTOR {
    
    Result: XMVECTOR;
    for 0..3 {
	Result.u[it] = (V1.u[it] & ~Control.u[it]) | (V2.u[it] & Control.u[it]);
    }
    return Result;
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

    // SinFov := sin(0.5 * FovAngleY);
    // CosFov := cos(0.5 * FovAngleY);
    // XMScalarSinCos possibly faster?
    SinFov, CosFov: float;
    XMScalarSinCos(*SinFov, *CosFov, 0.5 * FovAngleY);

    fRange := FarZ / (FarZ - NearZ);
    Height := CosFov / SinFov;
    
    // _MM_SHUFFLE(z, y, x, w) :: (z << 6) | (y << 4) | (x << 2) | w

    cpu_info := get_cpu_info();
    // TODO @Speed
    // if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.AVX2) {
    //     #asm AVX2 {}
    // }
    // if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.AVX) {
    //     #asm AVX {}
    // }
    if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.SSE2) {

        vValues := XMVECTOR.{
	    x=Height/AspectRatio,
	    y=Height,
	    z=fRange,
	    w=-fRange*NearZ
	};

	vTemp: XMVECTOR;
	M: XMMATRIX;
	
	#asm SSE2 {
	    movss vTemp, vValues;
	}
	// print("[DXM] vTemp: %\n", vTemp);
	M.v[0] = vTemp;
	vTemp = vValues;
	// Pull constant to stack:
	ymask := g_XMMaskY;
	#asm SSE2 { andps vTemp, ymask; }
	M.v[1] = vTemp;
	ident := g_XMIdentityR3;
	#asm SSE2 {
	    xorps vTemp, vTemp;
	    shufps vValues, ident, (3 << 6) | (2 << 4) | (3 << 2) | 2;
	    shufps vTemp, vValues, (3 << 6) | (0 << 4) | (0 << 2) | 0;
	}
	M.v[2] = vTemp;
	#asm SSE2 { shufps vTemp, vValues, (2 << 6) | (1 << 4) | (0 << 2) | 0; }
	M.v[3] = vTemp;

	return M;
    }
    // If your CPU doesn't support SSE2, that's a you problem.
    // SCALAR
    Width := Height / AspectRatio;

    M := XMMATRIX.{
	Width, 0, 0, 0,
	0, Height, 0, 0,
	0, 0, fRange, 1,
	0, 0, -fRange*NearZ, 1
    };
    
    return M;
}

XMMatrixOrthographicLH :: (
    ViewWidth: float,
    ViewHeight: float,
    NearZ: float,
    FarZ: float
) -> XMMATRIX {

    fRange := 1 / ViewWidth;
    
    cpu_info := get_cpu_info();
    // TODO @Speed
    // if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.AVX2) {
    //     #asm AVX2 {}
    // }
    // if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.AVX) {
    //     #asm AVX {}
    // }
    if check_feature(cpu_info.feature_leaves, x86_Feature_Flag.SSE2) {

	vValues := XMVECTOR.{
	    x=2/ViewWidth,
	    y=2/ViewHeight,
	    z=fRange,
	    w=-fRange*NearZ
	};

	vTemp: XMVECTOR;
	M: XMMATRIX;

	#asm { movss vTemp, vValues; }
	M.v[0] = vTemp;
	vTemp = vValues;
	ymask := g_XMMaskY;
	#asm { andps vTemp, ymask; }
	M.v[1] = vTemp;
	ident := g_XMIdentityR3;
	#asm {
	    xorps vTemp, vTemp;
	    shufps vValues, ident, (3 << 6) | (2 << 4) | (3 << 2) | 2;
	    shufps vTemp, vValues, (2 << 6) | (0 << 4) | (0 << 2) | 0;
	}
	M.v[2] = vTemp;
	#asm { shufps vTemp, vValues, (3 << 6) | (1 << 4) | (0 << 2) | 0; }
	M.v[3] = vTemp;

	return M;
    }
    // SCALAR
    M := XMMATRIX.{
	2/ViewWidth, 0, 0, 0,
	0, 2/ViewHeight, 0, 0,
	0, 0, fRange, 0,
	0, 0, -fRange*NearZ, 1
    };

    return M;
}

#import "Basic";
#import "Math";
#import "Machine_X64";
