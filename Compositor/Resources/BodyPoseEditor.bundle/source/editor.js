import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { TransformControls } from 'three/addons/controls/TransformControls.js';
import { Mannequin, BONE_NAMES, BONE_DEFS, IK_CHAINS } from './mannequin.js';
import { PRESETS } from './poses.js';

const $ = id => document.getElementById(id);
const canvas = $('stage');
const renderer = new THREE.WebGLRenderer({canvas,antialias:true,preserveDrawingBuffer:true});
renderer.setPixelRatio(Math.min(devicePixelRatio,2));
renderer.setClearColor(0xf5f4ef);
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(36,1,.02,100);
camera.position.set(0,1.5,5);
const orbit = new OrbitControls(camera,canvas);orbit.target.set(0,.9,0);orbit.enableDamping=true;
scene.add(new THREE.HemisphereLight(0xffffff,0x888078,2));
const light = new THREE.DirectionalLight(0xffffff,3);light.position.set(-3,5,6);scene.add(light);
const grid = new THREE.GridHelper(12,24,0xbcb6aa,0xe2ded4);scene.add(grid);
const proxy = new THREE.Object3D();scene.add(proxy);
const gizmo = new TransformControls(camera,canvas);scene.add(gizmo.getHelper());gizmo.setSize(.8);
const raycaster=new THREE.Raycaster(),pointer=new THREE.Vector2();
const colors=[0xc57b41,0x3b8e96,0x8660aa,0x5d9052,0xb65e72];
let figures=[], selected=0, joint='root', markers=new THREE.Group(), moving=false, restoring=false;
scene.add(markers);
const error = message => { $('error').textContent=message;window.webkit?.messageHandlers.poseEditor.postMessage({type:'error',message}); };
window.addEventListener('error',e=>error(e.message));
for(const [i,preset] of PRESETS.entries()) {const o=new Option(preset.name,String(i));$('preset').add(o);}
for(const name of BONE_NAMES) $('joint').add(new Option(BONE_DEFS[name].label,name));
function active(){return figures[selected]?.model;}
function clearMarkers(){for(const child of [...markers.children]){child.geometry.dispose();child.material.dispose();markers.remove(child);}}
function updateMarkers(){
 clearMarkers();const model=active();if(!model)return;
 model.group.updateMatrixWorld(true);
 for(const name of BONE_NAMES){const ball=new THREE.Mesh(new THREE.SphereGeometry(.024,8,6),new THREE.MeshBasicMaterial({color:name===joint?0xe74d2a:0x426ba0,depthTest:false}));ball.position.copy(model.bones[name].getWorldPosition(new THREE.Vector3()));ball.userData.joint=name;ball.renderOrder=10;markers.add(ball);}
}
function syncHandle(){const model=active();if(!model)return;restoring=true;model.group.updateMatrixWorld(true);proxy.position.copy(model.bones[joint].getWorldPosition(new THREE.Vector3()));proxy.quaternion.copy(model.bones[joint].getWorldQuaternion(new THREE.Quaternion()));gizmo.attach(proxy);restoring=false;updateMarkers();}
function select(index){selected=index;joint='root';$('joint').value=joint;$('person').value=String(index);syncHandle();}
function ground(model){if($('ground').checked)model.snapToGround();}
function fit(){
 if(!figures.length)return;const box=new THREE.Box3();figures.forEach(f=>box.expandByObject(f.model.group));const size=box.getSize(new THREE.Vector3()),center=box.getCenter(new THREE.Vector3());const distance=Math.max(size.y,size.x/Math.max(camera.aspect,.1),size.z)*1.9+.7;camera.position.copy(center).add(new THREE.Vector3(0,.2,distance));orbit.target.copy(center);orbit.update();
}
function resize(){renderer.setSize(canvas.clientWidth,canvas.clientHeight,false);camera.aspect=canvas.clientWidth/Math.max(canvas.clientHeight,1);camera.updateProjectionMatrix();}new ResizeObserver(resize).observe(canvas);
gizmo.addEventListener('dragging-changed',event=>{moving=event.value;orbit.enabled=!moving;if(!moving)syncHandle();});
gizmo.addEventListener('objectChange',()=>{
 if(restoring)return;const model=active();if(!model)return;
 if(gizmo.mode==='translate'){
  if(IK_CHAINS[joint]) model.solveIK(joint,proxy.position,{limits:$('limits').checked,iterations:24});
  else {const current=model.bones[joint].getWorldPosition(new THREE.Vector3());const localTarget=model.group.worldToLocal(proxy.position.clone());const localCurrent=model.group.worldToLocal(current);model.bones.root.position.add(localTarget.sub(localCurrent));}
 } else {
  const node=model.bones[joint];const parentRotation=node.parent.getWorldQuaternion(new THREE.Quaternion());node.quaternion.copy(parentRotation.invert().multiply(proxy.quaternion));if($('limits').checked)model.clampBone(joint);
 }
 model.group.updateMatrixWorld(true);ground(model);updateMarkers();
});
canvas.addEventListener('pointerdown',e=>{
 if(gizmo.axis)return;const rect=canvas.getBoundingClientRect();pointer.set((e.clientX-rect.left)/rect.width*2-1,-(e.clientY-rect.top)/rect.height*2+1);raycaster.setFromCamera(pointer,camera);const hit=raycaster.intersectObjects(markers.children)[0];if(hit){joint=hit.object.userData.joint;$('joint').value=joint;syncHandle();}
});
$('person').onchange=()=>select(Number($('person').value));
$('joint').onchange=()=>{joint=$('joint').value;syncHandle();};
$('preset').onchange=()=>{if($('preset').value==='')return;active().setPose(PRESETS[Number($('preset').value)].pose);ground(active());syncHandle();$('preset').value='';};
function mode(value){gizmo.setMode(value);$('move').classList.toggle('active',value==='translate');$('rotate').classList.toggle('active',value==='rotate');syncHandle();}
$('move').onclick=()=>mode('translate');$('rotate').onclick=()=>mode('rotate');
$('mirror').onclick=()=>{active().mirrorPose();ground(active());syncHandle();};
$('reset').onclick=()=>{active().resetPose();ground(active());syncHandle();};
$('ground').onchange=()=>{ground(active());syncHandle();};
$('front').onclick=()=>{fit();};$('fit').onclick=fit;
$('side').onclick=()=>{fit();const d=camera.position.distanceTo(orbit.target);camera.position.copy(orbit.target).add(new THREE.Vector3(d,.2,0));orbit.update();};
window.loadPosePlan=(people,document)=>{
 for(const figure of figures){scene.remove(figure.model.group);figure.model.group.traverse(n=>{n.geometry?.dispose();if(Array.isArray(n.material))n.material.forEach(m=>m.dispose());else n.material?.dispose();});}
 figures=[];$('person').replaceChildren();let saved={};try{saved=JSON.parse(document||'{}');}catch{}
 people.forEach((person,index)=>{
  const model=new Mannequin();const prior=saved.figures?.find(f=>f.id===person.id);
  model.group.traverse(n=>{if(n.isMesh){n.material=new THREE.MeshStandardMaterial({color:colors[index],roughness:.7});}});
  model.group.position.set((index-(people.length-1)/2)*.85,0,0);
  if(prior){model.setPose(prior.pose);model.group.position.fromArray(prior.position);}ground(model);scene.add(model.group);figures.push({id:person.id,model});$('person').add(new Option(`人物 ${index+1}`,String(index)));
 });
 select(0);fit();if(saved.camera && saved.target){camera.position.fromArray(saved.camera);orbit.target.fromArray(saved.target);orbit.update();}
 window.webkit?.messageHandlers.poseEditor.postMessage({type:'ready'});
};
window.exportPosePlan=()=>{
 if(!figures.length)return error('没有可保存的人偶。');
 const state={figures:figures.map(f=>({id:f.id,pose:f.model.getPose(),position:f.model.group.position.toArray()})),camera:camera.position.toArray(),target:orbit.target.toArray()};
 const visible=gizmo.getHelper().visible;gizmo.getHelper().visible=false;markers.visible=false;grid.visible=false;renderer.render(scene,camera);
 const output=document.createElement('canvas');output.width=renderer.domElement.width;output.height=renderer.domElement.height;const context=output.getContext('2d');context.drawImage(renderer.domElement,0,0);context.font=`bold ${Math.max(20,output.width/45)}px system-ui`;context.textAlign='center';context.fillStyle='#222';
 figures.forEach((f,index)=>{const box=new THREE.Box3().setFromObject(f.model.group);const p=new THREE.Vector3((box.min.x+box.max.x)/2,box.max.y+.09,(box.min.z+box.max.z)/2).project(camera);context.fillText(`人物 ${index+1}`, (p.x+1)/2*output.width,(1-p.y)/2*output.height);});
 const png=output.toDataURL('image/png').split(',')[1];gizmo.getHelper().visible=visible;markers.visible=true;grid.visible=true;
 window.webkit?.messageHandlers.poseEditor.postMessage({type:'saved',png,document:JSON.stringify(state),ids:figures.map(f=>f.id)});
};
function frame(){requestAnimationFrame(frame);orbit.update();renderer.render(scene,camera);}resize();frame();
