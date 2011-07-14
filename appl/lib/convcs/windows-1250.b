implement GenCP;

include "sys.m";
include "draw.m";
include "gencp.b";

CHARSET : con "windows-1250";

cstab := array [] of {
16r0000, 16r0001, 16r0002, 16r0003, 16r0004, 16r0005, 16r0006, 16r0007, 16r0008, 16r0009, 16r000A, 16r000B, 16r000C, 16r000D, 16r000E, 16r000F,
16r0010, 16r0011, 16r0012, 16r0013, 16r0014, 16r0015, 16r0016, 16r0017, 16r0018, 16r0019, 16r001A, 16r001B, 16r001C, 16r001D, 16r001E, 16r001F,
16r0020, 16r0021, 16r0022, 16r0023, 16r0024, 16r0025, 16r0026, 16r0027, 16r0028, 16r0029, 16r002A, 16r002B, 16r002C, 16r002D, 16r002E, 16r002F,
16r0030, 16r0031, 16r0032, 16r0033, 16r0034, 16r0035, 16r0036, 16r0037, 16r0038, 16r0039, 16r003A, 16r003B, 16r003C, 16r003D, 16r003E, 16r003F,
16r0040, 16r0041, 16r0042, 16r0043, 16r0044, 16r0045, 16r0046, 16r0047, 16r0048, 16r0049, 16r004A, 16r004B, 16r004C, 16r004D, 16r004E, 16r004F,
16r0050, 16r0051, 16r0052, 16r0053, 16r0054, 16r0055, 16r0056, 16r0057, 16r0058, 16r0059, 16r005A, 16r005B, 16r005C, 16r005D, 16r005E, 16r005F,
16r0060, 16r0061, 16r0062, 16r0063, 16r0064, 16r0065, 16r0066, 16r0067, 16r0068, 16r0069, 16r006A, 16r006B, 16r006C, 16r006D, 16r006E, 16r006F,
16r0070, 16r0071, 16r0072, 16r0073, 16r0074, 16r0075, 16r0076, 16r0077, 16r0078, 16r0079, 16r007A, 16r007B, 16r007C, 16r007D, 16r007E, 16r007F,
16r20AC, -1, 16r201A, -1, 16r201E, 16r2026, 16r2020, 16r2021, -1, 16r2030, 16r0160, 16r2039, 16r015A, 16r0164, 16r017D, 16r0179,
-1, 16r2018, 16r2019, 16r201C, 16r201D, 16r2022, 16r2013, 16r2014, -1, 16r2122, 16r0161, 16r203A, 16r015B, 16r0165, 16r017E, 16r017A,
16r00A0, 16r02C7, 16r02D8, 16r0141, 16r00A4, 16r0104, 16r00A6, 16r00A7, 16r00A8, 16r00A9, 16r015E, 16r00AB, 16r00AC, 16r00AD, 16r00AE, 16r017B,
16r00B0, 16r00B1, 16r02DB, 16r0142, 16r00B4, 16r00B5, 16r00B6, 16r00B7, 16r00B8, 16r0105, 16r015F, 16r00BB, 16r013D, 16r02DD, 16r013E, 16r017C,
16r0154, 16r00C1, 16r00C2, 16r0102, 16r00C4, 16r0139, 16r0106, 16r00C7, 16r010C, 16r00C9, 16r0118, 16r00CB, 16r011A, 16r00CD, 16r00CE, 16r010E,
16r0110, 16r0143, 16r0147, 16r00D3, 16r00D4, 16r0150, 16r00D6, 16r00D7, 16r0158, 16r016E, 16r00DA, 16r0170, 16r00DC, 16r00DD, 16r0162, 16r00DF,
16r0155, 16r00E1, 16r00E2, 16r0103, 16r00E4, 16r013A, 16r0107, 16r00E7, 16r010D, 16r00E9, 16r0119, 16r00EB, 16r011B, 16r00ED, 16r00EE, 16r010F,
16r0111, 16r0144, 16r0148, 16r00F3, 16r00F4, 16r0151, 16r00F6, 16r00F7, 16r0159, 16r016F, 16r00FA, 16r0171, 16r00FC, 16r00FD, 16r0163, 16r02D9,
};