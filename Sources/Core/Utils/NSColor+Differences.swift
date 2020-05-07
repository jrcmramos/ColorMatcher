//

import Foundation
import AppKit

// Based on https://github.com/jathu/sweetercolor/blob/master/Sweetercolor/Sweetercolor.swift

extension NSColor {
    /**
        Get the red, green, blue and alpha values.

        - returns: An array of four CGFloat numbers from [0, 1] representing RGBA respectively.
    */
    var RGBA: [CGFloat] {
        var R: CGFloat = 0
        var G: CGFloat = 0
        var B: CGFloat = 0
        var A: CGFloat = 0
        self.getRed(&R, green: &G, blue: &B, alpha: &A)
        return [R,G,B,A]
    }



    /**
        Get the 8 bit red, green, blue and alpha values.

        - returns: An array of four CGFloat numbers from [0, 255] representing RGBA respectively.
    */
    var RGBA_8Bit: [CGFloat] {
        let RGBA = self.RGBA
        return [round(RGBA[0] * 255), round(RGBA[1] * 255), round(RGBA[2] * 255), RGBA[3]]
    }



    /**
        Get the hue, saturation, brightness and alpha values.

        - returns: An array of four CGFloat numbers from [0, 255] representing HSBA respectively.
    */
    var HSBA: [CGFloat] {
        var H: CGFloat = 0
        var S: CGFloat = 0
        var B: CGFloat = 0
        var A: CGFloat = 0
        self.getHue(&H, saturation: &S, brightness: &B, alpha: &A)
        return [H,S,B,A]
    }



    /**
        Get the 8 bit hue, saturation, brightness and alpha values.

        - returns: An array of four CGFloat numbers representing HSBA respectively. Ranges: H[0,360], S[0,100], B[0,100], A[0,1]
    */
    var HSBA_8Bit: [CGFloat] {
        let HSBA = self.HSBA
        return [round(HSBA[0] * 360), round(HSBA[1] * 100), round(HSBA[2] * 100), HSBA[3]]
    }



    /**
        Get the CIE XYZ values.

        - returns: An array of three CGFloat numbers representing XYZ respectively.
    */
    var XYZ: [CGFloat] {
        // http://www.easyrgb.com/index.php?X=MATH&H=02#text2

        let RGBA = self.RGBA

        func XYZ_helper(c: CGFloat) -> CGFloat {
            return (0.04045 < c ? pow((c + 0.055)/1.055, 2.4) : c/12.92) * 100
        }

        let R = XYZ_helper(c: RGBA[0])
        let G = XYZ_helper(c: RGBA[1])
        let B = XYZ_helper(c: RGBA[2])

        let X: CGFloat = (R * 0.4124) + (G * 0.3576) + (B * 0.1805)
        let Y: CGFloat = (R * 0.2126) + (G * 0.7152) + (B * 0.0722)
        let Z: CGFloat = (R * 0.0193) + (G * 0.1192) + (B * 0.9505)

        return [X, Y, Z]
    }



    /**
        Get the CIE L*ab values.

        - returns: An array of three CGFloat numbers representing LAB respectively.
    */
    var LAB: [CGFloat] {
        // http://www.easyrgb.com/index.php?X=MATH&H=07#text7

        let XYZ = self.XYZ

        func LAB_helper(c: CGFloat) -> CGFloat {
            return 0.008856 < c ? pow(c, 1/3) : ((7.787 * c) + (16/116))
        }

        let X: CGFloat = LAB_helper(c: XYZ[0]/95.047)
        let Y: CGFloat = LAB_helper(c: XYZ[1]/100.0)
        let Z: CGFloat = LAB_helper(c: XYZ[2]/108.883)

        let L: CGFloat = (116 * Y) - 16
        let A: CGFloat = 500 * (X - Y)
        let B: CGFloat = 200 * (Y - Z)

        return [L, A, B]
    }



    /**
        Detemine the distance between two colors based on the way humans perceive them.

        - parameter compare color: A UIColor to compare.

        - returns: A CGFloat representing the deltaE
    */
    func CIE94(compare color: NSColor) -> CGFloat {
        // https://en.wikipedia.org/wiki/Color_difference#CIE94

        let k_L: CGFloat = 1
        let k_C: CGFloat = 1
        let k_H: CGFloat = 1
        let k_1: CGFloat = 0.045
        let k_2: CGFloat = 0.015

        let LAB1 = self.LAB
        let L_1 = LAB1[0], a_1 = LAB1[1], b_1 = LAB1[2]

        let LAB2 = color.LAB
        let L_2 = LAB2[0], a_2 = LAB2[1], b_2 = LAB2[2]

        let deltaL: CGFloat = L_1 - L_2
        let deltaA: CGFloat = a_1 - a_2
        let deltaB: CGFloat = b_1 - b_2

        let C_1: CGFloat = sqrt(pow(a_1, 2) + pow(b_1, 2))
        let C_2: CGFloat = sqrt(pow(a_2, 2) + pow(b_2, 2))
        let deltaC_ab: CGFloat = C_1 - C_2

        let deltaH_ab: CGFloat = sqrt(pow(deltaA, 2) + pow(deltaB, 2) - pow(deltaC_ab, 2))

        let s_L: CGFloat = 1
        let s_C: CGFloat = 1 + (k_1 * C_1)
        let s_H: CGFloat = 1 + (k_2 * C_1)

        // Calculate

        let P1: CGFloat = pow(deltaL/(k_L * s_L), 2)
        let P2: CGFloat = pow(deltaC_ab/(k_C * s_C), 2)
        let P3: CGFloat = pow(deltaH_ab/(k_H * s_H), 2)

        return sqrt((P1.isNaN ? 0:P1) + (P2.isNaN ? 0:P2) + (P3.isNaN ? 0:P3))
    }



    /**
        Detemine the distance between two colors based on the way humans perceive them.
        Uses the Sharma 2004 alteration of the CIEDE2000 algorithm.

        - parameter compare color: A UIColor to compare.

        - returns: A CGFloat representing the deltaE
    */
    func CIEDE2000(compare color: NSColor) -> CGFloat {
        // CIEDE2000, Sharma 2004 -> http://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf

        func rad2deg(r: CGFloat) -> CGFloat {
            return r * CGFloat(180/Double.pi)
        }

        func deg2rad(d: CGFloat) -> CGFloat {
            return d * CGFloat(Double.pi/180)
        }

        let k_l = CGFloat(1), k_c = CGFloat(1), k_h = CGFloat(1)

        let LAB1 = self.LAB
        let L_1 = LAB1[0], a_1 = LAB1[1], b_1 = LAB1[2]

        let LAB2 = color.LAB
        let L_2 = LAB2[0], a_2 = LAB2[1], b_2 = LAB2[2]

        let C_1ab = sqrt(pow(a_1, 2) + pow(b_1, 2))
        let C_2ab = sqrt(pow(a_2, 2) + pow(b_2, 2))
        let C_ab  = (C_1ab + C_2ab)/2

        let G = 0.5 * (1 - sqrt(pow(C_ab, 7)/(pow(C_ab, 7) + pow(25, 7))))
        let a_1_p = (1 + G) * a_1
        let a_2_p = (1 + G) * a_2

        let C_1_p = sqrt(pow(a_1_p, 2) + pow(b_1, 2))
        let C_2_p = sqrt(pow(a_2_p, 2) + pow(b_2, 2))

        // Read note 1 (page 23) for clarification on radians to hue degrees
        let h_1_p = (b_1 == 0 && a_1_p == 0) ? 0 : (atan2(b_1, a_1_p) + CGFloat(2 * Double.pi)) * CGFloat(180/Double.pi)
        let h_2_p = (b_2 == 0 && a_2_p == 0) ? 0 : (atan2(b_2, a_2_p) + CGFloat(2 * Double.pi)) * CGFloat(180/Double.pi)

        let deltaL_p = L_2 - L_1
        let deltaC_p = C_2_p - C_1_p

        var h_p: CGFloat = 0
        if (C_1_p * C_2_p) == 0 {
            h_p = 0
        } else if abs(h_2_p - h_1_p) <= 180 {
            h_p = h_2_p - h_1_p
        } else if (h_2_p - h_1_p) > 180 {
            h_p = h_2_p - h_1_p - 360
        } else if (h_2_p - h_1_p) < -180 {
            h_p = h_2_p - h_1_p + 360
        }

        let deltaH_p = 2 * sqrt(C_1_p * C_2_p) * sin(deg2rad(d: h_p/2))

        let L_p = (L_1 + L_2)/2
        let C_p = (C_1_p + C_2_p)/2

        var h_p_bar: CGFloat = 0
        if (h_1_p * h_2_p) == 0 {
            h_p_bar = h_1_p + h_2_p
        } else if abs(h_1_p - h_2_p) <= 180 {
            h_p_bar = (h_1_p + h_2_p)/2
        } else if abs(h_1_p - h_2_p) > 180 && (h_1_p + h_2_p) < 360 {
            h_p_bar = (h_1_p + h_2_p + 360)/2
        } else if abs(h_1_p - h_2_p) > 180 && (h_1_p + h_2_p) >= 360 {
            h_p_bar = (h_1_p + h_2_p - 360)/2
        }

        let T1 = cos(deg2rad(d: h_p_bar - 30))
        let T2 = cos(deg2rad(d: 2 * h_p_bar))
        let T3 = cos(deg2rad(d: (3 * h_p_bar) + 6))
        let T4 = cos(deg2rad(d: (4 * h_p_bar) - 63))
        let T = 1 - rad2deg(r: 0.17 * T1) + rad2deg(r: 0.24 * T2) - rad2deg(r: 0.32 * T3) + rad2deg(r: 0.20 * T4)

        let deltaTheta = 30 * exp(-pow((h_p_bar - 275)/25, 2))
        let R_c = 2 * sqrt(pow(C_p, 7)/(pow(C_p, 7) + pow(25, 7)))
        let S_l =  1 + ((0.015 * pow(L_p - 50, 2))/sqrt(20 + pow(L_p - 50, 2)))
        let S_c = 1 + (0.045 * C_p)
        let S_h = 1 + (0.015 * C_p * T)
        let R_t = -sin(deg2rad(d: 2 * deltaTheta)) * R_c

        // Calculate total

        let P1 = deltaL_p/(k_l * S_l)
        let P2 = deltaC_p/(k_c * S_c)
        let P3 = deltaH_p/(k_h * S_h)
        let deltaE = sqrt(pow(P1, 2) + pow(P2, 2) + pow(P3, 2) + (R_t * P2 * P3))

        return deltaE
    }


}
