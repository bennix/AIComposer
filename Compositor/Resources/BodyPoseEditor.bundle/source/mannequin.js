// Mannequin model: articulated wooden-doll style figure built from simple solids.
// Character faces +Z, character's left is +X, Y is up. Units ≈ meters.
import * as THREE from 'three';

const D2R = Math.PI / 180;

// ---------- Bone definitions ----------
// limits in degrees: [min, max] for x, y, z (left side; right side is mirrored automatically)
export const BONE_DEFS = {
  root:      { label: '骨盆 / 整体', limits: [[-180, 180], [-180, 180], [-180, 180]] },
  spine:     { label: '腰部', limits: [[-40, 70], [-45, 45], [-35, 35]] },
  chest:     { label: '胸部', limits: [[-35, 50], [-40, 40], [-30, 30]] },
  neck:      { label: '颈部', limits: [[-40, 50], [-60, 60], [-35, 35]] },
  head:      { label: '头部', limits: [[-40, 45], [-50, 50], [-30, 30]] },
  shoulderL: { label: '左上臂', limits: [[-180, 70], [-100, 100], [-30, 175]] },
  elbowL:    { label: '左前臂', limits: [[-155, 0], [-90, 90], [0, 0]] },
  wristL:    { label: '左手', limits: [[-80, 80], [-40, 40], [-45, 45]] },
  shoulderR: { label: '右上臂', mirror: 'shoulderL' },
  elbowR:    { label: '右前臂', mirror: 'elbowL' },
  wristR:    { label: '右手', mirror: 'wristL' },
  hipL:      { label: '左大腿', limits: [[-140, 45], [-70, 70], [-35, 90]] },
  kneeL:     { label: '左小腿', limits: [[0, 160], [-20, 20], [0, 0]] },
  ankleL:    { label: '左脚', limits: [[-35, 70], [-35, 35], [-25, 25]] },
  hipR:      { label: '右大腿', mirror: 'hipL' },
  kneeR:     { label: '右小腿', mirror: 'kneeL' },
  ankleR:    { label: '右脚', mirror: 'ankleL' },
};
// resolve mirrored limits
for (const [name, def] of Object.entries(BONE_DEFS)) {
  if (def.mirror) {
    const src = BONE_DEFS[def.mirror].limits;
    def.limits = [
      [...src[0]],
      [-src[1][1], -src[1][0]],
      [-src[2][1], -src[2][0]],
    ];
  }
}
export const BONE_NAMES = Object.keys(BONE_DEFS);
export const MIRROR_PAIRS = [
  ['shoulderL', 'shoulderR'], ['elbowL', 'elbowR'], ['wristL', 'wristR'],
  ['hipL', 'hipR'], ['kneeL', 'kneeR'], ['ankleL', 'ankleR'],
];
// Dragging a joint rotates these ancestors (nearest first) so the joint follows the target.
// Bones not listed here move the whole figure instead.
export const IK_CHAINS = {
  chest: ['spine'],
  neck: ['chest', 'spine'],
  head: ['neck', 'chest', 'spine'],
};
for (const s of ['L', 'R']) {
  IK_CHAINS['shoulder' + s] = ['chest', 'spine'];
  IK_CHAINS['elbow' + s] = ['shoulder' + s];
  IK_CHAINS['wrist' + s] = ['elbow' + s, 'shoulder' + s];
  IK_CHAINS['knee' + s] = ['hip' + s];
  IK_CHAINS['ankle' + s] = ['knee' + s, 'hip' + s];
}

// ---------- Geometry helpers ----------
// Lathe solid hanging down from y=0 to y=-len. radiusFn(t) with t in [0,1] from top to bottom.
function latheSolid(len, radiusFn, { capTop = null, capBottom = null, segs = 40, radial = 36 } = {}) {
  const rTop = radiusFn(0), rBot = radiusFn(1);
  const ct = (capTop ?? rTop) / len;
  const cb = (capBottom ?? rBot) / len;
  const pts = [];
  for (let i = segs; i >= 0; i--) {
    const t = i / segs;
    let f = 1;
    if (t < ct) { const u = 1 - t / ct; f = Math.sqrt(Math.max(0, 1 - u * u)); }
    if (t > 1 - cb) { const u = 1 - (1 - t) / cb; f = Math.min(f, Math.sqrt(Math.max(0, 1 - u * u))); }
    pts.push(new THREE.Vector2(Math.max(radiusFn(t) * f, 1e-4), -t * len));
  }
  const geo = new THREE.LatheGeometry(pts, radial);
  geo.userData.profile = { len, radiusFn, ct, cb };
  return geo;
}
const lerp = (a, b, t) => a + (b - a) * t;
const bump = (t, c, w) => Math.exp(-((t - c) * (t - c)) / (2 * w * w));

export class Mannequin {
  constructor() {
    this.group = new THREE.Group();
    this.bones = {};
    this.parts = [];      // pickable body meshes
    this.inks = [];       // decorative ink lines
    this.shape = { height: 170, weight: 65, bust: 1, hips: 1, shoulders: 1, waist: 1, muscle: 1, headSize: 1 };
    this._build();
  }

  _bone(name, parent, pos) {
    const b = new THREE.Object3D();
    b.name = name;
    b.position.set(...pos);
    b.rotation.order = name === 'root' ? 'YXZ' : 'ZXY';
    b.userData.rest = new THREE.Vector3(...pos);
    (parent || this.group).add(b);
    this.bones[name] = b;
    return b;
  }

  _part(bone, geo, { pos = [0, 0, 0], scale = [1, 1, 1], rot = [0, 0, 0], key = null } = {}) {
    const m = new THREE.Mesh(geo);
    m.position.set(...pos);
    m.scale.set(...scale);
    m.rotation.set(rot[0] * D2R, rot[1] * D2R, rot[2] * D2R);
    m.userData.bone = bone.name;
    m.userData.baseScale = new THREE.Vector3(...scale);
    m.userData.basePos = new THREE.Vector3(...pos);
    if (key) m.userData.key = key;
    bone.add(m);
    this.parts.push(m);
    return m;
  }

  // Ink line along points (in the parent mesh's local space)
  _ink(mesh, points, radius = 0.0038, closed = false) {
    const curve = new THREE.CatmullRomCurve3(points, closed);
    // compensate the mesh scale so the tube stays roughly round
    const s = mesh.scale;
    const avg = (s.x + s.y + s.z) / 3;
    const geo = new THREE.TubeGeometry(curve, Math.max(24, points.length * 3), radius / avg, 6, closed);
    const ink = new THREE.Mesh(geo);
    ink.userData.ink = true;
    ink.raycast = () => {};
    mesh.add(ink);
    this.inks.push(ink);
    return ink;
  }

  // Meridian line on a lathe mesh facing direction angle (0 = +Z) between t0..t1
  _latheMeridian(mesh, t0, t1, angle = 0, n = 24) {
    const { len, radiusFn, ct, cb } = mesh.geometry.userData.profile;
    const pts = [];
    for (let i = 0; i <= n; i++) {
      const t = lerp(t0, t1, i / n);
      let f = 1;
      if (t < ct) { const u = 1 - t / ct; f = Math.sqrt(Math.max(0, 1 - u * u)); }
      if (t > 1 - cb) { const u = 1 - (1 - t) / cb; f = Math.min(f, Math.sqrt(Math.max(0, 1 - u * u))); }
      const r = radiusFn(t) * f + 0.0015;
      pts.push(new THREE.Vector3(Math.sin(angle) * r, -t * len, Math.cos(angle) * r));
    }
    return this._ink(mesh, pts);
  }

  // Ring around a lathe mesh at parameter t, covering angle range
  _latheRing(mesh, t, a0 = -Math.PI, a1 = Math.PI, n = 48) {
    const { len, radiusFn } = mesh.geometry.userData.profile;
    const r = radiusFn(t) + 0.0015;
    const pts = [];
    for (let i = 0; i <= n; i++) {
      const a = lerp(a0, a1, i / n);
      pts.push(new THREE.Vector3(Math.sin(a) * r, -t * len, Math.cos(a) * r));
    }
    return this._ink(mesh, pts);
  }

  _build() {
    const sphere = new THREE.SphereGeometry(1, 48, 32);

    // ----- Root / pelvis -----
    const root = this._bone('root', null, [0, 0.93, 0]);
    const pelvisGeo = latheSolid(0.2, (t) => {
      return 0.112 + 0.04 * bump(t, 0.38, 0.22) - 0.035 * t * t;
    }, { capTop: 0.03, capBottom: 0.07 });
    const pelvis = this._part(root, pelvisGeo, { pos: [0, 0.09, -0.005], scale: [1, 1, 0.74], key: 'pelvis' });
    this._latheMeridian(pelvis, 0.05, 0.9, 0);
    // bikini line curves (front)
    {
      const pts = [];
      const { len, radiusFn } = pelvisGeo.userData.profile;
      for (let i = 0; i <= 30; i++) {
        const s = i / 30; // 0..1 across from left side to right side
        const a = lerp(1.25, -1.25, s);
        const t = 0.32 + 0.5 * (1 - Math.abs(a) / 1.25) ** 1.4;
        const r = radiusFn(t) + 0.0015;
        pts.push(new THREE.Vector3(Math.sin(a) * r, -t * len, Math.cos(a) * r));
      }
      this._ink(pelvis, pts);
    }

    // ----- Spine / abdomen -----
    const spine = this._bone('spine', root, [0, 0.07, 0]);
    const absGeo = latheSolid(0.17, (t) => {
      // t=0 top (waist up toward ribs) .. t=1 bottom (toward pelvis)
      return 0.088 + 0.025 * t * t + 0.008 * bump(t, 0.1, 0.1);
    }, { capTop: 0.02, capBottom: 0.04 });
    const abs = this._part(spine, absGeo, { pos: [0, 0.16, 0], scale: [1, 1, 0.72], key: 'abs' });
    this._latheMeridian(abs, 0.08, 0.92, 0);

    // ----- Chest -----
    const chest = this._bone('chest', spine, [0, 0.12, 0]);
    const chestGeo = latheSolid(0.3, (t) => {
      // t=0 top (shoulder line) .. t=1 bottom (rib cage)
      return 0.088 + 0.045 * bump(t, 0.55, 0.28) + 0.01 * (1 - t);
    }, { capTop: 0.06, capBottom: 0.05 });
    const chestMesh = this._part(chest, chestGeo, { pos: [0, 0.3, 0], scale: [1, 1, 0.66], key: 'chest' });
    this._latheMeridian(chestMesh, 0.55, 0.96, 0);
    // breasts
    this.breastL = this._part(chest, sphere, { pos: [0.058, 0.155, 0.062], scale: [0.054, 0.052, 0.05], key: 'breastL' });
    this.breastR = this._part(chest, sphere, { pos: [-0.058, 0.155, 0.062], scale: [0.054, 0.052, 0.05], key: 'breastR' });
    this.breastL.userData.bone = 'chest';
    this.breastR.userData.bone = 'chest';

    // ----- Neck / head -----
    const neck = this._bone('neck', chest, [0, 0.29, -0.005]);
    const neckGeo = latheSolid(0.1, () => 0.033, { capTop: 0.01, capBottom: 0.01 });
    this._part(neck, neckGeo, { pos: [0, 0.1, 0], key: 'neck' });
    const head = this._bone('head', neck, [0, 0.085, 0]);
    // egg-shaped head: sphere with tapered chin
    const headGeo = new THREE.SphereGeometry(1, 48, 36);
    {
      const p = headGeo.attributes.position;
      for (let i = 0; i < p.count; i++) {
        const y = p.getY(i);
        if (y < 0) {
          const k = 1 - 0.32 * (y * y); // narrower toward chin
          p.setX(i, p.getX(i) * k);
          p.setZ(i, p.getZ(i) * (1 - 0.12 * y * y));
        }
      }
      headGeo.computeVertexNormals();
    }
    const headMesh = this._part(head, headGeo, { pos: [0, 0.105, 0.012], scale: [0.078, 0.112, 0.092], key: 'head' });
    this.headMesh = headMesh;
    // face cross lines (vertical center + eye line)
    {
      const vp = [];
      for (let i = 0; i <= 40; i++) {
        const a = lerp(-1.45, 1.35, i / 40);
        const y = Math.sin(a), c = Math.cos(a);
        let x = 0, z = c;
        if (y < 0) z *= (1 - 0.12 * y * y);
        vp.push(new THREE.Vector3(x, y, z).multiplyScalar(1.018));
      }
      this._ink(headMesh, vp);
      const hp = [];
      const ey = -0.12;
      for (let i = 0; i <= 40; i++) {
        const a = lerp(-1.5, 1.5, i / 40);
        const r = Math.sqrt(1 - ey * ey);
        const k = 1 - 0.32 * ey * ey;
        hp.push(new THREE.Vector3(Math.sin(a) * r * k, ey, Math.cos(a) * r * (1 - 0.12 * ey * ey)).multiplyScalar(1.018));
      }
      this._ink(headMesh, hp);
    }

    // ----- Arms -----
    for (const side of ['L', 'R']) {
      const s = side === 'L' ? 1 : -1;
      const sh = this._bone('shoulder' + side, chest, [0.158 * s, 0.255, -0.008]);
      this._part(sh, sphere, { scale: [0.043, 0.043, 0.043], key: 'shoulderBall' + side });
      const uaGeo = latheSolid(0.27, (t) => 0.039 + 0.006 * bump(t, 0.3, 0.2) - 0.01 * t, { capTop: 0.03, capBottom: 0.03 });
      this._part(sh, uaGeo, { pos: [0, -0.01, 0], key: 'upperArm' + side });
      const el = this._bone('elbow' + side, sh, [0, -0.27, 0]);
      this._part(el, sphere, { scale: [0.031, 0.031, 0.031], key: 'elbowBall' + side });
      const faGeo = latheSolid(0.235, (t) => 0.033 + 0.005 * bump(t, 0.2, 0.15) - 0.013 * t, { capTop: 0.026, capBottom: 0.02 });
      this._part(el, faGeo, { pos: [0, -0.008, 0], key: 'forearm' + side });
      const wr = this._bone('wrist' + side, el, [0, -0.238, 0]);
      this._part(wr, sphere, { scale: [0.022, 0.022, 0.022], key: 'wristBall' + side });
      // mitten hand: palm + fingers + thumb (palm faces body: thin in X)
      this._part(wr, sphere, { pos: [0, -0.06, 0.004], scale: [0.019, 0.05, 0.038], key: 'palm' + side });
      this._part(wr, sphere, { pos: [0, -0.125, 0.002], scale: [0.015, 0.042, 0.034], rot: [8, 0, 0], key: 'fingers' + side });
      this._part(wr, sphere, { pos: [-0.012 * s, -0.05, 0.035], scale: [0.012, 0.034, 0.012], rot: [-30, 0, 18 * s], key: 'thumb' + side });
    }

    // ----- Legs -----
    for (const side of ['L', 'R']) {
      const s = side === 'L' ? 1 : -1;
      const hip = this._bone('hip' + side, root, [0.083 * s, -0.045, 0]);
      this._part(hip, sphere, { pos: [0.006 * s, 0, 0], scale: [0.066, 0.066, 0.066], key: 'hipBall' + side });
      const thGeo = latheSolid(0.42, (t) => 0.072 + 0.006 * bump(t, 0.2, 0.15) - 0.03 * t, { capTop: 0.06, capBottom: 0.04 });
      const thigh = this._part(hip, thGeo, { pos: [0, 0, 0], key: 'thigh' + side });
      this._latheRing(thigh, 0.55, -1.0, 1.0);
      const kn = this._bone('knee' + side, hip, [0, -0.42, 0]);
      this._part(kn, sphere, { pos: [0, 0, 0.006], scale: [0.044, 0.044, 0.044], key: 'kneeBall' + side });
      const shGeo = latheSolid(0.39, (t) => 0.041 + 0.01 * bump(t, 0.25, 0.14) - 0.016 * t, { capTop: 0.04, capBottom: 0.026 });
      this._part(kn, shGeo, { pos: [0, -0.005, 0], key: 'shin' + side });
      const an = this._bone('ankle' + side, kn, [0, -0.39, 0]);
      this._part(an, sphere, { scale: [0.03, 0.03, 0.03], key: 'ankleBall' + side });
      this._part(an, sphere, { pos: [0, -0.042, 0.045], scale: [0.037, 0.03, 0.098], rot: [4, 0, 0], key: 'foot' + side });
      this._part(an, sphere, { pos: [0, -0.05, 0.13], scale: [0.033, 0.019, 0.04], rot: [0, 0, 0], key: 'toes' + side });
    }

    // assign ids
    let id = 2;
    for (const m of this.parts) m.userData.id = id++;
    this.group.updateMatrixWorld(true);
  }

  // ---------- Body shape ----------
  setShape(shape) {
    Object.assign(this.shape, shape);
    const s = this.shape;
    const heightScale = s.height / 170;
    const bmi = s.weight / (s.height / 100) ** 2;
    const bodyWidth = Math.max(0.65, Math.min(1.7, Math.sqrt(bmi / (65 / 1.7 ** 2))));
    this.group.scale.set(heightScale * bodyWidth, heightScale, heightScale * bodyWidth);
    const byKey = (k) => this.parts.find((p) => p.userData.key === k);
    const setS = (k, fx, fy = 1, fz = fx) => {
      const m = byKey(k); if (!m) return;
      const b = m.userData.baseScale;
      m.scale.set(b.x * fx, b.y * fy, b.z * fz);
    };
    setS('breastL', s.bust, s.bust, s.bust);
    setS('breastR', s.bust, s.bust, s.bust);
    for (const k of ['breastL', 'breastR']) {
      const m = byKey(k); const b = m.userData.basePos;
      m.position.set(b.x, b.y - (s.bust - 1) * 0.01, b.z + (s.bust - 1) * 0.012 - (1 - s.bust) * 0.02 * 0);
      m.visible = s.bust > 0.05;
    }
    setS('pelvis', s.hips, 1, 0.74 / 0.74 * (0.85 + 0.15 * s.hips));
    setS('hipBallL', s.hips); setS('hipBallR', s.hips);
    this.bones.hipL.position.x = 0.083 * (0.7 + 0.3 * s.hips);
    this.bones.hipR.position.x = -0.083 * (0.7 + 0.3 * s.hips);
    setS('chest', s.shoulders, 1, 0.9 + 0.1 * s.shoulders);
    this.bones.shoulderL.position.x = 0.158 * s.shoulders;
    this.bones.shoulderR.position.x = -0.158 * s.shoulders;
    setS('abs', s.waist, 1, 0.9 + 0.1 * s.waist);
    for (const side of ['L', 'R']) {
      for (const k of ['upperArm', 'forearm', 'thigh', 'shin']) setS(k + side, s.muscle, 1, s.muscle);
      for (const k of ['shoulderBall', 'elbowBall', 'kneeBall']) setS(k + side, 0.85 + 0.15 * s.muscle);
    }
    setS('head', s.headSize / bodyWidth, s.headSize, s.headSize / bodyWidth);
    // ink tubes inherit scaling; fine for small variations
    this.group.updateMatrixWorld(true);
  }

  // ---------- Pose I/O ----------
  getPose() {
    const bones = {};
    for (const n of BONE_NAMES) {
      const r = this.bones[n].rotation;
      bones[n] = [r.x / D2R, r.y / D2R, r.z / D2R].map((v) => Math.round(v * 100) / 100);
    }
    const p = this.bones.root.position;
    return { root: [p.x, p.y, p.z], bones };
  }

  setPose(pose, { partial = false } = {}) {
    if (!partial) for (const n of BONE_NAMES) this.bones[n].rotation.set(0, 0, 0);
    if (pose.bones) {
      for (const [n, v] of Object.entries(pose.bones)) {
        const b = this.bones[n];
        if (b) b.rotation.set(v[0] * D2R, (v[1] || 0) * D2R, (v[2] || 0) * D2R);
      }
    }
    if (pose.root) this.bones.root.position.set(pose.root[0] || 0, pose.root[1] ?? 0.93, pose.root[2] || 0);
    else if (!partial) this.bones.root.position.set(0, 0.93, 0);
    this.group.updateMatrixWorld(true);
  }

  resetPose() { this.setPose({ bones: {} }); }

  mirrorPose() {
    const p = this.getPose();
    const out = { root: [-p.root[0], p.root[1], p.root[2]], bones: {} };
    const m = (v) => [v[0], -v[1], -v[2]];
    for (const n of ['root', 'spine', 'chest', 'neck', 'head']) out.bones[n] = m(p.bones[n]);
    for (const [a, b] of MIRROR_PAIRS) { out.bones[a] = m(p.bones[b]); out.bones[b] = m(p.bones[a]); }
    this.setPose(out);
  }

  clampBone(name) {
    const def = BONE_DEFS[name];
    const r = this.bones[name].rotation;
    const c = (v, [lo, hi]) => Math.min(hi * D2R, Math.max(lo * D2R, v));
    r.set(c(r.x, def.limits[0]), c(r.y, def.limits[1]), c(r.z, def.limits[2]));
  }

  // CCD inverse kinematics: rotate the ancestors of `name` so its joint reaches `target` (world space).
  // Returns false for bones that have no IK chain.
  solveIK(name, target, { limits = true, iterations = 16 } = {}) {
    const chain = IK_CHAINS[name];
    if (!chain) return false;
    const eff = this.bones[name];
    const effW = new THREE.Vector3(), a = new THREE.Vector3(), b = new THREE.Vector3();
    const q = new THREE.Quaternion();
    // Two-bone limbs: set the hinge bend analytically from the target distance,
    // then let CCD aim the joints above it (CCD alone gets stuck on a straight, clamped hinge).
    let hinge = chain.find((bn) => BONE_DEFS[bn].limits[2][0] === BONE_DEFS[bn].limits[2][1]);
    if (hinge && chain.indexOf(hinge) === chain.length - 1) hinge = null;
    if (hinge) {
      const h = this.bones[hinge];
      const base = this.bones[chain[chain.indexOf(hinge) + 1]].getWorldPosition(new THREE.Vector3());
      const L1 = h.position.length(), L2 = eff.position.length();
      const d = THREE.MathUtils.clamp(base.distanceTo(target), Math.abs(L1 - L2) + 1e-4, L1 + L2 - 1e-4);
      const bend = Math.PI - Math.acos((L1 * L1 + L2 * L2 - d * d) / (2 * L1 * L2));
      const hi = BONE_DEFS[hinge].limits[0][1];
      h.rotation.x = (hi > 0 ? 1 : -1) * bend;
      if (limits) this.clampBone(hinge);
      h.updateMatrixWorld(true);
    }
    for (let it = 0; it < iterations; it++) {
      for (const bn of chain) {
        const bone = this.bones[bn];
        eff.getWorldPosition(effW);
        if (effW.distanceToSquared(target) < 1e-8) return true;
        if (bn === hinge) continue;
        const lz = BONE_DEFS[bn].limits[2];
        if (lz[0] === lz[1]) {
          // hinge (knee/elbow): bend only about the parent-space X axis, keep twist
          a.copy(effW); bone.parent.worldToLocal(a).sub(bone.position);
          b.copy(target); bone.parent.worldToLocal(b).sub(bone.position);
          bone.rotation.x += Math.atan2(a.y * b.z - a.z * b.y, a.y * b.y + a.z * b.z);
        } else {
          a.copy(effW); bone.worldToLocal(a);
          b.copy(target); bone.worldToLocal(b);
          if (a.lengthSq() < 1e-10 || b.lengthSq() < 1e-10) continue;
          q.setFromUnitVectors(a.normalize(), b.normalize());
          bone.quaternion.multiply(q);
        }
        if (limits) this.clampBone(bn);
        bone.updateMatrixWorld(true);
      }
    }
    return true;
  }

  // Lowest world-space Y over all vertices
  lowestPoint() {
    this.group.updateMatrixWorld(true);
    let min = Infinity;
    const v = new THREE.Vector3();
    for (const m of this.parts) {
      if (!m.visible) continue;
      const pos = m.geometry.attributes.position;
      const step = pos.count > 600 ? 3 : 1;
      for (let i = 0; i < pos.count; i += step) {
        v.fromBufferAttribute(pos, i).applyMatrix4(m.matrixWorld);
        if (v.y < min) min = v.y;
      }
    }
    return min;
  }

  snapToGround() {
    const low = this.lowestPoint();
    this.bones.root.position.y -= low / this.group.scale.y;
    this.group.updateMatrixWorld(true);
  }

  // Bounding info for camera framing
  worldPoints(step = 4) {
    this.group.updateMatrixWorld(true);
    const out = [];
    for (const m of this.parts) {
      if (!m.visible) continue;
      const pos = m.geometry.attributes.position;
      for (let i = 0; i < pos.count; i += step) {
        out.push(new THREE.Vector3().fromBufferAttribute(pos, i).applyMatrix4(m.matrixWorld));
      }
    }
    return out;
  }

  randomPose(amount = 0.45) {
    const pose = { bones: {} };
    const rnd = (lo, hi) => {
      const mid = Math.max(lo, Math.min(hi, 0));
      const a = mid + (Math.random() * 2 - 1) * (hi - lo) * 0.5 * amount;
      return Math.max(lo, Math.min(hi, a));
    };
    for (const n of BONE_NAMES) {
      if (n === 'root') continue;
      const L = BONE_DEFS[n].limits;
      pose.bones[n] = [rnd(...L[0]), rnd(...L[1]) * 0.5, rnd(...L[2])];
    }
    pose.bones.root = [0, Math.random() * 60 - 30, 0];
    this.setPose(pose);
  }
}
