(() => {
 const el=id=>document.getElementById(id);
 let revision=0,timer;
 window.stillNativeResult=(id,message)=>{if(id===revision)el('status').textContent=message;};
 window.stillNativeLifecycle=hidden=>{window.stillNativeHidden=hidden;document.dispatchEvent(new Event('visibilitychange'));};
 window.stillNativeBack=()=>{if(!document.querySelector('.device').classList.contains('show-settings'))return false;document.querySelector('.settings-back').click();return true;};
 function send(){
  clearTimeout(timer);
  const settings={enabled:el('reminders').checked,sound:el('sound').checked,vibration:el('vibrate').checked,start:el('start-time').value,end:el('end-time').value,rhythm:Number(el('rhythm').value),rotation:Number(el('rotation').value),instrument:el('instrument').value};
  const id=++revision;
  if(!settings.start||!settings.end||settings.end<=settings.start){el('status').textContent='Check reminder times. Previous schedule is unchanged.';return;}
  el('status').textContent='Saving reminders…';
  timer=setTimeout(()=>StillNative.postMessage(JSON.stringify({id,settings})),250);
 }
 ['reminders','sound','vibrate','start-time','end-time','rhythm','rotation','instrument'].forEach(id=>el(id).addEventListener('change',send));
 const retry=document.createElement('button');retry.textContent='Renew reminders';retry.className='pause';retry.addEventListener('click',send);el('status').after(retry);
 send();
})();
