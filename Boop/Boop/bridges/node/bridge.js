#!/usr/bin/env node
const {execFileSync} = require('child_process');
const fs = require('fs');
const Module = require('module');
const path = require('path');

const state = JSON.parse(process.env.BOOP_STATE || '{}');
const MODULE_EXT = process.env.BOOP_MODULE_EXT || '.njs';
const SCRIPT_DIR = process.env.BOOP_SCRIPT_DIR || '';
const LIB_DIR = process.env.BOOP_LIB_DIR || '';

require.extensions['.njs'] = require.extensions['.js'];

const originalRequire = Module.prototype.require;
Module.prototype.require = function(name) {
  let target = name;
  if(!target.endsWith(MODULE_EXT)) target += MODULE_EXT;
  let file;
  if(target.startsWith('@boop/')) {
    file = path.join(LIB_DIR, target.slice(6));
  } else {
    file = path.join(SCRIPT_DIR, target);
  }
  if(fs.existsSync(file)) return originalRequire.call(this, file);
  return originalRequire.call(this, name);
};

class State {
  constructor(data){
    this.text = data.text;
    this.fullText = data.fullText;
    this.selection = data.selection;
    this.network = data.network;
    this.inserts = [];
    this.messages = [];
  }
  post_info(msg){ this.messages.push({type:'info', message: msg}); }
  post_error(msg){ this.messages.push({type:'error', message: msg}); }
  insert(val){ this.inserts.push(val); }
  fetch(url, method, body){
    if(!this.network){ this.post_error('Network permission required'); return null; }
    try{
      const args = ['-sL'];
      if(method && method !== 'GET') args.push('-X', method);
      if(body) args.push('--data', body);
      args.push(url);
      return execFileSync('curl', args, {encoding: 'utf8'});
    }catch(e){
      this.post_error('Failed to fetch');
      return null;
    }
  }
}

const scriptPath = process.argv[2];
const stateObj = new State(state);
const user = require(path.resolve(scriptPath));
if(typeof user.main === 'function'){
  const res = user.main(stateObj);
  if(res && typeof res.then === 'function') {
    res.then(()=>finish()).catch(()=>finish());
  } else {
    finish();
  }
} else {
  finish();
}

function finish(){
  const output = {
    text: stateObj.text,
    fullText: stateObj.fullText,
    selection: stateObj.selection,
    inserts: stateObj.inserts,
    messages: stateObj.messages
  };
  console.log(JSON.stringify(output));
}
