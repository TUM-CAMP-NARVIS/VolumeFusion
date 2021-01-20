#include <af/MarchingCubes.cuh>

namespace af {

__constant__ int edgeTable_d[256];
__constant__ int triTable_d[256][16];

// To find which edges are intersected by the surface, we find the edges in a (trivial) table.
// Table giving the edges intersected by the surface:
int edgeTable[256] = {
    0x0,   0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c, 0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00, 0x190, 0x99,
    0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c, 0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90, 0x230, 0x339, 0x33,  0x13a,
    0x636, 0x73f, 0x435, 0x53c, 0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30, 0x3a0, 0x2a9, 0x1a3, 0xaa,  0x7a6, 0x6af,
    0x5a5, 0x4ac, 0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0, 0x460, 0x569, 0x663, 0x76a, 0x66,  0x16f, 0x265, 0x36c,
    0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60, 0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff,  0x3f5, 0x2fc, 0xdfc, 0xcf5,
    0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0, 0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55,  0x15c, 0xe5c, 0xf55, 0xc5f, 0xd56,
    0xa5a, 0xb53, 0x859, 0x950, 0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,  0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3,
    0x9c9, 0x8c0, 0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc, 0xcc,  0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
    0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c, 0x15c, 0x55,  0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650, 0xaf0, 0xbf9,
    0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc, 0x2fc, 0x3f5, 0xff,  0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0, 0xb60, 0xa69, 0x963, 0x86a,
    0xf66, 0xe6f, 0xd65, 0xc6c, 0x36c, 0x265, 0x16f, 0x66,  0x76a, 0x663, 0x569, 0x460, 0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af,
    0xaa5, 0xbac, 0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa,  0x1a3, 0x2a9, 0x3a0, 0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
    0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33,  0x339, 0x230, 0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c, 0x69c, 0x795,
    0x49f, 0x596, 0x29a, 0x393, 0x99,  0x190, 0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c, 0x70c, 0x605, 0x50f, 0x406,
    0x30a, 0x203, 0x109, 0x0};

// This table gives the edges forming triangles for the surface.
int triTable[256][16] = {{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 1, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 8, 3, 9, 8, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 3, 1, 2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {9, 2, 10, 0, 2, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {2, 8, 3, 2, 10, 8, 10, 9, 8, -1, -1, -1, -1, -1, -1, -1},
                         {3, 11, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 11, 2, 8, 11, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 9, 0, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 11, 2, 1, 9, 11, 9, 8, 11, -1, -1, -1, -1, -1, -1, -1},
                         {3, 10, 1, 11, 10, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 10, 1, 0, 8, 10, 8, 11, 10, -1, -1, -1, -1, -1, -1, -1},
                         {3, 9, 0, 3, 11, 9, 11, 10, 9, -1, -1, -1, -1, -1, -1, -1},
                         {9, 8, 10, 10, 8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 7, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 3, 0, 7, 3, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 1, 9, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 1, 9, 4, 7, 1, 7, 3, 1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 10, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {3, 4, 7, 3, 0, 4, 1, 2, 10, -1, -1, -1, -1, -1, -1, -1},
                         {9, 2, 10, 9, 0, 2, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1},
                         {2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4, -1, -1, -1, -1},
                         {8, 4, 7, 3, 11, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {11, 4, 7, 11, 2, 4, 2, 0, 4, -1, -1, -1, -1, -1, -1, -1},
                         {9, 0, 1, 8, 4, 7, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1},
                         {4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1, -1, -1, -1, -1},
                         {3, 10, 1, 3, 11, 10, 7, 8, 4, -1, -1, -1, -1, -1, -1, -1},
                         {1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4, -1, -1, -1, -1},
                         {4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3, -1, -1, -1, -1},
                         {4, 7, 11, 4, 11, 9, 9, 11, 10, -1, -1, -1, -1, -1, -1, -1},
                         {9, 5, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {9, 5, 4, 0, 8, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 5, 4, 1, 5, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {8, 5, 4, 8, 3, 5, 3, 1, 5, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 10, 9, 5, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {3, 0, 8, 1, 2, 10, 4, 9, 5, -1, -1, -1, -1, -1, -1, -1},
                         {5, 2, 10, 5, 4, 2, 4, 0, 2, -1, -1, -1, -1, -1, -1, -1},
                         {2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8, -1, -1, -1, -1},
                         {9, 5, 4, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 11, 2, 0, 8, 11, 4, 9, 5, -1, -1, -1, -1, -1, -1, -1},
                         {0, 5, 4, 0, 1, 5, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1},
                         {2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5, -1, -1, -1, -1},
                         {10, 3, 11, 10, 1, 3, 9, 5, 4, -1, -1, -1, -1, -1, -1, -1},
                         {4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10, -1, -1, -1, -1},
                         {5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3, -1, -1, -1, -1},
                         {5, 4, 8, 5, 8, 10, 10, 8, 11, -1, -1, -1, -1, -1, -1, -1},
                         {9, 7, 8, 5, 7, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {9, 3, 0, 9, 5, 3, 5, 7, 3, -1, -1, -1, -1, -1, -1, -1},
                         {0, 7, 8, 0, 1, 7, 1, 5, 7, -1, -1, -1, -1, -1, -1, -1},
                         {1, 5, 3, 3, 5, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {9, 7, 8, 9, 5, 7, 10, 1, 2, -1, -1, -1, -1, -1, -1, -1},
                         {10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3, -1, -1, -1, -1},
                         {8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2, -1, -1, -1, -1},
                         {2, 10, 5, 2, 5, 3, 3, 5, 7, -1, -1, -1, -1, -1, -1, -1},
                         {7, 9, 5, 7, 8, 9, 3, 11, 2, -1, -1, -1, -1, -1, -1, -1},
                         {9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11, -1, -1, -1, -1},
                         {2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7, -1, -1, -1, -1},
                         {11, 2, 1, 11, 1, 7, 7, 1, 5, -1, -1, -1, -1, -1, -1, -1},
                         {9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11, -1, -1, -1, -1},
                         {5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0, -1},
                         {11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0, -1},
                         {11, 10, 5, 7, 11, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {10, 6, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 3, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {9, 0, 1, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 8, 3, 1, 9, 8, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1},
                         {1, 6, 5, 2, 6, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 6, 5, 1, 2, 6, 3, 0, 8, -1, -1, -1, -1, -1, -1, -1},
                         {9, 6, 5, 9, 0, 6, 0, 2, 6, -1, -1, -1, -1, -1, -1, -1},
                         {5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8, -1, -1, -1, -1},
                         {2, 3, 11, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {11, 0, 8, 11, 2, 0, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1},
                         {0, 1, 9, 2, 3, 11, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1},
                         {5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11, -1, -1, -1, -1},
                         {6, 3, 11, 6, 5, 3, 5, 1, 3, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6, -1, -1, -1, -1},
                         {3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9, -1, -1, -1, -1},
                         {6, 5, 9, 6, 9, 11, 11, 9, 8, -1, -1, -1, -1, -1, -1, -1},
                         {5, 10, 6, 4, 7, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 3, 0, 4, 7, 3, 6, 5, 10, -1, -1, -1, -1, -1, -1, -1},
                         {1, 9, 0, 5, 10, 6, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1},
                         {10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4, -1, -1, -1, -1},
                         {6, 1, 2, 6, 5, 1, 4, 7, 8, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7, -1, -1, -1, -1},
                         {8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6, -1, -1, -1, -1},
                         {7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9, -1},
                         {3, 11, 2, 7, 8, 4, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1},
                         {5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11, -1, -1, -1, -1},
                         {0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6, -1, -1, -1, -1},
                         {9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6, -1},
                         {8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6, -1, -1, -1, -1},
                         {5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11, -1},
                         {0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7, -1},
                         {6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9, -1, -1, -1, -1},
                         {10, 4, 9, 6, 4, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 10, 6, 4, 9, 10, 0, 8, 3, -1, -1, -1, -1, -1, -1, -1},
                         {10, 0, 1, 10, 6, 0, 6, 4, 0, -1, -1, -1, -1, -1, -1, -1},
                         {8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10, -1, -1, -1, -1},
                         {1, 4, 9, 1, 2, 4, 2, 6, 4, -1, -1, -1, -1, -1, -1, -1},
                         {3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4, -1, -1, -1, -1},
                         {0, 2, 4, 4, 2, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {8, 3, 2, 8, 2, 4, 4, 2, 6, -1, -1, -1, -1, -1, -1, -1},
                         {10, 4, 9, 10, 6, 4, 11, 2, 3, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6, -1, -1, -1, -1},
                         {3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10, -1, -1, -1, -1},
                         {6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1, -1},
                         {9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3, -1, -1, -1, -1},
                         {8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1, -1},
                         {3, 11, 6, 3, 6, 0, 0, 6, 4, -1, -1, -1, -1, -1, -1, -1},
                         {6, 4, 8, 11, 6, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {7, 10, 6, 7, 8, 10, 8, 9, 10, -1, -1, -1, -1, -1, -1, -1},
                         {0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10, -1, -1, -1, -1},
                         {10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0, -1, -1, -1, -1},
                         {10, 6, 7, 10, 7, 1, 1, 7, 3, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7, -1, -1, -1, -1},
                         {2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9, -1},
                         {7, 8, 0, 7, 0, 6, 6, 0, 2, -1, -1, -1, -1, -1, -1, -1},
                         {7, 3, 2, 6, 7, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7, -1, -1, -1, -1},
                         {2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7, -1},
                         {1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11, -1},
                         {11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1, -1, -1, -1, -1},
                         {8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6, -1},
                         {0, 9, 1, 11, 6, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0, -1, -1, -1, -1},
                         {7, 11, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {7, 6, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {3, 0, 8, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 1, 9, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {8, 1, 9, 8, 3, 1, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1},
                         {10, 1, 2, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 10, 3, 0, 8, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1},
                         {2, 9, 0, 2, 10, 9, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1},
                         {6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8, -1, -1, -1, -1},
                         {7, 2, 3, 6, 2, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {7, 0, 8, 7, 6, 0, 6, 2, 0, -1, -1, -1, -1, -1, -1, -1},
                         {2, 7, 6, 2, 3, 7, 0, 1, 9, -1, -1, -1, -1, -1, -1, -1},
                         {1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6, -1, -1, -1, -1},
                         {10, 7, 6, 10, 1, 7, 1, 3, 7, -1, -1, -1, -1, -1, -1, -1},
                         {10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8, -1, -1, -1, -1},
                         {0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7, -1, -1, -1, -1},
                         {7, 6, 10, 7, 10, 8, 8, 10, 9, -1, -1, -1, -1, -1, -1, -1},
                         {6, 8, 4, 11, 8, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {3, 6, 11, 3, 0, 6, 0, 4, 6, -1, -1, -1, -1, -1, -1, -1},
                         {8, 6, 11, 8, 4, 6, 9, 0, 1, -1, -1, -1, -1, -1, -1, -1},
                         {9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6, -1, -1, -1, -1},
                         {6, 8, 4, 6, 11, 8, 2, 10, 1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6, -1, -1, -1, -1},
                         {4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9, -1, -1, -1, -1},
                         {10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3, -1},
                         {8, 2, 3, 8, 4, 2, 4, 6, 2, -1, -1, -1, -1, -1, -1, -1},
                         {0, 4, 2, 4, 6, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8, -1, -1, -1, -1},
                         {1, 9, 4, 1, 4, 2, 2, 4, 6, -1, -1, -1, -1, -1, -1, -1},
                         {8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1, -1, -1, -1, -1},
                         {10, 1, 0, 10, 0, 6, 6, 0, 4, -1, -1, -1, -1, -1, -1, -1},
                         {4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3, -1},
                         {10, 9, 4, 6, 10, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 9, 5, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 3, 4, 9, 5, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1},
                         {5, 0, 1, 5, 4, 0, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1},
                         {11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5, -1, -1, -1, -1},
                         {9, 5, 4, 10, 1, 2, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1},
                         {6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5, -1, -1, -1, -1},
                         {7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2, -1, -1, -1, -1},
                         {3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6, -1},
                         {7, 2, 3, 7, 6, 2, 5, 4, 9, -1, -1, -1, -1, -1, -1, -1},
                         {9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7, -1, -1, -1, -1},
                         {3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0, -1, -1, -1, -1},
                         {6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8, -1},
                         {9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7, -1, -1, -1, -1},
                         {1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4, -1},
                         {4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10, -1},
                         {7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10, -1, -1, -1, -1},
                         {6, 9, 5, 6, 11, 9, 11, 8, 9, -1, -1, -1, -1, -1, -1, -1},
                         {3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5, -1, -1, -1, -1},
                         {0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11, -1, -1, -1, -1},
                         {6, 11, 3, 6, 3, 5, 5, 3, 1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6, -1, -1, -1, -1},
                         {0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10, -1},
                         {11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5, -1},
                         {6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3, -1, -1, -1, -1},
                         {5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2, -1, -1, -1, -1},
                         {9, 5, 6, 9, 6, 0, 0, 6, 2, -1, -1, -1, -1, -1, -1, -1},
                         {1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8, -1},
                         {1, 5, 6, 2, 1, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6, -1},
                         {10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0, -1, -1, -1, -1},
                         {0, 3, 8, 5, 6, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {10, 5, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {11, 5, 10, 7, 5, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {11, 5, 10, 11, 7, 5, 8, 3, 0, -1, -1, -1, -1, -1, -1, -1},
                         {5, 11, 7, 5, 10, 11, 1, 9, 0, -1, -1, -1, -1, -1, -1, -1},
                         {10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1, -1, -1, -1, -1},
                         {11, 1, 2, 11, 7, 1, 7, 5, 1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11, -1, -1, -1, -1},
                         {9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7, -1, -1, -1, -1},
                         {7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2, -1},
                         {2, 5, 10, 2, 3, 5, 3, 7, 5, -1, -1, -1, -1, -1, -1, -1},
                         {8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5, -1, -1, -1, -1},
                         {9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2, -1, -1, -1, -1},
                         {9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2, -1},
                         {1, 3, 5, 3, 7, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 7, 0, 7, 1, 1, 7, 5, -1, -1, -1, -1, -1, -1, -1},
                         {9, 0, 3, 9, 3, 5, 5, 3, 7, -1, -1, -1, -1, -1, -1, -1},
                         {9, 8, 7, 5, 9, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {5, 8, 4, 5, 10, 8, 10, 11, 8, -1, -1, -1, -1, -1, -1, -1},
                         {5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0, -1, -1, -1, -1},
                         {0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5, -1, -1, -1, -1},
                         {10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4, -1},
                         {2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8, -1, -1, -1, -1},
                         {0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11, -1},
                         {0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5, -1},
                         {9, 4, 5, 2, 11, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4, -1, -1, -1, -1},
                         {5, 10, 2, 5, 2, 4, 4, 2, 0, -1, -1, -1, -1, -1, -1, -1},
                         {3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9, -1},
                         {5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2, -1, -1, -1, -1},
                         {8, 4, 5, 8, 5, 3, 3, 5, 1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 4, 5, 1, 0, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5, -1, -1, -1, -1},
                         {9, 4, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 11, 7, 4, 9, 11, 9, 10, 11, -1, -1, -1, -1, -1, -1, -1},
                         {0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11, -1, -1, -1, -1},
                         {1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11, -1, -1, -1, -1},
                         {3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4, -1},
                         {4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2, -1, -1, -1, -1},
                         {9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3, -1},
                         {11, 7, 4, 11, 4, 2, 2, 4, 0, -1, -1, -1, -1, -1, -1, -1},
                         {11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4, -1, -1, -1, -1},
                         {2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9, -1, -1, -1, -1},
                         {9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7, -1},
                         {3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10, -1},
                         {1, 10, 2, 8, 7, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 9, 1, 4, 1, 7, 7, 1, 3, -1, -1, -1, -1, -1, -1, -1},
                         {4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1, -1, -1, -1, -1},
                         {4, 0, 3, 7, 4, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {4, 8, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {9, 10, 8, 10, 11, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {3, 0, 9, 3, 9, 11, 11, 9, 10, -1, -1, -1, -1, -1, -1, -1},
                         {0, 1, 10, 0, 10, 8, 8, 10, 11, -1, -1, -1, -1, -1, -1, -1},
                         {3, 1, 10, 11, 3, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 2, 11, 1, 11, 9, 9, 11, 8, -1, -1, -1, -1, -1, -1, -1},
                         {3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9, -1, -1, -1, -1},
                         {0, 2, 11, 8, 0, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {3, 2, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {2, 3, 8, 2, 8, 10, 10, 8, 9, -1, -1, -1, -1, -1, -1, -1},
                         {9, 10, 2, 0, 9, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8, -1, -1, -1, -1},
                         {1, 10, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {1, 3, 8, 9, 1, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 9, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {0, 3, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
                         {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}};

void initEdgeTableDevice() {
    static bool isInitialized = false;
    if (isInitialized)
        return;
    cudaMemcpyToSymbol(edgeTable_d, edgeTable, 256 * sizeof(int));
    cudaMemcpyToSymbol(triTable_d, triTable, 256 * 16 * sizeof(int));
    isInitialized = true;
}

__device__ Vec3f interpolate(float tsdf0, float tsdf1, const Vec3f& val0, const Vec3f& val1, float isoValue) {
    if (fabs(isoValue - tsdf0) < 1e-7)
        return val0;
    if (fabs(isoValue - tsdf1) < 1e-7)
        return val1;
    if (fabs(tsdf0 - tsdf1) < 1e-7)
        return val0;

    double mu = (isoValue - tsdf0) / (tsdf1 - tsdf0);
    if (mu > 1.0)
        mu = 1.0;
    else if (mu < 0)
        mu = 0.0;

    Vec3f val;
    val[0] = val0[0] + mu * (val1[0] - val0[0]);
    val[1] = val0[1] + mu * (val1[1] - val0[1]);
    val[2] = val0[2] + mu * (val1[2] - val0[2]);
    return val;
}

__device__ Vec3f voxelToWorld(int i, int j, int k, const Vec3f& cVoxelSize, const Vec3f& cVolSize) {
    Vec3f pt = Vec3i(i, j, k).cast<float>().cwiseProduct(cVoxelSize) - cVolSize * 0.5;
    return pt;
}

__device__ Vec3f getVertex(int i1,
                           int j1,
                           int k1,
                           int i2,
                           int j2,
                           int k2,
                           const float* cTsdf,
                           const Vec3i& cDims,
                           const Vec3f& cVoxelSize,
                           const Vec3f& cVolSize,
                           float isoValue) {
    float v1 = cTsdf[k1 * cDims[0] * cDims[1] + j1 * cDims[0] + i1];
    Vec3f p1 = voxelToWorld(i1, j1, k1, cVoxelSize, cVolSize);
    float v2 = cTsdf[k2 * cDims[0] * cDims[1] + j2 * cDims[0] + i2];
    Vec3f p2 = voxelToWorld(i2, j2, k2, cVoxelSize, cVolSize);
    return interpolate(v1, v2, p1, p2, isoValue);
}

__device__ int
computeLutIndex(int i, int j, int k, const float* cTsdf, const float* cTsdfWeights, const Vec3i& cDims, float isoValue) {
    size_t offZ = cDims[0] * cDims[1];
    size_t offY = cDims[0];

    // clang-format off
    size_t off1   =  k      * offZ + (j + 1) * offY + (i + 1);
    size_t off2   =  k      * offZ +  j      * offY + (i + 1);
    size_t off4   =  k      * offZ +  j      * offY +  i;
    size_t off8   =  k      * offZ + (j + 1) * offY +  i;
    size_t off16  = (k + 1) * offZ + (j + 1) * offY + (i + 1);
    size_t off32  = (k + 1) * offZ +  j      * offY + (i + 1);
    size_t off64  = (k + 1) * offZ +  j      * offY +  i;
    size_t off128 = (k + 1) * offZ + (j + 1) * offY +  i;
    // clang-format on

    // determine cube index for lookup table
    int cubeIdx = 0;
    // check if behind the surface
    if (!(cTsdfWeights[off1] == 0.0f || cTsdfWeights[off2] == 0.0f || cTsdfWeights[off4] == 0.0f || cTsdfWeights[off8] == 0.0f
          || cTsdfWeights[off16] == 0.0f || cTsdfWeights[off32] == 0.0f || cTsdfWeights[off64] == 0.0f
          || cTsdfWeights[off128] == 0.0f)) {
        if (cTsdf[off1] > isoValue)
            cubeIdx |= 1;
        if (cTsdf[off2] > isoValue)
            cubeIdx |= 2;
        if (cTsdf[off4] > isoValue)
            cubeIdx |= 4;
        if (cTsdf[off8] > isoValue)
            cubeIdx |= 8;
        if (cTsdf[off16] > isoValue)
            cubeIdx |= 16;
        if (cTsdf[off32] > isoValue)
            cubeIdx |= 32;
        if (cTsdf[off64] > isoValue)
            cubeIdx |= 64;
        if (cTsdf[off128] > isoValue)
            cubeIdx |= 128;
    }

    return cubeIdx;
}

__device__ unsigned int pushBackVertex(Vec3f* mesh, unsigned int* meshSize, const Vec3f& cVertex) {
    unsigned int lastSize = atomicAdd(meshSize, 1);
    mesh[lastSize]        = cVertex;
    return lastSize;
}

__device__ unsigned int pushBackFace(Vec3i* faces, unsigned int* facesSize, const Vec3i& cFaceVerts) {
    unsigned int lastSize = atomicAdd(facesSize, 1);
    faces[lastSize]       = cFaceVerts;
    return lastSize;
}

__device__ void computeTriangles(Vec3f* mesh,
                                 unsigned int* meshSize,
                                 Vec3i* faces,
                                 unsigned int* facesSize,
                                 int cubeIndex,
                                 const Vec3f edgePoints[12]) {
    Vec3f pts[3];
    for (int i = 0; triTable_d[cubeIndex][i] != -1; i += 3) {
        Vec3f p1 = edgePoints[triTable_d[cubeIndex][i]];
        pts[0]   = p1;
        Vec3f p2 = edgePoints[triTable_d[cubeIndex][i + 1]];
        pts[1]   = p2;
        Vec3f p3 = edgePoints[triTable_d[cubeIndex][i + 2]];
        pts[2]   = p3;

        if (p1 != p2 && p1 != p3 && p2 != p3) {
            // add vertices
            Vec3i vIdx;
            for (int t = 0; t < 3; ++t) {
                vIdx[t] = pushBackVertex(mesh, meshSize, pts[t]);
            }

            // add face
            Vec3i faceVerts(vIdx[0], vIdx[1], vIdx[2]);
            pushBackFace(faces, facesSize, faceVerts);
        }
    }
}

__global__ void marchingCubesMeshKernel(Vec3f* mesh,
                                        unsigned int* meshSize,
                                        const float* cTsdf,
                                        const float* cTsdfWeights,
                                        const Vec3i cDims,
                                        const Vec3f cVoxelSize,
                                        const Vec3f cVolSize,
                                        const float cIsoValue) {
    std::size_t cX = threadIdx.x + blockDim.x * blockIdx.x;
    std::size_t cY = threadIdx.y + blockDim.y * blockIdx.y;
    std::size_t cZ = threadIdx.z + blockDim.z * blockIdx.z;
    if (cX >= cDims[0] - 2 || cY >= cDims[1] - 2 || cZ >= cDims[2] - 2)
        return;

    int cubeindex = computeLutIndex(cX, cY, cZ, cTsdf, cTsdfWeights, cDims, cIsoValue);

    if (cubeindex != 0 && cubeindex != 255) {
        if (edgeTable_d[cubeindex] & 1) {
            // interpolate between vertices 0 and 1
            pushBackVertex(mesh, meshSize,
                           getVertex(cX + 1, cY + 1, cZ, cX + 1, cY, cZ, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 2) {
            // interpolate between vertices 1 and 2
            pushBackVertex(mesh, meshSize, getVertex(cX + 1, cY, cZ, cX, cY, cZ, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 4) {
            // interpolate between vertices 2 and 3
            pushBackVertex(mesh, meshSize, getVertex(cX, cY, cZ, cX, cY + 1, cZ, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 8) {
            // interpolate between vertices 3 and 0
            pushBackVertex(mesh, meshSize,
                           getVertex(cX, cY + 1, cZ, cX + 1, cY + 1, cZ, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 16) {
            // interpolate between vertices 4 and 5
            pushBackVertex(mesh, meshSize,
                           getVertex(cX + 1, cY + 1, cZ + 1, cX + 1, cY, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 32) {
            // interpolate between vertices 5 and 6
            pushBackVertex(mesh, meshSize,
                           getVertex(cX + 1, cY, cZ + 1, cX, cY, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 64) {
            // interpolate between vertices 6 and 7
            pushBackVertex(mesh, meshSize,
                           getVertex(cX, cY, cZ + 1, cX, cY + 1, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 128) {
            // interpolate between vertices 7 and 4
            pushBackVertex(mesh, meshSize,
                           getVertex(cX, cY + 1, cZ + 1, cX + 1, cY + 1, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 256) {
            // interpolate between vertices 0 and 4
            pushBackVertex(mesh, meshSize,
                           getVertex(cX + 1, cY + 1, cZ, cX + 1, cY + 1, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 512) {
            // interpolate between vertices 1 and 5
            pushBackVertex(mesh, meshSize,
                           getVertex(cX + 1, cY, cZ, cX + 1, cY, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 1024) {
            // interpolate between vertices 2 and 6
            pushBackVertex(mesh, meshSize, getVertex(cX, cY, cZ, cX, cY, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }

        if (edgeTable_d[cubeindex] & 2048) {
            //     // interpolate between vertices 3 and 7
            pushBackVertex(mesh, meshSize,
                           getVertex(cX, cY + 1, cZ, cX, cY + 1, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue));
        }
    }
}

void runMarchingCubesMeshKernel(Vec3f* mesh,
                                unsigned int* meshSize,
                                const float* cTsdf,
                                const float* cTsdfWeights,
                                const Vec3i cDims,
                                const Vec3f& cVoxelSize,
                                const Vec3f& cVolSize,
                                const float cIsoValue) {
    initEdgeTableDevice();
    dim3 block, grid;
    setupBlockGrid(block, grid, cDims[0] - 2, cDims[1] - 2, cDims[2] - 2);
    marchingCubesMeshKernel<<<grid, block>>>(mesh, meshSize, cTsdf, cTsdfWeights, cDims, cVoxelSize, cVolSize, cIsoValue);
    CUDA_CHECK;
    cudaDeviceSynchronize();
}

__global__ void marchingCubesFullKernel(Vec3f* mesh,
                                        unsigned int* meshSize,
                                        Vec3i* faces,
                                        unsigned int* facesSize,
                                        const float* cTsdf,
                                        const float* cTsdfWeights,
                                        const Vec3i cDims,
                                        const Vec3f cVoxelSize,
                                        const Vec3f cVolSize,
                                        const float cIsoValue) {
    std::size_t cX = threadIdx.x + blockDim.x * blockIdx.x;
    std::size_t cY = threadIdx.y + blockDim.y * blockIdx.y;
    std::size_t cZ = threadIdx.z + blockDim.z * blockIdx.z;
    if (cX >= cDims[0] - 2 || cY >= cDims[1] - 2 || cZ >= cDims[2] - 2)
        return;

    int cubeindex = computeLutIndex(cX, cY, cZ, cTsdf, cTsdfWeights, cDims, cIsoValue);

    Vec3f edgePoints[12];
    int edgeIndices[12][6];

    if (cubeindex != 0 && cubeindex != 255) {
        if (edgeTable_d[cubeindex] & 1) {
            // interpolate between vertices 0 and 1
            edgePoints[0]     = getVertex(cX + 1, cY + 1, cZ, cX + 1, cY, cZ, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[0][0] = cX + 1;
            edgeIndices[0][1] = cY + 1;
            edgeIndices[0][2] = cZ;
            edgeIndices[0][3] = cX + 1;
            edgeIndices[0][4] = cY;
            edgeIndices[0][5] = cZ;
        }

        if (edgeTable_d[cubeindex] & 2) {
            // interpolate between vertices 1 and 2
            edgePoints[1]     = getVertex(cX + 1, cY, cZ, cX, cY, cZ, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[1][0] = cX + 1;
            edgeIndices[1][1] = cY;
            edgeIndices[1][2] = cZ;
            edgeIndices[1][3] = cX;
            edgeIndices[1][4] = cY;
            edgeIndices[1][5] = cZ;
        }

        if (edgeTable_d[cubeindex] & 4) {
            // interpolate between vertices 2 and 3
            edgePoints[2]     = getVertex(cX, cY, cZ, cX, cY + 1, cZ, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[2][0] = cX;
            edgeIndices[2][1] = cY;
            edgeIndices[2][2] = cZ;
            edgeIndices[2][3] = cX;
            edgeIndices[2][4] = cY + 1;
            edgeIndices[2][5] = cZ;
        }

        if (edgeTable_d[cubeindex] & 8) {
            // interpolate between vertices 3 and 0
            edgePoints[3]     = getVertex(cX, cY + 1, cZ, cX + 1, cY + 1, cZ, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[3][0] = cX;
            edgeIndices[3][1] = cY + 1;
            edgeIndices[3][2] = cZ;
            edgeIndices[3][3] = cX + 1;
            edgeIndices[3][4] = cY + 1;
            edgeIndices[3][5] = cZ;
        }

        if (edgeTable_d[cubeindex] & 16) {
            // interpolate between vertices 4 and 5
            edgePoints[4] = getVertex(cX + 1, cY + 1, cZ + 1, cX + 1, cY, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[4][0] = cX + 1;
            edgeIndices[4][1] = cY + 1;
            edgeIndices[4][2] = cZ + 1;
            edgeIndices[4][3] = cX + 1;
            edgeIndices[4][4] = cY;
            edgeIndices[4][5] = cZ + 1;
        }

        if (edgeTable_d[cubeindex] & 32) {
            // interpolate between vertices 5 and 6
            edgePoints[5]     = getVertex(cX + 1, cY, cZ + 1, cX, cY, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[5][0] = cX + 1;
            edgeIndices[5][1] = cY;
            edgeIndices[5][2] = cZ + 1;
            edgeIndices[5][3] = cX;
            edgeIndices[5][4] = cY;
            edgeIndices[5][5] = cZ + 1;
        }

        if (edgeTable_d[cubeindex] & 64) {
            // interpolate between vertices 6 and 7
            edgePoints[6]     = getVertex(cX, cY, cZ + 1, cX, cY + 1, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[6][0] = cX;
            edgeIndices[6][1] = cY;
            edgeIndices[6][2] = cZ + 1;
            edgeIndices[6][3] = cX;
            edgeIndices[6][4] = cY + 1;
            edgeIndices[6][5] = cZ + 1;
        }

        if (edgeTable_d[cubeindex] & 128) {
            // interpolate between vertices 7 and 4
            edgePoints[7] = getVertex(cX, cY + 1, cZ + 1, cX + 1, cY + 1, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[7][0] = cX;
            edgeIndices[7][1] = cY + 1;
            edgeIndices[7][2] = cZ + 1;
            edgeIndices[7][3] = cX + 1;
            edgeIndices[7][4] = cY + 1;
            edgeIndices[7][5] = cZ + 1;
        }

        if (edgeTable_d[cubeindex] & 256) {
            // interpolate between vertices 0 and 4
            edgePoints[8] = getVertex(cX + 1, cY + 1, cZ, cX + 1, cY + 1, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[8][0] = cX + 1;
            edgeIndices[8][1] = cY + 1;
            edgeIndices[8][2] = cZ;
            edgeIndices[8][3] = cX + 1;
            edgeIndices[8][4] = cY + 1;
            edgeIndices[8][5] = cZ + 1;
        }

        if (edgeTable_d[cubeindex] & 512) {
            // interpolate between vertices 1 and 5
            edgePoints[9]     = getVertex(cX + 1, cY, cZ, cX + 1, cY, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[9][0] = cX + 1;
            edgeIndices[9][1] = cY;
            edgeIndices[9][2] = cZ;
            edgeIndices[9][3] = cX + 1;
            edgeIndices[9][4] = cY;
            edgeIndices[9][5] = cZ + 1;
        }

        if (edgeTable_d[cubeindex] & 1024) {
            // interpolate between vertices 2 and 6
            edgePoints[10]     = getVertex(cX, cY, cZ, cX, cY, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[10][0] = cX;
            edgeIndices[10][1] = cY;
            edgeIndices[10][2] = cZ;
            edgeIndices[10][3] = cX;
            edgeIndices[10][4] = cY;
            edgeIndices[10][5] = cZ + 1;
        }

        if (edgeTable_d[cubeindex] & 2048) {
            //     // interpolate between vertices 3 and 7
            edgePoints[11]     = getVertex(cX, cY + 1, cZ, cX, cY + 1, cZ + 1, cTsdf, cDims, cVoxelSize, cVolSize, cIsoValue);
            edgeIndices[11][0] = cX;
            edgeIndices[11][1] = cY + 1;
            edgeIndices[11][2] = cZ;
            edgeIndices[11][3] = cX;
            edgeIndices[11][4] = cY + 1;
            edgeIndices[11][5] = cZ + 1;
        }

        computeTriangles(mesh, meshSize, faces, facesSize, cubeindex, edgePoints);
    }
}

void runMarchingCubesFullKernel(Vec3f* mesh,
                                unsigned int* meshSize,
                                Vec3i* faces,
                                unsigned int* facesSize,
                                const float* cTsdf,
                                const float* cTsdfWeights,
                                const Vec3i cDims,
                                const Vec3f& cVoxelSize,
                                const Vec3f& cVolSize,
                                const float cIsoValue) {
    initEdgeTableDevice();
    dim3 block, grid;
    setupBlockGrid(block, grid, cDims[0] - 2, cDims[1] - 2, cDims[2] - 2);
    marchingCubesFullKernel<<<grid, block>>>(mesh, meshSize, faces, facesSize, cTsdf, cTsdfWeights, cDims, cVoxelSize, cVolSize,
                                             cIsoValue);
    CUDA_CHECK;
    cudaDeviceSynchronize();
}

}  // namespace af