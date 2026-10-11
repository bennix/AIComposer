import assert from 'node:assert/strict';
import * as THREE from 'three';
import { Mannequin, BONE_DEFS } from './mannequin.js';
import { PRESETS } from './poses.js';
const model=new Mannequin();assert.equal(PRESETS.length,22);
for(const preset of PRESETS){model.setPose(preset.pose);model.snapToGround();assert.ok(Math.abs(model.lowestPoint())<1e-5,preset.name);for(const values of Object.values(model.getPose().bones))assert.ok(values.every(Number.isFinite));}
model.resetPose();model.snapToGround();
const initial=model.bones.wristL.getWorldPosition(new THREE.Vector3());
const target=initial.clone().add(new THREE.Vector3(.2,.25,.1));
assert.equal(model.solveIK('wristL',target,{limits:true,iterations:32}),true);
const after=model.bones.wristL.getWorldPosition(new THREE.Vector3());assert.ok(after.distanceTo(target)<initial.distanceTo(target)*.6, 'hand IK converges');
for(const name of ['shoulderL','elbowL']){const r=model.bones[name].rotation;for(const [axis,i] of ['x','y','z'].map((a,i)=>[a,i])){const [lo,hi]=BONE_DEFS[name].limits[i];assert.ok(r[axis]>=lo*Math.PI/180-1e-6&&r[axis]<=hi*Math.PI/180+1e-6);}}
const other=new Mannequin();assert.notDeepEqual(model.getPose(),other.getPose());
const saved=model.getPose();const clone=new Mannequin();clone.setPose(saved);assert.deepEqual(clone.getPose(),saved);
assert.equal(model.solveIK('root',target),false);
console.log('PASS: 22 presets, grounding, hand IK convergence, joint limits, independent people, pose round-trip.');
