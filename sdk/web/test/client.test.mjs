import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createAnalytics} from '../index.js';
test('imports and page calls are safe during SSR',async()=>{const client=createAnalytics({project:'test',key:'test'});await client.pageView();await client.track('test');});
test('requires project credentials and a valid endpoint',()=>{assert.throws(()=>createAnalytics({}),TypeError);assert.throws(()=>createAnalytics({project:'test',key:'test',endpoint:'javascript:alert(1)'}),TypeError);});
test('tracks browser routes with stable anonymous identity and reports failures',async()=>{
 const originals=Object.fromEntries(['window','document','location','localStorage','fetch'].map(k=>[k,Object.getOwnPropertyDescriptor(globalThis,k)]));
 try{
  const values=new Map(),requests=[];
  Object.assign(globalThis,{window:{},document:{referrer:'https://example.org/article'},location:{origin:'https://app.example',pathname:'/home'},localStorage:{getItem:k=>values.get(k),setItem:(k,v)=>values.set(k,v)},fetch:async(url,options)=>{requests.push({url,...JSON.parse(options.body)});return{ok:true,status:202};}});
  const client=createAnalytics({project:'test',key:'public-write-key'});await client.pageView();await client.pageView('/next');
  assert.equal(requests[0].url,'https://analytics.lailaolab.com/api/events');assert.equal(requests[0].page,'/home');assert.equal(requests[1].page,'/next');assert.equal(requests[0].visitor,requests[1].visitor);assert.notEqual(requests[0].id,requests[1].id);assert.equal(requests[0].source,'example.org');assert.equal(requests[0].platform,'Web');
  globalThis.localStorage={getItem(){throw Error('Storage disabled');}};const privateClient=createAnalytics({project:'private',key:'test'});await privateClient.track('click');
  globalThis.fetch=async()=>({ok:false,status:403});await assert.rejects(client.track('blocked'),/403/);
 }finally{for(const [key,descriptor] of Object.entries(originals)){if(descriptor)Object.defineProperty(globalThis,key,descriptor);else delete globalThis[key];}}
});
