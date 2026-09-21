const text=document.getElementById('text');
const statusEl=document.getElementById('status');
const langBtn=document.getElementById('langBtn');
const detectBtn=document.getElementById('detectBtn');
const fixBtn=document.getElementById('fixBtn');
const clearBtn=document.getElementById('clearBtn');

function detectLanguage(value){
  const ar=(value.match(/[\u0600-\u06FF]/g)||[]).length;
  const en=(value.match(/[A-Za-z]/g)||[]).length;
  if(!ar&&!en) return 'unknown';
  return ar>=en?'ar':'en';
}

function applyDirection(lang){
  if(lang==='ar'){
    text.dir='rtl';
    text.lang='ar';
    document.documentElement.dir='rtl';
    document.documentElement.lang='ar';
    statusEl.textContent='الوضع الحالي: عربي';
  }else{
    text.dir='ltr';
    text.lang='en';
    document.documentElement.dir='ltr';
    document.documentElement.lang='en';
    statusEl.textContent='Current mode: English';
  }
}

langBtn.addEventListener('click',()=>{
  const current=text.lang==='en'?'en':'ar';
  applyDirection(current==='ar'?'en':'ar');
  text.focus();
});

detectBtn.addEventListener('click',()=>{
  const lang=detectLanguage(text.value);
  if(lang==='unknown'){
    statusEl.textContent='ماكو نص كافي لاكتشاف اللغة.';
    return;
  }
  applyDirection(lang);
});

fixBtn.addEventListener('click',()=>{
  let v=text.value;
  v=v.replace(/[ \t]+/g,' ');
  v=v.replace(/ +([,.!?،؛:])/g,'$1');
  v=v.replace(/([,.!?،؛:])([^\s\n])/g,'$1 $2');
  v=v.replace(/\n{3,}/g,'\n\n');
  v=v.trim();
  text.value=v;
  const lang=detectLanguage(v);
  if(lang!=='unknown') applyDirection(lang);
  statusEl.textContent=lang==='en'?'Quick formatting fixed. Browser spellcheck is enabled.':'تم تصحيح المسافات وعلامات الترقيم بسرعة، والتدقيق الإملائي للمتصفح مفعّل.';
});

clearBtn.addEventListener('click',()=>{
  text.value='';
  statusEl.textContent='تم المسح.';
  text.focus();
});

text.addEventListener('input',()=>{
  const lang=detectLanguage(text.value);
  if(lang!=='unknown') {
    text.dir=lang==='ar'?'rtl':'ltr';
    text.lang=lang;
  }
});