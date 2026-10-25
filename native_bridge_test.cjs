const fs=require('fs'),vm=require('vm'),assert=require('assert');
const nodes={};function node(id){return nodes[id]??={checked:true,value:'',textContent:'',events:{},addEventListener(k,fn){(this.events[k]??=[]).push(fn)},fire(k){(this.events[k]||[]).forEach(f=>f())},after(){},classList:{contains:()=>false}}}
Object.assign(node('vibrate'),{checked:false});for(const [id,value]of Object.entries({'start-time':'09:00','end-time':'21:00',rhythm:'35',rotation:'3',instrument:'bowl'}))node(id).value=value;
let timer=null,messages=[],visibility=0;
const document={getElementById:node,createElement:()=>node('retry'),querySelector:node,dispatchEvent(){visibility++}};
const window={};vm.runInNewContext(fs.readFileSync('assets/web/native_bridge.js','utf8'),{window,document,Event:class{},setTimeout:f=>(timer=f,1),clearTimeout:()=>timer=null,StillNative:{postMessage:s=>messages.push(JSON.parse(s))}});
timer();assert.equal(messages[0].settings.instrument,'bowl');assert.equal(messages[0].settings.vibration,false);
node('reminders').checked=false;node('reminders').fire('change');node('instrument').value='crystal';node('instrument').fire('change');timer();assert.equal(messages.length,2);assert.equal(messages[1].settings.enabled,false);assert.equal(messages[1].settings.instrument,'crystal');
window.stillNativeResult(1,'stale');assert.notEqual(node('status').textContent,'stale');window.stillNativeResult(messages[1].id,'Saved');assert.equal(node('status').textContent,'Saved');
node('end-time').value='08:00';node('end-time').fire('change');assert.equal(timer,null);assert(node('status').textContent.includes('Previous schedule'));
window.stillNativeLifecycle(true);assert.equal(window.stillNativeHidden,true);assert.equal(visibility,1);
console.log('PASS: native bridge sends actual settings, coalesces rapid edits, rejects invalid time, ignores stale replies, forwards lifecycle.');
