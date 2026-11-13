import React,{useEffect,useState} from 'react';
import {BlueprintPage} from '../pages/blueprint/index.js';
const routes=new Set(['/','/qa/blueprints','/qa/shared']);
export function App(){
 const [path,setPath]=useState(()=>window.location.pathname);
 useEffect(()=>{const onPop=()=>setPath(window.location.pathname);window.addEventListener('popstate',onPop);return()=>window.removeEventListener('popstate',onPop);},[]);
 function navigate(event){if(event.button!==0||event.ctrlKey||event.metaKey||event.shiftKey||event.altKey)return;event.preventDefault();const next=event.currentTarget.pathname;if(next!==path){window.history.pushState(null,'',next);setPath(next);}}
 return <><nav aria-label="QA 기능"><a href="/qa/blueprints" onClick={navigate}>XML·Blueprint</a>{' · '}<a href="/qa/shared" onClick={navigate}>공용 시나리오·실행</a></nav>{routes.has(path)?<BlueprintPage key={path} section={path==='/qa/shared'?'shared':'blueprint'}/>:<main><h1>페이지를 찾을 수 없습니다.</h1></main>}</>;
}
