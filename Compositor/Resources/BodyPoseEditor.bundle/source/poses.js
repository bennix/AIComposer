// Built-in pose presets. Angles in degrees, Euler order ZXY.
// Conventions (rest = standing, arms hanging):
//   limbs: -X swings forward, +X swings backward; left limbs +Z = outward, right limbs -Z = outward
//   knee +X bends; elbow -X bends; spine/neck/head +X bends forward
export const PRESETS = [
  {
    name: '自然站立',
    pose: { bones: {
      shoulderL: [0, 0, 7], shoulderR: [0, 0, -7], elbowL: [-12, 0, 0], elbowR: [-12, 0, 0],
      hipL: [0, 0, 2], hipR: [0, 0, -2], head: [-3, 0, 0],
    } },
  },
  {
    name: '对立式',
    pose: { bones: {
      root: [0, 8, 5], spine: [0, -4, -5], chest: [0, -4, -4], neck: [0, 0, 4], head: [0, 10, 6],
      hipL: [-6, 10, -6], kneeL: [16, 0, 0], ankleL: [6, 12, 0],
      hipR: [2, 0, -2], kneeR: [2, 0, 0],
      shoulderL: [-6, 0, 10], elbowL: [-18, 0, 0], shoulderR: [6, 0, -14], elbowR: [-14, 0, 0],
    } },
  },
  {
    name: '双手抱头',
    pose: { bones: {
      root: [0, 0, 3], spine: [-4, 0, -3], chest: [-6, 0, 0], head: [-6, 0, 4],
      shoulderL: [10, 90, 150], elbowL: [-145, 0, 0],
      shoulderR: [10, -90, -150], elbowR: [-145, 0, 0],
      hipL: [-4, 0, -4], kneeL: [10, 0, 0], hipR: [2, 0, -2],
    } },
  },
  {
    name: '行走',
    pose: { bones: {
      root: [0, 20, 0], spine: [4, -6, 0], chest: [0, -6, 0], head: [-4, 10, 0],
      hipL: [-24, 0, 1], kneeL: [12, 0, 0], ankleL: [-8, 0, 0],
      hipR: [20, 0, -1], kneeR: [28, 0, 0], ankleR: [22, 0, 0],
      shoulderL: [18, 0, 6], elbowL: [-15, 0, 0], shoulderR: [-20, 0, -6], elbowR: [-30, 0, 0],
    } },
  },
  {
    name: '前倾扶膝',
    pose: { bones: {
      root: [50, 25, 0], spine: [12, 0, 0], chest: [8, 0, 0], neck: [-30, 0, 0], head: [-28, 0, 0],
      hipL: [-62, 0, 4], kneeL: [28, 0, 0], ankleL: [-6, 0, 0],
      hipR: [-66, 0, -4], kneeR: [30, 0, 0], ankleR: [-6, 0, 0],
      shoulderL: [-38, 0, 2], elbowL: [-12, 0, 0], wristL: [20, 0, 0],
      shoulderR: [-38, 0, -2], elbowR: [-12, 0, 0], wristR: [20, 0, 0],
    } },
  },
  {
    name: '单腿平衡',
    pose: { bones: {
      root: [0, -20, 0], spine: [-6, 0, 4], chest: [-4, 0, 0], head: [0, -10, -6],
      hipL: [0, 0, 1], hipR: [6, 0, -4], kneeR: [110, 0, 0], ankleR: [40, 0, 0],
      shoulderL: [0, 0, 70], elbowL: [-20, 0, 0], shoulderR: [-10, 0, -60], elbowR: [-25, 0, 0],
      wristL: [0, 0, 20], wristR: [0, 0, -20],
    } },
  },
  {
    name: '坐姿',
    pose: { bones: {
      root: [-8, 25, 0], spine: [6, 0, 0], chest: [4, 0, 0], head: [6, -8, 0],
      hipL: [-80, 0, 6], kneeL: [70, 0, 0], ankleL: [10, 0, 0],
      hipR: [-88, -10, -2], kneeR: [100, 0, 0], ankleR: [20, 0, 0],
      shoulderL: [-25, 0, 10], elbowL: [-50, 0, 0], shoulderR: [10, 0, -25], elbowR: [-5, 0, 0], wristR: [-60, 0, 0],
    } },
  },
  {
    name: '抱膝坐',
    pose: { bones: {
      root: [-25, 15, 0], spine: [25, 0, 0], chest: [15, 0, 0], neck: [10, 0, 0], head: [10, -10, 0],
      hipL: [-105, 0, 4], kneeL: [140, 0, 0], ankleL: [25, 0, 0],
      hipR: [-100, 0, -4], kneeR: [135, 0, 0], ankleR: [25, 0, 0],
      shoulderL: [-55, -30, 10], elbowL: [-85, 0, 0], shoulderR: [-55, 30, -10], elbowR: [-85, 0, 0],
    } },
  },
  {
    name: '盘腿坐',
    pose: { bones: {
      root: [-4, 0, 0], spine: [6, 0, 0], head: [-4, 0, 0],
      hipL: [-70, 40, 55], kneeL: [140, 0, 0], ankleL: [10, 0, -10],
      hipR: [-70, -40, -55], kneeR: [140, 0, 0], ankleR: [10, 0, 10],
      shoulderL: [-30, 0, 4], elbowL: [-40, 0, 0], shoulderR: [-30, 0, -4], elbowR: [-40, 0, 0],
    } },
  },
  {
    name: '跪坐',
    pose: { bones: {
      root: [-4, -15, 0], spine: [4, 0, 0], neck: [-4, 0, 0], head: [-2, 10, 6],
      hipL: [-70, 0, 5], kneeL: [155, 0, 0], ankleL: [60, 0, 0],
      hipR: [-70, 0, -5], kneeR: [155, 0, 0], ankleR: [60, 0, 0],
      shoulderL: [-20, 0, 8], elbowL: [-40, 0, 0], shoulderR: [-20, 0, -8], elbowR: [-40, 0, 0],
    } },
  },
  {
    name: '单膝跪地',
    pose: { bones: {
      root: [0, 30, 0], spine: [8, 0, 0], chest: [4, 0, 0], head: [-6, -10, 0],
      hipL: [-88, 0, 4], kneeL: [92, 0, 0], ankleL: [-4, 0, 0],
      hipR: [8, 0, -2], kneeR: [95, 0, 0], ankleR: [50, 0, 0],
      shoulderL: [-50, 0, 8], elbowL: [-60, 0, 0], shoulderR: [-30, 0, -6], elbowR: [-70, 0, 0],
    } },
  },
  {
    name: '下蹲',
    pose: { bones: {
      root: [20, 15, 0], spine: [15, 0, 0], chest: [6, 0, 0], neck: [-15, 0, 0], head: [-15, 0, 0],
      hipL: [-130, -10, 25], kneeL: [150, 0, 0], ankleL: [-30, 0, 0],
      hipR: [-130, 10, -25], kneeR: [150, 0, 0], ankleR: [-30, 0, 0],
      shoulderL: [-50, 0, 15], elbowL: [-40, 0, 0], shoulderR: [-50, 0, -15], elbowR: [-40, 0, 0],
    } },
  },
  {
    name: '四肢着地',
    pose: { bones: {
      root: [88, 20, 0], spine: [-6, 0, 0], chest: [-4, 0, 0], neck: [-40, 0, 0], head: [-35, 0, 0],
      hipL: [-88, 0, 4], kneeL: [92, 0, 0], ankleL: [50, 0, 0],
      hipR: [-88, 0, -4], kneeR: [92, 0, 0], ankleR: [50, 0, 0],
      shoulderL: [-80, 0, 4], elbowL: [0, 0, 0], wristL: [70, 0, 0],
      shoulderR: [-80, 0, -4], elbowR: [0, 0, 0], wristR: [70, 0, 0],
    } },
  },
  {
    name: '后撑坐地',
    pose: { bones: {
      root: [-38, 20, 0], spine: [4, 0, 0], chest: [2, 0, 0], neck: [14, 0, 0], head: [10, -10, 4],
      hipL: [-95, 0, 6], kneeL: [115, 0, 0], ankleL: [-10, 0, 0],
      hipR: [-52, 15, -10], kneeR: [6, 0, 0], ankleR: [20, 0, 0],
      shoulderL: [42, 0, 14], elbowL: [0, 0, 0], wristL: [-70, 0, 0],
      shoulderR: [42, 0, -14], elbowR: [0, 0, 0], wristR: [-70, 0, 0],
    } },
  },
  {
    name: '侧卧',
    pose: { bones: {
      root: [0, 0, 88], spine: [4, 0, -4], chest: [0, 0, 0], neck: [0, 0, -15], head: [0, 0, -10],
      hipL: [-35, 0, 4], kneeL: [60, 0, 0], ankleL: [20, 0, 0],
      hipR: [-15, 0, -2], kneeR: [30, 0, 0], ankleR: [20, 0, 0],
      shoulderR: [0, 0, -160], elbowR: [-110, 0, 0],
      shoulderL: [-10, 0, 10], elbowL: [-20, 0, 0],
    } },
  },
  {
    name: '趴卧',
    pose: { bones: {
      root: [90, 0, 0], spine: [-20, 0, 0], chest: [-25, 0, 0], neck: [-25, 0, 0], head: [-20, 0, 0],
      hipL: [4, 0, 4], kneeL: [100, 0, 0], ankleL: [40, 0, 0],
      hipR: [4, 0, -4], kneeR: [60, 0, 0], ankleR: [40, 0, 0],
      shoulderL: [-110, 0, 18], elbowL: [-100, 0, 0], shoulderR: [-110, 0, -18], elbowR: [-100, 0, 0],
    } },
  },
  {
    name: '仰卧屈膝',
    pose: { bones: {
      root: [-90, 0, 0], neck: [15, 0, 0], head: [5, -20, 0],
      hipL: [-60, 0, 4], kneeL: [110, 0, 0], ankleL: [10, 0, 0],
      hipR: [-6, 0, -4], kneeR: [10, 0, 0], ankleR: [40, 0, 0],
      shoulderL: [0, 0, 100], elbowL: [-90, 0, 0], shoulderR: [0, 0, -30], elbowR: [-10, 0, 0],
    } },
  },
  {
    name: '伸展',
    pose: { bones: {
      spine: [-6, 0, 0], chest: [-8, 0, 0], neck: [-10, 0, 0], head: [-14, 0, 0],
      shoulderL: [0, 0, 168], elbowL: [-8, 0, 0], shoulderR: [0, 0, -168], elbowR: [-8, 0, 0],
      ankleL: [30, 0, 0], ankleR: [30, 0, 0],
    } },
  },
  {
    name: '单手扶头',
    pose: { bones: {
      root: [0, 0, 4], spine: [0, 0, -4], chest: [-2, 0, -3], neck: [0, 0, 4], head: [-4, 0, 8],
      shoulderR: [10, -90, -150], elbowR: [-140, 0, 0],
      shoulderL: [4, 0, 10], elbowL: [-10, 0, 0],
      hipL: [-6, 0, -12], kneeL: [12, 0, 0], ankleL: [8, 0, 0],
      hipR: [2, 0, 4], kneeR: [2, 0, 0],
    } },
  },
  {
    name: '回眸',
    pose: { bones: {
      root: [0, 160, 0], spine: [-4, -15, 0], chest: [-4, -20, 0], neck: [0, -30, 0], head: [-4, -35, 0],
      hipL: [-14, 0, 2], kneeL: [16, 0, 0], ankleL: [-6, 0, 0],
      hipR: [10, 0, -2], kneeR: [20, 0, 0], ankleR: [30, 0, 0],
      shoulderL: [6, 0, 8], elbowL: [-14, 0, 0], shoulderR: [-4, 0, -8], elbowR: [-20, 0, 0],
    } },
  },
  {
    name: '交叉腿举臂',
    pose: { bones: {
      root: [0, 0, -3], spine: [-4, 0, 3], chest: [-6, 0, 2], head: [-6, 0, -6],
      shoulderL: [-6, 30, 160], elbowL: [-95, 0, 0], shoulderR: [-6, -30, -160], elbowR: [-95, 0, 0],
      hipL: [-4, 0, -10], kneeL: [6, 0, 0], ankleL: [6, 0, 0],
      hipR: [-2, 0, 9], kneeR: [6, 0, 0], ankleR: [6, 0, 0],
    } },
  },
  {
    name: '侧身坐',
    pose: { bones: {
      root: [-6, 20, 10], spine: [4, 0, -8], chest: [2, 0, -6], neck: [0, 0, 6], head: [-4, -15, 8],
      hipL: [-80, -20, -10], kneeL: [150, 0, 0], ankleL: [50, 0, 0],
      hipR: [-50, -30, -40], kneeR: [150, 0, 0], ankleR: [50, 0, 0],
      shoulderR: [6, 0, -30], elbowR: [-4, 0, 0], wristR: [-70, 0, 0],
      shoulderL: [-30, 0, 4], elbowL: [-60, 0, 0],
    } },
  },
];
